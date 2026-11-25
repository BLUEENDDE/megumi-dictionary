import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语法浏览历史：最近看过的排在前面，最多留 200 条。
class GrammarHistory {
  static const _key = 'grammar_history_v1';
  static const maxCount = 200;

  /// 记录变化次数，界面可监听刷新
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static final List<String> _ids = [];
  static bool _loaded = false;

  static List<String> get ids => List.unmodifiable(_ids);

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw != null) {
      _ids
        ..clear()
        ..addAll(raw);
    }
  }

  /// 记一次浏览：已存在就移到最前。
  static Future<void> add(String id) async {
    await load();
    _ids.remove(id);
    _ids.insert(0, id);
    if (_ids.length > maxCount) {
      _ids.removeRange(maxCount, _ids.length);
    }
    revision.value++;
    await _save();
  }

  static Future<void> clear() async {
    _ids.clear();
    _loaded = true;
    revision.value++;
    await _save();
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _ids);
  }
}
