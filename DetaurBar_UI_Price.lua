-- DetaurBar_UI_Price.lua
-- Price tab: price item sub-tabs, graph panel, sub-tab bar, threshold row, AH interval, price sub-tabs

DetaurBar.UI.priceItemSubTabs = {}
DetaurBar.UI.priceItemSubTabNames = { "Notifications", "Chart" }
DetaurBar.UI.activePriceItemSubTab = "Notifications"
DetaurBar.UI.expandedPriceItemId = nil
DetaurBar.UI.selectedPriceItemId = nil

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

-- [SUB-TABS/PRICE] Create 2 sub-tabs: Notifications, Chart
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

-- [PRICE/AH SCAN INTERVAL] AH scan interval edit in price > Notifications row
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

    if subTabName == "Notifications" then
        DetaurBar.UI.priceGraphPanel:Hide()
        DetaurBar.UI.priceSubTabBar:Hide()
        if DetaurBar.UI.priceThresholdRow then DetaurBar.UI.priceThresholdRow:Hide() end
        DetaurBar.UI.editBox:Hide()
        DetaurBar.UI.addButton:Hide()
    else
        DetaurBar.UI.priceGraphPanel:Show()
        DetaurBar.UI.priceSubTabBar:Show()
        DetaurBar.UI.editBox:Show()
        DetaurBar.UI.addButton:Show()
        DetaurBar.UI.UpdateThresholdRow()
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

    local itemTexture = nil
    local itemId = DetaurBar.UI.GetItemIdFromText(item.title)
    if itemId then
        local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemId)
        itemTexture = texture
        if DetaurBar.Data.ItemIcons and DetaurBar.Data.ItemIcons[itemId] then
            itemTexture = DetaurBar.Data.ItemIcons[itemId]
        end
    end

    if itemTexture then
        DetaurBar.UI.priceThresholdRow.icon:SetTexture(itemTexture)
        DetaurBar.UI.priceThresholdRow.icon:Show()
    else
        DetaurBar.UI.priceThresholdRow.icon:Hide()
    end

    local itemName = DetaurBar.UI.GetOfflineItemNameById(itemId) or item.title
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
