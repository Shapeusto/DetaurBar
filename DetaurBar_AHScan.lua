-- DetaurBar_AHScan.lua
-- Auction House price scanning with pagination support.

-- State machine overview:
--
-- OnUpdate driver (scanFrame) is the ONLY place that calls QueryAuctionItems.
-- OnResults callback only reads results and sets state flags.
--
-- Per-item lifecycle:
--   1. OnUpdate picks item from queue, queries page 0, clears needsNextPage
--   2. OnUpdate guards: CanSendAuctionQuery() + AucAdvanced not scanning
--   3. AUCTION_ITEM_LIST_UPDATE -> OnResults reads page i
--   4. OnResults: if item found (minBuyout) --> saves, sets itemComplete
--   5. OnResults: if NOT found, page full, pages left --> sets needsNextPage
--   6. OnResults: if NOT found, not full page or no pages left --> sets itemComplete
--   7. OnUpdate sees itemComplete -> clears scanCurrentItemId -> picks next item
--
-- Timeout: if a page query doesn't arrive in QUERY_TIMEOUT sec,
--          OnUpdate nullifies scanCurrentItemId as a timeout failure.

DetaurBar = DetaurBar or {}
DetaurBar.AHScan = {}

-- Queue of item IDs to scan
local scanQueue = {}
local scanTotal = 0

-- Current item state
local scanCurrentItemId = nil
local scanCurrentName = nil
local scanCurrentPage = 0

-- Flags set by OnResults, consumed by OnUpdate
local scanNeedsNextPage = false
local scanItemComplete = false
local scanItemFound = false

-- Timing
local scanQueryTime = 0
local QUERY_TIMEOUT = 5
local lastScanTime = 0
local MAX_PAGES = 10

--------------------------------------------------------------------------------
-- Settings helpers
--------------------------------------------------------------------------------

local function GetSettingsTable()
    if DetaurBar.Data and DetaurBar.Data.GetSettings then
        return DetaurBar.Data.GetSettings()
    end
    return DetaurBarDB and DetaurBarDB.settings or {}
end

local function GetAHScanIntervalSeconds()
    local settings = GetSettingsTable()
    local intervalMinutes = tonumber(settings.ahScanInterval) or 10
    if intervalMinutes < 1 then intervalMinutes = 1 end
    return intervalMinutes * 60
end

--------------------------------------------------------------------------------
-- Progress bar
--------------------------------------------------------------------------------

local scanStatusFrame = CreateFrame("Frame", "DetaurBarScanStatus", UIParent)
scanStatusFrame:SetSize(220, 36)
scanStatusFrame:SetFrameStrata("DIALOG")
scanStatusFrame:Hide()
scanStatusFrame:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left=3, right=3, top=3, bottom=3 }
})
scanStatusFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.92)
scanStatusFrame:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.9)

local scanStatusLabel = scanStatusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
scanStatusLabel:SetPoint("TOPLEFT", scanStatusFrame, "TOPLEFT", 8, -6)

local scanBarBg = scanStatusFrame:CreateTexture(nil, "BACKGROUND")
scanBarBg:SetPoint("BOTTOMLEFT", scanStatusFrame, "BOTTOMLEFT", 8, 6)
scanBarBg:SetPoint("BOTTOMRIGHT", scanStatusFrame, "BOTTOMRIGHT", -8, 6)
scanBarBg:SetHeight(6)
scanBarBg:SetTexture(0.2, 0.2, 0.2, 1)

local scanBarFill = scanStatusFrame:CreateTexture(nil, "ARTWORK")
scanBarFill:SetPoint("BOTTOMLEFT", scanBarBg, "BOTTOMLEFT", 0, 0)
scanBarFill:SetHeight(6)
scanBarFill:SetTexture(1.0, 0.82, 0.0, 1)
scanBarFill:SetWidth(1)

local function UpdateScanProgress()
    if scanTotal == 0 then return end
    local done = scanTotal - #scanQueue - (scanCurrentItemId and 1 or 0)
    local pct = done / scanTotal
    local maxW = scanBarBg:GetWidth()
    if maxW and maxW > 0 then
        scanBarFill:SetWidth(math.max(1, maxW * pct))
    end
    local name = scanCurrentName or "..."
    local pageInfo = ""
    if scanCurrentItemId and scanCurrentPage > 0 then
        pageInfo = " (page " .. (scanCurrentPage + 1) .. ")"
    end
    scanStatusLabel:SetText(string.format("DetaurBar: %d/%d  %s%s", done, scanTotal, name, pageInfo))
end

local function ShowScanStatus()
    scanStatusFrame:ClearAllPoints()
    if AuctionFrame and AuctionFrame:IsShown() then
        scanStatusFrame:SetPoint("TOP", AuctionFrame, "BOTTOM", 0, -4)
    else
        scanStatusFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    end
    scanStatusFrame:Show()
end

