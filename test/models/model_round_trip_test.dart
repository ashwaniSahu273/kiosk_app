// Property-based tests for model serialization round-trips.
//
// Feature: kiosk-multi-tenant-app, Property: model serialization round-trip
//   — fromJson(toJson(x)) == x
//
// Validates: Requirements 10.2 (design Property 23 family — serialization
// round-trip correctness). Each property below runs a minimum of 100 iterations
// (glados default is 100; configured explicitly via ExploreConfig).
//
// These tests use `glados` with custom generators for every core model. The
// generators intentionally cover nullable fields (both null and present values)
// for BrandingProfile (logoRef / colors / donationUrl) and AuthResult
// (organization). PrayerSchedule.date is generated from epoch-milliseconds via
// DateTime.fromMillisecondsSinceEpoch(..., isUtc: true) so that it survives the
// ISO-8601 string round-trip (DateTime.parse(toIso8601String())) exactly,
// avoiding microsecond-precision and timezone/DST ambiguity.

import 'package:glados/glados.dart';
import 'package:kiosk_app/app/core/data/models/models.dart';

/// Minimum iterations per property test (design requires >= 100).
final ExploreConfig _explore = ExploreConfig(numRuns: 100);

/// Strings that may be empty or non-empty (letters + digits). Round-trips
/// trivially through the in-memory Map produced by toJson/fromJson.
final Generator<String> _strings = any.letterOrDigits;

/// Epoch-milliseconds within ~±253 years of the UNIX epoch. Kept well inside
/// the valid DateTime range so construction never overflows.
final Generator<int> _epochMillis = any.intInRange(-8000000000000, 8000000000000);

/// UTC DateTimes that survive the ISO-8601 string round-trip exactly.
final Generator<DateTime> _dateTimes =
    _epochMillis.map((int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true));

final Generator<BrandingProfile> _brandingProfiles = any.combine8(
  _strings, // organizationId
  _strings, // displayName
  _strings.nullable, // logoRef (nullable)
  any.int.nullable, // primaryColor (nullable)
  any.int.nullable, // secondaryColor (nullable)
  any.int.nullable, // accentColor (nullable)
  any.int.nullable, // scaffoldBackgroundColor (nullable)
  _strings.nullable, // donationUrl (nullable)
  (
    String organizationId,
    String displayName,
    String? logoRef,
    int? primaryColor,
    int? secondaryColor,
    int? accentColor,
    int? scaffoldBackgroundColor,
    String? donationUrl,
  ) =>
      BrandingProfile(
    organizationId: organizationId,
    displayName: displayName,
    logoRef: logoRef,
    primaryColor: primaryColor,
    secondaryColor: secondaryColor,
    accentColor: accentColor,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    donationUrl: donationUrl,
  ),
);

final Generator<Organization> _organizations = any.combine2(
  _strings,
  _brandingProfiles,
  (String id, BrandingProfile branding) =>
      Organization(id: id, branding: branding),
);

final Generator<PrayerTime> _prayerTimes = any.combine2(
  _strings,
  any.intInRange(0, 1440), // minutesSinceMidnight in 0..1439
  (String name, int minutes) =>
      PrayerTime(name: name, minutesSinceMidnight: minutes),
);

final Generator<PrayerSchedule> _prayerSchedules = any.combine3(
  _strings,
  _dateTimes,
  any.list(_prayerTimes), // may be empty
  (String organizationId, DateTime date, List<PrayerTime> prayers) =>
      PrayerSchedule(
    organizationId: organizationId,
    date: date,
    prayers: prayers,
  ),
);

final Generator<Program> _programs = any.combine3(
  _strings,
  _strings,
  _strings,
  (String organizationId, String id, String name) =>
      Program(organizationId: organizationId, id: id, name: name),
);

final Generator<DonationCategory> _donationCategories = any.combine3(
  _strings,
  _strings,
  _strings,
  (String organizationId, String id, String name) =>
      DonationCategory(organizationId: organizationId, id: id, name: name),
);

final Generator<Session> _sessions = any.combine3(
  _strings,
  _strings,
  _strings,
  (String token, String refreshToken, String organizationId) => Session(
    token: token,
    refreshToken: refreshToken,
    organizationId: organizationId,
  ),
);

final Generator<AuthResult> _authResults = any.combine2(
  _sessions,
  _organizations.nullable, // organization is optional
  (Session session, Organization? organization) =>
      AuthResult(session: session, organization: organization),
);

