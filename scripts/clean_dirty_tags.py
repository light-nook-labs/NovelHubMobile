#!/usr/bin/env python3
"""清理数据库中的脏数据标签
处理两种情况:
1. 未拆分的JSON数组格式标签: ["仙侠", "女性主角"] -> 拆分为单独的标签关联
2. 嵌套列表格式标签: [["tag1", "tag2"]] -> 拆分为单独的标签关联
"""

import sqlite3
import json
import os
import sys

from validators import normalize_tags

def clean_dirty_tags(db_path):
    """清理数据库中的脏数据标签"""
    print(f"\n处理数据库: {db_path}")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 1. 找到脏数据标签（JSON数组格式，包括嵌套列表）
    cursor.execute("SELECT id, name FROM tags WHERE name LIKE '[%'")
    dirty_tags = cursor.fetchall()
    
    if not dirty_tags:
        print("  未发现脏数据标签")
        conn.close()
        return
    
    print(f"  发现 {len(dirty_tags)} 个脏数据标签")
    
    total_fixed = 0
    total_deleted = 0
    
    for tag_id, tag_name in dirty_tags:
        try:
            # 解析JSON数组
            tag_list = json.loads(tag_name)
            if not isinstance(tag_list, list):
                continue
            
            print(f"  处理标签 ID={tag_id}: {tag_name[:60]}...")
            
            # 2. 找到使用这个脏数据标签的小说
            cursor.execute("""
                SELECT novel_id FROM novel_tags WHERE tag_id = ?
            """, (tag_id,))
            novel_ids = [row[0] for row in cursor.fetchall()]
            
            if not novel_ids:
                # 没有小说使用这个标签，直接删除
                cursor.execute("DELETE FROM tags WHERE id = ?", (tag_id,))
                total_deleted += 1
                continue
            
            # 3. 使用normalize_tags处理嵌套列表
            normalized_tags = normalize_tags(tag_list)
            
            if not normalized_tags:
                # 没有有效的标签，删除关联和标签
                cursor.execute("DELETE FROM novel_tags WHERE tag_id = ?", (tag_id,))
                cursor.execute("DELETE FROM tags WHERE id = ?", (tag_id,))
                total_deleted += 1
                continue
            
            # 4. 为每个标签名查找或创建正确的标签
            for single_tag_name in normalized_tags:
                single_tag_name = single_tag_name.strip()
                if not single_tag_name:
                    continue
                
                # 查找是否已存在这个标签
                cursor.execute("SELECT id FROM tags WHERE name = ?", (single_tag_name,))
                existing = cursor.fetchone()
                
                if existing:
                    correct_tag_id = existing[0]
                else:
                    # 创建新标签
                    cursor.execute("INSERT INTO tags (name) VALUES (?)", (single_tag_name,))
                    correct_tag_id = cursor.lastrowid
                    print(f"    创建新标签: {single_tag_name} (ID={correct_tag_id})")
                
                # 5. 为每个小说添加正确的标签关联（如果不存在）
                for novel_id in novel_ids:
                    cursor.execute("""
                        INSERT OR IGNORE INTO novel_tags (novel_id, tag_id)
                        VALUES (?, ?)
                    """, (novel_id, correct_tag_id))
                    if cursor.rowcount > 0:
                        total_fixed += 1
            
            # 6. 删除脏数据标签的关联
            cursor.execute("DELETE FROM novel_tags WHERE tag_id = ?", (tag_id,))
            
            # 7. 删除脏数据标签
            cursor.execute("DELETE FROM tags WHERE id = ?", (tag_id,))
            total_deleted += 1
            
        except json.JSONDecodeError:
            print(f"    无法解析JSON: {tag_name}")
        except Exception as e:
            print(f"    处理出错: {e}")
    
    conn.commit()
    conn.close()
    
    print(f"  修复了 {total_fixed} 个标签关联")
    print(f"  删除了 {total_deleted} 个脏数据标签")

def main():
    # 处理所有chunk数据库
    chunks_dir = os.path.expanduser("~/.local/share/novel_hub_mobile/chunks")
    
    if not os.path.exists(chunks_dir):
        print(f"chunks目录不存在: {chunks_dir}")
        print("请先运行应用以生成chunks目录")
        return
    
    for chunk_name in ['cold', 'warm', 'hot']:
        db_path = os.path.join(chunks_dir, f"{chunk_name}_chunk.sqlite")
        if os.path.exists(db_path):
            clean_dirty_tags(db_path)
        else:
            print(f"\n跳过 {chunk_name}_chunk.sqlite (文件不存在)")
    
    # 也处理合并后的数据库
    merged_db = os.path.expanduser("~/.local/share/novel_hub_mobile/novel_hub.sqlite")
    if os.path.exists(merged_db):
        print("\n处理合并后的数据库...")
        clean_dirty_tags(merged_db)
    
    print("\n清理完成！")

if __name__ == "__main__":
    main()
