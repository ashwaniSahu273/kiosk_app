/// A single named prayer and its scheduled time of day.
///
/// [minutesSinceMidnight] is the Athan (adhan) time in the range 0..1439.
/// [iqamahMinutesSinceMidnight], when set, is the congregational prayer time.
class PrayerTime {
  const PrayerTime({
    required this.name,
    required this.minutesSinceMidnight,
    this.iqamahMinutesSinceMidnight,
  });

  final String name;

  /// Athan (adhan) time; also used for next-prayer resolution.
  final int minutesSinceMidnight;

  /// Iqamah time when the masjid begins congregational prayer.
  final int? iqamahMinutesSinceMidnight;

  /// Whether this row should show an Iqamah column (Sunrise is Athan-only).
  bool get hasIqamah =>
      iqamahMinutesSinceMidnight != null &&
      !name.toLowerCase().contains('sunrise');

  PrayerTime copyWith({
    String? name,
    int? minutesSinceMidnight,
    int? iqamahMinutesSinceMidnight,
    bool clearIqamah = false,
  }) {
    return PrayerTime(
      name: name ?? this.name,
      minutesSinceMidnight: minutesSinceMidnight ?? this.minutesSinceMidnight,
      iqamahMinutesSinceMidnight: clearIqamah
          ? null
          : (iqamahMinutesSinceMidnight ?? this.iqamahMinutesSinceMidnight),
    );
  }

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      name: json['name'] as String,
      minutesSinceMidnight: json['minutesSinceMidnight'] as int,
      iqamahMinutesSinceMidnight:
          json['iqamahMinutesSinceMidnight'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'minutesSinceMidnight': minutesSinceMidnight,
      if (iqamahMinutesSinceMidnight != null)
        'iqamahMinutesSinceMidnight': iqamahMinutesSinceMidnight,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PrayerTime &&
            runtimeType == other.runtimeType &&
            name == other.name &&
            minutesSinceMidnight == other.minutesSinceMidnight &&
            iqamahMinutesSinceMidnight == other.iqamahMinutesSinceMidnight;
  }

  @override
  int get hashCode =>
      Object.hash(name, minutesSinceMidnight, iqamahMinutesSinceMidnight);

  @override
  String toString() =>
      'PrayerTime(name: $name, minutesSinceMidnight: $minutesSinceMidnight)';
}
