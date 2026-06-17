import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../services/chunked_sync_service.dart';

/// Database that merges multiple SQLite chunks using ATTACH
class MergedDatabase {
  final ChunkedSyncService _syncService;
  late DatabaseConnection _connection;

  MergedDatabase(this._syncService);

  /// Open the merged database
  Future<void> open() async {
    // Get chunk paths
    final coldPath = await _syncService.getChunkPath('cold');
    final warmPath = await _syncService.getChunkPath('warm');
    final hotPath = await _syncService.getChunkPath('hot');

    // Create a temporary database to use as the main connection
    final tempDir = await getTemporaryDirectory();
    final tempDbPath = p.join(tempDir.path, 'merged_temp.sqlite');

    // Open the main database
    _connection = DatabaseConnection(NativeDatabase(File(tempDbPath)));

    // Attach chunk databases
    await _attachChunks(coldPath, warmPath, hotPath);

    // Create merged views
    await _createMergedViews();
  }

  /// Attach chunk databases
  Future<void> _attachChunks(
    String coldPath,
    String warmPath,
    String hotPath,
  ) async {
    // Check if files exist and attach them
    if (await File(coldPath).exists()) {
      await _connection.runCustom("ATTACH '$coldPath' AS cold");
    }

    if (await File(warmPath).exists()) {
      await _connection.runCustom("ATTACH '$warmPath' AS warm");
    }

    if (await File(hotPath).exists()) {
      await _connection.runCustom("ATTACH '$hotPath' AS hot");
    }
  }

  /// Create merged views for querying
  Future<void> _createMergedViews() async {
    // Create a view that unions all novels from all chunks (use UNION to deduplicate)
    await _connection.runCustom('''
      CREATE VIEW IF NOT EXISTS merged_novels AS
      SELECT * FROM hot.novels
      UNION
      SELECT * FROM warm.novels
      UNION
      SELECT * FROM cold.novels
    ''');

    // Create a view for all tags
    await _connection.runCustom('''
      CREATE VIEW IF NOT EXISTS merged_tags AS
      SELECT * FROM hot.tags
      UNION
      SELECT * FROM warm.tags
      UNION
      SELECT * FROM cold.tags
    ''');

    // Create a view for all novel_tags
    await _connection.runCustom('''
      CREATE VIEW IF NOT EXISTS merged_novel_tags AS
      SELECT * FROM hot.novel_tags
      UNION
      SELECT * FROM warm.novel_tags
      UNION
      SELECT * FROM cold.novel_tags
    ''');

    // Create a view for all authors
    await _connection.runCustom('''
      CREATE VIEW IF NOT EXISTS merged_authors AS
      SELECT * FROM hot.authors
      UNION
      SELECT * FROM warm.authors
      UNION
      SELECT * FROM cold.authors
    ''');

    // Create a view for all contests
    await _connection.runCustom('''
      CREATE VIEW IF NOT EXISTS merged_contests AS
      SELECT * FROM hot.contests
      UNION
      SELECT * FROM warm.contests
      UNION
      SELECT * FROM cold.contests
    ''');
  }

  /// Execute a query on the merged database
  Future<QueryResult> executeQuery(String sql) async {
    final result = await _connection.runSelect(sql, []);
    return QueryResult(result);
  }

  /// Get all novels
  Future<List<NovelRow>> getNovels({
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    var sql = 'SELECT * FROM merged_novels';
    final params = <dynamic>[];

    if (orderBy != null) {
      // Whitelist allowed order by columns to prevent SQL injection
      final allowedColumns = [
        'click_num', 'word_num', 'like_num', 'praise_num',
        'review_num', 'comment_num', 'last_update', 'id', 'title'
      ];
      final parts = orderBy.split(' ');
      if (parts.isNotEmpty && allowedColumns.contains(parts[0])) {
        final direction = parts.length > 1 && parts[1].toUpperCase() == 'ASC' ? 'ASC' : 'DESC';
        sql += ' ORDER BY ${parts[0]} $direction';
      }
    }

    if (limit != null) {
      sql += ' LIMIT ?';
      params.add(limit);
    }

    if (offset != null) {
      sql += ' OFFSET ?';
      params.add(offset);
    }

    final result = await _connection.runSelect(sql, params);
    return result.map((row) => NovelRow.fromMap(row)).toList();
  }

  /// Get novels by status
  Future<List<NovelRow>> getNovelsByStatus(
    int status, {
    int? limit,
    int? offset,
  }) async {
    var sql = 'SELECT * FROM merged_novels WHERE status = ?';
    final params = <dynamic>[status];

    if (limit != null) {
      sql += ' LIMIT ?';
      params.add(limit);
    }

    if (offset != null) {
      sql += ' OFFSET ?';
      params.add(offset);
    }

    final result = await _connection.runSelect(sql, params);
    return result.map((row) => NovelRow.fromMap(row)).toList();
  }

  /// Get novel count
  Future<int> getNovelCount() async {
    final result = await _connection.runSelect(
      'SELECT COUNT(*) as count FROM merged_novels',
      [],
    );
    return result.first['count'] as int;
  }

  /// Get novel count by status
  Future<Map<int, int>> getNovelCountByStatus() async {
    final result = await _connection.runSelect(
      'SELECT status, COUNT(*) as count FROM merged_novels GROUP BY status',
      [],
    );

    final counts = <int, int>{};
    for (final row in result) {
      counts[row['status'] as int] = row['count'] as int;
    }
    return counts;
  }

  /// Close the database
  Future<void> close() async {
    await _connection.close();
  }
}

/// Query result wrapper
class QueryResult {
  final List<Map<String, dynamic>> rows;

  QueryResult(this.rows);

  int get length => rows.length;
  bool get isEmpty => rows.isEmpty;
  bool get isNotEmpty => rows.isNotEmpty;

  Map<String, dynamic> operator [](int index) => rows[index];
}

/// Novel row wrapper
class NovelRow {
  final int id;
  final String title;
  final String? author;
  final int genre;
  final int status;
  final int ptype;
  final bool hasBanner;
  final int? wordNum;
  final int? clickNum;
  final int? praiseNum;
  final int? likeNum;
  final int? commentNum;
  final int? reviewNum;
  final int? contestId;
  final String? cover;
  final String? lastUpdate;
  final String? dbUpdate;

  NovelRow({
    required this.id,
    required this.title,
    this.author,
    required this.genre,
    required this.status,
    required this.ptype,
    required this.hasBanner,
    this.wordNum,
    this.clickNum,
    this.praiseNum,
    this.likeNum,
    this.commentNum,
    this.reviewNum,
    this.contestId,
    this.cover,
    this.lastUpdate,
    required this.dbUpdate,
  });

  factory NovelRow.fromMap(Map<String, dynamic> map) {
    return NovelRow(
      id: map['id'] as int,
      title: map['title'] as String,
      author: map['author'] as String?,
      genre: map['genre'] as int,
      status: map['status'] as int,
      ptype: map['ptype'] as int,
      hasBanner: (map['has_banner'] as int? ?? 0) == 1,
      wordNum: map['word_num'] as int?,
      clickNum: map['click_num'] as int?,
      praiseNum: map['praise_num'] as int?,
      likeNum: map['like_num'] as int?,
      commentNum: map['comment_num'] as int?,
      reviewNum: map['review_num'] as int?,
      contestId: map['contest_id'] as int?,
      cover: map['cover'] as String?,
      lastUpdate: map['last_update'] as String?,
      dbUpdate: map['db_update'] as String?,
    );
  }
}
