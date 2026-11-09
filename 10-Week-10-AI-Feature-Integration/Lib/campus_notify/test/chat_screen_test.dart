import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/ai/ai_service.dart';
import 'package:campus_notify/features/chat_screen.dart';

import 'ai_service_test.dart';

void main() {
  group('ChatScreen Widget & Privacy Tests', () {
    late FakeSecureStorage fakeStorage;
    late AiService aiService;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      aiService = AiService(storage: fakeStorage);
    });

    testWidgets('Merender antarmuka ChatScreen lengkap dengan banner privasi', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ChatScreen(aiService: aiService)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Campus AI Chat'), findsOneWidget);
      expect(
        find.textContaining('Privasi: Jangan kirim NIK, telepon'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.text('Jadwal KRS Semester Ini'), findsOneWidget);
    });

    testWidgets(
      'Memblokir pengiriman NIK 16 digit dan menampilkan SnackBar privasi',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ChatScreen(aiService: aiService)),
        );
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(TextField);
        await tester.enterText(
          textFieldFinder,
          'Halo tolong cek NIK saya 3578012345678901',
        );
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pump();

        // Memastikan SnackBar keamanan muncul dan pesan diblokir dari antrian chat
        expect(
          find.textContaining('Peringatan Keamanan: Terdeteksi NIK'),
          findsOneWidget,
        );
      },
    );
  });
}
