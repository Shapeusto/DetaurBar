# Changelog

## 2026-07-07

### Fixed: Dismount on action nefungovalo z keybindingov a spôsobovalo taint

#### Problém 1: Syntax error – chýbajúci `end` v event handleri
- `DetaurBar_Core.lua:131` – po bloku `MERCHANT_SHOW` chýbal druhý `end` pre uzavretie hlavného `if...elseif` reťazca. Lua parser hlásil "unexpected symbol near ')'".

#### Problém 2: PreClick hook nechytal keybinding
- V 3.3.5a keybinding volá `UseAction(slot)` priamo v C kóde, čím obchádza `PreClick` na action buttonoch.
- Pokus o wrapper na `UseAction` fungoval, ale spôsobil **taint** ("Detaurtodo has been blocked from an action only available to Blizzard UI").

#### Riešenie: SetOverrideBindingClick namiesto wrapp eru UseAction
- Pridaný `DetaurBar.Core.SetupOverrideBindings()` – pre každý action slot (ActionButton1-12, MultiBar*, PetActionButton1-10, StanceButton1-10, ExtraActionButton1) získa binding key cez `GetBindingKey()` a nastaví `SetOverrideBindingClick`, ktorý presmeruje keybind na `:Click()` na príslušnom button frame.
- `:Click()` spustí secure `OnClick` handler, ktorý zavolá `PreClick` – a tam náš `HookScript` hook zavolá `TryDismount()`.
- Registrovaný `UPDATE_BINDINGS` event – obnoví overrides pri zmene keybindingov.

#### Výsledný flow
- **Myš**: klik → PreClick (hook) → TryDismount() → OnClick → spell
- **Klávesa**: keybind → SetOverrideBindingClick → ActionButton:Click() → PreClick (hook) → TryDismount() → OnClick → spell
- Žiadny taint, lebo `HookScript` a `SetOverrideBindingClick` sú taint-safe API.

### Changed: Dismount on action – len na lietajúcom mounte (gear/equipset bez dismountu)

#### Problém
- Dismount na každej akcii spôsoboval zbytočné dismouty pri prepínaní gearu (equipment manager, `/equipset`).
- Detekcia cez `GetActionInfo` / `GetAttribute` zlyhávala, lebo equipment manager volá `UseEquipmentSet()` priamo (obchádza action buttony).

#### Riešenie: Dismountovať len keď si na lietajúcom mounte
- Pridaná `IsOnFlyingMount()` – detekcia lietajúceho mounta:
  - `IsMounted()` + `IsFlyableArea()` (neflyable zóna = ground mount → nikdy dismount)
  - `GetUnitSpeed("player") > 2.25` (násobiteľ rýchlosti; ground max ~2.0, flying min ~2.5)
  - Speed = 0 (stojíš na mieste) v flyable zóne → predpoklad flying → dismount
- `TryDismount()` teraz kontroluje `IsOnFlyingMount()` namiesto `IsMounted()`
- Odstránené komplexné `GetActionSlot`, `IsEquippableId`, `MacroIsGearEquip` – už netreba
- `HookActionButton` zjednodušený naspäť na priame volanie `TryDismount()`

#### Flow
- **Lietajúci mount**: akcia → PreClick → `IsOnFlyingMount()` = true → `Dismount()`
- **Pozemný mount**: akcia → PreClick → `IsOnFlyingMount()` = false → bez dismountu (gear, macro, equipset, všetko funguje)
- **Bez mounta**: `IsMounted()` = false → bez dismountu (netreba)

### Added: Show alerts in chat (Settings > Various)
- Nová voľba "Show alerts in chat" v Settings > Various
- `DetaurBar.Core.PrintAlert(msg)` – helper ktorý skontroluje nastavenie a vypíše do chatu modrou správu s prefixom `[DetaurBar]`
- Chat výpis pridaný ku všetkým alertom:
  - **Dungeon Alert** – na LFG_PROPOSAL_SHOW
  - **Wintergrasp Alert** / **Wintergrasp Battle Start** – pri WG alertoch
  - **Random Alert: <názov>** – pri random alertoch (vypíše meno alertu)
  - **Enemy Alert: <meno>** – pri prvom objavení v monitorovacom okne (po zmiznutí a novom objavení znovu)
  - **Mind Control Alert: <meno>** – pri Mind Controle v parté/raide
