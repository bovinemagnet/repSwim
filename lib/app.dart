import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/swim/presentation/screens/swim_session_screen.dart';
import 'features/stopwatch/presentation/screens/stopwatch_screen.dart';
import 'features/pb/presentation/screens/pb_screen.dart';
import 'features/analytics/presentation/screens/analytics_screen.dart';
import 'features/dryland/presentation/screens/dryland_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/swim',
      builder: (context, state) => const SwimSessionScreen(),
    ),
    GoRoute(
      path: '/stopwatch',
      builder: (context, state) => const StopwatchScreen(),
    ),
    GoRoute(
      path: '/pb',
      builder: (context, state) => const PbScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/dryland',
      builder: (context, state) => const DrylandScreen(),
    ),
  ],
);

class RepSwimApp extends ConsumerWidget {
  const RepSwimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'repSwim',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
