import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/repositories/providers.dart';
import '../../data/services/sync_service.dart';
import '../../data/models/database.dart';
import '../../shared/widgets/novel_card.dart';
import '../../app/theme.dart';

part 'home_screen.g.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final syncInfo = ref.watch(lastSyncInfoProvider);
    final bannerNovels = ref.watch(bannerNovelsProvider);
    final latestNovels = ref.watch(novelsProvider(limit: 10));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statisticsProvider);
          ref.invalidate(lastSyncInfoProvider);
          ref.invalidate(bannerNovelsProvider);
          ref.invalidate(novelsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Hero Banner + App Bar
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              title: GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '搜索小说...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: bannerNovels.when(
                  loading: () => Container(color: AppColors.primary),
                  error: (_, __) => Container(color: AppColors.primary),
                  data: (novels) {
                    if (novels.isEmpty) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                        ),
                      );
                    }
                    return _HeroBanner(novel: novels.first);
                  },
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () => _showSyncDialog(context, ref),
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner novels carousel
                    bannerNovels.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (novels) {
                        if (novels.length <= 1) return const SizedBox.shrink();
                        return _BannerShowcase(novels: novels.skip(1).toList());
                      },
                    ),
                    const SizedBox(height: 16),

                    // Statistics
                    _StatsCard(stats: stats),
                    const SizedBox(height: 16),

                    // Latest novels
                    Text(
                      '最新小说',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    latestNovels.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => Text('Error: $err'),
                      data: (novels) {
                        if (novels.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.cloud_download,
                                        size: 48, color: AppColors.primary),
                                    SizedBox(height: 16),
                                    Text('暂无数据，点击同步按钮下载'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return SizedBox(
                          height: 280,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: novels.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final novel = novels[index];
                              return SizedBox(
                                width: 120,
                                child: NovelCard(
                                  novel: novel,
                                  onTap: () => context.push('/novel/${novel.id}'),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quick Navigation
                    _QuickNavCard(),
                    const SizedBox(height: 16),

                    // Sync Status
                    _SyncStatusCard(syncInfo: syncInfo),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据已是最新')),
        );
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
          ref.invalidate(statisticsProvider);
          ref.invalidate(lastSyncInfoProvider);
          ref.invalidate(bannerNovelsProvider);
          ref.invalidate(novelsProvider);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: ${result.error}')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('错误: $e')),
      );
    }
  }
}

class _HeroBanner extends StatelessWidget {
  final Novel novel;

  const _HeroBanner({required this.novel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        if (novel.cover != null && novel.cover!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: novel.cover!.startsWith('http')
                ? novel.cover!
                : 'https://rs.sfacg.com/web/novel/images/NovelCover/Big/${novel.cover}',
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.accent],
                ),
              ),
            ),
          ),
        // Gradient overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerShowcase extends StatelessWidget {
  final List<Novel> novels;

  const _BannerShowcase({required this.novels});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: novels.length,
        itemBuilder: (context, index) {
          final novel = novels[index];
          return GestureDetector(
            onTap: () => context.push('/novel/${novel.id}'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (novel.cover != null && novel.cover!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: novel.cover!.startsWith('http')
                          ? novel.cover!
                          : 'https://rs.sfacg.com/web/novel/images/NovelCover/Big/${novel.cover}',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.book, size: 48, color: AppColors.primary),
                      ),
                    ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('推荐',
                              style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          novel.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final AsyncValue<Map<String, int>> stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('数据库统计',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            stats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
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
    );
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
        Icon(icon, size: 28, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.book, color: AppColors.primary),
            title: const Text('浏览小说'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/novels'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.primary),
            title: const Text('作者'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/authors'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.tag, color: AppColors.primary),
            title: const Text('标签'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tags'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.emoji_events, color: AppColors.secondary),
            title: const Text('比赛'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/contests'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.search, color: AppColors.primary),
            title: const Text('搜索'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/search'),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  final AsyncValue<SyncInfo?> syncInfo;

  const _SyncStatusCard({required this.syncInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('同步状态',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),
            syncInfo.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
              data: (info) {
                if (info == null) {
                  return const Text('尚未同步数据');
                }
                return Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.ongoing, size: 16),
                    const SizedBox(width: 8),
                    Text('版本: ${info.version}'),
                    if (info.syncedAt != null) ...[
                      const Spacer(),
                      Text(
                        '${info.syncedAt!.month}/${info.syncedAt!.day}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
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

@riverpod
Future<List<Novel>> bannerNovels(BannerNovelsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getBannerNovels();
}
