import 'package:flutter/material.dart';

import '../models/word_pair.dart';
import '../services/progress_store.dart';
import '../services/user_pairs_store.dart';
import '../theme/palette.dart';
import '../widgets/ui_kit.dart';
import 'detail_screen.dart';

/// 已学习的词对：学习中的 + 已掌握。
class LearnedListScreen extends StatefulWidget {
  final List<WordPair> pairs;
  final ProgressStore store;
  final UserPairsStore? userPairs;

  const LearnedListScreen({
    super.key,
    required this.pairs,
    required this.store,
    this.userPairs,
  });

  @override
  State<LearnedListScreen> createState() => _LearnedListScreenState();
}

class _LearnedListScreenState extends State<LearnedListScreen> {
  Future<void> _open(WordPair pair) async {
    await Navigator.of(context).push(
      fadeUpRoute(
        DetailScreen(
          pair: pair,
          store: widget.store,
          userPairs: widget.userPairs,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final learning = widget.store.learningPairs(widget.pairs);
    final mastered = widget.store.masteredPairs(widget.pairs);
    final fresh = widget.store.unlearned(widget.pairs);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('已学习'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _Summary(
            learning: learning.length,
            mastered: mastered.length,
            fresh: fresh.length,
          ),
          const SizedBox(height: 20),
          if (learning.isEmpty && mastered.isEmpty && fresh.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '还没有学过的词对',
                style: TextStyle(fontSize: 13, color: p.hint),
              ),
            ),
          if (learning.isNotEmpty) ...[
            _SectionTitle('学习中', learning.length),
            const SizedBox(height: 10),
            for (final pair in learning)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _Row(
                  pair: pair,
                  stat: widget.store.statFor(pair.id),
                  onTap: () => _open(pair),
                ),
              ),
            const SizedBox(height: 14),
          ],
          if (mastered.isNotEmpty) ...[
            _SectionTitle('已掌握', mastered.length),
            const SizedBox(height: 10),
            for (final pair in mastered)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _Row(
                  pair: pair,
                  stat: widget.store.statFor(pair.id),
                  mastered: true,
                  onTap: () => _open(pair),
                ),
              ),
            const SizedBox(height: 14),
          ],
          if (fresh.isNotEmpty) ...[
            _SectionTitle('新学', fresh.length),
            const SizedBox(height: 10),
            for (final pair in fresh)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _Row(
                  pair: pair,
                  stat: widget.store.statFor(pair.id),
                  fresh: true,
                  onTap: () => _open(pair),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final int learning;
  final int mastered;
  final int fresh;

  const _Summary({
    required this.learning,
    required this.mastered,
    required this.fresh,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: '学习中',
              value: '$learning',
              color: p.primary,
            ),
          ),
          Container(width: 1, height: 30, color: p.divider),
          Expanded(
            child: _Metric(
              label: '已掌握',
              value: '$mastered',
              color: p.success,
            ),
          ),
          Container(width: 1, height: 30, color: p.divider),
          Expanded(
            child: _Metric(label: '新学', value: '$fresh', color: p.hint),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 11.5, color: p.muted)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final int count;

  const _SectionTitle(this.text, this.count);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        const SizedBox(width: 8),
        Text('$count 组', style: TextStyle(fontSize: 12.5, color: p.muted)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final WordPair pair;
  final PairStat stat;
  final bool mastered;
  final bool fresh;
  final VoidCallback onTap;

  const _Row({
    required this.pair,
    required this.stat,
    required this.onTap,
    this.mastered = false,
    this.fresh = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pair.first.form,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.compare_arrows_rounded,
                            size: 14,
                            color: p.primary.withValues(alpha: 0.6),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            pair.second.form,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (!fresh) ...[
                          _BoxBar(box: stat.box, mastered: mastered),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          fresh
                              ? '还没学过'
                              : mastered
                                  ? '复习完成'
                                  : '记忆 ${stat.box}/${ProgressStore.maxBox}',
                          style: TextStyle(fontSize: 11, color: p.hint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                fresh ? '—' : '${stat.accuracyPercent}%',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: mastered ? p.success : p.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 一排小方块，显示记忆推进到第几格。
class _BoxBar extends StatelessWidget {
  final int box;
  final bool mastered;

  const _BoxBar({required this.box, required this.mastered});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Row(
      children: [
        for (var i = 1; i <= ProgressStore.maxBox; i++)
          Container(
            width: 12,
            height: 4,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i <= box
                  ? (mastered ? p.success : p.primary)
                  : p.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}
