# DetaurBar

![Showcase](preview.gif)

In-game organizer addon for **World of Warcraft: Wrath of the Lich King (Patch 3.3.5a)** — designed for Warmane (Icecrown).

## Features

### Note
- User-defined categories (Add / Delete, scroll arrows for many categories)
- Checkbox toggles completed state (greyed out when done)
- Click anywhere on a task to copy its text (1 second to press Ctrl+C)
- Drag task between categories to reorganize
- Daily reset at 3:00 AM unchecks all completed tasks
- Delete (X) removes task

### Loot
- **Add** sub-tab: whitelist items you want to track (icons, rarity colors, tooltips with sell price)
- **Delete** sub-tab: auto-delete list for gray items
- **Delete all grays** checkbox in Delete sub-tab
- Arrow button copies item to Price list (item stays in Loot)
- Shift-click to link item to chat
- Drag & drop items from bags, AH, or profession windows
- Offline item name and icon lookup from 21,000+ database

### Price
- **Notifications** sub-tab — Auto-populated alert list:
  - **Low price** section: items where AH price ≤ your set threshold
  - **High price** section: items where AH price ≥ your set high threshold
  - Shows item icon, name, and current price in gold
  - No graph, no time filters — clean compact list
  - Remove (X) clears threshold and removes from list
- **Chart** sub-tab — Full item tracking with threshold management:
  - Click any item row to expand/collapse its price history graph
  - **Threshold row** above time filters:
    - Selected item icon + name (truncated)
    - Low threshold input (gold) + gold icon
    - High threshold input (silver) + silver icon
    - OK (✓) button to save, Clear (X) button to remove thresholds
  - Items with thresholds show `[Xg]` in gold (low) and orange (high) next to name
  - Graph with **Daily / Weekly / Monthly / Yearly** views
  - Configurable AH auto-scan interval in Price > Notifications
- Automatic AH scan when AH is opened (page 0 only, Auctioneer-compatible)
- Progress bar during AH scan
- Filters by exact item ID

### Enemy Detection
- Detects hostile players via combat events, mouseover, and target scanning
- **Draggable monitor window** with ornate WoW dialog frame (toggle via right-click minimap icon)
- Eye icon toggle on monitor (center-right) — synced with Alert > Enemy > Enable checkbox
- Resizable width (200–500px) with bottom-right grip
- Each row shows: enemy name (red), level + 4-char class abbrev, current activity
- **Left-click** row → targets the enemy
- **Right-click** row → dismisses enemy from list (session-only)
- Enemies auto-fade after 120s of inactivity
- Automatically disabled in instances

### Alert
- **Dung** — Screen flash on LFG proposal: enable/disable, flash color (Green/Yellow/Red), flash duration
- **Arena** — Screen flash on arena match start (`ARENA_OPPONENT_UPDATE`): enable/disable, flash color (Green/Yellow/Red), flash duration
- **Raid** — Raid roll / ready-check alerts with flash style, duration, color, sound
- **WG** — Two configurable alerts:
  - **Registration Warning**: minutes before, flash duration, flash color, play sound, sound selection
  - **Battle Start**: minutes before, flash duration, flash color, play sound, sound selection
- **Random** — Multiple named timer alerts:
  - Per-alert: interval, flash duration, flash color, play sound, sound selection
  - Add / Delete buttons to manage alerts
  - Click to select which alert is active
- **Enemy** — Enemy detection configuration:
  - Enable/disable detection
  - Screen flash on new enemy (on/off)
  - Flash color (Green/Yellow/Red)
  - Flash style (Smooth = border fade / Aggressive = fullscreen pulse)
  - Play sound (on/off) + sound picker (Raid/Ready)
  - **Alert Mind Control**: center-screen red text when party/raid member gets Mind Controlled (4s fade)
- **Buffs** — Cooldown & stack tracking:
  - Enable/disable tracking
  - 5×2 drag-from-spellbook cooldown slots (10 slots) with icon display
  - Center-screen alert on cooldown expiry or stack change
  - Maelstrom Weapon stack tracking (Show maelstorm stack checkbox)
- **Item** — Bag item tracking:
  - Enable/disable tracking
  - 5×5 drag-from-bags grid (25 item slots)
  - Configurable alert interval (minutes) and threshold (count)
  - Periodic bag scan via OnUpdate timer
  - Chat alert when item count drops to or below threshold

### Settings (gear button)
- **Loot sub-tab**: Show/hide Add and Delete sub-tabs in Loot tab
- **Alert sub-tab**: Show/hide Dung/Raid/WG/Arena/Random/Enemy/Buffs/Item sub-tabs in Alert tab
- **Various sub-tab**:
  - **Autosell junk and autorepair**: auto-sells all grey items and repairs equipment on merchant open
  - **Show alerts in chat**: prints alert name to chat when any alert fires
  - **Scan auction house**: enables/disables automatic AH price scanning
  - **Move items with ALT+RightClick**: when bank is open, ALT+RightClick an item → moves all matching items from bags to empty bank slots

### General
- Shift-click item linking from bags, profession windows, Auction House
- Shift-click inserts item link into edit box when focused
- Drag & drop items directly onto the addon window
- 21,000+ item offline database (Warmane-correct IDs)
- Draggable minimap button with saved position
- Resizable and movable window with saved position
- Mouse wheel scrolling on item list
- Row pool system for smooth scrolling performance

## Commands
- `/todo` or `/detaurbar` — Toggle main window
- `/detaurdebug` — Debug info (UI state, DB, minimap button)
- `/detaurenemy` — Toggle enemy monitor window
- `/detaurid scan` — Scan items in bags/bank for ID lookup
- `/detaurid icon <id>` — Show icon path for an item ID
- `/detaurid save <id>` — Save current target/item to price list by ID
- `/detaurfixherbs` — Fix Northrend herb item IDs (safe mapping, no data loss)
- `/detaurrecover` — Recover items stuck in legacy array format
- `/detaurrestore` — Restore items from backup
- `/detaurmigrate` — Manually re-run data migrations
- Right-click minimap icon — Toggle enemy monitor window

## Installation
1. Download and extract the `Detaurtodo` folder
2. Place it in `World of Warcraft\Interface\AddOns\`
3. Launch the game and enable **Detaurtodo** in the AddOns list
4. Type `/todo` or `/detaurbar` to open

## Requirements
- WoW client patch **3.3.5a** (Build 12340)
- Tested on Warmane Icecrown
