import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/word_pair.dart';
import '../services/backup_service.dart';
import '../services/progress_store.dart';
import '../services/settings_store.dart';
import '../services/user_pairs_store.dart';
import '../theme/palette.dart';
import 'text_import_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ProgressStore progress;
  final UserPairsStore userPairs;

  /// 作为底部页签嵌入时为 true：不显示返回键。
  final bool embedded;

  const SettingsScreen({
    super.key,
    required this.progress,
    required this.userPairs,
    this.embedded = false,
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

  String _backupHint(int? lastBackup) {
    if (lastBackup == null) return '还没备份过 · 换设备前务必先导一份';
    final at = DateTime.fromMillisecondsSinceEpoch(lastBackup);
    final days = DateTime.now().difference(at).inDays;
    if (days <= 0) return '上次备份：今天';
    if (days == 1) return '上次备份：昨天';
    return '上次备份：$days 天前';
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
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '两种存法：复制到剪贴板，或点「发送到…」直接发到自己的微信 / 邮箱 / 网盘。'
                  '换手机或重装后，用「导入备份」把这段文字粘回来就能恢复。',
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
            TextButton(
              onPressed: () async {
                var shared = false;
                try {
                  await SharePlus.instance.share(
                    ShareParams(
                      text: text,
                      subject: '印尼语背词 备份',
                    ),
                  );
                  shared = true;
                } catch (_) {
                  // 分享面板不可用（部分设备/模拟器），退回复制，别让用户白点。
                  shared = false;
                }
                await SettingsStore().markBackedUp();
                if (!shared) {
                  await Clipboard.setData(ClipboardData(text: text));
                }
                if (context.mounted) Navigator.of(context).pop();
                if (mounted) setState(() {});
                _toast(
                  shared ? '已发送，记得把内容存好' : '分享不可用，已改为复制到剪贴板',
                );
              },
              child: const Text('发送到…'),
            ),
            FilledButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                await SettingsStore().markBackedUp();
                if (context.mounted) Navigator.of(context).pop();
                if (mounted) setState(() {});
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
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '把之前导出的那段文字粘进来。会合并自建词库，同名的以导入为准。',
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

      // 自建词库：按 id 合并，导入的覆盖同 id 的
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
        content: const Text('自建词库会保留，但练习记录和正确率会全部清零。'),
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
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: const Text('我的'),
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
          const _SectionTitle('词库'),
          _Card(
            child: Column(
              children: [
                _Tile(
                  icon: Icons.add_circle_outline_rounded,
                  title: '添加单词',
                  subtitle: '一行一组词对，粘贴文本批量录入',
                  onTap: () async {
                    final added = await Navigator.of(context).push<int>(
                      MaterialPageRoute(
                        builder: (_) => TextImportScreen(
                          userPairs: widget.userPairs,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    if (added != null && added > 0) {
                      setState(() {});
                      _toast('已添加 $added 组词对');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('数据'),
          ValueListenableBuilder<int?>(
            valueListenable: SettingsStore.lastBackupAt,
            builder: (context, lastBackup, _) {
              return _Card(
                child: Column(
                  children: [
                    _Tile(
                      icon: Icons.upload_rounded,
                      title: '导出备份',
                      subtitle: _backupHint(lastBackup),
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
              );
            },
          ),
          const SizedBox(height: 24),
          const _SectionTitle('关于'),
          _Card(
            child: Column(
              children: [
                _InfoRow(label: '名称', value: 'megumi辞書'),
                const SizedBox(height: 10),
                _InfoRow(label: '自建词库', value: '${widget.userPairs.pairs.length} 组'),
                const SizedBox(height: 10),
                _InfoRow(label: '已掌握', value: '${widget.progress.trainedPairs} 组'),
                const SizedBox(height: 10),
                _InfoRow(label: '版本', value: '3.1.0'),
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
