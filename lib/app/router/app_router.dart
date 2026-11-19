import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/auth_controller.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/splash_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/chat/domain/chat.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_thread_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/notifications_screen.dart';
import '../../features/dashboard/presentation/qr_scanner_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/leave/presentation/leave_screen.dart';
import '../../features/live/presentation/live_screen.dart';
import '../../features/mailbox/domain/email.dart';
import '../../features/mailbox/presentation/mailbox_screen.dart';
import '../../features/profile/presentation/employee_profile_screen.dart';
import '../../features/profile/presentation/help_support_screen.dart';
import '../../features/profile/presentation/more_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/projects/presentation/project_detail_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../../features/sharing/presentation/sharing_screen.dart';
import '../../features/summary/presentation/summary_screen.dart';
import '../../features/tasks/presentation/task_board_screen.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';
import 'app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  ref.onDispose(refresh.dispose);
  ref.listen<AuthState>(authControllerProvider, (_, _) => refresh.notify());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isSplash = location == '/splash';
      final isLogin = location == '/login';

      if (auth.isInitializing) {
        return isSplash ? null : '/splash';
      }
      if (!auth.isAuthenticated) {
        return isLogin ? null : '/login';
      }
      if (isSplash || isLogin) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(path: '/tasks', redirect: (context, state) => '/more/tasks'),
      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) =>
            TaskDetailScreen(taskId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/calendar',
        redirect: (context, state) => '/more/calendar',
      ),
      GoRoute(path: '/events', redirect: (context, state) => '/more/events'),
      GoRoute(
        path: '/projects',
        redirect: (context, state) => '/more/projects',
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatThreadScreen(
          conversationId: state.pathParameters['id'] ?? '',
          conversation: state.extra is Conversation
              ? state.extra as Conversation
              : null,
        ),
      ),
      GoRoute(path: '/live', builder: (context, state) => const LiveScreen()),
      GoRoute(
        path: '/sharing',
        builder: (context, state) => const SharingScreen(),
      ),
      GoRoute(
        path: '/mailbox',
        builder: (context, state) => const MailboxScreen(),
      ),
      GoRoute(
        path: '/mailbox/compose',
        builder: (context, state) => ComposeScreen(
          replyTo: state.extra is EmailMessage
              ? state.extra as EmailMessage
              : null,
        ),
      ),
      GoRoute(
        path: '/mailbox/:id',
        redirect: (context, state) =>
            state.extra is EmailMessage ? null : '/mailbox',
        builder: (context, state) =>
            EmailDetailScreen(email: state.extra as EmailMessage),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leave',
                builder: (context, state) => const LeaveScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/summary',
                builder: (context, state) => const SummaryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'calendar',
                    builder: (context, state) => const CalendarScreen(),
                  ),
                  GoRoute(
                    path: 'tasks',
                    builder: (context, state) => const TaskBoardScreen(),
                  ),
                  GoRoute(
                    path: 'events',
                    builder: (context, state) => const EventsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => EventDetailScreen(
                          eventId: state.pathParameters['id'] ?? '',
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'projects',
                    builder: (context, state) => const ProjectsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => ProjectDetailScreen(
                          projectId: state.pathParameters['id'] ?? '',
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const EmployeeProfileScreen(),
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (context, state) => const HelpSupportScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorScreen(
      message: state.error?.toString() ?? 'This page could not be found.',
    ),
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 44),
              const SizedBox(height: 12),
              const Text(
                'Page not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Back to dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
