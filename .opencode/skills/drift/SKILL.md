# Drift (SQLite) Skill

## Setup

```dart
// data/database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

@DriftDatabase(tables: [Novels, Authors, Tags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'novel_hub.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

## Table Definition

```dart
class Novels extends Table {
  IntColumn get id => integer()();  // nid from JSONL
  TextColumn get title => text().withLength(min: 1, max: 500)();
  IntColumn get genre => integer().withDefault(const Constant(1))();
  IntColumn get status => integer().withDefault(const Constant(1))();
  IntColumn get ptype => integer().withDefault(const Constant(1))();
  IntColumn get authorId => integer().references(Authors, #id).nullable()();
  BoolColumn get has_banner => boolean().withDefault(const Constant(false))();
  IntColumn get word_num => integer().nullable()();
  IntColumn get click_num => integer().nullable()();
  IntColumn get praise_num => integer().nullable()();
  IntColumn get like_num => integer().nullable()();
  IntColumn get comment_num => integer().nullable()();
  IntColumn get review_num => integer().nullable()();
  TextColumn get cover => text().nullable()();
  DateTimeColumn get last_update => dateTime().nullable()();
  DateTimeColumn get db_update => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

## Queries

```dart
// Select
final novels = await (select(novels)
  ..where((t) => t.genre.equals(1))
  ..orderBy([(t) => OrderingTerm.desc(t.last_update)])
  ..limit(20))
  .get();

// Insert (upsert)
await into(novels).insertOnConflictUpdate(novelCompanion);

// Update
await (update(novels)..where((t) => t.id.equals(id)))
  .write(NovelsCompanion(title: Value('New Title')));

// Delete
await (delete(novels)..where((t) => t.id.equals(id))).go();

// Join
final query = select(novels).join([
  leftOuterJoin(authors, authors.id.equalsExp(novels.authorId)),
]);
```

## Code Generation

```bash
# Generate database code
dart run build_runner build --delete-conflicting-outputs

# Watch mode (recommended during development)
dart run build_runner watch
```

## Migrations

```dart
@override
int get schemaVersion => 2;  // Increment version

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(novels, novels.newColumn);
    }
  },
);
```

## Best Practices

- Always use `Value()` for nullable fields in Companions
- Use `insertOnConflictUpdate` for upserts
- Index columns used in WHERE/ORDER BY
- Use transactions for batch operations
