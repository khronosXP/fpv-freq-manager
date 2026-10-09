import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_freq_manager/core/constants/fpv_frequencies.dart';
import 'package:fpv_freq_manager/core/math/conflict_analyzer.dart';
import 'package:fpv_freq_manager/core/math/imd_validator.dart';
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

    test('Detects Triple-Beat IMD3 collisions in 6-drone grid (diff = 0 MHz)', () {
      // User grid:
      // Борт 1: E3 (5665)
      // Борт 2: R3 (5732)
      // Борт 3: A5 (5785)
      // Борт 4: A3 (5825)
      // Борт 5: F8 (5880)
      // Борт 6: E8 (5945)
      final slots = [
        ManualDroneSlot(
          id: 1,
          boardNumber: 1,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandE[2], // E3: 5665
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
          channel: FpvFrequencies.bandA[4], // A5: 5785
        ),
        ManualDroneSlot(
          id: 4,
          boardNumber: 4,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandA[2], // A3: 5825
        ),
        ManualDroneSlot(
          id: 5,
          boardNumber: 5,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandF[7], // F8: 5880
        ),
        ManualDroneSlot(
          id: 6,
          boardNumber: 6,
          boardType: BoardType.standard,
          channel: FpvFrequencies.bandE[7], // E8: 5945
        ),
      ];

      final report = analyzer.analyze(slots);
      expect(report.hasCollisions, isTrue);
      expect(report.directCollisions, isEmpty); // Guard bands are >= 40 MHz
      // Under safe 12 MHz threshold, 2*5880 - 5825 = 5935 vs 5945 (diff = 10 < 12) is also flagged
      expect(report.imdCollisions.isNotEmpty, isTrue);
      expect(report.tripleBeatCollisions.isNotEmpty, isTrue);

      // Contains the exact 0 MHz hit: E3(5665) + E8(5945) - A5(5785) = 5825 (A3!)
      final zeroHit = report.tripleBeatCollisions.any(
        (tb) =>
            tb.distance == 0 &&
            tb.victim.id == 4 && // Slot 4 (A3)
            tb.beatFrequency == 5825,
      );
      expect(zeroHit, isTrue);
      expect(report.conflictedSlotIds, containsAll([1, 3, 4, 6]));
    });

    test(
      'Detects borderline 10 MHz conflict in [5645, 5685, 5740, 5805] and provides clean suggestions >= 12 MHz',
      () {
        final slots = [
          ManualDroneSlot(
            id: 1,
            boardNumber: 1,
            boardType: BoardType.standard,
            channel: FpvFrequencies.bandE[3], // E4: 5645
          ),
          ManualDroneSlot(
            id: 2,
            boardNumber: 2,
            boardType: BoardType.standard,
            channel: FpvFrequencies.bandE[1], // E2: 5685
          ),
          ManualDroneSlot(
            id: 3,
            boardNumber: 3,
            boardType: BoardType.standard,
            channel: FpvFrequencies.bandF[0], // F1: 5740
          ),
          ManualDroneSlot(
            id: 4,
            boardNumber: 4,
            boardType: BoardType.standard,
            channel: FpvFrequencies.bandA[3], // A4: 5805
          ),
        ];

        final report = analyzer.analyze(slots);
        expect(report.hasCollisions, isTrue);
        expect(
          report.imdCollisions.isNotEmpty,
          isTrue,
        ); // 2*5740 - 5685 = 5795 vs 5805 (diff = 10 < 12)
        expect(report.conflictedSlotIds, contains(4));

        final suggestions = report.suggestionsBySlotId[4];
        expect(suggestions, isNotNull);
        expect(suggestions!.isNotEmpty, isTrue);

        // Every suggested channel must be 100% clean under safe >= 12 MHz standard!
        for (final alt in suggestions) {
          final testSet = [5645, 5685, 5740, alt.frequency];
          expect(ImdValidator.isValidSet(testSet), isTrue);
        }
      },
    );
  });
}
