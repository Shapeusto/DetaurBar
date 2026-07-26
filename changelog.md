# Changelog

## 2026-07-26 — Scrollbar overhang fix (listBackground backdrop inset), Chart toolbar

### Added
- **Price > Chart toolbar**: three toggle icon buttons (Graph, Threshold, Order mode) below the price sub-tab bar, visible only in Chart sub-tab
- **Graph toggle** (book icon): show/hide the price history graph section and time-filter sub-tab bar
- **Threshold toggle** (coin icon): show/hide the price threshold row
- **Order mode toggle** (arrow icon): switch between threshold mode and reorder mode (up/down arrows) within Chart sub-tab, replicating Order sub-tab functionality
- Visual ON/OFF state on toggle buttons (gold border = ON, dark border = OFF)
- Toolbar hidden when settings panel is open or non-Price tab is active
- Settings: `chartGraphVisible`, `chartThresholdVisible`, `chartOrderMode` saved in `DetaurBarDB.settings`

### Changed
- Chart sub-tab rows respect `chartOrderMode`: up/down arrows replace delete button when order mode is active
- `swapBtn`/`downBtn` click handlers and tooltips work in Chart sub-tab when `chartOrderMode` is true

### Fixed
- **Chart toolbar icons**: icon textures changed from `SetAllPoints(btn)` (22×22) to `SetSize(16, 16)` centered — no longer protrude past button border
- **Chart toolbar order toggle**: replaced broken texture `INV_Misc_Arrow_01` (does not exist in 3.3.5a) with `UI-ScrollBar-ScrollUpButton-Up`

### Removed
- **Price > Order sub-tab**: fully removed — no longer needed since order mode is accessible via Chart toolbar toggle (order mode toggle button)
- Removed "Order" from `priceItemSubTabNames`, `priceKeys` (Settings > Price checkboxes), and `priceSubTabsVisible` defaults
- Removed all Order sub-tab dead code: `SelectPriceItemSubTab` Order branch, `UpdateContentAnchors` Order branch, `RefreshTasks` Order rendering block, row OnClick/swap/down btn Order conditions, placeholder text check

### Fixed
- **Chart toolbar**: replaced semi-transparent texture backdrop with proper frame backdrop (solid dark + border) so icons don't visually overlap with item list
- **Chart layout**: scroll frame now positioned below toolbar (TOPLEFT at -120 instead of -88) — no overlap with item rows
- **Chart layout**: `priceThresholdRow` re-anchored to frame bottom when graph is hidden, preventing gaps
- **Chart layout**: scroll frame bottom extends dynamically — when both graph and threshold are hidden, scroll fills full width below toolbar to near frame bottom
- **Scrollbar overhang when threshold toggle OFF**: `listBackground` backdrop uses `insets = { right = 3 }`, so the dark bgFile ends 3px before the frame's right edge. Anchor offset `20` only covered scrollbar to its midpoint. Changed `listBackground` BOTTOMRIGHT x-offset from `20` to `24` so the dark area extends 1px past the scrollbar's right edge, eliminating the visible overhang.

## 2026-07-26 — Bank scan fixes

### Fixed
- **Bank scan**: opening guild bank no longer clears bank counts (only sources being rescanned are cleared)
- **Bank scan**: opening bank no longer clears guild bank counts
- **Bank scan**: old combined-format migration now sets all per-source counts to 0 (next scan populates them correctly) instead of copying the old combined count to all sources
- Alert > Enemy: Alert Mind Control checkbox was outside the scroll area (contentHeight 300 → 340)

### Added
- Alert > Enemy: **Alert Mind Control** checkbox now has a tooltip explaining functionality

## 2026-07-25 — Price > Bank sub-tab

### Added
- **Price > Bank sub-tab**: scans bags, personal bank, and guild bank for items with count ≥ threshold
- **Persistent cache** (`DetaurBarDB.bankCache`): stores all found items and counts, survives reload
- **6×6 grid** (36 slots) showing item icons + count, sorted by count descending
- **Threshold input** (numeric EditBox) — items filtered by threshold on display; changing threshold instantly refilters (no data loss)
- **Auto-scan** on login (`PLAYER_LOGIN`), bank open (`BANKFRAME_OPENED`), guild bank open (`GUILDBANKFRAME_OPENED`)
- Guild bank scan works with **Bagnon** addon (no `GuildBankFrame` dependency)
- Settings > Price: **Bank** checkbox to show/hide the sub-tab
- **3 source checkboxes** (Personal, Bank, Guildbank) below the grid with horizontal divider — filter which sources contribute to display
- Per-source cache: counts stored separately per source (`DetaurBarDB.bankCache[itemId] = { personal, bank, guildbank }`)
- Old cache format auto-migrated on access

### Changed
- Cache stores all scanned items regardless of threshold; threshold applied only at display time via `BuildBankDisplayList()`
- Cache format changed from `{ [itemId] = count }` to `{ [itemId] = { personal, bank, guildbank } }`

