import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/utils/mappings.dart';
import '../../app/theme.dart';

part 'tags_screen.g.dart';

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  final _scrollController = ScrollController();
  final _pageSize = 48;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<Tag> _tags = [];
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
    final newTags = await db.getAllTags(
      limit: _pageSize,
      offset: _currentPage * _pageSize,
    );

    setState(() {
      _currentPage++;
      _tags.addAll(newTags);
      _hasMore = newTags.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标签'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _tags.isEmpty && _isLoadingMore
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
              ? const Center(child: Text('暂无数据'))
              : Stack(
                  children: [
                    GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _tags.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _tags.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final tag = _tags[index];
                        return Card(
                          child: InkWell(
                            onTap: () => context.push('/tag/${tag.id}'),
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: Text(
                                tag.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
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
}

class TagDetailScreen extends ConsumerStatefulWidget {
  final int tagId;

  const TagDetailScreen({super.key, required this.tagId});

  @override
  ConsumerState<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends ConsumerState<TagDetailScreen> {
  final _scrollController = ScrollController();
  final _pageSize = 48;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<Novel> _novels = [];
  bool _showBackToTop = false;
  String _sortBy = 'click_num';
  bool _descending = true;

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
    final newNovels = await db.getNovelsByTag(
      widget.tagId,
      limit: _pageSize,
      offset: _currentPage * _pageSize,
      sortBy: _sortBy,
      descending: _descending,
    );

    setState(() {
      _currentPage++;
      _novels.addAll(newNovels);
      _hasMore = newNovels.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  void _resetAndReload() {
    setState(() {
      _currentPage = 0;
      _novels = [];
      _hasMore = true;
    });
    _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final tagAsync = ref.watch(tagProvider(widget.tagId));

    return Scaffold(
      appBar: AppBar(
        title: tagAsync.when(
          loading: () => const Text('标签详情'),
          error: (_, __) => const Text('标签详情'),
          data: (tag) => Text(tag?.name ?? '未知'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: _novels.isEmpty && _isLoadingMore
          ? const Center(child: CircularProgressIndicator())
          : _novels.isEmpty
              ? const Center(child: Text('该标签暂无小说'))
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FilterBottomSheet(
        sortBy: _sortBy,
        descending: _descending,
        onApply: (sortBy, descending) {
          setState(() {
            _sortBy = sortBy;
            _descending = descending;
          });
          _resetAndReload();
        },
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

class _FilterBottomSheet extends StatefulWidget {
  final String sortBy;
  final bool descending;
  final Function(String, bool) onApply;

  const _FilterBottomSheet({
    required this.sortBy,
    required this.descending,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String _sortBy;
  late bool _descending;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.sortBy;
    _descending = widget.descending;
  }

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      {'key': 'click_num', 'label': '点击量'},
      {'key': 'word_num', 'label': '字数'},
      {'key': 'like_num', 'label': '收藏'},
      {'key': 'praise_num', 'label': '点赞'},
      {'key': 'last_update', 'label': '更新时间'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '排序',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _descending = !_descending);
                },
                icon: Icon(
                  _descending ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 16,
                ),
                label: Text(_descending ? '降序' : '升序'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortOptions.map((option) {
              final key = option['key']!;
              final label = option['label']!;
              return GestureDetector(
                onTap: () => setState(() => _sortBy = key),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _sortBy == key
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: _sortBy == key ? Colors.white : null,
                      fontWeight:
                          _sortBy == key ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_sortBy, _descending);
                Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('应用'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@riverpod
Future<List<Tag>> tags(TagsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllTags();
}

@riverpod
Future<Tag?> tag(TagRef ref, int id) async {
  final db = ref.watch(databaseProvider);
  return db.getTag(id);
}

@riverpod
Future<List<Novel>> tagNovels(TagNovelsRef ref, int tagId) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelsByTag(tagId);
}
