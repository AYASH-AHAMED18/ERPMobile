import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';
import '../../features/chat/presentation/chat_controllers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread =
        ref
            .watch(conversationsControllerProvider)
            .value
            ?.fold<int>(
              0,
              (sum, conversation) => sum + conversation.unreadCount,
            ) ??
        0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        unreadChats: unread,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadChats = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadChats;

  static const _items = [
    _NavItem('Dashboard', Icons.home_outlined, Icons.home_rounded, false),
    _NavItem(
      'Chat',
      Icons.chat_bubble_outline_rounded,
      Icons.chat_bubble_rounded,
      true,
    ),
    _NavItem(
      'Leave',
      Icons.assignment_outlined,
      Icons.assignment_rounded,
      false,
    ),
    _NavItem(
      'Summary',
      Icons.bar_chart_outlined,
      Icons.bar_chart_rounded,
      false,
    ),
    _NavItem('More', Icons.more_horiz_rounded, Icons.more_horiz_rounded, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.line)),
        boxShadow: AppShadows.soft,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.bottomNavHeight,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _BottomNavButton(
                    item: _items[i],
                    selected: currentIndex == i,
                    badge: _items[i].showBadge ? unreadChats : 0,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : context.navInactive;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 24,
                  color: color,
                ),
                if (badge > 0)
                  Positioned(
                    right: -9,
                    top: -7,
                    child: CountBadge(count: badge, height: 17, fontSize: 9),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon, this.showBadge);
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool showBadge;
}
