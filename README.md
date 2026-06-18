# Novel Hub Mobile

Offline-first novel metadata browser for [Novel Hub](https://github.com/light-nook-labs/novel_hub).

## Features

- **Offline First**: Local SQLite database, browse without network
- **Auto Sync**: Download latest data from GitHub Releases
- **Dark Mode**: Full support for dark/light themes
- **Full Text Search**: Search by title, author, tags with pagination
- **Bookshelf**: Save novels locally with persistent storage
- **Rankings**: 6 dimensions (clicks/words/likes/praises/reviews/comments)
- **Multi-filter**: Filter by genre, status, ptype, year, word count
- **Banner Showcase**: Hero carousel with search and reverse order

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter 3.11+ | UI Framework |
| Riverpod | State Management |
| drift | SQLite ORM |
| dio | HTTP Client |
| go_router | Routing |
| cached_network_image | Image Caching |
| shared_preferences | Local Storage |

## Quick Start

### Requirements

- Flutter 3.11+
- Dart 3.11+

### Install & Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d linux
```

### Build

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Linux
flutter build linux --release
```

## Project Structure

```
lib/
├── main.dart
├── app/
│   ├── router.dart
│   ├── theme.dart
│   └── theme_provider.dart
├── data/
│   ├── models/database.dart
│   └── repositories/providers.dart
├── features/
│   ├── home/
│   ├── novels/
│   ├── authors/
│   ├── tags/
│   ├── contests/
│   ├── banner/
│   ├── bookshelf/
│   ├── rankings/
│   ├── search/
│   └── settings/
└── shared/
    └── widgets/
```

## Data Source

Data from [Novel Hub](https://github.com/light-nook-labs/novel_hub) GitHub Releases:

- Chunked SQLite databases (cold/warm/hot)
- Auto-merged on first launch
- Monthly updates for active novels

## License

MIT License - Contributions welcome
