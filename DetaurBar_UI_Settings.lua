-- DetaurBar_UI_Settings.lua
-- Settings panel, sub-tabs, controls, and management

DetaurBar = DetaurBar or {}
DetaurBar.UI = DetaurBar.UI or {}

-- ============================================
--  STATE: Settings-specific variables
-- ============================================
local alertWGAlert1SoundButtons = {}
local alertWGAlert2ColorButtons = {}
local alertRandomColorButtons = {}
local alertRandomSoundButtons = {}

-- ============================================
--  UI FACTORY: Reusable components for settings
-- ============================================
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

local function CreateChoiceButton(parent, width, label)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(22)
    button:SetWidth(width)
    button:EnableMouse(true)
    button:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
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

local function CreateAlertEditBox(parent, width)
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

local function CreateAlertLabel(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    return label
end

local function CreateAlertCheck(parent, text, x, y, onClick)
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

local function SetButtonGroupValue(group, value)
    for key, button in pairs(group) do
        SetChoiceButtonStyle(button, key == value)
    end
end

local function CreateAlertChoiceRow(parent, group, options, x, y, width, onChoose)
    local buttonWidth = math.floor((width - ((#options - 1) * 4)) / #options)
    local currentX = x
    for _, opt in ipairs(options) do
        local button = CreateChoiceButton(parent, buttonWidth, opt.label)
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", currentX, y)
        button:SetScript("OnClick", function()
            onChoose(opt.key)
            SetButtonGroupValue(group, opt.key)
        end)
        DetaurBar.UI.SetSimpleTooltip(button, opt.label, opt.tooltip or ("Select " .. opt.label .. "."))
        group[opt.key] = button
        currentX = currentX + buttonWidth + 4
    end
end

local function CreateAlertEditRow(parent, labelText, x, y, width, maxLetters, onEnter)
    local label = CreateAlertLabel(parent, labelText, x, y)
    local edit = CreateAlertEditBox(parent, width)
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

local function CreateSectionDivider(parent)
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
    divider:SetHeight(8)
    return divider
end

-- ============================================
--  SETTINGS PANEL: Main backdrop frame
-- ============================================
DetaurBar.UI.alertPanel = CreateFrame("Frame", "DetaurBarSettingsPanel", _G["DetaurBarFrame"])
DetaurBar.UI.alertPanel:SetPoint("TOPLEFT", _G["DetaurBarFrame"], "TOPLEFT", 16, -60)
DetaurBar.UI.alertPanel:SetPoint("BOTTOMRIGHT", _G["DetaurBarFrame"], "BOTTOMRIGHT", -16, 14)
DetaurBar.UI.alertPanel:Hide()
DetaurBar.UI.alertPanel:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
DetaurBar.UI.alertPanel:SetBackdropColor(0, 0, 0, 0.0)
DetaurBar.UI.alertPanel:SetBackdropBorderColor(0, 0, 0, 0)

-- Sub-tab bar inside settings panel
DetaurBar.UI.alertSubTabBar = CreateFrame("Frame", "DetaurBarSettingsSubTabBar", DetaurBar.UI.alertPanel)
DetaurBar.UI.alertSubTabBar:SetHeight(24)
DetaurBar.UI.alertSubTabBar:SetPoint("TOPLEFT", DetaurBar.UI.alertPanel, "TOPLEFT", 8, -8)
DetaurBar.UI.alertSubTabBar:SetPoint("TOPRIGHT", DetaurBar.UI.alertPanel, "TOPRIGHT", -24, -8)
DetaurBar.UI.alertSubTabBar:Hide()

-- Background frame for settings content
DetaurBar.UI.alertListBackground = CreateFrame("Frame", "DetaurBarSettingsListBackground", DetaurBar.UI.alertPanel)
DetaurBar.UI.alertListBackground:SetPoint("TOPLEFT", DetaurBar.UI.alertSubTabBar, "BOTTOMLEFT", -1, -2)
DetaurBar.UI.alertListBackground:SetPoint("BOTTOMRIGHT", DetaurBar.UI.alertPanel, "BOTTOMRIGHT", 0, 36)
DetaurBar.UI.alertListBackground:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
DetaurBar.UI.alertListBackground:SetBackdropColor(0, 0, 0, 0.4)
DetaurBar.UI.alertListBackground:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
DetaurBar.UI.alertListBackground:Hide()

-- ScrollFrame for settings content
DetaurBar.UI.alertScrollFrame = CreateFrame("ScrollFrame", "DetaurBarSettingsScrollFrame", DetaurBar.UI.alertListBackground)
DetaurBar.UI.alertScrollFrame:SetPoint("TOPLEFT", DetaurBar.UI.alertListBackground, "TOPLEFT", 0, 0)
DetaurBar.UI.alertScrollFrame:SetPoint("BOTTOMRIGHT", DetaurBar.UI.alertListBackground, "BOTTOMRIGHT", -16, 0)
DetaurBar.UI.alertScrollFrame:Hide()
DetaurBar.UI.alertScrollFrame:EnableMouseWheel(true)

-- Vertical scroll bar
local alertScrollBar = CreateFrame("Slider", "DetaurBarSettingsScrollBar", DetaurBar.UI.alertScrollFrame, "UIPanelScrollBarTemplate")
alertScrollBar:SetPoint("TOPLEFT", DetaurBar.UI.alertScrollFrame, "TOPRIGHT", 4, -16)
alertScrollBar:SetPoint("BOTTOMLEFT", DetaurBar.UI.alertScrollFrame, "BOTTOMRIGHT", 4, 16)
alertScrollBar:SetWidth(16)
alertScrollBar:SetValueStep(1)
alertScrollBar:SetMinMaxValues(0, 0)
alertScrollBar:SetValue(0)
alertScrollBar:SetScript("OnValueChanged", function(self, value)
    DetaurBar.UI.alertScrollFrame:SetVerticalScroll(value)
end)

DetaurBar.UI.alertScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = alertScrollBar:GetValue()
    alertScrollBar:SetValue(current - delta * 20)
end)

-- Scroll child — actual content parent
DetaurBar.UI.alertScrollChild = CreateFrame("Frame", "DetaurBarSettingsScrollChild", DetaurBar.UI.alertScrollFrame)
DetaurBar.UI.alertScrollFrame:SetScrollChild(DetaurBar.UI.alertScrollChild)
DetaurBar.UI.alertScrollChild:SetWidth(math.max(1, DetaurBar.UI.alertScrollFrame:GetWidth() or (_G["DetaurBarFrame"]:GetWidth() - 64)))
DetaurBar.UI.alertScrollChild:SetHeight(390)

-- ============================================
--  SETTINGS SUB-TABS: Dungeon / Wintergrasp / Random
-- ============================================
local alertSubTabNames = { "Dung", "Raid", "WG", "Random", "Enemy", "Buffs" }
for i, name in ipairs(alertSubTabNames) do
    local subTab = CreateFrame("Button", "DetaurBarSettingsSubTab_" .. name, DetaurBar.UI.alertPanel)
    subTab:SetHeight(24)
    subTab:SetFrameLevel(DetaurBar.UI.alertPanel:GetFrameLevel() + 6)
    subTab:EnableMouse(true)
    subTab.tabName = name
    subTab:Hide()
    subTab:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
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
        DetaurBar.UI.SelectAlertSubTab(name)
    end)
    DetaurBar.UI.alertSubTabs[i] = subTab
end

-- ============================================
--  SUB-TAB STYLE: Gold active / Dark inactive
-- ============================================
local function SetAlertSubTabStyle(subTab)
    if subTab.tabName == DetaurBar.UI.activeAlertSubTab then
        subTab:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
        subTab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        subTab.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    else
        subTab:SetBackdropColor(0, 0, 0, 0.55)
        subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        subTab.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
    end
end

function DetaurBar.UI.UpdateAlertSubTabBar()
    local totalWidth = _G["DetaurBarFrame"]:GetWidth() - 28
    local subTabGap = 1
    local settings = DetaurBar.UI.GetSettingsDB()
    local visibleTabs = {}
    for _, subTab in ipairs(DetaurBar.UI.alertSubTabs) do
        if settings.alertSubTabsVisible and settings.alertSubTabsVisible[subTab.tabName] ~= false then
            table.insert(visibleTabs, subTab)
        end
    end
    local numTabs = #visibleTabs
    local subTabWidth = (totalWidth - (subTabGap * (numTabs - 1))) / math.max(1, numTabs)
    for i, subTab in ipairs(visibleTabs) do
        subTab:SetWidth(subTabWidth)
        subTab:ClearAllPoints()
        if i == 1 then
            subTab:SetPoint("TOPLEFT", DetaurBar.UI.alertSubTabBar, "TOPLEFT", 0, 0)
        else
            subTab:SetPoint("LEFT", visibleTabs[i-1], "RIGHT", subTabGap, 0)
        end
    end
end

function DetaurBar.UI.UpdateAlertSubTabVisuals()
    for _, subTab in ipairs(DetaurBar.UI.alertSubTabs) do
        SetAlertSubTabStyle(subTab)
        if subTab.tabName == DetaurBar.UI.activeAlertSubTab then
            subTab:Disable()
        else
            subTab:Enable()
        end
    end
end

-- ============================================
--  SETTINGS CONTROLS: Dungeon sub-tab
-- ============================================
local sc = DetaurBar.UI.alertScrollChild

local dungeonEnableCheckbox, dungeonEnableLabel = CreateAlertCheck(sc, "Enable Dungeon Flash Alert", 8, -8, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.dungeonFlashEnabled = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(dungeonEnableCheckbox, "Enable Dungeon Flash Alert", "Flash the whole screen when a Dungeon Finder proposal appears.")

local dungeonColorLabel = CreateAlertLabel(sc, "Flash Color", 8, -40)

local dungeonDurationLabel, dungeonDurationEdit = CreateAlertEditRow(sc, "Flash duration", 8, -68, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.dungeonFlashDuration = DetaurBar.UI.ClampNumber(self:GetText(), 0, 0, 120)
    self:SetText(tostring(settings.dungeonFlashDuration))
end)
DetaurBar.UI.SetSimpleTooltip(dungeonDurationEdit, "Flash Duration", "How many seconds to flash. Set 0 for infinite (until proposal closes).")

local dungeonColorRow = {}
CreateAlertChoiceRow(sc, dungeonColorRow, {
    { key = "GREEN", label = "Green", tooltip = "Use a green full-screen flash." },
    { key = "YELLOW", label = "Yellow", tooltip = "Use a yellow full-screen flash." },
    { key = "RED", label = "Red", tooltip = "Use a red full-screen flash." },
}, 8, -94, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.dungeonFlashColor = value
end)

-- ============================================
--  SETTINGS CONTROLS: Raid sub-tab
-- ============================================
local raidRollCheckbox, raidRollLabel = CreateAlertCheck(sc, "Roll Alert", 8, -8, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.raidRollAlertEnabled = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(raidRollCheckbox, "Roll Alert", "Flash when someone rolls in raid chat.")

local raidRollColorLabel = CreateAlertLabel(sc, "Flash Color", 8, -40)
local alertRaidRollColorButtons = {}
CreateAlertChoiceRow(sc, alertRaidRollColorButtons, {
    { key = "GREEN", label = "Green", tooltip = "Use a green flash." },
    { key = "YELLOW", label = "Yellow", tooltip = "Use a yellow flash." },
    { key = "RED", label = "Red", tooltip = "Use a red flash." },
}, 8, -56, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.raidRollAlertColor = value
end)

local raidRollDurationLabel, raidRollDurationEdit = CreateAlertEditRow(sc, "Flash duration", 8, -82, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.raidRollAlertDuration = DetaurBar.UI.ClampNumber(self:GetText(), 0, 0, 30)
    self:SetText(tostring(settings.raidRollAlertDuration))
end)
DetaurBar.UI.SetSimpleTooltip(raidRollDurationEdit, "Flash Duration", "How long to flash. Set 0 for no flash.")

local raidRollStyleLabel = CreateAlertLabel(sc, "Flash Style", 8, -108)
local alertRaidRollStyleButtons = {}
CreateAlertChoiceRow(sc, alertRaidRollStyleButtons, {
    { key = "SMOOTH", label = "Smooth", tooltip = "Subtle border-edge flash." },
    { key = "AGGRESSIVE", label = "Aggressive", tooltip = "Full-screen pulsing flash." },
}, 8, -124, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.raidRollAlertStyle = value
end)

local raidRollSoundCheckbox, raidRollSoundLabel = CreateAlertCheck(sc, "Play Sound", 8, -150, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.raidRollAlertPlaySound = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(raidRollSoundCheckbox, "Play Sound", "Play a sound when a roll is detected.")

local raidRollSoundChoiceLabel = CreateAlertLabel(sc, "Select Sound", 8, -176)
local alertRaidRollSoundButtons = {}
CreateAlertChoiceRow(sc, alertRaidRollSoundButtons, {
    { key = "RaidWarning", label = "Raid", tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = "Ready", tooltip = "Play the Ready Check sound." },
}, 8, -192, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.raidRollAlertSound = value
end)

-- Divider between Roll Alert and Ready Check Alert sections
local raidDivider = CreateSectionDivider(sc)
raidDivider:SetPoint("TOP", alertRaidRollSoundButtons.ReadyCheck, "BOTTOM", 0, -10)
raidDivider:SetPoint("LEFT", sc, "LEFT", 10)
raidDivider:SetPoint("RIGHT", sc, "RIGHT", -10)

local raidReadyCheckbox, raidReadyLabel = CreateAlertCheck(sc, "Ready Check Alert", 8, -238, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.raidReadyCheckAlertEnabled = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(raidReadyCheckbox, "Ready Check Alert", "Flash when a ready check is performed.")

local raidReadyColorLabel = CreateAlertLabel(sc, "Flash Color", 8, -270)
local alertRaidReadyColorButtons = {}
CreateAlertChoiceRow(sc, alertRaidReadyColorButtons, {
    { key = "GREEN", label = "Green", tooltip = "Use a green flash." },
    { key = "YELLOW", label = "Yellow", tooltip = "Use a yellow flash." },
    { key = "RED", label = "Red", tooltip = "Use a red flash." },
}, 8, -286, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.raidReadyCheckAlertColor = value
end)

local raidReadyDurationLabel, raidReadyDurationEdit = CreateAlertEditRow(sc, "Flash duration", 8, -312, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.raidReadyCheckAlertDuration = DetaurBar.UI.ClampNumber(self:GetText(), 0, 0, 30)
    self:SetText(tostring(settings.raidReadyCheckAlertDuration))
end)
DetaurBar.UI.SetSimpleTooltip(raidReadyDurationEdit, "Flash Duration", "How long to flash. Set 0 for no flash.")

local raidReadyStyleLabel = CreateAlertLabel(sc, "Flash Style", 8, -338)
local alertRaidReadyStyleButtons = {}
CreateAlertChoiceRow(sc, alertRaidReadyStyleButtons, {
    { key = "SMOOTH", label = "Smooth", tooltip = "Subtle border-edge flash." },
    { key = "AGGRESSIVE", label = "Aggressive", tooltip = "Full-screen pulsing flash." },
}, 8, -354, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.raidReadyCheckAlertStyle = value
end)

local raidReadySoundCheckbox, raidReadySoundLabel = CreateAlertCheck(sc, "Play Sound", 8, -380, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.raidReadyCheckAlertPlaySound = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(raidReadySoundCheckbox, "Play Sound", "Play a sound when a ready check is performed.")

local raidReadySoundChoiceLabel = CreateAlertLabel(sc, "Select Sound", 8, -406)
local alertRaidReadySoundButtons = {}
CreateAlertChoiceRow(sc, alertRaidReadySoundButtons, {
    { key = "RaidWarning", label = "Raid", tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = "Ready", tooltip = "Play the Ready Check sound." },
}, 8, -422, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.raidReadyCheckAlertSound = value
end)

-- ============================================
--  SETTINGS CONTROLS: Wintergrasp sub-tab
-- ============================================
local wgEnableCheckbox, wgEnableLabel = CreateAlertCheck(sc, "Enable Wintergrasp Alerts", 8, -8, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlertsEnabled = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(wgEnableCheckbox, "Enable Wintergrasp Alerts", "Run background Wintergrasp countdown checks and fire warnings when the threshold is reached.")

local wgSectionLabel = CreateAlertLabel(sc, "Registration Warning", 8, -40)

local wgAlert1MinutesLabel, wgAlert1MinutesEdit = CreateAlertEditRow(sc, "Minutes before start", 8, -68, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert1Minutes = DetaurBar.UI.ClampNumber(self:GetText(), 15, 0, 120)
    self:SetText(tostring(settings.wgAlert1Minutes))
end)
DetaurBar.UI.SetSimpleTooltip(wgAlert1MinutesEdit, "Registration Warning", "Minutes before battle start to flash the screen.")

local wgAlert1DurationLabel, wgAlert1DurationEdit = CreateAlertEditRow(sc, "Flash duration", 8, -96, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert1Duration = DetaurBar.UI.ClampNumber(self:GetText(), 2, 0, 30)
    self:SetText(tostring(settings.wgAlert1Duration))
end)
DetaurBar.UI.SetSimpleTooltip(wgAlert1DurationEdit, "Flash Duration", "How long the Wintergrasp registration warning should flash.")

local wgAlert1ColorLabel = CreateAlertLabel(sc, "Flash Color", 8, -124)

local alertWGColorButtons = {}
CreateAlertChoiceRow(sc, alertWGColorButtons, {
    { key = "GREEN", label = "Green", tooltip = "Use a green Wintergrasp flash." },
    { key = "YELLOW", label = "Yellow", tooltip = "Use a yellow Wintergrasp flash." },
    { key = "RED", label = "Red", tooltip = "Use a red Wintergrasp flash." },
}, 8, -140, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert1Color = value
end)

local wgAlert1SoundCheckbox, wgAlert1SoundLabel = CreateAlertCheck(sc, "Play Sound", 8, -168, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert1PlaySound = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(wgAlert1SoundCheckbox, "Play Sound Alert", "Play a sound when the Registration Warning threshold is reached.")

local wgAlert1SoundChoiceLabel = CreateAlertLabel(sc, "Select Sound", 8, -194)
CreateAlertChoiceRow(sc, alertWGAlert1SoundButtons, {
    { key = "RaidWarning", label = "Raid", tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = "Ready", tooltip = "Play the Ready Check sound." },
}, 8, -210, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert1Sound = value
end)

-- Divider between Registration Warning and Battle Start Warning sections
local wgDivider = CreateSectionDivider(sc)
wgDivider:SetPoint("TOP", alertWGAlert1SoundButtons.ReadyCheck, "BOTTOM", 0, -10)
wgDivider:SetPoint("LEFT", sc, "LEFT", 10)
wgDivider:SetPoint("RIGHT", sc, "RIGHT", -10)

local wgStartLabel = CreateAlertLabel(sc, "Battle Start Warning", 8, -262)

local wgAlert2MinutesLabel, wgAlert2MinutesEdit = CreateAlertEditRow(sc, "Minutes before start", 8, -290, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert2Minutes = DetaurBar.UI.ClampNumber(self:GetText(), 1, 0, 120)
    self:SetText(tostring(settings.wgAlert2Minutes))
end)
DetaurBar.UI.SetSimpleTooltip(wgAlert2MinutesEdit, "Battle Start Warning", "Minutes before battle start to play the selected sound.")

local wgAlert2DurationLabel, wgAlert2DurationEdit = CreateAlertEditRow(sc, "Flash duration", 8, -318, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert2Duration = DetaurBar.UI.ClampNumber(self:GetText(), 0, 0, 30)
    self:SetText(tostring(settings.wgAlert2Duration))
end)
DetaurBar.UI.SetSimpleTooltip(wgAlert2DurationEdit, "Flash Duration", "How long the Battle Start Warning should flash. Set 0 for no flash.")

local wgAlert2ColorLabel = CreateAlertLabel(sc, "Flash Color", 8, -346)
CreateAlertChoiceRow(sc, alertWGAlert2ColorButtons, {
    { key = "GREEN", label = "Green", tooltip = "Use a green flash." },
    { key = "YELLOW", label = "Yellow", tooltip = "Use a yellow flash." },
    { key = "RED", label = "Red", tooltip = "Use a red flash." },
}, 8, -362, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert2Color = value
end)

local wgSoundCheckbox, wgSoundLabel = CreateAlertCheck(sc, "Play Sound", 8, -390, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert2PlaySound = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(wgSoundCheckbox, "Play Sound Alert", "Play a sound when the Wintergrasp start threshold is reached.")

local wgSoundChoiceLabel = CreateAlertLabel(sc, "Select Sound", 8, -416)

local alertSoundButtons = {}
CreateAlertChoiceRow(sc, alertSoundButtons, {
    { key = "RaidWarning", label = "Raid", tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = "Ready", tooltip = "Play the Ready Check sound." },
}, 8, -432, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert2Sound = value
end)

-- ============================================
--  SETTINGS CONTROLS: Random sub-tab
-- ============================================
local randomEnableCheckbox, randomEnableLabel = CreateAlertCheck(sc, "Enable Random Alerts", 8, -8, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.randomAlertsEnabled = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(randomEnableCheckbox, "Enable Random Alerts", "Fire the selected alert on a repeating timer.")

local randomIntervalLabel, randomIntervalEdit = CreateAlertEditRow(sc, "How often (minutes)", 8, -40, 36, 3, function(self)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then
        alert.intervalMinutes = DetaurBar.UI.ClampNumber(self:GetText(), 5, 1, 999)
        self:SetText(tostring(alert.intervalMinutes))
    end
end)
DetaurBar.UI.SetSimpleTooltip(randomIntervalEdit, "How Often", "Fire an alert every this many minutes.")

local randomDurationLabel, randomDurationEdit = CreateAlertEditRow(sc, "Flash duration", 8, -68, 36, 3, function(self)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then
        alert.flashDuration = DetaurBar.UI.ClampNumber(self:GetText(), 0, 0, 30)
        self:SetText(tostring(alert.flashDuration))
    end
end)
DetaurBar.UI.SetSimpleTooltip(randomDurationEdit, "Flash Duration", "How long to flash. Set 0 for no flash.")

local randomColorLabel = CreateAlertLabel(sc, "Flash Color", 8, -96)
CreateAlertChoiceRow(sc, alertRandomColorButtons, {
    { key = "GREEN", label = "Green", tooltip = "Use a green flash." },
    { key = "YELLOW", label = "Yellow", tooltip = "Use a yellow flash." },
    { key = "RED", label = "Red", tooltip = "Use a red flash." },
}, 8, -112, 162, function(value)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then alert.flashColor = value end
end)

local randomSoundCheckbox, randomSoundLabel = CreateAlertCheck(sc, "Play Sound", 8, -140, function(self)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then alert.playSound = self:GetChecked() and true or false end
end)
DetaurBar.UI.SetSimpleTooltip(randomSoundCheckbox, "Play Sound", "Play a sound with each alert.")

local randomSoundChoiceLabel = CreateAlertLabel(sc, "Select Sound", 8, -166)
CreateAlertChoiceRow(sc, alertRandomSoundButtons, {
    { key = "RaidWarning", label = "Raid", tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = "Ready", tooltip = "Play the Ready Check sound." },
}, 8, -182, 162, function(value)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then alert.sound = value end
end)

-- ============================================
--  SETTINGS SAVE BUTTON
-- ============================================
DetaurBar.UI.alertSaveButton = CreateFrame("Button", "DetaurBarSettingsSaveButton", DetaurBar.UI.alertPanel, "UIPanelButtonTemplate")
DetaurBar.UI.alertSaveButton:SetSize(72, 22)
DetaurBar.UI.alertSaveButton:SetPoint("BOTTOMRIGHT", DetaurBar.UI.alertPanel, "BOTTOMRIGHT", -8, 8)
DetaurBar.UI.alertSaveButton:SetText("Save")
DetaurBar.UI.alertSaveButton:SetScript("OnClick", function()
    if DetaurBar.UI and DetaurBar.UI.SaveSettings then
        DetaurBar.UI.SaveSettings()
    end
end)

-- ============================================
--  SETTINGS CONTROL LISTS
-- ============================================
local function SetAlertControlsVisible(group, visible)
    for _, control in ipairs(group) do
        if visible then control:Show() else control:Hide() end
    end
end

local alertDungeonControls = {
    dungeonEnableCheckbox, dungeonEnableLabel,
    dungeonColorLabel,
    dungeonDurationLabel, dungeonDurationEdit,
    dungeonColorRow.GREEN, dungeonColorRow.YELLOW, dungeonColorRow.RED,
}

local alertRaidControls = {
    raidRollCheckbox, raidRollLabel,
    raidRollColorLabel,
    alertRaidRollColorButtons.GREEN, alertRaidRollColorButtons.YELLOW, alertRaidRollColorButtons.RED,
    raidRollDurationLabel, raidRollDurationEdit,
    raidRollStyleLabel,
    alertRaidRollStyleButtons.SMOOTH, alertRaidRollStyleButtons.AGGRESSIVE,
    raidRollSoundCheckbox, raidRollSoundLabel,
    raidRollSoundChoiceLabel,
    alertRaidRollSoundButtons.RaidWarning, alertRaidRollSoundButtons.ReadyCheck,
    raidDivider,
    raidReadyCheckbox, raidReadyLabel,
    raidReadyColorLabel,
    alertRaidReadyColorButtons.GREEN, alertRaidReadyColorButtons.YELLOW, alertRaidReadyColorButtons.RED,
    raidReadyDurationLabel, raidReadyDurationEdit,
    raidReadyStyleLabel,
    alertRaidReadyStyleButtons.SMOOTH, alertRaidReadyStyleButtons.AGGRESSIVE,
    raidReadySoundCheckbox, raidReadySoundLabel,
    raidReadySoundChoiceLabel,
    alertRaidReadySoundButtons.RaidWarning, alertRaidReadySoundButtons.ReadyCheck,
}

local alertWintergraspControls = {
    wgEnableCheckbox, wgEnableLabel,
    wgSectionLabel,
    wgAlert1MinutesLabel, wgAlert1MinutesEdit,
    wgAlert1DurationLabel, wgAlert1DurationEdit,
    wgAlert1ColorLabel,
    alertWGColorButtons.GREEN, alertWGColorButtons.YELLOW, alertWGColorButtons.RED,
    wgAlert1SoundCheckbox, wgAlert1SoundLabel,
    wgAlert1SoundChoiceLabel,
    alertWGAlert1SoundButtons.RaidWarning, alertWGAlert1SoundButtons.ReadyCheck,
    wgDivider,
    wgStartLabel,
    wgAlert2MinutesLabel, wgAlert2MinutesEdit,
    wgAlert2DurationLabel, wgAlert2DurationEdit,
    wgAlert2ColorLabel,
    alertWGAlert2ColorButtons.GREEN, alertWGAlert2ColorButtons.YELLOW, alertWGAlert2ColorButtons.RED,
    wgSoundCheckbox, wgSoundLabel,
    wgSoundChoiceLabel,
    alertSoundButtons.RaidWarning, alertSoundButtons.ReadyCheck,
}

-- ============================================
--  SETTINGS RANDOM: Alert list and add/delete
-- ============================================
local randomListBackground = CreateFrame("Frame", nil, sc)
randomListBackground:SetPoint("TOPLEFT", sc, "TOPLEFT", 6, -210)
randomListBackground:SetPoint("TOPRIGHT", sc, "TOPRIGHT", -6, -210)
randomListBackground:SetHeight(120)
randomListBackground:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
randomListBackground:SetBackdropColor(0, 0, 0, 0.6)
randomListBackground:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

local randomAlertRows = {}

function DetaurBar.UI.UpdateRandomAlertRows()
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
                DetaurBar.UI.UpdateAlertPanel()
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

local randomAddEdit = CreateFrame("EditBox", nil, sc)
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
randomAddEdit:SetFrameLevel(sc:GetFrameLevel() + 10)
randomAddEdit:SetMaxLetters(40)
randomAddEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
randomAddEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local randomAddButton = CreateFrame("Button", nil, sc, "UIPanelButtonTemplate")
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
        DetaurBar.UI.UpdateAlertPanel()
    end
end)

local randomDeleteButton = CreateFrame("Button", nil, sc, "UIPanelButtonTemplate")
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
        DetaurBar.UI.UpdateAlertPanel()
    end
end)

local alertRandomControls = {
    randomEnableCheckbox, randomEnableLabel,
    randomIntervalLabel, randomIntervalEdit,
    randomDurationLabel, randomDurationEdit,
    randomColorLabel,
    alertRandomColorButtons.GREEN, alertRandomColorButtons.YELLOW, alertRandomColorButtons.RED,
    randomSoundCheckbox, randomSoundLabel,
    randomSoundChoiceLabel,
    alertRandomSoundButtons.RaidWarning, alertRandomSoundButtons.ReadyCheck,
    randomListBackground,
    randomAddEdit, randomAddButton, randomDeleteButton,
}

-- ============================================
--  SETTINGS CONTROLS: Enemy sub-tab
-- ============================================
local enemyEnableCheckbox, enemyEnableLabel = CreateAlertCheck(sc, "Enable Enemy Detection", 8, -8, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.enemyEnabled = self:GetChecked() and true or false
    DetaurBar.Enemy.UpdateZoneType()
    if DetaurBar.Enemy.UpdateToggleIcon then
        DetaurBar.Enemy.UpdateToggleIcon()
    end
end)
DetaurBar.UI.enemyEnableCheckbox = enemyEnableCheckbox
DetaurBar.UI.SetSimpleTooltip(enemyEnableCheckbox, "Enable Enemy Detection", "Detect nearby hostile players via combat events.")

local enemySectionLabel = CreateAlertLabel(sc, "Alert on Detection", 8, -40)

local enemyFlashCheckbox, enemyFlashLabel = CreateAlertCheck(sc, "Screen Flash", 8, -68, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.enemyFlashEnabled = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(enemyFlashCheckbox, "Screen Flash", "Flash the screen when a new enemy is detected.")

local enemyColorLabel = CreateAlertLabel(sc, "Flash Color", 8, -96)
local alertEnemyColorButtons = {}
CreateAlertChoiceRow(sc, alertEnemyColorButtons, {
    { key = "GREEN", label = "Green", tooltip = "Use a green flash." },
    { key = "YELLOW", label = "Yellow", tooltip = "Use a yellow flash." },
    { key = "RED", label = "Red", tooltip = "Use a red flash." },
}, 8, -112, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.enemyFlashColor = value
end)

local enemyStyleLabel = CreateAlertLabel(sc, "Flash Style", 8, -140)
local alertEnemyStyleButtons = {}
CreateAlertChoiceRow(sc, alertEnemyStyleButtons, {
    { key = "SMOOTH", label = "Smooth", tooltip = "Subtle border-edge flash." },
    { key = "AGGRESSIVE", label = "Aggressive", tooltip = "Full-screen pulsing flash." },
}, 8, -156, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.enemyFlashStyle = value
end)

local enemySoundCheckbox, enemySoundLabel = CreateAlertCheck(sc, "Play Sound", 8, -185, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.enemyPlaySound = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(enemySoundCheckbox, "Play Sound", "Play a sound when a new enemy is detected.")

local enemySoundChoiceLabel = CreateAlertLabel(sc, "Select Sound", 8, -211)
local alertEnemySoundButtons = {}
CreateAlertChoiceRow(sc, alertEnemySoundButtons, {
    { key = "RaidWarning", label = "Raid", tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = "Ready", tooltip = "Play the Ready Check sound." },
}, 8, -227, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.enemySound = value
end)

local enemyMindControlDivider = CreateSectionDivider(sc)
enemyMindControlDivider:SetPoint("TOP", alertEnemySoundButtons.ReadyCheck, "BOTTOM", 0, -10)
enemyMindControlDivider:SetPoint("LEFT", sc, "LEFT", 10)
enemyMindControlDivider:SetPoint("RIGHT", sc, "RIGHT", -10)

local enemyMindControlCheckbox, enemyMindControlLabel = CreateAlertCheck(sc, "Alert Mind Control", 8, -4, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.mindControlAlertEnabled = self:GetChecked() and true or false
end)
enemyMindControlCheckbox:ClearAllPoints()
enemyMindControlCheckbox:SetPoint("TOPLEFT", sc, "TOPLEFT", 8, -275)

local alertEnemyControls = {
    enemyEnableCheckbox, enemyEnableLabel,
    enemySectionLabel,
    enemyFlashCheckbox, enemyFlashLabel,
    enemyColorLabel,
    alertEnemyColorButtons.GREEN, alertEnemyColorButtons.YELLOW, alertEnemyColorButtons.RED,
    enemyStyleLabel,
    alertEnemyStyleButtons.SMOOTH, alertEnemyStyleButtons.AGGRESSIVE,
    enemySoundCheckbox, enemySoundLabel,
    enemySoundChoiceLabel,
    alertEnemySoundButtons.RaidWarning, alertEnemySoundButtons.ReadyCheck,
    enemyMindControlDivider,
    enemyMindControlCheckbox, enemyMindControlLabel,
}

-- ============================================
--  SETTINGS CONTROLS: Buffs sub-tab
-- ============================================
local alertBuffsControls = {}

local buffsEnableCheckbox, buffsEnableLabel = CreateAlertCheck(sc, "Enable Cooldown Tracking", 8, -8, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.buffsEnabled = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(buffsEnableCheckbox, "Enable Buff/Cooldown Tracking", "Show center-screen icons when cooldowns expire or stacking buffs change.")
table.insert(alertBuffsControls, buffsEnableCheckbox)
table.insert(alertBuffsControls, buffsEnableLabel)

-- Section: Cooldowns
local buffsCooldownLabel = CreateAlertLabel(sc, "Cooldown Slots (drag spells from spellbook)", 8, -40)
buffsCooldownLabel:SetFontObject("GameFontNormalSmall")
buffsCooldownLabel:SetTextColor(0.6, 0.6, 0.6, 1.0)
table.insert(alertBuffsControls, buffsCooldownLabel)

local buffsSpellSlots = {}
local slotGap = 8
local slotSize = 36
for i = 1, 4 do
    local slot = CreateFrame("Button", nil, sc)
    slot:SetSize(slotSize, slotSize)
    slot:SetPoint("TOPLEFT", sc, "TOPLEFT", 8 + (i - 1) * (slotSize + slotGap), -64)
    slot:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    slot:SetBackdropColor(0, 0, 0, 0.8)
    slot:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)

    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(slot)
    icon:Hide()

    local closeX = CreateFrame("Button", nil, slot)
    closeX:SetSize(12, 12)
    closeX:SetPoint("TOPRIGHT", slot, "TOPRIGHT", 2, -2)
    closeX:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    closeX:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
    closeX:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
    closeX:Hide()
    closeX:SetScript("OnClick", function()
        DetaurBar.Data.InitializeDB()
        if DetaurBarDB.settings.buffsSpellSlots then
            DetaurBarDB.settings.buffsSpellSlots[i] = nil
        end
        DetaurBar.UI.UpdateAlertPanel()
        if DetaurBar.Buffs and DetaurBar.Buffs.OnSlotChanged then DetaurBar.Buffs.OnSlotChanged() end
    end)

    slot:EnableMouse(true)
    slot:RegisterForDrag("LeftButton")
    slot:SetScript("OnReceiveDrag", function()
        local infoType, bookIndexOrId, bookType = GetCursorInfo()
        if infoType == "spell" and bookIndexOrId then
            DetaurBar.Data.InitializeDB()
            if not DetaurBarDB.settings.buffsSpellSlots then DetaurBarDB.settings.buffsSpellSlots = {} end
            local name, _, icon = GetSpellInfo(bookIndexOrId, bookType or "spell")
            local spellId = select(10, GetSpellInfo(bookIndexOrId, bookType or "spell"))
            DetaurBarDB.settings.buffsSpellSlots[i] = { id = spellId or bookIndexOrId, name = name, icon = icon, bookIndex = bookIndexOrId, bookType = bookType or "spell" }
            ClearCursor()
            DetaurBar.UI.UpdateAlertPanel()
            if DetaurBar.Buffs and DetaurBar.Buffs.OnSlotChanged then DetaurBar.Buffs.OnSlotChanged() end
        end
    end)
    slot:SetScript("OnEnter", function(self)
        local data = DetaurBarDB.settings.buffsSpellSlots and DetaurBarDB.settings.buffsSpellSlots[i]
        if data then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(data.name or ("Spell ID: " .. data.id), 1.0, 1.0, 1.0)
            GameTooltip:Show()
        end
    end)
    slot:SetScript("OnLeave", function() GameTooltip:Hide() end)

    slot.icon = icon
    slot.closeX = closeX

    buffsSpellSlots[i] = slot
    table.insert(alertBuffsControls, slot)
end

-- Divider after cooldown slots
local buffsDivider = CreateSectionDivider(sc)
buffsDivider:SetPoint("TOP", buffsSpellSlots[1], "BOTTOM", 0, -12)
buffsDivider:SetPoint("LEFT", sc, "LEFT", 10)
buffsDivider:SetPoint("RIGHT", sc, "RIGHT", -10)
table.insert(alertBuffsControls, buffsDivider)

-- Show maelstorm stack checkbox
local buffsStacksCheckbox, buffsStacksLabel = CreateAlertCheck(sc, "Show maelstorm stack", 0, 0, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.buffsFollowStacks = self:GetChecked() and true or false
end)
buffsStacksCheckbox:ClearAllPoints()
buffsStacksCheckbox:SetPoint("TOPLEFT", sc, "TOPLEFT", 8, -132)
DetaurBar.UI.SetSimpleTooltip(buffsStacksCheckbox, "Show maelstorm stack", "Show icon center-screen when Maelstrom Weapon reaches 5 stacks.")
table.insert(alertBuffsControls, buffsStacksCheckbox)
table.insert(alertBuffsControls, buffsStacksLabel)

-- ============================================
--  SELECT SETTINGS SUB-TAB
-- ============================================
function DetaurBar.UI.SelectAlertSubTab(subTabName)
    DetaurBar.UI.activeAlertSubTab = subTabName
    DetaurBar.UI.UpdateAlertSubTabBar()
    DetaurBar.UI.UpdateAlertSubTabVisuals()

    if alertScrollBar then
        alertScrollBar:SetValue(0)
    end

    SetAlertControlsVisible(alertDungeonControls, subTabName == "Dung")
    SetAlertControlsVisible(alertRaidControls, subTabName == "Raid")
    SetAlertControlsVisible(alertWintergraspControls, subTabName == "WG")
    SetAlertControlsVisible(alertRandomControls, subTabName == "Random")
    SetAlertControlsVisible(alertEnemyControls, subTabName == "Enemy")
    SetAlertControlsVisible(alertBuffsControls, subTabName == "Buffs")

    if DetaurBar.UI.UpdateContentAnchors then
        DetaurBar.UI.UpdateContentAnchors()
    end
    DetaurBar.UI.UpdateAlertPanel()
end

-- ============================================
--  UPDATE SETTINGS PANEL
-- ============================================
function DetaurBar.UI.UpdateAlertPanel()
    local settings = DetaurBar.UI.GetSettingsDB()

    dungeonEnableCheckbox:SetChecked(settings.dungeonFlashEnabled and 1 or nil)
    SetButtonGroupValue(dungeonColorRow, settings.dungeonFlashColor or "YELLOW")
    dungeonDurationEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.dungeonFlashDuration, 0, 0, 120)))
    DetaurBar.UI.ahIntervalEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.ahScanInterval, 10, 1, 120)))

    raidRollCheckbox:SetChecked(settings.raidRollAlertEnabled and 1 or nil)
    SetButtonGroupValue(alertRaidRollColorButtons, settings.raidRollAlertColor or "YELLOW")
    raidRollDurationEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.raidRollAlertDuration, 0, 0, 30)))
    SetButtonGroupValue(alertRaidRollStyleButtons, settings.raidRollAlertStyle or "AGGRESSIVE")
    raidRollSoundCheckbox:SetChecked(settings.raidRollAlertPlaySound and 1 or nil)
    SetButtonGroupValue(alertRaidRollSoundButtons, settings.raidRollAlertSound or "RaidWarning")

    raidReadyCheckbox:SetChecked(settings.raidReadyCheckAlertEnabled and 1 or nil)
    SetButtonGroupValue(alertRaidReadyColorButtons, settings.raidReadyCheckAlertColor or "YELLOW")
    raidReadyDurationEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.raidReadyCheckAlertDuration, 0, 0, 30)))
    SetButtonGroupValue(alertRaidReadyStyleButtons, settings.raidReadyCheckAlertStyle or "AGGRESSIVE")
    raidReadySoundCheckbox:SetChecked(settings.raidReadyCheckAlertPlaySound and 1 or nil)
    SetButtonGroupValue(alertRaidReadySoundButtons, settings.raidReadyCheckAlertSound or "RaidWarning")

    wgEnableCheckbox:SetChecked(settings.wgAlertsEnabled and 1 or nil)
    wgAlert1MinutesEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.wgAlert1Minutes, 15, 0, 120)))
    wgAlert1DurationEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.wgAlert1Duration, 2, 0, 30)))
    SetButtonGroupValue(alertWGColorButtons, settings.wgAlert1Color or "YELLOW")
    wgAlert1SoundCheckbox:SetChecked(settings.wgAlert1PlaySound and 1 or nil)
    SetButtonGroupValue(alertWGAlert1SoundButtons, settings.wgAlert1Sound or "RaidWarning")
    wgAlert2MinutesEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.wgAlert2Minutes, 1, 0, 120)))
    wgAlert2DurationEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.wgAlert2Duration, 0, 0, 30)))
    SetButtonGroupValue(alertWGAlert2ColorButtons, settings.wgAlert2Color or "YELLOW")
    wgSoundCheckbox:SetChecked(settings.wgAlert2PlaySound and 1 or nil)
    SetButtonGroupValue(alertSoundButtons, settings.wgAlert2Sound or "RaidWarning")

    if randomEnableCheckbox then
        randomEnableCheckbox:SetChecked(settings.randomAlertsEnabled and 1 or nil)
        local a = DetaurBar.Data.GetRandomActiveAlert()
        if a then
            randomIntervalEdit:SetText(tostring(a.intervalMinutes or 5))
            randomDurationEdit:SetText(tostring(a.flashDuration or 3))
            SetButtonGroupValue(alertRandomColorButtons, a.flashColor or "YELLOW")
            randomSoundCheckbox:SetChecked(a.playSound and 1 or nil)
            SetButtonGroupValue(alertRandomSoundButtons, a.sound or "RaidWarning")
        end
        DetaurBar.UI.UpdateRandomAlertRows()
    end

    enemyEnableCheckbox:SetChecked(settings.enemyEnabled and 1 or nil)
    if DetaurBar.Enemy.UpdateToggleIcon then DetaurBar.Enemy.UpdateToggleIcon() end
    enemyFlashCheckbox:SetChecked(settings.enemyFlashEnabled and 1 or nil)
    SetButtonGroupValue(alertEnemyColorButtons, settings.enemyFlashColor or "YELLOW")
    SetButtonGroupValue(alertEnemyStyleButtons, settings.enemyFlashStyle or "AGGRESSIVE")
    enemySoundCheckbox:SetChecked(settings.enemyPlaySound and 1 or nil)
    SetButtonGroupValue(alertEnemySoundButtons, settings.enemySound or "RaidWarning")
    enemyMindControlCheckbox:SetChecked(settings.mindControlAlertEnabled and 1 or nil)

    SetAlertControlsVisible(alertDungeonControls, DetaurBar.UI.activeAlertSubTab == "Dung")
    SetAlertControlsVisible(alertRaidControls, DetaurBar.UI.activeAlertSubTab == "Raid")
    SetAlertControlsVisible(alertWintergraspControls, DetaurBar.UI.activeAlertSubTab == "WG")
    SetAlertControlsVisible(alertRandomControls, DetaurBar.UI.activeAlertSubTab == "Random")
    SetAlertControlsVisible(alertEnemyControls, DetaurBar.UI.activeAlertSubTab == "Enemy")
    SetAlertControlsVisible(alertBuffsControls, DetaurBar.UI.activeAlertSubTab == "Buffs")

    -- Update spell slot icons
    if DetaurBar.UI.activeAlertSubTab == "Buffs" then
        for i, slot in ipairs(buffsSpellSlots) do
            local data = settings.buffsSpellSlots and settings.buffsSpellSlots[i]
            if data and data.id then
                local _, _, icon
                if data.bookIndex and data.bookType then
                    _, _, icon = GetSpellInfo(data.bookIndex, data.bookType)
                end
                if not icon then
                    _, _, icon = GetSpellInfo(data.id)
                end
                if not icon then icon = data.icon end
                if icon then
                    slot.icon:SetTexture(icon)
                    slot.icon:Show()
                else
                    slot.icon:Hide()
                end
                slot.closeX:Show()
            else
                slot.icon:Hide()
                slot.closeX:Hide()
            end
        end
        buffsEnableCheckbox:SetChecked(settings.buffsEnabled and 1 or nil)
        buffsStacksCheckbox:SetChecked(settings.buffsFollowStacks and 1 or nil)
    end
    if DetaurBar.UI.alertScrollFrame then DetaurBar.UI.alertScrollFrame:Show() end
    if DetaurBar.UI.alertScrollChild then DetaurBar.UI.alertScrollChild:Show() end

    DetaurBar.UI.UpdateAlertScroll()
