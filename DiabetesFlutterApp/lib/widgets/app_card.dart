import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

// ── Section card ─────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderTopColor;
  const AppCard(
      {super.key, required this.child, this.padding, this.borderTopColor});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: padding ?? const EdgeInsets.all(18),
        decoration: cardDecoration(borderTopColor: borderTopColor),
        child: child,
      );
}

// ── Card section title ────────────────────────────────────────────────────────
class CardTitle extends StatelessWidget {
  final String text;
  const CardTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text.toUpperCase(), style: AppText.cardTitle),
      );
}

// ── Thin divider ─────────────────────────────────────────────────────────────
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(color: Color(0xFFF1F5F9), height: 1));
}

// ── Stepper control ───────────────────────────────────────────────────────────
class StepperField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? unit; // optional unit suffix shown next to the label
  final int value;
  final int min, max, step;
  final ValueChanged<int> onChanged;

  const StepperField({
    super.key,
    required this.label,
    this.hint,
    this.unit,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(label, style: AppText.label),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(unit!,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600)),
              ],
            ]),
            if (hint != null) ...[
              const SizedBox(height: 2),
              Text(hint!,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, color: AppColors.textLight)),
            ],
          ],
        )),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _Btn(
                label: '−',
                onTap: () => onChanged((value - step).clamp(min, max))),
            Container(
              width: 50,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(color: AppColors.border, width: 1.5),
                ),
              ),
              child: Text('$value',
                  style: GoogleFonts.spaceMono(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            _Btn(
                label: '+',
                onTap: () => onChanged((value + step).clamp(min, max))),
          ]),
        ),
      ]);
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 42,
          height: 44,
          child: Center(
            child: Text(label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: AppColors.accent,
                  height: 1,
                )),
          ),
        ),
      );
}

// ── Slider row ────────────────────────────────────────────────────────────────
class SliderRow extends StatelessWidget {
  final String label;
  final String unit;
  final String displayValue;
  final double value, min, max;
  final ValueChanged<double> onChanged;

  const SliderRow({
    super.key,
    required this.label,
    required this.unit,
    required this.displayValue,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: AppText.label),
            RichText(
                text: TextSpan(children: [
              TextSpan(
                text: displayValue,
                style: GoogleFonts.spaceMono(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent),
              ),
              TextSpan(
                text: ' $unit',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight),
              ),
            ])),
          ]),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${min.toInt()}',
                      style: GoogleFonts.spaceMono(
                          fontSize: 9, color: AppColors.textLight)),
                  Text('${max.toInt()}',
                      style: GoogleFonts.spaceMono(
                          fontSize: 9, color: AppColors.textLight)),
                ]),
          ),
        ],
      );
}

// ── Feature importance bar row ────────────────────────────────────────────────
class FeatureBar extends StatelessWidget {
  final String name;
  final double value;
  final double maxValue;

  const FeatureBar(
      {super.key,
      required this.name,
      required this.value,
      required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final pct = (value.abs() / maxValue).clamp(0.0, 1.0);
    final color = value >= 0 ? AppColors.accent : AppColors.textLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(name, style: AppText.label),
          Text(
            '${value >= 0 ? '+' : ''}${value.toStringAsFixed(4)}',
            style: GoogleFonts.spaceMono(
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ]),
    );
  }
}

// ── Metric pill ───────────────────────────────────────────────────────────────
class MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const MetricPill(
      {super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            Text(value,
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textPrimary,
                )),
            const SizedBox(height: 3),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                )),
          ]),
        ),
      );
}
