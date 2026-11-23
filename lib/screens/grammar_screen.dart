import 'package:flutter/material.dart';

import '../services/grammar_history.dart';
import '../services/grammar_store.dart';
import '../theme/palette.dart';
import '../widgets/ui_kit.dart';
import 'grammar_detail_screen.dart';
import 'grammar_history_screen.dart';

/// 语法栏：和背词并列，列表 + 独立搜索。
class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  String _query = '';
  String _cat = '全部';
  List<String> _history = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await GrammarHistory.load();
    if (mounted) setState(() => _history = GrammarHistory.ids.toList());
  }

  void _open(GrammarPoint g) async {
    await Navigator.of(context).push(fadeUpRoute(GrammarDetailScreen(point: g)));
    if (mounted) setState(() => _history = GrammarHistory.ids.toList());
  }

  bool get _batchMode => _query.trim().isEmpty && _cat == '全部';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final cats = ['全部', ...GrammarStore.categories];
    int countOf(String c) => c == '全部'
        ? GrammarStore.points.length
        : GrammarStore.points.where((g) => g.cat == c).length;
    final list = _batchMode
        ? GrammarStore.currentBatch
        : GrammarStore.search(_query)
            .where((g) => _cat == '全部' || g.cat == _cat)
            .toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Text(
              'MEGUMI · 语法',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
                color: p.muted,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    '语法',
                    style: TextStyle(
                      fontSize: 34,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                    ),
                  ),
                ),
                Tooltip(
                  message: '换一批',
                  child: Material(
                    color: p.card,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => GrammarStore.shuffleBatch()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded,
                                size: 17, color: p.primary),
                            const SizedBox(width: 5),
                            Text(
                              '换一批',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: p.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '新编印尼语（语法）· 按主题看规则和例句，看完可以直接练习。',
              style: TextStyle(fontSize: 13.5, height: 1.6, color: p.muted),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                if (_history.isEmpty) return;
                await Navigator.of(context).push(
                  fadeUpRoute(const GrammarHistoryScreen()),
                );
                await _loadHistory();
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 17, color: p.primary),
                    const SizedBox(width: 8),
                    Text(
                      '最近浏览',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _history.isEmpty ? '暂无记录' : '${_history.length} 条',
                      style: TextStyle(fontSize: 12, color: p.hint),
                    ),
                    const Spacer(),
                    if (_history.isNotEmpty)
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: p.hint,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(fontSize: 14, color: p.ink),
              decoration: InputDecoration(
                hintText: '搜语法点，例如 被动 / -kan',
                hintStyle: TextStyle(fontSize: 13.5, color: p.hint),
                prefixIcon: Icon(Icons.search_rounded, size: 19, color: p.hint),
                isDense: true,
                filled: true,
                fillColor: p.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in cats)
                  GestureDetector(
                    onTap: () => setState(() => _cat = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _cat == c ? p.primary : p.card,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$c ${countOf(c)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _cat == c ? FontWeight.w700 : FontWeight.w400,
                          color: _cat == c
                              ? (context.isDark
                                  ? const Color(0xFF10231F)
                                  : Colors.white)
                              : p.muted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  _batchMode
                      ? '换一批 · 每次 ${list.length} 条'
                      : '共 ${list.length} 条',
                  style: TextStyle(fontSize: 12.5, color: p.hint),
                ),
                if (_batchMode) ...[
                  const Spacer(),
                  Text(
                    '共 ${GrammarStore.points.length} 条',
                    style: TextStyle(fontSize: 12.5, color: p.hint),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (list.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '没找到相关语法点',
                  style: TextStyle(fontSize: 13, color: p.hint),
                ),
              ),
            for (final g in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: p.card,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _open(g),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: p.chipBg,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        g.cat,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: p.muted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        g.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: p.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  g.summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.5,
                                    color: p.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: p.hint,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
