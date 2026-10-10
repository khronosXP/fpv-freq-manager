import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_freq_manager/presentation/providers/theme_provider.dart';
import 'package:fpv_freq_manager/presentation/screens/calculator_screen.dart';
import 'package:fpv_freq_manager/presentation/theme/app_theme.dart';

void main() {
  group('Theme Architecture & Palette Verification', () {
    test('AppTheme.lightTheme conforms to UI Max Pro specifications', () {
      final light = AppTheme.lightTheme;
      expect(light.brightness, Brightness.light);
      expect(
        light.scaffoldBackgroundColor,
        const Color(0xFFF8FAFC),
      ); // Slate 50
      expect(
        light.colorScheme.primary,
        const Color(0xFF0265DC),
      ); // Cobalt 7.2:1
      expect(light.colorScheme.onPrimary, const Color(0xFFFFFFFF));
      expect(light.colorScheme.surface, const Color(0xFFFFFFFF));
      expect(light.colorScheme.onSurface, const Color(0xFF0F172A)); // Slate 900
      expect(light.colorScheme.secondary, const Color(0xFFB45309)); // Amber
      expect(light.colorScheme.tertiary, const Color(0xFF047857)); // Emerald
      expect(light.colorScheme.error, const Color(0xFFDC2626)); // Crimson
    });

    test('AppTheme.darkTheme conforms to telemetry specifications', () {
      final dark = AppTheme.darkTheme;
      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, const Color(0xFF0D1117));
      expect(dark.colorScheme.primary, const Color(0xFF00E5FF)); // Neon cyan
      expect(dark.colorScheme.surface, const Color(0xFF121820));
      expect(dark.colorScheme.onSurface, const Color(0xFFECEFF1));
    });

    test('ThemeModeNotifier defaults to light and toggles to dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);

      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.light);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });

  group('Theme Switcher UI Widget Test', () {
    testWidgets('AppBar contains theme toggle and toggles theme on tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              final mode = ref.watch(themeModeProvider);
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: mode,
                home: const CalculatorScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In light mode initially, should have dark_mode icon to switch to dark
      final themeBtnFinder = find.byTooltip('Темна тема (Телеметрія)');
      expect(themeBtnFinder, findsOneWidget);

      // Tap theme switch
      await tester.tap(themeBtnFinder);
      await tester.pumpAndSettle();

      // Now in dark mode, tooltip should update to light mode switch
      expect(find.byTooltip('Світла тема (UI Max Pro)'), findsOneWidget);

      // Tap back to light
      await tester.tap(find.byTooltip('Світла тема (UI Max Pro)'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Темна тема (Телеметрія)'), findsOneWidget);
    });
  });
}
