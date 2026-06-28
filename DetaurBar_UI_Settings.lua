-- DetaurBar_UI_Settings.lua
-- Settings panel, sub-tabs, controls, and management

DetaurBar = DetaurBar or {}
DetaurBar.UI = DetaurBar.UI or {}

-- ============================================
--  STATE: Settings-specific variables
-- ============================================
local settingsWGAlert1SoundButtons = {}
local settingsWGAlert2ColorButtons = {}
local settingsRandomColorButtons = {}
local settingsRandomSoundButtons = {}

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
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    edit:SetBackdropColor(0, 0, 0, 0.8)
    edit:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
    return edit
end

local function CreateSettingsLabel(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    return label
end

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

local function SetButtonGroupValue(group, value)
    for key, button in pairs(group) do
        SetChoiceButtonStyle(button, key == value)
    end
end

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
        DetaurBar.UI.SetSimpleTooltip(button, opt.label, opt.tooltip or ("Select " .. opt.label .. "."))
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

-- ============================================
--  SETTINGS PANEL: Main backdrop frame
-- ============================================
DetaurBar.UI.settingsPanel = CreateFrame("Frame", "DetaurBarSettingsPanel", _G["DetaurBarFrame"])
DetaurBar.UI.settingsPanel:SetPoint("TOPLEFT", _G["DetaurBarFrame"], "TOPLEFT", 16, -60)
DetaurBar.UI.settingsPanel:SetPoint("BOTTOMRIGHT", _G["DetaurBarFrame"], "BOTTOMRIGHT", -16, 14)
DetaurBar.UI.settingsPanel:Hide()
DetaurBar.UI.settingsPanel:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
DetaurBar.UI.settingsPanel:SetBackdropColor(0, 0, 0, 0.0)
DetaurBar.UI.settingsPanel:SetBackdropBorderColor(0, 0, 0, 0)

-- Sub-tab bar inside settings panel
DetaurBar.UI.settingsSubTabBar = CreateFrame("Frame", "DetaurBarSettingsSubTabBar", DetaurBar.UI.settingsPanel)
DetaurBar.UI.settingsSubTabBar:SetHeight(24)
DetaurBar.UI.settingsSubTabBar:SetPoint("TOPLEFT", DetaurBar.UI.settingsPanel, "TOPLEFT", 8, -8)
DetaurBar.UI.settingsSubTabBar:SetPoint("TOPRIGHT", DetaurBar.UI.settingsPanel, "TOPRIGHT", -24, -8)
DetaurBar.UI.settingsSubTabBar:Hide()

-- Background frame for settings content
DetaurBar.UI.settingsListBackground = CreateFrame("Frame", "DetaurBarSettingsListBackground", DetaurBar.UI.settingsPanel)
DetaurBar.UI.settingsListBackground:SetPoint("TOPLEFT", DetaurBar.UI.settingsSubTabBar, "BOTTOMLEFT", -1, -2)
DetaurBar.UI.settingsListBackground:SetPoint("BOTTOMRIGHT", DetaurBar.UI.settingsPanel, "BOTTOMRIGHT", 0, 36)
DetaurBar.UI.settingsListBackground:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
DetaurBar.UI.settingsListBackground:SetBackdropColor(0, 0, 0, 0.4)
DetaurBar.UI.settingsListBackground:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
DetaurBar.UI.settingsListBackground:Hide()

-- ScrollFrame for settings content
DetaurBar.UI.settingsScrollFrame = CreateFrame("ScrollFrame", "DetaurBarSettingsScrollFrame", DetaurBar.UI.settingsListBackground)
DetaurBar.UI.settingsScrollFrame:SetPoint("TOPLEFT", DetaurBar.UI.settingsListBackground, "TOPLEFT", 0, 0)
DetaurBar.UI.settingsScrollFrame:SetPoint("BOTTOMRIGHT", DetaurBar.UI.settingsListBackground, "BOTTOMRIGHT", -16, 0)
DetaurBar.UI.settingsScrollFrame:Hide()
DetaurBar.UI.settingsScrollFrame:EnableMouseWheel(true)

-- Vertical scroll bar
local settingsScrollBar = CreateFrame("Slider", "DetaurBarSettingsScrollBar", DetaurBar.UI.settingsScrollFrame, "UIPanelScrollBarTemplate")
settingsScrollBar:SetPoint("TOPLEFT", DetaurBar.UI.settingsScrollFrame, "TOPRIGHT", 4, -16)
settingsScrollBar:SetPoint("BOTTOMLEFT", DetaurBar.UI.settingsScrollFrame, "BOTTOMRIGHT", 4, 16)
settingsScrollBar:SetWidth(16)
settingsScrollBar:SetValueStep(1)
settingsScrollBar:SetMinMaxValues(0, 0)
settingsScrollBar:SetValue(0)
settingsScrollBar:SetScript("OnValueChanged", function(self, value)
    DetaurBar.UI.settingsScrollFrame:SetVerticalScroll(value)
end)

DetaurBar.UI.settingsScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = settingsScrollBar:GetValue()
    settingsScrollBar:SetValue(current - delta * 20)
end)

