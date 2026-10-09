import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_freq_manager/presentation/screens/calculator_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const ProviderScope(child: MaterialApp(home: CalculatorScreen()));
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('CalculatorScreen switches to manual mode and displays slots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify initial auto mode
    expect(find.text('Авто-розрахунок'), findsOneWidget);
    expect(find.text('Ручний інспектор'), findsOneWidget);
    expect(find.text('Стандартні борти (A, B, E, F, R)'), findsOneWidget);

    // Tap 'Ручний інспектор'
    await tester.tap(find.text('Ручний інспектор'));
    await tester.pumpAndSettle();

    // Now in manual mode
    expect(find.text('СІТКА БЕЗПЕЧНА (ЧИСТИЙ ЕФІР)'), findsOneWidget);
    expect(find.text('Борт 1'), findsOneWidget);
    expect(find.text('Борт 2'), findsOneWidget);
    expect(find.text('2 / 12 бортів'), findsOneWidget);
    expect(find.text('R1'), findsOneWidget);
    expect(find.text('R4'), findsOneWidget);
  });

  testWidgets('Manual mode: toggle lock on a slot', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Switch to manual mode
    await tester.tap(find.text('Ручний інспектор'));
    await tester.pumpAndSettle();

    // Find unlock icon
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

  testWidgets('Manual mode: conflict detection and auto-healing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Switch to manual mode
    await tester.tap(find.text('Ручний інспектор'));
    await tester.pumpAndSettle();

    // Add a 3rd board
    await tester.tap(find.text('Додати борт'));
    await tester.pumpAndSettle();

    // Tap '+ Стандартний (5.8G)' in popup
    await tester.tap(find.text('+ Стандартний (5.8G)'));
    await tester.pumpAndSettle();

    // Board 3 added with R1 by default, which clashes with Board 1 (R1)!
    expect(find.text('Борт 3'), findsOneWidget);
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
    'Auto mode calculation automatically syncs boards to manual inspector on switch',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // In auto mode, increment to 4 standard boards (initial is 2)
      final incBtn = find.widgetWithIcon(IconButton, Icons.add).first;
      await tester.tap(incBtn);
      await tester.pumpAndSettle();
      await tester.tap(incBtn);
      await tester.pumpAndSettle();

      // Tap calculate
      final calcBtn = find.textContaining('Розрахувати сітку');
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      // Now switch to 'Ручний інспектор'
      await tester.tap(find.text('Ручний інспектор'));
      await tester.pumpAndSettle();

      // All 4 boards should be automatically synced to manual inspector!
      expect(find.text('4 / 12 бортів'), findsOneWidget);
      expect(find.text('Борт 1'), findsOneWidget);
      expect(find.text('Борт 2'), findsOneWidget);
      expect(find.text('Борт 3'), findsOneWidget);
      expect(find.text('Борт 4'), findsOneWidget);
      expect(find.text('З розрахунку (4)'), findsOneWidget);
    },
  );
}
