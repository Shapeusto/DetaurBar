-- DetaurBar_AHScan.lua
-- Auction House price scanning with progress bar and threshold checking.

DetaurBar = DetaurBar or {}
DetaurBar.AHScan = {}

local scanQueue = {}
local scanTotal = 0
local scanCurrentItemId = nil
local scanCurrentName = nil
local lastScanTime = 0

local function GetSettingsTable()
    if DetaurBar.Data and DetaurBar.Data.GetSettings then
        return DetaurBar.Data.GetSettings()
    end
    return DetaurBarDB and DetaurBarDB.settings or {}
end

local function GetAHScanIntervalSeconds()
    local settings = GetSettingsTable()
    local intervalMinutes = tonumber(settings.ahScanInterval) or 10
    if intervalMinutes < 1 then
        intervalMinutes = 1
    end
    return intervalMinutes * 60
end

-- Progress bar
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
scanStatusLabel:SetText("DetaurBar: Scanning...")

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
    scanStatusLabel:SetText(string.format("DetaurBar: %d/%d  %s", done, scanTotal, name))
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

local scanQueryTime = 0
local QUERY_TIMEOUT = 5

-- Hidden scan frame with OnUpdate driver
local scanFrame = CreateFrame("Frame")
scanFrame:Hide()
scanFrame:SetScript("OnUpdate", function(self)
    if not AuctionFrame or not AuctionFrame:IsShown() then
        scanQueue = {}
        scanCurrentItemId = nil
        HideScanStatus()
        self:Hide()
        return
    end
    if scanCurrentItemId then
        if GetTime() - scanQueryTime > QUERY_TIMEOUT then
            scanCurrentItemId = nil
            UpdateScanProgress()
        end
        return
    end
    if #scanQueue == 0 then
        lastScanTime = time()
        HideScanStatus()
        if DetaurBarFrame and DetaurBarFrame:IsShown() then
            DetaurBar.UI.RefreshTasks()
        end
        self:Hide()
        return
    end
    if not CanSendAuctionQuery() then return end
    if AucAdvanced and AucAdvanced.Scan and AucAdvanced.Scan.IsScanning and AucAdvanced.Scan.IsScanning() then return end

    scanCurrentItemId = table.remove(scanQueue, 1)
    scanCurrentName = DetaurBar.Data.GetItemName(scanCurrentItemId) or ("ID:" .. scanCurrentItemId)
    scanQueryTime = GetTime()
    UpdateScanProgress()
    QueryAuctionItems(scanCurrentName, nil, nil, 0, 0, 0, 0, false, 0)
end)

function DetaurBar.AHScan.StartScan()
    if (time() - lastScanTime) < GetAHScanIntervalSeconds() then return end
    local priceItems = DetaurBar.Data.GetItems("price")
    scanQueue = {}
    scanCurrentItemId = nil
    scanCurrentName = nil
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

function DetaurBar.AHScan.OnResults()
    if not scanCurrentItemId then return end

    local numOnPage = GetNumAuctionItems("list")
    if numOnPage == 0 then
        if GetTime() - scanQueryTime > 1 then
            scanCurrentItemId = nil
            UpdateScanProgress()
        end
        return
    end

    local minBuyout = nil
    for i = 1, numOnPage do
        local _, _, count, _, _, _, _, _, buyout = GetAuctionItemInfo("list", i)
        if buyout and buyout > 0 and count and count > 0 then
            local link = GetAuctionItemLink("list", i)
            local linkId = link and tonumber(link:match("item:(%d+)"))
            if linkId == scanCurrentItemId then
                local perItem = math.floor(buyout / count)
                if not minBuyout or perItem < minBuyout then
                    minBuyout = perItem
                end
            end
        end
    end

    if minBuyout and minBuyout > 0 then
        DetaurBar.Data.SavePricePoint(scanCurrentItemId, minBuyout)

        local priceItems = DetaurBar.Data.GetItems("price")
        for _, item in ipairs(priceItems) do
            local itemId = tonumber(item.title:match("item:(%d+)"))
                        or tonumber(item.title:match("^%d+$") and item.title)
            if itemId == scanCurrentItemId and item.threshold and item.threshold > 0 then
                local thresholdCopper = item.threshold * 10000
                if minBuyout <= thresholdCopper then
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
            if itemId == scanCurrentItemId and item.thresholdHigh and item.thresholdHigh > 0 then
                local thresholdHighCopper = item.thresholdHigh * 10000
                if minBuyout >= thresholdHighCopper then
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
    scanCurrentItemId = nil
    UpdateScanProgress()
end
