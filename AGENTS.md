# AGENTS.md

## Project Overview

Mobile app for [Novel Hub](https://github.com/light-nook-labs/novel_hub) — offline-first novel metadata browser.

- **Architecture**: Client(mobile)/Server(GitHub Releases)
- **Data**: Local SQLite, auto-syncs from GitHub releases when online
- **No API dependency**: All data comes from release archives (JSONL/CSV)

## Tech Stack

- **Framework**: Flutter (Dart 3.11+)
- **State Management**: Riverpod
- **Database**: drift (SQLite for Flutter)
- **HTTP**: dio
- **Routing**: go_router

## Key Commands

```bash
# Setup
flutter pub get

# Development
flutter run                    # Run on connected device/emulator
flutter run -d chrome          # Run on Chrome (for quick testing)

# Code generation (required after model changes)
dart run build_runner build --delete-conflicting-outputs

# Testing
flutter test                   # Run all tests
flutter test test/widget_test.dart  # Run single test file

# Build
flutter build apk              # Android APK
flutter build ios              # iOS (requires macOS)
flutter build appbundle        # Android App Bundle

# Lint/Format
dart analyze                   # Static analysis
dart format .                  # Format code
```

## Data Source

Release archive from `light-nook-labs/novel_hub`:

```
release.tar.gz
├── jsonl/meta_01.jsonl    # 20k records per file
├── jsonl/meta_02.jsonl
├── csv/meta_01.csv
├── tasks.csv
```

### Novel Data Schema (JSONL)

```json
{
  "nid": 12345,           // Novel ID (primary key)
  "title": "...",
  "author": "...",
  "genre": "奇幻",        // Chinese enum string
  "status": "连载中",     // Chinese enum string
  "ptype": "长篇",        // Chinese enum string
  "has_banner": false,
  "word_num": 100000,
  "click_num": 50000,
  "praise_num": 100,
  "like_num": 200,
  "comment_num": 50,
  "review_num": 10,
  "contest": null,        // Optional
  "tags": ["tag1", "tag2"],
  "cover": "https://...",  // Full URL or null
  "last_update": "2026-01-01T00:00:00+00:00"
}
```

### Enum Mappings (Chinese → Integer)

Store as integers in SQLite, display as Chinese:

| Field    | Values (zh)                          |
|----------|--------------------------------------|
| genre    | 奇幻, 武侠, 同人, 言情, 科幻, 悬疑   |
| status   | 连载中, 完结, 断更                   |
| ptype    | 短篇, 中篇, 长篇                     |

## Sync Strategy

1. Check GitHub releases for latest version (no auth needed for public repo)
2. Download `release.tar.gz` if newer than local
3. Extract and parse JSONL files
4. Upsert into local SQLite (match on `nid`)
5. Track sync timestamp in shared_preferences

## Project Structure

```
lib/
├── main.dart
├── app/                  # App configuration, routing
├── data/
│   ├── models/           # Drift database models
│   ├── repositories/     # Data access layer
│   └── services/         # GitHub sync, HTTP client
├── features/
│   ├── home/             # Home screen
│   ├── novels/           # Novel list, detail, search
│   ├── rankings/         # Various rankings
│   └── settings/         # App settings, sync controls
└── shared/
    ├── widgets/          # Reusable widgets
    └── utils/            # Helpers, formatters
```

## Design Rules

- **No cold colors** (blue, indigo, sky, cyan, violet, purple, fuchsia)
- **Grid-first**: Novel lists use grid layout
- **Dark mode**: Always support dark mode
- **Offline-first**: App must work without network after initial sync

## Testing

```bash
flutter test                           # All tests
flutter test test/features/novels/     # Feature tests
```

## Common Pitfalls

- **build_runner**: Must run after any model change to regenerate database code
- **JSONL parsing**: Each line is a separate JSON object, not a JSON array
- **Cover URLs**: May be null for default covers
- **Tags**: Stored as JSON array in JSONL, needs join table in SQLite
- **last_update**: ISO 8601 with timezone, handle timezone conversion for display
