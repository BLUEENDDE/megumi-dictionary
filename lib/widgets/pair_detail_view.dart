import 'package:flutter/material.dart';

import '../models/word_family.dart';
import '../models/word_pair.dart';
import '../services/family_index.dart';
import '../theme/palette.dart';
import 'ui_kit.dart';

/// 一组词对的对比内容（词头、板块、例句）。
/// 详情页和学习会话都用它，避免两份实现走偏。
class PairDetailView extends StatelessWidget {
  final WordPair pair;
  final void Function(WordFamily family) onOpenFamily;

  const PairDetailView({
    super.key,
    required this.pair,
    required this.onOpenFamily,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _Header(pair: pair, onOpenFamily: onOpenFamily),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: p.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pair.summary,
                  style: TextStyle(fontSize: 13.5, height: 1.6, color: p.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          '差异板块',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '一条轴看一个区别，逐条比过去',
          style: TextStyle(fontSize: 12.5, color: p.muted),
        ),
        const SizedBox(height: 12),
        if (pair.axes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '这组还没写板块，编辑时可以补上',
              style: TextStyle(fontSize: 12.5, color: p.hint),
            ),
          ),
        for (final axis in pair.axes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AxisCard(pair: pair, axis: axis),
          ),
        const SizedBox(height: 18),
        Text(
          '最小对比句',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '同一件事，两个词说出来的味道不一样',
          style: TextStyle(fontSize: 12.5, color: p.muted),
        ),
        const SizedBox(height: 12),
        _ExampleCard(
          word: pair.first.form,
          sentence: pair.example.firstText,
          gloss: pair.example.firstGloss,
          note: pair.example.firstNote,
        ),
        const SizedBox(height: 10),
        _ExampleCard(
          word: pair.second.form,
          sentence: pair.example.secondText,
          gloss: pair.example.secondGloss,
          note: pair.example.secondNote,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final WordPair pair;
  final void Function(WordFamily family) onOpenFamily;

  const _Header({required this.pair, required this.onOpenFamily});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Side(
              sense: pair.first,
              family: familyForWord(pair.first.form),
              onOpenFamily: onOpenFamily,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: p.chipBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'vs',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: p.muted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: _Side(
              sense: pair.second,
              family: familyForWord(pair.second.form),
              onOpenFamily: onOpenFamily,
            ),
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final WordSense sense;
  final WordFamily? family;
  final void Function(WordFamily family) onOpenFamily;

  const _Side({
    required this.sense,
    required this.family,
    required this.onOpenFamily,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final family = this.family;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                sense.form,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
            ),
            if (family != null) ...[
              const SizedBox(width: 8),
              _FamilyButton(
                family: family,
                onTap: () => onOpenFamily(family),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          sense.gloss,
          style: TextStyle(fontSize: 12.5, height: 1.5, color: p.muted),
        ),
      ],
    );
  }
}

class _FamilyButton extends StatelessWidget {
  final WordFamily family;
  final VoidCallback onTap;

  const _FamilyButton({required this.family, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Tooltip(
      message: '关系网：${family.members.length} 个派生词',
      child: Material(
        color: p.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hub_outlined, size: 14, color: p.primary),
                const SizedBox(width: 3),
                Text(
                  '${family.members.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AxisCard extends StatelessWidget {
  final WordPair pair;
  final ContrastAxis axis;

  const _AxisCard({required this.pair, required this.axis});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            axis.name,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: p.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Cell(word: pair.first.form, text: axis.first)),
              Container(
                width: 1,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: p.divider,
              ),
              Expanded(child: _Cell(word: pair.second.form, text: axis.second)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String word;
  final String text;

  const _Cell({required this.word, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          word,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: p.hint,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text.isEmpty ? '—' : text,
          style: TextStyle(fontSize: 13, height: 1.55, color: p.ink),
        ),
      ],
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String word;
  final String sentence;
  final String gloss;
  final String note;

  const _ExampleCard({
    required this.word,
    required this.sentence,
    required this.gloss,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    if (sentence.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          '$word 还没有例句，编辑时补一条',
          style: TextStyle(fontSize: 12.5, color: p.hint),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              word,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: p.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          highlightedText(
            sentence,
            word,
            style: TextStyle(fontSize: 15, height: 1.55, color: p.ink),
            highlightColor: p.primary,
          ),
          if (gloss.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              gloss,
              style: TextStyle(fontSize: 12.5, height: 1.5, color: p.muted),
            ),
          ],
          if (note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(note, style: TextStyle(fontSize: 11.5, color: p.hint)),
          ],
        ],
      ),
    );
  }
}