local function HideScanStatus()
    scanStatusFrame:Hide()
end

--------------------------------------------------------------------------------
-- Threshold checking
--------------------------------------------------------------------------------

local function CheckThresholds(itemId, minBuyout)
    if not minBuyout or minBuyout <= 0 then return end
    local priceItems = DetaurBar.Data.GetItems("price")
    for _, item in ipairs(priceItems) do
        local iid = tonumber(item.title:match("item:(%d+)"))
                    or tonumber(item.title:match("^%d+$") and item.title)
        if iid == itemId then
            if item.threshold and item.threshold > 0 then
                local t = item.threshold * 10000
                if minBuyout <= t then
                    if not item.frequent then
                        item.frequent = true
                        print("|cffffff00DetaurBar:|r " .. (item.title or "Item") .. " dropped below " .. item.threshold .. "g threshold! Added to Notifications.")
                    end
                else
                    if item.frequent then
                        item.frequent = nil
                        print("|cffffff00DetaurBar:|r " .. (item.title or "Item") .. " rose above " .. item.threshold .. "g threshold! Removed from Notifications.")
                    end
                end
            end
            if item.thresholdHigh and item.thresholdHigh > 0 then
                local th = item.thresholdHigh * 10000
                if minBuyout >= th then
                    if not item.frequentHigh then
                        item.frequentHigh = true
                        print("|cffffff00DetaurBar:|r " .. (item.title or "Item") .. " rose above " .. item.thresholdHigh .. "g threshold! Added to Notifications.")
                    end
                else
                    if item.frequentHigh then
                        item.frequentHigh = nil
                        print("|cffffff00DetaurBar:|r " .. (item.title or "Item") .. " dropped below " .. item.thresholdHigh .. "g threshold! Removed from Notifications.")
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- ClearStaleThresholds — called when item was NOT found on AH at all
-- (bought out / beyond MAX_PAGES range). Clears only 'frequent' (low alert).
-- 'frequentHigh' must NOT be affected, because "not found" is not proof of high price.
--------------------------------------------------------------------------------

local function ClearStaleThresholds(itemId)
    if not itemId then return end
    local priceItems = DetaurBar.Data.GetItems("price")
    for _, item in ipairs(priceItems) do
        local iid = tonumber(item.title:match("item:(%d+)"))
                    or tonumber(item.title:match("^%d+$") and item.title)
        if iid == itemId then
            if item.frequent then
                item.frequent = nil
                print("|cffffff00DetaurBar:|r " .. (item.title or "Item") .. " - not found on AH (probably bought out). Removed from Notifications.")
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Query page 0 for a new item
-- Called ONLY from OnUpdate when guards pass and no item is active.
--------------------------------------------------------------------------------

local function StartItemQuery(itemId)
    scanCurrentItemId = itemId
    scanCurrentName = DetaurBar.Data.GetItemName(itemId) or ("ID:" .. itemId)
    scanCurrentPage = 0
    scanNeedsNextPage = false
    scanItemComplete = false
    scanItemFound = false
    scanQueryTime = GetTime()
    UpdateScanProgress()
    -- signature: QueryAuctionItems(name, minLvl, maxLvl, invType, class, subclass, page, usable, quality, getAll)
    QueryAuctionItems(scanCurrentName, nil, nil, 0, 0, 0, scanCurrentPage, false, 0)
end

--------------------------------------------------------------------------------
-- Query a subsequent page for the current item
-- Called ONLY from OnUpdate when guards pass and needsNextPage is true.
--------------------------------------------------------------------------------

local function QueryNextPage()
    scanNeedsNextPage = false
    scanQueryTime = GetTime()
    UpdateScanProgress()
    -- signature: QueryAuctionItems(name, minLvl, maxLvl, invType, class, subclass, page, usable, quality, getAll)
    QueryAuctionItems(scanCurrentName, nil, nil, 0, 0, 0, scanCurrentPage, false, 0)
end

--------------------------------------------------------------------------------
-- Advance to the next item in the queue
-- Called from OnUpdate when scanItemComplete or timeout fires.
--------------------------------------------------------------------------------

local function AdvanceToNextItem()
    if scanCurrentItemId and not scanItemFound then
        ClearStaleThresholds(scanCurrentItemId)
    end
    scanCurrentItemId = nil
    scanCurrentName = nil
    scanCurrentPage = 0
    scanNeedsNextPage = false
    scanItemComplete = false
    scanItemFound = false
    UpdateScanProgress()
    if DetaurBarFrame and DetaurBarFrame:IsShown() then
        DetaurBar.UI.RefreshTasks()
    end
end

--------------------------------------------------------------------------------
-- OnUpdate driver — the ONLY code that calls QueryAuctionItems.
-- Also handles timeouts and item advancement.
--------------------------------------------------------------------------------

