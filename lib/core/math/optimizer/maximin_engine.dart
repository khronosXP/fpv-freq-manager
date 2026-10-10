import '../../models/fpv_channel.dart';
import '../imd_validator.dart';
import '../models/allocation_score.dart';
import '../models/band_allocation_result.dart';
import 'diff_map.dart';

export '../models/band_allocation_result.dart';

/// Рушій оптимізації частот за критерієм Maximin із гілково-межовим відсіканням (Branch & Bound).
class MaximinEngine {
  final int minSpacing;
  final double minImdFloor;

  const MaximinEngine({this.minSpacing = 40, this.minImdFloor = 10.0});

  /// Розраховує мінімальний відступ IMD3 всередині впорядкованого набору частот.
  /// Повертає 0.0 при виявленні симетричного резонансу або прямих колізій.
  static double calculateIntraBandImd3Margin(List<int> sorted) {
    final n = sorted.length;
    if (n < 3) return 999.0;

    // 1. Швидка перевірка Sidon DiffMap на 0 МГц резонанс
    if (DiffMap.hasSymmetricResonance(sorted)) {
      return 0.0;
    }

    double minMargin = 999.0;

    // 2. Двотонова IMD3: 2*fa - fb
    for (int i = 0; i < n; i++) {
      final fa = sorted[i];
      for (int j = 0; j < n; j++) {
        if (i == j) continue;
        final fb = sorted[j];
        final imd = 2 * fa - fb;

        for (int k = 0; k < n; k++) {
          final dist = (imd - sorted[k]).abs().toDouble();
          if (dist < minMargin) {
            minMargin = dist;
            if (minMargin == 0.0) return 0.0;
          }
        }
      }
    }

    // 3. Тритонова IMD3: fa + fb - fc
    if (n >= 4) {
      for (int i = 0; i < n; i++) {
        final fa = sorted[i];
        for (int j = i + 1; j < n; j++) {
          final fb = sorted[j];
          for (int k = 0; k < n; k++) {
            if (k == i || k == j) continue;
            final fc = sorted[k];
            final imd = fa + fb - fc;

            for (int m = 0; m < n; m++) {
              if (m == i || m == j || m == k) continue;
              final dist = (imd - sorted[m]).abs().toDouble();
              if (dist < minMargin) {
                minMargin = dist;
                if (minMargin == 0.0) return 0.0;
              }
            }
          }
        }
      }
    }

    return minMargin;
  }

