# DetaurBar Price History Viewer

Samostatný HTML nástroj na prezeranie historických cenových dát z WoW SavedVariables súboru.

## Použitie

1. Otvor `index.html` v prehliadači (stačí dvojklik, netreba server)
2. Klikni **Load SavedVariables…** a vyber:
   ```
   WTF\Account\<tvoj_ucet>\Icecrown\Detaur\SavedVariables\Detaurtodo.lua
   ```
3. V ľavom paneli klikni na item — zobrazí sa graf cien v čase

## Súbory

| Súbor | Účel |
|-------|------|
| `index.html` | HTML štruktúra (vstupný bod) |
| `style.css` | Všetky štýly |
| `app.js` | Lua parser, UI, canvas graf |
| `items.js` | 21 682 itemov (ID → názov) z offline databázy |
| `build_items_json.py` | Generuje `items.js` z `DetaurBar_ItemDB.lua` |
| `README.md` | Tento súbor |

## Aktualizácia item mien

Keď aktualizuješ `DetaurBar_ItemDB.lua` (napr. po `python parse_itemcache.py` v koreni addonu), spusti:

```
python build_items_json.py
```

v priečinku `Dataanalysis/` — prepíše `items.js` s aktuálnymi názvami.

## Technológie

Čistý HTML + CSS + JavaScript (žiadne knižnice, žiadny server, funguje offline).
Lua parser je vlastný, šitý na mieru WoW SavedVariables formátu.
Graf kreslený priamo cez `<canvas>`.
