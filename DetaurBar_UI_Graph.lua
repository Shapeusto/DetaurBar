-- DetaurBar_UI_Graph.lua
-- Price graph drawing utilities (FormatMoney, ClearGraphObjects, DrawPriceGraph)

DetaurBar = DetaurBar or {}
DetaurBar.UI = DetaurBar.UI or {}

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
    row.graphTextures = {}
    row.graphLabels = {}
    row.graphFrames = {}
end

-- [GRAPH HELPERS] GfTex — create and track a graph texture
function DetaurBar.UI.GfTex(row, gf, layer)
    local t = gf:CreateTexture(nil, layer or "OVERLAY")
    t:SetDrawLayer(layer or "OVERLAY")
    table.insert(row.graphTextures, t)
    return t
end

-- [GRAPH HELPERS] GfLabel — create and track a graph label font string
function DetaurBar.UI.GfLabel(row, gf)
    local f = gf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    table.insert(row.graphLabels, f)
    return f
end

-- [GRAPH HELPERS] GfFrame — create and track a graph hover frame
function DetaurBar.UI.GfFrame(row, gf)
    if not row.graphFrames then
        row.graphFrames = {}
    end
    local f = CreateFrame("Frame", nil, gf)
    table.insert(row.graphFrames, f)
    return f
end

-- [GRAPH HELPERS] DrawGfLine — dot-stepping line renderer (SetRotation doesn't work in 3.3.5a)
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

    -- axes
    DetaurBar.UI.DrawGfLine(row, gf, GRAPH_PAD_L, GRAPH_PAD_B, GRAPH_PAD_L, GRAPH_PAD_B + plotH, 1, 0.5, 0.5, 0.5, 1)
    DetaurBar.UI.DrawGfLine(row, gf, GRAPH_PAD_L, GRAPH_PAD_B, GRAPH_PAD_L + plotW, GRAPH_PAD_B, 1, 0.5, 0.5, 0.5, 1)

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
        DetaurBar.UI.DrawGfLine(row, gf, GRAPH_PAD_L, y, GRAPH_PAD_L + plotW, y, 1, 0.25, 0.25, 0.25, 0.6)
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
        hover:SetScript("OnEnter", function(self)
            dot:SetSize(8, 8)
            dot:SetTexture(1, 0.82, 0, 1)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(date("%d.%m.%Y %H:%M", p.ts), 1.0, 0.82, 0.0)
            GameTooltip:AddLine(DetaurBar.UI.FormatMoney(p.price), 1.0, 1.0, 1.0)
            GameTooltip:Show()
        end)
        hover:SetScript("OnLeave", function(self)
            dot:SetSize(5, 5)
            dot:SetTexture(1, 1, 1, 1)
            GameTooltip:Hide()
        end)

        prevX, prevY = x, y
    end
end
