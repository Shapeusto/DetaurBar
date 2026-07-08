-- DetaurBar_Alerts.lua
-- Flash system, Wintergrasp alerts, and random alert timer checking.

DetaurBar = DetaurBar or {}
DetaurBar.Alerts = {}

-- [FLASH] Full-screen flash frame
local dungeonFlashFrame = CreateFrame("Frame", "DetaurBarDungeonFlashFrame", UIParent)
dungeonFlashFrame:SetAllPoints(UIParent)
dungeonFlashFrame:SetFrameStrata("FULLSCREEN_DIALOG")
dungeonFlashFrame:Hide()
dungeonFlashFrame:EnableMouse(false)

local dungeonFlashTexture = dungeonFlashFrame:CreateTexture(nil, "BACKGROUND")
dungeonFlashTexture:SetAllPoints(dungeonFlashFrame)
dungeonFlashTexture:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
dungeonFlashTexture:SetVertexColor(1.0, 1.0, 0.0, 1.0)
dungeonFlashFrame.texture = dungeonFlashTexture

local dungeonFlashPulse = 0
local dungeonFlashReasons = {}
local dungeonFlashColor = "YELLOW"

local wintergraspCheckElapsed = 0
local randomCheckElapsed = 0
local randomNextFireAt = nil

-- [STATE] Wintergrasp tracking
local wintergraspState = {
    battleStartAt = nil,
    alert1Fired = false,
    alert2Fired = false,
    initialized = false,
    lastRemaining = nil,
}

local wintergraspSoundPaths = {
    RaidWarning = "Sound\\Interface\\RaidWarning.wav",
    PvPFlagCaptured = "Sound\\Interface\\PvPFlagCaptured.wav",
    ReadyCheck = "Sound\\Interface\\ReadyCheck.wav",
}

local wintergraspFlashColors = {
    GREEN = { 0.0, 1.0, 0.0 },
    YELLOW = { 1.0, 1.0, 0.0 },
    RED = { 1.0, 0.0, 0.0 },
}

local function GetSettingsTable()
    if DetaurBar.Data and DetaurBar.Data.GetSettings then
        return DetaurBar.Data.GetSettings()
    end
    return DetaurBarDB and DetaurBarDB.settings or {}
end

local function GetFlashColorRGB(colorKey)
    local color = wintergraspFlashColors[colorKey or "YELLOW"] or wintergraspFlashColors.YELLOW
    return color[1], color[2], color[3]
end

local function ApplyDungeonFlashColor(colorKey)
    local r, g, b = GetFlashColorRGB(colorKey)
    dungeonFlashFrame.texture:SetVertexColor(r, g, b, 1.0)
    dungeonFlashColor = colorKey or "YELLOW"
end

local function UpdateDungeonFlashState()
    if next(dungeonFlashReasons) then
        dungeonFlashFrame:SetAlpha(0.15)
        dungeonFlashFrame:Show()
    else
        dungeonFlashPulse = 0
        dungeonFlashFrame:Hide()
    end
end

function DetaurBar.Alerts.StartDungeonFlash(reason, colorKey, durationSeconds)
    local settings = GetSettingsTable()
    if reason == "lfg" and not settings.dungeonFlashEnabled then
        return
    end

    local now = GetTime()
    local chosenColor = colorKey or settings.dungeonFlashColor or "YELLOW"
    ApplyDungeonFlashColor(chosenColor)
    dungeonFlashReasons[reason or "generic"] = {
        colorKey = chosenColor,
        startedAt = now,
        expiresAt = durationSeconds and (now + durationSeconds) or nil,
    }
    UpdateDungeonFlashState()
end

function DetaurBar.Alerts.StopDungeonFlash(reason)
    if reason then
        dungeonFlashReasons[reason] = nil
    else
        wipe(dungeonFlashReasons)
    end
    UpdateDungeonFlashState()
end

dungeonFlashFrame:SetScript("OnUpdate", function(self, elapsed)
    local newestReason = nil
    local newestTime = nil

    for reason, data in pairs(dungeonFlashReasons) do
        if data.expiresAt and GetTime() >= data.expiresAt then
            dungeonFlashReasons[reason] = nil
        else
            if not newestTime or (data.startedAt or 0) >= newestTime then
                newestReason = reason
                newestTime = data.startedAt or 0
            end
        end
    end

    if not newestReason then
        dungeonFlashPulse = 0
        self:Hide()
        return
    end

    local data = dungeonFlashReasons[newestReason]
    if data and data.colorKey then
        ApplyDungeonFlashColor(data.colorKey)
    end

    dungeonFlashPulse = dungeonFlashPulse + elapsed
    local alpha = 0.18 + (math.abs(math.sin(dungeonFlashPulse * 28)) * 0.82)
    self:SetAlpha(alpha)
    self:Show()
end)

local function PlayConfiguredSound(soundKey)
    local soundPath = wintergraspSoundPaths[soundKey or "RaidWarning"] or wintergraspSoundPaths.RaidWarning
    if soundPath then
        PlaySoundFile(soundPath)
    end
end

