-- DetaurBar_Core.lua
-- Handles addon initialization, event registration, slash commands, and loot management.

DetaurBar = DetaurBar or {}
DetaurBar.Core = {}

local eventFrame = CreateFrame("Frame", "DetaurBarEventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
eventFrame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
eventFrame:RegisterEvent("LFG_PROPOSAL_SHOW")
eventFrame:RegisterEvent("LFG_PROPOSAL_HIDE")
eventFrame:RegisterEvent("LFG_PROPOSAL_CLOSE")
eventFrame:RegisterEvent("LFG_PROPOSAL_FAILED")
eventFrame:RegisterEvent("LFG_PROPOSAL_SUCCEEDED")
eventFrame:RegisterEvent("LFG_PROPOSAL_COMPLETE")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("UPDATE_BINDINGS")

local function GetSettingsTable()
    if DetaurBar.Data and DetaurBar.Data.GetSettings then
        return DetaurBar.Data.GetSettings()
    end
    return DetaurBarDB and DetaurBarDB.settings or {}
end

eventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 == "DetaurBar" or arg1 == "Detaurtodo" then
            DetaurBar.Data.InitializeDB()
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_LOGIN" then
        DetaurBar.Data.InitializeDB()
        DetaurBar.UI.Initialize()
        DetaurBar.Core.UpdateAutoLootCVar()
        DetaurBar.Core.HookActionButtons()
        DetaurBar.Core.SetupOverrideBindings()
        self:UnregisterEvent("PLAYER_LOGIN")

    elseif event == "UPDATE_BINDINGS" then
        DetaurBar.Core.SetupOverrideBindings()

    elseif event == "GET_ITEM_INFO_RECEIVED" then
        if DetaurBarFrame and DetaurBarFrame:IsShown() then
            DetaurBar.UI.RefreshTasks()
        end

    elseif event == "AUCTION_HOUSE_SHOW" then
        local delayFrame = CreateFrame("Frame")
        local elapsed = 0
        delayFrame:SetScript("OnUpdate", function(self, e)
            elapsed = elapsed + e
            if elapsed < 2 then return end
            self:SetScript("OnUpdate", nil)
            self:Hide()
            if DetaurBar.AHScan and DetaurBar.AHScan.StartScan then
                DetaurBar.AHScan.StartScan()
            end
        end)

    elseif event == "LFG_PROPOSAL_SHOW" then
        local settings = GetSettingsTable()
        if settings.dungeonFlashEnabled and DetaurBar.Alerts and DetaurBar.Alerts.StartDungeonFlash then
            local duration = (settings.dungeonFlashDuration and settings.dungeonFlashDuration > 0) and settings.dungeonFlashDuration or nil
            DetaurBar.Alerts.StartDungeonFlash("lfg", settings.dungeonFlashColor or "YELLOW", duration)
        end

    elseif event == "LFG_PROPOSAL_HIDE"
        or event == "LFG_PROPOSAL_CLOSE"
        or event == "LFG_PROPOSAL_FAILED"
        or event == "LFG_PROPOSAL_SUCCEEDED"
        or event == "LFG_PROPOSAL_COMPLETE" then
        if DetaurBar.Alerts and DetaurBar.Alerts.StopDungeonFlash then
            DetaurBar.Alerts.StopDungeonFlash("lfg")
        end

    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        if DetaurBar.Alerts and DetaurBar.Alerts.ResetAlertState then
            DetaurBar.Alerts.ResetAlertState()
        end

    elseif event == "AUCTION_ITEM_LIST_UPDATE" then
        if DetaurBar.AHScan and DetaurBar.AHScan.OnResults then
            DetaurBar.AHScan.OnResults()
        end

    elseif event == "LOOT_OPENED" then
        DetaurBar.Core.OnLootOpened()

    elseif event == "BAG_UPDATE" then
        DetaurBar.Core.OnBagUpdate()

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool = ...
        if eventType == "SPELL_AURA_APPLIED" and spellName and spellName:find("Mind Control") then
            local settings = GetSettingsTable()
            if settings.mindControlAlertEnabled and destName and destName ~= UnitName("player") then
                -- Check if it's a player (not NPC) via GUID prefix
                if destGUID and destGUID:find("^Player%-") then
                    -- Check if they're in our party/raid by iterating
                    local inGroup = false
                    if GetNumRaidMembers() > 0 then
                        for i = 1, GetNumRaidMembers() do
                            local name = GetRaidRosterInfo(i)
                            if name == destName then inGroup = true; break end
                        end
                    else
                        for i = 1, GetNumPartyMembers() do
                            local name = UnitName("party" .. i)
                            if name == destName then inGroup = true; break end
                        end
                    end
                    if inGroup and DetaurBar.Core.ShowMindControlAlert then
                        DetaurBar.Core.ShowMindControlAlert(destName)
                    end
                end
            end
        end

    elseif event == "MERCHANT_SHOW" then
        local settings = GetSettingsTable()
        if settings.autoSellRepairEnabled then
            DetaurBar.Core.AutoSellAndRepair()
        end

    -- Dismount handled via PreClick hook (HookActionButtons)
    end
end)

