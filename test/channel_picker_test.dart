import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_freq_manager/core/models/board_type.dart';
import 'package:fpv_freq_manager/core/models/manual_drone_slot.dart';
import 'package:fpv_freq_manager/presentation/widgets/manual/channel_picker_sheet.dart';

void main() {
  testWidgets('ChannelPickerSheet: Lowband slot shows only Band L channels', (
    tester,
  ) async {
    const slot = ManualDroneSlot(
      id: 1,
      boardNumber: 1,
      boardType: BoardType.lowband,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ChannelPickerSheet.show(
                context: context,
                targetSlot: slot,
                otherSlots: const [],
                onSelectChannel: (_) {},
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify Title with Lowband
    expect(find.textContaining('Lowband'), findsOneWidget);

    // Verify Band tabs are NOT shown for single-band Lowband
    expect(find.text('Band R'), findsNothing);
    expect(find.text('Band F'), findsNothing);

    // Verify Lowband channels are present
    expect(find.text('L1'), findsOneWidget);
    expect(find.text('5333 MHz'), findsOneWidget);

    // Verify Standard channels are NOT present
    expect(find.text('R1'), findsNothing);
    expect(find.text('F1'), findsNothing);
  });

  testWidgets('ChannelPickerSheet: X-band slot shows only Band X channels', (
    tester,
  ) async {
    const slot = ManualDroneSlot(
      id: 2,
      boardNumber: 2,
      boardType: BoardType.xBand,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ChannelPickerSheet.show(
                context: context,
                targetSlot: slot,
                otherSlots: const [],
                onSelectChannel: (_) {},
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify Title with X-band
    expect(find.textContaining('X-band'), findsOneWidget);

    // Verify Band tabs are NOT shown for single-band X-band
    expect(find.text('Band R'), findsNothing);

    // Verify X-band channels are present
    expect(find.text('X1'), findsOneWidget);
    expect(find.text('4990 MHz'), findsOneWidget);

    // Verify Standard channels are NOT present
    expect(find.text('L1'), findsNothing);
    expect(find.text('R1'), findsNothing);
  });

  testWidgets('ChannelPickerSheet: Standard slot shows R, F, A, B, E tabs', (
    tester,
  ) async {
    const slot = ManualDroneSlot(
      id: 3,
      boardNumber: 3,
      boardType: BoardType.standard,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ChannelPickerSheet.show(
                context: context,
                targetSlot: slot,
                otherSlots: const [],
                onSelectChannel: (_) {},
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify Title with Стандарт
    expect(find.textContaining('Стандарт'), findsOneWidget);

    // Verify Band tabs are present for standard 5.8 GHz
    expect(find.text('Band R'), findsOneWidget);
    expect(find.text('Band F'), findsOneWidget);
    expect(find.text('Band A'), findsOneWidget);
    expect(find.text('Band B'), findsOneWidget);
    expect(find.text('Band E'), findsOneWidget);

    // Verify Lowband and X-band are NOT present in tabs or list
    expect(find.text('Band L'), findsNothing);
    expect(find.text('Band X'), findsNothing);
  });
}