### Fixed
- `ScanBankItems` now pre-clears ALL source counts (personal, bank, guildbank) before merging fresh scan data — only items actually found in the current scan retain their counts. Fixes stale data: "Personal" showing guild-bank-only items, "Bank" showing stale guild bank data, etc.

## 2026-07-13 — Debuffs "Show Everything", Enemy "Show cast", Price Order sub-tab

### Added
- **Price > Order sub-tab**: reorder tracked items with up/down arrow buttons
  - Up (↑) and down (↓) arrows on each row to move items in the list
  - No delete, no thresholds, no graph — clean reorder-only view
  - Order changes are shared with Chart (same data source)
  - Order is the third (last) sub-tab, after Chart
- **Settings > Price** sub-tab: 3 checkboxes (News, Chart, Order) — show/hide Price sub-tabs, same pattern as Settings > Loot
  - Price sub-tab widths adapt to visible count on tab switch (like Loot)
- **Alert > Debuffs > Show Everything** checkbox: unchecked = only show debuffs from current target (filters out irrelevant nearby units)
- **Alert > Enemy > Show cast** checkbox: unchecked = hide casting/activity text in the enemy monitor window

### Fixed
- Up/down arrow buttons: 21×21 (was 14×14), repositioned to rightmost edge of each row
- Order sub-tab no longer shows leftover UI elements (AH interval row, input box, add button)
- Layout anchoring for Order: separate `elseif` branch in `UpdateContentAnchors`
- Price sub-tab width uses `#visiblePrice` instead of hardcoded `/2`
- Swap button tooltip shows "Move Up" in Order mode instead of "Set Price Threshold"
- `DetaurBar.UI.UpdateTabAnchors()` now called in Price tab block (was only in Loot)
- `AddOrUpdateEnemy` checks `enemyShowCast` before storing activity — off = no activity saved
- `DetaurBar.Enemy.ClearActivities()` helper clears all stored activities when toggling Show cast off

## 2026-07-12 — Debuffs sub-tab (Alert > Debuffs), CLE parameter fix

### Added
- **Debuffs sub-tab** in Alert: 5×5 drag-from-spellbook grid (25 slots), Enable Debuffs Tracking checkbox
- **Center-screen icon pool** (10 frames, DIALOG strata, y=200) — shows icon when a tracked enemy debuff is applied, hides on removal
- **Stack counting** — multiple applications increment counter, icon hides only when all stacks are gone
- **Hostile-only filter** — only shows icons for spells cast by or on hostile units (bit.band with COMBATLOG_OBJECT_REACTION_HOSTILE)
- Settings > Alert: **Debuffs** checkbox to show/hide the sub-tab

### Fixed
- **COMBAT_LOG_EVENT_UNFILTERED parameter order** in `DetaurBar_Core.lua:120` — in patch 3.3.5a, CLE has NO `timestamp` or `hideCaster` parameters. The old destructuring had 2 extra variables that shifted all subsequent values (eventType → sourceGUID, sourceFlags → destName, spellId/spellName → nil). Fixed to match the working Enemy module pattern: `local eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool = ...`

## 2026-07-09 — Item cooldown tracking in Alert > Buffs

### Added
- **Buffs > Item Cooldowns** — 1×4 drag-from-bags slots for potions/flasks/elixirs below the timeout row. Uses `GetItemCooldown(itemId)` to track shared potion/category cooldowns. Shows center-screen alert when cooldown expires, with the same "Dont hide unused" and timeout behavior as spell cooldowns. Data stored in `DetaurBarDB.settings.buffsItemCooldownSlots`.

## 2026-07-09 — Buffs persistent timeout: OnUpdate not firing on hidden frame

### Fixed
- **Persistent alert timeout not working** (`DetaurBar_UI_Buffs.lua:61`) — `ShowAlert` called `f.animFrame:Hide()` before setting up the timeout OnUpdate. When `f.animFrame` was reused from a previous call (persistent branch), it stayed hidden, and WoW 3.3.5a does not fire `OnUpdate` on hidden frames. The timeout ticker never ran, so the icon stayed indefinitely. Non-persistent (normal fade) was unaffected because it creates a new Frame with `CreateFrame` (which defaults to shown). Fixed by adding `f.animFrame:Show()` before setting the new OnUpdate on the reused frame.

## 2026-07-09 — Lua 5.1 upvalue limit fix (>60 upvalues in UpdateAlertPanel)

### Fixed
- **"function has more than 60 upvalues" error** in `DetaurBar_UI_Settings.lua:1289` — Lua 5.1 limits upvalues per function to 60. `UpdateAlertPanel` reached 61 after adding `buffsDontHideCheckbox` and `buffsTimeoutEdit`. Fixed by:
  - Moving `SetButtonGroupValue` and `SetAlertControlsVisible` from local functions to `DetaurBar.UI.*` (global lookup, not upvalue)
  - Storing new buffs controls on `DetaurBar.UI.buffsDontHideCheckbox` / `DetaurBar.UI.buffsTimeoutEdit` instead of direct local references
  - Result: ~57 upvalues, safely under limit

