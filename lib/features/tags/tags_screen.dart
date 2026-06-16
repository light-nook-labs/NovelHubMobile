import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
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

class TagDetailScreen extends ConsumerWidget {
  final int tagId;

  const TagDetailScreen({super.key, required this.tagId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagAsync = ref.watch(tagProvider(tagId));
    final novelsAsync = ref.watch(tagNovelsProvider(tagId));

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
      body: novelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (novels) {
          if (novels.isEmpty) {
            return const Center(child: Text('该标签暂无小说'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: novels.length,
            itemBuilder: (context, index) {
              final novel = novels[index];
              return Card(
                child: ListTile(
                  title: Text(novel.title),
                  subtitle: Text(
                    '点击: ${_formatNumber(novel.clickNum ?? 0)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/novel/${novel.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 10000) return '${(num / 10000).toStringAsFixed(1)}万';
    return num.toString();
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
