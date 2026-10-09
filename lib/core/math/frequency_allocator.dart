import '../constants/fpv_frequencies.dart';
import '../models/assigned_board.dart';
import '../models/board_type.dart';
import '../models/fpv_channel.dart';
import 'imd_validator.dart';

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

  /// Вычисляет оптимальное распределение частот для заданного количества бортов.
  FrequencyAllocationResult allocate({
    required int numStandard,
    required int numLowband,
    required int numXBand,
  }) {
    final total = numStandard + numLowband + numXBand;
    if (total <= 0) {
      return const FrequencyAllocationResult.success([]);
    }

    // Фізичні ліміти радіофізики:
    // 1. Стандартні сітки 5.8 ГГц — максимум 6 бортів.
    // 2. Повний комплекс з урахуванням тритонового IMD3 (Triple-Beat >= 10 МГц)
    //    теоретично вміщує максимум 9 одночасних бортів.
    if (total > 9 || numStandard > 6) {
      return const FrequencyAllocationResult.failure(
        FrequencyAllocationResult.defaultErrorMessage,
      );
    }

    // 6 стандартних бортів займають весь спектр 5.8 ГГц (E4, R2, A6, A4, A1, E8).
    // Комбінація 6 стандартних бортів з >= 2 розширеними бортами математично
    // утворює неминучий інтермодуляційний конфлікт 3-го порядку (Triple-Beat).
    if (numStandard == 6 && (numLowband >= 2 || numXBand >= 2 || total > 7)) {
      return const FrequencyAllocationResult.failure(
        'Неможливо підібрати чисті частоти для 6 стандартних бортів та розширених діапазонів '
        'без інтермодуляції 3-го порядку (Triple-Beat). Переведіть 1-2 стандартні борти на Lowband або X-Band.',
      );
    }

    // Составляем упорядоченный список слотов для назначения:
    // Сначала стандартные борты (наиболее жесткие ограничения — только стандартные сетки),
    // Затем Lowband, затем X-band.
    final slots = <_SlotRequest>[];
    int boardCounter = 1;

    for (int i = 0; i < numStandard; i++) {
      slots.add(
        _SlotRequest(
          boardNumber: boardCounter++,
          boardType: BoardType.standard,
          allowedCategories: const [BandCategory.standard],
        ),
      );
    }
    for (int i = 0; i < numLowband; i++) {
      slots.add(
        _SlotRequest(
          boardNumber: boardCounter++,
          boardType: BoardType.lowband,
          allowedCategories: const [
            BandCategory.lowband,
            BandCategory.standard,
          ],
        ),
      );
    }
    for (int i = 0; i < numXBand; i++) {
      slots.add(
        _SlotRequest(
          boardNumber: boardCounter++,
          boardType: BoardType.xBand,
          allowedCategories: const [BandCategory.xBand, BandCategory.standard],
        ),
      );
    }

    // Подготавливаем списки кандидатов для каждого типа
    final candidatesBySlot = slots.map((slot) {
      return _getCandidatesForSlot(slot.boardType);
    }).toList();

    final chosenChannels = <FpvChannel>[];
    final chosenFrequencies = <int>[];
    final usedChannelCodes = <String>{};

    final tiers = (total <= 6 && numStandard < 6)
        ? const [15, 12]
        : (numStandard == 6 ? const [10] : const [12, 10]);

    bool found = false;
    for (final minImd in tiers) {
      chosenChannels.clear();
      chosenFrequencies.clear();
      usedChannelCodes.clear();

      found = _backtrack(
        slotIndex: 0,
        slots: slots,
        candidatesBySlot: candidatesBySlot,
        chosenChannels: chosenChannels,
        chosenFrequencies: chosenFrequencies,
        usedChannelCodes: usedChannelCodes,
        lastCandidateIndex: -1,
        minDistance: minImd,
      );
      if (found) break;
    }

    if (!found) {
      return const FrequencyAllocationResult.failure(
        FrequencyAllocationResult.defaultErrorMessage,
      );
    }

    // Успешный результат
    final result = <AssignedBoard>[];
    for (int i = 0; i < slots.length; i++) {
      result.add(
        AssignedBoard(
          boardNumber: slots[i].boardNumber,
          boardType: slots[i].boardType,
          channel: chosenChannels[i],
        ),
      );
    }

    return FrequencyAllocationResult.success(result);
  }

  static final List<FpvChannel> _sortedStandardChannels = () {
    final seenFreqs = <int>{};
    final unique = <FpvChannel>[];
    for (final ch in FpvFrequencies.standardChannels) {
      if (seenFreqs.add(ch.frequency)) {
        unique.add(ch);
      }
    }
    unique.sort((a, b) => a.frequency.compareTo(b.frequency));
    return List<FpvChannel>.unmodifiable(unique);
  }();

  static final List<FpvChannel> _sortedLowbandChannels = () {
    final seenFreqs = <int>{};
    final unique = <FpvChannel>[];
    for (final ch in [
      ...FpvFrequencies.lowbandChannels,
      ...FpvFrequencies.standardChannels,
    ]) {
      if (seenFreqs.add(ch.frequency)) {
        unique.add(ch);
      }
    }
    unique.sort((a, b) => a.frequency.compareTo(b.frequency));
    return List<FpvChannel>.unmodifiable(unique);
  }();

  static final List<FpvChannel> _sortedXBandChannels = () {
    final seenFreqs = <int>{};
    final unique = <FpvChannel>[];
    for (final ch in [
      ...FpvFrequencies.xBandChannels,
      ...FpvFrequencies.standardChannels,
    ]) {
      if (seenFreqs.add(ch.frequency)) {
        unique.add(ch);
      }
    }
    unique.sort((a, b) => a.frequency.compareTo(b.frequency));
    return List<FpvChannel>.unmodifiable(unique);
  }();

  /// Формирует отсортированный по частоте список кандидатов для слота
  List<FpvChannel> _getCandidatesForSlot(BoardType type) => switch (type) {
    BoardType.standard => _sortedStandardChannels,
    BoardType.lowband => _sortedLowbandChannels,
    BoardType.xBand => _sortedXBandChannels,
  };

  /// Поиск с возвратом (backtracking) с ранним отсечением и устранением симметрии
  bool _backtrack({
    required int slotIndex,
    required List<_SlotRequest> slots,
    required List<List<FpvChannel>> candidatesBySlot,
    required List<FpvChannel> chosenChannels,
    required List<int> chosenFrequencies,
    required Set<String> usedChannelCodes,
    required int lastCandidateIndex,
    required int minDistance,
  }) {
    if (slotIndex == slots.length) {
      return true; // Все борты успешно распределены!
    }

    final sameTypeAsPrev =
        slotIndex > 0 &&
        slots[slotIndex].boardType == slots[slotIndex - 1].boardType;
    final startIndex = sameTypeAsPrev ? lastCandidateIndex + 1 : 0;
    final candidates = candidatesBySlot[slotIndex];

    for (int i = startIndex; i < candidates.length; i++) {
      final candidate = candidates[i];

      // Исключаем повторное использование одного и того же канала или частоты
      if (usedChannelCodes.contains(candidate.code)) continue;
      if (chosenFrequencies.contains(candidate.frequency)) continue;

      // Проверка защитного интервала Δf >= 40 и IMD3
      if (!ImdValidator.canAddFrequency(
        chosenFrequencies,
        candidate.frequency,
        minDistance: minDistance,
      )) {
        continue;
      }

      // Шаг вперед
      chosenChannels.add(candidate);
      chosenFrequencies.add(candidate.frequency);
      usedChannelCodes.add(candidate.code);

      if (_backtrack(
        slotIndex: slotIndex + 1,
        slots: slots,
        candidatesBySlot: candidatesBySlot,
        chosenChannels: chosenChannels,
        chosenFrequencies: chosenFrequencies,
        usedChannelCodes: usedChannelCodes,
        lastCandidateIndex: i,
        minDistance: minDistance,
      )) {
        return true;
      }

      // Шаг назад (backtrack)
      chosenChannels.removeLast();
      chosenFrequencies.removeLast();
      usedChannelCodes.remove(candidate.code);
    }

    return false;
  }
}

class _SlotRequest {
  final int boardNumber;
  final BoardType boardType;
  final List<BandCategory> allowedCategories;

  const _SlotRequest({
    required this.boardNumber,
    required this.boardType,
    required this.allowedCategories,
  });
}
