"""
model/train.py  —  Improved training pipeline
==============================================
Drop this into: chronic-disease-main/model/train.py
Everything else (config.py, preprocessing.py, predict.py) stays the same.

New vs original:
  1. Zero-value fix  — Glucose/BP/Skin/Insulin/BMI 0s → NaN → median imputed
  2. XGBoost         — Added as 4th model
  3. SMOTE           — Balances 65/35 class imbalance on training set
  4. ROC-AUC         — Added to all model metrics
  5. Cross-validation — mean±std saved per model
  6. 4 PNG plots     — confusion matrix, ROC curves, feature importance, CV comparison
  7. Flask-ready     — saves scaler+imputer stats to artifacts/scaler_stats.json
                       so the API can compute SHAP-style contributions per patient

pip install xgboost imbalanced-learn  (add to requirements.txt)
Run: python model/train.py --retrain
"""
from __future__ import annotations

import argparse
import json
import pickle
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from sklearn.ensemble import RandomForestClassifier
from sklearn.inspection import permutation_importance
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score, f1_score, precision_score, recall_score,
    roc_auc_score, roc_curve, ConfusionMatrixDisplay,
)
from sklearn.model_selection import (
    GridSearchCV, StratifiedKFold, cross_val_score, train_test_split,
)
from sklearn.pipeline import Pipeline
from sklearn.svm import SVC
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler

try:
    from xgboost import XGBClassifier
    _XGB = True
except ImportError:
    _XGB = False
    print("[warn] xgboost not installed. Run: pip install xgboost")

try:
    from imblearn.over_sampling import SMOTE
    _SMOTE = True
except ImportError:
    _SMOTE = False
    print("[warn] imbalanced-learn not installed. Run: pip install imbalanced-learn")

import config
from model.preprocessing import make_numeric_preprocess

# Columns that cannot physically be 0 in this dataset
_ZERO_IS_MISSING = ["Glucose", "BloodPressure", "SkinThickness", "Insulin", "BMI"]


# ─── helpers ──────────────────────────────────────────────────────────────────

def load_dataset() -> pd.DataFrame:
    for path in [config.DATASET_PATH, config.ROOT_DATASET_FALLBACK_PATH]:
        try:
            return pd.read_csv(path)
        except FileNotFoundError:
            continue
    return pd.read_csv(config.DATASET_URL)


