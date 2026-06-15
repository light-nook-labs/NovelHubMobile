import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/database.dart';
import '../../shared/utils/mappings.dart';

/// Represents a parsed novel from JSONL before database insertion.
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
  final String? cover;
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
      genre: genreMapping.getValue(json['genre'] as String? ?? '奇幻'),
      status: statusMapping.getValue(json['status'] as String? ?? '连载中'),
      ptype: ptypeMapping.getValue(json['ptype'] as String? ?? '长篇'),
      hasBanner: json['has_banner'] as bool? ?? false,
      wordNum: json['word_num'] as int?,
      clickNum: json['click_num'] as int?,
      praiseNum: json['praise_num'] as int?,
      likeNum: json['like_num'] as int?,
      commentNum: json['comment_num'] as int?,
      reviewNum: json['review_num'] as int?,
      contest: json['contest'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      cover: json['cover'] as String?,
      lastUpdate: _parseDateTime(json['last_update'] as String?),
    );
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
    int? authorId,
    int? contestId,
  ) {
    return NovelsCompanion(
      id: Value(data.nid),
      title: Value(data.title),
      genre: Value(data.genre),
      status: Value(data.status),
      ptype: Value(data.ptype),
      authorId: Value(authorId),
      contestId: Value(contestId),
      hasBanner: Value(data.hasBanner),
      wordNum: Value(data.wordNum),
      clickNum: Value(data.clickNum),
      praiseNum: Value(data.praiseNum),
      likeNum: Value(data.likeNum),
      commentNum: Value(data.commentNum),
      reviewNum: Value(data.reviewNum),
      cover: Value(data.cover),
      lastUpdate: Value(data.lastUpdate),
    );
  }
}
