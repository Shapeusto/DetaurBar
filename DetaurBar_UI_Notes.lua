-- DetaurBar_UI_Notes.lua
-- Merged Tasks tab: user-defined categories, checkboxes, click-to-copy, drag-to-move

DetaurBar.UI.notesSubTabs = {}
DetaurBar.UI.activeNotesSubTab = nil

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

-- [BUTTON FACTORY] CreateSubTabButton — child of scrollChild, reused via pool
local function CreateSubTabButton()
    local subTab = CreateFrame("Button", nil, DetaurBar.UI.notesTabScrollChild)
    subTab:SetHeight(24)
    subTab:EnableMouse(true)
    subTab.tabName = ""
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
    label:SetText("")
    subTab.label = label

    local highlight = subTab:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(subTab)
    highlight:SetTexture(1.0, 0.82, 0.0, 0.12)

    subTab:SetScript("OnClick", function()
        DetaurBar.UI.SelectNotesSubTab(subTab.tabName)
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
            GameTooltip:AddLine("Move Task", 1.0, 1.0, 1.0)
            GameTooltip:AddLine("Release to move this task to " .. self.tabName .. ".", 0.5, 0.5, 0.5)
            GameTooltip:Show()
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self.tabName, 1.0, 0.82, 0.0)
            GameTooltip:Show()
        end
    end)
    subTab:SetScript("OnLeave", function(self)
        SetNotesSubTabStyle(self)
        GameTooltip:Hide()
    end)

    return subTab
end

-- [SUBTAB MANAGEMENT] DetaurBar.UI.RebuildNotesSubTabs — sync button pool with DB
function DetaurBar.UI.RebuildNotesSubTabs()
    local catNames = DetaurBar.Data.GetTaskCategories()
    local pool = DetaurBar.UI.notesSubTabs

    while #pool < #catNames do
        table.insert(pool, CreateSubTabButton())
    end

    for i, subTab in ipairs(pool) do
        if i <= #catNames then
            local name = catNames[i]
            subTab.tabName = name
            subTab.label:SetText(name)
            subTab:Show()
        else
            subTab:Hide()
        end
    end

    if not DetaurBar.UI.activeNotesSubTab or not DetaurBar.Data.TaskCategoryExists(DetaurBar.UI.activeNotesSubTab) then
        DetaurBar.UI.activeNotesSubTab = catNames[1] or "General"
    end

    DetaurBar.UI.LayoutNotesSubTabs()
    DetaurBar.UI.UpdateNotesSubTabVisuals()

    -- Clamp scroll after layout change (e.g. after delete)
    local container = DetaurBar.UI.notesTabContainer
    if container then
        local maxScroll = math.max(0, DetaurBar.UI.notesTabScrollChild:GetWidth() - container:GetWidth())
        local cur = container:GetHorizontalScroll() or 0
        if cur > maxScroll then
            container:SetHorizontalScroll(maxScroll)
        end
    end
end

-- [LAYOUT] DetaurBar.UI.LayoutNotesSubTabs — position buttons in scrollChild
function DetaurBar.UI.LayoutNotesSubTabs()
    local pool = DetaurBar.UI.notesSubTabs
    local shown = {}
    for _, t in ipairs(pool) do
        if t:IsShown() then table.insert(shown, t) end
    end
    local n = #shown
    if n == 0 then return end

    local totalWidth = DetaurBar.UI.frame:GetWidth() - 28
    local gap = 1

    local maxTextWidth = 0
    for _, subTab in ipairs(shown) do
        local tw = subTab.label:GetStringWidth() or 0
        if tw > maxTextWidth then maxTextWidth = tw end
    end
    local MIN_WIDTH = math.max(50, maxTextWidth + 12)

    local btnWidth = math.max(MIN_WIDTH, (totalWidth - (n - 1) * gap) / n)
    local totalContentWidth = n * btnWidth + (n - 1) * gap

    for i, subTab in ipairs(shown) do
        subTab:SetWidth(btnWidth)
        subTab:ClearAllPoints()
        if i == 1 then
            subTab:SetPoint("TOPLEFT", DetaurBar.UI.notesTabScrollChild, "TOPLEFT", 0, 0)
        else
            subTab:SetPoint("LEFT", shown[i-1], "RIGHT", gap, 0)
        end
    end

    DetaurBar.UI.notesTabScrollChild:SetWidth(totalContentWidth)
    DetaurBar.UI.UpdateNotesSubTabArrows()

    -- Clamp scroll on resize (totalWidth may have changed)
    local container = DetaurBar.UI.notesTabContainer
    if container then
        local maxScroll = math.max(0, totalContentWidth - totalWidth)
        local cur = container:GetHorizontalScroll() or 0
        if cur > maxScroll then
            container:SetHorizontalScroll(maxScroll)
        end
    end
