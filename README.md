# DetaurBar

In-game organizer addon for **World of Warcraft: Wrath of the Lich King (Patch 3.3.5a)** — designed for Warmane (Icecrown).

## Features

### Todo
- Checklist split into **Day / Week / Month** sub-tabs
- Day resets automatically at 3:00 AM
- Week and Month persist indefinitely
- Checkbox toggles completed state (greyed out when done)
- Delete (X) removes task

### Notes
- Quick text notes across **General / War / Guild** sub-tabs
- Click any note to paste its text into chat
- Copy button on each row to paste into chat
- Drag notes between sub-tabs to reorganize (drag row, drop on target sub-tab)

### Loot
- **Add** sub-tab: whitelist items you want to track (icons, rarity colors, tooltips with sell price)
- **Delete** sub-tab: auto-delete list for gray items
- **Delete All Grays** checkbox in Delete sub-tab
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
- Resizable width (200–500px) with bottom-right grip
- Each row shows: enemy name (red), level + 4-char class abbrev, current activity
- **Left-click** row → targets the enemy
- **Right-click** row → dismisses enemy from list (session-only)
- Enemies auto-fade after 120s of inactivity
- Automatically disabled in instances

### Settings
- **Dungeon** — Screen flash on LFG proposal: enable/disable, flash color (Green/Yellow/Red), flash duration
- **Wintergrasp** — Two configurable alerts:
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
- `/detaurid scan` — Scan items in bags/bank for ID lookup
- Right-click minimap icon — Toggle enemy monitor window

## Installation
1. Download and extract the `Detaurtodo` folder
2. Place it in `World of Warcraft\Interface\AddOns\`
3. Launch the game and enable **Detaurtodo** in the AddOns list
4. Type `/todo` or `/detaurbar` to open

## Requirements
- WoW client patch **3.3.5a** (Build 12340)
- Tested on Warmane Icecrown
