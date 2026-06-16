#!/usr/bin/env python3
"""
Build chunked SQLite databases from Novel Hub JSONL data.

This script processes JSONL files from novel_hub release and creates
chunked SQLite databases based on activity level:

- Cold: 断更, 已完结 (inactive, never updated)
- Warm: 完结A, 断更A (low activity)
- Hot: 连载中 (high activity, updated monthly)

下架 (removed) data is excluded as it has no value.
"""

import json
import sqlite3
import os
import sys
from pathlib import Path
from typing import Optional

# Chunk configuration
CHUNKS = {
    'cold': {
        'statuses': ['断更', '已完结'],
        'description': 'Inactive data (never updated)',
    },
    'warm': {
        'statuses': ['完结A', '断更A'],
        'description': 'Low activity data',
    },
    'hot': {
        'statuses': ['连载中'],
        'description': 'High activity data (updated monthly)',
    },
}

# Status mapping
STATUS_MAP = {
    '其他': 1,
    '已完结': 2,
    '连载中': 3,
    '断更': 4,
    '断更A': 5,
    '完结A': 6,
    '下架': 7,
}

# Genre mapping
GENRE_MAP = {
    '其他': 1,
    '魔幻': 2,
    '玄幻': 3,
    '古风': 4,
    '科幻': 5,
    '校园': 6,
    '都市': 7,
    '游戏': 8,
    '同人': 9,
    '悬疑': 10,
}

# Ptype mapping
PTYPE_MAP = {
    '其他': 1,
    '免费': 2,
    '签约': 3,
    'VIP': 4,
}


def create_database(db_path: str, is_hot: bool = False) -> sqlite3.Connection:
    """Create SQLite database with schema.
    
    Args:
        db_path: Path to the database file
        is_hot: If True, create indexes for frequently queried fields
    """
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Create novels table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS novels (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            author TEXT,
            genre INTEGER DEFAULT 1,
            status INTEGER DEFAULT 1,
            ptype INTEGER DEFAULT 1,
            has_banner BOOLEAN DEFAULT 0,
            word_num INTEGER,
            click_num INTEGER,
            praise_num INTEGER,
            like_num INTEGER,
            comment_num INTEGER,
            review_num INTEGER,
            contest_id INTEGER,
            cover TEXT,
            last_update DATETIME,
            db_update DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Create authors table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS authors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
        )
    ''')
    
    # Create tags table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
        )
    ''')
    
    # Create novel_tags table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS novel_tags (
            novel_id INTEGER,
            tag_id INTEGER,
            PRIMARY KEY (novel_id, tag_id),
            FOREIGN KEY (novel_id) REFERENCES novels(id),
            FOREIGN KEY (tag_id) REFERENCES tags(id)
        )
    ''')
    
    # Create contests table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS contests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
        )
    ''')
    
    # Create indexes based on chunk type
    if is_hot:
        # Hot chunk needs more indexes for frequent queries
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_novels_status ON novels(status)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_novels_genre ON novels(genre)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_novels_ptype ON novels(ptype)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_novels_click_num ON novels(click_num DESC)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_novels_last_update ON novels(last_update DESC)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_novels_has_banner ON novels(has_banner)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_novel_tags_novel_id ON novel_tags(novel_id)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_novel_tags_tag_id ON novel_tags(tag_id)')
    else:
        # Cold/warm chunks need minimal indexes
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_novels_status ON novels(status)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_novels_click_num ON novels(click_num DESC)')
    
    conn.commit()
    return conn


