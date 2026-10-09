class TwoToneImdViolation {
  final int f1, f2, f3, imdFrequency, distance;

  const TwoToneImdViolation({
    required this.f1,
    required this.f2,
    required this.f3,
    required this.imdFrequency,
    required this.distance,
  });

  @override
  String toString() =>
      'Two-tone IMD3: 2*$f1 - $f2 = $imdFrequency clashes with $f3 (diff = ${distance}MHz < ${ImdValidator.minImdDistance}MHz)';
}

typedef ImdViolation = TwoToneImdViolation;

class TripleBeatViolation {
  final int f1, f2, f3, victim, imdFrequency, distance;

  const TripleBeatViolation({
    required this.f1,
    required this.f2,
    required this.f3,
    required this.victim,
    required this.imdFrequency,
    required this.distance,
  });

  @override
  String toString() =>
      'Triple-beat IMD3: $f1 + $f2 - $f3 = $imdFrequency clashes with $victim (diff = ${distance}MHz < ${ImdValidator.minImdDistance}MHz)';
}

class GuardBandViolation {
  final int f1, f2, delta;

  const GuardBandViolation({
    required this.f1,
    required this.f2,
    required this.delta,
  });

  @override
  String toString() =>
      'Guard band violation: |$f1 - $f2| = ${delta}MHz < ${ImdValidator.minGuardBand}MHz';
}

class ImdValidator {
  ImdValidator._();

  /// Мінімальний захисний інтервал між будь-якими двома каналами (МГц).
  static const int minGuardBand = 40;

  /// Стандартний безпечний допуск від IMD3 (МГц).
  /// Гарантує вихід паразитної гармоніки за межі смуги пропускання фільтра ПЧ (IF SAW Filter ~17-20 МГц).
  static const int minImdDistance = 12;

  /// Граничний фізичний допуск IMD3 для екстремально щільних сіток на 6 стандартних бортів (МГц).
  static const int marginalImdDistance = 10;

  /// Перевіряє, чи дотримується захисний інтервал Δf >= 40 МГц для всіх пар.
  static bool hasValidGuardBands(List<int> frequencies) {
    for (int i = 0; i < frequencies.length; i++) {
      for (int j = i + 1; j < frequencies.length; j++) {
        if ((frequencies[i] - frequencies[j]).abs() < minGuardBand) {
          return false;
        }
      }
    }
    return true;
  }

