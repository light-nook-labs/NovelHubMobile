import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/utils/mappings.dart';
import '../../app/theme.dart';

class NovelDetailScreen extends ConsumerWidget {
  final int novelId;

  const NovelDetailScreen({super.key, required this.novelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novelAsync = ref.watch(novelProvider(novelId));
    final tagsAsync = ref.watch(novelTagsProvider(novelId));
    final authorAsync = ref.watch(novelAuthorProvider(novelId));

    return Scaffold(
      body: novelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (novel) {
          if (novel == null) {
            return const Center(child: Text('小说不存在'));
          }
          return _buildContent(context, novel, tagsAsync, authorAsync);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Novel novel,
    AsyncValue<List<Tag>> tagsAsync,
    AsyncValue<Author?> authorAsync,
  ) {
    return CustomScrollView(
      slivers: [
        // App bar with cover
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              novel.title,
              style: const TextStyle(
                shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
              ),
            ),
            background: _buildCoverBackground(novel),
          ),
        ),
        // Novel info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author
                authorAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (author) {
                    if (author == null) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            author.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Status and genre
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.signal_cellular_alt,
                      label: statusMapping.getZh(novel.status),
                      color: _getStatusColor(novel.status),
                    ),
                    _InfoChip(
                      icon: Icons.category,
                      label: genreMapping.getZh(novel.genre),
                      color: AppColors.primary,
                    ),
                    _InfoChip(
                      icon: Icons.description,
                      label: ptypeMapping.getZh(novel.ptype),
                      color: AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats grid
                _buildStatsGrid(context, novel),
                const SizedBox(height: 16),
                // Tags
                tagsAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (tags) {
                    if (tags.isEmpty) return const SizedBox();
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag.name),
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Last update
                if (novel.lastUpdate != null)
                  Row(
                    children: [
                      const Icon(Icons.update, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '最后更新: ${_formatDateTime(novel.lastUpdate!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverBackground(Novel novel) {
    if (novel.cover == null || novel.cover!.isEmpty) {
      return Container(
        color: AppColors.primary.withValues(alpha: 0.2),
        child: const Center(
          child: Icon(Icons.book, size: 80, color: AppColors.primary),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: novel.cover!,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            color: AppColors.primary.withValues(alpha: 0.2),
            child: const Center(
              child: Icon(Icons.book, size: 80, color: AppColors.primary),
            ),
          ),
        ),
        // Gradient overlay
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, Novel novel) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _StatItem(icon: Icons.touch_app, label: '点击', value: novel.clickNum),
        _StatItem(icon: Icons.text_fields, label: '字数', value: novel.wordNum),
        _StatItem(icon: Icons.thumb_up, label: '点赞', value: novel.likeNum),
        _StatItem(icon: Icons.favorite, label: '收藏', value: novel.praiseNum),
        _StatItem(icon: Icons.rate_review, label: '书评', value: novel.reviewNum),
        _StatItem(icon: Icons.comment, label: '评论', value: novel.commentNum),
      ],
    );
  }

  Color _getStatusColor(int status) {
    return switch (status) {
      1 => AppColors.ongoing,
      2 => AppColors.completed,
      3 => AppColors.stopped,
      _ => Colors.grey,
    };
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatNumber(value ?? 0),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
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
