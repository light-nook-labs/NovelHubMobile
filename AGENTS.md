# AGENTS.md

## Project Overview

Mobile app for [Novel Hub](https://github.com/light-nook-labs/novel_hub) — offline-first novel metadata browser.

- **Architecture**: Client(mobile)/Server(GitHub Releases)
- **Data**: Local SQLite, auto-syncs from GitHub releases when online
- **No API dependency**: All data comes from release archives (JSONL/CSV)
- **Goal**: Full feature parity with web Django app, no backend needed

## Feature Parity with Web

| Feature | Web (Django) | Mobile |
|---------|-------------|--------|
| Novel list + filter | ✅ | ✅ |
| Novel detail | ✅ | ✅ |
| Rankings (6 dimensions) | ✅ | ✅ |
| Search | ✅ | ✅ |
| Banner showcase | ✅ | ✅ |
| Author list + detail | ✅ | ✅ |
| Tag list + detail | ✅ | ✅ |
| Contest list + detail | ✅ | ✅ |
| Genre/Status/Ptype browse | ✅ | ✅ |
| Dark mode | ✅ | ✅ |

## Tech Stack

- **Framework**: Flutter (Dart 3.11+)
- **State Management**: Riverpod (code generation)
- **Database**: drift (SQLite)
- **HTTP**: dio
- **Routing**: go_router

## Key Commands

```bash
flutter pub get                                      # Setup
flutter run -d linux                                 # Dev (Linux)
dart run build_runner build --delete-conflicting-outputs  # Codegen
flutter analyze                                      # Lint
dart format .                                        # Format
```

## Data Source

Release archive from `light-nook-labs/novel_hub` (monthly CI auto-publish):

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
  "nid": 12345,
  "title": "...",
  "author": "...",
  "genre": "奇幻",
  "status": "连载中",
  "ptype": "长篇",
  "has_banner": false,
  "word_num": 100000,
  "click_num": 50000,
  "praise_num": 100,
  "like_num": 200,
  "comment_num": 50,
  "review_num": 10,
  "contest": null,
  "tags": ["tag1", "tag2"],
  "cover": "https://...",
  "last_update": "2026-01-01T00:00:00+00:00"
}
```

### Enum Mappings (Chinese → Integer)

| Field  | Values (zh)                        |
|--------|------------------------------------|
| genre  | 奇幻, 武侠, 同人, 言情, 科幻, 悬疑 |
| status | 连载中, 完结, 断更                 |
| ptype  | 短篇, 中篇, 长篇                   |

## Design Rules

- **No cold colors** (blue, indigo, sky, cyan, violet, purple, fuchsia)
- **Grid-first**: Novel lists use grid layout (3 cols mobile, 4+ desktop)
- **Dark mode**: Always support dark mode
- **Offline-first**: Works without network after initial sync
- **Cover prefix**: `https://rs.sfacg.com/web/novel/images/NovelCover/Big/`

## Project Structure

```
lib/
├── main.dart
├── app/                  # router, theme
├── data/
│   ├── models/           # drift database
│   ├── repositories/     # Riverpod providers
│   └── services/         # sync, JSONL parser
├── features/
│   ├── home/             # stats, banner, latest
│   ├── novels/           # list, detail
│   ├── authors/          # list, detail
│   ├── tags/             # list, detail
│   ├── contests/         # list, detail
│   ├── rankings/         # 6-dimension rankings
│   ├── search/           # search
│   └── settings/         # sync, clear
└── shared/
    ├── widgets/          # NovelCard, etc.
    └── utils/            # mappings, formatters
```

## Common Pitfalls

- **build_runner**: Must run after model/provider changes
- **JSONL**: Each line is a separate JSON object, not array
- **Cover URLs**: May be null; default cover → `null` in DB
- **Tags**: JSON array in JSONL, needs join table in SQLite
- **last_update**: ISO 8601 with timezone