-- ============================================
--  MIND CONTROL ALERT
-- ============================================
local mcAlertFrame = CreateFrame("Frame", nil, UIParent)
mcAlertFrame:SetSize(500, 80)
mcAlertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
mcAlertFrame:Hide()
mcAlertFrame:SetFrameStrata("DIALOG")
local mcAlertText = mcAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mcAlertText:SetPoint("CENTER", mcAlertFrame, "CENTER", 0, 0)
mcAlertText:SetTextColor(1.0, 0.1, 0.1, 1.0)
mcAlertText:SetJustifyH("CENTER")
mcAlertText:SetFont("Fonts\\FRIZQT___CYR.ttf", 28, "OUTLINE")

local mcAlertAnimation
function DetaurBar.Core.ShowMindControlAlert(destName)
    mcAlertText:SetText(destName .. " has Mind Control!")
    mcAlertFrame:Show()
    mcAlertFrame:SetAlpha(1.0)
    if mcAlertAnimation then
        mcAlertAnimation:Hide()
        mcAlertAnimation:SetScript("OnUpdate", nil)
    end
    mcAlertAnimation = CreateFrame("Frame")
    local elapsed = 0
    mcAlertAnimation:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + (e or 0)
        if elapsed < 4 then
            mcAlertFrame:SetAlpha(math.max(0, 1 - (elapsed - 1) / 3))
        else
            mcAlertFrame:Hide()
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-- ============================================
--  AUTO SELL JUNK + AUTO REPAIR
-- ============================================
function DetaurBar.Core.AutoSellAndRepair()
    -- Sell all grey items
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local _, _, quality = GetItemInfo(link)
                if quality ~= nil and quality == 0 then
                    UseContainerItem(bag, slot)
                end
            end
        end
    end
    -- Repair all items
    if CanMerchantRepair() then
        RepairAllItems()
    end
end

-- ============================================
--  DISMOUNT ON ACTION
-- ============================================
local lastDismountTime = 0
function DetaurBar.Core.TryDismount()
    local settings = GetSettingsTable()
    if not settings.dismountOnActionEnabled or not IsMounted() then
        return
    end
    local now = GetTime()
    if now - lastDismountTime < 1 then
        return
    end
    lastDismountTime = now
    Dismount()
end

local function GetActionSlot(button)
    local name = button:GetName()
    if not name then return end
    local num = name:match("^ActionButton(%d+)$")
    if num then return tonumber(num) end
    num = name:match("^MultiBarBottomLeftButton(%d+)$")
    if num then return 12 + tonumber(num) end
    num = name:match("^MultiBarBottomRightButton(%d+)$")
    if num then return 24 + tonumber(num) end
    num = name:match("^MultiBarRightButton(%d+)$")
    if num then return 36 + tonumber(num) end
    num = name:match("^MultiBarLeftButton(%d+)$")
    if num then return 48 + tonumber(num) end
end

