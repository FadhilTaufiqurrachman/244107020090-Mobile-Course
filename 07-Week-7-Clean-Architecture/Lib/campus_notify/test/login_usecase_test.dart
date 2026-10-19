import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/auth/domain/usecases/login_usecase.dart';

// Fake Repository murni untuk domain testing auth
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.fail = false});

  final bool fail;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    if (fail) {
      return (
        session: null,
        failure: const AuthFailure('Email atau kata sandi tidak cocok'),
      );
    }

    return (
      session: AuthSession(
        access: 'mock-access-token',
        refresh: 'mock-refresh-token',
        email: email,
      ),
      failure: null,
    );
  }

  @override
  Future<({String? refreshedToken, Failure? failure})> refresh(
    String refreshToken,
  ) async {
    if (fail) {
      return (refreshedToken: null, failure: const AuthFailure('Refresh gagal'));
    }
    return (refreshedToken: 'new-token', failure: null);
  }
}

void main() {
  group('LoginUseCase Tests', () {
    test('Berhasil login dan mengembalikan AuthSession tanpa failure', () async {
      final repo = FakeAuthRepository(fail: false);
      final useCase = LoginUseCase(repo);

      final result = await useCase.call(
        email: 'mahasiswa@kampus.ac.id',
        password: 'password123',
      );

      expect(result.failure, isNull);
      expect(result.session, isNotNull);
      expect(result.session!.access, 'mock-access-token');
      expect(result.session!.email, 'mahasiswa@kampus.ac.id');
    });

    test('Mengembalikan AuthFailure tanpa melempar exception saat kredensial salah',
        () async {
      final repo = FakeAuthRepository(fail: true);
      final useCase = LoginUseCase(repo);

      final result = await useCase.call(
        email: 'salah@kampus.ac.id',
        password: 'wrong',
      );

      expect(result.session, isNull);
      expect(result.failure, isA<AuthFailure>());
      expect(result.failure!.message, 'Email atau kata sandi tidak cocok');
    });
  });
}
