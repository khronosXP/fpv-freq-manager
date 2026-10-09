import 'board_type.dart';
import 'fpv_channel.dart';

class ManualDroneSlot {
  final int id;
  final int boardNumber;
  final BoardType boardType;
  final FpvChannel? channel;
  final bool isLocked;

  const ManualDroneSlot({
    required this.id,
    required this.boardNumber,
    required this.boardType,
    this.channel,
    this.isLocked = false,
  });

  bool get isAssigned => channel != null;

  ManualDroneSlot copyWith({
    int? id,
    int? boardNumber,
    BoardType? boardType,
    FpvChannel? Function()? channel,
    bool? isLocked,
  }) {
    return ManualDroneSlot(
      id: id ?? this.id,
      boardNumber: boardNumber ?? this.boardNumber,
      boardType: boardType ?? this.boardType,
      channel: channel != null ? channel() : this.channel,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualDroneSlot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          boardNumber == other.boardNumber &&
          boardType == other.boardType &&
          channel == other.channel &&
          isLocked == other.isLocked;

  @override
  int get hashCode =>
      id.hashCode ^
      boardNumber.hashCode ^
      boardType.hashCode ^
      channel.hashCode ^
      isLocked.hashCode;
}
