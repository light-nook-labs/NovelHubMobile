import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'dart:io';

import '../../shared/utils/mappings.dart';

part 'database.g.dart';

class Authors extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  IntColumn get topNovelId => integer().nullable()();
  TextColumn get topNovelTitle => text().nullable()();
  IntColumn get topNovelClicks => integer().withDefault(const Constant(0))();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
}

class Contests extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 300)();
}

class Novels extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get author => text().nullable()();
  IntColumn get genre => integer().withDefault(const Constant(1))();
  IntColumn get status => integer().withDefault(const Constant(1))();
  IntColumn get ptype => integer().withDefault(const Constant(1))();
  IntColumn get contestId => integer().nullable()();
  BoolColumn get hasBanner => boolean().withDefault(const Constant(false))();
  IntColumn get wordNum => integer().nullable()();
  IntColumn get clickNum => integer().nullable()();
  IntColumn get praiseNum => integer().nullable()();
  IntColumn get likeNum => integer().nullable()();
  IntColumn get commentNum => integer().nullable()();
  IntColumn get reviewNum => integer().nullable()();
  TextColumn get cover => text().nullable()();
  TextColumn get lastUpdate => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class NovelTags extends Table {
  IntColumn get novelId => integer()();
  IntColumn get tagId => integer()();

  @override
  Set<Column> get primaryKey => {novelId, tagId};
}

class BannerNovel {
  final int id;
  final String title;
  final String author;

  BannerNovel({required this.id, required this.title, required this.author});
}

class AuthorWithStats {
  final int id;
  final String name;
  final String? topNovelTitle;
  final int topNovelClicks;

  AuthorWithStats({
    required this.id,
    required this.name,
    this.topNovelTitle,
    required this.topNovelClicks,
  });
}

class TagWithCount {
  final int id;
  final String name;
  final int novelCount;

  TagWithCount({
    required this.id,
    required this.name,
    required this.novelCount,
  });
}

class ContestWithCount {
  final int id;
  final String name;
  final int novelCount;

  ContestWithCount({
    required this.id,
    required this.name,
    required this.novelCount,
  });
}

