#!/usr/bin/env python3
"""
parse_itemcache.py
Parsuje WoW 3.3.5a WDB cache subory - obsahuju vsetky itemy co klient
kedy videl zo servera (spravne Warmane IDcka).

Zdroje (merguju sa):
  - itemcache.wdb     : plne item data (nazov na offset 12)
  - itemnamecache.wdb : len nazvy itemov (nazov na offset 0)

Generuje aktualizovany ItemDatabase blok pre DetaurBar_Data.lua
"""

import struct
import os
import re

WDB_DIR  = r"D:\GAMES\World of Warcraft 3.3.5a\Cache\WDB\enUS"
LUA_FILE = "DetaurBar_Data.lua"

def parse_itemcache(path):
    """itemcache.wdb: zaznam = uint32 class + uint32 sub + uint32 unk + name_string"""
    items = {}
    with open(path, 'rb') as f:
        raw = f.read()
    offset = 24  # preskoc 24-bajtovy header
    while offset < len(raw) - 8:
        item_id   = struct.unpack_from('<I', raw, offset)[0]
        data_size = struct.unpack_from('<I', raw, offset + 4)[0]
        offset += 8
        if item_id == 0 and data_size == 0:
            break
        if data_size == 0 or offset + data_size > len(raw):
            offset += data_size
            continue
        record = raw[offset:offset + data_size]
        offset += data_size
        if len(record) < 13:
            continue
        try:
            null_pos = record.index(b'\x00', 12)
            name = record[12:null_pos].decode('utf-8', errors='replace').strip()
        except (ValueError, UnicodeDecodeError):
            continue
        if name and item_id > 0:
            items[item_id] = name
    return items

def parse_itemnamecache(path):
    """itemnamecache.wdb: zaznam = len nazov priamo (bez prefix uint32 fields)"""
    items = {}
    with open(path, 'rb') as f:
        raw = f.read()
    offset = 24  # preskoc header
    while offset < len(raw) - 8:
        item_id   = struct.unpack_from('<I', raw, offset)[0]
        data_size = struct.unpack_from('<I', raw, offset + 4)[0]
        offset += 8
        if item_id == 0 and data_size == 0:
            break
        if data_size == 0 or offset + data_size > len(raw):
            offset += data_size
            continue
        record = raw[offset:offset + data_size]
        offset += data_size
        # itemnamecache: nazov je priamo na zaciatku zaznamu
        try:
            null_pos = record.index(b'\x00')
            name = record[0:null_pos].decode('utf-8', errors='replace').strip()
        except (ValueError, UnicodeDecodeError):
            continue
        if name and item_id > 0:
            items[item_id] = name
    return items

def update_lua(items):
    with open(LUA_FILE, encoding='utf-8') as f:
        content = f.read()
    lines = ["DetaurBar.Data.ItemDatabase = {"]
    for item_id in sorted(items.keys()):
        name = items[item_id]
        safe = name.replace('\\', '\\\\').replace('"', '\\"')
        lines.append(f'    ["{safe.lower()}"] = {item_id},')
    lines.append("}")
    new_block = "\n".join(lines)
    pattern = re.compile(r'DetaurBar\.Data\.ItemDatabase\s*=\s*\{.*?\n\}', re.DOTALL)
    new_content, n = pattern.subn(new_block, content)
    if n == 0:
        new_content = content + "\n" + new_block + "\n"
    with open(LUA_FILE, 'w', encoding='utf-8') as f:
        f.write(new_content)

def main():
    items = {}

    p1 = os.path.join(WDB_DIR, "itemcache.wdb")
    p2 = os.path.join(WDB_DIR, "itemnamecache.wdb")

    if os.path.exists(p1):
        a = parse_itemcache(p1)
        print(f"itemcache.wdb     : {len(a)} itemov")
        items.update(a)

    if os.path.exists(p2):
        b = parse_itemnamecache(p2)
        print(f"itemnamecache.wdb : {len(b)} itemov")
        # itemcache ma prednost (obsahuje spravnejsie nazvy)
        for iid, name in b.items():
            if iid not in items:
                items[iid] = name

    print(f"Spolu (merge)     : {len(items)} unikatnych itemov\n")

    if not items:
        print("Ziadne itemy nenajdene.")
        return

    update_lua(items)
    print(f"Aktualizovany {LUA_FILE}.")
    print("Hotovo! /reload v hre.")

if __name__ == "__main__":
    main()
