import 'package:flutter/material.dart';

import '../models/word_pair.dart';
import '../theme/palette.dart';

class AddPairScreen extends StatefulWidget {
  /// 传了就是编辑，没传就是新建。
  final WordPair? initial;

  const AddPairScreen({super.key, this.initial});

  @override
  State<AddPairScreen> createState() => _AddPairScreenState();
}

class _AxisDraft {
  final TextEditingController name;
  final TextEditingController first;
  final TextEditingController second;

  _AxisDraft({String name = '', String first = '', String second = ''})
      : name = TextEditingController(text: name),
        first = TextEditingController(text: first),
        second = TextEditingController(text: second);

  void dispose() {
    name.dispose();
    first.dispose();
    second.dispose();
  }
}

class _AddPairScreenState extends State<AddPairScreen> {
  late final TextEditingController _formA;
  late final TextEditingController _glossA;
  late final TextEditingController _formB;
  late final TextEditingController _glossB;
  late final TextEditingController _summary;
  late final TextEditingController _tag;
  late final TextEditingController _sentenceA;
  late final TextEditingController _glossSentenceA;
  late final TextEditingController _sentenceB;
  late final TextEditingController _glossSentenceB;

  final List<_AxisDraft> _axes = [];

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    _formA = TextEditingController(text: initial?.first.form ?? '');
    _glossA = TextEditingController(
      text: initial == null || initial.first.gloss == '（还没写释义）'
          ? ''
          : initial.first.gloss,
    );
    _formB = TextEditingController(text: initial?.second.form ?? '');
    _glossB = TextEditingController(
      text: initial == null || initial.second.gloss == '（还没写释义）'
          ? ''
          : initial.second.gloss,
    );
    _summary = TextEditingController(text: initial?.summary ?? '');
    _tag = TextEditingController(
      text: initial == null || initial.tag == '自建' ? '' : initial.tag,
    );
    _sentenceA = TextEditingController(text: initial?.example.firstText ?? '');
    _glossSentenceA =
        TextEditingController(text: initial?.example.firstGloss ?? '');
    _sentenceB = TextEditingController(text: initial?.example.secondText ?? '');
    _glossSentenceB =
        TextEditingController(text: initial?.example.secondGloss ?? '');

