import 'package:flutter/material.dart';
import '../../../core/math/conflict_analyzer.dart';

class CollisionDetailDialog extends StatelessWidget {
  final ConflictReport report;

  const CollisionDetailDialog({super.key, required this.report});

  static Future<void> show(BuildContext context, ConflictReport report) {
    return showDialog(
      context: context,
      builder: (context) => CollisionDetailDialog(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(16),
      title: Row(
        children: [
          Icon(Icons.analytics_outlined, color: colorScheme.error, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Звіт радіоколізій',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (report.directCollisions.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Прямі колізії (Δf < 40 МГц)',
                  report.directCollisions.length,
                ),
                const SizedBox(height: 8),
                ...report.directCollisions.map(
                  (c) => _buildDirectItem(c, theme, colorScheme),
                ),
                const SizedBox(height: 16),
              ],
              if (report.imdCollisions.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Інтермодуляція IMD3 (|2f1 - f2 - f3| < 10 МГц)',
                  report.imdCollisions.length,
                ),
                const SizedBox(height: 8),
                ...report.imdCollisions.map(
                  (c) => _buildImdItem(c, theme, colorScheme),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрити'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectItem(
    DirectCollision c,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Борт ${c.slotA.boardNumber} (${c.slotA.channel?.code})',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const Text(' ↔ '),
              Text(
                'Борт ${c.slotB.boardNumber} (${c.slotB.channel?.code})',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Різниця: ${c.delta} МГц (потрібно ≥ 40 МГц, дефіцит: ${40 - c.delta} МГц)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.error,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImdItem(
    ImdCollision c,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2×Б${c.transmitter1.boardNumber} (${c.transmitter1.channel?.code}) - Б${c.transmitter2.boardNumber} (${c.transmitter2.channel?.code}) = ${c.imdFrequency} МГц',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Вражає Борт ${c.victim.boardNumber} (${c.victim.channel?.code}): зазор ${c.distance} МГц (потрібно ≥ 10 МГц)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.error,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
