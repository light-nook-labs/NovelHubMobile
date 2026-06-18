import 'dart:async';

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
  final _searchController = TextEditingController();
  String _searchKeyword = '';
  Timer? _debounceTimer;

  // For browsing mode
  final _pageSize = 48;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<AuthorWithStats> _authors = [];
  bool _showBackToTop = false;

  // For search mode
  bool _isSearching = false;
  List<Author> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _showBackToTop = _scrollController.offset > 500;
      });
    }

    if (!_isSearching &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  void _onSearchChanged(String keyword) {
    _debounceTimer?.cancel();
    if (keyword.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchKeyword = '';
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchKeyword = keyword;
      _isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final db = ref.read(databaseProvider);
      final results = await db.searchAuthors(keyword);
      if (mounted && _searchKeyword == keyword) {
        setState(() {
          _searchResults = results;
        });
      }
    });
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '搜索作者名或代表作...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
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
            child: _isSearching
                ? _buildSearchResults()
                : _buildBrowseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const EmptyState(icon: Icons.search_off, message: '未找到匹配的作者');
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final author = _searchResults[index];
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
                      if (author.topNovelTitle != null && author.topNovelTitle!.isNotEmpty) ...[
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
    );
  }

  Widget _buildBrowseList() {
    if (_authors.isEmpty && _isLoadingMore) {
      return const LoadingState(message: '加载作者列表...');
    }
    if (_authors.isEmpty) {
      return const EmptyState(icon: Icons.person, message: '暂无作者数据');
    }

    return Stack(
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
        BackToTopButton(
          scrollController: _scrollController,
          show: _showBackToTop,
        ),
      ],
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
