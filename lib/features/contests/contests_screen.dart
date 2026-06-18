import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/novel_rank_list.dart';
import '../../shared/utils/spacing.dart';
import '../../app/theme.dart';
import '../../app/settings_provider.dart';

part 'contests_screen.g.dart';

class ContestsScreen extends ConsumerStatefulWidget {
  const ContestsScreen({super.key});

  @override
  ConsumerState<ContestsScreen> createState() => _ContestsScreenState();
}

class _ContestsScreenState extends ConsumerState<ContestsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  List<ContestWithCount> _contests = [];
  List<ContestWithCount> _filteredContests = [];
  bool _isLoading = true;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadContests();
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

  void _filterContests(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContests = _contests;
      } else {
        _filteredContests = _contests
            .where((contest) => contest.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _loadContests() async {
    final db = ref.read(databaseProvider);
    final contests = await db.getContestsWithCount(limit: 10000);
    if (mounted) {
      setState(() {
        _contests = contests;
        _filteredContests = contests;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('比赛'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const LoadingState(message: '加载比赛列表...')
          : _contests.isEmpty
          ? const EmptyState(icon: Icons.emoji_events, message: '暂无比赛数据')
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterContests,
                    decoration: InputDecoration(
                      hintText: '搜索比赛...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _filterContests('');
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
                  child: _filteredContests.isEmpty
                      ? const EmptyState(icon: Icons.search_off, message: '未找到匹配的比赛')
                      : Stack(
                          children: [
                            GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _filteredContests.length,
                              itemBuilder: (context, index) {
                                final contest = _filteredContests[index];
                                return Card(
                                  child: InkWell(
                                    onTap: () => context.push('/contest/${contest.id}'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              contest.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${contest.novelCount} 本',
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
                ),
              ],
            ),
    );
  }
}

class ContestDetailScreen extends ConsumerStatefulWidget {
  final int contestId;

  const ContestDetailScreen({super.key, required this.contestId});

  @override
  ConsumerState<ContestDetailScreen> createState() => _ContestDetailScreenState();
}

class _ContestDetailScreenState extends ConsumerState<ContestDetailScreen> {
  int? _selectedGenre;
  int? _selectedStatus;
  int? _selectedYear;
  int? _selectedMinWordNum;
  int? _selectedMaxWordNum;
  String _sortBy = 'click_num';
  bool _descending = true;

  @override
  Widget build(BuildContext context) {
    final contestAsync = ref.watch(contestProvider(widget.contestId));
    final db = ref.read(databaseProvider);

    final hasFilters =
        _selectedGenre != null ||
        _selectedStatus != null ||
        _selectedYear != null ||
        _selectedMinWordNum != null ||
        _selectedMaxWordNum != null;

    return Scaffold(
      appBar: AppBar(
        title: contestAsync.when(
          loading: () => const Text('比赛详情'),
          error: (_, __) => const Text('比赛详情'),
          data: (contest) => Text(contest?.name ?? '未知'),
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
        key: ValueKey('contest_${widget.contestId}_${_selectedGenre}_${_selectedStatus}_$_selectedYear'),
        loadNovels: (offset, limit) => db.getNovelsByContest(
          widget.contestId,
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
Future<List<Contest>> contests(ContestsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllContests();
}

@riverpod
Future<Contest?> contest(ContestRef ref, int id) async {
  final db = ref.watch(databaseProvider);
  return db.getContest(id);
}

@riverpod
Future<List<Novel>> contestNovels(ContestNovelsRef ref, int contestId) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelsByContest(contestId);
}
