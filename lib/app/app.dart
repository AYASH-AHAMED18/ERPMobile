import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router/app_router.dart';
import '../app/theme/app_theme.dart';
import '../app/theme/theme_controller.dart';

class SpeedCodeErpApp extends ConsumerWidget {
  const SpeedCodeErpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode =
        ref.watch(themeControllerProvider).value ?? ThemeMode.light;

    return MaterialApp.router(
      title: 'SpeedCode Labs ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
