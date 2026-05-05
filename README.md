# 🩺 Diabetes Risk Prediction App

A complete end-to-end Machine Learning project for predicting diabetes risk.

## 📱 Mobile App (Flutter)
- Predict diabetes risk using patient data
- SHAP feature contributions
- Health suggestions
- PDF report export

## 🧠 ML Model
- Dataset: Pima Indians Diabetes Dataset (768 samples)
- Models: SVM, Logistic Regression, Random Forest
- Champion: SVM (RBF) — 74% accuracy
- Features: Glucose, BMI, Age, Insulin, Blood Pressure, etc.

## 🚀 Backend (Flask API)
- Deployed on Render.com
- Endpoints: /health, /predict, /metrics, /feature-importance

## 🛠️ Tech Stack
| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| ML Model | scikit-learn SVM |
| API | Flask + Flask-CORS |
| Deployment | Render.com |
| Dataset | Pima Indians Diabetes |

## 📊 Model Results
| Model | Accuracy | ROC-AUC |
|---|---|---|
| SVM (RBF) | 74.0% | 0.796 |
| Random Forest | 72.1% | 0.804 |
| Logistic Regression | 70.8% | 0.813 |

## 🔗 Live API
https://diabetes-api-wjkc.onrender.com/health