def fix_zero_values(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    cols = [c for c in _ZERO_IS_MISSING if c in df.columns]
    df[cols] = df[cols].replace(0, np.nan)
    print("\n── Zero-value fix ───────────────────────────────────")
    for c in cols:
        n = df[c].isna().sum()
        print(f"   {c:20s}: {n:3d} zeros → NaN (median will fill)")
    print()
    return df


# ─── training ─────────────────────────────────────────────────────────────────

def train_and_select_champion(df: pd.DataFrame):
    feat = config.FEATURE_COLUMNS
    X, y = df[feat], df[config.TARGET_COLUMN]
    X_tr, X_te, y_tr, y_te = train_test_split(
        X, y, test_size=0.20, stratify=y, random_state=config.RANDOM_STATE
    )
    pre = make_numeric_preprocess(feat)
    cv5 = StratifiedKFold(n_splits=5, shuffle=True, random_state=config.RANDOM_STATE)

    cfgs: dict = {
        "Logistic Regression": {
            "est": LogisticRegression(max_iter=500, solver="lbfgs"),
            "grid": {"clf__C": [0.1, 1, 10], "clf__penalty": ["l2"]},
        },
        "Random Forest": {
            "est": RandomForestClassifier(random_state=config.RANDOM_STATE),
            "grid": {"clf__n_estimators": [100, 300], "clf__max_depth": [None, 5, 10]},
        },
        "SVM (RBF)": {
            "est": SVC(probability=True, random_state=config.RANDOM_STATE),
            "grid": {"clf__C": [0.5, 1.0, 2.0], "clf__gamma": ["scale", "auto"]},
        },
    }
    if _XGB:
        cfgs["XGBoost"] = {
            "est": XGBClassifier(
                use_label_encoder=False, eval_metric="logloss",
                random_state=config.RANDOM_STATE, verbosity=0,
            ),
            "grid": {
                "clf__n_estimators": [100, 300],
                "clf__max_depth": [4, 6],
                "clf__learning_rate": [0.05, 0.1],
            },
        }

    results: dict = {}
    for name, cfg in cfgs.items():
        print(f"Training {name}...")
        plain_pipe = Pipeline([("pre", pre), ("clf", cfg["est"])])
        gs = GridSearchCV(plain_pipe, cfg["grid"], cv=cv5, scoring="accuracy",
                          n_jobs=-1, verbose=0)
        gs.fit(X_tr, y_tr)
        best_model = gs.best_estimator_

        # SMOTE: re-fit best model on balanced data
        if _SMOTE:
            best_params = {k.replace("clf__", ""): v
                           for k, v in gs.best_params_.items()}
            est_class = cfg["est"].__class__
            # rebuild estimator with best params (filter only valid ones)
            import inspect
            valid = inspect.signature(est_class.__init__).parameters
            filtered = {k: v for k, v in best_params.items() if k in valid}
            new_est = est_class(**filtered)
            from imblearn.pipeline import Pipeline as ImbPipe
            smote_pipe = ImbPipe([
                ("pre", make_numeric_preprocess(feat)),
                ("smote", SMOTE(random_state=config.RANDOM_STATE)),
                ("clf", new_est),
            ])
            smote_pipe.fit(X_tr, y_tr)
            best_model = smote_pipe

        y_pred = best_model.predict(X_te)
        y_prob = best_model.predict_proba(X_te)[:, 1]

        # Cross-val on plain pipeline with best params
        cv_scores = cross_val_score(gs.best_estimator_, X, y, cv=cv5,
                                    scoring="accuracy", n_jobs=-1)

        results[name] = {
            "model": best_model,
            "y_pred": y_pred,
            "y_prob": y_prob,
            "metrics": {
                "accuracy":         float(accuracy_score(y_te, y_pred)),
                "precision":        float(precision_score(y_te, y_pred, zero_division=0)),
                "recall":           float(recall_score(y_te, y_pred, zero_division=0)),
                "f1":               float(f1_score(y_te, y_pred, zero_division=0)),
                "roc_auc":          float(roc_auc_score(y_te, y_prob)),
                "cv_accuracy_mean": float(cv_scores.mean()),
                "cv_accuracy_std":  float(cv_scores.std()),
            },
            "best_params": gs.best_params_,
        }
        m = results[name]["metrics"]
        print(f"   Acc={m['accuracy']:.3f}  AUC={m['roc_auc']:.3f}  "
              f"CV={m['cv_accuracy_mean']:.3f}±{m['cv_accuracy_std']:.3f}")

    champion = max(results, key=lambda k: results[k]["metrics"]["accuracy"])
    print(f"\n🏆  Champion: {champion}\n")

    # Permutation importance on champion
    perm = permutation_importance(
        results[champion]["model"], X_te, y_te,
        scoring="accuracy", n_repeats=10, random_state=config.RANDOM_STATE,
    )
    fi = {feat[i]: float(perm.importances_mean[i]) for i in range(len(feat))}

    return results, champion, results[champion]["model"], X_te, y_te, fi, X, y


# ─── save scaler stats for Flask SHAP contributions ───────────────────────────

def save_scaler_stats(df: pd.DataFrame, artifacts_dir: Path) -> None:
    """
    Save mean & std of each feature (after zero-fix imputation) so the
    Flask API can compute SHAP-style per-feature contributions without
    needing a full SHAP library.
    """
    feat = config.FEATURE_COLUMNS
    X = df[feat].copy()
    cols = [c for c in _ZERO_IS_MISSING if c in X.columns]
    X[cols] = X[cols].replace(0, np.nan)

    imp = SimpleImputer(strategy="median")
    X_filled = imp.fit_transform(X)
    sc = StandardScaler()
    sc.fit(X_filled)

    stats = {
        "features": feat,
        "mean":     sc.mean_.tolist(),
        "scale":    sc.scale_.tolist(),
        "median":   imp.statistics_.tolist(),
    }
    out = artifacts_dir / "scaler_stats.json"
    with open(out, "w") as f:
        json.dump(stats, f, indent=2)
    print(f"   Saved scaler_stats.json  → {out}")


# ─── plots ────────────────────────────────────────────────────────────────────

def save_confusion_matrix(results, champion, y_te, artifacts_dir):
    fig, ax = plt.subplots(figsize=(5, 4))
    ConfusionMatrixDisplay.from_predictions(
        y_te, results[champion]["y_pred"],
        display_labels=["No Diabetes", "Diabetes"],
        colorbar=False, ax=ax, cmap="Blues",
    )
    ax.set_title(f"Confusion Matrix — {champion}", fontweight="bold")
    fig.tight_layout()
    p = artifacts_dir / "confusion_matrix.png"
    fig.savefig(p, dpi=150); plt.close(fig)
    print(f"   Saved confusion_matrix.png → {p}")


def save_roc_curves(results, y_te, artifacts_dir):
    colors = ["#6366f1", "#22c55e", "#f59e0b", "#ef4444"]
    fig, ax = plt.subplots(figsize=(6, 5))
    for (name, data), color in zip(results.items(), colors):
        fpr, tpr, _ = roc_curve(y_te, data["y_prob"])
        ax.plot(fpr, tpr, color=color, lw=2,
                label=f"{name} (AUC={data['metrics']['roc_auc']:.3f})")
    ax.plot([0, 1], [0, 1], "k--", lw=1, alpha=0.5)
    ax.set_xlabel("False Positive Rate"); ax.set_ylabel("True Positive Rate")
    ax.set_title("ROC Curves — All Models", fontweight="bold")
    ax.legend(loc="lower right", fontsize=9)
    fig.tight_layout()
    p = artifacts_dir / "roc_curves.png"
    fig.savefig(p, dpi=150); plt.close(fig)
    print(f"   Saved roc_curves.png       → {p}")


def save_feature_importance_plot(fi, champion, artifacts_dir):
    sorted_fi = sorted(fi.items(), key=lambda x: x[1])
    names, vals = zip(*sorted_fi)
    colors = ["#ef4444" if v < 0 else "#6366f1" for v in vals]
    fig, ax = plt.subplots(figsize=(7, 4))
    bars = ax.barh(names, vals, color=colors)
    ax.axvline(0, color="black", lw=0.8)
    ax.set_xlabel("Permutation importance")
    ax.set_title(f"Feature Importance — {champion}", fontweight="bold")
    ax.bar_label(bars, fmt="%.4f", padding=3, fontsize=8)
    fig.tight_layout()
    p = artifacts_dir / "feature_importance.png"
    fig.savefig(p, dpi=150); plt.close(fig)
    print(f"   Saved feature_importance.png → {p}")


def save_cv_comparison(results, artifacts_dir):
    names = list(results.keys())
    test_acc = [results[n]["metrics"]["accuracy"] for n in names]
    cv_mean  = [results[n]["metrics"]["cv_accuracy_mean"] for n in names]
    cv_std   = [results[n]["metrics"]["cv_accuracy_std"] for n in names]
    x = np.arange(len(names))
    fig, ax = plt.subplots(figsize=(8, 4.5))
    ax.bar(x - 0.175, test_acc, 0.35, label="Test accuracy",
           color=["#6366f1", "#22c55e", "#f59e0b", "#ef4444"][:len(names)])
    ax.bar(x + 0.175, cv_mean, 0.35, yerr=cv_std, capsize=4,
           label="CV accuracy (mean±std)",
           color=["#6366f180", "#22c55e80", "#f59e0b80", "#ef444480"][:len(names)])
    ax.set_xticks(x); ax.set_xticklabels(names, rotation=10, ha="right")
    ax.set_ylim(0, 1); ax.legend(fontsize=9)
    ax.set_title("Model Comparison — Test vs CV Accuracy", fontweight="bold")
    fig.tight_layout()
    p = artifacts_dir / "model_comparison.png"
    fig.savefig(p, dpi=150); plt.close(fig)
    print(f"   Saved model_comparison.png  → {p}")


# ─── main ─────────────────────────────────────────────────────────────────────

def train_and_save(model_path=None, artifacts_dir=None):
    if model_path is None:   model_path    = config.MODEL_PATH
    if artifacts_dir is None: artifacts_dir = config.ARTIFACTS_DIR
    model_path.parent.mkdir(parents=True, exist_ok=True)
    artifacts_dir.mkdir(parents=True, exist_ok=True)

    df = load_dataset()
    df = fix_zero_values(df)

    results, champion, champ_model, X_te, y_te, fi, X, y = \
        train_and_select_champion(df)

    # JSON artifacts (backward-compatible)
    metrics_out = {
        name: {"metrics": data["metrics"], "best_params": data["best_params"]}
        for name, data in results.items()
    }
    with open(config.METRICS_PATH, "w") as f:
        json.dump(metrics_out, f, indent=2)
    print(f"   Saved metrics.json         → {config.METRICS_PATH}")

    with open(config.FEATURE_IMPORTANCE_PATH, "w") as f:
        json.dump(fi, f, indent=2)
    print(f"   Saved feature_importance.json → {config.FEATURE_IMPORTANCE_PATH}")

    summary = {
        "best_model": champion,
        "selection_metric": config.MODEL_SELECTION_METRIC,
        "test_metrics": results[champion]["metrics"],
        "smote_used": _SMOTE,
        "xgboost_used": _XGB,
    }
    with open(config.TRAINING_SUMMARY_PATH, "w") as f:
        json.dump(summary, f, indent=2)
    print(f"   Saved training_summary.json → {config.TRAINING_SUMMARY_PATH}")

    with open(model_path, "wb") as f:
        pickle.dump(champ_model, f)
    print(f"   Saved model.pkl            → {model_path}")

    # Scaler stats for Flask API
    save_scaler_stats(df, artifacts_dir)

    # Plots
    print("\n── Saving plots ─────────────────────────────────────")
    save_confusion_matrix(results, champion, y_te, artifacts_dir)
    save_roc_curves(results, y_te, artifacts_dir)
    save_feature_importance_plot(fi, champion, artifacts_dir)
    save_cv_comparison(results, artifacts_dir)

    return model_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--retrain", action="store_true")
    args = parser.parse_args()
    if not args.retrain and config.MODEL_PATH.exists() and config.METRICS_PATH.exists():
        print("Model exists. Use --retrain to overwrite.")
    else:
        out = train_and_save()
        print(f"\nDone → {out}")
