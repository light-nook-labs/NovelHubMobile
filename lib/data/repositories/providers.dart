import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/database.dart';
import '../services/sync_service.dart';

part 'providers.g.dart';

/// Singleton database provider.
@Riverpod(keepAlive: true)
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

/// Last sync info - cached until manually invalidated.
@Riverpod(keepAlive: true)
Future<SyncInfo?> lastSyncInfo(LastSyncInfoRef ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.getLastSyncInfo();
}

/// Novel count - cached until manually invalidated.
@Riverpod(keepAlive: true)
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

/// Batch novel tags - for loading tags for multiple novels at once.
@riverpod
Future<Map<int, List<Tag>>> novelTagsBatch(
  NovelTagsBatchRef ref,
  List<int> novelIds,
) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelTagsBatch(novelIds);
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

/// All authors with stats - cached until manually invalidated.
@Riverpod(keepAlive: true)
Future<List<AuthorWithStats>> authorsWithStats(AuthorsWithStatsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAuthorsWithStats(limit: 10000);
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

/// Database statistics - cached until manually invalidated.
/// This is the most expensive query, so we cache it heavily.
@Riverpod(keepAlive: true)
Future<Map<String, int>> statistics(StatisticsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getStatistics();
}

/// Banner novels - cached until manually invalidated.
@Riverpod(keepAlive: true)
Future<List<BannerNovel>> bannerNovels(BannerNovelsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getBannerNovels();
}

/// Database merge time - cached until manually invalidated.
@Riverpod(keepAlive: true)
Future<DateTime?> dbMergeTime(DbMergeTimeRef ref) async {
  return getDbMergeTime();
}

/// All tags with count - cached until manually invalidated.
@Riverpod(keepAlive: true)
Future<List<TagWithCount>> tagsWithCount(TagsWithCountRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getTagsWithCount(limit: 10000);
}

/// All contests with count - cached until manually invalidated.
@Riverpod(keepAlive: true)
Future<List<ContestWithCount>> contestsWithCount(ContestsWithCountRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getContestsWithCount(limit: 10000);
}

/// Genre counts - cached until manually invalidated.
@Riverpod(keepAlive: true)
Future<Map<int, int>> genreCounts(GenreCountsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getGenreCounts();
}

/// Status counts - cached until manually invalidated.
@Riverpod(keepAlive: true)
Future<Map<int, int>> statusCounts(StatusCountsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getStatusCounts();
}

/// Ptype counts - cached until manually invalidated.
@Riverpod(keepAlive: true)
Future<Map<int, int>> ptypeCounts(PtypeCountsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getPtypeCounts();
}

/// Available years from novels - cached until manually invalidated.
@Riverpod(keepAlive: true)
Future<List<int>> availableYears(AvailableYearsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAvailableYears();
}

/// Cached sorted novels for rankings.
/// First page (top 48) is cached for faster initial load.
@Riverpod(keepAlive: true)
Future<List<Novel>> topNovelsByField(
  TopNovelsByFieldRef ref,
  String field, {
  bool descending = true,
  int limit = 48,
}) async {
  final db = ref.watch(databaseProvider);
  return db.getNovelsSorted(
    field,
    descending: descending,
    limit: limit,
  );
}
