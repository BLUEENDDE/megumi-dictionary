import 'package:flutter/material.dart';

import '../services/grammar_history.dart';
import '../services/grammar_store.dart';
import '../theme/palette.dart';
import '../widgets/ui_kit.dart';
import 'grammar_detail_screen.dart';

/// 最近浏览：单独一页，按分类分组。
class GrammarHistoryScreen extends StatefulWidget {
  const GrammarHistoryScreen({super.key});

  @override
  State<GrammarHistoryScreen> createState() => _GrammarHistoryScreenState();
}

class _GrammarHistoryScreenState extends State<GrammarHistoryScreen> {
  List<String> _ids = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await GrammarHistory.load();
    if (mounted) setState(() => _ids = GrammarHistory.ids.toList());
  }

  Map<String, List<GrammarPoint>> _grouped() {
    final map = <String, List<GrammarPoint>>{};
    for (final id in _ids) {
      final g = GrammarStore.byId(id);
      if (g == null) continue;
      map.putIfAbsent(g.cat, () => []).add(g);
    }
    return map;
  }

  Future<void> _open(GrammarPoint g) async {
    await Navigator.of(context).push(fadeUpRoute(GrammarDetailScreen(point: g)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final grouped = _grouped();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '最近浏览',
          style: TextStyle(fontSize: 15, color: p.ink),
        ),
        actions: [
          if (_ids.isNotEmpty)
            TextButton(
              onPressed: () async {
                await GrammarHistory.clear();
                await _load();
              },
              child: Text(
                '清空',
                style: TextStyle(fontSize: 12.5, color: p.muted),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _ids.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 40, color: p.hint),
                    const SizedBox(height: 12),
                    Text(
                      '还没有看过语法',
                      style: TextStyle(fontSize: 13.5, color: p.muted),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        '${entry.key} · ${entry.value.length} 条',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: p.hint,
                        ),
                      ),
                    ),
                    for (final g in entry.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: p.card,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _open(g),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: p.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          g.summary,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: p.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: p.hint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}
