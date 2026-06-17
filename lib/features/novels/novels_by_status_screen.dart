import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/database.dart';
import '../../shared/widgets/novel_card.dart';
import '../../shared/widgets/novel_rank_list.dart';
import '../../shared/utils/mappings.dart';
import '../../app/theme.dart';
import '../../app/settings_provider.dart';
import 'novels_screen.dart';

class NovelsByStatusScreen extends ConsumerStatefulWidget {
  final int? initialStatus;

  const NovelsByStatusScreen({super.key, this.initialStatus});

  @override
  ConsumerState<NovelsByStatusScreen> createState() =>
      _NovelsByStatusScreenState();
}

class _NovelsByStatusScreenState extends ConsumerState<NovelsByStatusScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedGenre;
  int? _selectedYear;
  String _sortBy = 'click_num';
  bool _descending = true;

  late TabController _tabController;

  static const _statusTabs = [
    {'label': '全部', 'value': null},
    {'label': '已完结', 'value': 2},
    {'label': '连载中', 'value': 3},
    {'label': '断更', 'value': 4},
    {'label': '断更A', 'value': 5},
    {'label': '完结A', 'value': 6},
    {'label': '其他', 'value': 1},
  ];

  @override
  void initState() {
    super.initState();
    int initialTabIndex = 0;
    if (widget.initialStatus != null) {
      final index = _statusTabs.indexWhere(
        (tab) => tab['value'] == widget.initialStatus,
      );
      if (index >= 0) initialTabIndex = index;
    }

    _tabController = TabController(
      length: _statusTabs.length,
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

  int? get _selectedStatus =>
      _statusTabs[_tabController.index]['value'] as int?;

  @override
  Widget build(BuildContext context) {
    final novelsAsync = ref.watch(
      filteredNovelsProvider(
        genre: _selectedGenre,
        status: _selectedStatus,
        year: _selectedYear,
        sortBy: _sortBy,
        descending: _descending,
      ),
    );

    final hasFilters = _selectedGenre != null || _selectedYear != null;

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
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: _statusTabs.map((tab) {
            final isOther = tab['value'] == 1;
            return Tab(
              child: Text(
                tab['label'] as String,
                style: isOther
                    ? const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)
                    : null,
              ),
            );
          }).toList(),
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
    final hideOther = ref.read(hideOtherNotifierProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedGenre: _selectedGenre,
        selectedYear: _selectedYear,
        sortBy: _sortBy,
        descending: _descending,
        hideOther: hideOther,
        onApply: (genre, year, sortBy, descending) {
          setState(() {
            _selectedGenre = genre;
            _selectedYear = year;
            _sortBy = sortBy;
            _descending = descending;
          });
        },
      ),
    );
  }

  Widget _buildNovelGrid(List<Novel> novels) {
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

class _FilterBottomSheet extends StatefulWidget {
  final int? selectedGenre;
  final int? selectedYear;
  final String sortBy;
  final bool descending;
  final bool hideOther;
  final Function(int?, int?, String, bool) onApply;

  const _FilterBottomSheet({
    required this.selectedGenre,
    required this.selectedYear,
    required this.sortBy,
    required this.descending,
    required this.hideOther,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late int? _genre;
  late int? _year;
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

  List<int> get _years {
    final currentYear = DateTime.now().year;
    return List.generate(7, (i) => currentYear - i);
  }

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
