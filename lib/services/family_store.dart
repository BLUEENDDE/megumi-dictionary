import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/word_family.dart';
import 'dictionary.dart';
import 'family_index.dart';

/// 词族数据：手工精校 > 自动归并 > 单词语素拆解。
class FamilyStore {
  static final Map<String, WordFamily> _families = {};
  static final Map<String, String> _rootOf = {};

  /// 全量语素拆解：词 → 词根 / 词缀
  static final Map<String, String> _wordRoot = {};
  static final Map<String, String> _wordAffix = {};
  static final Map<String, List<String>> _rootForms = {};

  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  static int get count => _families.length;

  static int get decomposedWords => _wordRoot.length;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    await _loadFamilies();
    await _loadAffixes();
  }

  static Future<void> _loadFamilies() async {
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

  static Future<void> _loadAffixes() async {
    try {
      final raw = await rootBundle.loadString('assets/affixes.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in map.entries) {
        final value = entry.value as List<dynamic>;
        final root = value[0] as String;
        final affix = value[1] as String;
        _wordRoot[entry.key] = root;
        _wordAffix[entry.key] = affix;
        _rootForms.putIfAbsent(root, () => []).add(entry.key);
      }
    } catch (_) {
      // 没有拆解数据也不影响人工词族
    }
  }

  /// 先找手工整理的词族，再找自动归并的，最后按语素现拼一个。
  static WordFamily? familyOf(String word) {
    final curated = familyForWord(word);
    if (curated != null) return curated;

    final root = _rootOf[word] ?? _wordRoot[word] ?? word;
    final packed = _families[_rootOf[word] ?? ''];
    if (packed != null) return packed;

    final forms = _rootForms[root];
    if (forms == null || forms.isEmpty) return null;

    final members = <DerivedWord>[];
    for (final form in forms) {
      members.add(
        DerivedWord(
          form: form,
          affix: _wordAffix[form] ?? '',
          gloss: Dictionary.entryOf(form)?.gloss ?? '',
          note: '',
        ),
      );
    }

    return WordFamily(
      root: root,
      rootGloss: Dictionary.entryOf(root)?.gloss ?? '',
      rootNote: '同源词 ${members.length} 个 · 按词缀对比',
      members: members,
    );
  }
}
