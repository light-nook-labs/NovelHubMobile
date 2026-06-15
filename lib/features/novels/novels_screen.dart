import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/novel_card.dart';
import '../../shared/utils/mappings.dart';

part 'novels_screen.g.dart';

class NovelsScreen extends ConsumerStatefulWidget {
  const NovelsScreen({super.key});

  @override
  ConsumerState<NovelsScreen> createState() => _NovelsScreenState();
}

class _NovelsScreenState extends ConsumerState<NovelsScreen> {
  int? _selectedGenre;
  int? _selectedStatus;
  String _sortBy = 'last_update';
  bool _descending = true;

  @override
  Widget build(BuildContext context) {
    final novelsAsync = ref.watch(
      filteredNovelsProvider(
        genre: _selectedGenre,
        status: _selectedStatus,
        sortBy: _sortBy,
        descending: _descending,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('小说列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          // Novel grid
          Expanded(
            child: novelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (novels) {
                if (novels.isEmpty) {
                  return const Center(child: Text('暂无数据，请先同步'));
                }
                return _buildNovelGrid(novels);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          FilterChip(
            label: Text(
              _selectedGenre == null
                  ? '全部类型'
                  : genreMapping.getZh(_selectedGenre!),
            ),
            selected: _selectedGenre != null,
            onSelected: (selected) {
              setState(() => _selectedGenre = selected ? 1 : null);
            },
          ),
          const SizedBox(width: 8),
          ...genreMapping.allZh.map((zh) {
            final value = genreMapping.getValue(zh);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(zh),
                selected: _selectedGenre == value,
                onSelected: (selected) {
                  setState(() => _selectedGenre = selected ? value : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNovelGrid(List<Novel> novels) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: novels.length,
          itemBuilder: (context, index) {
            final novel = novels[index];
            return NovelCard(
              novel: novel,
              onTap: () => context.push('/novel/${novel.id}'),
            );
          },
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('排序方式', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _SortChip(
                      label: '更新时间',
                      value: 'last_update',
                      current: _sortBy,
                      onSelected: (v) => setSheetState(() => _sortBy = v),
                    ),
                    _SortChip(
                      label: '点击量',
                      value: 'click_num',
                      current: _sortBy,
                      onSelected: (v) => setSheetState(() => _sortBy = v),
                    ),
                    _SortChip(
                      label: '字数',
                      value: 'word_num',
                      current: _sortBy,
                      onSelected: (v) => setSheetState(() => _sortBy = v),
                    ),
                    _SortChip(
                      label: '点赞',
                      value: 'like_num',
                      current: _sortBy,
                      onSelected: (v) => setSheetState(() => _sortBy = v),
                    ),
                    _SortChip(
                      label: '收藏',
                      value: 'praise_num',
                      current: _sortBy,
                      onSelected: (v) => setSheetState(() => _sortBy = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '排序方向',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('降序')),
                        ButtonSegment(value: false, label: Text('升序')),
                      ],
                      selected: {_descending},
                      onSelectionChanged: (v) =>
                          setSheetState(() => _descending = v.first),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text('应用'),
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

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onSelected;

  const _SortChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: current == value,
      onSelected: (_) => onSelected(value),
    );
  }
}

/// Filtered novels provider.
@riverpod
Future<List<Novel>> filteredNovels(
  FilteredNovelsRef ref, {
  int? genre,
  int? status,
  String sortBy = 'last_update',
  bool descending = true,
}) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelsSorted(sortBy, descending: descending, limit: 100);
}
