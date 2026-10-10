import '../../core/math/conflict_analyzer.dart';
import '../../core/models/assigned_board.dart';
import '../../core/models/board_type.dart';
import '../../core/models/fleet_drone_slot.dart';

/// Стан єдиного реактивного полотна флоту (Unified Fleet Canvas).
class FleetState {
  static const int maxTotalBoards = 12;
  static const int maxStandardBoards = 5;
  static const int maxLowbandBoards = 4;
  static const int maxXBandBoards = 3;

  final List<FleetDroneSlot> slots;
  final bool useExtendedBands;
  final ConflictReport conflictReport;
  final bool isCalculating;
  final String? lastStatusMessage;
  final int? selectedSlotId;
  final bool hasGenerated;

  const FleetState({
    required this.slots,
    this.useExtendedBands = false,
    required this.conflictReport,
    this.isCalculating = false,
    this.lastStatusMessage,
    this.selectedSlotId,
    this.hasGenerated = false,
  });

  int get standardCount =>
      slots.where((s) => s.boardType == BoardType.standard).length;
  int get lowbandCount =>
      slots.where((s) => s.boardType == BoardType.lowband).length;
  int get xBandCount =>
      slots.where((s) => s.boardType == BoardType.xBand).length;
  int get totalBoards =>
      standardCount + (useExtendedBands ? (lowbandCount + xBandCount) : 0);

  bool get canIncrementStandard =>
      standardCount < maxStandardBoards && totalBoards < maxTotalBoards;
  bool get canDecrementStandard => standardCount > 1;

  bool get canIncrementLowband =>
      useExtendedBands &&
      lowbandCount < maxLowbandBoards &&
      totalBoards < maxTotalBoards;
  bool get canDecrementLowband => lowbandCount > 0;

  bool get canIncrementXBand =>
      useExtendedBands &&
      xBandCount < maxXBandBoards &&
      totalBoards < maxTotalBoards;
  bool get canDecrementXBand => xBandCount > 0;

  bool get isStandardAtLimit => standardCount >= maxStandardBoards;
  bool get isTotalAtLimit => totalBoards >= maxTotalBoards;

  bool get hasConflicts => conflictReport.hasCollisions;

  List<AssignedBoard> get assignedBoards {
    final boards = <AssignedBoard>[];
    for (int i = 0; i < slots.length; i++) {
      final s = slots[i];
      if (s.channel != null) {
        boards.add(
          AssignedBoard(
            boardNumber: i + 1,
            boardType: s.boardType,
            channel: s.channel!,
          ),
        );
      }
    }
    return boards;
  }

  FleetState copyWith({
    List<FleetDroneSlot>? slots,
    bool? useExtendedBands,
    ConflictReport? conflictReport,
    bool? isCalculating,
    String? Function()? lastStatusMessage,
    int? Function()? selectedSlotId,
    bool? hasGenerated,
  }) {
    return FleetState(
      slots: slots ?? this.slots,
      useExtendedBands: useExtendedBands ?? this.useExtendedBands,
      conflictReport: conflictReport ?? this.conflictReport,
      isCalculating: isCalculating ?? this.isCalculating,
      lastStatusMessage: lastStatusMessage != null
          ? lastStatusMessage()
          : this.lastStatusMessage,
      selectedSlotId: selectedSlotId != null
          ? selectedSlotId()
          : this.selectedSlotId,
      hasGenerated: hasGenerated ?? this.hasGenerated,
    );
  }
}
