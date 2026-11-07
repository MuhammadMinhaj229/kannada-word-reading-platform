/// Serializes device-local timestamps with an explicit UTC offset.
///
/// Dart's [DateTime.toIso8601String] omits the offset for local DateTime
/// values. The research export requires the local clock time and time zone
/// offset, so this codec adds `+HH:MM` or `-HH:MM`. UTC values retain `Z`.
class LocalTimestamp {
  const LocalTimestamp._();

  static String format(DateTime value, {Duration? offsetOverride}) {
    final iso = value.toIso8601String();
    if (value.isUtc && offsetOverride == null) {
      return iso;
    }

    final localIso = value.isUtc ? iso.substring(0, iso.length - 1) : iso;
    final offset = offsetOverride ?? value.timeZoneOffset;
    final totalMinutes = offset.inMinutes.abs();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';

    return '$localIso$sign$hours:$minutes';
  }
}
