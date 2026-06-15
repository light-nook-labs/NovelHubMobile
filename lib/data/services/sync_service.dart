import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'jsonl_parser.dart';
import '../models/database.dart';

/// GitHub release information.
class ReleaseInfo {
  final String tagName;
  final String name;
  final String body;
  final DateTime publishedAt;
  final String downloadUrl;

  const ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.downloadUrl,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final assets = json['assets'] as List<dynamic>;
    final releaseAsset = assets.firstWhere(
      (a) => a['name'] == 'release.tar.gz',
      orElse: () => null,
    );

    return ReleaseInfo(
      tagName: json['tag_name'] as String,
      name: json['name'] as String,
      body: json['body'] as String? ?? '',
      publishedAt: DateTime.parse(json['published_at'] as String),
      downloadUrl: releaseAsset?['browser_download_url'] as String? ?? '',
    );
  }
}

/// Service for syncing data from GitHub releases.
class SyncService {
  static const _owner = 'light-nook-labs';
  static const _repo = 'novel_hub';
  static const _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';
  static const _lastSyncKey = 'last_sync_version';
  static const _lastSyncTimeKey = 'last_sync_time';

  final Dio _dio;
  final AppDatabase _db;

  SyncService(this._db, this._dio);

  /// Check if a new release is available.
  Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get(
        _apiUrl,
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );

      final release = ReleaseInfo.fromJson(response.data);
      final prefs = await SharedPreferences.getInstance();
      final lastVersion = prefs.getString(_lastSyncKey);

      if (lastVersion == release.tagName) {
        return null; // Already up to date
      }

