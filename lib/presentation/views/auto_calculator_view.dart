import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_mode_provider.dart';
import '../providers/frequency_manager_provider.dart';
import '../providers/manual_config_provider.dart';
import '../widgets/board_counter_card.dart';
import '../widgets/extended_bands_section.dart';
import '../widgets/result_cheat_sheet.dart';
import '../widgets/rf_spectrum_chart.dart';

class AutoCalculatorView extends ConsumerWidget {
  const AutoCalculatorView({super.key});

  static String pluralBoards(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 19) return 'бортів';
    if (mod10 == 1) return 'борт';
    if (mod10 >= 2 && mod10 <= 4) return 'борти';
    return 'бортів';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(frequencyManagerProvider);
    final notifier = ref.read(frequencyManagerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStandardCounter(state, notifier, colorScheme),
        if (state.standardCount >= 6 && !state.useExtendedBands)
          _buildStandardLimitTip(colorScheme, theme.textTheme),
        ExtendedBandsSection(state: state, notifier: notifier),
        if (state.isTotalAtLimit) _buildTotalLimitNotice(colorScheme, theme),
        const SizedBox(height: 14),
        _buildGenerateButton(state, notifier, colorScheme, theme),
        const SizedBox(height: 16),
        _buildResultsSection(context, ref, state, notifier, colorScheme, theme),
      ],
    );
  }

  Widget _buildStandardCounter(
    FrequencyManagerState state,
    FrequencyManagerNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return BoardCounterCard(
      title: 'Стандартні борти (A, B, E, F, R)',
      subtitle: 'Сітки 5.8 GHz • 40 каналів',
      count: state.standardCount,
      canIncrement: state.canIncrementStandard,
      canDecrement: state.canDecrementStandard,
      monospaceSubtitle: true,
      limitMessage: state.isStandardAtLimit
          ? 'Ліміт 5.8 GHz: макс. 5 без завад'
          : null,
      onIncrement: notifier.incrementStandard,
      onDecrement: notifier.decrementStandard,
      accentColor: colorScheme.primary,
    );
  }

  Widget _buildTotalLimitNotice(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Досягнуто загальний ліміт: 12 бортів (сумарно для комплексу)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardLimitTip(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6, left: 4),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 15, color: colorScheme.secondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Понад 6 бортів: увімкніть розширені діапазони нижче',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(
    FrequencyManagerState state,
    FrequencyManagerNotifier notifier,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isBusy = state.isCalculating;
    return ElevatedButton(
      onPressed: (state.totalBoards > 0 && !isBusy) ? notifier.generate : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: isBusy
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Розрахунок сітки...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.tune),
                const SizedBox(width: 8),
                Text(
                  state.totalBoards > 0
                      ? 'Розрахувати сітку (${state.totalBoards} ${pluralBoards(state.totalBoards)})'
                      : 'Оберіть кількість бортів',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResultsSection(
    BuildContext context,
    WidgetRef ref,
    FrequencyManagerState state,
    FrequencyManagerNotifier notifier,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    if (!state.hasGenerated || state.result == null) {
      return const SizedBox.shrink();
    }

    if (!state.result!.isSuccess) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.result!.errorMessage ?? 'Помилка розрахунку',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final boards = state.result!.boards;

    return Column(
      children: [
        RfSpectrumChart(
          boards: boards,
          selectedBoardNumber: state.selectedBoardNumber,
          onSelectBoard: notifier.selectBoard,
        ),
        const SizedBox(height: 8),
        ResultCheatSheet(
          boards: boards,
          selectedBoardNumber: state.selectedBoardNumber,
          onSelectBoard: notifier.selectBoard,
          onReset: notifier.reset,
        ),
        const SizedBox(height: 12),
        // Bridge button to open allocation in manual configurator
        OutlinedButton.icon(
          onPressed: () {
            ref
                .read(manualConfigProvider.notifier)
                .importFromAllocation(boards);
            ref.read(appModeProvider.notifier).setMode(FpvManagerMode.manual);
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(Icons.edit_note, color: colorScheme.primary),
          label: Text(
            'Налаштувати або зафіксувати в ручному режимі',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
