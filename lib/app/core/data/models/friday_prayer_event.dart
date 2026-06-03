/// A Friday (Jumu'ah) program entry shown on the Today's prayer screen.
class FridayPrayerEvent {
  const FridayPrayerEvent({
    required this.name,
    required this.minutesSinceMidnight,
  });

  final String name;
  final int minutesSinceMidnight;

  FridayPrayerEvent copyWith({
    String? name,
    int? minutesSinceMidnight,
  }) {
    return FridayPrayerEvent(
      name: name ?? this.name,
      minutesSinceMidnight:
          minutesSinceMidnight ?? this.minutesSinceMidnight,
    );
  }

  factory FridayPrayerEvent.fromJson(Map<String, dynamic> json) {
    return FridayPrayerEvent(
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
        other is FridayPrayerEvent &&
            runtimeType == other.runtimeType &&
            name == other.name &&
            minutesSinceMidnight == other.minutesSinceMidnight;
  }

  @override
  int get hashCode => Object.hash(name, minutesSinceMidnight);

  @override
  String toString() =>
      'FridayPrayerEvent(name: $name, minutesSinceMidnight: $minutesSinceMidnight)';
}
