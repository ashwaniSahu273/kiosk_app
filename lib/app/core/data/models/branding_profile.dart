/// Branding and theming data for a single [Organization].
///
/// Color fields are nullable ARGB integers; when omitted the [ThemeEngine]
/// substitutes a documented default for the corresponding role. [logoRef] may
/// be an asset path or URL; when null the bundled placeholder logo is used.
/// [donationUrl] when null drives the Scan-to-Donate unavailable state.
class BrandingProfile {
  const BrandingProfile({
    required this.organizationId,
    required this.displayName,
    this.logoRef,
    this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.scaffoldBackgroundColor,
    this.donationUrl,
  });

  final String organizationId;
  final String displayName;
  final String? logoRef;
  final int? primaryColor;
  final int? secondaryColor;
  final int? accentColor;
  final int? scaffoldBackgroundColor;
  final String? donationUrl;

  BrandingProfile copyWith({
    String? organizationId,
    String? displayName,
    String? logoRef,
    int? primaryColor,
    int? secondaryColor,
    int? accentColor,
    int? scaffoldBackgroundColor,
    String? donationUrl,
  }) {
    return BrandingProfile(
      organizationId: organizationId ?? this.organizationId,
      displayName: displayName ?? this.displayName,
      logoRef: logoRef ?? this.logoRef,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      scaffoldBackgroundColor:
          scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
      donationUrl: donationUrl ?? this.donationUrl,
    );
  }

  factory BrandingProfile.fromJson(Map<String, dynamic> json) {
    return BrandingProfile(
      organizationId: json['organizationId'] as String,
      displayName: json['displayName'] as String,
      logoRef: json['logoRef'] as String?,
      primaryColor: json['primaryColor'] as int?,
      secondaryColor: json['secondaryColor'] as int?,
      accentColor: json['accentColor'] as int?,
      scaffoldBackgroundColor: json['scaffoldBackgroundColor'] as int?,
      donationUrl: json['donationUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'displayName': displayName,
      'logoRef': logoRef,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
      'scaffoldBackgroundColor': scaffoldBackgroundColor,
      'donationUrl': donationUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BrandingProfile &&
            runtimeType == other.runtimeType &&
            organizationId == other.organizationId &&
            displayName == other.displayName &&
            logoRef == other.logoRef &&
            primaryColor == other.primaryColor &&
            secondaryColor == other.secondaryColor &&
            accentColor == other.accentColor &&
            scaffoldBackgroundColor == other.scaffoldBackgroundColor &&
            donationUrl == other.donationUrl;
  }

  @override
  int get hashCode => Object.hash(
        organizationId,
        displayName,
        logoRef,
        primaryColor,
        secondaryColor,
        accentColor,
        scaffoldBackgroundColor,
        donationUrl,
      );

  @override
  String toString() {
    return 'BrandingProfile(organizationId: $organizationId, '
        'displayName: $displayName, logoRef: $logoRef, '
        'primaryColor: $primaryColor, secondaryColor: $secondaryColor, '
        'accentColor: $accentColor, '
        'scaffoldBackgroundColor: $scaffoldBackgroundColor, '
        'donationUrl: $donationUrl)';
  }
}
