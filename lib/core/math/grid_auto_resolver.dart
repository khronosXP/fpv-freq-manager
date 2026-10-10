import '../constants/fpv_frequencies.dart';
import '../models/board_type.dart';
import '../models/fpv_channel.dart';
import '../models/manual_drone_slot.dart';
import 'conflict_analyzer.dart';
import 'imd_validator.dart';

class AutoFixResult {
  final bool isSuccess;
  final List<ManualDroneSlot> resolvedSlots;
  final Set<int> changedSlotIds;
  final String? errorMessage;

  const AutoFixResult.success({
    required this.resolvedSlots,
    required this.changedSlotIds,
  }) : isSuccess = true,
       errorMessage = null;

  const AutoFixResult.failure(this.errorMessage)
    : isSuccess = false,
      resolvedSlots = const [],
      changedSlotIds = const {};
}

class GridAutoResolver {
  final ConflictAnalyzer analyzer;

  const GridAutoResolver({this.analyzer = const ConflictAnalyzer()});

  ConflictAnalyzer get _analyzer => analyzer;

  /// Вирішує радіоколізії, суворо зберігаючи незмінними зафіксовані (isLocked) борти
  AutoFixResult resolve(List<ManualDroneSlot> slots) {
    if (slots.isEmpty) {
      return const AutoFixResult.success(resolvedSlots: [], changedSlotIds: {});
    }

    final assignedSlots = slots.where((s) => s.isAssigned).toList();

    // 1. Перевірка взаємної колізії зафіксованих каналів
    final lockedSlots = assignedSlots.where((s) => s.isLocked).toList();
    final lockedReport = _analyzer.analyze(lockedSlots);
    if (lockedReport.hasCollisions) {
      return const AutoFixResult.failure(
        'Неможливо виправити: зафіксовані канали (🔒) конфліктують між собою. '
        'Зніміть блокування хоча б з одного зафіксованого борта.',
      );
    }

    // Якщо всі канали призначені і поточна конфігурація вже чиста
    final currentReport = _analyzer.analyze(assignedSlots);
    if (assignedSlots.length == slots.length && currentReport.isClean) {
      return AutoFixResult.success(
        resolvedSlots: slots,
        changedSlotIds: const {},
      );
    }

    // Адаптивний поріг IMD3: для 6 стандартних бортів фізично необхідний допуск 10 МГц
    final standardCount = slots
        .where((s) => s.boardType == BoardType.standard)
        .length;
    final minDistance = standardCount == 6
        ? ImdValidator.marginalImdDistance
        : ImdValidator.minImdDistance;

    // 2. Фаза 1 (Micro-fix): тримаємо чисті незаблоковані слоти незмінними,
    // міняємо тільки конфліктні незаблоковані або непризначені слоти.
    final fixedSlotsPhase1 = assignedSlots
        .where(
          (s) => s.isLocked || !currentReport.conflictedSlotIds.contains(s.id),
        )
        .toList();
    final toResolvePhase1 = slots
        .where(
          (s) =>
              !s.isLocked &&
              (s.channel == null ||
                  currentReport.conflictedSlotIds.contains(s.id)),
        )
        .toList();

    final phase1Solution = _solveSlots(
      fixedSlots: fixedSlotsPhase1,
      variableSlots: toResolvePhase1,
      minDistance: minDistance,
    );

    if (phase1Solution != null) {
      return _buildResult(slots, phase1Solution);
    }

    // 3. Фаза 2 (Macro-fix): тримаємо тільки locked слоти,
    // змінюємо всі незаблоковані слоти.
    final fixedSlotsPhase2 = lockedSlots;
    final toResolvePhase2 = slots.where((s) => !s.isLocked).toList();

    final phase2Solution = _solveSlots(
      fixedSlots: fixedSlotsPhase2,
      variableSlots: toResolvePhase2,
      minDistance: minDistance,
    );

    if (phase2Solution != null) {
      return _buildResult(slots, phase2Solution);
    }

    return const AutoFixResult.failure(
      'Не вдалося підібрати безпечні частоти без зміни зафіксованих каналів. '
      'Спробуйте розблокувати частину каналів або активувати розширені діапазони.',
    );
  }

