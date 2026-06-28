-- DetaurBar_UI_Todo.lua
-- Todo tab sub-tabs: Day, Week, Month

DetaurBar.UI.todoSubTabs = {}
DetaurBar.UI.todoSubTabNames = { "Day", "Week", "Month" }
DetaurBar.UI.activeTodoSubTab = "Day"

-- [SUB-TAB STYLE] Todo sub-tab visual
local function SetTodoSubTabStyle(subTab)
    if subTab.tabName == DetaurBar.UI.activeTodoSubTab then
        subTab:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
        subTab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        subTab.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    else
        subTab:SetBackdropColor(0, 0, 0, 0.55)
        subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        subTab.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
    end
end

-- [SUB-TABS/TODO] Create 3 sub-tabs: Day, Week, Month
for i, name in ipairs(DetaurBar.UI.todoSubTabNames) do
    local subTab = CreateFrame("Button", "DetaurBarTodoSubTab_" .. name, DetaurBar.UI.frame)
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
        DetaurBar.UI.SelectTodoSubTab(name)
    end)

    DetaurBar.UI.todoSubTabs[i] = subTab
end

-- [SUB-TAB VISUALS] UpdateTodoSubTabVisuals
function DetaurBar.UI.UpdateTodoSubTabVisuals()
    for _, subTab in ipairs(DetaurBar.UI.todoSubTabs) do
        SetTodoSubTabStyle(subTab)
        if subTab.tabName == DetaurBar.UI.activeTodoSubTab then
            subTab:Disable()
        else
            subTab:Enable()
        end
    end
end

-- [SUB-TAB SWITCH] DetaurBar.UI.SelectTodoSubTab
function DetaurBar.UI.SelectTodoSubTab(subTabName)
    DetaurBar.UI.activeTodoSubTab = subTabName
    DetaurBar.UI.UpdateTodoSubTabVisuals()
    DetaurBar.UI.UpdateInputPlaceholder()
    DetaurBar.UI.RefreshTasks()
end
