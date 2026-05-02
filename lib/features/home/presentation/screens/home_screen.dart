import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';
import '../../../profiles/domain/entities/swimmer_profile.dart';
import '../../../swim/presentation/providers/swim_providers.dart';
import '../../../swim/domain/entities/swim_session.dart';
import '../../../../core/utils/duration_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final sessionsAsync = ref.watch(swimSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.pool, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('repSwim'),
          ],
        ),
        actions: [
          const _ProfileSwitcher(),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Analytics',
            onPressed: () => context.push('/analytics'),
          ),
          IconButton(
            icon: const Icon(Icons.sync_outlined),
            tooltip: 'Sync settings',
            onPressed: () => context.push('/settings/sync'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _TodaySummaryCard(sessionsAsync: sessionsAsync),
          ),
          const SliverToBoxAdapter(child: _QuickActions()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Sessions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/sessions'),
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text('View all'),
                  ),
                ],
              ),
            ),
          ),
          _RecentSessionsList(sessionsAsync: sessionsAsync),
        ],
      ),
    );
  }
}

class _ProfileSwitcher extends ConsumerWidget {
  const _ProfileSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final currentProfile = ref.watch(currentProfileProvider);

    return PopupMenuButton<String>(
      tooltip: 'Switch swimmer',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (value) async {
        if (value == '__add__') {
          await _showAddProfileDialog(context, ref);
          return;
        }
        if (value == '__manage__') {
          if (!context.mounted) return;
          context.push('/profiles');
          return;
        }
        ref.read(selectedProfileIdProvider.notifier).state = value;
      },
      itemBuilder: (context) {
        final profiles = profilesAsync.valueOrNull ??
            <SwimmerProfile>[SwimmerProfile.defaultProfile];
        return [
          ...profiles.map(
            (profile) => PopupMenuItem<String>(
              value: profile.id,
              child: Row(
                children: [
                  Icon(
                    profile.id == currentProfile.id
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text(profile.displayName)),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: '__manage__',
            child: Row(
              children: [
                Icon(Icons.manage_accounts_outlined, size: 18),
                SizedBox(width: 8),
                Text('Manage swimmers'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: '__add__',
            child: Row(
              children: [
                Icon(Icons.add, size: 18),
                SizedBox(width: 8),
                Text('Add swimmer'),
              ],
            ),
          ),
        ];
      },
    );
  }

  Future<void> _showAddProfileDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add swimmer'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Profile name'),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.trim().isEmpty) return;
    final profile =
        await ref.read(profilesProvider.notifier).addProfile(name.trim());
    ref.read(selectedProfileIdProvider.notifier).state = profile.id;
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.sessionsAsync});

  final AsyncValue<List<SwimSession>> sessionsAsync;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(today,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.8),
                      )),
              const SizedBox(height: 8),
              sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Text(
                      'No sessions yet - start your first swim!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                    );
                  }
                  final last = sessions.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last session',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.straighten,
                            label: '${last.totalDistance}m',
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            icon: Icons.timer_outlined,
                            label: DurationUtils.formatDuration(last.totalTime),
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            icon: Icons.waves,
                            label: last.stroke,
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator.adaptive(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.pool,
                  label: 'New Swim',
                  onTap: () => context.push('/swim'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.repeat,
                  label: 'Intervals',
                  onTap: () => context.push('/intervals'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.timer,
                  label: 'Timer',
                  onTap: () => context.push('/stopwatch'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.fitness_center,
                  label: 'Dryland',
                  onTap: () => context.push('/dryland'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.emoji_events_outlined,
                  label: 'Personal Bests',
                  onTap: () => context.push('/pb'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.graphic_eq,
                  label: 'Tempo',
                  onTap: () => context.push('/tempo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.bar_chart,
                  label: 'Analytics',
                  onTap: () => context.push('/analytics'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSessionsList extends StatelessWidget {
  const _RecentSessionsList({required this.sessionsAsync});

  final AsyncValue<List<SwimSession>> sessionsAsync;

  @override
  Widget build(BuildContext context) {
    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pool_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No swim sessions yet',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }
        final recent = sessions.take(10).toList();
        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.separated(
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _SessionTile(session: recent[i]),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final SwimSession session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('EEE, d MMM').format(session.date);
    return Card(
      child: ListTile(
        onTap: () => context.push('/sessions/${session.id}'),
        leading: CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          child: Icon(Icons.pool,
              color: colorScheme.onSecondaryContainer, size: 20),
        ),
        title: Text(
          '${session.totalDistance}m · ${session.stroke}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$dateStr · ${DurationUtils.formatDuration(session.totalTime)}',
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
      ),
    );
  }
}
