import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/nannies_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  final NannyFilter currentFilter;
  final void Function(NannyFilter) onApply;

  const FilterBottomSheet({super.key, required this.currentFilter, required this.onApply});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _rateRange;
  String? _language;
  String? _skill;
  int? _minYears;
  double? _minRating;

  static const double _minRate = 20;
  static const double _maxRate = 200;

  @override
  void initState() {
    super.initState();
    _rateRange = RangeValues(
      (widget.currentFilter.minRate ?? _minRate).toDouble(),
      (widget.currentFilter.maxRate ?? _maxRate).toDouble(),
    );
    _language = widget.currentFilter.language;
    _skill = widget.currentFilter.skill;
    _minYears = widget.currentFilter.minYears;
    _minRating = widget.currentFilter.minRating;
  }

  void _apply() {
    final filter = widget.currentFilter.copyWith(
      minRate: _rateRange.start > _minRate ? _rateRange.start.toInt() : null,
      maxRate: _rateRange.end < _maxRate ? _rateRange.end.toInt() : null,
      language: _language,
      skill: _skill,
      minYears: _minYears,
      minRating: _minRating,
    );
    widget.onApply(filter);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _rateRange = const RangeValues(_minRate, _maxRate);
      _language = null;
      _skill = null;
      _minYears = null;
      _minRating = null;
    });
    widget.onApply(const NannyFilter());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  TextButton(onPressed: _reset, child: const Text('Reset all')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Price range
                  _Section(title: 'Hourly Rate (₪)', child: Column(
                    children: [
                      RangeSlider(
                        values: _rateRange,
                        min: _minRate, max: _maxRate,
                        divisions: 18,
                        activeColor: AppColors.primary,
                        labels: RangeLabels('₪${_rateRange.start.toInt()}', '₪${_rateRange.end.toInt()}'),
                        onChanged: (v) => setState(() => _rateRange = v),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₪${_rateRange.start.toInt()}/hr', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('₪${_rateRange.end.toInt()}/hr', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  )),

                  // Min rating
                  _Section(title: 'Minimum Rating', child: Wrap(
                    spacing: 8,
                    children: [null, 3.0, 3.5, 4.0, 4.5].map((r) => _FilterChip(
                      label: r == null ? 'Any' : '${r}★',
                      selected: _minRating == r,
                      onTap: () => setState(() => _minRating = r),
                    )).toList(),
                  )),

                  // Min years experience
                  _Section(title: 'Min. Experience', child: Wrap(
                    spacing: 8,
                    children: [null, 1, 2, 3, 5, 8].map((y) => _FilterChip(
                      label: y == null ? 'Any' : '$y+ yrs',
                      selected: _minYears == y,
                      onTap: () => setState(() => _minYears = y),
                    )).toList(),
                  )),

                  // Language
                  _Section(title: 'Language', child: Wrap(
                    spacing: 8,
                    children: AppConstants.languages.map((l) => _FilterChip(
                      label: l,
                      selected: _language == l,
                      onTap: () => setState(() => _language = _language == l ? null : l),
                    )).toList(),
                  )),

                  // Skill
                  _Section(title: 'Specialization', child: Wrap(
                    spacing: 8,
                    children: AppConstants.skills.take(10).map((s) => _FilterChip(
                      label: s,
                      selected: _skill == s,
                      onTap: () => setState(() => _skill = _skill == s ? null : s),
                    )).toList(),
                  )),

                  const SizedBox(height: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: AppButton(label: 'Apply Filters', onTap: _apply),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}
