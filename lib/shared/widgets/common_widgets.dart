import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../utils/mappings.dart';

/// Reusable search bar widget for AppBar
class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;

  const SearchBarWidget({
    super.key,
    this.hintText = '搜索小说...',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/search'),
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
              hintText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable back-to-top floating action button
class BackToTopButton extends StatelessWidget {
  final ScrollController scrollController;
  final bool show;

  const BackToTopButton({
    super.key,
    required this.scrollController,
    required this.show,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton.small(
        onPressed: () {
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
        child: const Icon(Icons.arrow_upward),
      ),
    );
  }
}

/// Reusable empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const EmptyState({
    super.key,
    this.icon = Icons.book,
    this.message = '暂无数据',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable loading state widget
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable cover image widget
class CoverImage extends StatelessWidget {
  final String? cover;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const CoverImage({
    super.key,
    this.cover,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (cover == null || cover!.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Center(
          child: Icon(Icons.book, size: 24, color: AppColors.primary),
        ),
      );
    }

    final url = cover!.startsWith('http')
        ? cover!
        : 'https://rs.sfacg.com/web/novel/images/NovelCover/Big/$cover';

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          placeholder: (context, url) => Container(
            color: AppColors.primary.withValues(alpha: 0.1),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.primary.withValues(alpha: 0.1),
            child: const Center(
              child: Icon(Icons.broken_image, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable badge widget
class BadgeWidget extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;

  const BadgeWidget({
    super.key,
    required this.label,
    required this.color,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: outlined ? Border.all(color: color.withValues(alpha: 0.3)) : null,
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
}

/// Reusable status badge
class StatusBadge extends StatelessWidget {
  final int status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      2 => AppColors.completed,
      3 => AppColors.ongoing,
      4 => AppColors.stopped,
      5 => AppColors.stopped,
      6 => AppColors.completed,
      _ => Colors.grey,
    };

    return BadgeWidget(
      label: statusMapping.getZh(status),
      color: color,
    );
  }
}

/// Reusable genre badge
class GenreBadge extends StatelessWidget {
  final int genre;

  const GenreBadge({super.key, required this.genre});

  @override
  Widget build(BuildContext context) {
    return BadgeWidget(
      label: genreMapping.getZh(genre),
      color: AppColors.primary,
    );
  }
}

/// Reusable ptype badge
class PtypeBadge extends StatelessWidget {
  final int ptype;

  const PtypeBadge({super.key, required this.ptype});

  @override
  Widget build(BuildContext context) {
    return BadgeWidget(
      label: ptypeMapping.getZh(ptype),
      color: AppColors.secondary,
    );
  }
}

/// Reusable filter chip widget
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Reusable list item with divider
class ListItemWithDivider extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ListItemWithDivider({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: child,
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// Reusable stat item for grid
class StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int? rank;

  const StatItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.rank,
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
                  value,
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
}

/// Number formatting utility
String formatNumber(int num) {
  if (num >= 100000000) return '${(num / 100000000).toStringAsFixed(1)}亿';
  if (num >= 10000) return '${(num / 10000).toStringAsFixed(1)}万';
  return num.toString();
}
