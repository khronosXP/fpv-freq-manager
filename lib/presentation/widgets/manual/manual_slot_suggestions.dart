import 'package:flutter/material.dart';
import '../../../core/models/fpv_channel.dart';

class ManualSlotSuggestions extends StatelessWidget {
  final List<FpvChannel> suggestions;
  final ValueChanged<FpvChannel> onSelectSuggestion;

  const ManualSlotSuggestions({
    super.key,
    required this.suggestions,
    required this.onSelectSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(Icons.lightbulb_outline, size: 16, color: colorScheme.secondary),
        const SizedBox(width: 6),
        Text(
          'Заміни:',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((candidate) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    label: Text(
                      '${candidate.code} (${candidate.frequency})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    onPressed: () => onSelectSuggestion(candidate),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
