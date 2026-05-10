"""Sklearn preprocessing pipeline steps used by model/train.py."""
from __future__ import annotations

from sklearn.impute import SimpleImputer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler


def numeric_steps(feature_names: list[str]) -> list[tuple[str, object]]:
    """Flat imputer + scaler steps (imblearn.Pipeline forbids nested sklearn.Pipeline)."""
    _ = feature_names
    return [
        ("imputer", SimpleImputer(strategy="median")),
        ("scaler", StandardScaler()),
    ]


def make_numeric_preprocess(feature_names: list[str]) -> Pipeline:
    """Median impute NaNs, then standard-scale."""
    return Pipeline(numeric_steps(feature_names))
