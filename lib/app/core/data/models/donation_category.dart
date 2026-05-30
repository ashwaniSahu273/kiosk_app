import 'org_owned.dart';

/// A named giving option (for example, "Zakat", "General Fund") that a kiosk
/// visitor can choose to donate toward.
class DonationCategory implements OrgOwned {
  const DonationCategory({
    required this.organizationId,
    required this.id,
    required this.name,
  });

  @override
  final String organizationId;
  final String id;
  final String name;

  DonationCategory copyWith({
    String? organizationId,
    String? id,
    String? name,
  }) {
    return DonationCategory(
      organizationId: organizationId ?? this.organizationId,
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory DonationCategory.fromJson(Map<String, dynamic> json) {
    return DonationCategory(
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
        other is DonationCategory &&
            runtimeType == other.runtimeType &&
            organizationId == other.organizationId &&
            id == other.id &&
            name == other.name;
  }

  @override
  int get hashCode => Object.hash(organizationId, id, name);

  @override
  String toString() =>
      'DonationCategory(organizationId: $organizationId, id: $id, name: $name)';
}