local function IsEquippableAction(slot)
    if not slot then return false end
    local actionType, id = GetActionInfo(slot)
    if actionType ~= "item" or not id then return false end
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(id)
    return equipLoc and equipLoc ~= ""
end

local function HookActionButton(button)
    if button and not button.DetaurBarHooked then
        local slot = GetActionSlot(button)
        button:HookScript("PreClick", function()
            if IsEquippableAction(slot) then
                return
            end
            DetaurBar.Core.TryDismount()
        end)
        button.DetaurBarHooked = true
    end
end

function DetaurBar.Core.HookActionButtons()
    for i = 1, 12 do
        HookActionButton(_G["ActionButton" .. i])
        HookActionButton(_G["MultiBarBottomLeftButton" .. i])
        HookActionButton(_G["MultiBarBottomRightButton" .. i])
        HookActionButton(_G["MultiBarRightButton" .. i])
        HookActionButton(_G["MultiBarLeftButton" .. i])
    end
    for i = 1, 10 do
        HookActionButton(_G["PetActionButton" .. i])
        HookActionButton(_G["StanceButton" .. i])
    end
    HookActionButton(_G["ExtraActionButton1"])
end

-- Route keybinds through action buttons so PreClick fires (taint-safe)
local bindingOwner = CreateFrame("Frame", "DetaurBarBindingOwner")
bindingOwner:Hide()

local function OverrideActionBinding(actionName, buttonName)
    local k1, k2 = GetBindingKey(actionName)
    if k1 and k1 ~= "" then
        SetOverrideBindingClick(bindingOwner, false, k1, buttonName, "LeftButton")
    end
    if k2 and k2 ~= "" then
        SetOverrideBindingClick(bindingOwner, false, k2, buttonName, "LeftButton")
    end
end

function DetaurBar.Core.SetupOverrideBindings()
    ClearOverrideBindings(bindingOwner)
    for i = 1, 12 do
        OverrideActionBinding("ACTIONBUTTON" .. i, "ActionButton" .. i)
        OverrideActionBinding("MULTIACTIONBAR1BUTTON" .. i, "MultiBarBottomLeftButton" .. i)
        OverrideActionBinding("MULTIACTIONBAR2BUTTON" .. i, "MultiBarBottomRightButton" .. i)
        OverrideActionBinding("MULTIACTIONBAR3BUTTON" .. i, "MultiBarRightButton" .. i)
        OverrideActionBinding("MULTIACTIONBAR4BUTTON" .. i, "MultiBarLeftButton" .. i)
    end
    for i = 1, 10 do
        OverrideActionBinding("BONUSACTIONBUTTON" .. i, "PetActionButton" .. i)
        OverrideActionBinding("STANCEBUTTON" .. i, "StanceButton" .. i)
    end
    OverrideActionBinding("EXTRAACTIONBUTTON1", "ExtraActionButton1")
end

function DetaurBar.Core.UpdateAutoLootCVar()
    local addItems = DetaurBar.Data.GetItems("loot_add")
    if #addItems > 0 then
        SetCVar("autoLootDefault", "0")
    else
        SetCVar("autoLootDefault", "1")
    end
end

function DetaurBar.Core.OnLootOpened()
    local addItems = DetaurBar.Data.GetItems("loot_add")
    if not addItems or #addItems == 0 then return end

    local addSet = {}
    for _, entry in ipairs(addItems) do
        local id = tonumber(entry.title:match("item:(%d+)"))
                or tonumber(entry.title:match("^%d+$") and entry.title)
        if id then addSet[id] = true end
    end

    local numSlots = GetNumLootItems()
    for i = numSlots, 1, -1 do
        local link = GetLootSlotLink(i)
        if not link then
            LootSlot(i)
        else
            local slotId = tonumber(link:match("item:(%d+)"))
            if slotId and addSet[slotId] then
                LootSlot(i)
            end
        end
    end
end

