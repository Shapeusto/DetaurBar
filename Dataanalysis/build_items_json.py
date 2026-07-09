"""Generate items.js (id -> name) from DetaurBar_ItemDB.lua (name -> id)."""
import re, json, sys, os

src = os.path.join(os.path.dirname(__file__), '..', 'DetaurBar_ItemDB.lua')
dst = os.path.join(os.path.dirname(__file__), 'items.js')

with open(src, 'r', encoding='utf-8') as f:
    text = f.read()

# Match: ["name"] = 12345,
pat = re.compile(r'\[\s*"([^"]+)"\s*\]\s*=\s*(\d+)\s*,')
id_to_name = {}
for m in pat.finditer(text):
    name, iid = m.group(1), int(m.group(2))
    if iid not in id_to_name:
        id_to_name[str(iid)] = name

with open(dst, 'w', encoding='utf-8') as f:
    f.write('// Auto-generated from DetaurBar_ItemDB.lua\n')
    f.write('var itemNames = ')
    json.dump(id_to_name, f, ensure_ascii=False, sort_keys=True)
    f.write(';\n')

print(f"Written {len(id_to_name)} entries to {dst}")
