import 'organization.dart';
import 'session.dart';

/// The result of a successful login request.
///
/// Carries the authenticated [session] (token, refresh token, and resolved
/// organization id) and, optionally, the resolved [organization] (including its
/// branding) when the login response also returns it. When the organization is
/// not part of the login response, [organization] is null and the caller
/// resolves it separately using [Session.organizationId].
class AuthResult {
  const AuthResult({
    required this.session,
    this.organization,
  });

  final Session session;
  final Organization? organization;

  AuthResult copyWith({
    Session? session,
    Organization? organization,
  }) {
    return AuthResult(
      session: session ?? this.session,
      organization: organization ?? this.organization,
    );
  }

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final Object? org = json['organization'];
    return AuthResult(
      session: Session.fromJson(json['session'] as Map<String, dynamic>),
      organization: org == null
          ? null
          : Organization.fromJson(org as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'session': session.toJson(),
      'organization': organization?.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthResult &&
            runtimeType == other.runtimeType &&
            session == other.session &&
            organization == other.organization;
  }

  @override
  int get hashCode => Object.hash(session, organization);

  @override
  String toString() =>
      'AuthResult(session: $session, organization: $organization)';
}
