import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_mode_provider.dart';
import '../providers/frequency_manager_provider.dart';
import '../providers/manual_config_provider.dart';
import '../views/auto_calculator_view.dart';
import '../views/manual_configurator_view.dart';
import '../widgets/calculator_footer.dart';
import '../widgets/calculator_header_banner.dart';
import '../widgets/quadcopter_logo.dart';

class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentMode = ref.watch(appModeProvider);
    final modeNotifier = ref.read(appModeProvider.notifier);

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
                  _buildModeSelector(
                    context,
                    ref,
                    currentMode,
                    modeNotifier,
                    colorScheme,
                  ),
                  const SizedBox(height: 16),
                  if (currentMode == FpvManagerMode.auto)
                    const AutoCalculatorView()
                  else
                    const ManualConfiguratorView(),
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

  Widget _buildModeSelector(
    BuildContext context,
    WidgetRef ref,
    FpvManagerMode currentMode,
    AppModeNotifier notifier,
    ColorScheme colorScheme,
  ) {
    return SegmentedButton<FpvManagerMode>(
      segments: const [
        ButtonSegment<FpvManagerMode>(
          value: FpvManagerMode.auto,
          icon: Icon(Icons.auto_awesome, size: 18),
          label: Text('Авто-розрахунок'),
        ),
        ButtonSegment<FpvManagerMode>(
          value: FpvManagerMode.manual,
          icon: Icon(Icons.tune, size: 18),
          label: Text('Ручний інспектор'),
        ),
      ],
      selected: {currentMode},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) {
          final newMode = selected.first;
          if (newMode == FpvManagerMode.manual) {
            final autoState = ref.read(frequencyManagerProvider);
            if (autoState.hasGenerated &&
                autoState.result != null &&
                autoState.result!.isSuccess &&
                autoState.result!.boards.isNotEmpty) {
              ref
                  .read(manualConfigProvider.notifier)
                  .syncWithAllocationIfUntouched(autoState.result!.boards);
            }
          }
          notifier.setMode(newMode);
        }
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
