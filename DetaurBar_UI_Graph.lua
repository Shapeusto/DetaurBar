-- DetaurBar_UI_Graph.lua
-- Price graph drawing utilities (FormatMoney, ClearGraphObjects, DrawPriceGraph)

DetaurBar = DetaurBar or {}
DetaurBar.UI = DetaurBar.UI or {}

-- Custom confirmation frame for deleting price data points
local confirmFrame = CreateFrame("Frame", nil, UIParent)
confirmFrame:SetSize(250, 100)
confirmFrame:SetFrameStrata("FULLSCREEN_DIALOG")
confirmFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
confirmFrame:SetBackdropColor(0, 0, 0, 0.9)
confirmFrame:SetBackdropBorderColor(1, 1, 1, 0.8)
confirmFrame:Hide()
confirmFrame:SetScript("OnHide", function(self)
    self.pendingItemId = nil
    self.pendingTimestamp = nil
end)

local confirmText = confirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
confirmText:SetPoint("TOP", confirmFrame, "TOP", 0, -15)
confirmText:SetText("Delete this price data point?")

local confirmYes = CreateFrame("Button", nil, confirmFrame, "GameMenuButtonTemplate")
confirmYes:SetSize(80, 25)
confirmYes:SetPoint("BOTTOMLEFT", confirmFrame, "BOTTOMLEFT", 35, 25)
confirmYes:SetText("Yes")
confirmYes:SetScript("OnClick", function()
    if confirmFrame.pendingItemId and confirmFrame.pendingTimestamp then
        DetaurBar.Data.DeletePricePoint(confirmFrame.pendingItemId, confirmFrame.pendingTimestamp)
        confirmFrame.pendingItemId = nil
        confirmFrame.pendingTimestamp = nil
        confirmFrame:Hide()
        DetaurBar.UI.RefreshTasks()
    end
end)

local confirmNo = CreateFrame("Button", nil, confirmFrame, "GameMenuButtonTemplate")
confirmNo:SetSize(80, 25)
confirmNo:SetPoint("BOTTOMRIGHT", confirmFrame, "BOTTOMRIGHT", -35, 25)
confirmNo:SetText("No")
confirmNo:SetScript("OnClick", function()
    confirmFrame.pendingItemId = nil
    confirmFrame.pendingTimestamp = nil
    confirmFrame:Hide()
end)

-- [HELPERS] FormatMoney — converts copper to gold/silver/copper coin texture string
function DetaurBar.UI.FormatMoney(amount)
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local copper = amount % 100

    local str = ""
    if gold > 0 then
        str = str .. gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t "
    end
    if silver > 0 or gold > 0 then
        str = str .. silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "
    end
    str = str .. copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
    return str
end

-- [FORMAT] FormatGold — copper to compact "g s" string for graph labels
function DetaurBar.UI.FormatGold(copper)
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    if g > 0 then return g .. "g " .. s .. "s" end
    if s > 0 then return s .. "s " .. (copper % 100) .. "c" end
    return (copper % 100) .. "c"
end

-- [GRAPH HELPERS] ClearGraphObjects — hides all textures/labels/frames for a row graph
-- Keeps the object pool so the next redraw reuses them instead of re-creating (fast item switching).
function DetaurBar.UI.ClearGraphObjects(row)
    if row.graphTextures then
        for _, t in ipairs(row.graphTextures) do t:Hide() end
    end
    if row.graphLabels then
        for _, f in ipairs(row.graphLabels) do f:Hide() end
    end
    if row.graphFrames then
        for _, fr in ipairs(row.graphFrames) do fr:Hide() end
    end
end

-- [GRAPH HELPERS] GfTex — get (or create) a graph texture, reusing hidden ones from the pool
function DetaurBar.UI.GfTex(row, gf, layer)
    if row.graphTextures then
        for _, t in ipairs(row.graphTextures) do
            if not t:IsShown() then
                t:ClearAllPoints()
                t:SetDrawLayer(layer or "OVERLAY")
                return t
            end
        end
    end
    local t = gf:CreateTexture(nil, layer or "OVERLAY")
    t:SetDrawLayer(layer or "OVERLAY")
    table.insert(row.graphTextures, t)
    return t