-- Scroll child — actual content parent
DetaurBar.UI.settingsScrollChild = CreateFrame("Frame", "DetaurBarSettingsScrollChild", DetaurBar.UI.settingsScrollFrame)
DetaurBar.UI.settingsScrollFrame:SetScrollChild(DetaurBar.UI.settingsScrollChild)
DetaurBar.UI.settingsScrollChild:SetWidth(math.max(1, DetaurBar.UI.settingsScrollFrame:GetWidth() or (_G["DetaurBarFrame"]:GetWidth() - 64)))
DetaurBar.UI.settingsScrollChild:SetHeight(390)

-- ============================================
--  SETTINGS SUB-TABS: Dungeon / Wintergrasp / Random
-- ============================================
local settingsSubTabNames = { "Dungeon", "Wintergrasp", "Random", "Enemy" }
for i, name in ipairs(settingsSubTabNames) do
    local subTab = CreateFrame("Button", "DetaurBarSettingsSubTab_" .. name, DetaurBar.UI.settingsPanel)
    subTab:SetHeight(24)
    subTab:SetFrameLevel(DetaurBar.UI.settingsPanel:GetFrameLevel() + 6)
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
        DetaurBar.UI.SelectSettingsSubTab(name)
    end)
    DetaurBar.UI.settingsSubTabs[i] = subTab
end

-- ============================================
--  SUB-TAB STYLE: Gold active / Dark inactive
-- ============================================
local function SetSettingsSubTabStyle(subTab)
    if subTab.tabName == DetaurBar.UI.activeSettingsSubTab then
        subTab:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
        subTab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        subTab.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    else
        subTab:SetBackdropColor(0, 0, 0, 0.55)
        subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        subTab.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
    end
end

function DetaurBar.UI.UpdateSettingsSubTabBar()
    local totalWidth = DetaurBar.UI.settingsPanel:GetWidth() - 8
    local subTabGap = 4
    local numTabs = #DetaurBar.UI.settingsSubTabs
    local subTabWidth = (totalWidth - (subTabGap * (numTabs - 1))) / math.max(1, numTabs)
    for i, subTab in ipairs(DetaurBar.UI.settingsSubTabs) do
        subTab:SetWidth(subTabWidth)
        subTab:ClearAllPoints()
        if i == 1 then
            subTab:SetPoint("TOPLEFT", DetaurBar.UI.settingsSubTabBar, "TOPLEFT", 0, 0)
        else
            subTab:SetPoint("LEFT", DetaurBar.UI.settingsSubTabs[i-1], "RIGHT", subTabGap, 0)
        end
    end
end

function DetaurBar.UI.UpdateSettingsSubTabVisuals()
    for _, subTab in ipairs(DetaurBar.UI.settingsSubTabs) do
        SetSettingsSubTabStyle(subTab)
        if subTab.tabName == DetaurBar.UI.activeSettingsSubTab then
            subTab:Disable()
        else
            subTab:Enable()
        end
    end
end

-- ============================================
--  SETTINGS CONTROLS: Dungeon sub-tab
-- ============================================
local sc = DetaurBar.UI.settingsScrollChild