- Default vypnuté

### Fixed: Enemy chat alert len pri prvom objavení v monitori; Buffy bez chatu
- **Enemy Alert** – presunutý z `OnNewEnemy` (volaný pri každom combat log evente) do `AddOrUpdateEnemy()` – vypíše sa len keď sa nepriateľ prvýkrát objaví v monitorovacom okne. Po zmiznutí (120s) a novom objavení sa vypíše znova.
- **Buff Alert** – odstránený chat výpis úplne (cooldown alert aj Maelstrom Weapon stacks). Flash a center-screen ikona ostávajú.

### Added: Delete price data point (right-click on graph dot)
- Každá bodka v grafe má hover frame (Button) s `RegisterForClicks("RightButtonUp")` a `OnClick` handlerom
- Pravým klikom na bodku sa zobrazí custom confirm frame s Yes/No tlačidlami
- Po potvrdení `DetaurBar.Data.DeletePricePoint(itemId, timestampStr)` vymaže iba tú jednu bodku
- `DetaurBar_Data.lua` – nová funkcia `DeletePricePoint`
- `DetaurBar_UI_Graph.lua` – `GfFrame` zmenený z `Frame` na `Button` (RegisterForClicks v 3.3.5a nie je na Frame)
- Tooltip zobrazuje "Right-click to delete"

### Changed: SavedVariables → SavedVariablesPerCharacter
- `Detaurtodo.toc` – `## SavedVariables` → `## SavedVariablesPerCharacter`
- Dáta sú per-char, nie account-wide
- Migrácia: account-wide `Detaurtodo.lua` skopírovaný do `Account\MATUSY\Icecrown\Detaur\SavedVariables\`
- Ostatné postavy na MATUSY začínajú s prázdnym DetaurBarDB

### Added: Scan auction house checkbox (Settings > Various)
- Nový checkbox "Scan auction house" v Settings > Various
- `ahScanningEnabled = true` default
- Keď vypnuté, `AHScan.StartScan()` returnne hneď na začiatku – žiadny scan sa nespustí
- `DetaurBar_Data.lua`, `DetaurBar_UI.lua`, `DetaurBar_AHScan.lua`

### Removed: Dismount on action (funkcia je v 3.3.5a zabudovaná)
- Odstránené `IsOnFlyingMount()`, `TryDismount()`, `HookActionButton()`, `HookActionButtons()`, `SetupOverrideBindings()`, `OverrideActionBinding()`
- Odstránený checkbox "Dismount on action" z Settings > Various
- Odstránený `dismountOnActionEnabled` z InitializeDB
- Odstránené `UPDATE_BINDINGS` event a handler
- Všetky súbory: `DetaurBar_Core.lua`, `DetaurBar_Data.lua`, `DetaurBar_UI.lua`

## 2026-07-06

### Fixed: Northrend herb ID nightmare (konečne správne)

#### Problém
Warmane (WotLK 3.3.5a private server) používa **iné itemID pre Northrend bylinky** než oficiálny Blizzard cache `itemcache.wdb`. Bylinky sú posunuté – nie systematicky (nie +N), ale každá má iný posun oproti stock WotLK databáze.

#### Čo všetko zlyhalo

| Pokus | Čo sa stalo |
|-------|-------------|
| **v1** (forward mapping) | V1 naniesla mapovanie staré→nové ID na všetky `item:ID` položky. Fungovalo pre tie, čo mali správny pôvodný názov. |
| **v2** | Spustila to isté mapovanie ZNOVA. Stacking: 36903→36905→36906→36908→36902 – každé ďalšie spustenie posunulo ID o ďalší krok. |
| **v3** | Rovnaký problém – stacking pokračoval. Bylinky sa reťazovo menili na úplne iné. |
| **`_migratedHerbIdsFinal`** | Opravovala už len **link formát** (`\|Hitem:ID\|h[Meno]\|h`), nie `item:ID` – lebo pri ňom nie je uložené meno a nedá sa skrížiť s DB. Tento prístup bol správny, ale neriešil `item:ID` položky. |
| **`/detaurfixherbs` (pôvodný)** | **DEVASTATUJÚCE**: nastavil `DetaurBarDB.price = {}` namiesto opravy ID. Zmazal všetky cenníkové záznamy. **ODSTRÁNENÝ**. |
| **ItemDatabase ručná oprava** | Namiesto vygenerovania DB z Warmane cache boli ID nastavené tipovaním: `frost lotus=36902`, `fire leaf=36903`, `adder's tongue=36905`, `lichbloom=36906`, `icethorn=36908`. **ŽIADNE z týchto ID nesedí na Warmane!** |
| **DetaurIDFinder in-game** | Nástroj ukázal správne ID pre Goldclover, ale ostatné bylinky neboli v session cache a `GetItemInfo` vrátil nil. Výsledok: databáza zostala nesprávna. |

