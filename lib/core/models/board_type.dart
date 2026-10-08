enum BoardType {
  standard,
  lowband,
  xBand;

  String get displayName {
    switch (this) {
      case BoardType.standard:
        return 'Стандарт';
      case BoardType.lowband:
        return 'Lowband';
      case BoardType.xBand:
        return 'X-band';
    }
  }

  String get shortLabel {
    switch (this) {
      case BoardType.standard:
        return 'СТД';
      case BoardType.lowband:
        return 'LOW';
      case BoardType.xBand:
        return 'X-B';
    }
  }
}
