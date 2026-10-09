import '../../models/fpv_channel.dart';
import '../imd_validator.dart';
import '../models/allocation_score.dart';
import 'diff_map.dart';

/// Результат оптимізації смуги частот.
class BandAllocationResult {
  final List<FpvChannel> channels;
  final AllocationScore score;
  final bool isSuccess;
  final String? errorMessage;

  const BandAllocationResult({
    required this.channels,
    required this.score,
    required this.isSuccess,
    this.errorMessage,
  });

  const BandAllocationResult.failure(String message)
    : channels = const [],
      score = const AllocationScore(
        imdMargin: 0,
        minSpacing: 0,
        totalSpread: 0,
        totalScore: -1e9,
      ),
      isSuccess = false,
      errorMessage = message;
}

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

    // Забезпечуємо унікальність за частотою та сортування
    final uniqueMap = <int, FpvChannel>{};
    for (final ch in availableChannels) {
      uniqueMap.putIfAbsent(ch.frequency, () => ch);
    }
    final sortedChannels = uniqueMap.values.toList()
      ..sort((a, b) => a.frequency.compareTo(b.frequency));

    if (sortedChannels.length < count) {
      return BandAllocationResult.failure(
        'Недостатньо фізичних каналів у пулі ($count потрібно, ${sortedChannels.length} доступно).',
      );
    }

    // 1-2 борти не мають інтермодуляції: просто максимізуємо рознос (Near-Far)
    if (count == 1) {
      final best = sortedChannels.first;
      return BandAllocationResult(
        channels: [best],
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
      // Обираємо крайні канали з розносом >= minSpacing
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

    List<FpvChannel>? bestCombo;
    AllocationScore? bestScore;

    void backtrack({
      required int startIndex,
      required List<FpvChannel> current,
      required List<int> currentFreqs,
    }) {
      if (current.length == count) {
        final imdMargin = calculateIntraBandImd3Margin(currentFreqs);
        if (imdMargin < minImdFloor) return;

        int minSp = 999;
        for (int i = 0; i < currentFreqs.length - 1; i++) {
          final sp = currentFreqs[i + 1] - currentFreqs[i];
          if (sp < minSp) minSp = sp;
        }

        final spread = currentFreqs.last - currentFreqs.first;
        final score = AllocationScore.calculate(
          imdMargin: imdMargin,
          minSpacing: minSp,
          totalSpread: spread,
        );

        if (bestScore == null || score.compareTo(bestScore!) > 0) {
          bestScore = score;
          bestCombo = List<FpvChannel>.from(current);
        }
        return;
      }

      final needed = count - current.length;
      final maxStart = sortedChannels.length - needed;

      for (int i = startIndex; i <= maxStart; i++) {
        final cand = sortedChannels[i];

        // 1. Монотонний захисний інтервал Δf >= minSpacing
        if (current.isNotEmpty &&
            cand.frequency - current.last.frequency < minSpacing) {
          continue;
        }

        // 2. Раннє відсікання симетричного 0 МГц резонансу
        if (!DiffMap.canAddWithoutCollision(currentFreqs, cand.frequency)) {
          continue;
        }

        // 3. Раннє відсікання гілок, що порушують мінімальний IMD-поріг
        if (!ImdValidator.canAddFrequency(
          currentFreqs,
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
