import 'package:dio/dio.dart';

String mapDioExceptionToUserMessage(Object error) {
  if (error is DioException) {
    // 1. Cek status code 401 (Unauthorized / Sesi berakhir)
    if (error.response?.statusCode == 401) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }

    // 2. Cek jenis gangguan koneksi (timeout & offline)
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server kampus habis waktu (timeout). Silakan coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet (offline). Periksa jaringan Anda.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode ?? 0;
        return 'Server mengalami kendala (Kode: $code). Coba beberapa saat lagi.';
      case DioExceptionType.cancel:
        return 'Permintaan ke server dibatalkan.';
      default:
        return 'Terjadi gangguan jaringan. Silakan coba lagi.';
    }
  }

  // Pemetaan umum jika bukan DioException (misal validasi login)
  final raw = error.toString().replaceFirst('Exception: ', '');
  return raw.isEmpty ? 'Terjadi kesalahan yang tidak diketahui.' : raw;
}