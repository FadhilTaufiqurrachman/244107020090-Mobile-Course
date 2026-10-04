import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart';

void main() {
  // ProviderScope wajib diletakkan di root aplikasi Riverpod
  runApp(const ProviderScope(child: CampusNotifyApp()));
}

// Konfigurasi GoRouter sebagai Provider agar bisa membaca authState
final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch auth state agar router update otomatis saat login/logout
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Ambil nilai status login (true/false). Jika masih loading, anggap false.
      final loggedIn = authState.value ?? false;
      
      final goingLogin = state.matchedLocation == '/login';
      
      // Proteksi route: belum login, paksa ke /login
      if (!loggedIn && !goingLogin) return '/login';
      
      // Sudah login tapi mencoba buka /login, kembalikan ke home
      if (loggedIn && goingLogin) return '/';
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login', 
        builder: (context, state) => const LoginPage()
      ),
      GoRoute(
        path: '/', 
        builder: (context, state) => const HomePage()
      ),
      GoRoute(
        path: '/pengumuman/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'unknown';
          return AnnouncementPage(id: id);
        },
      ),
    ],
  );
});

class CampusNotifyApp extends ConsumerWidget {
  const CampusNotifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}