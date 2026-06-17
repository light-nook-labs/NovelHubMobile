import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/database.dart';
import '../../shared/utils/mappings.dart';

/// Cover URL prefix (from novel_hub/site_config.toml)
const _coverPrefix = 'https://rs.sfacg.com/web/novel/images/NovelCover/Big/';
const _defaultCover = 'defaultNew.jpg';

/// Represents a parsed novel from JSONL before database insertion.
///
/// Field names match novel_hub/utils/models.py Meta model.
class NovelData {
  final int nid;
  final String title;
  final String author;
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
  final String? contest;
  final List<String> tags;
  final String? cover; // Compressed suffix or null
  final DateTime? lastUpdate;

  const NovelData({
    required this.nid,
    required this.title,
    required this.author,
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
    this.contest,
    this.tags = const [],
    this.cover,
    this.lastUpdate,
  });

  factory NovelData.fromJson(Map<String, dynamic> json) {
    return NovelData(
      nid: json['nid'] as int,
      title: json['title'] as String,
      author: json['author'] as String? ?? '',
      genre: genreMapping.getValue(json['genre'] as String? ?? '其他'),
      status: statusMapping.getValue(json['status'] as String? ?? '其他'),
      ptype: ptypeMapping.getValue(json['ptype'] as String? ?? '其他'),
      hasBanner: json['has_banner'] as bool? ?? false,
      wordNum: json['word_num'] as int?,
      clickNum: json['click_num'] as int?,
      praiseNum: json['praise_num'] as int?,
      likeNum: json['like_num'] as int?,
      commentNum: json['comment_num'] as int?,
      reviewNum: json['review_num'] as int?,
      contest: json['contest'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      cover: _compressCover(json['cover'] as String?),
      lastUpdate: _parseDateTime(json['last_update'] as String?),
    );
  }

  /// Compress cover URL to suffix, default cover → null.
  /// Matches novel_hub/utils/loader.py compress_cover().
  static String? _compressCover(String? url) {
    if (url == null || url.isEmpty) return null;
    String suffix;
    if (url.startsWith(_coverPrefix)) {
      suffix = url.substring(_coverPrefix.length);
    } else {
      suffix = url;
    }
    if (suffix == _defaultCover) return null;
    return suffix;
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
}

/// Service for parsing JSONL data files.
class JsonlParser {
  /// Parse a single JSONL line into NovelData.
  static NovelData? parseLine(String line) {
    if (line.trim().isEmpty) return null;
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      return NovelData.fromJson(json);
    } catch (e) {
      // Skip malformed lines
      return null;
    }
  }

  /// Parse JSONL content into a list of NovelData.
  static List<NovelData> parseContent(String content) {
    final novels = <NovelData>[];
    for (final line in const LineSplitter().convert(content)) {
      final novel = parseLine(line);
      if (novel != null) {
        novels.add(novel);
      }
    }
    return novels;
  }

  /// Convert NovelData to NovelsCompanion for database insertion.
  static NovelsCompanion toCompanion(
    NovelData data,
    String? author,
    int? contestId,
  ) {
    return NovelsCompanion(
      id: Value(data.nid),
      title: Value(data.title),
      author: Value(author),
      genre: Value(data.genre),
      status: Value(data.status),
      ptype: Value(data.ptype),
      contestId: Value(contestId),
      hasBanner: Value(data.hasBanner),
      wordNum: Value(data.wordNum),
      clickNum: Value(data.clickNum),
      praiseNum: Value(data.praiseNum),
      likeNum: Value(data.likeNum),
      commentNum: Value(data.commentNum),
      reviewNum: Value(data.reviewNum),
      cover: Value(data.cover),
      lastUpdate: Value(data.lastUpdate?.toIso8601String()),
    );
  }
}
