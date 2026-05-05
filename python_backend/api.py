"""
api.py  —  Flask REST API for Diabetes Prediction
===================================================
Place this file at: chronic-disease-main/api.py

Run:
    pip install flask flask-cors
    python api.py

The API runs on http://localhost:5000
For Android emulator use: http://10.0.2.2:5000
For a real device on same WiFi: http://<your-pc-ip>:5000

Endpoints:
  POST /predict   — run prediction + SHAP-style contributions
  GET  /health    — check the server is running
  GET  /metrics   — return all model comparison metrics
  GET  /features  — return feature importance
"""
from __future__ import annotations

import json
import pickle
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from flask import Flask, jsonify, request
from flask_cors import CORS

ROOT_DIR = Path(__file__).resolve().parent
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

import config

app = Flask(__name__)
CORS(app)   # allow Flutter to call from any origin

# ─── load model + artifacts once at startup ───────────────────────────────────

def _load_model():
    try:
        with open(config.MODEL_PATH, "rb") as f:
            return pickle.load(f)
    except FileNotFoundError:
        with open(config.ROOT_MODEL_FALLBACK_PATH, "rb") as f:
            return pickle.load(f)

def _load_json(path: Path) -> dict:
    with open(path, "r") as f:
        return json.load(f)

_model = _load_model()
_metrics = _load_json(config.METRICS_PATH)
_feature_importance = _load_json(config.FEATURE_IMPORTANCE_PATH)
_training_summary   = _load_json(config.TRAINING_SUMMARY_PATH)

# Scaler stats (mean, std) so we can compute feature contributions
_SCALER_STATS_PATH = config.ARTIFACTS_DIR / "scaler_stats.json"
try:
    _scaler_stats = _load_json(_SCALER_STATS_PATH)
except FileNotFoundError:
    _scaler_stats = None
    print("[warn] scaler_stats.json not found. Run model/train.py --retrain first.")


# ─── SHAP-style linear feature contributions ──────────────────────────────────

def compute_contributions(inputs: dict[str, float]) -> dict[str, float]:
    """
    Compute per-feature contribution to the final risk score.

    For a logistic model the contribution of feature i is:
        coef[i] * (x[i] - mean[i]) / scale[i]

    We approximate this using the model's predict_proba evaluated by
    permuting each feature back to its mean — i.e. the risk change when
    that feature is set to the population average. This gives an honest,
    model-agnostic contribution without needing the SHAP library.

    Returns a dict: feature_name → contribution (positive = raises risk).
    """
    if _scaler_stats is None:
        return {}

    features = _scaler_stats["features"]
    means    = _scaler_stats["mean"]
    medians  = _scaler_stats["median"]

    # Baseline prediction (all features at their training means)
    baseline_row = {f: medians[i] for i, f in enumerate(features)}
    baseline_df  = pd.DataFrame([baseline_row])[features]
    baseline_prob = float(_model.predict_proba(baseline_df)[0][1])

    # Full prediction
    full_df   = pd.DataFrame([{f: inputs[f] for f in features}])[features]
    full_prob = float(_model.predict_proba(full_df)[0][1])

    contributions = {}
    for i, feat in enumerate(features):
        # Prediction with this feature set to its mean (everything else real)
        ablated = dict(inputs)
        ablated[feat] = medians[i]
        ablated_df   = pd.DataFrame([{f: ablated[f] for f in features}])[features]
        ablated_prob  = float(_model.predict_proba(ablated_df)[0][1])
        # Contribution = how much risk drops when we remove this feature's info
        contributions[feat] = round(full_prob - ablated_prob, 4)

    return contributions


# ─── routes ───────────────────────────────────────────────────────────────────

@app.route("/health", methods=["GET"])
def health():
    champion = _training_summary.get("best_model", "Unknown")
    acc = _training_summary.get("test_metrics", {}).get("accuracy", 0)
    return jsonify({
        "status": "ok",
        "champion_model": champion,
        "accuracy": round(acc, 4),
    })


