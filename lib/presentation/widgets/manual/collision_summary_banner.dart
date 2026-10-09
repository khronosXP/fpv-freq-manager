import 'package:flutter/material.dart';
import '../../../core/math/conflict_analyzer.dart';

class CollisionSummaryBanner extends StatelessWidget {
  final ConflictReport report;
  final bool isResolving;
  final VoidCallback onAutoResolve;
  final VoidCallback onShowDetails;

  const CollisionSummaryBanner({
    super.key,
    required this.report,
    required this.isResolving,
    required this.onAutoResolve,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (report.isClean) {
      return _buildCleanBanner(colorScheme, theme);
    }
    return _buildCollisionBanner(colorScheme, theme);
  }

  Widget _buildCleanBanner(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: colorScheme.tertiary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'СІТКА БЕЗПЕЧНА (ЧИСТИЙ ЕФІР)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontFamily: 'monospace',
                    color: colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Δf ≥ 40 MHz • IMD3 ≥ 10 MHz • Завад не виявлено',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollisionBanner(ColorScheme colorScheme, ThemeData theme) {
    final directCount = report.directCollisions.length;
    final imdCount = report.imdCollisions.length;
    final tbCount = report.tripleBeatCollisions.length;

    final String summaryText;
    if (tbCount > 0) {
      summaryText =
          'КОЛІЗІЇ: $directCount прямих • $imdCount 2-тон • $tbCount 3-тон';
    } else {
      summaryText = 'КОЛІЗІЇ: $directCount прямих • $imdCount IMD3';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summaryText,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        fontFamily: 'monospace',
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Є загроза взаємного глушіння бортів у польоті',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionButtons(colorScheme),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: onShowDetails,
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.analytics_outlined, size: 16),
          label: const Text('Деталі'),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: isResolving ? null : onAutoResolve,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          icon: isResolving
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.auto_fix_high, size: 16),
          label: Text(
            isResolving ? 'Виправлення...' : 'Автовиправлення',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