@DriftDatabase(tables: [Authors, Tags, Contests, Novels, NovelTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Cache for static data that only changes when DB is rebuilt
  List<int>? _cachedYears;
  Map<String, int>? _cachedStatistics;
  Map<int, int>? _cachedGenreCounts;
  Map<int, int>? _cachedStatusCounts;
  Map<int, int>? _cachedPtypeCounts;
  List<Tag>? _cachedAllTags;
  List<Contest>? _cachedAllContests;

  /// Clear all caches (call when DB is reset/rebuilt)
  void clearCaches() {
    _cachedYears = null;
    _cachedStatistics = null;
    _cachedGenreCounts = null;
    _cachedStatusCounts = null;
    _cachedPtypeCounts = null;
    _cachedAllTags = null;
    _cachedAllContests = null;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Create indexes for better query performance
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_novels_click_num ON novels(click_num)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_novels_genre ON novels(genre)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_novels_status ON novels(status)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_novels_ptype ON novels(ptype)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_novels_has_banner ON novels(has_banner)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_novels_author ON novels(author)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_novels_contest_id ON novels(contest_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_novel_tags_novel_id ON novel_tags(novel_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_novel_tags_tag_id ON novel_tags(tag_id)',
      );
    },
  );

  // ===== Author operations =====

  Future<int> createAuthor(String name) async {
    return into(authors).insert(
      AuthorsCompanion.insert(name: name),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<Map<String, int>> createAuthorsBatch(List<String> names) async {
    final map = <String, int>{};
    for (final name in names) {
      final id = await createAuthor(name);
      if (id > 0) {
        map[name] = id;
      }
    }
    for (final name in names) {
      if (!map.containsKey(name)) {
        final query = select(authors)..where((t) => t.name.equals(name));
        final result = await query.getSingleOrNull();
        if (result != null) {
          map[name] = result.id;
        }
      }
    }
    return map;
  }

  // ===== Tag operations =====

  Future<int> createTag(String name) async {
    return into(
      tags,
    ).insert(TagsCompanion.insert(name: name), mode: InsertMode.insertOrIgnore);
  }

  Future<Map<String, int>> createTagsBatch(List<String> names) async {
    final map = <String, int>{};
    for (final name in names) {
      final id = await createTag(name);
      if (id > 0) {
        map[name] = id;
      }
    }
    for (final name in names) {
      if (!map.containsKey(name)) {
        final query = select(tags)..where((t) => t.name.equals(name));
        final result = await query.getSingleOrNull();
        if (result != null) {
          map[name] = result.id;
        }
      }
    }
    return map;
  }

  // ===== Contest operations =====

  Future<int> createContest(String name) async {
    return into(contests).insert(
      ContestsCompanion.insert(name: name),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<int?> getOrCreateContest(String? name) async {
    if (name == null || name.isEmpty) return null;
    final query = select(contests)..where((t) => t.name.equals(name));
    final existing = await query.getSingleOrNull();
    if (existing != null) return existing.id;
    return into(contests).insert(ContestsCompanion.insert(name: name));
  }

  // ===== Novel operations =====

  Future<void> upsertNovel(NovelsCompanion novel) async {
    await into(novels).insertOnConflictUpdate(novel);
  }

  Future<void> upsertNovelsBatch(List<NovelsCompanion> novelList) async {
    await batch((batch) {
      batch.insertAll(novels, novelList, mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> addNovelTag(int novelId, int tagId) async {
    await into(novelTags).insert(
      NovelTagsCompanion.insert(novelId: novelId, tagId: tagId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> addNovelTagsBatch(List<NovelTagPair> pairs) async {
    await batch((batch) {
      batch.insertAll(
        novelTags,
        pairs.map(
          (p) => NovelTagsCompanion.insert(novelId: p.novelId, tagId: p.tagId),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  // ===== Query operations =====

  Future<List<Novel>> getAllNovels({int limit = 50, int offset = 0}) async {
    // Default sort: click_num desc (matching novel_hub web)
    final query = select(novels)
      ..orderBy([(t) => OrderingTerm.desc(t.clickNum)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Future<Novel?> getNovel(int id) async {
    final query = select(novels)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<Novel>> getNovelsByGenre(
    int genre, {
    int limit = 50,
    int offset = 0,
  }) async {
    final query = select(novels)
      ..where((t) => t.genre.equals(genre))
      ..orderBy([(t) => OrderingTerm.desc(t.clickNum)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Future<List<Novel>> searchNovels(String keyword, {int limit = 50}) async {
    final query = select(novels)
      ..where((t) => t.title.like('%$keyword%'))
      ..orderBy([(t) => OrderingTerm.desc(t.clickNum)])
      ..limit(limit);
    return query.get();
  }

  Future<List<Author>> searchAuthors(String keyword, {int limit = 20}) async {
    final query = select(authors)
      ..where((t) => t.name.like('%$keyword%') | t.topNovelTitle.like('%$keyword%'))
      ..orderBy([(t) => OrderingTerm.desc(t.topNovelClicks)])
      ..limit(limit);
    return query.get();
  }

  Future<List<Novel>> getNovelsSorted(
    String field, {
    bool descending = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = select(novels);

    // Filter out null and 0 values for the sorting field
    switch (field) {
      case 'click_num':
        query.where((t) => t.clickNum.isBiggerThanValue(0));
        break;
      case 'word_num':
        query.where((t) => t.wordNum.isBiggerThanValue(0));
        break;
      case 'praise_num':
        query.where((t) => t.praiseNum.isBiggerThanValue(0));
        break;
      case 'like_num':
        query.where((t) => t.likeNum.isBiggerThanValue(0));
        break;
      case 'review_num':
        query.where((t) => t.reviewNum.isBiggerThanValue(0));
        break;
      case 'comment_num':
        query.where((t) => t.commentNum.isBiggerThanValue(0));
        break;
    }

    switch (field) {
      case 'click_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.clickNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'word_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.wordNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'praise_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.praiseNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'like_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.likeNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'review_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.reviewNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'comment_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.commentNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      default:
        query.orderBy([(t) => OrderingTerm.desc(t.lastUpdate)]);
    }

    query.limit(limit, offset: offset);
    return query.get();
  }

  Future<List<Novel>> getNovelsFiltered({
    int? genre,
    int? status,
    int? ptype,
    int? year,
    int? minWordNum,
    int? maxWordNum,
    String sortBy = 'click_num',
    bool descending = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = select(novels);

    if (genre != null) {
      query.where((t) => t.genre.equals(genre));
    }
    if (status != null) {
      query.where((t) => t.status.equals(status));
    }
    if (ptype != null) {
      query.where((t) => t.ptype.equals(ptype));
    }
    if (year != null) {
      final startDate = DateTime(year, 1, 1).toIso8601String();
      final endDate = DateTime(year + 1, 1, 1).toIso8601String();
      query.where(
        (t) =>
            t.lastUpdate.isBiggerOrEqualValue(startDate) &
            t.lastUpdate.isSmallerThanValue(endDate),
      );
    }
    if (minWordNum != null) {
      query.where((t) => t.wordNum.isBiggerOrEqualValue(minWordNum));
    }
    if (maxWordNum != null) {
      query.where((t) => t.wordNum.isSmallerOrEqualValue(maxWordNum));
    }

    switch (sortBy) {
      case 'click_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.clickNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'word_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.wordNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'praise_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.praiseNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'like_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.likeNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'review_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.reviewNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'comment_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.commentNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      default:
        query.orderBy([(t) => OrderingTerm.desc(t.lastUpdate)]);
    }

    query.limit(limit, offset: offset);
    return query.get();
  }

  Future<int> getNovelCount() async {
    final count = countAll();
    final query = select(novels).addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<List<Tag>> getNovelTags(int novelId) async {
    final query = select(novelTags).join([
      innerJoin(tags, tags.id.equalsExp(novelTags.tagId)),
    ])..where(novelTags.novelId.equals(novelId));

    final results = await query.get();
    return results.map((row) => row.readTable(tags)).toList();
  }

  Future<Map<int, List<Tag>>> getNovelTagsBatch(List<int> novelIds) async {
    if (novelIds.isEmpty) return {};
    
    final query = select(novelTags).join([
      innerJoin(tags, tags.id.equalsExp(novelTags.tagId)),
    ])..where(novelTags.novelId.isIn(novelIds));

    final results = await query.get();
    final map = <int, List<Tag>>{};
    for (final row in results) {
      final novelId = row.readTable(novelTags).novelId;
      final tag = row.readTable(tags);
      map.putIfAbsent(novelId, () => []).add(tag);
    }
    return map;
  }

  Future<Author?> getNovelAuthor(int novelId) async {
    final novel = await getNovel(novelId);
    if (novel == null || novel.author == null || novel.author!.isEmpty) return null;
    // Look up author by name from novels.author
    final query = select(authors)..where((t) => t.name.equals(novel.author!));
    return query.getSingleOrNull();
  }

  // ===== Author queries =====

  Future<List<Author>> getAllAuthors({int limit = 100, int offset = 0}) async {
    final query = select(authors)
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Future<Author?> getAuthor(int id) async {
    final query = select(authors)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<Novel>> getNovelsByAuthor(
    int authorId, {
    int limit = 50,
    int offset = 0,
  }) async {
    // Get author name first
    final author = await getAuthor(authorId);
    if (author == null) return [];
    final query = select(novels)
      ..where((t) => t.author.equals(author.name))
      ..orderBy([(t) => OrderingTerm.desc(t.clickNum)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Future<List<AuthorWithStats>> getAuthorsWithStats({
    int limit = 1000,
    int offset = 0,
  }) async {
    // Use pre-computed stats from authors table
    final query = select(authors)
      ..orderBy([(t) => OrderingTerm.desc(t.topNovelClicks)])
      ..limit(limit, offset: offset);
    
    final results = await query.get();
    
    return results.map((author) {
      return AuthorWithStats(
        id: author.id,
        name: author.name,
        topNovelTitle: author.topNovelTitle,
        topNovelClicks: author.topNovelClicks,
      );
    }).toList();
  }

  // ===== Tag queries =====

  Future<List<Tag>> getAllTags({int limit = 100, int offset = 0}) async {
    // Only cache when using default parameters
    if (limit == 100 && offset == 0 && _cachedAllTags != null) {
      return _cachedAllTags!;
    }
    
    final query = select(tags)
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit, offset: offset);
    final result = await query.get();
    
    // Cache only default query
    if (limit == 100 && offset == 0) {
      _cachedAllTags = result;
    }
    return result;
  }

  Future<List<TagWithCount>> getTagsWithCount({
    int limit = 100,
    int offset = 0,
  }) async {
    final query =
        select(
            tags,
          ).join([innerJoin(novelTags, novelTags.tagId.equalsExp(tags.id))])
          ..addColumns([novelTags.novelId.count()])
          ..groupBy([tags.id])
          ..orderBy([OrderingTerm.desc(novelTags.novelId.count())])
          ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map((row) {
      return TagWithCount(
        id: row.readTable(tags).id,
        name: row.readTable(tags).name,
        novelCount: row.read(novelTags.novelId.count()) ?? 0,
      );
    }).toList();
  }

  Future<Tag?> getTag(int id) async {
    final query = select(tags)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<Novel>> getNovelsByTag(
    int tagId, {
    int limit = 50,
    int offset = 0,
    String sortBy = 'click_num',
    bool descending = true,
  }) async {
    final query = select(novelTags).join([
      innerJoin(novels, novels.id.equalsExp(novelTags.novelId)),
    ])..where(novelTags.tagId.equals(tagId));

    switch (sortBy) {
      case 'click_num':
        query.orderBy([
          OrderingTerm(
            expression: novels.clickNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'word_num':
        query.orderBy([
          OrderingTerm(
            expression: novels.wordNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'like_num':
        query.orderBy([
          OrderingTerm(
            expression: novels.likeNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'praise_num':
        query.orderBy([
          OrderingTerm(
            expression: novels.praiseNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      default:
        query.orderBy([OrderingTerm.desc(novels.lastUpdate)]);
    }

    query.limit(limit, offset: offset);
    final results = await query.get();
    return results.map((row) => row.readTable(novels)).toList();
  }

  // ===== Contest queries =====

  Future<List<Contest>> getAllContests({
    int limit = 100,
    int offset = 0,
  }) async {
    // Only cache when using default parameters
    if (limit == 100 && offset == 0 && _cachedAllContests != null) {
      return _cachedAllContests!;
    }
    
    final query = select(contests)
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit, offset: offset);
    final result = await query.get();
    
    // Cache only default query
    if (limit == 100 && offset == 0) {
      _cachedAllContests = result;
    }
    return result;
  }

  Future<List<ContestWithCount>> getContestsWithCount({
    int limit = 100,
    int offset = 0,
  }) async {
    final query =
        select(
            contests,
          ).join([innerJoin(novels, novels.contestId.equalsExp(contests.id))])
          ..addColumns([novels.id.count()])
          ..groupBy([contests.id])
          ..orderBy([OrderingTerm.desc(novels.id.count())])
          ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map((row) {
      return ContestWithCount(
        id: row.readTable(contests).id,
        name: row.readTable(contests).name,
        novelCount: row.read(novels.id.count()) ?? 0,
      );
    }).toList();
  }

  Future<Contest?> getContest(int id) async {
    final query = select(contests)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<Novel>> getNovelsByContest(
    int contestId, {
    int limit = 50,
    int offset = 0,
    String sortBy = 'click_num',
    bool descending = true,
  }) async {
    final query = select(novels)
      ..where((t) => t.contestId.equals(contestId));

    switch (sortBy) {
      case 'click_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.clickNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'word_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.wordNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'like_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.likeNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'praise_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.praiseNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'review_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.reviewNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      case 'comment_num':
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.commentNum,
            mode: descending ? OrderingMode.desc : OrderingMode.asc,
          ),
        ]);
        break;
      default:
        query.orderBy([(t) => OrderingTerm.desc(t.lastUpdate)]);
    }

    query.limit(limit, offset: offset);
    return query.get();
  }

  // ===== Banner novels =====

  Future<List<BannerNovel>> getBannerNovels({int limit = 12}) async {
    final query = select(novels)
      ..where((t) => t.hasBanner.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.clickNum)])
      ..limit(limit);

    final results = await query.get();
    return results.map((novel) {
      return BannerNovel(
        id: novel.id,
        title: novel.title,
        author: novel.author ?? '',
      );
    }).toList();
  }

  Future<List<BannerNovel>> getBannerNovelsPaginated({
    required int offset,
    required int limit,
    bool reverse = false,
  }) async {
    final query = select(novels)
      ..where((t) => t.hasBanner.equals(true))
      ..orderBy([(t) => reverse ? OrderingTerm.asc(t.clickNum) : OrderingTerm.desc(t.clickNum)])
      ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map((novel) {
      return BannerNovel(
        id: novel.id,
        title: novel.title,
        author: novel.author ?? '',
      );
    }).toList();
  }

  Future<int> getBannerNovelCount() async {
    final query = selectOnly(novels)
      ..where(novels.hasBanner.equals(true))
      ..addColumns([countAll()]);
    final result = await query.getSingle();
    return result.read(countAll()) ?? 0;
  }

  // ===== Statistics =====

  Future<Map<String, int>> getStatistics() async {
    // Return cached data if available
    if (_cachedStatistics != null) return _cachedStatistics!;
    
    final novelCount = await getNovelCount();

    final authorCountQuery = countAll();
    final authorQuery = select(authors).addColumns([authorCountQuery]);
    final authorResult = await authorQuery.getSingle();
    final authorCount = authorResult.read(authorCountQuery) ?? 0;

    final tagCountQuery = countAll();
    final tagQuery = select(tags).addColumns([tagCountQuery]);
    final tagResult = await tagQuery.getSingle();
    final tagCount = tagResult.read(tagCountQuery) ?? 0;

    final contestCountQuery = countAll();
    final contestQuery = select(contests).addColumns([contestCountQuery]);
    final contestResult = await contestQuery.getSingle();
    final contestCount = contestResult.read(contestCountQuery) ?? 0;

    final stats = {
      'novels': novelCount,
      'authors': authorCount,
      'tags': tagCount,
      'contests': contestCount,
      'genres': genreMapping.allZh.length,
      'statuses': statusMapping.allZh.length,
      'ptypes': ptypeMapping.allZh.length,
    };
    
    // Cache the result
    _cachedStatistics = stats;
    return stats;
  }

  // ===== Novel rankings =====

  Future<Map<String, int>> getNovelRankings(int novelId) async {
    final novel = await getNovel(novelId);
    if (novel == null) return {};

    final rankings = <String, int>{};
    
    // Single query to get all rankings at once
    // Count how many novels have higher values for each field
    final fields = [
      ('word_num', novels.wordNum, novel.wordNum),
      ('click_num', novels.clickNum, novel.clickNum),
      ('like_num', novels.likeNum, novel.likeNum),
      ('praise_num', novels.praiseNum, novel.praiseNum),
      ('review_num', novels.reviewNum, novel.reviewNum),
      ('comment_num', novels.commentNum, novel.commentNum),
    ];

    for (final (name, column, value) in fields) {
      if (value != null && value > 0) {
        final query = selectOnly(novels)
          ..where(column.isBiggerThanValue(value))
          ..addColumns([countAll()]);
        final result = await query.getSingle();
        final count = result.read(countAll()) ?? 0;
        rankings[name] = count + 1;
      }
    }

    return rankings;
  }

  // ===== Enum count queries =====

  Future<List<int>> getAvailableYears() async {
    // Return cached data if available
    if (_cachedYears != null) return _cachedYears!;
    
    // Use raw SQL to extract distinct years efficiently
    final result = await customSelect(
      "SELECT DISTINCT SUBSTR(last_update, 1, 4) as year FROM novels WHERE last_update IS NOT NULL ORDER BY year DESC",
      readsFrom: {novels},
    ).get();
    
    final years = <int>[];
    for (final row in result) {
      final yearStr = row.read<String>('year');
      final year = int.tryParse(yearStr);
      if (year != null) {
        years.add(year);
      }
    }
    
    // Cache the result
    _cachedYears = years;
    return years;
  }

  Future<Map<int, int>> getGenreCounts() async {
    // Return cached data if available
    if (_cachedGenreCounts != null) return _cachedGenreCounts!;
    
    final query = selectOnly(novels)
      ..addColumns([novels.genre, countAll()])
      ..groupBy([novels.genre]);
    final results = await query.get();
    final counts = <int, int>{};
    for (final row in results) {
      final genre = row.read(novels.genre)!;
      final count = row.read(countAll()) ?? 0;
      counts[genre] = count;
    }
    
    // Cache the result
    _cachedGenreCounts = counts;
    return counts;
  }

  Future<Map<int, int>> getStatusCounts() async {
    // Return cached data if available
    if (_cachedStatusCounts != null) return _cachedStatusCounts!;
    
    final query = selectOnly(novels)
      ..addColumns([novels.status, countAll()])
      ..groupBy([novels.status]);
    final results = await query.get();
    final counts = <int, int>{};
    for (final row in results) {
      final status = row.read(novels.status)!;
      final count = row.read(countAll()) ?? 0;
      counts[status] = count;
    }
    
    // Cache the result
    _cachedStatusCounts = counts;
    return counts;
  }

  Future<Map<int, int>> getPtypeCounts() async {
    // Return cached data if available
    if (_cachedPtypeCounts != null) return _cachedPtypeCounts!;
    
    final query = selectOnly(novels)
      ..addColumns([novels.ptype, countAll()])
      ..groupBy([novels.ptype]);
    final results = await query.get();
    final counts = <int, int>{};
    for (final row in results) {
      final ptype = row.read(novels.ptype)!;
      final count = row.read(countAll()) ?? 0;
      counts[ptype] = count;
    }
    
    // Cache the result
    _cachedPtypeCounts = counts;
    return counts;
  }

  // ===== Reset to bundled database =====

  Future<void> resetToDefault() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'novel_hub.sqlite');

    // Delete existing database
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }

    // 从assets重新复制chunk并合并
    final chunksDir = p.join(dbFolder.path, 'chunks');
    for (final chunkName in ['cold', 'warm', 'hot']) {
      await _copyBundledChunk(chunkName, p.join(chunksDir, '${chunkName}_chunk.sqlite'));
    }
    await _createMergedDatabase(dbPath);
    
    // Clear caches after reset
    clearCaches();
  }
}

bool _dbInitialized = false;
const _dbVersionKey = 'novel_hub_db_version';
const _currentDbVersion = '2.1.0'; // Update this when bundled chunks change

/// Initialize the database from bundled chunks. Call this in main() before runApp().
/// Only copies and merges chunks on first launch or when version changes.
Future<void> initDatabase() async {
  if (_dbInitialized) return;
  
  final dbFolder = await getApplicationDocumentsDirectory();
  final chunksDir = p.join(dbFolder.path, 'chunks');
  
  // Copy chunks from assets if needed
  for (final chunkName in ['cold', 'warm', 'hot']) {
    final chunkPath = p.join(chunksDir, '${chunkName}_chunk.sqlite');
    if (!await File(chunkPath).exists()) {
      await _copyBundledChunk(chunkName, chunkPath);
    }
  }
  
  _dbInitialized = true;
}

/// 获取数据库合并时间（基于merged数据库文件的修改时间）
Future<DateTime?> getDbMergeTime() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dbFolder.path, 'novel_hub.sqlite');
  final dbFile = File(dbPath);
  if (await dbFile.exists()) {
    final stat = await dbFile.stat();
    return stat.modified;
  }
  return null;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'novel_hub.sqlite');
      final chunksDir = p.join(dbFolder.path, 'chunks');
      final mergedMarkerPath = p.join(dbFolder.path, '.db_merged_v1');
      
      // Check if merged database already exists and is valid
      final dbExists = await File(dbPath).exists();
      final markerExists = await File(mergedMarkerPath).exists();
      
      if (dbExists && markerExists) {
        // Database already merged, use it directly
        return NativeDatabase.createInBackground(File(dbPath));
      }
      
      // First time: copy chunks and merge
      for (final chunkName in ['cold', 'warm', 'hot']) {
        final chunkPath = p.join(chunksDir, '${chunkName}_chunk.sqlite');
        await _copyBundledChunk(chunkName, chunkPath);
      }
      
      if (await File(dbPath).exists()) {
        await File(dbPath).delete();
      }
      await _createMergedDatabase(dbPath);
      
      // Create marker file to indicate merge is complete
      await File(mergedMarkerPath).writeAsString('1');
      
      return NativeDatabase.createInBackground(File(dbPath));
    } catch (e) {
      print('Error initializing database: $e');
      // Fallback: create empty database
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'novel_hub_fallback.sqlite');
      return NativeDatabase.createInBackground(File(dbPath));
    }
  });
}

Future<void> _createMergedDatabase(String targetPath) async {
  final chunksDir = p.join(File(targetPath).parent.path, 'chunks');
  
  // Copy chunks from assets if needed
  for (final chunkName in ['cold', 'warm', 'hot']) {
    final chunkPath = p.join(chunksDir, '${chunkName}_chunk.sqlite');
    if (!await File(chunkPath).exists()) {
      await _copyBundledChunk(chunkName, chunkPath);
    }
  }
  
  // Use cold chunk as base
  final coldPath = p.join(chunksDir, 'cold_chunk.sqlite');
  final warmPath = p.join(chunksDir, 'warm_chunk.sqlite');
  final hotPath = p.join(chunksDir, 'hot_chunk.sqlite');
  
  // Copy cold chunk as the main database
  await File(coldPath).copy(targetPath);
  
  // Open the database directly with sqlite3 and merge data
  final db = sqlite3.open(targetPath);
  
  try {
    // Enable WAL mode for better performance
    db.execute('PRAGMA journal_mode=WAL');
    
    // Attach warm and hot chunks
    db.execute("ATTACH '${warmPath}' AS warm");
    db.execute("ATTACH '${hotPath}' AS hot");
    
    // Begin transaction
    db.execute('BEGIN TRANSACTION');
    
    // Insert novels from warm and hot chunks (novels are unique by id)
    db.execute('INSERT OR REPLACE INTO novels SELECT * FROM warm.novels');
    db.execute('INSERT OR REPLACE INTO novels SELECT * FROM hot.novels');
    
    // Merge contests with name-based deduplication
    // Build contest name -> cold ID mapping
    final contestRows = db.select('SELECT name, id FROM contests');
    final contestNameToId = <String, int>{};
    for (final row in contestRows) {
      contestNameToId[row[0] as String] = row[1] as int;
    }
    
    // For each chunk, remap contest IDs in novels table
    for (final chunkAlias in ['warm', 'hot']) {
      // Get chunk's contest mapping
      final chunkContests = db.select('SELECT id, name FROM $chunkAlias.contests');
      final contestOldToNew = <int, int>{};
      
      for (final row in chunkContests) {
        final oldId = row[0] as int;
        final name = row[1] as String;
        
        if (contestNameToId.containsKey(name)) {
          contestOldToNew[oldId] = contestNameToId[name]!;
        } else {
          // New contest not in cold, insert it
          db.execute('INSERT OR IGNORE INTO contests (name) VALUES (?)', [name]);
          final newId = db.select('SELECT id FROM contests WHERE name = ?', [name])[0][0] as int;
          contestNameToId[name] = newId;
          contestOldToNew[oldId] = newId;
        }
      }
      
      // Update contest_id in novels from this chunk
      for (final entry in contestOldToNew.entries) {
        if (entry.key != entry.value) {
          db.execute(
            'UPDATE novels SET contest_id = ? WHERE contest_id = ? AND id IN (SELECT id FROM $chunkAlias.novels)',
            [entry.value, entry.key],
          );
        }
      }
    }
    
    // Merge tags with ID remapping
    // Build tag name -> cold ID mapping
    final tagRows = db.select('SELECT name, id FROM tags');
    final tagNameToId = <String, int>{};
    for (final row in tagRows) {
      tagNameToId[row[0] as String] = row[1] as int;
    }
    
    // For each chunk, remap tag IDs
    for (final chunkAlias in ['warm', 'hot']) {
      // Get chunk's tag mapping
      final chunkTags = db.select('SELECT id, name FROM $chunkAlias.tags');
      final oldToNew = <int, int>{};
      
      for (final row in chunkTags) {
        final oldId = row[0] as int;
        final name = row[1] as String;
        
        if (tagNameToId.containsKey(name)) {
          oldToNew[oldId] = tagNameToId[name]!;
        } else {
          // New tag not in cold, insert it
          db.execute('INSERT OR IGNORE INTO tags (name) VALUES (?)', [name]);
          final newId = db.select('SELECT id FROM tags WHERE name = ?', [name])[0][0] as int;
          tagNameToId[name] = newId;
          oldToNew[oldId] = newId;
        }
      }
      
      // Insert novel_tags with remapped tag IDs
      final chunkNovelTags = db.select(
        'SELECT novel_id, tag_id FROM $chunkAlias.novel_tags'
      );
      
      for (final row in chunkNovelTags) {
        final novelId = row[0] as int;
        final oldTagId = row[1] as int;
        final newTagId = oldToNew[oldTagId];
        
        if (newTagId != null) {
          db.execute(
            'INSERT OR IGNORE INTO novel_tags (novel_id, tag_id) VALUES (?, ?)',
            [novelId, newTagId],
          );
        }
      }
    }
    
    // Merge authors: update existing if better, insert new ones
    // Update existing authors if warm/hot has better stats
    db.execute('''
      UPDATE authors SET 
        top_novel_id = warm_authors.top_novel_id,
        top_novel_title = warm_authors.top_novel_title,
        top_novel_clicks = warm_authors.top_novel_clicks
      FROM warm.authors AS warm_authors
      WHERE authors.name = warm_authors.name 
        AND warm_authors.top_novel_clicks > authors.top_novel_clicks
    ''');
    db.execute('''
      UPDATE authors SET 
        top_novel_id = hot_authors.top_novel_id,
        top_novel_title = hot_authors.top_novel_title,
        top_novel_clicks = hot_authors.top_novel_clicks
      FROM hot.authors AS hot_authors
      WHERE authors.name = hot_authors.name 
        AND hot_authors.top_novel_clicks > authors.top_novel_clicks
    ''');
    
    // Insert new authors from warm and hot
    db.execute('''
      INSERT OR IGNORE INTO authors (name, top_novel_id, top_novel_title, top_novel_clicks)
      SELECT name, top_novel_id, top_novel_title, top_novel_clicks FROM warm.authors
    ''');
    db.execute('''
      INSERT OR IGNORE INTO authors (name, top_novel_id, top_novel_title, top_novel_clicks)
      SELECT name, top_novel_id, top_novel_title, top_novel_clicks FROM hot.authors
    ''');
    
    // Commit transaction
    db.execute('COMMIT');
    
    // Detach chunks
    db.execute("DETACH warm");
    db.execute("DETACH hot");
  } catch (e) {
    // Rollback on error
    try {
      db.execute('ROLLBACK');
    } catch (_) {}
    rethrow;
  } finally {
    db.dispose();
  }
}

Future<void> _copyBundledChunk(String chunkName, String targetPath) async {
  // Ensure directory exists
  final dir = File(targetPath).parent;
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  
  // Try loading compressed .gz file first (smaller app size)
  try {
    final gzData = await rootBundle.load('assets/chunks/${chunkName}_chunk.sqlite.gz');
    final compressedBytes = gzData.buffer.asUint8List();
    final decompressedBytes = gzip.decode(compressedBytes);
    final file = File(targetPath);
    await file.writeAsBytes(decompressedBytes, flush: true);
    return;
  } catch (_) {}
  
  // Fall back to uncompressed .sqlite file
  try {
    final data = await rootBundle.load('assets/chunks/${chunkName}_chunk.sqlite');
    final bytes = data.buffer.asUint8List();
    final file = File(targetPath);
    await file.writeAsBytes(bytes, flush: true);
    return;
  } catch (_) {}
  
  // If both fail, create empty database file
  print('Warning: Could not load chunk $chunkName from assets, creating empty file');
  final file = File(targetPath);
  if (!await file.exists()) {
    await file.create(recursive: true);
  }
}

class NovelTagPair {
  final int novelId;
  final int tagId;

  const NovelTagPair({required this.novelId, required this.tagId});
}

class _AuthorStats {
  String? topNovelTitle;
  int topNovelClicks;
  int totalClicks;
  int novelCount;
  int bannerCount;

  _AuthorStats({
    this.topNovelTitle,
    this.topNovelClicks = 0,
    this.totalClicks = 0,
    this.novelCount = 0,
    this.bannerCount = 0,
  });
}
