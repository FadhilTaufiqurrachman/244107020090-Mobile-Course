import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../routes.dart';

final _local = FlutterLocalNotificationsPlugin();
String? pendingDeepLink;
void Function(String route)? _onNotificationTap;

// [LARANGAN BUILDCONTEXT]: Berjalan di Dart Isolate terpisah.
// Jangan pernah mengakses BuildContext atau Riverpod di fungsi top-level ini.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Pesan background diterima: ${message.messageId}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

void listenForeground(void Function(String route) go) {
  _onNotificationTap = go;

  // Foreground: sistem TIDAK menampilkan banner otomatis,
  // jadi tampilkan manual via local notification.
  FirebaseMessaging.onMessage.listen((message) async {
    final route = routeFromMessage(message.data);
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
    go(routeFromMessage(message.data));
  });
}

Future<void> handleTerminated(void Function(String route) go) async {
  // Terminated -> dibuka dari notifikasi.
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) go(routeFromMessage(initial.data));

  if (pendingDeepLink != null) {
    go(pendingDeepLink!);
    pendingDeepLink = null;
  }
}

// 1. Meminta izin notifikasi (Berbeda antara Android 13+ POST_NOTIFICATIONS vs iOS alert/badge/sound/provisional)
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
      // [LARANGAN BUILDCONTEXT]: Teruskan payload ke router tanpa BuildContext
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
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await onToken(token);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  await subscribeCampusTopic();
}

Future<void> subscribeCampusTopic() async {
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}

Future<void> unsubscribeCampusTopic() async {
  await FirebaseMessaging.instance.unsubscribeFromTopic('pengumuman-kampus');
}

Future<void> registerDeviceToken(String token) async {
  try {
    // Simulasi delegasi registrasi token perangkat ke endpoint /devices
    debugPrint('Mock register device FCM ke backend sukses untuk token: $token');
  } catch (e) {
    debugPrint('Gagal mengirim token ke server: $e');
  }
}