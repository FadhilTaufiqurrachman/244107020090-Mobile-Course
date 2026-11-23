import 'package:dio/dio.dart';

import '../features/auth/data/datasources/token_store.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import 'network_cache.dart';

Dio buildApiClient(
  TokenStore store,
  AuthRepository auth, {
  bool enableRetry = true,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example-campus-api.test',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept-Encoding': 'gzip, deflate, br',
        'Accept': 'application/json',
      },
    ),
  );

  // Retry interceptor untuk mengatasi kegagalan transient network
  if (enableRetry) {
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 5),
        ],
      ),
    );
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Setiap request ke server, sisipkan token jika ada
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        // Jika error 401 (token mati/expired)
        if (e.response?.statusCode == 401) {
          final refresh = await store.readRefresh();

          // Kalau refresh token tidak ada, relakan saja (kembalikan error)
          if (refresh == null) return handler.next(e);

          try {
            // Minta akses baru menggunakan refresh token melalui repository domain
            final renewedResult = await auth.refresh(refresh);
            if (renewedResult.refreshedToken == null) {
              throw Exception(
                renewedResult.failure?.message ?? 'Refresh gagal',
              );
            }

            final renewed = renewedResult.refreshedToken!;

            // Simpan token yang baru
            await store.save(access: renewed, refresh: refresh);

            // Ulangi request (fetch ulang) dengan token baru
            final retry = await dio.fetch(
              e.requestOptions..headers['Authorization'] = 'Bearer $renewed',
            );

            // Berhasil!
            return handler.resolve(retry);
          } catch (_) {
            // Jika refresh token juga gagal, hapus semuanya (paksa user login ulang)
            await store.clear();
          }
        }
        handler.next(e);
      },
    ),
  );

  return dio;
}
