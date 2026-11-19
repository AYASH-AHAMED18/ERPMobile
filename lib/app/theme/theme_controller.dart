import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

class ThemeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final stored = await ref.read(sessionStorageProvider).readThemeMode();
    return _decode(stored);
  }

  ThemeMode _decode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = AsyncData(mode);
    await ref.read(sessionStorageProvider).saveThemeMode(mode.name);
  }

  Future<void> toggle() async {
    final current = state.value ?? ThemeMode.light;
    await setMode(current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
