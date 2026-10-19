import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/token_store.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../../../data/api_client.dart';

// --- DATA LAYER PROVIDERS ---
final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepositoryImpl();
});

final apiClientProvider = Provider<Dio>((ref) {
  return buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  );
});

// --- DOMAIN LAYER PROVIDER ---
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

// --- PRESENTATION LAYER STATE NOTIFIER ---
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final loginUseCase = ref.read(loginUseCaseProvider);
    final result = await loginUseCase.call(email: email, password: password);

    if (result.failure != null) {
      state = AsyncError(result.failure!.message, StackTrace.current);
      return;
    }

    if (result.session != null) {
      await ref.read(tokenStoreProvider).save(
            access: result.session!.access,
            refresh: result.session!.refresh,
          );
      state = const AsyncData(true);
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
  }
}
