# Riverpod Skill

## Provider Types

```dart
// Simple value
final myProvider = Provider((ref) => 'value');

// Async value
final myFutureProvider = FutureProvider((ref) async {
  return await fetchData();
});

// State (mutable)
final myStateProvider = StateProvider((ref) => 0);

// Notifier
final myNotifierProvider = NotifierProvider<MyNotifier, State>(() {
  return MyNotifier();
});

// Async Notifier
final myAsyncNotifierProvider = AsyncNotifierProvider<MyAsyncNotifier, Data>(() {
  return MyAsyncNotifier();
});
```

## Code Generation (Recommended)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_provider.g.dart';

@riverpod
Future<List<Novel>> novels(NovelsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllNovels();
}

@riverpod
class NovelDetail extends _$NovelDetail {
  @override
  Future<Novel> build(int id) async {
    final db = ref.watch(databaseProvider);
    return db.getNovel(id);
  }
  
  Future<void> updateTitle(String title) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseProvider);
      await db.updateNovel(id, title: title);
      return db.getNovel(id);
    });
  }
}
```

## Widget Usage

```dart
// ConsumerWidget
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(novelsProvider);
    
    return asyncValue.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (novels) => ListView.builder(
        itemCount: novels.length,
        itemBuilder: (context, index) => NovelCard(novels[index]),
      ),
    );
  }
}

// ConsumerStatefulWidget (for local state + providers)
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});

  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(myProvider);
    return Container();
  }
}
```

## Provider Dependencies

```dart
// Provider that depends on another
@riverpod
Future<List<Novel>> filteredNovels(FilteredNovelsRef ref) async {
  final genre = ref.watch(selectedGenreProvider);
  final db = ref.watch(databaseProvider);
  return db.getNovelsByGenre(genre);
}
```

## Disposing

```dart
// Auto-dispose when no longer watched
@riverpod
Future<Data> myData(MyDataRef ref) {
  ref.onDispose(() {
    // Cleanup
  });
  return fetchData();
}
```

## Best Practices

- Use `@riverpod` code generation for type safety
- Keep providers focused (single responsibility)
- Use `ref.watch` for reactive updates, `ref.read` for one-time reads
- Handle all AsyncValue states (loading, error, data)
- Use `AsyncNotifier` for complex state with mutations
