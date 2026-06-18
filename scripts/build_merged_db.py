#!/usr/bin/env python3
"""
Build merged SQLite database from chunk files.
This runs at build time to avoid runtime database merging in Dart.
"""

import sqlite3
import os
import sys
from pathlib import Path


def merge_chunks(chunks_dir: str, output_path: str) -> None:
    """Merge cold, warm, hot chunks into a single database."""
    cold_path = os.path.join(chunks_dir, 'cold_chunk.sqlite')
    warm_path = os.path.join(chunks_dir, 'warm_chunk.sqlite')
    hot_path = os.path.join(chunks_dir, 'hot_chunk.sqlite')
    
    # Verify all chunks exist
    for path in [cold_path, warm_path, hot_path]:
        if not os.path.exists(path):
            print(f'Error: Chunk not found: {path}')
            sys.exit(1)
    
    print(f'Merging chunks...')
    print(f'  Cold: {cold_path}')
    print(f'  Warm: {warm_path}')
    print(f'  Hot: {hot_path}')
    print(f'  Output: {output_path}')
    
    # Use cold chunk as base
    import shutil
    shutil.copy2(cold_path, output_path)
    
    # Open merged database
    conn = sqlite3.connect(output_path)
    conn.execute('PRAGMA journal_mode=WAL')
    
    try:
        # Attach warm and hot chunks
        conn.execute(f"ATTACH '{warm_path}' AS warm")
        conn.execute(f"ATTACH '{hot_path}' AS hot")
        
        # Insert novels (unique by id, warm/hot have newer data)
        print('  Merging novels...')
        conn.execute('INSERT OR REPLACE INTO novels SELECT * FROM warm.novels')
        conn.execute('INSERT OR REPLACE INTO novels SELECT * FROM hot.novels')
        
        # Merge tags: map chunk tag IDs to cold tag IDs
        print('  Merging tags...')
        
        # Build tag name -> cold ID mapping
        cursor = conn.execute('SELECT name, id FROM tags')
        tag_name_to_id = {row[0]: row[1] for row in cursor}
        
        # For each chunk, build old_id -> cold_id mapping
        for chunk_alias in ['warm', 'hot']:
            # Get chunk's tag mapping
            chunk_cursor = conn.execute(f'SELECT id, name FROM {chunk_alias}.tags')
            old_to_new = {}
            for old_id, name in chunk_cursor:
                if name in tag_name_to_id:
                    old_to_new[old_id] = tag_name_to_id[name]
                else:
                    # New tag not in cold, insert it
                    conn.execute('INSERT OR IGNORE INTO tags (name) VALUES (?)', (name,))
                    new_id = conn.execute('SELECT id FROM tags WHERE name = ?', (name,)).fetchone()[0]
                    tag_name_to_id[name] = new_id
                    old_to_new[old_id] = new_id
            
            # Insert novel_tags with remapped tag IDs
            print(f'  Remapping novel_tags from {chunk_alias}...')
            chunk_novel_tags = conn.execute(
                f'SELECT novel_id, tag_id FROM {chunk_alias}.novel_tags'
            ).fetchall()
            
            for novel_id, old_tag_id in chunk_novel_tags:
                new_tag_id = old_to_new.get(old_tag_id)
                if new_tag_id is not None:
                    conn.execute(
                        'INSERT OR IGNORE INTO novel_tags (novel_id, tag_id) VALUES (?, ?)',
                        (novel_id, new_tag_id)
                    )
        
        # Merge contests
        print('  Merging contests...')
        conn.execute('INSERT OR REPLACE INTO contests SELECT * FROM warm.contests')
        conn.execute('INSERT OR REPLACE INTO contests SELECT * FROM hot.contests')
        
        # Merge authors
        print('  Merging authors...')
        
        # Collect all authors from all chunks
        all_authors = {}  # name -> {top_novel_id, top_novel_title, top_novel_clicks}
        
        for chunk_alias in ['main', 'warm', 'hot']:
            if chunk_alias == 'main':
                cursor = conn.execute('SELECT name, top_novel_id, top_novel_title, top_novel_clicks FROM authors')
            else:
                cursor = conn.execute(f'SELECT name, top_novel_id, top_novel_title, top_novel_clicks FROM {chunk_alias}.authors')
            
            for row in cursor:
                name, top_novel_id, top_novel_title, top_novel_clicks = row
                if name not in all_authors or top_novel_clicks > all_authors[name]['top_novel_clicks']:
                    all_authors[name] = {
                        'top_novel_id': top_novel_id,
                        'top_novel_title': top_novel_title,
                        'top_novel_clicks': top_novel_clicks,
                    }
        
        # Clear and repopulate authors table
        conn.execute('DELETE FROM authors')
        for author_name, author_stat in all_authors.items():
            conn.execute('''
                INSERT INTO authors (name, top_novel_id, top_novel_title, top_novel_clicks)
                VALUES (?, ?, ?, ?)
            ''', (
                author_name,
                author_stat['top_novel_id'],
                author_stat['top_novel_title'],
                author_stat['top_novel_clicks'],
            ))
        
        conn.commit()
        
        # Detach chunks
        conn.execute("DETACH warm")
        conn.execute("DETACH hot")
        
        # Get stats
        cursor = conn.cursor()
        cursor.execute('SELECT COUNT(*) FROM novels')
        novel_count = cursor.fetchone()[0]
        cursor.execute('SELECT COUNT(*) FROM authors')
        author_count = cursor.fetchone()[0]
        
        print(f'  Done! {novel_count:,} novels, {author_count:,} authors')
    finally:
        conn.close()


def main():
    if len(sys.argv) < 3:
        print('Usage: python3 build_merged_db.py <chunks_dir> <output_path>')
        print('Example: python3 build_merged_db.py assets/chunks assets/db/novel_hub.sqlite')
        sys.exit(1)
    
    chunks_dir = sys.argv[1]
    output_path = sys.argv[2]
    
    # Create output directory
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    merge_chunks(chunks_dir, output_path)


if __name__ == '__main__':
    main()
