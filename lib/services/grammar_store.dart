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
  final String cat;
  final String title;
  final String summary;
  final String body;
  final List<GrammarExample> examples;
  final List<GrammarPractice> practice;

  const GrammarPoint({
    required this.id,
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

  static bool get isLoaded => _loaded;

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
      _points = list.map((item) {
        final map = item as Map<String, dynamic>;
        return GrammarPoint(
          id: (map['id'] as String?) ?? '',
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
      }).toList();
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

  static GrammarPoint? byId(String id) {
    for (final g in _points) {
      if (g.id == id) return g;
    }
    return null;
  }
}
