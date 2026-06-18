import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../data/repositories/providers.dart';
import '../../data/services/sync_service.dart';
import '../../data/models/database.dart';
import '../../app/theme.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/utils/spacing.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<BannerNovel>? _shuffledBanners;

  @override
  Widget build(BuildContext context) {
    final mergeTimeAsync = ref.watch(dbMergeTimeProvider);
    final bannerNovels = ref.watch(bannerNovelsProvider);
    final stats = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const SearchBarWidget(),
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
          ref.invalidate(dbMergeTimeProvider);
          ref.invalidate(bannerNovelsProvider);
          setState(() => _shuffledBanners = null);
        },
        child: ListView(
          padding: AppSpacing.paddingM,
          children: [
            // Hero Banner Carousel (random 5 banner novels)
            bannerNovels.when(
              loading: () => _BannerShimmer(),
              error: (_, __) => const SizedBox.shrink(),
              data: (novels) {
                if (novels.isEmpty) return const SizedBox.shrink();
                // Cache the shuffled result
                if (_shuffledBanners == null || _shuffledBanners!.length != novels.length) {
                  _shuffledBanners = List<BannerNovel>.from(novels)..shuffle(Random());
                }
                final displayNovels = _shuffledBanners!.take(5).toList();
                return _HeroBannerCarousel(novels: displayNovels);
              },
            ),
            AppSpacing.gapHeightM,

            // Quick Navigation with counts
            stats.when(
              loading: () => _QuickNavCard(),
              error: (_, __) => _QuickNavCard(),
              data: (data) => _QuickNavCard(stats: data),
            ),
            AppSpacing.gapHeightM,

            // Sync Status
            _SyncStatusCard(mergeTimeAsync: mergeTimeAsync),
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
          ref.invalidate(statisticsProvider);
          ref.invalidate(lastSyncInfoProvider);
          ref.invalidate(bannerNovelsProvider);
          ref.invalidate(novelsProvider);
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
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 170,
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
                child: GestureDetector(
                  onTap: () => context.push('/novel/${novel.id}'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: bannerUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.centerRight,
                            width: double.infinity,
                            errorWidget: (_, __, ___) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppColors.primary, AppColors.accent],
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.book,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        novel.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        novel.author,
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.novels.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.novels.length,
              (index) => Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
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
      ],
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  final Map<String, int>? stats;

  const _QuickNavCard({this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.book, color: AppColors.primary),
            title: Text(
              '小说${stats != null ? '（${stats!['novels'] ?? 0}）' : ''}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/novels'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.primary),
            title: Text(
              '作者${stats != null ? '（${stats!['authors'] ?? 0}）' : ''}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/authors'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.tag, color: AppColors.primary),
            title: Text('标签${stats != null ? '（${stats!['tags'] ?? 0}）' : ''}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tags'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.emoji_events, color: AppColors.secondary),
            title: Text(
              '比赛${stats != null ? '（${stats!['contests'] ?? 0}）' : ''}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/contests'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.category, color: AppColors.primary),
            title: Text(
              '小说分类${stats != null ? '（${stats!['genres'] ?? 0}）' : ''}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/genres'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.trending_up, color: AppColors.primary),
            title: Text(
              '状态${stats != null ? '（${stats!['statuses'] ?? 0}）' : ''}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/statuses'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.workspace_premium, color: AppColors.primary),
            title: Text(
              '类型${stats != null ? '（${stats!['ptypes'] ?? 0}）' : ''}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/ptypes'),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  final AsyncValue<DateTime?> mergeTimeAsync;

  const _SyncStatusCard({required this.mergeTimeAsync});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据状态',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            mergeTimeAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
              data: (mergeTime) {
                if (mergeTime == null) {
                  return const Text('尚未加载数据');
                }
                return Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.ongoing,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text('数据已加载'),
                    const Spacer(),
                    Text(
                      '${mergeTime.month}/${mergeTime.day} ${mergeTime.hour}:${mergeTime.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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

class _BannerShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: PageView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 120,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        height: 10,
                        width: 80,
                        color: Colors.white,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
