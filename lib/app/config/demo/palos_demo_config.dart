import '../../core/data/models/models.dart';
import 'demo_campaign_images.dart';

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

/// Canonical demo salah rows (Athan + Iqamah) for the prayer-times screens.
const List<PrayerTime> kDemoSalahTemplate = <PrayerTime>[
  PrayerTime(name: 'Fajr', minutesSinceMidnight: 330, iqamahMinutesSinceMidnight: 345),
  PrayerTime(name: 'Sunrise', minutesSinceMidnight: 390),
  PrayerTime(name: 'Dhuhr', minutesSinceMidnight: 770, iqamahMinutesSinceMidnight: 785),
  PrayerTime(name: 'Asr', minutesSinceMidnight: 945, iqamahMinutesSinceMidnight: 960),
  PrayerTime(
    name: 'Maghrib',
    minutesSinceMidnight: 1095,
    iqamahMinutesSinceMidnight: 1110,
  ),
  PrayerTime(name: 'Isha', minutesSinceMidnight: 1185, iqamahMinutesSinceMidnight: 1200),
];

/// Slightly earlier times for the second demo organization.
const List<PrayerTime> kDemoSalahTemplateAnnoor = <PrayerTime>[
  PrayerTime(name: 'Fajr', minutesSinceMidnight: 315, iqamahMinutesSinceMidnight: 330),
  PrayerTime(name: 'Sunrise', minutesSinceMidnight: 375),
  PrayerTime(name: 'Dhuhr', minutesSinceMidnight: 780, iqamahMinutesSinceMidnight: 795),
  PrayerTime(name: 'Asr', minutesSinceMidnight: 990, iqamahMinutesSinceMidnight: 1005),
  PrayerTime(
    name: 'Maghrib',
    minutesSinceMidnight: 1140,
    iqamahMinutesSinceMidnight: 1155,
  ),
  PrayerTime(name: 'Isha', minutesSinceMidnight: 1230, iqamahMinutesSinceMidnight: 1245),
];

