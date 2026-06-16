import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/providers.dart';
import '../../shared/widgets/novel_rank_list.dart';

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
    _tabController = TabController(
      length: RankingType.values.length,
      vsync: this,
    );
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
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
    final db = ref.read(databaseProvider);

    return NovelRankList(
      loadNovels: (offset, limit) => db.getNovelsSorted(
        type.field,
        descending: true,
        limit: limit,
        offset: offset,
      ),
      showRank: true,
      valueLabel: type.label,
    );
  }
}
