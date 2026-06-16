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
  final int? initialGenre;
  final int? initialStatus;
  final int? initialPtype;

  const NovelsScreen({
    super.key,
    this.initialGenre,
    this.initialStatus,
    this.initialPtype,
  });

  @override
  ConsumerState<NovelsScreen> createState() => _NovelsScreenState();
}

class _NovelsScreenState extends ConsumerState<NovelsScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedGenre;
  int? _selectedStatus;
  int? _selectedYear;
  String _sortBy = 'click_num';
  bool _descending = true;
  
  late TabController _tabController;
  
  static const _ptypeTabs = [
    {'label': '全部', 'value': null},
    {'label': '其他', 'value': 1},
    {'label': '免费', 'value': 2},
    {'label': '签约', 'value': 3},
    {'label': 'VIP', 'value': 4},
  ];

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.initialGenre;
    _selectedStatus = widget.initialStatus;
    
    // Set initial ptype tab
    int initialTabIndex = 0;
    if (widget.initialPtype != null) {
      final index = _ptypeTabs.indexWhere(
        (tab) => tab['value'] == widget.initialPtype,
      );
      if (index >= 0) initialTabIndex = index;
    }
    
    _tabController = TabController(
      length: _ptypeTabs.length,
      vsync: this,
      initialIndex: initialTabIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int? get _selectedPtype => _ptypeTabs[_tabController.index]['value'] as int?;

  @override
  Widget build(BuildContext context) {
    final novelsAsync = ref.watch(
      filteredNovelsProvider(
        genre: _selectedGenre,
        status: _selectedStatus,
        ptype: _selectedPtype,
        year: _selectedYear,
        sortBy: _sortBy,
        descending: _descending,
      ),
    );

    final hasFilters = _selectedGenre != null ||
        _selectedStatus != null ||
        _selectedYear != null;

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
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune,
              color: hasFilters ? AppColors.primary : null,
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: _ptypeTabs.map((tab) => Tab(text: tab['label'] as String)).toList(),
        ),
      ),
      body: novelsAsync.when(
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
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedGenre: _selectedGenre,
        selectedStatus: _selectedStatus,
        selectedYear: _selectedYear,
        sortBy: _sortBy,
        descending: _descending,
        onApply: (genre, status, year, sortBy, descending) {
          setState(() {
            _selectedGenre = genre;
            _selectedStatus = status;
            _selectedYear = year;
            _sortBy = sortBy;
            _descending = descending;
          });
        },
      ),
    );
  }

  Widget _buildNovelGrid(List<Novel> novels) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.55,
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
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final int? selectedGenre;
  final int? selectedStatus;
  final int? selectedYear;
  final String sortBy;
  final bool descending;
  final Function(int?, int?, int?, String, bool) onApply;

  const _FilterBottomSheet({
    required this.selectedGenre,
    required this.selectedStatus,
    required this.selectedYear,
    required this.sortBy,
    required this.descending,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late int? _genre;
  late int? _status;
  late int? _year;
  late String _sortBy;
  late bool _descending;

  static const _years = [2026, 2025, 2024, 2023, 2022, 2021, 2020];

  @override
  void initState() {
    super.initState();
    _genre = widget.selectedGenre;
    _status = widget.selectedStatus;
    _year = widget.selectedYear;
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _genre = null;
                        _status = null;
                        _year = null;
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
                    options: genreMapping.allZh.map((zh) {
                      final value = genreMapping.getValue(zh);
                      return _Option(label: zh, value: value);
                    }).toList(),
                    selectedValue: _genre,
                    onChanged: (v) => setState(() => _genre = v),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: '状态',
                    options: statusMapping.allZh.map((zh) {
                      final value = statusMapping.getValue(zh);
                      return _Option(label: zh, value: value);
                    }).toList(),
                    selectedValue: _status,
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: '更新年份',
                    options: _years
                        .map((y) => _Option(label: '$y年', value: y))
                        .toList(),
                    selectedValue: _year,
                    onChanged: (v) => setState(() => _year = v),
                  ),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip(
              label: '全部',
              isSelected: selectedValue == null,
              onTap: () => onChanged(null),
            ),
            ...options.map((option) => _buildChip(
              label: option.label,
              isSelected: selectedValue == option.value,
              onTap: () => onChanged(option.value),
            )),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
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
            return _buildChip(
              label: label,
              isSelected: _sortBy == key,
              onTap: () => setState(() => _sortBy = key),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
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

class _Option {
  final String label;
  final int value;

  const _Option({required this.label, required this.value});
}

@riverpod
Future<List<Novel>> filteredNovels(
  FilteredNovelsRef ref, {
  int? genre,
  int? status,
  int? ptype,
  int? year,
  String sortBy = 'click_num',
  bool descending = true,
}) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelsFiltered(
    genre: genre,
    status: status,
    ptype: ptype,
    year: year,
    sortBy: sortBy,
    descending: descending,
    limit: 100,
  );
}