@app.route("/predict", methods=["POST"])
def predict():
    """
    Request body (JSON):
    {
      "Pregnancies": 2,
      "Glucose": 148,
      "BloodPressure": 72,
      "SkinThickness": 35,
      "Insulin": 0,
      "BMI": 33.6,
      "Age": 50
    }

    Response:
    {
      "prob_class_1": 0.78,
      "risk_pct": 78.0,
      "risk_level": "High",
      "pred_label": "Diabetes",
      "contributions": { "Glucose": 0.21, "BMI": 0.08, ... },
      "suggestions": ["...", "..."]
    }
    """
    body = request.get_json(silent=True)
    if not body:
        return jsonify({"error": "Request body must be JSON"}), 400

    # Validate all features are present
    missing = [f for f in config.FEATURE_COLUMNS if f not in body]
    if missing:
        return jsonify({"error": f"Missing fields: {missing}"}), 400

    try:
        inputs = {f: float(body[f]) for f in config.FEATURE_COLUMNS}
    except (TypeError, ValueError) as e:
        return jsonify({"error": f"Invalid value: {e}"}), 400

    # Run model
    input_df = pd.DataFrame([inputs])[config.FEATURE_COLUMNS]
    prob = float(_model.predict_proba(input_df)[0][1])
    risk_pct = prob * 100.0

    pred_label = "Diabetes" if prob >= config.DIABETIC_PROB_THRESHOLD else "No Diabetes"
    if risk_pct < config.RISK_LOW_MAX:
        risk_level = "Low"
    elif risk_pct < config.RISK_MODERATE_MAX:
        risk_level = "Medium"
    else:
        risk_level = "High"

    # SHAP-style contributions
    contributions = compute_contributions(inputs)

    # Health suggestions (same logic as utils/suggestions.py)
    suggestions = _get_suggestions(inputs, risk_level)

    return jsonify({
        "prob_class_1": round(prob, 4),
        "risk_pct":     round(risk_pct, 2),
        "risk_level":   risk_level,
        "pred_label":   pred_label,
        "contributions": contributions,
        "suggestions":   suggestions,
    })


@app.route("/metrics", methods=["GET"])
def metrics():
    return jsonify({
        "models": _metrics,
        "champion": _training_summary.get("best_model"),
        "feature_importance": _feature_importance,
    })


@app.route("/features", methods=["GET"])
def features():
    return jsonify(_feature_importance)


# ─── suggestions (mirrors utils/suggestions.py) ───────────────────────────────

def _get_suggestions(inputs: dict, risk_level: str) -> list[str]:
    sugs = []
    g   = inputs["Glucose"]
    bmi = inputs["BMI"]
    bp  = inputs["BloodPressure"]
    age = inputs["Age"]

    if g >= 126:
        sugs.append("High glucose: reduce sugar and refined carbs, monitor blood sugar regularly.")
    elif g >= 100:
        sugs.append("Borderline glucose: limit sugary drinks and processed foods.")
    else:
        sugs.append("Glucose is in a healthier range — maintain balanced nutrition.")

    if bmi >= 30:
        sugs.append("BMI suggests obesity: aim for regular physical activity and portion control.")
    elif bmi >= 25:
        sugs.append("BMI is moderately elevated: gradual weight management through diet and exercise.")
    else:
        sugs.append("BMI is relatively healthy: keep current habits and stay active.")

    if bp >= 90:
        sugs.append("Blood pressure is elevated: reduce salt, manage stress, follow clinician advice.")
    elif bp >= 80:
        sugs.append("Blood pressure slightly elevated: stay hydrated and manage lifestyle factors.")

    if age >= 45 and risk_level in ("Medium", "High"):
        sugs.append("Age 45+ with elevated risk: discuss HbA1c screening with your healthcare provider.")

    if risk_level == "High":
        sugs.append("High risk: consult a doctor or endocrinologist soon.")
        sugs.append("Consider periodic glucose/HbA1c monitoring based on clinician guidance.")
    elif risk_level == "Medium":
        sugs.append("Medium risk: start lifestyle adjustments now and re-check as advised.")
    else:
        sugs.append("Low risk: maintain healthy habits and do routine check-ups.")

    seen, out = set(), []
    for s in sugs:
        if s not in seen:
            seen.add(s); out.append(s)
    return out


# ─── run ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("Starting Diabetes Prediction API...")
    print("  POST /predict  — run a prediction")
    print("  GET  /health   — server status")
    print("  GET  /metrics  — model metrics")
    app.run(host="0.0.0.0", port=5000, debug=False)
