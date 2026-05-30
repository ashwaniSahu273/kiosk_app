import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/app_constants.dart';
import 'api_auth_context.dart';
import 'api_endpoints.dart';
import 'api_result.dart';

/// Centralized network client. All outbound HTTP flows through this class
/// (Requirement 10.1).
///
/// Responsibilities:
/// - Inject `Authorization: Bearer <token>` and `X-Organization-Id` from the
///   injected [ApiAuthContext] on every request (Requirements 3.1, 2.x).
/// - Apply a 30s timeout to content/auth requests and a 10s timeout to the
///   token-refresh attempt.
/// - On HTTP 401, perform a single refresh (single-flight) via the auth
///   context, then retry the original request once (Requirements 2.4, 2.5).
/// - Map every outcome (success, error, timeout, unreachable) into an
///   [ApiResult]; never throw to the caller (Requirement 10.2).
class ApiClient {
  ApiClient({
    required ApiAuthContext authContext,
    http.Client? httpClient,
    this.baseUrl = ApiEndpoints.baseUrl,
    this.contentTimeout = AppConstants.contentTimeout,
  })  : _authContext = authContext,
        _http = httpClient ?? http.Client();

  static const String _logTag = 'API_CLIENT';

  final ApiAuthContext _authContext;
  final http.Client _http;

  /// Base URL prefixed to every endpoint path.
  final String baseUrl;

  /// Timeout for content/auth requests (default 30s).
  final Duration contentTimeout;

  /// Guards single-flight token refresh: concurrent 401s share one refresh.
  Future<bool>? _inFlightRefresh;

  /// Performs a GET request and maps the outcome into an [ApiResult].
  ///
  /// [parse] converts the decoded JSON body into [T]; when omitted the decoded
  /// body is returned as-is.
  Future<ApiResult<T>> get<T>(
    String endpoint, {
    T Function(dynamic)? parse,
    Map<String, String>? headers,
    bool isRetry = false,
  }) {
    return _send<T>(
      method: 'GET',
      endpoint: endpoint,
      parse: parse,
      extraHeaders: headers,
      isRetry: isRetry,
      perform: (uri, builtHeaders) =>
          _http.get(uri, headers: builtHeaders).timeout(contentTimeout),
      retry: () => get<T>(
        endpoint,
        parse: parse,
        headers: headers,
        isRetry: true,
      ),
    );
  }

  /// Performs a POST request with a JSON [body] and maps the outcome into an
  /// [ApiResult].
  Future<ApiResult<T>> post<T>(
    String endpoint,
    Map<String, dynamic> body, {
    T Function(dynamic)? parse,
    Map<String, String>? headers,
    bool isRetry = false,
  }) {
    return _send<T>(
      method: 'POST',
      endpoint: endpoint,
      parse: parse,
      extraHeaders: headers,
      isRetry: isRetry,
      perform: (uri, builtHeaders) => _http
          .post(uri, headers: builtHeaders, body: jsonEncode(body))
          .timeout(contentTimeout),
      retry: () => post<T>(
        endpoint,
        body,
        parse: parse,
        headers: headers,
        isRetry: true,
      ),
    );
  }

  /// Shared request pipeline: builds the URL/headers, runs [perform], handles
  /// the 401 → single-refresh → single-retry flow, and maps every outcome
  /// (including transport failures) into an [ApiResult].
  Future<ApiResult<T>> _send<T>({
    required String method,
    required String endpoint,
    required T Function(dynamic)? parse,
    required Map<String, String>? extraHeaders,
    required bool isRetry,
    required Future<http.Response> Function(Uri uri, Map<String, String> headers)
        perform,
    required Future<ApiResult<T>> Function() retry,
  }) async {
    try {
      final Uri uri = Uri.parse('$baseUrl$endpoint');
      final http.Response response =
          await perform(uri, _buildHeaders(extraHeaders));

      // 401 on a protected request: attempt a single refresh, then retry once.
      if (response.statusCode == HttpStatus.unauthorized && !isRetry) {
        final bool refreshed = await _refreshOnce();
        if (refreshed) {
          return retry();
        }
      }

      return _mapResponse<T>(response, parse);
    } on TimeoutException {
      log('$_logTag timeout on $method $endpoint');
      return ApiResult<T>.failure(
        HttpStatus.requestTimeout,
        'The request timed out. Please try again.',
      );
    } on SocketException {
      log('$_logTag unreachable on $method $endpoint');
      return ApiResult<T>.failure(
        0,
        'Could not reach the server. Check your connection.',
      );
    } on http.ClientException catch (e) {
      log('$_logTag client error on $method $endpoint: $e');
      return ApiResult<T>.failure(0, 'Network error: ${e.message}');
    } catch (e) {
      log('$_logTag unexpected error on $method $endpoint: $e');
      return ApiResult<T>.failure(
        500,
        'Something went wrong. Please try again.',
      );
    }
  }

  /// Runs the auth context's single refresh attempt, collapsing concurrent
  /// callers onto one in-flight refresh (single-flight). The refresh is bounded
  /// by the 10s refresh timeout; any failure resolves to false.
  Future<bool> _refreshOnce() {
    final Future<bool>? existing = _inFlightRefresh;
    if (existing != null) {
      return existing;
    }

    final Future<bool> refresh = _authContext
        .refreshSession()
        .timeout(ApiEndpoints.refreshTimeout)
        .catchError((Object _) => false)
        .whenComplete(() => _inFlightRefresh = null);

    _inFlightRefresh = refresh;
    return refresh;
  }

  /// Maps an HTTP response into an [ApiResult]. Success is determined solely by
  /// the status code being in `[200, 300)`.
  ApiResult<T> _mapResponse<T>(
    http.Response response,
    T Function(dynamic)? parse,
  ) {
    final int statusCode = response.statusCode;
    final bool isSuccess = ApiResult.isSuccessStatus(statusCode);

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        // Non-JSON body: keep the raw string so callers/messages can use it.
        decoded = response.body;
      }
    }

    if (isSuccess) {
      final T? data = parse != null ? parse(decoded) : decoded as T?;
      return ApiResult<T>(
        success: true,
        statusCode: statusCode,
        message: _extractMessage(decoded),
        data: data,
      );
    }

    return ApiResult<T>.failure(
      statusCode,
      _extractMessage(decoded) ?? 'Request failed with status $statusCode.',
    );
  }

  /// Best-effort extraction of a human-readable message from a decoded body.
  String? _extractMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final Object? msg = decoded['message'] ?? decoded['msg'] ?? decoded['error'];
      if (msg is String && msg.isNotEmpty) {
        return msg;
      }
    } else if (decoded is String && decoded.isNotEmpty) {
      return decoded;
    }
    return null;
  }

  /// Builds request headers, injecting auth and organization scoping from the
  /// [ApiAuthContext]. Caller-supplied [extraHeaders] take precedence.
  Map<String, String> _buildHeaders(Map<String, String>? extraHeaders) {
    final String? token = _authContext.accessToken;
    final String? orgId = _authContext.organizationId;

    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        AppConstants.authorizationHeader: 'Bearer $token',
      if (orgId != null && orgId.isNotEmpty)
        AppConstants.organizationIdHeader: orgId,
      ...?extraHeaders,
    };
  }

  /// Releases the underlying HTTP client. Call when the client is disposed.
  void close() => _http.close();
}