#### Čo ukázala Warmane cache (7. 7. 2026)
Po priamom prečítaní `Cache/WDB/enUS/itemcache.wdb`:

| ID | Warmane meno | Čo hovorila stará DB |
|---|-------------|---------------------|
| 36901 | Goldclover | Goldclover (✓) |
| 36902 | **NOT FOUND** (neexistuje) | frost lotus (✗) |
| 36903 | **Adder's Tongue** | fire leaf (✗) |
| 36904 | Tiger Lily | Tiger Lily (✓) |
| 36905 | **Lichbloom** | adder's tongue (✗) |
| 36906 | **Icethorn** | lichbloom (✗) |
| 36907 | Talandra's Rose | Talandra's Rose (✓) |
| 36908 | **Frost Lotus** | icethorn (✗) |
| 39970 | **Fire Leaf** | chýbal v DB |

Žiadne ID 36902 na Warmane neexistuje. Frost Lotus je na 36908, Fire Leaf na 39970.

#### Konečné riešenie
1. **ItemDatabase** (name→ID) opravený podľa Warmane cache:
   - `frost lotus = 36908` (nebol 36902)
   - `adder's tongue = 36903` (nebol 36905)
   - `lichbloom = 36905` (nebol 36906)
   - `icethorn = 36906` (nebol 36908)
   - `fire leaf = 39970` (nebol 36903)
2. **ItemIcons** (ID→textúra) opravené:
   - [36905] → Lichbloom (bol AddersTongue)
   - [36906] → Icethorn (bol Lichbloom)
   - [39970] → FireLeaf (chýbalo)
   - [36903] a [36905] odstránené z ItemIcons → nechá sa vyriešiť cez `GetItemInfo` (server poskytne skutočnú cestu ikony)
3. **Migrácia v4** (`_migratedHerbIdsV4`): opraví `item:ID` aj link formát pri každom reload-e pomocou mapovania:
   - `36902→36908, 36903→39970, 36905→36903, 36906→36905, 36908→36906`
4. **`/detaurfixherbs`** (nová bezpečná verzia): to isté mapovanie aplikuje okamžite, nič nemaže, iba mení ID.
5. **`/detaurrecover` a `/detaurrestore`** obnovia dáta z disku (ktoré boli v starom array formáte a nedostupné).

#### Poučenie
- Nikdy nemeniť `ItemDatabase` ručne – vždy generovať z `itemcache.wdb` (parse_itemcache.py)
- Pri `item:ID` formáte sa nedá zistiť pôvodné meno – ak je ID zlé, treba mapovať staré→nové ID explicitne
- Warmane ID sa LÍŠIA od stock WotLK – overovať vždy z cache, nie z webu
- `DetaurIDFinder` je spoľahlivý len ak je item v session cache (`GetItemInfo` vracia data)
- Mazanie cenníka v menej migrácie je neprípustné – vždy len premapovať ID, nikdy nemaž

