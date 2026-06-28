-- DetaurBar_UI.lua
-- Handles frame creation, textures, tabs, checkboxes, scrolling, and layouts.

-- Global namespace
DetaurBar = DetaurBar or {}
DetaurBar.UI = {}

-- [MAIN FRAME] CreateFrame with size/position/move/resize, default hidden
local frame = CreateFrame("Frame", "DetaurBarFrame", UIParent)
frame:SetSize(300, 430)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:SetResizable(true)
frame:SetMinResize(300, 430)
frame:SetMaxResize(600, 1200)
frame:Hide() -- Hidden by default
tinsert(UISpecialFrames, "DetaurBarFrame")


-- [MAIN FRAME] Solid backdrop panel with WoW dialog border
frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
frame:SetBackdropColor(0.12, 0.10, 0.08, 1)

-- [MAIN FRAME] Drag-to-move saves position to DetaurBarDB
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
    if DetaurBarDB then
        DetaurBarDB.framePosition = {
            point = point,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
    end
end)

-- [HEADER] Title header texture (DialogBox-Header)
local header = frame:CreateTexture(nil, "ARTWORK")
header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
header:SetWidth(256)
header:SetHeight(64)
header:SetPoint("TOP", frame, "TOP", 0, 12)

local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("TOP", header, "TOP", 0, -14)
titleText:SetText("DetaurBar") -- Updated Header Text
titleText:SetTextColor(1.0, 0.82, 0.0, 1.0) -- Classic WoW Gold

-- [HEADER] Close button (standard UIPanelCloseButton)
local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function()
    frame:Hide()
end)

-- [STATE] Tab names, active tab, expanded price tracking
local tabs = {}
local tabNames = { "Todo", "Notes", "Loot", "Price", "Settings" }
local activeTab = "Todo"
local expandedPriceItemId = nil

-- Todo sub-tabs (Day, Week, Month)
local todoSubTabs = {}
local todoSubTabNames = { "Day", "Week", "Month" }
local activeTodoSubTab = "Day"
local UpdateTodoSubTabVisuals

-- Notes sub-tabs (General, War, Guild)
local notesSubTabs = {}
local notesSubTabNames = { "General", "War", "Guild" }
local activeNotesSubTab = "General"
local draggedNote = nil
local UpdateNotesSubTabVisuals

-- [STATE] Loot sub-tabs: Add / Delete (sub-tab for batch-deleting gray items)
local lootSubTabs = {}
local lootSubTabNames = { "Add", "Delete" }
local activeLootSubTab = "Add"
local UpdateLootSubTabVisuals
local deleteAllGraysCheckbox

-- [STATE] Price item sub-tabs: Notifications (auto-filtered) / Chart (with graph + threshold)
local priceItemSubTabs = {}
local priceItemSubTabNames = { "Notifications", "Chart" }
local activePriceItemSubTab = "Notifications"
local UpdatePriceItemSubTabVisuals

-- [STATE] Settings sub-tabs: Dungeon / Wintergrasp / Random
local settingsSubTabs = {}
local settingsSubTabNames = { "Dungeon", "Wintergrasp", "Random" }
local activeSettingsSubTab = "Dungeon"
local UpdateSettingsSubTabVisuals

-- [STATE] Selected price item for threshold editing; settings panel/bar references; color/sound label maps
local selectedPriceItemId = nil
local priceThresholdRow = nil
local priceAhIntervalRow = nil
local PRICE_THRESHOLD_ROW_HEIGHT = 40
local settingsPanel = nil
local settingsSubTabBar = nil
local settingsListBackground = nil
local settingsColorButtons = {}
local settingsWGColorButtons = {}
local settingsSoundButtons = {}
local settingsColorLabels = { GREEN = "Green", YELLOW = "Yellow", RED = "Red" }
local settingsSoundLabels = {
    RaidWarning = "Raid",
    PvPFlagCaptured = "PvP",
    ReadyCheck = "Ready",
}

-- [HELPERS] Category string builders (todo_day, notes_war, etc.)
local function GetTodoCategory(subTabName)
    return "todo_" .. subTabName:lower()
end

local function GetNotesCategory(subTabName)
    return "notes_" .. subTabName:lower()
end

-- [HELPERS] GetSettingsDB — returns DetaurBarDB.settings with InitializeDB()
local function GetSettingsDB()
    DetaurBar.Data.InitializeDB()
    return DetaurBarDB.settings or {}
end

-- [HELPERS] ClampNumber — tonumber with fallback, clamped to [min, max]
local function ClampNumber(value, defaultValue, minValue, maxValue)
    value = tonumber(value) or defaultValue
    if minValue and value < minValue then
        value = minValue
    end
    if maxValue and value > maxValue then
        value = maxValue
    end
    return value
end

-- [UI FACTORY] SetChoiceButtonStyle — gold accent for active, dark for inactive
local function SetChoiceButtonStyle(button, isActive)
    if isActive then
        button:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
        button:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        button.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
        button:Disable()
    else
        button:SetBackdropColor(0, 0, 0, 0.55)
        button:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        button.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
        button:Enable()
    end
end

-- [UI FACTORY] CreateChoiceButton — small toggle button with gold highlight
local function CreateChoiceButton(parent, width, label)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(22)
    button:SetWidth(width)
    button:EnableMouse(true)
    button:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 12,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    button:SetBackdropColor(0, 0, 0, 0.55)
    button:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", button, "CENTER", 0, 0)
    text:SetText(label)
    button.label = text

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetTexture(1.0, 0.82, 0.0, 0.12)

    return button
end

-- [UI FACTORY] CreateSettingEditBox — numeric EditBox with dark backdrop
local function CreateSettingEditBox(parent, width)
    local edit = CreateFrame("EditBox", nil, parent)
    edit:SetSize(width, 20)
    edit:SetAutoFocus(false)
    edit:SetNumeric(true)
    edit:SetTextInsets(4, 4, 0, 0)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 12,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    edit:SetBackdropColor(0, 0, 0, 0.8)
    edit:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
    return edit
end

-- [UI FACTORY] SetSimpleTooltip — OnEnter/OnLeave GameTooltip helper
local function SetSimpleTooltip(frame, title, text)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(title, 1.0, 1.0, 1.0)
        if text then
            GameTooltip:AddLine(text, 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- [NOTES] ClearDraggedNote — resets drag state and OnUpdate
local function ClearDraggedNote()
    draggedNote = nil
    frame:SetScript("OnUpdate", nil)
end

-- [NOTES] StartDraggedNote — tracks held mouse, auto-clears after 0.15s release
local function StartDraggedNote(fromCategory, itemId)
    draggedNote = {
        fromCategory = fromCategory,
        itemId = itemId
    }
    local releaseElapsed = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        if not IsMouseButtonDown("LeftButton") then
            releaseElapsed = releaseElapsed + elapsed
            if releaseElapsed > 0.15 then
                ClearDraggedNote()
            end
        else
            releaseElapsed = 0
        end
    end)
end

-- [NOTES] DropDraggedNoteOnSubTab — moves note to target category
local function DropDraggedNoteOnSubTab(subTab)
    if not draggedNote then
        return false
    end

    local toCategory = GetNotesCategory(subTab.tabName)
    if draggedNote.fromCategory ~= toCategory then
        DetaurBar.Data.MoveItem(draggedNote.fromCategory, toCategory, draggedNote.itemId)
        DetaurBar.UI.SelectNotesSubTab(subTab.tabName)
    else
        DetaurBar.UI.RefreshTasks()
    end

    ClearDraggedNote()
    return true
end

local function SetTodoSubTabStyle(subTab)
    if subTab.tabName == activeTodoSubTab then
        subTab:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
        subTab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        subTab.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    else
        subTab:SetBackdropColor(0, 0, 0, 0.55)
        subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        subTab.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
    end
end

local function SetNotesSubTabStyle(subTab)
    if subTab.tabName == activeNotesSubTab then
        subTab:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
        subTab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        subTab.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    else
        subTab:SetBackdropColor(0, 0, 0, 0.55)
        subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        subTab.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
    end
end

-- [SUB-TAB STYLE] Loot sub-tab visual (active = gold, inactive = dark)
local function SetLootSubTabStyle(subTab)
    if subTab.tabName == activeLootSubTab then
        subTab:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
        subTab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        subTab.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    else
        subTab:SetBackdropColor(0, 0, 0, 0.55)
        subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        subTab.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
    end
end

-- [SUB-TAB STYLE] Price item sub-tab visual
local function SetPriceItemSubTabStyle(subTab)
    if subTab.tabName == activePriceItemSubTab then
        subTab:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
        subTab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        subTab.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    else
        subTab:SetBackdropColor(0, 0, 0, 0.55)
        subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        subTab.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
    end
end

-- [SUB-TAB STYLE] Settings sub-tab visual
local function SetSettingsSubTabStyle(subTab)
    if subTab.tabName == activeSettingsSubTab then
        subTab:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
        subTab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        subTab.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    else
        subTab:SetBackdropColor(0, 0, 0, 0.55)
        subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        subTab.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
    end
end

-- [ITEM HELPERS] GetItemIdFromText — extract item ID from link, "item:ID" text, number, or DB name lookup
local function GetItemIdFromText(text)
    if not text then return nil end
    local id = string.match(text, "item:%s*(%d+)")
    if id then
        return tonumber(id)
    end
    if string.match(text, "^%d+$") then
        return tonumber(text)
    end
    -- Database lookup by name
    local cleanedName = string.lower(text):gsub("^%s*(.-)%s*$", "%1")
    if DetaurBar.Data.ItemDatabase and DetaurBar.Data.ItemDatabase[cleanedName] then
        return DetaurBar.Data.ItemDatabase[cleanedName]
    end
    return nil
end

-- [ITEM HELPERS] GetOfflineItemNameById — look up name from offline ItemDatabaseReverse
local function GetOfflineItemNameById(itemId)
    if not itemId or not DetaurBar.Data.ItemDatabaseReverse then
        return nil
    end
    local name = DetaurBar.Data.ItemDatabaseReverse[itemId]
    if name then
        -- Kapitalizuj prve pismeno a pismena po medzere (nie po apostrofe)
        local result = name:gsub("(%s)(%a)", function(s, a) return s .. a:upper() end)
        return result:sub(1,1):upper() .. result:sub(2)
    end
    return nil
end

-- [ITEM HELPERS] BuildOfflineItemLink — builds hyperlink from offline name
local function BuildOfflineItemLink(itemId)
    local itemName = GetOfflineItemNameById(itemId)
    if itemName then
        return "|cffffffff|Hitem:" .. itemId .. ":0:0:0:0:0:0:0|h[" .. itemName .. "]|h|r"
    end
    return nil
end

-- [ITEM HELPERS] GetUsableItemLink — prefers offline link, falls back to GetItemInfo
local function GetUsableItemLink(text)
    local itemId = GetItemIdFromText(text)
    local itemLink

    if itemId then
        -- VZDY pouzivaj offline link ak sa najde ID v databaze (ignoruj serverove GetItemInfo)
        itemLink = BuildOfflineItemLink(itemId)
        if not itemLink then
            -- Ak offline link neexistuje, skus server
            _, itemLink = GetItemInfo(itemId)
            if not itemLink then
                _, itemLink = GetItemInfo("item:" .. itemId)
            end
        end
        return itemLink or BuildOfflineItemLink(itemId), itemId
    end

    _, itemLink = GetItemInfo(text)
    if not itemLink then
        local capped = text:gsub("(%a)([%w_']*)", function(f, r) return f:upper() .. r:lower() end)
        _, itemLink = GetItemInfo(capped)
    end

    return itemLink, nil
end

-- [DRAG-DROP] OnReceiveDragHandler — imports dragged items into active tab/category
local function OnReceiveDragHandler()
    local infoType, itemId, itemLink = GetCursorInfo()
    if infoType == "item" then
        local category = activeTab:lower()
        if category == "loot" then
            category = "loot_" .. activeLootSubTab:lower()
        end
        if category == "loot_add" or category == "loot_delete" or category == "sell" or category == "price" then
            local title = itemLink or ("item:" .. itemId)
            local newItem = DetaurBar.Data.AddItem(category, title)
            if newItem and category == "price" and activePriceItemSubTab == "Notifications" then
                newItem.frequent = true
            end
            ClearCursor()
            DetaurBar.UI.RefreshTasks()
        end
    end
end

-- [MAIN FRAME] Register drag-drop receiver on main frame
frame:SetScript("OnReceiveDrag", OnReceiveDragHandler)


-- [TABS] Create 5 main tab buttons (Todo, Notes, Loot, Price, Settings)
for i, name in ipairs(tabNames) do
    local tab = CreateFrame("Button", "DetaurBarTab_" .. name, frame, "UIPanelButtonTemplate")
    tab:SetHeight(22)
    tab.tabName = name
    tab:SetText(name)
    
    tab:SetScript("OnClick", function()
        DetaurBar.UI.SelectTab(name)
    end)
    
    tabs[i] = tab
end

-- [SUB-TABS/TODO] Create 3 sub-tabs: Day, Week, Month
for i, name in ipairs(todoSubTabNames) do
    local subTab = CreateFrame("Button", "DetaurBarTodoSubTab_" .. name, frame)
    subTab:SetHeight(24)
    subTab:SetFrameLevel(frame:GetFrameLevel() + 6)
    subTab:EnableMouse(true)
    subTab.tabName = name
    subTab:Hide()

    subTab:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 12,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    subTab:SetBackdropColor(0, 0, 0, 0.55)
    subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

    local label = subTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", subTab, "CENTER", 0, 0)
    label:SetText(name)
    subTab.label = label

    local highlight = subTab:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(subTab)
    highlight:SetTexture(1.0, 0.82, 0.0, 0.12)

    subTab:SetScript("OnClick", function()
        DetaurBar.UI.SelectTodoSubTab(name)
    end)

    todoSubTabs[i] = subTab
end

