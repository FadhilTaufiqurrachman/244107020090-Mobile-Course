import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // 1. Tambahkan import GoRouter

// 2. Pastikan import untuk todo_page dan stats_page tidak di-comment
import 'pages/todo_page.dart'; 
// import 'pages/product_page.dart'; // (Biarkan dicomment jika tidak dipakai)
import 'pages/stats_page.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

// 3. Buat Widget MainLayout untuk menampilkan Bottom NavigationBar
class MainLayout extends StatelessWidget {
  final Widget child; // Widget child ini otomatis diisi TodoPage atau StatsPage
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child, // Menampilkan halaman aktif di sini
      bottomNavigationBar: NavigationBar(
        // Mengecek URL saat ini untuk mewarnai icon tab yang sedang aktif
        selectedIndex: GoRouterState.of(context).uri.toString() == '/stats' ? 1 : 0,
        onDestinationSelected: (index) {
          // Berpindah URL ketika icon tab ditekan
          if (index == 0) context.go('/');
          if (index == 1) context.go('/stats');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'ToDo'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Stats'),
        ],
      ),
    );
  }
}

// 4. Konfigurasi GoRouter dengan fitur ShellRoute
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      // ShellRoute akan membungkus rute di bawahnya ke dalam MainLayout
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const TodoPage(),
        ),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsPage(),
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 5. Ubah MaterialApp menjadi MaterialApp.router
    return MaterialApp.router(
      title: 'Week 3 - Refactoring',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      routerConfig: _router, // Menyambungkan konfigurasi router di atas
    );
  }
}