local isDeleting = false
function DetaurBar.Core.OnBagUpdate()
    if isDeleting then return end

    local deleteItems    = DetaurBar.Data.GetItems("loot_delete")
    local deleteAllGrays = DetaurBarDB and DetaurBarDB.loot and DetaurBarDB.loot.deleteAllGrays

    if #deleteItems == 0 and not deleteAllGrays then return end

    local deleteSet = {}
    for _, entry in ipairs(deleteItems) do
        local id = tonumber(entry.title:match("item:(%d+)"))
                or tonumber(entry.title:match("^%d+$") and entry.title)
        if id then deleteSet[id] = true end
    end

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemId = tonumber(link:match("item:(%d+)"))
                local shouldDelete = false

                if itemId and deleteSet[itemId] then
                    shouldDelete = true
                elseif deleteAllGrays then
                    local quality = select(3, GetItemInfo(link))
                    if quality == 0 then
                        shouldDelete = true
                    end
                end

                if shouldDelete then
                    isDeleting = true
                    PickupContainerItem(bag, slot)
                    DeleteCursorItem()
                    isDeleting = false
                    return
                end
            end
        end
    end
end

SLASH_DETAURBAR1 = "/todo"
SLASH_DETAURBAR2 = "/detaurbar"
SlashCmdList["DETAURBAR"] = function(msg)
    if DetaurBar and DetaurBar.UI and DetaurBar.UI.ToggleVisibility then
        DetaurBar.UI.ToggleVisibility()
    else
        print("|cffffff00DetaurBar:|r UI not yet initialized. Please wait a moment.")
    end
end

SLASH_DETAURENEMY1 = "/detaurenemy"
SlashCmdList["DETAURENEMY"] = function(msg)
    if DetaurBar and DetaurBar.Enemy and DetaurBar.Enemy.ToggleMonitor then
        DetaurBar.Enemy.ToggleMonitor()
    else
        print("|cffffff00DetaurBar:|r Enemy module not loaded.")
    end
end

SLASH_DETAURDEBUG1 = "/detaurdebug"
SlashCmdList["DETAURDEBUG"] = function(msg)
    DetaurBar.Data.InitializeDB()

    local activeTab, activeNotesSubTab, activeLootSubTab, activePriceItemSubTab, activePriceSubTab = nil, nil, nil, nil, nil
    if DetaurBar.UI and DetaurBar.UI.GetState then
        activeTab, activeNotesSubTab, activeLootSubTab, activePriceItemSubTab, activePriceSubTab = DetaurBar.UI.GetState()
    end

    local settings = GetSettingsTable()
    print("|cffffff00DetaurBar debug:|r tab=" .. tostring(activeTab)
        .. " tasks=" .. tostring(activeNotesSubTab)
        .. " buy=" .. tostring(activeLootSubTab)
        .. " priceItems=" .. tostring(activePriceItemSubTab)
        .. " priceGraph=" .. tostring(activePriceSubTab))
    print("|cffffff00Settings:|r dungeonFlash=" .. tostring(settings.dungeonFlashEnabled)
        .. " color=" .. tostring(settings.dungeonFlashColor)
        .. " ahScanInterval=" .. tostring(settings.ahScanInterval) .. "m"
        .. " wgAlerts=" .. tostring(settings.wgAlertsEnabled)
        .. " wg1=" .. tostring(settings.wgAlert1Minutes) .. "m/"
        .. tostring(settings.wgAlert1Duration) .. "s/"
        .. tostring(settings.wgAlert1Color)
        .. " wg2=" .. tostring(settings.wgAlert2Minutes) .. "m/"
        .. tostring(settings.wgAlert2PlaySound)
        .. "/" .. tostring(settings.wgAlert2Sound))
end

