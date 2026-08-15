-- DetaurBar_UI.lua
-- Handles frame creation, textures, tabs, checkboxes, scrolling, and layouts.

-- Global namespace
DetaurBar = DetaurBar or {}
DetaurBar.UI = DetaurBar.UI or {}

-- [MAIN FRAME] CreateFrame with size/position/move/resize, default hidden
local frame = CreateFrame("Frame", "DetaurBarFrame", UIParent)
frame:SetSize(300, 485)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:SetResizable(true)
frame:SetMinResize(300, 485)
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

-- [HEADER] Close button — slightly larger real Blizzard "X" icon
local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetSize(30, 30)
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -9, -4)

-- [HEADER] Settings quick-button — right next to X
local settingsBtn = CreateFrame("Button", nil, frame)
settingsBtn:SetSize(22, 22)
settingsBtn:SetPoint("RIGHT", closeBtn, "LEFT", 5, 0)

local settingsIcon = settingsBtn:CreateTexture(nil, "ARTWORK")
settingsIcon:SetAllPoints(settingsBtn)
settingsIcon:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
settingsBtn.icon = settingsIcon

local settingsHighlight = settingsBtn:CreateTexture(nil, "HIGHLIGHT")
settingsHighlight:SetAllPoints(settingsBtn)
settingsHighlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
settingsHighlight:SetBlendMode("ADD")

DetaurBar.UI.settingsBtn = settingsBtn

closeBtn:SetScript("OnClick", function()
    if DetaurBar.UI.settingsMenuPanel then DetaurBar.UI.settingsMenuPanel:Hide() end
    frame:Hide()
end)

settingsBtn:SetScript("OnClick", function()
    DetaurBar.UI.ToggleSettingsMenu()
end)

settingsBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Settings", 1.0, 1.0, 1.0)
    GameTooltip:Show()
end)
settingsBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- [SETTINGS MENU] Panel inside main frame for managing visible sub-tabs
DetaurBar.UI.settingsMenuPanel = nil
DetaurBar.UI.settingsMenuPanelVisible = false
DetaurBar.UI.settingsMenuActiveSubTab = "Loot"
local smSettingsSubTabNames = { "Loot", "Alert", "Price", "Various" }

