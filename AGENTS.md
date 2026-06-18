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
| Novel list + filter | ✅ | ✅ | List view with header tabs for ptype |
| Novel detail | ✅ | ✅ | Cover right, info left, copy title, SFACG link |
| Rankings (6 dimensions) | ✅ | ✅ | Rank-style list with tabs |
| Search | ✅ | ✅ | Full screen, debounced (300ms Timer) |
| Banner showcase | ✅ | ✅ | Hero carousel (5) + dedicated tab |
| Author list + detail | ✅ | ✅ | Sorted by total clicks |
| Tag list + detail | ✅ | ✅ | 3-column grid with novel count + full filter |
| Contest list + detail | ✅ | ✅ | 2-column grid with novel count + full filter |
| Genre/Status/Ptype browse | ✅ | ✅ | List pages + filtered novels |
| Dark mode | ✅ | ✅ | Manual theme switching |
| Load more | ✅ | ✅ | 48 per page, back-to-top button |
| Word count filter | ✅ | ✅ | Range-based filter with breakpoints |

## Tech Stack

- **Framework**: Flutter (Dart 3.11+)
- **State Management**: Riverpod (code generation)
- **Database**: drift (SQLite)
- **HTTP**: dio
- **Routing**: go_router
- **Image**: cached_network_image
- **Storage**: shared_preferences
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

**Bottom Nav (5 tabs):**
- Home - `/`
- Novels - `/novels`
- Banners - `/banners`
- Rankings - `/rankings`
- Settings - `/settings`

**Header Nav:**
- Search bar in AppBar → opens full screen search page

**Novels Screen Header Tabs:**
- All/Free/Signed/VIP (ptype filter)
- "Other" tab: hidden by default, shown last with smaller font when enabled

**Rankings Screen Header Tabs:**
- Clicks/Words/Likes/Praises/Reviews/Comments

**Full Screen Pages (no bottom nav):**
- Novel detail - `/novel/:id`
- Search - `/search`
- Authors list - `/authors`
- Author detail - `/author/:id`
- Tags list - `/tags`
- Tag detail - `/tag/:id`
- Contests list - `/contests`
- Contest detail - `/contest/:id`
- Genre list - `/genres`
- Status list - `/statuses`
- Ptype list - `/ptypes`
- Novels by genre - `/novels-by-genre`
- Novels by status - `/novels-by-status`

## Default Sorting

Matching novel_hub web defaults:
- **Novel list**: `click_num` DESC
- **Rankings**: `click_num` DESC (default tab)
- **Authors**: Top novel `click_num` DESC (pre-computed `top_novel_clicks`)
- **Home latest**: `click_num` DESC

## Enum Mappings

From `novel_hub/utils/mappings.py` (index 1 = OTHER/fallback):

### Genre (Novel Genre)
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

### Status (Novel Status)
| Value | Chinese |
|-------|---------|
| 1 | 其他 |
| 2 | 已完结 |
| 3 | 连载中 |
| 4 | 断更 |
| 5 | 断更A |
| 6 | 完结A |
| 7 | 下架 |

### Ptype (Novel Type)
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

### Chunked Data Strategy

Data is split into chunks based on activity level:

| Chunk | Status | Records | Size (compressed) | Update Frequency |
|-------|--------|---------|-------------------|------------------|
| Cold | 断更, 已完结 | ~241k | ~58MB | Never |
| Warm | 完结A, 断更A | ~2.5k | ~1.6MB | Quarterly |
| Hot | 连载中 | ~2.8k | ~1.9MB | Monthly |

**下架 (removed) and 其他 (other) data is excluded** as it has no value.

**App bundling:**
- App includes: Cold chunk (~58MB compressed .gz)
- First launch download: Warm + Hot chunks (~3.5MB)
- Monthly update: Hot chunk (~1.9MB)

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

**Chunked database**: `assets/chunks/`
- `cold_chunk.sqlite.gz` (~58MB compressed) - 断更, 已完结
- `warm_chunk.sqlite` (~1.6MB) - 完结A, 断更A
- `hot_chunk.sqlite` (~1.9MB) - 连载中

**Runtime path**: `~/.local/share/novel_hub_mobile/chunks/`

**Database provider**: KeepAlive singleton (no multiple instances)