void main() {
  group('Model serialization round-trips (fromJson(toJson(x)) == x)', () {
    // Feature: kiosk-multi-tenant-app, Property: model serialization round-trip
    //   — fromJson(toJson(x)) == x
    // Validates: Requirements 10.2
    Glados<BrandingProfile>(_brandingProfiles, _explore).test(
      'BrandingProfile (incl. null/present logoRef, colors, donationUrl)',
      (BrandingProfile x) {
        expect(BrandingProfile.fromJson(x.toJson()), equals(x));
      },
    );

    // Feature: kiosk-multi-tenant-app, Property: model serialization round-trip
    //   — fromJson(toJson(x)) == x
    // Validates: Requirements 10.2
    Glados<Organization>(_organizations, _explore).test(
      'Organization (nested BrandingProfile)',
      (Organization x) {
        expect(Organization.fromJson(x.toJson()), equals(x));
      },
    );

    // Feature: kiosk-multi-tenant-app, Property: model serialization round-trip
    //   — fromJson(toJson(x)) == x
    // Validates: Requirements 10.2
    Glados<PrayerTime>(_prayerTimes, _explore).test(
      'PrayerTime',
      (PrayerTime x) {
        expect(PrayerTime.fromJson(x.toJson()), equals(x));
      },
    );

    // Feature: kiosk-multi-tenant-app, Property: model serialization round-trip
    //   — fromJson(toJson(x)) == x
    // Validates: Requirements 10.2
    Glados<PrayerSchedule>(_prayerSchedules, _explore).test(
      'PrayerSchedule (ISO-8601 date round-trip + possibly empty prayers)',
      (PrayerSchedule x) {
        expect(PrayerSchedule.fromJson(x.toJson()), equals(x));
      },
    );

    // Feature: kiosk-multi-tenant-app, Property: model serialization round-trip
    //   — fromJson(toJson(x)) == x
    // Validates: Requirements 10.2
    Glados<Program>(_programs, _explore).test(
      'Program',
      (Program x) {
        expect(Program.fromJson(x.toJson()), equals(x));
      },
    );

    // Feature: kiosk-multi-tenant-app, Property: model serialization round-trip
    //   — fromJson(toJson(x)) == x
    // Validates: Requirements 10.2
    Glados<DonationCategory>(_donationCategories, _explore).test(
      'DonationCategory',
      (DonationCategory x) {
        expect(DonationCategory.fromJson(x.toJson()), equals(x));
      },
    );

    // Feature: kiosk-multi-tenant-app, Property: model serialization round-trip
    //   — fromJson(toJson(x)) == x
    // Validates: Requirements 10.2
    Glados<Session>(_sessions, _explore).test(
      'Session',
      (Session x) {
        expect(Session.fromJson(x.toJson()), equals(x));
      },
    );

    // Feature: kiosk-multi-tenant-app, Property: model serialization round-trip
    //   — fromJson(toJson(x)) == x
    // Validates: Requirements 10.2
    Glados<AuthResult>(_authResults, _explore).test(
      'AuthResult (incl. null/present organization)',
      (AuthResult x) {
        expect(AuthResult.fromJson(x.toJson()), equals(x));
      },
    );
  });

  // Example-based edge cases that complement the property tests above.
  group('Model round-trip edge cases (examples)', () {
    test('BrandingProfile with all optional fields null', () {
      const x = BrandingProfile(
        organizationId: 'org-1',
        displayName: 'Palos',
      );
      expect(BrandingProfile.fromJson(x.toJson()), equals(x));
    });

    test('BrandingProfile with all optional fields present', () {
      const x = BrandingProfile(
        organizationId: 'org-1',
        displayName: 'Palos',
        logoRef: 'assets/images/logo.png',
        primaryColor: 0xFF2E7D32,
        secondaryColor: 0xFF58BA47,
        accentColor: 0xFF1B5E20,
        scaffoldBackgroundColor: 0xFFF5F7FA,
        donationUrl: 'https://example.org/donate',
      );
      expect(BrandingProfile.fromJson(x.toJson()), equals(x));
    });

    test('PrayerSchedule with empty prayers list', () {
      final x = PrayerSchedule(
        organizationId: 'org-1',
        date: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
        prayers: const <PrayerTime>[],
      );
      expect(PrayerSchedule.fromJson(x.toJson()), equals(x));
    });

    test('PrayerSchedule with a populated prayers list', () {
      final x = PrayerSchedule(
        organizationId: 'org-1',
        date: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
        prayers: const <PrayerTime>[
          PrayerTime(name: 'Fajr', minutesSinceMidnight: 300),
          PrayerTime(name: 'Dhuhr', minutesSinceMidnight: 780),
          PrayerTime(name: 'Isha', minutesSinceMidnight: 1230),
        ],
      );
      expect(PrayerSchedule.fromJson(x.toJson()), equals(x));
    });

    test('AuthResult without organization', () {
      const x = AuthResult(
        session: Session(
          token: 't',
          refreshToken: 'r',
          organizationId: 'org-1',
        ),
      );
      expect(AuthResult.fromJson(x.toJson()), equals(x));
    });

    test('AuthResult with organization', () {
      const x = AuthResult(
        session: Session(
          token: 't',
          refreshToken: 'r',
          organizationId: 'org-1',
        ),
        organization: Organization(
          id: 'org-1',
          branding: BrandingProfile(
            organizationId: 'org-1',
            displayName: 'Palos',
          ),
        ),
      );
      expect(AuthResult.fromJson(x.toJson()), equals(x));
    });
  });
}
