-- DetaurBar_UI_Recipes.lua
-- Price > Recipes sub-tab: profession dropdown, recipe linking, reagent capture, expand/collapse list

DetaurBar.UI.activeRecipeProfession = "All"
DetaurBar.UI.expandedRecipeId = nil

-- ============================================
--  RECIPES SUB-TAB: panel (dropdown + link input)
-- ============================================
DetaurBar.UI.recipesPanel = CreateFrame("Frame", nil, DetaurBar.UI.frame)
DetaurBar.UI.recipesPanel:SetPoint("TOPLEFT", DetaurBar.UI.frame, "TOPLEFT", 14, -86)
DetaurBar.UI.recipesPanel:SetPoint("TOPRIGHT", DetaurBar.UI.frame, "TOPRIGHT", -14, -86)
DetaurBar.UI.recipesPanel:SetHeight(56)
DetaurBar.UI.recipesPanel:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left=3, right=3, top=3, bottom=3 }
})
DetaurBar.UI.recipesPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
DetaurBar.UI.recipesPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
DetaurBar.UI.recipesPanel:Hide()

-- Row 1: "Select profession:" label + dropdown
local recipesProfLabel = DetaurBar.UI.recipesPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
recipesProfLabel:SetPoint("LEFT", DetaurBar.UI.recipesPanel, "LEFT", 8, 12)
recipesProfLabel:SetText("Select profession:")
recipesProfLabel:SetTextColor(1.0, 0.82, 0.0, 1.0)

local function AddRecipesProfessionEntry(text, value)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.value = value
    info.func = function()
        DetaurBar.UI.activeRecipeProfession = value
        UIDropDownMenu_SetText(DetaurBar.UI.recipesProfessionDropdown, text)
        DetaurBar.UI.RefreshTasks()
    end
    UIDropDownMenu_AddButton(info)
end

local RECIPES_PRIMARY_PROFESSIONS = {
    ["Alchemy"] = true,
    ["Blacksmithing"] = true,
    ["Cooking"] = true,
    ["Enchanting"] = true,
    ["Engineering"] = true,
    ["First Aid"] = true,
    ["Fishing"] = true,
    ["Herbalism"] = true,
    ["Inscription"] = true,
    ["Jewelcrafting"] = true,
    ["Leatherworking"] = true,
    ["Mining"] = true,
    ["Skinning"] = true,
    ["Tailoring"] = true,
}

local function InitRecipesProfessionDropdown()
    AddRecipesProfessionEntry("All", "All")
    for i = 1, GetNumSkillLines() do
        if i > 14 then break end
        local skillName, isHeader = GetSkillLineInfo(i)
        if (not isHeader) and skillName and RECIPES_PRIMARY_PROFESSIONS[skillName] then
            AddRecipesProfessionEntry(skillName, skillName)
        end
    end
end

DetaurBar.UI.recipesProfessionDropdown = CreateFrame("Frame", "DetaurBarRecipesProfessionDropdown", DetaurBar.UI.recipesPanel, "UIDropDownMenuTemplate")
DetaurBar.UI.recipesProfessionDropdown:SetPoint("LEFT", recipesProfLabel, "RIGHT", 4, 0)
DetaurBar.UI.recipesProfessionDropdown:SetWidth(150)
UIDropDownMenu_SetAnchor(DetaurBar.UI.recipesProfessionDropdown, 0, 0, "TOPLEFT", DetaurBar.UI.recipesProfessionDropdown, "BOTTOMLEFT")
UIDropDownMenu_Initialize(DetaurBar.UI.recipesProfessionDropdown, InitRecipesProfessionDropdown)
UIDropDownMenu_SetText(DetaurBar.UI.recipesProfessionDropdown, "All")

-- Row 2: recipe link input box
DetaurBar.UI.recipesLinkBox = CreateFrame("EditBox", nil, DetaurBar.UI.recipesPanel)
DetaurBar.UI.recipesLinkBox:SetSize(200, 20)
DetaurBar.UI.recipesLinkBox:SetPoint("LEFT", DetaurBar.UI.recipesPanel, "LEFT", 10, -14)
DetaurBar.UI.recipesLinkBox:SetPoint("RIGHT", DetaurBar.UI.recipesPanel, "RIGHT", -10, -14)
DetaurBar.UI.recipesLinkBox:SetTextInsets(4, 4, 0, 0)
DetaurBar.UI.recipesLinkBox:SetAutoFocus(false)
DetaurBar.UI.recipesLinkBox:SetFontObject("GameFontHighlightSmall")
DetaurBar.UI.recipesLinkBox:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
DetaurBar.UI.recipesLinkBox:SetBackdropColor(0, 0, 0, 0.8)
DetaurBar.UI.recipesLinkBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
DetaurBar.UI.recipesLinkBox:SetScript("OnEscapePressed", function()
    DetaurBar.UI.recipesLinkBox:SetText("")
    DetaurBar.UI.recipesLinkBox:ClearFocus()
end)
DetaurBar.UI.recipesLinkBox:SetScript("OnEnterPressed", function()
    DetaurBar.UI.HandleRecipeLink()
end)