const List<FridayPrayerEvent> kDemoFridayEvents = <FridayPrayerEvent>[
  FridayPrayerEvent(name: 'Dars Al Jumah', minutesSinceMidnight: 750),
  FridayPrayerEvent(name: 'First Khutbah', minutesSinceMidnight: 780),
  FridayPrayerEvent(name: 'Second Khutbah', minutesSinceMidnight: 855),
];

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
    prayers: kDemoSalahTemplate,
    fridayEvents: kDemoFridayEvents,
  ),
  programs: const <Program>[
    Program(
      organizationId: kPalosOrganizationId,
      id: 'palos-quran-circle',
      name: 'Weekly Quran Circle',
      description:
          'Study tafsir and tajweed with community teachers every week.',
      imageUrl: DemoCampaignImages.quran,
    ),
    Program(
      organizationId: kPalosOrganizationId,
      id: 'palos-youth-halaqa',
      name: 'Youth Halaqa',
      description:
          'Guided discussions and activities for teens and young adults.',
      imageUrl: DemoCampaignImages.youth,
    ),
    Program(
      organizationId: kPalosOrganizationId,
      id: 'palos-sisters-class',
      name: "Sisters' Tajweed Class",
      description:
          'Sisters-only sessions focused on Quran recitation and pronunciation.',
      imageUrl: DemoCampaignImages.sisters,
    ),
    Program(
      organizationId: kPalosOrganizationId,
      id: 'palos-new-muslim',
      name: 'New Muslim Mentorship',
      description:
          'One-on-one support for new Muslims learning prayer and daily practice.',
      imageUrl: DemoCampaignImages.mentorship,
    ),
    Program(
      organizationId: kPalosOrganizationId,
      id: 'palos-weekend-school',
      name: 'Weekend Islamic School',
      description:
          'Islamic studies, Arabic, and character building for children.',
      imageUrl: DemoCampaignImages.weekendSchool,
    ),
    Program(
      organizationId: kPalosOrganizationId,
      id: 'palos-iftar-sponsorship',
      name: 'Community Iftar Sponsorship',
      description:
          'Sponsor iftar meals for families and guests during Ramadan.',
      imageUrl: DemoCampaignImages.iftar,
    ),
    Program(
      organizationId: kPalosOrganizationId,
      id: 'palos-arabic-classes',
      name: 'Arabic Language Classes',
      description:
          'Beginner and intermediate Arabic for understanding the Quran.',
      imageUrl: DemoCampaignImages.arabic,
    ),
    Program(
      organizationId: kPalosOrganizationId,
      id: 'palos-seniors-halaqa',
      name: 'Senior Brothers Halaqa',
      description:
          'Weekly gathering for senior community members and lifelong learning.',
      imageUrl: DemoCampaignImages.seniors,
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
      imageUrl: DemoCampaignImages.zakat,
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
      imageUrl: DemoCampaignImages.sadaqah,
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
      imageUrl: DemoCampaignImages.generalFund,
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
      imageUrl: DemoCampaignImages.maintenance,
      tagLabel: 'Give Hope',
      goalAmount: 75000,
      raisedAmount: 18900,
    ),
    DonationCategory(
      organizationId: kPalosOrganizationId,
      id: 'palos-ramadan-food',
      name: 'Ramadan Food Drive',
      description:
          'Provide grocery boxes and hot meals for families throughout Ramadan.',
      imageUrl: DemoCampaignImages.ramadanFood,
      tagLabel: 'Ramadan',
      goalAmount: 40000,
      raisedAmount: 22100,
    ),
    DonationCategory(
      organizationId: kPalosOrganizationId,
      id: 'palos-youth-center',
      name: 'Youth Center Fund',
      description:
          'Fund sports, mentoring, and safe after-school space for local youth.',
      imageUrl: DemoCampaignImages.youthCenter,
      tagLabel: 'Youth',
      goalAmount: 60000,
      raisedAmount: 15800,
    ),
    DonationCategory(
      organizationId: kPalosOrganizationId,
      id: 'palos-widow-orphan',
      name: 'Widow & Orphan Support',
      description:
          'Monthly assistance for widows and orphans in our community.',
      imageUrl: DemoCampaignImages.orphan,
      tagLabel: 'Families',
      goalAmount: 35000,
      raisedAmount: 9400,
    ),
    DonationCategory(
      organizationId: kPalosOrganizationId,
      id: 'palos-cemetery',
      name: 'Cemetery & Burial Fund',
      description:
          'Help cover burial costs and cemetery upkeep for those in need.',
      imageUrl: DemoCampaignImages.building,
      tagLabel: 'Community',
      goalAmount: 45000,
      raisedAmount: 11200,
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
    prayers: kDemoSalahTemplateAnnoor,
    fridayEvents: kDemoFridayEvents,
  ),
  programs: const <Program>[
    Program(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-arabic-101',
      name: 'Arabic 101',
      description: 'Foundational Arabic grammar and vocabulary for all ages.',
      imageUrl: DemoCampaignImages.arabic,
    ),
    Program(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-weekend-school',
      name: 'Weekend School',
      description: 'Quran, Islamic studies, and enrichment every Saturday.',
      imageUrl: DemoCampaignImages.weekendSchool,
    ),
    Program(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-youth-halaqa',
      name: 'Youth Halaqa',
      description: 'Weekly youth circle with mentors and peer activities.',
      imageUrl: DemoCampaignImages.youth,
    ),
    Program(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-quran-hifz',
      name: 'Quran Memorization',
      description: 'Structured hifz program with qualified teachers.',
      imageUrl: DemoCampaignImages.quran,
    ),
    Program(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-new-muslim',
      name: 'New Muslim Support',
      description: 'Shahada, prayer, and community onboarding for converts.',
      imageUrl: DemoCampaignImages.mentorship,
    ),
    Program(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-sisters-circle',
      name: "Sisters' Circle",
      description: 'Sisters-only classes, socials, and spiritual growth.',
      imageUrl: DemoCampaignImages.sisters,
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
      imageUrl: DemoCampaignImages.zakat,
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
      imageUrl: DemoCampaignImages.building,
      goalAmount: 200000,
      raisedAmount: 67000,
    ),
    DonationCategory(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-sadaqah',
      name: 'Sadaqah',
      description: 'General charity for urgent family and community needs.',
      imageUrl: DemoCampaignImages.sadaqah,
      goalAmount: 20000,
      raisedAmount: 6100,
    ),
    DonationCategory(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-ramadan',
      name: 'Ramadan Food Drive',
      description: 'Meals and groceries for families during Ramadan.',
      imageUrl: DemoCampaignImages.ramadanFood,
      tagLabel: 'Ramadan',
      goalAmount: 28000,
      raisedAmount: 9800,
    ),
    DonationCategory(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-youth-fund',
      name: 'Youth Programs Fund',
      description: 'Support classes, trips, and mentorship for young Muslims.',
      imageUrl: DemoCampaignImages.youthCenter,
      tagLabel: 'Youth',
      goalAmount: 35000,
      raisedAmount: 7200,
    ),
    DonationCategory(
      organizationId: kMasjidAnNoorOrganizationId,
      id: 'annoor-maintenance',
      name: 'Facility Maintenance',
      description: 'Keep the masjid clean, safe, and welcoming year-round.',
      imageUrl: DemoCampaignImages.maintenance,
      goalAmount: 55000,
      raisedAmount: 14300,
    ),
  ],
);

/// All organizations seeded into the demo. The [DemoDataSource] is built from
/// this list, so onboarding another tenant is a one-line data addition.
final List<OrganizationData> demoOrganizations = <OrganizationData>[
  palosOrganizationData,
  masjidAnNoorOrganizationData,
];