### Fixed: Price list data boli v pamäti prázdne ale na disku v poriadku
- **Príčina**: kód v `GetItems("price")` očakával `DetaurBarDB.price["Horde"]` (faction-kľúč), ale staré dáta boli uložené ako pole `DetaurBarDB.price[1], [2], ...` (array formát). Po prechode na faction formát nikto nenapísal migráciu starých dát.
- **Dôsledok**: `GetItems("price")` vracal `DetaurBarDB.price["Horde"]` čo bolo prázdne `{}`, hoci reálne položky boli na indexoch 1-13.
- **Oprava**: migrácia v `InitializeDB()` + `/detaurrecover` (okamžitá oprava v pamäti bez reloadu).

### Added
- `/detaurrecover` – zachráni položky uviaznuté v starom array formáte
- `/detaurrestore` – obnoví 18 chýbajúcich položiek zo zálohy (1.7.) s thresholdmi
- `_migratedHerbIdsV4` – migrácia herb ID v `InitializeDB()`
- Settings Menu (gear) > Various sub-tab s dvoma checkboxmi:
  - **Alert Mind Control**: keď parták dostane Mind Control, zobrazí sa v strede obrazovky červený text "[Meno] has Mind Control!" (fade po 4s). Detekcia cez `COMBAT_LOG_EVENT_UNFILTERED` pre kúzla obsahujúce "Mind Control" na hráčoch v parté/raide.
  - **Autosell junk and autorepair**: pri otvorení vendora (`MERCHANT_SHOW`) automaticky predá všetky grey itemy (quality=0) a opraví výstroj (`RepairAllItems(true)`).
- Obe nastavenia persistentné v `DetaurBarDB.settings.mindControlAlertEnabled` / `autoSellRepairEnabled`.
- Settings > Various: pridaný checkbox **Dismount on action** — automaticky zosadí z mounta (`Dismount()`) pri `UNIT_SPELLCAST_SENT`, `ACTIONBAR_UPDATE_STATE` a `BAG_UPDATE` (aby zachytil akcie blokované mountom aj itemy z batoha). Debounce 1s.
- Opravené `AutoSellAndRepair`: `RepairAllItems(true)` → `RepairAllItems()` (3.3.5a nepozná guild bank parameter) + `CanMerchantRepair()` check.

### Changed
- Settings Menu checkboxes (Loot a Alert) používajú `GameFontNormal` namiesto `GameFontNormalSmall` (väčšie písmo)
- Enemy monitor toggle ikona: `INV_Misc_Eye_01` → `Spell_Nature_BloodLust`
- Minimap button ikona: `INV_Misc_Note_01` → `Spell_Nature_BloodLust`

### Renamed (kód — žiadny vplyv na funkčnosť)
- **Alert tab** kód: všetky `settings*` prefixy premenované na `alert*`, aby nedošlo k zámene so Settings Menu (gear button). Týka sa `DetaurBar.UI.*` API aj lokálnych premenných/funkcií v `DetaurBar_UI_Settings.lua`:
  - `settingsPanel/SubTabBar/SubTabs/ListBackground/ScrollFrame/ScrollChild/SaveButton` → `alert*`
  - `activeSettingsSubTab` → `activeAlertSubTab`
  - `UpdateSettingsSubTabBar/Visuals/Panel/Scroll` → `UpdateAlert*`
  - `SelectSettingsSubTab` → `SelectAlertSubTab`
  - `SetSettingsControlsVisible/SubTabStyle` → `SetAlert*`
  - Všetky control group premenné (`settingsDungeonControls`, `settingsRaidRollColorButtons`, atď.) → `alert*`
  - Factory funkcie (`CreateSettingsLabel/Check/ChoiceRow/EditRow/EditBox`) → `CreateAlert*`
- **Settings Menu** (gear) názvy (`settingsMenu*`, `settingsBtn`, `smSettings*`) zostali nezmenené.

### Merged
- Zlúčené tab-y Todo a Notes do jedného tabu "Note"
- Nová dátová štruktúra `DetaurBarDB.tasks` (staré `todo` / `notes` sa ignorujú)
- Daily reset o 3:00 odškrtáva všetky položky vo všetkých kategóriách