  /// Двотонова перевірка IMD3 (|2*f1 - f2 - f3| >= minDistance МГц).
  static bool hasNoTwoToneCollisions(
    List<int> frequencies, {
    int minDistance = minImdDistance,
  }) {
    final n = frequencies.length;
    if (n < 3) return true;

    for (int i = 0; i < n; i++) {
      final f1 = frequencies[i];
      for (int j = 0; j < n; j++) {
        if (i == j) continue;
        final f2 = frequencies[j];
        final imd = 2 * f1 - f2;

        for (int k = 0; k < n; k++) {
          if (k == i || k == j) continue;
          final f3 = frequencies[k];
          if ((imd - f3).abs() < minDistance) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Трисигнальна перевірка IMD3 Triple-Beat (|(fi + fj) - (fk + fm)| >= minDistance МГц).
  static bool hasNoTripleBeatCollisions(
    List<int> frequencies, {
    int minDistance = minImdDistance,
  }) {
    final n = frequencies.length;
    if (n < 4) return true;

    for (int i = 0; i < n; i++) {
      final fi = frequencies[i];
      for (int j = i + 1; j < n; j++) {
        final fj = frequencies[j];
        final sum1 = fi + fj;

        for (int k = i + 1; k < n; k++) {
          if (k == j) continue;
          final fk = frequencies[k];
          for (int m = k + 1; m < n; m++) {
            if (m == j) continue;
            final fm = frequencies[m];
            final sum2 = fk + fm;

            if ((sum1 - sum2).abs() < minDistance) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  /// Повна перевірка IMD3 (двотонові продукти 2*f1 - f2 та тритонові fi + fj - fk).
  static bool hasNoImd3Collisions(
    List<int> frequencies, {
    int minDistance = minImdDistance,
  }) {
    return hasNoTwoToneCollisions(frequencies, minDistance: minDistance) &&
        hasNoTripleBeatCollisions(frequencies, minDistance: minDistance);
  }

  /// Повна валідація набору частот (захисний інтервал + двотоновий та тритоновий IMD3).
  static bool isValidSet(
    List<int> frequencies, {
    int minDistance = minImdDistance,
  }) {
    return hasValidGuardBands(frequencies) &&
        hasNoImd3Collisions(frequencies, minDistance: minDistance);
  }

  /// Інкрементальна перевірка: чи можна безпечно додати [candidate] до вже валідного [current].
  static bool canAddFrequency(
    List<int> current,
    int candidate, {
    int minDistance = minImdDistance,
  }) {
    // 1. Захисний інтервал зі всіма поточними частотами
    for (final f in current) {
      if ((candidate - f).abs() < minGuardBand) {
        return false;
      }
    }

    if (current.length < 2) {
      return true;
    }

    // 2. Двотонова інтермодуляція IMD3
    for (int i = 0; i < current.length; i++) {
      final f1 = current[i];
      for (int j = 0; j < current.length; j++) {
        if (i == j) continue;
        final f2 = current[j];

        // candidate як приймач f3: 2*f1 - f2 ~ candidate
        final imd = 2 * f1 - f2;
        if ((imd - candidate).abs() < minDistance) {
          return false;
        }

        // candidate як f1: 2*candidate - f1 ~ f2
        final imdAsF1 = 2 * candidate - f1;
        if ((imdAsF1 - f2).abs() < minDistance) {
          return false;
        }

        // candidate як f2: 2*f1 - candidate ~ f2
        final imdAsF2 = 2 * f1 - candidate;
        if ((imdAsF2 - f2).abs() < minDistance) {
          return false;
        }
      }
    }

    if (current.length < 3) {
      return true;
    }

    // 3. Тритонова інтермодуляція Triple-Beat (zero-allocation incremental pruning)
    // Охоплює всі ролі candidate (приймач або будь-який з передавачів):
    // |(a + b - c) - candidate| < minDistance
    final curLen = current.length;
    for (int i = 0; i < curLen; i++) {
      final a = current[i];
      for (int j = i + 1; j < curLen; j++) {
        final b = current[j];
        for (int k = 0; k < curLen; k++) {
          if (k == i || k == j) continue;
          final c = current[k];
          final beat = a + b - c;
          if ((beat - candidate).abs() < minDistance) {
            return false;
          }
        }
      }
    }

    return true;
  }

  /// Повертає перелік усіх порушень для діагностики.
  static List<String> findViolations(
    List<int> frequencies, {
    int minDistance = minImdDistance,
  }) {
    final violations = <String>[];

    // 1. Guard band
    for (int i = 0; i < frequencies.length; i++) {
      for (int j = i + 1; j < frequencies.length; j++) {
        final delta = (frequencies[i] - frequencies[j]).abs();
        if (delta < minGuardBand) {
          violations.add(
            'Guard band: |${frequencies[i]} - ${frequencies[j]}| = ${delta}MHz < ${minGuardBand}MHz',
          );
        }
      }
    }

    final n = frequencies.length;

    // 2. Two-tone IMD3
    for (int i = 0; i < n; i++) {
      final f1 = frequencies[i];
      for (int j = 0; j < n; j++) {
        if (i == j) continue;
        final f2 = frequencies[j];
        final imd = 2 * f1 - f2;

        for (int k = 0; k < n; k++) {
          if (k == i || k == j) continue;
          final f3 = frequencies[k];
          final diff = (imd - f3).abs();
          if (diff < minDistance) {
            violations.add(
              'Two-tone IMD3: 2*$f1 - $f2 = $imd clashes with $f3 (diff = ${diff}MHz < ${minDistance}MHz)',
            );
          }
        }
      }
    }

    // 3. Three-tone Triple-Beat
    for (int i = 0; i < n; i++) {
      final f1 = frequencies[i];
      for (int j = i + 1; j < n; j++) {
        final f2 = frequencies[j];
        for (int k = 0; k < n; k++) {
          if (k == i || k == j) continue;
          final f3 = frequencies[k];
          final beat = f1 + f2 - f3;

          for (int m = 0; m < n; m++) {
            if (m == i || m == j || m == k) continue;
            final fVictim = frequencies[m];
            final diff = (beat - fVictim).abs();
            if (diff < minDistance) {
              violations.add(
                'Triple-beat IMD3: $f1 + $f2 - $f3 = $beat clashes with $fVictim (diff = ${diff}MHz < ${minDistance}MHz)',
              );
            }
          }
        }
      }
    }

    return violations;
  }
}
