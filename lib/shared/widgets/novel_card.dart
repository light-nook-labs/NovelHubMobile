import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/database.dart';
import '../../app/theme.dart';
import 'common_widgets.dart';

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
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primary.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildCover(),
            ),
          ),
          const SizedBox(height: 6),

          // Title (max 2 lines)
          Expanded(
            flex: 1,
            child: Text(
              novel.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Status badge
          StatusBadge(status: novel.status),
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
      memCacheHeight: 400,
      memCacheWidth: 320,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image, size: 32),
      ),
    );
  }
}