-- [SUB-TABS/NOTES] Create 3 sub-tabs: General, War, Guild (supports drag-to-move)
for i, name in ipairs(notesSubTabNames) do
    local subTab = CreateFrame("Button", "DetaurBarNotesSubTab_" .. name, frame)
    subTab:SetHeight(24)
    subTab:SetFrameLevel(frame:GetFrameLevel() + 6)
    subTab:EnableMouse(true)
    subTab.tabName = name
    subTab:Hide() -- Hidden by default

    subTab:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 12,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    subTab:SetBackdropColor(0, 0, 0, 0.55)
    subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

    local label = subTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", subTab, "CENTER", 0, 0)
    label:SetText(name)
    subTab.label = label

    local highlight = subTab:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(subTab)
    highlight:SetTexture(1.0, 0.82, 0.0, 0.12)
    
    subTab:SetScript("OnClick", function()
        DetaurBar.UI.SelectNotesSubTab(name)
    end)
    subTab:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            DropDraggedNoteOnSubTab(self)
        end
    end)
    subTab:SetScript("OnReceiveDrag", function(self)
        DropDraggedNoteOnSubTab(self)
    end)
    subTab:SetScript("OnEnter", function(self)
        if draggedNote then
            self:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Move Note", 1.0, 1.0, 1.0)
            GameTooltip:AddLine("Release to move this note to " .. self.tabName .. ".", 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end
    end)
    subTab:SetScript("OnLeave", function(self)
        SetNotesSubTabStyle(self)
        GameTooltip:Hide()
    end)
    
    notesSubTabs[i] = subTab
end

-- [SUB-TABS/LOOT] Create 2 sub-tabs: Add, Delete
for i, name in ipairs(lootSubTabNames) do
    local subTab = CreateFrame("Button", "DetaurBarLootSubTab_" .. name, frame)
    subTab:SetHeight(24)
    subTab:SetFrameLevel(frame:GetFrameLevel() + 6)
    subTab:EnableMouse(true)
    subTab.tabName = name
    subTab:Hide()

    subTab:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 12,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    subTab:SetBackdropColor(0, 0, 0, 0.55)
    subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

    local label = subTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", subTab, "CENTER", 0, 0)
    label:SetText(name)
    subTab.label = label

    local highlight = subTab:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(subTab)
    highlight:SetTexture(1.0, 0.82, 0.0, 0.12)

    subTab:SetScript("OnClick", function()
        DetaurBar.UI.SelectLootSubTab(name)
    end)

    lootSubTabs[i] = subTab
end

-- [SUB-TABS/PRICE] Create 2 sub-tabs: Notifications, Chart
for i, name in ipairs(priceItemSubTabNames) do
    local subTab = CreateFrame("Button", "DetaurBarPriceItemSubTab_" .. name, frame)
    subTab:SetHeight(24)
    subTab:SetFrameLevel(frame:GetFrameLevel() + 6)
    subTab:EnableMouse(true)
    subTab.tabName = name
    subTab:Hide()

    subTab:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 12,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    subTab:SetBackdropColor(0, 0, 0, 0.55)
    subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

    local label = subTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", subTab, "CENTER", 0, 0)
    label:SetText(name)
    subTab.label = label

    local highlight = subTab:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(subTab)
    highlight:SetTexture(1.0, 0.82, 0.0, 0.12)

    subTab:SetScript("OnClick", function()
        DetaurBar.UI.SelectPriceItemSubTab(name)
    end)

    priceItemSubTabs[i] = subTab
end

-- [SUB-TABS/SETTINGS] Create 3 sub-tabs: Dungeon, Wintergrasp, Random
for i, name in ipairs(settingsSubTabNames) do
    local subTab = CreateFrame("Button", "DetaurBarSettingsSubTab_" .. name, frame)
    subTab:SetHeight(24)
    subTab:SetFrameLevel(frame:GetFrameLevel() + 6)
    subTab:EnableMouse(true)
    subTab.tabName = name
    subTab:Hide()

    subTab:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 12,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    subTab:SetBackdropColor(0, 0, 0, 0.55)
    subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

    local label = subTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", subTab, "CENTER", 0, 0)
    label:SetText(name)
    subTab.label = label

    local highlight = subTab:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(subTab)
    highlight:SetTexture(1.0, 0.82, 0.0, 0.12)

    subTab:SetScript("OnClick", function()
        DetaurBar.UI.SelectSettingsSubTab(name)
    end)

    settingsSubTabs[i] = subTab
end

-- [SETTINGS/LAYOUT] UpdateSettingsSubTabBar — positions 3 sub-tabs inside settingsSubTabBar
local function UpdateSettingsSubTabBar()
    local totalWidth = frame:GetWidth() - 28
    local subTabGap = 4
    local subTabWidth = (totalWidth - (subTabGap * 2)) / 3
    for i, subTab in ipairs(settingsSubTabs) do
        subTab:SetWidth(subTabWidth)
        subTab:ClearAllPoints()
        if i == 1 then
            subTab:SetPoint("TOPLEFT", settingsSubTabBar, "TOPLEFT", 0, 0)
        else
            subTab:SetPoint("LEFT", settingsSubTabs[i-1], "RIGHT", subTabGap, 0)
        end
    end
end

-- [SETTINGS/LAYOUT] UpdateSettingsSubTabVisuals — gold for active, dark for inactive
UpdateSettingsSubTabVisuals = function()
    for _, subTab in ipairs(settingsSubTabs) do
        SetSettingsSubTabStyle(subTab)
        if subTab.tabName == activeSettingsSubTab then
            subTab:Disable()
        else
            subTab:Enable()
        end
    end
end

-- [LAYOUT] UpdateTabAnchors — positions main tabs, all sub-tabs to fit frame width
local function UpdateTabAnchors()
    local totalWidth = frame:GetWidth() - 28 -- Padding to fit inside thick borders
    local tabWidth = totalWidth / math.max(1, #tabs) -- Split evenly among main tabs
    for i, tab in ipairs(tabs) do
        tab:SetWidth(tabWidth)
        tab:ClearAllPoints()
        if i == 1 then
            tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -30)
        else
            tab:SetPoint("LEFT", tabs[i-1], "RIGHT", 0, 0)
        end
    end
    
    -- Layout Todo and Notes sub-tabs on the inner panel edge.
    local subTabGap = 4
    local subTabWidth = (totalWidth - (subTabGap * 2)) / 3
    for i, subTab in ipairs(todoSubTabs) do
        subTab:SetWidth(subTabWidth)
        subTab:ClearAllPoints()
        if i == 1 then
            subTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
        else
            subTab:SetPoint("LEFT", todoSubTabs[i-1], "RIGHT", subTabGap, 0)
        end
    end
    for i, subTab in ipairs(notesSubTabs) do
        subTab:SetWidth(subTabWidth)
        subTab:ClearAllPoints()
        if i == 1 then
            subTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
        else
            subTab:SetPoint("LEFT", notesSubTabs[i-1], "RIGHT", subTabGap, 0)
        end
    end
    local lootSubTabWidth = (totalWidth - subTabGap) / 2
    for i, subTab in ipairs(lootSubTabs) do
        subTab:SetWidth(lootSubTabWidth)
        subTab:ClearAllPoints()
        if i == 1 then
            subTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
        else
            subTab:SetPoint("LEFT", lootSubTabs[i-1], "RIGHT", subTabGap, 0)
        end
    end

    local priceItemSubTabWidth = (totalWidth - subTabGap) / 2
    for i, subTab in ipairs(priceItemSubTabs) do
        subTab:SetWidth(priceItemSubTabWidth)
        subTab:ClearAllPoints()
        if i == 1 then
            subTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
        else
            subTab:SetPoint("LEFT", priceItemSubTabs[i-1], "RIGHT", subTabGap, 0)
        end
    end

    local settingsSubTabWidth = (totalWidth - (subTabGap * 3)) / 4
    for i, subTab in ipairs(settingsSubTabs) do
        subTab:SetWidth(settingsSubTabWidth)
        subTab:ClearAllPoints()
        if i == 1 then
            subTab:SetPoint("TOPLEFT", settingsSubTabBar, "TOPLEFT", 0, 0)
        else
            subTab:SetPoint("LEFT", settingsSubTabs[i-1], "RIGHT", subTabGap, 0)
        end
    end

    if settingsSubTabBar then
        settingsSubTabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
        settingsSubTabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -60)
        UpdateSettingsSubTabBar()
    end
end

-- [STATE] Scroll/graph bar/price graph/price sub-tab/settings scroll declarations
local scrollFrame
local priceGraphPanel
local priceSubTabBar
local priceGraphHolder = { graphTextures = {}, graphLabels = {}, graphFrames = {} }
local PRICE_GRAPH_PANEL_HEIGHT = 120
local PRICE_SUBTAB_HEIGHT = 24
local activePriceSubTab = "Daily"
local priceSubTabObjects = {}
local UpdatePriceSubTabVisuals
local settingsScrollFrame
local settingsScrollChild
local settingsSaveButton
local settingsDungeonControls = {}
local settingsWintergraspControls = {}
local UpdateRandomAlertRows
local settingsRandomControls = {}

-- [LAYOUT] UpdateContentAnchors — hides settings UI or main scroll/graph based on activeTab
local function UpdateContentAnchors()
    if activeTab == "Settings" then
        if scrollFrame then scrollFrame:Hide() end
        if priceGraphPanel then priceGraphPanel:Hide() end
        if priceSubTabBar then priceSubTabBar:Hide() end
        if priceThresholdRow then priceThresholdRow:Hide() end
        if priceAhIntervalRow then priceAhIntervalRow:Hide() end
        if settingsSubTabBar then settingsSubTabBar:Show() end
        if settingsListBackground then settingsListBackground:Show() end
        if settingsScrollFrame then settingsScrollFrame:Show() end
        if settingsPanel then settingsPanel:Show() end
        if settingsScrollChild then settingsScrollChild:Show() end
        return
    end

    if settingsPanel then
        settingsPanel:Hide()
    end
    if settingsSubTabBar then
        settingsSubTabBar:Hide()
    end
    if settingsListBackground then
        settingsListBackground:Hide()
    end
    if settingsScrollFrame then
        settingsScrollFrame:Hide()
    end

    scrollFrame:ClearAllPoints()
    if activeTab == "Notes" or activeTab == "Todo" or activeTab == "Price" then
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -88)
    elseif activeTab == "Loot" and activeLootSubTab == "Delete" then
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -114)
    elseif activeTab == "Loot" then
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -88)
    else
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -60)
    end
    if activeTab == "Price" then
        if activePriceItemSubTab == "Chart" then
            scrollFrame:SetPoint("BOTTOMLEFT", priceThresholdRow, "TOPLEFT", 0, 4)
            scrollFrame:SetPoint("BOTTOMRIGHT", priceThresholdRow, "TOPRIGHT", -16, 4)
            priceThresholdRow:Show()
            priceSubTabBar:Show()
            priceGraphPanel:Show()
            if priceAhIntervalRow then priceAhIntervalRow:Hide() end
        else
            -- Notifications: anchor directly to frame bottom (no graph, no time filters, no threshold row)
            scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 50)
            if priceThresholdRow then priceThresholdRow:Hide() end
            priceSubTabBar:Hide()
            priceGraphPanel:Hide()
            if priceAhIntervalRow then priceAhIntervalRow:Show() end
        end
    else
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 50)
        priceSubTabBar:Hide()
        priceGraphPanel:Hide()
        if priceThresholdRow then priceThresholdRow:Hide() end
        if priceAhIntervalRow then priceAhIntervalRow:Hide() end
    end
end

-- [SETTINGS/PANEL] Main settings backdrop panel (transparent, frames inset)
settingsPanel = CreateFrame("Frame", "DetaurBarSettingsPanel", frame)
settingsPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -60)
settingsPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 14)
settingsPanel:Hide()
settingsPanel:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 12,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
settingsPanel:SetBackdropColor(0, 0, 0, 0.0)
settingsPanel:SetBackdropBorderColor(0, 0, 0, 0)

-- [SETTINGS/PANEL] Sub-tab bar inside settings panel (holds 4 sub-tab buttons)
settingsSubTabBar = CreateFrame("Frame", "DetaurBarSettingsSubTabBar", settingsPanel)
settingsSubTabBar:SetHeight(24)
settingsSubTabBar:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 8, -8)
settingsSubTabBar:SetPoint("TOPRIGHT", settingsPanel, "TOPRIGHT", -24, -8)
settingsSubTabBar:Hide()

-- [SETTINGS/PANEL] Background frame for settings content with dark backdrop
settingsListBackground = CreateFrame("Frame", "DetaurBarSettingsListBackground", settingsPanel)
settingsListBackground:SetPoint("TOPLEFT", settingsSubTabBar, "BOTTOMLEFT", -1, -2)
settingsListBackground:SetPoint("BOTTOMRIGHT", settingsPanel, "BOTTOMRIGHT", 0, 36)
settingsListBackground:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 12,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
settingsListBackground:SetBackdropColor(0, 0, 0, 0.4)
settingsListBackground:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
settingsListBackground:Hide()

-- [SETTINGS/PANEL] ScrollFrame for settings content, mouse-wheel enabled
settingsScrollFrame = CreateFrame("ScrollFrame", "DetaurBarSettingsScrollFrame", settingsListBackground)
settingsScrollFrame:SetPoint("TOPLEFT", settingsListBackground, "TOPLEFT", 4, -4)
settingsScrollFrame:SetPoint("BOTTOMRIGHT", settingsListBackground, "BOTTOMRIGHT", -20, 4)
settingsScrollFrame:Hide()
settingsScrollFrame:EnableMouseWheel(true)

-- [SETTINGS/PANEL] Vertical scroll bar for settings scroll frame
local settingsScrollBar = CreateFrame("Slider", "DetaurBarSettingsScrollBar", settingsScrollFrame, "UIPanelScrollBarTemplate")
settingsScrollBar:SetPoint("TOPLEFT", settingsScrollFrame, "TOPRIGHT", 4, -16)
settingsScrollBar:SetPoint("BOTTOMLEFT", settingsScrollFrame, "BOTTOMRIGHT", 4, 16)
settingsScrollBar:SetWidth(16)
settingsScrollBar:SetValueStep(1)
settingsScrollBar:SetMinMaxValues(0, 0)
settingsScrollBar:SetValue(0)

settingsScrollBar:SetScript("OnValueChanged", function(self, value)
    settingsScrollFrame:SetVerticalScroll(value)
end)

settingsScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = settingsScrollBar:GetValue()
    settingsScrollBar:SetValue(current - delta * 20)
end)

-- [SETTINGS/PANEL] Settings scroll child — actual content parent
settingsScrollChild = CreateFrame("Frame", "DetaurBarSettingsScrollChild", settingsScrollFrame)
settingsScrollFrame:SetScrollChild(settingsScrollChild)
settingsScrollChild:SetWidth(math.max(1, settingsScrollFrame:GetWidth() or (frame:GetWidth() - 64)))
settingsScrollChild:SetHeight(390)