end

-- ============================================
--  UPDATE SETTINGS SCROLL
-- ============================================
function DetaurBar.UI.UpdateAlertScroll()
    if not DetaurBar.UI.alertScrollFrame or not DetaurBar.UI.alertScrollChild then
        return
    end
    DetaurBar.UI.alertScrollFrame:Show()
    DetaurBar.UI.alertScrollChild:Show()

    local innerWidth = DetaurBar.UI.alertScrollFrame:GetWidth() or 0
    if innerWidth <= 0 then
        innerWidth = math.max(1, _G["DetaurBarFrame"]:GetWidth() - 64)
    end
    DetaurBar.UI.alertScrollChild:SetWidth(innerWidth)

    local contentHeight = 0
    if DetaurBar.UI.activeAlertSubTab == "Dung" then
        contentHeight = 180
    elseif DetaurBar.UI.activeAlertSubTab == "Raid" then
        contentHeight = 470
    elseif DetaurBar.UI.activeAlertSubTab == "WG" then
        contentHeight = 480
    elseif DetaurBar.UI.activeAlertSubTab == "Random" then
        contentHeight = 380
    elseif DetaurBar.UI.activeAlertSubTab == "Enemy" then
        contentHeight = 300
    elseif DetaurBar.UI.activeAlertSubTab == "Buffs" then
        contentHeight = 220
    else
        contentHeight = 120
    end
    DetaurBar.UI.alertScrollChild:SetHeight(contentHeight)

    local visibleHeight = DetaurBar.UI.alertScrollFrame:GetHeight() or 0
    if visibleHeight <= 0 then
        visibleHeight = DetaurBar.UI.alertListBackground and DetaurBar.UI.alertListBackground:GetHeight() or (_G["DetaurBarFrame"]:GetHeight() - 120)
    end
    if visibleHeight <= 0 then
        visibleHeight = 300
    end
    local maxScroll = math.max(0, contentHeight - visibleHeight)
    alertScrollBar:SetMinMaxValues(0, maxScroll)

    if maxScroll == 0 then
        alertScrollBar:SetValue(0)
        alertScrollBar:Hide()
    else
        alertScrollBar:Show()
        local currentVal = alertScrollBar:GetValue()
        if currentVal > maxScroll then
            alertScrollBar:SetValue(maxScroll)
        end
    end
    DetaurBar.UI.alertScrollFrame:SetVerticalScroll(alertScrollBar:GetValue())