SLASH_DETAURMIGRATE1 = "/detaurmigrate"
SlashCmdList["DETAURMIGRATE"] = function(msg)
    if not DetaurBarDB or not DetaurBarDB.priceHistory then
        print("|cffff0000DetaurBar:|r No price history found")
        return
    end

    local faction = UnitFactionGroup("player") or "Unknown"
    local migrated = 0

    for oldKey, history in pairs(DetaurBarDB.priceHistory) do
        local oldKeyStr = tostring(oldKey)
        if not oldKeyStr:find(":") then
            local newKey = oldKeyStr .. ":" .. faction
            local itemId = tonumber(oldKeyStr)
            local itemName = ""
            if itemId then
                local name = GetItemInfo(itemId)
                if name then itemName = " (" .. name .. ")" end
            end
            if DetaurBarDB.priceHistory[newKey] then
                local merged = 0
                for ts, price in pairs(history) do
                    if not DetaurBarDB.priceHistory[newKey][ts] then
                        DetaurBarDB.priceHistory[newKey][ts] = price
                        merged = merged + 1
                    end
                end
                print("|cffffff00Merged|r " .. merged .. " points for " .. oldKeyStr .. itemName .. " -> " .. newKey)
            else
                DetaurBarDB.priceHistory[newKey] = history
                DetaurBarDB.priceHistory[oldKey] = nil
                local count = 0
                for _ in pairs(history) do count = count + 1 end
                print("|cff00ff00Moved|r " .. oldKeyStr .. itemName .. " -> " .. newKey .. " (" .. count .. " points)")
            end
            migrated = migrated + 1
        end
    end

    if migrated > 0 then
        print("|cffffff00DetaurBar:|r Migration complete! " .. migrated .. " items moved to " .. faction .. " keys. Reload with /reload")
    else
        print("|cffffff00DetaurBar:|r Nothing to migrate (all items already faction-specific)")
    end
end

SLASH_DETAURRESTORE1 = "/detaurrestore"
SlashCmdList["DETAURRESTORE"] = function(msg)
    if not DetaurBarDB or not DetaurBarDB.price then
        print("|cffff0000DetaurBar:|r No price data found")
        return
    end
    local faction = UnitFactionGroup("player") or "Horde"
    if not DetaurBarDB.price[faction] then
        DetaurBarDB.price[faction] = {}
    end

    -- Items from backup (1.7.2026) with their thresholds
    -- Skipping 36908 (old Frost Lotus ID) — already present as 36902
    local restoreItems = {
        { id = 13467, threshold = 9 },
        { id = 34736, threshold = 2 },
        { id = 34754, threshold = 3 },
        { id = 35625, threshold = 13 },
        { id = 36919, threshold = 130 },
        { id = 36922, threshold = 120 },
        { id = 36925, threshold = 60 },
        { id = 36931, threshold = 100 },
        { id = 37702, threshold = 3 },
        { id = 3928 },
        { id = 40211, threshold = 30 },
        { id = 43005 },
        { id = 43007, threshold = 2 },
        { id = 43297, threshold = 150 },
        { id = 4637 },
        { id = 49633, threshold = 150 },
        { id = 8483 },
        { id = 8845, threshold = 2 },
    }

    -- Check which already exist
    local existingTitles = {}
    for _, item in ipairs(DetaurBarDB.price[faction]) do
        if item.title then
            local itemId = tonumber(item.title:match("item:(%d+)"))
            if itemId then existingTitles[itemId] = true end
        end
    end

    local added = 0
    for _, item in ipairs(restoreItems) do
        if not existingTitles[item.id] then
            local entry = {
                id = time() .. "_" .. tostring(math.random(1000, 9999)),
                title = "item:" .. item.id,
                completed = false,
                created = time(),
            }
            if item.threshold then
                entry.threshold = item.threshold
            end
            table.insert(DetaurBarDB.price[faction], entry)
            added = added + 1
        end
    end

    if added > 0 then
        print("|cff00ff00DetaurBar:|r Obnovenych " .. added .. " poloziek zo zalohy!")
        if DetaurBar and DetaurBar.UI and DetaurBar.UI.RefreshTasks then
            DetaurBar.UI.RefreshTasks()
        end
    else
        print("|cffffff00DetaurBar:|r Vsetky polozky uz su v cenniku")
    end
end

