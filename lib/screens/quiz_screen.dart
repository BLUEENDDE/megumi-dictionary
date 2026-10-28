import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/word_pair.dart';
import '../services/progress_store.dart';

enum _OptionState { idle, correct, wrong, dim }

class QuizScreen extends StatefulWidget {
  final List<WordPair> pairs;
  final ProgressStore? store;

  /// 仅用于截图预览：right = 自动选对，wrong = 自动选错。正式使用留空。
  final String? previewAnswer;

  const QuizScreen({
    super.key,
    required this.pairs,
    this.store,
    this.previewAnswer,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  late final List<QuizItem> _items;
  late final AnimationController _shake;

  int _index = 0;
  String? _selected;
  int _correct = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _items = _buildItems(widget.pairs);
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    final preview = widget.previewAnswer;
    if (preview != null && _items.isNotEmpty) {
      final first = _items.first;
      final target = preview == 'right'
          ? first.answer
          : first.options.firstWhere((o) => o != first.answer);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _choose(target);
      });
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  // ---------- 出题 ----------

  List<QuizItem> _buildItems(List<WordPair> pairs) {
    final random = math.Random();
    final items = <QuizItem>[];

    for (final pair in pairs) {
      final useFirst = random.nextBool();
      final answer = useFirst ? pair.first.form : pair.second.form;
      final other = useFirst ? pair.second.form : pair.first.form;
      final sentence =
          useFirst ? pair.example.firstText : pair.example.secondText;
      final gloss = useFirst ? pair.example.firstGloss : pair.example.secondGloss;
      final note = useFirst ? pair.example.firstNote : pair.example.secondNote;

      // 例句里没有目标词就出不了填空题，跳过这一组（用户自建的可能没填例句）。
      if (!sentence.toLowerCase().contains(answer.toLowerCase())) {
        continue;
      }

      final options = <String>[answer, other]..shuffle(random);

      items.add(
        QuizItem(
          pair: pair,
          prompt: _blankOut(sentence, answer),
          gloss: gloss,
          answer: answer,
          options: options,
          note: note,
        ),
      );
    }

    items.shuffle(random);
    return items;
  }

  String _blankOut(String sentence, String word) {
    final index = sentence.toLowerCase().indexOf(word.toLowerCase());
    if (index < 0) return sentence;
    return '${sentence.substring(0, index)}____'
        '${sentence.substring(index + word.length)}';
  }

  // ---------- 交互 ----------

  void _choose(String option) {
    if (_selected != null) return;

    final item = _items[_index];
    final isRight = option == item.answer;

    setState(() {
      _selected = option;
      if (isRight) _correct++;
    });

    widget.store?.record(item.pair.id, isRight);

    if (isRight) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
    }
  }

  void _next() {
    if (_index + 1 >= _items.length) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _selected = null;
      _correct = 0;
      _finished = false;
    });
  }

  // ---------- 界面 ----------

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('没有可练习的词对')),
      );
    }

    if (_finished) {
      return _ResultView(
        total: _items.length,
        correct: _correct,
        onRestart: _restart,
        onClose: () => Navigator.of(context).maybePop(),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final item = _items[_index];
    final answered = _selected != null;
    final isRight = _selected == item.answer;
    final progress = (_index + (answered ? 1 : 0)) / _items.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          '第 ${_index + 1} / ${_items.length} 题',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B6A63),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '答对 $_correct',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE8E5DD),
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                children: [
                  const Text(
                    '选词填空',
                    style: TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9A988F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      item.prompt,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1B18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) {
                      final t = _shake.value;
                      final dx = math.sin(t * math.pi * 5) * (1 - t) * 10;
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        for (final option in item.options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _OptionButton(
                              label: option,
                              state: _stateFor(option, item, answered),
                              onTap: answered ? null : () => _choose(option),
                              scheme: scheme,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: answered
                        ? Padding(
                            key: ValueKey('feedback-$_index'),
                            padding: const EdgeInsets.only(top: 12),
                            child: _FeedbackCard(
                              isRight: isRight,
                              item: item,
                              scheme: scheme,
                            ),
                          )
                        : Padding(
                            key: const ValueKey('hint'),
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              '想不起来也没关系，选完会告诉你这两个词差在哪。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.6,
                                color: const Color(0xFF9A988F),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: answered ? 1 : 0,
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: answered ? _next : null,
                    child: Text(
                      _index + 1 >= _items.length ? '看结果' : '继续',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
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

  _OptionState _stateFor(String option, QuizItem item, bool answered) {
    if (!answered) return _OptionState.idle;
    if (option == item.answer) return _OptionState.correct;
    if (option == _selected) return _OptionState.wrong;
    return _OptionState.dim;
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final _OptionState state;
  final VoidCallback? onTap;
  final ColorScheme scheme;

  const _OptionButton({
    required this.label,
    required this.state,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D4F);
    const red = Color(0xFFC2453E);

    Color border;
    Color fill;
    Color text;
    IconData? icon;

    switch (state) {
      case _OptionState.idle:
        border = const Color(0xFFE3E0D8);
        fill = Colors.white;
        text = const Color(0xFF1C1B18);
        icon = null;
      case _OptionState.correct:
        border = green;
        fill = green.withValues(alpha: 0.08);
        text = green;
        icon = Icons.check_circle_rounded;
      case _OptionState.wrong:
        border = red;
        fill = red.withValues(alpha: 0.08);
        text = red;
        icon = Icons.cancel_rounded;
      case _OptionState.dim:
        border = const Color(0xFFEDEBE4);
        fill = const Color(0xFFFAF9F5);
        text = const Color(0xFFA8A69C);
        icon = null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, size: 20, color: text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final bool isRight;
  final QuizItem item;
  final ColorScheme scheme;

  const _FeedbackCard({
    required this.isRight,
    required this.item,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D4F);
    const red = Color(0xFFC2453E);
    final color = isRight ? green : red;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRight ? Icons.check_circle_rounded : Icons.info_rounded,
                size: 17,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                isRight ? '对了' : '答案是 ${item.answer}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.gloss,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: Color(0xFF4A4941),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.note,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF8E8C82),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.pair.first.form} vs ${item.pair.second.form}：${item.pair.summary}',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: scheme.primary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final int total;
  final int correct;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const _ResultView({
    required this.total,
    required this.correct,
    required this.onRestart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = total == 0 ? 0.0 : correct / total;
    final message = ratio >= 0.9
        ? '这组已经很稳了'
        : ratio >= 0.6
            ? '有印象，再刷一遍会更好'
            : '先回词对里再看一眼对比';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            children: [
              const Spacer(),
              Text(
                '$correct / $total',
                style: const TextStyle(
                  fontSize: 56,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1B18),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF6B6A63),
                ),
              ),
              const SizedBox(height: 28),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8E5DD),
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onRestart,
                  child: const Text(
                    '再来一遍',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: TextButton(
                  onPressed: onClose,
                  child: const Text(
                    '回到词对',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B6A63),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
