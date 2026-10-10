import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/fpv_frequencies.dart';
import '../../core/math/conflict_analyzer.dart';
import '../../core/math/frequency_allocator.dart';
import '../../core/math/grid_auto_resolver.dart';
import '../../core/models/assigned_board.dart';
import '../../core/models/board_type.dart';
import '../../core/models/fleet_drone_slot.dart';
import '../../core/models/fpv_channel.dart';
import 'fleet_state.dart';

export 'fleet_state.dart';

class FleetNotifier extends Notifier<FleetState> {
  final ConflictAnalyzer _analyzer = const ConflictAnalyzer();
  final FrequencyAllocator _allocator = const FrequencyAllocator();
  final GridAutoResolver _resolver = const GridAutoResolver();

  int _nextId = 3;

  static List<ManualDroneSlot> _defaultSlots() => [
    ManualDroneSlot(
      id: 1,
      boardNumber: 1,
      boardType: BoardType.standard,
      channel: FpvFrequencies.bandR[0], // R1: 5658
      isLocked: false,
    ),
    ManualDroneSlot(
      id: 2,
      boardNumber: 2,
      boardType: BoardType.standard,
      channel: FpvFrequencies.bandR[3], // R4: 5769
      isLocked: false,
    ),
  ];

  @override
  FleetState build() {
    final initialSlots = _defaultSlots();
    return FleetState(
      slots: initialSlots,
      conflictReport: _analyzer.analyze(initialSlots),
    );
  }

  void toggleExtendedBands() {
    state = state.copyWith(
      useExtendedBands: !state.useExtendedBands,
      lastStatusMessage: () => null,
    );
    if (state.hasGenerated) {
      calculateOptimalFleet();
    }
  }

  void incrementStandard() {
    if (state.canIncrementStandard) _addSlotOfType(BoardType.standard);
  }

  void decrementStandard() {
    if (state.canDecrementStandard) _removeSlotOfType(BoardType.standard);
  }

  void incrementLowband() {
    if (state.canIncrementLowband) _addSlotOfType(BoardType.lowband);
  }

  void decrementLowband() {
    if (state.canDecrementLowband) _removeSlotOfType(BoardType.lowband);
  }

  void incrementXBand() {
    if (state.canIncrementXBand) _addSlotOfType(BoardType.xBand);
  }

  void decrementXBand() {
    if (state.canDecrementXBand) _removeSlotOfType(BoardType.xBand);
  }

  void _addSlotOfType(BoardType type) {
    final newSlot = ManualDroneSlot(
      id: _nextId++,
      boardNumber: state.slots.length + 1,
      boardType: type,
      channel: null,
      isLocked: false,
    );
    _updateSlotsAndRecalculate([...state.slots, newSlot]);
  }

  void _removeSlotOfType(BoardType type) {
    // Шукаємо останній незаблокований слот відповідного типу
    final index = state.slots.lastIndexWhere(
      (s) => s.boardType == type && !s.isLocked,
    );
    if (index == -1) return;

    final updated = List<FleetDroneSlot>.from(state.slots)..removeAt(index);
    _reindexAndRecalculate(updated);
  }

  void _reindexAndRecalculate(List<FleetDroneSlot> rawSlots) {
    final reindexed = <FleetDroneSlot>[];
    for (int i = 0; i < rawSlots.length; i++) {
      reindexed.add(rawSlots[i].copyWith(boardNumber: i + 1));
    }
    _updateSlotsAndRecalculate(reindexed);
  }

  void _updateSlotsAndRecalculate(List<FleetDroneSlot> newSlots) {
    state = state.copyWith(
      slots: newSlots,
      conflictReport: _analyzer.analyze(newSlots),
      lastStatusMessage: () => null,
    );
    if (state.hasGenerated) {
      calculateOptimalFleet();
    }
  }

  void changeSlotType(int slotId, BoardType newType) {
    final updated = state.slots.map((s) {
      if (s.id == slotId) {
        return s.copyWith(boardType: newType, channel: () => null);
      }
      return s;
    }).toList();
    _reindexAndRecalculate(updated);
  }

  void removeSlot(int slotId) {
    if (state.slots.length <= 1) return;
    final updated = state.slots.where((s) => s.id != slotId).toList();
    _reindexAndRecalculate(updated);
  }

  void toggleLock(int slotId) {
    final updated = state.slots.map((s) {
      if (s.id == slotId) {
        return s.copyWith(isLocked: !s.isLocked);
      }
      return s;
    }).toList();

    state = state.copyWith(slots: updated, lastStatusMessage: () => null);
  }

  void assignChannel(int slotId, FpvChannel? channel) {
    final updated = state.slots.map((s) {
      if (s.id == slotId) {
        return s.copyWith(channel: () => channel);
      }
      return s;
    }).toList();

    state = state.copyWith(
      slots: updated,
      conflictReport: _analyzer.analyze(updated),
      lastStatusMessage: () => null,
    );
  }