SLASH_DETAURRECOVER1 = "/detaurrecover"
SlashCmdList["DETAURRECOVER"] = function(msg)
    if not DetaurBarDB or not DetaurBarDB.price then
        print("|cffff0000DetaurBar:|r No price data found")
        return
    end
    local found = 0
    local items = {}
    local i = 1
    while type(DetaurBarDB.price[i]) == "table" do
        table.insert(items, DetaurBarDB.price[i])
        DetaurBarDB.price[i] = nil
        i = i + 1
    end
    for k in pairs(DetaurBarDB.price) do
        if type(k) ~= "string" then
            DetaurBarDB.price[k] = nil
        end
    end
    local faction = UnitFactionGroup("player") or "Horde"
    if not DetaurBarDB.price[faction] then
        DetaurBarDB.price[faction] = {}
    end
    for _, item in ipairs(items) do
        table.insert(DetaurBarDB.price[faction], item)
        found = found + 1
    end
    if found > 0 then
        print("|cff00ff00DetaurBar:|r Obnovenych " .. found .. " poloziek z cenniku!")
        if DetaurBar and DetaurBar.UI and DetaurBar.UI.RefreshTasks then
            DetaurBar.UI.RefreshTasks()
        end
    else
        print("|cffffff00DetaurBar:|r Vsetko je uz v poriadku, ziadne polozky neboli stratene")
    end
end

SLASH_DETAURFIXHERBS1 = "/detaurfixherbs"
SlashCmdList["DETAURFIXHERBS"] = function(msg)
    if not DetaurBarDB or not DetaurBarDB.price then
        print("|cffff0000DetaurBar:|r No price data found")
        return
    end
    local herbIdFix = {
        [36902] = 36908,  -- frost lotus
        [36903] = 39970,  -- fire leaf
        [36905] = 36903,  -- adder's tongue
        [36906] = 36905,  -- lichbloom
        [36908] = 36906,  -- icethorn
    }
    local totalFixed = 0
    local function fixItem(item)
        if not item.title then return end
        local itemIdNum = tonumber(string.match(item.title, "^item:(%d+)$"))
        if itemIdNum and herbIdFix[itemIdNum] then
            item.title = "item:" .. herbIdFix[itemIdNum]
            totalFixed = totalFixed + 1
            return
        end
        local linkName = string.match(item.title, "%|h%[(.-)%]%|h")
        if linkName and DetaurBar.Data.ItemDatabase then
            local cleaned = string.lower(linkName)
            local correctId = DetaurBar.Data.ItemDatabase[cleaned]
            if correctId then
                local newTitle = string.gsub(item.title, "|Hitem:(%d+)", "|Hitem:" .. correctId)
                if newTitle ~= item.title then
                    item.title = newTitle
                    totalFixed = totalFixed + 1
                end
            end
        end
    end
    local function fixList(list)
        if list and type(list) == "table" then
            for _, item in ipairs(list) do
                fixItem(item)
            end
        end
    end
    fixList(DetaurBarDB.price)
    fixList(DetaurBarDB.sell)
    if DetaurBarDB.loot and type(DetaurBarDB.loot) == "table" then
        fixList(DetaurBarDB.loot.add)
        fixList(DetaurBarDB.loot.delete)
        fixList(DetaurBarDB.loot.refuse)
    end
    -- Fix tasks/notes categories that may contain item links
    if DetaurBarDB.tasks and DetaurBarDB.tasks.data then
        for _, catName in ipairs(DetaurBarDB.tasks.categories) do
            fixList(DetaurBarDB.tasks.data[catName])
        end
    end
    if DetaurBarDB.notes and DetaurBarDB.notes.data then
        for _, catName in ipairs(DetaurBarDB.notes.categories) do
            fixList(DetaurBarDB.notes.data[catName])
        end
    end
    print("|cff00ff00DetaurBar:|r Opravenych " .. totalFixed .. " northrend byliniek!")
    if DetaurBar and DetaurBar.UI and DetaurBar.UI.RefreshTasks then
        DetaurBar.UI.RefreshTasks()
    end
end

-- REMOVED: /detaurfixherbs (was dangerous — deleted records instead of fixing them)
