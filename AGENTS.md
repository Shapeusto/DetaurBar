# Project Context: WOTLK WoW Addon (Warmane Private Server)
You are a code assistant specialized in World of Warcraft addon development for the legacy Wrath of the Lich King client.

## Environment Details:
- Target Server: Warmane (Icecrown realm)
- Client Version: Patch 3.3.5a (Build 12340) - NOT retail, NOT Wrath Classic.

## Strict API Rules:
1. TOC files must use `## Interface: 30300`.
2. DO NOT use modern UI templates like `BackdropTemplate`. In patch 3.3.5a, backdrops/borders are native to frames.
3. DO NOT use modern namespaced APIs (e.g., NO `C_Timer`, NO `C_Container`, NO `C_QuestLog`).
4. For timing/delays, use standard frame `OnUpdate` handlers with elapsed time tracking (`arg1` or `elapsed`).
5. All UI components (Frames, Buttons) must be created using legacy `CreateFrame` arguments compatible with the 2010 API.
6. Use legacy chat printing: `print()` or `DEFAULT_CHAT_FRAME:AddMessage()`.
7. SavedVariables must be handled manually via `ADDON_LOADED` or `PLAYER_LOGIN` events, as modern lifecycle methods do not exist.

## What DOES NOT WORK and why — do not try these again
- `GetItemInfo("Item Name")` — returns nil if the item is not in session cache. **Do not use for bulk lookups.**
- `GetItemInfo(id)` — works, but triggers a server request; response arrives asynchronously via `GET_ITEM_INFO_RECEIVED`.
- Scraping evowow.com — HTTP 403, blocks bots. **Do not use.**
- Scraping wowhead.com — same restrictions.
- Manual item IDs from any website — unreliable without verification on Warmane.
- `DetaurBar.toc` — ignored by the WoW client, always write to `Detaurtodo.toc`.
- `GetItemIcon(itemId)` — does **not exist** in 3.3.5a. Do not use it.
- `SetRotation()` on textures — does not reliably render diagonal lines in 3.3.5a. Use dot-stepping instead (see DrawGfLine in DetaurBar_UI_Graph.lua).
- `GetNumAuctionItems("list")` — returns only 1 value in 3.3.5a (number on page), NOT 2 values. There is no totalCount.
- `GetAuctionItemInfo("list", i)` — does NOT return itemId as 15th value in 3.3.5a. Use `GetAuctionItemLink("list", i)` and extract ID from the link string instead.
- AH pagination — conflicts fatally with Auctioneer addon. Every query to page > 0 triggers Auctioneer which fires its own query and overwrites results. Scan page 0 only.
- `SetEnabled()` on EditBox — does not exist in 3.3.5a, use `Enable()` / `Disable()` on Button frames.
- `OnDragStop` script on a plain Frame — does not fire in 3.3.5a.
- `SetNumeric(true)` on EditBox when you want text input — blocks typing; use only for numeric fields.
- `TargetByName(name)` — does **not exist** in 3.3.5a. Use `RunMacroText("/target name")` or `SecureActionButtonTemplate` with `/target` macro instead.
- `RunMacroText()` — protected function; will taint from insecure contexts. Must be called from a secure execution path (hardware event or secure template PreClick/OnClick).
- `SetAttribute` on secure frames — protected function; will taint the entire secure frame tree if called from insecure context. Once tainted, ALL game interactions (quest, vendor, NPC) will fail with "Interaction action failed because of an Addon". **Never call SetAttribute outside PreClick or hardware-event handlers.**
- `SecureActionButtonTemplate` — using this template and calling `SetAttribute` from insecure code (PLAYER_LOGIN, OnUpdate, timers) taints the global secure frame tree. Always set type/macrotext attributes inside `PreClick` (which runs in the secure template's own secure context).
- `UseAction(slot)` — wrapping this C function from insecure Lua code taints the secure execution path, causing "blocked from an action only available to Blizzard UI". Do NOT wrap UseAction.
- `GetUnitSpeed("player")` — returns a **multiplier** (1.0 = normal run speed), NOT yards per second. Ground mounts: ~1.6–2.0, flying mounts: ~2.5–3.8. Do not compare against yds/s values.
- To target by name without taint: use `SecureActionButtonTemplate` with `PreClick` setting `"type1"` and `"macrotext1"` attributes, then `/target Name` macro executes securely. Do NOT use `RunMacroText()` from insecure code. Do NOT use `TargetUnit()` from insecure code.
- `GetCursorInfo()` — in 3.3.5a returns `"item", itemID, itemLink` where `itemID` is a **number**. Do NOT assume the second return is a string or call `.match()` on it.
- `CreateFontString()` — returns a FontString, NOT a Frame. FontStrings do NOT have `SetScript()`. Do NOT call `SetScript` or `SetSimpleTooltip` (which calls `SetScript`) on FontStrings.
- **Lua 5.1 upvalue limit (60)** — functions that reference many local variables from enclosing scopes hit "more than 60 upvalues" error. Fix: move references to a global table (e.g. `DetaurBar.UI.xxx`) instead of direct local references.
- `COMBAT_LOG_EVENT_UNFILTERED` in 3.3.5a — does NOT have `timestamp` or `hideCaster` parameters. The order is: `eventType(string), sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, [spellSchool]`. The Enemy module (`DetaurBar_UI_Enemy.lua:191`) uses the correct pattern.
- **Backdrop `insets` shrink the bgFile, not the frame** — when a frame has `SetBackdrop({ insets = { right = 3 } })`, the bgFile texture only fills the area 3px inside the frame's right edge. The frame's own positioning and hit-rect are unaffected. If you anchor another element relative to the frame's right edge, the visible dark area will be 3px narrower than the frame. Always adjust anchor offsets to compensate when the backdrop bgFile must visually cover a neighboring element (e.g., `listBackground` x-offset must be `24` instead of `20` to cover scrollbar when `insets.right = 3`).
- `GetWorldPVPAreaInfo(id)` — does **not exist** in 3.3.5a.
- `GetWorldStateValue(id)` — does **not exist** in 3.3.5a. World state system is not exposed via Lua API. Wintergrasp faction control cannot be queried programmatically.
- **Auctioneer replaces the AH UI** — `BrowseBuyoutButton` and other default AH frames are replaced by Auctioneer. `hooksecurefunc("BuyoutAuction")` fires but the browse list is cleared before the hook runs, so `GetAuctionItemLink("list", index)` returns nil. **Do not use AH hooks for buy detection. Use mailbox (`MAIL_INBOX_UPDATE`, `MAIL_CLOSED`) instead.**

## File Structure

| File | Purpose |
|------|---------|
| `Detaurtodo.toc` | Addon manifest (always edit this one, not DetaurBar.toc) |
| `DetaurBar_Core.lua` | Events, initialization, AH price scanning logic |
| `DetaurBar_UI.lua` | Main UI: frame, tabs, scroll, row pool, RefreshTasks, SelectTab, item helpers |
| `DetaurBar_UI_Todo.lua` | Todo sub-tabs (Day/Week/Month) + SelectTodoSubTab |
| `DetaurBar_UI_Notes.lua` | Notes sub-tabs (General/War/Guild) + drag-to-move + SelectNotesSubTab |
| `DetaurBar_UI_Loot.lua` | Loot sub-tabs (Add/Delete) + deleteAllGraysCheckbox + SelectLootSubTab |
| `DetaurBar_UI_Price.lua` | Price item sub-tabs (Chart/Bank/List/Recipes + News view toggle), graph panel, threshold row, AH interval, price sub-tabs, bank grid/scan, all price functions |
| `DetaurBar_UI_Recipes.lua` | Price > Recipes sub-tab: profession dropdown, recipe link input, reagent capture, expand/collapse recipe rows |
| `DetaurBar_UI_Settings.lua` | Alert panel (Dung/Raid/WG/Random/Enemy/Buffs/Item sub-tabs, flash alerts, flash frames) |
| `DetaurBar_UI_Buffs.lua` | Buffs tracking: cooldown expiry alerts, stacking buff change alerts, center-screen icon display |
| `DetaurBar_UI_Debuffs.lua` | Debuffs tracking: COMBAT_LOG_EVENT_UNFILTERED hook, center-screen icon pool (10 slots, y=200), stack counting, hostile-only filter |
| `DetaurBar_UI_Enemy.lua` | Enemy detection engine, draggable monitor window, smooth/aggressive flash alerts, right-click dismiss |
| `DetaurBar_UI_ArmorIcons.lua` | Armor-type icons on enemy player nameplates (class-color detection, all visible enemies, auto-enables ShowClassColorInNameplate CVar) |
| `DetaurBar_UI_Graph.lua` | Price graph drawing (DrawPriceGraph, ClearGraphObjects, DrawGfLine) |
| `DetaurBar_Data.lua` | SavedVariable helpers, 21,000+ item offline database, random alert CRUD functions |
| `DetaurBar_Minimap.lua` | Minimap button |
| `DetaurBar_Alerts.lua` | Screen flash, Wintergrasp timer, dungeon flash, random alerts |
| `DetaurBar_AHScan.lua` | Auction House price scanning |
| `DetaurIDFinder.lua` | Dev helper: `/detaurid scan` to find item IDs in-game |
| `parse_itemcache.py` | Generates ItemDatabase from WoW client cache files |

## Tab Structure

The addon has 4 main tabs: **Note**, **Loot**, **Price**, **Alert**

### Settings Menu (gear button panel)
- Gear button (settings icon) next to close (X) opens a **panel** inside the main frame (same as other tab panels)
- Panel has 4 sub-tabs: **Loot**, **Alert**, **Price**, **Various**
- **Settings > Loot**: 2 checkboxes (Add, Delete) — default both checked, unchecking hides the corresponding sub-tab from the Loot tab
- **Settings > Alert**: 9 checkboxes (Dung, Raid, WG, Arena, Random, Enemy, Buffs, Debuffs, Item) — default all checked, unchecking hides the corresponding sub-tab from the Settings/Alert tab
- **Settings > Price**: 4 checkboxes (Chart, List, Bank, Recipes) — default all checked, unchecking hides the corresponding sub-tab from the Price tab. Below them a divider (`UI-FriendsFrame-OnlineDivider`), then the **Scan auction house** checkbox (`DetaurBarDB.settings.ahScanningEnabled`)
- **Settings > Various**: 3 checkboxes (Autosell junk and autorepair, Show alerts in chat, Ignore Yell) — persistent v `DetaurBarDB.settings.*`. Below a divider (`UI-FriendsFrame-OnlineDivider`): **Show armor** checkbox (`showArmorEnabled`), then 4 armor-type rows (Mail/Plate/Cloth/Leather, each `armorShow<Type>` checkbox + clickable icon button opening the armor icon picker `armorIcons[type]`). When **Show armor** is on, armor icons are drawn above EVERY visible enemy player nameplate (no targeting needed, no separate mode checkbox)
- State stored in `DetaurBarDB.settings.lootSubTabsVisible`, `DetaurBarDB.settings.priceSubTabsVisible`, and `DetaurBarDB.settings.alertSubTabsVisible`
- Toggle via gear button; closes on tab switch

### Todo tab
- 3 sub-tabs: **Day**, **Week**, **Month**
- Only Day resets daily (3:00 AM)
- SavedVariable: `DetaurBarDB.todo.day / .week / .month`
- Category strings: `"todo_day"`, `"todo_week"`, `"todo_month"`

### Note tab
- 3 sub-tabs: **General**, **War**, **Guild**
- SavedVariable: `DetaurBarDB.notes.general / .war / .guild`
- Category strings: `"notes_general"`, `"notes_war"`, `"notes_guild"`
- Click row = copy text to chat; drag row to sub-tab = move between categories

### Loot tab
- SavedVariable: `DetaurBarDB.loot`
- Category string: `"loot"`
- Arrow button on each row = **copy** item to Price list (item stays in Loot)
- Shift-click row = link item to chat

### Price tab
- SavedVariable: `DetaurBarDB.price` (list of tracked items)
- SavedVariable: `DetaurBarDB.priceHistory[itemId][timestampStr] = copperPerItem`
- Category string: `"price"`
- **Four sub-tabs: Chart / Bank / List / Recipes** (News is no longer a sub-tab — see below)
- **Chart sub-tab** has TWO views toggled by the **News icon** in the toolbar (`DetaurBar.UI.newsViewToggle`, icon `INV_Jewelcrafting_Dragonseye03`, state `DetaurBar.UI.newsViewActive`):
  - **Chart view** (default): Full tracking with threshold management, order mode toggle. Split layout: scrollable item list, threshold row, time filters, graph panel (120px).
  - **News view** (toggle icon active): Auto-populated alert list (items below low threshold / above high threshold). **Clicking an item row jumps to the Chart view with that item's graph open** (sets `expandedPriceItemId`, switches `newsViewActive` off, forces `chartGraphVisible = true`, selects it in the threshold row, calls `SelectPriceItemSubTab("Chart")`); header rows are ignored.
    - Shows item icon, name, current price in gold; no graph, no time filters — clean compact list
    - Delete (X) removes from Low price AND clears threshold
    - At the bottom: **Scan AH button + AH Scan Interval** row (`DetaurBar.UI.priceAhIntervalRow`), exactly as the old News sub-tab layout.
  - The News view is only reached while the Chart sub-tab is active (`DetaurBar.UI.IsNewsView()` = `activePriceItemSubTab == "Chart" and newsViewActive`). All row rendering, filtering and layout branches keyed off `activePriceItemSubTab == "News"` were converted to `IsNewsView()`.
  - **Threshold row** (above time filters): selected item icon + name + 4-digit gold input + gold icon + OK (✓) / Clear (X)
  - Click item row = expand/collapse price graph + auto-selects item in threshold row
  - Items with thresholds show `[Xg]` next to name
  - Sub-tab bar: **Daily**, **Weekly**, **Monthly**, **Yearly**
  - Graph: dot-stepping lines, 3 X/Y axis labels
  - **Toolbar icons** (left side): News view toggle + Order mode toggle (Graph / Threshold / Buy-Sell toggles were removed)
- **List selector dropdown** (right side of toolbar, `DetaurBar.UI.chartListDropdown`): this is the **single list filter** — it filters the item list in Chart view AND selects which lists the AH scan includes AND what News view shows. Options: `All` (everything), `Default` (items without a list), or one specific list. Stored in `DetaurBarDB.settings.scanFilterList`; `activePriceListName` is synced to it when entering the Chart sub-tab. (The separate "AH scan filter" bar with its own dropdown + News Display Mode toggle was removed — News always respects this dropdown.)
- **Bank sub-tab**: Scans bags, personal bank, and guild bank for items with count ≥ threshold
  - Threshold input box (numeric) at top — changing threshold instantly refilters
  - 6×6 item grid (36 slots) with icons and counts, sorted by count descending
  - Auto-scan on login, bank open, guild bank open
  - Persistent cache (`DetaurBarDB.bankCache`) stores per-source counts (personal/bank/guildbank)
  - 3 source checkboxes (Personal, Bank, Guildbank) stacked vertically below the grid — filter which sources contribute to display. The main frame default/min height is 485 (not 430) so these fit below the 6x6 grid at 36px slots; do not shrink the grid back to 40px slots at 430 height or the checkboxes overflow the panel.
  - Horizontal divider between grid and checkboxes
  - Works with Bagnon addon
- **List sub-tab**: Create and manage custom item lists (dropdown selector + add/delete). Items added while a specific list is selected get tagged with `list = "ListName"` and only appear in that list (hidden from Default).
  - Delete button shows confirmation dialog (YES/NO) before removing a list
  - DB structure: `DetaurBarDB.priceLists = { ["Default"] = true, ["Gems"] = true, ... }`
- **Recipes sub-tab**: Track profession recipes with a captured material list.
  - **Profession dropdown** ("All" + the player's professions). **`GetProfessions()`/`GetProfessionInfo()` do NOT exist in 3.3.5a** — detect professions by iterating `GetNumSkillLines()` and matching `GetSkillLineInfo(i)` (returns `skillName, isHeader, ...`) against the 11 primary profession names plus Cooking/First Aid/Fishing (all open the TradeSkill window); skip header lines, stop at i > 14 (weapon skills follow).
  - **Recipe link input**: shift-click a recipe from the open profession book (TradeSkill window) into the input box and press Enter. The recipe is matched by name against the open profession window and its icon + reagents are captured at link time (`GetTradeSkillReagentInfo`); the book never needs to be open again.
    - 3.3.5a gotchas: `GetTradeSkillInfo(i)` returns `name, tradeType, numAvailable, isExpanded` — the 2nd return is `"header"`/`"rank"`, NOT a texture. **Collapsed subclass headers hide their recipes from `GetNumTradeSkills`/`GetTradeSkillInfo`**, and the "Have Materials" filter (`TradeSkillOnlyShowMakeable`) hides un-craftable recipes. Before scanning, expand all collapsed headers (`ExpandTradeSkillSubClass(i)`) and temporarily disable the Have Materials filter, then restore both after. Match recipes robustly by item ID via `GetTradeSkillItemLink(i)` (`item:(\d+)`) falling back to name match.
  - Click a recipe row = expand/collapse its reagents under the recipe name; delete (X) removes the recipe.
  - DB: `DetaurBarDB.recipes` (list of `{ id, name, profession, icon, itemId, reagents = { {name, icon, count, itemId} }, created }`), helpers `DetaurBar.Data.AddRecipe` / `DeleteRecipe`. `itemId` is the crafted item ID parsed from the recipe link; reagent `itemId` is resolved offline via `DetaurBar.UI.GetItemIdFromText`. Icons are resolved offline via `DetaurBar.Data.GetItemTexture(itemId)` (NOT `GetTradeSkillInfo` texture, which is wrong in 3.3.5a).
  - Expanding a recipe inserts one sub-row per reagent (indented icon + `countx name`); clicking a reagent row links it to chat; shift-click on a recipe row links the crafted item.
  - Recipe and reagent rows show a very small right-aligned threshold badge (`LOW xg` red / `HIGH xg` green) when the item is tracked in the Price list and has `threshold`/`thresholdHigh` set (`DetaurBar.UI.GetItemThresholdText(itemId)`).
- AH auto-scan: every N minutes when AH opened (page 0 only), configurable in Price > Chart (News view)

### Alert tab
- 9 sub-tabs: **Dung**, **Raid**, **WG**, **Arena**, **Random**, **Enemy**, **Buffs**, **Debuffs**, **Item** (visibility controlled by Settings Menu > Alert)
- SavedVariable: `DetaurBarDB.settings`
- **Dung sub-tab**: Enable screen flash on LFG proposal, flash duration, flash color (Green/Yellow/Red)
- **Arena sub-tab**: Enable screen flash on arena match start (`ARENA_OPPONENT_UPDATE`), flash duration, flash color (Green/Yellow/Red)
- **Raid sub-tab**: Raid roll/ready-check alerts with flash style, duration, color, sound
- **WG sub-tab**: Wintergrasp alerts, **Show time in enemy tracker** checkbox (displays WG countdown at top of enemy monitor), Registration Warning (minutes, flash duration, flash color, play sound, select sound), Battle Start Warning (minutes, flash duration, flash color, play sound, select sound)
- **Random sub-tab**: Enable random alerts, list of named alerts (each with interval, flash duration, flash color, play sound, select sound), Add/Delete buttons, click to select active alert
- **Enemy sub-tab**: Enable enemy detection, **Show cast** checkbox (monitor window shows cast/nearby activity), screen flash (enable/disable), flash color (Green/Yellow/Red), flash style (Smooth/Aggressive), play sound (enable/disable), select sound (Raid/Ready), **Alert Mind Control** checkbox (center-screen text when party/raid member gets Mind Controlled)
- **Buffs sub-tab**: Enable buff/cooldown tracking, 5×2 drag-from-spellbook cooldown slots (10 slots, icon + close X), Follow Stacks checkbox, center-screen icon display on cooldown expiry or stack change, "Dont hide unused" checkbox + timeout, 1×4 drag-from-bags item cooldown slots (potion/flask/elixir)
- **Debuffs sub-tab**: Enable enemy debuff tracking, Show Everything checkbox (unchecked = only current target), 5×5 drag-from-spellbook grid (25 slots), center-screen icon pool (10 frames, DIALOG strata, y=200), stack counting, hostile-only filter via COMBAT_LOG_EVENT_UNFILTERED
- **Item sub-tab**: Enable item tracking, 5×5 drag-from-bags grid (25 item slots), alert interval (minutes), alert threshold (count), periodic bag scan via OnUpdate timer, chat alert when count ≤ threshold

### Enemy tab
- Detects hostile players via COMBAT_LOG_EVENT_UNFILTERED, PLAYER_TARGET_CHANGED, UPDATE_MOUSEOVER_UNIT
- Automatically disabled in instances
- Draggable monitor window (right-click minimap button to toggle)
- Resizable width (200–500px) via bottom-right grip
- Ornate UI-DialogBox-Border frame with dark warm brown backdrop
- Each row shows: enemy name (red, 4-char class abbrev, activity)
- Left-click row = targets the enemy via SecureActionButtonTemplate macro
- Right-click row = dismisses enemy from the list (session-only)
- Eye icon toggle (center-right of monitor) synced bidirectionally with Alert > Enemy > Enable checkbox
- WG countdown shown at the top when Alert > WG > Show time in enemy tracker is enabled (gold text, updates every 1s)
- Enemies fade after 120s of inactivity
- Max 10 enemies shown
- **Aggressive flash**: fullscreen pulsing (pulsating 0.18–1.0 alpha over 2.6s)
- **Smooth flash**: 48px border bars at edges, visible→fade over 1.5s
- 60s throttle between re-alerts for the same enemy

## SavedVariable Structure

```lua
DetaurBarDB = {
    todo = { day = {}, week = {}, month = {} },
    notes = { general = {}, war = {}, guild = {} },
    loot = {},
    sell = {},          -- legacy, may still have data
    bankCache = { [itemId] = { personal = count, bank = count, guildbank = count } },   -- Price > Bank scan cache (per-source counts)
    price = {},         -- list of tracked items (same format as buy)
    priceHistory = {
        [itemId] = {
            ["1749916409"] = 329000,   -- unix timestamp string = copper per item
        }
    },
    minimapAngle = 45,
    framePosition = { point, relativePoint, xOfs, yOfs },
    lastResetDay = number,
    settings = {
        chartGraphVisible = true,
        chartThresholdVisible = true,
        chartOrderMode = false,
        dungeonFlashEnabled = false,
        dungeonFlashColor = "YELLOW",
        dungeonFlashDuration = 0,
        ahScanInterval = 10,
        scanFilterList = "All",  -- "All" | "Default" | "<list name>" — single list filter (Chart toolbar dropdown): filters the Chart list AND selects the AH scan lists AND what News view shows
        newsViewActive = false,  -- runtime only (not persisted): Chart sub-tab shows News view when true
        lootSubTabsVisible = { Add = true, Delete = true },
        priceSubTabsVisible = { Chart = true, Bank = true, List = true, Recipes = true },
        alertSubTabsVisible = { Dung = true, Raid = true, WG = true, Arena = true, Random = true, Enemy = true, Buffs = true, Debuffs = true, Item = true },
        wgAlertsEnabled = true,
        wgShowTimeOnEnemyTracker = false,
        wgAlert1Minutes = 15,
        wgAlert1Duration = 2,
        wgAlert1Color = "YELLOW",
        wgAlert1PlaySound = true,
        wgAlert1Sound = "RaidWarning",
        wgAlert2Minutes = 1,
        wgAlert2Duration = 0,
        wgAlert2Color = "YELLOW",
        wgAlert2PlaySound = true,
        wgAlert2Sound = "RaidWarning",
        wgCycleOffset = nil,
        randomAlertsEnabled = false,
        randomAlerts = {
            { id = "ts_1234", name = "My Alert", intervalMinutes = 5, flashDuration = 3, flashColor = "YELLOW", playSound = false, sound = "RaidWarning" }
        },
        randomActiveAlertId = nil,
        enemyEnabled = false,
        enemyShowCast = true,
        enemyFlashEnabled = false,
        enemyFlashColor = "YELLOW",
        enemyFlashStyle = "AGGRESSIVE",
        enemyPlaySound = false,
        enemySound = "RaidWarning",
        mindControlAlertEnabled = false,
        autoSellRepairEnabled = false,
        showAlertsInChat = false,
        ignoreYellEnabled = false,
        buffsEnabled = false,
        buffsSpellSlots = {},  -- each slot: { id = spellId, name = "Earth Shock", icon = "Interface\\Icons\\Spell_Nature_EarthShock" }
        buffsFollowStacks = false,
        buffsDontHideUnused = false,
        buffsHideTimeout = 1,
        buffsItemCooldownSlots = {},   -- indexed 1..4: { itemId, name, icon }
        itemTrackingEnabled = false,
        itemTrackingSlots = {},   -- indexed 1..25: { itemId, name, icon }
        itemTrackingInterval = 30, -- minutes
        itemTrackingThreshold = 0, -- count
        debuffsEnabled = false,
        debuffsShowEverything = true,
        debuffsSlots = {},   -- indexed 1..25: { spellId, name, icon }
    },
}
```

Each item in a list is:
```lua
{ id = "timestamp_random", title = "item:36908", completed = false, created = timestamp, threshold = 0, frequent = false }
```
- Price tab items: `threshold` = gold amount for low-price alert, `frequent` = shown in Low price tab

## AH Price Scanning (DetaurBar_Core.lua)

- Triggered by `AUCTION_HOUSE_SHOW`, starts after 2s delay
- Throttled to once per 10 minutes (`SCAN_INTERVAL = 600`)
- Scans **page 0 only** — pagination conflicts with Auctioneer addon
- Waits for `CanSendAuctionQuery()` and checks `AucAdvanced.Scan.IsScanning()`
- On `AUCTION_ITEM_LIST_UPDATE`: filters results by item ID using `GetAuctionItemLink`, saves lowest buyout per item
- On scan: checks thresholds — if price ≤ threshold, sets `frequent = true` (auto-adds to Low price); if price > threshold, clears `frequent`
- Ignores 0-result events (Auctioneer interference)
- Shows progress bar anchored below AH frame during scan
- After scan: calls `DetaurBar.UI.RefreshTasks()` to update graph
- List filtering: only items matching `DetaurBarDB.settings.scanFilterList` are scanned — `"All"` scans everything, `"Default"` scans only items without a list, a list name scans only items in that list.

## Price Graph (DetaurBar_UI_Graph.lua)

- Drawn with `Texture` objects (no canvas available in 3.3.5a)
- Lines drawn as dot-stepping (pixel-by-pixel) — `SetRotation` doesn't work
- Graph textures/labels stored in `row.graphTextures` / `row.graphLabels` tables
- For the Price tab, uses `DetaurBar.UI.priceGraphHolder` + `DetaurBar.UI.priceGraphPanel`
- `ClearGraphObjects(holder)` hides all textures/labels before redraw
- X axis: 3 evenly spaced labels across the time range (not tied to data points)
- Y axis: 3 labels (min, mid, max price)
- Daily sub-tab: filters last 24h, X labels show `HH:MM`
- Weekly/Monthly/Yearly: filter last 7/30/365 days, X labels show `DD/MM`

## Item Data Flow

1. User types name or drags item → saved as `"item:ID"` or raw name
2. `RefreshTasks()` calls `GetOfflineItemNameById(id)` → offline DB lookup
3. If not in offline DB, calls `GetItemInfo(id)` → async server request
4. Icon: `DetaurBar.Data.ItemIcons[id]` → `GetItemInfo` texture → nil (no icon shown)
5. Tooltip: `GameTooltip:SetHyperlink(serverLink)` if cached, offline fallback otherwise
6. Shift-click: `HandleModifiedItemClick(itemLink)` → links to chat

## Item Database — how to update

```
python parse_itemcache.py
```

Reads `Cache/WDB/enUS/itemcache.wdb` and `Cache/WDB/enUS/itemnamecache.wdb`.
**Never edit ItemDatabase manually** — generated by the script.

## CRITICAL: "Official" vs. Warmane item IDs

| Source | Status |
|--------|--------|
| wotlk.evowow.com | ❌ IDs differ from Warmane |
| wowhead.com/wotlk/ | ❌ Same problem |
| `GetItemInfo(id)` in-game on Warmane | ✅ Only correct source |
| `Cache/WDB/enUS/itemcache.wdb` | ✅ Only correct source (offline) |

Verify IDs in-game: `/run local n,l = GetItemInfo(ID); print(n, l)`

## TOC File Rule
**Always edit `Detaurtodo.toc`**, never `DetaurBar.toc`.

## Sub-tab visual style (reuse this pattern)
All sub-tabs (Todo/Notes/Price) use the same visual pattern:
```lua
subTab:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left=3, right=3, top=3, bottom=3 }
})
-- Active:
subTab:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
subTab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
-- Inactive:
subTab:SetBackdropColor(0, 0, 0, 0.55)
subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
```

## Adding a new tab
1. Add name to `tabNames` in `DetaurBar_UI.lua`
2. Add category to `GetItems()` in `DetaurBar_Data.lua`
3. Add DB init in `InitializeDB()` in `DetaurBar_Data.lua`
4. Add row rendering branch in `RefreshTasks()` in `DetaurBar_UI.lua`
5. Add placeholder text in `DetaurBar.UI.UpdateInputPlaceholder()`
6. Add category handling in `AddNewItem()` and `OnReceiveDragHandler()`

## Adding a new sub-tab family
1. Create a `DetaurBar_UI_TabName.lua` file following the pattern of existing tab files
2. Initialize sub-tab arrays on `DetaurBar.UI` (e.g. `DetaurBar.UI.mySubTabs = {}`)
3. Add to `Detaurtodo.toc` after `DetaurBar_UI.lua`
4. Reference `DetaurBar.UI.frame` (set by main UI file) as the parent frame
5. Store sub-tab creation + visual update + select functions on `DetaurBar.UI`

## Git rules
- Never add `Co-Authored-By: Claude` to commit messages
- Never push automatically — only when user explicitly asks
- Never commit automatically — only when user explicitly asks
- Do NOT touch git at all (no add, no commit, no push) unless user gives an explicit command to do so
