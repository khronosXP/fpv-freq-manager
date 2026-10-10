import '../constants/fpv_frequencies.dart';
import '../models/assigned_board.dart';
import '../models/board_type.dart';
import '../models/fpv_channel.dart';
import '../models/manual_drone_slot.dart';
import 'optimizer/maximin_engine.dart';

class FrequencyAllocationResult {
  final bool isSuccess;
  final List<AssignedBoard> boards;
  final String? errorMessage;

  const FrequencyAllocationResult.success(this.boards)
    : isSuccess = true,
      errorMessage = null;

  const FrequencyAllocationResult.failure(this.errorMessage)
    : isSuccess = false,
      boards = const [];

  static const String defaultErrorMessage =
      'Неможливо підібрати чисті частоти для заданої кількості бортів. '
      'Зменшіть кількість бортів або активуйте розширені діапазони.';
}

class FrequencyAllocator {
  const FrequencyAllocator();

  /// Максимальна фізична місткість за діапазонами
  static const int maxStandardCapacity = 6;
  static const int maxLowbandCapacity = 4;
  static const int maxXBandCapacity = 3;
  static const int maxTotalCapacity = 12;

  /// Обчислює оптимальний розподіл частот за архітектурою Maximin Engine Optimizer
  /// із суворою ізоляцією діапазонів (Strict Band Isolation).
  FrequencyAllocationResult allocate({
    required int numStandard,
    required int numLowband,
    required int numXBand,
  }) {
    final slots = <ManualDroneSlot>[];
    int id = 1;
    for (int i = 0; i < numStandard; i++) {
      slots.add(
        ManualDroneSlot(
          id: id,
          boardNumber: id++,
          boardType: BoardType.standard,
        ),
      );
    }
    for (int i = 0; i < numLowband; i++) {
      slots.add(
        ManualDroneSlot(
          id: id,
          boardNumber: id++,
          boardType: BoardType.lowband,
        ),
      );
    }
    for (int i = 0; i < numXBand; i++) {
      slots.add(
        ManualDroneSlot(id: id, boardNumber: id++, boardType: BoardType.xBand),
      );
    }
    return allocateFleetSlots(currentSlots: slots);
  }

  /// Обчислює оптимальний розподіл частот для списку слотів із урахуванням зафіксованих каналів (🔒).
  FrequencyAllocationResult allocateFleetSlots({
    required List<ManualDroneSlot> currentSlots,
  }) {
    if (currentSlots.isEmpty) {
      return const FrequencyAllocationResult.success([]);
    }

    final stdSlots = currentSlots
        .where((s) => s.boardType == BoardType.standard)
        .toList();
    final lowSlots = currentSlots
        .where((s) => s.boardType == BoardType.lowband)
        .toList();
    final xSlots = currentSlots
        .where((s) => s.boardType == BoardType.xBand)
        .toList();

    final stdCount = stdSlots.length;
    final lowCount = lowSlots.length;
    final xCount = xSlots.length;
    final total = stdCount + lowCount + xCount;

    if (total > maxTotalCapacity ||
        stdCount > maxStandardCapacity ||
        lowCount > maxLowbandCapacity ||
        xCount > maxXBandCapacity) {
      return const FrequencyAllocationResult.failure(
        FrequencyAllocationResult.defaultErrorMessage,
      );
    }

    final stdLocked = stdSlots
        .where((s) => s.isLocked && s.channel != null)
        .map((s) => s.channel!)
        .toList();
    final lowLocked = lowSlots
        .where((s) => s.isLocked && s.channel != null)
        .map((s) => s.channel!)
        .toList();
    final xLocked = xSlots
        .where((s) => s.isLocked && s.channel != null)
        .map((s) => s.channel!)
        .toList();

    final stdPool = List<FpvChannel>.from(FpvFrequencies.standardChannels);
    final lowPool = List<FpvChannel>.from(FpvFrequencies.lowbandChannels);
    final xPool = FpvFrequencies.xBandChannels;

    // Гранична фільтрація стику Lowband та Standard
    final hasLockedL8 = lowLocked.any((ch) => ch.frequency == 5613);
    if (hasLockedL8) {
      stdPool.removeWhere((ch) => ch.frequency < 5653);
    } else if (stdCount > 0 && lowCount > 0) {
      lowPool.removeWhere((ch) => ch.frequency == 5613);
    }

    final stdEngine = MaximinEngine(
      minSpacing: 40,
      minImdFloor: stdCount == 6 ? 10.0 : 12.0,
    );
    const lowEngine = MaximinEngine(minSpacing: 40, minImdFloor: 10.0);
    const xEngine = MaximinEngine(minSpacing: 40, minImdFloor: 10.0);

    final stdResult = stdEngine.optimize(
      availableChannels: stdPool,
      count: stdCount,
      lockedChannels: stdLocked,
    );
    if (stdCount > 0 && !stdResult.isSuccess) {
      return FrequencyAllocationResult.failure(
        stdResult.errorMessage ?? FrequencyAllocationResult.defaultErrorMessage,
      );
    }

    final lowResult = lowEngine.optimize(
      availableChannels: lowPool,
      count: lowCount,
      lockedChannels: lowLocked,
    );
    if (lowCount > 0 && !lowResult.isSuccess) {
      return FrequencyAllocationResult.failure(
        lowResult.errorMessage ?? FrequencyAllocationResult.defaultErrorMessage,
      );
    }

    final xResult = xEngine.optimize(
      availableChannels: xPool,
      count: xCount,
      lockedChannels: xLocked,
    );
    if (xCount > 0 && !xResult.isSuccess) {
      return FrequencyAllocationResult.failure(
        xResult.errorMessage ?? FrequencyAllocationResult.defaultErrorMessage,
      );
    }

    // Розподіляємо обчислені канали по слотах
    final stdFreeChannels = stdResult.channels
        .where((ch) => !stdLocked.any((l) => l.frequency == ch.frequency))
        .toList();
    final lowFreeChannels = lowResult.channels
        .where((ch) => !lowLocked.any((l) => l.frequency == ch.frequency))
        .toList();
    final xFreeChannels = xResult.channels
        .where((ch) => !xLocked.any((l) => l.frequency == ch.frequency))
        .toList();

    int stdFreeIdx = 0;
    int lowFreeIdx = 0;
    int xFreeIdx = 0;

    final updatedBoards = <AssignedBoard>[];
    for (int i = 0; i < currentSlots.length; i++) {
      final slot = currentSlots[i];
      FpvChannel assignedCh;
      if (slot.isLocked && slot.channel != null) {
        assignedCh = slot.channel!;
      } else {
        switch (slot.boardType) {
          case BoardType.standard:
            assignedCh = stdFreeChannels[stdFreeIdx++];
          case BoardType.lowband:
            assignedCh = lowFreeChannels[lowFreeIdx++];
          case BoardType.xBand:
            assignedCh = xFreeChannels[xFreeIdx++];
        }
      }
      updatedBoards.add(
        AssignedBoard(
          boardNumber: i + 1,
          boardType: slot.boardType,
          channel: assignedCh,
        ),
      );
    }

    return FrequencyAllocationResult.success(updatedBoards);
  }
}
