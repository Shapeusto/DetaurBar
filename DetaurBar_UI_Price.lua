-- DetaurBar_UI_Price.lua
-- Price tab: price item sub-tabs, graph panel, sub-tab bar, threshold row, AH interval, price sub-tabs

DetaurBar.UI.priceItemSubTabs = {}
DetaurBar.UI.priceItemSubTabNames = { "News", "Chart", "List", "Bank", "Recipes" }
DetaurBar.UI.activePriceItemSubTab = "News"
DetaurBar.UI.expandedPriceItemId = nil
DetaurBar.UI.selectedPriceItemId = nil
DetaurBar.UI.activePriceListName = "Default"

-- [SUB-TAB STYLE] Price item sub-tab visual
local function SetPriceItemSubTabStyle(subTab)
    if subTab.tabName == DetaurBar.UI.activePriceItemSubTab then
        subTab:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
        subTab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        subTab.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    else
        subTab:SetBackdropColor(0, 0, 0, 0.55)
        subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        subTab.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
    end
end

-- [SUB-TABS/PRICE] Create 3 sub-tabs: News, Chart, Order
for i, name in ipairs(DetaurBar.UI.priceItemSubTabNames) do
    local subTab = CreateFrame("Button", "DetaurBarPriceItemSubTab_" .. name, DetaurBar.UI.frame)
    subTab:SetHeight(24)
    subTab:SetFrameLevel(DetaurBar.UI.frame:GetFrameLevel() + 6)
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

    DetaurBar.UI.priceItemSubTabs[i] = subTab
end

-- [SUB-TAB VISUALS] UpdatePriceItemSubTabVisuals
function DetaurBar.UI.UpdatePriceItemSubTabVisuals()
    for _, subTab in ipairs(DetaurBar.UI.priceItemSubTabs) do
        SetPriceItemSubTabStyle(subTab)
        if subTab.tabName == DetaurBar.UI.activePriceItemSubTab then
            subTab:Disable()
        else
            subTab:Enable()
        end
    end
end

-- [PRICE/CHART TOOLBAR] Icon row below price item sub-tabs (Chart only)
DetaurBar.UI.priceChartToolbar = CreateFrame("Frame", "DetaurBarPriceChartToolbar", DetaurBar.UI.frame)
DetaurBar.UI.priceChartToolbar:SetHeight(28)
DetaurBar.UI.priceChartToolbar:SetPoint("TOPLEFT", DetaurBar.UI.frame, "TOPLEFT", 14, -86)
DetaurBar.UI.priceChartToolbar:SetPoint("TOPRIGHT", DetaurBar.UI.frame, "TOPRIGHT", -14, -86)
DetaurBar.UI.priceChartToolbar:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left=3, right=3, top=3, bottom=3 }
})
DetaurBar.UI.priceChartToolbar:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
DetaurBar.UI.priceChartToolbar:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
DetaurBar.UI.priceChartToolbar:Hide()

local lastChartToggleBtn
local function CreateChartToolbarToggle(texture, tooltipTitle, tooltipText, settingKey)
    local btn = CreateFrame("Button", nil, DetaurBar.UI.priceChartToolbar)
    btn:SetSize(22, 22)
    if lastChartToggleBtn then
        btn:SetPoint("LEFT", lastChartToggleBtn, "RIGHT", 4, 0)
    else
        btn:SetPoint("LEFT", DetaurBar.UI.priceChartToolbar, "LEFT", 6, 0)
    end
    lastChartToggleBtn = btn

    btn:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left=3, right=3, top=3, bottom=3 }
    })

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    icon:SetTexture(texture)
    btn.icon = icon

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(btn)
    highlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    highlight:SetBlendMode("ADD")

    DetaurBar.UI.SetSimpleTooltip(btn, tooltipTitle, tooltipText)

    function btn:UpdateVisualState()
        DetaurBar.Data.InitializeDB()
        local on = DetaurBarDB.settings[settingKey]
        btn.icon:SetDesaturated(not on)
        if on then
            btn:SetBackdropColor(0.18, 0.12, 0.06, 0.95)
            btn:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        else
            btn:SetBackdropColor(0, 0, 0, 0.55)
            btn:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        end
    end

    btn:SetScript("OnClick", function()
        DetaurBar.Data.InitializeDB()
        DetaurBarDB.settings[settingKey] = not DetaurBarDB.settings[settingKey]
        btn:UpdateVisualState()
        DetaurBar.UI.SelectPriceItemSubTab(DetaurBar.UI.activePriceItemSubTab)
    end)

    btn:UpdateVisualState()
    return btn
end

DetaurBar.UI.chartGraphToggle = CreateChartToolbarToggle(
    "Interface\\Icons\\INV_Misc_Book_01",
    "Toggle Graph",
    "Show or hide the price history graph section.",
    "chartGraphVisible"
)
DetaurBar.UI.chartThresholdToggle = CreateChartToolbarToggle(
    "Interface\\Icons\\INV_Misc_Coin_01",
    "Toggle Threshold",
    "Show or hide the price threshold row.",
    "chartThresholdVisible"
)
DetaurBar.UI.chartOrderToggle = CreateChartToolbarToggle(
    "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up",
    "Toggle Order Mode",
    "Switch between threshold mode and reorder mode (up/down arrows).",
    "chartOrderMode"
)

-- [PRICE/LIST SCAN FILTER TOGGLE] 4th icon — shows checkboxes for which lists to AH-scan
DetaurBar.UI.chartScanFilterToggle = CreateFrame("Button", nil, DetaurBar.UI.priceChartToolbar)
DetaurBar.UI.chartScanFilterToggle:SetSize(22, 22)
DetaurBar.UI.chartScanFilterToggle:SetPoint("LEFT", lastChartToggleBtn, "RIGHT", 4, 0)
lastChartToggleBtn = DetaurBar.UI.chartScanFilterToggle

DetaurBar.UI.chartScanFilterToggle:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left=3, right=3, top=3, bottom=3 }
})

local scanFilterIcon = DetaurBar.UI.chartScanFilterToggle:CreateTexture(nil, "ARTWORK")
scanFilterIcon:SetSize(16, 16)
scanFilterIcon:SetPoint("CENTER", DetaurBar.UI.chartScanFilterToggle, "CENTER", 0, 0)
scanFilterIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_02")
DetaurBar.UI.chartScanFilterToggle.icon = scanFilterIcon
DetaurBar.UI.chartScanFilterToggle.icon:SetDesaturated(true)

local scanFilterHighlight = DetaurBar.UI.chartScanFilterToggle:CreateTexture(nil, "HIGHLIGHT")
scanFilterHighlight:SetAllPoints(DetaurBar.UI.chartScanFilterToggle)
scanFilterHighlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
scanFilterHighlight:SetBlendMode("ADD")

DetaurBar.UI.SetSimpleTooltip(DetaurBar.UI.chartScanFilterToggle, "Scan Filter", "Toggle which price lists are included in AH scanning.")