### Added
- Checkbox ku každej položke (completed/nesplnené) z Todo
- Užívateľom definované kategórie (Add/Delete category, scroll šípky)
- Click-to-copy: klik na riadok skopíruje text, 1 sekunda na Ctrl+C
- Drag-to-move: pretiahnutie riadku na inú kategóriu
- Nový **Settings Menu** panel (gear button) — namiesto otvárania Alert tabu
  - Dva sub-taby: Loot (Add/Delete checkboxes) a Alert (Dung/Raid/WG/Random/Enemy checkboxes)
  - Persistentné nastavenia v `DetaurBarDB.settings.lootSubTabsVisible` / `alertSubTabsVisible`
- Dynamické skrývanie/zobrazovanie Loot a Alert sub-tabov podľa zaškrtnutia v Settings Menu
- Ochrana General kategórie (nedá sa zmazať — `DeleteTaskCategory` + UI)

### Changed
- Tab button "Notes" → "Note"
- Tab button "Settings" → "Alert"
- Sub-tab "Dungeon" → "Dung" v Alert tab-e
- Resize grip: používa `RegisterForDrag` namiesto `OnMouseDown`/`OnMouseUp`
- `DetaurBar_UI_Todo.lua` odstránený z TOC
- Tooltip pre copy-to-chat skrátený, ikonka copyBtn odstránená z task riadkov
- Gear button otvára Settings Menu panel (inline v hlavnom frame) namiesto Alert tabu
- Settings Menu panel: kontajner bez vlastného backdropu, dark box je samostatný frame 28px pod sub-tabmi (vizuálne zhodné s Loot tabom)
- Zatvorenie Settings Menu (gear button / tab switch) vráti zobrazenie na Notes > General
- Gear button nezanecháva focusnutý tab — všetky 4 hlavné taby sú v normálnom stave

### Fixed
- **`listBackground` prekrývanie (REKURENTNÝ BUG)**: pri prepnutí na Settings tab (Alert) alebo otvorení Settings Menu (gear) zostával `listBackground` (tmavý box zoznamu) viditeľný a prekrýval sa s `settingsListBackground`. Prejavilo sa to ako duplicitné okraje/dvojité čiary.
  - Príčina 1: v `UpdateContentAnchors()` chýbalo `listBackground:Hide()` v `activeTab == "Settings"` vetve
  - Príčina 2: `UpdateContentAnchors()` je definovaná pred lokálnou deklaráciou `listBackground` (Lua 5.1 scope — lokálna premenná nie je viditeľná pred svojou deklaráciou), takže holý `listBackground` sa vyhodnocoval ako globál → nil, a `if listBackground then` nikdy neprešlo. Oprava: používať `DetaurBar.UI.listBackground` (vždy prístupné cez globálny namespace)
  - **Rovnaký problém** platí pre `editBox` a `addButton` — všetky tri lokálne premenné sú deklarované až po `UpdateContentAnchors`, preto v nej treba vždy používať `DetaurBar.UI.*` verziu
- Checkboxy v Settings Menu ukladajú zmeny do DB okamžite (nie až po reloade)
- `ToggleVisibility` (minimap button / slash command) vždy zobrazí Notes > General
- `ToggleSettingsMenu`: pridané `SetTabButtonsActive` pre správne focusovanie tabov
- `tabs` a `activeTab` scope: funkcie `SetTabButtonsActive` a `ToggleSettingsMenu` presunuté až po deklarácii lokálnych premenných

### Removed
- Copy button (ikonka) z task riadkov — zbytočná, keďže copy funguje klikom na celý riadok

---

## 2026-07-08 — Item tracking (Alert > Item sub-tab), bugfixy

### Added
- **Item sub-tab** v Alert: 5×5 drag-from-bags grid (25 slotov), Enable Item Tracking checkbox
- Divider, Alert interval (minutes, default 30) a Alert threshold (count, default 0) edit boxy
- **Item tracking timer** v `DetaurBar_Core.lua` – OnUpdate na eventFrame, každých N minút skontroluje počty itemov v bagoch
- **Chat alert** keď počet ≤ threshold: `[DetaurBar] Low on <meno>: <count> remaining`
- Settings > Alert checkbox pre skrytie Item sub-tabu (v settingsMenuPanel)

