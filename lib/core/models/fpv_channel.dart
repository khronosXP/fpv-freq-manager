import 'board_type.dart';

enum BandCategory {
  standard,
  lowband,
  xBand;

  bool isCompatibleWith(BoardType boardType) {
    switch (boardType) {
      case BoardType.standard:
        return this == BandCategory.standard;
      case BoardType.lowband:
        return this == BandCategory.lowband || this == BandCategory.standard;
      case BoardType.xBand:
        return this == BandCategory.xBand || this == BandCategory.standard;
    }
  }
}

class FpvChannel {
  final String bandName; // 'A', 'B', 'E', 'F', 'R', 'L', 'X'
  final int channelNumber; // 1..8
  final int frequency; // in MHz (e.g. 5658)
  final BandCategory category;

  const FpvChannel({
    required this.bandName,
    required this.channelNumber,
    required this.frequency,
    required this.category,
  });

  String get code => '$bandName$channelNumber';

  String get displayName => '$code ($frequency)';

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FpvChannel &&
          runtimeType == other.runtimeType &&
          frequency == other.frequency &&
          code == other.code;

  @override
  int get hashCode => frequency.hashCode ^ code.hashCode;
}
