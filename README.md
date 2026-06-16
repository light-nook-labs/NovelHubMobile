# Novel Hub Mobile

Offline-first novel metadata browser, aligned with [Novel Hub](https://github.com/light-nook-labs/novel_hub) web version.

## Features

- 📱 **Offline First**: Local SQLite database, browse without network
- 🔄 **Auto Sync**: Download latest data from GitHub Releases
- 🌙 **Dark Mode**: Full support for dark/light themes
- 🔍 **Full Text Search**: Search by title, author, tags
- 📊 **Rankings**: 6 dimensions (clicks/words/likes/praises/reviews/comments)
- 🏷️ **Multi-filter**: Filter by genre, status, ptype, year, word count

## Screenshots

| Home | Novels | Rankings | Detail |
|------|--------|----------|--------|
| Hero Carousel | 4-Column Grid | Tab Navigation | Cover + Info |

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter | UI Framework |
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

### Install Dependencies

```bash
flutter pub get
```

### Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run

```bash
# Linux Desktop
flutter run -d linux

# Android
flutter run -d android

# iOS
flutter run -d ios
```

### Build

```bash
# Linux
flutter build linux --debug

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                    # App entry
├── app/
│   ├── router.dart             # Route config
│   ├── theme.dart              # Theme config
│   ├── theme_provider.dart     # Theme state
│   └── settings_provider.dart  # Settings state
├── data/
│   ├── models/database.dart    # Database models
│   ├── repositories/providers.dart  # Riverpod providers
│   └── services/
│       ├── jsonl_parser.dart   # JSONL parser
│       └── sync_service.dart   # Sync service
├── features/
│   ├── home/                   # Home page
│   ├── novels/                 # Novel list/detail
│   ├── authors/                # Author list/detail
│   ├── tags/                   # Tag list/detail
│   ├── contests/               # Contest list/detail
│   ├── banner/                 # Banner tab
│   ├── browse/                 # Enum list pages
│   ├── rankings/               # Rankings
│   ├── search/                 # Search
│   └── settings/               # Settings
└── shared/
    ├── widgets/
    │   ├── novel_card.dart     # Novel card
    │   ├── novel_rank_list.dart # Reusable rank list
    │   └── common_widgets.dart # Reusable UI components
    └── utils/
        ├── mappings.dart       # Enum mappings
        └── spacing.dart        # Spacing system
```

## Data Source

Data comes from [Novel Hub](https://github.com/light-nook-labs/novel_hub) GitHub Releases:

- Monthly auto-publish `release.tar.gz`
- Contains JSONL format novel metadata
- Auto-download and import on first launch

## Development Guide

### Add New Page

1. Create new directory under `lib/features/`
2. Create page files
3. Add route in `lib/app/router.dart`
4. Run `dart run build_runner build` to generate code

### Modify Database

1. Edit `lib/data/models/database.dart`
2. Run `dart run build_runner build`
3. Update `lib/data/repositories/providers.dart`

### Add New Filter

1. Add filter option in `lib/shared/widgets/novel_rank_list.dart`
2. Update database query method
3. Update corresponding page

## Common Issues

### build_runner Failure

```bash
# Clean and regenerate
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Database Corruption

1. Go to Settings page
2. Click "Reset Data"
3. Re-sync

### Images Not Displaying

- Check network connection
- Verify URL format (starts with `https://`)
- Try clearing image cache

## License

MIT License