## 2026-07-09 — Buffs: "Dont hide unused" with configurable timeout

### Added
- **Alert > Buffs: "Dont hide unused" checkbox** — when checked, center-screen alert icons for cooldown expiry and Maelstrom Weapon 5-stacks stay visible until the spell is used again (or MW stacks drop below 5).
- **"Timeout (minutes)" edit box** below the checkbox — sets how many minutes the icon stays visible even with "Dont hide unused" enabled. Default: 1 minute. Overrides the permanent display with a max lifetime.

## 2026-07-09 — Ignore Yell checkbox in Settings > Various

### Added
- **Settings > Various: "Ignore Yell" checkbox** — when checked, filters out all Yell messages (`CHAT_MSG_YELL`) from the chat frame using `ChatFrame_AddMessageEventFilter`. Toggleable in real-time without reload.

## 2026-07-09 — Enemy monitor 0→1 transition: hit-rect fix

### Fixed
- **Enemy row bottom half unclickable after 0→1 enemy transition** — when monitor went from 0 enemies to exactly 1, the frame height stayed the same (47px), so `OnSizeChanged` never fired and the re-entrant layout correction never ran. Fixed by:
  - **4-point anchoring**: rows now anchored by all 4 corners (`TOPLEFT/TOPRIGHT/BOTTOMLEFT/BOTTOMRIGHT`) instead of 2 corners + `SetHeight`, defining hit-rect explicitly.
  - **`updatingMonitor` guard**: prevents re-entrant calls to `UpdateMonitor` via `OnSizeChanged` → `SetHeight` → `OnSizeChanged` → `UpdateMonitor`, ensuring layout runs exactly once regardless of whether frame height changes.
  - **`SetHitRectInsets(0,0,0,0)`** to eliminate any hidden insets.

## 2026-07-09 — Enemy row click stability, PrintAlert fix, Dataanalysis price viewer

