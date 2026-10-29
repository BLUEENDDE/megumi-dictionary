import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/word_pair.dart';
import '../services/user_pairs_store.dart';
import '../services/word_text_import.dart';
import '../theme/palette.dart';

class TextImportScreen extends StatefulWidget {
  final UserPairsStore userPairs;

  const TextImportScreen({super.key, required this.userPairs});

  @override
  State<TextImportScreen> createState() => _TextImportScreenState();
}

class _TextImportScreenState extends State<TextImportScreen> {
  final TextEditingController _text = TextEditingController();
  ImportParseResult _parsed =
      const ImportParseResult(drafts: [], errors: []);

  @override
  void initState() {
    super.initState();
    _text.addListener(_reparse);
  }

  @override
  void dispose() {
    _text.removeListener(_reparse);
    _text.dispose();
    super.dispose();
  }

  void _reparse() {
    setState(() => _parsed = parseWordList(_text.text));
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    _text.text = text;
  }

  Future<void> _import() async {
    if (_parsed.drafts.isEmpty) return;
    final stamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < _parsed.drafts.length; i++) {
      final draft = _parsed.drafts[i];
      await widget.userPairs.add(
        WordPair(
          id: 'user-$stamp-$i',
          tag: '导入',
          summary: draft.summary,
          first: WordSense(form: draft.first, gloss: draft.firstGloss),
          second: WordSense(form: draft.second, gloss: draft.secondGloss),
          axes: const [],
          example: const ExamplePair(
            firstText: '',
            firstGloss: '',
            firstNote: '',
            secondText: '',
            secondGloss: '',
            secondNote: '',
          ),
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(_parsed.drafts.length);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final count = _parsed.drafts.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('添加单词'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '一行一组词对，用竖线或逗号分开：\n'
              '词A | 释义A | 词B | 释义B | 差在哪（可省）\n\n'
              '例：besar | 大（体积） | luas | 大（面积） | 体积 vs 面积\n'
              '以 # 开头的行会被忽略。',
              style: TextStyle(fontSize: 12, height: 1.8, color: p.primary),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            maxLines: 12,
            minLines: 8,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              fontFamily: 'monospace',
              color: p.ink,
            ),
            decoration: InputDecoration(
              hintText: '在这里粘贴或输入…',
              hintStyle: TextStyle(fontSize: 13, color: p.hint),
              filled: true,
              fillColor: p.card,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                label: const Text('从剪贴板粘贴', style: TextStyle(fontSize: 13)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _text.clear(),
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: const Text('清空', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (count > 0)
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 16, color: p.success),
                const SizedBox(width: 6),
                Text(
                  '识别到 $count 组词对',
                  style: TextStyle(fontSize: 13, color: p.success),
                ),
              ],
            ),
          for (final error in _parsed.errors)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded, size: 15, color: p.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(fontSize: 12, height: 1.5, color: p.danger),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor:
                  context.isDark ? const Color(0xFF10231F) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: count > 0 ? _import : null,
            child: Text(
              count > 0 ? '添加 $count 组' : '还没有可添加的内容',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
