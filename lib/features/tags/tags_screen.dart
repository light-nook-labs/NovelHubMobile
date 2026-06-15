import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/providers.dart';
import '../../data/models/database.dart';
import '../../app/theme.dart';

part 'tags_screen.g.dart';

class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('标签')),
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (tags) {
          if (tags.isEmpty) {
            return const Center(child: Text('暂无数据'));
          }
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                return ActionChip(
                  label: Text(tag.name),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  onPressed: () => context.push('/tag/${tag.id}'),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class TagDetailScreen extends ConsumerWidget {
  final int tagId;

  const TagDetailScreen({super.key, required this.tagId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagAsync = ref.watch(tagProvider(tagId));
    final novelsAsync = ref.watch(tagNovelsProvider(tagId));

    return Scaffold(
      appBar: AppBar(
        title: tagAsync.when(
          loading: () => const Text('标签'),
          error: (_, __) => const Text('标签'),
          data: (tag) => Text(tag?.name ?? '未知'),
        ),
      ),
      body: novelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (novels) {
          if (novels.isEmpty) {
            return const Center(child: Text('该标签暂无小说'));
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
                    '点击: ${_formatNumber(novel.clickNum ?? 0)}',
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
Future<List<Tag>> tags(TagsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllTags();
}

@riverpod
Future<Tag?> tag(TagRef ref, int id) async {
  final db = ref.watch(databaseProvider);
  return db.getTag(id);
}

@riverpod
Future<List<Novel>> tagNovels(TagNovelsRef ref, int tagId) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelsByTag(tagId);
}
