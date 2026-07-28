-- DetaurBar_UI_Enemy.lua
-- Enemy detection, monitor window, and alert system

DetaurBar = DetaurBar or {}
DetaurBar.Enemy = DetaurBar.Enemy or {}
DetaurBar.UI = DetaurBar.UI or {}

local band = bit.band
local bor = bit.bor
local time = time

local ENEMY_FADE_TIME = 120
local ENEMY_ENCOUNTER = 60
local MAX_ENEMIES = 10

local HOSTILE_CHECK = bor(COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_CONTROL_PLAYER)
local HOSTILE_PLAYER = bor(COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PLAYER)
local HOSTILE_PET = bor(COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PET)
local HOSTILE_GUARDIAN = bor(COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_GUARDIAN)
local FRIENDLY_CHECK = bor(COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER)
local ME_FLAGS = bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PLAYER)

local enemies = {}
local enemyDisplay = {}
local alertTimers = {}
local listening = false
local dismissed = {}
local updatingMonitor = false

local soundPaths = {
    RaidWarning = "Sound\\Interface\\RaidWarning.wav",
    ReadyCheck = "Sound\\Interface\\ReadyCheck.wav",
    PvPFlagCaptured = "Sound\\Interface\\PvPFlagCaptured.wav",
}

local flashColors = {
    GREEN = { 0.0, 1.0, 0.0 },
    YELLOW = { 1.0, 1.0, 0.0 },
    RED = { 1.0, 0.0, 0.0 },
}

local function GetSettings()
    if DetaurBar.Data and DetaurBar.Data.GetSettings then
        return DetaurBar.Data.GetSettings()
    end
    return DetaurBarDB and DetaurBarDB.settings or {}
end

local function GetFlashColorRGB(colorKey)
    local c = flashColors[colorKey or "YELLOW"] or flashColors.YELLOW
    return c[1], c[2], c[3]
end

-- Flash frames
local flashFrame
local flashElapsed = 0
local smoothFlashFrame
local smoothFlashElapsed = 0

local function CreateFlashFrames()
    if flashFrame then return end
    -- Aggressive fullscreen flash
    flashFrame = CreateFrame("Frame", "DetaurBarEnemyFlashFrame", UIParent)
    flashFrame:SetAllPoints(UIParent)
    flashFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    flashFrame:EnableMouse(false)
    flashFrame:Hide()
    local tex = flashFrame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(flashFrame)
    tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    flashFrame.texture = tex
    flashFrame:SetScript("OnUpdate", function(self, elapsed)
        flashElapsed = flashElapsed + elapsed
        if flashElapsed >= 2.6 then
            self:Hide()
            return
        end
        local alpha = 0.18 + (math.abs(math.sin(flashElapsed * 28)) * 0.82)
        self:SetAlpha(alpha)
    end)

    -- Smooth border flash (visible → fade out)
    smoothFlashFrame = CreateFrame("Frame", "DetaurBarEnemySmoothFlash", UIParent)
    smoothFlashFrame:SetAllPoints(UIParent)
    smoothFlashFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    smoothFlashFrame:EnableMouse(false)
    smoothFlashFrame:Hide()
    local bw = 48
    local borders = {}
    for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local t = smoothFlashFrame:CreateTexture(nil, "BACKGROUND")
        t:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        if edge == "TOP" then
            t:SetPoint("TOPLEFT", smoothFlashFrame, "TOPLEFT", 0, 0)
            t:SetPoint("TOPRIGHT", smoothFlashFrame, "TOPRIGHT", 0, 0)
            t:SetHeight(bw)
        elseif edge == "BOTTOM" then
            t:SetPoint("BOTTOMLEFT", smoothFlashFrame, "BOTTOMLEFT", 0, 0)
            t:SetPoint("BOTTOMRIGHT", smoothFlashFrame, "BOTTOMRIGHT", 0, 0)
            t:SetHeight(bw)
        elseif edge == "LEFT" then
            t:SetPoint("TOPLEFT", smoothFlashFrame, "TOPLEFT", 0, 0)
            t:SetPoint("BOTTOMLEFT", smoothFlashFrame, "BOTTOMLEFT", 0, 0)
            t:SetWidth(bw)
        else
            t:SetPoint("TOPRIGHT", smoothFlashFrame, "TOPRIGHT", 0, 0)
            t:SetPoint("BOTTOMRIGHT", smoothFlashFrame, "BOTTOMRIGHT", 0, 0)
            t:SetWidth(bw)
        end
        t:Hide()
        borders[edge] = t
    end
    smoothFlashFrame.borders = borders
    smoothFlashFrame:SetScript("OnUpdate", function(self, elapsed)
        smoothFlashElapsed = smoothFlashElapsed + elapsed
        if smoothFlashElapsed >= 1.5 then
            for _, t in pairs(self.borders) do t:Hide() end
            self:Hide()
            return
        end
        local alpha = 0.7 * (1 - smoothFlashElapsed / 1.5)
        for _, t in pairs(self.borders) do t:SetAlpha(alpha) end
    end)
