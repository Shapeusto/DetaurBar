-- DetaurBar_UI_Buffs.lua
-- Tracks spell cooldowns and stacking buffs, shows center-screen icons.

DetaurBar = DetaurBar or {}
DetaurBar.Buffs = {}

-- ============================================
--  ALERT FRAME POOL (multiple side-by-side)
-- ============================================
local MAX_ALERTS = 6
local alertFrames = {}

for i = 1, MAX_ALERTS do
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(34, 34)
    f:SetPoint("CENTER", UIParent, "CENTER", (i - 1) * 40 - ((MAX_ALERTS - 1) * 20), -200)
    f:Hide()
    f:SetFrameStrata("DIALOG")

    local icon = f:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints(f)

    local bg = CreateFrame("Frame", nil, f)
    bg:SetPoint("TOPLEFT", f, "TOPLEFT", -3, 3)
    bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 3, -3)
    bg:SetFrameLevel(f:GetFrameLevel() - 1)
    bg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    bg:SetBackdropColor(0, 0, 0, 0.7)
    bg:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.8)

    f.icon = icon
    f.bg = bg
    f.animFrame = nil

    alertFrames[i] = f
end

-- ============================================
--  SHOW ALERT (uses next available frame)
-- ============================================
function DetaurBar.Buffs.ShowAlert(icon, name)
    for _, f in ipairs(alertFrames) do
        if not f:IsShown() then
            if icon then
                f.icon:SetTexture(icon)
                f.icon:Show()
            else
                f.icon:Hide()
            end

            f:Show()
            f:SetAlpha(1.0)

            if f.animFrame then
                f.animFrame:Hide()
                f.animFrame:SetScript("OnUpdate", nil)
            end
            local elapsed = 0
            f.animFrame = CreateFrame("Frame")
            f.animFrame:SetScript("OnUpdate", function(self, e)
                elapsed = elapsed + (e or 0)
                if elapsed < 1.0 then
                elseif elapsed < 1.5 then
                    f:SetAlpha(math.max(0, 1 - (elapsed - 1.0) / 0.5))
                else
                    f:Hide()
                    self:SetScript("OnUpdate", nil)
                end
            end)
            return
        end
    end
end

-- ============================================
--  COOLDOWN TRACKING
-- ============================================
local prevCooldownState = {} -- keyed by SLOT INDEX (1-4)

function DetaurBar.Buffs.OnSlotChanged()
    local slots = DetaurBarDB and DetaurBarDB.settings and DetaurBarDB.settings.buffsSpellSlots or {}
    for i = 1, 4 do
        local data = slots[i]
        if data and data.id then
            prevCooldownState[i] = 0
        else
            prevCooldownState[i] = nil
        end
    end
end

-- ============================================
--  POLLING UPDATE FRAME
-- ============================================
local updateFrame = CreateFrame("Frame")
local pollTimer = 0

updateFrame:SetScript("OnUpdate", function(self, elapsed)
    pollTimer = pollTimer + (elapsed or 0)
    if pollTimer < 0.5 then return end
    pollTimer = 0

    local settings = DetaurBarDB and DetaurBarDB.settings
    if not settings then return end

    local slots = settings.buffsSpellSlots or {}

    -- Cooldown check (gated by buffsEnabled)
    if settings.buffsEnabled then
    for i = 1, 4 do
        local data = slots[i]
        if data and data.id then
            -- Try GetSpellCooldown(bookIndex, bookType) first, fallback to (spellId)
            local start, duration
            if data.bookIndex and data.bookType then
                start, duration = GetSpellCooldown(data.bookIndex, data.bookType)
            end
            if not duration then
                start, duration = GetSpellCooldown(data.id)
            end
            local prev = prevCooldownState[i] or 0
            if duration and duration > 0 then
                if duration > 1.5 then
                    prevCooldownState[i] = start + duration
                end
            elseif prev > 0 and duration == 0 then
                local name, _, icon
                if data.bookIndex and data.bookType then
                    name, _, icon = GetSpellInfo(data.bookIndex, data.bookType)
                end
                if not icon or not name then
                    local n, _, ico = GetSpellInfo(data.id)
                    if not name then name = n end
                    if not icon then icon = ico end
                end
                if not icon then icon = data.icon end
                if not name then name = data.name end
                DetaurBar.Buffs.ShowAlert(icon, name or ("ID: " .. data.id))
                prevCooldownState[i] = 0
            end
        end
    end
    end

    -- Stacks check (Maelstrom Weapon only)
    if settings.buffsFollowStacks then
        if DetaurBar.Buffs.mwAlerted == nil then DetaurBar.Buffs.mwAlerted = false end

        local mwCount = 0
        local mwIcon, mwName
        for i = 1, 40 do
            local buffName, _, buffIcon, buffCount, _, _, _, _, _, _, spellId = UnitBuff("player", i)
            if not buffName then break end
            if spellId == 53817 then
                mwCount = buffCount or 0
                mwIcon = buffIcon
                mwName = buffName
                break
            end
        end

        if mwCount >= 5 and not DetaurBar.Buffs.mwAlerted then
            DetaurBar.Buffs.mwAlerted = true
            DetaurBar.Buffs.ShowAlert(mwIcon, (mwName or "Maelstrom Weapon") .. " x" .. mwCount)
        elseif mwCount < 5 then
            DetaurBar.Buffs.mwAlerted = false
        end
    end
end)

-- ============================================
--  INIT
-- ============================================
DetaurBar.Buffs.OnSlotChanged()