DetaurBar.UI.recipesLinkBoxPlaceholder = DetaurBar.UI.recipesLinkBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
DetaurBar.UI.recipesLinkBoxPlaceholder:SetPoint("LEFT", DetaurBar.UI.recipesLinkBox, "LEFT", 6, 0)
DetaurBar.UI.recipesLinkBoxPlaceholder:SetText("Link a recipe from your profession book...")
DetaurBar.UI.recipesLinkBox:SetScript("OnTextChanged", function(self)
    if self:GetText() == "" then
        DetaurBar.UI.recipesLinkBoxPlaceholder:Show()
    else
        DetaurBar.UI.recipesLinkBoxPlaceholder:Hide()
    end
end)

-- ============================================
--  RECIPES: link handling + reagent capture
-- ============================================
function DetaurBar.UI.HandleRecipeLink()
    local text = DetaurBar.UI.recipesLinkBox:GetText()
    if not text or text == "" then return end

    local recipeName = text:match("%[(.-)%]")
    if not recipeName then
        recipeName = text:match("^%s*(.-)%s*$")
    end
    if not recipeName or recipeName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ff[DetaurBar]|r Invalid recipe link.")
        return
    end
    local craftedItemId = tonumber(text:match("item:(%d+)"))

    local profession = DetaurBar.UI.activeRecipeProfession
    if not profession or profession == "All" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ff[DetaurBar]|r Select a profession first.")
        return
    end

    -- Capture reagents from the open profession window (TradeSkillFrame).
    -- 3.3.5a: collapsed subclass headers hide their recipes from GetNumTradeSkills,
    -- and the "Have Materials" filter hides un-craftable recipes. Expand/reset and restore.
    local reagents = {}
    local captured = false
    if TradeSkillFrame and TradeSkillFrame:IsShown() then
        local collapsedHeaders = {}
        local num = GetNumTradeSkills()
        for i = num, 1, -1 do
            local hName, hType, _, isExpanded = GetTradeSkillInfo(i)
            if hType == "header" and not isExpanded then
                collapsedHeaders[hName] = true
                ExpandTradeSkillSubClass(i)
            end
        end

        local haveMaterialsChecked
        if TradeSkillFrameAvailableFilterCheckButton and TradeSkillOnlyShowMakeable then
            haveMaterialsChecked = TradeSkillFrameAvailableFilterCheckButton:GetChecked()
            if haveMaterialsChecked then
                TradeSkillOnlyShowMakeable(false)
            end
        end

        num = GetNumTradeSkills()
        for i = 1, num do
            local name, tradeType = GetTradeSkillInfo(i)
            if tradeType ~= "header" then
                local matched = false
                if craftedItemId and GetTradeSkillItemLink then
                    local itemLink = GetTradeSkillItemLink(i)
                    local skillItemId = itemLink and tonumber(itemLink:match("item:(%d+)"))
                    if skillItemId and skillItemId == craftedItemId then
                        matched = true
                    end
                end
                if not matched and name == recipeName then
                    matched = true
                end
                if matched then
                    captured = true
                    local n = GetTradeSkillNumReagents(i)
                    for r = 1, n do
                        local rName, rIcon, rCount = GetTradeSkillReagentInfo(i, r)
                        if rName then
                            local reagentId = DetaurBar.UI.GetItemIdFromText(rName)
                            table.insert(reagents, {
                                name = rName,
                                icon = (reagentId and DetaurBar.Data.GetItemTexture(reagentId)) or rIcon,
                                count = rCount,
                                itemId = reagentId,
                            })
                        end
                    end
                    break
                end
            end
        end

        -- Restore the trade skill window state
        if haveMaterialsChecked and TradeSkillOnlyShowMakeable then
            TradeSkillOnlyShowMakeable(true)
        end
        num = GetNumTradeSkills()
        for i = num, 1, -1 do
            local hName, hType, _, isExpanded = GetTradeSkillInfo(i)
            if hType == "header" and collapsedHeaders[hName] and isExpanded then
                CollapseTradeSkillSubClass(i)
            end
        end
    end

    if not captured then
        DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ff[DetaurBar]|r Could not find '" .. recipeName .. "' in the open profession window. Open the profession book with this recipe visible, then link again.")
        return
    end

    DetaurBar.Data.AddRecipe({
        name = recipeName,
        profession = profession,
        icon = craftedItemId and DetaurBar.Data.GetItemTexture(craftedItemId) or nil,
        itemId = craftedItemId,
        reagents = reagents,
    })

    DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ff[DetaurBar]|r Recipe added: " .. recipeName)
    DetaurBar.UI.recipesLinkBox:SetText("")
    DetaurBar.UI.recipesLinkBox:ClearFocus()
    DetaurBar.UI.RefreshTasks()
end

DetaurBar.UI.ShowRecipesPanel = function()
    DetaurBar.UI.recipesPanel:Show()
end

DetaurBar.UI.HideRecipesPanel = function()
    DetaurBar.UI.recipesPanel:Hide()
end
