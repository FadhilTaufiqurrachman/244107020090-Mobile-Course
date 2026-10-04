import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; 
import 'pages/settings_page.dart';
import 'pages/notes_page.dart';    
import 'pages/note_detail_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider).value ?? false;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const NotesPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/note/:id',
          builder: (context, state) {
            final noteId = int.parse(state.pathParameters['id']!);
            return NoteDetailPage(noteId: noteId);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Offline Notes',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      routerConfig: router, 
    );
  }
}