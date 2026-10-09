import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_freq_manager/core/constants/fpv_frequencies.dart';
import 'package:fpv_freq_manager/core/math/conflict_analyzer.dart';
import 'package:fpv_freq_manager/core/models/board_type.dart';
import 'package:fpv_freq_manager/core/models/manual_drone_slot.dart';

void main() {
  const analyzer = ConflictAnalyzer();

  group('ConflictAnalyzer', () {
    test('Empty or single slot produces clean report', () {
      expect(analyzer.analyze([]).isClean, isTrue);

      final single = [
        ManualDroneSlot(
          id: 1,
          boardNumber: 1,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandR[0], // R1: 5658
        ),
      ];
      expect(analyzer.analyze(single).isClean, isTrue);
    });

    test('Detects direct guard band collision (Δf < 40 MHz)', () {
      final slots = [
        ManualDroneSlot(
          id: 1,
          boardNumber: 1,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandR[0], // R1: 5658
        ),
        ManualDroneSlot(
          id: 2,
          boardNumber: 2,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandR[1], // R2: 5695 (diff = 37 < 40)
        ),
      ];

      final report = analyzer.analyze(slots);
      expect(report.hasCollisions, isTrue);
      expect(report.directCollisions.length, equals(1));
      expect(report.directCollisions.first.delta, equals(37));
      expect(report.conflictedSlotIds, containsAll([1, 2]));
    });

    test('Detects IMD3 collision and provides clean suggestions', () {
      // R1: 5658, R3: 5732 -> 2*R3 - R1 = 11464 - 5658 = 5806 (hits R5: 5806!)
      final slots = [
        ManualDroneSlot(
          id: 1,
          boardNumber: 1,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandR[0], // R1: 5658
        ),
        ManualDroneSlot(
          id: 2,
          boardNumber: 2,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandR[2], // R3: 5732
        ),
        ManualDroneSlot(
          id: 3,
          boardNumber: 3,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandR[4], // R5: 5806 (IMD3 hit!)
        ),
      ];

      final report = analyzer.analyze(slots);
      expect(report.hasCollisions, isTrue);
      expect(report.imdCollisions.isNotEmpty, isTrue);
      expect(report.conflictedSlotIds, containsAll([1, 2, 3]));

      // Slot 3 should have alternative clean suggestions
      final suggestions = report.suggestionsBySlotId[3];
      expect(suggestions, isNotNull);
      expect(suggestions!.isNotEmpty, isTrue);
    });
  });
}
