import 'package:flutter/material.dart';

import '../models/word_pair.dart';
import '../widgets/ui_kit.dart';
import 'quiz_screen.dart';

class DetailScreen extends StatelessWidget {
  final WordPair pair;

  const DetailScreen({super.key, required this.pair});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const ink = Color(0xFF1C1B18);
    const muted = Color(0xFF6B6A63);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('${pair.first.form} / ${pair.second.form}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          _Header(pair: pair, scheme: scheme),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pair.summary,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      color: scheme.primary.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            '差异板块',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '一条轴看一个区别，逐条比过去',
            style: TextStyle(fontSize: 12.5, color: muted),
          ),
          const SizedBox(height: 12),
          for (final axis in pair.axes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AxisCard(pair: pair, axis: axis, scheme: scheme),
            ),
          const SizedBox(height: 18),
          const Text(
            '最小对比句',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '同一件事，两个词说出来的味道不一样',
            style: TextStyle(fontSize: 12.5, color: muted),
          ),
          const SizedBox(height: 12),
          _ExampleCard(
            word: pair.first.form,
            sentence: pair.example.firstText,
            gloss: pair.example.firstGloss,
            note: pair.example.firstNote,
            scheme: scheme,
          ),
          const SizedBox(height: 10),
          _ExampleCard(
            word: pair.second.form,
            sentence: pair.example.secondText,
            gloss: pair.example.secondGloss,
            note: pair.example.secondNote,
            scheme: scheme,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                fadeUpRoute(QuizScreen(pairs: [pair])),
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
  final ColorScheme scheme;

  const _Header({required this.pair, required this.scheme});

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFF6B6A63);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: const Color(0xFFF1EFE9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'vs',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: muted,
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
    const ink = Color(0xFF1C1B18);
    const muted = Color(0xFF6B6A63);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sense.form,
          style: const TextStyle(
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sense.gloss,
          style: const TextStyle(fontSize: 12.5, height: 1.5, color: muted),
        ),
      ],
    );
  }
}

class _AxisCard extends StatelessWidget {
  final WordPair pair;
  final ContrastAxis axis;
  final ColorScheme scheme;

  const _AxisCard({
    required this.pair,
    required this.axis,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1C1B18);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Cell(
                  word: pair.first.form,
                  text: axis.first,
                  color: ink,
                ),
              ),
              Container(
                width: 1,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: const Color(0xFFEDEBE4),
              ),
              Expanded(
                child: _Cell(
                  word: pair.second.form,
                  text: axis.second,
                  color: ink,
                ),
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
  final Color color;

  const _Cell({required this.word, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          word,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9A988F),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: TextStyle(fontSize: 13, height: 1.55, color: color),
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
  final ColorScheme scheme;

  const _ExampleCard({
    required this.word,
    required this.sentence,
    required this.gloss,
    required this.note,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1C1B18);
    const muted = Color(0xFF6B6A63);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  word,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          highlightedText(
            sentence,
            word,
            style: const TextStyle(fontSize: 15, height: 1.55, color: ink),
            highlightColor: scheme.primary,
          ),
          const SizedBox(height: 6),
          Text(
            gloss,
            style: const TextStyle(fontSize: 12.5, height: 1.5, color: muted),
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF9A988F),
            ),
          ),
        ],
      ),
    );
  }
}
