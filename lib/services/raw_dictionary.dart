import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// 扫描原文：每个词在 OCR 里对应的完整文字，一字不改。
class RawDictionary {
  static Map<String, String> _raw = const {};
  static bool _loaded = false;
  static bool _loading = false;

  static bool get isLoaded => _loaded;

  static Future<void> load() async {
    if (_loaded || _loading) return;
    _loading = true;
    try {
      final data = await rootBundle.load('assets/dictionary_raw.json.gz');
      final bytes = gzip.decode(data.buffer.asUint8List());
      final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      _raw = map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      _raw = const {};
    }
    _loaded = true;
    _loading = false;
  }

  static String? of(String word) => _raw[word];
}
