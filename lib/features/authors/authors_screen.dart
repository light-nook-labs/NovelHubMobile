import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/novel_rank_list.dart';
import '../../app/theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/utils/spacing.dart';

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
    if (mounted) {
      setState(() {
        _showBackToTop = _scrollController.offset > 500;
      });
    }

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
    if (mounted) setState(() => _isLoadingMore = true);

    final db = ref.read(databaseProvider);
    final newAuthors = await db.getAuthorsWithStats(
      limit: _pageSize,
      offset: _currentPage * _pageSize,
    );

    if (mounted) {
      setState(() {
        _currentPage++;
        _authors.addAll(newAuthors);
        _hasMore = newAuthors.length == _pageSize;
        _isLoadingMore = false;
      });
    }
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
          ? const LoadingState(message: '加载作者列表...')
          : _authors.isEmpty
          ? const EmptyState(icon: Icons.person, message: '暂无作者数据')
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
                        padding: AppSpacing.listItemPadding,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    author.name,
                                    style: AppTextStyles.labelLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (author.topNovelTitle != null) ...[
                                    AppSpacing.gapHeightXS,
                                    Text(
                                      author.topNovelTitle!,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.grey[500],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            AppSpacing.gapWidthM,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatNumber(author.topNovelClicks),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '点击',
                                  style: AppTextStyles.labelSmall.copyWith(
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
                BackToTopButton(
                  scrollController: _scrollController,
                  show: _showBackToTop,
                ),
              ],
            ),
    );
  }
}

class AuthorDetailScreen extends ConsumerWidget {
  final int authorId;

  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorAsync = ref.watch(authorProvider(authorId));
    final db = ref.read(databaseProvider);

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
      body: NovelRankList(
        loadNovels: (offset, limit) =>
            db.getNovelsByAuthor(authorId, limit: limit, offset: offset),
        showRank: true,
        valueLabel: '点击',
      ),
    );
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
