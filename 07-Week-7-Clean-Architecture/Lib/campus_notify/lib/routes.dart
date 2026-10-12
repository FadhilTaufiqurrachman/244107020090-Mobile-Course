class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String announcement = '/pengumuman/:id';

  // Helper untuk membuat path detail pengumuman (contoh: /pengumuman/99)
  static String announcementById(String id) => '/pengumuman/$id';
}

/// Fungsi murni (pure function) untuk mengekstrak route dari payload data FCM.
/// Bisa langsung di-unit-test tanpa menginisialisasi Firebase.
String routeFromMessage(Map<String, dynamic> data) {
  final rawRoute = data['route']?.toString().trim() ?? '';
  if (rawRoute.isEmpty) return AppRoutes.home;
  return rawRoute.startsWith('/') ? rawRoute : '/$rawRoute';
}