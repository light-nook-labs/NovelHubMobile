import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../app/theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/utils/spacing.dart';
import '../contests/contests_screen.dart';
import '../bookshelf/bookshelf_provider.dart';

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
    final bookshelfAsync = ref.watch(bookshelfProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('小说详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          novelAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (novel) {
              if (novel == null) return const SizedBox.shrink();
              final isInBookshelf = bookshelfAsync.valueOrNull?.contains(novel.id) ?? false;
              return IconButton(
                icon: Icon(
                  isInBookshelf ? Icons.bookmark : Icons.bookmark_border,
                  color: isInBookshelf ? AppColors.primary : null,
                ),
                onPressed: () {
                  ref.read(bookshelfProvider.notifier).toggle(novel.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isInBookshelf ? '已从书架移除' : '已添加到书架'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ],
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
            return const EmptyState(icon: Icons.book, message: '小说不存在');
          }
          final contestAsync = novel.contestId != null
              ? ref.watch(contestProvider(novel.contestId!))
              : null;
          return _buildContent(
            context,
            novel,
            tagsAsync,
            authorAsync,
            rankingsAsync,
            contestAsync,
          );
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
    AsyncValue<Contest?>? contestAsync,
  ) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero: cover + title/author/badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover (left)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CoverImage(
                  cover: novel.cover,
                  width: 110,
                  height: 147,
                  borderRadius: 8,
                ),
              ),
              AppSpacing.gapWidthL,

              // Info (right)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + ID + copy
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: novel.title,
                                  style: AppTextStyles.titleLarge,
                                ),
                                TextSpan(
                                  text: '  #${novel.id}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: novel.title));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('已复制标题'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapHeightS,

                    // Author with icon
                    authorAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (author) {
                        if (author == null) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () => context.push('/author/${author.id}'),
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 15, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  author.name,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                        StatusBadge(
                          status: novel.status,
                          onTap: () => context.push('/novels-by-status?status=${novel.status}'),
                        ),
                        GenreBadge(
                          genre: novel.genre,
                          onTap: () => context.push('/novels-by-genre?genre=${novel.genre}'),
                        ),
                        PtypeBadge(
                          ptype: novel.ptype,
                          onTap: () => context.go('/novels?ptype=${novel.ptype}'),
                        ),
                      ],
                    ),
                    AppSpacing.gapHeightS,

                    // SFACG button
                    _ViewOnSfacgButton(novelId: novel.id),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapHeightL,

          // Tags
          tagsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (tags) {
              if (tags.isEmpty) return const SizedBox.shrink();
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .map((tag) => _TagChip(id: tag.id, name: tag.name))
                    .toList(),
              );
            },
          ),
          AppSpacing.gapHeightL,

          // Contest
          if (contestAsync != null)
            contestAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (contest) {
                if (contest == null) return const SizedBox.shrink();
                return _ContestCard(contest: contest);
              },
            ),
          if (contestAsync != null) AppSpacing.gapHeightL,

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final int id;
  final String name;

  const _TagChip({required this.id, required this.name});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tag/$id'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.label, size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(color: AppColors.primaryDark, fontSize: 12),
            ),
          ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _DateRow(icon: Icons.update, label: '最后更新', date: novel.lastUpdate),
    );
  }
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? date;

  const _DateRow({required this.icon, required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          date != null ? _formatDate(date!) : '未知',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _ContestCard extends StatelessWidget {
  final Contest contest;

  const _ContestCard({required this.contest});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/contest/${contest.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events, size: 20, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '比赛',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contest.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
