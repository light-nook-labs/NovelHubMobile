import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/novel_card.dart';
import '../../shared/utils/mappings.dart';
import '../../app/theme.dart';
import '../../app/settings_provider.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/utils/spacing.dart';

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
  int? _selectedMinWordNum;
  int? _selectedMaxWordNum;
  String _sortBy = 'click_num';
  bool _descending = true;

  late TabController _tabController;

  List<Map<String, dynamic>> _getPtypeTabs(bool hideOther) {
    final tabs = [
      {'label': '全部', 'value': null},
      {'label': '免费', 'value': 2},
      {'label': '签约', 'value': 3},
      {'label': 'VIP', 'value': 4},
    ];
    if (!hideOther) {
      tabs.add({'label': '其他', 'value': 1});
    }
    return tabs;
  }

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.initialGenre;
    _selectedStatus = widget.initialStatus;

    // Tab controller will be initialized in build with correct tab count
    _tabController = TabController(
      length: 5, // Will be updated in didChangeDependencies
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hideOther = ref.read(hideOtherNotifierProvider);
    final ptypeTabs = _getPtypeTabs(hideOther);

    // Set initial ptype tab
    int initialTabIndex = 0;
    if (widget.initialPtype != null) {
      final index = ptypeTabs.indexWhere(
        (tab) => tab['value'] == widget.initialPtype,
      );
      if (index >= 0) initialTabIndex = index;
    }

    _tabController.dispose();
    _tabController = TabController(
      length: ptypeTabs.length,
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

  int? get _selectedPtype {
    final hideOther = ref.read(hideOtherNotifierProvider);
    final ptypeTabs = _getPtypeTabs(hideOther);
    if (_tabController.index < ptypeTabs.length) {
      return ptypeTabs[_tabController.index]['value'] as int?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hideOther = ref.watch(hideOtherNotifierProvider);
    final ptypeTabs = _getPtypeTabs(hideOther);

    final novelsAsync = ref.watch(
      filteredNovelsProvider(
        genre: _selectedGenre,
        status: _selectedStatus,
        ptype: _selectedPtype,
        year: _selectedYear,
        minWordNum: _selectedMinWordNum,
        maxWordNum: _selectedMaxWordNum,
        sortBy: _sortBy,
        descending: _descending,
      ),
    );

    final hasFilters =
        _selectedGenre != null ||
        _selectedStatus != null ||
        _selectedYear != null ||
        _selectedMinWordNum != null ||
        _selectedMaxWordNum != null;

    return Scaffold(
      appBar: AppBar(
        title: const SearchBarWidget(),
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
          tabs: ptypeTabs.map((tab) {
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
            return const EmptyState(
              icon: Icons.book,
              message: '暂无数据',
              subtitle: '尝试调整筛选条件',
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
        selectedMinWordNum: _selectedMinWordNum,
        selectedMaxWordNum: _selectedMaxWordNum,
        sortBy: _sortBy,
        descending: _descending,
        onApply:
            (genre, status, year, minWordNum, maxWordNum, sortBy, descending) {
              setState(() {
                _selectedGenre = genre;
                _selectedStatus = status;
                _selectedYear = year;
                _selectedMinWordNum = minWordNum;
                _selectedMaxWordNum = maxWordNum;
                _sortBy = sortBy;
                _descending = descending;
              });
            },
      ),
    );
  }

  Widget _buildNovelGrid(List<Novel> novels) {
    return GridView.builder(
      padding: AppSpacing.paddingM,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.55,
        crossAxisSpacing: AppSpacing.gridSpacing,
        mainAxisSpacing: AppSpacing.gridSpacing,
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
  final int? selectedMinWordNum;
  final int? selectedMaxWordNum;
  final String sortBy;
  final bool descending;
  final Function(int?, int?, int?, int?, int?, String, bool) onApply;

  const _FilterBottomSheet({
    required this.selectedGenre,
    required this.selectedStatus,
    required this.selectedYear,
    required this.selectedMinWordNum,
    required this.selectedMaxWordNum,
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
  late int? _minWordNum;
  late int? _maxWordNum;
  late String _sortBy;
  late bool _descending;

  static const _years = [2026, 2025, 2024, 2023, 2022, 2021, 2020];
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
            _buildChip(
              label: '全部',
              isSelected: selectedValue == null,
              onTap: () => onChanged(null),
            ),
            ...options.map(
              (option) => _buildChip(
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

  Widget _buildWordNumSection() {
    // Build range options from breakpoints
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
            return _buildChip(
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

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChipWidget(label: label, isSelected: isSelected, onTap: onTap);
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
  int? minWordNum,
  int? maxWordNum,
  String sortBy = 'click_num',
  bool descending = true,
}) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelsFiltered(
    genre: genre,
    status: status,
    ptype: ptype,
    year: year,
    minWordNum: minWordNum,
    maxWordNum: maxWordNum,
    sortBy: sortBy,
    descending: descending,
    limit: 100,
  );
}
