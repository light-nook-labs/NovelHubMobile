import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../app/theme.dart';

part 'authors_screen.g.dart';

class AuthorsScreen extends ConsumerWidget {
  const AuthorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorsAsync = ref.watch(authorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('作者'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: authorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (authors) {
          if (authors.isEmpty) {
            return const Center(child: Text('暂无数据'));
          }
          return ListView.builder(
            itemCount: authors.length,
            itemBuilder: (context, index) {
              final author = authors[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    author.name.isNotEmpty ? author.name[0] : '?',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
                title: Text(author.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/author/${author.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class AuthorDetailScreen extends ConsumerWidget {
  final int authorId;

  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorAsync = ref.watch(authorProvider(authorId));
    final novelsAsync = ref.watch(authorNovelsProvider(authorId));

    return Scaffold(
      appBar: AppBar(
        title: authorAsync.when(
          loading: () => const Text('作者详情'),
          error: (_, __) => const Text('作者详情'),
          data: (author) => Text(author?.name ?? '未知'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: novelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (novels) {
          if (novels.isEmpty) {
            return const Center(child: Text('该作者暂无作品'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: novels.length,
            itemBuilder: (context, index) {
              final novel = novels[index];
              return Card(
                child: ListTile(
                  title: Text(novel.title),
                  subtitle: Text(
                    '点击: ${_formatNumber(novel.clickNum ?? 0)} | 字数: ${_formatNumber(novel.wordNum ?? 0)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/novel/${novel.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 10000) return '${(num / 10000).toStringAsFixed(1)}万';
    return num.toString();
  }
}

@riverpod
Future<List<Author>> authors(AuthorsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllAuthors();
}

@riverpod
Future<Author?> author(AuthorRef ref, int id) async {
  final db = ref.watch(databaseProvider);
  return db.getAuthor(id);
}

@riverpod
Future<List<Novel>> authorNovels(AuthorNovelsRef ref, int authorId) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelsByAuthor(authorId);
}
