import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/database.dart';
import '../services/sync_service.dart';

part 'providers.g.dart';

/// Singleton database provider.
@riverpod
AppDatabase database(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

/// Dio provider.
@riverpod
Dio dio(Ref ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );
}

/// Sync service provider.
@riverpod
SyncService syncService(Ref ref) {
  final db = ref.watch(databaseProvider);
  final dio = ref.watch(dioProvider);
  return SyncService(db, dio);
}

/// Check for updates.
@riverpod
Future<ReleaseInfo?> checkUpdate(CheckUpdateRef ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.checkForUpdate();
}

/// Last sync info.
@riverpod
Future<SyncInfo?> lastSyncInfo(LastSyncInfoRef ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.getLastSyncInfo();
}

/// Novel count.
@riverpod
Future<int> novelCount(NovelCountRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelCount();
}

/// All novels with pagination.
@riverpod
Future<List<Novel>> novels(
  NovelsRef ref, {
  int limit = 50,
  int offset = 0,
}) async {
  final db = ref.watch(databaseProvider);
  return db.getAllNovels(limit: limit, offset: offset);
}

/// Novels by genre.
@riverpod
Future<List<Novel>> novelsByGenre(
  NovelsByGenreRef ref,
  int genre, {
  int limit = 50,
  int offset = 0,
}) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelsByGenre(genre, limit: limit, offset: offset);
}

/// Novels sorted by field.
@riverpod
Future<List<Novel>> novelsSorted(
  NovelsSortedRef ref,
  String field, {
  bool descending = true,
  int limit = 50,
  int offset = 0,
}) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelsSorted(
    field,
    descending: descending,
    limit: limit,
    offset: offset,
  );
}

/// Search novels.
@riverpod
Future<List<Novel>> searchNovels(
  SearchNovelsRef ref,
  String keyword, {
  int limit = 50,
}) async {
  final db = ref.watch(databaseProvider);
  return db.searchNovels(keyword, limit: limit);
}

/// Single novel.
@riverpod
Future<Novel?> novel(NovelRef ref, int id) async {
  final db = ref.watch(databaseProvider);
  return db.getNovel(id);
}

/// Novel tags.
@riverpod
Future<List<Tag>> novelTags(NovelTagsRef ref, int novelId) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelTags(novelId);
}

/// Novel author.
@riverpod
Future<Author?> novelAuthor(NovelAuthorRef ref, int novelId) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelAuthor(novelId);
}

/// All authors.
@riverpod
Future<List<Author>> authors(AuthorsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllAuthors(limit: 10000);
}

/// Novel rankings (for each metric).
@riverpod
Future<Map<String, int>> novelRankings(
  NovelRankingsRef ref,
  int novelId,
) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelRankings(novelId);
}

/// Database statistics.
@riverpod
Future<Map<String, int>> statistics(StatisticsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getStatistics();
}
