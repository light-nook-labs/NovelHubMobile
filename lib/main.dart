import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'app/theme_provider.dart';
import 'data/models/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('Starting app...');
  
  // Initialize database from bundled chunks before app starts
  try {
    debugPrint('Initializing database...');
    await initDatabase();
    debugPrint('Database initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Database initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue anyway - the app might still work with limited functionality
  }
  
  debugPrint('Running app...');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp.router(
      title: 'Novel Hub',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
