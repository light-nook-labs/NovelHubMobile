import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/novels/novels_screen.dart';
import '../features/novels/novels_by_genre_screen.dart';
import '../features/novels/novels_by_status_screen.dart';
import '../features/novels/novel_detail_screen.dart';
import '../features/rankings/rankings_screen.dart';
import '../features/authors/authors_screen.dart';
import '../features/tags/tags_screen.dart';
import '../features/contests/contests_screen.dart';
import '../features/banner/banner_screen.dart';
import '../features/browse/enum_list_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/bookshelf/bookshelf_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/novels',
          pageBuilder: (context, state) {
            final genre = state.uri.queryParameters['genre'];
            final status = state.uri.queryParameters['status'];
            final ptype = state.uri.queryParameters['ptype'];
            return NoTransitionPage(
              child: NovelsScreen(
                initialGenre: genre != null ? int.tryParse(genre) : null,
                initialStatus: status != null ? int.tryParse(status) : null,
                initialPtype: ptype != null ? int.tryParse(ptype) : null,
              ),
            );
          },
        ),
        GoRoute(
          path: '/banners',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: BannerScreen()),
        ),
        GoRoute(
          path: '/rankings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: RankingsScreen()),
        ),
        GoRoute(
          path: '/bookshelf',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: BookshelfScreen()),
        ),
      ],
    ),
    // Full screens (no bottom nav)
    GoRoute(
      path: '/novel/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const Scaffold(body: Center(child: Text('无效的ID')));
        }
        return NovelDetailScreen(novelId: id);
      },
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/authors',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AuthorsScreen(),
    ),
    GoRoute(
      path: '/author/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const Scaffold(body: Center(child: Text('无效的ID')));
        }
        return AuthorDetailScreen(authorId: id);
      },
    ),
    GoRoute(
      path: '/tags',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TagsScreen(),
    ),
    GoRoute(
      path: '/tag/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const Scaffold(body: Center(child: Text('无效的ID')));
        }
        return TagDetailScreen(tagId: id);
      },
    ),
    GoRoute(
      path: '/contests',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ContestsScreen(),
    ),
    GoRoute(
      path: '/genres',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GenreListScreen(),
    ),
    GoRoute(
      path: '/statuses',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StatusListScreen(),
    ),
    GoRoute(
      path: '/ptypes',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PtypeListScreen(),
    ),
    GoRoute(
      path: '/novels-by-genre',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final genre = state.uri.queryParameters['genre'];
        return NovelsByGenreScreen(
          initialGenre: genre != null ? int.tryParse(genre) : null,
        );
      },
    ),
    GoRoute(
      path: '/novels-by-status',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final status = state.uri.queryParameters['status'];
        return NovelsByStatusScreen(
          initialStatus: status != null ? int.tryParse(status) : null,
        );
      },
    ),
    GoRoute(
      path: '/contest/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const Scaffold(body: Center(child: Text('无效的ID')));
        }
        return ContestDetailScreen(contestId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: TooltipVisibility(
        visible: false,
        child: NavigationBar(
          selectedIndex: _getSelectedIndex(context),
          onDestinationSelected: (index) => _onItemTapped(context, index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '首页',
            ),
            NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label: '小说',
            ),
            NavigationDestination(
              icon: Icon(Icons.star_outline),
              selectedIcon: Icon(Icons.star),
              label: '背投',
            ),
            NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard),
              label: '排行',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: '书架',
            ),
          ],
        ),
      ),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/novels')) return 1;
    if (location.startsWith('/banners')) return 2;
    if (location.startsWith('/rankings')) return 3;
    if (location.startsWith('/bookshelf')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/novels');
      case 2:
        context.go('/banners');
      case 3:
        context.go('/rankings');
      case 4:
        context.go('/bookshelf');
    }
  }
}
