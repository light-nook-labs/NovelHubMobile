import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Chunk information
class ChunkInfo {
  final String name;
  final String description;
  final String downloadUrl;
  final int recordCount;
  final DateTime? lastUpdated;

  const ChunkInfo({
    required this.name,
    required this.description,
    required this.downloadUrl,
    this.recordCount = 0,
    this.lastUpdated,
  });
}

/// Sync status for each chunk
class ChunkSyncStatus {
  final String chunkName;
  final String? version;
  final DateTime? lastSynced;
  final bool isRequired;

  const ChunkSyncStatus({
    required this.chunkName,
    this.version,
    this.lastSynced,
    this.isRequired = false,
  });
}

/// Service for syncing chunked SQLite databases from GitHub releases.
class ChunkedSyncService {
  static const _owner = 'light-nook-labs';
  static const _repo = 'NovelHubMobile';
  static const _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  // Chunk configuration
  static const _chunks = ['cold', 'warm', 'hot'];
  static const _requiredChunks = ['cold']; // Bundled with app

  final Dio _dio;

  ChunkedSyncService(this._dio);

  /// Copy bundled chunks from assets to app documents directory
  Future<void> copyBundledChunks() async {
    final chunkDir = await _getChunkDir();
    
    // Copy all chunks from assets
    for (final chunkName in _chunks) {
      final chunkPath = p.join(chunkDir, '${chunkName}_chunk.sqlite');
      if (!await File(chunkPath).exists()) {
        try {
          // Try loading compressed .gz file first (smaller app size)
          final gzData = await rootBundle.load('assets/chunks/${chunkName}_chunk.sqlite.gz');
          final compressedBytes = gzData.buffer.asUint8List();
          final decompressedBytes = _gzipDecode(compressedBytes);
          await File(chunkPath).writeAsBytes(decompressedBytes);
        } catch (e) {
          try {
            // Fall back to uncompressed .sqlite file
            final data = await rootBundle.load('assets/chunks/${chunkName}_chunk.sqlite');
            final bytes = data.buffer.asUint8List();
            await File(chunkPath).writeAsBytes(bytes);
          } catch (e) {
            // If asset doesn't exist, that's okay
          }
        }
      }
    }
  }

