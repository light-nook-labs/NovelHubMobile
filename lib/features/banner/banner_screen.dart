import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/database.dart';
import '../../data/repositories/providers.dart';
import '../../app/theme.dart';

part 'banner_screen.g.dart';

const _bannerUrlPattern =
    'https://rs.sfacg.com/web/novel/images/images/beitouNew/{nid}.jpg';

String _getBannerUrl(int nid) {
  return _bannerUrlPattern.replaceAll('{nid}', nid.toString());
}

class BannerScreen extends ConsumerStatefulWidget {
  const BannerScreen({super.key});

  @override
  ConsumerState<BannerScreen> createState() => _BannerScreenState();
}

class _BannerScreenState extends ConsumerState<BannerScreen> {
  final _scrollController = ScrollController();
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;
  List<Novel> _novels = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Trigger initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMore();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    final db = ref.read(databaseProvider);
    final newNovels = await db.getBannerNovelsPaginated(
      offset: _currentPage * _pageSize,
      limit: _pageSize,
    );

    setState(() {
      _currentPage++;
      _novels.addAll(newNovels);
      _hasMore = newNovels.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bannerCount = ref.watch(bannerCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: bannerCount.when(
          loading: () => const Text('背投'),
          error: (_, __) => const Text('背投'),
          data: (count) => Text('背投 ($count)'),
        ),
      ),
      body: _novels.isEmpty && _isLoadingMore
          ? const Center(child: CircularProgressIndicator())
          : _novels.isEmpty
               ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book, size: 64, color: AppColors.primary),
                      SizedBox(height: 16),
                      Text('暂无背投数据'),
                    ],
                  ),
                )
               : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _currentPage = 0;
                      _novels = [];
                      _hasMore = true;
                    });
                    await _loadMore();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _novels.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _novels.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final novel = _novels[index];
                      return _BannerCard(
                        novel: novel,
                        onTap: () => context.push('/novel/${novel.id}'),
                      );
                    },
                  ),
                ),
    );
  }
}

@riverpod
Future<int> bannerCount(BannerCountRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getBannerNovelCount();
}

class _BannerCard extends StatelessWidget {
  final Novel novel;
  final VoidCallback onTap;

  const _BannerCard({required this.novel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 3 / 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: _getBannerUrl(novel.id),
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.book, size: 48, color: Colors.white),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      novel.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      novel.authorId?.toString() ?? '未知',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
