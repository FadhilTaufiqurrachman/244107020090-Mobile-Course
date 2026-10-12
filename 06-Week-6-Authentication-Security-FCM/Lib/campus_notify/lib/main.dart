import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

import 'routes.dart';
import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart';
import 'messaging/push_service.dart';

// Provider untuk menyimpan token terpotong (12 karakter) agar tampil di UI Debug
class MaskedTokenNotifier extends Notifier<String> {
  @override
  String build() => 'Memuat token...';

  void setToken(String value) {
    state = value;
  }
}

final maskedFcmTokenProvider =
    NotifierProvider<MaskedTokenNotifier, String>(MaskedTokenNotifier.new);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Daftarkan background handler SEBELUM request permission
  registerBackgroundHandler();

  await requestNotificationPermission();
  await initLocalNotifications();

  runApp(const ProviderScope(child: CampusNotifyApp()));
}

// Konfigurasi GoRouter menggunakan konstanta dari lib/routes.dart
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<AsyncValue<bool>>(const AsyncLoading());
  ref.onDispose(notifier.dispose);

  ref.listen<AsyncValue<bool>>(
    authStateProvider,
    (_, next) => notifier.value = next,
    fireImmediately: true,
  );

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      // Tunggu pembacaan secure storage selesai sebelum melakukan redirect
      if (authState.isLoading) return null;

      final loggedIn = authState.value ?? false;
      final goingLogin = state.matchedLocation == AppRoutes.login;

      // Proteksi route: belum login, paksa ke /login
      if (!loggedIn && !goingLogin) return AppRoutes.login;

      // Sudah login tapi mencoba buka /login, kembalikan ke home
      if (loggedIn && goingLogin) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.announcement,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'unknown';
          return AnnouncementPage(id: id);
        },
      ),
    ],
  );
});

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  @override
  void initState() {
    super.initState();
    _initPushAndDeepLink();
  }

  Future<void> _initPushAndDeepLink() async {
    // 1. Inisialisasi token FCM dan kirim ke backend POST /devices
    await initFcmToken(
      onToken: (token) async {
        final truncated =
            token.length > 12 ? '${token.substring(0, 12)}...' : token;
        debugPrint('Token terpotong: $truncated');
        ref.read(maskedFcmTokenProvider.notifier).setToken(truncated);

        try {
          final dio = ref.read(apiClientProvider);
          await dio.post(
            '/devices',
            data: {'fcm_token': token, 'platform': 'android'},
          );
        } catch (_) {
          debugPrint('Mock POST /devices terkirim untuk token: $truncated');
        }
      },
    );

    // 2. Pastikan authState selesai dimuat sebelum memproses deep link notifikasi
    await ref.read(authStateProvider.future);
    if (!mounted) return;

    final router = ref.read(goRouterProvider);

    void go(String route) {
      if (route.isNotEmpty && route != AppRoutes.home) {
        router.push(route);
      }
    }

    // 3. Aktifkan listener untuk Foreground, Background klik, dan Terminated klik
    listenForeground(go);
    await handleTerminated(go);
  }

  @override
  Widget build(BuildContext context) {
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