local function RebuildSettingsMenuCheckboxes()
    local panel = DetaurBar.UI.settingsMenuPanel
    if not panel then return end

    -- Style sub-tabs
    for _, st in ipairs(panel.subTabButtons) do
        if st.tabName == DetaurBar.UI.settingsMenuActiveSubTab then
            st:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
            st:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
            st.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
        else
            st:SetBackdropColor(0, 0, 0, 0.55)
            st:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
            st.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
        end
    end

    -- Clear old checkboxes
    for _, child in ipairs({panel.content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    -- Textures are not returned by GetChildren() — hide the tracked one (reused, not re-created)
    if panel.priceDivider then
        panel.priceDivider:Hide()
    end
    if panel.variousDivider then
        panel.variousDivider:Hide()
    end
    if panel.armorIconPickerPanel then
        panel.armorIconPickerPanel:Hide()
    end

    local settings = DetaurBar.UI.GetSettingsDB()
    local active = DetaurBar.UI.settingsMenuActiveSubTab

    local function OnCheckChanged(tabType, key, self)
        DetaurBar.Data.InitializeDB()
        if tabType == "loot" then
            DetaurBarDB.settings.lootSubTabsVisible[key] = self:GetChecked() and true or false
        elseif tabType == "price" then
            DetaurBarDB.settings.priceSubTabsVisible[key] = self:GetChecked() and true or false
        else
            DetaurBarDB.settings.alertSubTabsVisible[key] = self:GetChecked() and true or false
        end
    end

    if active == "Loot" then
        local lootKeys = { "Add", "Delete" }
        for idx, key in ipairs(lootKeys) do
            local cb = CreateFrame("CheckButton", nil, panel.content, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("TOPLEFT", panel.content, "TOPLEFT", 8, -8 - (idx - 1) * 30)
            cb:SetChecked(settings.lootSubTabsVisible and settings.lootSubTabsVisible[key] ~= false)
            local keyCopy = key
            cb:SetScript("OnClick", function(self)
                OnCheckChanged("loot", keyCopy, self)
            end)
            local lab = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lab:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            lab:SetText(key)
            lab:SetTextColor(1, 0.82, 0, 1)
        end
    elseif active == "Alert" then
        local alertKeys = { "Dung", "Raid", "WG", "Arena", "Random", "Enemy", "Buffs", "Debuffs", "Item" }
        for idx, key in ipairs(alertKeys) do
            local cb = CreateFrame("CheckButton", nil, panel.content, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("TOPLEFT", panel.content, "TOPLEFT", 8, -8 - (idx - 1) * 30)
            cb:SetChecked(settings.alertSubTabsVisible and settings.alertSubTabsVisible[key] ~= false)
            local keyCopy = key
            cb:SetScript("OnClick", function(self)
                OnCheckChanged("alert", keyCopy, self)
            end)
            local lab = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lab:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            lab:SetText(key)
            lab:SetTextColor(1, 0.82, 0, 1)
        end
    elseif active == "Price" then
        local priceKeys = { "Chart", "List", "Bank", "Recipes" }
        for idx, key in ipairs(priceKeys) do
            local cb = CreateFrame("CheckButton", nil, panel.content, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("TOPLEFT", panel.content, "TOPLEFT", 8, -8 - (idx - 1) * 30)
            cb:SetChecked(settings.priceSubTabsVisible and settings.priceSubTabsVisible[key] ~= false)
            local keyCopy = key
            cb:SetScript("OnClick", function(self)
                OnCheckChanged("price", keyCopy, self)
            end)
            local lab = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lab:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            lab:SetText(key)
            lab:SetTextColor(1, 0.82, 0, 1)
        end
        -- Divider below the sub-tab checkboxes (created once, reused)
        local divider = panel.priceDivider
        if not divider then
            divider = panel.content:CreateTexture(nil, "ARTWORK")
            divider:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
            divider:SetHeight(8)
            panel.priceDivider = divider
        end
        divider:ClearAllPoints()
        divider:SetPoint("TOPLEFT", panel.content, "TOPLEFT", 8, -8 - #priceKeys * 30)
        divider:SetPoint("TOPRIGHT", panel.content, "TOPRIGHT", -8, -8 - #priceKeys * 30)
        divider:Show()
        -- Scan auction house checkbox below the divider
        local cb = CreateFrame("CheckButton", nil, panel.content, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("TOPLEFT", panel.content, "TOPLEFT", 8, -8 - #priceKeys * 30 - 14)
        cb:SetChecked(settings.ahScanningEnabled and true or false)
        cb:SetScript("OnClick", function(self)
            DetaurBar.Data.InitializeDB()
            settings.ahScanningEnabled = self:GetChecked() and true or false
        end)
        local lab = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lab:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        lab:SetText("Scan auction house")
        lab:SetTextColor(1, 0.82, 0, 1)
    elseif active == "Various" then
        local variousKeys = {
            { key = "autoSellRepairEnabled", label = "Autosell junk and autorepair" },
            { key = "showAlertsInChat", label = "Show alerts in chat" },
            { key = "ignoreYellEnabled", label = "Ignore Yell" },
        }
        for idx, entry in ipairs(variousKeys) do
            local cb = CreateFrame("CheckButton", nil, panel.content, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("TOPLEFT", panel.content, "TOPLEFT", 8, -8 - (idx - 1) * 30)
            cb:SetChecked(settings[entry.key] and true or false)
            cb:SetScript("OnClick", function(self)
                DetaurBar.Data.InitializeDB()
                settings[entry.key] = self:GetChecked() and true or false
            end)
            local lab = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lab:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            lab:SetText(entry.label)
            lab:SetTextColor(1, 0.82, 0, 1)
        end
        -- Divider below the 3 base checkboxes (created once, reused)
        local divider = panel.variousDivider
        if not divider then
            divider = panel.content:CreateTexture(nil, "ARTWORK")
            divider:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
            divider:SetHeight(8)
            panel.variousDivider = divider
        end
        divider:ClearAllPoints()
        divider:SetPoint("TOPLEFT", panel.content, "TOPLEFT", 8, -8 - #variousKeys * 30)
        divider:SetPoint("TOPRIGHT", panel.content, "TOPRIGHT", -8, -8 - #variousKeys * 30)
        divider:Show()

        -- Show armor master checkbox
        local showArmorCb = CreateFrame("CheckButton", nil, panel.content, "UICheckButtonTemplate")
        showArmorCb:SetSize(20, 20)
        showArmorCb:SetPoint("TOPLEFT", panel.content, "TOPLEFT", 8, -8 - #variousKeys * 30 - 14)
        showArmorCb:SetChecked(settings.showArmorEnabled and true or false)
        showArmorCb:SetScript("OnClick", function(self)
            DetaurBar.Data.InitializeDB()
            settings.showArmorEnabled = self:GetChecked() and true or false
        end)
        local showArmorLab = showArmorCb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        showArmorLab:SetPoint("LEFT", showArmorCb, "RIGHT", 4, 0)
        showArmorLab:SetText("Show armor")
        showArmorLab:SetTextColor(1, 0.82, 0, 1)

        -- 4 armor-type rows: checkbox + label + icon button
        local armorTypes = { "Mail", "Plate", "Cloth", "Leather" }
        local armorIcons = {
            Mail = "Interface\\Icons\\INV_Chest_Chain_03",
            Plate = "Interface\\Icons\\INV_Chest_Plate03",
            Cloth = "Interface\\Icons\\INV_Chest_Cloth_06",
            Leather = "Interface\\Icons\\INV_Chest_Leather_04",
        }
        for idx, armorKey in ipairs(armorTypes) do
            local rowY = -8 - #variousKeys * 30 - 14 - 30 - (idx - 1) * 30
            local cb = CreateFrame("CheckButton", nil, panel.content, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("TOPLEFT", panel.content, "TOPLEFT", 8, rowY)
            cb:SetChecked(settings["armorShow" .. armorKey] ~= false)
            cb:SetScript("OnClick", function(self)
                DetaurBar.Data.InitializeDB()
                settings["armorShow" .. armorKey] = self:GetChecked() and true or false
            end)
            local lab = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lab:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            lab:SetText(armorKey)
            lab:SetTextColor(1, 0.82, 0, 1)

            local iconBtn = CreateFrame("Button", nil, panel.content)
            iconBtn:SetSize(24, 24)
            iconBtn:SetPoint("LEFT", lab, "RIGHT", 8, 0)
            local iconTex = iconBtn:CreateTexture(nil, "ARTWORK")
            iconTex:SetAllPoints(iconBtn)
            iconBtn.iconTexture = iconTex
            iconBtn.armorKey = armorKey
            iconBtn:SetScript("OnClick", function(self)
                DetaurBar.Data.InitializeDB()
                local picker = DetaurBar.UI.armorIconPickerPanel
                if not picker then
                    DetaurBar.UI.CreateArmorIconPicker()
                    picker = DetaurBar.UI.armorIconPickerPanel
                end
                picker.selectedArmorType = self.armorKey
                picker:ClearAllPoints()
                picker:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
                picker:SetFrameStrata("DIALOG")
                picker:Show()
                picker:Raise()
            end)
            local function UpdateArmorIconTex()
                local iconPath = settings.armorIcons and settings.armorIcons[armorKey] or armorIcons[armorKey]
                iconTex:SetTexture(iconPath)
                iconTex:Show()
            end
            UpdateArmorIconTex()
            iconBtn.UpdateIcon = UpdateArmorIconTex
            panel.armorIconButtons = panel.armorIconButtons or {}
            panel.armorIconButtons[armorKey] = iconBtn
        end

        -- If icon picker exists, hide it on sub-tab rebuild and refresh shown icons
        if panel.armorIconPickerPanel then
            panel.armorIconPickerPanel:Hide()
        end
        for _, btn in pairs(panel.armorIconButtons or {}) do
            if btn.UpdateIcon then btn.UpdateIcon() end
        end
    end
end

local function CreateSettingsMenuPanel()
    if DetaurBar.UI.settingsMenuPanel then return end

    -- Panel is an INVISIBLE container (no own visual box)
    local panel = CreateFrame("Frame", nil, frame)
    panel:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
    panel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 36)
    panel:SetFrameLevel(frame:GetFrameLevel() + 10)
    panel:EnableMouse(true)
    panel:Hide()

    -- Sub-tab bar hore, bez pozadia
    local subTabBar = CreateFrame("Frame", nil, panel)
    subTabBar:SetHeight(24)
    subTabBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    subTabBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)

    local subTabButtons = {}
    local gap = 1

    for i, name in ipairs(smSettingsSubTabNames) do
        local st = CreateFrame("Button", nil, panel)
        st:SetHeight(24)
        st.tabName = name
        st:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 12, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        local lab = st:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lab:SetPoint("CENTER")
        lab:SetText(name)
        st.label = lab
        local hl = st:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(st)
        hl:SetTexture(1.0, 0.82, 0.0, 0.12)
        st:SetScript("OnClick", function()
            DetaurBar.UI.settingsMenuActiveSubTab = name
            RebuildSettingsMenuCheckboxes()
        end)
        subTabButtons[i] = st
    end

    local function LayoutSettingsMenuSubTabs()
        local totalW = subTabBar:GetWidth()
        if totalW <= 0 then return end
        local n = #subTabButtons
        local w = (totalW - gap * (n - 1)) / n
        for i, st in ipairs(subTabButtons) do
            st:SetWidth(w)
            st:ClearAllPoints()
            if i == 1 then
                st:SetPoint("TOPLEFT", subTabBar, "TOPLEFT", 0, 0)
            else
                st:SetPoint("TOPLEFT", subTabButtons[i-1], "TOPRIGHT", gap, 0)
            end
        end
    end

    subTabBar:SetScript("OnSizeChanged", LayoutSettingsMenuSubTabs)
    LayoutSettingsMenuSubTabs()
    DetaurBar.UI.settingsSubTabBar = subTabBar
    subTabBar.subTabButtons = subTabButtons
    panel.subTabButtons = subTabButtons

    -- NEW separate dark box for content — with proper gap from tabs (28px, like Loot)
    local listBg = CreateFrame("Frame", nil, panel)
    listBg:SetPoint("TOPLEFT", subTabBar, "BOTTOMLEFT", -1, -2)
    listBg:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    listBg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    listBg:SetBackdropColor(0, 0, 0, 0.4)
    listBg:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)

    -- content is child of listBg, not the panel directly
    local content = CreateFrame("Frame", nil, listBg)
    content:SetPoint("TOPLEFT", listBg, "TOPLEFT", 4, -4)
    content:SetPoint("BOTTOMRIGHT", listBg, "BOTTOMRIGHT", -4, 4)
    panel.content = content

    DetaurBar.UI.settingsMenuPanel = panel
end

-- [SETTINGS MENU] Armor icon picker — small panel with preset armor icons
local ARMOR_PICKER_ICONS = {
    "Interface\\Icons\\INV_Chest_Chain_03",
    "Interface\\Icons\\INV_Chest_Chain_07",
    "Interface\\Icons\\INV_Chest_Chain_08",
    "Interface\\Icons\\INV_Chest_Chain_12",
    "Interface\\Icons\\INV_Chest_Plate03",
    "Interface\\Icons\\INV_Chest_Plate04",
    "Interface\\Icons\\INV_Chest_Plate05",
    "Interface\\Icons\\INV_Chest_Plate06",
    "Interface\\Icons\\INV_Chest_Plate08",
    "Interface\\Icons\\INV_Chest_Plate10",
    "Interface\\Icons\\INV_Chest_Cloth_01",
    "Interface\\Icons\\INV_Chest_Cloth_06",
    "Interface\\Icons\\INV_Chest_Cloth_07",
    "Interface\\Icons\\INV_Chest_Cloth_08",
    "Interface\\Icons\\INV_Chest_Cloth_09",
    "Interface\\Icons\\INV_Chest_Cloth_10",
    "Interface\\Icons\\INV_Chest_Leather_01",
    "Interface\\Icons\\INV_Chest_Leather_02",
    "Interface\\Icons\\INV_Chest_Leather_04",
    "Interface\\Icons\\INV_Chest_Leather_05",
    "Interface\\Icons\\INV_Chest_Leather_06",
    "Interface\\Icons\\INV_Chest_Leather_07",
    "Interface\\Icons\\INV_Chest_Leather_08",
    "Interface\\Icons\\INV_Chest_Leather_10",
    "Interface\\Icons\\INV_Misc_ArmorKit_02",
    "Interface\\Icons\\INV_Shoulder_24",
    "Interface\\Icons\\INV_Shoulder_25",
    "Interface\\Icons\\INV_Shoulder_31",
    "Interface\\Icons\\INV_Shoulder_32",
    "Interface\\Icons\\INV_Helmet_12",
    "Interface\\Icons\\INV_Helmet_13",
    "Interface\\Icons\\INV_Helmet_15",
}

function DetaurBar.UI.CreateArmorIconPicker()
    if DetaurBar.UI.armorIconPickerPanel then return end
    local picker = CreateFrame("Frame", "DetaurBarArmorIconPicker", UIParent)
    picker:SetSize(170, 160)
    picker:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    picker:SetBackdropColor(0.1, 0.08, 0.06, 0.98)
    picker:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.9)
    picker:EnableMouse(true)
    picker:Hide()

    local cols = 4
    local size = 36
    local gap = 4
    local pickerButtons = {}
    for i, iconPath in ipairs(ARMOR_PICKER_ICONS) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local btn = CreateFrame("Button", nil, picker)
        btn:SetSize(size, size)
        btn:SetPoint("TOPLEFT", picker, "TOPLEFT", 6 + col * (size + gap), -6 - row * (size + gap))
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(btn)
        tex:SetTexture(iconPath)
        btn.iconPath = iconPath
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(btn)
        hl:SetTexture(1.0, 1.0, 1.0, 0.2)
        btn:SetScript("OnClick", function(self)
            DetaurBar.Data.InitializeDB()
            local armorType = picker.selectedArmorType
            if armorType then
                DetaurBarDB.settings.armorIcons = DetaurBarDB.settings.armorIcons or {}
                DetaurBarDB.settings.armorIcons[armorType] = self.iconPath
                picker:Hide()
                local panel = DetaurBar.UI.settingsMenuPanel
                if panel and panel.armorIconButtons and panel.armorIconButtons[armorType] then
                    panel.armorIconButtons[armorType].iconTexture:SetTexture(self.iconPath)
                end
            end
        end)
        pickerButtons[i] = btn
    end

    picker.SetSelectedArmorType = function(self, armorType)
        self.selectedArmorType = armorType
    end
    picker.Close = function(self)
        self:Hide()
    end

    -- Close on ESC / click outside handled by frame OnUpdate guard (simple hide)
    picker:SetScript("OnMouseDown", function(self)
        self:Hide()
    end)

    picker:Hide()
    DetaurBar.UI.armorIconPickerPanel = picker
end

-- [STATE] Tab names, active tab
local tabs = {}
local tabNames = { "Notes", "Loot", "Price", "Settings" }
local activeTab = "Notes"

local function SetTabButtonsActive(active)
    for _, tab in ipairs(tabs) do
        if active and tab.tabName == active then
            tab:Disable()
        else
            tab:Enable()
        end
    end
end

function DetaurBar.UI.ToggleSettingsMenu()
    if not DetaurBar.UI.settingsMenuPanel then
        CreateSettingsMenuPanel()
    end
    local panel = DetaurBar.UI.settingsMenuPanel
    if panel:IsShown() then
        if DetaurBar.UI.armorIconPickerPanel then
            DetaurBar.UI.armorIconPickerPanel:Hide()
        end
        panel:Hide()
        DetaurBar.UI.settingsMenuPanelVisible = false
        DetaurBar.UI.SelectTab("Notes")
        return
    end
    DetaurBar.UI.settingsMenuPanelVisible = true
    SetTabButtonsActive(nil)
    DetaurBar.UI.UpdateContentAnchors()
    DetaurBar.UI.settingsMenuActiveSubTab = "Loot"
    RebuildSettingsMenuCheckboxes()
    panel:Show()
end

-- [STATE] Settings sub-tabs array (populated by DetaurBar_UI_Settings.lua)
DetaurBar.UI.alertSubTabs = {}
DetaurBar.UI.activeAlertSubTab = "Dung"

-- [STATE] Settings panel/bar references
DetaurBar.UI.alertPanel = nil
DetaurBar.UI.alertSubTabBar = nil
DetaurBar.UI.alertListBackground = nil

-- [STATE] Sub-tab tables (initialized empty; populated by tab files loaded after this)
DetaurBar.UI.todoSubTabs = {}
DetaurBar.UI.notesSubTabs = {}
DetaurBar.UI.lootSubTabs = {}
DetaurBar.UI.priceItemSubTabs = {}

-- [HELPERS] Category string builder
function DetaurBar.UI.GetNotesCategory(subTabName)
    return "tasks_" .. subTabName:lower()
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

-- [ITEM HELPERS] GetItemThresholds — returns the tracked price item (with threshold/thresholdHigh) for an itemId, or nil
function DetaurBar.UI.GetItemThresholds(itemId)
    if not itemId then return nil end
    local items = DetaurBar.Data.GetItems("price")
    for _, item in ipairs(items) do
        if DetaurBar.UI.GetItemIdFromText(item.title) == itemId then
            return item
        end
    end
    return nil
end

-- [ITEM HELPERS] GetItemThresholdText — small colored "Xg Yg" string if the item is tracked with thresholds
function DetaurBar.UI.GetItemThresholdText(itemId)
    local item = DetaurBar.UI.GetItemThresholds(itemId)
    if not item then return nil end
    local low = item.threshold and item.threshold > 0 and item.threshold
    local high = item.thresholdHigh and item.thresholdHigh > 0 and item.thresholdHigh
    if not low and not high then return nil end
    local t = ""
    if low then t = "|cffffd700" .. low .. "G|r" end
    if high then
        if low then t = t .. "  " end
        t = t .. "|cffff8000" .. high .. "G|r"
    end
    return t
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
            if newItem and category == "price" and DetaurBar.UI.IsNewsView() then
                newItem.frequent = true
            end
            ClearCursor()
            DetaurBar.UI.RefreshTasks()
        end
    end
end

-- [MAIN FRAME] Register drag-drop receiver on main frame
frame:SetScript("OnReceiveDrag", OnReceiveDragHandler)


-- [TABS] Create main tab buttons (Notes, Loot, Price, Settings)
for i, name in ipairs(tabNames) do
    local tab = CreateFrame("Button", "DetaurBarTab_" .. name, frame, "UIPanelButtonTemplate")
    tab:SetHeight(22)
    tab.tabName = name
    local displayName = ({ Notes = "Note", Loot = "Loot", Price = "Price", Settings = "Alert" })[name] or name
    tab:SetText(displayName)
    
    tab:SetScript("OnClick", function()
        DetaurBar.UI.SelectTab(name)
    end)
    
    tabs[i] = tab
end

-- Sub-tab creation moved to DetaurBar_UI_Notes.lua, DetaurBar_UI_Loot.lua, DetaurBar_UI_Price.lua

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
    
    DetaurBar.UI.LayoutNotesSubTabs()
    local subTabGap = 1
    local visibleLoot = {}
    for _, subTab in ipairs(DetaurBar.UI.lootSubTabs) do
        local settings = DetaurBar.UI.GetSettingsDB()
        if settings.lootSubTabsVisible and settings.lootSubTabsVisible[subTab.tabName] ~= false then
            table.insert(visibleLoot, subTab)
        end
    end
    if #visibleLoot > 0 then
        local lootSubTabWidth = (totalWidth - subTabGap * (#visibleLoot - 1)) / #visibleLoot
        for i, subTab in ipairs(visibleLoot) do
            subTab:SetWidth(lootSubTabWidth)
            subTab:ClearAllPoints()
            if i == 1 then
                subTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
            else
                subTab:SetPoint("LEFT", visibleLoot[i-1], "RIGHT", subTabGap, 0)
            end
        end
    end

    local visiblePrice = {}
    local settings = DetaurBar.UI.GetSettingsDB()
    for _, subTab in ipairs(DetaurBar.UI.priceItemSubTabs) do
        if settings.priceSubTabsVisible and settings.priceSubTabsVisible[subTab.tabName] ~= false then
            table.insert(visiblePrice, subTab)
        end
    end
    if #visiblePrice > 0 then
        local priceItemSubTabWidth = (totalWidth - subTabGap * (#visiblePrice - 1)) / #visiblePrice
        for i, subTab in ipairs(visiblePrice) do
            subTab:SetWidth(priceItemSubTabWidth)
            subTab:ClearAllPoints()
            if i == 1 then
                subTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
            else
                subTab:SetPoint("LEFT", visiblePrice[i-1], "RIGHT", subTabGap, 0)
            end
        end
    end

    if DetaurBar.UI.alertSubTabBar then
        DetaurBar.UI.alertSubTabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -60)
        DetaurBar.UI.alertSubTabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -60)
        DetaurBar.UI.UpdateAlertSubTabBar()
    end
end

-- [STATE] Scroll/graph bar/price graph/price sub-tab/settings scroll declarations
local scrollFrame
DetaurBar.UI.priceGraphHolder = { graphTextures = {}, graphLabels = {}, graphFrames = {} }
DetaurBar.UI.alertScrollFrame = nil
DetaurBar.UI.alertScrollChild = nil
DetaurBar.UI.alertSaveButton = nil

-- [LAYOUT] UpdateContentAnchors — hides settings UI or main scroll/graph based on activeTab
function DetaurBar.UI.UpdateContentAnchors()
    if DetaurBar.UI.settingsMenuPanel and DetaurBar.UI.settingsMenuPanelVisible then
        DetaurBar.UI.settingsMenuPanel:Show()
        if DetaurBar.UI.alertPanel then DetaurBar.UI.alertPanel:Hide() end
        if DetaurBar.UI.alertSubTabBar then DetaurBar.UI.alertSubTabBar:Hide() end
        if DetaurBar.UI.alertListBackground then DetaurBar.UI.alertListBackground:Hide() end
        if DetaurBar.UI.alertScrollFrame then DetaurBar.UI.alertScrollFrame:Hide() end
        if DetaurBar.UI.alertScrollChild then DetaurBar.UI.alertScrollChild:Hide() end
        if scrollFrame then scrollFrame:Hide() end
        if DetaurBar.UI.listBackground then DetaurBar.UI.listBackground:Hide() end
        if DetaurBar.UI.notesTabContainer then DetaurBar.UI.notesTabContainer:Hide() end
        if DetaurBar.UI.notesCatControls then DetaurBar.UI.notesCatControls:Hide() end
        if DetaurBar.UI.notesTabLeftArrow then DetaurBar.UI.notesTabLeftArrow:Hide() end
        if DetaurBar.UI.notesTabRightArrow then DetaurBar.UI.notesTabRightArrow:Hide() end
        for _, subTab in ipairs(DetaurBar.UI.lootSubTabs) do subTab:Hide() end
        for _, subTab in ipairs(DetaurBar.UI.priceItemSubTabs) do subTab:Hide() end
        if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
        if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
        if DetaurBar.UI.deleteAllGraysCheckbox then DetaurBar.UI.deleteAllGraysCheckbox:Hide() end
        if DetaurBar.UI.editBox then DetaurBar.UI.editBox:Hide() end
        if DetaurBar.UI.addButton then DetaurBar.UI.addButton:Hide() end
        if DetaurBar.UI.bankPanel then DetaurBar.UI.bankPanel:Hide() end
        if DetaurBar.UI.priceChartToolbar then DetaurBar.UI.priceChartToolbar:Hide() end
        if DetaurBar.UI.priceListPanel then DetaurBar.UI.priceListPanel:Hide() end
        if DetaurBar.UI.priceListControls then DetaurBar.UI.priceListControls:Hide() end
        if DetaurBar.UI.recipesPanel then DetaurBar.UI.recipesPanel:Hide() end
        return
    end
    if DetaurBar.UI.settingsMenuPanel then DetaurBar.UI.settingsMenuPanel:Hide() end
    if activeTab == "Settings" then
        if scrollFrame then scrollFrame:Hide() end
        if DetaurBar.UI.listBackground then DetaurBar.UI.listBackground:Hide() end
        if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
        if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
        if DetaurBar.UI.priceChartToolbar then DetaurBar.UI.priceChartToolbar:Hide() end
        if DetaurBar.UI.priceListPanel then DetaurBar.UI.priceListPanel:Hide() end
        if DetaurBar.UI.priceListControls then DetaurBar.UI.priceListControls:Hide() end
        if DetaurBar.UI.recipesPanel then DetaurBar.UI.recipesPanel:Hide() end
        if DetaurBar.UI.alertSubTabBar then DetaurBar.UI.alertSubTabBar:Show() end
        if DetaurBar.UI.alertListBackground then DetaurBar.UI.alertListBackground:Show() end
        if DetaurBar.UI.alertScrollFrame then DetaurBar.UI.alertScrollFrame:Show() end
        if DetaurBar.UI.alertPanel then DetaurBar.UI.alertPanel:Show() end
        if DetaurBar.UI.alertScrollChild then DetaurBar.UI.alertScrollChild:Show() end
        return
    end

    if DetaurBar.UI.alertPanel then
        DetaurBar.UI.alertPanel:Hide()
    end
    if DetaurBar.UI.alertSubTabBar then
        DetaurBar.UI.alertSubTabBar:Hide()
    end
    if DetaurBar.UI.alertListBackground then
        DetaurBar.UI.alertListBackground:Hide()
    end
    if DetaurBar.UI.alertScrollFrame then
        DetaurBar.UI.alertScrollFrame:Hide()
    end
    if DetaurBar.UI.bankPanel and activeTab ~= "Price" then
        DetaurBar.UI.bankPanel:Hide()
    end
    if activeTab ~= "Notes" then
        if DetaurBar.UI.notesTabContainer then DetaurBar.UI.notesTabContainer:Hide() end
        if DetaurBar.UI.notesCatControls then DetaurBar.UI.notesCatControls:Hide() end
        if DetaurBar.UI.notesTabLeftArrow then DetaurBar.UI.notesTabLeftArrow:Hide() end
        if DetaurBar.UI.notesTabRightArrow then DetaurBar.UI.notesTabRightArrow:Hide() end
    end

    scrollFrame:ClearAllPoints()
    if activeTab == "Price" and DetaurBar.UI.activePriceItemSubTab == "Chart" then
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -120)
    elseif activeTab == "Price" and DetaurBar.UI.activePriceItemSubTab == "List" then
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -150)
    elseif activeTab == "Price" and DetaurBar.UI.activePriceItemSubTab == "Recipes" then
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -122)
    elseif activeTab == "Notes" or activeTab == "Price" then
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
            local settings = DetaurBar.UI.GetSettingsDB()
            if DetaurBar.UI.priceChartToolbar then DetaurBar.UI.priceChartToolbar:Show() end
            if scrollFrame then scrollFrame:Show() end
            if DetaurBar.UI.listBackground then DetaurBar.UI.listBackground:Show() end
            if DetaurBar.UI.bankPanel then DetaurBar.UI.bankPanel:Hide() end
            if DetaurBar.UI.priceListPanel then DetaurBar.UI.priceListPanel:Hide() end
            if DetaurBar.UI.priceListControls then DetaurBar.UI.priceListControls:Hide() end
            if DetaurBar.UI.recipesPanel then DetaurBar.UI.recipesPanel:Hide() end

            if DetaurBar.UI.newsViewActive then
                -- News view: interval row at the bottom
                if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
                if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
                if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
                if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Show() end
                scrollFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 50)
                scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 50)
            else
                -- Classic chart view
                if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end

                -- Graph panel + sub-tab bar + re-anchor threshold row
                if settings.chartGraphVisible then
                    if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Show() end
                    if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Show() end
                    DetaurBar.UI.priceThresholdRow:ClearAllPoints()
                    DetaurBar.UI.priceThresholdRow:SetPoint("BOTTOMLEFT", DetaurBar.UI.priceSubTabBar, "TOPLEFT", 0, 4)
                    DetaurBar.UI.priceThresholdRow:SetPoint("BOTTOMRIGHT", DetaurBar.UI.priceSubTabBar, "TOPRIGHT", 0, 4)
                else
                    if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
                    if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
                    DetaurBar.UI.priceThresholdRow:ClearAllPoints()
                    DetaurBar.UI.priceThresholdRow:SetPoint("BOTTOMLEFT", DetaurBar.UI.frame, "BOTTOMLEFT", 16, 46)
                    DetaurBar.UI.priceThresholdRow:SetPoint("BOTTOMRIGHT", DetaurBar.UI.frame, "BOTTOMRIGHT", -20, 46)
                end

                -- Scroll bottom anchor based on visible elements
                if settings.chartThresholdVisible then
                    if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Show() end
                    scrollFrame:SetPoint("BOTTOMLEFT", DetaurBar.UI.priceThresholdRow, "TOPLEFT", 0, 4)
                    scrollFrame:SetPoint("BOTTOMRIGHT", DetaurBar.UI.priceThresholdRow, "TOPRIGHT", -16, 4)
                elseif settings.chartGraphVisible then
                    if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
                    scrollFrame:SetPoint("BOTTOMLEFT", DetaurBar.UI.priceSubTabBar, "TOPLEFT", 0, 4)
                    scrollFrame:SetPoint("BOTTOMRIGHT", DetaurBar.UI.priceSubTabBar, "TOPRIGHT", -16, 4)
                else
                    if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
                    scrollFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 50)
                    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 50)
                end
            end
        elseif DetaurBar.UI.activePriceItemSubTab == "Bank" then
            if scrollFrame then scrollFrame:Hide() end
            if DetaurBar.UI.listBackground then DetaurBar.UI.listBackground:Hide() end
            if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
            if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
            if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
            if DetaurBar.UI.priceChartToolbar then DetaurBar.UI.priceChartToolbar:Hide() end
            if DetaurBar.UI.priceListPanel then DetaurBar.UI.priceListPanel:Hide() end
            if DetaurBar.UI.priceListControls then DetaurBar.UI.priceListControls:Hide() end
            if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
            if DetaurBar.UI.bankPanel then DetaurBar.UI.bankPanel:Show() end
            if DetaurBar.UI.recipesPanel then DetaurBar.UI.recipesPanel:Hide() end
            elseif DetaurBar.UI.activePriceItemSubTab == "List" then
            if scrollFrame then scrollFrame:Show() end
            if DetaurBar.UI.listBackground then DetaurBar.UI.listBackground:Show() end
            scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 50)
            if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
            if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
            if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
            if DetaurBar.UI.priceChartToolbar then DetaurBar.UI.priceChartToolbar:Hide() end
            if DetaurBar.UI.priceListPanel then DetaurBar.UI.priceListPanel:Show() end
            if DetaurBar.UI.priceListControls then DetaurBar.UI.priceListControls:Show() end
            if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
            if DetaurBar.UI.bankPanel then DetaurBar.UI.bankPanel:Hide() end
            if DetaurBar.UI.recipesPanel then DetaurBar.UI.recipesPanel:Hide() end
            elseif DetaurBar.UI.activePriceItemSubTab == "Recipes" then
            if scrollFrame then scrollFrame:Show() end
            if DetaurBar.UI.listBackground then DetaurBar.UI.listBackground:Show() end
            scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 50)
            if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
            if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
            if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
            if DetaurBar.UI.priceChartToolbar then DetaurBar.UI.priceChartToolbar:Hide() end
            if DetaurBar.UI.priceListPanel then DetaurBar.UI.priceListPanel:Hide() end
            if DetaurBar.UI.priceListControls then DetaurBar.UI.priceListControls:Hide() end
            if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
            if DetaurBar.UI.bankPanel then DetaurBar.UI.bankPanel:Hide() end
            if DetaurBar.UI.recipesPanel then DetaurBar.UI.recipesPanel:Show() end
            else
            -- Fallback (News-like default layout)
            if scrollFrame then scrollFrame:Show() end
            if DetaurBar.UI.listBackground then DetaurBar.UI.listBackground:Show() end
            scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 50)
            if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
            if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
            if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
            if DetaurBar.UI.priceChartToolbar then DetaurBar.UI.priceChartToolbar:Hide() end
            if DetaurBar.UI.priceListPanel then DetaurBar.UI.priceListPanel:Hide() end
            if DetaurBar.UI.priceListControls then DetaurBar.UI.priceListControls:Hide() end
            if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
            if DetaurBar.UI.bankPanel then DetaurBar.UI.bankPanel:Hide() end
            if DetaurBar.UI.recipesPanel then DetaurBar.UI.recipesPanel:Hide() end
            end
    elseif activeTab == "Notes" then
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 84)
        if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
        if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
        if DetaurBar.UI.priceChartToolbar then DetaurBar.UI.priceChartToolbar:Hide() end
        if DetaurBar.UI.priceListPanel then DetaurBar.UI.priceListPanel:Hide() end
        if DetaurBar.UI.priceListControls then DetaurBar.UI.priceListControls:Hide() end
        if DetaurBar.UI.recipesPanel then DetaurBar.UI.recipesPanel:Hide() end
    else
        scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -36, 50)
        if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
        if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
        if DetaurBar.UI.priceChartToolbar then DetaurBar.UI.priceChartToolbar:Hide() end
        if DetaurBar.UI.priceListPanel then DetaurBar.UI.priceListPanel:Hide() end
        if DetaurBar.UI.priceListControls then DetaurBar.UI.priceListControls:Hide() end
        if DetaurBar.UI.recipesPanel then DetaurBar.UI.recipesPanel:Hide() end
    end
