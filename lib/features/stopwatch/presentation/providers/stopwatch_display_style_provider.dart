import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';

enum StopwatchDisplayStyle {
  standard('Standard'),
  nixieTube('Nixie'),
  vacuumFluorescent('VFD'),
  numitron('Numitron'),
  splitFlap('Split-flap');

  const StopwatchDisplayStyle(this.label);

  final String label;
}

final stopwatchDisplayStyleProvider =
    StateProvider<StopwatchDisplayStyle>((ref) {
  return StopwatchDisplayStyle.standard;
});

final stopwatchDisplayStyleBootstrapProvider =
    FutureProvider<void>((ref) async {
  final saved = await ref
      .read(appSettingsDaoProvider)
      .getString(kStopwatchDisplayStyleSetting);
  if (saved == null || saved.isEmpty) return;
  for (final style in StopwatchDisplayStyle.values) {
    if (style.name != saved) continue;
    ref.read(stopwatchDisplayStyleProvider.notifier).state = style;
    return;
  }
});

Future<void> setStopwatchDisplayStyle(
  WidgetRef ref,
  StopwatchDisplayStyle style,
) async {
  ref.read(stopwatchDisplayStyleProvider.notifier).state = style;
  await ref
      .read(appSettingsDaoProvider)
      .setString(kStopwatchDisplayStyleSetting, style.name);
}
