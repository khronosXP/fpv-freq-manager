import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_freq_manager/core/math/imd_validator.dart';

void main() {
  group('ImdValidator', () {
    test('Guard band: rejects frequencies closer than 40 MHz', () {
      // 5800 and 5820 are 20 MHz apart (< 40)
      expect(ImdValidator.hasValidGuardBands([5800, 5820]), isFalse);
      expect(ImdValidator.isValidSet([5800, 5820]), isFalse);

      // 5800 and 5840 are 40 MHz apart (>= 40)
      expect(ImdValidator.hasValidGuardBands([5800, 5840]), isTrue);
    });

    test('IMD3: detects 3rd order intermodulation collision within 10 MHz', () {
      // Suppose f1 = 5700, f2 = 5750.
      // 2*f1 - f2 = 11400 - 5750 = 5650.
      // If f3 = 5655, |5650 - 5655| = 5 MHz (< 10 MHz) -> collision!
      const f1 = 5700;
      const f2 = 5750;
      const f3 = 5655;

      expect(ImdValidator.hasNoImd3Collisions([f1, f2, f3]), isFalse);
      expect(ImdValidator.isValidSet([f1, f2, f3]), isFalse);

      final violations = ImdValidator.findViolations([f1, f2, f3]);
      expect(violations.any((v) => v.contains('IMD3')), isTrue);
    });

    test('TZ example set is 100% valid: R1(5658), F4(5800), L2(5373)', () {
      final freqs = [5658, 5800, 5373];
      expect(ImdValidator.hasValidGuardBands(freqs), isTrue);
      expect(ImdValidator.hasNoImd3Collisions(freqs), isTrue);
      expect(ImdValidator.isValidSet(freqs), isTrue);
      expect(ImdValidator.findViolations(freqs), isEmpty);
    });

    test('canAddFrequency incrementally agrees with isValidSet', () {
      final current = [5658, 5800];
      // 5373 can be added
      expect(ImdValidator.canAddFrequency(current, 5373), isTrue);
      expect(ImdValidator.isValidSet([...current, 5373]), isTrue);

      // 5820 violates guard band with 5800 (diff 20 MHz)
      expect(ImdValidator.canAddFrequency(current, 5820), isFalse);

      // 2*5800 - 5658 = 5942. A frequency at 5940 has diff 2 MHz (< 10 MHz)
      expect(ImdValidator.canAddFrequency(current, 5940), isFalse);
    });

    test(
      'Triple-Beat IMD3: detects 3-tone collision in user 6-drone grid (diff = 0 MHz)',
      () {
        // User grid:
        // E3: 5665, R3: 5732, A5: 5785, A3: 5825, F8: 5880, E8: 5945
        // 5665 + 5945 - 5785 = 5825 (diff = 0 MHz on A3!)
        final userGrid = [5665, 5732, 5785, 5825, 5880, 5945];

        // Guard bands are all >= 40 MHz
        expect(ImdValidator.hasValidGuardBands(userGrid), isTrue);

        // Under 10 MHz marginal tolerance, two-tone check passes:
        expect(
          ImdValidator.hasNoTwoToneCollisions(
            userGrid,
            minDistance: ImdValidator.marginalImdDistance,
          ),
          isTrue,
        );

        // Triple-beat check FAILS even under marginal tolerance (diff = 0 MHz)!
        expect(
          ImdValidator.hasNoTripleBeatCollisions(
            userGrid,
            minDistance: ImdValidator.marginalImdDistance,
          ),
          isFalse,
        );
        expect(
          ImdValidator.hasNoImd3Collisions(
            userGrid,
            minDistance: ImdValidator.marginalImdDistance,
          ),
          isFalse,
        );
        expect(
          ImdValidator.isValidSet(
            userGrid,
            minDistance: ImdValidator.marginalImdDistance,
          ),
          isFalse,
        );

        final violations = ImdValidator.findViolations(userGrid);
        expect(violations.any((v) => v.contains('Triple-beat IMD3')), isTrue);
      },
    );

    test('canAddFrequency rejects candidate causing Triple-Beat', () {
      final current = [5665, 5785, 5825]; // E3, A5, A3
      // Candidate E8: 5945 causes 5785 + 5825 - 5665 = 5945 (0 MHz diff!)
      expect(ImdValidator.canAddFrequency(current, 5945), isFalse);
    });

    test(
      'Clean 6-drone standard grid achieves 10 MHz physical ceiling under marginal tolerance',
      () {
        // Set 1: E4(5645), R2(5695), A6(5765), A4(5805), A1(5865), E8(5945)
        final cleanGrid = [5645, 5695, 5765, 5805, 5865, 5945];
        expect(ImdValidator.hasValidGuardBands(cleanGrid), isTrue);
        expect(
          ImdValidator.hasNoTwoToneCollisions(
            cleanGrid,
            minDistance: ImdValidator.marginalImdDistance,
          ),
          isTrue,
        );
        expect(
          ImdValidator.hasNoTripleBeatCollisions(
            cleanGrid,
            minDistance: ImdValidator.marginalImdDistance,
          ),
          isTrue,
        );
        expect(
          ImdValidator.isValidSet(
            cleanGrid,
            minDistance: ImdValidator.marginalImdDistance,
          ),
          isTrue,
        );
      },
    );

    test(
      'Rejects borderline 10 MHz grid [5645, 5685, 5740, 5805] under safe 12 MHz threshold',
      () {
        // Borderline grid criticized for sitting on the edge of the IF filter:
        // 2*5740 - 5685 = 5795 (diff 10 MHz to 5805, unsafe for IF SAW filter)
        final borderlineGrid = [5645, 5685, 5740, 5805];
        expect(ImdValidator.hasValidGuardBands(borderlineGrid), isTrue);
        expect(ImdValidator.hasNoTwoToneCollisions(borderlineGrid), isFalse);
        expect(ImdValidator.isValidSet(borderlineGrid), isFalse);

        final violations = ImdValidator.findViolations(borderlineGrid);
        expect(violations.any((v) => v.contains('Two-tone IMD3')), isTrue);
      },
    );

    test(
      'Clean 4-drone grids [5645, 5685, 5740, 5880 / 5820] pass strict 12 MHz & 15 MHz safety',
      () {
        // Critic proposed grid with R7: 5880:
        final criticGrid = [5645, 5685, 5740, 5880];
        expect(ImdValidator.isValidSet(criticGrid), isTrue);
        expect(ImdValidator.isValidSet(criticGrid, minDistance: 15), isTrue);

        // Optimal generator grid with F5: 5820:
        final optGrid = [5645, 5685, 5740, 5820];
        expect(ImdValidator.isValidSet(optGrid), isTrue);
        expect(ImdValidator.isValidSet(optGrid, minDistance: 15), isTrue);
      },
    );

    test('Critic 9-drone proposed grid has fatal 0 MHz collisions', () {
      // Proposed by critic:
      // X1(4990), X6(5140), L1(5333), L4(5453), R1(5658), B1(5700), F2(5760), F5(5820), R7(5880)
      final criticGrid9 = [4990, 5140, 5333, 5453, 5658, 5700, 5760, 5820, 5880];
      final violations = ImdValidator.findViolations(criticGrid9, minDistance: 10);
      expect(violations.isNotEmpty, isTrue);

      // Demonstrates catastrophic 0 MHz hits:
      // 2*5760 - 5700 = 5820 (diff = 0 MHz on F5!)
      // 2*5820 - 5880 = 5760 (diff = 0 MHz on F2!)
      // 2*5820 - 5760 = 5880 (diff = 0 MHz on R7!)
      // 5700 + 5453 - 5333 = 5820 (diff = 0 MHz on F5!)
      final zeroHits = violations.where((v) => v.contains('diff = 0MHz')).toList();
      expect(zeroHits.length, greaterThanOrEqualTo(10));
    });
  });
}
