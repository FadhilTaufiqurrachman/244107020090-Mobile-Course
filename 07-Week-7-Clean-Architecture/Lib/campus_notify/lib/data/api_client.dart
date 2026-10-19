import 'package:dio/dio.dart';
import '../features/auth/data/datasources/token_store.dart';
import '../features/auth/domain/repositories/auth_repository.dart';

Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));

  dio.interceptors.add(InterceptorsWrapper(
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
            throw Exception(renewedResult.failure?.message ?? 'Refresh gagal');
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
  ));

  return dio;
}