end

-- [UI FACTORY] SetSimpleTooltip — OnEnter/OnLeave GameTooltip helper (used by both main UI and settings)
function DetaurBar.UI.SetSimpleTooltip(frame, title, text)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(title, 1.0, 1.0, 1.0)
        if text then
            if type(text) == "table" then
                for _, line in ipairs(text) do
                    GameTooltip:AddLine(line, 0.5, 0.5, 0.5)
                end
            else
                GameTooltip:AddLine(text, 0.5, 0.5, 0.5)
            end
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
local listBackground = CreateFrame("Frame", "DetaurBarListBackground_DEBUG", frame)
DetaurBar.UI.listBackground = listBackground
listBackground:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", -4, 4)
listBackground:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 24, -4)
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
    local step = (activeTab == "Price" and 150 or 20)
    scrollBar:SetValue(current - delta * step)
end)

listBackground:EnableMouseWheel(true)
listBackground:SetScript("OnMouseWheel", function(self, delta)
    local current = scrollBar:GetValue()
    local step = (activeTab == "Price" and 150 or 20)
    scrollBar:SetValue(current - delta * step)
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
-- Helper: price items visible under the current list filter (Chart/List sub-tab).
local function GetVisiblePriceItems()
    local items = DetaurBar.Data.GetItems("price")
    if not items then return nil end
    if DetaurBar.UI.IsNewsView() or DetaurBar.UI.activePriceItemSubTab == "Bank" or not DetaurBar.UI.activePriceListName then
        return items
    end
    if DetaurBar.UI.activePriceListName == "All" then
        return items
    end
    local filtered = {}
    for _, item in ipairs(items) do
        if DetaurBar.UI.activePriceListName == "Default" then
            if not item.list then
                table.insert(filtered, item)
            end
        elseif item.list == DetaurBar.UI.activePriceListName then
            table.insert(filtered, item)
        end
    end
    return filtered
end

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
    
    -- List Copy Button (copy item to a price list, rightmost)
    local listCopyBtn = CreateFrame("Button", nil, row)
    listCopyBtn:SetSize(21, 21)
    listCopyBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.listCopyBtn = listCopyBtn

    -- Swap Button (Up arrow for Price Order sub-tab)
    local swapBtn = CreateFrame("Button", nil, row)
    swapBtn:SetSize(21, 21)
    swapBtn:SetPoint("RIGHT", listCopyBtn, "LEFT", -2, 0)
    row.swapBtn = swapBtn

    -- Down Button (for Price Order sub-tab reordering)
    local downBtn = CreateFrame("Button", nil, row)
    downBtn:SetSize(21, 21)
    downBtn:SetPoint("RIGHT", swapBtn, "LEFT", -2, 0)
    row.downBtn = downBtn
    
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

    -- Very small threshold badge (Recipes sub-tab: LOW/HIGH gold thresholds for tracked items)
    local thresholdText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    thresholdText:SetFont("Fonts\\FRIZQT___CYR.ttf", 8, "OUTLINE")
    thresholdText:SetJustifyH("RIGHT")
    thresholdText:Hide()
    row.thresholdText = thresholdText
    
    -- Handle Shift-click on item row to link it to active chat frame, or click on notes to copy
    row:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            if row.isReagentRow then
                if row.reagentItemId then
                    local itemLink = DetaurBar.UI.GetUsableItemLink(row.reagentItemId)
                    if itemLink then
                        HandleModifiedItemClick(itemLink)
                    end
                end
                return
            end
            if IsShiftKeyDown() then
                if row.itemCategory == "price" and DetaurBar.UI.activePriceItemSubTab == "Recipes" then
                    local recipe
                    for _, r in ipairs(DetaurBar.Data.GetItems("recipes")) do
                        if r.id == self.itemId then recipe = r break end
                    end
                    if recipe then
                        local craftedId = recipe.itemId
                        if not craftedId and recipe.name then
                            craftedId = DetaurBar.UI.GetItemIdFromText(recipe.name)
                        end
                        if craftedId then
                            local itemLink = DetaurBar.UI.GetUsableItemLink(craftedId)
                            if itemLink then
                                HandleModifiedItemClick(itemLink)
                            end
                        end
                    end
                elseif row.itemCategory == "loot_add" or row.itemCategory == "loot_delete" or row.itemCategory == "sell" or row.itemCategory == "price" then
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
                    if DetaurBar.UI.activePriceItemSubTab == "Recipes" then
                        -- Recipes: click row to expand/collapse reagents
                        if DetaurBar.UI.expandedRecipeId == self.itemId then
                            DetaurBar.UI.expandedRecipeId = nil
                        else
                            DetaurBar.UI.expandedRecipeId = self.itemId
                        end
                        DetaurBar.UI.RefreshTasks()
                    else
                        -- News view: clicking an item jumps to the Chart view with its graph open
                        if DetaurBar.UI.IsNewsView() then
                            if not self.itemId then return end
                            DetaurBar.UI.expandedPriceItemId = self.itemId
                            DetaurBar.UI.newsViewActive = false
                            if DetaurBar.UI.newsViewToggle then DetaurBar.UI.newsViewToggle:UpdateVisualState() end
                            local newsSettings = DetaurBar.UI.GetSettingsDB()
                            newsSettings.chartGraphVisible = true
                            DetaurBar.UI.selectedPriceItemId = self.itemId
                            DetaurBar.UI.SelectPriceItemSubTab("Chart")
                            return
                        end
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
        end
    end)

    local function SetupClipboardEditBox()
        if not DetaurBar.ClipboardEditBox then
            DetaurBar.ClipboardEditBox = CreateFrame("EditBox", nil, UIParent)
            DetaurBar.ClipboardEditBox:SetSize(1, 1)
            DetaurBar.ClipboardEditBox:Hide()
            DetaurBar.ClipboardEditBox:SetScript("OnEditFocusLost", function(self)
                self:SetScript("OnUpdate", nil)
                self:Hide()
            end)
            DetaurBar.ClipboardEditBox:SetScript("OnKeyDown", function(self, key)
                if key == "ESCAPE" then
                    self:ClearFocus()
                end
            end)
        end
    end

    row:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and not draggedNote then
            if row.itemCategory and row.itemCategory:find("^tasks_") then
                local note = DetaurBar.Data.GetItemById(row.itemCategory, self.itemId)
                if note and note.title then
                    SetupClipboardEditBox()
                    local eb = DetaurBar.ClipboardEditBox
                    eb:SetText(note.title)
                    eb:HighlightText(0, note.title:len())
                    eb:SetScript("OnUpdate", function(self, elaps)
                        self.timer = (self.timer or 0) + elaps
                        if self.timer > 1 then
                            self:ClearFocus()
                            self:SetScript("OnUpdate", nil)
                            self.timer = nil
                        end
                    end)
                    eb.timer = 0
                    eb:Show()
                    eb:SetFocus()
                end
            end
        end
    end)
    
    -- Scripts & Interactions
    row:SetScript("OnEnter", function(self)
        self.bg:SetTexture(1.0, 0.82, 0.0, 0.1) -- Subtle gold highlight on hover
        
        -- GameTooltip hover support for item linking categories (Loot/Sell/Price)
        if row.isReagentRow then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            if row.reagentItemId then
                local _, serverLink = GetItemInfo(row.reagentItemId)
                if serverLink then
                    GameTooltip:SetHyperlink(serverLink)
                else
                    local name = DetaurBar.UI.GetOfflineItemNameById(row.reagentItemId)
                    GameTooltip:AddLine(name or (row.reagentName or "?"), 1.0, 1.0, 1.0)
                    GameTooltip:AddLine("ID: " .. row.reagentItemId, 0.7, 0.7, 0.7)
                end
            else
                GameTooltip:AddLine(row.reagentName or "?", 1.0, 1.0, 1.0)
            end
            if row.reagentItemId then
                GameTooltip:AddLine("Click to link to chat", 0.5, 0.5, 0.5)
            end
            GameTooltip:Show()
        elseif row.itemCategory == "loot_add" or row.itemCategory == "loot_delete" or row.itemCategory == "sell" or row.itemCategory == "price" then
            local itemDetail = DetaurBar.Data.GetItemById(row.itemCategory, self.itemId)
            if itemDetail and itemDetail.title then
                local itemLink = DetaurBar.UI.GetUsableItemLink(itemDetail.title)
                if itemLink then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    local itemId = DetaurBar.UI.GetItemIdFromText(itemDetail.title)
                    -- Try server first (if item is in client cache, shows full tooltip)
                    local _, serverLink, _, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(itemId or itemDetail.title)
                    if serverLink then
                        GameTooltip:SetHyperlink(serverLink)
                        if itemSellPrice and itemSellPrice > 0 then
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddDoubleLine("Sell Price:", DetaurBar.UI.FormatMoney(itemSellPrice), 1.0, 0.82, 0.0, 1.0, 1.0, 1.0)
                        end
                    else
                        -- Offline fallback: server does not have item in cache
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
        elseif row.itemCategory and row.itemCategory:find("^tasks_") then
            local note = DetaurBar.Data.GetItemById(row.itemCategory, self.itemId)
            if note and note.title then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine("Copy Note to Chat", 1.0, 1.0, 1.0)
                GameTooltip:AddLine("Click anywhere on this task.", 0.5, 0.5, 0.5)
                GameTooltip:AddLine("You have 1 second to press Ctrl+C.", 0.5, 0.5, 0.5)
                GameTooltip:Show()
            end
        end
    end)
    
    row:SetScript("OnLeave", function(self)
        self.bg:SetTexture(0, 0, 0, 0)
        GameTooltip:Hide()
    end)

    row:SetScript("OnDragStart", function(self)
        if self.itemId and self.itemCategory and self.itemCategory:find("^tasks_") then
            DetaurBar.UI.StartDraggedNote(self.itemCategory, self.itemId)
            self.bg:SetTexture(1.0, 0.82, 0.0, 0.18)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Move Task", 1.0, 1.0, 1.0)
            GameTooltip:AddLine("Drop this task on a category tab above.", 0.5, 0.5, 0.5)
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
            if row.itemCategory == "price" and DetaurBar.UI.activePriceItemSubTab == "Recipes" then
                DetaurBar.Data.DeleteRecipe(row.itemId)
                if DetaurBar.UI.expandedRecipeId == row.itemId then
                    DetaurBar.UI.expandedRecipeId = nil
                end
            elseif row.itemCategory == "price" and DetaurBar.UI.IsNewsView() then
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
                local deletedName = nil
                if row.itemCategory == "price" then
                    local item = DetaurBar.Data.GetItemById("price", row.itemId)
                    if item then
                        local itemId = DetaurBar.UI.GetItemIdFromText(item.title)
                        if itemId then
                            deletedName = DetaurBar.Data.GetItemName(itemId)
                        end
                        if not deletedName then
                            deletedName = item.title
                        end
                    end
                end
                DetaurBar.Data.DeleteItem(row.itemCategory, row.itemId)
                if row.itemCategory == "price" and DetaurBar.UI.expandedPriceItemId == row.itemId then
                    DetaurBar.UI.expandedPriceItemId = nil
                end
                if deletedName then
                    DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ff[DetaurBar]|r Deleted: " .. deletedName)
                end
            end
            DetaurBar.UI.RefreshTasks()
        end
    end)

    deleteBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        if row.itemCategory == "price" and DetaurBar.UI.activePriceItemSubTab == "Recipes" then
            GameTooltip:AddLine("Delete Recipe", 1.0, 1.0, 1.0)
            GameTooltip:AddLine("Removes this recipe from the list.", 0.5, 0.5, 0.5)
        elseif row.itemCategory == "price" and DetaurBar.UI.IsNewsView() then
            GameTooltip:AddLine("Remove Alert", 1.0, 1.0, 1.0)
            GameTooltip:AddLine("Removes this item from the alert list", 0.5, 0.5, 0.5)
            GameTooltip:AddLine("and clears its threshold.", 0.5, 0.5, 0.5)
        else
            GameTooltip:AddLine("Delete", 1.0, 1.0, 1.0)
            GameTooltip:AddLine("Removes this item from the list.", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    deleteBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    swapBtn:SetScript("OnClick", function(self)
        if row.itemId and row.itemCategory == "loot_add" then
            local item = DetaurBar.Data.GetItemById(row.itemCategory, row.itemId)
            if item then
                DetaurBar.Data.AddItem("price", item.title)
                DetaurBar.UI.RefreshTasks()
            end
        elseif row.itemId and row.itemCategory == "price" and DetaurBar.UI.activePriceItemSubTab == "Chart" and DetaurBar.UI.GetSettingsDB().chartOrderMode then
            local items = DetaurBar.Data.GetItems("price")
            if not items then return end
            local visible = GetVisiblePriceItems()
            if not visible then return end
            local idx
            for i, v in ipairs(visible) do
                if v.id == row.itemId then idx = i; break end
            end
            if idx and idx > 1 then
                local target = visible[idx-1]
                local rowIdx, targetIdx
                for i, v in ipairs(items) do
                    if v.id == row.itemId then rowIdx = i end
                    if v.id == target.id then targetIdx = i end
                end
                if rowIdx and targetIdx then
                    items[rowIdx], items[targetIdx] = items[targetIdx], items[rowIdx]
                    DetaurBar.UI.RefreshTasks()
                end
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
        if row.itemCategory == "price" and DetaurBar.UI.activePriceItemSubTab == "Chart" and DetaurBar.UI.GetSettingsDB().chartOrderMode then
            GameTooltip:AddLine("Move Up", 1.0, 1.0, 1.0)
        elseif row.itemCategory == "price" then
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
    
    -- Down button (Price Order reorder)
    downBtn:SetScript("OnClick", function(self)
        if row.itemId and row.itemCategory == "price" and DetaurBar.UI.activePriceItemSubTab == "Chart" and DetaurBar.UI.GetSettingsDB().chartOrderMode then
            local items = DetaurBar.Data.GetItems("price")
            if not items then return end
            local visible = GetVisiblePriceItems()
            if not visible then return end
            local idx
            for i, v in ipairs(visible) do
                if v.id == row.itemId then idx = i; break end
            end
            if idx and idx < #visible then
                local target = visible[idx+1]
                local rowIdx, targetIdx
                for i, v in ipairs(items) do
                    if v.id == row.itemId then rowIdx = i end
                    if v.id == target.id then targetIdx = i end
                end
                if rowIdx and targetIdx then
                    items[rowIdx], items[targetIdx] = items[targetIdx], items[rowIdx]
                    DetaurBar.UI.RefreshTasks()
                end
            end
        end
    end)
    downBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Move Down", 1.0, 1.0, 1.0)
        GameTooltip:Show()
    end)
    downBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    listCopyBtn:SetScript("OnClick", function(self)
        if DetaurBar.UI.listCopyPopup then DetaurBar.UI.listCopyPopup:Hide() end
        if not row.itemId or row.itemCategory ~= "price" then return end
        local item = DetaurBar.Data.GetItemById(row.itemCategory, row.itemId)
        if not item or not item.title then return end
        DetaurBar.Data.InitializeDB()
        local listNames = {}
        for name in pairs(DetaurBarDB.priceLists) do
            if name ~= "All" then table.insert(listNames, name) end
        end
        table.sort(listNames)
        DetaurBar.UI.SetActiveListCopyItem(item.title)
        DetaurBar.UI.activeListCopySourceItem = item
        DetaurBar.UI.RebuildListCopyPopup(listNames)
        DetaurBar.UI.listCopyPopup:ClearAllPoints()
        DetaurBar.UI.listCopyPopup:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 4)
        DetaurBar.UI.listCopyPopup:Show()
    end)
    listCopyBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Copy to List", 1.0, 1.0, 1.0)
        GameTooltip:AddLine("Add this item to a price list.", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    listCopyBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    copyBtn:SetScript("OnClick", function(self)
        if row.itemId and row.itemCategory and row.itemCategory:find("notes_") then
            local note = DetaurBar.Data.GetItemById(row.itemCategory, row.itemId)
            if note and note.title then
                SetupClipboardEditBox()
                local eb = DetaurBar.ClipboardEditBox
                eb:SetText(note.title)
                eb:HighlightText(0, note.title:len())
                eb:SetScript("OnUpdate", function(self, elaps)
                    self.timer = (self.timer or 0) + elaps
                    if self.timer > 2 then
                        self:ClearFocus()
                        self:SetScript("OnUpdate", nil)
                        self.timer = nil
                    end
                end)
                eb.timer = 0
                eb:Show()
                eb:SetFocus()
            end
        end
    end)
    
    copyBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Copy Note Text", 1.0, 1.0, 1.0)
        GameTooltip:AddLine("Click to copy note text (then Ctrl+C to clipboard).", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    
    copyBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    row:SetScript("OnReceiveDrag", OnReceiveDragHandler)
    
    return row
end

-- [LIST COPY POPUP] popup frame for copying items to price lists
DetaurBar.UI.activeListCopyItemTitle = nil

function DetaurBar.UI.SetActiveListCopyItem(title)
    DetaurBar.UI.activeListCopyItemTitle = title
end

function DetaurBar.UI.RebuildListCopyPopup(listNames)
    for _, child in ipairs(DetaurBar.UI.listCopyPopup.children or {}) do
        child:Hide()
        child:SetParent(nil)
    end
    DetaurBar.UI.listCopyPopup.children = {}
    DetaurBar.UI.listCopyPopup:SetBackdropColor(0.1, 0.1, 0.1, 0.95)

    local y = -4
    for _, name in ipairs(listNames) do
        local captured = name
        local btn = CreateFrame("Button", nil, DetaurBar.UI.listCopyPopup, "UIPanelButtonTemplate")
        btn:SetSize(DetaurBar.UI.listCopyPopup:GetWidth() - 8, 20)
        btn:SetPoint("TOP", DetaurBar.UI.listCopyPopup, "TOP", 0, y)
        btn:SetText(captured)
        btn:SetScript("OnClick", function()
            local title = DetaurBar.UI.activeListCopyItemTitle
            local src = DetaurBar.UI.activeListCopySourceItem
            if title then
                local newItem = DetaurBar.Data.AddItem("price", title)
                if newItem and src then
                    newItem.list = captured
                    newItem.threshold = src.threshold
                    newItem.thresholdHigh = src.thresholdHigh
                    newItem.frequent = src.frequent
                    newItem.frequentHigh = src.frequentHigh
                end
                DetaurBar.UI.RefreshTasks()
            end
            DetaurBar.UI.listCopyPopup:Hide()
        end)
        table.insert(DetaurBar.UI.listCopyPopup.children, btn)
        y = y - 24
    end

    local totalH = math.abs(y - 4) + 4
    if totalH < 10 then totalH = 10 end
    DetaurBar.UI.listCopyPopup:SetHeight(totalH)
end

DetaurBar.UI.listCopyPopup = CreateFrame("Frame", "DetaurBarListCopyPopup", UIParent)
DetaurBar.UI.listCopyPopup:SetWidth(130)
DetaurBar.UI.listCopyPopup:SetHeight(10)
DetaurBar.UI.listCopyPopup:SetFrameStrata("TOOLTIP")
DetaurBar.UI.listCopyPopup:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left=3, right=3, top=3, bottom=3 }
})
DetaurBar.UI.listCopyPopup:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
DetaurBar.UI.listCopyPopup:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
DetaurBar.UI.listCopyPopup:Hide()