-- [UI FACTORY] CreateSettingsLabel — gold-colored TOPLEFT label
local function CreateSettingsLabel(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    return label
end

-- [UI FACTORY] CreateSettingsCheck — CheckButton with gold label + OnClick callback
local function CreateSettingsCheck(parent, text, x, y, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetSize(20, 20)
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    checkbox:SetScript("OnClick", onClick)
    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    label:SetText(text)
    label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    return checkbox, label
end

-- [UI FACTORY] SetButtonGroupValue — highlight the active button in a choice group
local function SetButtonGroupValue(group, value)
    for key, button in pairs(group) do
        SetChoiceButtonStyle(button, key == value)
    end
end

-- [UI FACTORY] CreateSettingsChoiceRow — row of choice buttons, stores in group[key]
local function CreateSettingsChoiceRow(parent, group, options, x, y, width, onChoose)
    local buttonWidth = math.floor((width - ((#options - 1) * 4)) / #options)
    local currentX = x
    for _, opt in ipairs(options) do
        local button = CreateChoiceButton(parent, buttonWidth, opt.label)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", currentX, y)
        button:SetScript("OnClick", function()
            onChoose(opt.key)
            SetButtonGroupValue(group, opt.key)
        end)
        SetSimpleTooltip(button, opt.label, opt.tooltip or ("Select " .. opt.label .. "."))
        group[opt.key] = button
        currentX = currentX + buttonWidth + 4
    end
end

local function CreateSettingsEditRow(parent, labelText, x, y, width, maxLetters, onEnter)
    local label = CreateSettingsLabel(parent, labelText, x, y)
    local edit = CreateSettingEditBox(parent, width)
    edit:SetPoint("LEFT", label, "RIGHT", 8, 0)
    edit:SetMaxLetters(maxLetters or 4)
    edit:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        onEnter(self)
    end)
    edit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return label, edit
end

local dungeonEnableCheckbox, dungeonEnableLabel = CreateSettingsCheck(settingsScrollChild, "Enable Dungeon Flash Alert", 8, -8, function(self)
    local settings = GetSettingsDB()
    settings.dungeonFlashEnabled = self:GetChecked() and true or false
end)
SetSimpleTooltip(dungeonEnableCheckbox, "Enable Dungeon Flash Alert", "Flash the whole screen when a Dungeon Finder proposal appears.")

local dungeonColorLabel = CreateSettingsLabel(settingsScrollChild, "Flash Color", 8, -40)
local dungeonDurationLabel, dungeonDurationEdit = CreateSettingsEditRow(settingsScrollChild, "Flash duration", 8, -68, 36, 3, function(self)
    local settings = GetSettingsDB()
    settings.dungeonFlashDuration = ClampNumber(self:GetText(), 0, 0, 120)
    self:SetText(tostring(settings.dungeonFlashDuration))
end)
SetSimpleTooltip(dungeonDurationEdit, "Flash Duration", "How many seconds to flash. Set 0 for infinite (until proposal closes).")
local dungeonColorRow = {}
CreateSettingsChoiceRow(settingsScrollChild, settingsColorButtons, {
    { key = "GREEN", label = settingsColorLabels.GREEN, tooltip = "Use a green full-screen flash." },
    { key = "YELLOW", label = settingsColorLabels.YELLOW, tooltip = "Use a yellow full-screen flash." },
    { key = "RED", label = settingsColorLabels.RED, tooltip = "Use a red full-screen flash." },
}, 8, -94, 162, function(value)
    local settings = GetSettingsDB()
    settings.dungeonFlashColor = value
end)

local ahLabel, ahIntervalEdit = CreateSettingsEditRow(settingsScrollChild, "AH Scan Interval", 8, -10, 36, 3, function(self)
    local settings = GetSettingsDB()
    settings.ahScanInterval = ClampNumber(self:GetText(), 10, 1, 120)
    self:SetText(tostring(settings.ahScanInterval))
end)
SetSimpleTooltip(ahIntervalEdit, "AH Scan Interval", "How often the addon can auto-scan the Auction House while the AH is open.")

-- [PRICE/AH SCAN INTERVAL] Row shown in Price > Notifications (moved from Settings > Auction)
priceAhIntervalRow = CreateFrame("Frame", nil, frame)
priceAhIntervalRow:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 21)
priceAhIntervalRow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 21)
priceAhIntervalRow:SetHeight(22)
priceAhIntervalRow:Hide()

ahLabel:SetParent(priceAhIntervalRow)
ahLabel:ClearAllPoints()
ahLabel:SetPoint("LEFT", priceAhIntervalRow, "LEFT", 0, 2)

ahIntervalEdit:SetParent(priceAhIntervalRow)
ahIntervalEdit:ClearAllPoints()
ahIntervalEdit:SetPoint("LEFT", ahLabel, "RIGHT", 8, 0)

-- [SETTINGS/WINTERGRASP] Enable checkbox for Wintergrasp alerts
local wgEnableCheckbox, wgEnableLabel = CreateSettingsCheck(settingsScrollChild, "Enable Wintergrasp Alerts", 8, -8, function(self)
    local settings = GetSettingsDB()
    settings.wgAlertsEnabled = self:GetChecked() and true or false
end)
SetSimpleTooltip(wgEnableCheckbox, "Enable Wintergrasp Alerts", "Run background Wintergrasp countdown checks and fire warnings when the threshold is reached.")

-- [SETTINGS/WINTERGRASP] "Registration Warning" section label
local wgSectionLabel = CreateSettingsLabel(settingsScrollChild, "Registration Warning", 8, -40)
-- [SETTINGS/WINTERGRASP] Alert1 minutes + duration edits, color choice, sound checkbox + sound choice
local wgAlert1MinutesLabel, wgAlert1MinutesEdit = CreateSettingsEditRow(settingsScrollChild, "Minutes before start", 8, -68, 36, 3, function(self)
    local settings = GetSettingsDB()
    settings.wgAlert1Minutes = ClampNumber(self:GetText(), 15, 0, 120)
    self:SetText(tostring(settings.wgAlert1Minutes))
end)
SetSimpleTooltip(wgAlert1MinutesEdit, "Registration Warning", "Minutes before battle start to flash the screen.")
local wgAlert1DurationLabel, wgAlert1DurationEdit = CreateSettingsEditRow(settingsScrollChild, "Flash duration", 8, -96, 36, 3, function(self)
    local settings = GetSettingsDB()
    settings.wgAlert1Duration = ClampNumber(self:GetText(), 2, 0, 30)
    self:SetText(tostring(settings.wgAlert1Duration))
end)
SetSimpleTooltip(wgAlert1DurationEdit, "Flash Duration", "How long the Wintergrasp registration warning should flash.")
local wgAlert1ColorLabel = CreateSettingsLabel(settingsScrollChild, "Flash Color", 8, -124)
CreateSettingsChoiceRow(settingsScrollChild, settingsWGColorButtons, {
    { key = "GREEN", label = settingsColorLabels.GREEN, tooltip = "Use a green Wintergrasp flash." },
    { key = "YELLOW", label = settingsColorLabels.YELLOW, tooltip = "Use a yellow Wintergrasp flash." },
    { key = "RED", label = settingsColorLabels.RED, tooltip = "Use a red Wintergrasp flash." },
}, 8, -140, 162, function(value)
    local settings = GetSettingsDB()
    settings.wgAlert1Color = value
end)
local wgAlert1SoundCheckbox, wgAlert1SoundLabel = CreateSettingsCheck(settingsScrollChild, "Play Sound", 8, -168, function(self)
    local settings = GetSettingsDB()
    settings.wgAlert1PlaySound = self:GetChecked() and true or false
end)
SetSimpleTooltip(wgAlert1SoundCheckbox, "Play Sound Alert", "Play a sound when the Registration Warning threshold is reached.")
local wgAlert1SoundChoiceLabel = CreateSettingsLabel(settingsScrollChild, "Select Sound", 8, -194)
local settingsWGAlert1SoundButtons = {}
CreateSettingsChoiceRow(settingsScrollChild, settingsWGAlert1SoundButtons, {
    { key = "RaidWarning", label = settingsSoundLabels.RaidWarning, tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = settingsSoundLabels.ReadyCheck, tooltip = "Play the Ready Check sound." },
}, 8, -210, 162, function(value)
    local settings = GetSettingsDB()
    settings.wgAlert1Sound = value
end)

-- [SETTINGS/WINTERGRASP] "Battle Start Warning" section + alert2 controls
local wgStartLabel = CreateSettingsLabel(settingsScrollChild, "Battle Start Warning", 8, -248)
local wgAlert2MinutesLabel, wgAlert2MinutesEdit = CreateSettingsEditRow(settingsScrollChild, "Minutes before start", 8, -276, 36, 3, function(self)
    local settings = GetSettingsDB()
    settings.wgAlert2Minutes = ClampNumber(self:GetText(), 1, 0, 120)
    self:SetText(tostring(settings.wgAlert2Minutes))
end)
SetSimpleTooltip(wgAlert2MinutesEdit, "Battle Start Warning", "Minutes before battle start to play the selected sound.")
local wgAlert2DurationLabel, wgAlert2DurationEdit = CreateSettingsEditRow(settingsScrollChild, "Flash duration", 8, -304, 36, 3, function(self)
    local settings = GetSettingsDB()
    settings.wgAlert2Duration = ClampNumber(self:GetText(), 0, 0, 30)
    self:SetText(tostring(settings.wgAlert2Duration))
end)
SetSimpleTooltip(wgAlert2DurationEdit, "Flash Duration", "How long the Battle Start Warning should flash. Set 0 for no flash.")
local wgAlert2ColorLabel = CreateSettingsLabel(settingsScrollChild, "Flash Color", 8, -332)
local settingsWGAlert2ColorButtons = {}
CreateSettingsChoiceRow(settingsScrollChild, settingsWGAlert2ColorButtons, {
    { key = "GREEN", label = settingsColorLabels.GREEN, tooltip = "Use a green flash." },
    { key = "YELLOW", label = settingsColorLabels.YELLOW, tooltip = "Use a yellow flash." },
    { key = "RED", label = settingsColorLabels.RED, tooltip = "Use a red flash." },
}, 8, -348, 162, function(value)
    local settings = GetSettingsDB()
    settings.wgAlert2Color = value
end)
local wgSoundCheckbox, wgSoundLabel = CreateSettingsCheck(settingsScrollChild, "Play Sound", 8, -376, function(self)
    local settings = GetSettingsDB()
    settings.wgAlert2PlaySound = self:GetChecked() and true or false
end)
SetSimpleTooltip(wgSoundCheckbox, "Play Sound Alert", "Play a sound when the Wintergrasp start threshold is reached.")
local wgSoundChoiceLabel = CreateSettingsLabel(settingsScrollChild, "Select Sound", 8, -402)
local settingsSoundButtons = {}
CreateSettingsChoiceRow(settingsScrollChild, settingsSoundButtons, {
    { key = "RaidWarning", label = settingsSoundLabels.RaidWarning, tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = settingsSoundLabels.ReadyCheck, tooltip = "Play the Ready Check sound." },
}, 8, -418, 162, function(value)
    local settings = GetSettingsDB()
    settings.wgAlert2Sound = value
end)

-- [SETTINGS/RANDOM] Enable checkbox for random alerts
local randomEnableCheckbox, randomEnableLabel = CreateSettingsCheck(settingsScrollChild, "Enable Random Alerts", 8, -8, function(self)
    local settings = GetSettingsDB()
    settings.randomAlertsEnabled = self:GetChecked() and true or false
end)
SetSimpleTooltip(randomEnableCheckbox, "Enable Random Alerts", "Fire the selected alert on a repeating timer.")

-- [SETTINGS/RANDOM] Interval edit — saves to active alert object
local randomIntervalLabel, randomIntervalEdit = CreateSettingsEditRow(settingsScrollChild, "How often (minutes)", 8, -40, 36, 3, function(self)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then
        alert.intervalMinutes = ClampNumber(self:GetText(), 5, 1, 999)
        self:SetText(tostring(alert.intervalMinutes))
    end
end)
SetSimpleTooltip(randomIntervalEdit, "How Often", "Fire an alert every this many minutes.")

-- [SETTINGS/RANDOM] Flash duration edit — saves to active alert object
local randomDurationLabel, randomDurationEdit = CreateSettingsEditRow(settingsScrollChild, "Flash duration", 8, -68, 36, 3, function(self)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then
        alert.flashDuration = ClampNumber(self:GetText(), 0, 0, 30)
        self:SetText(tostring(alert.flashDuration))
    end
end)
SetSimpleTooltip(randomDurationEdit, "Flash Duration", "How long to flash. Set 0 for no flash.")

-- [SETTINGS/RANDOM] Color choice row — saves to active alert object
local randomColorLabel = CreateSettingsLabel(settingsScrollChild, "Flash Color", 8, -96)
local settingsRandomColorButtons = {}
CreateSettingsChoiceRow(settingsScrollChild, settingsRandomColorButtons, {
    { key = "GREEN", label = settingsColorLabels.GREEN, tooltip = "Use a green flash." },
    { key = "YELLOW", label = settingsColorLabels.YELLOW, tooltip = "Use a yellow flash." },
    { key = "RED", label = settingsColorLabels.RED, tooltip = "Use a red flash." },
}, 8, -112, 162, function(value)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then alert.flashColor = value end
end)

-- [SETTINGS/RANDOM] Sound checkbox + sound choice row — saves to active alert object
local randomSoundCheckbox, randomSoundLabel = CreateSettingsCheck(settingsScrollChild, "Play Sound", 8, -140, function(self)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then alert.playSound = self:GetChecked() and true or false end
end)
SetSimpleTooltip(randomSoundCheckbox, "Play Sound", "Play a sound with each alert.")

local randomSoundChoiceLabel = CreateSettingsLabel(settingsScrollChild, "Select Sound", 8, -166)
local settingsRandomSoundButtons = {}
CreateSettingsChoiceRow(settingsScrollChild, settingsRandomSoundButtons, {
    { key = "RaidWarning", label = settingsSoundLabels.RaidWarning, tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = settingsSoundLabels.ReadyCheck, tooltip = "Play the Ready Check sound." },
}, 8, -182, 162, function(value)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then alert.sound = value end
end)

-- [SETTINGS] Save button anchored bottom-right of settings panel
settingsSaveButton = CreateFrame("Button", "DetaurBarSettingsSaveButton", settingsPanel, "UIPanelButtonTemplate")
settingsSaveButton:SetSize(72, 22)
settingsSaveButton:SetPoint("BOTTOMRIGHT", settingsPanel, "BOTTOMRIGHT", -8, 8)
settingsSaveButton:SetText("Save")
settingsSaveButton:SetScript("OnClick", function()
    if DetaurBar.UI and DetaurBar.UI.SaveSettings then
        DetaurBar.UI.SaveSettings()
    end
end)

-- [SETTINGS/HELPER] SetSettingsControlsVisible — show/hide a list of controls
local function SetSettingsControlsVisible(group, visible)
    for _, control in ipairs(group) do
        if visible then
            control:Show()
        else
            control:Hide()
        end
    end
end

-- [SETTINGS/CONTROLS] Dungeon sub-tab: enable checkbox, color buttons, duration edit
settingsDungeonControls = {
    dungeonEnableCheckbox, dungeonEnableLabel,
    dungeonColorLabel,
    dungeonDurationLabel, dungeonDurationEdit,
    settingsColorButtons.GREEN, settingsColorButtons.YELLOW, settingsColorButtons.RED,
}

-- [SETTINGS/CONTROLS] Wintergrasp sub-tab: enable checkbox, reg/start warnings, color/sound buttons
settingsWintergraspControls = {
    wgEnableCheckbox, wgEnableLabel,
    wgSectionLabel,
    wgAlert1MinutesLabel, wgAlert1MinutesEdit,
    wgAlert1DurationLabel, wgAlert1DurationEdit,
    wgAlert1ColorLabel,
    settingsWGColorButtons.GREEN, settingsWGColorButtons.YELLOW, settingsWGColorButtons.RED,
    wgAlert1SoundCheckbox, wgAlert1SoundLabel,
    wgAlert1SoundChoiceLabel,
    settingsWGAlert1SoundButtons.RaidWarning, settingsWGAlert1SoundButtons.ReadyCheck,
    wgStartLabel,
    wgAlert2MinutesLabel, wgAlert2MinutesEdit,
    wgAlert2DurationLabel, wgAlert2DurationEdit,
    wgAlert2ColorLabel,
    settingsWGAlert2ColorButtons.GREEN, settingsWGAlert2ColorButtons.YELLOW, settingsWGAlert2ColorButtons.RED,
    wgSoundCheckbox, wgSoundLabel,
    wgSoundChoiceLabel,
    settingsSoundButtons.RaidWarning, settingsSoundButtons.ReadyCheck,
}

-- [SETTINGS/RANDOM] Background frame for the random alerts list (randomListBackground)
local randomListBackground = CreateFrame("Frame", nil, settingsScrollChild)
randomListBackground:SetPoint("TOPLEFT", settingsScrollChild, "TOPLEFT", 6, -210)
randomListBackground:SetPoint("TOPRIGHT", settingsScrollChild, "TOPRIGHT", -6, -210)
randomListBackground:SetHeight(120)
randomListBackground:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
randomListBackground:SetBackdropColor(0, 0, 0, 0.6)
randomListBackground:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

-- [SETTINGS/RANDOM] Table of row buttons + UpdateRandomAlertRows function for the alert list
local randomAlertRows = {}

UpdateRandomAlertRows = function()
    local alerts = DetaurBar.Data.GetRandomAlerts()
    local activeAlert = DetaurBar.Data.GetRandomActiveAlert()

    for _, row in ipairs(randomAlertRows) do
        row:Hide()
    end

    for i, alert in ipairs(alerts) do
        local row = randomAlertRows[i]
        if not row then
            row = CreateFrame("Button", nil, randomListBackground)
            row:SetHeight(24)
            row:SetPoint("TOPLEFT", randomListBackground, "TOPLEFT", 4, -(4 + (i-1) * 26))
            row:SetPoint("TOPRIGHT", randomListBackground, "TOPRIGHT", -4, -(4 + (i-1) * 26))
            local rowBg = row:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints(row)
            rowBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
            rowBg:SetVertexColor(0, 0, 0, 0)
            row.bg = rowBg
            local rowLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rowLabel:SetPoint("LEFT", row, "LEFT", 6, 0)
            rowLabel:SetTextColor(1, 1, 1, 1)
            row.label = rowLabel
            row:SetScript("OnClick", function(self)
                DetaurBar.Data.SetRandomActiveAlert(self.alertId)
                if DetaurBar.Alerts and DetaurBar.Alerts.ResetAlertState then
                    DetaurBar.Alerts.ResetAlertState()
                end
                DetaurBar.UI.UpdateSettingsPanel()
            end)
            randomAlertRows[i] = row
        end
        row.alertId = alert.id
        row.label:SetText(alert.name)
        if activeAlert and alert.id == activeAlert.id then
            row.bg:SetVertexColor(0.18, 0.12, 0.02, 0.95)
            row.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
        else
            row.bg:SetVertexColor(0, 0, 0, 0)
            row.label:SetTextColor(1, 1, 1, 1)
        end
        row:Show()
    end
end

-- [SETTINGS/RANDOM] EditBox + Add button for creating a new alert
local randomAddEdit = CreateFrame("EditBox", nil, settingsScrollChild)
randomAddEdit:SetSize(120, 20)
randomAddEdit:SetAutoFocus(false)
randomAddEdit:SetTextInsets(4, 4, 0, 0)
randomAddEdit:SetFontObject("GameFontHighlightSmall")
randomAddEdit:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
randomAddEdit:SetBackdropColor(0, 0, 0, 0.8)
randomAddEdit:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
randomAddEdit:SetPoint("BOTTOMLEFT", randomListBackground, "BOTTOMLEFT", 4, -30)
randomAddEdit:SetFrameLevel(settingsScrollChild:GetFrameLevel() + 10)
randomAddEdit:SetMaxLetters(40)
randomAddEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
randomAddEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local randomAddButton = CreateFrame("Button", nil, settingsScrollChild, "UIPanelButtonTemplate")
randomAddButton:SetSize(50, 22)
randomAddButton:SetPoint("LEFT", randomAddEdit, "RIGHT", 6, 0)
randomAddButton:SetText("Add")
randomAddButton:SetScript("OnClick", function()
    local name = randomAddEdit:GetText()
    if name and name ~= "" then
        local alert = DetaurBar.Data.AddRandomAlert(name)
        DetaurBar.Data.SetRandomActiveAlert(alert.id)
        randomAddEdit:SetText("")
        if DetaurBar.Core and DetaurBar.Alerts.ResetAlertState then
            DetaurBar.Alerts.ResetAlertState()
        end
        DetaurBar.UI.UpdateSettingsPanel()
    end
end)

-- [SETTINGS/RANDOM] "Delete" button — removes active alert
local randomDeleteButton = CreateFrame("Button", nil, settingsScrollChild, "UIPanelButtonTemplate")
randomDeleteButton:SetSize(60, 22)
randomDeleteButton:SetPoint("LEFT", randomAddButton, "RIGHT", 4, 0)
randomDeleteButton:SetText("Delete")
randomDeleteButton:SetScript("OnClick", function()
    local active = DetaurBar.Data.GetRandomActiveAlert()
    if active then
        DetaurBar.Data.DeleteRandomAlert(active.id)
        if DetaurBar.Core and DetaurBar.Alerts.ResetAlertState then
            DetaurBar.Alerts.ResetAlertState()
        end
        DetaurBar.UI.UpdateSettingsPanel()
    end
end)

-- [SETTINGS/CONTROLS] Random sub-tab control list (settings controls + list bg + add/delete)
settingsRandomControls = {
    randomEnableCheckbox, randomEnableLabel,
    randomIntervalLabel, randomIntervalEdit,
    randomDurationLabel, randomDurationEdit,
    randomColorLabel,
    settingsRandomColorButtons.GREEN, settingsRandomColorButtons.YELLOW, settingsRandomColorButtons.RED,
    randomSoundCheckbox, randomSoundLabel,
    randomSoundChoiceLabel,
    settingsRandomSoundButtons.RaidWarning, settingsRandomSoundButtons.ReadyCheck,
    randomListBackground,
    randomAddEdit, randomAddButton, randomDeleteButton,
}

-- [SUB-TAB VISUALS] UpdateTodoSubTabVisuals — gold/dark + enable/disable for Day/Week/Month
UpdateTodoSubTabVisuals = function()
    for _, subTab in ipairs(todoSubTabs) do
        SetTodoSubTabStyle(subTab)
        if subTab.tabName == activeTodoSubTab then
            subTab:Disable()
        else
            subTab:Enable()
        end
    end
end

-- [SUB-TAB VISUALS] UpdateNotesSubTabVisuals — General/War/Guild style update
UpdateNotesSubTabVisuals = function()
    for _, subTab in ipairs(notesSubTabs) do
        SetNotesSubTabStyle(subTab)
        if subTab.tabName == activeNotesSubTab then
            subTab:Disable()
        else
            subTab:Enable()
        end
    end
end

-- [SUB-TAB VISUALS] UpdateLootSubTabVisuals — Add/Delete style update
UpdateLootSubTabVisuals = function()
    for _, subTab in ipairs(lootSubTabs) do
        SetLootSubTabStyle(subTab)
        if subTab.tabName == activeLootSubTab then
            subTab:Disable()
        else
            subTab:Enable()
        end
    end
end

-- [SUB-TAB VISUALS] UpdatePriceItemSubTabVisuals — Notifications/Chart style update
UpdatePriceItemSubTabVisuals = function()
    for _, subTab in ipairs(priceItemSubTabs) do
        SetPriceItemSubTabStyle(subTab)
        if subTab.tabName == activePriceItemSubTab then
            subTab:Disable()
        else
            subTab:Enable()
        end
    end
end

-- [LOOT] "Delete All Grays" checkbox — shown only when Loot > Delete is active
deleteAllGraysCheckbox = CreateFrame("CheckButton", "DetaurBarDeleteAllGrays", frame, "UICheckButtonTemplate")
deleteAllGraysCheckbox:SetSize(20, 20)
deleteAllGraysCheckbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -90)
deleteAllGraysCheckbox:Hide()
deleteAllGraysCheckbox:SetScript("OnClick", function(self)
    if DetaurBarDB and DetaurBarDB.loot then
        DetaurBarDB.loot.deleteAllGrays = self:GetChecked() and true or false
    end
end)
local deleteAllGraysLabel = deleteAllGraysCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
deleteAllGraysLabel:SetPoint("LEFT", deleteAllGraysCheckbox, "RIGHT", 4, 0)
deleteAllGraysLabel:SetText("Delete all grays")
deleteAllGraysLabel:SetTextColor(1, 0.82, 0, 1)

-- [MAIN SCROLL] ScrollFrame — main item list container
scrollFrame = CreateFrame("ScrollFrame", "DetaurBarScrollFrame", frame)
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -60)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 50)

