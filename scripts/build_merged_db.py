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
        
        # Insert other tables
        print('  Merging tags...')
        conn.execute('INSERT OR REPLACE INTO tags SELECT * FROM warm.tags')
        conn.execute('INSERT OR REPLACE INTO tags SELECT * FROM hot.tags')
        
        print('  Merging contests...')
        conn.execute('INSERT OR REPLACE INTO contests SELECT * FROM warm.contests')
        conn.execute('INSERT OR REPLACE INTO contests SELECT * FROM hot.contests')
        
        print('  Merging novel_tags...')
        conn.execute('INSERT OR REPLACE INTO novel_tags SELECT * FROM warm.novel_tags')
        conn.execute('INSERT OR REPLACE INTO novel_tags SELECT * FROM hot.novel_tags')
        
        # Detach chunks
        conn.execute("DETACH warm")
        conn.execute("DETACH hot")
        
        conn.commit()
        
        # Recompute author stats
        print('  Recomputing author stats...')
        conn.execute('''
            UPDATE authors SET 
                novel_count = (
                    SELECT COUNT(*) FROM novels WHERE novels.author = authors.name
                ),
                banner_count = (
                    SELECT COUNT(*) FROM novels WHERE novels.author = authors.name AND has_banner = 1
                ),
                top_novel_id = (
                    SELECT id FROM novels 
                    WHERE novels.author = authors.name 
                    ORDER BY click_num DESC LIMIT 1
                ),
                top_novel_title = (
                    SELECT title FROM novels 
                    WHERE novels.author = authors.name 
                    ORDER BY click_num DESC LIMIT 1
                ),
                top_novel_clicks = (
                    SELECT COALESCE(MAX(click_num), 0) FROM novels 
                    WHERE novels.author = authors.name
                )
        ''')
        
        # Delete authors with no novels
        conn.execute('DELETE FROM authors WHERE novel_count = 0 OR novel_count IS NULL')
        
        conn.commit()
        
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
