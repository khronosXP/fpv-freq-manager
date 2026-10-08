import 'board_type.dart';
import 'fpv_channel.dart';

class AssignedBoard {
  final int boardNumber; // 1-indexed (Борт 1, Борт 2...)
  final BoardType boardType;
  final FpvChannel channel;

  const AssignedBoard({
    required this.boardNumber,
    required this.boardType,
    required this.channel,
  });

  String get label => 'Борт $boardNumber (${boardType.displayName})';
  String get fullDescription => '$label: ${channel.displayName}';

  @override
  String toString() => fullDescription;
}
