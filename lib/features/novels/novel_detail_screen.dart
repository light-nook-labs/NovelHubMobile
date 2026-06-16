import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/utils/mappings.dart';
import '../../app/theme.dart';

const _sfacgUrlPattern = 'https://book.sfacg.com/Novel/{nid}/';

class NovelDetailScreen extends ConsumerWidget {
  final int novelId;

  const NovelDetailScreen({super.key, required this.novelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novelAsync = ref.watch(novelProvider(novelId));
    final tagsAsync = ref.watch(novelTagsProvider(novelId));
    final authorAsync = ref.watch(novelAuthorProvider(novelId));
    final rankingsAsync = ref.watch(novelRankingsProvider(novelId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('小说详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: novelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (novel) {
          if (novel == null) {
            return const Center(child: Text('小说不存在'));
          }
          return _buildContent(context, novel, tagsAsync, authorAsync, rankingsAsync);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Novel novel,
    AsyncValue<List<Tag>> tagsAsync,
    AsyncValue<Author?> authorAsync,
    AsyncValue<Map<String, int>> rankingsAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          _Breadcrumb(novelTitle: novel.title),
          const SizedBox(height: 16),

          // Main: info + cover
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info (left)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      novel.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '#${novel.id}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Author
                    authorAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (author) {
                        if (author == null) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () {
                            // Navigate to author detail
                          },
                          child: Text(
                            author.name,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (novel.hasBanner)
                          _Badge(
                            label: '背投',
                            color: AppColors.accent,
                          ),
                        _StatusBadge(status: novel.status),
                        _GenreBadge(genre: novel.genre),
                        _PtypeBadge(ptype: novel.ptype),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Tags (directly below badges)
                    tagsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (tags) {
                        if (tags.isEmpty) return const SizedBox.shrink();
                        return Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags.map((tag) => _TagChip(name: tag.name)).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Cover (right)
              Column(
                children: [
                  _CoverImage(cover: novel.cover),
                  const SizedBox(height: 8),
                  _ViewOnSfacgButton(novelId: novel.id),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats grid (2 cols)
          rankingsAsync.when(
            loading: () => _StatsGrid(novel: novel, rankings: const {}),
            error: (_, __) => _StatsGrid(novel: novel, rankings: const {}),
            data: (rankings) => _StatsGrid(novel: novel, rankings: rankings),
          ),
          const SizedBox(height: 16),

          // Dates
          _DatesSection(novel: novel),
        ],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String? cover;

  const _CoverImage({required this.cover});

  @override
  Widget build(BuildContext context) {
    if (cover == null || cover!.isEmpty) {
      return Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.book, size: 48, color: AppColors.primary),
        ),
      );
    }

    final url = cover!.startsWith('http')
        ? cover!
        : 'https://rs.sfacg.com/web/novel/images/NovelCover/Big/$cover';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 120,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            color: AppColors.primary.withValues(alpha: 0.1),
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.primary.withValues(alpha: 0.1),
            child: const Center(
              child: Icon(Icons.broken_image, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewOnSfacgButton extends StatelessWidget {
  final int novelId;

  const _ViewOnSfacgButton({required this.novelId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: ElevatedButton.icon(
        onPressed: () async {
          final url = Uri.parse(
            _sfacgUrlPattern.replaceAll('{nid}', novelId.toString()),
          );
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.open_in_new, size: 14),
        label: const Text('在SFACG查看', style: TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final String novelTitle;

  const _Breadcrumb({required this.novelTitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            '首页',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('/', style: TextStyle(color: Colors.grey[400])),
        ),
        Expanded(
          child: Text(
            novelTitle,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final int status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      2 => AppColors.completed,   // 已完结
      3 => AppColors.ongoing,     // 连载中
      4 => AppColors.stopped,     // 断更
      5 => AppColors.stopped,     // 断更A
      6 => AppColors.completed,   // 完结A
      _ => Colors.grey,
    };

    return _Badge(
      label: statusMapping.getZh(status),
      color: color,
    );
  }
}

class _GenreBadge extends StatelessWidget {
  final int genre;

  const _GenreBadge({required this.genre});

  @override
  Widget build(BuildContext context) {
    return _Badge(
      label: genreMapping.getZh(genre),
      color: AppColors.primary,
    );
  }
}

class _PtypeBadge extends StatelessWidget {
  final int ptype;

  const _PtypeBadge({required this.ptype});

  @override
  Widget build(BuildContext context) {
    return _Badge(
      label: ptypeMapping.getZh(ptype),
      color: AppColors.secondary,
    );
  }
}

class _TagChip extends StatelessWidget {
  final String name;

  const _TagChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Novel novel;
  final Map<String, int> rankings;

  const _StatsGrid({required this.novel, required this.rankings});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _StatItem(
          icon: Icons.text_fields,
          label: '字数',
          value: novel.wordNum,
          rank: rankings['word_num'],
          color: AppColors.primary,
        ),
        _StatItem(
          icon: Icons.touch_app,
          label: '点击',
          value: novel.clickNum,
          rank: rankings['click_num'],
          color: AppColors.accent,
        ),
        _StatItem(
          icon: Icons.favorite,
          label: '收藏',
          value: novel.likeNum,
          rank: rankings['like_num'],
          color: Colors.pink,
        ),
        _StatItem(
          icon: Icons.thumb_up,
          label: '点赞',
          value: novel.praiseNum,
          rank: rankings['praise_num'],
          color: AppColors.primary,
        ),
        _StatItem(
          icon: Icons.rate_review,
          label: '长评',
          value: novel.reviewNum,
          rank: rankings['review_num'],
          color: Colors.teal,
        ),
        _StatItem(
          icon: Icons.comment,
          label: '短评',
          value: novel.commentNum,
          rank: rankings['comment_num'],
          color: Colors.brown,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? value;
  final int? rank;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.rank,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                Text(
                  _formatNumber(value ?? 0),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (rank != null)
            Text(
              '#$rank',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 100000000) return '${(num / 100000000).toStringAsFixed(1)}亿';
    if (num >= 10000) return '${(num / 10000).toStringAsFixed(1)}万';
    return num.toString();
  }
}

class _DatesSection extends StatelessWidget {
  final Novel novel;

  const _DatesSection({required this.novel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _DateRow(
            icon: Icons.update,
            label: '最后更新',
            date: novel.lastUpdate,
          ),
          const SizedBox(height: 8),
          _DateRow(
            icon: Icons.sync,
            label: '同步时间',
            date: novel.dbUpdate,
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? date;

  const _DateRow({
    required this.icon,
    required this.label,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        Text(
          date != null ? _formatDate(date!) : '未知',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
