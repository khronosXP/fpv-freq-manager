import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/fpv_frequencies.dart';
import '../../core/math/conflict_analyzer.dart';
import '../../core/math/grid_auto_resolver.dart';
import '../../core/models/assigned_board.dart';
import '../../core/models/board_type.dart';
import '../../core/models/fpv_channel.dart';
import '../../core/models/manual_drone_slot.dart';

class ManualConfigState {
  static const int maxTotalBoards = 12;

  final List<ManualDroneSlot> slots;
  final ConflictReport conflictReport;
  final String? lastStatusMessage;
  final int? selectedSlotId;
  final bool isResolving;
  final bool isUserCustomized;

  const ManualConfigState({
    required this.slots,
    required this.conflictReport,
    this.lastStatusMessage,
    this.selectedSlotId,
    this.isResolving = false,
    this.isUserCustomized = false,
  });

  bool get canAddSlot => slots.length < maxTotalBoards;
  bool get canRemoveSlot => slots.length > 1;

  ManualConfigState copyWith({
    List<ManualDroneSlot>? slots,
    ConflictReport? conflictReport,
    String? Function()? lastStatusMessage,
    int? Function()? selectedSlotId,
    bool? isResolving,
    bool? isUserCustomized,
  }) {
    return ManualConfigState(
      slots: slots ?? this.slots,
      conflictReport: conflictReport ?? this.conflictReport,
      lastStatusMessage: lastStatusMessage != null
          ? lastStatusMessage()
          : this.lastStatusMessage,
      selectedSlotId: selectedSlotId != null
          ? selectedSlotId()
          : this.selectedSlotId,
      isResolving: isResolving ?? this.isResolving,
      isUserCustomized: isUserCustomized ?? this.isUserCustomized,
    );
  }
}

class ManualConfigNotifier extends Notifier<ManualConfigState> {
  final ConflictAnalyzer _analyzer = const ConflictAnalyzer();
  late final GridAutoResolver _resolver = GridAutoResolver(analyzer: _analyzer);

  int _nextId = 3;

  @override
  ManualConfigState build() {
    // Початковий стан: 2 стандартні борти (R1 та R4 - чиста пара)
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

    return ManualConfigState(
      slots: initialSlots,
      conflictReport: _analyzer.analyze(initialSlots),
    );
  }

  void addSlot([BoardType type = BoardType.standard]) {
    if (!state.canAddSlot) return;

    final newSlotId = _nextId++;
    final newBoardNumber = state.slots.length + 1;

    // Підбираємо перший канал за замовчуванням
    final defaultChannel = _getDefaultChannelForType(type);

    final updated = [
      ...state.slots,
      ManualDroneSlot(
        id: newSlotId,
        boardNumber: newBoardNumber,
        boardType: type,
        channel: defaultChannel,
        isLocked: false,
      ),
    ];

    state = state.copyWith(
      slots: updated,
      conflictReport: _analyzer.analyze(updated),
      lastStatusMessage: () => null,
      isUserCustomized: true,
    );
  }

  void removeSlot(int slotId) {
    if (!state.canRemoveSlot) return;

    final filtered = state.slots.where((s) => s.id != slotId).toList();
    // Переіндексація номерів бортів (1..N)
    final reindexed = List.generate(
      filtered.length,
      (i) => filtered[i].copyWith(boardNumber: i + 1),
    );

    state = state.copyWith(
      slots: reindexed,
      conflictReport: _analyzer.analyze(reindexed),
      lastStatusMessage: () => null,
      selectedSlotId: state.selectedSlotId == slotId ? () => null : null,
      isUserCustomized: true,
    );
  }

