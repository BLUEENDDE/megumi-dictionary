import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/dictionary.dart';
import '../services/progress_store.dart';
import '../theme/palette.dart';

class WordQuestion {
  final DictEntry answer;
  final List<DictEntry> options;

  const WordQuestion({required this.answer, required this.options});
}

/// 组题：每个词一道四选一，正确项 + 最多 3 个干扰项。
///
/// 干扰项会避开同一个词、同一个释义（很多词共用一条释义，不去重就会出现
/// 两个一模一样的选项，选哪个都算对/算错），也会跳过没有释义的词。
/// 词池为空或太小的时候宁可少给几个选项，也不抛异常。
List<WordQuestion> buildWordQuestions({
  required List<DictEntry> words,
  required List<DictEntry> pool,
  math.Random? random,
}) {
  if (words.isEmpty) return const [];

  final rnd = random ?? math.Random();
  final source = pool.isEmpty ? words : pool;
  final result = <WordQuestion>[];

  for (final word in words) {
    final options = <DictEntry>[word];
    final usedGlosses = <String>{_glossKey(word.gloss)};

    var guard = 0;
    while (options.length < 4 && guard < 400) {
      guard++;
      final candidate = source[rnd.nextInt(source.length)];
      if (candidate.word == word.word) continue;
      if (candidate.gloss.trim().isEmpty) continue;
      if (!usedGlosses.add(_glossKey(candidate.gloss))) continue;
      options.add(candidate);
    }

    options.shuffle(rnd);
    result.add(WordQuestion(answer: word, options: options));
  }

  return result;
}

/// 比较释义是否重复时忽略大小写和首尾空白。
String _glossKey(String gloss) => gloss.trim().toLowerCase();

/// 单词四选一：给印尼语词，选正确的中文释义。
class WordQuizScreen extends StatefulWidget {
  final String title;
  final List<DictEntry> words;
  final List<DictEntry> pool;
  final ProgressStore store;

  const WordQuizScreen({
    super.key,
    required this.title,
    required this.words,
    required this.pool,
    required this.store,
  });

  @override
  State<WordQuizScreen> createState() => _WordQuizScreenState();
}

class _WordQuizScreenState extends State<WordQuizScreen>
    with SingleTickerProviderStateMixin {
  late final List<WordQuestion> _questions;
  late final AnimationController _shake;

  int _index = 0;
  DictEntry? _picked;
  int _correct = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = buildWordQuestions(words: widget.words, pool: widget.pool);
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _pick(DictEntry entry) {
    if (_picked != null) return;
    final question = _questions[_index];
    final isRight = entry.word == question.answer.word;

    setState(() {
      _picked = entry;
      if (isRight) _correct++;
    });

    widget.store.record('w:${question.answer.word}', isRight);

    if (isRight) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
    }
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    if (_questions.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '没有可练的词',
                  style: TextStyle(fontSize: 15, color: p.muted),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_finished) {
      final total = _questions.length;
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_correct / $total',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '这一组过完了',
                  style: TextStyle(fontSize: 14, color: p.muted),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 220,
                  height: 48,
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
                    onPressed: () => Navigator.of(context).maybePop(_correct),
                    child: const Text(
                      '完成',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_index];
    final answered = _picked != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(_correct),
        ),
        title: Text(
          '${widget.title} · ${_index + 1}/${_questions.length}',
          style: TextStyle(fontSize: 14, color: p.muted),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_index + (answered ? 1 : 0)) / _questions.length,
                  minHeight: 4,
                  backgroundColor: p.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(p.primary),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 26,
                    ),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      question.answer.word,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) {
                      final t = _shake.value;
                      final dx = math.sin(t * math.pi * 5) * (1 - t) * 9;
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        for (final option in question.options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _Option(
                              text: option.gloss.isEmpty ? '—' : option.gloss,
                              state: _stateOf(
                                option,
                                question,
                                answered,
                              ),
                              onTap: answered ? null : () => _pick(option),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                  onPressed: answered ? _next : null,
                  child: Text(
                    _index + 1 >= _questions.length ? '看结果' : '继续',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

  _OptionState _stateOf(
    DictEntry option,
    WordQuestion question,
    bool answered,
  ) {
    if (!answered) return _OptionState.idle;
    if (option.word == question.answer.word) return _OptionState.correct;
    if (identical(option, _picked)) return _OptionState.wrong;
    return _OptionState.dim;
  }
}

enum _OptionState { idle, correct, wrong, dim }

class _Option extends StatelessWidget {
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  const _Option({required this.text, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    late final Color border;
    late final Color fill;
    late final Color ink;
    IconData? icon;

    switch (state) {
      case _OptionState.idle:
        border = p.divider;
        fill = p.card;
        ink = p.ink;
      case _OptionState.correct:
        border = p.success;
        fill = p.success.withValues(alpha: 0.1);
        ink = p.success;
        icon = Icons.check_circle_rounded;
      case _OptionState.wrong:
        border = p.danger;
        fill = p.danger.withValues(alpha: 0.1);
        ink = p.danger;
        icon = Icons.cancel_rounded;
      case _OptionState.dim:
        border = p.divider.withValues(alpha: 0.6);
        fill = p.chipBg.withValues(alpha: 0.5);
        ink = p.hint;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 14, height: 1.5, color: ink),
                  ),
                ),
                if (icon != null) Icon(icon, size: 18, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
