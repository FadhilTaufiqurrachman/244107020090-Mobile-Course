import '../../domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.access,
    required super.refresh,
    super.email,
  });

  Map<String, dynamic> toJson() => {
        'access': access,
        'refresh': refresh,
        if (email != null) 'email': email,
      };

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      access: json['access'] as String? ?? '',
      refresh: json['refresh'] as String? ?? '',
      email: json['email'] as String?,
    );
  }

  AuthSession toEntity() => AuthSession(
        access: access,
        refresh: refresh,
        email: email,
      );
}
