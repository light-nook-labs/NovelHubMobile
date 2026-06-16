import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
  IntColumn get genre => integer().withDefault(const Constant(1))();
  IntColumn get status => integer().withDefault(const Constant(1))();
  IntColumn get ptype => integer().withDefault(const Constant(1))();
  IntColumn get authorId => integer().references(Authors, #id).nullable()();
  IntColumn get contestId => integer().references(Contests, #id).nullable()();
  BoolColumn get hasBanner => boolean().withDefault(const Constant(false))();
  IntColumn get wordNum => integer().nullable()();
  IntColumn get clickNum => integer().nullable()();
  IntColumn get praiseNum => integer().nullable()();
  IntColumn get likeNum => integer().nullable()();
  IntColumn get commentNum => integer().nullable()();
  IntColumn get reviewNum => integer().nullable()();
  TextColumn get cover => text().nullable()();
  DateTimeColumn get lastUpdate => dateTime().nullable()();
  DateTimeColumn get dbUpdate => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class NovelTags extends Table {
  IntColumn get novelId => integer().references(Novels, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {novelId, tagId};
}

class BannerNovel {
  final int id;
  final String title;
  final String author;

  BannerNovel({
    required this.id,
    required this.title,
    required this.author,
  });
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

@DriftDatabase(tables: [Authors, Tags, Contests, Novels, NovelTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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
    return into(tags).insert(
      TagsCompanion.insert(name: name),
      mode: InsertMode.insertOrIgnore,
    );
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
        pairs.map((p) => NovelTagsCompanion.insert(
              novelId: p.novelId,
              tagId: p.tagId,
            )),
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

  Future<List<Novel>> getNovelsByGenre(int genre,
      {int limit = 50, int offset = 0}) async {
    final query = select(novels)
      ..where((t) => t.genre.equals(genre))
      ..orderBy([(t) => OrderingTerm.desc(t.lastUpdate)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Future<List<Novel>> searchNovels(String keyword, {int limit = 50}) async {
    final query = select(novels)
      ..where((t) => t.title.like('%$keyword%'))
      ..limit(limit);
    return query.get();
  }

  Future<List<Novel>> getNovelsSorted(String field,
      {bool descending = true, int limit = 50, int offset = 0}) async {
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
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'word_num':
        query.orderBy([
          (t) => OrderingTerm(
              expression: t.wordNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'praise_num':
        query.orderBy([
          (t) => OrderingTerm(
              expression: t.praiseNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'like_num':
        query.orderBy([
          (t) => OrderingTerm(
              expression: t.likeNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'review_num':
        query.orderBy([
          (t) => OrderingTerm(
              expression: t.reviewNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'comment_num':
        query.orderBy([
          (t) => OrderingTerm(
              expression: t.commentNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
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
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year + 1, 1, 1);
      query.where((t) =>
          t.lastUpdate.isBiggerOrEqualValue(startDate) &
          t.lastUpdate.isSmallerThanValue(endDate));
    }

    switch (sortBy) {
      case 'click_num':
        query.orderBy([
          (t) => OrderingTerm(
              expression: t.clickNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'word_num':
        query.orderBy([
          (t) => OrderingTerm(
              expression: t.wordNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'praise_num':
        query.orderBy([
          (t) => OrderingTerm(
              expression: t.praiseNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'like_num':
        query.orderBy([
          (t) => OrderingTerm(
              expression: t.likeNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'review_num':
        query.orderBy([
          (t) => OrderingTerm(
              expression: t.reviewNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'comment_num':
        query.orderBy([
          (t) => OrderingTerm(
              expression: t.commentNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
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

  Future<Author?> getNovelAuthor(int novelId) async {
    final novel = await getNovel(novelId);
    if (novel == null || novel.authorId == null) return null;
    final query = select(authors)..where((t) => t.id.equals(novel.authorId!));
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

  Future<List<Novel>> getNovelsByAuthor(int authorId,
      {int limit = 50, int offset = 0}) async {
    final query = select(novels)
      ..where((t) => t.authorId.equals(authorId))
      ..orderBy([(t) => OrderingTerm.desc(t.lastUpdate)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Future<List<AuthorWithStats>> getAuthorsWithStats({int limit = 1000, int offset = 0}) async {
    // Get total clicks per author
    final authorClicks = <int, int>{};
    final authorClicksQuery = selectOnly(novels)
      ..where(novels.authorId.isNotNull())
      ..addColumns([novels.authorId, novels.clickNum.sum()])
      ..groupBy([novels.authorId]);
    final authorClicksResults = await authorClicksQuery.get();
    for (final row in authorClicksResults) {
      final authorId = row.read(novels.authorId);
      final totalClicks = row.read(novels.clickNum.sum()) ?? 0;
      if (authorId != null) {
        authorClicks[authorId] = totalClicks;
      }
    }

    // Get all authors and sort by total clicks
    final authorList = await select(authors).get();
    authorList.sort((a, b) {
      final clicksA = authorClicks[a.id] ?? 0;
      final clicksB = authorClicks[b.id] ?? 0;
      return clicksB.compareTo(clicksA); // Descending
    });

    // Apply offset and limit after sorting
    final end = offset + limit;
    final limitedAuthors = authorList.length > offset 
        ? authorList.sublist(offset, end > authorList.length ? authorList.length : end)
        : <Author>[];

    // Get novel counts per author
    final novelCounts = <int, int>{};
    final novelCountQuery = selectOnly(novels)
      ..where(novels.authorId.isNotNull())
      ..addColumns([novels.authorId, countAll()])
      ..groupBy([novels.authorId]);
    final novelCountResults = await novelCountQuery.get();
    for (final row in novelCountResults) {
      final authorId = row.read(novels.authorId);
      final count = row.read(countAll()) ?? 0;
      if (authorId != null) {
        novelCounts[authorId] = count;
      }
    }

    // Get banner counts per author
    final bannerCounts = <int, int>{};
    final bannerQuery = selectOnly(novels)
      ..where(novels.hasBanner.equals(true) & novels.authorId.isNotNull())
      ..addColumns([novels.authorId, countAll()])
      ..groupBy([novels.authorId]);
    final bannerResults = await bannerQuery.get();
    for (final row in bannerResults) {
      final authorId = row.read(novels.authorId);
      final count = row.read(countAll()) ?? 0;
      if (authorId != null) {
        bannerCounts[authorId] = count;
      }
    }

    // Get top novels (by click_num per author)
    final topNovels = <int, String>{};
    final allNovels = await (select(novels)
          ..where((t) => t.authorId.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.clickNum)]))
        .get();
    for (final novel in allNovels) {
      if (novel.authorId != null && !topNovels.containsKey(novel.authorId)) {
        topNovels[novel.authorId!] = novel.title;
      }
    }

    // Build result
    return limitedAuthors.map((author) {
      return AuthorWithStats(
        id: author.id,
        name: author.name,
        topNovelTitle: topNovels[author.id],
        novelCount: novelCounts[author.id] ?? 0,
        bannerCount: bannerCounts[author.id] ?? 0,
      );
    }).toList();
  }

  // ===== Tag queries =====

  Future<List<Tag>> getAllTags({int limit = 100, int offset = 0}) async {
    final query = select(tags)
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Future<Tag?> getTag(int id) async {
    final query = select(tags)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<Novel>> getNovelsByTag(int tagId,
      {int limit = 50, int offset = 0, String sortBy = 'click_num', bool descending = true}) async {
    final query = select(novelTags).join([
      innerJoin(novels, novels.id.equalsExp(novelTags.novelId)),
    ])
      ..where(novelTags.tagId.equals(tagId));

    switch (sortBy) {
      case 'click_num':
        query.orderBy([
          OrderingTerm(
              expression: novels.clickNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'word_num':
        query.orderBy([
          OrderingTerm(
              expression: novels.wordNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'like_num':
        query.orderBy([
          OrderingTerm(
              expression: novels.likeNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
        ]);
        break;
      case 'praise_num':
        query.orderBy([
          OrderingTerm(
              expression: novels.praiseNum,
              mode: descending ? OrderingMode.desc : OrderingMode.asc),
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

  Future<List<Contest>> getAllContests(
      {int limit = 100, int offset = 0}) async {
    final query = select(contests)
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Future<Contest?> getContest(int id) async {
    final query = select(contests)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<Novel>> getNovelsByContest(int contestId,
      {int limit = 50, int offset = 0}) async {
    final query = select(novels)
      ..where((t) => t.contestId.equals(contestId))
      ..orderBy([(t) => OrderingTerm.desc(t.lastUpdate)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  // ===== Banner novels =====

  Future<List<BannerNovel>> getBannerNovels({int limit = 12}) async {
    final query = select(novels).join([
      innerJoin(authors, authors.id.equalsExp(novels.authorId)),
    ])
      ..where(novels.hasBanner.equals(true))
      ..orderBy([OrderingTerm.desc(novels.clickNum)])
      ..limit(limit);

    final results = await query.get();
    return results.map((row) {
      return BannerNovel(
        id: row.readTable(novels).id,
        title: row.readTable(novels).title,
        author: row.readTable(authors).name,
      );
    }).toList();
  }

  Future<List<BannerNovel>> getBannerNovelsPaginated({
    required int offset,
    required int limit,
  }) async {
    final query = select(novels).join([
      innerJoin(authors, authors.id.equalsExp(novels.authorId)),
    ])
      ..where(novels.hasBanner.equals(true))
      ..orderBy([OrderingTerm.desc(novels.clickNum)])
      ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map((row) {
      return BannerNovel(
        id: row.readTable(novels).id,
        title: row.readTable(novels).title,
        author: row.readTable(authors).name,
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

    // Count distinct genres (excluding 其他=1)
    final genreQuery = selectOnly(novels)
      ..where(novels.genre.isBiggerThanValue(1))
      ..addColumns([novels.genre]);
    final genreResults = await genreQuery.get();
    final genreCount = genreResults.map((r) => r.read(novels.genre)).toSet().length;

    // Count distinct statuses (excluding 其他=1)
    final statusQuery = selectOnly(novels)
      ..where(novels.status.isBiggerThanValue(1))
      ..addColumns([novels.status]);
    final statusResults = await statusQuery.get();
    final statusCount = statusResults.map((r) => r.read(novels.status)).toSet().length;

    // Count distinct ptypes (excluding 其他=1)
    final ptypeQuery = selectOnly(novels)
      ..where(novels.ptype.isBiggerThanValue(1))
      ..addColumns([novels.ptype]);
    final ptypeResults = await ptypeQuery.get();
    final ptypeCount = ptypeResults.map((r) => r.read(novels.ptype)).toSet().length;

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
    final fields = [
      ('word_num', novels.wordNum),
      ('click_num', novels.clickNum),
      ('like_num', novels.likeNum),
      ('praise_num', novels.praiseNum),
      ('review_num', novels.reviewNum),
      ('comment_num', novels.commentNum),
    ];

    for (final (name, column) in fields) {
      final value = switch (name) {
        'word_num' => novel.wordNum,
        'click_num' => novel.clickNum,
        'like_num' => novel.likeNum,
        'praise_num' => novel.praiseNum,
        'review_num' => novel.reviewNum,
        'comment_num' => novel.commentNum,
        _ => null,
      };

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

  // ===== Reset to bundled database =====

  Future<void> resetToDefault() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'novel_hub.sqlite');
    
    // Delete existing database
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
    
    // Copy bundled database
    await _copyBundledDatabase(dbPath);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'novel_hub.sqlite');
    final file = File(dbPath);
    
    // If database doesn't exist, copy from bundled asset
    if (!await file.exists()) {
      await _copyBundledDatabase(dbPath);
    }
    
    return NativeDatabase.createInBackground(file);
  });
}

Future<void> _copyBundledDatabase(String targetPath) async {
  // Load bundled database from assets
  final data = await rootBundle.load('assets/db/novel_hub.sqlite');
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
