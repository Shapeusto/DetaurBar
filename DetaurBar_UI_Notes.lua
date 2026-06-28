-- DetaurBar_UI_Notes.lua
-- Notes tab sub-tabs: General, War, Guild

DetaurBar.UI.notesSubTabs = {}
DetaurBar.UI.notesSubTabNames = { "General", "War", "Guild" }
DetaurBar.UI.activeNotesSubTab = "General"

-- [SUB-TAB STYLE] Notes sub-tab visual
local function SetNotesSubTabStyle(subTab)
    if subTab.tabName == DetaurBar.UI.activeNotesSubTab then
        subTab:SetBackdropColor(0.18, 0.12, 0.02, 0.95)
        subTab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
        subTab.label:SetTextColor(1.0, 0.82, 0.0, 1.0)
    else
        subTab:SetBackdropColor(0, 0, 0, 0.55)
        subTab:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
        subTab.label:SetTextColor(1.0, 1.0, 1.0, 1.0)
    end
end

-- [SUB-TABS/NOTES] Create 3 sub-tabs: General, War, Guild
for i, name in ipairs(DetaurBar.UI.notesSubTabNames) do
    local subTab = CreateFrame("Button", "DetaurBarNotesSubTab_" .. name, DetaurBar.UI.frame)
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
        DetaurBar.UI.SelectNotesSubTab(name)
    end)
    subTab:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            DetaurBar.UI.DropDraggedNoteOnSubTab(self)
        end
    end)
    subTab:SetScript("OnReceiveDrag", function(self)
        DetaurBar.UI.DropDraggedNoteOnSubTab(self)
    end)
    subTab:SetScript("OnEnter", function(self)
        if DetaurBar.UI.draggedNote then
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

    DetaurBar.UI.notesSubTabs[i] = subTab
end

-- [SUB-TAB VISUALS] UpdateNotesSubTabVisuals
function DetaurBar.UI.UpdateNotesSubTabVisuals()
    for _, subTab in ipairs(DetaurBar.UI.notesSubTabs) do
        SetNotesSubTabStyle(subTab)
        if subTab.tabName == DetaurBar.UI.activeNotesSubTab then
            subTab:Disable()
        else
            subTab:Enable()
        end
    end
end

-- [SUB-TAB SWITCH] DetaurBar.UI.SelectNotesSubTab
function DetaurBar.UI.SelectNotesSubTab(subTabName)
    DetaurBar.UI.activeNotesSubTab = subTabName
    DetaurBar.UI.UpdateNotesSubTabVisuals()
    DetaurBar.UI.UpdateInputPlaceholder()
    DetaurBar.UI.RefreshTasks()
end
