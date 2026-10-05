import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _local = FlutterLocalNotificationsPlugin();
String? pendingDeepLink; // Akan digunakan untuk navigasi saat notifikasi diklik

// 1. Meminta izin notifikasi (Wajib untuk Android 13+ dan iOS)
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );

  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

// 2. Inisialisasi notifikasi lokal untuk menangani klik saat aplikasi di foreground
Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();

  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      // Klik banner foreground -> teruskan payload ke router
      pendingDeepLink = response.payload;

      // Catatan: Logika untuk langsung pindah halaman menggunakan GoRouter
      // biasanya ditangani oleh listener di provider/router nantinya.
    },
  );
}

// 3. Token lifecycle: ambil, kirim ke backend, pantau perubahan
Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  // 1. Ambil token saat ini dan kirim ke backend
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await onToken(token);
  }

  // 2. Token bisa berubah (reinstall, clear data, rotasi keamanan).
  // Listener ini WAJIB ada, jika tidak backend menyimpan token basi.
  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  // 3. Langganan topik kampus (mis. semua mahasiswa angkatan)
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}
