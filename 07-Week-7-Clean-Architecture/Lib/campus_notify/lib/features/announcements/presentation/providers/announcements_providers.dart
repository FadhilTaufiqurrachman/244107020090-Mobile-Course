import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcement_detail.dart';

// --- DATA LAYER PROVIDER ---
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return const AnnouncementRepositoryImpl();
});

// --- DOMAIN LAYER PROVIDER ---
final getAnnouncementDetailProvider = Provider<GetAnnouncementDetail>((ref) {
  return GetAnnouncementDetail(ref.watch(announcementRepositoryProvider));
});

// --- PRESENTATION LAYER FUTURE PROVIDER ---
final announcementDetailProvider =
    FutureProvider.family<Announcement, String>((ref, id) async {
  final getDetail = ref.watch(getAnnouncementDetailProvider);
  final result = await getDetail.call(id);

  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }

  return result.announcement!;
});
