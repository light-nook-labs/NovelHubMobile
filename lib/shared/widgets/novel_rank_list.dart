import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/database.dart';
import '../../app/theme.dart';
import 'common_widgets.dart';

class NovelRankList extends StatefulWidget {
  final Future<List<Novel>> Function(int offset, int limit) loadNovels;
  final bool showRank;
  final String valueLabel;

  const NovelRankList({
    super.key,
    required this.loadNovels,
    this.showRank = true,
    this.valueLabel = '点击',
  });

  @override
  State<NovelRankList> createState() => _NovelRankListState();
}

class _NovelRankListState extends State<NovelRankList> {
  final _scrollController = ScrollController();
  final _pageSize = 48;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<Novel> _novels = [];
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _showBackToTop = _scrollController.offset > 500;
    });

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    final newNovels = await widget.loadNovels(
      _currentPage * _pageSize,
      _pageSize,
    );

    setState(() {
      _currentPage++;
      _novels.addAll(newNovels);
      _hasMore = newNovels.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  void reset() {
    setState(() {
      _currentPage = 0;
      _novels = [];
      _hasMore = true;
    });
    _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_novels.isEmpty && _isLoadingMore) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_novels.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _novels.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _novels.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final novel = _novels[index];
            return NovelRankRow(
              novel: novel,
              rank: index + 1,
              showRank: widget.showRank,
              valueLabel: widget.valueLabel,
            );
          },
        ),
        if (_showBackToTop)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            ),
          ),
      ],
    );
  }
}

class NovelRankRow extends StatelessWidget {
  final Novel novel;
  final int rank;
  final bool showRank;
  final String valueLabel;

  const NovelRankRow({
    super.key,
    required this.novel,
    required this.rank,
    this.showRank = true,
    this.valueLabel = '点击',
  });

  @override
  Widget build(BuildContext context) {
    final url = novel.cover != null && novel.cover!.isNotEmpty
        ? (novel.cover!.startsWith('http')
              ? novel.cover!
              : 'https://rs.sfacg.com/web/novel/images/NovelCover/Big/${novel.cover}')
        : null;

    return InkWell(
      onTap: () => context.push('/novel/${novel.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rank
            if (showRank) ...[_buildRank(rank), const SizedBox(width: 10)],
            // Cover
            _buildCover(url),
            const SizedBox(width: 10),
            // Novel info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + ID
                  _buildTitle(context),
                  const SizedBox(height: 4),
                  // Badges
                  _buildBadges(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Value
            _buildValue(),
          ],
        ),
      ),
    );
  }

  Widget _buildRank(int rank) {
    final isTop3 = rank <= 3;
    final color = switch (rank) {
      1 => const Color(0xFFFFD700), // Gold
      2 => const Color(0xFFC0C0C0), // Silver
      3 => const Color(0xFFCD7F32), // Bronze
      _ => Colors.grey,
    };

    if (isTop3) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Center(
          child: Text(
            '$rank',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 28,
      child: Text(
        '$rank',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCover(String? url) {
    return Container(
      width: 50,
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const Center(
                child: Icon(Icons.book, size: 24, color: AppColors.primary),
              ),
            )
          : const Center(
              child: Icon(Icons.book, size: 24, color: AppColors.primary),
            ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: novel.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.3,
            ),
          ),
          TextSpan(
            text: ' #${novel.id}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        StatusBadge(status: novel.status),
        GenreBadge(genre: novel.genre),
        PtypeBadge(ptype: novel.ptype),
      ],
    );
  }

  Widget _buildValue() {
    final value = novel.clickNum ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatNumber(value),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          valueLabel,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

class NovelFilterBottomSheet extends StatefulWidget {
  final String sortBy;
  final bool descending;
  final Function(String, bool) onApply;

  const NovelFilterBottomSheet({
    super.key,
    required this.sortBy,
    required this.descending,
    required this.onApply,
  });

  @override
  State<NovelFilterBottomSheet> createState() => _NovelFilterBottomSheetState();
}

class _NovelFilterBottomSheetState extends State<NovelFilterBottomSheet> {
  late String _sortBy;
  late bool _descending;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.sortBy;
    _descending = widget.descending;
  }

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      {'key': 'click_num', 'label': '点击量'},
      {'key': 'word_num', 'label': '字数'},
      {'key': 'like_num', 'label': '收藏'},
      {'key': 'praise_num', 'label': '点赞'},
      {'key': 'last_update', 'label': '更新时间'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '排序',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortOptions.map((option) {
              final key = option['key']!;
              final label = option['label']!;
              return GestureDetector(
                onTap: () => setState(() => _sortBy = key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _sortBy == key
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: _sortBy == key ? Colors.white : null,
                      fontWeight: _sortBy == key
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_sortBy, _descending);
                Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('应用'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
