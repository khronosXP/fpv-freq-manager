/// Реєстр парних різниць (Sidon Difference Map) для миттєвого відсікання
/// 4-хвильових резонансів та точних влучань Δ = 0 МГц.
class DiffMap {
  DiffMap._();

  /// Перевіряє, чи містить набір частот однакові парні різниці (Sidon collision).
  ///
  /// Математичне обґрунтування:
  /// Якщо |fa - fb| == |fc - fd|:
  /// 1) За 4 різних частот: fa + fd - fb = fc => точний Triple-Beat (Δ = 0 МГц).
  /// 2) За 3 частот (спільна fb): fa - fb == fb - fc => 2*fb - fa = fc (двотоновий IMD3, Δ = 0 МГц).
  ///
  /// Відтак будь-який дублікат різниці є фатальною інтермодуляційною колізією 0 МГц!
  static bool hasSymmetricResonance(List<int> sortedFrequencies) {
    final n = sortedFrequencies.length;
    if (n < 3) return false;

    final seenDiffs = <int>{};
    for (int i = 0; i < n; i++) {
      final f1 = sortedFrequencies[i];
      for (int j = i + 1; j < n; j++) {
        final diff = sortedFrequencies[j] - f1;
        if (!seenDiffs.add(diff)) {
          return true; // Знайдено резонанс Δ = 0 МГц!
        }
      }
    }
    return false;
  }

  /// Інкрементальна перевірка: чи можна додати [candidate] до [currentSorted]
  /// без утворення однакових різниць.
  static bool canAddWithoutCollision(List<int> currentSorted, int candidate) {
    final n = currentSorted.length;
    if (n < 2) return true;

    // Збираємо існуючі різниці
    final existingDiffs = <int>{};
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        existingDiffs.add(currentSorted[j] - currentSorted[i]);
      }
    }

    // Перевіряємо нові різниці з candidate
    final newDiffs = <int>{};
    for (int i = 0; i < n; i++) {
      final diff = (candidate - currentSorted[i]).abs();
      // Якщо така різниця вже існувала, або нова різниця дублюється:
      if (existingDiffs.contains(diff) || !newDiffs.add(diff)) {
        return false;
      }
    }

    return true;
  }
}
