import 'dart:convert';
import 'dart:io';

/// GitHub Release 里的版本信息。
class UpdateInfo {
  final String version;
  final String url;
  final String notes;

  const UpdateInfo({
    required this.version,
    required this.url,
    required this.notes,
  });
}

/// 检查更新：读本仓库的 latest release。
class UpdateChecker {
  static const _api =
      'https://api.github.com/repos/BLUENDDE/megumi-dictionary/releases/latest';

  /// 返回「有新版」时的信息；已是最新或检查失败返回 null。
  static Future<UpdateInfo?> check(String currentVersion) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(_api));
      req.headers.set('Accept', 'application/vnd.github+json');
      req.headers.set('User-Agent', 'megumi-dict-app');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      final body = await res.transform(utf8.decoder).join();
      final map = jsonDecode(body) as Map<String, dynamic>;
      final tag = (map['tag_name'] as String? ?? '').replaceAll('v', '').trim();
      final url = (map['html_url'] as String?) ?? '';
      final notes = (map['body'] as String?) ?? '';
      if (tag.isEmpty) return null;
      if (compareVersions(tag, currentVersion) <= 0) return null;
      return UpdateInfo(version: tag, url: url, notes: notes);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// 比较点分版本号：a > b 返回 1，相等 0，小于 -1。
  static int compareVersions(String a, String b) {
    final pa = _parts(a);
    final pb = _parts(b);
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x > y ? 1 : -1;
    }
    return 0;
  }

  static List<int> _parts(String v) => v
      .split('+')
      .first
      .split('.')
      .map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}
