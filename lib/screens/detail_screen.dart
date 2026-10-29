import 'package:flutter/material.dart';

import '../models/word_pair.dart';
import '../services/progress_store.dart';
import '../services/user_pairs_store.dart';
import '../theme/palette.dart';
import '../widgets/ui_kit.dart';
import 'add_pair_screen.dart';
import 'quiz_screen.dart';

class DetailScreen extends StatefulWidget {
  final WordPair pair;
  final ProgressStore store;
  final UserPairsStore? userPairs;

  const DetailScreen({
    super.key,
    required this.pair,
    required this.store,
    this.userPairs,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late WordPair _pair;

  @override
  void initState() {
    super.initState();
    _pair = widget.pair;
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<WordPair>(
      fadeUpRoute(AddPairScreen(initial: _pair)),
    );
    if (updated == null) return;
    await widget.userPairs?.update(updated);
    if (!mounted) return;
    setState(() => _pair = updated);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final editable = _pair.isUserMade && widget.userPairs != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('${_pair.first.form} / ${_pair.second.form}'),
        actions: [
          if (editable)
            IconButton(
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: '编辑',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          _Header(pair: _pair),
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
                    _pair.summary,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      color: p.primary,
                    ),
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
          if (_pair.axes.isEmpty)
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
          for (final axis in _pair.axes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AxisCard(pair: _pair, axis: axis),
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
            word: _pair.first.form,
            sentence: _pair.example.firstText,
            gloss: _pair.example.firstGloss,
            note: _pair.example.firstNote,
          ),
          const SizedBox(height: 10),
          _ExampleCard(
            word: _pair.second.form,
            sentence: _pair.example.secondText,
            gloss: _pair.example.secondGloss,
            note: _pair.example.secondNote,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          height: 52,
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
            onPressed: () {
              Navigator.of(context).push(
                fadeUpRoute(QuizScreen(pairs: [_pair], store: widget.store)),
              );
            },
            icon: const Icon(Icons.bolt_rounded, size: 20),
            label: const Text(
              '练这一组',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final WordPair pair;

  const _Header({required this.pair});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _Side(sense: pair.first)),
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
          Expanded(child: _Side(sense: pair.second)),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final WordSense sense;

  const _Side({required this.sense});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sense.form,
          style: TextStyle(
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
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
              Expanded(
                child: _Cell(word: pair.first.form, text: axis.first),
              ),
              Container(
                width: 1,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: p.divider,
              ),
              Expanded(
                child: _Cell(word: pair.second.form, text: axis.second),
              ),
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
