import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../app/theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/utils/spacing.dart';

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
        loading: () => const LoadingState(message: '加载小说详情...'),
        error: (err, stack) => EmptyState(
          icon: Icons.error_outline,
          message: '加载失败',
          subtitle: err.toString(),
        ),
        data: (novel) {
          if (novel == null) {
            return const EmptyState(
              icon: Icons.book,
              message: '小说不存在',
            );
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
      padding: AppSpacing.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          _Breadcrumb(novelTitle: novel.title),
          AppSpacing.gapHeightL,

          // Main: info + cover
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info (left)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with copy button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            novel.title,
                            style: AppTextStyles.titleLarge,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: novel.title));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('已复制标题'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy,
                            size: 18,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '#${novel.id}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    AppSpacing.gapHeightS,

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
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
                    AppSpacing.gapHeightS,

                    // Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (novel.hasBanner)
                          const BadgeWidget(
                            label: '背投',
                            color: AppColors.accent,
                          ),
                        StatusBadge(status: novel.status),
                        GenreBadge(genre: novel.genre),
                        PtypeBadge(ptype: novel.ptype),
                      ],
                    ),
                    AppSpacing.gapHeightS,

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
              AppSpacing.gapWidthL,

              // Cover (right)
              Column(
                children: [
                  CoverImage(
                    cover: novel.cover,
                    width: 120,
                    height: 160,
                    borderRadius: 8,
                  ),
                  AppSpacing.gapHeightS,
                  _ViewOnSfacgButton(novelId: novel.id),
                ],
              ),
            ],
          ),
          AppSpacing.gapHeightL,

          // Stats grid (2 cols)
          rankingsAsync.when(
            loading: () => _StatsGrid(novel: novel, rankings: const {}),
            error: (_, __) => _StatsGrid(novel: novel, rankings: const {}),
            data: (rankings) => _StatsGrid(novel: novel, rankings: rankings),
          ),
          AppSpacing.gapHeightL,

          // Dates
          _DatesSection(novel: novel),
        ],
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
        StatItem(
          icon: Icons.text_fields,
          label: '字数',
          value: formatNumber(novel.wordNum ?? 0),
          rank: rankings['word_num'],
          color: AppColors.primary,
        ),
        StatItem(
          icon: Icons.touch_app,
          label: '点击',
          value: formatNumber(novel.clickNum ?? 0),
          rank: rankings['click_num'],
          color: AppColors.accent,
        ),
        StatItem(
          icon: Icons.favorite,
          label: '收藏',
          value: formatNumber(novel.likeNum ?? 0),
          rank: rankings['like_num'],
          color: Colors.pink,
        ),
        StatItem(
          icon: Icons.thumb_up,
          label: '点赞',
          value: formatNumber(novel.praiseNum ?? 0),
          rank: rankings['praise_num'],
          color: AppColors.primary,
        ),
        StatItem(
          icon: Icons.rate_review,
          label: '长评',
          value: formatNumber(novel.reviewNum ?? 0),
          rank: rankings['review_num'],
          color: Colors.teal,
        ),
        StatItem(
          icon: Icons.comment,
          label: '短评',
          value: formatNumber(novel.commentNum ?? 0),
          rank: rankings['comment_num'],
          color: Colors.brown,
        ),
      ],
    );
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