end

-- [ARROW VIS] DetaurBar.UI.UpdateNotesSubTabArrows — show/hide based on current scroll
function DetaurBar.UI.UpdateNotesSubTabArrows()
    if not DetaurBar.UI.notesTabContainer then return end
    local scroll = DetaurBar.UI.notesTabContainer:GetHorizontalScroll() or 0
    local maxScroll = math.max(0, DetaurBar.UI.notesTabScrollChild:GetWidth() - DetaurBar.UI.notesTabContainer:GetWidth())

    if DetaurBar.UI.notesTabLeftArrow then
        if scroll > 0 then DetaurBar.UI.notesTabLeftArrow:Show() else DetaurBar.UI.notesTabLeftArrow:Hide() end
    end
    if DetaurBar.UI.notesTabRightArrow then
        if scroll < maxScroll then DetaurBar.UI.notesTabRightArrow:Show() else DetaurBar.UI.notesTabRightArrow:Hide() end
    end
end

-- [CONTAINER] ScrollFrame with native clipping for sub-tab buttons
do
    local container = CreateFrame("ScrollFrame", nil, DetaurBar.UI.frame)
    container:SetPoint("TOPLEFT", DetaurBar.UI.frame, "TOPLEFT", 14, -60)
    container:SetPoint("TOPRIGHT", DetaurBar.UI.frame, "TOPRIGHT", -14, -60)
    container:SetHeight(24)
    container:SetFrameLevel(DetaurBar.UI.frame:GetFrameLevel() + 6)
    container:Hide()
    DetaurBar.UI.notesTabContainer = container

    local scrollChild = CreateFrame("Frame", nil, container)
    scrollChild:SetHeight(24)
    container:SetScrollChild(scrollChild)
    DetaurBar.UI.notesTabScrollChild = scrollChild
end

-- [SCROLL ARROWS] Left/right arrow buttons at container edges
do
    local leftArrow = CreateFrame("Button", nil, DetaurBar.UI.frame)
    leftArrow:SetSize(12, 24)
    leftArrow:SetPoint("LEFT", DetaurBar.UI.notesTabContainer, "LEFT", 0, 0)
    leftArrow:SetFrameLevel(DetaurBar.UI.frame:GetFrameLevel() + 10)
    leftArrow:Hide()
    leftArrow:SetScript("OnClick", function()
        local c = DetaurBar.UI.notesTabContainer
        if not c then return end
        c:SetHorizontalScroll(math.max(0, (c:GetHorizontalScroll() or 0) - 60))
        DetaurBar.UI.UpdateNotesSubTabArrows()
    end)
    local ll = leftArrow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ll:SetPoint("CENTER")
    ll:SetText("<")
    ll:SetTextColor(1.0, 0.82, 0.0, 1.0)
    DetaurBar.UI.notesTabLeftArrow = leftArrow

    local rightArrow = CreateFrame("Button", nil, DetaurBar.UI.frame)
    rightArrow:SetSize(12, 24)
    rightArrow:SetPoint("RIGHT", DetaurBar.UI.notesTabContainer, "RIGHT", 0, 0)
    rightArrow:SetFrameLevel(DetaurBar.UI.frame:GetFrameLevel() + 10)
    rightArrow:Hide()
    rightArrow:SetScript("OnClick", function()
        local c = DetaurBar.UI.notesTabContainer
        if not c then return end
        local scroll = (c:GetHorizontalScroll() or 0) + 60
        local maxScroll = math.max(0, DetaurBar.UI.notesTabScrollChild:GetWidth() - c:GetWidth())
        c:SetHorizontalScroll(math.min(scroll, maxScroll))
        DetaurBar.UI.UpdateNotesSubTabArrows()
    end)
    local rl = rightArrow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rl:SetPoint("CENTER")
    rl:SetText(">")
    rl:SetTextColor(1.0, 0.82, 0.0, 1.0)
    DetaurBar.UI.notesTabRightArrow = rightArrow
end

-- [VISUALS] DetaurBar.UI.UpdateNotesSubTabVisuals
function DetaurBar.UI.UpdateNotesSubTabVisuals()
    for _, subTab in ipairs(DetaurBar.UI.notesSubTabs) do
        if subTab:IsShown() then
            SetNotesSubTabStyle(subTab)
            if subTab.tabName == DetaurBar.UI.activeNotesSubTab then
                subTab:Disable()
            else
                subTab:Enable()
            end
        end
    end
end

