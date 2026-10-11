import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

final _local = FlutterLocalNotificationsPlugin();
String? pendingDeepLink; // Akan digunakan untuk navigasi saat notifikasi diklik

// Letakkan di bagian atas, di bawah import dan deklarasi _local / pendingDeepLink

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Jangan akses BuildContext / Riverpod di sini[cite: 17].
  // Tugasnya: catat / simpan ringan saja. Navigasi dilakukan saat klik[cite: 17].
  debugPrint('Pesan background diterima: ${message.messageId}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// Tambahkan fungsi ini di bagian bawah file

void listenForeground(void Function(String route) go) {
  // Foreground: sistem TIDAK menampilkan banner otomatis,
  // jadi tampilkan manual via local notification.
  FirebaseMessaging.onMessage.listen((message) async {
    final route = message.data['route'] ?? '/';
    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: route,
    );
  });

  // Background -> diklik.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(message.data['route'] ?? '/');
  });
}

Future<void> handleTerminated(void Function(String route) go) async {
  // Terminated -> dibuka dari notifikasi.
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) go(initial.data['route'] ?? '/');

  if (pendingDeepLink != null) {
    go(pendingDeepLink!);
    pendingDeepLink = null; // Reset setelah diproses
  }
}

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