end

local function DoAggressiveFlash(colorKey)
    CreateFlashFrames()
    local r, g, b = GetFlashColorRGB(colorKey)
    flashFrame.texture:SetVertexColor(r, g, b, 1.0)
    flashElapsed = 0
    flashFrame:Show()
end

local function DoSmoothFlash(colorKey)
    CreateFlashFrames()
    local r, g, b = GetFlashColorRGB(colorKey)
    for _, t in pairs(smoothFlashFrame.borders) do
        t:SetVertexColor(r, g, b, 1.0)
        t:Show()
    end
    smoothFlashElapsed = 0
    smoothFlashFrame:Show()
end

local function DoFlash(colorKey, style)
    if style == "SMOOTH" then
        DoSmoothFlash(colorKey)
    else
        DoAggressiveFlash(colorKey)
    end
end

local function DoSound(soundKey)
    local path = soundPaths[soundKey or "RaidWarning"] or soundPaths.RaidWarning
    PlaySoundFile(path)
end

-- Zone check
function DetaurBar.Enemy.UpdateZoneType()
    local settings = GetSettings()
    if not settings.enemyEnabled then
        listening = false
        return
    end
    local inInstance = IsInInstance()
    if inInstance then
        listening = false
    else
        listening = true
    end
end

-- Add or update enemy
local function AddOrUpdateEnemy(name, level, class, spellName, activityText)
    if not name then return end
    name = strsplit("-", name)
    local now = time()
    local enemy = enemies[name]
    if not enemy then
        enemy = { name = name }
        enemies[name] = enemy
        dismissed[name] = nil
    end
    if level and level > 0 then enemy.level = level end
    if class then enemy.class = class end
    enemy.last = now
    local showCastSetting = DetaurBarDB and DetaurBarDB.settings and DetaurBarDB.settings.enemyShowCast ~= false
    if showCastSetting then
        enemy.activity = activityText or spellName or "Detected"
    end
end

