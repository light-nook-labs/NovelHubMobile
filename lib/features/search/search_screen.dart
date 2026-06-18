import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/novel_rank_list.dart';
import '../../shared/widgets/common_widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _keyword = '';
  Timer? _debounceTimer;
  bool _showBackToTop = false;

  // Pagination state
  final _pageSize = 10;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<Novel> _novels = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _controller.dispose();
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

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _keyword = value;
          _currentPage = 0;
          _novels = [];
          _hasMore = true;
        });
        if (_keyword.isNotEmpty) {
          _loadMore();
        }
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _keyword.isEmpty) return;
    setState(() => _isLoadingMore = true);

    final db = ref.read(databaseProvider);
    final newNovels = await db.searchNovels(
      _keyword,
      limit: _pageSize,
      offset: _currentPage * _pageSize,
    );

    if (!mounted) return;
    setState(() {
      _currentPage++;
      _novels.addAll(newNovels);
      _hasMore = newNovels.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索小说名称...',
            border: InputBorder.none,
            suffixIcon: _keyword.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _debounceTimer?.cancel();
                      setState(() {
                        _keyword = '';
                        _novels = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: _keyword.isEmpty
          ? _buildEmptyState()
          : _novels.isEmpty && _isLoadingMore
              ? const Center(child: CircularProgressIndicator())
              : _novels.isEmpty
                  ? Center(child: Text('未找到 "$_keyword" 相关小说'))
                  : _buildResults(context),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '输入关键词搜索',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
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
              showRank: false,
              valueLabel: '点击',
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
