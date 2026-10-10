import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/fpv_frequencies.dart';
import '../../core/math/conflict_analyzer.dart';
import '../../core/math/frequency_allocator.dart';
import '../../core/models/board_type.dart';
import '../../core/models/fleet_drone_slot.dart';
import '../../core/models/fpv_channel.dart';
import 'fleet_state.dart';

export 'fleet_state.dart';

class FleetNotifier extends Notifier<FleetState> {
  final ConflictAnalyzer _analyzer = const ConflictAnalyzer();
  final FrequencyAllocator _allocator = const FrequencyAllocator();

  int _nextId = 3;

  @override
  FleetState build() {
    final initialSlots = [
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
    if (!state.canIncrementStandard) return;
    final newSlot = ManualDroneSlot(
      id: _nextId++,
      boardNumber: state.slots.length + 1,
      boardType: BoardType.standard,
      channel: null,
      isLocked: false,
    );
    _updateSlotsAndRecalculate([...state.slots, newSlot]);
  }

  void decrementStandard() {
    if (!state.canDecrementStandard) return;
    _removeSlotOfType(BoardType.standard);
  }

  void incrementLowband() {
    if (!state.canIncrementLowband) return;
    final newSlot = ManualDroneSlot(
      id: _nextId++,
      boardNumber: state.slots.length + 1,
      boardType: BoardType.lowband,
      channel: null,
      isLocked: false,
    );
    _updateSlotsAndRecalculate([...state.slots, newSlot]);
  }

  void decrementLowband() {
    if (!state.canDecrementLowband) return;
    _removeSlotOfType(BoardType.lowband);
  }

  void incrementXBand() {
    if (!state.canIncrementXBand) return;
    final newSlot = ManualDroneSlot(
      id: _nextId++,
      boardNumber: state.slots.length + 1,
      boardType: BoardType.xBand,
      channel: null,
      isLocked: false,
    );
    _updateSlotsAndRecalculate([...state.slots, newSlot]);
  }

  void decrementXBand() {
    if (!state.canDecrementXBand) return;
    _removeSlotOfType(BoardType.xBand);
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

    state = state.copyWith(slots: updated);
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

    // Фільтруємо слоти відповідно до активності розширених діапазонів
    final activeSlots = state.useExtendedBands
        ? state.slots
        : state.slots.where((s) => s.boardType == BoardType.standard).toList();

    final result = _allocator.allocateFleetSlots(currentSlots: activeSlots);

    if (result.isSuccess) {
      final updatedSlots = <FleetDroneSlot>[];
      for (int i = 0; i < activeSlots.length; i++) {
        final original = activeSlots[i];
        final assignedBoard = result.boards[i];
        updatedSlots.add(
          original.copyWith(
            boardNumber: assignedBoard.boardNumber,
            boardType: assignedBoard.boardType,
            channel: () => assignedBoard.channel,
          ),
        );
      }

      state = state.copyWith(
        slots: updatedSlots,
        conflictReport: _analyzer.analyze(updatedSlots),
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

  Future<void> autoHealUnlocked() => calculateOptimalFleet();

  void resetFleet() {
    _nextId = 3;
    final initialSlots = [
      ManualDroneSlot(
        id: 1,
        boardNumber: 1,
        boardType: BoardType.standard,
        channel: FpvFrequencies.bandR[0],
        isLocked: false,
      ),
      ManualDroneSlot(
        id: 2,
        boardNumber: 2,
        boardType: BoardType.standard,
        channel: FpvFrequencies.bandR[3],
        isLocked: false,
      ),
    ];
    state = FleetState(
      slots: initialSlots,
      useExtendedBands: false,
      conflictReport: _analyzer.analyze(initialSlots),
    );
  }
}

final fleetProvider = NotifierProvider<FleetNotifier, FleetState>(() {
  return FleetNotifier();
});