-- Checkbox panel anchored below the toolbar
DetaurBar.UI.scanFilterPanel = CreateFrame("Frame", "DetaurBarScanFilterPanel", DetaurBar.UI.priceChartToolbar)
DetaurBar.UI.scanFilterPanel:SetWidth(140)
DetaurBar.UI.scanFilterPanel:SetHeight(10)
DetaurBar.UI.scanFilterPanel:SetPoint("TOPLEFT", DetaurBar.UI.priceChartToolbar, "BOTTOMLEFT", 6, 0)
DetaurBar.UI.scanFilterPanel:Hide()
DetaurBar.UI.scanFilterPanel:SetFrameLevel(DetaurBar.UI.priceChartToolbar:GetFrameLevel() + 5)

local function RebuildScanFilterCheckboxes()
    for _, child in ipairs(DetaurBar.UI.scanFilterPanel.children or {}) do
        child:Hide()
    end
    DetaurBar.UI.scanFilterPanel.children = {}

    DetaurBar.Data.InitializeDB()
    local settings = DetaurBar.Data.GetSettings()
    local enabledLists = settings.scanEnabledLists or {}
    local listNames = {}
    for name in pairs(DetaurBarDB.priceLists) do
        if name ~= "All" then table.insert(listNames, name) end
    end
    table.sort(listNames)

    local y = -11
    for _, name in ipairs(listNames) do
        local captured = name
        local cb = CreateFrame("CheckButton", nil, DetaurBar.UI.scanFilterPanel, "UICheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint("TOPLEFT", DetaurBar.UI.scanFilterPanel, "TOPLEFT", 6, y)
        cb:SetChecked(enabledLists[captured])

        local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        label:SetText(captured)
        label:SetTextColor(1, 1, 1, 1)

        cb:SetScript("OnClick", function(self2)
            DetaurBar.Data.InitializeDB()
            DetaurBar.Data.GetSettings().scanEnabledLists[captured] = self2:GetChecked()
        end)

        table.insert(DetaurBar.UI.scanFilterPanel.children, cb)
        table.insert(DetaurBar.UI.scanFilterPanel.children, label)
        y = y - 22
    end

    local totalH = math.abs(y - 4) + 4
    if totalH < 10 then totalH = 10 end
    DetaurBar.UI.scanFilterPanel:SetHeight(totalH)
end

DetaurBar.UI.chartScanFilterToggle:SetScript("OnClick", function()
    if DetaurBar.UI.scanFilterPanel:IsShown() then
        DetaurBar.UI.scanFilterPanel:Hide()
        if DetaurBar.UI.scrollFrame then DetaurBar.UI.scrollFrame:Show() end
        DetaurBar.UI.chartScanFilterToggle:SetBackdropColor(0, 0, 0, 0.55)
        DetaurBar.UI.chartScanFilterToggle:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        DetaurBar.UI.chartScanFilterToggle.icon:SetDesaturated(true)
    else
        RebuildScanFilterCheckboxes()
        if DetaurBar.UI.scrollFrame then DetaurBar.UI.scrollFrame:Hide() end
        DetaurBar.UI.scanFilterPanel:Show()
        DetaurBar.UI.chartScanFilterToggle:SetBackdropColor(0.18, 0.12, 0.06, 0.95)
        DetaurBar.UI.chartScanFilterToggle:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        DetaurBar.UI.chartScanFilterToggle.icon:SetDesaturated(false)
    end
end)

-- [PRICE/CHART BUY/SELL TOGGLE] 5th icon — show/hide buy/sell markers on graph
DetaurBar.UI.chartBuySellToggle = CreateChartToolbarToggle(
    "Interface\\Icons\\INV_Misc_Bag_01",
    "Toggle Buy/Sell Markers",
    "Show or hide buy/sell history markers on the price graph.",
    "chartBuySellVisible"
)

-- [PRICE/CHART LIST DROPDOWN] right side of toolbar
local function InitChartListDropdown()
    local function AddStaticListEntry(text, value)
        local info = UIDropDownMenu_CreateInfo()
        info.text = text
        info.value = value
        info.func = function()
            DetaurBar.UI.activePriceListName = value
            UIDropDownMenu_SetText(DetaurBar.UI.chartListDropdown, text)
            DetaurBar.UI.RefreshTasks()
        end
        UIDropDownMenu_AddButton(info)
    end
    AddStaticListEntry("Default", "Default")
    AddStaticListEntry("All", "All")
    DetaurBar.Data.InitializeDB()
    local listNames = {}
    for name in pairs(DetaurBarDB.priceLists) do
        if name ~= "Default" and name ~= "All" then table.insert(listNames, name) end
    end
    table.sort(listNames)
    for _, name in ipairs(listNames) do
        local captured = name
        local info2 = UIDropDownMenu_CreateInfo()
        info2.text = captured
        info2.value = captured
        info2.func = function()
            DetaurBar.UI.activePriceListName = captured
            UIDropDownMenu_SetText(DetaurBar.UI.chartListDropdown, captured)
            DetaurBar.UI.RefreshTasks()
        end
        UIDropDownMenu_AddButton(info2)
    end
end

DetaurBar.UI.chartListDropdown = CreateFrame("Frame", "DetaurBarChartListDropdown", DetaurBar.UI.priceChartToolbar, "UIDropDownMenuTemplate")
DetaurBar.UI.chartListDropdown:SetPoint("RIGHT", DetaurBar.UI.priceChartToolbar, "RIGHT", -54, -2)
DetaurBar.UI.chartListDropdown:SetWidth(96)
UIDropDownMenu_SetAnchor(DetaurBar.UI.chartListDropdown, 0, 0, "TOPLEFT", DetaurBar.UI.chartListDropdown, "BOTTOMLEFT")
UIDropDownMenu_Initialize(DetaurBar.UI.chartListDropdown, InitChartListDropdown)
UIDropDownMenu_SetText(DetaurBar.UI.chartListDropdown, "Default")

-- [PRICE/GRAPH PANEL] fixed bottom section, shown only on Price tab
DetaurBar.UI.priceGraphPanel = CreateFrame("Frame", "DetaurBarPriceGraphPanel", DetaurBar.UI.frame)
DetaurBar.UI.priceGraphPanel:SetHeight(120)
DetaurBar.UI.priceGraphPanel:SetPoint("BOTTOMLEFT", DetaurBar.UI.frame, "BOTTOMLEFT", 16, 46)
DetaurBar.UI.priceGraphPanel:SetPoint("BOTTOMRIGHT", DetaurBar.UI.frame, "BOTTOMRIGHT", -20, 46)
DetaurBar.UI.priceGraphPanel:Hide()

local priceGraphHint = DetaurBar.UI.priceGraphPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
priceGraphHint:SetPoint("CENTER", DetaurBar.UI.priceGraphPanel, "CENTER", 0, 0)
priceGraphHint:SetText("Click an item above to view price history")
DetaurBar.UI.priceGraphPanel.hint = priceGraphHint

-- [PRICE/SUB-TAB BAR] sits between list and graph
DetaurBar.UI.priceSubTabBar = CreateFrame("Frame", "DetaurBarPriceSubTabBar", DetaurBar.UI.frame)
DetaurBar.UI.priceSubTabBar:SetHeight(24)
DetaurBar.UI.priceSubTabBar:SetPoint("BOTTOMLEFT", DetaurBar.UI.priceGraphPanel, "TOPLEFT", 0, 4)
DetaurBar.UI.priceSubTabBar:SetPoint("BOTTOMRIGHT", DetaurBar.UI.priceGraphPanel, "TOPRIGHT", 0, 4)
DetaurBar.UI.priceSubTabBar:Hide()

-- [PRICE/GRAPH] Divider line above graph
local priceGraphDivider = DetaurBar.UI.priceGraphPanel:CreateTexture(nil, "ARTWORK")
priceGraphDivider:SetHeight(1)
priceGraphDivider:SetPoint("TOPLEFT", DetaurBar.UI.priceGraphPanel, "TOPLEFT", 0, 0)
priceGraphDivider:SetPoint("TOPRIGHT", DetaurBar.UI.priceGraphPanel, "TOPRIGHT", 0, 0)
priceGraphDivider:SetTexture(0.4, 0.4, 0.4, 0.6)

-- [PRICE/THRESHOLD ROW] shown only in Chart subtab
local PRICE_THRESHOLD_ROW_HEIGHT = 40
DetaurBar.UI.priceThresholdRow = CreateFrame("Frame", "DetaurBarPriceThresholdRow", DetaurBar.UI.frame)
DetaurBar.UI.priceThresholdRow:SetHeight(PRICE_THRESHOLD_ROW_HEIGHT)
DetaurBar.UI.priceThresholdRow:SetPoint("BOTTOMLEFT", DetaurBar.UI.priceSubTabBar, "TOPLEFT", 0, 4)
DetaurBar.UI.priceThresholdRow:SetPoint("BOTTOMRIGHT", DetaurBar.UI.priceSubTabBar, "TOPRIGHT", 0, 4)
DetaurBar.UI.priceThresholdRow:Hide()
DetaurBar.UI.priceThresholdRow:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left=3, right=3, top=3, bottom=3 }
})
DetaurBar.UI.priceThresholdRow:SetBackdropColor(0.1, 0.1, 0.05, 0.95)
DetaurBar.UI.priceThresholdRow:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.8)

