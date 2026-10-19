import '../../../../core/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl();

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      // Simulasi delay jaringan/autentikasi
      await Future.delayed(const Duration(milliseconds: 500));

      // Validasi logika bisnis
      if (!email.contains('@') || password.length < 6) {
        return (
          session: null,
          failure: const AuthFailure('Email tidak valid atau kata sandi kurang dari 6 karakter'),
        );
      }

      final model = AuthSessionModel(
        access: 'mock-access-for-$email',
        refresh: 'mock-refresh-for-$email',
        email: email,
      );

      return (session: model.toEntity(), failure: null);
    } catch (e) {
      return (
        session: null,
        failure: AuthFailure('Gagal melakukan autentikasi: $e'),
      );
    }
  }

  @override
  Future<({String? refreshedToken, Failure? failure})> refresh(
    String refreshToken,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (refreshToken.isEmpty) {
        return (
          refreshedToken: null,
          failure: const AuthFailure('Refresh token tidak ditemukan atau kosong'),
        );
      }

      final renewed =
          'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
      return (refreshedToken: renewed, failure: null);
    } catch (e) {
      return (
        refreshedToken: null,
        failure: AuthFailure('Gagal memperbarui token: $e'),
      );
    }
  }
}
