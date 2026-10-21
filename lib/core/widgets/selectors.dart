import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SelectorOption<T> {
  const SelectorOption(this.value, this.label);

  final T value;
  final String label;
}

/// Pill segmented control (category product groups, giveaway tabs).
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<SelectorOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.segmentTrack,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        for (final option in options)
          Expanded(
            child: Semantics(
              button: true,
              selected: option.value == selected,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: () => onChanged(option.value),
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option.value == selected ? AppColors.violet : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: option.value == selected
                            ? Colors.white
                            : AppColors.segmentInactiveText,
                        fontSize: 13,
                        fontWeight: option.value == selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Row of filter pills (My Orders / My Giveaways filters).
class FilterPills<T> extends StatelessWidget {
  const FilterPills({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<SelectorOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < options.length; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: Semantics(
            button: true,
            selected: options[i].value == selected,
            child: Material(
              color: options[i].value == selected ? AppColors.violet : AppColors.chipTrack,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                key: ValueKey('filter-${options[i].value}'),
                borderRadius: BorderRadius.circular(24),
                onTap: () => onChanged(options[i].value),
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        options[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: options[i].value == selected ? Colors.white : AppColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}