-- [REFRESH] DetaurBar.UI.RefreshTasks — main render loop: rebuilds the visible row list
function DetaurBar.UI.RefreshTasks()
    if activeTab == "Settings" then
        return
    end

    if DetaurBar.UI.listCopyPopup then DetaurBar.UI.listCopyPopup:Hide() end

    local category = activeTab:lower()
    if category == "notes" and DetaurBar.UI.activeNotesSubTab then
        category = "tasks_" .. DetaurBar.UI.activeNotesSubTab:lower()
    elseif category == "loot" then
        category = "loot_" .. DetaurBar.UI.activeLootSubTab:lower()
        if DetaurBar.Core and DetaurBar.Core.UpdateAutoLootCVar then
            DetaurBar.Core.UpdateAutoLootCVar()
        end
    end
    local items = DetaurBar.Data.GetItems(category)
    -- Recipes sub-tab: pull from recipe DB, with expanded reagent rows
    if category == "price" and DetaurBar.UI.activePriceItemSubTab == "Recipes" then
        local allRecipes = DetaurBar.Data.GetItems("recipes")
        local expandedList = {}
        for _, recipe in ipairs(allRecipes) do
            table.insert(expandedList, recipe)
            if DetaurBar.UI.expandedRecipeId == recipe.id then
                local reagents = recipe.reagents
                if reagents and #reagents > 0 then
                    for _, reagent in ipairs(reagents) do
                        table.insert(expandedList, { isReagent = true, recipeId = recipe.id, reagent = reagent })
                    end
                else
                    table.insert(expandedList, { isReagent = true, recipeId = recipe.id, reagent = { name = "(no reagents captured)", count = nil, icon = nil } })
                end
            end
        end
        items = expandedList
    end
    -- Filter price items by selected list (Chart or List sub-tab)
    if category == "price" and not DetaurBar.UI.IsNewsView() and DetaurBar.UI.activePriceItemSubTab ~= "Bank" and DetaurBar.UI.activePriceItemSubTab ~= "Recipes" and DetaurBar.UI.activePriceListName then
        local filtered = {}
        for _, item in ipairs(items) do
            if DetaurBar.UI.activePriceListName == "All" then
                table.insert(filtered, item)
            elseif DetaurBar.UI.activePriceListName == "Default" then
                if not item.list then
                    table.insert(filtered, item)
                end
            elseif item.list == DetaurBar.UI.activePriceListName then
                table.insert(filtered, item)
            end
        end
        items = filtered
    end
    -- News view: respect the AH scan filter selection (the Chart toolbar dropdown)
    if category == "price" and DetaurBar.UI.IsNewsView() then
        local settings = DetaurBar.UI.GetSettingsDB()
        local scanFilterList = settings.scanFilterList or "All"
        local filtered = {}
        for _, item in ipairs(items) do
            local itemList = item.list
            if scanFilterList == "All" then
                table.insert(filtered, item)
            elseif itemList then
                if scanFilterList == itemList then table.insert(filtered, item) end
            else
                if scanFilterList == "Default" then table.insert(filtered, item) end
            end
        end
        items = filtered
    end
    if category == "price" and DetaurBar.UI.IsNewsView() then
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
        row.isReagentRow = false
        row.reagentItemId = nil
        row.reagentName = nil
        row.thresholdText:Hide()
        row.itemIcon:SetPoint("LEFT", row, "LEFT", 6, 0)
        
        -- Clear prior points to allow layout realignment
        row.titleText:ClearAllPoints()
        
        local textWidth = width - 65
        
        -- Track notification section for dual-section delete behavior
        if category == "price" and DetaurBar.UI.IsNewsView() then
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
            row.downBtn:Hide()
            row.listCopyBtn:Hide()
            row:SetHeight(22)
            row.titleText:SetPoint("LEFT", row, "LEFT", 10, 0)
            row.titleText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            row.titleText:SetText(item.title)
            row.titleText:SetTextColor(1.0, 0.82, 0.0, 1.0)
        elseif category:find("^tasks_") then
            row.checkbox:Show()
            row.itemIcon:Hide()
            row.swapBtn:Hide()
            row.copyBtn:Hide()
            row.downBtn:Hide()
            row.listCopyBtn:Hide()
            row.deleteBtn:Show()
            row.checkbox:SetChecked(item.completed and 1 or nil)
            
            row.titleText:SetPoint("LEFT", row.checkbox, "RIGHT", 8, 0)
            row.titleText:SetPoint("RIGHT", row.deleteBtn, "LEFT", -8, 0)
            row.titleText:SetText(item.title)
            
            if item.completed then
                row.titleText:SetTextColor(0.5, 0.5, 0.5, 0.7)
            else
                row.titleText:SetTextColor(1.0, 1.0, 1.0, 1.0)
            end
            
        elseif category == "price" then
            row.titleText:SetFont("Fonts\\FRIZQT___CYR.ttf", 11, "OUTLINE")
            row.checkbox:Hide()
            row.copyBtn:Hide()
            row.downBtn:Hide()
            row.listCopyBtn:Hide()

            if DetaurBar.UI.activePriceItemSubTab == "Recipes" then
                -- Recipes subtab: recipe row (icon + name) + expandable reagent sub-rows
                row.swapBtn:Hide()

                if item.isReagent then
                    -- Reagent sub-row: icon + "countx name", click to link to chat
                    row.deleteBtn:Hide()
                    local reagent = item.reagent
                    local reagentId = reagent.itemId
                    if not reagentId and reagent.name then
                        reagentId = DetaurBar.UI.GetItemIdFromText(reagent.name)
                    end
                    local icon = reagent.icon
                    if reagentId then
                        local offlineIcon = DetaurBar.Data.GetItemTexture(reagentId)
                        if offlineIcon then icon = offlineIcon end
                    end
                    if icon then
                        row.itemIcon:SetPoint("LEFT", row, "LEFT", 26, 0)
                        row.itemIcon:SetTexture(icon)
                        row.itemIcon:Show()
                        row.titleText:SetPoint("LEFT", row.itemIcon, "RIGHT", 6, 0)
                    else
                        row.itemIcon:Hide()
                        row.titleText:SetPoint("LEFT", row, "LEFT", 26, 0)
                    end
                    local thrText = DetaurBar.UI.GetItemThresholdText(reagentId)
                    if thrText then
                        row.thresholdText:SetText(thrText)
                        row.thresholdText:SetPoint("RIGHT", row, "RIGHT", -6, 0)
                        row.thresholdText:Show()
                        row.titleText:SetPoint("RIGHT", row.thresholdText, "LEFT", -4, 0)
                    else
                        row.thresholdText:Hide()
                        row.titleText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
                    end
                    row.titleText:SetText((reagent.count and reagent.count .. "x " or "") .. (reagent.name or "?"))
                    row.titleText:SetTextColor(0.85, 0.85, 0.85, 1.0)
                    row.isReagentRow = true
                    row.reagentItemId = reagentId
                    row.reagentName = reagent.name
                else
                    -- Recipe row: offline-resolved icon + name, click to expand/collapse reagents
                    row.deleteBtn:Show()
                    local recipe = item
                    local recipeId = recipe.itemId
                    if not recipeId and recipe.name then
                        recipeId = DetaurBar.UI.GetItemIdFromText(recipe.name)
                    end
                    local icon = recipe.icon
                    if recipeId then
                        local offlineIcon = DetaurBar.Data.GetItemTexture(recipeId)
                        if offlineIcon then icon = offlineIcon end
                        if not recipe.itemId then
                            recipe.itemId = recipeId
                            recipe.icon = icon or recipe.icon
                        end
                    end
                    if icon then
                        row.itemIcon:SetPoint("LEFT", row, "LEFT", 6, 0)
                        row.itemIcon:SetTexture(icon)
                        row.itemIcon:Show()
                        row.titleText:SetPoint("LEFT", row.itemIcon, "RIGHT", 8, 0)
                    else
                        row.itemIcon:Hide()
                        row.titleText:SetPoint("LEFT", row, "LEFT", 8, 0)
                    end
                    local thrText = DetaurBar.UI.GetItemThresholdText(recipeId)
                    if thrText then
                        row.thresholdText:SetText(thrText)
                        row.thresholdText:SetPoint("RIGHT", row.deleteBtn, "LEFT", -4, 0)
                        row.thresholdText:Show()
                        row.titleText:SetPoint("RIGHT", row.thresholdText, "LEFT", -4, 0)
                    else
                        row.thresholdText:Hide()
                        row.titleText:SetPoint("RIGHT", row.deleteBtn, "LEFT", -8, 0)
                    end
                    row.titleText:SetText(recipe.name or "Unknown recipe")
                    row.titleText:SetTextColor(1.0, 1.0, 1.0, 1.0)
                end

            else
                -- News subtab: simple display with current price
            if DetaurBar.UI.IsNewsView() then
                row.deleteBtn:Show()
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
                    if not itemTexture then
                        itemTexture = DetaurBar.Data.GetItemTexture(itemId)
                    end
                end
                
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
                            priceText = DetaurBar.UI.FormatGold(priceCopper)
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
                        GetItemInfo("item:" .. itemId)
                        local offlineLink = DetaurBar.UI.BuildOfflineItemLink(itemId)
                        if offlineLink then
                            row.titleText:SetText(offlineLink .. "  |cffffd700" .. priceText .. "|r")
                            row.titleText:SetTextColor(1, 1, 1, 1)
                        else
                            row.titleText:SetText(item.title:gsub("^item:", "") .. "  |cffffd700" .. priceText .. "|r")
                            row.titleText:SetTextColor(0.6, 0.6, 0.6, 1)
                        end
                    else
                        row.titleText:SetText(item.title .. "  |cffffd700" .. priceText .. "|r")
                        row.titleText:SetTextColor(1, 1, 1, 1)
                    end
                end

            else
                -- Chart subtab (with optional order mode)
                local settings = DetaurBar.UI.GetSettingsDB()
                local orderMode = settings.chartOrderMode

                if orderMode and DetaurBar.UI.activePriceItemSubTab == "Chart" then
                    -- Chart in order mode: up/down arrows + list copy, no delete, no threshold
                    row.deleteBtn:Hide()
                    row.swapBtn:Show()
                    row.listCopyBtn:Show()
                    row.downBtn:Show()
                    row.swapBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
                    row.swapBtn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
                    row.swapBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
                    row.listCopyBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Note_02")
                    row.listCopyBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
                    row.downBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
                    row.downBtn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
                    row.downBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
                else
                    row.deleteBtn:Show()
                    row.swapBtn:Hide()
                    row.listCopyBtn:Hide()
                    row.downBtn:Hide()
                end

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
                    -- Fallback: try offline texture when name/GetItemInfo failed
                    if not itemTexture then
                        itemTexture = DetaurBar.Data.GetItemTexture(itemId)
                    end
                end

                local rightAnchor = orderMode and row.downBtn or row.deleteBtn
                local rightOffset = -8

                -- Check for manual thresholds (only when not in order mode)
                local thresholdText = ""
                local thresholdHighText = ""
                if not orderMode and itemId and item.threshold and item.threshold > 0 then
                    thresholdText = "  |cffffd700[" .. item.threshold .. "g]|r"
                end
                if not orderMode and itemId and item.thresholdHigh and item.thresholdHigh > 0 then
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
                        GetItemInfo("item:" .. itemId)
                        local offlineLink = DetaurBar.UI.BuildOfflineItemLink(itemId)
                        if offlineLink then
                            row.titleText:SetText(offlineLink .. thresholdText .. thresholdHighText)
                            row.titleText:SetTextColor(1, 1, 1, 1)
                        else
                            row.titleText:SetText(item.title:gsub("^item:", "") .. thresholdText .. thresholdHighText)
                            row.titleText:SetTextColor(0.6, 0.6, 0.6, 1)
                        end
                    else
                        row.titleText:SetText(item.title .. thresholdText .. thresholdHighText)
                        row.titleText:SetTextColor(1, 1, 1, 1)
                    end
                end
            end
            end

        elseif category == "loot_add" or category == "loot_delete" or category == "sell" then
            row.checkbox:Hide()
            row.copyBtn:Hide()
            row.downBtn:Hide()
            row.listCopyBtn:Hide()

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
                -- Use OFFLINE database first (ignore server GetItemInfo)
                itemName = DetaurBar.UI.GetOfflineItemNameById(itemId)
                itemLink = DetaurBar.UI.BuildOfflineItemLink(itemId)
                
                -- If offline DB has no name, try server
                if not itemName then
                    itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
                    if not itemLink then
                        itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo("item:" .. itemId)
                    end
                    -- If server was used, try to get icon
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
                        row.titleText:SetText(item.title:gsub("^item:", ""))
                        row.titleText:SetTextColor(0.6, 0.6, 0.6, 1.0) -- Grey until cached
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
        local minRowHeight = (category == "price" and 22 or 28)
        local currentRowHeight = (category == "price" and math.max(minRowHeight, textHeight + 6) or math.max(minRowHeight, textHeight + 10))

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
    if activeTab == "Notes" then
        placeholderText:SetText("Enter task (" .. DetaurBar.UI.activeNotesSubTab .. ")...")
    elseif activeTab == "Loot" then
        if DetaurBar.UI.activeLootSubTab == "Add" then
            placeholderText:SetText("Whitelist item (Add)...")
        else
            placeholderText:SetText("Auto-delete item (Delete)...")
        end
    elseif activeTab == "Price" then
        if DetaurBar.UI.activePriceItemSubTab == "Chart" then
            if DetaurBar.UI.IsNewsView() then
                placeholderText:SetText("")
            else
                placeholderText:SetText("Enter item to track...")
            end
        elseif DetaurBar.UI.activePriceItemSubTab == "Recipes" then
            placeholderText:SetText("")
        elseif DetaurBar.UI.activePriceItemSubTab == "Bank" then
            placeholderText:SetText("")
        elseif DetaurBar.UI.activePriceItemSubTab == "List" then
            placeholderText:SetText("Add item to list...")
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
    if DetaurBar.UI.settingsMenuPanel then DetaurBar.UI.settingsMenuPanel:Hide() end
    DetaurBar.UI.settingsMenuPanelVisible = false
    activeTab = tabName
    for _, tab in ipairs(tabs) do
        if tab.tabName == tabName then
            tab:Disable() -- Native WoW look: active tab is disabled/pushed
        else
            tab:Enable()
        end
    end

    if tabName == "Settings" then
        for _, subTab in ipairs(DetaurBar.UI.lootSubTabs) do subTab:Hide() end
        for _, subTab in ipairs(DetaurBar.UI.priceItemSubTabs) do subTab:Hide() end
        if DetaurBar.UI.notesTabContainer then DetaurBar.UI.notesTabContainer:Hide() end
        if DetaurBar.UI.notesCatControls then DetaurBar.UI.notesCatControls:Hide() end
        if DetaurBar.UI.notesTabLeftArrow then DetaurBar.UI.notesTabLeftArrow:Hide() end
        if DetaurBar.UI.notesTabRightArrow then DetaurBar.UI.notesTabRightArrow:Hide() end
        local settings = DetaurBar.UI.GetSettingsDB()
        for _, subTab in ipairs(DetaurBar.UI.alertSubTabs) do
            if settings.alertSubTabsVisible and settings.alertSubTabsVisible[subTab.tabName] ~= false then
                subTab:Show()
            else
                subTab:Hide()
            end
        end
        if DetaurBar.UI.deleteAllGraysCheckbox then DetaurBar.UI.deleteAllGraysCheckbox:Hide() end
        if scrollFrame then scrollFrame:Hide() end
        if listBackground then listBackground:Hide() end
        if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
        if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
        if DetaurBar.UI.priceChartToolbar then DetaurBar.UI.priceChartToolbar:Hide() end
        if DetaurBar.UI.priceListPanel then DetaurBar.UI.priceListPanel:Hide() end
        if DetaurBar.UI.priceListControls then DetaurBar.UI.priceListControls:Hide() end
        if DetaurBar.UI.bankPanel then DetaurBar.UI.bankPanel:Hide() end
        if DetaurBar.UI.recipesPanel then DetaurBar.UI.recipesPanel:Hide() end
        if DetaurBar.UI.alertSubTabBar then DetaurBar.UI.alertSubTabBar:Show() end
        if DetaurBar.UI.alertPanel then DetaurBar.UI.alertPanel:Show() end
        if DetaurBar.UI.alertListBackground then DetaurBar.UI.alertListBackground:Show() end
        if DetaurBar.UI.alertScrollFrame then DetaurBar.UI.alertScrollFrame:Show() end
        if DetaurBar.UI.alertScrollChild then DetaurBar.UI.alertScrollChild:Show() end
        editBox:ClearFocus()
        editBox:Hide()
        addButton:Hide()
        if not DetaurBar.UI.activeAlertSubTab then DetaurBar.UI.activeAlertSubTab = "Dung" end
        if settings.alertSubTabsVisible and settings.alertSubTabsVisible[DetaurBar.UI.activeAlertSubTab] == false then
            -- pick first visible sub-tab, or keep "Dung" as fallback
            local found
            for _, st in ipairs(DetaurBar.UI.alertSubTabs) do
                if settings.alertSubTabsVisible[st.tabName] ~= false then found = st.tabName; break end
            end
            DetaurBar.UI.activeAlertSubTab = found or "Dung"
        end
        DetaurBar.UI.SelectAlertSubTab(DetaurBar.UI.activeAlertSubTab)
        if DetaurBar.UI.UpdateAlertPanel then
            DetaurBar.UI.UpdateAlertPanel()
        end
        DetaurBar.UI.UpdateAlertSubTabBar()
        DetaurBar.UI.UpdateInputPlaceholder()
        DetaurBar.UI.RefreshTasks()
        return
    end

    for _, subTab in ipairs(DetaurBar.UI.alertSubTabs) do
        subTab:Hide()
    end
    if DetaurBar.UI.alertSubTabBar then
        DetaurBar.UI.alertSubTabBar:Hide()
    end
    
    -- Show/hide notes (merged) sub-tabs, category controls, and rebuild sub-tab buttons from DB
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

    -- Show/hide loot sub-tabs (filtered by settings menu)
    if tabName == "Loot" then
        local settings = DetaurBar.UI.GetSettingsDB()
        local firstVisible
        for _, subTab in ipairs(DetaurBar.UI.lootSubTabs) do
            if settings.lootSubTabsVisible and settings.lootSubTabsVisible[subTab.tabName] ~= false then
                subTab:Show()
                if not firstVisible then firstVisible = subTab.tabName end
            else
                subTab:Hide()
            end
        end
        if DetaurBar.UI.activeLootSubTab and settings.lootSubTabsVisible and settings.lootSubTabsVisible[DetaurBar.UI.activeLootSubTab] ~= false then
            -- keep current
        elseif firstVisible then
            DetaurBar.UI.activeLootSubTab = firstVisible
        elseif DetaurBar.UI.lootSubTabs[1] then
            DetaurBar.UI.activeLootSubTab = DetaurBar.UI.lootSubTabs[1].tabName
        end
        DetaurBar.UI.SelectLootSubTab(DetaurBar.UI.activeLootSubTab)
        DetaurBar.UI.UpdateTabAnchors()
    else
        for _, subTab in ipairs(DetaurBar.UI.lootSubTabs) do subTab:Hide() end
        if DetaurBar.UI.deleteAllGraysCheckbox then DetaurBar.UI.deleteAllGraysCheckbox:Hide() end
    end

    -- Price sub-tab visuals (UpdateContentAnchors shows/hides the bar)
    if tabName == "Price" then
        if DetaurBar.UI.alertPanel then DetaurBar.UI.alertPanel:Hide() end
        if scrollFrame then scrollFrame:Show() end
        if listBackground then listBackground:Show() end
        local settings = DetaurBar.UI.GetSettingsDB()
        local firstVisible
        for _, subTab in ipairs(DetaurBar.UI.priceItemSubTabs) do
            if settings.priceSubTabsVisible and settings.priceSubTabsVisible[subTab.tabName] ~= false then
                subTab:Show()
                if not firstVisible then firstVisible = subTab.tabName end
            else
                subTab:Hide()
            end
        end
        if DetaurBar.UI.activePriceItemSubTab and settings.priceSubTabsVisible and settings.priceSubTabsVisible[DetaurBar.UI.activePriceItemSubTab] ~= false then
            -- keep current
        elseif firstVisible then
            DetaurBar.UI.activePriceItemSubTab = firstVisible
        elseif DetaurBar.UI.priceItemSubTabs[1] then
            DetaurBar.UI.activePriceItemSubTab = DetaurBar.UI.priceItemSubTabs[1].tabName
        end
        DetaurBar.UI.SelectPriceItemSubTab(DetaurBar.UI.activePriceItemSubTab)
        DetaurBar.UI.UpdatePriceSubTabVisuals()
        DetaurBar.UI.LayoutPriceSubTabs()
        DetaurBar.UI.UpdateTabAnchors()
    else
        for _, subTab in ipairs(DetaurBar.UI.priceItemSubTabs) do subTab:Hide() end
        if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
        if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        if DetaurBar.UI.priceChartToolbar then DetaurBar.UI.priceChartToolbar:Hide() end
        if DetaurBar.UI.priceListPanel then DetaurBar.UI.priceListPanel:Hide() end
        if DetaurBar.UI.priceListControls then DetaurBar.UI.priceListControls:Hide() end
        if DetaurBar.UI.bankPanel then DetaurBar.UI.bankPanel:Hide() end
        if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
        if DetaurBar.UI.recipesPanel then DetaurBar.UI.recipesPanel:Hide() end
        editBox:Show()
        addButton:Show()
        if DetaurBar.UI.alertPanel then DetaurBar.UI.alertPanel:Hide() end
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
    return activeTab, DetaurBar.UI.activeNotesSubTab, DetaurBar.UI.activeLootSubTab, DetaurBar.UI.activePriceItemSubTab, DetaurBar.UI.activePriceSubTab
