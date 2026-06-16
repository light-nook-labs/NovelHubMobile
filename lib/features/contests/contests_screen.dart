import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/utils/spacing.dart';

part 'contests_screen.g.dart';

class ContestsScreen extends ConsumerStatefulWidget {
  const ContestsScreen({super.key});

  @override
  ConsumerState<ContestsScreen> createState() => _ContestsScreenState();
}

class _ContestsScreenState extends ConsumerState<ContestsScreen> {
  final _scrollController = ScrollController();
  final _pageSize = 48;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<Contest> _contests = [];
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
    final newContests = await db.getAllContests(
      limit: _pageSize,
      offset: _currentPage * _pageSize,
    );

    setState(() {
      _currentPage++;
      _contests.addAll(newContests);
      _hasMore = newContests.length == _pageSize;
      _isLoadingMore = false;
    });
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
      body: _contests.isEmpty && _isLoadingMore
          ? const LoadingState(message: '加载比赛列表...')
          : _contests.isEmpty
              ? const EmptyState(
                  icon: Icons.emoji_events,
                  message: '暂无比赛数据',
                )
              : Stack(
                  children: [
                    GridView.builder(
                      controller: _scrollController,
                      padding: AppSpacing.paddingM,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3,
                        crossAxisSpacing: AppSpacing.gridSpacing,
                        mainAxisSpacing: AppSpacing.gridSpacing,
                      ),
                      itemCount: _contests.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _contests.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final contest = _contests[index];
                        return Card(
                          child: InkWell(
                            onTap: () => context.push('/contest/${contest.id}'),
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
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

class ContestDetailScreen extends ConsumerWidget {
  final int contestId;

  const ContestDetailScreen({super.key, required this.contestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestAsync = ref.watch(contestProvider(contestId));
    final novelsAsync = ref.watch(contestNovelsProvider(contestId));

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
      ),
      body: novelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (novels) {
          if (novels.isEmpty) {
            return const Center(child: Text('该比赛暂无作品'));
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
                    '点击: ${_formatNumber(novel.clickNum ?? 0)} | 字数: ${_formatNumber(novel.wordNum ?? 0)}',
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
