import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/database.dart';
import '../../data/repositories/providers.dart';
import '../../app/theme.dart';
import '../../shared/widgets/common_widgets.dart';

part 'banner_screen.g.dart';

const _bannerUrlPattern =
    'https://rs.sfacg.com/web/novel/images/images/beitouNew/{nid}.jpg';

String _getBannerUrl(int nid) {
  return _bannerUrlPattern.replaceAll('{nid}', nid.toString());
}

void _showLightbox(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, size: 64, color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  );
}

class BannerScreen extends ConsumerStatefulWidget {
  const BannerScreen({super.key});

  @override
  ConsumerState<BannerScreen> createState() => _BannerScreenState();
}

class _BannerScreenState extends ConsumerState<BannerScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;
  List<BannerNovel> _novels = [];
  bool _isLoadingMore = false;
  bool _showBackToTop = false;
  bool _isReversed = false;
  String _searchKeyword = '';

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
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 500;
    if (shouldShow != _showBackToTop) {
      setState(() => _showBackToTop = shouldShow);
    }

    if (_searchKeyword.isEmpty &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  void _filterNovels(String keyword) {
    setState(() {
      _searchKeyword = keyword;
    });
  }

  void _toggleReverse() {
    setState(() {
      _isReversed = !_isReversed;
      _currentPage = 0;
      _novels = [];
      _hasMore = true;
    });
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    final db = ref.read(databaseProvider);
    final newNovels = await db.getBannerNovelsPaginated(
      offset: _currentPage * _pageSize,
      limit: _pageSize,
      reverse: _isReversed,
    );

    if (!mounted) return;
    setState(() {
      _currentPage++;
      _novels.addAll(newNovels);
      _hasMore = newNovels.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  List<BannerNovel> get _displayNovels {
    if (_searchKeyword.isEmpty) {
      return _novels;
    }
    final lowerKeyword = _searchKeyword.toLowerCase();
    return _novels.where((novel) {
      return novel.title.toLowerCase().contains(lowerKeyword);
    }).toList();
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.swap_vert,
              color: _isReversed ? AppColors.primary : null,
            ),
            onPressed: _toggleReverse,
            tooltip: _isReversed ? '正序' : '逆序',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterNovels,
              decoration: InputDecoration(
                hintText: '搜索背投标题...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _filterNovels('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: _novels.isEmpty && _isLoadingMore
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
                    : _displayNovels.isEmpty
                        ? const EmptyState(icon: Icons.search_off, message: '未找到匹配的背投')
                        : Stack(
                            children: [
                              RefreshIndicator(
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: _displayNovels.length + (_hasMore && _searchKeyword.isEmpty ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _displayNovels.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    return _BannerCard(novel: _displayNovels[index]);
                                  },
                                ),
                              ),
                              if (_showBackToTop)
                                Positioned(
                                  right: 16,
                                  bottom: 16,
                                  child: FloatingActionButton.small(
                                    onPressed: () {
                                      _scrollController.animateTo(
                                        0,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    },
                                    child: const Icon(Icons.arrow_upward),
                                  ),
                                ),
                            ],
                          ),
          ),
        ],
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
  final BannerNovel novel;

  const _BannerCard({required this.novel});

  @override
  Widget build(BuildContext context) {
    final bannerUrl = _getBannerUrl(novel.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showLightbox(context, bannerUrl),
            child: AspectRatio(
              aspectRatio: 3 / 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: bannerUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
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
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/novel/${novel.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  novel.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  novel.author,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
