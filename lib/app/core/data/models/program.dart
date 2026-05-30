import 'org_owned.dart';

/// An organization activity or class that a kiosk visitor can register for,
/// displayed in the Available Programs section.
class Program implements OrgOwned {
  const Program({
    required this.organizationId,
    required this.id,
    required this.name,
  });

  @override
  final String organizationId;
  final String id;
  final String name;

  Program copyWith({
    String? organizationId,
    String? id,
    String? name,
  }) {
    return Program(
      organizationId: organizationId ?? this.organizationId,
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      organizationId: json['organizationId'] as String,
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'id': id,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Program &&
            runtimeType == other.runtimeType &&
            organizationId == other.organizationId &&
            id == other.id &&
            name == other.name;
  }

  @override
  int get hashCode => Object.hash(organizationId, id, name);

  @override
  String toString() =>
      'Program(organizationId: $organizationId, id: $id, name: $name)';
}