-- [MAIN SCROLL] listBackground — dark panel frame behind scrollable items, receives drag-drop
local listBackground = CreateFrame("Frame", nil, frame)
listBackground:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", -4, 4)
listBackground:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 20, -4)
listBackground:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 12,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
listBackground:SetBackdropColor(0, 0, 0, 0.4)
listBackground:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
listBackground:EnableMouse(true)
listBackground:SetScript("OnReceiveDrag", OnReceiveDragHandler)

-- [MAIN SCROLL] Scroll child — actual parent frame for item rows
local scrollChild = CreateFrame("Frame", "DetaurBarScrollChild", scrollFrame)
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetWidth(scrollFrame:GetWidth())
scrollChild:SetHeight(1)

-- [MAIN SCROLL] Scroll bar slider with OnValueChanged
local scrollBar = CreateFrame("Slider", "DetaurBarScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
scrollBar:SetWidth(16)
scrollBar:SetValueStep(1)
scrollBar:SetMinMaxValues(0, 0)
scrollBar:SetValue(0)

scrollBar:SetScript("OnValueChanged", function(self, value)
    scrollFrame:SetVerticalScroll(value)
end)

scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = scrollBar:GetValue()
    scrollBar:SetValue(current - delta * 20)
end)

listBackground:EnableMouseWheel(true)
listBackground:SetScript("OnMouseWheel", function(self, delta)
    local current = scrollBar:GetValue()
    scrollBar:SetValue(current - delta * 20)
end)

-- Price Graph Panel (fixed bottom section, shown only on Price tab)
priceGraphPanel = CreateFrame("Frame", "DetaurBarPriceGraphPanel", frame)
priceGraphPanel:SetHeight(PRICE_GRAPH_PANEL_HEIGHT)
priceGraphPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 46)
priceGraphPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 46)
priceGraphPanel:Hide()

-- "Select an item" placeholder
local priceGraphHint = priceGraphPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
priceGraphHint:SetPoint("CENTER", priceGraphPanel, "CENTER", 0, 0)
priceGraphHint:SetText("Click an item above to view price history")
priceGraphPanel.hint = priceGraphHint

-- Price Sub-Tab Bar (Weekly / Monthly / Yearly), sits between list and graph
priceSubTabBar = CreateFrame("Frame", "DetaurBarPriceSubTabBar", frame)
priceSubTabBar:SetHeight(PRICE_SUBTAB_HEIGHT)
priceSubTabBar:SetPoint("BOTTOMLEFT", priceGraphPanel, "TOPLEFT", 0, 4)
priceSubTabBar:SetPoint("BOTTOMRIGHT", priceGraphPanel, "TOPRIGHT", 0, 4)
priceSubTabBar:Hide()

-- Price Threshold Row (shown only in "Chart" subtab, above time filter buttons)
priceThresholdRow = CreateFrame("Frame", "DetaurBarPriceThresholdRow", frame)
priceThresholdRow:SetHeight(PRICE_THRESHOLD_ROW_HEIGHT)
priceThresholdRow:SetPoint("BOTTOMLEFT", priceSubTabBar, "TOPLEFT", 0, 4)
priceThresholdRow:SetPoint("BOTTOMRIGHT", priceSubTabBar, "TOPRIGHT", 0, 4)
priceThresholdRow:Hide()
priceThresholdRow:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left=3, right=3, top=3, bottom=3 }
})
priceThresholdRow:SetBackdropColor(0.1, 0.1, 0.05, 0.95)
priceThresholdRow:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.8)

-- Selected item icon (same size as row item icons: 18x18)
local thresholdIcon = priceThresholdRow:CreateTexture(nil, "ARTWORK")
thresholdIcon:SetSize(18, 18)
thresholdIcon:SetPoint("LEFT", priceThresholdRow, "LEFT", 8, 0)
priceThresholdRow.icon = thresholdIcon

-- Selected item name (truncated to 11 chars, same font)
local thresholdName = priceThresholdRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
thresholdName:SetPoint("LEFT", thresholdIcon, "RIGHT", 6, 0)
thresholdName:SetTextColor(1.0, 0.82, 0.0, 1.0)
priceThresholdRow.name = thresholdName

-- Low threshold input (4 digits max)
local thresholdInput = CreateFrame("EditBox", "DetaurBarPriceThresholdInput", priceThresholdRow)
thresholdInput:SetSize(36, 20)
thresholdInput:SetPoint("LEFT", thresholdName, "RIGHT", 6, 0)
thresholdInput:SetAutoFocus(false)
thresholdInput:SetNumeric(true)
thresholdInput:SetMaxLetters(4)
thresholdInput:SetTextInsets(4, 4, 0, 0)
thresholdInput:SetFontObject("GameFontHighlightSmall")
thresholdInput:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
thresholdInput:SetBackdropColor(0, 0, 0, 0.8)
thresholdInput:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
thresholdInput:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    DetaurBar.UI.SavePriceThreshold()
end)
thresholdInput:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)
priceThresholdRow.input = thresholdInput

-- Gold icon after low input
local thresholdGoldIcon = thresholdInput:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
thresholdGoldIcon:SetPoint("LEFT", thresholdInput, "RIGHT", 4, 0)
thresholdGoldIcon:SetTextColor(1.0, 0.82, 0.0, 1.0)
thresholdGoldIcon:SetText("|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t")
priceThresholdRow.goldIcon = thresholdGoldIcon

-- High threshold input (4 digits max)
local thresholdInputHigh = CreateFrame("EditBox", "DetaurBarPriceThresholdInputHigh", priceThresholdRow)
thresholdInputHigh:SetSize(36, 20)
thresholdInputHigh:SetPoint("LEFT", thresholdGoldIcon, "RIGHT", 6, 0)
thresholdInputHigh:SetAutoFocus(false)
thresholdInputHigh:SetNumeric(true)
thresholdInputHigh:SetMaxLetters(4)
thresholdInputHigh:SetTextInsets(4, 4, 0, 0)
thresholdInputHigh:SetFontObject("GameFontHighlightSmall")
thresholdInputHigh:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
thresholdInputHigh:SetBackdropColor(0, 0, 0, 0.8)
thresholdInputHigh:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
thresholdInputHigh:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    DetaurBar.UI.SavePriceThreshold()
end)
thresholdInputHigh:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)
priceThresholdRow.inputHigh = thresholdInputHigh

-- Silver icon after high input
local thresholdSilverIcon = thresholdInputHigh:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
thresholdSilverIcon:SetPoint("LEFT", thresholdInputHigh, "RIGHT", 4, 0)
thresholdSilverIcon:SetTextColor(0.8, 0.8, 0.9, 1.0)
thresholdSilverIcon:SetText("|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t")
priceThresholdRow.silverIcon = thresholdSilverIcon

-- OK (checkmark) button — saves both thresholds
local thresholdOkBtn = CreateFrame("Button", nil, priceThresholdRow)
thresholdOkBtn:SetSize(16, 16)
thresholdOkBtn:SetPoint("RIGHT", priceThresholdRow, "RIGHT", -6, 0)
thresholdOkBtn:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check")
thresholdOkBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
thresholdOkBtn:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
thresholdOkBtn:SetScript("OnClick", function()
    DetaurBar.UI.SavePriceThreshold()
end)
thresholdOkBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Save Thresholds", 1.0, 1.0, 1.0)
    GameTooltip:Show()
end)
thresholdOkBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
priceThresholdRow.okBtn = thresholdOkBtn

-- Clear (X) button — clears both thresholds
local thresholdClearBtn = CreateFrame("Button", nil, priceThresholdRow)
thresholdClearBtn:SetSize(16, 16)
thresholdClearBtn:SetPoint("RIGHT", thresholdOkBtn, "LEFT", -4, 0)
thresholdClearBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
thresholdClearBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
thresholdClearBtn:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
thresholdClearBtn:SetScript("OnClick", function()
    DetaurBar.UI.ClearPriceThreshold()
end)
thresholdClearBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Clear Thresholds", 1.0, 1.0, 1.0)
    GameTooltip:Show()
end)
thresholdClearBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
priceThresholdRow.clearBtn = thresholdClearBtn

-- [PRICE/GRAPH] Divider line above graph panel
local priceGraphDivider = priceGraphPanel:CreateTexture(nil, "ARTWORK")
priceGraphDivider:SetHeight(1)
priceGraphDivider:SetPoint("TOPLEFT", priceGraphPanel, "TOPLEFT", 0, 0)
priceGraphDivider:SetPoint("TOPRIGHT", priceGraphPanel, "TOPRIGHT", 0, 0)
priceGraphDivider:SetTexture(0.4, 0.4, 0.4, 0.6)

