import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_freq_manager/core/math/frequency_allocator.dart';
import 'package:fpv_freq_manager/core/math/imd_validator.dart';
import 'package:fpv_freq_manager/core/constants/fpv_frequencies.dart';
import 'package:fpv_freq_manager/core/models/board_type.dart';
import 'package:fpv_freq_manager/core/models/fpv_channel.dart';

void main() {
  const allocator = FrequencyAllocator();

  group('FrequencyAllocator', () {
    test('Zero boards returns empty success', () {
      final result = allocator.allocate(
        numStandard: 0,
        numLowband: 0,
        numXBand: 0,
      );
      expect(result.isSuccess, isTrue);
      expect(result.boards, isEmpty);
      expect(result.errorMessage, isNull);
    });

    test('Allocates clean channels for 4 standard boards', () {
      final result = allocator.allocate(
        numStandard: 4,
        numLowband: 0,
        numXBand: 0,
      );
      expect(result.isSuccess, isTrue);
      expect(result.boards.length, equals(4));

      final freqs = result.boards.map((b) => b.channel.frequency).toList();

      // Check all constraints
      expect(ImdValidator.isValidSet(freqs), isTrue);

      // All channels must belong to standard category
      for (final board in result.boards) {
        expect(board.channel.category, equals(BandCategory.standard));
        expect(board.boardType, equals(BoardType.standard));
      }
    });

    test('Allocates clean channels for 5 standard boards (safe >= 12-15 MHz)', () {
      final result = allocator.allocate(
        numStandard: 5,
        numLowband: 0,
        numXBand: 0,
      );
      expect(result.isSuccess, isTrue);
      expect(result.boards.length, equals(5));
      for (final b in result.boards) {
        // ignore: avoid_print
        print('5-STD BOARD: ${b.boardNumber}: ${b.channel.code} (${b.channel.frequency} MHz)');
      }
      final freqs = result.boards.map((b) => b.channel.frequency).toList();
      expect(ImdValidator.isValidSet(freqs, minDistance: 12), isTrue);
    });

    test('Allocates mixed setup: 2 standard, 2 lowband, 1 x-band', () {
      final result = allocator.allocate(
        numStandard: 2,
        numLowband: 2,
        numXBand: 1,
      );
      expect(result.isSuccess, isTrue);
      expect(result.boards.length, equals(5));

      final freqs = result.boards.map((b) => b.channel.frequency).toList();
      expect(ImdValidator.isValidSet(freqs), isTrue);

      // Verify routing pool constraints
      final standardBoards = result.boards.where(
        (b) => b.boardType == BoardType.standard,
      );
      for (final b in standardBoards) {
        expect(b.channel.category, equals(BandCategory.standard));
      }

      final lowbandBoards = result.boards.where(
        (b) => b.boardType == BoardType.lowband,
      );
      for (final b in lowbandBoards) {
        expect(
          b.channel.category == BandCategory.lowband ||
              b.channel.category == BandCategory.standard,
          isTrue,
        );
      }

      final xBoards = result.boards.where(
        (b) => b.boardType == BoardType.xBand,
      );
      for (final b in xBoards) {
        expect(
          b.channel.category == BandCategory.xBand ||
              b.channel.category == BandCategory.standard,
          isTrue,
        );
      }
    });

    test(
      'Handles overflow: returns specified error message when clean set is impossible',
      () {
        // Requesting 15 standard boards in standard 5.8GHz spectrum cannot satisfy Δf >= 40 + IMD3
        final result = allocator.allocate(
          numStandard: 15,
          numLowband: 0,
          numXBand: 0,
        );
        expect(result.isSuccess, isFalse);
        expect(result.boards, isEmpty);
        expect(
          result.errorMessage,
          equals(
            'Неможливо підібрати чисті частоти для заданої кількості бортів. '
            'Зменшіть кількість бортів або активуйте розширені діапазони.',
          ),
        );
      },
    );

    test('Board numbering is sequential from 1 to N', () {
      final result = allocator.allocate(
        numStandard: 2,
        numLowband: 1,
        numXBand: 1,
      );
      expect(result.isSuccess, isTrue);
      final numbers = result.boards.map((b) => b.boardNumber).toList();
      expect(numbers, equals([1, 2, 3, 4]));
    });

    test(
      'Allocates clean channels for 6 standard boards (verified against Triple-Beat)',
      () {
        final result = allocator.allocate(
          numStandard: 6,
          numLowband: 0,
          numXBand: 0,
        );
        expect(result.isSuccess, isTrue);
        expect(result.boards.length, equals(6));

        final freqs = result.boards.map((b) => b.channel.frequency).toList();
        expect(ImdValidator.hasValidGuardBands(freqs), isTrue);
        expect(
          ImdValidator.hasNoTwoToneCollisions(
            freqs,
            minDistance: ImdValidator.marginalImdDistance,
          ),
          isTrue,
        );
        expect(
          ImdValidator.hasNoTripleBeatCollisions(
            freqs,
            minDistance: ImdValidator.marginalImdDistance,
          ),
          isTrue,
        );
        expect(
          ImdValidator.isValidSet(
            freqs,
            minDistance: ImdValidator.marginalImdDistance,
          ),
          isTrue,
        );
      },
    );

    test('High-performance allocation completes in under 50ms', () {
      final sw = Stopwatch()..start();
      for (final (std, low, x, expectedSuccess) in [
        (2, 0, 0, true),
        (4, 0, 0, true),
        (6, 0, 0, true),
        (6, 1, 0, true),
        (4, 2, 2, true),
        (6, 2, 0, false),
        (4, 4, 4, false),
        (6, 6, 0, false),
      ]) {
        sw.reset();
        final res = allocator.allocate(
          numStandard: std,
          numLowband: low,
          numXBand: x,
        );
        expect(res.isSuccess, equals(expectedSuccess));
        expect(sw.elapsedMilliseconds, lessThan(50));
      }
    });

    test('Allocates clean 9-drone grid (5 standard, 2 lowband, 2 x-band)', () {
      final result = allocator.allocate(
        numStandard: 5,
        numLowband: 2,
        numXBand: 2,
      );
      expect(result.isSuccess, isTrue);
      expect(result.boards.length, equals(9));
      final freqs = result.boards.map((b) => b.channel.frequency).toList();
      expect(
        ImdValidator.isValidSet(
          freqs,
          minDistance: ImdValidator.marginalImdDistance,
        ),
        isTrue,
      );
    });
  });
}
