import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/database.dart';
import '../../data/repositories/providers.dart';
import '../../shared/widgets/novel_card.dart';
import '../../app/theme.dart';

part 'banner_screen.g.dart';

class BannerScreen extends ConsumerStatefulWidget {
  const BannerScreen({super.key});

  @override
  ConsumerState<BannerScreen> createState() => _BannerScreenState();
}

class _BannerScreenState extends ConsumerState<BannerScreen> {
  final _scrollController = ScrollController();
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;
  List<Novel> _novels = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    final db = ref.read(databaseProvider);
    final newNovels = await db.getBannerNovelsPaginated(
      offset: _currentPage * _pageSize,
      limit: _pageSize,
    );

    setState(() {
      _currentPage++;
      _novels.addAll(newNovels);
      _hasMore = newNovels.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bannerCount = ref.watch(bannerCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: bannerCount.when(
          loading: () => const Text('推荐小说'),
          error: (_, __) => const Text('推荐小说'),
          data: (count) => Text('推荐小说 ($count)'),
        ),
      ),
      body: _novels.isEmpty && _isLoadingMore
          ? const Center(child: CircularProgressIndicator())
          : _novels.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book, size: 64, color: AppColors.primary),
                      SizedBox(height: 16),
                      Text('暂无推荐小说'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _currentPage = 0;
                      _novels = [];
                      _hasMore = true;
                    });
                    await _loadMore();
                  },
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _novels.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _novels.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return NovelCard(
                        novel: _novels[index],
                        onTap: () =>
                            context.push('/novel/${_novels[index].id}'),
                      );
                    },
                  ),
                ),
    );
  }
}

@riverpod
Future<int> bannerCount(BannerCountRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getBannerNovelCount();
}