  void setSlotChannel(int slotId, FpvChannel channel) {
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
      isUserCustomized: true,
    );
  }

  void toggleSlotLock(int slotId) {
    final updated = state.slots.map((s) {
      if (s.id == slotId) {
        return s.copyWith(isLocked: !s.isLocked);
      }
      return s;
    }).toList();

    state = state.copyWith(
      slots: updated,
      conflictReport: _analyzer.analyze(updated),
      isUserCustomized: true,
    );
  }

  void changeSlotType(int slotId, BoardType type) {
    final updated = state.slots.map((s) {
      if (s.id == slotId) {
        final currentChannel = s.channel;
        // Перевіряємо чи поточний канал сумісний з новим типом
        final isCompatible = _isChannelCompatibleWithType(currentChannel, type);
        return s.copyWith(
          boardType: type,
          channel: () =>
              isCompatible ? currentChannel : _getDefaultChannelForType(type),
        );
      }
      return s;
    }).toList();

    state = state.copyWith(
      slots: updated,
      conflictReport: _analyzer.analyze(updated),
      lastStatusMessage: () => null,
      isUserCustomized: true,
    );
  }

  void selectSlot(int? slotId) {
    state = state.copyWith(
      selectedSlotId: () => state.selectedSlotId == slotId ? null : slotId,
    );
  }

  void autoResolveConflicts() {
    if (state.conflictReport.isClean) {
      state = state.copyWith(
        lastStatusMessage: () => 'Сітка вже чиста, завад не виявлено',
      );
      return;
    }

    state = state.copyWith(isResolving: true);
    final result = _resolver.resolve(state.slots);

    if (result.isSuccess) {
      final newReport = _analyzer.analyze(result.resolvedSlots);
      final count = result.changedSlotIds.length;
      state = state.copyWith(
        slots: result.resolvedSlots,
        conflictReport: newReport,
        isResolving: false,
        lastStatusMessage: () => count > 0
            ? 'Виправлено $count ${count == 1 ? "борт" : "бортів"}. Сітка безпечна.'
            : 'Сітка успішно верифікована.',
      );
    } else {
      state = state.copyWith(
        isResolving: false,
        lastStatusMessage: () => result.errorMessage ?? 'Помилка оптимізації',
      );
    }
  }

  void importFromAllocation(
    List<AssignedBoard> boards, {
    bool markCustomized = true,
  }) {
    if (boards.isEmpty) return;

    final imported = List.generate(
      boards.length,
      (i) => ManualDroneSlot(
        id: _nextId++,
        boardNumber: i + 1,
        boardType: boards[i].boardType,
        channel: boards[i].channel,
        isLocked: false,
      ),
    );

    state = state.copyWith(
      slots: imported,
      conflictReport: _analyzer.analyze(imported),
      isUserCustomized: markCustomized,
      lastStatusMessage: () =>
          'Імпортовано ${imported.length} бортів із авто-розрахунку',
    );
  }

  /// Автоматично підтягує розраховані борти, якщо користувач ще не змінював слоти вручну
  bool syncWithAllocationIfUntouched(List<AssignedBoard> boards) {
    if (boards.isEmpty) return false;
    if (!state.isUserCustomized || state.slots.length <= 2) {
      importFromAllocation(boards, markCustomized: false);
      return true;
    }
    return false;
  }

  void resetToCleanPair() {
    final initialSlots = [
      ManualDroneSlot(
        id: _nextId++,
        boardNumber: 1,
        boardType: BoardType.standard,
        channel: FpvFrequencies.bandR[0],
        isLocked: false,
      ),
      ManualDroneSlot(
        id: _nextId++,
        boardNumber: 2,
        boardType: BoardType.standard,
        channel: FpvFrequencies.bandR[3],
        isLocked: false,
      ),
    ];

    state = ManualConfigState(
      slots: initialSlots,
      conflictReport: _analyzer.analyze(initialSlots),
      isUserCustomized: false,
    );
  }

  FpvChannel _getDefaultChannelForType(BoardType type) {
    switch (type) {
      case BoardType.standard:
        return FpvFrequencies.bandR[0];
      case BoardType.lowband:
        return FpvFrequencies.bandL[0];
      case BoardType.xBand:
        return FpvFrequencies.bandX[0];
    }
  }

  bool _isChannelCompatibleWithType(FpvChannel? ch, BoardType type) {
    if (ch == null) return false;
    switch (type) {
      case BoardType.standard:
        return ch.category == BandCategory.standard;
      case BoardType.lowband:
        return ch.category == BandCategory.lowband ||
            ch.category == BandCategory.standard;
      case BoardType.xBand:
        return ch.category == BandCategory.xBand ||
            ch.category == BandCategory.standard;
    }
  }
}

final manualConfigProvider =
    NotifierProvider<ManualConfigNotifier, ManualConfigState>(
      ManualConfigNotifier.new,
    );
