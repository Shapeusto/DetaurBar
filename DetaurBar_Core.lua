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
        self:UnregisterEvent("PLAYER_LOGIN")

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
    end
end)

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

    local activeTab, activeTodoSubTab, activeNotesSubTab, activeLootSubTab, activePriceItemSubTab, activePriceSubTab = nil, nil, nil, nil, nil, nil
    if DetaurBar.UI and DetaurBar.UI.GetState then
        activeTab, activeTodoSubTab, activeNotesSubTab, activeLootSubTab, activePriceItemSubTab, activePriceSubTab = DetaurBar.UI.GetState()
    end

    local settings = GetSettingsTable()
    print("|cffffff00DetaurBar debug:|r tab=" .. tostring(activeTab)
        .. " todo=" .. tostring(activeTodoSubTab)
        .. " notes=" .. tostring(activeNotesSubTab)
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
