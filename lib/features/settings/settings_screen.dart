import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/providers.dart';
import '../../app/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncInfo = ref.watch(lastSyncInfoProvider);
    final stats = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
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
                  leading: const Icon(Icons.delete_sweep, color: Colors.red),
                  title: const Text('清除数据'),
                  subtitle: const Text('删除本地所有小说数据'),
                  onTap: () => _showClearDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.science, color: AppColors.secondary),
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
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $err'),
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
                  title: Text('版本'),
                  subtitle: Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code, color: AppColors.primary),
                  title: const Text('GitHub'),
                  subtitle: const Text('light-nook-labs/NovelHubMobile'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // TODO: Open URL
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _startSync(BuildContext context, WidgetRef ref) async {
    final syncService = ref.read(syncServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SyncProgressDialog(),
    );

    try {
      final release = await syncService.checkForUpdate();
      if (release == null) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('数据已是最新')));
        }
        return;
      }

      final result = await syncService.syncFromRelease(release);

      if (context.mounted) {
        Navigator.pop(context);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('同步成功: ${result.novelCount} 本小说')),
          );
          ref.invalidate(lastSyncInfoProvider);
          ref.invalidate(statisticsProvider);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('同步失败: ${result.error}')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('错误: $e')));
      }
    }
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('将删除本地所有小说数据，确定继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final db = ref.read(databaseProvider);
              await db.clearAll();
              ref.invalidate(statisticsProvider);
              ref.invalidate(lastSyncInfoProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('数据已清除')));
              }
            },
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }

  void _loadTestData(BuildContext context, WidgetRef ref) async {
    // For testing: load from a single JSONL file
    const testPath = '/tmp/jsonl/meta_01.jsonl';
    final file = File(testPath);
    if (!file.existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('测试文件不存在: /tmp/jsonl/meta_01.jsonl'),
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SyncProgressDialog(),
    );

    try {
      final syncService = ref.read(syncServiceProvider);
      final result = await syncService.loadFromJsonlFile(testPath);

      if (context.mounted) {
        Navigator.pop(context);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('加载成功: ${result.novelCount} 本小说'),
            ),
          );
          ref.invalidate(lastSyncInfoProvider);
          ref.invalidate(statisticsProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('加载失败: ${result.error}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('错误: $e')),
        );
      }
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
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