local function GetWintergraspRemainingSeconds()
    if GetWintergraspWaitTime then
        local waitTime = GetWintergraspWaitTime()
        if waitTime then
            local remaining = tonumber(waitTime)
            if remaining and remaining >= 0 then
                local settings = GetSettingsTable()
                settings.wgCycleOffset = (time() + remaining) % 10800
                return remaining, GetTime() + remaining
            end
        end
    end

    local settings = GetSettingsTable()
    if settings.wgCycleOffset then
        local now = time()
        local remaining = (settings.wgCycleOffset - (now % 10800)) % 10800
        return remaining, GetTime() + remaining
    end

    return nil, nil
end

local function ResetWintergraspState(predictedStartAt)
    wintergraspState.battleStartAt = predictedStartAt
    wintergraspState.alert1Fired = false
    wintergraspState.alert2Fired = false
end

function DetaurBar.Alerts.ResetAlertState()
    wintergraspState.alert1Fired = false
    wintergraspState.alert2Fired = false
    randomNextFireAt = nil
end

local function CheckWintergraspAlerts(forceReset)
    local settings = GetSettingsTable()
    if not settings.wgAlertsEnabled then
        return
    end

    local remaining, predictedStartAt = GetWintergraspRemainingSeconds()
    if not remaining then
        return
    end

    if forceReset or not wintergraspState.initialized or not wintergraspState.battleStartAt or (
        predictedStartAt and math.abs(predictedStartAt - wintergraspState.battleStartAt) > 120
    ) then
        ResetWintergraspState(predictedStartAt)
        wintergraspState.initialized = true
        wintergraspState.lastRemaining = remaining
        return
    end

    local alert1Seconds = math.max(0, tonumber(settings.wgAlert1Minutes) or 15) * 60
    local alert2Seconds = math.max(0, tonumber(settings.wgAlert2Minutes) or 1) * 60

    if alert1Seconds > 0
        and not wintergraspState.alert1Fired
        and wintergraspState.lastRemaining
        and wintergraspState.lastRemaining > alert1Seconds
        and remaining <= alert1Seconds then
        wintergraspState.alert1Fired = true
        if settings.wgAlert1PlaySound then
            PlayConfiguredSound(settings.wgAlert1Sound)
        end
        local duration = math.max(0.1, tonumber(settings.wgAlert1Duration) or 2)
        DetaurBar.Alerts.StartDungeonFlash("wintergrasp", settings.wgAlert1Color or "YELLOW", duration)
        DetaurBar.Core.PrintAlert("Wintergrasp Alert")
    end

    if alert2Seconds >= 0
        and not wintergraspState.alert2Fired
        and wintergraspState.lastRemaining
        and wintergraspState.lastRemaining > alert2Seconds
        and remaining <= alert2Seconds then
        wintergraspState.alert2Fired = true
        if settings.wgAlert2Duration and settings.wgAlert2Duration > 0 then
            local duration = settings.wgAlert2Duration
            DetaurBar.Alerts.StartDungeonFlash("wintergrasp2", settings.wgAlert2Color or "YELLOW", duration)
            DetaurBar.Core.PrintAlert("Wintergrasp Battle Start")
        end
        if settings.wgAlert2PlaySound then
            PlayConfiguredSound(settings.wgAlert2Sound)
        end
    end

    if remaining > math.max(alert1Seconds, alert2Seconds) + 120 and wintergraspState.alert1Fired and wintergraspState.alert2Fired then
        ResetWintergraspState(predictedStartAt)
        wintergraspState.initialized = true
    end

    wintergraspState.lastRemaining = remaining
end

-- [UPDATE LOOP] Wintergrasp checks every 2s, random alerts every 1s
local alertUpdateFrame = CreateFrame("Frame", "DetaurBarAlertUpdateFrame")
alertUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    wintergraspCheckElapsed = wintergraspCheckElapsed + elapsed
    if wintergraspCheckElapsed >= 2 then
        wintergraspCheckElapsed = 0
        CheckWintergraspAlerts(false)
    end

    local settings2 = GetSettingsTable()
    if settings2.randomAlertsEnabled then
        randomCheckElapsed = randomCheckElapsed + elapsed
        if randomCheckElapsed >= 1 then
            randomCheckElapsed = 0
            local activeAlert = DetaurBar.Data and DetaurBar.Data.GetRandomActiveAlert and DetaurBar.Data.GetRandomActiveAlert()
            if activeAlert then
                local now = GetTime()
                local intervalSecs = math.max(60, (tonumber(activeAlert.intervalMinutes) or 5) * 60)
                if not randomNextFireAt then
                    randomNextFireAt = now + intervalSecs
                elseif now >= randomNextFireAt then
                    randomNextFireAt = now + intervalSecs
                    local duration = (activeAlert.flashDuration and activeAlert.flashDuration > 0) and activeAlert.flashDuration or nil
                    if duration then
                        DetaurBar.Alerts.StartDungeonFlash("random", activeAlert.flashColor or "YELLOW", duration)
                    end
                    DetaurBar.Core.PrintAlert("Random Alert: " .. (activeAlert.name or "unnamed"))
                    if activeAlert.playSound then
                        PlayConfiguredSound(activeAlert.sound)
                    end
                end
            end
        end
    else
        randomNextFireAt = nil
    end
end)
