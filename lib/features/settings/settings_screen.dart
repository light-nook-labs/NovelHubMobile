import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/providers.dart';
import '../../app/theme.dart';
import '../../app/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncInfo = ref.watch(lastSyncInfoProvider);
    final stats = ref.watch(statisticsProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // Theme section
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
                  subtitle: syncInfo.when(
                    loading: () => const Text('加载中...'),
                    error: (_, __) => const Text('未同步'),
                    data: (info) {
                      if (info == null) return const Text('未同步');
                      return Text('版本: ${info.version}');
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _startSync(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore, color: AppColors.primary),
                  title: const Text('重置数据'),
                  subtitle: const Text('重置为默认数据库'),
                  onTap: () => _showClearDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.science,
                    color: AppColors.secondary,
                  ),
                  title: const Text('加载测试数据'),
                  subtitle: const Text('从本地 JSONL 文件加载'),
                  onTap: () => _loadTestData(context, ref),
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
                  subtitle: Text('1.0.0'),
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
    final syncService = ref.read(syncServiceProvider);

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SyncProgressDialog(),
    );

    try {
      final release = await syncService.checkForUpdate();
      if (release == null) {
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('数据已是最新')));
        return;
      }

      final result = await syncService.syncFromRelease(release);

      if (!context.mounted) return;
      Navigator.pop(context);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步成功: ${result.novelCount} 本小说')),
        );
        Future.microtask(() {
          ref.invalidate(lastSyncInfoProvider);
          ref.invalidate(statisticsProvider);
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('同步失败: ${result.error}')));
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('错误: $e')));
    }
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重置数据'),
        content: const Text('将重置为默认数据库（8,362 本小说），确定继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final db = ref.read(databaseProvider);
              await db.resetToDefault();
              if (context.mounted) {
                Future.microtask(() {
                  ref.invalidate(statisticsProvider);
                  ref.invalidate(lastSyncInfoProvider);
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

  void _loadTestData(BuildContext context, WidgetRef ref) async {
    const testPath = '/tmp/jsonl/meta_13.jsonl';
    final file = File(testPath);
    if (!file.existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('测试文件不存在: /tmp/jsonl/meta_13.jsonl')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SyncProgressDialog(),
    );

    try {
      final syncService = ref.read(syncServiceProvider);
      final result = await syncService.loadFromJsonlFile(testPath);

      if (!context.mounted) return;

      Navigator.pop(context);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载成功: ${result.novelCount} 本小说')),
        );
        Future.microtask(() {
          ref.invalidate(lastSyncInfoProvider);
          ref.invalidate(statisticsProvider);
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载失败: ${result.error}')));
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('错误: $e')));
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

  const _ThemeModeTile({required this.currentMode, required this.onChanged});

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
