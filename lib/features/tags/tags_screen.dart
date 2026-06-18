import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/novel_rank_list.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/utils/spacing.dart';
import '../../app/theme.dart';
import '../../app/settings_provider.dart';

part 'tags_screen.g.dart';

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  List<TagWithCount> _tags = [];
  List<TagWithCount> _filteredTags = [];
  bool _isLoading = true;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTags();
  }

  @override
  void dispose() {
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
  }

  void _filterTags(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTags = _tags;
      } else {
        _filteredTags = _tags
            .where((tag) => tag.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _loadTags() async {
    final db = ref.read(databaseProvider);
    final tags = await db.getTagsWithCount(limit: 10000);
    if (mounted) {
      setState(() {
        _tags = tags;
        _filteredTags = tags;
        _isLoading = false;
      });
    }
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
      body: _isLoading
          ? const LoadingState(message: '加载标签列表...')
          : _tags.isEmpty
          ? const EmptyState(icon: Icons.tag, message: '暂无标签数据')
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterTags,
                    decoration: InputDecoration(
                      hintText: '搜索标签...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _filterTags('');
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
                // Grid
                Expanded(
                  child: _filteredTags.isEmpty
                      ? const EmptyState(icon: Icons.search_off, message: '未找到匹配的标签')
                      : Stack(
                          children: [
                            GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 1.6,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _filteredTags.length,
                              itemBuilder: (context, index) {
                                final tag = _filteredTags[index];
                                return Card(
                                  child: InkWell(
                                    onTap: () => context.push('/tag/${tag.id}'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              tag.name,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Text(
                                            '${tag.novelCount}',
                                            style: TextStyle(
                                              fontSize: 10,
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
  int? _selectedGenre;
  int? _selectedStatus;
  int? _selectedYear;
  int? _selectedMinWordNum;
  int? _selectedMaxWordNum;
  String _sortBy = 'click_num';
  bool _descending = true;

  @override
  Widget build(BuildContext context) {
    final tagAsync = ref.watch(tagProvider(widget.tagId));
    final db = ref.read(databaseProvider);

    final hasFilters =
        _selectedGenre != null ||
        _selectedStatus != null ||
        _selectedYear != null ||
        _selectedMinWordNum != null ||
        _selectedMaxWordNum != null;

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
            icon: Icon(
              Icons.tune,
              color: hasFilters ? AppColors.primary : null,
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: NovelRankList(
        key: ValueKey('tag_${widget.tagId}_${_selectedGenre}_${_selectedStatus}_${_selectedYear}_$_sortBy'),
        loadNovels: (offset, limit) => db.getNovelsByTag(
          widget.tagId,
          limit: limit,
          offset: offset,
          sortBy: _sortBy,
          descending: _descending,
        ),
        showRank: true,
        valueLabel: _getValueLabel(),
      ),
    );
  }

  String _getValueLabel() {
    return switch (_sortBy) {
      'word_num' => '字数',
      'like_num' => '收藏',
      'praise_num' => '点赞',
      'review_num' => '长评',
      'comment_num' => '短评',
      _ => '点击',
    };
  }

  void _showFilterBottomSheet(BuildContext context) {
    // Watch to ensure years are loaded before showing filter
    final availableYearsAsync = ref.watch(availableYearsProvider);
    final availableYears = availableYearsAsync.valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NovelFilterBottomSheet(
        selectedGenre: _selectedGenre,
        selectedStatus: _selectedStatus,
        selectedYear: _selectedYear,
        selectedMinWordNum: _selectedMinWordNum,
        selectedMaxWordNum: _selectedMaxWordNum,
        sortBy: _sortBy,
        descending: _descending,
        availableYears: availableYears,
        onApply: (genre, status, year, minWordNum, maxWordNum, sortBy, descending) {
          setState(() {
            _selectedGenre = genre;
            _selectedStatus = status;
            _selectedYear = year;
            _selectedMinWordNum = minWordNum;
            _selectedMaxWordNum = maxWordNum;
            _sortBy = sortBy;
            _descending = descending;
          });
        },
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
