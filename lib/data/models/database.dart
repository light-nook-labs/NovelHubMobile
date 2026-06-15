import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
  IntColumn get id => integer()(); // nid from JSONL (sfacg novel id)
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

  @override
  List<Set<Column>> get uniqueKeys => [];
}

class NovelTags extends Table {
  IntColumn get novelId => integer().references(Novels, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {novelId, tagId};
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
    // Fetch existing authors for names that were ignored
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
    final query = select(novels)
      ..orderBy([(t) => OrderingTerm.desc(t.lastUpdate)])
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
      ..orderBy([(t) => OrderingTerm.desc(t.lastUpdate)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  Future<List<Novel>> getNovelsByStatus(
    int status, {
    int limit = 50,
    int offset = 0,
  }) async {
    final query = select(novels)
      ..where((t) => t.status.equals(status))
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

  Future<List<Novel>> getNovelsSorted(
    String field, {
    bool descending = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = select(novels);

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

    return {'novels': novelCount, 'authors': authorCount, 'tags': tagCount};
  }

  // ===== Clear all data =====

  Future<void> clearAll() async {
    await transaction(() async {
      await delete(novelTags).go();
      await delete(novels).go();
      await delete(authors).go();
      await delete(tags).go();
      await delete(contests).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'novel_hub.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

class NovelTagPair {
  final int novelId;
  final int tagId;

  const NovelTagPair({required this.novelId, required this.tagId});
}