  /// Виконує Maximin-пошук найкращої комбінації з [count] каналів у [availableChannels].
  BandAllocationResult optimize({
    required List<FpvChannel> availableChannels,
    required int count,
    List<FpvChannel> lockedChannels = const [],
  }) {
    if (count <= 0) {
      return const BandAllocationResult(
        channels: [],
        score: AllocationScore(
          imdMargin: 999,
          minSpacing: 0,
          totalSpread: 0,
          totalScore: 0,
        ),
        isSuccess: true,
      );
    }

    // 1. Валідація зафіксованих каналів (🔒)
    final lockedFreqs = lockedChannels.map((c) => c.frequency).toList()..sort();
    for (int i = 0; i < lockedFreqs.length; i++) {
      for (int j = i + 1; j < lockedFreqs.length; j++) {
        if ((lockedFreqs[i] - lockedFreqs[j]).abs() < minSpacing) {
          return const BandAllocationResult.failure(
            'Зафіксовані канали (🔒) конфліктують між собою (Δf < 40 МГц).',
          );
        }
      }
    }
    if (lockedFreqs.length >= 3 &&
        calculateIntraBandImd3Margin(lockedFreqs) < minImdFloor) {
      return const BandAllocationResult.failure(
        'Зафіксовані канали (🔒) мають інтермодуляційний конфлікт IMD3.',
      );
    }
    if (lockedChannels.length > count) {
      return BandAllocationResult.failure(
        'Кількість зафіксованих каналів (${lockedChannels.length}) перевищує ліміт ($count).',
      );
    }
    if (lockedChannels.length == count) {
      final margin = calculateIntraBandImd3Margin(lockedFreqs);
      int minSp = 999;
      for (int i = 0; i < lockedFreqs.length - 1; i++) {
        final sp = lockedFreqs[i + 1] - lockedFreqs[i];
        if (sp < minSp) minSp = sp;
      }
      final spread = lockedFreqs.isNotEmpty
          ? lockedFreqs.last - lockedFreqs.first
          : 0;
      return BandAllocationResult(
        channels: List<FpvChannel>.from(lockedChannels)
          ..sort((a, b) => a.frequency.compareTo(b.frequency)),
        score: AllocationScore.calculate(
          imdMargin: margin,
          minSpacing: minSp,
          totalSpread: spread,
        ),
        isSuccess: true,
      );
    }

    final freeCount = count - lockedChannels.length;

    // 2. Фільтрація доступного пулу (вилучаємо зафіксовані)
    final uniqueMap = <int, FpvChannel>{};
    final lockedFreqSet = lockedFreqs.toSet();
    for (final ch in availableChannels) {
      if (!lockedFreqSet.contains(ch.frequency)) {
        uniqueMap.putIfAbsent(ch.frequency, () => ch);
      }
    }
    final sortedChannels = uniqueMap.values.toList()
      ..sort((a, b) => a.frequency.compareTo(b.frequency));

    if (sortedChannels.length < freeCount) {
      return BandAllocationResult.failure(
        'Недостатньо фізичних каналів у пулі ($freeCount потрібно, ${sortedChannels.length} доступно).',
      );
    }

    // Швидкі оптимізації для 1-2 бортів БЕЗ блокувань
    if (lockedChannels.isEmpty) {
      if (count == 1) {
        return BandAllocationResult(
          channels: [sortedChannels.first],
          score: const AllocationScore(
            imdMargin: 999,
            minSpacing: 999,
            totalSpread: 0,
            totalScore: 5000,
          ),
          isSuccess: true,
        );
      }

      if (count == 2) {
        for (int i = 0; i < sortedChannels.length; i++) {
          for (int j = sortedChannels.length - 1; j > i; j--) {
            final c1 = sortedChannels[i];
            final c2 = sortedChannels[j];
            final spacing = c2.frequency - c1.frequency;
            if (spacing >= minSpacing) {
              return BandAllocationResult(
                channels: [c1, c2],
                score: AllocationScore.calculate(
                  imdMargin: 999,
                  minSpacing: spacing,
                  totalSpread: spacing,
                ),
                isSuccess: true,
              );
            }
          }
        }
        return const BandAllocationResult.failure(
          'Неможливо рознести 2 борти з інтервалом Δf ≥ 40 МГц.',
        );
      }
    }

    List<FpvChannel>? bestCombo;
    AllocationScore? bestScore;

    void backtrack({
      required int startIndex,
      required List<FpvChannel> current,
      required List<int> currentFreqs,
    }) {
      if (current.length == freeCount) {
        final allChannels = [...lockedChannels, ...current]
          ..sort((a, b) => a.frequency.compareTo(b.frequency));
        final allFreqs = allChannels.map((c) => c.frequency).toList();

        final imdMargin = calculateIntraBandImd3Margin(allFreqs);
        if (imdMargin < minImdFloor) return;

        int minSp = 999;
        for (int i = 0; i < allFreqs.length - 1; i++) {
          final sp = allFreqs[i + 1] - allFreqs[i];
          if (sp < minSp) minSp = sp;
        }

        final spread = allFreqs.last - allFreqs.first;
        final score = AllocationScore.calculate(
          imdMargin: imdMargin,
          minSpacing: minSp,
          totalSpread: spread,
        );

        if (bestScore == null || score.compareTo(bestScore!) > 0) {
          bestScore = score;
          bestCombo = allChannels;
        }
        return;
      }

      final needed = freeCount - current.length;
      final maxStart = sortedChannels.length - needed;

      for (int i = startIndex; i <= maxStart; i++) {
        final cand = sortedChannels[i];

        // 1. Монотонний інтервал Δf >= minSpacing між вільними
        if (current.isNotEmpty &&
            cand.frequency - current.last.frequency < minSpacing) {
          continue;
        }

        // 2. Захисний інтервал з кожним зафіксованим каналом
        bool clashesWithLocked = false;
        for (final lf in lockedFreqs) {
          if ((cand.frequency - lf).abs() < minSpacing) {
            clashesWithLocked = true;
            break;
          }
        }
        if (clashesWithLocked) continue;

        // Повний комбінований набір для перевірки
        final combinedFreqs = [...lockedFreqs, ...currentFreqs];

        // 3. Раннє відсікання симетричного 0 МГц резонансу
        if (!DiffMap.canAddWithoutCollision(combinedFreqs, cand.frequency)) {
          continue;
        }

        // 4. Раннє відсікання гілок за порогом IMD
        if (!ImdValidator.canAddFrequency(
          combinedFreqs,
          cand.frequency,
          minDistance: minImdFloor.toInt(),
        )) {
          continue;
        }

        current.add(cand);
        currentFreqs.add(cand.frequency);

        backtrack(
          startIndex: i + 1,
          current: current,
          currentFreqs: currentFreqs,
        );

        current.removeLast();
        currentFreqs.removeLast();
      }
    }

    backtrack(startIndex: 0, current: [], currentFreqs: []);

    if (bestCombo == null || bestScore == null) {
      return BandAllocationResult.failure(
        'Неможливо підібрати чисту сітку для $count бортів '
        'із запасом IMD3 ≥ ${minImdFloor.toInt()} МГц та Δf ≥ $minSpacing МГц.',
      );
    }

    return BandAllocationResult(
      channels: bestCombo!,
      score: bestScore!,
      isSuccess: true,
    );
  }
}
