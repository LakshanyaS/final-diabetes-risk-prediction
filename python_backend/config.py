"""Paths and constants shared by api.py and model/train.py."""
from __future__ import annotations

from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent

# Same 7 features as POST /predict in api.py (no DiabetesPedigreeFunction).
FEATURE_COLUMNS = [
    "Pregnancies",
    "Glucose",
    "BloodPressure",
    "SkinThickness",
    "Insulin",
    "BMI",
    "Age",
]
TARGET_COLUMN = "Outcome"

RANDOM_STATE = 42
MODEL_SELECTION_METRIC = "accuracy"

DIABETIC_PROB_THRESHOLD = 0.5
RISK_LOW_MAX = 33.33
RISK_MODERATE_MAX = 66.66

ARTIFACTS_DIR = ROOT_DIR / "model" / "artifacts"
MODEL_PATH = ARTIFACTS_DIR / "model.pkl"
METRICS_PATH = ARTIFACTS_DIR / "metrics.json"
FEATURE_IMPORTANCE_PATH = ARTIFACTS_DIR / "feature_importance.json"
TRAINING_SUMMARY_PATH = ARTIFACTS_DIR / "training_summary.json"

# jbrownlee CSV has no header; columns match UCI Pima.
PIMA_COLUMN_NAMES = [
    "Pregnancies",
    "Glucose",
    "BloodPressure",
    "SkinThickness",
    "Insulin",
    "BMI",
    "DiabetesPedigreeFunction",
    "Age",
    "Outcome",
]

DATASET_PATH = ROOT_DIR / "data" / "diabetes.csv"
ROOT_DATASET_FALLBACK_PATH = ROOT_DIR.parent / "data" / "diabetes.csv"
DATASET_URL = (
    "https://raw.githubusercontent.com/jbrownlee/Datasets/master/"
    "pima-indians-diabetes.data.csv"
)

ROOT_MODEL_FALLBACK_PATH = ROOT_DIR / "model.pkl"
