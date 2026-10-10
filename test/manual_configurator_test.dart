import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_freq_manager/core/constants/fpv_frequencies.dart';
import 'package:fpv_freq_manager/presentation/providers/fleet_provider.dart';
import 'package:fpv_freq_manager/presentation/screens/calculator_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const ProviderScope(child: MaterialApp(home: CalculatorScreen()));
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets(
    'Unified Fleet Canvas: displays slots directly without modal switching',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // In unified mode, both counters and interactive slots are visible immediately
      expect(find.text('Стандартні борти (A, B, E, F, R)'), findsOneWidget);
      expect(find.text('СІТКА БЕЗПЕЧНА (ЧИСТИЙ ЕФІР)'), findsOneWidget);
      expect(find.text('Борт 1'), findsWidgets);
      expect(find.text('Борт 2'), findsWidgets);
      expect(find.text('R1'), findsWidgets);
      expect(find.text('R4'), findsWidgets);
    },
  );

  testWidgets('Unified Canvas: toggle lock on a slot', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Find unlock icon on the first slot
    final unlockIcons = find.byIcon(Icons.lock_open);
    expect(unlockIcons, findsWidgets);

    await tester.ensureVisible(unlockIcons.first);
    await tester.pumpAndSettle();

    // Tap first unlock icon to lock it
    await tester.tap(unlockIcons.first);
    await tester.pumpAndSettle();

    // One lock icon should now be active
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('Unified Canvas: conflict detection and 1-click auto-healing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const CalculatorScreen();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Force a conflict by setting Board 2 to R1 (same as Board 1)
    capturedRef
        .read(fleetProvider.notifier)
        .assignChannel(2, FpvFrequencies.bandR[0]);
    await tester.pumpAndSettle();

    // Collision banner appears immediately in real-time
    expect(find.textContaining('КОЛІЗІЇ:'), findsOneWidget);

    final autoFixBtn = find.text('Автовиправлення');
    expect(autoFixBtn, findsOneWidget);

    await tester.ensureVisible(autoFixBtn);
    await tester.pumpAndSettle();

    // Tap auto-heal
    await tester.tap(autoFixBtn);
    await tester.pumpAndSettle();

    // Conflicts should be resolved!
    expect(find.text('СІТКА БЕЗПЕЧНА (ЧИСТИЙ ЕФІР)'), findsOneWidget);
  });

  testWidgets(
    'Unified Canvas: incrementing fleet size reactively adds slots and computes optimal grid',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Increment to 4 standard boards (initial is 2)
      final incBtn = find.widgetWithIcon(IconButton, Icons.add).first;
      await tester.tap(incBtn);
      await tester.pumpAndSettle();
      await tester.tap(incBtn);
      await tester.pumpAndSettle();

      // 4 slots are displayed immediately
      expect(find.text('Борт 1'), findsWidgets);
      expect(find.text('Борт 2'), findsWidgets);
      expect(find.text('Борт 3'), findsWidgets);
      expect(find.text('Борт 4'), findsWidgets);

      // Tap calculate
      final calcBtn = find.textContaining('Розрахувати сітку');
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      // Grid is clean and verified
      expect(find.text('СІТКА БЕЗПЕЧНА (ЧИСТИЙ ЕФІР)'), findsOneWidget);
    },
  );
}
