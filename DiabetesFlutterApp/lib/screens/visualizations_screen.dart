import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/model.dart';
import '../utils/theme.dart';
import '../widgets/app_card.dart';

class VisualizationsScreen extends StatelessWidget {
  const VisualizationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(children: [

        // ── Stats grid ───────────────────────────────────────────────────────
        Row(children: [
          _StatCard(value: '768',   label: 'Total Samples', color: AppColors.accent),
          const SizedBox(width: 10),
          _StatCard(value: '34.9%', label: 'Diabetic Rate',  color: AppColors.red),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _StatCard(value: '120.9', label: 'Avg Glucose',    color: AppColors.yellow),
          const SizedBox(width: 10),
          _StatCard(value: '32.0',  label: 'Avg BMI',         color: AppColors.green),
        ]),
        const SizedBox(height: 14),

        // ── Glucose chart ────────────────────────────────────────────────────
        _ChartCard(
          title: '🩸  GLUCOSE DISTRIBUTION BY OUTCOME',
          subtitle: 'Histogram of glucose levels split by diabetic outcome',
          child: _HistogramChart(
            bins:    glucoseBins.map((v) => v.toDouble()).toList(),
            seriesA: glucoseNoD.map((v) => v.toDouble()).toList(),
            seriesB: glucoseDiab.map((v) => v.toDouble()).toList(),
            colorA:  AppColors.indigo,
            colorB:  AppColors.red,
            labelA:  'No Diabetes',
            labelB:  'Diabetes',
          ),
        ),

        // ── BMI chart ────────────────────────────────────────────────────────
        _ChartCard(
          title: '⚖️  BMI DISTRIBUTION BY OUTCOME',
          subtitle: 'Histogram of BMI values split by diabetic outcome',
          child: _HistogramChart(
            bins:    bmiBins.map((v) => v.toDouble()).toList(),
            seriesA: bmiNoD.map((v) => v.toDouble()).toList(),
            seriesB: bmiDiab.map((v) => v.toDouble()).toList(),
            colorA:  AppColors.indigo,
            colorB:  AppColors.red,
            labelA:  'No Diabetes',
            labelB:  'Diabetes',
          ),
        ),

        // ── Feature importance ───────────────────────────────────────────────
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle('🧬  FEATURE IMPORTANCE (PERMUTATION)'),
          Text(
            'Accuracy drop when each feature is permuted\nSource: model/artifacts/feature_importance.json',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textLight, height: 1.5),
          ),
          const SizedBox(height: 16),
          ...featureImportanceSorted.map((e) => FeatureBar(
            name: e.key, value: e.value, maxValue: 0.0669,
          )),
        ])),

      ]),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.spaceMono(fontSize: 26, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 5),
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: AppColors.textLight, letterSpacing: 0.5,
        )),
      ]),
    ),
  );
}

// ── Chart card wrapper ────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CardTitle(title),
      Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textLight)),
      const SizedBox(height: 16),
      child,
    ]),
  );
}

// ── Histogram chart ───────────────────────────────────────────────────────────
class _HistogramChart extends StatelessWidget {
  final List<double> bins, seriesA, seriesB;
  final Color colorA, colorB;
  final String labelA, labelB;

  const _HistogramChart({
    required this.bins, required this.seriesA, required this.seriesB,
    required this.colorA, required this.colorB, required this.labelA, required this.labelB,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = [...seriesA, ...seriesB].reduce((a, b) => a > b ? a : b) + 12;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Legend
      Row(children: [
        _dot(colorA), const SizedBox(width: 5),
        Text(labelA, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(width: 14),
        _dot(colorB), const SizedBox(width: 5),
        Text(labelB, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
      ]),
      const SizedBox(height: 14),

      SizedBox(
        height: 210,
        child: BarChart(
          BarChartData(
            maxY: maxY, minY: 0,
            groupsSpace: 3,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                  rod.toY.toInt().toString(),
                  GoogleFonts.spaceMono(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 30,
                getTitlesWidget: (v, _) => Text('${v.toInt()}',
                    style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.textLight)),
              )),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i >= bins.length || i % 3 != 0) return const Text('');
                  return Text(bins[i].toInt().toString(),
                      style: GoogleFonts.spaceMono(fontSize: 8, color: AppColors.textLight));
                },
              )),
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(bins.length, (i) => BarChartGroupData(
              x: i,
              groupVertically: false,
              barRods: [
                BarChartRodData(toY: seriesA[i], color: colorA.withOpacity(0.75), width: 5,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                BarChartRodData(toY: seriesB[i], color: colorB.withOpacity(0.75), width: 5,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
              ],
            )),
          ),
        ),
      ),
    ]);
  }

  Widget _dot(Color c) => Container(
    width: 10, height: 10,
    decoration: BoxDecoration(color: c.withOpacity(0.8), borderRadius: BorderRadius.circular(3)),
  );
}
