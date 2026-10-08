import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_freq_manager/main.dart';
import 'package:fpv_freq_manager/presentation/widgets/rf_spectrum_chart.dart';
import 'package:fpv_freq_manager/presentation/widgets/result_cheat_sheet.dart';

void main() {
  testWidgets(
    'CalculatorScreen: renders header, increments, generates horizontally scrollable spectrum and cheat sheet',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: FpvFrequencyManagerApp()),
      );

      // Title & Subtitle branding
      expect(find.text('Менеджер відеочастот FPV'), findsOneWidget);
      expect(find.text('від команди Дизармерів Ф-22'), findsOneWidget);

      // Initial state: standard counter displays 2
      expect(find.text('Стандартні борти (A, B, E, F, R)'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Increment standard boards to 3
      final addIcon = find.byIcon(Icons.add).first;
      await tester.tap(addIcon);
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);

      // Tap generate button
      final generateBtn = find.text('Розрахувати сітку (3 борти)');
      expect(generateBtn, findsOneWidget);
      await tester.tap(generateBtn);
      await tester.pumpAndSettle();

      // Verification: Spectrum chart & Cheat-sheet appear
      expect(find.byType(RfSpectrumChart), findsOneWidget);
      expect(find.text('Скрол ↔'), findsOneWidget);
      expect(find.byType(ResultCheatSheet), findsOneWidget);
      expect(find.text('Борт 1'), findsOneWidget);
      expect(find.text('Борт 2'), findsOneWidget);
      expect(find.text('Борт 3'), findsOneWidget);

      // Tap copy button and verify accentuated SnackBar
      final copyBtn = find.text('Копіювати');
      await tester.ensureVisible(copyBtn);
      await tester.pumpAndSettle();
      await tester.tap(copyBtn);
      await tester.pump();

      expect(find.text('СІТКУ ЧАСТОТ СКОПІЙОВАНО'), findsOneWidget);
      expect(find.textContaining('3 борти у буфері обміну'), findsOneWidget);
    },
  );

  testWidgets('Standard counter caps at 6 boards and displays limit message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: FpvFrequencyManagerApp()),
    );

    final addIcon = find.byIcon(Icons.add).first;

    // Tap 4 times to go from 2 to 6
    for (int i = 0; i < 4; i++) {
      await tester.tap(addIcon);
      await tester.pumpAndSettle();
    }

    expect(find.text('6'), findsOneWidget);
    expect(find.textContaining('Ліміт 5.8 GHz: макс. 6'), findsOneWidget);

    // Try tapping 5th time - should stay at 6
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('Toggle extended bands shows Lowband and X-band counters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: FpvFrequencyManagerApp()),
    );

    // Toggle switch
    final toggle = find.byType(Switch);
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    // Now Lowband and X-band cards are visible
    expect(find.text('Борти Lowband'), findsOneWidget);
    expect(find.text('Борти X-band'), findsOneWidget);
  });

  testWidgets('Total limit notice appears once globally when sum reaches 12', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: FpvFrequencyManagerApp()),
    );

    // Toggle switch to enable extended bands
    final toggle = find.byType(Switch);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final addIcons = find.byIcon(Icons.add);
    final addStandard = addIcons.at(0);
    final addLowband = addIcons.at(1);

    // Standard starts at 2. Tap 4 times -> 6 standard
    for (int i = 0; i < 4; i++) {
      await tester.tap(addStandard);
      await tester.pumpAndSettle();
    }

    // Lowband starts at 0. Tap 6 times -> 6 lowband (sum = 12)
    for (int i = 0; i < 6; i++) {
      await tester.tap(addLowband);
      await tester.pumpAndSettle();
    }

    // Global limit notice appears exactly ONCE
    expect(
      find.textContaining('Досягнуто загальний ліміт: 12 бортів'),
      findsOneWidget,
    );
  });
}
