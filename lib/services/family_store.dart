import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/word_family.dart';
import 'family_index.dart';

/// 自动归并出来的词族（离线预计算，assets/families.json）。
class FamilyStore {
  static final Map<String, WordFamily> _families = {};
  static final Map<String, String> _rootOf = {};
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  static int get count => _families.length;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = await rootBundle.loadString('assets/families.json');
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final root = map['r'] as String? ?? '';
        if (root.isEmpty) continue;
        final members = ((map['m'] as List?) ?? [])
            .map(
              (m) => DerivedWord(
                form: (m['w'] as String?) ?? '',
                affix: (m['a'] as String?) ?? '',
                gloss: (m['g'] as String?) ?? '',
                note: '',
              ),
            )
            .toList();

        _families[root] = WordFamily(
          root: root,
          rootGloss: (map['rg'] as String?) ?? '',
          rootNote: '同一个词根长出来的 ${members.length} 个词',
          members: members,
        );
        for (final m in members) {
          _rootOf[m.form] = root;
        }
      }
    } catch (_) {
      // 资源缺失就只用人工整理的词族
    }
  }

  /// 先找手工整理的词族，再找自动归并的。
  static WordFamily? familyOf(String word) {
    final curated = familyForWord(word);
    if (curated != null) return curated;
    final root = _rootOf[word];
    if (root == null) return null;
    return _families[root];
  }
}
