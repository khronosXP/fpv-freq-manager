class ImdViolation {
  final int f1;
  final int f2;
  final int f3;
  final int imdFrequency;
  final int distance;

  const ImdViolation({
    required this.f1,
    required this.f2,
    required this.f3,
    required this.imdFrequency,
    required this.distance,
  });

  @override
  String toString() =>
      'IMD3 violation: 2*$f1 - $f2 = $imdFrequency clashes with $f3 (diff = ${distance}MHz < ${ImdValidator.minImdDistance}MHz)';
}

class GuardBandViolation {
  final int f1;
  final int f2;
  final int delta;

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

  /// Минимальный защитный интервал между любыми двумя каналами (МГц).
  static const int minGuardBand = 40;

  /// Минимальный допуск безопасности от интермодуляции 3-го порядка (МГц).
  static const int minImdDistance = 10;

  /// Проверяет, соблюдается ли защитный интервал Δf >= 40 МГц для всех пар.
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

  /// Проверяет отсутствие IMD3 коллизий (|2*f1 - f2| != f3 с запасом >= 10 МГц).
  static bool hasNoImd3Collisions(List<int> frequencies) {
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
          if ((imd - f3).abs() < minImdDistance) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Полная валидация набора частот.
  static bool isValidSet(List<int> frequencies) {
    return hasValidGuardBands(frequencies) && hasNoImd3Collisions(frequencies);
  }

  /// Инкрементальная проверка: можно ли безопасно добавить [candidate] к уже валидному [current].
  static bool canAddFrequency(List<int> current, int candidate) {
    // 1. Проверка защитного интервала со всеми текущими частотами
    for (final f in current) {
      if ((candidate - f).abs() < minGuardBand) {
        return false;
      }
    }

    if (current.length < 2) {
      return true;
    }

    // 2. Проверка IMD3, где candidate является приемником (f3)
    // 2*f1 - f2 ~ candidate
    for (int i = 0; i < current.length; i++) {
      final f1 = current[i];
      for (int j = 0; j < current.length; j++) {
        if (i == j) continue;
        final f2 = current[j];
        final imd = 2 * f1 - f2;
        if ((imd - candidate).abs() < minImdDistance) {
          return false;
        }
      }
    }

    // 3. Проверка IMD3, где candidate является одним из передатчиков (f1 или f2)
    for (int i = 0; i < current.length; i++) {
      final fOtherTransmitter = current[i];
      for (int k = 0; k < current.length; k++) {
        if (k == i) continue;
        final fReceiver = current[k];

        // candidate как f1: 2*candidate - fOtherTransmitter ~ fReceiver
        final imdAsF1 = 2 * candidate - fOtherTransmitter;
        if ((imdAsF1 - fReceiver).abs() < minImdDistance) {
          return false;
        }

        // candidate как f2: 2*fOtherTransmitter - candidate ~ fReceiver
        final imdAsF2 = 2 * fOtherTransmitter - candidate;
        if ((imdAsF2 - fReceiver).abs() < minImdDistance) {
          return false;
        }
      }
    }

    return true;
  }

  /// Возвращает список всех нарушений для диагностики.
  static List<String> findViolations(List<int> frequencies) {
    final violations = <String>[];

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
          if (diff < minImdDistance) {
            violations.add(
              'IMD3: 2*$f1 - $f2 = $imd clashes with $f3 (diff = ${diff}MHz < ${minImdDistance}MHz)',
            );
          }
        }
      }
    }

    return violations;
  }
}
