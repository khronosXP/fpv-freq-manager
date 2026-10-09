import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_freq_manager/core/constants/fpv_frequencies.dart';
import 'package:fpv_freq_manager/core/math/conflict_analyzer.dart';
import 'package:fpv_freq_manager/core/math/grid_auto_resolver.dart';
import 'package:fpv_freq_manager/core/models/board_type.dart';
import 'package:fpv_freq_manager/core/models/manual_drone_slot.dart';

void main() {
  const analyzer = ConflictAnalyzer();
  const resolver = GridAutoResolver(analyzer: analyzer);

  group('GridAutoResolver', () {
    test('Resolves direct collision while preserving locked slot', () {
      final slots = [
        // Board 1 locked to R1 (5658)
        ManualDroneSlot(
          id: 1,
          boardNumber: 1,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandR[0], // R1: 5658
          isLocked: true,
        ),
        // Board 2 unlocked, initially on R2 (5695 - collides with R1 Δf=37)
        ManualDroneSlot(
          id: 2,
          boardNumber: 2,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandR[1], // R2: 5695
          isLocked: false,
        ),
      ];

      final result = resolver.resolve(slots);
      expect(result.isSuccess, isTrue);

      final resolvedSlots = result.resolvedSlots;
      // Locked board 1 MUST still be R1 (5658)
      expect(resolvedSlots[0].channel?.code, equals('R1'));
      expect(resolvedSlots[0].channel?.frequency, equals(5658));

      // Board 2 MUST be changed to a clean channel
      expect(resolvedSlots[1].channel?.code, isNot(equals('R2')));
      expect(result.changedSlotIds, contains(2));
      expect(result.changedSlotIds, isNot(contains(1)));

      // Resulting grid must be completely clean
      final report = analyzer.analyze(resolvedSlots);
      expect(report.isClean, isTrue);
    });

    test('Fails gracefully when locked boards mutually collide', () {
      final slots = [
        ManualDroneSlot(
          id: 1,
          boardNumber: 1,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandR[0], // R1: 5658
          isLocked: true,
        ),
        ManualDroneSlot(
          id: 2,
          boardNumber: 2,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandR[1], // R2: 5695 (collides with R1)
          isLocked: true, // Both locked!
        ),
      ];

      final result = resolver.resolve(slots);
      expect(result.isSuccess, isFalse);
      expect(
        result.errorMessage,
        contains('зафіксовані канали (🔒) конфліктують між собою'),
      );
    });
  });
}
