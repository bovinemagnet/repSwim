import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/profiles/domain/entities/swimmer_profile.dart';
import '../features/profiles/presentation/providers/profile_providers.dart';

enum FormFactor { phone, tablet, desktop }

FormFactor getFormFactor(double width) {
  if (width < 600) return FormFactor.phone;
  if (width < 1000) return FormFactor.tablet;
  return FormFactor.desktop;
}

class AppDestination {
  const AppDestination({
    required this.path,
    required this.label,
    required this.icon,
  });

  final String path;
  final String label;
  final IconData icon;
}

const appDestinations = [
  AppDestination(path: '/', label: 'Home', icon: Icons.home_outlined),
  AppDestination(
    path: '/sessions',
    label: 'Sessions',
    icon: Icons.list_alt_outlined,
  ),
  AppDestination(path: '/analytics', label: 'Analytics', icon: Icons.bar_chart),
  AppDestination(path: '/pb', label: 'PBs', icon: Icons.emoji_events_outlined),
  AppDestination(
    path: '/dryland',
    label: 'Dryland',
    icon: Icons.fitness_center,
  ),
  AppDestination(
    path: '/profiles',
    label: 'Profiles',
    icon: Icons.manage_accounts_outlined,
  ),
];

class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({
    super.key,
    required this.child,
    this.location,
  });

  final Widget child;
  final String? location;

  int _selectedIndex(String location) {
    final index = appDestinations.indexWhere((destination) {
      if (destination.path == '/') return location == '/';
      return location.startsWith(destination.path);
    });
    return index < 0 ? 0 : index;
  }

  void _go(BuildContext context, int index) {
    context.go(appDestinations[index].path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation =
        location ?? GoRouterState.of(context).uri.toString();
    final selectedIndex = _selectedIndex(currentLocation);

    return LayoutBuilder(
      builder: (context, constraints) {
        final formFactor = getFormFactor(constraints.maxWidth);
        if (formFactor == FormFactor.phone) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _go(context, index),
              destinations: [
                for (final destination in appDestinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
            ),
          );
        }

        final extended = formFactor == FormFactor.desktop;
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: extended,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _go(context, index),
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                    child: _RailProfileSwitcher(extended: extended),
                  ),
                  destinations: [
                    for (final destination in appDestinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _RailProfileSwitcher extends ConsumerWidget {
  const _RailProfileSwitcher({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider).valueOrNull ??
        <SwimmerProfile>[SwimmerProfile.defaultProfile];
    final currentProfile = ref.watch(currentProfileProvider);

    if (!extended) {
      return PopupMenuButton<String>(
        tooltip: 'Switch swimmer',
        icon: const Icon(Icons.account_circle_outlined),
        onSelected: (profileId) {
          if (profileId == '__manage__') {
            context.go('/profiles');
            return;
          }
          ref.read(selectedProfileIdProvider.notifier).state = profileId;
        },
        itemBuilder: (_) => [
          for (final profile in profiles)
            PopupMenuItem<String>(
              value: profile.id,
              child: Text(profile.displayName),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: '__manage__',
            child: Text('Manage swimmers'),
          ),
        ],
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Switch swimmer',
      onSelected: (profileId) {
        if (profileId == '__manage__') {
          context.go('/profiles');
          return;
        }
        ref.read(selectedProfileIdProvider.notifier).state = profileId;
      },
      itemBuilder: (_) => [
        for (final profile in profiles)
          PopupMenuItem<String>(
            value: profile.id,
            child: Text(profile.displayName),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: '__manage__',
          child: Text('Manage swimmers'),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle_outlined),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                currentProfile.displayName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
