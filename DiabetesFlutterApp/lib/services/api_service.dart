/// api_service.dart
/// ─────────────────────────────────────────────────────────────────────────
/// Single point of contact between Flutter and the Flask API.
///
/// Base URL for different environments:
///   Android emulator  → http://10.0.2.2:5000
///   iOS simulator     → http://127.0.0.1:5000
///   Real device       → http://<your-PC-LAN-IP>:5000
///   Production        → https://your-deployed-domain.com
///
/// Change [baseUrl] below to match your setup.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ── Change this to match your environment ──────────────────────────────
  //static const String baseUrl = 'http://localhost:5000';
  // For render----------------
  static const String baseUrl = 'https://diabetes-api-wjkc.onrender.com';

  static const Duration _timeout = Duration(seconds: 15);
  static final _headers = {'Content-Type': 'application/json'};

  // ── Health check ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> checkHealth() async {
    final res = await http
        .get(Uri.parse('$baseUrl/health'), headers: _headers)
        .timeout(_timeout);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Predict ────────────────────────────────────────────────────────────
  /// Sends patient data and returns the full prediction result.
  ///
  /// Returns a map with keys:
  ///   success, prob_class_1, risk_pct, risk_level, pred_label,
  ///   feature_contribs, suggestions
  static Future<Map<String, dynamic>> predict({
    required double pregnancies,
    required double glucose,
    required double bloodPressure,
    required double skinThickness,
    required double insulin,
    required double bmi,
    required double dpf,
    required double age,
  }) async {
    final body = jsonEncode({
      'Pregnancies': pregnancies,
      'Glucose': glucose,
      'BloodPressure': bloodPressure,
      'SkinThickness': skinThickness,
      'Insulin': insulin,
      'BMI': bmi,
      'DiabetesPedigreeFunction': dpf,
      'Age': age,
    });

    final res = await http
        .post(Uri.parse('$baseUrl/predict'), headers: _headers, body: body)
        .timeout(_timeout);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'Prediction failed (${res.statusCode})');
    }
  }

  // ── Feature importance ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getFeatureImportance() async {
    final res = await http
        .get(Uri.parse('$baseUrl/feature-importance'), headers: _headers)
        .timeout(_timeout);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Model metrics ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMetrics() async {
    final res = await http
        .get(Uri.parse('$baseUrl/metrics'), headers: _headers)
        .timeout(_timeout);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── SHAP summary ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getShapSummary() async {
    final res = await http
        .get(Uri.parse('$baseUrl/shap-summary'), headers: _headers)
        .timeout(_timeout);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
