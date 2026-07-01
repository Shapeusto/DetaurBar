-- DetaurBar_UI.lua
-- Handles frame creation, textures, tabs, checkboxes, scrolling, and layouts.

-- Global namespace
DetaurBar = DetaurBar or {}
DetaurBar.UI = DetaurBar.UI or {}

-- [MAIN FRAME] CreateFrame with size/position/move/resize, default hidden
local frame = CreateFrame("Frame", "DetaurBarFrame", UIParent)
frame:SetSize(300, 430)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:SetResizable(true)
frame:SetMinResize(300, 430)
frame:SetMaxResize(600, 1200)
frame:Hide() -- Hidden by default
DetaurBar.UI.frame = frame
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

-- [STATE] Tab names, active tab
local tabs = {}
local tabNames = { "Todo", "Notes", "Loot", "Price", "Settings" }
local activeTab = "Todo"

-- [STATE] Settings sub-tabs: Dungeon / Wintergrasp / Random / Enemy
DetaurBar.UI.settingsSubTabs = {}
DetaurBar.UI.settingsSubTabNames = { "Dungeon", "Wintergrasp", "Random", "Enemy" }
DetaurBar.UI.activeSettingsSubTab = "Dungeon"

-- [STATE] Settings panel/bar references
DetaurBar.UI.settingsPanel = nil
DetaurBar.UI.settingsSubTabBar = nil
DetaurBar.UI.settingsListBackground = nil

-- [STATE] Sub-tab tables (initialized empty; populated by tab files loaded after this)
DetaurBar.UI.todoSubTabs = {}
DetaurBar.UI.notesSubTabs = {}
DetaurBar.UI.lootSubTabs = {}
DetaurBar.UI.priceItemSubTabs = {}

-- [HELPERS] Category string builders (todo_day, notes_war, etc.)
local function GetTodoCategory(subTabName)
    return "todo_" .. subTabName:lower()
end

function DetaurBar.UI.GetNotesCategory(subTabName)
    return "notes_" .. subTabName:lower()
end

-- [HELPERS] GetSettingsDB — returns DetaurBarDB.settings with InitializeDB()
function DetaurBar.UI.GetSettingsDB()
    DetaurBar.Data.InitializeDB()
    return DetaurBarDB.settings or {}
end

-- [HELPERS] ClampNumber — tonumber with fallback, clamped to [min, max]
function DetaurBar.UI.ClampNumber(value, defaultValue, minValue, maxValue)
    value = tonumber(value) or defaultValue
    if minValue and value < minValue then
        value = minValue
    end
    if maxValue and value > maxValue then
        value = maxValue
    end
    return value
end

-- [NOTES] ClearDraggedNote — resets drag state and OnUpdate
function DetaurBar.UI.ClearDraggedNote()
    DetaurBar.UI.draggedNote = nil
    frame:SetScript("OnUpdate", nil)
end

-- [NOTES] StartDraggedNote — tracks held mouse, auto-clears after 0.15s release
function DetaurBar.UI.StartDraggedNote(fromCategory, itemId)
    DetaurBar.UI.draggedNote = {
        fromCategory = fromCategory,
        itemId = itemId
    }
    local releaseElapsed = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        if not IsMouseButtonDown("LeftButton") then
            releaseElapsed = releaseElapsed + elapsed
            if releaseElapsed > 0.15 then
                DetaurBar.UI.ClearDraggedNote()
            end
        else
            releaseElapsed = 0
        end
    end)
end

-- [NOTES] DropDraggedNoteOnSubTab — moves note to target category
function DetaurBar.UI.DropDraggedNoteOnSubTab(subTab)
    if not DetaurBar.UI.draggedNote then
        return false
    end

    local toCategory = DetaurBar.UI.GetNotesCategory(subTab.tabName)
    if DetaurBar.UI.draggedNote.fromCategory ~= toCategory then
        DetaurBar.Data.MoveItem(DetaurBar.UI.draggedNote.fromCategory, toCategory, DetaurBar.UI.draggedNote.itemId)
        DetaurBar.UI.SelectNotesSubTab(subTab.tabName)
    else
        DetaurBar.UI.RefreshTasks()
    end

    DetaurBar.UI.ClearDraggedNote()
    return true
