/// Модель оцінки якості розподілу частот за функцією Maximin.
class AllocationScore implements Comparable<AllocationScore> {
  /// Мінімальний запас інтермодуляції 3-го порядку (МГц).
  final double imdMargin;

  /// Мінімальний міжканальний захисний інтервал Δf (МГц).
  final int minSpacing;

  /// Загальний розмах смуги f_max - f_min (МГц).
  /// Допомагає розсувати борти на краї для запобігання ефекту Near-Far.
  final int totalSpread;

  /// Підсумковий зважений бал придатності сітки.
  final double totalScore;

  const AllocationScore({
    required this.imdMargin,
    required this.minSpacing,
    required this.totalSpread,
    required this.totalScore,
  });

  /// Розраховує бал за функцією Maximin:
  /// score = min(imdMargin, 50.0) * 100.0 + minSpacing * 10.0 + totalSpread * 0.1
  factory AllocationScore.calculate({
    required double imdMargin,
    required int minSpacing,
    required int totalSpread,
  }) {
    // Обмежуємо вплив IMD запасу понад 50 МГц (смуга фільтрів ПЧ ~17-20 МГц)
    final clampedImd = imdMargin > 50.0 ? 50.0 : imdMargin;
    final score =
        (clampedImd * 100.0) + (minSpacing * 10.0) + (totalSpread * 0.1);

    return AllocationScore(
      imdMargin: imdMargin,
      minSpacing: minSpacing,
      totalSpread: totalSpread,
      totalScore: score,
    );
  }

  @override
  int compareTo(AllocationScore other) =>
      totalScore.compareTo(other.totalScore);

  @override
  String toString() =>
      'AllocationScore(score: ${totalScore.toStringAsFixed(1)}, imd: ${imdMargin.toStringAsFixed(1)}MHz, Δf: ${minSpacing}MHz, spread: ${totalSpread}MHz)';
}
