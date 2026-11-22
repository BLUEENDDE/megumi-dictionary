import 'package:flutter/material.dart';

import '../services/grammar_store.dart';
import '../theme/palette.dart';
import '../widgets/ui_kit.dart';
import 'grammar_practice_screen.dart';

class GrammarDetailScreen extends StatelessWidget {
  final GrammarPoint point;

  const GrammarDetailScreen({super.key, required this.point});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      appBar: AppBar(
        title: Text(point.cat, style: const TextStyle(fontSize: 14)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              point.title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              point.summary,
              style: TextStyle(fontSize: 13.5, height: 1.6, color: p.muted),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                point.body,
                style: TextStyle(fontSize: 14, height: 1.85, color: p.ink),
              ),
            ),
            if (point.examples.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '例句',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.muted,
                ),
              ),
              const SizedBox(height: 8),
              for (final e in point.examples)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.id,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          color: p.ink,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.cn,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.6,
                          color: p.muted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: p.primary,
                  foregroundColor: context.isDark
                      ? const Color(0xFF10231F)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: point.practice.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                          fadeUpRoute(
                            GrammarPracticeScreen(point: point),
                          ),
                        ),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(
                  point.practice.isEmpty
                      ? '这一条暂无练习'
                      : '练习（${point.practice.length} 题）',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