end



-- [ITEM HELPERS] GetItemIdFromText — extract item ID from link, "item:ID" text, number, or DB name lookup
function DetaurBar.UI.GetItemIdFromText(text)
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
function DetaurBar.UI.GetOfflineItemNameById(itemId)
    if not itemId or not DetaurBar.Data.ItemDatabaseReverse then
        return nil
    end
    local name = DetaurBar.Data.ItemDatabaseReverse[itemId]
    if name then
        local result = name:gsub("(%s)(%a)", function(s, a) return s .. a:upper() end)
        return result:sub(1,1):upper() .. result:sub(2)
    end
    return nil
end

-- [ITEM HELPERS] BuildOfflineItemLink — builds hyperlink from offline name
function DetaurBar.UI.BuildOfflineItemLink(itemId)
    local itemName = DetaurBar.UI.GetOfflineItemNameById(itemId)
    if itemName then
        return "|cffffffff|Hitem:" .. itemId .. ":0:0:0:0:0:0:0|h[" .. itemName .. "]|h|r"
    end
    return nil
end

-- [ITEM HELPERS] GetUsableItemLink — prefers offline link, falls back to GetItemInfo
function DetaurBar.UI.GetUsableItemLink(text)
    local itemId = DetaurBar.UI.GetItemIdFromText(text)
    local itemLink

    if itemId then
        itemLink = DetaurBar.UI.BuildOfflineItemLink(itemId)
        if not itemLink then
            _, itemLink = GetItemInfo(itemId)
            if not itemLink then
                _, itemLink = GetItemInfo("item:" .. itemId)
            end
        end
        return itemLink or DetaurBar.UI.BuildOfflineItemLink(itemId), itemId
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
            category = "loot_" .. DetaurBar.UI.activeLootSubTab:lower()
        end
        if category == "loot_add" or category == "loot_delete" or category == "sell" or category == "price" then
            local title = itemLink or ("item:" .. itemId)
            local newItem = DetaurBar.Data.AddItem(category, title)
            if newItem and category == "price" and DetaurBar.UI.activePriceItemSubTab == "Notifications" then
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

-- Sub-tab creation moved to DetaurBar_UI_Todo.lua, DetaurBar_UI_Notes.lua, DetaurBar_UI_Loot.lua, DetaurBar_UI_Price.lua

-- [LAYOUT] UpdateTabAnchors — positions main tabs, all sub-tabs to fit frame width
function DetaurBar.UI.UpdateTabAnchors()
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
    for i, subTab in ipairs(DetaurBar.UI.todoSubTabs) do
        subTab:SetWidth(subTabWidth)
        subTab:ClearAllPoints()
        if i == 1 then
            subTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
        else
            subTab:SetPoint("LEFT", DetaurBar.UI.todoSubTabs[i-1], "RIGHT", subTabGap, 0)
        end
    end
    DetaurBar.UI.LayoutNotesSubTabs()
    local lootSubTabWidth = (totalWidth - subTabGap) / 2
    for i, subTab in ipairs(DetaurBar.UI.lootSubTabs) do
        subTab:SetWidth(lootSubTabWidth)
        subTab:ClearAllPoints()
        if i == 1 then
            subTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
        else
            subTab:SetPoint("LEFT", DetaurBar.UI.lootSubTabs[i-1], "RIGHT", subTabGap, 0)
        end
    end

    local priceItemSubTabWidth = (totalWidth - subTabGap) / 2
    for i, subTab in ipairs(DetaurBar.UI.priceItemSubTabs) do
        subTab:SetWidth(priceItemSubTabWidth)
        subTab:ClearAllPoints()
        if i == 1 then
            subTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
        else
            subTab:SetPoint("LEFT", DetaurBar.UI.priceItemSubTabs[i-1], "RIGHT", subTabGap, 0)
        end
    end

    if DetaurBar.UI.settingsSubTabBar then
        DetaurBar.UI.settingsSubTabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
        DetaurBar.UI.settingsSubTabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -60)
        DetaurBar.UI.UpdateSettingsSubTabBar()
    end
end

