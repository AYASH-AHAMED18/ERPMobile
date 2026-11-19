import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_controller.dart';
import '../../features/authentication/presentation/auth_controller.dart';
import '../../features/dashboard/presentation/dashboard_controller.dart';
import 'app_drawer.dart';
import 'app_header.dart';

class ErpHeader extends ConsumerWidget {
  const ErpHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(currentEmployeeProvider);
    final themeMode =
        ref.watch(themeControllerProvider).value ?? ThemeMode.light;
    final unread =
        ref.watch(dashboardControllerProvider).value?.unreadNotifications ?? 0;

    return AppHeader(
      employee: employee,
      unreadNotifications: unread,
      isDark: themeMode == ThemeMode.dark,
      onOpenMenu: () => Scaffold.maybeOf(context)?.openDrawer(),
      onScanQr: () => context.push('/scanner'),
      onNotifications: () => context.push('/notifications'),
      onToggleTheme: () => ref.read(themeControllerProvider.notifier).toggle(),
      onProfile: () => context.go('/more/profile'),
    );
  }
}

class ErpModuleScaffold extends StatelessWidget {
  const ErpModuleScaffold({super.key, required this.body, this.drawer = true});

  final Widget body;
  final bool drawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      drawer: drawer ? const AppDrawer() : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ErpHeader(),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class AppPageTitle extends StatelessWidget {
  const AppPageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            InkResponse(
              onTap: onBack,
              radius: 20,
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.line),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 18),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class ModuleSectionTitle extends StatelessWidget {
  const ModuleSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class ModuleFilterRow extends StatelessWidget {
  const ModuleFilterRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: children,
      ),
    );
  }
}
