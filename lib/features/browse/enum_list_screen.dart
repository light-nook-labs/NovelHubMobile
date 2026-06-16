import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/utils/mappings.dart';
import '../../app/theme.dart';

class GenreListScreen extends StatelessWidget {
  const GenreListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小说分类'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        itemCount: genreMapping.allZh.length,
        itemBuilder: (context, index) {
          final zh = genreMapping.allZh[index];
          final value = genreMapping.getValue(zh);
          return ListTile(
            leading: const Icon(Icons.category, color: AppColors.primary),
            title: Text(zh),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/novels-by-genre?genre=$value'),
          );
        },
      ),
    );
  }
}

class StatusListScreen extends StatelessWidget {
  const StatusListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('状态'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        itemCount: statusMapping.allZh.length,
        itemBuilder: (context, index) {
          final zh = statusMapping.allZh[index];
          final value = statusMapping.getValue(zh);
          return ListTile(
            leading: const Icon(Icons.signal_wifi_statusbar_4_bar,
                color: AppColors.primary),
            title: Text(zh),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/novels-by-status?status=$value'),
          );
        },
      ),
    );
  }
}

class PtypeListScreen extends StatelessWidget {
  const PtypeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('类型'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        itemCount: ptypeMapping.allZh.length,
        itemBuilder: (context, index) {
          final zh = ptypeMapping.allZh[index];
          final value = ptypeMapping.getValue(zh);
          return ListTile(
            leading:
                const Icon(Icons.vpn_key, color: AppColors.primary),
            title: Text(zh),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to novels tab with ptype filter
              context.go('/novels?ptype=$value');
            },
          );
        },
      ),
    );
  }
}
