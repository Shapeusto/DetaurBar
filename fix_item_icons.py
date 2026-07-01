#!/usr/bin/env python3
"""
fix_item_icons.py
Overi/opravi ikony v DetaurBar.Data.ItemIcons podla znamych spravnych hodnt.

Pouzitie:
    python fix_item_icons.py
    -> Aplikuje KNOWN_FIXES na DetaurBar_ItemDB.lua (ak treba)
    -> Vypise zvyne nespravne ikony (ak nejake su)

Ziskavanie spravnych icon pathov v hre:
    /detaurid icon <id1> <id2> ...
"""

import re

LUA_FILE = r"D:\GAMES\World of Warcraft 3.3.5a\Interface\AddOns\Detaurtodo\DetaurBar_ItemDB.lua"

# Zname spravne ikony overene na Warmane (item_id -> spravny icon path)
KNOWN_FIXES = {
    # uncut rare gems (WotLK, Warmane)
    36917: r"Interface\\Icons\\INV_Jewelcrafting_Gem_12",   # Bloodstone
    36918: r"Interface\\Icons\\INV_Jewelcrafting_Gem_04",   # Scarlet Ruby
    36919: r"Interface\\Icons\\INV_Jewelcrafting_Gem_32",   # Cardinal Ruby
    36922: r"Interface\\Icons\\INV_Jewelcrafting_Gem_36",   # King's Amber
    36923: r"Interface\\Icons\\INV_Jewelcrafting_Gem_10",   # Chalcedony
    36925: r"Interface\\Icons\\INV_Jewelcrafting_Gem_35",   # Majestic Zircon
    36927: r"Interface\\Icons\\INV_Jewelcrafting_Gem_06",   # Twilight Opal
    36928: r"Interface\\Icons\\INV_Jewelcrafting_Gem_31",   # Dreadstone
    36929: r"Interface\\Icons\\INV_Jewelcrafting_Gem_09",   # Huge Citrine
    36931: r"Interface\\Icons\\INV_Jewelcrafting_Gem_33",   # Ametrine
    36932: r"Interface\\Icons\\INV_Jewelcrafting_Gem_07",   # Dark Jade
    36934: r"Interface\\Icons\\INV_Jewelcrafting_Gem_34",   # Eye of Zul
}


def parse_item_icons(text):
    entries = []
    lines = text.split('\n')
    in_icons = False
    for lineno, line in enumerate(lines, 1):
        if 'DetaurBar.Data.ItemIcons = {' in line:
            in_icons = True
            continue
        if in_icons:
            if line.strip() == '}':
                break
            m = re.match(r'\s*\[(\d+)\]\s*=\s*"([^"]+)"', line)
            if m:
                entries.append((int(m.group(1)), m.group(2), lineno, line))
    return entries


def item_name_from_db(text, item_id):
    for m in re.finditer(r'\s*\["([^"]+)"\]\s*=\s*(\d+)', text):
        if int(m.group(2)) == item_id:
            return m.group(1)
    return "???"


def main():
    with open(LUA_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    icon_entries = parse_item_icons(content)

    # Zistime co treba opravit
    to_fix = [(item_id, icon, lineno, raw) for item_id, icon, lineno, raw in icon_entries
              if item_id in KNOWN_FIXES and icon != KNOWN_FIXES[item_id]]
    ok = [(item_id, icon, lineno, raw) for item_id, icon, lineno, raw in icon_entries
          if item_id not in KNOWN_FIXES or icon == KNOWN_FIXES[item_id]]

    print(f"ItemIcons: {len(icon_entries)} entries")
    print(f"  OK:           {len(ok)}")
    print(f"  Treba opravit: {len(to_fix)}")
    print()

    if to_fix:
        print("Opravujem:")
        lines = content.split('\n')
        for item_id, icon, lineno, raw in to_fix:
            new_icon = KNOWN_FIXES[item_id]
            name = item_name_from_db(content, item_id)
            lines[lineno - 1] = raw.replace(icon, new_icon)
            print(f"  [{item_id:>5}] {name:25s} {icon}")
            print(f"        -> {new_icon}")
        print()

        with open(LUA_FILE, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
        print(f"Aplikovanych {len(to_fix)} oprat do {LUA_FILE}")
    else:
        print("Vsetky zname polozky su uz spravne.")


if __name__ == "__main__":
    main()
