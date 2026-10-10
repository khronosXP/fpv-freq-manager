import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/calculator_screen.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: FpvFrequencyManagerApp()));
}

class FpvFrequencyManagerApp extends ConsumerWidget {
  const FpvFrequencyManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Менеджер відеочастот FPV — від команди Дизармерів Ф-22',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const CalculatorScreen(),
    );
  }
}
