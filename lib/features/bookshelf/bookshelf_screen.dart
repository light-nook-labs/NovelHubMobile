import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/database.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/novel_rank_list.dart';
import 'bookshelf_provider.dart';

class BookshelfScreen extends ConsumerWidget {
  const BookshelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novelsAsync = ref.watch(bookshelfNovelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('书架'),
      ),
      body: novelsAsync.when(
        loading: () => const LoadingState(message: '加载书架...'),
        error: (err, stack) => EmptyState(
          icon: Icons.error_outline,
          message: '加载失败',
          subtitle: err.toString(),
        ),
        data: (novels) {
          if (novels.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_border,
              message: '书架为空',
              subtitle: '在小说详情页点击收藏按钮添加到书架',
            );
          }
          return _BookshelfList(novels: novels);
        },
      ),
    );
  }
}

class _BookshelfList extends ConsumerStatefulWidget {
  final List<Novel> novels;

  const _BookshelfList({required this.novels});

  @override
  ConsumerState<_BookshelfList> createState() => _BookshelfListState();
}

class _BookshelfListState extends ConsumerState<_BookshelfList> {
  final _scrollController = ScrollController();
  bool _showBackToTop = false;

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
    final shouldShow = _scrollController.offset > 500;
    if (shouldShow != _showBackToTop) {
      setState(() => _showBackToTop = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          itemCount: widget.novels.length,
          itemBuilder: (context, index) {
            final novel = widget.novels[index];
            return Dismissible(
              key: ValueKey(novel.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('移除确认'),
                    content: Text('确定将"${novel.title}"从书架移除？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('移除'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) {
                ref.read(bookshelfProvider.notifier).remove(novel.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已从书架移除: ${novel.title}')),
                );
              },
              child: NovelRankRow(
                novel: novel,
                rank: index + 1,
                showRank: false,
                valueLabel: '点击',
              ),
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
    );
  }
}
