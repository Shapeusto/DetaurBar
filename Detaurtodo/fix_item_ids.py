#!/usr/bin/env python3
"""
fix_item_ids.py
Opravuje DetaurBar_Data.lua na zaklade realnych ID zo warmane servera.
Zdroj: DetaurIDFinder scan (GetItemInfo per ID -> porovnanie nazvov).
"""

import re

LUA_FILE = "DetaurBar_Data.lua"

# Opravy: nazov_itemu -> (stare_id, nove_id)
# Zistene z warmane servera cez GetItemInfo(id) scan
FIXES = {
    # Herbs
    "frost lotus":          (36902, 36908),
    "icethorn":             (36908, 36906),
    "lichbloom":            (36906, 36905),
    "adder's tongue":       (36905, 36903),

    # Herbs - shift o 1
    "kingsblood":           (3357,  3356),
    "liferoot":             (3358,  3357),
    "khadgar's whisker":    (3821,  3358),
    "goldthorn":            (3820,  3821),

    # Ore/Bar
    "bronze bar":           (2842,  2841),
    "silver bar":           (2843,  2842),
    "cobalt bar":           (36913, 36916),
    "saronite bar":         (36916, 36913),

    # WotLK Gems
    "monarch topaz":        (36927, 36930),
    "huge citrine":         (36930, 36929),
    "dark jade":            (36929, 36932),
    "twilight opal":        (36933, 36927),
    "dreadstone":           (46844, 36928),
    "king's amber":         (46845, 36922),

    # Crystallized Elements (vsetky posunte)
    "crystallized fire":    (37700, 37702),
    "crystallized water":   (37701, 37705),
    "crystallized earth":   (37702, 37701),
    "crystallized air":     (37703, 37700),
    "crystallized shadow":  (37704, 37703),
    "crystallized life":    (37705, 37704),

    # Eternals (posunte)
    "eternal earth":        (35622, 35624),
    "eternal water":        (35623, 35622),
    "eternal air":          (35625, 35623),
    "eternal life":         (35626, 35625),

    # Primals (posunte)
    "primal fire":          (22451, 21884),
    "primal air":           (22456, 22451),
    "primal shadow":        (22457, 22456),
    "primal might":         (22450, 23571),

    # Inks
    "celestial ink":        (39771, 43120),
    "ethereal ink":         (39772, 43124),

    # Cloths (cloth specialties)
    "moonshroud":           (41595, 41594),
    "spellweave":           (41594, 41595),
}

# Polozky ktore maju na warmane uplne ine itemy (nezname spravne ID)
# -> odstranit z offline DB aby sa nezobrazoval zly item
REMOVE = [
    "tin bar",                        # 2841 = Bronze Bar na warmane
    "bolt of silk cloth",             # 2320 = Coarse Thread
    "bolt of imbued frostweave cloth",# 33476 = iny item
    "emerald pigment",                # 39118 = iny item
    "grave moss",                     # 3356 = Kingsblood na warmane
    "fire leaf",                      # 36903 = Adder's Tongue na warmane
    "knothide leather scraps",        # 21886 = Primal Life na warmane
    "violet pigment",                 # 39119 = iny item
    "forest emerald",                 # 36928 = Dreadstone na warmane
    "darkflame ink",                  # 39773 = iny item
    "silvery pigment",                # 39120 = iny item
    "snowfall ink",                   # 43124 = Ethereal Ink na warmane
    "borean leather scraps",          # 33566 = iny item
    "nether pigment",                 # 39330 = iny item
    "alabaster pigment",              # 39115 = iny item
    "jadefire ink",                   # 39337 = iny item
    "azure pigment",                  # 39331 = iny item
    "royal ink",                      # 39336 = iny item
    "nightmare seed",                 # 22792 = Nightmare Vine
    "greater astral essence",         # 10998 = Lesser Astral Essence na warmane
    "living ruby",                    # 23077 = Blood Garnet na warmane
    "noble topaz",                    # 23079 = Deep Peridot na warmane
    "primal water",                   # 21884 = Primal Fire na warmane
    "felsteel bar",                   # 23571 = Primal Might na warmane
    "sun crystal",                    # 36932 = Dark Jade na warmane
    "shadow crystal",                 # 36931 = Ametrine na warmane
    "sky sapphire",                   # 36922 = King's Amber na warmane
    "golden pigment",                 # 39117 = iny item
    "dusky pigment",                  # 39116 = iny item
]

def main():
    with open(LUA_FILE, encoding="utf-8") as f:
        content = f.read()

    fixed = 0
    removed = 0
    skipped = 0

    # 1. Aplikuj opravy ID
    print("=== Opravujem IDcka ===")
    for name, (old_id, new_id) in FIXES.items():
        pattern = re.compile(
            r'(\["' + re.escape(name) + r'"\]\s*=\s*)' + str(old_id),
            re.IGNORECASE
        )
        new_content, n = pattern.subn(r'\g<1>' + str(new_id), content)
        if n:
            print(f"  OK  {name!r:40s}  {old_id} -> {new_id}")
            content = new_content
            fixed += 1
        else:
            print(f"  --  {name!r:40s}  (ID {old_id} nenajdene)")
            skipped += 1

    # 2. Odstran polozky s neznamymi spravnymi IDckami
    print("\n=== Odstranujem neplatne polozky ===")
    for name in REMOVE:
        pattern = re.compile(
            r'\s*\["' + re.escape(name) + r'"\]\s*=\s*\d+,?\s*\n',
            re.IGNORECASE
        )
        new_content, n = pattern.subn('\n', content)
        if n:
            print(f"  REMOVED  {name!r}")
            content = new_content
            removed += 1
        else:
            print(f"  --       {name!r} (nenajdene)")

    # 3. Uloz
    with open(LUA_FILE, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"\nHotovo: {fixed} opravene, {removed} odstranene, {skipped} preskocene.")

if __name__ == "__main__":
    main()