local scanFrame = CreateFrame("Frame")
scanFrame:Hide()
scanFrame:SetScript("OnUpdate", function(self)
    -- AH closed → abort everything, reset timer so next open triggers fresh scan
    if not AuctionFrame or not AuctionFrame:IsShown() then
        if scanCurrentItemId and not scanItemFound then
            ClearStaleThresholds(scanCurrentItemId)
        end
        scanQueue = {}
        scanCurrentItemId = nil
        lastScanTime = 0
        HideScanStatus()
        self:Hide()
        return
    end

    -- Guards that apply to ALL queries (first page + subsequent pages)
    local canQuery = CanSendAuctionQuery()
    local isAuctioneerScanning = AucAdvanced and AucAdvanced.Scan
                                and AucAdvanced.Scan.IsScanning
                                and AucAdvanced.Scan.IsScanning()
    if not canQuery or isAuctioneerScanning then
        return
    end

    -- Check timeout for current item/page
    if scanCurrentItemId then
        if GetTime() - scanQueryTime > QUERY_TIMEOUT then
            AdvanceToNextItem()
            return
        end
        if scanItemComplete then
            AdvanceToNextItem()
            return
        end
        if scanNeedsNextPage then
            QueryNextPage()
            return
        end
        return  -- waiting for results
    end

    -- No current item — pick next from queue or finish
    if #scanQueue == 0 then
        lastScanTime = time()
        HideScanStatus()
        if DetaurBarFrame and DetaurBarFrame:IsShown() then
            DetaurBar.UI.RefreshTasks()
        end
        self:Hide()
        return
    end

    -- Start scanning the next item (page 0)
    local itemId = table.remove(scanQueue, 1)
    StartItemQuery(itemId)
end)

--------------------------------------------------------------------------------
-- StartScan — called when AH opens to kick off the scan
--------------------------------------------------------------------------------

function DetaurBar.AHScan.StartScan()
    local settings = DetaurBar.Data.GetSettings()
    if not settings.ahScanningEnabled then return end
    if (time() - lastScanTime) < GetAHScanIntervalSeconds() then return end
    local priceItems = DetaurBar.Data.GetItems("price")
    scanQueue = {}
    for _, item in ipairs(priceItems) do
        local itemId = tonumber(item.title:match("item:(%d+)"))
                    or tonumber(item.title:match("^%d+$") and item.title)
        if itemId then
            table.insert(scanQueue, itemId)
        end
    end
    scanTotal = #scanQueue
    if scanTotal > 0 then
        ShowScanStatus()
        UpdateScanProgress()
        scanFrame:Show()
    end
end

--------------------------------------------------------------------------------
-- OnResults — called from DetaurBar_Core on AUCTION_ITEM_LIST_UPDATE
-- Reads current page, saves price if found, sets state flags for OnUpdate.
-- NEVER calls QueryAuctionItems directly.
--------------------------------------------------------------------------------

function DetaurBar.AHScan.OnResults()
    if not scanCurrentItemId then return end
    if scanItemComplete then return end

    local numOnPage = GetNumAuctionItems("list")

    -- Empty page (still loading or Auctioneer interference)
    if numOnPage == 0 then
        if GetTime() - scanQueryTime > 1 then
            scanItemComplete = true
        end
        return
    end

    -- Scan items on this page for a match
    local minBuyout = nil
    local foundOnPage = false
    for i = 1, numOnPage do
        local _, _, count, _, _, _, _, _, buyout = GetAuctionItemInfo("list", i)
        if buyout and buyout > 0 and count and count > 0 then
            local link = GetAuctionItemLink("list", i)
            local linkId = link and tonumber(link:match("item:(%d+)"))
            if linkId == scanCurrentItemId then
                foundOnPage = true
                local perItem = math.floor(buyout / count)
                if not minBuyout or perItem < minBuyout then
                    minBuyout = perItem
                end
            end
        end
    end

    if minBuyout and minBuyout > 0 then
        -- SUCCESS: found our item with a buyout price
        scanItemFound = true
        DetaurBar.Data.SavePricePoint(scanCurrentItemId, minBuyout)
        CheckThresholds(scanCurrentItemId, minBuyout)
        scanItemComplete = true
        UpdateScanProgress()
        if DetaurBarFrame and DetaurBarFrame:IsShown() then
            DetaurBar.UI.RefreshTasks()
        end
        return
    end

    if foundOnPage then
        -- Found our item but no buyout (bid-only auctions). Done.
        scanItemComplete = true
        UpdateScanProgress()
        return
    end

    -- Item not found on this page.
    -- In WoW 3.3.5a, GetNumAuctionItems("list") returns only 1 value (page count, not total).
    -- Max items per page is 50. If page is full, more pages may exist.
    if numOnPage >= 50 and scanCurrentPage + 1 < MAX_PAGES then
        scanCurrentPage = scanCurrentPage + 1
        scanNeedsNextPage = true
    else
        scanItemComplete = true
    end
    UpdateScanProgress()
end
