import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FpvManagerMode { auto, manual }

class AppModeNotifier extends Notifier<FpvManagerMode> {
  @override
  FpvManagerMode build() => FpvManagerMode.auto;

  void setMode(FpvManagerMode mode) {
    state = mode;
  }
}

final appModeProvider = NotifierProvider<AppModeNotifier, FpvManagerMode>(
  AppModeNotifier.new,
);
