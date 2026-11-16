import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes.dart';
import '../../domain/entities/announcement.dart';
import '../providers/announcements_providers.dart';

class PaginatedAnnouncementsPage extends ConsumerStatefulWidget {
  const PaginatedAnnouncementsPage({super.key});

  @override
  ConsumerState<PaginatedAnnouncementsPage> createState() =>
      _PaginatedAnnouncementsPageState();
}

class _PaginatedAnnouncementsPageState
    extends ConsumerState<PaginatedAnnouncementsPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Announcement> _items = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(announcementRepositoryProvider);
      final result = await repo.fetchAnnouncementsPage(_page, limit: 8);

      if (result.announcements.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(result.announcements);
        _page++;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Pengumuman (Infinite Scroll)')),
      body: _items.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _items.clear();
                  _page = 1;
                  _hasMore = true;
                });
                await _loadPage();
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _items.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final item = _items[index];
                  return AnnouncementListTile(item: item);
                },
              ),
            ),
    );
  }
}

/// Item tile terpisah dengan const support dan optimasi decoding visual
class AnnouncementListTile extends StatelessWidget {
  final Announcement item;

  const AnnouncementListTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.campaign, color: Colors.blue),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          item.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push(AppRoutes.announcementById(item.id));
        },
      ),
    );
  }
}
