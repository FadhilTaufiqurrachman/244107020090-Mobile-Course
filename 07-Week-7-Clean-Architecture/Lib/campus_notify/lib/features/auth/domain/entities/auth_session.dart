class AuthSession {
  const AuthSession({
    required this.access,
    required this.refresh,
    this.email,
  });

  final String access;
  final String refresh;
  final String? email;
}
