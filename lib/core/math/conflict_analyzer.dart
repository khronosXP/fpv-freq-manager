import '../constants/fpv_frequencies.dart';
import '../models/board_type.dart';
import '../models/fpv_channel.dart';
import '../models/manual_drone_slot.dart';
import 'imd_validator.dart';

class DirectCollision {
  final ManualDroneSlot slotA;
  final ManualDroneSlot slotB;
  final int delta;

  const DirectCollision({
    required this.slotA,
    required this.slotB,
    required this.delta,
  });

  @override
  String toString() =>
      'Борт ${slotA.boardNumber} (${slotA.channel?.code}) та Борт ${slotB.boardNumber} (${slotB.channel?.code}): різниця $delta МГц < 40 МГц';
}

class ImdCollision {
  final ManualDroneSlot transmitter1;
  final ManualDroneSlot transmitter2;
  final ManualDroneSlot victim;
  final int imdFrequency;
  final int distance;
  final int threshold;

  const ImdCollision({
    required this.transmitter1,
    required this.transmitter2,
    required this.victim,
    required this.imdFrequency,
    required this.distance,
    this.threshold = ImdValidator.minImdDistance,
  });

  @override
  String toString() =>
      '2×Борт ${transmitter1.boardNumber} (${transmitter1.channel?.code}) - Борт ${transmitter2.boardNumber} (${transmitter2.channel?.code}) = $imdFrequency МГц глушить Борт ${victim.boardNumber} (${victim.channel?.code}, зазор $distance МГц < $threshold МГц)';
}

class TripleBeatCollision {
  final ManualDroneSlot transmitter1;
  final ManualDroneSlot transmitter2;
  final ManualDroneSlot transmitter3;
  final ManualDroneSlot victim;
  final int imdFrequency;
  final int distance;
  final int threshold;

  const TripleBeatCollision({
    required this.transmitter1,
    required this.transmitter2,
    required this.transmitter3,
    required this.victim,
    required this.imdFrequency,
    required this.distance,
    this.threshold = ImdValidator.minImdDistance,
  });

  int get beatFrequency => imdFrequency;

  @override
  String toString() =>
      'Борт ${transmitter1.boardNumber} (${transmitter1.channel?.code}) + Борт ${transmitter2.boardNumber} (${transmitter2.channel?.code}) - Борт ${transmitter3.boardNumber} (${transmitter3.channel?.code}) = $imdFrequency МГц глушить Борт ${victim.boardNumber} (${victim.channel?.code}, зазор $distance МГц < $threshold МГц)';
}

class ConflictReport {
  final List<DirectCollision> directCollisions;
  final List<ImdCollision> imdCollisions;
  final List<TripleBeatCollision> tripleBeatCollisions;
  final Set<int> conflictedSlotIds;
  final Map<int, List<FpvChannel>> suggestionsBySlotId;

  const ConflictReport({
    this.directCollisions = const [],
    this.imdCollisions = const [],
    this.tripleBeatCollisions = const [],
    this.conflictedSlotIds = const {},
    this.suggestionsBySlotId = const {},
  });

  const ConflictReport.empty() : this();

  bool get hasCollisions =>
      directCollisions.isNotEmpty ||
      imdCollisions.isNotEmpty ||
      tripleBeatCollisions.isNotEmpty;
  bool get isClean => !hasCollisions;
  int get totalCollisionsCount =>
      directCollisions.length +
      imdCollisions.length +
      tripleBeatCollisions.length;
}

class ConflictAnalyzer {
  const ConflictAnalyzer();

