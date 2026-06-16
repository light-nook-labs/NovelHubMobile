import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/repositories/providers.dart';
import '../../data/services/sync_service.dart';
import '../../data/models/database.dart';
import '../../app/theme.dart';

part 'home_screen.g.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final syncInfo = ref.watch(lastSyncInfoProvider);
    final bannerNovels = ref.watch(bannerNovelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => context.push('/search'),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          ref.invalidate(bannerNovelsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Hero Banner Carousel (first 5 banner novels)
            bannerNovels.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (novels) {
                if (novels.isEmpty) return const SizedBox.shrink();
                final displayNovels =
                    novels.length > 5 ? novels.sublist(0, 5) : novels;
                return _HeroBannerCarousel(novels: displayNovels);
              },
            ),
            const SizedBox(height: 12),

            // Statistics
            _StatsCard(stats: stats),
            const SizedBox(height: 12),

            // Quick Navigation
            _QuickNavCard(),
            const SizedBox(height: 12),

            // Sync Status
            _SyncStatusCard(syncInfo: syncInfo),
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

class _HeroBannerCarousel extends StatefulWidget {
  final List<BannerNovel> novels;

  const _HeroBannerCarousel({required this.novels});

  @override
  State<_HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<_HeroBannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.novels.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final novel = widget.novels[index];
              final bannerUrl =
                  'https://rs.sfacg.com/web/novel/images/images/beitouNew/${novel.id}.jpg';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/novel/${novel.id}'),
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(
                          imageUrl: bannerUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.centerRight,
                          errorWidget: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.primary, AppColors.accent],
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.book,
                                  size: 48, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => context.push('/novel/${novel.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            novel.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            novel.author,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Page indicators
        if (widget.novels.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.novels.length,
              (index) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? AppColors.primary
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
      ],
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('数据库统计',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 12),
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
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('同步状态',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
Future<List<BannerNovel>> bannerNovels(BannerNovelsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getBannerNovels();
}
