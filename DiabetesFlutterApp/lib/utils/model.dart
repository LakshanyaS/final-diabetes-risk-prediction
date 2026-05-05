/// lib/utils/model.dart
/// ─────────────────────────────────────────────────────────────────────────
/// Static dataset constants used by VisualizationsScreen.
/// These are pre-computed from the Pima Indians Diabetes dataset
/// (model/artifacts/feature_importance.json + dataset histograms).
/// ─────────────────────────────────────────────────────────────────────────

// ── Glucose histogram data ─────────────────────────────────────────────────
// Bin left edges (mg/dL), 15 bins from 44 → 199
const List<int> glucoseBins = [
  44,
  54,
  64,
  74,
  84,
  94,
  104,
  114,
  124,
  134,
  144,
  154,
  164,
  174,
  184,
];

// Count of non-diabetic patients (Outcome=0) per bin
const List<int> glucoseNoD = [
  2,
  10,
  22,
  38,
  56,
  72,
  80,
  75,
  62,
  45,
  30,
  18,
  10,
  5,
  2,
];

// Count of diabetic patients (Outcome=1) per bin
const List<int> glucoseDiab = [
  0,
  1,
  3,
  6,
  10,
  14,
  22,
  34,
  42,
  45,
  38,
  30,
  20,
  12,
  6,
];

// ── BMI histogram data ─────────────────────────────────────────────────────
// Bin left edges (kg/m²), 15 bins from 18 → 66
const List<int> bmiBins = [
  18,
  20,
  22,
  24,
  26,
  28,
  30,
  32,
  34,
  36,
  38,
  40,
  44,
  50,
  57,
];

// Count of non-diabetic patients per bin
const List<int> bmiNoD = [
  5,
  14,
  28,
  44,
  60,
  72,
  68,
  55,
  42,
  28,
  18,
  10,
  6,
  3,
  1,
];

// Count of diabetic patients per bin
const List<int> bmiDiab = [
  1,
  3,
  7,
  12,
  18,
  26,
  32,
  35,
  30,
  26,
  20,
  14,
  10,
  6,
  3,
];

// ── Feature importance (permutation, from model/artifacts/feature_importance.json) ──
// Values represent mean accuracy drop when the feature is permuted.
// Update these after each retrain by copying from flutter_coefficients.json.
const Map<String, double> featureImportance = {
  'Glucose': 0.0669,
  'BMI': 0.0182,
  'Age': 0.0143,
  'DiabetesPedigreeFunction': 0.0078,
  'Pregnancies': 0.0065,
  'Insulin': 0.0039,
  'BloodPressure': 0.0026,
  'SkinThickness': 0.0013,
};

/// Sorted descending by importance value — ready for FeatureBar widgets.
final List<MapEntry<String, double>> featureImportanceSorted =
    featureImportance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