local dungeonEnableCheckbox, dungeonEnableLabel = CreateSettingsCheck(sc, "Enable Dungeon Flash Alert", 8, -8, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.dungeonFlashEnabled = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(dungeonEnableCheckbox, "Enable Dungeon Flash Alert", "Flash the whole screen when a Dungeon Finder proposal appears.")

local dungeonColorLabel = CreateSettingsLabel(sc, "Flash Color", 8, -40)

local dungeonDurationLabel, dungeonDurationEdit = CreateSettingsEditRow(sc, "Flash duration", 8, -68, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.dungeonFlashDuration = DetaurBar.UI.ClampNumber(self:GetText(), 0, 0, 120)
    self:SetText(tostring(settings.dungeonFlashDuration))
end)
DetaurBar.UI.SetSimpleTooltip(dungeonDurationEdit, "Flash Duration", "How many seconds to flash. Set 0 for infinite (until proposal closes).")

local dungeonColorRow = {}
CreateSettingsChoiceRow(sc, dungeonColorRow, {
    { key = "GREEN", label = "Green", tooltip = "Use a green full-screen flash." },
    { key = "YELLOW", label = "Yellow", tooltip = "Use a yellow full-screen flash." },
    { key = "RED", label = "Red", tooltip = "Use a red full-screen flash." },
}, 8, -94, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.dungeonFlashColor = value
end)

-- ============================================
--  SETTINGS CONTROLS: Wintergrasp sub-tab
-- ============================================
local wgEnableCheckbox, wgEnableLabel = CreateSettingsCheck(sc, "Enable Wintergrasp Alerts", 8, -8, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlertsEnabled = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(wgEnableCheckbox, "Enable Wintergrasp Alerts", "Run background Wintergrasp countdown checks and fire warnings when the threshold is reached.")

local wgSectionLabel = CreateSettingsLabel(sc, "Registration Warning", 8, -40)

local wgAlert1MinutesLabel, wgAlert1MinutesEdit = CreateSettingsEditRow(sc, "Minutes before start", 8, -68, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert1Minutes = DetaurBar.UI.ClampNumber(self:GetText(), 15, 0, 120)
    self:SetText(tostring(settings.wgAlert1Minutes))
end)
DetaurBar.UI.SetSimpleTooltip(wgAlert1MinutesEdit, "Registration Warning", "Minutes before battle start to flash the screen.")

local wgAlert1DurationLabel, wgAlert1DurationEdit = CreateSettingsEditRow(sc, "Flash duration", 8, -96, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert1Duration = DetaurBar.UI.ClampNumber(self:GetText(), 2, 0, 30)
    self:SetText(tostring(settings.wgAlert1Duration))
end)
DetaurBar.UI.SetSimpleTooltip(wgAlert1DurationEdit, "Flash Duration", "How long the Wintergrasp registration warning should flash.")

local wgAlert1ColorLabel = CreateSettingsLabel(sc, "Flash Color", 8, -124)

local settingsWGColorButtons = {}
CreateSettingsChoiceRow(sc, settingsWGColorButtons, {
    { key = "GREEN", label = "Green", tooltip = "Use a green Wintergrasp flash." },
    { key = "YELLOW", label = "Yellow", tooltip = "Use a yellow Wintergrasp flash." },
    { key = "RED", label = "Red", tooltip = "Use a red Wintergrasp flash." },
}, 8, -140, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert1Color = value
end)

local wgAlert1SoundCheckbox, wgAlert1SoundLabel = CreateSettingsCheck(sc, "Play Sound", 8, -168, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert1PlaySound = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(wgAlert1SoundCheckbox, "Play Sound Alert", "Play a sound when the Registration Warning threshold is reached.")

local wgAlert1SoundChoiceLabel = CreateSettingsLabel(sc, "Select Sound", 8, -194)
CreateSettingsChoiceRow(sc, settingsWGAlert1SoundButtons, {
    { key = "RaidWarning", label = "Raid", tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = "Ready", tooltip = "Play the Ready Check sound." },
}, 8, -210, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert1Sound = value
end)

local wgStartLabel = CreateSettingsLabel(sc, "Battle Start Warning", 8, -248)

local wgAlert2MinutesLabel, wgAlert2MinutesEdit = CreateSettingsEditRow(sc, "Minutes before start", 8, -276, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert2Minutes = DetaurBar.UI.ClampNumber(self:GetText(), 1, 0, 120)
    self:SetText(tostring(settings.wgAlert2Minutes))
end)
DetaurBar.UI.SetSimpleTooltip(wgAlert2MinutesEdit, "Battle Start Warning", "Minutes before battle start to play the selected sound.")

local wgAlert2DurationLabel, wgAlert2DurationEdit = CreateSettingsEditRow(sc, "Flash duration", 8, -304, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert2Duration = DetaurBar.UI.ClampNumber(self:GetText(), 0, 0, 30)
    self:SetText(tostring(settings.wgAlert2Duration))
end)
DetaurBar.UI.SetSimpleTooltip(wgAlert2DurationEdit, "Flash Duration", "How long the Battle Start Warning should flash. Set 0 for no flash.")

local wgAlert2ColorLabel = CreateSettingsLabel(sc, "Flash Color", 8, -332)
CreateSettingsChoiceRow(sc, settingsWGAlert2ColorButtons, {
    { key = "GREEN", label = "Green", tooltip = "Use a green flash." },
    { key = "YELLOW", label = "Yellow", tooltip = "Use a yellow flash." },
    { key = "RED", label = "Red", tooltip = "Use a red flash." },
}, 8, -348, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert2Color = value
end)

local wgSoundCheckbox, wgSoundLabel = CreateSettingsCheck(sc, "Play Sound", 8, -376, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert2PlaySound = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(wgSoundCheckbox, "Play Sound Alert", "Play a sound when the Wintergrasp start threshold is reached.")

local wgSoundChoiceLabel = CreateSettingsLabel(sc, "Select Sound", 8, -402)

local settingsSoundButtons = {}
CreateSettingsChoiceRow(sc, settingsSoundButtons, {
    { key = "RaidWarning", label = "Raid", tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = "Ready", tooltip = "Play the Ready Check sound." },
}, 8, -418, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.wgAlert2Sound = value
end)

-- ============================================
--  SETTINGS CONTROLS: Random sub-tab
-- ============================================
local randomEnableCheckbox, randomEnableLabel = CreateSettingsCheck(sc, "Enable Random Alerts", 8, -8, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.randomAlertsEnabled = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(randomEnableCheckbox, "Enable Random Alerts", "Fire the selected alert on a repeating timer.")

local randomIntervalLabel, randomIntervalEdit = CreateSettingsEditRow(sc, "How often (minutes)", 8, -40, 36, 3, function(self)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then
        alert.intervalMinutes = DetaurBar.UI.ClampNumber(self:GetText(), 5, 1, 999)
        self:SetText(tostring(alert.intervalMinutes))
    end
end)
DetaurBar.UI.SetSimpleTooltip(randomIntervalEdit, "How Often", "Fire an alert every this many minutes.")

local randomDurationLabel, randomDurationEdit = CreateSettingsEditRow(sc, "Flash duration", 8, -68, 36, 3, function(self)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then
        alert.flashDuration = DetaurBar.UI.ClampNumber(self:GetText(), 0, 0, 30)
        self:SetText(tostring(alert.flashDuration))
    end
end)
DetaurBar.UI.SetSimpleTooltip(randomDurationEdit, "Flash Duration", "How long to flash. Set 0 for no flash.")

local randomColorLabel = CreateSettingsLabel(sc, "Flash Color", 8, -96)
CreateSettingsChoiceRow(sc, settingsRandomColorButtons, {
    { key = "GREEN", label = "Green", tooltip = "Use a green flash." },
    { key = "YELLOW", label = "Yellow", tooltip = "Use a yellow flash." },
    { key = "RED", label = "Red", tooltip = "Use a red flash." },
}, 8, -112, 162, function(value)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then alert.flashColor = value end
end)

local randomSoundCheckbox, randomSoundLabel = CreateSettingsCheck(sc, "Play Sound", 8, -140, function(self)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then alert.playSound = self:GetChecked() and true or false end
end)
DetaurBar.UI.SetSimpleTooltip(randomSoundCheckbox, "Play Sound", "Play a sound with each alert.")

local randomSoundChoiceLabel = CreateSettingsLabel(sc, "Select Sound", 8, -166)
CreateSettingsChoiceRow(sc, settingsRandomSoundButtons, {
    { key = "RaidWarning", label = "Raid", tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = "Ready", tooltip = "Play the Ready Check sound." },
}, 8, -182, 162, function(value)
    local alert = DetaurBar.Data.GetRandomActiveAlert()
    if alert then alert.sound = value end
end)

-- ============================================
--  SETTINGS SAVE BUTTON
-- ============================================
DetaurBar.UI.settingsSaveButton = CreateFrame("Button", "DetaurBarSettingsSaveButton", DetaurBar.UI.settingsPanel, "UIPanelButtonTemplate")
DetaurBar.UI.settingsSaveButton:SetSize(72, 22)
DetaurBar.UI.settingsSaveButton:SetPoint("BOTTOMRIGHT", DetaurBar.UI.settingsPanel, "BOTTOMRIGHT", -8, 8)
DetaurBar.UI.settingsSaveButton:SetText("Save")
DetaurBar.UI.settingsSaveButton:SetScript("OnClick", function()
    if DetaurBar.UI and DetaurBar.UI.SaveSettings then
        DetaurBar.UI.SaveSettings()
    end
end)

-- ============================================
--  SETTINGS CONTROL LISTS
-- ============================================
local function SetSettingsControlsVisible(group, visible)
    for _, control in ipairs(group) do
        if visible then control:Show() else control:Hide() end
    end
end

local settingsDungeonControls = {
    dungeonEnableCheckbox, dungeonEnableLabel,
    dungeonColorLabel,
    dungeonDurationLabel, dungeonDurationEdit,
    dungeonColorRow.GREEN, dungeonColorRow.YELLOW, dungeonColorRow.RED,
}

local settingsWintergraspControls = {
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
        DetaurBar.UI.UpdateSettingsPanel()
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
        DetaurBar.UI.UpdateSettingsPanel()
    end
end)

local settingsRandomControls = {
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

-- ============================================
--  SETTINGS CONTROLS: Enemy sub-tab
-- ============================================
local enemyEnableCheckbox, enemyEnableLabel = CreateSettingsCheck(sc, "Enable Enemy Detection", 8, -8, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.enemyEnabled = self:GetChecked() and true or false
    DetaurBar.Enemy.UpdateZoneType()
end)
DetaurBar.UI.SetSimpleTooltip(enemyEnableCheckbox, "Enable Enemy Detection", "Detect nearby hostile players via combat events.")

local enemySectionLabel = CreateSettingsLabel(sc, "Alert on Detection", 8, -40)

local enemyFlashCheckbox, enemyFlashLabel = CreateSettingsCheck(sc, "Screen Flash", 8, -68, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.enemyFlashEnabled = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(enemyFlashCheckbox, "Screen Flash", "Flash the screen when a new enemy is detected.")

local enemyColorLabel = CreateSettingsLabel(sc, "Flash Color", 8, -96)
local settingsEnemyColorButtons = {}
CreateSettingsChoiceRow(sc, settingsEnemyColorButtons, {
    { key = "GREEN", label = "Green", tooltip = "Use a green flash." },
    { key = "YELLOW", label = "Yellow", tooltip = "Use a yellow flash." },
    { key = "RED", label = "Red", tooltip = "Use a red flash." },
}, 8, -112, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.enemyFlashColor = value
end)

local enemyStyleLabel = CreateSettingsLabel(sc, "Flash Style", 8, -140)
local settingsEnemyStyleButtons = {}
CreateSettingsChoiceRow(sc, settingsEnemyStyleButtons, {
    { key = "SMOOTH", label = "Smooth", tooltip = "Subtle border-edge flash." },
    { key = "AGGRESSIVE", label = "Aggressive", tooltip = "Full-screen pulsing flash." },
}, 8, -156, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.enemyFlashStyle = value
end)

local enemySoundCheckbox, enemySoundLabel = CreateSettingsCheck(sc, "Play Sound", 8, -180, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.enemyPlaySound = self:GetChecked() and true or false
end)
DetaurBar.UI.SetSimpleTooltip(enemySoundCheckbox, "Play Sound", "Play a sound when a new enemy is detected.")

local enemySoundChoiceLabel = CreateSettingsLabel(sc, "Select Sound", 8, -206)
local settingsEnemySoundButtons = {}
CreateSettingsChoiceRow(sc, settingsEnemySoundButtons, {
    { key = "RaidWarning", label = "Raid", tooltip = "Play the Raid Warning sound." },
    { key = "ReadyCheck", label = "Ready", tooltip = "Play the Ready Check sound." },
}, 8, -222, 162, function(value)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.enemySound = value
end)

local settingsEnemyControls = {
    enemyEnableCheckbox, enemyEnableLabel,
    enemySectionLabel,
    enemyFlashCheckbox, enemyFlashLabel,
    enemyColorLabel,
    settingsEnemyColorButtons.GREEN, settingsEnemyColorButtons.YELLOW, settingsEnemyColorButtons.RED,
    enemyStyleLabel,
    settingsEnemyStyleButtons.SMOOTH, settingsEnemyStyleButtons.AGGRESSIVE,
    enemySoundCheckbox, enemySoundLabel,
    enemySoundChoiceLabel,
    settingsEnemySoundButtons.RaidWarning, settingsEnemySoundButtons.ReadyCheck,
}

-- ============================================
--  SELECT SETTINGS SUB-TAB
-- ============================================
function DetaurBar.UI.SelectSettingsSubTab(subTabName)
    DetaurBar.UI.activeSettingsSubTab = subTabName
    DetaurBar.UI.UpdateSettingsSubTabBar()
    DetaurBar.UI.UpdateSettingsSubTabVisuals()

    if settingsScrollBar then
        settingsScrollBar:SetValue(0)
    end

    SetSettingsControlsVisible(settingsDungeonControls, subTabName == "Dungeon")
    SetSettingsControlsVisible(settingsWintergraspControls, subTabName == "Wintergrasp")
    SetSettingsControlsVisible(settingsRandomControls, subTabName == "Random")
    SetSettingsControlsVisible(settingsEnemyControls, subTabName == "Enemy")

    if DetaurBar.UI.UpdateContentAnchors then
        DetaurBar.UI.UpdateContentAnchors()
    end
    DetaurBar.UI.UpdateSettingsPanel()
end

-- ============================================
--  UPDATE SETTINGS PANEL
-- ============================================
function DetaurBar.UI.UpdateSettingsPanel()
    local settings = DetaurBar.UI.GetSettingsDB()

    dungeonEnableCheckbox:SetChecked(settings.dungeonFlashEnabled and 1 or nil)
    SetButtonGroupValue(dungeonColorRow, settings.dungeonFlashColor or "YELLOW")
    dungeonDurationEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.dungeonFlashDuration, 0, 0, 120)))
    DetaurBar.UI.ahIntervalEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.ahScanInterval, 10, 1, 120)))

    wgEnableCheckbox:SetChecked(settings.wgAlertsEnabled and 1 or nil)
    wgAlert1MinutesEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.wgAlert1Minutes, 15, 0, 120)))
    wgAlert1DurationEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.wgAlert1Duration, 2, 0, 30)))
    SetButtonGroupValue(settingsWGColorButtons, settings.wgAlert1Color or "YELLOW")
    wgAlert1SoundCheckbox:SetChecked(settings.wgAlert1PlaySound and 1 or nil)
    SetButtonGroupValue(settingsWGAlert1SoundButtons, settings.wgAlert1Sound or "RaidWarning")
    wgAlert2MinutesEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.wgAlert2Minutes, 1, 0, 120)))
    wgAlert2DurationEdit:SetText(tostring(DetaurBar.UI.ClampNumber(settings.wgAlert2Duration, 0, 0, 30)))
    SetButtonGroupValue(settingsWGAlert2ColorButtons, settings.wgAlert2Color or "YELLOW")
    wgSoundCheckbox:SetChecked(settings.wgAlert2PlaySound and 1 or nil)
    SetButtonGroupValue(settingsSoundButtons, settings.wgAlert2Sound or "RaidWarning")

    if randomEnableCheckbox then
        randomEnableCheckbox:SetChecked(settings.randomAlertsEnabled and 1 or nil)
        local a = DetaurBar.Data.GetRandomActiveAlert()
        if a then
            randomIntervalEdit:SetText(tostring(a.intervalMinutes or 5))
            randomDurationEdit:SetText(tostring(a.flashDuration or 3))
            SetButtonGroupValue(settingsRandomColorButtons, a.flashColor or "YELLOW")
            randomSoundCheckbox:SetChecked(a.playSound and 1 or nil)
            SetButtonGroupValue(settingsRandomSoundButtons, a.sound or "RaidWarning")
        end
        DetaurBar.UI.UpdateRandomAlertRows()
    end

    enemyEnableCheckbox:SetChecked(settings.enemyEnabled and 1 or nil)
    enemyFlashCheckbox:SetChecked(settings.enemyFlashEnabled and 1 or nil)
    SetButtonGroupValue(settingsEnemyColorButtons, settings.enemyFlashColor or "YELLOW")
    SetButtonGroupValue(settingsEnemyStyleButtons, settings.enemyFlashStyle or "AGGRESSIVE")
    enemySoundCheckbox:SetChecked(settings.enemyPlaySound and 1 or nil)
    SetButtonGroupValue(settingsEnemySoundButtons, settings.enemySound or "RaidWarning")

    SetSettingsControlsVisible(settingsDungeonControls, DetaurBar.UI.activeSettingsSubTab == "Dungeon")
    SetSettingsControlsVisible(settingsWintergraspControls, DetaurBar.UI.activeSettingsSubTab == "Wintergrasp")
    SetSettingsControlsVisible(settingsRandomControls, DetaurBar.UI.activeSettingsSubTab == "Random")

    if DetaurBar.UI.settingsScrollFrame then DetaurBar.UI.settingsScrollFrame:Show() end
    if DetaurBar.UI.settingsScrollChild then DetaurBar.UI.settingsScrollChild:Show() end

    DetaurBar.UI.UpdateSettingsScroll()