end

-- [GRAPH HELPERS] GfLabel — get (or create) a graph label font string
function DetaurBar.UI.GfLabel(row, gf)
    if row.graphLabels then
        for _, f in ipairs(row.graphLabels) do
            if not f:IsShown() then
                f:ClearAllPoints()
                return f
            end
        end
    end
    local f = gf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    table.insert(row.graphLabels, f)
    return f
end

-- [GRAPH HELPERS] GfFrame — get (or create) a graph hover frame
function DetaurBar.UI.GfFrame(row, gf)
    if not row.graphFrames then
        row.graphFrames = {}
    end
    for _, f in ipairs(row.graphFrames) do
        if not f:IsShown() then
            f:ClearAllPoints()
            return f
        end
    end
    local f = CreateFrame("Button", nil, gf)
    f:Hide()
    table.insert(row.graphFrames, f)
    return f
end

-- [GRAPH HELPERS] DrawGfLine — dot-stepping line renderer (SetRotation doesn't work in 3.3.5a)
-- Only for diagonal lines; axis-aligned lines should use DrawGfHLine/DrawGfVLine.
function DetaurBar.UI.DrawGfLine(row, gf, x1, y1, x2, y2, thick, r, g, b, a)
    local dx, dy = x2 - x1, y2 - y1
    local steps = math.floor(math.max(math.abs(dx), math.abs(dy)))
    if steps < 1 then steps = 1 end
    local sx, sy = dx / steps, dy / steps
    for i = 0, steps do
        local t = DetaurBar.UI.GfTex(row, gf)
        t:SetTexture(r, g, b, a)
        t:SetSize(thick, thick)
        t:SetPoint("CENTER", gf, "BOTTOMLEFT", x1 + sx * i, y1 + sy * i)
        t:Show()
    end
end

-- [GRAPH HELPERS] DrawGfHLine — single-texture horizontal line (no dot-stepping)
function DetaurBar.UI.DrawGfHLine(row, gf, x1, x2, y, thick, r, g, b, a)
    local t = DetaurBar.UI.GfTex(row, gf)
    t:SetTexture(r, g, b, a)
    t:SetWidth(x2 - x1)
    t:SetHeight(thick)
    t:SetPoint("BOTTOMLEFT", gf, "BOTTOMLEFT", x1, y - thick / 2)
    t:Show()
end

-- [GRAPH HELPERS] DrawGfVLine — single-texture vertical line (no dot-stepping)
function DetaurBar.UI.DrawGfVLine(row, gf, x, y1, y2, thick, r, g, b, a)
    local t = DetaurBar.UI.GfTex(row, gf)
    t:SetTexture(r, g, b, a)
    t:SetWidth(thick)
    t:SetHeight(y2 - y1)
    t:SetPoint("BOTTOMLEFT", gf, "BOTTOMLEFT", x - thick / 2, y1)
    t:Show()
end

-- [GRAPH] DrawPriceGraph — renders full graph for a given itemId on the graph frame
function DetaurBar.UI.DrawPriceGraph(row, gf, itemId)
    DetaurBar.UI.ClearGraphObjects(row)

    local history = DetaurBar.Data.GetPriceHistory(itemId)
    local now = time()
    local cutoff
    do
        local activePriceSubTab = DetaurBar.UI.activePriceSubTab or "Daily"
        if activePriceSubTab == "Daily" then
            cutoff = now - 86400
        elseif activePriceSubTab == "Weekly" then
            cutoff = now - 7 * 86400
        elseif activePriceSubTab == "Monthly" then
            cutoff = now - 30 * 86400
        else
            cutoff = now - 365 * 86400
        end
    end

    local points = {}
    for tsStr, price in pairs(history) do
        local ts = tonumber(tsStr)
        if ts and ts >= cutoff then
            table.insert(points, { ts = ts, price = price })
        end
    end
    table.sort(points, function(a, b) return a.ts < b.ts end)

    local gw = gf:GetWidth()
    local gh = gf:GetHeight()
    local GRAPH_PAD_L = 46
    local GRAPH_PAD_R = 8
    local GRAPH_PAD_T = 8
    local GRAPH_PAD_B = 20
    local plotW = gw - GRAPH_PAD_L - GRAPH_PAD_R
    local plotH = gh - GRAPH_PAD_T - GRAPH_PAD_B

    -- background
    local bg = DetaurBar.UI.GfTex(row, gf, "BACKGROUND")
    bg:SetAllPoints(gf)
    bg:SetTexture(0, 0, 0, 0.5)
    bg:Show()

    -- axes (single textures, not dot-stepped)
    DetaurBar.UI.DrawGfVLine(row, gf, GRAPH_PAD_L, GRAPH_PAD_B, GRAPH_PAD_B + plotH, 1, 0.5, 0.5, 0.5, 1)
    DetaurBar.UI.DrawGfHLine(row, gf, GRAPH_PAD_L, GRAPH_PAD_L + plotW, GRAPH_PAD_B, 1, 0.5, 0.5, 0.5, 1)

    if #points == 0 then
        local lbl = DetaurBar.UI.GfLabel(row, gf)
        lbl:SetPoint("CENTER", gf, "CENTER", 0, 0)
        lbl:SetText("No data yet — open the Auction House to scan")
        lbl:SetTextColor(0.5, 0.5, 0.5, 1)
        lbl:Show()
        return
    end

    local minP, maxP = points[1].price, points[1].price
    local minTs, maxTs = points[1].ts, points[#points].ts
    for _, p in ipairs(points) do
        if p.price < minP then minP = p.price end
        if p.price > maxP then maxP = p.price end
    end
    local pRange = maxP - minP
    if pRange == 0 then pRange = math.max(maxP * 0.1, 1) end
    local dMin = math.max(0, minP - pRange * 0.1)
    local dMax = maxP + pRange * 0.1
    local dRange = dMax - dMin
    local tsRange = math.max(maxTs - minTs, 1)

    local function toX(ts)
        if maxTs == minTs then return GRAPH_PAD_L + plotW / 2 end
        return GRAPH_PAD_L + (ts - minTs) / tsRange * plotW
    end
    local function toY(price)
        return GRAPH_PAD_B + (price - dMin) / dRange * plotH
    end

    -- Y axis labels (top, mid, bottom)
    for i = 0, 2 do
        local price = dMin + dRange * i / 2
        local y = GRAPH_PAD_B + plotH * i / 2
        DetaurBar.UI.DrawGfHLine(row, gf, GRAPH_PAD_L, GRAPH_PAD_L + plotW, y, 1, 0.25, 0.25, 0.25, 0.6)
        local lbl = DetaurBar.UI.GfLabel(row, gf)
        lbl:SetPoint("RIGHT", gf, "BOTTOMLEFT", GRAPH_PAD_L - 2, y)
        lbl:SetText(DetaurBar.UI.FormatGold(math.floor(price)))
        lbl:SetTextColor(0.65, 0.65, 0.65, 1)
        lbl:Show()
    end

    -- X axis labels: 3 evenly spaced across the time range
    local activePriceSubTab = DetaurBar.UI.activePriceSubTab or "Daily"
    local fmt = (activePriceSubTab == "Daily") and "%H:%M" or "%d/%m"
    for i = 0, 2 do
        local ts = minTs + tsRange * i / 2
        local x = GRAPH_PAD_L + plotW * i / 2
        local lbl = DetaurBar.UI.GfLabel(row, gf)
        lbl:SetPoint("TOP", gf, "BOTTOMLEFT", x, GRAPH_PAD_B - 2)
        lbl:SetText(date(fmt, math.floor(ts)))
        lbl:SetTextColor(0.55, 0.55, 0.55, 1)
        lbl:Show()
    end

    -- Lines and dots
    local prevX, prevY
    for _, p in ipairs(points) do
        local x, y = toX(p.ts), toY(p.price)
        if prevX then
            DetaurBar.UI.DrawGfLine(row, gf, prevX, prevY, x, y, 1.5, 1.0, 0.82, 0.0, 0.9)
        end
        local dot = DetaurBar.UI.GfTex(row, gf)
        dot:SetTexture(1, 1, 1, 1)
        dot:SetSize(5, 5)
        dot:SetPoint("CENTER", gf, "BOTTOMLEFT", x, y)
        dot:Show()

        -- Interactive hover frame for tooltip and hover animation
        local hover = DetaurBar.UI.GfFrame(row, gf)
        hover:SetSize(16, 16)
        hover:SetPoint("CENTER", gf, "BOTTOMLEFT", x, y)
        hover:EnableMouse(true)
        hover:RegisterForClicks("RightButtonUp")
        hover:SetScript("OnEnter", function(self)
            dot:SetSize(8, 8)
            dot:SetTexture(1, 0.82, 0, 1)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(date("%d.%m.%Y %H:%M", p.ts), 1.0, 0.82, 0.0)
            GameTooltip:AddLine(DetaurBar.UI.FormatMoney(p.price), 1.0, 1.0, 1.0)
            GameTooltip:AddLine("Right-click to delete", 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)
        hover:SetScript("OnLeave", function(self)
            dot:SetSize(5, 5)
            dot:SetTexture(1, 1, 1, 1)
            GameTooltip:Hide()
        end)
        hover:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                confirmFrame.pendingItemId = itemId
                confirmFrame.pendingTimestamp = tostring(p.ts)
                confirmFrame:ClearAllPoints()
                confirmFrame:SetPoint("CENTER", UIParent, "CENTER")
                confirmFrame:Show()
            end
        end)
        hover:Show()

        prevX, prevY = x, y
    end

    -- Buy/Sell markers overlay (connected like the price series, with tooltips)
    local settings = DetaurBar.Data.GetSettings()
    if settings.chartBuySellVisible then
        local bsHistory = DetaurBar.Data.GetBuySellHistory(itemId)
        if bsHistory and #bsHistory > 0 then
            local prevBX, prevBY
            for _, rec in ipairs(bsHistory) do
                if rec.ts >= cutoff then
                    local markerPrice = rec.price or dMin
                    if markerPrice <= 0 then
                        markerPrice = dMin
                    end
                    local bx, by = toX(rec.ts), toY(markerPrice)
                    by = math.max(GRAPH_PAD_B, math.min(GRAPH_PAD_B + plotH, by))
                    local isBuy = rec.type == "buy"
                    local bsR, bsG, bsB = isBuy and 1.0 or 0.0, isBuy and 0.0 or 1.0, 0.0

                    -- Connect to previous buy/sell marker
                    if prevBX then
                        DetaurBar.UI.DrawGfLine(row, gf, prevBX, prevBY, bx, by, 1, bsR, bsG, bsB, 0.9)
                    end

                    -- Marker dot (larger than data points)
                    local dot = DetaurBar.UI.GfTex(row, gf)
                    dot:SetTexture(bsR, bsG, bsB, 1)
                    dot:SetSize(7, 7)
                    dot:SetPoint("CENTER", gf, "BOTTOMLEFT", bx, by)
                    dot:Show()

                    -- Interactive hover frame for tooltip
                    local hover = DetaurBar.UI.GfFrame(row, gf)
                    hover:SetSize(14, 14)
                    hover:SetPoint("CENTER", gf, "BOTTOMLEFT", bx, by)
                    hover:EnableMouse(true)
                    hover:SetScript("OnEnter", function(self)
                        dot:SetSize(9, 9)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(date("%d.%m.%Y %H:%M", rec.ts), 1.0, 0.82, 0.0)
                        GameTooltip:AddLine((isBuy and "Buy" or "Sell") .. " " .. DetaurBar.UI.FormatMoney(markerPrice), bsR, bsG, bsB)
                        GameTooltip:Show()
                    end)
                    hover:SetScript("OnLeave", function(self)
                        dot:SetSize(7, 7)
                        GameTooltip:Hide()
                    end)
                    hover:Show()

                    prevBX, prevBY = bx, by
                end
            end
        end
    end
end
