import 'branding_profile.dart';

/// A tenant entity (for example, a masjid such as "Palos") that owns its own
/// branding, theme, prayer schedule, programs, and donation categories.
class Organization {
  const Organization({
    required this.id,
    required this.branding,
  });

  final String id;
  final BrandingProfile branding;

  Organization copyWith({
    String? id,
    BrandingProfile? branding,
  }) {
    return Organization(
      id: id ?? this.id,
      branding: branding ?? this.branding,
    );
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      branding:
          BrandingProfile.fromJson(json['branding'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'branding': branding.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Organization &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            branding == other.branding;
  }

  @override
  int get hashCode => Object.hash(id, branding);

  @override
  String toString() => 'Organization(id: $id, branding: $branding)';
}