end

-- ============================================
--  UPDATE SETTINGS SCROLL
-- ============================================
function DetaurBar.UI.UpdateSettingsScroll()
    if not DetaurBar.UI.settingsScrollFrame or not DetaurBar.UI.settingsScrollChild then
        return
    end
    DetaurBar.UI.settingsScrollFrame:Show()
    DetaurBar.UI.settingsScrollChild:Show()

    local innerWidth = DetaurBar.UI.settingsScrollFrame:GetWidth() or 0
    if innerWidth <= 0 then
        innerWidth = math.max(1, _G["DetaurBarFrame"]:GetWidth() - 64)
    end
    DetaurBar.UI.settingsScrollChild:SetWidth(innerWidth)

    local contentHeight = 0
    if DetaurBar.UI.activeSettingsSubTab == "Dungeon" then
        contentHeight = 180
    elseif DetaurBar.UI.activeSettingsSubTab == "Wintergrasp" then
        contentHeight = 460
    elseif DetaurBar.UI.activeSettingsSubTab == "Random" then
        contentHeight = 380
    elseif DetaurBar.UI.activeSettingsSubTab == "Enemy" then
        contentHeight = 240
    else
        contentHeight = 120
    end
    DetaurBar.UI.settingsScrollChild:SetHeight(contentHeight)

    local visibleHeight = DetaurBar.UI.settingsScrollFrame:GetHeight() or 0
    if visibleHeight <= 0 then
        visibleHeight = DetaurBar.UI.settingsListBackground and DetaurBar.UI.settingsListBackground:GetHeight() or (_G["DetaurBarFrame"]:GetHeight() - 120)
    end
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
    DetaurBar.UI.settingsScrollFrame:SetVerticalScroll(settingsScrollBar:GetValue())