end

-- [ADD ITEM] DetaurBar.UI.AddNewItem — submits editBox text as new task/item
function DetaurBar.UI.AddNewItem()
    local title = editBox:GetText()
    title = title:gsub("^%s*(.-)%s*$", "%1") -- Trim spaces
    if title ~= "" then
        local category = activeTab:lower()
        if category == "notes" then
            category = "tasks_" .. DetaurBar.UI.activeNotesSubTab:lower()
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
        if newItem and category == "price" and DetaurBar.UI.IsNewsView() then
            newItem.frequent = true
        end
        if newItem and category == "price" and DetaurBar.UI.activePriceItemSubTab == "List" and DetaurBar.UI.activePriceListName and DetaurBar.UI.activePriceListName ~= "Default" and DetaurBar.UI.activePriceListName ~= "All" then
            newItem.list = DetaurBar.UI.activePriceListName
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
    if DetaurBarFrame and DetaurBarFrame:IsShown() then
        -- Recipes sub-tab input box gets spell/item links via shift-click
        if DetaurBar.UI.recipesLinkBox and DetaurBar.UI.recipesLinkBox:HasFocus() then
            DetaurBar.UI.recipesLinkBox:Insert(link)
            return true
        end
        if editBox:HasFocus() then
            editBox:Insert(link)
            return true
        end
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

