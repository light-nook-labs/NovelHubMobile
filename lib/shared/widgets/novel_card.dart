import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/database.dart';
import '../../shared/utils/mappings.dart';
import '../../app/theme.dart';

class NovelCard extends StatelessWidget {
  final Novel novel;
  final VoidCallback? onTap;

  const NovelCard({super.key, required this.novel, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover with 4:5 aspect ratio (matching web design)
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildCover(),
            ),
          ),
          const SizedBox(height: 6),

          // Title (max 2 lines)
          Text(
            novel.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),

          // Status + Genre badges (hidden on very small cards)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _SmallBadge(
                  label: statusMapping.getZh(novel.status),
                  color: _getStatusColor(novel.status),
                ),
                const SizedBox(width: 4),
                _SmallBadge(
                  label: genreMapping.getZh(novel.genre),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    if (novel.cover == null || novel.cover!.isEmpty) {
      return const Center(
        child: Icon(Icons.book, size: 32, color: AppColors.primary),
      );
    }

    final url = novel.cover!.startsWith('http')
        ? novel.cover!
        : 'https://rs.sfacg.com/web/novel/images/NovelCover/Big/${novel.cover}';

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheHeight: 500, // Limit cache size
      memCacheWidth: 400,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image, size: 32),
      ),
    );
  }

  Color _getStatusColor(int status) {
    return switch (status) {
      2 => AppColors.completed,   // 已完结
      3 => AppColors.ongoing,     // 连载中
      4 => AppColors.stopped,     // 断更
      5 => AppColors.stopped,     // 断更A
      6 => AppColors.completed,   // 完结A
      _ => Colors.grey,
    };
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
