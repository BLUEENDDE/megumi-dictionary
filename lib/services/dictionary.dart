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

  /// 例句的中文翻译，可能为空
  final String exampleCn;

  /// 教材课次，例如「第15课」；为空表示不是教材词条
  final String lesson;

  /// 例句的语法说明（教材词条专用）
  final String grammar;

  const DictEntry({
    required this.word,
    required this.gloss,
    required this.page,
    this.level = 2,
    this.pos = '',
    this.example = '',
    this.exampleCn = '',
    this.lesson = '',
    this.grammar = '',
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
          exampleCn: (map['exc'] as String?) ?? '',
        );
      }).where((e) => e.word.isNotEmpty).toList();
    } catch (_) {
      _entries = const [];
    }
    try {
      final raw = await rootBundle.loadString('assets/newbase1.json');
      final list = jsonDecode(raw) as List<dynamic>;
      _newBase1 = list.map((item) {
        final map = item as Map<String, dynamic>;
        return DictEntry(
          word: (map['w'] as String? ?? '').trim(),
          gloss: (map['g'] as String? ?? '').trim(),
          page: 0,
          level: -1,
          pos: (map['pos'] as String?) ?? '',
          example: (map['ex'] as String?) ?? '',
          exampleCn: (map['exc'] as String?) ?? '',
          lesson: (map['lesson'] as String?) ?? '',
          grammar: (map['gr'] as String?) ?? '',
        );
      }).where((e) => e.word.isNotEmpty).toList();
    } catch (_) {
      _newBase1 = const [];
    }
    _loaded = true;
  }

  /// 搜索时把教材词也带上：同一个词两边都有时，教材词优先（带课次和语法）。
  static List<DictEntry> searchAll(String query, {int limit = 80}) {
    final base = search(query, limit: limit);
    final book = searchIn(_newBase1, query, limit: limit);
    final out = <DictEntry>[];
    final seen = <String>{};
    for (final e in book) {
      if (seen.add(e.word)) out.add(e);
    }
    for (final e in base) {
      if (seen.add(e.word)) out.add(e);
    }
    return out.take(limit).toList();
  }

  static List<DictEntry> searchIn(
    List<DictEntry> src,
    String query,
    {int limit = 80}
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final prefix = <DictEntry>[];
    final contains = <DictEntry>[];
    for (final e in src) {
      final w = e.word.toLowerCase();
      if (w.startsWith(q)) {
        prefix.add(e);
      } else if (w.contains(q) || e.gloss.contains(q)) {
        contains.add(e);
      }
    }
    return [...prefix, ...contains].take(limit).toList();
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

  /// 《新编基础印尼语一》的 460 条生词
  static List<DictEntry> _newBase1 = const [];

  static List<DictEntry> get newBase1 => _newBase1;

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