import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/network_cache.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcement_detail.dart';

// --- CACHE STORAGE PROVIDER ---
final cacheStorageProvider = Provider<InMemoryCacheStorage>((ref) {
  return InMemoryCacheStorage();
});

// --- DATA LAYER PROVIDER ---
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  final cache = ref.watch(cacheStorageProvider);
  return AnnouncementRepositoryImpl(cacheStorage: cache);
});

// --- DOMAIN LAYER PROVIDER ---
final getAnnouncementDetailProvider = Provider<GetAnnouncementDetail>((ref) {
  return GetAnnouncementDetail(ref.watch(announcementRepositoryProvider));
});

// --- PRESENTATION LAYER FUTURE PROVIDER ---
final announcementDetailProvider = FutureProvider.family<Announcement, String>((
  ref,
  id,
) async {
  final getDetail = ref.watch(getAnnouncementDetailProvider);
  final result = await getDetail.call(id);

  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }

  return result.announcement!;
});