      return release;
    } catch (e) {
      return null;
    }
  }

  /// Download and sync data from a release.
  Future<SyncResult> syncFromRelease(
    ReleaseInfo release, {
    Function(double)? onProgress,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. Download tar.gz
      final tempDir = await getTemporaryDirectory();
      final archivePath = p.join(tempDir.path, 'release.tar.gz');

      await _dio.download(
        release.downloadUrl,
        archivePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total * 0.5); // 0-50% for download
          }
        },
      );

      // 2. Extract and parse JSONL files
      final archiveFile = File(archivePath);
      final bytes = archiveFile.readAsBytesSync();
      final archive = TarDecoder().decodeBytes(
        GZipDecoder().decodeBytes(bytes),
      );

      final jsonlFiles = archive
          .where((f) => f.name.endsWith('.jsonl'))
          .toList();
      if (jsonlFiles.isEmpty) {
        return SyncResult.error('No JSONL files found in archive');
      }

      // 3. Parse all novels
      final allNovels = <NovelData>[];
      for (var i = 0; i < jsonlFiles.length; i++) {
        final file = jsonlFiles[i];
        final content = String.fromCharCodes(file.content as List<int>);
        final novels = JsonlParser.parseContent(content);
        allNovels.addAll(novels);

        if (onProgress != null) {
          onProgress(0.5 + (i / jsonlFiles.length) * 0.3); // 50-80% for parsing
        }
      }

      // 4. Clear existing data and insert new
      await _db.clearAll();

      // 5. Extract unique entities
      final authorNames = allNovels
          .map((n) => n.author)
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();
      final tagNames = allNovels.expand((n) => n.tags).toSet().toList();
      final contestNames = allNovels
          .map((n) => n.contest)
          .where((n) => n != null)
          .cast<String>()
          .toSet()
          .toList();

      // 6. Create authors, tags, contests
      final authorMap = await _db.createAuthorsBatch(authorNames);
      final tagMap = await _db.createTagsBatch(tagNames);

      final contestMap = <String, int>{};
      for (final name in contestNames) {
        final id = await _db.getOrCreateContest(name);
        if (id != null) contestMap[name] = id;
      }

      // 7. Upsert novels in batches
      const batchSize = 500;
      final novelTagPairs = <NovelTagPair>[];

      for (var i = 0; i < allNovels.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, allNovels.length);
        final batch = allNovels.sublist(i, end);

        final companions = batch.map((novel) {
          final authorId = authorMap[novel.author];
          final contestId = novel.contest != null
              ? contestMap[novel.contest]
              : null;
          return JsonlParser.toCompanion(novel, authorId, contestId);
        }).toList();

        await _db.upsertNovelsBatch(companions);

        // Collect tag pairs
        for (final novel in batch) {
          for (final tagName in novel.tags) {
            final tagId = tagMap[tagName];
            if (tagId != null) {
              novelTagPairs.add(NovelTagPair(novelId: novel.nid, tagId: tagId));
            }
          }
        }

        if (onProgress != null) {
          onProgress(
            0.8 + (end / allNovels.length) * 0.15,
          ); // 80-95% for insertion
        }
      }

      // 8. Insert novel-tag relationships
      await _db.addNovelTagsBatch(novelTagPairs);

      // 9. Save sync state
      await prefs.setString(_lastSyncKey, release.tagName);
      await prefs.setString(_lastSyncTimeKey, DateTime.now().toIso8601String());

      // 10. Cleanup
      await archiveFile.delete();

      if (onProgress != null) {
        onProgress(1.0);
      }

      return SyncResult.success(
        version: release.tagName,
        novelCount: allNovels.length,
        authorCount: authorNames.length,
        tagCount: tagNames.length,
      );
    } catch (e) {
      return SyncResult.error(e.toString());
    }
  }

  /// Load data from a local release.tar.gz file (for testing).
  Future<SyncResult> loadFromLocalFile(String filePath,
      {Function(double)? onProgress}) async {
    try {
      final archiveFile = File(filePath);
      if (!archiveFile.existsSync()) {
        return SyncResult.error('File not found: $filePath');
      }

      // 1. Read and extract archive
      final bytes = archiveFile.readAsBytesSync();
      final archive = TarDecoder().decodeBytes(
        GZipDecoder().decodeBytes(bytes),
      );

      final jsonlFiles = archive
          .where((f) => f.name.endsWith('.jsonl'))
          .toList();
      if (jsonlFiles.isEmpty) {
        return SyncResult.error('No JSONL files found in archive');
      }

      // 2. Parse all novels
      final allNovels = <NovelData>[];
      for (var i = 0; i < jsonlFiles.length; i++) {
        final file = jsonlFiles[i];
        final content = String.fromCharCodes(file.content as List<int>);
        final novels = JsonlParser.parseContent(content);
        allNovels.addAll(novels);

        if (onProgress != null) {
          onProgress((i / jsonlFiles.length) * 0.5);
        }
      }

      // 3. Clear existing data and insert new
      await _db.clearAll();

      // 4. Extract unique entities
      final authorNames = allNovels
          .map((n) => n.author)
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();
      final tagNames = allNovels.expand((n) => n.tags).toSet().toList();
      final contestNames = allNovels
          .map((n) => n.contest)
          .where((n) => n != null)
          .cast<String>()
          .toSet()
          .toList();

      // 5. Create authors, tags, contests
      final authorMap = await _db.createAuthorsBatch(authorNames);
      final tagMap = await _db.createTagsBatch(tagNames);

      final contestMap = <String, int>{};
      for (final name in contestNames) {
        final id = await _db.getOrCreateContest(name);
        if (id != null) contestMap[name] = id;
      }

      // 6. Upsert novels in batches
      const batchSize = 500;
      final novelTagPairs = <NovelTagPair>[];

      for (var i = 0; i < allNovels.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, allNovels.length);
        final batch = allNovels.sublist(i, end);

        final companions = batch.map((novel) {
          final authorId = authorMap[novel.author];
          final contestId =
              novel.contest != null ? contestMap[novel.contest] : null;
          return JsonlParser.toCompanion(novel, authorId, contestId);
        }).toList();

        await _db.upsertNovelsBatch(companions);

        for (final novel in batch) {
          for (final tagName in novel.tags) {
            final tagId = tagMap[tagName];
            if (tagId != null) {
              novelTagPairs.add(
                NovelTagPair(novelId: novel.nid, tagId: tagId),
              );
            }
          }
        }

        if (onProgress != null) {
          onProgress(0.5 + (end / allNovels.length) * 0.4);
        }
      }

      // 7. Insert novel-tag relationships
      await _db.addNovelTagsBatch(novelTagPairs);

      // 8. Save sync state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, 'local-test');
      await prefs.setString(
          _lastSyncTimeKey, DateTime.now().toIso8601String());

      if (onProgress != null) {
        onProgress(1.0);
      }

      return SyncResult.success(
        version: 'local-test',
        novelCount: allNovels.length,
        authorCount: authorNames.length,
        tagCount: tagNames.length,
      );
    } catch (e) {
      return SyncResult.error(e.toString());
    }
  }

  /// Get last sync info.
  Future<SyncInfo?> getLastSyncInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString(_lastSyncKey);
    final timeStr = prefs.getString(_lastSyncTimeKey);

    if (version == null) return null;

    return SyncInfo(
      version: version,
      syncedAt: timeStr != null ? DateTime.tryParse(timeStr) : null,
    );
  }
}

class SyncResult {
  final bool success;
  final String? error;
  final String? version;
  final int? novelCount;
  final int? authorCount;
  final int? tagCount;

  const SyncResult({
    required this.success,
    this.error,
    this.version,
    this.novelCount,
    this.authorCount,
    this.tagCount,
  });

  factory SyncResult.success({
    required String version,
    required int novelCount,
    required int authorCount,
    required int tagCount,
  }) => SyncResult(
    success: true,
    version: version,
    novelCount: novelCount,
    authorCount: authorCount,
    tagCount: tagCount,
  );

  factory SyncResult.error(String error) =>
      SyncResult(success: false, error: error);
}

class SyncInfo {
  final String version;
  final DateTime? syncedAt;

  const SyncInfo({required this.version, this.syncedAt});
}
