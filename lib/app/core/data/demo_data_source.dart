import '../../config/demo/palos_demo_config.dart';
import 'models/models.dart';

/// The Home_Screen content sections that the demo can independently force into
/// a failure or empty state, used to exercise the error/empty UI paths
/// (Requirements 3.5, 3.6, 12.3) without a live backend.
enum KioskSection {
  organization,
  branding,
  prayerSchedule,
  programs,
  donationCategories,
}

/// Thrown by the [DemoDataSource] when a section is configured to fail.
///
/// The [KioskRepository] catches this and maps it into an
/// `ApiResult.failure(...)`, mirroring how a real transport failure would be
/// surfaced through the centralized network layer.
class DemoFailureException implements Exception {
  const DemoFailureException(this.section, [this.message]);

  final KioskSection section;
  final String? message;

  @override
  String toString() =>
      'DemoFailureException(section: ${section.name}, message: $message)';
}

/// A configurable, in-memory data source backing the offline demo.
///
/// Exposes the seeded organizations, authenticates demo credentials, and serves
/// organization content (branding, prayer schedule, programs, donation
/// categories). Programs and donation categories are returned as a single
/// cross-tenant pool — exactly as an over-broad backend response might — so the
/// [KioskRepository] can demonstrate dropping items that do not belong to the
/// active organization (Requirements 3.2, 3.3).
///
/// The failure/empty toggles ([forceFailure], [forceEmpty]) let the demo drive
/// each section into its error or empty state on demand.
class DemoDataSource {
  DemoDataSource({List<OrganizationData>? organizations})
      : _organizations = List<OrganizationData>.unmodifiable(
          organizations ?? demoOrganizations,
        );

  final List<OrganizationData> _organizations;

  /// Sections currently configured to fail (throw [DemoFailureException]).
  final Set<KioskSection> _forcedFailures = <KioskSection>{};

  /// Sections currently configured to return an empty result.
  final Set<KioskSection> _forcedEmpty = <KioskSection>{};

  /// The seeded organizations available to the demo (read-only).
  List<OrganizationData> get organizations => _organizations;

  // ---- Failure / empty toggles ----

  /// Forces [section] to fail on its next read (simulates a transport error).
  void forceFailure(KioskSection section) => _forcedFailures.add(section);

  /// Forces [section] to return an empty result on its next read.
  void forceEmpty(KioskSection section) => _forcedEmpty.add(section);

  /// Clears a forced-failure toggle for [section].
  void clearFailure(KioskSection section) => _forcedFailures.remove(section);

  /// Clears a forced-empty toggle for [section].
  void clearEmpty(KioskSection section) => _forcedEmpty.remove(section);

  /// Clears every forced-failure and forced-empty toggle.
  void resetScenario() {
    _forcedFailures.clear();
    _forcedEmpty.clear();
  }

  /// Whether [section] is currently configured to fail.
  bool isFailing(KioskSection section) => _forcedFailures.contains(section);

  /// Whether [section] is currently configured to return empty.
  bool isEmptyForced(KioskSection section) => _forcedEmpty.contains(section);

  // ---- Lookups ----

  /// Returns the seeded [OrganizationData] for [organizationId], or null when
  /// no such tenant is seeded.
  OrganizationData? organizationDataById(String organizationId) {
    for (final OrganizationData data in _organizations) {
      if (data.organizationId == organizationId) {
        return data;
      }
    }
    return null;
  }

  // ---- Authentication ----

  /// Authenticates a demo administrator by [email] and [password].
  ///
  /// Returns an [AuthResult] (carrying a [Session] and the resolved
  /// [Organization]) when the credentials match a seeded organization;
  /// otherwise returns null to indicate an authentication failure.
  Future<AuthResult?> authenticate(String email, String password) async {
    for (final OrganizationData data in _organizations) {
      if (data.credential.matches(email, password)) {
        final Session session = Session(
          token: 'demo-token-${data.organizationId}',
          refreshToken: 'demo-refresh-${data.organizationId}',
          organizationId: data.organizationId,
        );
        return AuthResult(
          session: session,
          organization: data.organization,
        );
      }
    }
    return null;
  }

  // ---- Organization content ----

  /// Returns the [Organization] for [organizationId].
  Future<Organization?> fetchOrganization(String organizationId) async {
    _guardFailure(KioskSection.organization);
    return organizationDataById(organizationId)?.organization;
  }

  /// Returns the [BrandingProfile] for [organizationId].
  Future<BrandingProfile?> fetchBranding(String organizationId) async {
    _guardFailure(KioskSection.branding);
    return organizationDataById(organizationId)?.branding;
  }

  /// Returns the [PrayerSchedule] for [organizationId].
  ///
  /// When the prayer-schedule section is forced empty, returns a schedule with
  /// no prayers (drives the Next_Prayer_Card empty-state, Requirement 6.5).
  Future<PrayerSchedule?> fetchPrayerSchedule(String organizationId) async {
    _guardFailure(KioskSection.prayerSchedule);
    final OrganizationData? data = organizationDataById(organizationId);
    if (data == null) {
      return null;
    }
    if (_forcedEmpty.contains(KioskSection.prayerSchedule)) {
      return data.prayerSchedule.copyWith(prayers: const <PrayerTime>[]);
    }
    return data.prayerSchedule;
  }

  /// Returns programs across all seeded organizations (a cross-tenant pool).
  ///
  /// The repository scopes this to the active organization, so any items
  /// belonging to other tenants are dropped (Requirements 3.2, 3.3). When the
  /// programs section is forced empty, returns an empty list.
  Future<List<Program>> fetchPrograms() async {
    _guardFailure(KioskSection.programs);
    if (_forcedEmpty.contains(KioskSection.programs)) {
      return const <Program>[];
    }
    return <Program>[
      for (final OrganizationData data in _organizations) ...data.programs,
    ];
  }

  /// Returns donation categories across all seeded organizations (a
  /// cross-tenant pool), scoped by the repository to the active organization.
  /// When the donations section is forced empty, returns an empty list.
  Future<List<DonationCategory>> fetchDonationCategories() async {
    _guardFailure(KioskSection.donationCategories);
    if (_forcedEmpty.contains(KioskSection.donationCategories)) {
      return const <DonationCategory>[];
    }
    return <DonationCategory>[
      for (final OrganizationData data in _organizations)
        ...data.donationCategories,
    ];
  }

  void _guardFailure(KioskSection section) {
    if (_forcedFailures.contains(section)) {
      throw DemoFailureException(
        section,
        'Demo: forced failure for ${section.name}.',
      );
    }
  }
}
