import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/novels/novels_screen.dart';
import '../features/novels/novel_detail_screen.dart';
import '../features/rankings/rankings_screen.dart';
import '../features/authors/authors_screen.dart';
import '../features/tags/tags_screen.dart';
import '../features/contests/contests_screen.dart';
import '../features/banner/banner_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';

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
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: NovelsScreen()),
        ),
        GoRoute(
          path: '/rankings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: RankingsScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
    // Full screens (no bottom nav)
    GoRoute(
      path: '/novel/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return NovelDetailScreen(novelId: id);
      },
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/banners',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BannerScreen(),
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
        final id = int.parse(state.pathParameters['id']!);
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
        final id = int.parse(state.pathParameters['id']!);
        return TagDetailScreen(tagId: id);
      },
    ),
    GoRoute(
      path: '/contests',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ContestsScreen(),
    ),
    GoRoute(
      path: '/contest/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ContestDetailScreen(contestId: id);
      },
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
      bottomNavigationBar: NavigationBar(
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
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: '排行',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/novels')) return 1;
    if (location.startsWith('/rankings')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/novels');
      case 2:
        context.go('/rankings');
      case 3:
        context.go('/settings');
    }
  }
}