-- [PRICE/SUB-TABS] 4 price sub-tab names + visual update function
local priceSubTabNames = { "Daily", "Weekly", "Monthly", "Yearly" }
local subTabGap = 4

-- [PRICE/SUB-TABS] UpdatePriceSubTabVisuals — gold/dark + enable/disable
UpdatePriceSubTabVisuals = function()
    for _, st in ipairs(priceSubTabObjects) do
        if st.tabName == activePriceSubTab then
            st:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
            st:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
            st.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
            st:Disable()
        else
            st:SetBackdropColor(0, 0, 0, 0.55)
            st:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
            st.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
            st:Enable()
        end
    end
end

-- [PRICE/SUB-TABS] Create 4 sub-tab buttons (Daily/Weekly/Monthly/Yearly)
for i, name in ipairs(priceSubTabNames) do
    local st = CreateFrame("Button", "DetaurBarPriceSubTab_" .. name, priceSubTabBar)
    st:SetHeight(PRICE_SUBTAB_HEIGHT)
    st:SetFrameLevel(frame:GetFrameLevel() + 6)
    st:EnableMouse(true)
    st.tabName = name
    st:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left=3, right=3, top=3, bottom=3 }
    })
    st:SetBackdropColor(0, 0, 0, 0.55)
    st:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

    local lbl = st:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("CENTER", st, "CENTER", 0, 0)
    lbl:SetText(name)
    st.label = lbl

    local hi = st:CreateTexture(nil, "HIGHLIGHT")
    hi:SetAllPoints(st)
    hi:SetTexture(1.0, 0.82, 0.0, 0.12)

    st:SetScript("OnClick", function()
        activePriceSubTab = name
        UpdatePriceSubTabVisuals()
        DetaurBar.UI.RefreshTasks()
    end)

    priceSubTabObjects[i] = st
end

-- [PRICE/SUB-TABS] LayoutPriceSubTabs — positions sub-tabs dynamically
local function LayoutPriceSubTabs()
    local totalW = priceSubTabBar:GetWidth()
    if totalW <= 0 then return end
    local n = #priceSubTabObjects
    local w = (totalW - subTabGap * (n - 1)) / n
    for i, st in ipairs(priceSubTabObjects) do
        st:SetWidth(w)
        st:ClearAllPoints()
        if i == 1 then
            st:SetPoint("TOPLEFT", priceSubTabBar, "TOPLEFT", 0, 0)
        else
            st:SetPoint("LEFT", priceSubTabObjects[i-1], "RIGHT", subTabGap, 0)
        end
    end
end

priceSubTabBar:SetScript("OnSizeChanged", LayoutPriceSubTabs)

-- [ROW POOL] Constants and pool table for item rows
local rowPool = {}
local rowHeight = 28
local rowSpacing = 4
local GRAPH_HEIGHT = 90
local GRAPH_PAD_L = 46
local GRAPH_PAD_R = 8
local GRAPH_PAD_T = 8
local GRAPH_PAD_B = 20

-- [HELPERS] FormatMoney — converts copper to gold/silver/copper coin texture string
local function FormatMoney(amount)
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local copper = amount % 100
    
    local str = ""
    if gold > 0 then
        str = str .. gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t "
    end
    if silver > 0 or gold > 0 then
        str = str .. silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "
    end
    str = str .. copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
    return str
end

-- [GRAPH HELPERS] ClearGraphObjects — hides all textures/labels/frames for a row graph
local function ClearGraphObjects(row)
    if row.graphTextures then
        for _, t in ipairs(row.graphTextures) do t:Hide() end
    end
    if row.graphLabels then
        for _, f in ipairs(row.graphLabels) do f:Hide() end
    end
    if row.graphFrames then
        for _, fr in ipairs(row.graphFrames) do fr:Hide() end
    end
    row.graphTextures = {}
    row.graphLabels = {}
    row.graphFrames = {}
end

-- [GRAPH HELPERS] GfTex — create and track a graph texture
local function GfTex(row, gf, layer)
    local t = gf:CreateTexture(nil, layer or "OVERLAY")
    table.insert(row.graphTextures, t)
    return t
end

-- [GRAPH HELPERS] GfLabel — create and track a graph label font string
local function GfLabel(row, gf)
    local f = gf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    table.insert(row.graphLabels, f)
    return f
end

-- [GRAPH HELPERS] GfFrame — create and track a graph hover frame
local function GfFrame(row, gf)
    if not row.graphFrames then
        row.graphFrames = {}
    end
    local f = CreateFrame("Frame", nil, gf)
    table.insert(row.graphFrames, f)
    return f
end

