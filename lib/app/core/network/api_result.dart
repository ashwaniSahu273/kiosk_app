/// The single typed result wrapper returned by the [ApiClient] to every caller.
///
/// Every HTTP response and transport outcome (success, error, timeout,
/// unreachable) is mapped into an [ApiResult]; the client never throws to the
/// caller. By construction, [success] is true if and only if [statusCode] is in
/// the half-open range `[200, 300)`.
///
/// Satisfies Requirements 10.1, 10.2 (typed result wrapper with a success flag,
/// status code, optional message, and optional typed data).
class ApiResult<T> {
  /// Creates a result directly. Prefer the [ApiResult.success] and
  /// [ApiResult.failure] factories, which enforce the success/status invariant.
  const ApiResult({
    required this.success,
    required this.statusCode,
    this.message,
    this.data,
  });

  /// True if and only if [statusCode] is in `[200, 300)`.
  final bool success;

  /// The HTTP status code, or a synthetic code for transport outcomes
  /// (for example `408` for a timeout and `0` when the host is unreachable).
  final int statusCode;

  /// Optional human-readable message (error detail or server message).
  final String? message;

  /// Optional typed payload, present on successful, parsed responses.
  final T? data;

  /// Whether [statusCode] falls within the HTTP success range `[200, 300)`.
  static bool isSuccessStatus(int statusCode) =>
      statusCode >= 200 && statusCode < 300;

  /// Builds a successful result. Asserts the status code is in `[200, 300)` so
  /// success results cannot be constructed with a non-success status.
  factory ApiResult.success(int statusCode, T data, {String? message}) {
    assert(
      isSuccessStatus(statusCode),
      'ApiResult.success requires a status code in [200, 300), got $statusCode',
    );
    return ApiResult<T>(
      success: true,
      statusCode: statusCode,
      message: message,
      data: data,
    );
  }

  /// Builds a failure result. Forces [success] to false regardless of the
  /// status code so callers can rely on the invariant.
  factory ApiResult.failure(int statusCode, String message) {
    return ApiResult<T>(
      success: false,
      statusCode: statusCode,
      message: message,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ApiResult<T> &&
            runtimeType == other.runtimeType &&
            success == other.success &&
            statusCode == other.statusCode &&
            message == other.message &&
            data == other.data;
  }

  @override
  int get hashCode => Object.hash(runtimeType, success, statusCode, message, data);

  @override
  String toString() =>
      'ApiResult<$T>(success: $success, statusCode: $statusCode, '
      'message: $message, data: $data)';
}