local thresholdIcon = DetaurBar.UI.priceThresholdRow:CreateTexture(nil, "ARTWORK")
thresholdIcon:SetSize(18, 18)
thresholdIcon:SetPoint("LEFT", DetaurBar.UI.priceThresholdRow, "LEFT", 8, 0)
DetaurBar.UI.priceThresholdRow.icon = thresholdIcon

local thresholdName = DetaurBar.UI.priceThresholdRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
thresholdName:SetPoint("LEFT", thresholdIcon, "RIGHT", 6, 0)
thresholdName:SetTextColor(1.0, 0.82, 0.0, 1.0)
DetaurBar.UI.priceThresholdRow.name = thresholdName

local thresholdInput = CreateFrame("EditBox", "DetaurBarPriceThresholdInput", DetaurBar.UI.priceThresholdRow)
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
DetaurBar.UI.priceThresholdRow.input = thresholdInput

local thresholdGoldIcon = thresholdInput:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
thresholdGoldIcon:SetPoint("LEFT", thresholdInput, "RIGHT", 4, 0)
thresholdGoldIcon:SetTextColor(1.0, 0.82, 0.0, 1.0)
thresholdGoldIcon:SetText("|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t")
DetaurBar.UI.priceThresholdRow.goldIcon = thresholdGoldIcon

local thresholdInputHigh = CreateFrame("EditBox", "DetaurBarPriceThresholdInputHigh", DetaurBar.UI.priceThresholdRow)
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
DetaurBar.UI.priceThresholdRow.inputHigh = thresholdInputHigh

local thresholdSilverIcon = thresholdInputHigh:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
thresholdSilverIcon:SetPoint("LEFT", thresholdInputHigh, "RIGHT", 4, 0)
thresholdSilverIcon:SetTextColor(0.8, 0.8, 0.9, 1.0)
thresholdSilverIcon:SetText("|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t")
DetaurBar.UI.priceThresholdRow.silverIcon = thresholdSilverIcon

local thresholdOkBtn = CreateFrame("Button", nil, DetaurBar.UI.priceThresholdRow)
thresholdOkBtn:SetSize(16, 16)
thresholdOkBtn:SetPoint("RIGHT", DetaurBar.UI.priceThresholdRow, "RIGHT", -6, 0)
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
thresholdOkBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
DetaurBar.UI.priceThresholdRow.okBtn = thresholdOkBtn

local thresholdClearBtn = CreateFrame("Button", nil, DetaurBar.UI.priceThresholdRow)
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
thresholdClearBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
DetaurBar.UI.priceThresholdRow.clearBtn = thresholdClearBtn

-- [PRICE/AH SCAN INTERVAL] AH scan interval edit in price > News row
DetaurBar.UI.priceAhIntervalRow = CreateFrame("Frame", nil, DetaurBar.UI.frame)
DetaurBar.UI.priceAhIntervalRow:SetPoint("BOTTOMLEFT", DetaurBar.UI.frame, "BOTTOMLEFT", 24, 12)
DetaurBar.UI.priceAhIntervalRow:SetPoint("BOTTOMRIGHT", DetaurBar.UI.frame, "BOTTOMRIGHT", -16, 12)
DetaurBar.UI.priceAhIntervalRow:SetHeight(22)
DetaurBar.UI.priceAhIntervalRow:Hide()

DetaurBar.UI.ahLabel, DetaurBar.UI.ahIntervalEdit = DetaurBar.UI.CreateSettingsEditRow(DetaurBar.UI.priceAhIntervalRow, "AH Scan Interval", 0, 2, 36, 3, function(self)
    local settings = DetaurBar.UI.GetSettingsDB()
    settings.ahScanInterval = DetaurBar.UI.ClampNumber(self:GetText(), 10, 1, 120)
    self:SetText(tostring(settings.ahScanInterval))
    print("|cffffff00DetaurBar:|r AH Scan Interval set to " .. settings.ahScanInterval .. " min.")
end)
DetaurBar.UI.SetSimpleTooltip(DetaurBar.UI.ahIntervalEdit, "AH Scan Interval", {
    "Press Enter to save.",
    "How often the addon can auto-scan",
    "the Auction House while the AH is open.",
})

DetaurBar.UI.ahScanButton = CreateFrame("Button", nil, DetaurBar.UI.priceAhIntervalRow, "UIPanelButtonTemplate")
DetaurBar.UI.ahScanButton:SetSize(70, 20)
DetaurBar.UI.ahScanButton:SetPoint("TOP", DetaurBar.UI.ahIntervalEdit, "TOP", 0, 0)
DetaurBar.UI.ahScanButton:SetPoint("RIGHT", DetaurBar.UI.priceAhIntervalRow, "RIGHT", -4, 0)
DetaurBar.UI.ahScanButton:SetText("Scan AH")
DetaurBar.UI.SetSimpleTooltip(DetaurBar.UI.ahScanButton, "Scan AH", "Manually trigger an immediate Auction House scan.")
DetaurBar.UI.ahScanButton:SetScript("OnClick", function()
    if DetaurBar.AHScan and DetaurBar.AHScan.StartScan then
        DetaurBar.AHScan.StartScan(true)
    end
end)

-- [PRICE/SUB-TABS] 4 price sub-tab names + visual update
DetaurBar.UI.priceSubTabNames = { "Daily", "Weekly", "Monthly", "Yearly" }
DetaurBar.UI.activePriceSubTab = "Daily"
DetaurBar.UI.priceSubTabObjects = {}
local subTabGap = 1