end

-- ============================================
--  SAVE SETTINGS
-- ============================================
function DetaurBar.UI.SaveSettings()
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.dungeonFlashEnabled = dungeonEnableCheckbox:GetChecked() and true or false
    settings.dungeonFlashDuration = DetaurBar.UI.ClampNumber(dungeonDurationEdit:GetText(), 0, 0, 120)
    settings.ahScanInterval = DetaurBar.UI.ClampNumber(DetaurBar.UI.ahIntervalEdit:GetText(), 10, 1, 120)
    settings.raidRollAlertEnabled = raidRollCheckbox:GetChecked() and true or false
    settings.raidRollAlertDuration = DetaurBar.UI.ClampNumber(raidRollDurationEdit:GetText(), 0, 0, 30)
    settings.raidRollAlertPlaySound = raidRollSoundCheckbox:GetChecked() and true or false
    for key, btn in pairs(alertRaidRollColorButtons) do
        if not btn:IsEnabled() then settings.raidRollAlertColor = key; break end
    end
    for key, btn in pairs(alertRaidRollStyleButtons) do
        if not btn:IsEnabled() then settings.raidRollAlertStyle = key; break end
    end
    for key, btn in pairs(alertRaidRollSoundButtons) do
        if not btn:IsEnabled() then settings.raidRollAlertSound = key; break end
    end
    settings.raidReadyCheckAlertEnabled = raidReadyCheckbox:GetChecked() and true or false
    settings.raidReadyCheckAlertDuration = DetaurBar.UI.ClampNumber(raidReadyDurationEdit:GetText(), 0, 0, 30)
    settings.raidReadyCheckAlertPlaySound = raidReadySoundCheckbox:GetChecked() and true or false
    for key, btn in pairs(alertRaidReadyColorButtons) do
        if not btn:IsEnabled() then settings.raidReadyCheckAlertColor = key; break end
    end
    for key, btn in pairs(alertRaidReadyStyleButtons) do
        if not btn:IsEnabled() then settings.raidReadyCheckAlertStyle = key; break end
    end
    for key, btn in pairs(alertRaidReadySoundButtons) do
        if not btn:IsEnabled() then settings.raidReadyCheckAlertSound = key; break end
    end
    settings.wgAlertsEnabled = wgEnableCheckbox:GetChecked() and true or false
    settings.wgAlert1Minutes = DetaurBar.UI.ClampNumber(wgAlert1MinutesEdit:GetText(), 15, 0, 120)
    settings.wgAlert1Duration = DetaurBar.UI.ClampNumber(wgAlert1DurationEdit:GetText(), 2, 0, 30)
    settings.wgAlert1PlaySound = wgAlert1SoundCheckbox:GetChecked() and true or false
    settings.wgAlert2Minutes = DetaurBar.UI.ClampNumber(wgAlert2MinutesEdit:GetText(), 1, 0, 120)
    settings.wgAlert2Duration = DetaurBar.UI.ClampNumber(wgAlert2DurationEdit:GetText(), 0, 0, 30)
    settings.wgAlert2PlaySound = wgSoundCheckbox:GetChecked() and true or false
    settings.randomAlertsEnabled = randomEnableCheckbox:GetChecked() and true or false
    local activeAlert = DetaurBar.Data.GetRandomActiveAlert()
    if activeAlert then
        activeAlert.intervalMinutes = DetaurBar.UI.ClampNumber(randomIntervalEdit:GetText(), 5, 1, 999)
        activeAlert.flashDuration = DetaurBar.UI.ClampNumber(randomDurationEdit:GetText(), 0, 0, 30)
        activeAlert.playSound = randomSoundCheckbox:GetChecked() and true or false
    end

    settings.enemyEnabled = enemyEnableCheckbox:GetChecked() and true or false
    if DetaurBar.Enemy.UpdateToggleIcon then DetaurBar.Enemy.UpdateToggleIcon() end
    settings.enemyFlashEnabled = enemyFlashCheckbox:GetChecked() and true or false
    settings.enemyPlaySound = enemySoundCheckbox:GetChecked() and true or false
    for key, btn in pairs(alertEnemyColorButtons) do
        if not btn:IsEnabled() then settings.enemyFlashColor = key; break end
    end
    for key, btn in pairs(alertEnemyStyleButtons) do
        if not btn:IsEnabled() then settings.enemyFlashStyle = key; break end
    end
    for key, btn in pairs(alertEnemySoundButtons) do
        if not btn:IsEnabled() then settings.enemySound = key; break end
    end

    DetaurBar.UI.UpdateAlertPanel()
    if DetaurBar.Alerts and DetaurBar.Alerts.ResetAlertState then
        DetaurBar.Alerts.ResetAlertState()
    end
    print("|cffffff00DetaurBar:|r Settings saved.")
end

DetaurBar.UI.alertPanel:SetScript("OnSizeChanged", function()
    DetaurBar.UI.UpdateAlertSubTabBar()
end)
