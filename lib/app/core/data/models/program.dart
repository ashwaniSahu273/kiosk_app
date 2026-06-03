import 'org_owned.dart';

/// An organization activity or class that a kiosk visitor can register for,
/// displayed in the Available Programs section.
class Program implements OrgOwned {
  const Program({
    required this.organizationId,
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
  });

  @override
  final String organizationId;
  final String id;
  final String name;

  /// Short copy for campaign cards.
  final String? description;

  /// Optional hero image URL for list cards.
  final String? imageUrl;

  String get displayDescription =>
      description ?? 'Register for $name and join the next available session.';

  Program copyWith({
    String? organizationId,
    String? id,
    String? name,
    String? description,
    String? imageUrl,
  }) {
    return Program(
      organizationId: organizationId ?? this.organizationId,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      organizationId: json['organizationId'] as String,
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Program &&
            runtimeType == other.runtimeType &&
            organizationId == other.organizationId &&
            id == other.id &&
            name == other.name &&
            description == other.description &&
            imageUrl == other.imageUrl;
  }

  @override
  int get hashCode =>
      Object.hash(organizationId, id, name, description, imageUrl);

  @override
  String toString() =>
      'Program(organizationId: $organizationId, id: $id, name: $name)';
}