function DetaurBar.UI.UpdatePriceSubTabVisuals()
    for _, st in ipairs(DetaurBar.UI.priceSubTabObjects) do
        if st.tabName == DetaurBar.UI.activePriceSubTab then
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

for i, name in ipairs(DetaurBar.UI.priceSubTabNames) do
    local st = CreateFrame("Button", "DetaurBarPriceSubTab_" .. name, DetaurBar.UI.priceSubTabBar)
    st:SetHeight(24)
    st:SetFrameLevel(DetaurBar.UI.frame:GetFrameLevel() + 6)
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
        DetaurBar.UI.activePriceSubTab = name
        DetaurBar.UI.UpdatePriceSubTabVisuals()
        DetaurBar.UI.RefreshTasks()
    end)

    DetaurBar.UI.priceSubTabObjects[i] = st
end

function DetaurBar.UI.LayoutPriceSubTabs()
    local totalW = DetaurBar.UI.priceSubTabBar:GetWidth()
    if totalW <= 0 then return end
    local n = #DetaurBar.UI.priceSubTabObjects
    local w = (totalW - subTabGap * (n - 1)) / n
    for i, st in ipairs(DetaurBar.UI.priceSubTabObjects) do
        st:SetWidth(w)
        st:ClearAllPoints()
        if i == 1 then
            st:SetPoint("TOPLEFT", DetaurBar.UI.priceSubTabBar, "TOPLEFT", 0, 0)
        else
            st:SetPoint("LEFT", DetaurBar.UI.priceSubTabObjects[i-1], "RIGHT", subTabGap, 0)
        end
    end
end

DetaurBar.UI.priceSubTabBar:SetScript("OnSizeChanged", DetaurBar.UI.LayoutPriceSubTabs)

-- [PRICE] DetaurBar.UI.SelectPriceItemSubTab
function DetaurBar.UI.SelectPriceItemSubTab(subTabName)
    DetaurBar.UI.activePriceItemSubTab = subTabName
    DetaurBar.UI.UpdatePriceItemSubTabVisuals()
    DetaurBar.UI.UpdateInputPlaceholder()

    -- Hide all sub-tab-specific elements first
    if DetaurBar.UI.priceGraphPanel then DetaurBar.UI.priceGraphPanel:Hide() end
    if DetaurBar.UI.priceSubTabBar then DetaurBar.UI.priceSubTabBar:Hide() end
    if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
    if DetaurBar.UI.priceChartToolbar then DetaurBar.UI.priceChartToolbar:Hide() end
    if DetaurBar.UI.priceListPanel then DetaurBar.UI.priceListPanel:Hide() end
    if DetaurBar.UI.priceListControls then DetaurBar.UI.priceListControls:Hide() end
    if DetaurBar.UI.priceAhIntervalRow then DetaurBar.UI.priceAhIntervalRow:Hide() end
    if DetaurBar.UI.bankPanel then DetaurBar.UI.bankPanel:Hide() end
    if DetaurBar.UI.recipesPanel then DetaurBar.UI.recipesPanel:Hide() end
    if DetaurBar.UI.scanFilterPanel then
        DetaurBar.UI.scanFilterPanel:Hide()
        if DetaurBar.UI.scrollFrame then DetaurBar.UI.scrollFrame:Show() end
    end

    if subTabName == "Recipes" then
        DetaurBar.UI.editBox:Hide()
        DetaurBar.UI.addButton:Hide()
        if DetaurBar.UI.ShowRecipesPanel then DetaurBar.UI.ShowRecipesPanel() end
    elseif subTabName == "News" then
        DetaurBar.UI.editBox:Hide()
        DetaurBar.UI.addButton:Hide()
    elseif subTabName == "Bank" then
        DetaurBar.UI.editBox:Hide()
        DetaurBar.UI.addButton:Hide()
        if DetaurBar.UI.bankPanel then DetaurBar.UI.bankPanel:Show() end
        if not DetaurBar.UI.bankCachedItems then
            DetaurBar.UI.LoadBankCache()
        end
        DetaurBar.UI.UpdateBankGrid()
    elseif subTabName == "List" then
        DetaurBar.UI.editBox:Show()
        DetaurBar.UI.addButton:Show()
        DetaurBar.UI.ShowPriceListPanel()
    else
        -- Chart sub-tab
        local settings = DetaurBar.UI.GetSettingsDB()
        if DetaurBar.UI.priceChartToolbar then
            DetaurBar.UI.priceChartToolbar:Show()
            UIDropDownMenu_SetText(DetaurBar.UI.chartListDropdown, DetaurBar.UI.activePriceListName or "Default")
        end
        if settings.chartGraphVisible then
            DetaurBar.UI.priceGraphPanel:Show()
            DetaurBar.UI.priceSubTabBar:Show()
            DetaurBar.UI.priceThresholdRow:ClearAllPoints()
            DetaurBar.UI.priceThresholdRow:SetPoint("BOTTOMLEFT", DetaurBar.UI.priceSubTabBar, "TOPLEFT", 0, 4)
            DetaurBar.UI.priceThresholdRow:SetPoint("BOTTOMRIGHT", DetaurBar.UI.priceSubTabBar, "TOPRIGHT", 0, 4)
        else
            DetaurBar.UI.priceGraphPanel:Hide()
            DetaurBar.UI.priceSubTabBar:Hide()
            DetaurBar.UI.priceThresholdRow:ClearAllPoints()
            DetaurBar.UI.priceThresholdRow:SetPoint("BOTTOMLEFT", DetaurBar.UI.frame, "BOTTOMLEFT", 16, 46)
            DetaurBar.UI.priceThresholdRow:SetPoint("BOTTOMRIGHT", DetaurBar.UI.frame, "BOTTOMRIGHT", -20, 46)
        end
        DetaurBar.UI.editBox:Show()
        DetaurBar.UI.addButton:Show()
        if settings.chartThresholdVisible then
            DetaurBar.UI.UpdateThresholdRow()
        else
            if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        end
    end

    DetaurBar.UI.UpdateContentAnchors()
    DetaurBar.UI.RefreshTasks()
end

-- [PRICE] DetaurBar.UI.SetSelectedPriceItem
function DetaurBar.UI.SetSelectedPriceItem(itemId)
    DetaurBar.UI.selectedPriceItemId = itemId
    DetaurBar.UI.UpdateThresholdRow()
    DetaurBar.UI.RefreshTasks()
end

