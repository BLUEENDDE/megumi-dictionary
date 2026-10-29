import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/dictionary.dart';
import '../theme/palette.dart';

/// 词典条目的详情弹层。
void showDictEntrySheet(BuildContext context, DictEntry entry) {
  final p = context.pal;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (context) {
      final bp = context.pal;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: bp.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              entry.word,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: bp.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '原文第 ${entry.page} 页',
              style: TextStyle(fontSize: 11.5, color: bp.hint),
            ),
            const SizedBox(height: 14),
            Text(
              entry.gloss.isEmpty ? '（这一条没识别出释义）' : entry.gloss,
              style: TextStyle(fontSize: 14.5, height: 1.75, color: bp.ink),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: '${entry.word}\n${entry.gloss}'),
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('复制'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