  /// Get the local path for chunk storage
  Future<String> _getChunkDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final chunkDir = p.join(appDir.path, 'chunks');
    await Directory(chunkDir).create(recursive: true);
    return chunkDir;
  }

  /// Get the path for a specific chunk
  Future<String> getChunkPath(String chunkName) async {
    final chunkDir = await _getChunkDir();
    return p.join(chunkDir, '${chunkName}_chunk.sqlite');
  }

  /// Check if all required chunks exist
  Future<bool> hasRequiredChunks() async {
    for (final chunkName in _requiredChunks) {
      final path = await getChunkPath(chunkName);
      if (!await File(path).exists()) {
        return false;
      }
    }
    return true;
  }

  /// Check if all chunks exist
  Future<bool> hasAllChunks() async {
    for (final chunkName in _chunks) {
      final path = await getChunkPath(chunkName);
      if (!await File(path).exists()) {
        return false;
      }
    }
    return true;
  }

  /// Get sync status for all chunks
  Future<Map<String, ChunkSyncStatus>> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final status = <String, ChunkSyncStatus>{};

    for (final chunkName in _chunks) {
      final version = prefs.getString('chunk_${chunkName}_version');
      final lastSyncedStr = prefs.getString('chunk_${chunkName}_last_synced');
      final lastSynced = lastSyncedStr != null
          ? DateTime.tryParse(lastSyncedStr)
          : null;
      final isRequired = _requiredChunks.contains(chunkName);

      status[chunkName] = ChunkSyncStatus(
        chunkName: chunkName,
        version: version,
        lastSynced: lastSynced,
        isRequired: isRequired,
      );
    }

    return status;
  }

  /// Check for updates and return list of chunks to download
  Future<List<ChunkInfo>> checkForUpdates() async {
    try {
      final response = await _dio.get(
        _apiUrl,
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );

      final release = response.data;
      final tagName = release['tag_name'] as String;
      final assets = release['assets'] as List<dynamic>;

      final prefs = await SharedPreferences.getInstance();
      final chunksToUpdate = <ChunkInfo>[];

      for (final chunkName in _chunks) {
        final fileName = '${chunkName}_chunk.sqlite.gz';
        final asset = assets.firstWhere(
          (a) => a['name'] == fileName,
          orElse: () => null,
        );

        if (asset == null) continue;

        final lastVersion = prefs.getString('chunk_${chunkName}_version');
        if (lastVersion == tagName) continue;

        chunksToUpdate.add(
          ChunkInfo(
            name: chunkName,
            description: _getChunkDescription(chunkName),
            downloadUrl: asset['browser_download_url'] as String,
          ),
        );
      }

      return chunksToUpdate;
    } catch (e) {
      return [];
    }
  }

  /// Download and install a single chunk
  Future<ChunkSyncResult> downloadChunk(
    ChunkInfo chunk, {
    Function(double)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final compressedPath = p.join(
        tempDir.path,
        '${chunk.name}_chunk.sqlite.gz',
      );
      final chunkPath = await getChunkPath(chunk.name);

      // Download compressed file
      await _dio.download(
        chunk.downloadUrl,
        compressedPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total * 0.8); // 0-80% for download
          }
        },
      );

      // Decompress
      if (onProgress != null) onProgress(0.9);

      final compressedFile = File(compressedPath);
      final compressedBytes = await compressedFile.readAsBytes();

      // Use gzip to decompress
      final decompressedBytes = _gzipDecode(compressedBytes);

      // Write to final location
      final chunkFile = File(chunkPath);
      await chunkFile.writeAsBytes(decompressedBytes);

      // Cleanup temp file
      await compressedFile.delete();

      // Save sync state
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();
      await prefs.setString('chunk_${chunk.name}_version', 'latest');
      await prefs.setString('chunk_${chunk.name}_last_synced', now);

      if (onProgress != null) onProgress(1.0);

      return ChunkSyncResult.success(chunkName: chunk.name);
    } catch (e) {
      return ChunkSyncResult.error(chunkName: chunk.name, error: e.toString());
    }
  }

  /// Download all missing chunks
  Future<ChunkedSyncResult> syncAll({
    Function(String, double)? onProgress,
  }) async {
    final results = <String, ChunkSyncResult>{};
    final chunksToDownload = <ChunkInfo>[];

    // Check which chunks need updating
    final updates = await checkForUpdates();
    chunksToDownload.addAll(updates);

    // Also check for missing chunks
    for (final chunkName in _chunks) {
      final path = await getChunkPath(chunkName);
      if (!await File(path).exists()) {
        if (!chunksToDownload.any((c) => c.name == chunkName)) {
          // Need to download this chunk
          final update = updates.firstWhere(
            (c) => c.name == chunkName,
            orElse: () => ChunkInfo(
              name: chunkName,
              description: _getChunkDescription(chunkName),
              downloadUrl: '',
            ),
          );
          if (update.downloadUrl.isNotEmpty) {
            chunksToDownload.add(update);
          }
        }
      }
    }

    // Download each chunk
    for (final chunk in chunksToDownload) {
      final result = await downloadChunk(
        chunk,
        onProgress: (progress) {
          if (onProgress != null) {
            onProgress(chunk.name, progress);
          }
        },
      );
      results[chunk.name] = result;

      if (!result.success) {
        return ChunkedSyncResult.error(
          error: 'Failed to download ${chunk.name}: ${result.error}',
          results: results,
        );
      }
    }

    return ChunkedSyncResult.success(results: results);
  }

  /// Initial sync - download warm and hot chunks
  Future<ChunkedSyncResult> initialSync({
    Function(String, double)? onProgress,
  }) async {
    final results = <String, ChunkSyncResult>{};

    // Download warm and hot chunks
    final chunksToDownload = ['warm', 'hot'];

    for (final chunkName in chunksToDownload) {
      final path = await getChunkPath(chunkName);
      if (await File(path).exists()) {
        continue; // Already exists
      }

      // Get download URL from release
      final updates = await checkForUpdates();
      final chunk = updates.firstWhere(
        (c) => c.name == chunkName,
        orElse: () => ChunkInfo(
          name: chunkName,
          description: _getChunkDescription(chunkName),
          downloadUrl: '',
        ),
      );

      if (chunk.downloadUrl.isEmpty) {
        results[chunkName] = ChunkSyncResult.error(
          chunkName: chunkName,
          error: 'No download URL found',
        );
        continue;
      }

      final result = await downloadChunk(
        chunk,
        onProgress: (progress) {
          if (onProgress != null) {
            onProgress(chunkName, progress);
          }
        },
      );
      results[chunkName] = result;
    }

    return ChunkedSyncResult.success(results: results);
  }

  /// Get chunk description
  String _getChunkDescription(String chunkName) {
    switch (chunkName) {
      case 'cold':
        return 'Inactive data (断更, 已完结)';
      case 'warm':
        return 'Low activity data (完结A, 断更A)';
      case 'hot':
        return 'High activity data (连载中)';
      default:
        return 'Unknown chunk';
    }
  }

  /// Decode gzip compressed bytes
  List<int> _gzipDecode(List<int> bytes) {
    // Use dart:io's gzip codec
    return gzip.decode(bytes);
  }
}

/// Result of a single chunk sync
class ChunkSyncResult {
  final bool success;
  final String chunkName;
  final String? error;

  const ChunkSyncResult({
    required this.success,
    required this.chunkName,
    this.error,
  });

  factory ChunkSyncResult.success({required String chunkName}) =>
      ChunkSyncResult(success: true, chunkName: chunkName);

  factory ChunkSyncResult.error({
    required String chunkName,
    required String error,
  }) => ChunkSyncResult(success: false, chunkName: chunkName, error: error);
}

/// Result of a chunked sync operation
class ChunkedSyncResult {
  final bool success;
  final String? error;
  final Map<String, ChunkSyncResult>? results;

  const ChunkedSyncResult({required this.success, this.error, this.results});

  factory ChunkedSyncResult.success({
    required Map<String, ChunkSyncResult> results,
  }) => ChunkedSyncResult(success: true, results: results);

  factory ChunkedSyncResult.error({
    required String error,
    Map<String, ChunkSyncResult>? results,
  }) => ChunkedSyncResult(success: false, error: error, results: results);
}