-- [STATE] Scroll/graph bar/price graph/price sub-tab/settings scroll declarations
local scrollFrame
DetaurBar.UI.priceGraphHolder = { graphTextures = {}, graphLabels = {}, graphFrames = {} }
DetaurBar.UI.settingsScrollFrame = nil
DetaurBar.UI.settingsScrollChild = nil
DetaurBar.UI.settingsSaveButton = nil

-- [LAYOUT] UpdateContentAnchors — hides settings UI or main scroll/graph based on activeTab
function DetaurBar.UI.UpdateContentAnchors()
    if activeTab == "Settings" then
        if scrollFrame then scrollFrame:Hide() end
        if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
        if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
        if DetaurBar.UI.settingsSubTabBar then DetaurBar.UI.settingsSubTabBar:Show() end
        if DetaurBar.UI.settingsListBackground then DetaurBar.UI.settingsListBackground:Show() end
        if DetaurBar.UI.settingsScrollFrame then DetaurBar.UI.settingsScrollFrame:Show() end
        if DetaurBar.UI.settingsPanel then DetaurBar.UI.settingsPanel:Show() end
        if DetaurBar.UI.settingsScrollChild then DetaurBar.UI.settingsScrollChild:Show() end
        return
    end

    if DetaurBar.UI.settingsPanel then
        DetaurBar.UI.settingsPanel:Hide()
    end
    if DetaurBar.UI.settingsSubTabBar then
        DetaurBar.UI.settingsSubTabBar:Hide()
    end
    if DetaurBar.UI.settingsListBackground then
        DetaurBar.UI.settingsListBackground:Hide()
    end
    if DetaurBar.UI.settingsScrollFrame then
        DetaurBar.UI.settingsScrollFrame:Hide()
    end

    scrollFrame:ClearAllPoints()
    if activeTab == "Notes" then
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -88)
    elseif activeTab == "Todo" or activeTab == "Price" then
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -88)
    elseif activeTab == "Loot" and DetaurBar.UI.activeLootSubTab == "Delete" then
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -114)
    elseif activeTab == "Loot" then
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -88)
    else
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -60)
    end
    if activeTab == "Price" then
        if DetaurBar.UI.activePriceItemSubTab == "Chart" then
            scrollFrame:SetPoint("BOTTOMLEFT", DetaurBar.UI.priceThresholdRow, "TOPLEFT", 0, 4)
            scrollFrame:SetPoint("BOTTOMRIGHT", DetaurBar.UI.priceThresholdRow, "TOPRIGHT", -16, 4)
            DetaurBar.UI.priceThresholdRow:Show()
            if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Show() end
            if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Show() end
            if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
        else
            scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 50)
            if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
            if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
            if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
            if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Show() end
        end
    elseif activeTab == "Notes" then
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 84)
        if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
        if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
    else
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 50)
        if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
        if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
    end
end

-- [UI FACTORY] SetSimpleTooltip — OnEnter/OnLeave GameTooltip helper (used by both main UI and settings)
function DetaurBar.UI.SetSimpleTooltip(frame, title, text)
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

-- [AH INTERVAL HELPERS] Small set of factory functions kept for AH scan interval creation below
function DetaurBar.UI.CreateSettingsLabel(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    return label
end

function DetaurBar.UI.CreateSettingEditBox(parent, width)
    local edit = CreateFrame("EditBox", nil, parent)
    edit:SetSize(width, 20)
    edit:SetAutoFocus(false)
    edit:SetNumeric(true)
    edit:SetTextInsets(4, 4, 0, 0)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    edit:SetBackdropColor(0, 0, 0, 0.8)
    edit:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
    return edit
end

function DetaurBar.UI.CreateSettingsEditRow(parent, labelText, x, y, width, maxLetters, onEnter)
    local label = DetaurBar.UI.CreateSettingsLabel(parent, labelText, x, y)
    local edit = DetaurBar.UI.CreateSettingEditBox(parent, width)
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

-- AH interval row creation moved to DetaurBar_UI_Price.lua

-- Visual update functions and deleteAllGraysCheckbox moved to tab files

-- [MAIN SCROLL] ScrollFrame — main item list container
scrollFrame = CreateFrame("ScrollFrame", "DetaurBarScrollFrame", frame)
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -60)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 50)
DetaurBar.UI.scrollFrame = scrollFrame

