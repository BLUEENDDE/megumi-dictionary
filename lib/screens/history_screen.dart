import 'package:flutter/material.dart';

import '../services/dictionary.dart';
import '../services/history_store.dart';
import '../theme/palette.dart';
import '../widgets/dict_entry_sheet.dart';

/// 浏览历史：最近点开过的词条，最多 20 条。
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    HistoryStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final words = HistoryStore.instance.words;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '浏览历史 ${words.length}/${HistoryStore.maxItems}',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          if (words.isNotEmpty)
            TextButton(
              onPressed: () async {
                await HistoryStore.instance.clear();
                if (mounted) setState(() {});
              },
              child: const Text('清空'),
            ),
        ],
      ),
      body: SafeArea(
        child: words.isEmpty
            ? Center(
                child: Text(
                  '还没有看过词条',
                  style: TextStyle(fontSize: 13.5, color: p.hint),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: words.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final word = words[index];
                  final entry = Dictionary.entryOf(word) ??
                      Dictionary.newBase1
                          .where((e) => e.word == word)
                          .firstOrNull;
                  return Material(
                    color: p.card,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: entry == null
                          ? null
                          : () => showDictEntrySheet(context, entry),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    word,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: p.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    entry?.gloss ?? '（词库已更新，找不到这个词）',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
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
                  );
                },
              ),
      ),
    );
  }
}
