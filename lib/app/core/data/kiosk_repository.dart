import '../network/api_result.dart';
import 'demo_data_source.dart';
import 'models/models.dart';

/// Centralized read/auth gateway for organization content.
///
/// Every read returns the typed [ApiResult] wrapper (Requirement 10.2) and the
/// repository never throws to its caller. For the offline demo it is backed by
/// a [DemoDataSource]; the same surface is structured so a later task can swap
/// in the `ApiClient` without changing callers.
///
/// Org-scoping (Requirements 3.2, 3.3): every list read is filtered to the
/// active organization id and any item whose `organizationId` does not match is
/// dropped, so cross-tenant content can never reach the UI.
class KioskRepository {
  KioskRepository({required DemoDataSource dataSource})
      : _dataSource = dataSource;

  final DemoDataSource _dataSource;

  /// The underlying demo data source, exposed so callers (and the demo
  /// harness) can drive the failure/empty toggles.
  DemoDataSource get dataSource => _dataSource;

  // ---- Authentication ----

  /// Authenticates an administrator and resolves their organization.
  ///
  /// Returns `ApiResult.success` with the [AuthResult] when the credentials
  /// match a seeded organization; otherwise `ApiResult.failure(401, ...)`.
  Future<ApiResult<AuthResult>> login(String email, String password) async {
    try {
      final AuthResult? result = await _dataSource.authenticate(email, password);
      if (result == null) {
        return ApiResult<AuthResult>.failure(
          401,
          'Invalid email or password.',
        );
      }
      return ApiResult<AuthResult>.success(200, result);
    } on DemoFailureException catch (e) {
      return ApiResult<AuthResult>.failure(500, _failureMessage(e));
    } catch (e) {
      return ApiResult<AuthResult>.failure(
        500,
        'Sign-in could not be completed. Please try again.',
      );
    }
  }

  // ---- Organization content reads ----

  /// Fetches the [Organization] for [organizationId].
  Future<ApiResult<Organization>> fetchOrganization(
    String organizationId,
  ) async {
    return _read<Organization>(
      () => _dataSource.fetchOrganization(organizationId),
      notFoundMessage: 'Organization not found.',
    );
  }

  /// Fetches the [BrandingProfile] for [organizationId].
  Future<ApiResult<BrandingProfile>> fetchBranding(
    String organizationId,
  ) async {
    return _read<BrandingProfile>(
      () => _dataSource.fetchBranding(organizationId),
      notFoundMessage: 'Branding not found for this organization.',
    );
  }

  /// Fetches the [PrayerSchedule] for [organizationId].
  ///
  /// The schedule is dropped (treated as not found) if its organization id does
  /// not match [organizationId], upholding org-scoping for the single-item read.
  Future<ApiResult<PrayerSchedule>> fetchPrayerSchedule(
    String organizationId,
  ) async {
    return _read<PrayerSchedule>(
      () => _dataSource.fetchPrayerSchedule(organizationId),
      notFoundMessage: 'Prayer schedule not found for this organization.',
      accept: (PrayerSchedule schedule) =>
          schedule.organizationId == organizationId,
    );
  }

  /// Fetches the [Program] list scoped to [organizationId].
  ///
  /// Items belonging to other tenants are dropped (Requirements 3.2, 3.3).
  Future<ApiResult<List<Program>>> fetchPrograms(String organizationId) async {
    return _readScopedList<Program>(
      _dataSource.fetchPrograms,
      organizationId,
    );
  }

  /// Fetches the [DonationCategory] list scoped to [organizationId].
  ///
  /// Items belonging to other tenants are dropped (Requirements 3.2, 3.3).
  Future<ApiResult<List<DonationCategory>>> fetchDonationCategories(
    String organizationId,
  ) async {
    return _readScopedList<DonationCategory>(
      _dataSource.fetchDonationCategories,
      organizationId,
    );
  }

  // ---- Internal helpers ----

  /// Reads a single nullable value and maps it into an [ApiResult]. A null (or
  /// rejected-by-[accept]) value becomes a 404 failure; a [DemoFailureException]
  /// becomes a 500 failure.
  Future<ApiResult<T>> _read<T>(
    Future<T?> Function() read, {
    required String notFoundMessage,
    bool Function(T value)? accept,
  }) async {
    try {
      final T? value = await read();
      if (value == null || (accept != null && !accept(value))) {
        return ApiResult<T>.failure(404, notFoundMessage);
      }
      return ApiResult<T>.success(200, value);
    } on DemoFailureException catch (e) {
      return ApiResult<T>.failure(500, _failureMessage(e));
    } catch (e) {
      return ApiResult<T>.failure(500, 'Content could not be loaded.');
    }
  }

  /// Reads a list of organization-owned items, filters it to [organizationId]
  /// (dropping every mismatched item), and maps the outcome into an
  /// [ApiResult]. An empty result after filtering is still a success carrying an
  /// empty list, so the caller can render the section's empty-state.
  Future<ApiResult<List<T>>> _readScopedList<T extends OrgOwned>(
    Future<List<T>> Function() read,
    String organizationId,
  ) async {
    try {
      final List<T> all = await read();
      final List<T> scoped = scopeToOrganization<T>(all, organizationId);
      return ApiResult<List<T>>.success(200, scoped);
    } on DemoFailureException catch (e) {
      return ApiResult<List<T>>.failure(500, _failureMessage(e));
    } catch (e) {
      return ApiResult<List<T>>.failure(500, 'Content could not be loaded.');
    }
  }

  String _failureMessage(DemoFailureException e) =>
      e.message ?? 'Content could not be loaded.';

  /// Pure org-scoping filter: keeps only items whose `organizationId` equals
  /// [organizationId] and drops all others (Requirements 3.2, 3.3).
  ///
  /// Exposed statically so it can be reused (and, in a later task, property
  /// tested) independently of the data source.
  static List<T> scopeToOrganization<T extends OrgOwned>(
    List<T> items,
    String organizationId,
  ) {
    return items
        .where((T item) => item.organizationId == organizationId)
        .toList(growable: false);
  }
}
