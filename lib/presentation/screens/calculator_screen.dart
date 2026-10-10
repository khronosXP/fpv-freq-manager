import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fleet_provider.dart';
import '../widgets/calculator_footer.dart';
import '../widgets/calculator_header_banner.dart';
import '../widgets/fleet/fleet_action_bar.dart';
import '../widgets/fleet/fleet_counters_section.dart';
import '../widgets/fleet/fleet_grid.dart';
import '../widgets/manual/collision_detail_dialog.dart';
import '../widgets/manual/collision_summary_banner.dart';
import '../widgets/quadcopter_logo.dart';
import '../widgets/result_cheat_sheet.dart';
import '../widgets/rf_spectrum_chart.dart';

class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(fleetProvider);
    final notifier = ref.read(fleetProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 68,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                QuadcopterLogo(size: 22, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Менеджер відеочастот FPV',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'від команди Дизармерів Ф-22',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CalculatorHeaderBanner(),
                  const SizedBox(height: 14),

                  // 1. Блок налаштування флоту (лічильники бортів)
                  const FleetCountersSection(),
                  const SizedBox(height: 14),

                  // 2. Панель дій (кнопка розрахунку та статус безпеки)
                  const FleetActionBar(),
                  const SizedBox(height: 14),

                  // 3. Банер колізій (1-click автовиправлення)
                  CollisionSummaryBanner(
                    report: state.conflictReport,
                    isResolving: state.isCalculating,
                    onAutoResolve: notifier.autoHealUnlocked,
                    onShowDetails: () => CollisionDetailDialog.show(
                      context,
                      state.conflictReport,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4. Інтерактивна матриця бортів (замки 🔒, вибір частот)
                  const FleetGrid(),
                  const SizedBox(height: 20),

                  // 5. Графік радіочастотного спектра та чітшит
                  if (state.assignedBoards.isNotEmpty) ...[
                    RfSpectrumChart(
                      boards: state.assignedBoards,
                      selectedBoardNumber: state.selectedSlotId,
                      onSelectBoard: notifier.selectSlot,
                    ),
                    const SizedBox(height: 20),
                    ResultCheatSheet(
                      boards: state.assignedBoards,
                      selectedBoardNumber: state.selectedSlotId,
                      onSelectBoard: notifier.selectSlot,
                      onReset: notifier.resetFleet,
                    ),
                  ],

                  const SizedBox(height: 28),
                  const CalculatorFooter(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
