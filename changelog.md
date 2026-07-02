# Changelog

## 2026-07-02 — Notes clipboard, delete button, loot fallback, flask icons fix

### Opravené: Ikonky flaskov v Price > Chart
- Flask of Endless Rage (46377), Pure Mojo (46378), Stoneblood (46379),
  Frost Wyrm (46376) mali nesprávne icon pathe `INV_Flask_1`–`INV_Flask_4`,
  ktoré v 3.3.5a neexistujú
- Opravené na `inv_alchemy_endlessflask_03`–`06` (overené z WotLK database)

### Opravené: Loot itemy bez názvu ukazovali "Loading Item [ID: ...]"
- Keď item nebol v offline DB a GetItemInfo vrátil nil, zobrazilo sa
  "Loading Item [ID: 9276]..." namiesto uloženého textu
- Oprava: zobrazí sa `item.title` (napr. "9276" alebo "item:9276")
- GetItemInfo sa stále volá pre server request; po doručení dát
  (GET_ITEM_INFO_RECEIVED) sa RefreshTasks zavolá a ukáže meno itemu

### Pridané: Delete button na Notes riadkoch
- Notes riadky teraz zobrazujú delete (X) tlačidlo — `row.deleteBtn:Show()`
- Predtým bolo tlačidlo skryté pre všetky notes kategórie

### Zmenené: Klik na note kopíruje text do clipboardu
- Namiesto `ChatFrame_OpenChat()` (otváralo chat) používa skrytý `EditBox`
  s `InputBoxTemplate`, umiestnený off-screen
- Po kliknutí: text sa nastaví, vyberie (highlight) a editačný box dostane focus
- Hráč stlačí Ctrl+C a môže vložiť kamkoľvek
- Rovnaké správanie pre klik na riadok aj na copy (📋) tlačidlo
- Focus sa automaticky zruší po 1 sekunde, na Escape, alebo kliknutím inam
- OnKeyDown handler na Escape: `ClearFocus()`; OnUpdate timeout 1s

## 2026-07-01 — Icon cache, gem icon fixes, AH pagination

### Opravené: Chýbajúce/nesprávne ikony gemov
- Väčšina `DetaurBar.Data.ItemIcons` pre WotLK gemy (rare aj epic) mala
  nesprávne icon pathe — používala špecifické názvy (`Bloodstone_01`,
  `TwilightOpal_01`, atď.), ktoré v 3.3.5a clienti neexistujú. Reálne ikony
  na Warmane sú `INV_Jewelcrafting_Gem_XX` (XX = 04–36).
- Opravené položky: 36917, 36918, 36919, 36922, 36923, 36925, 36927, 36928,
  36929, 36931, 36932, 36934. Overené v hre cez `/detaurid icon <id>`.
- Dve položky (36921 Autumn's Glow, 36930 Monarch Topaz) neboli v session cache
  — ponechané staré pathe, kým sa neoveria.

### Pridané: Automatický cache ikon
- `DetaurBar.Data.GetItemTexture(itemId)` v `DetaurBar_Data.lua`
- Kontroluje: `ItemIcons` → `DetaurBarDB.iconCache` → `GetItemInfo`
- Ak `GetItemInfo` vráti textúru, uloží ju do `DetaurBarDB.iconCache`
- Pri ďalšom reloadi je ikona ihneď k dispozícii
- V UI namiesto inline `ItemIcons[itemId]` + `GetItemInfo` používa
  `GetItemTexture` (Price tab, Loot tab)

### Opravené: AH scan nenašiel itemy na neskorších stranách
- Problém: `QueryAuctionItems` posielala `page` parameter na zlú pozíciu
  (4. namiesto 7.). Efekt: nikdy sa nespýtala na stránku > 0, len
  opakovane volala page 0 s odlišným invTypeIndex filterom.
- Oprava: správna signatúra `QueryAuctionItems(name, minLvl, maxLvl,
  invType, class, subclass, page, usable, quality, getAll)` — `page` je
  7. parameter.
- Pridaná paginácia: ak sa item nenašiel na page 0 a výsledkov je 50+
  (plná strana), skúša page 1, 2, ... až do MAX_PAGES (10).
- Výhradne `OnUpdate` driver volá `QueryAuctionItems` (guardy:
  `CanSendAuctionQuery()`, `AucAdvanced.Scan.IsScanning()`).
- `OnResults` iba číta výsledky a nastavuje stavové flagy
  (`scanNeedsNextPage`, `scanItemComplete`).
- Pre 3.3.5a: `GetNumAuctionItems("list")` vracia len 1 hodnotu
  (numOnPage), totalAuctions nie je k dispozícii.
