/// models_screen.dart — fetches model metrics live from the Flask API.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/app_card.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});
  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  bool                  _loading = true;
  String?               _error;
  Map<String, dynamic>? _metricsData;
  String?               _champion;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.getMetrics();
      if (r['success'] == true) {
        final metrics = r['metrics'] as Map<String, dynamic>;
        // Find champion by highest accuracy
        String champ = metrics.keys.first;
        double best  = 0;
        metrics.forEach((name, data) {
          final acc = (data['metrics']?['accuracy'] as num?)?.toDouble() ?? 0;
          if (acc > best) { best = acc; champ = name; }
        });
        setState(() { _metricsData = metrics; _champion = champ; });
      } else {
        setState(() => _error = r['error'] ?? 'Failed to load metrics');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _errorView();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(children: [
        _championBanner(),
        _metricsTable(),
        _detailCards(),
        _trainingNotes(),
      ]),
    );
  }

  // ── Champion banner ────────────────────────────────────────────────────────
  Widget _championBanner() {
    if (_champion == null) return const SizedBox();
    final data    = _metricsData![_champion!];
    final metrics = data['metrics'] as Map<String, dynamic>;
    final acc     = ((metrics['accuracy'] as num?)?.toDouble() ?? 0) * 100;
    final auc     = ((metrics['roc_auc']   as num?)?.toDouble() ?? 0);
    final cvMean  = ((metrics['cv_accuracy_mean'] as num?)?.toDouble() ?? 0) * 100;
    final cvStd   = ((metrics['cv_accuracy_std']  as num?)?.toDouble() ?? 0) * 100;

    return AppCard(
      borderTopColor: AppColors.indigo,
      child: Column(children: [
        const CardTitle('Champion Model'),
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('🏆', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_champion!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text('Selected by highest test accuracy',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500)),
          ])),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          MetricPill(label: 'Accuracy',  value: '${acc.toStringAsFixed(1)}%',  valueColor: AppColors.indigo),
          MetricPill(label: 'ROC-AUC',   value: auc > 0 ? auc.toStringAsFixed(3) : 'N/A', valueColor: AppColors.accent),
          MetricPill(label: 'CV Score',  value: cvMean > 0 ? '${cvMean.toStringAsFixed(1)}%' : 'N/A'),
          MetricPill(label: 'CV Std',    value: cvStd > 0 ? '±${cvStd.toStringAsFixed(1)}%' : 'N/A'),
        ]),
        if (cvMean > 0) ...[
          const SizedBox(height: 10),
          Text(
            '5-fold cross-validation: ${cvMean.toStringAsFixed(1)}% ± ${cvStd.toStringAsFixed(1)}% — '
            'proves results are consistent, not a lucky split.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, color: AppColors.textMuted, height: 1.5),
          ),
        ],
      ]),
    );
  }

  // ── Metrics table ──────────────────────────────────────────────────────────
  Widget _metricsTable() {
    final models  = _metricsData!.keys.toList();
    const headers = ['Model', 'Acc', 'Prec', 'Recall', 'F1', 'AUC'];

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('All Models Comparison'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 36,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 44,
            columnSpacing: 14,
            headingTextStyle: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted),
            dataTextStyle: GoogleFonts.spaceMono(
              fontSize: 11, fontWeight: FontWeight.w700),
            columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
            rows: models.map((name) {
              final m    = (_metricsData![name]['metrics'] as Map<String, dynamic>?) ?? {};
              final isC  = name == _champion;
              final fmt  = (String k) {
                final v = (m[k] as num?)?.toDouble() ?? 0;
                return v > 0 ? '${(v * 100).toStringAsFixed(1)}%' : '—';
              };
              final auc  = (m['roc_auc'] as num?)?.toDouble() ?? 0;

              return DataRow(
                color: WidgetStateProperty.all(
                  isC ? const Color(0xFFEEF2FF) : Colors.transparent),
                cells: [
                  DataCell(Text(
                    isC ? '🏆 $name' : name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: isC ? AppColors.indigo : AppColors.textSecondary),
                  )),
                  DataCell(Text(fmt('accuracy'),  style: TextStyle(color: isC ? AppColors.indigo : null))),
                  DataCell(Text(fmt('precision'))),
                  DataCell(Text(fmt('recall'))),
                  DataCell(Text(fmt('f1'))),
                  DataCell(Text(auc > 0 ? auc.toStringAsFixed(3) : '—')),
                ],
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  // ── Detail cards per model ─────────────────────────────────────────────────
  Widget _detailCards() => Column(
    children: _metricsData!.entries.map((e) {
      final name   = e.key;
      final params = (e.value['best_params'] as Map<String, dynamic>?) ?? {};
      final m      = (e.value['metrics']    as Map<String, dynamic>?) ?? {};
      final cvM    = (m['cv_accuracy_mean'] as num?)?.toDouble() ?? 0;
      final cvS    = (m['cv_accuracy_std']  as num?)?.toDouble() ?? 0;

      return AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (name == _champion)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('Champion',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.indigo)),
              ),
            Text(name, style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          if (params.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: params.entries.map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${p.key.replaceAll('clf__', '')}: ${p.value}',
                  style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.textMuted)),
              )).toList(),
            ),
          ],
          if (cvM > 0) ...[
            const SizedBox(height: 8),
            Text(
              'CV: ${(cvM * 100).toStringAsFixed(1)}% ± ${(cvS * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ],
        ]),
      );
    }).toList(),
  );

  // ── Training notes ─────────────────────────────────────────────────────────
  Widget _trainingNotes() => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const CardTitle('Training Configuration'),
      _note('Dataset',    'Pima Indian Diabetes — 768 samples, 8 features'),
      _note('Split',      '80% train / 20% test, stratified'),
      _note('CV',         '5-fold StratifiedKFold'),
      _note('Tuning',     'GridSearchCV on each model'),
      _note('Zero-fix',   'Glucose, BP, Skin, Insulin, BMI zeros → NaN → median impute'),
      _note('SMOTE',      'Applied if imbalanced-learn installed'),
      _note('Inference',  'Live — Flutter calls Flask API, real model runs on server'),
    ]),
  );

  Widget _note(String key, String val) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90,
        child: Text(key, style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted))),
      Expanded(child: Text(val, style: AppText.body)),
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
      Text(_error ?? '', style: AppText.body, textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: _load, child: const Text('Retry')),
    ]),
  );
}
