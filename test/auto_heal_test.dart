import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_freq_manager/core/constants/fpv_frequencies.dart';
import 'package:fpv_freq_manager/core/math/conflict_analyzer.dart';
import 'package:fpv_freq_manager/core/math/grid_auto_resolver.dart';
import 'package:fpv_freq_manager/core/math/imd_validator.dart';
import 'package:fpv_freq_manager/core/models/board_type.dart';
import 'package:fpv_freq_manager/core/models/manual_drone_slot.dart';
import 'package:fpv_freq_manager/presentation/providers/fleet_provider.dart';

void main() {
  group('GridAutoResolver Unit Tests (ADR-012)', () {
    const resolver = GridAutoResolver();
    const analyzer = ConflictAnalyzer();

    test(
      'Test 1: Smart Micro-Fix resolves collision preserving locked board',
      () {
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
            channel: FpvFrequencies.bandR[1], // R2: 5695 (diff = 37 < 40)
            isLocked: false,
          ),
        ];

        final reportBefore = analyzer.analyze(slots);
        expect(reportBefore.hasCollisions, isTrue);

        final result = resolver.resolve(slots);
        expect(result.isSuccess, isTrue);
        expect(result.changedSlotIds, contains(2));
        expect(result.changedSlotIds, isNot(contains(1)));

        final board1 = result.resolvedSlots.firstWhere((s) => s.id == 1);
        final board2 = result.resolvedSlots.firstWhere((s) => s.id == 2);
        expect(board1.channel?.code, equals('R1')); // Locked preserved
        expect(board2.channel?.code, isNot(equals('R2'))); // Shifted

        final reportAfter = analyzer.analyze(result.resolvedSlots);
        expect(reportAfter.isClean, isTrue);
      },
    );

    test('Test 2: Mutual locked collision fails early at Tier 0', () {
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
          channel: FpvFrequencies.bandR[1], // R2: 5695 (diff = 37)
          isLocked: true,
        ),
      ];

      final result = resolver.resolve(slots);
      expect(result.isSuccess, isFalse);
      expect(
        result.errorMessage,
        contains('зафіксовані канали (🔒) конфліктують'),
      );
    });

    test('Test 3: Adaptive IMD floor allows resolving 6 standard boards', () {
      // 6 boards with a valid anchor locked (E4 = 5645)
      final e4 = FpvFrequencies.standardChannels.firstWhere(
        (c) => c.frequency == 5645,
      );
      final slots = List.generate(
        6,
        (i) => ManualDroneSlot(
          id: i + 1,
          boardNumber: i + 1,
          boardType: BoardType.standard,
          channel: i == 0 ? e4 : FpvFrequencies.bandR[i],
          isLocked: i == 0,
        ),
      );

      final result = resolver.resolve(slots);
      expect(result.isSuccess, isTrue);
      expect(result.resolvedSlots.length, equals(6));

      final freqs = result.resolvedSlots
          .map((s) => s.channel!.frequency)
          .toList();
      expect(ImdValidator.isValidSet(freqs, minDistance: 10), isTrue);
    });

    test(
      'Test 4: Strict Band Isolation ensures lowband channels stay in lowband',
      () {
        final slots = [
          ManualDroneSlot(
            id: 1,
            boardNumber: 1,
            boardType: BoardType.lowband,
            channel: FpvFrequencies.lowbandChannels[0], // L1: 5333
            isLocked: false,
          ),
          ManualDroneSlot(
            id: 2,
            boardNumber: 2,
            boardType: BoardType.lowband,
            channel: FpvFrequencies.lowbandChannels[0], // L1: 5333 (collision)
            isLocked: false,
          ),
        ];

        final result = resolver.resolve(slots);
        expect(result.isSuccess, isTrue);
        for (final slot in result.resolvedSlots) {
          expect(slot.boardType, equals(BoardType.lowband));
          expect(
            FpvFrequencies.lowbandChannels.any(
              (c) => c.frequency == slot.channel!.frequency,
            ),
            isTrue,
          );
        }
      },
    );

    test('Test 5: Unassigned slot (channel == null) is cleanly populated', () {
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
          channel: null,
          isLocked: false,
        ),
      ];

      final result = resolver.resolve(slots);
      expect(result.isSuccess, isTrue);
      expect(result.resolvedSlots[1].channel, isNotNull);
      expect(result.resolvedSlots[0].channel?.code, equals('R1'));

      final report = analyzer.analyze(result.resolvedSlots);
      expect(report.isClean, isTrue);
    });
  });

  group('FleetNotifier Two-Tier Auto-Healing Pipeline Integration', () {
    test(
      'autoHealUnlocked resolves colliding unlocked boards with status message',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(fleetProvider.notifier);

        // Force collision: assign R1 and R2
        notifier.assignChannel(1, FpvFrequencies.bandR[0]); // R1: 5658
        notifier.assignChannel(2, FpvFrequencies.bandR[1]); // R2: 5695

        expect(container.read(fleetProvider).hasConflicts, isTrue);

        await notifier.autoHealUnlocked();

        final state = container.read(fleetProvider);
        expect(state.hasConflicts, isFalse);
        expect(state.lastStatusMessage, isNotNull);
        expect(state.lastStatusMessage, contains('Виправлено'));
      },
    );

    test(
      'autoHealUnlocked reports mutual lock collision without modifying slots',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(fleetProvider.notifier);

        // Lock both on colliding channels
        notifier.assignChannel(1, FpvFrequencies.bandR[0]); // R1: 5658
        notifier.toggleLock(1);
        notifier.assignChannel(2, FpvFrequencies.bandR[1]); // R2: 5695
        notifier.toggleLock(2);

        expect(container.read(fleetProvider).hasConflicts, isTrue);

        await notifier.autoHealUnlocked();

        final state = container.read(fleetProvider);
        expect(state.hasConflicts, isTrue);
        expect(
          state.lastStatusMessage,
          contains('зафіксовані канали (🔒) конфліктують'),
        );
        expect(state.slots[0].channel?.code, equals('R1'));
        expect(state.slots[1].channel?.code, equals('R2'));
      },
    );
  });
}
