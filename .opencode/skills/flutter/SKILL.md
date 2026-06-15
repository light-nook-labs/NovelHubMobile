# Flutter Skill

## Commands

```bash
# Development
flutter run                    # Run on connected device
flutter run -d chrome          # Run on Chrome
flutter run -d android         # Run on Android
flutter run -d ios             # Run on iOS

# Build
flutter build apk              # Android APK
flutter build ios              # iOS (requires macOS)
flutter build appbundle        # Android App Bundle
flutter build web              # Web

# Code Generation
dart run build_runner build --delete-conflicting-outputs  # Generate all
dart run build_runner watch    # Watch mode

# Testing
flutter test                   # All tests
flutter test test/path/to/test.dart  # Single test

# Lint/Format
dart analyze                   # Static analysis
dart format .                  # Format code
dart format --set-exit-if-changed .  # Check format (CI)

# Dependencies
flutter pub get                # Install dependencies
flutter pub upgrade            # Upgrade dependencies
flutter pub outdated           # Check outdated
```

## Project Structure

```
lib/
├── main.dart                  # Entry point
├── app/                       # App configuration
│   ├── app.dart              # MaterialApp/WidgetApp
│   ├── router.dart           # GoRouter configuration
│   └── theme.dart            # Theme data
├── data/                      # Data layer
│   ├── models/               # Drift database models
│   ├── repositories/         # Data access
│   └── services/             # API, sync services
├── features/                  # Feature modules
│   └── [feature]/
│       ├── [feature]_screen.dart
│       ├── [feature]_provider.dart
│       └── widgets/          # Feature-specific widgets
└── shared/                    # Shared code
    ├── widgets/              # Reusable widgets
    └── utils/                # Helpers
```

## Widget Conventions

- Use `const` constructors when possible
- Prefer `StatelessWidget` over `StatefulWidget`
- Extract reusable widgets to `shared/widgets/`
- Use `ConsumerWidget` for Riverpod integration

## File Naming

- Screens: `[name]_screen.dart`
- Providers: `[name]_provider.dart`
- Models: `[name].dart` (singular)
- Services: `[name]_service.dart`

## Common Patterns

### StatelessWidget with Riverpod

```dart
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myProvider);
    return data.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (data) => Text('Data: $data'),
    );
  }
}
```

### AsyncValue Handling

```dart
// Always handle all states
asyncValue.when(
  loading: () => LoadingWidget(),
  error: (error, stack) => ErrorWidget(error),
  data: (data) => DataWidget(data),
);
```
