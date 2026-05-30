/// A persisted authentication session.
///
/// All three fields ([token], [refreshToken], [organizationId]) are required
/// and must be non-empty for the session to be considered valid by the
/// StorageService.
class Session {
  const Session({
    required this.token,
    required this.refreshToken,
    required this.organizationId,
  });

  final String token;
  final String refreshToken;
  final String organizationId;

  Session copyWith({
    String? token,
    String? refreshToken,
    String? organizationId,
  }) {
    return Session(
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      organizationId: organizationId ?? this.organizationId,
    );
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      organizationId: json['organizationId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'refreshToken': refreshToken,
      'organizationId': organizationId,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Session &&
            runtimeType == other.runtimeType &&
            token == other.token &&
            refreshToken == other.refreshToken &&
            organizationId == other.organizationId;
  }

  @override
  int get hashCode => Object.hash(token, refreshToken, organizationId);

  @override
  String toString() =>
      'Session(token: $token, refreshToken: $refreshToken, '
      'organizationId: $organizationId)';
}
