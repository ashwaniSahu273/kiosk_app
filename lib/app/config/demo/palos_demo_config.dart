import '../../core/data/models/models.dart';

/// Documented default color roles (the Palos / `palos-new` palette) used by the
/// seeded demo organizations. Mirrors the table in the design's "Documented
/// Default Color Roles" section so the demo data renders with the reference
/// palette even before the dedicated `kiosk_colors.dart` (Task 7.1) exists.
class DemoPalette {
  const DemoPalette._();

  static const int palosPrimary = 0xFF2E7D32;
  static const int palosSecondary = 0xFF58BA47;
  static const int palosAccent = 0xFF81C784;
  static const int palosScaffoldBackground = 0xFFF5F7FA;
}

/// A demo administrator credential that resolves to a single [Organization].
///
/// The [DemoDataSource] matches a submitted email/password pair against these
/// credentials to authenticate the demo (offline) login.
class DemoCredential {
  const DemoCredential({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  /// Case-insensitive, trim-tolerant match for the submitted [email] and exact
  /// match for the [password].
  bool matches(String submittedEmail, String submittedPassword) {
    return submittedEmail.trim().toLowerCase() == email.toLowerCase() &&
        submittedPassword == password;
  }
}

/// A fully seeded organization for the data-driven demo.
///
/// Bundles everything the kiosk needs to render an organization end-to-end:
/// the [organization] (id + [BrandingProfile]), an admin [credential] so login
/// can resolve this tenant, the day's [prayerSchedule], the available
/// [programs], and the [donationCategories]. Adding a new organization to the
/// demo is purely a matter of adding another [OrganizationData] value — no
/// source-code branching required (Requirement 11.1).
class OrganizationData {
  const OrganizationData({
    required this.organization,
    required this.credential,
    required this.prayerSchedule,
    required this.programs,
    required this.donationCategories,
  });

  final Organization organization;
  final DemoCredential credential;
  final PrayerSchedule prayerSchedule;
  final List<Program> programs;
  final List<DonationCategory> donationCategories;

  /// Convenience accessor for the tenant identifier.
  String get organizationId => organization.id;

  /// Convenience accessor for the tenant's branding.
  BrandingProfile get branding => organization.branding;
}

/// Identifier of the seeded Palos organization.
const String kPalosOrganizationId = 'palos';

/// Identifier of the second seeded organization (proves multi-tenant
/// onboarding works from data alone).
const String kMasjidAnNoorOrganizationId = 'an-noor';

/// A fixed reference date for the seeded prayer schedules so the demo is
/// deterministic. Only the time-of-day (minutesSinceMidnight) matters for the
/// next-prayer countdown; the date anchors the schedule for display.
final DateTime _demoScheduleDate = DateTime(2024, 1, 1);

/// The seeded Palos organization data set (the primary Demo_Configuration).
///
/// Uses the palos-new reference palette (Requirement 4.7) and provides a full
/// daily prayer schedule, several programs, several donation categories, and a
/// donation URL so the Home_Screen can render the complete layout offline
/// (Requirement 12.1).
final OrganizationData palosOrganizationData = OrganizationData(
  organization: const Organization(
    id: kPalosOrganizationId,
    branding: BrandingProfile(
      organizationId: kPalosOrganizationId,
      displayName: 'Palos Masjid',
      logoRef: 'assets/images/kiosk_default_logo.png',
      primaryColor: DemoPalette.palosPrimary,
      secondaryColor: DemoPalette.palosSecondary,
      accentColor: DemoPalette.palosAccent,
      scaffoldBackgroundColor: DemoPalette.palosScaffoldBackground,
      donationUrl: 'https://palosmasjid.org/donate',
    ),
  ),
  credential: const DemoCredential(
    email: 'admin@palos.org',
    password: 'palos123',
  ),
  prayerSchedule: PrayerSchedule(
    organizationId: kPalosOrganizationId,
    date: _demoScheduleDate,
    prayers: const <PrayerTime>[
      PrayerTime(name: 'Fajr', minutesSinceMidnight: 330), // 5:30 AM
      PrayerTime(name: 'Dhuhr', minutesSinceMidnight: 750), // 12:30 PM
      PrayerTime(name: 'Asr', minutesSinceMidnight: 945), // 3:45 PM
      PrayerTime(name: 'Maghrib', minutesSinceMidnight: 1095), // 6:15 PM
      PrayerTime(name: 'Isha', minutesSinceMidnight: 1185), // 7:45 PM
    ],
  ),
  programs: const <Program>[
    Program(
      organizationId: kPalosOrganizationId,
      id: 'palos-quran-circle',
      name: 'Weekly Quran Circle',
    ),
    Program(
      organizationId: kPalosOrganizationId,
      id: 'palos-youth-halaqa',
      name: 'Youth Halaqa',
    ),
    Program(
      organizationId: kPalosOrganizationId,
      id: 'palos-sisters-class',
      name: "Sisters' Tajweed Class",
    ),
    Program(
      organizationId: kPalosOrganizationId,
      id: 'palos-new-muslim',
      name: 'New Muslim Mentorship',
    ),
  ],
  donationCategories: const <DonationCategory>[
    DonationCategory(
      organizationId: kPalosOrganizationId,
      id: 'palos-zakat',
      name: 'Zakat Fund',
      description:
          'Fulfill your Zakat obligation and support families in need within '
          'our community throughout the year.',
      tagLabel: 'Give Hope',
      goalAmount: 50000,
      raisedAmount: 12500,
    ),
    DonationCategory(
      organizationId: kPalosOrganizationId,
      id: 'palos-sadaqah',
      name: 'Sadaqah',
      description:
          'Your voluntary charity helps provide meals, utilities assistance, '
          'and emergency support for local families.',
      tagLabel: 'Give Hope',
      goalAmount: 25000,
      raisedAmount: 8200,
    ),
    DonationCategory(
      organizationId: kPalosOrganizationId,
      id: 'palos-general-fund',
      name: 'General Fund',
      description:
          'Support daily masjid operations, programs, and community outreach '
          'initiatives that serve everyone who walks through our doors.',
      tagLabel: 'Give Hope',
      goalAmount: 100000,
      raisedAmount: 34200,
    ),
    DonationCategory(
      organizationId: kPalosOrganizationId,
      id: 'palos-masjid-maintenance',
      name: 'Masjid Maintenance',
      description:
          'Help maintain and improve our facilities — from HVAC and plumbing '
          'to prayer hall upgrades and accessibility improvements.',
      tagLabel: 'Give Hope',
      goalAmount: 75000,
      raisedAmount: 18900,
    ),
  ],
);

/// A second, minimal organization that proves multi-tenant onboarding works
/// from data alone: a different id, a different branding palette, its own admin
/// credential, prayer schedule, programs, and donation categories.
final OrganizationData masjidAnNoorOrganizationData = OrganizationData(
  organization: const Organization(
    id: kMasjidAnNoorOrganizationId,
    branding: BrandingProfile(
      organizationId: kMasjidAnNoorOrganizationId,
      displayName: 'Masjid An-Noor',
      // No logoRef: exercises the bundled default-placeholder fallback.
      primaryColor: 0xFF1565C0, // blue primary (distinct from Palos green)
      secondaryColor: 0xFF42A5F5,
      accentColor: 0xFF90CAF9,
      scaffoldBackgroundColor: 0xFFEFF3F8,
      donationUrl: 'https://annoor.org/give',
    ),
  ),
  credential: const DemoCredential(
    email: 'admin@annoor.org',
    password: 'annoor123',
  ),
  prayerSchedule: PrayerSchedule(
    organizationId: kMasjidAnNoorOrganizationId,
    date: _demoScheduleDate,
    prayers: const <PrayerTime>[
      PrayerTime(name: 'Fajr', minutesSinceMidnight: 315), // 5:15 AM
      PrayerTime(name: 'Dhuhr', minutesSinceMidnight: 780), // 1:00 PM
      PrayerTime(name: 'Asr', minutesSinceMidnight: 990), // 4:30 PM
      PrayerTime(name: 'Maghrib', minutesSinceMidnight: 1140), // 7:00 PM
      PrayerTime(name: 'Isha', minutesSinceMidnight: 1230), // 8:30 PM
    ],
  ),
  programs: const <Program>[
    Program(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-arabic-101',
      name: 'Arabic 101',
    ),
    Program(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-weekend-school',
      name: 'Weekend School',
    ),
  ],
  donationCategories: const <DonationCategory>[
    DonationCategory(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-zakat',
      name: 'Zakat',
      description:
          'Support eligible recipients in our community through your annual '
          'Zakat contribution.',
      goalAmount: 30000,
      raisedAmount: 4500,
    ),
    DonationCategory(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-building-fund',
      name: 'Building Fund',
      description:
          'Help expand and renovate our masjid so we can welcome more families '
          'for prayer, classes, and community events.',
      goalAmount: 200000,
      raisedAmount: 67000,
    ),
  ],
);

/// All organizations seeded into the demo. The [DemoDataSource] is built from
/// this list, so onboarding another tenant is a one-line data addition.
final List<OrganizationData> demoOrganizations = <OrganizationData>[
  palosOrganizationData,
  masjidAnNoorOrganizationData,
];