-- [GRAPH HELPERS] DrawGfLine — dot-stepping line renderer (SetRotation doesn't work in 3.3.5a)
local function DrawGfLine(row, gf, x1, y1, x2, y2, thick, r, g, b, a)
    local dx, dy = x2 - x1, y2 - y1
    local steps = math.floor(math.max(math.abs(dx), math.abs(dy)))
    if steps < 1 then steps = 1 end
    local sx, sy = dx / steps, dy / steps
    for i = 0, steps do
        local t = GfTex(row, gf)
        t:SetTexture(r, g, b, a)
        t:SetSize(thick, thick)
        t:SetPoint("CENTER", gf, "BOTTOMLEFT", x1 + sx * i, y1 + sy * i)
        t:Show()
    end
end

-- [FORMAT] FormatGold — copper to compact "g s" string for graph labels
local function FormatGold(copper)
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    if g > 0 then return g .. "g " .. s .. "s" end
    if s > 0 then return s .. "s " .. (copper % 100) .. "c" end
    return (copper % 100) .. "c"
end

-- [GRAPH] DrawPriceGraph — renders full graph for a given itemId on the graph frame
local function DrawPriceGraph(row, gf, itemId)
    ClearGraphObjects(row)

    local history = DetaurBar.Data.GetPriceHistory(itemId)
    local now = time()
    local cutoff
    if activePriceSubTab == "Daily" then
        cutoff = now - 86400
    elseif activePriceSubTab == "Weekly" then
        cutoff = now - 7 * 86400
    elseif activePriceSubTab == "Monthly" then
        cutoff = now - 30 * 86400
    else -- Yearly
        cutoff = now - 365 * 86400
    end

    local points = {}
    for tsStr, price in pairs(history) do
        local ts = tonumber(tsStr)
        if ts and ts >= cutoff then
            table.insert(points, { ts = ts, price = price })
        end
    end
    table.sort(points, function(a, b) return a.ts < b.ts end)

    local gw = gf:GetWidth()
    local gh = gf:GetHeight()
    local plotW = gw - GRAPH_PAD_L - GRAPH_PAD_R
    local plotH = gh - GRAPH_PAD_T - GRAPH_PAD_B

    -- background
    local bg = GfTex(row, gf, "BACKGROUND")
    bg:SetAllPoints(gf)
    bg:SetTexture(0, 0, 0, 0.5)
    bg:Show()

    -- axes
    DrawGfLine(row, gf, GRAPH_PAD_L, GRAPH_PAD_B, GRAPH_PAD_L, GRAPH_PAD_B + plotH, 1, 0.5, 0.5, 0.5, 1)
    DrawGfLine(row, gf, GRAPH_PAD_L, GRAPH_PAD_B, GRAPH_PAD_L + plotW, GRAPH_PAD_B, 1, 0.5, 0.5, 0.5, 1)

    if #points == 0 then
        local lbl = GfLabel(row, gf)
        lbl:SetPoint("CENTER", gf, "CENTER", 0, 0)
        lbl:SetText("No data yet — open the Auction House to scan")
        lbl:SetTextColor(0.5, 0.5, 0.5, 1)
        lbl:Show()
        return
    end

    local minP, maxP = points[1].price, points[1].price
    local minTs, maxTs = points[1].ts, points[#points].ts
    for _, p in ipairs(points) do
        if p.price < minP then minP = p.price end
        if p.price > maxP then maxP = p.price end
    end
    local pRange = maxP - minP
    if pRange == 0 then pRange = math.max(maxP * 0.1, 1) end
    local dMin = math.max(0, minP - pRange * 0.1)
    local dMax = maxP + pRange * 0.1
    local dRange = dMax - dMin
    local tsRange = math.max(maxTs - minTs, 1)

    local function toX(ts)
        if maxTs == minTs then return GRAPH_PAD_L + plotW / 2 end
        return GRAPH_PAD_L + (ts - minTs) / tsRange * plotW
    end
    local function toY(price)
        return GRAPH_PAD_B + (price - dMin) / dRange * plotH
    end

    -- Y axis labels (top, mid, bottom)
    for i = 0, 2 do
        local price = dMin + dRange * i / 2
        local y = GRAPH_PAD_B + plotH * i / 2
        DrawGfLine(row, gf, GRAPH_PAD_L, y, GRAPH_PAD_L + plotW, y, 1, 0.25, 0.25, 0.25, 0.6)
        local lbl = GfLabel(row, gf)
        lbl:SetPoint("RIGHT", gf, "BOTTOMLEFT", GRAPH_PAD_L - 2, y)
        lbl:SetText(FormatGold(math.floor(price)))
        lbl:SetTextColor(0.65, 0.65, 0.65, 1)
        lbl:Show()
    end

    -- X axis labels: 3 evenly spaced across the time range (not tied to data points)
    local fmt = (activePriceSubTab == "Daily") and "%H:%M" or "%d/%m"
    for i = 0, 2 do
        local ts = minTs + tsRange * i / 2
        local x = GRAPH_PAD_L + plotW * i / 2
        local lbl = GfLabel(row, gf)
        lbl:SetPoint("TOP", gf, "BOTTOMLEFT", x, GRAPH_PAD_B - 2)
        lbl:SetText(date(fmt, math.floor(ts)))
        lbl:SetTextColor(0.55, 0.55, 0.55, 1)
        lbl:Show()
    end

    -- Lines and dots
    local prevX, prevY
    for _, p in ipairs(points) do
        local x, y = toX(p.ts), toY(p.price)
        if prevX then
            DrawGfLine(row, gf, prevX, prevY, x, y, 1.5, 1.0, 0.82, 0.0, 0.9)
        end
        local dot = GfTex(row, gf)
        dot:SetTexture(1, 1, 1, 1)
        dot:SetSize(5, 5)
        dot:SetPoint("CENTER", gf, "BOTTOMLEFT", x, y)
        dot:Show()

        -- Interactive hover frame for tooltip and hover animation
        local hover = GfFrame(row, gf)
        hover:SetSize(16, 16)
        hover:SetPoint("CENTER", gf, "BOTTOMLEFT", x, y)
        hover:EnableMouse(true)
        hover:SetScript("OnEnter", function(self)
            dot:SetSize(8, 8)
            dot:SetTexture(1, 0.82, 0, 1)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(date("%d.%m.%Y %H:%M", p.ts), 1.0, 0.82, 0.0)
            GameTooltip:AddLine(FormatMoney(p.price), 1.0, 1.0, 1.0)
            GameTooltip:Show()
        end)
        hover:SetScript("OnLeave", function(self)
            dot:SetSize(5, 5)
            dot:SetTexture(1, 1, 1, 1)
            GameTooltip:Hide()
        end)

        prevX, prevY = x, y
    end
end

-- [ROW FACTORY] CreateRowFrame — builds a pooled row frame with all child controls
local function CreateRowFrame(index)
    local row = CreateFrame("Frame", "DetaurBarRow_" .. index, scrollChild)
    row:SetHeight(rowHeight)
    row:EnableMouse(true) -- CRITICAL: Allows mouse events (Shift-click, hovers) to trigger on the row
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        scrollBar:SetValue(current - delta * 20)
    end)
    row:RegisterForDrag("LeftButton")
    
    -- Row hover background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetTexture(0, 0, 0, 0)
    row.bg = bg
    
    -- Checkbox Button
    local checkbox = CreateFrame("CheckButton", nil, row)
    checkbox:SetSize(20, 20)
    checkbox:SetPoint("LEFT", row, "LEFT", 6, 0)
    checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkbox:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
    row.checkbox = checkbox
    
    -- Item Icon (for Loot/Sell categories)
    local itemIcon = row:CreateTexture(nil, "ARTWORK")
    itemIcon:SetSize(18, 18)
    itemIcon:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.itemIcon = itemIcon
    
    -- Delete Button ('X')
    local deleteBtn = CreateFrame("Button", nil, row)
    deleteBtn:SetSize(14, 14)
    deleteBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    deleteBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    deleteBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
    deleteBtn:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
    row.deleteBtn = deleteBtn
    
    -- Swap Button (Arrow button next to delete button)
    local swapBtn = CreateFrame("Button", nil, row)
    swapBtn:SetSize(14, 14)
    swapBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -4, 0)
    row.swapBtn = swapBtn
    
    -- Copy/Duplicate Button (next to delete button, identical positioning as swapBtn since they are mutually exclusive)
    local copyBtn = CreateFrame("Button", nil, row)
    copyBtn:SetSize(14, 14)
    copyBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -4, 0)
    copyBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    copyBtn:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Down")
    copyBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    row.copyBtn = copyBtn
    
    -- Graph frame (Price tab inline graph)
    local graphFrame = CreateFrame("Frame", nil, row)
    graphFrame:SetHeight(GRAPH_HEIGHT)
    graphFrame:Hide()
    row.graphFrame = graphFrame
    row.graphTextures = {}
    row.graphLabels = {}
    row.graphFrames = {}

    -- Title Text Label (WoW Highlight font - White by default)
    local titleText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleText:SetJustifyH("LEFT") -- Force left-alignment
    titleText:SetNonSpaceWrap(true) -- Allow breaking long words/URLs if required
    row.titleText = titleText
    
    -- Handle Shift-click on item row to link it to active chat frame, or click on notes to copy
    row:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            if IsShiftKeyDown() then
                if row.itemCategory == "loot_add" or row.itemCategory == "loot_delete" or row.itemCategory == "sell" or row.itemCategory == "price" then
                    local itemDetail = DetaurBar.Data.GetItemById(row.itemCategory, self.itemId)
                    if itemDetail and itemDetail.title then
                        local itemLink = GetUsableItemLink(itemDetail.title)
                        if itemLink then
                            HandleModifiedItemClick(itemLink)
                        end
                    end
                end
            else
                if row.itemCategory == "price" then
                    if expandedPriceItemId == self.itemId then
                        expandedPriceItemId = nil
                    else
                        expandedPriceItemId = self.itemId
                    end
                    -- Also select for threshold row in "Chart" subtab
        if activePriceItemSubTab == "Chart" then
                        DetaurBar.UI.SetSelectedPriceItem(self.itemId)
                    end
                    DetaurBar.UI.RefreshTasks()
                end
            end
        end
    end)

    row:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and not draggedNote then
            if row.itemCategory and row.itemCategory:find("notes_") then
                local note = DetaurBar.Data.GetItemById(row.itemCategory, self.itemId)
                if note and note.title then
                    local editBox = ChatEdit_ChooseBoxForSend()
                    if editBox and editBox:IsShown() then
                        editBox:Insert(note.title)
                    else
                        ChatFrame_OpenChat(note.title)
                    end
                end
            end
        end
    end)
    
    -- Scripts & Interactions
    row:SetScript("OnEnter", function(self)
        self.bg:SetTexture(1.0, 0.82, 0.0, 0.1) -- Subtle gold highlight on hover
        
        -- GameTooltip hover support for item linking categories (Loot/Sell/Price)
        if row.itemCategory == "loot_add" or row.itemCategory == "loot_delete" or row.itemCategory == "sell" or row.itemCategory == "price" then
            local itemDetail = DetaurBar.Data.GetItemById(row.itemCategory, self.itemId)
            if itemDetail and itemDetail.title then
                local itemLink = GetUsableItemLink(itemDetail.title)
                if itemLink then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    local itemId = GetItemIdFromText(itemDetail.title)
                    -- Najprv skus server (ak je item v cache klienta, ukaze plny tooltip)
                    local _, serverLink, _, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(itemId or itemDetail.title)
                    if serverLink then
                        GameTooltip:SetHyperlink(serverLink)
                        if itemSellPrice and itemSellPrice > 0 then
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddDoubleLine("Sell Price:", FormatMoney(itemSellPrice), 1.0, 0.82, 0.0, 1.0, 1.0, 1.0)
                        end
                    else
                        -- Offline fallback: server nema item v cache
                        local itemName = GetOfflineItemNameById(itemId)
                        if itemName then
                            GameTooltip:ClearLines()
                            GameTooltip:AddLine(itemName, 1.0, 1.0, 1.0)
                            GameTooltip:AddLine("Offline item data", 0.5, 0.5, 0.5)
                            GameTooltip:AddLine("ID: " .. (itemId or "unknown"), 0.7, 0.7, 0.7)
                        else
                            GameTooltip:SetHyperlink(itemLink)
                        end
                    end
                    GameTooltip:Show()
                end
            end
        elseif row.itemCategory and row.itemCategory:find("notes_") then
            local note = DetaurBar.Data.GetItemById(row.itemCategory, self.itemId)
            if note and note.title then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine("Copy Note to Chat", 1.0, 1.0, 1.0)
                GameTooltip:AddLine("Click anywhere on this note to copy its text to the chat window.", 0.5, 0.5, 0.5)
                GameTooltip:Show()
            end
        end
    end)
    
    row:SetScript("OnLeave", function(self)
        self.bg:SetTexture(0, 0, 0, 0)
        GameTooltip:Hide()
    end)

    row:SetScript("OnDragStart", function(self)
        if self.itemId and self.itemCategory and self.itemCategory:find("notes_") then
            StartDraggedNote(self.itemCategory, self.itemId)
            self.bg:SetTexture(1.0, 0.82, 0.0, 0.18)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Move Note", 1.0, 1.0, 1.0)
            GameTooltip:AddLine("Drop this note on General, War, or Guild.", 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end
    end)
    
    checkbox:SetScript("OnClick", function(self)
        if row.itemId and row.itemCategory then
            DetaurBar.Data.ToggleTask(row.itemCategory, row.itemId)
            DetaurBar.UI.RefreshTasks()
        end
    end)
    
    deleteBtn:SetScript("OnClick", function(self)
        if row.itemId and row.itemCategory then
            if row.itemCategory == "price" and activePriceItemSubTab == "Notifications" then
                local item = DetaurBar.Data.GetItemById("price", row.itemId)
                if item then
                    if row.notifType ~= "high" then
                        item.frequent = nil
                        item.threshold = nil
                    end
                    if row.notifType ~= "low" then
                        item.frequentHigh = nil
                        item.thresholdHigh = nil
                    end
                end
                if expandedPriceItemId == row.itemId then
                    expandedPriceItemId = nil
                end
            else
                DetaurBar.Data.DeleteItem(row.itemCategory, row.itemId)
                if row.itemCategory == "price" and expandedPriceItemId == row.itemId then
                    expandedPriceItemId = nil
                end
            end
            DetaurBar.UI.RefreshTasks()
        end
    end)
    
    swapBtn:SetScript("OnClick", function(self)
        if row.itemId and row.itemCategory == "loot_add" then
            local item = DetaurBar.Data.GetItemById(row.itemCategory, row.itemId)
            if item then
                DetaurBar.Data.AddItem("price", item.title)
                DetaurBar.UI.RefreshTasks()
            end
        elseif row.itemId and row.itemCategory == "price" then
            DetaurBar.UI.SelectPriceItemSubTab("Chart")
            DetaurBar.UI.SetSelectedPriceItem(row.itemId)
            DetaurBar.UI.RefreshTasks()
        end
    end)

    swapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        if row.itemCategory == "price" then
            GameTooltip:AddLine("Set Price Threshold", 1.0, 1.0, 1.0)
            GameTooltip:AddLine("Click to set target price for alerts.", 0.5, 0.5, 0.5)
        else
            GameTooltip:AddLine("Copy to Price List", 1.0, 1.0, 1.0)
            GameTooltip:AddLine("Item stays in Loot list.", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    
    swapBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    copyBtn:SetScript("OnClick", function(self)
        if row.itemId and row.itemCategory and row.itemCategory:find("notes_") then
            local note = DetaurBar.Data.GetItemById(row.itemCategory, row.itemId)
            if note and note.title then
                local editBox = ChatEdit_ChooseBoxForSend()
                if editBox and editBox:IsShown() then
                    editBox:Insert(note.title)
                else
                    ChatFrame_OpenChat(note.title)
                end
            end
        end
    end)
    
    copyBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Copy Note to Chat", 1.0, 1.0, 1.0)
        GameTooltip:AddLine("Click to copy this note's text into the chat window.", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    
    copyBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    row:SetScript("OnReceiveDrag", OnReceiveDragHandler)
    
    return row
end

-- [REFRESH] DetaurBar.UI.RefreshTasks — main render loop: rebuilds the visible row list
function DetaurBar.UI.RefreshTasks()
    if activeTab == "Settings" then
        return
    end

    local category = activeTab:lower()
    if category == "todo" then
        category = "todo_" .. activeTodoSubTab:lower()
    elseif category == "notes" then
        category = "notes_" .. activeNotesSubTab:lower()
    elseif category == "loot" then
        category = "loot_" .. activeLootSubTab:lower()
        if DetaurBar.Core and DetaurBar.Core.UpdateAutoLootCVar then
            DetaurBar.Core.UpdateAutoLootCVar()
        end
    end
    local items = DetaurBar.Data.GetItems(category)
    if category == "price" and activePriceItemSubTab == "Notifications" then
        local lowItems = {}
        local highItems = {}
        for _, item in ipairs(items) do
            if item.frequent then
                table.insert(lowItems, item)
            end
            if item.frequentHigh then
                table.insert(highItems, item)
            end
        end
        local combined = {}
        if #lowItems > 0 then
            table.insert(combined, { isHeader = true, title = "Low price" })
            for _, item in ipairs(lowItems) do
                table.insert(combined, item)
            end
        end
        if #highItems > 0 then
            table.insert(combined, { isHeader = true, title = "High price" })
            for _, item in ipairs(highItems) do
                table.insert(combined, item)
            end
        end
        if #combined == 0 then
            table.insert(combined, { isHeader = true, title = "No alerts" })
        end
        items = combined
    end
    
    for _, row in ipairs(rowPool) do
        row:Hide()
    end
    
    local width = scrollFrame:GetWidth()
    scrollChild:SetWidth(width)
    
    local totalHeight = 0
    local currentNotifSection = nil
    
    for i, item in ipairs(items) do
        local row = rowPool[i]
        if not row then
            row = CreateRowFrame(i)
            table.insert(rowPool, i, row)
        end
        
        row.itemId = item.id
        row.itemCategory = category
        row.notifType = nil
        
        -- Clear prior points to allow layout realignment
        row.titleText:ClearAllPoints()
        
        local textWidth = width - 65
        
        -- Track notification section for dual-section delete behavior
        if category == "price" and activePriceItemSubTab == "Notifications" then
            if item.isHeader and item.title == "Low price" then
                currentNotifSection = "low"
            elseif item.isHeader and item.title == "High price" then
                currentNotifSection = "high"
            end
            row.notifType = (item.isHeader and nil or currentNotifSection)
        end
        
        -- Dynamic layout configuration based on active category
        if item.isHeader then
            row.checkbox:Hide()
            row.itemIcon:Hide()
            row.swapBtn:Hide()
            row.copyBtn:Hide()
            row.deleteBtn:Hide()
            row:SetHeight(22)
            row.titleText:SetPoint("LEFT", row, "LEFT", 10, 0)
            row.titleText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            row.titleText:SetText(item.title)
            row.titleText:SetTextColor(1.0, 0.82, 0.0, 1.0)
        elseif category:find("todo_") then
            row.checkbox:Show()
            row.itemIcon:Hide()
            row.swapBtn:Hide()
            row.copyBtn:Hide()
            row.checkbox:SetChecked(item.completed and 1 or nil)
            
            row.titleText:SetPoint("LEFT", row.checkbox, "RIGHT", 8, 0)
            row.titleText:SetPoint("RIGHT", row.deleteBtn, "LEFT", -8, 0)
            row.titleText:SetText(item.title)
            
            if item.completed then
                row.titleText:SetTextColor(0.5, 0.5, 0.5, 0.7) -- Completed is muted grey
            else
                row.titleText:SetTextColor(1.0, 1.0, 1.0, 1.0) -- Active task is white
            end
            
        elseif category:find("notes_") then
            row.checkbox:Hide()
            row.itemIcon:Hide()
            row.swapBtn:Hide()
            row.copyBtn:Show()
            
            textWidth = width - 60
            row.titleText:SetPoint("LEFT", row, "LEFT", 8, 0)
            row.titleText:SetPoint("RIGHT", row.copyBtn, "LEFT", -8, 0)
            row.titleText:SetText(item.title)
            row.titleText:SetTextColor(1.0, 1.0, 1.0, 1.0) -- Notes are white
            
        elseif category == "price" then
            row.checkbox:Hide()
            row.copyBtn:Hide()
            row.deleteBtn:Show()

            -- Notifications subtab: simple display with current price
            if activePriceItemSubTab == "Notifications" then
                row.swapBtn:Hide()
                
                local itemName, itemTexture, itemRarity
                local itemId = GetItemIdFromText(item.title)
                if itemId then
                    itemName = GetOfflineItemNameById(itemId)
                    if not itemName then
                        itemName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
                    else
                        itemRarity = 1
                        if DetaurBar.Data.ItemIcons and DetaurBar.Data.ItemIcons[itemId] then
                            itemTexture = DetaurBar.Data.ItemIcons[itemId]
                        end
                        if not itemTexture then
                            local _, _, sr, _, _, _, _, _, _, st = GetItemInfo(itemId)
                            itemTexture = st
                            if sr then itemRarity = sr end
                        end
                    end
                end
                
                -- Get current price from history (latest)
                local priceText = "0g"
                local priceCopper = 0
                if itemId then
                    local history = DetaurBar.Data.GetPriceHistory(itemId)
                    if history then
                        local latestPrice = 0
                        local latestTime = 0
                        for tsStr, price in pairs(history) do
                            local ts = tonumber(tsStr)
                            if ts and ts > latestTime then
                                latestTime = ts
                                latestPrice = price
                            end
                        end
                        if latestPrice > 0 then
                            priceCopper = latestPrice
                            local gold = math.floor(priceCopper / 10000)
                            local silver = math.floor((priceCopper % 10000) / 100)
                            if gold > 0 then
                                priceText = gold .. "g"
                            elseif silver > 0 then
                                priceText = silver .. "s"
                            else
                                priceText = (priceCopper % 100) .. "c"
                            end
                        end
                    end
                end
                
                if itemName and itemTexture then
                    row.itemIcon:SetTexture(itemTexture)
                    row.itemIcon:Show()
                    textWidth = width - 120
                    row.titleText:SetPoint("LEFT", row.itemIcon, "RIGHT", 8, 0)
                    row.titleText:SetPoint("RIGHT", row.deleteBtn, "LEFT", -8, 0)
                    row.titleText:SetText(itemName .. "  |cffffd700" .. priceText .. "|r")
                    local r, g, b = GetItemQualityColor(itemRarity or 1)
                    row.titleText:SetTextColor(r, g, b, 1.0)
                else
                    row.itemIcon:Hide()
                    textWidth = width - 60
                    row.titleText:SetPoint("LEFT", row, "LEFT", 8, 0)
                    row.titleText:SetPoint("RIGHT", row.deleteBtn, "LEFT", -8, 0)
                    if itemId then
                        GetItemInfo(itemId)
                        local offlineLink = BuildOfflineItemLink(itemId)
                        if offlineLink then
                            row.titleText:SetText(offlineLink .. "  |cffffd700" .. priceText .. "|r")
                            row.titleText:SetTextColor(1, 1, 1, 1)
                        else
                            row.titleText:SetText("Loading [ID: " .. itemId .. "]...  |cffffd700" .. priceText .. "|r")
                            row.titleText:SetTextColor(0.6, 0.6, 0.6, 1)
                        end
                    else
                        row.titleText:SetText(item.title .. "  |cffffd700" .. priceText .. "|r")
                        row.titleText:SetTextColor(1, 1, 1, 1)
                    end
                end
            else
                -- Chart subtab: no swap button, click row to select for threshold
                row.swapBtn:Hide()

                local itemName, itemTexture, itemRarity
                local itemId = GetItemIdFromText(item.title)
                if itemId then
                    itemName = GetOfflineItemNameById(itemId)
                    if not itemName then
                        itemName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
                    else
                        itemRarity = 1
                        if DetaurBar.Data.ItemIcons and DetaurBar.Data.ItemIcons[itemId] then
                            itemTexture = DetaurBar.Data.ItemIcons[itemId]
                        end
                        if not itemTexture then
                            local _, _, sr, _, _, _, _, _, _, st = GetItemInfo(itemId)
                            itemTexture = st
                            if sr then itemRarity = sr end
                        end
                    end
                end

                local rightAnchor = row.deleteBtn
                local rightOffset = -8

                -- Check for manual thresholds
                local thresholdText = ""
                local thresholdHighText = ""
                if itemId and item.threshold and item.threshold > 0 then
                    thresholdText = "  |cffffd700[" .. item.threshold .. "g]|r"
                end
                if itemId and item.thresholdHigh and item.thresholdHigh > 0 then
                    thresholdHighText = " |cffff8000[" .. item.thresholdHigh .. "g]|r"
                end

                if itemName and itemTexture then
                    row.itemIcon:SetTexture(itemTexture)
                    row.itemIcon:Show()
                    textWidth = width - 80
                    row.titleText:SetPoint("LEFT", row.itemIcon, "RIGHT", 8, 0)
                    row.titleText:SetPoint("RIGHT", rightAnchor, "LEFT", rightOffset, 0)
                    row.titleText:SetText(itemName .. thresholdText .. thresholdHighText)
                    local r, g, b = GetItemQualityColor(itemRarity or 1)
                    row.titleText:SetTextColor(r, g, b, 1.0)
                else
                    row.itemIcon:Hide()
                    textWidth = width - 80
                    row.titleText:SetPoint("LEFT", row, "LEFT", 8, 0)
                    row.titleText:SetPoint("RIGHT", rightAnchor, "LEFT", rightOffset, 0)
                    if itemId then
                        GetItemInfo(itemId)
                        local offlineLink = BuildOfflineItemLink(itemId)
                        if offlineLink then
                            row.titleText:SetText(offlineLink .. thresholdText .. thresholdHighText)
                            row.titleText:SetTextColor(1, 1, 1, 1)
                        else
                            row.titleText:SetText("Loading [ID: " .. itemId .. "]..." .. thresholdText .. thresholdHighText)
                            row.titleText:SetTextColor(0.6, 0.6, 0.6, 1)
                        end
                    else
                        row.titleText:SetText(item.title .. thresholdText .. thresholdHighText)
                        row.titleText:SetTextColor(1, 1, 1, 1)
                    end
                end
            end

        elseif category == "loot_add" or category == "loot_delete" or category == "sell" then
            row.checkbox:Hide()
            row.copyBtn:Hide()

            -- Swap button: Add=copy to Price, Refuse=move to Delete, Delete=hidden
            if category == "loot_add" then
                row.swapBtn:Show()
                row.swapBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
                row.swapBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
                row.swapBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
            else
                row.swapBtn:Hide()
            end
            
            -- Query item cache to pull exact name, icon texture, and color code by rarity quality
            local itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture
            local itemId = GetItemIdFromText(item.title)
            
            if itemId then
                -- Najprv pouzivaj OFFLINE databazu (ignoruje serverove GetItemInfo)
                itemName = GetOfflineItemNameById(itemId)
                itemLink = BuildOfflineItemLink(itemId)
                
                -- Ak offline databaza nema nazov, skus server
                if not itemName then
                    itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
                    if not itemLink then
                        itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo("item:" .. itemId)
                    end
                    -- Ak sa pouzilo server, skus ziskat ikonku
                    if not itemTexture and GetItemIcon then
                        itemTexture = GetItemIcon(itemId)
                    end
                else
                    itemRarity = itemRarity or 1
                    if DetaurBar.Data.ItemIcons and DetaurBar.Data.ItemIcons[itemId] then
                        itemTexture = DetaurBar.Data.ItemIcons[itemId]
                    end
                    -- Ak offline ikona chyba, skus server
                    if not itemTexture then
                        local _, _, serverRarity, _, _, _, _, _, _, serverTexture = GetItemInfo(itemId)
                        itemTexture = serverTexture
                        if serverRarity then itemRarity = serverRarity end
                    end
                end
            else
                itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(item.title)
                if not itemLink then
                    local capped = item.title:gsub("(%a)([%w_']*)", function(f, r) return f:upper() .. r:lower() end)
                    itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(capped)
                end
                -- Ak sme nasli link, konvertuj ulozeny title na item:ID
                -- Dalsi refresh uz pujde cez ID cestu (server request, ikona, tooltip)
                if itemLink then
                    local foundId = itemLink:match("item:(%d+)")
                    if foundId then
                        item.title = "item:" .. foundId
                    end
                end
            end
            
            local isLoot = (category == "loot_add")
            local rightAnchor = isLoot and row.swapBtn or row.deleteBtn
            local rightOffset = -8

            if itemName and itemTexture then
                row.itemIcon:SetTexture(itemTexture)
                row.itemIcon:Show()

                textWidth = width - 80
                row.titleText:SetPoint("LEFT", row.itemIcon, "RIGHT", 8, 0)
                row.titleText:SetPoint("RIGHT", rightAnchor, "LEFT", rightOffset, 0)
                row.titleText:SetText(itemName)

                -- Zabezpec, ze itemRarity nie je nil (default = Common = 1)
                itemRarity = itemRarity or 1
                local r, g, b = GetItemQualityColor(itemRarity)
                row.titleText:SetTextColor(r, g, b, 1.0)
            else
                row.itemIcon:Hide()

                textWidth = width - 60
                row.titleText:SetPoint("LEFT", row, "LEFT", 8, 0)
                row.titleText:SetPoint("RIGHT", rightAnchor, "LEFT", rightOffset, 0)
                
                if itemId then
                    -- Trigger client query to cache the item from server
                    GetItemInfo(itemId)
                    GetItemInfo("item:" .. itemId)
                    local offlineLink = BuildOfflineItemLink(itemId)
                    if offlineLink then
                        row.titleText:SetText(offlineLink)
                        row.titleText:SetTextColor(1.0, 1.0, 1.0, 1.0)
                    else
                        row.titleText:SetText("Loading Item [ID: " .. itemId .. "]...")
                        row.titleText:SetTextColor(0.6, 0.6, 0.6, 1.0) -- Muted grey for loading state
                    end
                else
                    row.titleText:SetText(item.title)
                    row.titleText:SetTextColor(1.0, 1.0, 1.0, 1.0) -- Fallback to white if uncached
                end
            end
        end
        
        -- Apply width constraints and calculate dynamic row height based on text wrapping
        row.titleText:SetWidth(textWidth)
        local textHeight = row.titleText:GetStringHeight()
        local currentRowHeight = math.max(28, textHeight + 10)

        row.graphFrame:Hide()
        row:SetHeight(currentRowHeight)
        
        row:ClearAllPoints()
        row:SetWidth(width)
        if i == 1 then
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -4)
        else
            row:SetPoint("TOPLEFT", rowPool[i-1], "BOTTOMLEFT", 0, -rowSpacing)
        end
        
        row:Show()
        totalHeight = totalHeight + currentRowHeight + rowSpacing
    end

    
    -- Update price graph panel (only for "Chart" subtab)
    if activeTab == "Price" and activePriceItemSubTab == "Chart" then
        if expandedPriceItemId then
            local foundItemId = nil
            for _, item in ipairs(items) do
                if item.id == expandedPriceItemId then
                    foundItemId = GetItemIdFromText(item.title)
                    break
                end
            end
            if foundItemId then
                priceGraphPanel.hint:Hide()
                DrawPriceGraph(priceGraphHolder, priceGraphPanel, foundItemId)
            else
                expandedPriceItemId = nil
                ClearGraphObjects(priceGraphHolder)
                priceGraphPanel.hint:Show()
            end
        else
            ClearGraphObjects(priceGraphHolder)
            priceGraphPanel.hint:Show()
        end
    end

    scrollChild:SetHeight(math.max(totalHeight, 1))
    
    local maxScroll = math.max(0, totalHeight - scrollFrame:GetHeight())
    scrollBar:SetMinMaxValues(0, maxScroll)
    
    if maxScroll == 0 then
        scrollBar:SetValue(0)
        scrollBar:Hide()
    else
        scrollBar:Show()
        local currentVal = scrollBar:GetValue()
        if currentVal > maxScroll then
            scrollBar:SetValue(maxScroll)
        end
    end
end

-- [ADD ITEM] addButton + editBox — bottom input bar for adding tasks/items
local addButton = CreateFrame("Button", "DetaurBarAddButton", frame, "UIPanelButtonTemplate")
addButton:SetSize(60, 22)
addButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 21)
addButton:SetText("Add")

-- [EDIT BOX] Input text EditBox with placeholder
local editBox = CreateFrame("EditBox", "DetaurBarEditBox", frame)
editBox:SetHeight(22)
editBox:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 21)
editBox:SetPoint("RIGHT", addButton, "LEFT", -8, 0)
editBox:SetFontObject("GameFontHighlight")
editBox:SetAutoFocus(false)
editBox:SetTextInsets(6, 6, 0, 0)
editBox:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 12,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
editBox:SetBackdropColor(0, 0, 0, 0.8)
editBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
editBox:SetScript("OnReceiveDrag", OnReceiveDragHandler)

