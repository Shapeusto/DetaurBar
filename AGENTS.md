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
- To target by name without taint: use `SecureActionButtonTemplate` with `PreClick` setting `"type1"` and `"macrotext1"` attributes, then `/target Name` macro executes securely. Do NOT use `RunMacroText()` from insecure code. Do NOT use `TargetUnit()` from insecure code.

## File Structure

| File | Purpose |
|------|---------|
| `Detaurtodo.toc` | Addon manifest (always edit this one, not DetaurBar.toc) |
| `DetaurBar_Core.lua` | Events, initialization, AH price scanning logic |
| `DetaurBar_UI.lua` | Main UI: frame, tabs, scroll, row pool, RefreshTasks, SelectTab, item helpers |
| `DetaurBar_UI_Todo.lua` | Todo sub-tabs (Day/Week/Month) + SelectTodoSubTab |
| `DetaurBar_UI_Notes.lua` | Notes sub-tabs (General/War/Guild) + drag-to-move + SelectNotesSubTab |
| `DetaurBar_UI_Loot.lua` | Loot sub-tabs (Add/Delete) + deleteAllGraysCheckbox + SelectLootSubTab |
| `DetaurBar_UI_Price.lua` | Price item sub-tabs, graph panel, threshold row, AH interval, price sub-tabs, all price functions |
| `DetaurBar_UI_Settings.lua` | Alert panel (Dung/Raid/WG/Random/Enemy/Buffs sub-tabs, flash alerts, flash frames) |
| `DetaurBar_UI_Buffs.lua` | Buffs tracking: cooldown expiry alerts, stacking buff change alerts, center-screen icon display |
| `DetaurBar_UI_Enemy.lua` | Enemy detection engine, draggable monitor window, smooth/aggressive flash alerts, right-click dismiss |
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
- Panel has 3 sub-tabs: **Loot**, **Alert**, **Various**
- **Settings > Loot**: 2 checkboxes (Add, Delete) — default both checked, unchecking hides the corresponding sub-tab from the Loot tab
- **Settings > Alert**: 6 checkboxes (Dung, Raid, WG, Random, Enemy, Buffs) — default all checked, unchecking hides the corresponding sub-tab from the Settings/Alert tab
- **Settings > Various**: 3 checkboxes (Alert Mind Control, Autosell junk and autorepair, Dismount on action) — persistent v `DetaurBarDB.settings.*`
- State stored in `DetaurBarDB.settings.lootSubTabsVisible` and `DetaurBarDB.settings.alertSubTabsVisible`
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
- **Two sub-tabs: Low price / All**
- **Low price sub-tab**: Auto-populated alert list (items below threshold)
  - Shows item icon, name, current price in gold
  - No graph, no time filters — clean compact list
  - Delete (X) removes from Low price AND clears threshold
- **All sub-tab**: Full tracking with threshold management
  - Split layout: scrollable item list, threshold row, time filters, graph panel (120px)
  - **Threshold row** (above time filters): selected item icon + name + 4-digit gold input + gold icon + OK (✓) / Clear (X)
  - Click item row = expand/collapse price graph + auto-selects item in threshold row
  - Items with thresholds show `[Xg]` next to name
  - Sub-tab bar: **Daily**, **Weekly**, **Monthly**, **Yearly**
  - Graph: dot-stepping lines, 3 X/Y axis labels
- AH auto-scan: every N minutes when AH opened (page 0 only), configurable in Price > Notifications

### Alert tab
- 6 sub-tabs: **Dung**, **Raid**, **WG**, **Random**, **Enemy**, **Buffs** (visibility controlled by Settings Menu > Alert)
- SavedVariable: `DetaurBarDB.settings`
- **Dung sub-tab**: Enable screen flash on LFG proposal, flash duration, flash color (Green/Yellow/Red)
- **Raid sub-tab**: Raid roll/ready-check alerts with flash style, duration, color, sound
- **WG sub-tab**: Wintergrasp alerts, Registration Warning (minutes, flash duration, flash color, play sound, select sound), Battle Start Warning (minutes, flash duration, flash color, play sound, select sound)
- **Random sub-tab**: Enable random alerts, list of named alerts (each with interval, flash duration, flash color, play sound, select sound), Add/Delete buttons, click to select active alert
- **Enemy sub-tab**: Enable enemy detection, screen flash (enable/disable), flash color (Green/Yellow/Red), flash style (Smooth/Aggressive), play sound (enable/disable), select sound (Raid/Ready)
- **Buffs sub-tab**: Enable buff/cooldown tracking, 4 drag-from-spellbook cooldown slots (icon + close X), Follow Stacks checkbox, center-screen icon display on cooldown expiry or stack change

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
        dungeonFlashEnabled = false,
        dungeonFlashColor = "YELLOW",
        dungeonFlashDuration = 0,
        ahScanInterval = 10,
        lootSubTabsVisible = { Add = true, Delete = true },
        alertSubTabsVisible = { Dung = true, Raid = true, WG = true, Random = true, Enemy = true, Buffs = true },
        wgAlertsEnabled = true,
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
        enemyFlashEnabled = false,
        enemyFlashColor = "YELLOW",
        enemyFlashStyle = "AGGRESSIVE",
        enemyPlaySound = false,
        enemySound = "RaidWarning",
        mindControlAlertEnabled = false,
        autoSellRepairEnabled = false,
        dismountOnActionEnabled = false,
        buffsEnabled = false,
        buffsSpellSlots = { nil, nil, nil, nil },  -- each slot: { id = spellId, name = "Earth Shock", icon = "Interface\\Icons\\Spell_Nature_EarthShock" }
        buffsFollowStacks = false,
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
