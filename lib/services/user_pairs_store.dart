import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/word_pair.dart';

/// 用户自己录的词对，和内置词库分开存。
class UserPairsStore {
  static const _key = 'user_pairs_v1';

  final List<WordPair> _pairs = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<WordPair> get pairs => List.unmodifiable(_pairs);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _pairs
          ..clear()
          ..addAll(
            list.map(
              (e) => WordPair.fromJson((e as Map).cast<String, dynamic>()),
            ),
          );
      } catch (_) {
        // 存的数据坏了就忽略，别让首页打不开。
      }
    }
    _loaded = true;
  }

  Future<void> add(WordPair pair) async {
    _pairs.insert(0, pair);
    await _save();
  }

  Future<void> remove(String id) async {
    _pairs.removeWhere((pair) => pair.id == id);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _pairs.map((pair) => pair.toJson()).toList();
    await prefs.setString(_key, jsonEncode(data));
  }
}
