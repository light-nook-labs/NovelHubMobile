import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/utils/mappings.dart';
import '../../app/theme.dart';

part 'authors_screen.g.dart';

class AuthorsScreen extends ConsumerStatefulWidget {
  const AuthorsScreen({super.key});

  @override
  ConsumerState<AuthorsScreen> createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends ConsumerState<AuthorsScreen> {
  final _scrollController = ScrollController();
  final _pageSize = 48;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<AuthorWithStats> _authors = [];
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show back to top button when scrolled down
    setState(() {
      _showBackToTop = _scrollController.offset > 500;
    });

    // Load more when near bottom
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
    final newAuthors = await db.getAuthorsWithStats(
      limit: _pageSize,
      offset: _currentPage * _pageSize,
    );

    setState(() {
      _currentPage++;
      _authors.addAll(newAuthors);
      _hasMore = newAuthors.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作者'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _authors.isEmpty && _isLoadingMore
          ? const Center(child: CircularProgressIndicator())
          : _authors.isEmpty
              ? const Center(child: Text('暂无数据'))
              : Stack(
                  children: [
                    ListView.separated(
                      controller: _scrollController,
                      itemCount: _authors.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (index == _authors.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final author = _authors[index];
                        return InkWell(
                          onTap: () => context.push('/author/${author.id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        author.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (author.topNovelTitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          author.topNovelTitle!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${author.bannerCount}/${author.novelCount}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      '背投/作品',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Back to top button
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
    );
  }
}

class AuthorDetailScreen extends ConsumerStatefulWidget {
  final int authorId;

  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  ConsumerState<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends ConsumerState<AuthorDetailScreen> {
  final _scrollController = ScrollController();
  final _pageSize = 48;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<Novel> _novels = [];
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _showBackToTop = _scrollController.offset > 500;
    });

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
    final newNovels = await db.getNovelsByAuthor(
      widget.authorId,
      limit: _pageSize,
      offset: _currentPage * _pageSize,
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
    final authorAsync = ref.watch(authorProvider(widget.authorId));

    return Scaffold(
      appBar: AppBar(
        title: authorAsync.when(
          loading: () => const Text('作者详情'),
          error: (_, __) => const Text('作者详情'),
          data: (author) => Text(author?.name ?? '未知'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _novels.isEmpty && _isLoadingMore
          ? const Center(child: CircularProgressIndicator())
          : _novels.isEmpty
              ? const Center(child: Text('该作者暂无作品'))
              : Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _novels.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _novels.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final novel = _novels[index];
                        return _buildNovelRow(context, novel, index + 1);
                      },
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
    );
  }

  Widget _buildNovelRow(BuildContext context, Novel novel, int rank) {
    final url = novel.cover != null && novel.cover!.isNotEmpty
        ? (novel.cover!.startsWith('http')
            ? novel.cover!
            : 'https://rs.sfacg.com/web/novel/images/NovelCover/Big/${novel.cover}')
        : null;

    return InkWell(
      onTap: () => context.push('/novel/${novel.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rank
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            // Cover
            Container(
              width: 50,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              clipBehavior: Clip.antiAlias,
              child: url != null
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Center(
                        child:
                            Icon(Icons.book, size: 24, color: AppColors.primary),
                      ),
                    )
                  : const Center(
                      child:
                          Icon(Icons.book, size: 24, color: AppColors.primary),
                    ),
            ),
            const SizedBox(width: 10),
            // Novel info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + ID
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: novel.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: ' #${novel.id}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Badges
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _buildBadge(
                        statusMapping.getZh(novel.status),
                        _getStatusColor(novel.status),
                      ),
                      _buildBadge(
                        genreMapping.getZh(novel.genre),
                        AppColors.primary,
                      ),
                      _buildBadge(
                        ptypeMapping.getZh(novel.ptype),
                        AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Click count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatNumber(novel.clickNum ?? 0),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '点击',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(int status) {
    return switch (status) {
      2 => AppColors.completed,
      3 => AppColors.ongoing,
      4 => AppColors.stopped,
      5 => AppColors.stopped,
      6 => AppColors.completed,
      _ => Colors.grey,
    };
  }

  String _formatNumber(int num) {
    if (num >= 100000000) return '${(num / 100000000).toStringAsFixed(1)}亿';
    if (num >= 10000) return '${(num / 10000).toStringAsFixed(1)}万';
    return num.toString();
  }
}

@riverpod
Future<List<Author>> authors(AuthorsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllAuthors();
}

@riverpod
Future<Author?> author(AuthorRef ref, int id) async {
  final db = ref.watch(databaseProvider);
  return db.getAuthor(id);
}

@riverpod
Future<List<Novel>> authorNovels(AuthorNovelsRef ref, int authorId) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelsByAuthor(authorId);
}