-- [PLACEHOLDER] Placeholder Text — changes based on active tab
local placeholderText = editBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
placeholderText:SetPoint("LEFT", editBox, "LEFT", 8, 0)
placeholderText:SetText("Enter task title...")

editBox:SetScript("OnTextChanged", function(self)
    if self:GetText() == "" then
        placeholderText:Show()
    else
        placeholderText:Hide()
    end
end)

-- [PLACEHOLDER] UpdateInputPlaceholder — sets edit box hint text per active tab
local function UpdateInputPlaceholder()
    if activeTab == "Todo" then
        placeholderText:SetText("Enter todo (" .. activeTodoSubTab .. ")...")
    elseif activeTab == "Notes" then
        placeholderText:SetText("Enter new note (" .. activeNotesSubTab .. ")...")
    elseif activeTab == "Loot" then
        if activeLootSubTab == "Add" then
            placeholderText:SetText("Whitelist item (Add)...")
        else
            placeholderText:SetText("Auto-delete item (Delete)...")
        end
    elseif activeTab == "Price" then
        if activePriceItemSubTab == "Chart" then
            placeholderText:SetText("Enter item to track...")
        else
            placeholderText:SetText("Notifications (auto-populated)")
        end
    elseif activeTab == "Settings" then
        placeholderText:SetText("")
    end
    
    if editBox:GetText() == "" then
        placeholderText:Show()
    else
        placeholderText:Hide()
    end
end

-- [TAB SWITCH] DetaurBar.UI.SelectTab — switches top-level tab, shows/hides sub-tab bars and panels
function DetaurBar.UI.SelectTab(tabName)
    activeTab = tabName
    for _, tab in ipairs(tabs) do
        if tab.tabName == tabName then
            tab:Disable() -- Native WoW look: active tab is disabled/pushed
        else
            tab:Enable()
        end
    end

    if tabName == "Settings" then
        for _, subTab in ipairs(todoSubTabs) do subTab:Hide() end
        for _, subTab in ipairs(notesSubTabs) do subTab:Hide() end
        for _, subTab in ipairs(lootSubTabs) do subTab:Hide() end
        for _, subTab in ipairs(priceItemSubTabs) do subTab:Hide() end
        for _, subTab in ipairs(settingsSubTabs) do subTab:Show() end
        if deleteAllGraysCheckbox then deleteAllGraysCheckbox:Hide() end
        if scrollFrame then scrollFrame:Hide() end
        if listBackground then listBackground:Hide() end
        if priceGraphPanel then priceGraphPanel:Hide() end
        if priceSubTabBar then priceSubTabBar:Hide() end
        if priceThresholdRow then priceThresholdRow:Hide() end
        if settingsSubTabBar then settingsSubTabBar:Show() end
        if settingsPanel then settingsPanel:Show() end
        editBox:ClearFocus()
        editBox:Hide()
        addButton:Hide()
        if settingsScrollBar then settingsScrollBar:SetValue(0) end
        if not activeSettingsSubTab then activeSettingsSubTab = "Dungeon" end
        DetaurBar.UI.SelectSettingsSubTab(activeSettingsSubTab)
        if DetaurBar.UI.UpdateSettingsPanel then
            DetaurBar.UI.UpdateSettingsPanel()
        end
        UpdateInputPlaceholder()
        DetaurBar.UI.RefreshTasks()
        return
    end

    for _, subTab in ipairs(settingsSubTabs) do
        subTab:Hide()
    end
    if settingsSubTabBar then
        settingsSubTabBar:Hide()
    end
    
    -- Show/hide todo sub-tabs
    if tabName == "Todo" then
        for _, subTab in ipairs(todoSubTabs) do subTab:Show() end
        if not activeTodoSubTab then activeTodoSubTab = "Day" end
        DetaurBar.UI.SelectTodoSubTab(activeTodoSubTab)
    else
        for _, subTab in ipairs(todoSubTabs) do subTab:Hide() end
    end

    -- Show/hide notes sub-tabs based on active tab
    if tabName == "Notes" then
        for _, subTab in ipairs(notesSubTabs) do
            subTab:Show()
        end
        if not activeNotesSubTab then
            activeNotesSubTab = "General"
        end
        DetaurBar.UI.SelectNotesSubTab(activeNotesSubTab)
    else
        for _, subTab in ipairs(notesSubTabs) do
            subTab:Hide()
        end
    end

    -- Show/hide loot sub-tabs
    if tabName == "Loot" then
        for _, subTab in ipairs(lootSubTabs) do subTab:Show() end
        if not activeLootSubTab then activeLootSubTab = "Add" end
        DetaurBar.UI.SelectLootSubTab(activeLootSubTab)
    else
        for _, subTab in ipairs(lootSubTabs) do subTab:Hide() end
        deleteAllGraysCheckbox:Hide()
    end

    -- Price sub-tab visuals (UpdateContentAnchors shows/hides the bar)
    if tabName == "Price" then
        if settingsPanel then settingsPanel:Hide() end
        if scrollFrame then scrollFrame:Show() end
        if listBackground then listBackground:Show() end
        for _, subTab in ipairs(priceItemSubTabs) do subTab:Show() end
        if not activePriceItemSubTab then activePriceItemSubTab = "Notifications" end
        DetaurBar.UI.SelectPriceItemSubTab(activePriceItemSubTab)
        UpdatePriceSubTabVisuals()
        LayoutPriceSubTabs()
    else
        for _, subTab in ipairs(priceItemSubTabs) do subTab:Hide() end
        -- Hide Price-specific UI when leaving Price tab
        priceGraphPanel:Hide()
        priceSubTabBar:Hide()
        if priceThresholdRow then priceThresholdRow:Hide() end
        -- Show editBox and addButton for non-Price tabs
        editBox:Show()
        addButton:Show()
        if settingsPanel then settingsPanel:Hide() end
        if scrollFrame then scrollFrame:Show() end
        if listBackground then listBackground:Show() end
    end

    UpdateContentAnchors()
    UpdateInputPlaceholder()
    DetaurBar.UI.RefreshTasks()
end

-- [SUB-TAB SWITCH] DetaurBar.UI.SelectTodoSubTab — switches Day/Week/Month
function DetaurBar.UI.SelectTodoSubTab(subTabName)
    activeTodoSubTab = subTabName
    UpdateTodoSubTabVisuals()
    UpdateInputPlaceholder()
    DetaurBar.UI.RefreshTasks()
end

-- [SUB-TAB SWITCH] DetaurBar.UI.SelectNotesSubTab — switches General/War/Guild
function DetaurBar.UI.SelectNotesSubTab(subTabName)
    activeNotesSubTab = subTabName
    UpdateNotesSubTabVisuals()
    UpdateInputPlaceholder()
    DetaurBar.UI.RefreshTasks()
end

-- [SUB-TAB SWITCH] DetaurBar.UI.SelectLootSubTab — switches Add/Delete
function DetaurBar.UI.SelectLootSubTab(subTabName)
    activeLootSubTab = subTabName
    UpdateLootSubTabVisuals()
    UpdateInputPlaceholder()
    if subTabName == "Delete" then
        deleteAllGraysCheckbox:SetChecked(DetaurBarDB and DetaurBarDB.loot and DetaurBarDB.loot.deleteAllGrays or false)
        deleteAllGraysCheckbox:Show()
    else
        deleteAllGraysCheckbox:Hide()
    end
    UpdateContentAnchors()
    DetaurBar.UI.RefreshTasks()
end

-- [SUB-TAB SWITCH] DetaurBar.UI.SelectPriceItemSubTab — switches Notifications/Chart
function DetaurBar.UI.SelectPriceItemSubTab(subTabName)
    activePriceItemSubTab = subTabName
    UpdatePriceItemSubTabVisuals()
    UpdateInputPlaceholder()
    
    -- Show/hide UI elements based on subtab
    if subTabName == "Notifications" then
        priceGraphPanel:Hide()
        priceSubTabBar:Hide()
        if priceThresholdRow then priceThresholdRow:Hide() end
        editBox:Hide()
        addButton:Hide()
    else -- "Chart"
        priceGraphPanel:Show()
        priceSubTabBar:Show()
        editBox:Show()
        addButton:Show()
        -- Show threshold row with placeholder if no item selected
        DetaurBar.UI.UpdateThresholdRow()
    end
    
    UpdateContentAnchors()
    DetaurBar.UI.RefreshTasks()
end

-- [SUB-TAB SWITCH] DetaurBar.UI.SelectSettingsSubTab — shows/hides the 4 settings panels
function DetaurBar.UI.SelectSettingsSubTab(subTabName)
    activeSettingsSubTab = subTabName
    if UpdateSettingsSubTabBar then
        UpdateSettingsSubTabBar()
    end
    if UpdateSettingsSubTabVisuals then
        UpdateSettingsSubTabVisuals()
    end

    if settingsScrollBar then
        settingsScrollBar:SetValue(0)
    end

    SetSettingsControlsVisible(settingsDungeonControls, subTabName == "Dungeon")
    SetSettingsControlsVisible(settingsWintergraspControls, subTabName == "Wintergrasp")
    SetSettingsControlsVisible(settingsRandomControls, subTabName == "Random")

    UpdateContentAnchors()
    DetaurBar.UI.UpdateSettingsPanel()