end

-- ============================================
--  SAVE SETTINGS
-- ============================================
function DetaurBar.UI.SaveSettings()
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.dungeonFlashEnabled = dungeonEnableCheckbox:GetChecked() and true or false
    settings.dungeonFlashDuration = DetaurBar.UI.ClampNumber(dungeonDurationEdit:GetText(), 0, 0, 120)
    settings.ahScanInterval = DetaurBar.UI.ClampNumber(DetaurBar.UI.ahIntervalEdit:GetText(), 10, 1, 120)
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
    settings.enemyFlashEnabled = enemyFlashCheckbox:GetChecked() and true or false
    settings.enemyPlaySound = enemySoundCheckbox:GetChecked() and true or false
    for key, btn in pairs(settingsEnemyColorButtons) do
        if not btn:IsEnabled() then settings.enemyFlashColor = key; break end
    end
    for key, btn in pairs(settingsEnemyStyleButtons) do
        if not btn:IsEnabled() then settings.enemyFlashStyle = key; break end
    end
    for key, btn in pairs(settingsEnemySoundButtons) do
        if not btn:IsEnabled() then settings.enemySound = key; break end
    end

    DetaurBar.UI.UpdateSettingsPanel()
    if DetaurBar.Alerts and DetaurBar.Alerts.ResetAlertState then
        DetaurBar.Alerts.ResetAlertState()
    end
    print("|cffffff00DetaurBar:|r Settings saved.")
end

DetaurBar.UI.settingsPanel:SetScript("OnSizeChanged", function()
    DetaurBar.UI.UpdateSettingsSubTabBar()
end)
