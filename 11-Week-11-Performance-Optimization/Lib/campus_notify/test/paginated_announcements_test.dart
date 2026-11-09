import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/presentation/pages/paginated_announcements_page.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcements_providers.dart';

class FakePaginatedAnnouncementRepository implements AnnouncementRepository {
  int fetchCallCount = 0;

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    return (announcement: null, failure: null);
  }

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncementsPage(int page, {int limit = 8}) async {
    fetchCallCount++;
    if (page > 2) {
      return (announcements: <Announcement>[], failure: null);
    }
    final list = List.generate(limit, (index) {
      final id = ((page - 1) * limit + index + 1).toString();
      return Announcement(
        id: id,
        title: 'Pengumuman Hal $page - Item $id',
        content: 'Deskripsi konten pengumuman nomor $id',
        author: 'Akademik',
        createdAt: DateTime(2026, 11, 9),
      );
    });
    return (announcements: list, failure: null);
  }
}

void main() {
  group('PaginatedAnnouncementsPage & Infinite Scroll Tests', () {
    late FakePaginatedAnnouncementRepository fakeRepo;

    setUp(() {
      fakeRepo = FakePaginatedAnnouncementRepository();
    });

    testWidgets(
      'Merender batch pertama pengumuman dan memicu pagination saat scroll',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              announcementRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(home: PaginatedAnnouncementsPage()),
          ),
        );

        // Tunggu load page pertama selesai
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          find.text('Daftar Pengumuman (Infinite Scroll)'),
          findsOneWidget,
        );
        expect(find.text('Pengumuman Hal 1 - Item 1'), findsOneWidget);
        expect(fakeRepo.fetchCallCount, 1);

        // Simulasikan scroll ke bawah mendekati akhir list (trigger onScroll)
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Page kedua harus terambil otomatis melalui infinite scroll
        expect(fakeRepo.fetchCallCount, greaterThanOrEqualTo(2));
        expect(find.text('Pengumuman Hal 2 - Item 9'), findsOneWidget);
      },
    );
  });
}