end

-- [PRICE] DetaurBar.UI.SetSelectedPriceItem — sets selected item for threshold editing (Chart subtab)
function DetaurBar.UI.SetSelectedPriceItem(itemId)
    selectedPriceItemId = itemId
    DetaurBar.UI.UpdateThresholdRow()
    DetaurBar.UI.RefreshTasks()
end

-- [PRICE] DetaurBar.UI.UpdateThresholdRow — shows/hides threshold row with current item info
function DetaurBar.UI.UpdateThresholdRow()
    if activePriceItemSubTab ~= "Chart" then
        if priceThresholdRow then priceThresholdRow:Hide() end
        return
    end
    
    if not selectedPriceItemId then
        -- Show placeholder/lorem ipsum item
        priceThresholdRow.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        priceThresholdRow.icon:Show()
        priceThresholdRow.name:SetText("NAME")
        priceThresholdRow.name:SetTextColor(0.5, 0.5, 0.5, 1.0)
        priceThresholdRow.input:SetText("")
        priceThresholdRow.inputHigh:SetText("")
        priceThresholdRow.okBtn:Hide()
        priceThresholdRow.clearBtn:Hide()
        priceThresholdRow:Show()
        return
    end
    
    local item = DetaurBar.Data.GetItemById("price", selectedPriceItemId)
    if not item then
        if priceThresholdRow then priceThresholdRow:Hide() end
        return
    end
    
    -- Get item icon
    local itemTexture = nil
    local itemId = GetItemIdFromText(item.title)
    if itemId then
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemId)
        itemTexture = texture
        if DetaurBar.Data.ItemIcons and DetaurBar.Data.ItemIcons[itemId] then
            itemTexture = DetaurBar.Data.ItemIcons[itemId]
        end
    end
    
    if itemTexture then
        priceThresholdRow.icon:SetTexture(itemTexture)
        priceThresholdRow.icon:Show()
    else
        priceThresholdRow.icon:Hide()
    end
    
    -- Get item name (truncate to 11 chars for compact layout)
    local itemName = GetOfflineItemNameById(itemId) or item.title
    if #itemName > 11 then
        itemName = itemName:sub(1, 11)
    end
    priceThresholdRow.name:SetText(itemName)
    priceThresholdRow.name:SetTextColor(1.0, 0.82, 0.0, 1.0)
    
    -- Set threshold values
    local threshold = item.threshold or 0
    priceThresholdRow.input:SetText(threshold > 0 and tostring(threshold) or "")
    local thresholdHigh = item.thresholdHigh or 0
    priceThresholdRow.inputHigh:SetText(thresholdHigh > 0 and tostring(thresholdHigh) or "")
    priceThresholdRow.okBtn:Show()
    priceThresholdRow.clearBtn:Show()
    
    priceThresholdRow:Show()
end

-- [SETTINGS] DetaurBar.UI.UpdateSettingsPanel — reads DB values into all UI controls
function DetaurBar.UI.UpdateSettingsPanel()
    local settings = GetSettingsDB()

    dungeonEnableCheckbox:SetChecked(settings.dungeonFlashEnabled and 1 or nil)
    SetButtonGroupValue(settingsColorButtons, settings.dungeonFlashColor or "YELLOW")
    dungeonDurationEdit:SetText(tostring(ClampNumber(settings.dungeonFlashDuration, 0, 0, 120)))
    ahIntervalEdit:SetText(tostring(ClampNumber(settings.ahScanInterval, 10, 1, 120)))

    wgEnableCheckbox:SetChecked(settings.wgAlertsEnabled and 1 or nil)
    wgAlert1MinutesEdit:SetText(tostring(ClampNumber(settings.wgAlert1Minutes, 15, 0, 120)))
    wgAlert1DurationEdit:SetText(tostring(ClampNumber(settings.wgAlert1Duration, 2, 0, 30)))
    SetButtonGroupValue(settingsWGColorButtons, settings.wgAlert1Color or "YELLOW")
    wgAlert1SoundCheckbox:SetChecked(settings.wgAlert1PlaySound and 1 or nil)
    SetButtonGroupValue(settingsWGAlert1SoundButtons, settings.wgAlert1Sound or "RaidWarning")
    wgAlert2MinutesEdit:SetText(tostring(ClampNumber(settings.wgAlert2Minutes, 1, 0, 120)))
    wgAlert2DurationEdit:SetText(tostring(ClampNumber(settings.wgAlert2Duration, 0, 0, 30)))
    SetButtonGroupValue(settingsWGAlert2ColorButtons, settings.wgAlert2Color or "YELLOW")
    wgSoundCheckbox:SetChecked(settings.wgAlert2PlaySound and 1 or nil)
    SetButtonGroupValue(settingsSoundButtons, settings.wgAlert2Sound or "RaidWarning")

if randomEnableCheckbox then
    local settings = GetSettingsDB()
    randomEnableCheckbox:SetChecked(settings.randomAlertsEnabled and 1 or nil)
    local a = DetaurBar.Data.GetRandomActiveAlert()
    if a then
        randomIntervalEdit:SetText(tostring(a.intervalMinutes or 5))
        randomDurationEdit:SetText(tostring(a.flashDuration or 3))
        SetButtonGroupValue(settingsRandomColorButtons, a.flashColor or "YELLOW")
        randomSoundCheckbox:SetChecked(a.playSound and 1 or nil)
        SetButtonGroupValue(settingsRandomSoundButtons, a.sound or "RaidWarning")
    end
    if UpdateRandomAlertRows then UpdateRandomAlertRows() end
end

    SetSettingsControlsVisible(settingsDungeonControls, activeSettingsSubTab == "Dungeon")
    SetSettingsControlsVisible(settingsWintergraspControls, activeSettingsSubTab == "Wintergrasp")

    SetSettingsControlsVisible(settingsRandomControls, activeSettingsSubTab == "Random")

    -- Ensure scroll frame and child are visible
    if settingsScrollFrame then settingsScrollFrame:Show() end
    if settingsScrollChild then settingsScrollChild:Show() end

    DetaurBar.UI.UpdateSettingsScroll()
end

-- [SETTINGS] DetaurBar.UI.UpdateSettingsScroll — recalculates scroll range per sub-tab content height
function DetaurBar.UI.UpdateSettingsScroll()
    if not settingsScrollFrame or not settingsScrollChild then
        return
    end

    -- Ensure scroll frame and child are visible
    settingsScrollFrame:Show()
    settingsScrollChild:Show()

    local innerWidth = settingsScrollFrame:GetWidth() or 0
    if innerWidth <= 0 then
        innerWidth = math.max(1, frame:GetWidth() - 64)
    end
    settingsScrollChild:SetWidth(innerWidth)

    local contentHeight = 0
    if activeSettingsSubTab == "Dungeon" then
        contentHeight = 180
    elseif activeSettingsSubTab == "Wintergrasp" then
        contentHeight = 460
    elseif activeSettingsSubTab == "Random" then
        contentHeight = 380
    else
        contentHeight = 120
    end
    settingsScrollChild:SetHeight(contentHeight)

    local visibleHeight = settingsScrollFrame:GetHeight() or 0
    if visibleHeight <= 0 then
        visibleHeight = settingsListBackground and settingsListBackground:GetHeight() or (frame:GetHeight() - 120)
    end
    -- Force scroll frame layout if height is still 0
    if visibleHeight <= 0 then
        visibleHeight = 300
    end
    local maxScroll = math.max(0, contentHeight - visibleHeight)
    settingsScrollBar:SetMinMaxValues(0, maxScroll)

    if maxScroll == 0 then
        settingsScrollBar:SetValue(0)
        settingsScrollBar:Hide()
    else
        settingsScrollBar:Show()
        local currentVal = settingsScrollBar:GetValue()
        if currentVal > maxScroll then
            settingsScrollBar:SetValue(maxScroll)
        end
    end
    settingsScrollFrame:SetVerticalScroll(settingsScrollBar:GetValue())
end

-- [SETTINGS] DetaurBar.UI.SaveSettings — writes all UI control values back to DB
function DetaurBar.UI.SaveSettings()
    local settings = GetSettingsDB()
    settings.dungeonFlashEnabled = dungeonEnableCheckbox:GetChecked() and true or false
    settings.dungeonFlashDuration = ClampNumber(dungeonDurationEdit:GetText(), 0, 0, 120)
    settings.ahScanInterval = ClampNumber(ahIntervalEdit:GetText(), 10, 1, 120)
    settings.wgAlertsEnabled = wgEnableCheckbox:GetChecked() and true or false
    settings.wgAlert1Minutes = ClampNumber(wgAlert1MinutesEdit:GetText(), 15, 0, 120)
    settings.wgAlert1Duration = ClampNumber(wgAlert1DurationEdit:GetText(), 2, 0, 30)
    settings.wgAlert1PlaySound = wgAlert1SoundCheckbox:GetChecked() and true or false
    settings.wgAlert2Minutes = ClampNumber(wgAlert2MinutesEdit:GetText(), 1, 0, 120)
    settings.wgAlert2Duration = ClampNumber(wgAlert2DurationEdit:GetText(), 0, 0, 30)
    settings.wgAlert2PlaySound = wgSoundCheckbox:GetChecked() and true or false
    settings.randomAlertsEnabled = randomEnableCheckbox:GetChecked() and true or false
    local activeAlert = DetaurBar.Data.GetRandomActiveAlert()
    if activeAlert then
        activeAlert.intervalMinutes = ClampNumber(randomIntervalEdit:GetText(), 5, 1, 999)
        activeAlert.flashDuration = ClampNumber(randomDurationEdit:GetText(), 0, 0, 30)
        activeAlert.playSound = randomSoundCheckbox:GetChecked() and true or false
    end

    DetaurBar.UI.UpdateSettingsPanel()
    if DetaurBar.Alerts and DetaurBar.Alerts.ResetAlertState then
    DetaurBar.Alerts.ResetAlertState()
end
    print("|cffffff00DetaurBar:|r Settings saved.")
end

-- [STATE] DetaurBar.UI.GetState — returns all active tab/sub-tab names
function DetaurBar.UI.GetState()
    return activeTab, activeTodoSubTab, activeNotesSubTab, activeLootSubTab, activePriceItemSubTab, activePriceSubTab
end

-- [PRICE] DetaurBar.UI.SavePriceThreshold — saves both low and high threshold values
function DetaurBar.UI.SavePriceThreshold()
    if not selectedPriceItemId then return end
    
    local lowText = priceThresholdRow.input:GetText()
    local lowGold = tonumber(lowText) or 0
    local highText = priceThresholdRow.inputHigh:GetText()
    local highGold = tonumber(highText) or 0
    
    local item = DetaurBar.Data.GetItemById("price", selectedPriceItemId)
    if item then
        item.threshold = lowGold
        item.thresholdHigh = highGold
        DetaurBar.UI.UpdateThresholdRow()
        DetaurBar.UI.RefreshTasks()
    end
end

-- [PRICE] DetaurBar.UI.ClearPriceThreshold — removes both thresholds for selected item
function DetaurBar.UI.ClearPriceThreshold()
    if not selectedPriceItemId then return end
    
    local item = DetaurBar.Data.GetItemById("price", selectedPriceItemId)
    if item then
        item.threshold = nil
        item.thresholdHigh = nil
        item.frequent = nil
        item.frequentHigh = nil
        DetaurBar.UI.UpdateThresholdRow()
        DetaurBar.UI.RefreshTasks()
    end
end

-- [ADD ITEM] DetaurBar.UI.AddNewItem — submits editBox text as new task/item
function DetaurBar.UI.AddNewItem()
    local title = editBox:GetText()
    title = title:gsub("^%s*(.-)%s*$", "%1") -- Trim spaces
    if title ~= "" then
        local category = activeTab:lower()
        if category == "todo" then
            category = "todo_" .. activeTodoSubTab:lower()
        elseif category == "notes" then
            category = "notes_" .. activeNotesSubTab:lower()
        elseif category == "loot" then
            category = "loot_" .. activeLootSubTab:lower()
        end

        if category == "loot_add" or category == "loot_delete" or category == "sell" or category == "price" then
            local itemId = GetItemIdFromText(title)
            if itemId then
                -- VZDY pouzivaj offline ID format, ignoruj serverove GetItemInfo
                title = "item:" .. itemId
            else
                local itemName, itemLink = GetItemInfo(title)
                if not itemLink then
                    local capped = title:gsub("(%a)([%w_']*)", function(f, r) return f:upper() .. r:lower() end)
                    itemName, itemLink = GetItemInfo(capped)
                end
                if itemLink then
                    title = itemLink
                end
            end
        end
        
        local newItem = DetaurBar.Data.AddItem(category, title)
        if newItem and category == "price" and activePriceItemSubTab == "Notifications" then
            newItem.frequent = true
        end
        editBox:SetText("")
        editBox:ClearFocus()
        DetaurBar.UI.RefreshTasks()
    end
end

addButton:SetScript("OnClick", DetaurBar.UI.AddNewItem)
editBox:SetScript("OnEnterPressed", DetaurBar.UI.AddNewItem)
editBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

-- [HOOK] HandleModifiedItemClick override — inserts item link into edit box if focused
local orig_HandleModifiedItemClick = HandleModifiedItemClick
function HandleModifiedItemClick(link)
    if DetaurBarFrame and DetaurBarFrame:IsShown() and editBox:HasFocus() then
        editBox:Insert(link)
        return true
    end
    if orig_HandleModifiedItemClick then
        return orig_HandleModifiedItemClick(link)
    end
end

-- [RESIZE] Resize grabber (bottom-right corner)
local resizeButton = CreateFrame("Button", nil, frame)
resizeButton:SetSize(16, 16)
resizeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

resizeButton:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        frame:StartSizing("BOTTOMRIGHT")
    end
end)
resizeButton:SetScript("OnMouseUp", function(self, button)
    frame:StopMovingOrSizing()
end)

-- [RESIZE] DetaurBar.UI.OnResize — re-layout all content on frame size change
function DetaurBar.UI.OnResize()
    UpdateTabAnchors()
    UpdateContentAnchors()
    LayoutPriceSubTabs()
    if settingsSubTabBar then
        UpdateSettingsSubTabBar()
    end
    local width = scrollFrame:GetWidth()
    scrollChild:SetWidth(width)
    for _, row in ipairs(rowPool) do
        row:SetWidth(width)
    end
    if settingsScrollFrame then
        DetaurBar.UI.UpdateSettingsScroll()
    end
    DetaurBar.UI.RefreshTasks()
end

frame:SetScript("OnSizeChanged", function()
    DetaurBar.UI.OnResize()
end)

-- [RESTORE] DetaurBar.UI.RestorePosition — restores saved frame position from DB
function DetaurBar.UI.RestorePosition()
    if DetaurBarDB and DetaurBarDB.framePosition then
        local pos = DetaurBarDB.framePosition
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    else
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
    end
end

-- [INIT] DetaurBar.UI.Initialize — sets up tabs, minimap, and window position
function DetaurBar.UI.Initialize()
    UpdateTabAnchors()
    DetaurBar.UI.SelectTab("Todo")
    DetaurBar.UI.UpdateMinimapPosition()
    DetaurBar.UI.RestorePosition()
end

-- [TOGGLE] DetaurBar.UI.ToggleVisibility — shows/hides the main frame
function DetaurBar.UI.ToggleVisibility()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

-- Minimap button moved to DetaurBar_Minimap.lua
