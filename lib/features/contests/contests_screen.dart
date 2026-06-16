import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../app/theme.dart';

part 'contests_screen.g.dart';

class ContestsScreen extends ConsumerWidget {
  const ContestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(contestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('比赛'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: contestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (contests) {
          if (contests.isEmpty) {
            return const Center(child: Text('暂无数据'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: contests.length,
            itemBuilder: (context, index) {
              final contest = contests[index];
              return Card(
                child: InkWell(
                  onTap: () => context.push('/contest/${contest.id}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events,
                            color: AppColors.secondary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            contest.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
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
