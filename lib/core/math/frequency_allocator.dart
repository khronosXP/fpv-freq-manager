import '../constants/fpv_frequencies.dart';
import '../models/assigned_board.dart';
import '../models/board_type.dart';
import '../models/fpv_channel.dart';
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
    final total = numStandard + numLowband + numXBand;
    if (total <= 0) {
      return const FrequencyAllocationResult.success([]);
    }

    // 1. Перевірка фізичних меж спектру
    if (total > maxTotalCapacity ||
        numStandard > maxStandardCapacity ||
        numLowband > maxLowbandCapacity ||
        numXBand > maxXBandCapacity) {
      return const FrequencyAllocationResult.failure(
        FrequencyAllocationResult.defaultErrorMessage,
      );
    }

    // 2. Суворі пули каналів (ізоляція без fallback)
    final stdPool = FpvFrequencies.standardChannels;
    final lowPool = List<FpvChannel>.from(FpvFrequencies.lowbandChannels);
    final xPool = FpvFrequencies.xBandChannels;

    // 3. Запобігання міжканальному накладанню на стику Lowband та Standard:
    // L8 (5613 МГц) та E4 (5645 МГц) мають різницю 32 МГц (< 40 МГц).
    // Якщо одночасно запитано Lowband та Standard, виключаємо L8 з пулу,
    // гарантуючи рознос на стику ≥ 72 МГц (L7 5573 до E4 5645).
    if (numStandard > 0 && numLowband > 0) {
      lowPool.removeWhere((ch) => ch.frequency == 5613);
    }

    // 4. Оптимізація кожного діапазону незалежним Maximin-рушієм
    final stdEngine = MaximinEngine(
      minSpacing: 40,
      minImdFloor: numStandard == 6 ? 10.0 : 12.0,
    );
    const lowEngine = MaximinEngine(minSpacing: 40, minImdFloor: 10.0);
    const xEngine = MaximinEngine(minSpacing: 40, minImdFloor: 10.0);

    // Оптимізація Standard 5.8 GHz
    final stdResult = stdEngine.optimize(
      availableChannels: stdPool,
      count: numStandard,
    );
    if (numStandard > 0 && !stdResult.isSuccess) {
      return FrequencyAllocationResult.failure(
        stdResult.errorMessage ?? FrequencyAllocationResult.defaultErrorMessage,
      );
    }

    // Оптимізація Lowband
    final lowResult = lowEngine.optimize(
      availableChannels: lowPool,
      count: numLowband,
    );
    if (numLowband > 0 && !lowResult.isSuccess) {
      return FrequencyAllocationResult.failure(
        lowResult.errorMessage ?? FrequencyAllocationResult.defaultErrorMessage,
      );
    }

    // Оптимізація X-band
    final xResult = xEngine.optimize(availableChannels: xPool, count: numXBand);
    if (numXBand > 0 && !xResult.isSuccess) {
      return FrequencyAllocationResult.failure(
        xResult.errorMessage ?? FrequencyAllocationResult.defaultErrorMessage,
      );
    }

    // 5. Формування підсумкового комплексу бортів із наскрізною нумерацією 1..N
    final boards = <AssignedBoard>[];
    int counter = 1;

    for (final ch in stdResult.channels) {
      boards.add(
        AssignedBoard(
          boardNumber: counter++,
          boardType: BoardType.standard,
          channel: ch,
        ),
      );
    }

    for (final ch in lowResult.channels) {
      boards.add(
        AssignedBoard(
          boardNumber: counter++,
          boardType: BoardType.lowband,
          channel: ch,
        ),
      );
    }

    for (final ch in xResult.channels) {
      boards.add(
        AssignedBoard(
          boardNumber: counter++,
          boardType: BoardType.xBand,
          channel: ch,
        ),
      );
    }

    return FrequencyAllocationResult.success(boards);
  }
}
