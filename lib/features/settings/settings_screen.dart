import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

import '../../data/repositories/providers.dart';
import '../../data/services/chunked_sync_service.dart';
import '../../app/theme.dart';
import '../../app/theme_provider.dart';
import '../../app/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);
    final hideOther = ref.watch(hideOtherNotifierProvider);

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
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.visibility_off,
                    color: AppColors.primary,
                  ),
                  title: const Text('隐藏"其他"选项'),
                  subtitle: const Text('隐藏分类、状态、类型中的"其他"选项'),
                  value: hideOther,
                  onChanged: (value) {
                    ref
                        .read(hideOtherNotifierProvider.notifier)
                        .setHideOther(value);
                  },
                ),
              ],
            ),
          ),

          // Sync section
          _SectionHeader(title: '数据同步'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.cloud_download,
                    color: AppColors.primary,
                  ),
                  title: const Text('同步数据'),
                  subtitle: const Text('从 GitHub 下载最新数据'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _startSync(context, ref),
                ),
                const Divider(height: 1),
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

          // Statistics section
          _SectionHeader(title: '数据统计'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: stats.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('加载失败')),
              ),
              data: (data) => Column(
                children: [
                  _StatTile(
                    icon: Icons.book,
                    label: '小说总数',
                    value: '${data['novels'] ?? 0}',
                  ),
                  const Divider(height: 1),
                  _StatTile(
                    icon: Icons.person,
                    label: '作者数量',
                    value: '${data['authors'] ?? 0}',
                  ),
                  const Divider(height: 1),
                  _StatTile(
                    icon: Icons.tag,
                    label: '标签数量',
                    value: '${data['tags'] ?? 0}',
                  ),
                  const Divider(height: 1),
                  _StatTile(
                    icon: Icons.emoji_events,
                    label: '比赛数量',
                    value: '${data['contests'] ?? 0}',
                  ),
                  const Divider(height: 1),
                  _StatTile(
                    icon: Icons.category,
                    label: '小说分类',
                    value: '${data['genres'] ?? 0}',
                  ),
                  const Divider(height: 1),
                  _StatTile(
                    icon: Icons.signal_wifi_statusbar_4_bar,
                    label: '状态类型',
                    value: '${data['statuses'] ?? 0}',
                  ),
                  const Divider(height: 1),
                  _StatTile(
                    icon: Icons.vpn_key,
                    label: '小说类型',
                    value: '${data['ptypes'] ?? 0}',
                  ),
                ],
              ),
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

  void _startSync(BuildContext context, WidgetRef ref) async {
    final dio = Dio();
    final syncService = ChunkedSyncService(dio);

    if (!context.mounted) return;

    // Show dialog and get navigator to pop later
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SyncProgressDialog(),
    );

    try {
      // Check for updates
      final chunksToUpdate = await syncService.checkForUpdates();

      if (chunksToUpdate.isEmpty) {
        if (!context.mounted) return;
        navigator.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('数据已是最新')));
        return;
      }

      // Download each chunk
      for (final chunk in chunksToUpdate) {
        final result = await syncService.downloadChunk(
          chunk,
          onProgress: (progress) {
            // Update progress dialog
          },
        );

        if (!result.success) {
          if (!context.mounted) return;
          navigator.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('同步失败: ${result.error}')),
          );
          return;
        }
      }

      if (!context.mounted) return;
      navigator.pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('同步成功: ${chunksToUpdate.length} 个数据块')),
      );

      // Refresh statistics
      Future.microtask(() {
        ref.invalidate(statisticsProvider);
      });
    } catch (e) {
      if (!context.mounted) return;
      try {
        navigator.pop();
      } catch (_) {}
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('错误: $e')));
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

      // Show dialog and get navigator to pop later
      final navigator = Navigator.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _SyncProgressDialog(),
      );

      // Copy file to chunks directory
      final dio = Dio();
      final syncService = ChunkedSyncService(dio);
      final chunkPath = await syncService.getChunkPath('hot');

      await file.copy(chunkPath);

      if (!context.mounted) return;
      navigator.pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入成功')),
      );

      // Refresh statistics
      Future.microtask(() {
        ref.invalidate(statisticsProvider);
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
              final dio = Dio();
              final syncService = ChunkedSyncService(dio);
              for (final chunkName in ['cold', 'warm', 'hot']) {
                final path = await syncService.getChunkPath(chunkName);
                final file = File(path);
                if (await file.exists()) {
                  await file.delete();
                }
              }

              // Copy bundled chunks
              await syncService.copyBundledChunks();

              if (context.mounted) {
                Future.microtask(() {
                  ref.invalidate(statisticsProvider);
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

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SyncProgressDialog extends StatelessWidget {
  const _SyncProgressDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在同步数据...'),
        ],
      ),
    );
  }
}
