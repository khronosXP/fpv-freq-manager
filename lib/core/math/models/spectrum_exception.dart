import '../../models/board_type.dart';

/// Виключення вичерпання фізичної ємності спектру під задані радіофізичні обмеження.
class SpectrumExhaustedException implements Exception {
  final BoardType boardType;
  final int requestedCount;
  final String message;

  const SpectrumExhaustedException({
    required this.boardType,
    required this.requestedCount,
    required this.message,
  });

  factory SpectrumExhaustedException.exceededCapacity({
    required BoardType boardType,
    required int requestedCount,
    required int maxCapacity,
  }) {
    return SpectrumExhaustedException(
      boardType: boardType,
      requestedCount: requestedCount,
      message:
          'У діапазоні ${boardType.label} фізично неможливо розмістити $requestedCount бортів '
          'без прямих інтермодуляційних колізій (фізична межа: $maxCapacity). '
          'Зменшіть кількість бортів або розподіліть їх між іншими діапазонами.',
    );
  }

  factory SpectrumExhaustedException.noCleanGrid({
    required BoardType boardType,
    required int requestedCount,
  }) {
    return SpectrumExhaustedException(
      boardType: boardType,
      requestedCount: requestedCount,
      message:
          'Неможливо підібрати чисту сітку для $requestedCount бортів у діапазоні ${boardType.label} '
          'із дотриманням Δf ≥ 40 МГц та IMD3 ≥ 10 МГц.',
    );
  }

  @override
  String toString() => 'SpectrumExhaustedException: $message';
}
