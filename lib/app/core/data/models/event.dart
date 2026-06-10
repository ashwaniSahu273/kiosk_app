import 'org_owned.dart';

class Event implements OrgOwned {
  const Event({
    required this.organizationId,
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.date,
    this.time,
    this.location,
  });

  @override
  final String organizationId;
  final String id;
  final String name;

  final String? description;
  final String? imageUrl;
  final String? date;
  final String? time;
  final String? location;

  String get displayDescription =>
      description ?? 'Join us for $name at the masjid.';

  String get displayDate => date ?? 'Date TBD';

  String get displayTime => time ?? 'Time TBD';

  String get displayLocation => location ?? 'Main prayer hall';

  Event copyWith({
    String? organizationId,
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? date,
    String? time,
    String? location,
  }) {
    return Event(
      organizationId: organizationId ?? this.organizationId,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      organizationId: json['organizationId'] as String,
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      date: json['date'] as String?,
      time: json['time'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
      if (location != null) 'location': location,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Event &&
            runtimeType == other.runtimeType &&
            organizationId == other.organizationId &&
            id == other.id &&
            name == other.name &&
            description == other.description &&
            imageUrl == other.imageUrl &&
            date == other.date &&
            time == other.time &&
            location == other.location;
  }

  @override
  int get hashCode =>
      Object.hash(organizationId, id, name, description, imageUrl, date, time, location);

  @override
  String toString() =>
      'Event(organizationId: $organizationId, id: $id, name: $name, date: $date)';
}