-- [PRICE] DetaurBar.UI.UpdateThresholdRow
function DetaurBar.UI.UpdateThresholdRow()
    if DetaurBar.UI.activePriceItemSubTab ~= "Chart" then
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        return
    end

    if not DetaurBar.UI.selectedPriceItemId then
        DetaurBar.UI.priceThresholdRow.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        DetaurBar.UI.priceThresholdRow.icon:Show()
        DetaurBar.UI.priceThresholdRow.name:SetText("NAME")
        DetaurBar.UI.priceThresholdRow.name:SetTextColor(0.5, 0.5, 0.5, 1.0)
        DetaurBar.UI.priceThresholdRow.input:SetText("")
        DetaurBar.UI.priceThresholdRow.inputHigh:SetText("")
        DetaurBar.UI.priceThresholdRow.okBtn:Hide()
        DetaurBar.UI.priceThresholdRow.clearBtn:Hide()
        DetaurBar.UI.priceThresholdRow:Show()
        return
    end

    local item = DetaurBar.Data.GetItemById("price", DetaurBar.UI.selectedPriceItemId)
    if not item then
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        return
    end

    local itemTexture, itemName
    local itemRarity = 1
    local itemId = DetaurBar.UI.GetItemIdFromText(item.title)
    if itemId then
        itemName = DetaurBar.UI.GetOfflineItemNameById(itemId)
        if itemName then
            itemRarity = 1
            itemTexture = DetaurBar.Data.GetItemTexture(itemId)
            if not itemTexture then
                local _, _, sr, _, _, _, _, _, _, st = GetItemInfo(itemId)
                itemTexture = st
                if sr then itemRarity = sr end
            end
        else
            itemName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
        end
        if not itemTexture then
            itemTexture = DetaurBar.Data.GetItemTexture(itemId)
        end
    end

    if itemTexture then
        DetaurBar.UI.priceThresholdRow.icon:SetTexture(itemTexture)
        DetaurBar.UI.priceThresholdRow.icon:Show()
    else
        DetaurBar.UI.priceThresholdRow.icon:Hide()
    end

    if not itemName then
        itemName = item.title
    end
    if #itemName > 11 then
        itemName = itemName:sub(1, 11)
    end
    DetaurBar.UI.priceThresholdRow.name:SetText(itemName)
    DetaurBar.UI.priceThresholdRow.name:SetTextColor(1.0, 0.82, 0.0, 1.0)

    local threshold = item.threshold or 0
    DetaurBar.UI.priceThresholdRow.input:SetText(threshold > 0 and tostring(threshold) or "")
    local thresholdHigh = item.thresholdHigh or 0
    DetaurBar.UI.priceThresholdRow.inputHigh:SetText(thresholdHigh > 0 and tostring(thresholdHigh) or "")
    DetaurBar.UI.priceThresholdRow.okBtn:Show()
    DetaurBar.UI.priceThresholdRow.clearBtn:Show()

    DetaurBar.UI.priceThresholdRow:Show()
end

-- [PRICE] DetaurBar.UI.SavePriceThreshold
function DetaurBar.UI.SavePriceThreshold()
    if not DetaurBar.UI.selectedPriceItemId then return end

    local lowText = DetaurBar.UI.priceThresholdRow.input:GetText()
    local lowGold = tonumber(lowText) or 0
    local highText = DetaurBar.UI.priceThresholdRow.inputHigh:GetText()
    local highGold = tonumber(highText) or 0

    local item = DetaurBar.Data.GetItemById("price", DetaurBar.UI.selectedPriceItemId)
    if item then
        item.threshold = lowGold
        item.thresholdHigh = highGold
        DetaurBar.UI.UpdateThresholdRow()
        DetaurBar.UI.RefreshTasks()
    end
end

-- [PRICE] DetaurBar.UI.ClearPriceThreshold
function DetaurBar.UI.ClearPriceThreshold()
    if not DetaurBar.UI.selectedPriceItemId then return end

    local item = DetaurBar.Data.GetItemById("price", DetaurBar.UI.selectedPriceItemId)
    if item then
        item.threshold = nil
        item.thresholdHigh = nil
        item.frequent = nil
        item.frequentHigh = nil
        DetaurBar.UI.UpdateThresholdRow()
        DetaurBar.UI.RefreshTasks()
    end
end

-- ============================================
--  LIST SUB-TAB: panel, dropdown, add-list
-- ============================================
local function InitListSubTabDropdown()
    local function AddStaticListEntry(text, value)
        local info = UIDropDownMenu_CreateInfo()
        info.text = text
        info.value = value
        info.func = function()
            DetaurBar.UI.activePriceListName = value
            UIDropDownMenu_SetText(DetaurBar.UI.priceListDropdown, text == "Default" and "Select list..." or text)
            DetaurBar.UI.RefreshTasks()
        end
        UIDropDownMenu_AddButton(info)
    end
    AddStaticListEntry("Default", "Default")
    AddStaticListEntry("All", "All")
    DetaurBar.Data.InitializeDB()
    local listNames = {}
    for name in pairs(DetaurBarDB.priceLists) do
        if name ~= "Default" and name ~= "All" then table.insert(listNames, name) end
    end
    table.sort(listNames)
    for _, name in ipairs(listNames) do
        local captured = name
        local info2 = UIDropDownMenu_CreateInfo()
        info2.text = captured
        info2.value = captured
        info2.func = function()
            DetaurBar.UI.activePriceListName = captured
            UIDropDownMenu_SetText(DetaurBar.UI.priceListDropdown, captured)
            DetaurBar.UI.RefreshTasks()
        end
        UIDropDownMenu_AddButton(info2)
    end
end

DetaurBar.UI.priceListPanel = CreateFrame("Frame", nil, DetaurBar.UI.frame)
DetaurBar.UI.priceListPanel:SetPoint("TOPLEFT", DetaurBar.UI.frame, "TOPLEFT", 14, -86)
DetaurBar.UI.priceListPanel:SetPoint("TOPRIGHT", DetaurBar.UI.frame, "TOPRIGHT", -14, -86)
DetaurBar.UI.priceListPanel:SetHeight(28)
DetaurBar.UI.priceListPanel:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left=3, right=3, top=3, bottom=3 }
})
DetaurBar.UI.priceListPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
DetaurBar.UI.priceListPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
DetaurBar.UI.priceListPanel:Hide()

-- List selector dropdown
DetaurBar.UI.priceListDropdown = CreateFrame("Frame", "DetaurBarPriceListDropdown", DetaurBar.UI.priceListPanel, "UIDropDownMenuTemplate")
DetaurBar.UI.priceListDropdown:SetPoint("LEFT", DetaurBar.UI.priceListPanel, "LEFT", -16, -2)
DetaurBar.UI.priceListDropdown:SetWidth(130)
UIDropDownMenu_SetAnchor(DetaurBar.UI.priceListDropdown, 0, 0, "TOPLEFT", DetaurBar.UI.priceListDropdown, "BOTTOMLEFT")
UIDropDownMenu_Initialize(DetaurBar.UI.priceListDropdown, InitListSubTabDropdown)
UIDropDownMenu_SetText(DetaurBar.UI.priceListDropdown, "Select list...")

-- [PRICE/LIST CONTROLS] Delete btn + add-list input + add btn (row below priceListPanel)
DetaurBar.UI.priceListControls = CreateFrame("Frame", nil, DetaurBar.UI.frame)
DetaurBar.UI.priceListControls:SetPoint("TOPLEFT", DetaurBar.UI.priceListPanel, "BOTTOMLEFT", 0, -2)
DetaurBar.UI.priceListControls:SetPoint("TOPRIGHT", DetaurBar.UI.priceListPanel, "BOTTOMRIGHT", 0, -2)
DetaurBar.UI.priceListControls:SetHeight(26)
DetaurBar.UI.priceListControls:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left=3, right=3, top=3, bottom=3 }
})
DetaurBar.UI.priceListControls:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
DetaurBar.UI.priceListControls:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
DetaurBar.UI.priceListControls:Hide()

