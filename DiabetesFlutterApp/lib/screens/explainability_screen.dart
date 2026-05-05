/// explainability_screen.dart
/// NEW screen — shows global SHAP feature importance fetched from the Flask API.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/app_card.dart';

class ExplainabilityScreen extends StatefulWidget {
  const ExplainabilityScreen({super.key});
  @override
  State<ExplainabilityScreen> createState() => _ExplainabilityScreenState();
}

class _ExplainabilityScreenState extends State<ExplainabilityScreen> {
  bool                   _loading = true;
  String?                _error;
  Map<String, dynamic>?  _shap;
  Map<String, dynamic>?  _permutation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getShapSummary(),
        ApiService.getFeatureImportance(),
      ]);
      setState(() {
        _shap       = results[0];
        _permutation = results[1];
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _errorView();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(children: [
        _infoCard(),
        if (_shap?['success'] == true) _shapCard(),
        _permutationCard(),
        _howToReadCard(),
      ]),
    );
  }

  // ── Info banner ────────────────────────────────────────────────────────────
  Widget _infoCard() => AppCard(
    borderTopColor: AppColors.indigo,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const CardTitle('Model Explainability'),
      Text(
        'This screen shows WHY the model makes its predictions — not just what it predicts.\n\n'
        'SHAP (SHapley Additive exPlanations) assigns each feature a score showing how much '
        'it contributed to the prediction across all patients in the dataset.',
        style: AppText.body,
      ),
    ]),
  );

  // ── SHAP global importance card ────────────────────────────────────────────
  Widget _shapCard() {
    final meanAbs = Map<String, dynamic>.from(_shap!['mean_abs_shap'] as Map);
    final sorted  = meanAbs.entries.toList()
      ..sort((a, b) => (b.value as double).compareTo(a.value as double));
    final maxVal  = (sorted.first.value as double);

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Global SHAP Feature Importance'),
        Text('Mean |SHAP value| across all test patients — higher = more influential.',
            style: AppText.body),
        const SizedBox(height: 16),
        ...sorted.map((e) {
          final val = (e.value as double);
          final pct = (val / maxVal).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.key, style: AppText.label),
                Text(val.toStringAsFixed(4),
                  style: GoogleFonts.spaceMono(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.indigo)),
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: pct, minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.indigo),
                ),
              ),
            ]),
          );
        }),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Glucose and BMI are the dominant predictors — a high glucose '
            'reading is the strongest signal for elevated diabetes risk.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, color: AppColors.indigo, height: 1.5),
          ),
        ),
      ]),
    );
  }

  // ── Permutation importance card ────────────────────────────────────────────
  Widget _permutationCard() {
    if (_permutation?['success'] != true) return const SizedBox();
    final fi     = Map<String, dynamic>.from(_permutation!['feature_importance'] as Map);
    final sorted = fi.entries.toList()
      ..sort((a, b) => (b.value as double).compareTo(a.value as double));
    final maxAbs = sorted.map((e) => (e.value as double).abs())
        .reduce((a, b) => a > b ? a : b);

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Permutation Feature Importance'),
        Text(
          'Accuracy drop when a feature is randomly shuffled. '
          'Negative = the model is slightly better without it (noisy feature).',
          style: AppText.body,
        ),
        const SizedBox(height: 16),
        ...sorted.map((e) {
          final val   = (e.value as double);
          final pct   = (val.abs() / maxAbs).clamp(0.0, 1.0);
          final color = val >= 0 ? AppColors.accent : AppColors.textLight;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.key, style: AppText.label),
                Text('${val >= 0 ? '+' : ''}${val.toStringAsFixed(4)}',
                  style: GoogleFonts.spaceMono(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: pct, minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  // ── How to read card ───────────────────────────────────────────────────────
  Widget _howToReadCard() => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const CardTitle('How to Read This'),
      _bullet('SHAP Value > 0', 'Feature pushed prediction toward Diabetes'),
      _bullet('SHAP Value < 0', 'Feature pushed prediction away from Diabetes'),
      _bullet('Permutation > 0', 'Feature helps the model — removing it reduces accuracy'),
      _bullet('Permutation < 0', 'Feature adds noise — the model is slightly better without it'),
      _bullet('Glucose', 'Most important predictor in both SHAP and permutation measures'),
      _bullet('Skin Thickness', 'Often negative — contains many zero/missing values in the dataset'),
    ]),
  );

  Widget _bullet(String term, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 6, height: 6, margin: const EdgeInsets.only(top: 5, right: 10),
        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
      ),
      Expanded(child: RichText(text: TextSpan(children: [
        TextSpan(text: '$term: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        TextSpan(text: desc,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
      ]))),
    ]),
  );

  // ── Error view ─────────────────────────────────────────────────────────────
  Widget _errorView() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.cloud_off_rounded, size: 52, color: AppColors.textLight),
      const SizedBox(height: 16),
      Text('Cannot reach server', style: AppText.label),
      const SizedBox(height: 8),
      Text(_error ?? 'Unknown error', style: AppText.body, textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: _load, child: const Text('Retry')),
    ]),
  );
}