  void selectSlot(int? slotId) {
    state = state.copyWith(selectedSlotId: () => slotId);
  }

  Future<void> calculateOptimalFleet() async {
    state = state.copyWith(isCalculating: true, lastStatusMessage: () => null);

    await Future<void>.delayed(Duration.zero);

    final activeSlots = state.slots;
    final result = _allocator.allocateFleetSlots(currentSlots: activeSlots);

    if (result.isSuccess) {
      var updatedSlots = _applyBoards(activeSlots, result.boards);
      var report = _analyzer.analyze(updatedSlots);

      // Якщо в Multi-Band виникли міждіапазонні колізії (Cross-Band IMD3), гармонізуємо їх
      if (report.hasCollisions) {
        final healResult = _resolver.resolve(updatedSlots);
        if (healResult.isSuccess && healResult.changedSlotIds.isNotEmpty) {
          final healedReport = _analyzer.analyze(healResult.resolvedSlots);
          if (healedReport.isClean) {
            updatedSlots = healResult.resolvedSlots;
            report = healedReport;
          }
        }
      }

      state = state.copyWith(
        slots: updatedSlots,
        conflictReport: report,
        hasGenerated: true,
        isCalculating: false,
        lastStatusMessage: () => null,
      );
    } else {
      state = state.copyWith(
        isCalculating: false,
        lastStatusMessage: () => result.errorMessage,
      );
    }
  }

  Future<void> autoHealUnlocked() async {
    state = state.copyWith(isCalculating: true, lastStatusMessage: () => null);

    await Future<void>.delayed(Duration.zero);

    // Tier 0: Pre-flight Locked Conflict Validation
    final lockedSlots = state.slots
        .where((s) => s.isLocked && s.isAssigned)
        .toList();
    final lockedReport = _analyzer.analyze(lockedSlots);
    if (lockedReport.hasCollisions) {
      state = state.copyWith(
        isCalculating: false,
        lastStatusMessage: () =>
            'Неможливо виправити: зафіксовані канали (🔒) конфліктують між собою. '
            'Зніміть блокування хоча б з одного зафіксованого борта.',
      );
      return;
    }

    // Tier 1: Smart Micro-Fix via GridAutoResolver
    final autoResult = _resolver.resolve(state.slots);
    if (autoResult.isSuccess && autoResult.changedSlotIds.isNotEmpty) {
      final updated = autoResult.resolvedSlots;
      final report = _analyzer.analyze(updated);
      if (report.isClean) {
        final count = autoResult.changedSlotIds.length;
        state = state.copyWith(
          slots: updated,
          conflictReport: report,
          hasGenerated: true,
          isCalculating: false,
          lastStatusMessage: () =>
              'Виправлено $count ${count == 1 ? 'борт' : (count < 5 ? 'борти' : 'бортів')}. Сітка безпечна.',
        );
        return;
      }
    }

    // Tier 2: Global Maximin Fallback via FrequencyAllocator
    final allocResult = _allocator.allocateFleetSlots(
      currentSlots: state.slots,
    );
    if (allocResult.isSuccess) {
      final updatedSlots = _applyBoards(state.slots, allocResult.boards);
      state = state.copyWith(
        slots: updatedSlots,
        conflictReport: _analyzer.analyze(updatedSlots),
        hasGenerated: true,
        isCalculating: false,
        lastStatusMessage: () => 'Сітку оптимізовано за алгоритмом Maximin.',
      );
      return;
    }

    // Failure: propagate actionable diagnostic message
    final failMsg =
        autoResult.errorMessage ??
        allocResult.errorMessage ??
        'Не вдалося підібрати безпечні частоти без зміни зафіксованих каналів. '
            'Спробуйте розблокувати частину каналів або активувати розширені діапазони.';

    state = state.copyWith(
      isCalculating: false,
      lastStatusMessage: () => failMsg,
    );
  }

  void resetFleet() {
    _nextId = 3;
    final initialSlots = _defaultSlots();
    state = FleetState(
      slots: initialSlots,
      useExtendedBands: false,
      conflictReport: _analyzer.analyze(initialSlots),
    );
  }

  List<FleetDroneSlot> _applyBoards(
    List<FleetDroneSlot> slots,
    List<AssignedBoard> boards,
  ) => [
    for (int i = 0; i < slots.length; i++)
      slots[i].copyWith(
        boardNumber: boards[i].boardNumber,
        boardType: boards[i].boardType,
        channel: () => boards[i].channel,
      ),
  ];
}

final fleetProvider = NotifierProvider<FleetNotifier, FleetState>(() {
  return FleetNotifier();
});
