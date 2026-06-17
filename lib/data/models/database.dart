import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'dart:io';

part 'database.g.dart';

class Authors extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
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
  TextColumn get dbUpdate => text().nullable()();

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
  final int novelCount;
  final int bannerCount;

  AuthorWithStats({
    required this.id,
    required this.name,
    this.topNovelTitle,
    required this.novelCount,
    required this.bannerCount,
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
    // Get all authors
    final allAuthors = await select(authors).get();
    
    // Get novel counts for each author using a single query
    final novelCountQuery = selectOnly(novels)
      ..addColumns([novels.author, novels.id.count()])
      ..where(novels.author.isNotNull())
      ..groupBy([novels.author]);
    final novelCountResults = await novelCountQuery.get();
    
    final novelCountMap = <String, int>{};
    for (final row in novelCountResults) {
      final authorName = row.read(novels.author);
      if (authorName != null) {
        novelCountMap[authorName] = row.read(novels.id.count()) ?? 0;
      }
    }
    
    // Get top novel for each author (by click_num)
    final topNovelMap = <String, String>{};
    for (final author in allAuthors) {
      final topNovel = await (select(novels)
        ..where((t) => t.author.equals(author.name))
        ..orderBy([(t) => OrderingTerm.desc(t.clickNum)])
        ..limit(1)
      ).getSingleOrNull();
      if (topNovel != null) {
        topNovelMap[author.name] = topNovel.title;
      }
    }
    
    // Get banner counts
    final bannerCountQuery = selectOnly(novels)
      ..addColumns([novels.author, novels.id.count()])
      ..where(novels.author.isNotNull() & novels.hasBanner.equals(true))
      ..groupBy([novels.author]);
    final bannerCountResults = await bannerCountQuery.get();
    
    final bannerCountMap = <String, int>{};
    for (final row in bannerCountResults) {
      final authorName = row.read(novels.author);
      if (authorName != null) {
        bannerCountMap[authorName] = row.read(novels.id.count()) ?? 0;
      }
    }
    
    // Build results
    final results = allAuthors.map((author) {
      return AuthorWithStats(
        id: author.id,
        name: author.name,
        topNovelTitle: topNovelMap[author.name],
        novelCount: novelCountMap[author.name] ?? 0,
        bannerCount: bannerCountMap[author.name] ?? 0,
      );
    }).toList();
    
    // Sort by novel count (descending)
    results.sort((a, b) => b.novelCount.compareTo(a.novelCount));
    
    // Apply offset and limit
    final end = offset + limit;
    return results.sublist(
      offset,
      end > results.length ? results.length : end,
    );
  }

  // ===== Tag queries =====

  Future<List<Tag>> getAllTags({int limit = 100, int offset = 0}) async {
    final query = select(tags)
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit, offset: offset);
    return query.get();
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
    final query = select(contests)
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit, offset: offset);
    return query.get();
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
  }) async {
    final query = select(novels)
      ..where((t) => t.hasBanner.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.clickNum)])
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

    // Use COUNT(DISTINCT) instead of loading all values into memory
    final genreCountQuery = countAll();
    final genreQuery = selectOnly(novels)
      ..where(novels.genre.isBiggerThanValue(1))
      ..addColumns([genreCountQuery]);
    final genreResult = await genreQuery.getSingle();
    final genreCount = genreResult.read(genreCountQuery) ?? 0;

    final statusCountQuery = countAll();
    final statusQuery = selectOnly(novels)
      ..where(novels.status.isBiggerThanValue(1))
      ..addColumns([statusCountQuery]);
    final statusResult = await statusQuery.getSingle();
    final statusCount = statusResult.read(statusCountQuery) ?? 0;

    final ptypeCountQuery = countAll();
    final ptypeQuery = selectOnly(novels)
      ..where(novels.ptype.isBiggerThanValue(1))
      ..addColumns([ptypeCountQuery]);
    final ptypeResult = await ptypeQuery.getSingle();
    final ptypeCount = ptypeResult.read(ptypeCountQuery) ?? 0;

    return {
      'novels': novelCount,
      'authors': authorCount,
      'tags': tagCount,
      'contests': contestCount,
      'genres': genreCount,
      'statuses': statusCount,
      'ptypes': ptypeCount,
    };
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

  Future<Map<int, int>> getGenreCounts() async {
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
    return counts;
  }

  Future<Map<int, int>> getStatusCounts() async {
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
    return counts;
  }

  Future<Map<int, int>> getPtypeCounts() async {
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
  }
}

bool _dbInitialized = false;
const _dbVersionKey = 'novel_hub_db_version';
const _currentDbVersion = '1.0.0'; // Update this when bundled chunks change

/// Initialize the database from bundled chunks. Call this in main() before runApp().
/// Only copies and merges chunks on first launch or when version changes.
Future<void> initDatabase() async {
  if (_dbInitialized) return;
  
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dbFolder.path, 'novel_hub.sqlite');
  final chunksDir = p.join(dbFolder.path, 'chunks');
  final versionFile = File(p.join(dbFolder.path, _dbVersionKey));
  
  // Check if database already exists and version matches
  final dbFile = File(dbPath);
  final dbExists = await dbFile.exists();
  String? storedVersion;
  if (await versionFile.exists()) {
    storedVersion = await versionFile.readAsString();
  }
  
  // Only copy and merge if DB doesn't exist or version changed
  if (!dbExists || storedVersion != _currentDbVersion) {
    // Copy chunks from assets
    for (final chunkName in ['cold', 'warm', 'hot']) {
      await _copyBundledChunk(chunkName, p.join(chunksDir, '${chunkName}_chunk.sqlite'));
    }
    
    // Merge chunks into main database
    await _createMergedDatabase(dbPath);
    
    // Store version
    await versionFile.writeAsString(_currentDbVersion);
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
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'novel_hub.sqlite');
    final file = File(dbPath);
    
    // If DB doesn't exist (initDatabase wasn't called), create it now
    if (!await file.exists()) {
      await initDatabase();
    }
    
    return NativeDatabase.createInBackground(file);
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
    
    // Insert data from warm chunk (replace if exists - warm has newer data)
    db.execute('INSERT OR REPLACE INTO novels SELECT * FROM warm.novels');
    db.execute('INSERT OR REPLACE INTO authors SELECT * FROM warm.authors');
    db.execute('INSERT OR REPLACE INTO tags SELECT * FROM warm.tags');
    db.execute('INSERT OR REPLACE INTO contests SELECT * FROM warm.contests');
    db.execute('INSERT OR REPLACE INTO novel_tags SELECT * FROM warm.novel_tags');
    
    // Insert data from hot chunk (replace if exists - hot has newest data)
    db.execute('INSERT OR REPLACE INTO novels SELECT * FROM hot.novels');
    db.execute('INSERT OR REPLACE INTO authors SELECT * FROM hot.authors');
    db.execute('INSERT OR REPLACE INTO tags SELECT * FROM hot.tags');
    db.execute('INSERT OR REPLACE INTO contests SELECT * FROM hot.contests');
    db.execute('INSERT OR REPLACE INTO novel_tags SELECT * FROM hot.novel_tags');
    
    // Detach chunks
    db.execute("DETACH warm");
    db.execute("DETACH hot");
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
  
  // Load bundled chunk from assets
  final data = await rootBundle.load('assets/chunks/${chunkName}_chunk.sqlite');
  final bytes = data.buffer.asUint8List();

  // Write to target path
  final file = File(targetPath);
  await file.writeAsBytes(bytes, flush: true);
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