-- Combat log parsing
local function OnCombatLogEvent(_, _, eventName, srcGuid, srcName, srcFlags, dstGuid, dstName, dstFlags, spellId, spellName)
    local settings = GetSettings()
    if not settings.enemyEnabled or not listening then return end

    local function getActivity()
        if eventName == "SWING_DAMAGE" or eventName == "SWING_MISSED" then
            return "Melee"
        elseif eventName == "RANGE_DAMAGE" or eventName == "RANGE_MISSED" then
            return "Shot"
        elseif eventName:find("^SPELL_") then
            return spellName or "Cast"
        end
        return nil
    end

    local activity = getActivity()
    if not activity then return end

    local name
    if srcFlags and band(srcFlags, HOSTILE_CHECK) == HOSTILE_CHECK then
        if band(srcFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER then
            name = srcName
        elseif band(srcFlags, COMBATLOG_OBJECT_TYPE_PET) == COMBATLOG_OBJECT_TYPE_PET or
               band(srcFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) == COMBATLOG_OBJECT_TYPE_GUARDIAN then
            return
        end
    end
    if not name and dstFlags and band(dstFlags, HOSTILE_CHECK) == HOSTILE_CHECK then
        if band(dstFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER then
            name = dstName
        end
    end
    if not name then return end

    AddOrUpdateEnemy(name, nil, nil, spellName, activity)
    DetaurBar.Enemy.OnNewEnemy(name)
end

-- Mouseover/target
local function UpdateUnit(unitId)
    local settings = GetSettings()
    if not settings.enemyEnabled or not listening then return end
    if not UnitIsPlayer(unitId) then return end
    if UnitIsFriend("player", unitId) then return end

    local name = UnitName(unitId)
    if not name then return end

    local level = UnitLevel(unitId)
    if level and level <= 0 then level = nil end

    local _, class = UnitClass(unitId)

    AddOrUpdateEnemy(name, level, class, nil, "Nearby")
    DetaurBar.Enemy.OnNewEnemy(name)
end

-- Alert
function DetaurBar.Enemy.OnNewEnemy(name)
    local settings = GetSettings()
    if not settings.enemyEnabled then return end
    if not name then return end

    local now = time()
    local lastAlert = alertTimers[name] or 0
    if now - lastAlert < ENEMY_ENCOUNTER then return end
    alertTimers[name] = now

    if DetaurBar.Core.PrintAlert then
        DetaurBar.Core.PrintAlert("Enemy Alert: " .. name)
    end

    if settings.enemyFlashEnabled and settings.enemyFlashColor then
        DoFlash(settings.enemyFlashColor, settings.enemyFlashStyle)
    end
    if settings.enemyPlaySound and settings.enemySound then
        DoSound(settings.enemySound)
    end
end

-- Monitor frame
local monitorFrame
local monitorRows = {}
local monitorEmptyText
local monitorToggleBtn

local function CreateMonitor()
    if monitorFrame then return end

    monitorFrame = CreateFrame("Frame", "DetaurBarEnemyMonitor", UIParent)
    monitorFrame:SetSize(300, 60)
    monitorFrame:SetPoint("CENTER", UIParent, "CENTER", 300, -100)
    monitorFrame:SetMovable(true)
    monitorFrame:SetResizable(true)
    monitorFrame:SetMinResize(200, 50)
    monitorFrame:SetMaxResize(500, 600)
    monitorFrame:EnableMouse(true)
    monitorFrame:RegisterForDrag("LeftButton")
    monitorFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    monitorFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    monitorFrame:SetFrameStrata("MEDIUM")
    monitorFrame:SetClampedToScreen(true)
    monitorFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    monitorFrame:SetBackdropColor(0.12, 0.10, 0.08, 1)
    monitorFrame:Hide()

    -- Resize grip
    local resizeBtn = CreateFrame("Button", nil, monitorFrame)
    resizeBtn:SetSize(16, 16)
    resizeBtn:SetPoint("BOTTOMRIGHT", monitorFrame, "BOTTOMRIGHT", -4, 4)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            monitorFrame:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeBtn:SetScript("OnMouseUp", function(self, button)
        monitorFrame:StopMovingOrSizing()
    end)

    -- Enable/disable toggle button (aligned with first row)
    monitorToggleBtn = CreateFrame("Button", nil, monitorFrame)
    monitorToggleBtn:SetSize(20, 20)
    monitorToggleBtn:SetPoint("TOPRIGHT", monitorFrame, "TOPRIGHT", -14, -14)
    monitorToggleBtn:SetFrameLevel(monitorFrame:GetFrameLevel() + 50)
    monitorToggleBtn:SetNormalTexture("Interface\\Icons\\Spell_Nature_BloodLust")
    monitorToggleBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    local toggleIcon = monitorToggleBtn:GetNormalTexture()
    monitorToggleBtn:SetScript("OnClick", function()
        local settings = GetSettings()
        settings.enemyEnabled = not settings.enemyEnabled
        DetaurBar.Enemy.UpdateZoneType()
        if settings.enemyEnabled then
            toggleIcon:SetDesaturated(false)
        else
            toggleIcon:SetDesaturated(true)
        end
        if DetaurBar.UI and DetaurBar.UI.enemyEnableCheckbox then
            DetaurBar.UI.enemyEnableCheckbox:SetChecked(settings.enemyEnabled and 1 or nil)
        end
    end)
    -- Update toggle icon state when monitor is shown
    DetaurBar.Enemy.UpdateToggleIcon = function()
        local settings = GetSettings()
        local enabled = settings.enemyEnabled
        toggleIcon:SetDesaturated(not enabled)
    end
    DetaurBar.Enemy.UpdateToggleIcon()

    monitorFrame:SetScript("OnSizeChanged", function()
        DetaurBar.Enemy.UpdateMonitor()
    end)

    monitorEmptyText = monitorFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    monitorEmptyText:SetPoint("TOPLEFT", monitorFrame, "TOPLEFT", 18, -20)
    monitorEmptyText:SetText("No Enemies Detected")
    monitorEmptyText:SetTextColor(0.5, 0.5, 0.5, 1.0)

    monitorWGText = monitorFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    monitorWGText:SetPoint("TOPLEFT", monitorFrame, "TOPLEFT", 18, 15)
    monitorWGText:SetPoint("TOPRIGHT", monitorFrame, "TOPRIGHT", -40, 15)
    monitorWGText:SetJustifyH("LEFT")
    monitorWGText:SetTextColor(1.0, 0.82, 0.0, 1.0)
    monitorWGText:Hide()

    -- Pre-create all row buttons with SecureActionButtonTemplate
    -- SetAttribute is called only inside PreClick (secure context) to avoid taint.
    for i = 1, MAX_ENEMIES do
        local row = CreateFrame("Button", nil, monitorFrame, "SecureActionButtonTemplate")
        row:SetHeight(18)
        row:EnableMouse(true)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(row)
        hl:SetTexture(1.0, 0.82, 0.0, 0.12)
        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.nameText:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.nameText:SetWidth(80)
        row.infoText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.infoText:SetPoint("LEFT", row.nameText, "RIGHT", 2, 0)
        row.infoText:SetWidth(60)
        row.activityText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.activityText:SetPoint("RIGHT", row, "RIGHT", -36, 0)
        row.activityText:SetWidth(90)
        -- PreClick runs in secure context before the secure action; safe for SetAttribute
        row:SetScript("PreClick", function(self)
            self:SetAttribute("type1", "macro")
            self:SetAttribute("macrotext1", "/target " .. (self.enemyTargetName or ""))
        end)
        -- PostClick: right-click dismisses the enemy
        row:SetScript("PostClick", function(self, button)
            if button == "RightButton" and self.enemyTargetName then
                dismissed[self.enemyTargetName] = true
                enemies[self.enemyTargetName] = nil
                DetaurBar.Enemy.RebuildDisplay()
                DetaurBar.Enemy.UpdateMonitor()
            end
        end)
        monitorRows[i] = row
    end
end

function DetaurBar.Enemy.UpdateMonitor()
    if updatingMonitor then return end
    if not monitorFrame or not monitorFrame:IsShown() then return end
    if not DetaurBar.Enemy.RebuildDisplay then return end

    -- Wintergrasp countdown timer at the top of the monitor
    local settings = DetaurBarDB and DetaurBarDB.settings
    if settings and settings.wgShowTimeOnEnemyTracker and DetaurBar.Alerts and DetaurBar.Alerts.GetWintergraspRemainingSeconds then
        local remaining = DetaurBar.Alerts.GetWintergraspRemainingSeconds()
        if remaining then
            local mins = math.floor(remaining / 60)
            local secs = remaining % 60
            monitorWGText:SetText("Wintergrasp: " .. mins .. "m " .. ("%02d"):format(secs) .. "s")
            monitorWGText:Show()
        else
            monitorWGText:SetText("Wintergrasp: unknown")
            monitorWGText:Show()
        end
    else
        monitorWGText:Hide()
    end

    local showCast = DetaurBarDB and DetaurBarDB.settings and DetaurBarDB.settings.enemyShowCast ~= false

    updatingMonitor = true
    DetaurBar.Enemy.RebuildDisplay()

    local rowHeight = 18
    local spacing = 1
    local count = math.min(#enemyDisplay, MAX_ENEMIES)
    local innerTop = 14
    if monitorWGText:IsShown() then innerTop = 14 end
    local bottomPad = 14

    if #enemyDisplay == 0 then
        monitorEmptyText:Show()
        for _, r in ipairs(monitorRows) do
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", monitorFrame, "TOPLEFT", 0, -9999)
            r:Hide()
        end
        monitorFrame:SetHeight(innerTop + rowHeight + spacing + bottomPad)
        updatingMonitor = false
        return
    end

    monitorEmptyText:Hide()

    local desiredHeight = innerTop + count * (rowHeight + spacing) + bottomPad
    monitorFrame:SetHeight(desiredHeight)

    for i = 1, count do
        local enemy = enemyDisplay[i]
        local row = monitorRows[i]
        if not row then break end

        row:Show()
        row:ClearAllPoints()
        local yOffset = -innerTop - (i - 1) * (rowHeight + spacing)
        row:SetPoint("TOPLEFT", monitorFrame, "TOPLEFT", 14, yOffset)
        row:SetPoint("TOPRIGHT", monitorFrame, "TOPRIGHT", -16, yOffset)
        row:SetPoint("BOTTOMLEFT", monitorFrame, "TOPLEFT", 14, yOffset - rowHeight)
        row:SetPoint("BOTTOMRIGHT", monitorFrame, "TOPRIGHT", -16, yOffset - rowHeight)
        row:SetHitRectInsets(0, 0, 0, 0)
        row:Enable()

        row.nameText:SetText(enemy.name or "?")
        row.nameText:SetTextColor(0.9, 0.2, 0.2, 1.0)
        row.enemyTargetName = enemy.name

        local lvl = ""
        if enemy.level and enemy.level > 0 then
            lvl = enemy.level
        else
            lvl = "??"
        end
        if enemy.class then
            lvl = lvl .. " " .. enemy.class:sub(1, 4)
        end
        row.infoText:SetText(lvl)
        row.infoText:SetTextColor(0.75, 0.75, 0.75, 1.0)

        if showCast then
            row.activityText:SetText("[" .. (enemy.activity or "Detected") .. "]")
            row.activityText:Show()
        else
            row.activityText:SetText("")
            row.activityText:Hide()
            enemy.activity = nil
        end
        row.activityText:SetTextColor(0.5, 0.5, 0.7, 1.0)
    end

    for i = count + 1, #monitorRows do
        monitorRows[i]:Hide()
    end

    updatingMonitor = false
end

function DetaurBar.Enemy.RebuildDisplay()
    local now = time()
    for name, enemy in pairs(enemies) do
        if now - enemy.last > ENEMY_FADE_TIME then
            enemies[name] = nil
        end
    end
    wipe(enemyDisplay)
    for _, enemy in pairs(enemies) do
        if not dismissed[enemy.name] then
            table.insert(enemyDisplay, enemy)
        end
    end
    table.sort(enemyDisplay, function(a, b) return a.last > b.last end)
end

function DetaurBar.Enemy.ClearActivities()
    for _, e in pairs(enemies) do
        e.activity = nil
    end
end

function DetaurBar.Enemy.ShowMonitor()
    if not monitorFrame then CreateMonitor() end
    monitorFrame:Show()
    if DetaurBar.Enemy.UpdateToggleIcon then
        DetaurBar.Enemy.UpdateToggleIcon()
    end
    DetaurBar.Enemy.UpdateMonitor()
end

function DetaurBar.Enemy.HideMonitor()
    if monitorFrame then monitorFrame:Hide() end
end

function DetaurBar.Enemy.ToggleMonitor()
    if monitorFrame and monitorFrame:IsShown() then
        DetaurBar.Enemy.HideMonitor()
    else
        DetaurBar.Enemy.ShowMonitor()
    end
end

-- Event frame
local detectFrame = CreateFrame("Frame", "DetaurBarEnemyDetectFrame")
do
    local updateElapsed = 0

    detectFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    detectFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    detectFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    detectFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    detectFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    detectFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            OnCombatLogEvent(event, ...)
        elseif event == "PLAYER_TARGET_CHANGED" then
            UpdateUnit("target")
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            UpdateUnit("mouseover")
        elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
            DetaurBar.Enemy.UpdateZoneType()
        end
    end)

    detectFrame:SetScript("OnUpdate", function(self, elapsed)
        updateElapsed = updateElapsed + elapsed
        if updateElapsed >= 1 then
            updateElapsed = 0
            DetaurBar.Enemy.RebuildDisplay()
            DetaurBar.Enemy.UpdateMonitor()
        end
    end)
end

-- Init
function DetaurBar.Enemy.Initialize()
    CreateMonitor()
    DetaurBar.Enemy.UpdateZoneType()
end
