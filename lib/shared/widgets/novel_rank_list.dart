import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/database.dart';
import '../../app/theme.dart';
import 'common_widgets.dart';

class NovelRankList extends ConsumerStatefulWidget {
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
  ConsumerState<NovelRankList> createState() => _NovelRankListState();
}

class _NovelRankListState extends ConsumerState<NovelRankList> {
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
    final shouldShow = _scrollController.offset > 500;
    if (shouldShow != _showBackToTop) {
      setState(() => _showBackToTop = shouldShow);
    }

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
            if (showRank) ...[_buildRank(context, rank), const SizedBox(width: 10)],
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
                  // Author with avatar icon
                  if (novel.author != null && novel.author!.isNotEmpty)
                    _buildAuthor(),
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

  Widget _buildRank(BuildContext context, int rank) {
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
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.black
              : Colors.white,
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
    return Text(
      novel.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
    );
  }

  Widget _buildAuthor() {
    return Row(
      children: [
        Icon(
          Icons.person,
          size: 14,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            novel.author!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
    final value = _getValueByLabel();
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

  int _getValueByLabel() {
    return switch (valueLabel) {
      '字数' => novel.wordNum ?? 0,
      '收藏' => novel.likeNum ?? 0,
      '点赞' => novel.praiseNum ?? 0,
      '长评' => novel.reviewNum ?? 0,
      '短评' => novel.commentNum ?? 0,
      _ => novel.clickNum ?? 0, // 默认为点击
    };
  }
}
