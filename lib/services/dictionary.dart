import 'dart:convert';

import 'package:flutter/services.dart';

class DictEntry {
  final String word;
  final String gloss;
  final int page;

  /// 0 初级 / 1 中级 / 2 高级
  final int level;

  /// 词性：动 / 名 / 形 / 副 / 连 / 介，空表示未标注
  final String pos;

  /// 例句（来自词典原文，可能为空）
  final String example;

  const DictEntry({
    required this.word,
    required this.gloss,
    required this.page,
    this.level = 2,
    this.pos = '',
    this.example = '',
  });
}

/// 内置词典：从 assets/dictionary.json 读出来，按前缀/包含匹配检索。
class Dictionary {
  static List<DictEntry> _entries = const [];
  static bool _loaded = false;

  static bool get isLoaded => _loaded;
  static int get size => _entries.length;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/dictionary.json');
      final list = jsonDecode(raw) as List<dynamic>;
      _entries = list.map((item) {
        final map = item as Map<String, dynamic>;
        return DictEntry(
          word: (map['w'] as String? ?? '').trim(),
          gloss: (map['g'] as String? ?? '').trim(),
          page: (map['p'] as num?)?.toInt() ?? 0,
          level: (map['lvl'] as num?)?.toInt() ?? 2,
          pos: (map['pos'] as String?) ?? '',
          example: (map['ex'] as String?) ?? '',
        );
      }).where((e) => e.word.isNotEmpty).toList();
    } catch (_) {
      _entries = const [];
    }
    _loaded = true;
  }

  static List<DictEntry> search(String query, {int limit = 80}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final prefix = <DictEntry>[];
    final contains = <DictEntry>[];

    for (final entry in _entries) {
      final w = entry.word.toLowerCase();
      if (w.startsWith(q)) {
        prefix.add(entry);
        if (prefix.length >= limit) break;
      } else if (w.contains(q) && contains.length < limit) {
        contains.add(entry);
      }
    }

    return [...prefix, ...contains].take(limit).toList();
  }

  static Map<String, DictEntry>? _byWord;

  static DictEntry? entryOf(String word) {
    _byWord ??= {for (final e in _entries) e.word: e};
    return _byWord![word];
  }

  static List<DictEntry> allOf({int? level}) => level == null
      ? _entries
      : _entries.where((e) => e.level == level).toList();

  static int countOf({int? level}) => level == null
      ? _entries.length
      : _entries.where((e) => e.level == level).length;

  static List<DictEntry> page({
    int? level,
    required int offset,
    int limit = 50,
  }) {
    final src = level == null
        ? _entries
        : _entries.where((e) => e.level == level);
    return src.skip(offset).take(limit).toList();
  }

  /// 随便取几条，用于空状态展示。
  static List<DictEntry> sample(int count) {
    if (_entries.isEmpty) return const [];
    final step = (_entries.length / count).floor().clamp(1, 9999);
    return [for (var i = 0; i < count; i++) _entries[(i * step) % _entries.length]];
  }
}