### Fixed
- **Enemy row click broken after dismiss all** — `ClearAllPoints` called after `Show()` caused rows to momentarily lose anchors. Row anchors changed from chained (row2 → row1's BOTTOM) to direct (each row → monitorFrame TOPLEFT). Added `Enable()` and `Show()` after all positioning. Unused rows are cleared + moved off-screen before `Hide()` to prevent stale layout on re-show.
- **Enemy PrintAlert fires on every alert** — moved from `AddOrUpdateEnemy` (first detection only) to `OnNewEnemy` (fires alongside every flash).
- **Dismissed enemies reappear on re-detection** — `dismissed[name]` is cleared when `AddOrUpdateEnemy` creates a new entry for a previously dismissed enemy.

### Removed
- **ALT+RightClick move to bank** — feature removed entirely (Settings > Various checkbox, `SetupAltClickHooks`, debug frame, `/altdebug`/`/altdebugshow`).

### Added
- **Dataanalysis/ folder** — standalone offline HTML/JS price history viewer.
  - Load `WTF/.../SavedVariables/Detaurtodo.lua` via File API
  - Canvas-based price chart with Daily/Weekly/Monthly/Yearly/All filters
  - Item name lookup from 21k+ offline database (`items.js` generated from `DetaurBar_ItemDB.lua`)
  - Tooltip hover on data points
  - See `Dataanalysis/README.md`

---

## 2026-07-09 — Buffs 5×2 grid, Arena sub-tab, sub-tab arrow leak fix

## 2026-07-08 — Item tracking (Alert > Item sub-tab), bugfixes

### Added
- **Item sub-tab** in Alert: 5×5 drag-from-bags grid (25 slots), Enable Item Tracking checkbox
- Divider, Alert interval (minutes, default 30) and Alert threshold (count, default 0) edit boxes
- **Item tracking timer** in `DetaurBar_Core.lua` – OnUpdate on eventFrame, checks item counts in bags every N minutes
- **Chat alert** when count ≤ threshold: `[DetaurBar] Low on <name>: <count> remaining`
- Settings > Alert checkbox to hide Item sub-tab (in settingsMenuPanel)

### Fixed
- **Settings file crash** – `DetaurBar.UI.SetSimpleTooltip()` called on a **FontString** (not Frame), which crashes in 3.3.5a. Entire `DetaurBar_UI_Settings.lua` failed to load → `SelectAlertSubTab` stayed nil → all sub-tab controls were visible at once
- **Drag into slot** – `GetCursorInfo()` in 3.3.5a returns second value as **itemID (number)**, not itemLink string. Fixed to `type(itemId) == "number"` and direct usage
- **Threshold not displaying** – `if thresh > 0 then` hid value 0. Now always shows the current value
- **Values not saving without Enter** – added `OnEditFocusLost` to `CreateAlertEditRow`; `SaveSettings()` now reads `itemTrackingEnabled`, `itemTrackingInterval`, `itemTrackingThreshold`
- **Positioning** – interval/threshold labels aligned at divider_left + 10
- **Price threshold row wrong/missing names** – `UpdateThresholdRow()` in `DetaurBar_UI_Price.lua` had two bugs: (1) no `GetItemInfo` fallback when offline DB had no name – showed raw `item.title` (e.g. `"item:20532"`) instead of the resolved name. Fixed by adding the same fallback chain as the chart list (offline DB → `GetItemInfo` → `GetItemTexture` → `item.title`).
- **Settings menu sub-tabs not resizing with window** – `CreateSettingsMenuPanel()` in `DetaurBar_UI.lua` calculated sub-tab widths once at creation from `frame:GetWidth()`, with no `OnSizeChanged` handler. Added `LayoutSettingsMenuSubTabs()` with `OnSizeChanged` on the sub-tab bar, matching the pattern used by price sub-tabs.
- **Alert sub-tabs now scrollable with arrows** – Converted `alertSubTabBar` from a plain Frame to a ScrollFrame with scroll child (matching the Notes sub-tab pattern). Added left/right arrow buttons, dynamic min-width based on text content + padding (`insets left/right = 4`, label `LEFT`/`RIGHT` with 8px offset, `CENTER` justify). No more squished text.

### Changed
- Removed dead `DetaurBar.UI.alertSubTabNames` from `DetaurBar_UI.lua` (was outdated, never used)

---

## 2026-07-08 — Buffs sub-tab: cooldown tracking, stack tracking, UI

### Added
- **Buffs sub-tab** in Alerts: 4 cooldown slots (drag-from-spellbook), Maelstrom Weapon stack tracking, Follow Stacks checkbox
- Center-screen alert pool: 6 frames, horizontal, 1s + 0.5s fade
- `GetSpellCooldown(bookIndex, bookType)` — works in 3.3.5a same as `GetSpellInfo`

### Fixed
- **Cooldown alert not showing**: `prevCooldownState` was keyed by spell ID, but `data.id` was book index (not spell ID). Fix: key by slot index `i` (1-4).
- **False alerts after casting**: `GetSpellCooldown` returned GCD (1-1.5s) for spells without their own cooldown, triggering alert after GCD expired. Fix: filter `duration > 1.5` ignores GCD.
- Removed `LookupSpellInfo` — in 3.3.5a `GetSpellInfo(index, bookType)` does not return spellID as 10th value
- Removed `FindSpellIdOnBars` — unnecessary dependency on action bars

### Changed
- **Stack tracking**: simplified to Maelstrom Weapon (spell ID 53817) — alert at 5 stacks. No learning/peak cycles.
- **Independent controls**: `buffsEnabled` (Enable Cooldown Tracking) controls only cooldown slots; `buffsFollowStacks` (Show maelstorm stack) controls only stack tracking
- **Divider** (same `UI-FriendsFrame-OnlineDivider` as in WG) between cooldown slots and stack checkbox
- **Label "Cooldown Slots"**: changed to `GameFontNormalSmall`, gray (0.6, 0.6, 0.6)
- **"Follow Stacks"** → **"Show maelstorm stack"**
- **Center-screen alert icons**: 34×34 (40% smaller), y=-200 (bottom half), no text
- **Spell names removed** from slots and alerts — only icons remain

### Fixed
- Enable Cooldown Tracking checkbox now restores state from `DetaurBarDB.settings.buffsEnabled`
- Drag handler correctly saves `bookIndex`/`bookType` from `GetCursorInfo()` for reliable icon display

---

## 2026-07-07

### Fixed: Dismount on action did not work from keybindings and caused taint

#### Problem 1: Syntax error – missing `end` in event handler
- `DetaurBar_Core.lua:131` – after the `MERCHANT_SHOW` block, a second `end` was missing to close the main `if...elseif` chain. Lua parser reported "unexpected symbol near ')'".

#### Problem 2: PreClick hook did not catch keybinding
- In 3.3.5a, keybinding calls `UseAction(slot)` directly in C code, bypassing `PreClick` on action buttons.
- A wrapper around `UseAction` worked but caused **taint** ("Detaurtodo has been blocked from an action only available to Blizzard UI").

#### Solution: SetOverrideBindingClick instead of UseAction wrapper
- Added `DetaurBar.Core.SetupOverrideBindings()` – for each action slot (ActionButton1-12, MultiBar*, PetActionButton1-10, StanceButton1-10, ExtraActionButton1) gets the binding key via `GetBindingKey()` and sets `SetOverrideBindingClick`, which redirects the keybind to `:Click()` on the corresponding button frame.
- `:Click()` triggers the secure `OnClick` handler, which calls `PreClick` – and there our `HookScript` hook calls `TryDismount()`.
- Registered `UPDATE_BINDINGS` event – refreshes overrides when keybindings change.

#### Resulting flow
- **Mouse**: click → PreClick (hook) → TryDismount() → OnClick → spell
- **Keyboard**: keybind → SetOverrideBindingClick → ActionButton:Click() → PreClick (hook) → TryDismount() → OnClick → spell
- No taint because `HookScript` and `SetOverrideBindingClick` are taint-safe APIs.

### Changed: Dismount on action – only on flying mount (no dismount for gear/equipset)

#### Problem
- Dismount on every action caused unnecessary dismounts when switching gear (equipment manager, `/equipset`).
- Detection via `GetActionInfo` / `GetAttribute` failed because equipment manager calls `UseEquipmentSet()` directly (bypasses action buttons).

#### Solution: Only dismount when on a flying mount
- Added `IsOnFlyingMount()` – flying mount detection:
  - `IsMounted()` + `IsFlyableArea()` (non-flyable zone = ground mount → never dismount)
  - `GetUnitSpeed("player") > 2.25` (speed multiplier; ground max ~2.0, flying min ~2.5)
  - Speed = 0 (standing still) in flyable zone → assume flying → dismount
- `TryDismount()` now checks `IsOnFlyingMount()` instead of `IsMounted()`
- Removed complex `GetActionSlot`, `IsEquippableId`, `MacroIsGearEquip` – no longer needed
- `HookActionButton` simplified back to direct `TryDismount()` call

#### Flow
- **Flying mount**: action → PreClick → `IsOnFlyingMount()` = true → `Dismount()`
- **Ground mount**: action → PreClick → `IsOnFlyingMount()` = false → no dismount (gear, macro, equipset, everything works)
- **No mount**: `IsMounted()` = false → no dismount (not needed)

### Added: Show alerts in chat (Settings > Various)
- New option "Show alerts in chat" in Settings > Various
- `DetaurBar.Core.PrintAlert(msg)` – helper that checks the setting and prints a blue message with `[DetaurBar]` prefix to chat
- Chat output added to all alerts:
  - **Dungeon Alert** – on LFG_PROPOSAL_SHOW
  - **Wintergrasp Alert** / **Wintergrasp Battle Start** – on WG alerts
  - **Random Alert: <name>** – on random alerts (prints alert name)
  - **Enemy Alert: <name>** – on first appearance in monitor window (reappears after fade and rediscovery)
  - **Mind Control Alert: <name>** – on Mind Control in party/raid
- Default off

### Fixed: Enemy chat alert only on first appearance in monitor; Buffs no chat
- **Enemy Alert** – moved from `OnNewEnemy` (called on every combat log event) to `AddOrUpdateEnemy()` – only prints when an enemy first appears in the monitor window. After fading (120s) and reappearing, it prints again.
- **Buff Alert** – removed chat output entirely (cooldown alert and Maelstrom Weapon stacks). Flash and center-screen icon remain.

### Added: Delete price data point (right-click on graph dot)
- Each dot in the graph has a hover frame (Button) with `RegisterForClicks("RightButtonUp")` and `OnClick` handler
- Right-clicking a dot shows a custom confirm frame with Yes/No buttons
- After confirmation, `DetaurBar.Data.DeletePricePoint(itemId, timestampStr)` deletes only that single data point
- `DetaurBar_Data.lua` – new function `DeletePricePoint`
- `DetaurBar_UI_Graph.lua` – `GfFrame` changed from `Frame` to `Button` (RegisterForClicks not available on Frame in 3.3.5a)
- Tooltip shows "Right-click to delete"

### Changed: SavedVariables → SavedVariablesPerCharacter
- `Detaurtodo.toc` – `## SavedVariables` → `## SavedVariablesPerCharacter`
- Data is per-character, not account-wide
- Migration: account-wide `Detaurtodo.lua` copied to `Account\MATUSY\Icecrown\Detaur\SavedVariables\`
- Other characters on MATUSY start with empty DetaurBarDB

### Added: Scan auction house checkbox (Settings > Various)
- New checkbox "Scan auction house" in Settings > Various
- `ahScanningEnabled = true` default
- When disabled, `AHScan.StartScan()` returns immediately – no scan starts
- `DetaurBar_Data.lua`, `DetaurBar_UI.lua`, `DetaurBar_AHScan.lua`

### Removed: Dismount on action (functionality is built-in in 3.3.5a)
- Removed `IsOnFlyingMount()`, `TryDismount()`, `HookActionButton()`, `HookActionButtons()`, `SetupOverrideBindings()`, `OverrideActionBinding()`
- Removed "Dismount on action" checkbox from Settings > Various
- Removed `dismountOnActionEnabled` from InitializeDB
- Removed `UPDATE_BINDINGS` event and handler
- All files: `DetaurBar_Core.lua`, `DetaurBar_Data.lua`, `DetaurBar_UI.lua`

---

## 2026-07-06

### Fixed: Northrend herb ID nightmare (finally correct)

#### Problem
Warmane (WotLK 3.3.5a private server) uses **different itemIDs for Northrend herbs** than the official Blizzard cache `itemcache.wdb`. Herbs are shifted – not systematically (not +N), but each has a different offset from the stock WotLK database.

#### Everything that failed

| Attempt | What happened |
|---------|---------------|
| **v1** (forward mapping) | V1 applied old→new ID mapping to all `item:ID` entries. Worked for those that had the correct original name. |
| **v2** | Ran the same mapping AGAIN. Stacking: 36903→36905→36906→36908→36902 – each subsequent run shifted IDs by another step. |
| **v3** | Same problem – stacking continued. Herbs chain-mutated into completely different ones. |
| **`_migratedHerbIdsFinal`** | Only fixed **link format** (`\|Hitem:ID\|h[Name]\|h`), not `item:ID` – because `item:ID` stores no name and cannot be cross-referenced with DB. This approach was correct but did not solve `item:ID` entries. |
| **`/detaurfixherbs` (original)** | **DEVASTATING**: set `DetaurBarDB.price = {}` instead of fixing IDs. Deleted all price entries. **REMOVED**. |
| **ItemDatabase manual fix** | Instead of generating DB from Warmane cache, IDs were guessed: `frost lotus=36902`, `fire leaf=36903`, `adder's tongue=36905`, `lichbloom=36906`, `icethorn=36908`. **NONE of these IDs are correct on Warmane!** |
| **DetaurIDFinder in-game** | Tool showed correct ID for Goldclover, but other herbs were not in session cache and `GetItemInfo` returned nil. Result: database remained incorrect. |

#### What Warmane cache showed (July 7, 2026)
After directly reading `Cache/WDB/enUS/itemcache.wdb`:

| ID | Warmane name | What old DB said |
|----|--------------|------------------|
| 36901 | Goldclover | Goldclover (✓) |
| 36902 | **NOT FOUND** (does not exist) | frost lotus (✗) |
| 36903 | **Adder's Tongue** | fire leaf (✗) |
| 36904 | Tiger Lily | Tiger Lily (✓) |
| 36905 | **Lichbloom** | adder's tongue (✗) |
| 36906 | **Icethorn** | lichbloom (✗) |
| 36907 | Talandra's Rose | Talandra's Rose (✓) |
| 36908 | **Frost Lotus** | icethorn (✗) |
| 39970 | **Fire Leaf** | missing from DB |

No ID 36902 exists on Warmane. Frost Lotus is at 36908, Fire Leaf at 39970.

#### Final solution
1. **ItemDatabase** (name→ID) fixed according to Warmane cache:
   - `frost lotus = 36908` (was 36902)
   - `adder's tongue = 36903` (was 36905)
   - `lichbloom = 36905` (was 36906)
   - `icethorn = 36906` (was 36908)
   - `fire leaf = 39970` (was 36903)
2. **ItemIcons** (ID→texture) fixed:
   - [36905] → Lichbloom (was AddersTongue)
   - [36906] → Icethorn (was Lichbloom)
   - [39970] → FireLeaf (was missing)
   - [36903] and [36905] removed from ItemIcons → left to be resolved via `GetItemInfo` (server provides actual icon path)
3. **Migration v4** (`_migratedHerbIdsV4`): fixes `item:ID` and link format on every reload using mapping:
   - `36902→36908, 36903→39970, 36905→36903, 36906→36905, 36908→36906`
4. **`/detaurfixherbs`** (new safe version): applies the same mapping immediately, deletes nothing, only changes IDs.
5. **`/detaurrecover` and `/detaurrestore`** restore data from disk (which was in old array format and inaccessible).

#### Lessons learned
- Never edit `ItemDatabase` manually – always generate from `itemcache.wdb` (parse_itemcache.py)
- With `item:ID` format, the original name cannot be determined – if ID is wrong, old→new ID must be mapped explicitly
- Warmane IDs DIFFER from stock WotLK – always verify from cache, not from websites
- `DetaurIDFinder` is reliable only if the item is in session cache (`GetItemInfo` returns data)
- Deleting price list in the name of migration is unacceptable – always remap IDs, never delete

### Fixed: Price list data was empty in memory but intact on disk
- **Cause**: code in `GetItems("price")` expected `DetaurBarDB.price["Horde"]` (faction key), but old data was stored as array `DetaurBarDB.price[1], [2], ...` (array format). After switching to faction format, no one wrote a migration for old data.
- **Consequence**: `GetItems("price")` returned `DetaurBarDB.price["Horde"]` which was empty `{}`, while actual entries existed at indices 1-13.
- **Fix**: migration in `InitializeDB()` + `/detaurrecover` (immediate in-memory fix without reload).

### Added
- `/detaurrecover` – rescues items stuck in old array format
- `/detaurrestore` – restores 18 missing entries from backup (July 1) with thresholds
- `_migratedHerbIdsV4` – herb ID migration in `InitializeDB()`
- Settings Menu (gear) > Various sub-tab with two checkboxes:
  - **Alert Mind Control**: when a party member gets Mind Control, shows red text "[Name] has Mind Control!" in center screen (fade after 4s). Detection via `COMBAT_LOG_EVENT_UNFILTERED` for spells containing "Mind Control" on players in party/raid.
  - **Autosell junk and autorepair**: on merchant open (`MERCHANT_SHOW`) automatically sells all grey items (quality=0) and repairs equipment (`RepairAllItems()`).
- Both settings persistent in `DetaurBarDB.settings.mindControlAlertEnabled` / `autoSellRepairEnabled`.
- Settings > Various: added **Dismount on action** checkbox — automatically dismounts (`Dismount()`) on `UNIT_SPELLCAST_SENT`, `ACTIONBAR_UPDATE_STATE` and `BAG_UPDATE` (to catch actions blocked by mount as well as bag items). Debounce 1s.
- Fixed `AutoSellAndRepair`: `RepairAllItems(true)` → `RepairAllItems()` (3.3.5a does not have guild bank parameter) + `CanMerchantRepair()` check.

### Changed
- Settings Menu checkboxes (Loot and Alert) use `GameFontNormal` instead of `GameFontNormalSmall` (larger text)
- Enemy monitor toggle icon: `INV_Misc_Eye_01` → `Spell_Nature_BloodLust`
- Minimap button icon: `INV_Misc_Note_01` → `Spell_Nature_BloodLust`

### Renamed (code — no functional impact)
- **Alert tab** code: all `settings*` prefixes renamed to `alert*` to avoid confusion with Settings Menu (gear button). Affects `DetaurBar.UI.*` API and local variables/functions in `DetaurBar_UI_Settings.lua`:
  - `settingsPanel/SubTabBar/SubTabs/ListBackground/ScrollFrame/ScrollChild/SaveButton` → `alert*`
  - `activeSettingsSubTab` → `activeAlertSubTab`
  - `UpdateSettingsSubTabBar/Visuals/Panel/Scroll` → `UpdateAlert*`
  - `SelectSettingsSubTab` → `SelectAlertSubTab`
  - `SetSettingsControlsVisible/SubTabStyle` → `SetAlert*`
  - All control group variables (`settingsDungeonControls`, `settingsRaidRollColorButtons`, etc.) → `alert*`
  - Factory functions (`CreateSettingsLabel/Check/ChoiceRow/EditRow/EditBox`) → `CreateAlert*`
- **Settings Menu** (gear) names (`settingsMenu*`, `settingsBtn`, `smSettings*`) remained unchanged.

### Merged
- Merged Todo and Notes tabs into a single "Note" tab
- New data structure `DetaurBarDB.tasks` (old `todo` / `notes` are ignored)
- Daily reset at 3:00 unchecks all items in all categories

### Added
- Checkbox for each item (completed/unchecked) in Todo
- User-defined categories (Add/Delete category, scroll arrows)
- Click-to-copy: clicking a row copies text, 1 second for Ctrl+C
- Drag-to-move: dragging a row to another category
- New **Settings Menu** panel (gear button) — instead of opening Alert tab
  - Two sub-tabs: Loot (Add/Delete checkboxes) and Alert (Dung/Raid/WG/Random/Enemy checkboxes)
  - Persistent settings in `DetaurBarDB.settings.lootSubTabsVisible` / `alertSubTabsVisible`
- Dynamic hiding/showing of Loot and Alert sub-tabs based on Settings Menu checkboxes
- General category protection (cannot be deleted — `DeleteTaskCategory` + UI)

### Changed
- Tab button "Notes" → "Note"
- Tab button "Settings" → "Alert"
- Sub-tab "Dungeon" → "Dung" in Alert tab
- Resize grip: uses `RegisterForDrag` instead of `OnMouseDown`/`OnMouseUp`
- `DetaurBar_UI_Todo.lua` removed from TOC
- Tooltip for copy-to-chat shortened, copyBtn icon removed from task rows
- Gear button opens Settings Menu panel (inline in main frame) instead of Alert tab
- Settings Menu panel: container without its own backdrop, dark box is a separate frame 28px below sub-tabs (visually identical to Loot tab)
- Closing Settings Menu (gear button / tab switch) returns view to Notes > General
- Gear button does not leave a focused tab — all 4 main tabs remain in normal state

### Fixed
- **`listBackground` overlap (RECURRING BUG)**: when switching to Settings tab (Alert) or opening Settings Menu (gear), `listBackground` (dark list box) remained visible and overlapped with `settingsListBackground`. Manifested as duplicate borders/double lines.
  - Cause 1: `UpdateContentAnchors()` was missing `listBackground:Hide()` in the `activeTab == "Settings"` branch
  - Cause 2: `UpdateContentAnchors()` is defined before the local declaration of `listBackground` (Lua 5.1 scope — local variable is not visible before its declaration), so bare `listBackground` evaluated as global → nil, and `if listBackground then` never passed. Fix: use `DetaurBar.UI.listBackground` (always accessible via global namespace)
  - **Same problem** applies to `editBox` and `addButton` — all three local variables are declared after `UpdateContentAnchors`, so always use `DetaurBar.UI.*` version inside it
- Checkboxes in Settings Menu save changes to DB immediately (not only after reload)
- `ToggleVisibility` (minimap button / slash command) always shows Notes > General
- `ToggleSettingsMenu`: added `SetTabButtonsActive` for correct tab focus
- `tabs` and `activeTab` scope: functions `SetTabButtonsActive` and `ToggleSettingsMenu` moved after local variable declarations

### Removed
- Copy button (icon) from task rows — unnecessary since copy works by clicking the entire row

---

## 2026-07-03 — Flask icons fix

### Fixed: Flask icons in Price > Chart
- Flask of Endless Rage (46377), Pure Mojo (46378), Stoneblood (46379),
  Frost Wyrm (46376) had incorrect icon paths `INV_Flask_1`–`INV_Flask_4`,
  which do not exist in 3.3.5a
- Fixed to `inv_alchemy_endlessflask_03`–`06` (verified from WotLK database)

## 2026-07-02 — Notes clipboard, delete button, loot fallback

### Fixed: Loot items without name showed "Loading Item [ID: ...]"
- When item was not in offline DB and GetItemInfo returned nil, it showed
  "Loading Item [ID: 9276]..." instead of the saved text
- Fix: shows `item.title` (e.g. "9276" or "item:9276")
- GetItemInfo is still called for server request; when data arrives
  (GET_ITEM_INFO_RECEIVED), RefreshTasks is called and shows the item name

### Added: Delete button on Notes rows
- Notes rows now show delete (X) button — `row.deleteBtn:Show()`
- Previously the button was hidden for all notes categories

### Changed: Click on note copies text to clipboard
- Instead of `ChatFrame_OpenChat()` (opened chat) uses a hidden `EditBox`
  with `InputBoxTemplate`, positioned off-screen
- After click: text is set, selected (highlighted) and the edit box gets focus
- Player presses Ctrl+C and can paste anywhere
- Same behavior for row click and copy (📋) button
- Focus is automatically cleared after 1 second, on Escape, or clicking elsewhere
- OnKeyDown handler for Escape: `ClearFocus()`; OnUpdate timeout 1s

## 2026-07-01 — Icon cache, gem icon fixes, AH pagination

### Fixed: Missing/incorrect gem icons
- Most `DetaurBar.Data.ItemIcons` for WotLK gems (rare and epic) had
  incorrect icon paths — used specific names (`Bloodstone_01`,
  `TwilightOpal_01`, etc.) which don't exist in 3.3.5a client. Real icons
  on Warmane are `INV_Jewelcrafting_Gem_XX` (XX = 04–36).
- Fixed entries: 36917, 36918, 36919, 36922, 36923, 36925, 36927, 36928,
  36929, 36931, 36932, 36934. Verified in-game via `/detaurid icon <id>`.
- Two entries (36921 Autumn's Glow, 36930 Monarch Topaz) were not in session
  cache — left with old paths until verified.

### Added: Automatic icon cache
- `DetaurBar.Data.GetItemTexture(itemId)` in `DetaurBar_Data.lua`
- Checks: `ItemIcons` → `DetaurBarDB.iconCache` → `GetItemInfo`
- If `GetItemInfo` returns a texture, saves it to `DetaurBarDB.iconCache`
- On next reload, icon is immediately available
- In UI, replaces inline `ItemIcons[itemId]` + `GetItemInfo` with
  `GetItemTexture` (Price tab, Loot tab)

### Fixed: AH scan did not find items on later pages
- Problem: `QueryAuctionItems` sent the `page` parameter at the wrong position
  (4th instead of 7th). Effect: never queried page > 0, only
  repeatedly called page 0 with different invTypeIndex filter.
- Fix: correct signature `QueryAuctionItems(name, minLvl, maxLvl,
  invType, class, subclass, page, usable, quality, getAll)` — `page` is
  7th parameter.
- Added pagination: if item was not found on page 0 and results are 50+
  (full page), tries page 1, 2, ... up to MAX_PAGES (10).
- Exclusively `OnUpdate` driver calls `QueryAuctionItems` (guards:
  `CanSendAuctionQuery()`, `AucAdvanced.Scan.IsScanning()`).
- `OnResults` only reads results and sets state flags
  (`scanNeedsNextPage`, `scanItemComplete`).
- For 3.3.5a: `GetNumAuctionItems("list")` returns only 1 value
  (numOnPage), totalAuctions is not available.
