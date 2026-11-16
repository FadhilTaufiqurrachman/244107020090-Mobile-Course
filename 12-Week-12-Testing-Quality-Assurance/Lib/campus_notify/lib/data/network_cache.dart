import 'dart:async';
import 'package:dio/dio.dart';

/// Kebijakan caching untuk request jaringan
enum CachePolicy {
  /// Membaca dari cache terlebih dahulu; jika kosong baru fetch ke server.
  cacheFirst,

  /// Mengambil data dari server terlebih dahulu; simpan ke cache; fallback ke cache jika gagal.
  networkFirst,

  /// Menampilkan data cache yang ada segera, sambil memperbarui data di latar belakang.
  staleWhileRevalidate,

  /// Hanya membaca dari database/penyimpanan lokal tanpa akses jaringan sama sekali.
  cacheOnly,
}

/// Representasi entri cache dengan timestamp kedaluwarsa
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration maxAge;

  const CacheEntry({
    required this.data,
    required this.timestamp,
    this.maxAge = const Duration(minutes: 10),
  });

  bool get isExpired => DateTime.now().difference(timestamp) > maxAge;
}

/// Penyimpanan cache memori sederhana
class InMemoryCacheStorage {
  final Map<String, CacheEntry<dynamic>> _store = {};

  void write<T>(String key, T data, {Duration maxAge = const Duration(minutes: 10)}) {
    _store[key] = CacheEntry<T>(
      data: data,
      timestamp: DateTime.now(),
      maxAge: maxAge,
    );
  }

  T? read<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    return entry.data as T?;
  }

  bool hasValid(String key) {
    final entry = _store[key];
    return entry != null && !entry.isExpired;
  }

  void clear() => _store.clear();
}

/// Interceptor Dio untuk percobaan ulang request secara otomatis (Retry Pattern)
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;
  final void Function(String message)? logPrint;

  RetryInterceptor({
    required this.dio,
    this.retries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 5),
    ],
    this.logPrint,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final extra = err.requestOptions.extra;
    final retryCount = (extra['retry_count'] as int?) ?? 0;

    // Retry hanya jika error terkait koneksi atau batas waktu (transient failure)
    final isTransient =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if (isTransient && retryCount < retries) {
      final nextCount = retryCount + 1;
      extra['retry_count'] = nextCount;

      final delay = retryCount < retryDelays.length
          ? retryDelays[retryCount]
          : retryDelays.last;

      logPrint?.call(
        '[RetryInterceptor] Request gagal: ${err.message}. Mencoba ulang #$nextCount dalam ${delay.inSeconds}s...',
      );

      await Future.delayed(delay);

      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return onError(retryErr, handler);
      }
    }

    return handler.next(err);
  }
}

/// Interceptor Dio untuk caching berbasis HTTP Request
class CacheInterceptor extends Interceptor {
  final InMemoryCacheStorage storage;
  final CachePolicy policy;

  CacheInterceptor({
    required this.storage,
    this.policy = CachePolicy.staleWhileRevalidate,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Hanya tangani HTTP GET untuk caching
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    final cacheKey = options.uri.toString();
    final cachedData = storage.read<dynamic>(cacheKey);

    if (policy == CachePolicy.cacheFirst && cachedData != null) {
      // Kembalikan langsung dari cache
      return handler.resolve(
        Response(
          requestOptions: options,
          data: cachedData,
          statusCode: 200,
          statusMessage: 'OK (From Cache)',
        ),
      );
    }

    if (policy == CachePolicy.cacheOnly) {
      if (cachedData != null) {
        return handler.resolve(
          Response(
            requestOptions: options,
            data: cachedData,
            statusCode: 200,
            statusMessage: 'OK (Cache Only)',
          ),
        );
      } else {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: 'Tidak ada data di cache lokal (Mode Offline)',
          ),
        );
      }
    }

    // Untuk staleWhileRevalidate atau networkFirst, teruskan ke network
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode == 200) {
      final cacheKey = response.requestOptions.uri.toString();
      storage.write(cacheKey, response.data);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Network-First / Stale-While-Revalidate fallback ke cache saat error
    if (err.requestOptions.method.toUpperCase() == 'GET') {
      final cacheKey = err.requestOptions.uri.toString();
      final cachedData = storage.read<dynamic>(cacheKey);
      if (cachedData != null) {
        return handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            data: cachedData,
            statusCode: 200,
            statusMessage: 'OK (Cache Fallback on Error)',
          ),
        );
      }
    }
    handler.next(err);
  }
}