    if (initial != null && initial.axes.isNotEmpty) {
      for (final axis in initial.axes) {
        _axes.add(
          _AxisDraft(name: axis.name, first: axis.first, second: axis.second),
        );
      }
    } else {
      _axes.add(_AxisDraft());
    }
  }

  @override
  void dispose() {
    for (final c in [
      _formA,
      _glossA,
      _formB,
      _glossB,
      _summary,
      _tag,
      _sentenceA,
      _glossSentenceA,
      _sentenceB,
      _glossSentenceB,
    ]) {
      c.dispose();
    }
    for (final axis in _axes) {
      axis.dispose();
    }
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    final a = _formA.text.trim();
    final b = _formB.text.trim();
    final summary = _summary.text.trim();

    if (a.isEmpty || b.isEmpty) {
      _toast('两个词都要填');
      return;
    }
    if (summary.isEmpty) {
      _toast('写一句「差在哪」，这是这个词对的灵魂');
      return;
    }

    final axes = <ContrastAxis>[];
    for (final draft in _axes) {
      final name = draft.name.text.trim();
      if (name.isEmpty) continue;
      axes.add(
        ContrastAxis(
          name: name,
          first: draft.first.text.trim(),
          second: draft.second.text.trim(),
        ),
      );
    }

    final pair = WordPair(
      id: widget.initial?.id ??
          'user-${DateTime.now().millisecondsSinceEpoch}',
      tag: _tag.text.trim().isEmpty ? '自建' : _tag.text.trim(),
      summary: summary,
      first: WordSense(
        form: a,
        gloss: _glossA.text.trim().isEmpty ? '（还没写释义）' : _glossA.text.trim(),
      ),
      second: WordSense(
        form: b,
        gloss: _glossB.text.trim().isEmpty ? '（还没写释义）' : _glossB.text.trim(),
      ),
      axes: axes,
      example: ExamplePair(
        firstText: _sentenceA.text.trim(),
        firstGloss: _glossSentenceA.text.trim(),
        firstNote: '用 $a 的场合',
        secondText: _sentenceB.text.trim(),
        secondGloss: _glossSentenceB.text.trim(),
        secondNote: '用 $b 的场合',
      ),
    );

    Navigator.of(context).pop(pair);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(_isEditing ? '编辑词对' : '添加词对'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _save,
              child: Text(
                '保存',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SectionLabel('两个词'),
          _Field(label: '词 A', hint: '例如 besar', controller: _formA),
          const SizedBox(height: 10),
          _Field(
            label: 'A 的意思',
            hint: '例如 大（体积、尺寸）',
            controller: _glossA,
          ),
          const SizedBox(height: 16),
          _Field(label: '词 B', hint: '例如 luas', controller: _formB),
          const SizedBox(height: 10),
          _Field(
            label: 'B 的意思',
            hint: '例如 大（面积、范围）',
            controller: _glossB,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('差在哪'),
          _Field(
            label: '一句话说明',
            hint: '例如 besar 说体积，luas 说面积',
            controller: _summary,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _Field(label: '标签（可空）', hint: '例如 尺寸 / 面积', controller: _tag),
          const SizedBox(height: 24),
          Row(
            children: [
              const _SectionLabel('差异板块'),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _axes.add(_AxisDraft())),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('加一条', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '一条轴看一个区别，比如「适用对象」「常见搭配」「语域」。留空不填也行。',
              style: TextStyle(fontSize: 12, height: 1.5, color: p.hint),
            ),
          ),
          for (var i = 0; i < _axes.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AxisCard(
                index: i,
                draft: _axes[i],
                canRemove: _axes.length > 1,
                onRemove: () {
                  setState(() {
                    _axes.removeAt(i).dispose();
                  });
                },
              ),
            ),
          const SizedBox(height: 14),
          const _SectionLabel('对比句（可空，但填了复习才出这道题）'),
          const SizedBox(height: 10),
          _Field(
            label: 'A 的例句',
            hint: '例句里要出现词 A，例如 Mereka tinggal di rumah yang besar.',
            controller: _sentenceA,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _Field(
            label: 'A 例句的中文',
            hint: '他们住在一栋大房子里。',
            controller: _glossSentenceA,
          ),
          const SizedBox(height: 16),
          _Field(
            label: 'B 的例句',
            hint: '例句里要出现词 B，例如 Lapangan itu sangat luas.',
            controller: _sentenceB,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _Field(
            label: 'B 例句的中文',
            hint: '那个操场很大。',
            controller: _glossSentenceB,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: p.primary,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontSize: 15, color: p.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: 12.5, color: p.hint),
        hintStyle: TextStyle(fontSize: 13.5, color: p.hint.withValues(alpha: 0.7)),
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: p.primary.withValues(alpha: 0.5),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _AxisCard extends StatelessWidget {
  final int index;
  final _AxisDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;

  const _AxisCard({
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '轴 ${index + 1}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: p.hint,
                ),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  iconSize: 18,
                  color: p.hint,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          TextField(
            controller: draft.name,
            style: TextStyle(fontSize: 14, color: p.ink),
            decoration: InputDecoration(
              hintText: '这条轴叫什么，例如「语域」',
              hintStyle: TextStyle(fontSize: 13, color: p.hint.withValues(alpha: 0.7)),
              isDense: true,
              border: InputBorder.none,
            ),
          ),
          Divider(height: 18, color: p.divider),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.first,
                  style: TextStyle(fontSize: 13.5, color: p.ink),
                  decoration: InputDecoration(
                    hintText: '词 A 在这条轴上',
                    hintStyle:
                        TextStyle(fontSize: 12.5, color: p.hint.withValues(alpha: 0.7)),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: draft.second,
                  style: TextStyle(fontSize: 13.5, color: p.ink),
                  decoration: InputDecoration(
                    hintText: '词 B 在这条轴上',
                    hintStyle:
                        TextStyle(fontSize: 12.5, color: p.hint.withValues(alpha: 0.7)),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
