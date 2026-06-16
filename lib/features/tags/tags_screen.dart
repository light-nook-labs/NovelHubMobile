import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/novel_rank_list.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/utils/spacing.dart';

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
  List<TagWithCount> _tags = [];
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
    final newTags = await db.getTagsWithCount(
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
          ? const LoadingState(message: '加载标签列表...')
          : _tags.isEmpty
              ? const EmptyState(
                  icon: Icons.tag,
                  message: '暂无标签数据',
                )
              : Stack(
                  children: [
                    GridView.builder(
                      controller: _scrollController,
                      padding: AppSpacing.paddingM,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: AppSpacing.gridSpacingSmall,
                        mainAxisSpacing: AppSpacing.gridSpacingSmall,
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      tag.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tag.novelCount} 本',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
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
                ),
    );
  }
}

class TagDetailScreen extends ConsumerWidget {
  final int tagId;

  const TagDetailScreen({super.key, required this.tagId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagAsync = ref.watch(tagProvider(tagId));
    final db = ref.read(databaseProvider);

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
      ),
      body: NovelRankList(
        loadNovels: (offset, limit) => db.getNovelsByTag(
          tagId,
          limit: limit,
          offset: offset,
          sortBy: 'click_num',
          descending: true,
        ),
        showRank: true,
        valueLabel: '点击',
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
