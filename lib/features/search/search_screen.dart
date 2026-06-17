import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/novel_rank_list.dart';

part 'search_screen.g.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _keyword = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider(_keyword));

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
                      setState(() => _keyword = '');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() => _keyword = value);
              }
            });
          },
        ),
      ),
      body: _keyword.isEmpty
          ? _buildEmptyState()
          : resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (novels) {
                if (novels.isEmpty) {
                  return Center(child: Text('未找到 "$_keyword" 相关小说'));
                }
                return _buildResults(context, novels);
              },
            ),
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

  Widget _buildResults(BuildContext context, List<Novel> novels) {
    return ListView.builder(
      itemCount: novels.length,
      itemBuilder: (context, index) {
        final novel = novels[index];
        return NovelRankRow(
          novel: novel,
          rank: index + 1,
          showRank: false,
          valueLabel: '点击',
        );
      },
    );
  }
}

@riverpod
Future<List<Novel>> searchResults(SearchResultsRef ref, String keyword) async {
  if (keyword.isEmpty) return [];
  // Debounce
  await Future.delayed(const Duration(milliseconds: 300));
  final db = ref.watch(databaseProvider);
  return db.searchNovels(keyword);
}