-- [SUB-TAB SWITCH] DetaurBar.UI.SelectNotesSubTab
function DetaurBar.UI.SelectNotesSubTab(subTabName)
    if not subTabName or not DetaurBar.Data.TaskCategoryExists(subTabName) then
        local cats = DetaurBar.Data.GetTaskCategories()
        subTabName = cats[1]
        if not subTabName then return end
    end
    DetaurBar.UI.activeNotesSubTab = subTabName
    DetaurBar.UI.UpdateNotesSubTabVisuals()
    DetaurBar.UI.UpdateInputPlaceholder()
    DetaurBar.UI.RefreshTasks()
end

-- [CATEGORY CONTROLS] Bottom bar: label, editBox, Add Cat, Delete Cat
do
    local bg = CreateFrame("Frame", nil, DetaurBar.UI.frame)
    bg:SetHeight(32)
    bg:SetPoint("BOTTOMLEFT", DetaurBar.UI.frame, "BOTTOMLEFT", 16, 49)
    bg:SetPoint("BOTTOMRIGHT", DetaurBar.UI.frame, "BOTTOMRIGHT", -16, 49)

    bg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    bg:SetBackdropColor(0, 0, 0, 0.4)
    bg:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
    bg:Hide()
    DetaurBar.UI.notesCatControls = bg

    local catEdit = CreateFrame("EditBox", nil, bg)
    catEdit:SetHeight(18)
    catEdit:SetFontObject("GameFontHighlightSmall")
    catEdit:SetAutoFocus(false)
    catEdit:SetTextInsets(4, 4, 0, 0)
    catEdit:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    catEdit:SetBackdropColor(0, 0, 0, 0.8)
    catEdit:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
    DetaurBar.UI.notesCatEdit = catEdit

    -- Placeholder text inside the edit box
    local catPlaceholder = catEdit:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    catPlaceholder:SetPoint("LEFT", catEdit, "LEFT", 6, 0)
    catPlaceholder:SetText("Add category")
    catEdit:SetScript("OnTextChanged", function(self)
        if self:GetText() == "" then
            catPlaceholder:Show()
        else
            catPlaceholder:Hide()
        end
    end)

    local addCatBtn = CreateFrame("Button", nil, bg, "UIPanelButtonTemplate")
    addCatBtn:SetSize(60, 18)
    addCatBtn:SetPoint("RIGHT", bg, "RIGHT", -6, 0)
    addCatBtn:SetText("Add")

    catEdit:SetPoint("LEFT", bg, "LEFT", 72, 0)
    catEdit:SetPoint("RIGHT", addCatBtn, "LEFT", -6, 0)
    addCatBtn:SetScript("OnClick", function()
        local name = catEdit:GetText()
        name = name:gsub("^%s*(.-)%s*$", "%1")
        if name ~= "" then
            local result = DetaurBar.Data.AddTaskCategory(name)
            if result then
                catEdit:SetText("")
                catEdit:ClearFocus()
                DetaurBar.UI.RebuildNotesSubTabs()
                DetaurBar.UI.SelectNotesSubTab(result)
                DetaurBar.UI.UpdateInputPlaceholder()
                DetaurBar.UI.OnResize()
            else
                catEdit:SetText("")
            end
        end
    end)
    DetaurBar.UI.notesAddCatBtn = addCatBtn

    catEdit:SetScript("OnEnterPressed", function(self)
        addCatBtn:GetScript("OnClick")(self)
    end)
    catEdit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    local delCatBtn = CreateFrame("Button", nil, bg, "UIPanelButtonTemplate")
    delCatBtn:SetSize(60, 18)
    delCatBtn:SetPoint("LEFT", bg, "LEFT", 6, 0)
    delCatBtn:SetText("Delete")
    delCatBtn:SetScript("OnClick", function()
        local active = DetaurBar.UI.activeNotesSubTab
        if not active then return end
        if active:lower() == "general" then
            print("Cannot delete the General category.")
            return
        end
        local cats = DetaurBar.Data.GetTaskCategories()
        if #cats <= 1 then
            print("Cannot delete the last category.")
            return
        end
        StaticPopup_Show("DETAURBAR_DELETE_CATEGORY", active)
    end)
    DetaurBar.UI.notesDelCatBtn = delCatBtn
end

-- [CONFIRM] StaticPopup dialog for category deletion
StaticPopupDialogs["DETAURBAR_DELETE_CATEGORY"] = {
    text = "Delete category '%s' and all its tasks?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        local active = DetaurBar.UI.activeNotesSubTab
        if not active then return end
        if DetaurBar.Data.DeleteTaskCategory(active) then
            local cats = DetaurBar.Data.GetTaskCategories()
            local newActive = cats[1] or "General"
            DetaurBar.UI.RebuildNotesSubTabs()
            DetaurBar.UI.SelectNotesSubTab(newActive)
            DetaurBar.UI.UpdateInputPlaceholder()
            DetaurBar.UI.OnResize()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