DetaurBar.UI.priceListDeleteBtn = CreateFrame("Button", nil, DetaurBar.UI.priceListControls, "UIPanelButtonTemplate")
DetaurBar.UI.priceListDeleteBtn:SetSize(60, 20)
DetaurBar.UI.priceListDeleteBtn:SetPoint("LEFT", DetaurBar.UI.priceListControls, "LEFT", 6, 0)
DetaurBar.UI.priceListDeleteBtn:SetText("Delete")
StaticPopupDialogs["DETAURBAR_DELETELIST"] = {
    text = "Delete list '%s'?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        DetaurBar.Data.InitializeDB()
        DetaurBarDB.priceLists[data] = nil
        DetaurBar.UI.activePriceListName = "Default"
        local faction = UnitFactionGroup("player") or "Horde"
        if DetaurBarDB.price[faction] then
            for _, item in ipairs(DetaurBarDB.price[faction]) do
                if item.list == data then item.list = nil end
            end
        end
        UIDropDownMenu_SetText(DetaurBar.UI.priceListDropdown, "Select list...")
        DetaurBar.UI.RefreshTasks()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

DetaurBar.UI.priceListDeleteBtn:SetScript("OnClick", function()
    local name = DetaurBar.UI.activePriceListName
    if name and name ~= "Default" and name ~= "All" then
        StaticPopup_Show("DETAURBAR_DELETELIST", name, nil, name)
    end
end)

DetaurBar.UI.priceListAddBox = CreateFrame("EditBox", nil, DetaurBar.UI.priceListControls, "InputBoxTemplate")
DetaurBar.UI.priceListAddBox:SetSize(140, 20)
DetaurBar.UI.priceListAddBox:SetPoint("LEFT", DetaurBar.UI.priceListDeleteBtn, "RIGHT", 6, 0)
DetaurBar.UI.priceListAddBox:SetTextInsets(4, 4, 0, 0)
DetaurBar.UI.priceListAddBox:SetAutoFocus(false)
DetaurBar.UI.priceListAddBox:SetScript("OnEscapePressed", function()
    DetaurBar.UI.priceListAddBox:SetText("")
    DetaurBar.UI.priceListAddBox:ClearFocus()
end)
DetaurBar.UI.priceListAddBox:SetScript("OnEnterPressed", function()
    local name = DetaurBar.UI.priceListAddBox:GetText():match("^%s*(.-)%s*$")
    if name and name ~= "" and name ~= "Default" and name ~= "All" then
        DetaurBar.Data.InitializeDB()
        DetaurBarDB.priceLists[name] = true
        DetaurBar.UI.priceListAddBox:SetText("")
        DetaurBar.UI.priceListAddBox:ClearFocus()
        DetaurBar.UI.RefreshTasks()
    end
end)

DetaurBar.UI.priceListAddBoxPlaceholder = DetaurBar.UI.priceListAddBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
DetaurBar.UI.priceListAddBoxPlaceholder:SetPoint("LEFT", DetaurBar.UI.priceListAddBox, "LEFT", 6, 0)
DetaurBar.UI.priceListAddBoxPlaceholder:SetText("List name...")
DetaurBar.UI.priceListAddBox:SetScript("OnTextChanged", function(self)
    if self:GetText() == "" then
        DetaurBar.UI.priceListAddBoxPlaceholder:Show()
    else
        DetaurBar.UI.priceListAddBoxPlaceholder:Hide()
    end
end)

DetaurBar.UI.priceListAddButton = CreateFrame("Button", nil, DetaurBar.UI.priceListControls, "UIPanelButtonTemplate")
DetaurBar.UI.priceListAddButton:SetSize(50, 20)
DetaurBar.UI.priceListAddButton:SetPoint("LEFT", DetaurBar.UI.priceListAddBox, "RIGHT", 4, 0)
DetaurBar.UI.priceListAddButton:SetText("Add")
DetaurBar.UI.priceListAddButton:SetScript("OnClick", function()
    local name = DetaurBar.UI.priceListAddBox:GetText():match("^%s*(.-)%s*$")
    if name and name ~= "" and name ~= "Default" and name ~= "All" then
        DetaurBar.Data.InitializeDB()
        DetaurBarDB.priceLists[name] = true
        DetaurBar.UI.priceListAddBox:SetText("")
        DetaurBar.UI.priceListAddBox:ClearFocus()
        DetaurBar.UI.RefreshTasks()
    end
end)

DetaurBar.UI.ShowPriceListPanel = function()
    DetaurBar.UI.priceListPanel:Show()
    DetaurBar.UI.priceListControls:Show()
    UIDropDownMenu_SetText(DetaurBar.UI.priceListDropdown, DetaurBar.UI.activePriceListName == "Default" and "Select list..." or DetaurBar.UI.activePriceListName or "Select list...")
end

DetaurBar.UI.HidePriceListPanel = function()
    DetaurBar.UI.priceListPanel:Hide()
    DetaurBar.UI.priceListControls:Hide()
end

-- ============================================
--  BANK SUB-TAB: panel, grid, scan
-- ============================================
DetaurBar.UI.bankPanel = CreateFrame("Frame", "DetaurBarBankPanel", DetaurBar.UI.frame)
DetaurBar.UI.bankPanel:SetPoint("TOPLEFT", DetaurBar.UI.frame, "TOPLEFT", 16, -88)
DetaurBar.UI.bankPanel:SetPoint("BOTTOMRIGHT", DetaurBar.UI.frame, "BOTTOMRIGHT", -20, 46)
DetaurBar.UI.bankPanel:SetFrameLevel(DetaurBar.UI.frame:GetFrameLevel() + 5)
DetaurBar.UI.bankPanel:Hide()

local function GetBankThresholdDB()
    DetaurBar.Data.InitializeDB()
    if not DetaurBarDB.settings.bankThreshold then
        DetaurBarDB.settings.bankThreshold = 30
    end
    return DetaurBarDB.settings.bankThreshold
end

-- Threshold input row at top of bank panel
DetaurBar.UI.bankThresholdRow = CreateFrame("Frame", nil, DetaurBar.UI.bankPanel)
DetaurBar.UI.bankThresholdRow:SetHeight(28)
DetaurBar.UI.bankThresholdRow:SetPoint("TOPLEFT", DetaurBar.UI.bankPanel, "TOPLEFT", 0, 0)
DetaurBar.UI.bankThresholdRow:SetPoint("TOPRIGHT", DetaurBar.UI.bankPanel, "TOPRIGHT", 0, 0)

local bankThresholdLabel = DetaurBar.UI.bankThresholdRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
bankThresholdLabel:SetPoint("LEFT", DetaurBar.UI.bankThresholdRow, "LEFT", 4, 0)
bankThresholdLabel:SetText("Threshold:")
bankThresholdLabel:SetTextColor(1.0, 0.82, 0.0, 1.0)

local bankThresholdInput = CreateFrame("EditBox", "DetaurBarBankThresholdInput", DetaurBar.UI.bankThresholdRow)
bankThresholdInput:SetSize(50, 22)
bankThresholdInput:SetPoint("LEFT", bankThresholdLabel, "RIGHT", 6, 0)
bankThresholdInput:SetAutoFocus(false)
bankThresholdInput:SetNumeric(true)
bankThresholdInput:SetMaxLetters(5)
bankThresholdInput:SetTextInsets(4, 4, 0, 0)
bankThresholdInput:SetFontObject("GameFontHighlightSmall")
bankThresholdInput:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
bankThresholdInput:SetBackdropColor(0, 0, 0, 0.8)
bankThresholdInput:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)

