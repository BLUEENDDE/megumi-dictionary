import 'dart:convert';

import 'package:flutter/services.dart';

class GrammarExample {
  final String id;
  final String cn;

  const GrammarExample({required this.id, required this.cn});
}

class GrammarPractice {
  final String q;
  final List<String> options;
  final String answer;
  final String why;

  const GrammarPractice({
    required this.q,
    required this.options,
    required this.answer,
    required this.why,
  });
}

class GrammarPoint {
  final String id;
  final String book;
  final String cat;
  final List<String> related;
  final String title;
  final String summary;
  final String body;
  final List<GrammarExample> examples;
  final List<GrammarPractice> practice;

  const GrammarPoint({
    required this.id,
    this.book = '新编印尼语（语法）',
    this.related = const [],
    required this.cat,
    required this.title,
    required this.summary,
    required this.body,
    required this.examples,
    required this.practice,
  });
}

/// 语法库：和词库完全分开，单独搜索。
class GrammarStore {
  static List<GrammarPoint> _points = const [];
  static bool _loaded = false;

  static List<GrammarPoint> get points => _points;

  /// 轮转游标 + 当前展示的批次（都放静态里，切页签不会重置）
  static int _cursor = 0;
  static List<GrammarPoint> _current = const [];

  static List<GrammarPoint> get currentBatch =>
      _current.isEmpty ? (_current = nextBatch()) : _current;

  static bool get isLoaded => _loaded;

  /// 书架：按书名分组
  static List<String> get books {
    final seen = <String>[];
    for (final g in _points) {
      if (!seen.contains(g.book)) seen.add(g.book);
    }
    return seen;
  }

  static List<GrammarPoint> ofBook(String book) =>
      _points.where((g) => g.book == book).toList();

  static List<String> get categories {
    final seen = <String>[];
    for (final g in _points) {
      if (!seen.contains(g.cat)) seen.add(g.cat);
    }
    return seen;
  }

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/grammar.json');
      final list = jsonDecode(raw) as List<dynamic>;
      final seenIds = <String>{};
      _points = list.map((item) {
        final map = item as Map<String, dynamic>;
        return GrammarPoint(
          id: (map['id'] as String?) ?? '',
          book: (map['book'] as String?) ?? '新编印尼语（语法）',
          related: ((map['related'] as List?) ?? [])
              .map((e) => e.toString())
              .toList(),
          cat: (map['cat'] as String?) ?? '其它',
          title: (map['title'] as String?) ?? '',
          summary: (map['summary'] as String?) ?? '',
          body: (map['body'] as String?) ?? '',
          examples: ((map['examples'] as List?) ?? [])
              .map((e) => GrammarExample(
                    id: ((e as Map)['id'] as String?) ?? '',
                    cn: (e['cn'] as String?) ?? '',
                  ))
              .toList(),
          practice: ((map['practice'] as List?) ?? [])
              .map((p) => GrammarPractice(
                    q: ((p as Map)['q'] as String?) ?? '',
                    options: ((p['options'] as List?) ?? [])
                        .map((o) => o.toString())
                        .toList(),
                    answer: (p['answer'] as String?) ?? '',
                    why: (p['why'] as String?) ?? '',
                  ))
              .toList(),
        );
      }).where((g) => g.id.isEmpty || seenIds.add(g.id)).toList();
    } catch (_) {
      _points = const [];
    }
    _loaded = true;
  }

  /// 只搜语法：标题、概述、正文、例句。
  static List<GrammarPoint> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _points;
    return _points.where((g) {
      return g.title.toLowerCase().contains(q) ||
          g.summary.toLowerCase().contains(q) ||
          g.body.toLowerCase().contains(q) ||
          g.cat.toLowerCase().contains(q) ||
          g.examples.any((e) =>
              e.id.toLowerCase().contains(q) || e.cn.contains(q));
    }).toList();
  }

  /// 按书取一批（用于书架模式）：轮转、不重复。
  static List<GrammarPoint> batch(int seed,
      {int count = 8, String? book}) {
    final src = book == null || book.isEmpty ? _points : ofBook(book);
    if (src.isEmpty) return const [];
    final start = ((seed - 1) * count) % src.length;
    final out = <GrammarPoint>[];
    for (var i = 0; i < (count < src.length ? count : src.length); i++) {
      out.add(src[(start + i) % src.length]);
    }
    return out;
  }

  /// 换一批：按顺序轮转，批与批之间不重复，走完一遍再从头开始。
  static List<GrammarPoint> nextBatch({int count = 8}) {
    if (_points.isEmpty) return const [];
    final n = _points.length;
    final size = count >= n ? n : count;
    final out = <GrammarPoint>[];
    for (var i = 0; i < size; i++) {
      out.add(_points[(_cursor + i) % n]);
    }
    _cursor = (_cursor + size) % n;
    return out;
  }

  /// 「换一批」按钮：取下一批并记住
  static List<GrammarPoint> shuffleBatch({int count = 8}) {
    _current = nextBatch(count: count);
    return _current;
  }

  /// 测试用：重置轮转状态
  static void resetRotation() {
    _cursor = 0;
    _current = const [];
  }

  static GrammarPoint? byId(String id) {
    for (final g in _points) {
      if (g.id == id) return g;
    }
    return null;
  }
}
