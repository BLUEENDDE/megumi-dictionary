import 'package:flutter/material.dart';

import '../services/dictionary.dart';
import '../services/progress_store.dart';
import '../theme/palette.dart';
import '../widgets/ui_kit.dart';
import 'word_quiz_screen.dart';

/// 复习前先看一眼这轮要考哪些词，点「开始复习」才进测验。
class ReviewListScreen extends StatelessWidget {
  final String title;
  final List<DictEntry> words;
  final List<DictEntry> pool;
  final ProgressStore store;

  const ReviewListScreen({
    super.key,
    required this.title,
    required this.words,
    required this.pool,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      appBar: AppBar(
        title: Text('复习 · $title', style: const TextStyle(fontSize: 15)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Text(
                    '这轮复习 ${words.length} 个词',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '第一轮正序，第二轮乱序',
                    style: TextStyle(fontSize: 11.5, color: p.hint),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                itemCount: words.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final e = words[index];
                  return Container(
                    padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 26,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(fontSize: 11.5, color: p.hint),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.word,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: p.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                e.gloss.isEmpty ? '—' : e.gloss,
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
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: context.isDark
                        ? const Color(0xFF10231F)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final score = await Navigator.of(context).push(
                      fadeUpRoute(
                        WordQuizScreen(
                          title: title,
                          isReview: true,
                          words: words,
                          pool: pool,
                          store: store,
                        ),
                      ),
                    );
                    if (context.mounted) Navigator.of(context).pop(score);
                  },
                  child: const Text(
                    '开始复习',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
