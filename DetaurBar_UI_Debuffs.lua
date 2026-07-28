-- DetaurBar_UI_Debuffs.lua
-- Tracks enemy debuffs (buffs cast by enemies), shows center-screen icons (upper area).

DetaurBar = DetaurBar or {}
DetaurBar.Debuffs = {}

local band = bit.band
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

-- ============================================
--  CENTER-SCREEN ICON POOL (upper area, y=200)
-- ============================================
local MAX_ICONS = 10
local iconFrames = {}

for i = 1, MAX_ICONS do
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(34, 34)
    f:SetPoint("CENTER", UIParent, "CENTER", (i - 1) * 40 - ((MAX_ICONS - 1) * 20), 200)
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
    bg:SetBackdropBorderColor(1.0, 0.1, 0.1, 0.8)

    f.icon = icon
    f.bg = bg
    f.slotIndex = nil
    f.lastRefresh = 0

    iconFrames[i] = f
end

-- ============================================
--  ACTIVE AURA TRACKING
-- ============================================
local activeAuras = {}
local slotIconMap = {}

function DetaurBar.Debuffs.ResetActiveAuras()
    for _, f in ipairs(iconFrames) do
        f:Hide()
        f.slotIndex = nil
    end
    wipe(activeAuras)
    wipe(slotIconMap)
end

function DetaurBar.Debuffs.GetActiveAuras()
    return activeAuras
end

-- Auto-hide stale icons after 60s without refresh
local DEBUFF_ICON_TIMEOUT = 60

local debuffCleanup = CreateFrame("Frame", nil, UIParent)
debuffCleanup:Show()
debuffCleanup:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 2 then return end
    self.elapsed = 0
    local now = GetTime()
    for slotIdx, f in pairs(slotIconMap) do
        if f:IsShown() and now - f.lastRefresh > DEBUFF_ICON_TIMEOUT then
            f:Hide()
            f.slotIndex = nil
            slotIconMap[slotIdx] = nil
            activeAuras[slotIdx] = 0
        end
    end
end)

-- Clean up when disabled
function DetaurBar.Debuffs.SetActive(enabled)
    if not enabled then
        DetaurBar.Debuffs.ResetActiveAuras()
    end
end

-- ============================================
--  SHOW / HIDE ICONS
-- ============================================
function DetaurBar.Debuffs.ShowIcon(slotIndex, iconTexture)
    for _, f in ipairs(iconFrames) do
        if not f:IsShown() then
            f.icon:SetTexture(iconTexture)
            f.icon:Show()
            f.slotIndex = slotIndex
            f.lastRefresh = GetTime()
            f:Show()
            f:SetAlpha(1.0)
            slotIconMap[slotIndex] = f
            return
        end
    end
end

function DetaurBar.Debuffs.HideIcon(slotIndex)
    for _, f in ipairs(iconFrames) do
        if f:IsShown() and f.slotIndex == slotIndex then
            f:Hide()
            f.slotIndex = nil
            slotIconMap[slotIndex] = nil
            return
        end
    end
end

-- Called from DetaurBar_Core.lua's COMBAT_LOG_EVENT_UNFILTERED handler
function DetaurBar.Debuffs.OnCombatLogEvent(eventType, sourceFlags, destFlags, spellId, spellName, sourceGUID, destGUID)
    if eventType ~= "SPELL_AURA_APPLIED" and eventType ~= "SPELL_AURA_REMOVED" and eventType ~= "SPELL_AURA_REFRESH" then
        return
    end
    if not spellId then return end

    local settings = DetaurBarDB and DetaurBarDB.settings
    if not settings or not settings.debuffsEnabled then return end
    local slots = settings.debuffsSlots
    if not slots then return end

    -- ShowEverything filter: when unchecked, only show for current target
    if settings.debuffsShowEverything == nil then settings.debuffsShowEverything = true end
    if not settings.debuffsShowEverything then
        local targetGUID = UnitGUID("target")
        if not targetGUID then return end
        if sourceGUID ~= targetGUID and destGUID ~= targetGUID then
            return
        end
    end

    -- Find slot by ID or name (handles different ranks)
    local slotIndex, slotData
    for idx, data in pairs(slots) do
        if data then
            if data.spellId == spellId then
                slotIndex = idx
                slotData = data
                break
            elseif spellName and data.name and data.name == spellName then
                slotIndex = idx
                slotData = data
                break
            end
        end
    end
    if not slotIndex then return end

    -- Check hostile: skip only when BOTH have flags AND both are non-hostile
    if sourceFlags and destFlags
    and band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == 0
    and band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == 0 then
        return
    end

    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
        local prev = activeAuras[slotIndex] or 0
        activeAuras[slotIndex] = prev + 1
        if prev == 0 then
            local iconTex = slotData.icon
            if not iconTex and slotData.spellId then
                local _, _, ico = GetSpellInfo(slotData.spellId)
                iconTex = ico
            end
            if iconTex then
                DetaurBar.Debuffs.ShowIcon(slotIndex, iconTex)
            end
        else
            -- Refresh timer on existing icon
            local f = slotIconMap[slotIndex]
            if f then
                f.lastRefresh = GetTime()
            end
        end
    elseif eventType == "SPELL_AURA_REMOVED" then
        local prev = activeAuras[slotIndex] or 0
        if prev > 0 then
            activeAuras[slotIndex] = prev - 1
            if activeAuras[slotIndex] == 0 then
                DetaurBar.Debuffs.HideIcon(slotIndex)
            end
        end
    end
end
