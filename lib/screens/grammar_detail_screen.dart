import 'package:flutter/material.dart';

import '../services/grammar_history.dart';
import '../services/grammar_store.dart';
import '../theme/palette.dart';
import '../widgets/ui_kit.dart';
import 'grammar_practice_screen.dart';

class GrammarDetailScreen extends StatefulWidget {
  final GrammarPoint point;

  const GrammarDetailScreen({super.key, required this.point});

  @override
  State<GrammarDetailScreen> createState() => _GrammarDetailScreenState();
}

class _GrammarDetailScreenState extends State<GrammarDetailScreen> {
  @override
  void initState() {
    super.initState();
    GrammarHistory.add(widget.point.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final related = [
      for (final id in widget.point.related)
        if (GrammarStore.byId(id) != null) GrammarStore.byId(id)!,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.point.cat, style: const TextStyle(fontSize: 14)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              widget.point.title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '《${widget.point.book}》',
              style: TextStyle(fontSize: 11.5, color: p.hint),
            ),
            const SizedBox(height: 6),
            Text(
              widget.point.summary,
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
                widget.point.body,
                style: TextStyle(fontSize: 14, height: 1.85, color: p.ink),
              ),
            ),
            if (widget.point.examples.isNotEmpty) ...[
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
              for (final e in widget.point.examples)
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
                onPressed: widget.point.practice.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                          fadeUpRoute(
                            GrammarPracticeScreen(point: widget.point),
                          ),
                        ),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(
                  widget.point.practice.isEmpty
                      ? '这一条暂无练习'
                      : '练习（${widget.point.practice.length} 题）',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (related.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                '相关语法',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.muted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in related)
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        fadeUpRoute(GrammarDetailScreen(point: g)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          g.title,
                          style: TextStyle(fontSize: 12.5, color: p.primary),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