**Pre-computed data** (built into chunks, read-only):
- Authors table: `top_novel_id`, `top_novel_title`, `top_novel_clicks`
- Each chunk contains only authors that appear in that chunk's novels
- All indexes created at build time for fast queries
- Authors sorted by `top_novel_clicks DESC` (no runtime aggregation)

### Authors Table Schema

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment |
| name | TEXT UNIQUE | Author name |
| top_novel_id | INTEGER | ID of top novel (by clicks) |
| top_novel_title | TEXT | Title of top novel |
| top_novel_clicks | INTEGER | Clicks of top novel |

## UI Conventions

**Layout:**
- Novel list: ListView with NovelRankRow (list view, not grid)
- Novel card: 4:5 cover ratio, title + status badge
- Detail page: Info left, cover right
- Novel rank list: Reusable component for consistent layout

**NovelRankRow:**
- Title with novel ID
- Author with person icon
- Status/Genre/Ptype badges
- Value (clicks/words/etc.)

**Colors:**
- No cold colors (blue, indigo, cyan, purple, fuchsia)
- Primary: Orange/Amber
- Status colors: Green(ongoing), Grey(stopped), Blue(completed)

**Typography:**
- Title: 14px bold
- Body: 12-13px
- Badge: 10px
- Chinese text wraps after ~10 characters

**Window (desktop testing):**
- Width: 390px (mobile)
- Height: 90% screen height
- GTK configured in `linux/runner/my_application.cc`

**Reusable Components:**
- `common_widgets.dart`: SearchBarWidget, BackToTopButton, EmptyState, LoadingState, CoverImage, BadgeWidget, StatusBadge, GenreBadge, PtypeBadge, FilterChipWidget, StatItem, formatNumber, NovelFilterBottomSheet
- `spacing.dart`: AppSpacing, AppTextStyles, AppDecorations
- `novel_rank_list.dart`: NovelRankList, NovelRankRow
- `novel_card.dart`: NovelCard

## Project Structure

```
lib/
├── main.dart
├── app/
│   ├── router.dart         # go_router config
│   ├── theme.dart          # light/dark themes
│   ├── theme_provider.dart # theme mode state
│   └── settings_provider.dart # settings state
├── data/
│   ├── models/
│   │   ├── database.dart   # drift tables + queries
│   │   └── merged_database.dart # chunk merging logic
│   ├── repositories/
│   │   └── providers.dart  # Riverpod providers
│   └── services/
│       ├── jsonl_parser.dart
│       ├── sync_service.dart
│       └── chunked_sync_service.dart
├── features/
│   ├── home/               # hero banner carousel, quick nav
│   ├── novels/             # list (list view), detail, by-genre, by-status
│   ├── authors/            # list, detail
│   ├── tags/               # list, detail with filter
│   ├── contests/           # list, detail with filter
│   ├── banner/             # banner tab (dedicated)
│   ├── browse/             # enum list screens
│   ├── rankings/           # 6 tabs, rank-style list
│   ├── search/             # full screen search
│   └── settings/           # sync, reset, theme, stats
└── shared/
    ├── widgets/
    │   ├── novel_card.dart
    │   ├── novel_rank_list.dart  # Reusable rank-style list
    │   └── common_widgets.dart   # Reusable UI components
    └── utils/
        ├── mappings.dart   # enum mappings
        └── spacing.dart    # Consistent spacing system
```

## Common Pitfalls

- **build_runner**: Must run after model/provider changes
- **JSONL**: Each line is a separate JSON object, not array
- **Cover URLs**: May be null; default cover → `null` in DB
- **Tags**: JSON array in JSONL, needs join table in SQLite
- **last_update**: ISO 8601 with timezone
- **Enum values**: Index 1 is always OTHER/fallback (not 0)
- **nid < 10000**: Test data, may have bugs; use meta_13.jsonl for real data
- **Database singleton**: Use `@Riverpod(keepAlive: true)` to prevent multiple instances

## Git Rules

**NEVER use `git add .` or `git add -A`** — always specify files or directories explicitly:

```bash
# ✅ Correct
git add lib/features/novels/novels_screen.dart
git add lib/shared/widgets/
git add AGENTS.md

# ❌ Wrong
git add .
git add -A
git add --all
```

This prevents accidentally committing:
- Untracked debug/temp files
- Large binary files
- Sensitive configuration
- Unintended changes

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