resizeButton:RegisterForDrag("LeftButton")
resizeButton:SetScript("OnDragStart", function(self)
    frame:StartSizing("BOTTOMRIGHT")
end)
resizeButton:SetScript("OnDragStop", function(self)
    frame:StopMovingOrSizing()
end)

-- [RESIZE] DetaurBar.UI.OnResize — re-layout all content on frame size change
function DetaurBar.UI.OnResize()
    DetaurBar.UI.UpdateTabAnchors()
    DetaurBar.UI.UpdateContentAnchors()
    if DetaurBar.UI.LayoutPriceSubTabs then DetaurBar.UI.LayoutPriceSubTabs() end
    if DetaurBar.UI.alertSubTabBar then
        DetaurBar.UI.UpdateAlertSubTabBar()
    end
    local width = scrollFrame:GetWidth()
    scrollChild:SetWidth(width)
    for _, row in ipairs(rowPool) do
        row:SetWidth(width)
    end
    if DetaurBar.UI.alertScrollFrame then
        DetaurBar.UI.UpdateAlertScroll()
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
    DetaurBar.UI.SelectTab("Notes")
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
        if DetaurBar.UI.settingsMenuPanel then
            DetaurBar.UI.settingsMenuPanel:Hide()
        end
        DetaurBar.UI.settingsMenuPanelVisible = false
        DetaurBar.UI.SelectTab("Notes")
    end
end

-- Minimap button moved to DetaurBar_Minimap.lua
