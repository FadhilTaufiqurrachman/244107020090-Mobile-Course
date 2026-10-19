import 'core/format.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String announcement = '/pengumuman/:id';

  // Helper untuk membuat path detail pengumuman (contoh: /pengumuman/99)
  static String announcementById(String id) => '/pengumuman/$id';
}

/// Fungsi murni (pure function) untuk mengekstrak route dari payload data FCM.
/// Diteruskan dari fungsi murni di lib/core/format.dart.
String routeFromMessage(Map<String, dynamic> data) =>
    parseRouteFromMessage(data);