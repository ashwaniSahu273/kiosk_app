import 'friday_prayer_event.dart';
import 'org_owned.dart';
import 'prayer_time.dart';

/// The set of named daily prayers and their times for the active Organization
/// on a given [date]. The [prayers] list may be empty.
class PrayerSchedule implements OrgOwned {
  const PrayerSchedule({
    required this.organizationId,
    required this.date,
    required this.prayers,
    this.fridayEvents = const <FridayPrayerEvent>[],
  });

  @override
  final String organizationId;
  final DateTime date;
  final List<PrayerTime> prayers;

  /// Optional Friday (Jumu'ah) program times for the Today's tab.
  final List<FridayPrayerEvent> fridayEvents;

  PrayerSchedule copyWith({
    String? organizationId,
    DateTime? date,
    List<PrayerTime>? prayers,
    List<FridayPrayerEvent>? fridayEvents,
  }) {
    return PrayerSchedule(
      organizationId: organizationId ?? this.organizationId,
      date: date ?? this.date,
      prayers: prayers ?? this.prayers,
      fridayEvents: fridayEvents ?? this.fridayEvents,
    );
  }

  factory PrayerSchedule.fromJson(Map<String, dynamic> json) {
    return PrayerSchedule(
      organizationId: json['organizationId'] as String,
      date: DateTime.parse(json['date'] as String),
      prayers: (json['prayers'] as List<dynamic>)
          .map((dynamic e) =>
              PrayerTime.fromJson(e as Map<String, dynamic>))
          .toList(),
      fridayEvents: (json['fridayEvents'] as List<dynamic>?)
              ?.map(
                (dynamic e) => FridayPrayerEvent.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const <FridayPrayerEvent>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'date': date.toIso8601String(),
      'prayers': prayers.map((PrayerTime p) => p.toJson()).toList(),
      if (fridayEvents.isNotEmpty)
        'fridayEvents':
            fridayEvents.map((FridayPrayerEvent e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PrayerSchedule &&
            runtimeType == other.runtimeType &&
            organizationId == other.organizationId &&
            date == other.date &&
            _listEquals(prayers, other.prayers) &&
            _fridayListEquals(fridayEvents, other.fridayEvents);
  }

  @override
  int get hashCode => Object.hash(
        organizationId,
        date,
        Object.hashAll(prayers),
        Object.hashAll(fridayEvents),
      );

  @override
  String toString() =>
      'PrayerSchedule(organizationId: $organizationId, date: $date, '
      'prayers: $prayers)';
}

bool _listEquals(List<PrayerTime> a, List<PrayerTime> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _fridayListEquals(List<FridayPrayerEvent> a, List<FridayPrayerEvent> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