-- [MAIN SCROLL] listBackground — dark panel frame behind scrollable items, receives drag-drop
local listBackground = CreateFrame("Frame", nil, frame)
DetaurBar.UI.listBackground = listBackground
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
DetaurBar.UI.scrollChild = scrollChild
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetWidth(scrollFrame:GetWidth())
scrollChild:SetHeight(1)

-- [MAIN SCROLL] Scroll bar slider with OnValueChanged
local scrollBar = CreateFrame("Slider", "DetaurBarScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
DetaurBar.UI.scrollBar = scrollBar
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

-- Price graph panel, sub-tab bar, threshold row, price sub-tabs moved to DetaurBar_UI_Price.lua

-- [ROW POOL] Constants and pool table for item rows
DetaurBar.UI.rowPool = {}
local rowPool = DetaurBar.UI.rowPool
local rowHeight = 28
local rowSpacing = 4
local GRAPH_HEIGHT = 90
local GRAPH_PAD_L = 46
local GRAPH_PAD_R = 8
local GRAPH_PAD_T = 8
local GRAPH_PAD_B = 20

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
                        local itemLink = DetaurBar.UI.GetUsableItemLink(itemDetail.title)
                        if itemLink then
                            HandleModifiedItemClick(itemLink)
                        end
                    end
                end
            else
                if row.itemCategory == "price" then
                    if DetaurBar.UI.expandedPriceItemId == self.itemId then
                        DetaurBar.UI.expandedPriceItemId = nil
                    else
                        DetaurBar.UI.expandedPriceItemId = self.itemId
                    end
                    -- Also select for threshold row in "Chart" subtab
        if DetaurBar.UI.activePriceItemSubTab == "Chart" then
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
                local itemLink = DetaurBar.UI.GetUsableItemLink(itemDetail.title)
                if itemLink then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    local itemId = DetaurBar.UI.GetItemIdFromText(itemDetail.title)
                    -- Najprv skus server (ak je item v cache klienta, ukaze plny tooltip)
                    local _, serverLink, _, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(itemId or itemDetail.title)
                    if serverLink then
                        GameTooltip:SetHyperlink(serverLink)
                        if itemSellPrice and itemSellPrice > 0 then
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddDoubleLine("Sell Price:", DetaurBar.UI.FormatMoney(itemSellPrice), 1.0, 0.82, 0.0, 1.0, 1.0, 1.0)
                        end
                    else
                        -- Offline fallback: server nema item v cache
                        local itemName = DetaurBar.UI.GetOfflineItemNameById(itemId)
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
            DetaurBar.UI.StartDraggedNote(self.itemCategory, self.itemId)
            self.bg:SetTexture(1.0, 0.82, 0.0, 0.18)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Move Note", 1.0, 1.0, 1.0)
            GameTooltip:AddLine("Drop this note on a category tab above.", 0.5, 0.5, 0.5)
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
            if row.itemCategory == "price" and DetaurBar.UI.activePriceItemSubTab == "Notifications" then
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
                if DetaurBar.UI.expandedPriceItemId == row.itemId then
                    DetaurBar.UI.expandedPriceItemId = nil
                end
            else
                DetaurBar.Data.DeleteItem(row.itemCategory, row.itemId)
                if row.itemCategory == "price" and DetaurBar.UI.expandedPriceItemId == row.itemId then
                    DetaurBar.UI.expandedPriceItemId = nil
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
        category = "todo_" .. DetaurBar.UI.activeTodoSubTab:lower()
    elseif category == "notes" then
        category = "notes_" .. DetaurBar.UI.activeNotesSubTab:lower()
    elseif category == "loot" then
        category = "loot_" .. DetaurBar.UI.activeLootSubTab:lower()
        if DetaurBar.Core and DetaurBar.Core.UpdateAutoLootCVar then
            DetaurBar.Core.UpdateAutoLootCVar()
        end
    end
    local items = DetaurBar.Data.GetItems(category)
    if category == "price" and DetaurBar.UI.activePriceItemSubTab == "Notifications" then
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
        if category == "price" and DetaurBar.UI.activePriceItemSubTab == "Notifications" then
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
            if DetaurBar.UI.activePriceItemSubTab == "Notifications" then
                row.swapBtn:Hide()
                
                local itemName, itemTexture, itemRarity
                local itemId = DetaurBar.UI.GetItemIdFromText(item.title)
                if itemId then
                    itemName = DetaurBar.UI.GetOfflineItemNameById(itemId)
                    if not itemName then
                        itemName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
                    else
                        itemRarity = 1
                        itemTexture = DetaurBar.Data.GetItemTexture(itemId)
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
                        local offlineLink = DetaurBar.UI.BuildOfflineItemLink(itemId)
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
                local itemId = DetaurBar.UI.GetItemIdFromText(item.title)
                if itemId then
                    itemName = DetaurBar.UI.GetOfflineItemNameById(itemId)
                    if not itemName then
                        itemName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
                    else
                        itemRarity = 1
                        itemTexture = DetaurBar.Data.GetItemTexture(itemId)
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
                        local offlineLink = DetaurBar.UI.BuildOfflineItemLink(itemId)
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
            local itemId = DetaurBar.UI.GetItemIdFromText(item.title)
            
            if itemId then
                -- Najprv pouzivaj OFFLINE databazu (ignoruje serverove GetItemInfo)
                itemName = DetaurBar.UI.GetOfflineItemNameById(itemId)
                itemLink = DetaurBar.UI.BuildOfflineItemLink(itemId)
                
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
                    itemTexture = DetaurBar.Data.GetItemTexture(itemId)
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
                    local offlineLink = DetaurBar.UI.BuildOfflineItemLink(itemId)
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
    if activeTab == "Price" and DetaurBar.UI.activePriceItemSubTab == "Chart" then
        if DetaurBar.UI.expandedPriceItemId then
            local foundItemId = nil
            for _, item in ipairs(items) do
                if item.id == DetaurBar.UI.expandedPriceItemId then
                    foundItemId = DetaurBar.UI.GetItemIdFromText(item.title)
                    break
                end
            end
            if foundItemId then
                DetaurBar.UI.priceGraphPanel.hint:Hide()
                DetaurBar.UI.DrawPriceGraph(DetaurBar.UI.priceGraphHolder, DetaurBar.UI.priceGraphPanel, foundItemId)
            else
                DetaurBar.UI.expandedPriceItemId = nil
                DetaurBar.UI.ClearGraphObjects(DetaurBar.UI.priceGraphHolder)
                DetaurBar.UI.priceGraphPanel.hint:Show()
            end
        else
            DetaurBar.UI.ClearGraphObjects(DetaurBar.UI.priceGraphHolder)
            DetaurBar.UI.priceGraphPanel.hint:Show()
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
DetaurBar.UI.addButton = addButton
addButton:SetSize(60, 22)
addButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 21)
addButton:SetText("Add")

