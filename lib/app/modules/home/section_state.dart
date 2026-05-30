/// Per-section loading state for the Home_Screen (Requirements 13.1, 13.3,
/// 13.4).
///
/// Each Home_Screen section (prayers, programs, donations, QR) independently
/// tracks its own state so a failure in one section never affects the others.
///
/// States:
/// * [SectionLoading] — the section is fetching content; the UI shows the
///   shared [ShimmerLoader].
/// * [SectionLoaded] — content arrived and is non-empty; the UI renders it.
/// * [SectionEmpty] — the request succeeded but returned no items; the UI
///   shows the section's empty-state message.
/// * [SectionError] — the request failed or timed out; the UI shows an
///   error message and a retry control. Previously loaded content (if any) is
///   retained alongside the error so the UI can choose to display it.
sealed class SectionState<T> {
  const SectionState();
}

/// The section is currently fetching its content (Requirement 13.1).
final class SectionLoading<T> extends SectionState<T> {
  const SectionLoading();

  @override
  String toString() => 'SectionLoading<$T>()';
}

/// Content was fetched successfully and is non-empty (Requirement 13.3).
final class SectionLoaded<T> extends SectionState<T> {
  const SectionLoaded(this.data);

  /// The successfully loaded, non-empty content.
  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionLoaded<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => Object.hash(runtimeType, data);

  @override
  String toString() => 'SectionLoaded<$T>(data: $data)';
}

/// The request succeeded but returned no items (Requirements 3.5, 13.4).
final class SectionEmpty<T> extends SectionState<T> {
  const SectionEmpty();

  @override
  String toString() => 'SectionEmpty<$T>()';
}

/// The request failed or timed out (Requirements 3.6, 13.4).
///
/// [message] is the human-readable error surfaced to the user.
/// [previousData] retains any content that was loaded before the failure so
/// the UI can optionally display it alongside the error/retry control.
final class SectionError<T> extends SectionState<T> {
  const SectionError(this.message, {this.previousData});

  /// Human-readable error message.
  final String message;

  /// Previously loaded content, if any, retained across the failure.
  final T? previousData;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionError<T> &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          previousData == other.previousData;

  @override
  int get hashCode => Object.hash(runtimeType, message, previousData);

  @override
  String toString() =>
      'SectionError<$T>(message: $message, previousData: $previousData)';
}
