import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/novel_card.dart';
import '../../shared/utils/mappings.dart';
import '../../app/theme.dart';

part 'novels_screen.g.dart';

class NovelsScreen extends ConsumerStatefulWidget {
  const NovelsScreen({super.key});

  @override
  ConsumerState<NovelsScreen> createState() => _NovelsScreenState();
}

class _NovelsScreenState extends ConsumerState<NovelsScreen> {
  int? _selectedGenre;
  int? _selectedStatus;
  int? _selectedPtype;
  String _sortBy = 'click_num';  // Default: click_num desc (matching novel_hub)
  bool _descending = true;

  @override
  Widget build(BuildContext context) {
    final novelsAsync = ref.watch(
      filteredNovelsProvider(
        genre: _selectedGenre,
        status: _selectedStatus,
        ptype: _selectedPtype,
        sortBy: _sortBy,
        descending: _descending,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => context.push('/search'),
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
                  '搜索小说...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters (matching web design)
          _buildFilters(),
          // Novel grid
          Expanded(
            child: novelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (novels) {
                if (novels.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暂无数据'),
                      ],
                    ),
                  );
                }
                return _buildNovelGrid(novels);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre filters
          _buildFilterRow(
            label: '分类',
            items: genreMapping.allZh.map((zh) {
              final value = genreMapping.getValue(zh);
              return FilterItem(label: zh, value: value);
            }).toList(),
            selectedValue: _selectedGenre,
            onChanged: (value) => setState(() => _selectedGenre = value),
          ),
          const SizedBox(height: 8),

          // Status filters
          _buildFilterRow(
            label: '状态',
            items: statusMapping.allZh.map((zh) {
              final value = statusMapping.getValue(zh);
              return FilterItem(label: zh, value: value);
            }).toList(),
            selectedValue: _selectedStatus,
            onChanged: (value) => setState(() => _selectedStatus = value),
          ),
          const SizedBox(height: 8),

          // Ptype filters
          _buildFilterRow(
            label: '类型',
            items: ptypeMapping.allZh.map((zh) {
              final value = ptypeMapping.getValue(zh);
              return FilterItem(label: zh, value: value);
            }).toList(),
            selectedValue: _selectedPtype,
            onChanged: (value) => setState(() => _selectedPtype = value),
          ),
          const SizedBox(height: 8),

          // Sort options
          _buildSortRow(),
        ],
      ),
    );
  }

  Widget _buildFilterRow({
    required String label,
    required List<FilterItem> items,
    required int? selectedValue,
    required ValueChanged<int?> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _FilterChip(
                label: '全部',
                isSelected: selectedValue == null,
                onTap: () => onChanged(null),
              ),
              ...items.map((item) => _FilterChip(
                label: item.label,
                isSelected: selectedValue == item.value,
                onTap: () => onChanged(item.value),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortRow() {
    final sortOptions = [
      {'key': 'last_update', 'label': '更新时间'},
      {'key': 'click_num', 'label': '点击量'},
      {'key': 'word_num', 'label': '字数'},
      {'key': 'like_num', 'label': '收藏'},
      {'key': 'praise_num', 'label': '点赞'},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 40,
          child: Text(
            '排序',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sortOptions.map((option) {
              final key = option['key']!;
              final label = option['label']!;
              return _FilterChip(
                label: label,
                isSelected: _sortBy == key,
                onTap: () {
                  setState(() {
                    if (_sortBy == key) {
                      _descending = !_descending;
                    } else {
                      _sortBy = key;
                      _descending = true;
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNovelGrid(List<Novel> novels) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 4 columns on mobile (matching web: grid-cols-4)
        final crossAxisCount = 4;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.55, // Adjusted for 4:5 cover + title
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
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
}

class FilterItem {
  final String label;
  final int value;

  const FilterItem({required this.label, required this.value});
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
      ),
    );
  }
}

@riverpod
Future<List<Novel>> filteredNovels(
  FilteredNovelsRef ref, {
  int? genre,
  int? status,
  int? ptype,
  String sortBy = 'last_update',
  bool descending = true,
}) async {
  final db = ref.watch(databaseProvider);
  // TODO: Apply genre/status/ptype filters in query
  return db.getNovelsSorted(
    sortBy,
    descending: descending,
    limit: 100,
  );
}