def insert_novel(conn: sqlite3.Connection, novel: dict) -> None:
    """Insert a novel into the database."""
    cursor = conn.cursor()
    
    # Get mapped values
    status = STATUS_MAP.get(novel.get('status', '其他'), 1)
    genre = GENRE_MAP.get(novel.get('genre', '其他'), 1)
    ptype = PTYPE_MAP.get(novel.get('ptype', '其他'), 1)
    
    # Handle author
    author_name = novel.get('author')
    if author_name:
        cursor.execute('INSERT OR IGNORE INTO authors (name) VALUES (?)', (author_name,))
        cursor.execute('SELECT id FROM authors WHERE name = ?', (author_name,))
        cursor.fetchone()  # Just to ensure it exists
    
    # Handle contest
    contest_name = novel.get('contest')
    contest_id = None
    if contest_name:
        cursor.execute('INSERT OR IGNORE INTO contests (name) VALUES (?)', (contest_name,))
        cursor.execute('SELECT id FROM contests WHERE name = ?', (contest_name,))
        contest_id = cursor.fetchone()[0]
    
    # Insert novel
    cursor.execute('''
        INSERT OR REPLACE INTO novels 
        (id, title, author, genre, status, ptype, has_banner, 
         word_num, click_num, praise_num, like_num, comment_num, 
         review_num, contest_id, cover, last_update)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        novel['nid'],
        novel['title'],
        author_name,
        genre,
        status,
        ptype,
        novel.get('has_banner', False),
        novel.get('word_num'),
        novel.get('click_num'),
        novel.get('praise_num'),
        novel.get('like_num'),
        novel.get('comment_num'),
        novel.get('review_num'),
        contest_id,
        novel.get('cover'),
        novel.get('last_update'),
    ))
    
    # Handle tags
    for tag_name in novel.get('tags', []):
        cursor.execute('INSERT OR IGNORE INTO tags (name) VALUES (?)', (tag_name,))
        cursor.execute('SELECT id FROM tags WHERE name = ?', (tag_name,))
        tag_id = cursor.fetchone()[0]
        cursor.execute('''
            INSERT OR IGNORE INTO novel_tags (novel_id, tag_id) 
            VALUES (?, ?)
        ''', (novel['nid'], tag_id))


def get_chunk_category(status: str) -> Optional[str]:
    """Get the chunk category for a given status.
    
    Returns:
        Chunk name or None if status should be excluded (下架)
    """
    # Exclude 下架 (removed) data
    if status == '下架':
        return None
    
    # Find the chunk for this status
    for chunk_name, config in CHUNKS.items():
        if status in config['statuses']:
            return chunk_name
    
    # Default to cold for unknown statuses
    return 'cold'


def process_jsonl_files(jsonl_dir: str, output_dir: str) -> dict:
    """Process JSONL files and create chunked SQLite databases.
    
    Returns:
        Dictionary with statistics for each chunk
    """
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Initialize chunk connections
    connections = {}
    stats = {}
    
    for chunk_name, chunk_config in CHUNKS.items():
        db_path = os.path.join(output_dir, f'{chunk_name}_chunk.sqlite')
        is_hot = (chunk_name == 'hot')
        connections[chunk_name] = create_database(db_path, is_hot)
        stats[chunk_name] = {
            'count': 0,
            'statuses': {},
            'db_path': db_path,
        }
    
    # Process all JSONL files
    total_processed = 0
    skipped = 0
    
    jsonl_files = sorted(Path(jsonl_dir).glob('*.jsonl'))
    print(f'Found {len(jsonl_files)} JSONL files')
    print()
    
    for jsonl_file in jsonl_files:
        print(f'Processing {jsonl_file.name}...')
        
        with open(jsonl_file, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                
                try:
                    novel = json.loads(line)
                    status = novel.get('status', '其他')
                    
                    # Get chunk category
                    chunk_name = get_chunk_category(status)
                    
                    # Skip excluded data
                    if chunk_name is None:
                        skipped += 1
                        continue
                    
                    # Insert into the appropriate chunk
                    insert_novel(connections[chunk_name], novel)
                    stats[chunk_name]['count'] += 1
                    stats[chunk_name]['statuses'][status] = stats[chunk_name]['statuses'].get(status, 0) + 1
                    total_processed += 1
                    
                except json.JSONDecodeError as e:
                    print(f'  Warning: Invalid JSON at line {line_num}: {e}')
                    continue
                except Exception as e:
                    print(f'  Warning: Error processing line {line_num}: {e}')
                    continue
    
    # Commit and close connections
    for chunk_name, conn in connections.items():
        conn.commit()
        conn.close()
    
    return {
        'total_processed': total_processed,
        'skipped': skipped,
        'stats': stats,
    }


def get_file_size_mb(filepath: str) -> float:
    """Get file size in MB."""
    return os.path.getsize(filepath) / (1024 * 1024)


def main():
    # Default paths
    jsonl_dir = '/home/interset/Desktop/novel_hub/release/dataset'
    output_dir = '/home/interset/Desktop/mobile/scripts/output'
    
    # Allow overriding from command line
    if len(sys.argv) > 1:
        jsonl_dir = sys.argv[1]
    if len(sys.argv) > 2:
        output_dir = sys.argv[2]
    
    print('Novel Hub Chunk Builder')
    print('=' * 60)
    print(f'Input: {jsonl_dir}')
    print(f'Output: {output_dir}')
    print()
    
    if not os.path.exists(jsonl_dir):
        print(f'Error: Input directory not found: {jsonl_dir}')
        sys.exit(1)
    
    # Process JSONL files
    result = process_jsonl_files(jsonl_dir, output_dir)
    
    # Print statistics
    print()
    print('=' * 60)
    print('CHUNKING RESULTS')
    print('=' * 60)
    print()
    print(f'Total processed: {result["total_processed"]:,}')
    print(f'Skipped (下架): {result["skipped"]:,}')
    print()
    
    total_size = 0
    for chunk_name, chunk_stats in result['stats'].items():
        db_path = chunk_stats['db_path']
        size_mb = get_file_size_mb(db_path)
        total_size += size_mb
        
        print(f'{chunk_name.upper()} CHUNK:')
        print(f'  Records: {chunk_stats["count"]:,}')
        print(f'  Size: {size_mb:.2f} MB')
        print(f'  Description: {CHUNKS[chunk_name]["description"]}')
        print(f'  Statuses:')
        for status, count in sorted(chunk_stats['statuses'].items(), key=lambda x: -x[1]):
            print(f'    {status}: {count:,}')
        print()
    
    print(f'Total size: {total_size:.2f} MB')
    print()
    
    print('Done!')


if __name__ == '__main__':
    main()
