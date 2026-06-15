import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_assistant/core/database/database_provider.dart';
import 'package:personal_assistant/core/theme/app_theme.dart';
import 'package:personal_assistant/core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeModeProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('设置')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Appearance section
            const _SectionHeader(title: '外观'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CupertinoColors.separator.withOpacity(0.3),
                  ),
                ),
                child: CupertinoListTile(
                  leading: const Icon(
                    CupertinoIcons.moon,
                    color: AppColors.primary,
                  ),
                  title: const Text('暗色模式'),
                  subtitle: Text(
                    _themeLabel(themeNotifier.themeMode),
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  trailing: CupertinoSwitch(
                    value: themeNotifier.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      ref
                          .read(themeModeProvider)
                          .setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Data management section
            const _SectionHeader(title: '数据管理'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CupertinoColors.separator.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    CupertinoListTile(
                      leading: const Icon(
                        CupertinoIcons.doc_text,
                        color: AppColors.primary,
                      ),
                      title: const Text('数据导出'),
                      subtitle: const Text(
                        '导出所有数据为 JSON 文件',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        color: CupertinoColors.systemGrey3,
                      ),
                      onTap: () => _exportData(context, ref),
                    ),
                    _DividerLine(),
                    CupertinoListTile(
                      leading: const Icon(
                        CupertinoIcons.doc_plaintext,
                        color: AppColors.primary,
                      ),
                      title: const Text('恢复数据'),
                      subtitle: const Text(
                        '从备份文件恢复所有数据',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        color: CupertinoColors.systemGrey3,
                      ),
                      onTap: () => _restoreData(context, ref),
                    ),
                    _DividerLine(),
                    CupertinoListTile(
                      leading: const Icon(
                        CupertinoIcons.delete,
                        color: CupertinoColors.destructiveRed,
                      ),
                      title: const Text(
                        '清除所有数据',
                        style: TextStyle(color: CupertinoColors.destructiveRed),
                      ),
                      subtitle: const Text(
                        '清空数据库中的所有记录',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        color: CupertinoColors.systemGrey3,
                      ),
                      onTap: () => _clearAllData(context, ref),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CupertinoColors.separator.withOpacity(0.3),
                  ),
                ),
                child: CupertinoListTile(
                  leading: const Icon(
                    CupertinoIcons.wrench,
                    color: AppColors.primary,
                  ),
                  title: const Text('压缩数据库'),
                  subtitle: const Text(
                    '执行 VACUUM 操作，回收已删除数据的磁盘空间',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  trailing: const Icon(
                    CupertinoIcons.chevron_right,
                    color: CupertinoColors.systemGrey3,
                  ),
                  onTap: () => _vacuumDatabase(context, ref),
                ),
              ),
            ),

            // Database size
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: FutureBuilder<int>(
                future: ref.read(databaseProvider).getDatabaseFileSize(),
                builder: (context, snapshot) {
                  final size = snapshot.data;
                  if (size == null) return const SizedBox.shrink();
                  return Text(
                    '数据库文件大小：${_formatSize(size)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.tertiaryLabel,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // About section
            const _SectionHeader(title: '关于'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CupertinoColors.separator.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            '拾光',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '版本 1.0.0+Phase5',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '点亮每个值得记录的时刻',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'Made with Flutter & Cupertino',
                style: TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.systemGrey3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _vacuumDatabase(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(databaseProvider).vacuumDatabase();
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => const CupertinoAlertDialog(
            title: Text('压缩完成'),
            content: Text('数据库已成功压缩，磁盘空间已回收。'),
            actions: [CupertinoDialogAction(child: Text('确定'))],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('压缩失败'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.light:
        return '浅色';
      default:
        return '跟随系统';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final dbHelper = ref.read(databaseProvider);
      final allData = await dbHelper.exportAllData();

      final dir = Directory(r'C:\pa\backup');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}\\backup_$timestamp.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(allData),
        flush: true,
      );

      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('导出成功'),
            content: Text('数据已导出到：\n${file.path}'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('导出失败'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _restoreData(BuildContext context, WidgetRef ref) async {
    final dir = Directory(r'C:\pa\backup');
    if (!await dir.exists()) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => const CupertinoAlertDialog(
            title: Text('无备份文件'),
            content: Text('未找到备份目录，请先导出数据。'),
            actions: [CupertinoDialogAction(child: Text('确定'))],
          ),
        );
      }
      return;
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    if (files.isEmpty) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => const CupertinoAlertDialog(
            title: Text('无备份文件'),
            content: Text('备份目录中没有找到 JSON 文件。'),
            actions: [CupertinoDialogAction(child: Text('确定'))],
          ),
        );
      }
      return;
    }

    files.sort((a, b) => b.path.compareTo(a.path));

    if (!context.mounted) return;
    final selected = await showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) => Container(
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择备份文件',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            _DividerLine(),
            Expanded(
              child: ListView.builder(
                itemCount: files.length,
                itemBuilder: (_, i) {
                  final name = files[i].uri.pathSegments.last;
                  return CupertinoListTile(
                    title: Text(name, style: const TextStyle(fontSize: 14)),
                    onTap: () => Navigator.pop(ctx, i),
                  );
                },
              ),
            ),
            CupertinoButton(
              child: const Text('取消'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );

    if (selected == null || !context.mounted) return;
    await _confirmAndRestore(context, ref, files[selected]);
  }

  Future<void> _confirmAndRestore(
    BuildContext context,
    WidgetRef ref,
    File file,
  ) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('确认恢复'),
        content: Text(
          '此操作将覆盖当前所有数据，\n确定从 "${file.uri.pathSegments.last}" 恢复吗？',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final typed = data.map(
        (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v as List)),
      );

      final dbHelper = ref.read(databaseProvider);
      await dbHelper.importAllData(typed);

      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => const CupertinoAlertDialog(
            title: Text('恢复成功'),
            content: Text('数据已成功恢复。'),
            actions: [CupertinoDialogAction(child: Text('确定'))],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('恢复失败'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('此操作将永久删除数据库中所有记录，\n且不可恢复。确定要继续吗？'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(databaseProvider).clearAllData();
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => const CupertinoAlertDialog(
            title: Text('已清除'),
            content: Text('所有数据已清除。'),
            actions: [CupertinoDialogAction(child: Text('确定'))],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('清除失败'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: CupertinoColors.separator.withOpacity(0.3),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel,
        ),
      ),
    );
  }
}
