import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../app/theme.dart';

part 'rankings_screen.g.dart';

enum RankingType {
  click('点击榜', Icons.touch_app, 'click_num'),
  word('字数榜', Icons.text_fields, 'word_num'),
  praise('收藏榜', Icons.favorite, 'praise_num'),
  like('点赞榜', Icons.thumb_up, 'like_num'),
  review('书评榜', Icons.rate_review, 'review_num'),
  comment('评论榜', Icons.comment, 'comment_num');

  final String label;
  final IconData icon;
  final String field;

  const RankingType(this.label, this.icon, this.field);
}

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: RankingType.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: RankingType.values
              .map((type) => Tab(icon: Icon(type.icon), text: type.label))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: RankingType.values
            .map((type) => _RankingList(type: type))
            .toList(),
      ),
    );
  }
}

class _RankingList extends ConsumerWidget {
  final RankingType type;

  const _RankingList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novelsAsync = ref.watch(rankingProvider(type.field));

    return novelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (novels) {
        if (novels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type.icon, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text('暂无数据，请先同步'),
              ],
            ),
          );
        }
        return _buildList(context, novels);
      },
    );
  }

  Widget _buildList(BuildContext context, List<Novel> novels) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: novels.length,
      itemBuilder: (context, index) {
        final novel = novels[index];
        final rank = index + 1;
        final value = _getValue(novel);

        return _RankingTile(
          rank: rank,
          novel: novel,
          value: value,
          type: type,
          onTap: () => context.push('/novel/${novel.id}'),
        );
      },
    );
  }

  int _getValue(Novel novel) {
    return switch (type) {
      RankingType.click => novel.clickNum ?? 0,
      RankingType.word => novel.wordNum ?? 0,
      RankingType.praise => novel.praiseNum ?? 0,
      RankingType.like => novel.likeNum ?? 0,
      RankingType.review => novel.reviewNum ?? 0,
      RankingType.comment => novel.commentNum ?? 0,
    };
  }
}

class _RankingTile extends StatelessWidget {
  final int rank;
  final Novel novel;
  final int value;
  final RankingType type;
  final VoidCallback onTap;

  const _RankingTile({
    required this.rank,
    required this.novel,
    required this.value,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: _buildRankBadge(context),
      title: Text(
        novel.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        novel.cover != null ? '作者ID: ${novel.authorId ?? "未知"}' : '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(type.icon, size: 14, color: AppColors.primary),
          const SizedBox(height: 2),
          Text(
            _formatNumber(value),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(BuildContext context) {
    final isTop3 = rank <= 3;
    final color = switch (rank) {
      1 => const Color(0xFFFFD700), // Gold
      2 => const Color(0xFFC0C0C0), // Silver
      3 => const Color(0xFFCD7F32), // Bronze
      _ => Colors.grey,
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isTop3 ? color.withValues(alpha: 0.2) : null,
        shape: BoxShape.circle,
        border: isTop3 ? Border.all(color: color, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isTop3 ? color : Colors.grey,
          fontSize: isTop3 ? 16 : 14,
        ),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 100000000) return '${(num / 100000000).toStringAsFixed(1)}亿';
    if (num >= 10000) return '${(num / 10000).toStringAsFixed(1)}万';
    return num.toString();
  }
}

@riverpod
Future<List<Novel>> ranking(RankingRef ref, String field) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelsSorted(field, descending: true, limit: 100);
}
