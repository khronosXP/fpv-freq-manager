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
    final assignedSlots = slots.where((s) => s.isAssigned).toList();
    if (assignedSlots.isEmpty) {
      return AutoFixResult.success(
        resolvedSlots: slots,
        changedSlotIds: const {},
      );
    }

    // 1. Перевірка взаємної колізії зафіксованих каналів
    final lockedSlots = assignedSlots.where((s) => s.isLocked).toList();
    final lockedReport = _analyzer.analyze(lockedSlots);
    if (lockedReport.hasCollisions) {
      return const AutoFixResult.failure(
        'Неможливо виправити: зафіксовані канали (🔒) конфліктують між собою. '
        'Зніміть блокування хоча б з одного зафіксованого борта.',
      );
    }

    // Якщо поточна конфігурація вже чиста
    final currentReport = _analyzer.analyze(assignedSlots);
    if (currentReport.isClean) {
      return AutoFixResult.success(
        resolvedSlots: slots,
        changedSlotIds: const {},
      );
    }

    // 2. Фаза 1 (Micro-fix): тримаємо чисті незаблоковані слоти незмінними,
    // міняємо тільки конфліктні незаблоковані слоти.
    final fixedSlotsPhase1 = assignedSlots
        .where(
          (s) => s.isLocked || !currentReport.conflictedSlotIds.contains(s.id),
        )
        .toList();
    final toResolvePhase1 = assignedSlots
        .where(
          (s) => !s.isLocked && currentReport.conflictedSlotIds.contains(s.id),
        )
        .toList();

    final phase1Solution = _solveSlots(
      fixedSlots: fixedSlotsPhase1,
      variableSlots: toResolvePhase1,
    );

    if (phase1Solution != null) {
      return _buildResult(slots, phase1Solution);
    }

    // 3. Фаза 2 (Macro-fix): тримаємо тільки locked слоти,
    // змінюємо всі незаблоковані слоти.
    final fixedSlotsPhase2 = lockedSlots;
    final toResolvePhase2 = assignedSlots.where((s) => !s.isLocked).toList();

    final phase2Solution = _solveSlots(
      fixedSlots: fixedSlotsPhase2,
      variableSlots: toResolvePhase2,
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
  }) {
    final fixedFrequencies = fixedSlots
        .map((s) => s.channel!.frequency)
        .toList();
    final usedCodes = fixedSlots.map((s) => s.channel!.code).toSet();

    // Сортуємо кандидатів для кожного слота за мінімальним відхиленням від поточного значення
    final candidatesBySlot = <List<FpvChannel>>[];
    for (final slot in variableSlots) {
      final pool = _getCandidatePool(slot.boardType).toList();
      final currentFreq = slot.channel?.frequency ?? 5800;
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

  List<FpvChannel> _getCandidatePool(BoardType type) {
    switch (type) {
      case BoardType.standard:
        return FpvFrequencies.standardChannels;
      case BoardType.lowband:
        return [
          ...FpvFrequencies.lowbandChannels,
          ...FpvFrequencies.standardChannels,
        ];
      case BoardType.xBand:
        return [
          ...FpvFrequencies.xBandChannels,
          ...FpvFrequencies.standardChannels,
        ];
    }
  }
}
