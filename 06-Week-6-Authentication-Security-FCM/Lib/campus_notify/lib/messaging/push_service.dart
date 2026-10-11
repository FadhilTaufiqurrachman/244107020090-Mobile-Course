import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

final _local = FlutterLocalNotificationsPlugin();
String? pendingDeepLink;
void Function(String route)? _onNotificationTap;

// ============================================================================
// [LARANGAN BUILDCONTEXT #1 - ISOLATE TERPISAH]
// Background handler WAJIB berupa fungsi top-level (bukan method kelas) dan
// memiliki anotasi @pragma('vm:entry-point').
// JANGAN PERNAH mengakses BuildContext, Widget, atau Riverpod di sini karena
// fungsi ini dieksekusi di Dart Isolate terpisah saat aplikasi tidak aktif.
// ============================================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Pesan background diterima: ${message.messageId}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// ============================================================================
// [PERBEDAAN ANDROID 13+ vs iOS #1 - RUNTIME PERMISSION]
// - Android 13+ (API 33+): Memunculkan dialog izin POST_NOTIFICATIONS di layar.
//   (Pada Android 12 ke bawah, izin otomatis diberikan saat instalasi).
// - iOS: Memunculkan dialog izin sistem untuk alert, badge, dan sound, serta
//   mendukung opsi provisional (notifikasi senyap ke Notification Center).
// ============================================================================
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

// ============================================================================
// [PERBEDAAN ANDROID 13+ vs iOS #2 - INISIALISASI LOCAL NOTIFICATION]
// - Android: Wajib mendefinisikan icon drawable/mipmap ('@mipmap/ic_launcher').
// - iOS (Darwin): Menggunakan DarwinInitializationSettings() untuk konfigurasi
//   presentasi banner di sistem iOS.
// ============================================================================
Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();

  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      // [LARANGAN BUILDCONTEXT #2]: Callback ini berada di luar widget tree.
      // Gunakan variabel pendingDeepLink / callback router, jangan BuildContext.
      final route = response.payload;
      if (route != null && route.isNotEmpty) {
        if (_onNotificationTap != null) {
          _onNotificationTap!(route);
        } else {
          pendingDeepLink = route;
        }
      }
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

  // 3. Langganan topik kampus
  await subscribeCampusTopic();
}

// Fungsi eksplisit untuk berlangganan dan berhenti berlangganan topik
Future<void> subscribeCampusTopic() async {
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}

Future<void> unsubscribeCampusTopic() async {
  await FirebaseMessaging.instance.unsubscribeFromTopic('pengumuman-kampus');
}

void listenForeground(void Function(String route) go) {
  // Hubungkan callback agar klik banner foreground langsung memicu navigasi
  _onNotificationTap = go;

  // ==========================================================================
  // [PERBEDAAN ANDROID vs iOS #3 - NOTIFICATION CHANNEL FOREGROUND]
  // Android 8.0+ (termasuk Android 13+) WAJIB menggunakan Notification Channel
  // ('pengumuman') dengan Importance.high & Priority.high agar muncul sebagai
  // heads-up banner saat aplikasi terbuka (foreground).
  // ==========================================================================
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

  // Background -> diklik
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(message.data['route'] ?? '/');
  });
}

Future<void> handleTerminated(void Function(String route) go) async {
  // Terminated -> dibuka dari notifikasi
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    go(initial.data['route'] ?? '/');
  }

  if (pendingDeepLink != null) {
    go(pendingDeepLink!);
    pendingDeepLink = null; // Reset setelah diproses
  }
}