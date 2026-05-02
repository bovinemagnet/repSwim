import '../../../../core/constants/app_constants.dart';
import '../entities/swimmer_profile.dart';

List<String> normalizePreferredStrokes(Iterable<String> strokes) {
  final allowed = kStrokes.toSet();
  final normalized = <String>[];
  for (final stroke in strokes) {
    final trimmed = stroke.trim();
    if (trimmed.isEmpty || !allowed.contains(trimmed)) continue;
    if (!normalized.contains(trimmed)) normalized.add(trimmed);
  }
  return normalized;
}

String? cleanProfileDetail(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

List<String> profileDetailsSummary(SwimmerProfile profile) {
  return [
    '${profile.preferredPoolLengthMeters}m pool',
    if (profile.clubName != null) profile.clubName!,
    if (profile.preferredStrokes.isNotEmpty)
      profile.preferredStrokes.join(', '),
    if (profile.primaryEvents != null) profile.primaryEvents!,
  ];
}
