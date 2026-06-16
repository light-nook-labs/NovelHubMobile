import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/utils/mappings.dart';
import '../../app/theme.dart';

part 'rankings_screen.g.dart';

enum RankingType {
  click('点击', Icons.touch_app, 'click_num'),
  word('字数', Icons.text_fields, 'word_num'),
  like('收藏', Icons.favorite, 'like_num'),
  praise('点赞', Icons.thumb_up, 'praise_num'),
  review('长评', Icons.rate_review, 'review_num'),
  comment('短评', Icons.comment, 'comment_num');

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
        title: GestureDetector(
          onTap: () => context.push('/search'),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '搜索小说...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: RankingType.values
              .map((type) => Tab(text: type.label))
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
    final authorsAsync = ref.watch(authorsProvider);

    return novelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (novels) {
        if (novels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type.icon, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text('暂无数据'),
              ],
            ),
          );
        }
        return authorsAsync.when(
          loading: () => _buildTable(context, novels, {}),
          error: (_, __) => _buildTable(context, novels, {}),
          data: (authors) {
            final authorMap = {for (var a in authors) a.id: a.name};
            return _buildTable(context, novels, authorMap);
          },
        );
      },
    );
  }

  Widget _buildTable(BuildContext context, List<Novel> novels, Map<int, String> authorMap) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: novels.length,
      itemBuilder: (context, index) {
        final novel = novels[index];
        final rank = index + 1;
        final value = _getValue(novel);
        final authorName = novel.authorId != null ? authorMap[novel.authorId] ?? '未知' : '未知';

        return InkWell(
          onTap: () => context.push('/novel/${novel.id}'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rank
                _buildRank(rank),
                const SizedBox(width: 10),
                // Cover
                _buildCover(novel),
                const SizedBox(width: 10),
                // Novel info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + ID
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
                      const SizedBox(height: 2),
                      // Author
                      Text(
                        authorName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Badges
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
                // Value
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatNumber(value),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      type.label.replaceAll('榜', ''),
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
      },
    );
  }

  Widget _buildCover(Novel novel) {
    final url = novel.cover != null && novel.cover!.isNotEmpty
        ? (novel.cover!.startsWith('http')
            ? novel.cover!
            : 'https://rs.sfacg.com/web/novel/images/NovelCover/Big/${novel.cover}')
        : null;

    return Container(
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
                child: Icon(Icons.book, size: 24, color: AppColors.primary),
              ),
            )
          : const Center(
              child: Icon(Icons.book, size: 24, color: AppColors.primary),
            ),
    );
  }

  Widget _buildRank(int rank) {
    final isTop3 = rank <= 3;
    final color = switch (rank) {
      1 => const Color(0xFFFFD700), // Gold
      2 => const Color(0xFFC0C0C0), // Silver
      3 => const Color(0xFFCD7F32), // Bronze
      _ => Colors.grey,
    };

    if (isTop3) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Center(
          child: Text(
            '$rank',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return SizedBox(
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
      2 => AppColors.completed, // 已完结
      3 => AppColors.ongoing, // 连载中
      4 => AppColors.stopped, // 断更
      5 => AppColors.stopped, // 断更A
      6 => AppColors.completed, // 完结A
      _ => Colors.grey,
    };
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
