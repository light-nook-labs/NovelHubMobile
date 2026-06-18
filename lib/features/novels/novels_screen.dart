import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/novel_rank_list.dart';
import '../../app/theme.dart';
import '../../app/settings_provider.dart';
import '../../shared/widgets/common_widgets.dart';

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

  List<Map<String, dynamic>> _getPtypeTabs() {
    // 其他 is always filtered in DB, so never show it
    return [
      {'label': '全部', 'value': null},
      {'label': '免费', 'value': 2},
      {'label': '签约', 'value': 3},
      {'label': 'VIP', 'value': 4},
    ];
  }

  void _ensureTabController() {
    if (_tabController != null) return;

    final ptypeTabs = _getPtypeTabs();

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
    final ptypeTabs = _getPtypeTabs();
    final index = _tabController?.index ?? 0;
    if (index < ptypeTabs.length) {
      return ptypeTabs[index]['value'] as int?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _ensureTabController();
    final ptypeTabs = _getPtypeTabs();

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
      body: NovelRankList(
        loadNovels: (offset, limit) async {
          final db = ref.read(databaseProvider);
          return db.getNovelsFiltered(
            genre: _selectedGenre,
            status: _selectedStatus,
            ptype: _selectedPtype,
            year: _selectedYear,
            minWordNum: _selectedMinWordNum,
            maxWordNum: _selectedMaxWordNum,
            sortBy: _sortBy,
            descending: _descending,
            limit: limit,
            offset: offset,
          );
        },
        showRank: false,
        valueLabel: '点击',
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    // Watch to ensure years are loaded before showing filter
    final availableYearsAsync = ref.watch(availableYearsProvider);
    final availableYears = availableYearsAsync.valueOrNull ?? [];
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
        availableYears: availableYears,
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
}
