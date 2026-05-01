class DurationUtils {
  DurationUtils._();

  /// Formats a [Duration] as "H:MM:SS" or "M:SS".
  static String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${_pad(minutes)}:${_pad(seconds)}';
    }
    return '$minutes:${_pad(seconds)}';
  }

  /// Formats a [Duration] with centiseconds as "M:SS.cs".
  static String formatDurationWithCentiseconds(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    final centiseconds = (d.inMilliseconds.remainder(1000) ~/ 10);
    return '${_pad(minutes)}:${_pad(seconds)}.${_pad(centiseconds)}';
  }

  /// Returns pace per 100m as a string like "1:45/100m".
  static String formatPace(Duration totalTime, int distanceMeters) {
    if (distanceMeters == 0) return '--:--/100m';
    final pace = calculatePace(totalTime, distanceMeters);
    return '${formatDuration(pace)}/100m';
  }

  /// Calculates pace per 100m as a [Duration].
  static Duration calculatePace(Duration totalTime, int distanceMeters) {
    if (distanceMeters == 0) return Duration.zero;
    final secondsPer100m = totalTime.inMilliseconds * 100 / distanceMeters;
    return Duration(milliseconds: secondsPer100m.round());
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