local bankCountLabel = DetaurBar.UI.bankThresholdRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
bankCountLabel:SetPoint("RIGHT", DetaurBar.UI.bankThresholdRow, "RIGHT", -4, 0)
bankCountLabel:SetTextColor(1.0, 1.0, 1.0, 1.0)
DetaurBar.UI.bankCountLabel = bankCountLabel

local BANK_COLS = 6
local BANK_ROWS = 6
local BANK_SLOT_SIZE = 36
local BANK_SLOT_GAP = 1

local BANK_GRID_HEIGHT = BANK_ROWS * (BANK_SLOT_SIZE + BANK_SLOT_GAP)

-- 6x6 item grid
DetaurBar.UI.bankGridFrame = CreateFrame("Frame", "DetaurBarBankGrid", DetaurBar.UI.bankPanel)
DetaurBar.UI.bankGridFrame:SetPoint("TOPLEFT", DetaurBar.UI.bankThresholdRow, "BOTTOMLEFT", 0, -1)
DetaurBar.UI.bankGridFrame:SetPoint("BOTTOMLEFT", DetaurBar.UI.bankThresholdRow, "BOTTOMLEFT", 0, -1 - BANK_GRID_HEIGHT)
DetaurBar.UI.bankGridFrame:SetPoint("TOPRIGHT", DetaurBar.UI.bankThresholdRow, "BOTTOMRIGHT", 0, -1)

function DetaurBar.UI.CreateBankGridSlots()
    if DetaurBar.UI.bankGridSlots then
        for _, slot in ipairs(DetaurBar.UI.bankGridSlots) do
            slot:Hide()
            slot:SetParent(nil)
        end
    end
    DetaurBar.UI.bankGridSlots = {}

    for row = 0, BANK_ROWS - 1 do
        for col = 0, BANK_COLS - 1 do
            local idx = row * BANK_COLS + col + 1
            if idx > BANK_ROWS * BANK_COLS then break end

            local slot = CreateFrame("Frame", "DetaurBarBankSlot_" .. idx, DetaurBar.UI.bankGridFrame)
            slot:SetSize(BANK_SLOT_SIZE, BANK_SLOT_SIZE)
            slot:EnableMouse(true)
            slot:SetPoint("TOPLEFT", DetaurBar.UI.bankGridFrame, "TOPLEFT",
                col * (BANK_SLOT_SIZE + BANK_SLOT_GAP),
                -(row * (BANK_SLOT_SIZE + BANK_SLOT_GAP)))

            slot:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 12, edgeSize = 12,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            slot:SetBackdropColor(0.08, 0.06, 0.04, 0.9)
            slot:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

            local icon = slot:CreateTexture(nil, "ARTWORK")
            icon:SetSize(BANK_SLOT_SIZE - 2, BANK_SLOT_SIZE - 2)
            icon:SetPoint("CENTER", slot, "CENTER", 0, 0)
            icon:Hide()
            slot.icon = icon

            local countText = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            countText:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 1)
            countText:SetTextColor(1.0, 1.0, 1.0, 1.0)
            countText:Hide()
            slot.countText = countText

            slot:SetScript("OnEnter", function(self)
                if self.itemId then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    local _, serverLink = GetItemInfo(self.itemId)
                    if serverLink then
                        GameTooltip:SetHyperlink(serverLink)
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("Count: " .. (self.itemCount or "?"), 0.8, 0.8, 0.8)
                    else
                        GameTooltip:ClearLines()
                        local name = DetaurBar.UI.GetOfflineItemNameById(self.itemId)
                        if name then
                            GameTooltip:AddLine(name, 1.0, 1.0, 1.0)
                            GameTooltip:AddLine("Count: " .. (self.itemCount or "?"), 0.8, 0.8, 0.8)
                            GameTooltip:AddLine("ID: " .. self.itemId, 0.5, 0.5, 0.5)
                        else
                            GameTooltip:AddLine("Item ID: " .. self.itemId, 1.0, 1.0, 1.0)
                            GameTooltip:AddLine("Count: " .. (self.itemCount or "?"), 0.8, 0.8, 0.8)
                            GameTooltip:AddLine("Server data not cached yet", 0.5, 0.5, 0.5)
                        end
                    end
                    GameTooltip:Show()
                end
            end)
            slot:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            DetaurBar.UI.bankGridSlots[idx] = slot
        end
    end
end

DetaurBar.UI.CreateBankGridSlots()

-- Horizontal divider below grid
DetaurBar.UI.bankSourceDivider = DetaurBar.UI.bankPanel:CreateTexture(nil, "ARTWORK")
DetaurBar.UI.bankSourceDivider:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
DetaurBar.UI.bankSourceDivider:SetHeight(8)
DetaurBar.UI.bankSourceDivider:SetPoint("TOPLEFT", DetaurBar.UI.bankGridFrame, "BOTTOMLEFT", 0, -4)
DetaurBar.UI.bankSourceDivider:SetPoint("TOPRIGHT", DetaurBar.UI.bankGridFrame, "BOTTOMRIGHT", 0, -4)

-- Source checkboxes stacked below each other below divider
local function OnBankSourceCheckboxClick(self)
    local checked = self:GetChecked()
    DetaurBarDB.settings.bankSources[self.source] = checked or false
    DetaurBar.UI.UpdateBankGrid()
end

local sourceKeys = { "Personal", "Bank", "Guildbank" }
DetaurBar.UI.bankSourceCheckboxes = {}
for i, key in ipairs(sourceKeys) do
    local cb = CreateFrame("CheckButton", "DetaurBarBankSourceCb" .. key, DetaurBar.UI.bankPanel, "UICheckButtonTemplate")
    cb:SetSize(20, 20)
    cb.source = key
    cb:SetPoint("LEFT", DetaurBar.UI.bankPanel, "LEFT", 5, 0)
    if i == 1 then
        cb:SetPoint("TOP", DetaurBar.UI.bankSourceDivider, "BOTTOM", 0, -6)
    else
        cb:SetPoint("TOP", DetaurBar.UI.bankSourceCheckboxes[sourceKeys[i - 1]], "BOTTOM", 0, -4)
    end

    local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetText(key)
    label:SetTextColor(1.0, 0.82, 0.0, 1.0)

    DetaurBar.Data.InitializeDB()
    if DetaurBarDB.settings.bankSources[key] == nil then
        DetaurBarDB.settings.bankSources[key] = true
    end
    cb:SetChecked(DetaurBarDB.settings.bankSources[key] and 1 or nil)
    cb:SetScript("OnClick", OnBankSourceCheckboxClick)

    DetaurBar.UI.bankSourceCheckboxes[key] = cb
end

bankThresholdInput:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    local val = tonumber(self:GetText()) or 30
    if val < 1 then val = 1 end
    DetaurBarDB.settings.bankThreshold = val
    self:SetText(tostring(val))
    DetaurBar.UI.UpdateBankGrid()
end)
bankThresholdInput:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

