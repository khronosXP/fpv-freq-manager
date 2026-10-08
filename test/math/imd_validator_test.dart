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
  });
}
