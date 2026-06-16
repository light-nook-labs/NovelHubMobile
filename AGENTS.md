# AGENTS.md

## Project Overview

Mobile app for [Novel Hub](https://github.com/light-nook-labs/novel_hub) — offline-first novel metadata browser.

- **Architecture**: Client(mobile)/Server(GitHub Releases)
- **Data**: Local SQLite, auto-syncs from GitHub releases when online
- **No API dependency**: All data comes from release archives (JSONL/CSV)
- **Goal**: Full feature parity with web Django app, no backend needed

## Feature Status

| Feature | Web (Django) | Mobile | Notes |
|---------|-------------|--------|-------|
| Novel list + filter | ✅ | ✅ | 4-column grid, inline filters |
| Novel detail | ✅ | ✅ | Cover right, info left |
| Rankings (6 dimensions) | ✅ | ✅ | Table view with tabs |
| Search | ✅ | ✅ | Full screen, debounced |
| Banner showcase | ✅ | ✅ | Hero banner + carousel + dedicated page |
| Author list + detail | ✅ | ✅ | |
| Tag list + detail | ✅ | ✅ | |
| Contest list + detail | ✅ | ✅ | |
| Genre/Status/Ptype browse | ✅ | ✅ | Via filters |
| Dark mode | ✅ | ✅ | |

## Tech Stack

- **Framework**: Flutter (Dart 3.11+)
- **State Management**: Riverpod (code generation)
- **Database**: drift (SQLite)
- **HTTP**: dio
- **Routing**: go_router
- **Window**: window_manager (desktop testing)

## Key Commands

```bash
flutter pub get                                      # Setup
flutter run -d linux                                 # Dev (Linux)
dart run build_runner build --delete-conflicting-outputs  # Codegen
flutter analyze                                      # Lint
dart format .                                        # Format
flutter build linux --debug                          # Build for testing
```

## Navigation Structure

**Bottom Nav (4 tabs):**
- 首页 (Home)
- 小说 (Novels)
- 排行 (Rankings)
- 设置 (Settings)

**Header Nav:**
- Search bar in AppBar → opens full screen search page

**Full Screen Pages (no bottom nav):**
- Novel detail
- Search
- Banner list (all banner novels)
- Authors/Tags/Contests list & detail

## Default Sorting

Matching novel_hub web defaults:
- **Novel list**: `click_num` DESC
- **Rankings**: `click_num` DESC (default tab)
- **Home latest**: `click_num` DESC

## Enum Mappings

From `novel_hub/utils/mappings.py` (index 1 = OTHER/fallback):

### Genre (类型)
| Value | Chinese |
|-------|---------|
| 1 | 其他 |
| 2 | 魔幻 |
| 3 | 玄幻 |
| 4 | 古风 |
| 5 | 科幻 |
| 6 | 校园 |
| 7 | 都市 |
| 8 | 游戏 |
| 9 | 同人 |
| 10 | 悬疑 |

### Status (状态)
| Value | Chinese |
|-------|---------|
| 1 | 其他 |
| 2 | 已完结 |
| 3 | 连载中 |
| 4 | 断更 |
| 5 | 断更A |
| 6 | 完结A |
| 7 | 下架 |

### Ptype (类型)
| Value | Chinese |
|-------|---------|
| 1 | 其他 |
| 2 | 免费 |
| 3 | 签约 |
| 4 | VIP |

## Data Source

Release archive from `light-nook-labs/novel_hub` (monthly CI auto-publish):

```
release.tar.gz
├── jsonl/meta_01.jsonl    # 20k records per file
├── jsonl/meta_02.jsonl
├── ...
├── csv/meta_01.csv
└── tasks.csv
```

### Novel Data Schema (JSONL)

```json
{
  "nid": 12345,
  "title": "...",
  "author": "...",
  "genre": "魔幻",
  "status": "连载中",
  "ptype": "免费",
  "has_banner": false,
  "word_num": 100000,
  "click_num": 50000,
  "praise_num": 100,
  "like_num": 200,
  "comment_num": 50,
  "review_num": 10,
  "contest": null,
  "tags": ["tag1", "tag2"],
  "cover": "https://rs.sfacg.com/web/novel/images/NovelCover/Big/xxx.jpg",
  "last_update": "2026-01-01T00:00:00+00:00"
}
```

## Database

**Bundled database**: `assets/db/novel_hub.sqlite`
- Contains ~8,362 novels (real data from meta_13.jsonl)
- Auto-copied to app documents on first launch
- "Reset data" restores to bundled default

**Runtime path**: `~/.local/share/novel_hub_mobile/novel_hub.sqlite`

## UI Conventions

**Layout:**
- Novel grid: 4 columns (matching web `grid-cols-4`)
- Novel card: 4:5 cover ratio, title + status badge
- Detail page: Info left, cover right

**Colors:**
- No cold colors (blue, indigo, cyan, purple, fuchsia)
- Primary: Orange/Amber
- Status colors: Green(ongoing), Grey(stopped), Blue(completed)

**Typography:**
- Title: 10-11px bold
- Body: 12-13px
- Badge: 8-9px

**Window (desktop testing):**
- Width: 390px (mobile)
- Height: 90% screen height
- GTK configured in `linux/runner/my_application.cc`

## Project Structure

```
lib/
├── main.dart
├── app/
│   ├── router.dart         # go_router config
│   └── theme.dart          # light/dark themes
├── data/
│   ├── models/
│   │   └── database.dart   # drift tables + queries
│   ├── repositories/
│   │   └── providers.dart  # Riverpod providers
│   └── services/
│       ├── jsonl_parser.dart
│       └── sync_service.dart
├── features/
│   ├── home/               # hero banner, stats, latest
│   ├── novels/             # list (4-col grid), detail
│   ├── authors/            # list, detail
│   ├── tags/               # list, detail
│   ├── contests/           # list, detail
│   ├── rankings/           # 6 tabs, table view
│   ├── search/             # full screen search
│   └── settings/           # sync, reset
└── shared/
    ├── widgets/
    │   └── novel_card.dart
    └── utils/
        └── mappings.dart   # enum mappings
```

## Common Pitfalls

- **build_runner**: Must run after model/provider changes
- **JSONL**: Each line is a separate JSON object, not array
- **Cover URLs**: May be null; default cover → `null` in DB
- **Tags**: JSON array in JSONL, needs join table in SQLite
- **last_update**: ISO 8601 with timezone
- **Enum values**: Index 1 is always OTHER/fallback (not 0)
- **nid < 10000**: Test data, may have bugs; use meta_13.jsonl for real data

## Testing

**Quick test with real data:**
```bash
# Generate SQLite from JSONL (Python)
python3 -c "
import json, sqlite3
# Read meta_13.jsonl, create database
# See scripts/generate_db.py
"
```

**Window size for PC testing:**
- Edit `linux/runner/my_application.cc`
- Set `gtk_window_set_default_size(window, width, height)`