-- [EDIT BOX] Input text EditBox with placeholder
local editBox = CreateFrame("EditBox", "DetaurBarEditBox", frame)
DetaurBar.UI.editBox = editBox
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
function DetaurBar.UI.UpdateInputPlaceholder()
    if activeTab == "Todo" then
        placeholderText:SetText("Enter todo (" .. DetaurBar.UI.activeTodoSubTab .. ")...")
    elseif activeTab == "Notes" then
        placeholderText:SetText("Enter new note (" .. DetaurBar.UI.activeNotesSubTab .. ")...")
    elseif activeTab == "Loot" then
        if DetaurBar.UI.activeLootSubTab == "Add" then
            placeholderText:SetText("Whitelist item (Add)...")
        else
            placeholderText:SetText("Auto-delete item (Delete)...")
        end
    elseif activeTab == "Price" then
        if DetaurBar.UI.activePriceItemSubTab == "Chart" then
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
        for _, subTab in ipairs(DetaurBar.UI.todoSubTabs) do subTab:Hide() end
        for _, subTab in ipairs(DetaurBar.UI.lootSubTabs) do subTab:Hide() end
        for _, subTab in ipairs(DetaurBar.UI.priceItemSubTabs) do subTab:Hide() end
        if DetaurBar.UI.notesTabContainer then DetaurBar.UI.notesTabContainer:Hide() end
        if DetaurBar.UI.notesCatControls then DetaurBar.UI.notesCatControls:Hide() end
        if DetaurBar.UI.notesTabLeftArrow then DetaurBar.UI.notesTabLeftArrow:Hide() end
        if DetaurBar.UI.notesTabRightArrow then DetaurBar.UI.notesTabRightArrow:Hide() end
        for _, subTab in ipairs(DetaurBar.UI.settingsSubTabs) do subTab:Show() end
        if DetaurBar.UI.deleteAllGraysCheckbox then DetaurBar.UI.deleteAllGraysCheckbox:Hide() end
        if scrollFrame then scrollFrame:Hide() end
        if listBackground then listBackground:Hide() end
        if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
        if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
        if DetaurBar.UI.settingsSubTabBar then DetaurBar.UI.settingsSubTabBar:Show() end
        if DetaurBar.UI.settingsPanel then DetaurBar.UI.settingsPanel:Show() end
        if DetaurBar.UI.settingsListBackground then DetaurBar.UI.settingsListBackground:Show() end
        if DetaurBar.UI.settingsScrollFrame then DetaurBar.UI.settingsScrollFrame:Show() end
        if DetaurBar.UI.settingsScrollChild then DetaurBar.UI.settingsScrollChild:Show() end
        editBox:ClearFocus()
        editBox:Hide()
        addButton:Hide()
        if not DetaurBar.UI.activeSettingsSubTab then DetaurBar.UI.activeSettingsSubTab = "Dungeon" end
        DetaurBar.UI.SelectSettingsSubTab(DetaurBar.UI.activeSettingsSubTab)
        if DetaurBar.UI.UpdateSettingsPanel then
            DetaurBar.UI.UpdateSettingsPanel()
        end
        DetaurBar.UI.UpdateInputPlaceholder()
        DetaurBar.UI.RefreshTasks()
        return
    end

    for _, subTab in ipairs(DetaurBar.UI.settingsSubTabs) do
        subTab:Hide()
    end
    if DetaurBar.UI.settingsSubTabBar then
        DetaurBar.UI.settingsSubTabBar:Hide()
    end
    
    -- Show/hide todo sub-tabs
    if tabName == "Todo" then
        for _, subTab in ipairs(DetaurBar.UI.todoSubTabs) do subTab:Show() end
        if not DetaurBar.UI.activeTodoSubTab then DetaurBar.UI.activeTodoSubTab = "Day" end
        DetaurBar.UI.SelectTodoSubTab(DetaurBar.UI.activeTodoSubTab)
    else
        for _, subTab in ipairs(DetaurBar.UI.todoSubTabs) do subTab:Hide() end
    end

    -- Show/hide notes sub-tabs, category controls, and rebuild sub-tab buttons from DB
    if tabName == "Notes" then
        DetaurBar.UI.RebuildNotesSubTabs()
        if DetaurBar.UI.notesTabContainer then DetaurBar.UI.notesTabContainer:Show() end
        if DetaurBar.UI.notesCatControls then DetaurBar.UI.notesCatControls:Show() end
        DetaurBar.UI.SelectNotesSubTab(DetaurBar.UI.activeNotesSubTab)
    else
        if DetaurBar.UI.notesTabContainer then DetaurBar.UI.notesTabContainer:Hide() end
        if DetaurBar.UI.notesCatControls then DetaurBar.UI.notesCatControls:Hide() end
        if DetaurBar.UI.notesTabLeftArrow then DetaurBar.UI.notesTabLeftArrow:Hide() end
        if DetaurBar.UI.notesTabRightArrow then DetaurBar.UI.notesTabRightArrow:Hide() end
    end

    -- Show/hide loot sub-tabs
    if tabName == "Loot" then
        for _, subTab in ipairs(DetaurBar.UI.lootSubTabs) do subTab:Show() end
        if not DetaurBar.UI.activeLootSubTab then DetaurBar.UI.activeLootSubTab = "Add" end
        DetaurBar.UI.SelectLootSubTab(DetaurBar.UI.activeLootSubTab)
    else
        for _, subTab in ipairs(DetaurBar.UI.lootSubTabs) do subTab:Hide() end
        if DetaurBar.UI.deleteAllGraysCheckbox then DetaurBar.UI.deleteAllGraysCheckbox:Hide() end
    end

    -- Price sub-tab visuals (UpdateContentAnchors shows/hides the bar)
    if tabName == "Price" then
        if DetaurBar.UI.settingsPanel then DetaurBar.UI.settingsPanel:Hide() end
        if scrollFrame then scrollFrame:Show() end
        if listBackground then listBackground:Show() end
        for _, subTab in ipairs(DetaurBar.UI.priceItemSubTabs) do subTab:Show() end
        if not DetaurBar.UI.activePriceItemSubTab then DetaurBar.UI.activePriceItemSubTab = "Notifications" end
        DetaurBar.UI.SelectPriceItemSubTab(DetaurBar.UI.activePriceItemSubTab)
        DetaurBar.UI.UpdatePriceSubTabVisuals()
        DetaurBar.UI.LayoutPriceSubTabs()
    else
        for _, subTab in ipairs(DetaurBar.UI.priceItemSubTabs) do subTab:Hide() end
        if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
        if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        editBox:Show()
        addButton:Show()
        if DetaurBar.UI.settingsPanel then DetaurBar.UI.settingsPanel:Hide() end
        if scrollFrame then scrollFrame:Show() end
        if listBackground then listBackground:Show() end
    end

    DetaurBar.UI.UpdateContentAnchors()
    DetaurBar.UI.UpdateInputPlaceholder()
    DetaurBar.UI.RefreshTasks()
