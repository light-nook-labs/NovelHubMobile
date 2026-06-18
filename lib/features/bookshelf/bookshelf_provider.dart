import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/database.dart';
import '../../data/repositories/providers.dart';

part 'bookshelf_provider.g.dart';

const _bookshelfKey = 'bookshelf_novel_ids';

@Riverpod(keepAlive: true)
class Bookshelf extends _$Bookshelf {
  @override
  Future<Set<int>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_bookshelfKey) ?? [];
    return ids.map((id) => int.parse(id)).toSet();
  }

  Future<void> toggle(int novelId) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();

    final newSet = Set<int>.from(current);
    if (newSet.contains(novelId)) {
      newSet.remove(novelId);
    } else {
      newSet.add(novelId);
    }

    await prefs.setStringList(
      _bookshelfKey,
      newSet.map((id) => id.toString()).toList(),
    );

    state = AsyncValue.data(newSet);
  }

  Future<void> remove(int novelId) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();

    final newSet = Set<int>.from(current)..remove(novelId);
    await prefs.setStringList(
      _bookshelfKey,
      newSet.map((id) => id.toString()).toList(),
    );

    state = AsyncValue.data(newSet);
  }

  bool contains(int novelId) {
    return state.valueOrNull?.contains(novelId) ?? false;
  }
}

@riverpod
Future<List<Novel>> bookshelfNovels(BookshelfNovelsRef ref) async {
  final bookshelfIds = await ref.watch(bookshelfProvider.future);
  if (bookshelfIds.isEmpty) return [];

  final db = ref.read(databaseProvider);
  final novels = <Novel>[];

  for (final id in bookshelfIds) {
    final novel = await db.getNovel(id);
    if (novel != null) {
      novels.add(novel);
    }
  }

  return novels;
}
