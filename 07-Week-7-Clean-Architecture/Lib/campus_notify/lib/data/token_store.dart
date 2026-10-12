import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  // Menggunakan default constructor flutter_secure_storage
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  
  // Mendefinisikan 'kunci' untuk mengakses penyimpanan
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  // Fungsi untuk menyimpan token
  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  // Fungsi untuk mengambil token
  Future<String?> readAccess() => _storage.read(key: _accessKey);
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  // Fungsi untuk menghapus token (digunakan saat logout)
  Future<void> clear() => _storage.deleteAll();
}