end

-- Select*SubTab functions moved to tab files
-- Price threshold/state functions moved to DetaurBar_UI_Price.lua

-- [STATE] DetaurBar.UI.GetState — returns all active tab/sub-tab names
function DetaurBar.UI.GetState()
    return activeTab, DetaurBar.UI.activeTodoSubTab, DetaurBar.UI.activeNotesSubTab, DetaurBar.UI.activeLootSubTab, DetaurBar.UI.activePriceItemSubTab, DetaurBar.UI.activePriceSubTab
end

-- [ADD ITEM] DetaurBar.UI.AddNewItem — submits editBox text as new task/item
function DetaurBar.UI.AddNewItem()
    local title = editBox:GetText()
    title = title:gsub("^%s*(.-)%s*$", "%1") -- Trim spaces
    if title ~= "" then
        local category = activeTab:lower()
        if category == "todo" then
            category = "todo_" .. DetaurBar.UI.activeTodoSubTab:lower()
        elseif category == "notes" then
            category = "notes_" .. DetaurBar.UI.activeNotesSubTab:lower()
        elseif category == "loot" then
            category = "loot_" .. DetaurBar.UI.activeLootSubTab:lower()
        end

        if category == "loot_add" or category == "loot_delete" or category == "sell" or category == "price" then
            local itemId = DetaurBar.UI.GetItemIdFromText(title)
            if itemId then
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
        if newItem and category == "price" and DetaurBar.UI.activePriceItemSubTab == "Notifications" then
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
    DetaurBar.UI.UpdateTabAnchors()
    DetaurBar.UI.UpdateContentAnchors()
    DetaurBar.UI.LayoutPriceSubTabs()
    if DetaurBar.UI.settingsSubTabBar then
        DetaurBar.UI.UpdateSettingsSubTabBar()
    end
    local width = scrollFrame:GetWidth()
    scrollChild:SetWidth(width)
    for _, row in ipairs(rowPool) do
        row:SetWidth(width)
    end
    if DetaurBar.UI.settingsScrollFrame then
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

-- [INIT] DetaurBar.UI.Initialize — sets up tabs, minimap, enemy detection, and window position
function DetaurBar.UI.Initialize()
    DetaurBar.UI.UpdateTabAnchors()
    DetaurBar.UI.SelectTab("Todo")
    DetaurBar.UI.UpdateMinimapPosition()
    DetaurBar.UI.RestorePosition()
    if DetaurBar.Enemy and DetaurBar.Enemy.Initialize then
        DetaurBar.Enemy.Initialize()
    end
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
