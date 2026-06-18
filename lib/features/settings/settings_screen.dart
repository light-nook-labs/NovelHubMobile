import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/providers.dart';
import '../../app/theme.dart';
import '../../app/theme_provider.dart';
import '../../app/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // Appearance section
          _SectionHeader(title: '外观'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _ThemeModeTile(
                  currentMode: themeMode,
                  onChanged: (mode) {
                    ref
                        .read(themeModeNotifierProvider.notifier)
                        .setThemeMode(mode);
                  },
                ),
              ],
            ),
          ),

          // Sync section
          _SectionHeader(title: '数据管理'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.upload_file,
                    color: AppColors.primary,
                  ),
                  title: const Text('导入数据库'),
                  subtitle: const Text('从本地文件导入 SQLite 数据库'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importDatabase(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore, color: AppColors.primary),
                  title: const Text('重置数据'),
                  subtitle: const Text('重置为默认数据库'),
                  onTap: () => _showClearDialog(context, ref),
                ),
              ],
            ),
          ),

          // Feedback section
          _SectionHeader(title: '反馈与支持'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.bug_report,
                    color: AppColors.primary,
                  ),
                  title: const Text('报告 Bug'),
                  subtitle: const Text('在 GitHub Issues 提交问题'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchUrl(
                    'https://github.com/light-nook-labs/NovelHubMobile/issues/new?template=bug_report.yml',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.lightbulb,
                    color: AppColors.primary,
                  ),
                  title: const Text('功能建议'),
                  subtitle: const Text('在 GitHub Issues 提交建议'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchUrl(
                    'https://github.com/light-nook-labs/NovelHubMobile/issues/new?template=feature_request.yml',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.description,
                    color: AppColors.primary,
                  ),
                  title: const Text('导出日志'),
                  subtitle: const Text('导出应用日志用于调试'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportLogs(context),
                ),
              ],
            ),
          ),

          // About section
          _SectionHeader(title: '关于'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info, color: AppColors.primary),
                  title: Text('Novel Hub Mobile'),
                  subtitle: Text('离线优先的小说元数据浏览器'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.tag, color: AppColors.primary),
                  title: Text('版本'),
                  subtitle: Text('0.1.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code, color: AppColors.primary),
                  title: const Text('GitHub'),
                  subtitle: const Text('light-nook-labs/NovelHubMobile'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchUrl(
                    'https://github.com/light-nook-labs/NovelHubMobile',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage, color: AppColors.primary),
                  title: const Text('数据来源'),
                  subtitle: const Text('light-nook-labs/novel_hub'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchUrl(
                    'https://github.com/light-nook-labs/novel_hub',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.description, color: AppColors.primary),
                  title: Text('技术栈'),
                  subtitle: Text('Flutter, Riverpod, drift, dio, go_router'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _importDatabase(BuildContext context, WidgetRef ref) async {
    try {
      // Pick SQLite file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['sqlite', 'db'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件不存在')),
          );
        }
        return;
      }

      if (!context.mounted) return;

      // Copy file to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final chunksDir = Directory('${appDir.path}/chunks');
      if (!await chunksDir.exists()) {
        await chunksDir.create(recursive: true);
      }
      
      final chunkPath = '${chunksDir.path}/hot_chunk.sqlite';
      await file.copy(chunkPath);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入成功')),
      );

      // Refresh statistics
      Future.microtask(() {
        ref.invalidate(statisticsProvider);
        ref.invalidate(dbMergeTimeProvider);
      });
    } catch (e) {
      if (!context.mounted) return;
      // Try to pop dialog if it's showing
      try {
        Navigator.of(context).pop();
      } catch (_) {}
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重置数据'),
        content: const Text('将重置为默认数据库，确定继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Delete all chunks
              final appDir = await getApplicationDocumentsDirectory();
              final chunksDir = Directory('${appDir.path}/chunks');
              if (await chunksDir.exists()) {
                await chunksDir.delete(recursive: true);
              }

              // Delete merged database
              final dbFile = File('${appDir.path}/novel_hub.sqlite');
              if (await dbFile.exists()) {
                await dbFile.delete();
              }

              if (context.mounted) {
                Future.microtask(() {
                  ref.invalidate(statisticsProvider);
                  ref.invalidate(dbMergeTimeProvider);
                  ref.invalidate(bannerNovelsProvider);
                  ref.invalidate(authorsWithStatsProvider);
                  ref.invalidate(novelCountProvider);
                });
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已重置为默认数据库')));
              }
            },
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportLogs(BuildContext context) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logFile = File('${appDir.path}/novel_hub.log');
      
      // Create a sample log file if it doesn't exist
      if (!await logFile.exists()) {
        await logFile.writeAsString(
          'Novel Hub Mobile Log\n'
          'Created: ${DateTime.now().toIso8601String()}\n'
          'Platform: ${Platform.operatingSystem}\n'
          'Version: 0.1.0\n',
        );
      }

      if (!context.mounted) return;

      // Share the log file
      await Share.shareXFiles(
        [XFile(logFile.path)],
        subject: 'Novel Hub Mobile 日志',
        text: 'Novel Hub Mobile 应用日志',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出日志失败: $e')));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeTile({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.brightness_6, color: AppColors.primary),
      title: const Text('主题模式'),
      subtitle: Text(_getModeName(currentMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context),
    );
  }

  String _getModeName(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => '跟随系统',
      ThemeMode.light => '浅色模式',
      ThemeMode.dark => '深色模式',
    };
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              icon: Icons.brightness_auto,
              label: '跟随系统',
              isSelected: currentMode == ThemeMode.system,
              onTap: () {
                onChanged(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.light_mode,
              label: '浅色模式',
              isSelected: currentMode == ThemeMode.light,
              onTap: () {
                onChanged(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.dark_mode,
              label: '深色模式',
              isSelected: currentMode == ThemeMode.dark,
              onTap: () {
                onChanged(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : null),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
