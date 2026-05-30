/// A single named prayer and its scheduled time of day.
///
/// [minutesSinceMidnight] is the schedule-local time of day in the range
/// 0..1439 inclusive.
class PrayerTime {
  const PrayerTime({
    required this.name,
    required this.minutesSinceMidnight,
  });

  final String name;
  final int minutesSinceMidnight;

  PrayerTime copyWith({
    String? name,
    int? minutesSinceMidnight,
  }) {
    return PrayerTime(
      name: name ?? this.name,
      minutesSinceMidnight: minutesSinceMidnight ?? this.minutesSinceMidnight,
    );
  }

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      name: json['name'] as String,
      minutesSinceMidnight: json['minutesSinceMidnight'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'minutesSinceMidnight': minutesSinceMidnight,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PrayerTime &&
            runtimeType == other.runtimeType &&
            name == other.name &&
            minutesSinceMidnight == other.minutesSinceMidnight;
  }

  @override
  int get hashCode => Object.hash(name, minutesSinceMidnight);

  @override
  String toString() =>
      'PrayerTime(name: $name, minutesSinceMidnight: $minutesSinceMidnight)';
}
