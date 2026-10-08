import 'package:flutter/material.dart';

class BoardCounterCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final bool canIncrement;
  final bool canDecrement;
  final String? limitMessage;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final Color? accentColor;
  final bool monospaceSubtitle;

  const BoardCounterCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
    this.canIncrement = true,
    this.canDecrement = true,
    this.limitMessage,
    this.onIncrement,
    this.onDecrement,
    this.accentColor,
    this.monospaceSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveAccent = accentColor ?? colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Left: Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: effectiveAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: monospaceSubtitle ? 'monospace' : null,
                          fontSize: monospaceSubtitle ? 11 : null,
                          letterSpacing: monospaceSubtitle ? 0.3 : null,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right: [-] Counter [+]
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: canDecrement ? onDecrement : null,
                        icon: const Icon(Icons.remove, size: 18),
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: canDecrement
                              ? colorScheme.surfaceContainerHighest
                              : colorScheme.surface.withValues(alpha: 0.3),
                          foregroundColor: canDecrement
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.2),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 40),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        child: Text(
                          '$count',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: count > 0
                                ? effectiveAccent
                                : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: canIncrement ? onIncrement : null,
                        icon: const Icon(Icons.add, size: 18),
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: canIncrement
                              ? effectiveAccent.withValues(alpha: 0.15)
                              : colorScheme.surface.withValues(alpha: 0.3),
                          foregroundColor: canIncrement
                              ? effectiveAccent
                              : colorScheme.onSurface.withValues(alpha: 0.2),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (limitMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 13,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        limitMessage!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
