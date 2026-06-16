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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover with 4:5 aspect ratio (matching web design)
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildCover(),
            ),
          ),
          const SizedBox(height: 4),

          // Title (max 2 lines)
          Expanded(
            flex: 1,
            child: Text(
              novel.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),

          // Status badge only (genre removed to save space)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: _getStatusColor(novel.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              statusMapping.getZh(novel.status),
              style: TextStyle(
                fontSize: 8,
                color: _getStatusColor(novel.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    if (novel.cover == null || novel.cover!.isEmpty) {
      return const Center(
        child: Icon(Icons.book, size: 24, color: AppColors.primary),
      );
    }

    final url = novel.cover!.startsWith('http')
        ? novel.cover!
        : 'https://rs.sfacg.com/web/novel/images/NovelCover/Big/${novel.cover}';

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheHeight: 400,
      memCacheWidth: 320,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image, size: 24),
      ),
    );
  }

  Color _getStatusColor(int status) {
    return switch (status) {
      2 => AppColors.completed,
      3 => AppColors.ongoing,
      4 => AppColors.stopped,
      5 => AppColors.stopped,
      6 => AppColors.completed,
      _ => Colors.grey,
    };
  }
}
