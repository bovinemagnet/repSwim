import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app/adaptive_shell.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/swim/presentation/screens/swim_session_detail_screen.dart';
import 'features/swim/presentation/screens/swim_sessions_screen.dart';
import 'features/swim/presentation/screens/swim_session_screen.dart';
import 'features/stopwatch/presentation/screens/stopwatch_screen.dart';
import 'features/stopwatch/presentation/screens/interval_timer_screen.dart';
import 'features/pb/presentation/screens/pb_screen.dart';
import 'features/profiles/presentation/screens/profiles_screen.dart';
import 'features/analytics/presentation/screens/analytics_screen.dart';
import 'features/dryland/presentation/screens/dryland_screen.dart';
import 'features/settings/presentation/screens/sync_settings_screen.dart';
import 'features/profiles/presentation/providers/profile_providers.dart';

final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => AdaptiveShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/sessions',
          builder: (context, state) => const SwimSessionsScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/pb',
          builder: (context, state) => const PbScreen(),
        ),
        GoRoute(
          path: '/profiles',
          builder: (context, state) => const ProfilesScreen(),
        ),
        GoRoute(
          path: '/dryland',
          builder: (context, state) => const DrylandScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/home',
      redirect: (context, state) => '/',
    ),
    GoRoute(
      path: '/swim',
      builder: (context, state) => const SwimSessionScreen(),
    ),
    GoRoute(
      path: '/sessions/:id',
      builder: (context, state) => SwimSessionDetailScreen(
        sessionId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/stopwatch',
      builder: (context, state) => const StopwatchScreen(),
    ),
    GoRoute(
      path: '/intervals',
      builder: (context, state) => const IntervalTimerScreen(),
    ),
    GoRoute(
      path: '/settings/sync',
      builder: (context, state) => const SyncSettingsScreen(),
    ),
  ],
);

class RepSwimApp extends ConsumerWidget {
  const RepSwimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(profileSelectionBootstrapProvider);
    ref.listen<String?>(selectedProfileIdProvider, (_, next) {
      if (next == null || next.isEmpty) return;
      ref
          .read(appSettingsDaoProvider)
          .setString(kSelectedProfileIdSetting, next);
    });

    return MaterialApp.router(
      title: 'repSwim',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
