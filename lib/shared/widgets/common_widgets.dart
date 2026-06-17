import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/theme.dart';
import '../utils/mappings.dart';

/// Reusable search bar widget for AppBar
class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;

  const SearchBarWidget({super.key, this.hintText = '搜索小说...', this.onTap});

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
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer loading grid for novels
class NovelGridShimmer extends StatelessWidget {
  final int itemCount;

  const NovelGridShimmer({super.key, this.itemCount = 12});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.55,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      width: 40,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shimmer loading for list items
class ListShimmer extends StatelessWidget {
  final int itemCount;

  const ListShimmer({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
          memCacheHeight: 400,
          memCacheWidth: 320,
          placeholder: (context, url) => Container(
            color: AppColors.primary.withValues(alpha: 0.1),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.primary.withValues(alpha: 0.1),
            child: const Center(child: Icon(Icons.broken_image, size: 24)),
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
        border: outlined
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
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

    return BadgeWidget(label: statusMapping.getZh(status), color: color);
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

  const ListItemWithDivider({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(onTap: onTap, child: child),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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

/// Reusable novel filter bottom sheet
class NovelFilterBottomSheet extends StatefulWidget {
  final int? selectedGenre;
  final int? selectedStatus;
  final int? selectedYear;
  final int? selectedMinWordNum;
  final int? selectedMaxWordNum;
  final String sortBy;
  final bool descending;
  final bool hideOther;
  final List<int> availableYears;
  final Function(int?, int?, int?, int?, int?, String, bool) onApply;

  const NovelFilterBottomSheet({
    super.key,
    this.selectedGenre,
    this.selectedStatus,
    this.selectedYear,
    this.selectedMinWordNum,
    this.selectedMaxWordNum,
    required this.sortBy,
    required this.descending,
    required this.hideOther,
    required this.availableYears,
    required this.onApply,
  });

  @override
  State<NovelFilterBottomSheet> createState() => _NovelFilterBottomSheetState();
}

class _NovelFilterBottomSheetState extends State<NovelFilterBottomSheet> {
  late int? _genre;
  late int? _status;
  late int? _year;
  late int? _minWordNum;
  late int? _maxWordNum;
  late String _sortBy;
  late bool _descending;

  static const _wordNumBreakpoints = [
    50000,
    100000,
    200000,
    500000,
    1000000,
    2000000,
    3000000,
    4000000,
    5000000,
  ];

  @override
  void initState() {
    super.initState();
    _genre = widget.selectedGenre;
    _status = widget.selectedStatus;
    _year = widget.selectedYear;
    _minWordNum = widget.selectedMinWordNum;
    _maxWordNum = widget.selectedMaxWordNum;
    _sortBy = widget.sortBy;
    _descending = widget.descending;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '筛选与排序',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _genre = null;
                        _status = null;
                        _year = null;
                        _minWordNum = null;
                        _maxWordNum = null;
                        _sortBy = 'click_num';
                        _descending = true;
                      });
                    },
                    child: const Text('重置'),
                  ),
                ],
              ),
            ),
            // Filter options
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSection(
                    title: '分类',
                    options: genreMapping.getAllZh(hideOther: widget.hideOther).map((zh) {
                      final value = genreMapping.getValue(zh);
                      return _Option(label: zh, value: value);
                    }).toList(),
                    selectedValue: _genre,
                    onChanged: (v) => setState(() => _genre = v),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: '状态',
                    options: statusMapping.getAllZh(hideOther: widget.hideOther).map((zh) {
                      final value = statusMapping.getValue(zh);
                      return _Option(label: zh, value: value);
                    }).toList(),
                    selectedValue: _status,
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: '更新年份',
                    options: widget.availableYears
                        .map((y) => _Option(label: '$y年', value: y))
                        .toList(),
                    selectedValue: _year,
                    onChanged: (v) => setState(() => _year = v),
                  ),
                  const SizedBox(height: 24),
                  _buildWordNumSection(),
                  const SizedBox(height: 24),
                  _buildSortSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Apply button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(
                      _genre,
                      _status,
                      _year,
                      _minWordNum,
                      _maxWordNum,
                      _sortBy,
                      _descending,
                    );
                    Navigator.pop(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('应用'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<_Option> options,
    required int? selectedValue,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChipWidget(
              label: '全部',
              isSelected: selectedValue == null,
              onTap: () => onChanged(null),
            ),
            ...options.map(
              (option) => FilterChipWidget(
                label: option.label,
                isSelected: selectedValue == option.value,
                onTap: () => onChanged(option.value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortSection() {
    final sortOptions = [
      {'key': 'click_num', 'label': '点击量'},
      {'key': 'word_num', 'label': '字数'},
      {'key': 'like_num', 'label': '收藏'},
      {'key': 'praise_num', 'label': '点赞'},
      {'key': 'last_update', 'label': '更新时间'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '排序',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() => _descending = !_descending);
              },
              icon: Icon(
                _descending ? Icons.arrow_downward : Icons.arrow_upward,
                size: 16,
              ),
              label: Text(_descending ? '降序' : '升序'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sortOptions.map((option) {
            final key = option['key']!;
            final label = option['label']!;
            return FilterChipWidget(
              label: label,
              isSelected: _sortBy == key,
              onTap: () => setState(() => _sortBy = key),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWordNumSection() {
    final ranges = <Map<String, dynamic>>[
      {'label': '不限', 'min': null, 'max': null},
      {'label': '<5万', 'min': null, 'max': 50000},
    ];
    for (int i = 0; i < _wordNumBreakpoints.length - 1; i++) {
      final min = _wordNumBreakpoints[i];
      final max = _wordNumBreakpoints[i + 1];
      final minLabel = _formatWordNum(min);
      final maxLabel = _formatWordNum(max);
      ranges.add({'label': '$minLabel-$maxLabel', 'min': min, 'max': max});
    }
    ranges.add({'label': '>500万', 'min': 5000000, 'max': null});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '字数范围',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ranges.map((range) {
            final min = range['min'] as int?;
            final max = range['max'] as int?;
            final isSelected = _minWordNum == min && _maxWordNum == max;
            return FilterChipWidget(
              label: range['label'] as String,
              isSelected: isSelected,
              onTap: () => setState(() {
                _minWordNum = min;
                _maxWordNum = max;
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatWordNum(int num) {
    if (num >= 10000) return '${(num / 10000).toInt()}万';
    return num.toString();
  }
}

class _Option {
  final String label;
  final int value;

  const _Option({required this.label, required this.value});
}