  /// Бектрекінг підбору безпечних каналів для змінних слотів
  Map<int, FpvChannel>? _solveSlots({
    required List<ManualDroneSlot> fixedSlots,
    required List<ManualDroneSlot> variableSlots,
    required int minDistance,
  }) {
    final fixedFrequencies = fixedSlots
        .map((s) => s.channel!.frequency)
        .toList();
    final usedCodes = fixedSlots.map((s) => s.channel!.code).toSet();

    // Сортуємо кандидатів для кожного слота за мінімальним відхиленням від поточної частоти
    final candidatesBySlot = <List<FpvChannel>>[];
    for (final slot in variableSlots) {
      final pool = _getCandidatePool(slot.boardType).toList();
      final currentFreq =
          slot.channel?.frequency ?? _defaultFreqFor(slot.boardType);
      pool.sort(
        (a, b) => (a.frequency - currentFreq).abs().compareTo(
          (b.frequency - currentFreq).abs(),
        ),
      );
      candidatesBySlot.add(pool);
    }

    final chosenChannels = <FpvChannel>[];
    final currentFrequencies = List<int>.from(fixedFrequencies);
    final currentUsedCodes = Set<String>.from(usedCodes);

    final success = _backtrack(
      slotIndex: 0,
      variableSlots: variableSlots,
      candidatesBySlot: candidatesBySlot,
      chosenChannels: chosenChannels,
      currentFrequencies: currentFrequencies,
      currentUsedCodes: currentUsedCodes,
      minDistance: minDistance,
    );

    if (!success) return null;

    final result = <int, FpvChannel>{};
    for (int i = 0; i < variableSlots.length; i++) {
      result[variableSlots[i].id] = chosenChannels[i];
    }
    return result;
  }

  bool _backtrack({
    required int slotIndex,
    required List<ManualDroneSlot> variableSlots,
    required List<List<FpvChannel>> candidatesBySlot,
    required List<FpvChannel> chosenChannels,
    required List<int> currentFrequencies,
    required Set<String> currentUsedCodes,
    required int minDistance,
  }) {
    if (slotIndex == variableSlots.length) {
      return true;
    }

    final candidates = candidatesBySlot[slotIndex];

    for (final candidate in candidates) {
      if (currentUsedCodes.contains(candidate.code)) continue;
      if (currentFrequencies.contains(candidate.frequency)) continue;

      if (!ImdValidator.canAddFrequency(
        currentFrequencies,
        candidate.frequency,
        minDistance: minDistance,
      )) {
        continue;
      }

      chosenChannels.add(candidate);
      currentFrequencies.add(candidate.frequency);
      currentUsedCodes.add(candidate.code);

      if (_backtrack(
        slotIndex: slotIndex + 1,
        variableSlots: variableSlots,
        candidatesBySlot: candidatesBySlot,
        chosenChannels: chosenChannels,
        currentFrequencies: currentFrequencies,
        currentUsedCodes: currentUsedCodes,
        minDistance: minDistance,
      )) {
        return true;
      }

      chosenChannels.removeLast();
      currentFrequencies.removeLast();
      currentUsedCodes.remove(candidate.code);
    }

    return false;
  }

  AutoFixResult _buildResult(
    List<ManualDroneSlot> originalSlots,
    Map<int, FpvChannel> resolvedMap,
  ) {
    final changedIds = <int>{};
    final updatedSlots = originalSlots.map((slot) {
      if (resolvedMap.containsKey(slot.id)) {
        final newChannel = resolvedMap[slot.id]!;
        if (newChannel.code != slot.channel?.code) {
          changedIds.add(slot.id);
        }
        return slot.copyWith(channel: () => newChannel);
      }
      return slot;
    }).toList();

    return AutoFixResult.success(
      resolvedSlots: updatedSlots,
      changedSlotIds: changedIds,
    );
  }

  int _defaultFreqFor(BoardType type) => switch (type) {
    BoardType.standard => 5800,
    BoardType.lowband => 5450,
    BoardType.xBand => 5100,
  };

  List<FpvChannel> _getCandidatePool(BoardType type) => switch (type) {
    BoardType.standard => FpvFrequencies.standardChannels,
    BoardType.lowband => FpvFrequencies.lowbandChannels,
    BoardType.xBand => FpvFrequencies.xBandChannels,
  };
}