function DetaurBar.UI.BuildBankDisplayList()
    DetaurBar.Data.InitializeDB()
    local threshold = DetaurBarDB.settings and DetaurBarDB.settings.bankThreshold or 30
    if threshold < 1 then threshold = 1 end
    if not DetaurBarDB.bankCache then
        DetaurBarDB.bankCache = {}
    end
    local sources = DetaurBarDB.settings.bankSources or { Personal = true, Bank = true, Guildbank = true }
    local result = {}
    for idStr, entry in pairs(DetaurBarDB.bankCache) do
        local numericId = tonumber(idStr)
        if numericId then
            -- Handle old format: number = treat as all sources
            local total
            if type(entry) == "number" then
                DetaurBarDB.bankCache[idStr] = { personal = entry, bank = entry, guildbank = entry }
                total = entry
            else
                total = 0
                if sources.Personal then total = total + (entry.personal or 0) end
                if sources.Bank then total = total + (entry.bank or 0) end
                if sources.Guildbank then total = total + (entry.guildbank or 0) end
            end
            if total >= threshold then
                table.insert(result, { itemId = numericId, count = total })
            end
        end
    end
    table.sort(result, function(a, b) return a.count > b.count end)
    DetaurBar.UI.bankCachedItems = result
end

function DetaurBar.UI.UpdateBankGrid()
    DetaurBar.UI.BuildBankDisplayList()
    local items = DetaurBar.UI.bankCachedItems or {}
    local numSlots = BANK_ROWS * BANK_COLS
    for i = 1, numSlots do
        local slot = DetaurBar.UI.bankGridSlots[i]
        if not slot then break end
        local data = items[i]
        if data then
            local texture = DetaurBar.Data.GetItemTexture(data.itemId)
            if not texture then
                texture = select(10, GetItemInfo(data.itemId))
            end
            if texture then
                slot.icon:SetTexture(texture)
                slot.icon:Show()
            else
                slot.icon:Hide()
                GetItemInfo(data.itemId)
                GetItemInfo("item:" .. data.itemId)
            end
            slot.countText:SetText(data.count)
            slot.countText:Show()
            slot.itemId = data.itemId
            slot.itemCount = data.count
            slot:SetBackdropBorderColor(0.4, 0.35, 0.1, 0.9)
        else
            slot.icon:Hide()
            slot.countText:Hide()
            slot.itemId = nil
            slot.itemCount = nil
            slot:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        end
    end

    local threshold = DetaurBarDB.settings and DetaurBarDB.settings.bankThreshold or 30
    local total = #items
    local maxSlots = numSlots
    if total == 0 then
        DetaurBar.UI.bankCountLabel:SetText("No items above " .. threshold)
    elseif total <= maxSlots then
        DetaurBar.UI.bankCountLabel:SetText(total .. " items above " .. threshold)
    else
        DetaurBar.UI.bankCountLabel:SetText(total .. " items above " .. threshold .. " (showing top " .. maxSlots .. ")")
    end
end

function DetaurBar.UI.ScanBankItems(silent)
    DetaurBar.Data.InitializeDB()
    if not DetaurBarDB.bankCache then
        DetaurBarDB.bankCache = {}
    end

    -- Determine which sources are available for this scan
    local bankAvailable = false
    for bag = 5, 11 do
        if GetContainerNumSlots(bag) and GetContainerNumSlots(bag) > 0 then
            bankAvailable = true
            break
        end
    end
    local gbankAvailable = GuildBankFrame and GuildBankFrame:IsShown() and GetNumGuildBankTabs() and GetNumGuildBankTabs() > 0

    -- Convert any old-format entries (combined count) before scan — set to 0, next scan populates per-source
    for idStr, entry in pairs(DetaurBarDB.bankCache) do
        if type(entry) == "number" then
            DetaurBarDB.bankCache[idStr] = { personal = 0, bank = 0, guildbank = 0 }
        end
    end

    local freshPersonal = {}
    local freshBank = {}
    local freshGuild = {}

    -- Scan bags (0 = backpack, 1-4 = bags)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemId = tonumber(link:match("item:(%d+)"))
                if itemId then
                    local _, count = GetContainerItemInfo(bag, slot)
                    count = count or 1
                    freshPersonal[itemId] = (freshPersonal[itemId] or 0) + count
                end
            end
        end
    end

    -- Scan bank containers (5-11)
    for bag = 5, 11 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local itemId = tonumber(link:match("item:(%d+)"))
                    if itemId then
                        local _, count = GetContainerItemInfo(bag, slot)
                        count = count or 1
                        freshBank[itemId] = (freshBank[itemId] or 0) + count
                    end
                end
            end
        end
    end

    -- Scan guild bank if open
    local numTabs = GetNumGuildBankTabs()
    if numTabs and numTabs > 0 then
        for tab = 1, numTabs do
            for slot = 1, 98 do
                local link = GetGuildBankItemLink(tab, slot)
                if link then
                    local itemId = tonumber(link:match("item:(%d+)"))
                    if itemId then
                        local info1, info2 = GetGuildBankItemInfo(tab, slot)
                        local itemCount
                        if type(info1) == "number" then
                            itemCount = info1
                        elseif type(info2) == "number" then
                            itemCount = info2
                        else
                            itemCount = 1
                        end
                        freshGuild[itemId] = (freshGuild[itemId] or 0) + itemCount
                    end
                end
            end
        end
    end

    -- Merge per-source into persistent cache
    local function EnsureEntry(id)
        local key = tostring(id)
        if not DetaurBarDB.bankCache[key] or type(DetaurBarDB.bankCache[key]) ~= "table" then
            DetaurBarDB.bankCache[key] = { personal = 0, bank = 0, guildbank = 0 }
        end
        return DetaurBarDB.bankCache[key]
    end

    -- Pre-clear sources that ARE being rescanned — sources not available keep existing data
    for _, entry in pairs(DetaurBarDB.bankCache) do
        if type(entry) == "table" then
            entry.personal = 0
            if bankAvailable then entry.bank = 0 end
            if gbankAvailable then entry.guildbank = 0 end
        end
    end

    for itemId, count in pairs(freshPersonal) do
        EnsureEntry(itemId).personal = count
    end
    for itemId, count in pairs(freshBank) do
        EnsureEntry(itemId).bank = count
    end
    for itemId, count in pairs(freshGuild) do
        EnsureEntry(itemId).guildbank = count
    end

    DetaurBar.UI.BuildBankDisplayList()

    if DetaurBar.UI.bankPanel and DetaurBar.UI.bankPanel:IsShown() then
        DetaurBar.UI.UpdateBankGrid()
    end

    if not silent then
        local unique = {}
        for id in pairs(freshPersonal) do unique[id] = true end
        for id in pairs(freshBank) do unique[id] = true end
        for id in pairs(freshGuild) do unique[id] = true end
        local totalNew = 0
        for _ in pairs(unique) do totalNew = totalNew + 1 end
        print("|cffffff00DetaurBar:|r Bank scan complete: " .. #DetaurBar.UI.bankCachedItems .. " items shown (found " .. totalNew .. " unique this scan)")
    end
end

-- Initialize bank threshold input text
local initThreshold = GetBankThresholdDB()
bankThresholdInput:SetText(tostring(initThreshold))

function DetaurBar.UI.LoadBankCache()
    DetaurBar.Data.InitializeDB()
    if not DetaurBarDB.bankCache then
        DetaurBarDB.bankCache = {}
    end
    DetaurBar.UI.BuildBankDisplayList()
end

DetaurBar.UI.LoadBankCache()
