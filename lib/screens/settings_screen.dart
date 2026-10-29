import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/word_pair.dart';
import '../services/backup_service.dart';
import '../services/progress_store.dart';
import '../services/settings_store.dart';
import '../services/user_pairs_store.dart';
import '../theme/palette.dart';

class SettingsScreen extends StatefulWidget {
  final ProgressStore progress;
  final UserPairsStore userPairs;

  const SettingsScreen({
    super.key,
    required this.progress,
    required this.userPairs,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export() async {
    final text = BackupService.encode(
      userPairs: widget.userPairs.pairs,
      progress: widget.progress,
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final p = context.pal;
        return AlertDialog(
          title: const Text('导出备份'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '复制下面这段文字，存到备忘录或网盘里。换手机时用「导入备份」粘回来。',
                  style: TextStyle(fontSize: 12.5, height: 1.6, color: p.muted),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      text,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.4,
                        fontFamily: 'monospace',
                        color: p.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
            FilledButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) Navigator.of(context).pop();
                _toast('已复制到剪贴板');
              },
              child: const Text('复制'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _import() async {
    final controller = TextEditingController();

    final raw = await showDialog<String>(
      context: context,
      builder: (context) {
        final p = context.pal;
        return AlertDialog(
          title: const Text('导入备份'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '把之前导出的那段文字粘进来。会合并自建词对，同名的以导入为准。',
                  style: TextStyle(fontSize: 12.5, height: 1.6, color: p.muted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 8,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: '粘贴备份内容…',
                    filled: true,
                    fillColor: p.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('导入'),
            ),
          ],
        );
      },
    );

    if (raw == null || raw.trim().isEmpty) return;

    try {
      final data = BackupService.decode(raw.trim());

      // 自建词对：按 id 合并，导入的覆盖同 id 的
      final merged = <String, WordPair>{
        for (final pair in widget.userPairs.pairs) pair.id: pair,
      };
      for (final pair in data.userPairs) {
        merged[pair.id] = pair;
      }
      await widget.userPairs.replaceAll(merged.values.toList());

      // 进度：合并覆盖
      final progressJson = widget.progress.toJson();
      final importedPairs =
          data.progress['pairs'] as Map<String, dynamic>? ?? {};
      final ownPairs = progressJson['pairs'] as Map<String, dynamic>;
      progressJson['pairs'] = {...ownPairs, ...importedPairs};
      final importedDaily =
          data.progress['daily'] as Map<String, dynamic>? ?? {};
      final ownDaily = progressJson['daily'] as Map<String, dynamic>;
      progressJson['daily'] = {...ownDaily, ...importedDaily};

      widget.progress.loadFromMap(progressJson);
      await widget.progress.persist();

      if (!mounted) return;
      setState(() {});
      _toast('导入完成：${data.userPairs.length} 组词对');
    } on FormatException catch (e) {
      _toast('导入失败：${e.message}');
    } catch (e) {
      _toast('导入失败：$e');
    }
  }

  Future<void> _resetProgress() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空学习进度？'),
        content: const Text('自建词对会保留，但练习记录和正确率会全部清零。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('算了'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('清空', style: TextStyle(color: context.pal.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.progress.reset();
    if (!mounted) return;
    setState(() {});
    _toast('进度已清空');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SectionTitle('外观'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: SettingsStore.themeMode,
            builder: (context, mode, _) {
              return _Card(
                child: Column(
                  children: [
                    for (final option in const [
                      (ThemeMode.system, '跟随系统'),
                      (ThemeMode.light, '浅色'),
                      (ThemeMode.dark, '深色'),
                    ])
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          await SettingsStore().setThemeMode(option.$1);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                mode == option.$1
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                size: 19,
                                color: mode == option.$1 ? p.primary : p.hint,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                option.$2,
                                style: TextStyle(fontSize: 14, color: p.ink),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const _SectionTitle('数据'),
          _Card(
            child: Column(
              children: [
                _Tile(
                  icon: Icons.upload_rounded,
                  title: '导出备份',
                  subtitle: '把词对和进度变成一段文字，复制走',
                  onTap: _export,
                ),
                Divider(color: p.divider, height: 1),
                _Tile(
                  icon: Icons.download_rounded,
                  title: '导入备份',
                  subtitle: '粘贴之前导出的文字，恢复数据',
                  onTap: _import,
                ),
                Divider(color: p.divider, height: 1),
                _Tile(
                  icon: Icons.restart_alt_rounded,
                  title: '清空学习进度',
                  subtitle: '保留词对，只清记录',
                  danger: true,
                  onTap: _resetProgress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('关于'),
          _Card(
            child: Column(
              children: [
                _InfoRow(label: '自建词对', value: '${widget.userPairs.pairs.length} 组'),
                const SizedBox(height: 10),
                _InfoRow(label: '已掌握', value: '${widget.progress.trainedPairs} 组'),
                const SizedBox(height: 10),
                _InfoRow(label: '版本', value: '0.5.0'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
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

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final color = danger ? p.danger : p.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: danger ? p.danger : p.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, color: p.hint),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: p.hint),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: p.muted)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
