# Routes Documentation

## Route Overview

| Path | Page | Description |
|------|------|-------------|
| `/` | Home | Hero carousel + quick nav |
| `/novels` | Novel List | 4-column grid, filter support |
| `/novels-by-genre` | Filter by Genre | ?genre=魔幻 |
| `/novels-by-status` | Filter by Status | ?status=连载中 |
| `/banners` | Banner List | Dedicated banner tab |
| `/rankings` | Rankings | 6 dimension tabs |
| `/search` | Search | Full text search |
| `/settings` | Settings | Sync, reset, theme |
| `/novel/:id` | Novel Detail | Cover + info + source |
| `/authors` | Author List | Sorted by total clicks |
| `/author/:id` | Author Detail | Author's works list |
| `/tags` | Tag List | 3-column grid |
| `/tag/:id` | Tag Detail | Tag's works list |
| `/contests` | Contest List | 2-column grid |
| `/contest/:id` | Contest Detail | Contest related works |
| `/genres` | Genre List | All novel genres |
| `/statuses` | Status List | All novel statuses |
| `/ptypes` | Ptype List | All novel types |

## Bottom Navigation

| Index | Label | Path | Icon |
|-------|-------|------|------|
| 0 | Home | `/` | home |
| 1 | Novels | `/novels` | book |
| 2 | Banners | `/banners` | image |
| 3 | Rankings | `/rankings` | trending_up |
| 4 | Settings | `/settings` | settings |

## Page Details

### Home `/`

**Features:**
- Hero carousel showing top 5 banner novels
- Quick nav: Novels, Authors, Tags, Contests, Search
- Latest novels list

**Data:**
- Carousel: `has_banner = true` novels, sorted by `click_num`
- Latest: sorted by `last_update`, top 10

---

### Novel List `/novels`

**Features:**
- 4-column grid showing novel covers
- Header tabs for ptype: All/Free/Signed/VIP
- Pull refresh + load more (48 per page)
- Click to enter novel detail

**Filter Parameters:**
- `ptype`: Novel type (optional)

**Data:**
- Sorted by `click_num` DESC
- Paginated, 48 per page

---

### Novel Detail `/novel/:id`

**Features:**
- Left: Novel info (title, author, status, genre, ptype)
- Right: Cover image
- Bottom: Chapter list (if available)
- Footer: Source reference (with image preview)

**Data:**
- Novel basic info
- Associated banner image
- Source document info

---

### Rankings `/rankings`

**Features:**
- 6 tabs: Clicks/Words/Likes/Praises/Reviews/Comments
- Each tab: Rank list (rank + cover + title + badges + value)
- Load more support (48 per page)
- Back to top button

**Data:**
- Sorted by corresponding dimension DESC
- Default shows click ranking

---

### Search `/search`

**Features:**
- Real-time search (debounce 300ms)
- Results: Novel list + Author list + Tag list
- Support title, author name, tag name search

**Data:**
- Full text search (title, author, tags)
- Results sorted by relevance

---

### Author List `/authors`

**Features:**
- List display: Author name + top novel + banner/novel count
- Sorted by total clicks DESC
- Load more support (48 per page)
- Back to top button

**Data:**
- Total clicks = sum of all author's novels
- Top novel = highest click count

---

### Author Detail `/author/:id`

**Features:**
- Author info display
- Works list (rank style: rank + cover + title + badges + clicks)
- Load more support (48 per page)
- Back to top button

---

### Tag List `/tags`

**Features:**
- 3-column grid showing tags
- Each tag shows name and novel count
- Load more support (48 per page)
- Back to top button

---

### Tag Detail `/tag/:id`

**Features:**
- Tag name display
- Works list (rank style: rank + cover + title + badges + clicks)
- Filter support (clicks/words/likes/praises/update time)
- Load more support (48 per page)
- Back to top button

---

### Contest List `/contests`

**Features:**
- 2-column grid showing contests
- Each contest shows name and novel count
- Load more support (48 per page)
- Back to top button

---

### Contest Detail `/contest/:id`

**Features:**
- Contest name display
- Related works list
- Load more support

---

### Banner List `/banners`

**Features:**
- Display all banner novels
- Sorted by clicks
- Load more support

---

### Genre List `/genres`

**Features:**
- Display all novel genres (魔幻, 玄幻, 古风, etc.)
- Click to enter genre's novel list
- Show novel count for each genre

---

### Status List `/statuses`

**Features:**
- Display all novel statuses (连载中, 已完结, etc.)
- Click to enter status's novel list
- Show novel count for each status

---

### Ptype List `/ptypes`

**Features:**
- Display all novel types (免费, 签约, VIP)
- Click to enter type's novel list
- Show novel count for each type

---

### Settings `/settings`

**Features:**
- Theme mode: System/Light/Dark
- Hide "Other" option toggle
- Sync data from GitHub Releases
- Reset data to default
- Data statistics
- Project info and links

---

## Query Parameters

### Novel List Filter

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `ptype` | string | Novel type | `/novels?ptype=免费` |

### Genre/Status/Type Filter

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `genre` | string | Novel genre | `/novels-by-genre?genre=魔幻` |
| `status` | string | Novel status | `/novels-by-status?status=连载中` |

---

## Route Guards

### Tenant Isolation

- All data queries automatically apply tenant isolation
- Different tenant data completely isolated

### Login State

- Current version does not require login
- Can be extended for login functionality in future

---

## Route History

### v0.1 (2026-06-14)

- Initial route configuration
- Basic page routes
- Bottom navigation
