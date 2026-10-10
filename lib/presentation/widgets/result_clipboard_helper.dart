import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/assigned_board.dart';

class ResultClipboardHelper {
  ResultClipboardHelper._();

  static void copyToClipboard(
    BuildContext context,
    List<AssignedBoard> boards,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('=== СІТКА ЧАСТОТ FPV // ДИЗАРМЕРИ Ф-22 ===');
    for (final b in boards) {
      buffer.writeln(
        'Борт ${b.boardNumber}: ${b.channel.code} (${b.channel.frequency} MHz) [${b.boardType.displayName}]',
      );
    }
    buffer.writeln('==========================================');
    buffer.writeln('Δf ≥ 40 MHz • IMD3 ≥ 12 MHz • RHCP');
    Clipboard.setData(ClipboardData(text: buffer.toString()));

    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(milliseconds: 2500),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(Icons.check, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'СІТКУ ЧАСТОТ СКОПІЙОВАНО',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${boards.length} ${pluralBoards(boards.length)} у буфері обміну (готово до вставки)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String pluralBoards(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 19) return 'бортів';
    if (mod10 == 1) return 'борт';
    if (mod10 >= 2 && mod10 <= 4) return 'борти';
    return 'бортів';
  }
}