### Fixed
- **Settings file crash** – `DetaurBar.UI.SetSimpleTooltip()` volaný na **FontString** (nie Frame), čo v 3.3.5a padá. Celý `DetaurBar_UI_Settings.lua` sa nenačítal → `SelectAlertSubTab` ostal nil → všetky sub-tab kontrolky boli viditeľné naraz
- **Drag do slotu** – `GetCursorInfo()` vracia v 3.3.5a druhú hodnotu ako **itemID (number)**, nie itemLink string. Opravené na `type(itemId) == "number"` a priame použitie
- **Threshold sa nezobrazoval** – `if thresh > 0 then` skrýval hodnotu 0. Teraz vždy zobrazí aktuálnu hodnotu
- **Hodnoty sa neukladali bez Enter** – pridaný `OnEditFocusLost` do `CreateAlertEditRow`; `SaveSettings()` teraz číta aj `itemTrackingEnabled`, `itemTrackingInterval`, `itemTrackingThreshold`
- **Positioning** – interval/threshold label-y zarovnané na divider_left + 10

### Changed
- Odstránený mŕtvy `DetaurBar.UI.alertSubTabNames` z `DetaurBar_UI.lua` (bol neaktuálny, nikdy nepoužitý)

---

### Added
- **Buffs sub-tab** v Alerts: 4 cooldown sloty (drag-from-spellbook), Maelstrom Weapon stack tracking, Follow Stacks checkbox
- Center-screen alert pool: 6 framov, horizontálne, 1s + 0.5s fade
- `GetSpellCooldown(bookIndex, bookType)` — funguje v 3.3.5a rovnako ako `GetSpellInfo`

### Fixed
- **Cooldown alert sa nezobrazoval**: `prevCooldownState` bol kľúčovaný spell ID, ale `data.id` bol book index (nie spell ID). Oprava: kľúčovať slot indexom `i` (1-4).
- **Falošné alerty po caste**: `GetSpellCooldown` vracalo GCD (1-1.5s) pre spelly bez vlastného cooldownu, čo spúšťalo alert po skončení GCD. Oprava: filter `duration > 1.5` ignoruje GCD.
- `LookupSpellInfo` odstránená — v 3.3.5a `GetSpellInfo(index, bookType)` nevracia spellID ako 10. hodnotu
- `FindSpellIdOnBars` odstránená — zbytočná závislosť na action baroch

### Changed
- **Stack tracking**: zjednodušený na Maelstrom Weapon (spell ID 53817) — alert pri 5 stackoch. Žiadne learning/peak cykly.
- **Nezávislé ovládanie**: `buffsEnabled` (Enable Cooldown Tracking) riadi iba cooldown sloty; `buffsFollowStacks` (Show maelstorm stack) riadi iba stack tracking
- **Divider** (rovnaký `UI-FriendsFrame-OnlineDivider` ako vo WG) medzi cooldown slotmi a stack checkboxom
- **Label "Cooldown Slots"**: zmenšený na `GameFontNormalSmall`, šedý (0.6, 0.6, 0.6)
- **"Follow Stacks"** → **"Show maelstorm stack"**
- **Center-screen alert ikony**: 34×34 (40% menšie), y=-200 (dolná polovica), bez textu
- **Názvy spellov odstránené** zo slotov aj z alertov — ostávajú len ikony

### Fixed
- Enable Cooldown Tracking checkbox teraz obnovuje stav z `DetaurBarDB.settings.buffsEnabled`
- Drag handler správne ukladá `bookIndex`/`bookType` z `GetCursorInfo()` pre spoľahlivé zobrazenie ikony

---

## 2026-07-03 — Flask icons fix

### Opravené: Ikonky flaskov v Price > Chart
- Flask of Endless Rage (46377), Pure Mojo (46378), Stoneblood (46379),
  Frost Wyrm (46376) mali nesprávne icon pathe `INV_Flask_1`–`INV_Flask_4`,
  ktoré v 3.3.5a neexistujú
- Opravené na `inv_alchemy_endlessflask_03`–`06` (overené z WotLK database)

## 2026-07-02 — Notes clipboard, delete button, loot fallback

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
