import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/providers.dart';
import '../../shared/utils/mappings.dart';
import '../../shared/widgets/common_widgets.dart';

class GenreListScreen extends ConsumerStatefulWidget {
  const GenreListScreen({super.key});

  @override
  ConsumerState<GenreListScreen> createState() => _GenreListScreenState();
}

class _GenreListScreenState extends ConsumerState<GenreListScreen> {
  Map<int, int> _counts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final db = ref.read(databaseProvider);
    final counts = await db.getGenreCounts();
    setState(() {
      _counts = counts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小说分类'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const LoadingState(message: '加载分类数据...')
          : ListView.builder(
              itemCount: genreMapping.allZh.length,
              itemBuilder: (context, index) {
                final zh = genreMapping.allZh[index];
                final value = genreMapping.getValue(zh);
                final count = _counts[value] ?? 0;
                return ListTile(
                  title: Text(zh),
                  subtitle: Text('$count 本'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/novels-by-genre?genre=$value'),
                );
              },
            ),
    );
  }
}

class StatusListScreen extends ConsumerStatefulWidget {
  const StatusListScreen({super.key});

  @override
  ConsumerState<StatusListScreen> createState() => _StatusListScreenState();
}

class _StatusListScreenState extends ConsumerState<StatusListScreen> {
  Map<int, int> _counts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final db = ref.read(databaseProvider);
    final counts = await db.getStatusCounts();
    setState(() {
      _counts = counts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('状态'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const LoadingState(message: '加载状态数据...')
          : ListView.builder(
              itemCount: statusMapping.allZh.length,
              itemBuilder: (context, index) {
                final zh = statusMapping.allZh[index];
                final value = statusMapping.getValue(zh);
                final count = _counts[value] ?? 0;
                return ListTile(
                  title: Text(zh),
                  subtitle: Text('$count 本'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/novels-by-status?status=$value'),
                );
              },
            ),
    );
  }
}

class PtypeListScreen extends ConsumerStatefulWidget {
  const PtypeListScreen({super.key});

  @override
  ConsumerState<PtypeListScreen> createState() => _PtypeListScreenState();
}

class _PtypeListScreenState extends ConsumerState<PtypeListScreen> {
  Map<int, int> _counts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final db = ref.read(databaseProvider);
    final counts = await db.getPtypeCounts();
    setState(() {
      _counts = counts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('类型'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const LoadingState(message: '加载类型数据...')
          : ListView.builder(
              itemCount: ptypeMapping.allZh.length,
              itemBuilder: (context, index) {
                final zh = ptypeMapping.allZh[index];
                final value = ptypeMapping.getValue(zh);
                final count = _counts[value] ?? 0;
                return ListTile(
                  title: Text(zh),
                  subtitle: Text('$count 本'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.go('/novels?ptype=$value');
                  },
                );
              },
            ),
    );
  }
}

class EnumListScreen extends StatefulWidget {
  final String title;
  final List<String> items;
  final Function(String) onTap;

  const EnumListScreen({
    super.key,
    required this.title,
    required this.items,
    required this.onTap,
  });

  @override
  State<EnumListScreen> createState() => _EnumListScreenState();
}

class _EnumListScreenState extends State<EnumListScreen> {
  final _scrollController = ScrollController();
  final _pageSize = 48;
  int _currentPage = 0;
  bool _hasMore = true;
  List<String> _items = [];
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
    setState(() {
      _showBackToTop = _scrollController.offset > 500;
    });

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore) {
      _loadMore();
    }
  }

  void _loadMore() {
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;

    setState(() {
      _currentPage++;
      _items.addAll(widget.items.sublist(
        startIndex,
        endIndex > widget.items.length ? widget.items.length : endIndex,
      ));
      _hasMore = endIndex < widget.items.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _items.isEmpty
          ? const Center(child: Text('暂无数据'))
          : Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      title: Text(item),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => widget.onTap(item),
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
            ),
    );
  }
}