  /// Аналізує поточний набір слотів та генерує детальний звіт про радіоколізії
  ConflictReport analyze(List<ManualDroneSlot> slots) {
    final assignedSlots = slots.where((s) => s.isAssigned).toList();
    if (assignedSlots.length < 2) {
      return const ConflictReport.empty();
    }

    final direct = <DirectCollision>[];
    final conflictedIds = <int>{};

    // 1. Прямі колізії (Guard band Δf < 40 МГц)
    for (int i = 0; i < assignedSlots.length; i++) {
      final sA = assignedSlots[i];
      final fA = sA.channel!.frequency;

      for (int j = i + 1; j < assignedSlots.length; j++) {
        final sB = assignedSlots[j];
        final fB = sB.channel!.frequency;
        final delta = (fA - fB).abs();

        if (delta < ImdValidator.minGuardBand) {
          direct.add(DirectCollision(slotA: sA, slotB: sB, delta: delta));
          conflictedIds.add(sA.id);
          conflictedIds.add(sB.id);
        }
      }
    }

    // 2. Інтермодуляційні колізії IMD3 (Стандартний допуск 12 МГц)
    const imdThreshold = ImdValidator.minImdDistance;

    final imd = <ImdCollision>[];
    if (assignedSlots.length >= 3) {
      for (int i = 0; i < assignedSlots.length; i++) {
        final t1 = assignedSlots[i];
        final f1 = t1.channel!.frequency;

        for (int j = 0; j < assignedSlots.length; j++) {
          if (i == j) continue;
          final t2 = assignedSlots[j];
          final f2 = t2.channel!.frequency;
          final imdFreq = 2 * f1 - f2;

          for (int k = 0; k < assignedSlots.length; k++) {
            if (k == i || k == j) continue;
            final vic = assignedSlots[k];
            final f3 = vic.channel!.frequency;
            final dist = (imdFreq - f3).abs();

            if (dist < imdThreshold) {
              // Уникаємо однакових дублікатів
              final alreadyAdded = imd.any(
                (c) =>
                    c.transmitter1.id == t1.id &&
                    c.transmitter2.id == t2.id &&
                    c.victim.id == vic.id,
              );
              if (!alreadyAdded) {
                imd.add(
                  ImdCollision(
                    transmitter1: t1,
                    transmitter2: t2,
                    victim: vic,
                    imdFrequency: imdFreq,
                    distance: dist,
                    threshold: imdThreshold,
                  ),
                );
                conflictedIds.add(t1.id);
                conflictedIds.add(t2.id);
                conflictedIds.add(vic.id);
              }
            }
          }
        }
      }
    }

    // 3. Тритонові інтермодуляційні колізії Triple-Beat (|f1 + f2 - f3 - f_victim| < 10 МГц)
    final tripleBeat = <TripleBeatCollision>[];
    if (assignedSlots.length >= 4) {
      final n = assignedSlots.length;
      for (int i = 0; i < n; i++) {
        final t1 = assignedSlots[i];
        final f1 = t1.channel!.frequency;

        for (int j = i + 1; j < n; j++) {
          final t2 = assignedSlots[j];
          final f2 = t2.channel!.frequency;

          for (int k = 0; k < n; k++) {
            if (k == i || k == j) continue;
            final t3 = assignedSlots[k];
            final f3 = t3.channel!.frequency;
            final beatFreq = f1 + f2 - f3;

            for (int m = 0; m < n; m++) {
              if (m == i || m == j || m == k) continue;
              final vic = assignedSlots[m];
              final fVic = vic.channel!.frequency;
              final dist = (beatFreq - fVic).abs();

              if (dist < imdThreshold) {
                final alreadyAdded = tripleBeat.any(
                  (c) =>
                      c.transmitter1.id == t1.id &&
                      c.transmitter2.id == t2.id &&
                      c.transmitter3.id == t3.id &&
                      c.victim.id == vic.id,
                );
                if (!alreadyAdded) {
                  tripleBeat.add(
                    TripleBeatCollision(
                      transmitter1: t1,
                      transmitter2: t2,
                      transmitter3: t3,
                      victim: vic,
                      imdFrequency: beatFreq,
                      distance: dist,
                      threshold: imdThreshold,
                    ),
                  );
                  conflictedIds.add(t1.id);
                  conflictedIds.add(t2.id);
                  conflictedIds.add(t3.id);
                  conflictedIds.add(vic.id);
                }
              }
            }
          }
        }
      }
    }

    // 4. Генерація рекомендацій заміни для незаблокованих конфліктних слотів
    final suggestions = {
      for (final slot in assignedSlots)
        if (!slot.isLocked && conflictedIds.contains(slot.id))
          slot.id: _findSuggestionsForSlot(slot, assignedSlots, imdThreshold),
    };

    return ConflictReport(
      directCollisions: direct,
      imdCollisions: imd,
      tripleBeatCollisions: tripleBeat,
      conflictedSlotIds: conflictedIds,
      suggestionsBySlotId: suggestions,
    );
  }

  /// Знаходить безпечні альтернативні канали для слота
  List<FpvChannel> _findSuggestionsForSlot(
    ManualDroneSlot target,
    List<ManualDroneSlot> allAssigned,
    int imdThreshold,
  ) {
    // Всі інші частоти, крім target
    final otherFrequencies = allAssigned
        .where((s) => s.id != target.id)
        .map((s) => s.channel!.frequency)
        .toList();

    final allowedPool = _getCandidatePool(target.boardType);
    final validAlternatives = <FpvChannel>[];

    for (final candidate in allowedPool) {
      if (candidate.code == target.channel?.code) continue;

      if (ImdValidator.canAddFrequency(
        otherFrequencies,
        candidate.frequency,
        minDistance: imdThreshold,
      )) {
        validAlternatives.add(candidate);
      }
    }

    // Сортуємо альтернативи за мінімальним відхиленням від поточної частоти
    final targetFreq = target.channel!.frequency;
    validAlternatives.sort(
      (a, b) => (a.frequency - targetFreq).abs().compareTo(
        (b.frequency - targetFreq).abs(),
      ),
    );

    return validAlternatives.take(4).toList();
  }

  List<FpvChannel> _getCandidatePool(BoardType type) => switch (type) {
    BoardType.standard => FpvFrequencies.standardChannels,
    BoardType.lowband => FpvFrequencies.lowbandChannels,
    BoardType.xBand => FpvFrequencies.xBandChannels,
  };
}
