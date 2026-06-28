-- DetaurBar_UI_Loot.lua
-- Loot tab sub-tabs: Add, Delete

DetaurBar.UI.lootSubTabs = {}
DetaurBar.UI.lootSubTabNames = { "Add", "Delete" }
DetaurBar.UI.activeLootSubTab = "Add"

-- [SUB-TAB STYLE] Loot sub-tab visual
local function SetLootSubTabStyle(subTab)
    if subTab.tabName == DetaurBar.UI.activeLootSubTab then
        subTab:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
        subTab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        subTab.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    else
        subTab:SetBackdropColor(0, 0, 0, 0.55)
        subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        subTab.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
    end
end

-- [SUB-TABS/LOOT] Create 2 sub-tabs: Add, Delete
for i, name in ipairs(DetaurBar.UI.lootSubTabNames) do
    local subTab = CreateFrame("Button", "DetaurBarLootSubTab_" .. name, DetaurBar.UI.frame)
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
        DetaurBar.UI.SelectLootSubTab(name)
    end)

    DetaurBar.UI.lootSubTabs[i] = subTab
end

-- [SUB-TAB VISUALS] UpdateLootSubTabVisuals
function DetaurBar.UI.UpdateLootSubTabVisuals()
    for _, subTab in ipairs(DetaurBar.UI.lootSubTabs) do
        SetLootSubTabStyle(subTab)
        if subTab.tabName == DetaurBar.UI.activeLootSubTab then
            subTab:Disable()
        else
            subTab:Enable()
        end
    end
end

-- [LOOT] "Delete All Grays" checkbox
DetaurBar.UI.deleteAllGraysCheckbox = CreateFrame("CheckButton", "DetaurBarDeleteAllGrays", DetaurBar.UI.frame, "UICheckButtonTemplate")
DetaurBar.UI.deleteAllGraysCheckbox:SetSize(20, 20)
DetaurBar.UI.deleteAllGraysCheckbox:SetPoint("TOPLEFT", DetaurBar.UI.frame, "TOPLEFT", 16, -90)
DetaurBar.UI.deleteAllGraysCheckbox:Hide()
DetaurBar.UI.deleteAllGraysCheckbox:SetScript("OnClick", function(self)
    if DetaurBarDB and DetaurBarDB.loot then
        DetaurBarDB.loot.deleteAllGrays = self:GetChecked() and true or false
    end
end)
local deleteAllGraysLabel = DetaurBar.UI.deleteAllGraysCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
deleteAllGraysLabel:SetPoint("LEFT", DetaurBar.UI.deleteAllGraysCheckbox, "RIGHT", 4, 0)
deleteAllGraysLabel:SetText("Delete all grays")
deleteAllGraysLabel:SetTextColor(1, 0.82, 0, 1)

-- [SUB-TAB SWITCH] DetaurBar.UI.SelectLootSubTab
function DetaurBar.UI.SelectLootSubTab(subTabName)
    DetaurBar.UI.activeLootSubTab = subTabName
    DetaurBar.UI.UpdateLootSubTabVisuals()
    DetaurBar.UI.UpdateInputPlaceholder()
    if subTabName == "Delete" then
        DetaurBar.UI.deleteAllGraysCheckbox:SetChecked(DetaurBarDB and DetaurBarDB.loot and DetaurBarDB.loot.deleteAllGrays or false)
        DetaurBar.UI.deleteAllGraysCheckbox:Show()
    else
        DetaurBar.UI.deleteAllGraysCheckbox:Hide()
    end
    DetaurBar.UI.UpdateContentAnchors()
    DetaurBar.UI.RefreshTasks()
end
