import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/providers.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novel Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final syncInfo = ref.watch(lastSyncInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novel Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _showSyncDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statisticsProvider);
          ref.invalidate(lastSyncInfoProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Statistics Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '数据库统计',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    stats.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => Text('Error: $err'),
                      data: (data) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.book,
                            label: '小说',
                            value: '${data['novels'] ?? 0}',
                          ),
                          _StatItem(
                            icon: Icons.person,
                            label: '作者',
                            value: '${data['authors'] ?? 0}',
                          ),
                          _StatItem(
                            icon: Icons.tag,
                            label: '标签',
                            value: '${data['tags'] ?? 0}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sync Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '同步状态',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    syncInfo.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => Text('Error: $err'),
                      data: (info) {
                        if (info == null) {
                          return const Text('尚未同步数据');
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('版本: ${info.version}'),
                            if (info.syncedAt != null)
                              Text(
                                '同步时间: ${_formatDateTime(info.syncedAt!)}',
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text('浏览小说'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to novel list
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text('搜索'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to search
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.leaderboard),
                    title: const Text('排行榜'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to rankings
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showSyncDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步数据'),
        content: const Text('从 GitHub Releases 下载最新数据？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startSync(context, ref);
            },
            child: const Text('同步'),
          ),
        ],
      ),
    );
  }

  void _startSync(BuildContext context, WidgetRef ref) async {
    final syncService = ref.read(syncServiceProvider);
    
    // Show progress dialog
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('数据已是最新')),
          );
        }
        return;
      }

      final result = await syncService.syncFromRelease(release);
      
      if (context.mounted) {
        Navigator.pop(context);
        
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('同步成功: ${result.novelCount} 本小说'),
            ),
          );
          ref.invalidate(statisticsProvider);
          ref.invalidate(lastSyncInfoProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('同步失败: ${result.error}')),
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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
