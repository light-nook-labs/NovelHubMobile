import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/novel_rank_list.dart';
import '../../app/theme.dart';
import '../../app/settings_provider.dart';
import '../../shared/widgets/common_widgets.dart';

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
    with TickerProviderStateMixin {
  int? _selectedGenre;
  int? _selectedStatus;
  int? _selectedYear;
  int? _selectedMinWordNum;
  int? _selectedMaxWordNum;
  String _sortBy = 'click_num';
  bool _descending = true;

  TabController? _tabController;
  bool _lastHideOther = true;

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

  void _ensureTabController(bool hideOther) {
    if (_tabController != null && hideOther == _lastHideOther) return;

    final ptypeTabs = _getPtypeTabs(hideOther);

    int initialTabIndex = 0;
    if (widget.initialPtype != null) {
      final index = ptypeTabs.indexWhere(
        (tab) => tab['value'] == widget.initialPtype,
      );
      if (index >= 0) initialTabIndex = index;
    }

    _tabController?.dispose();
    _tabController = TabController(
      length: ptypeTabs.length,
      vsync: this,
      initialIndex: initialTabIndex,
    );
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        setState(() {});
      }
    });
    _lastHideOther = hideOther;
  }

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.initialGenre;
    _selectedStatus = widget.initialStatus;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  int? get _selectedPtype {
    final hideOther = ref.read(hideOtherNotifierProvider);
    final ptypeTabs = _getPtypeTabs(hideOther);
    final index = _tabController?.index ?? 0;
    if (index < ptypeTabs.length) {
      return ptypeTabs[index]['value'] as int?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hideOther = ref.watch(hideOtherNotifierProvider);
    _ensureTabController(hideOther);
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
        loading: () => const NovelGridShimmer(),
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
    final hideOther = ref.read(hideOtherNotifierProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NovelFilterBottomSheet(
        selectedGenre: _selectedGenre,
        selectedStatus: _selectedStatus,
        selectedYear: _selectedYear,
        selectedMinWordNum: _selectedMinWordNum,
        selectedMaxWordNum: _selectedMaxWordNum,
        sortBy: _sortBy,
        descending: _descending,
        hideOther: hideOther,
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
    limit: 48,
  );
}
