-- DetaurBar_UI_ArmorIcons.lua
-- Shows user-chosen armor-type icons on enemy player nameplates when the
-- "Show armor" setting is enabled. Icon is drawn above EVERY visible enemy
-- player plate. In 3.3.5a enemy player nameplates show a class-colored health
-- bar, so the class (and thus armor type) is read from the bar color without a
-- unitID. The current target and mouseover plates fall back to reliable
-- unit-based class detection.

DetaurBar = DetaurBar or {}
DetaurBar.UI = DetaurBar.UI or {}

local CLASS_ARMOR = {
    WARRIOR = "Plate", PALADIN = "Plate", DEATHKNIGHT = "Plate",
    HUNTER = "Mail", SHAMAN = "Mail",
    ROGUE = "Leather", DRUID = "Leather",
    MAGE = "Cloth", PRIEST = "Cloth", WARLOCK = "Cloth",
}
for k, v in pairs(CLASS_ARMOR) do
    CLASS_ARMOR[k:lower()] = v
end

local SCAN_INTERVAL = 0.2

local plates = {}
local targetPlate
local mousePlate
local found = {}
local plateCache = {}

-- Reverse lookup: nameplate healthbar color -> class (LibNameplates technique).
-- Enemy player nameplates show a class-colored bar, so matching the bar color
-- against RAID_CLASS_COLORS identifies the class without a unitID.
local colorToClass = {}
if RAID_CLASS_COLORS then
    for class, c in pairs(RAID_CLASS_COLORS) do
        local key = string.format("%d,%d,%d",
            math.floor((c.r or 0) * 100 + 0.5),
            math.floor((c.g or 0) * 100 + 0.5),
            math.floor((c.b or 0) * 100 + 0.5))
        colorToClass[key] = class
    end
end

local function GetSettingsTable()
    if DetaurBar.Data and DetaurBar.Data.GetSettings then
        return DetaurBar.Data.GetSettings()
    end
    if DetaurBarDB and DetaurBarDB.settings then
        return DetaurBarDB.settings
    end
    return {}
end

local function IsNamePlate(frame)
    if not frame then return false end
    if frame.RealPlate or frame.extended or frame.UnitFrame or frame.aloftData then
        return true
    end
    local _, r2 = frame:GetRegions()
    return r2 and r2:GetObjectType() == "Texture" and r2:GetTexture() == "Interface\\Tooltips\\Nameplate-Border"
end

local function GetNameRegion(frame)
    if not frame then return nil end
    if frame.extended and frame.extended.regions and frame.extended.regions.name then
        return frame.extended.regions.name
    elseif frame.aloftData and frame.aloftData.nameTextRegion then
        return frame.aloftData.nameTextRegion
    elseif frame.oldName then
        return frame.oldName
    elseif frame.oldname then
        return frame.oldname
    end
    return select(7, frame:GetRegions())
end

local function GetHighlightRegion(frame)
    if not frame then return nil end
    if frame.extended and frame.extended.regions then
        return frame.extended.regions.highlight or frame.extended.regions.highlightTexture
    elseif frame.aloftData and frame.aloftData.highlightRegion then
        return frame.aloftData.highlightRegion
    elseif frame.highlight then
        return frame.highlight
    end
    return select(6, frame:GetRegions())
end

local function StripRealm(name)
    if not name then return name end
    return name:match("^(.+)%-") or name
end

local function PlateMatchesUnit(plate, unit)
    local region = GetNameRegion(plate)
    if not region or not region.GetText then return false end
    local plateName = StripRealm(region:GetText() or "")
    local unitName = StripRealm(UnitName(unit))
    return plateName == unitName
end

local function GetEnemyArmorType(unit)
    if not UnitExists(unit) then return nil end
    if not UnitIsPlayer(unit) then return nil end
    if UnitIsFriend("player", unit) then return nil end
    local classFile = select(2, UnitClass(unit))
    return classFile and CLASS_ARMOR[classFile] or nil
end

local function GetHealthBar(frame)
    if not frame then return nil end
    if frame.extended and frame.extended.bars and frame.extended.bars.health then
        return frame.extended.bars.health
    elseif frame.aloftData and frame.aloftData.healthBar then
        return frame.aloftData.healthBar
    end
    return select(1, frame:GetChildren())
end

-- Class color -> armor type for an arbitrary nameplate, cached per plate.
local function GetPlateArmorType(plate)
    local cached = plateCache[plate]
    local bar = GetHealthBar(plate)
    if not bar or not bar.GetStatusBarColor then
        if cached and cached.sig then
            plateCache[plate] = nil
        end
        return nil
    end
    local r, g, b = bar:GetStatusBarColor()
    local sig = string.format("%d,%d,%d",
        math.floor((r or 0) * 100 + 0.5),
        math.floor((g or 0) * 100 + 0.5),
        math.floor((b or 0) * 100 + 0.5))
    if cached and cached.sig == sig then
        return cached.armor
    end
    local classFile = colorToClass[sig]
    local armor = classFile and CLASS_ARMOR[classFile] or nil
    plateCache[plate] = { sig = sig, armor = armor }
    return armor
end

local function GetOrCreateIcon(plate)
    local icon = plates[plate]
    if icon then return icon end
    icon = CreateFrame("Frame", nil, plate)
    icon:SetSize(22, 22)
    local tex = icon:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(icon)
    icon.tex = tex
    icon:SetPoint("BOTTOM", plate, "TOP", 0, 6)
    icon:SetFrameLevel(plate:GetFrameLevel() or 0)
    icon:Hide()
    plates[plate] = icon
    return icon
end

local function UpdateAllPlateIcon(plate, settings)
    local icon = plates[plate]
    local armorType
    if plate == targetPlate then
        armorType = GetEnemyArmorType("target")
    elseif plate == mousePlate then
        armorType = GetEnemyArmorType("mouseover")
    else
        armorType = GetPlateArmorType(plate)
    end
    if not settings.showArmorEnabled or not armorType then
        if icon then icon:Hide() end
        return
    end
    if settings["armorShow" .. armorType] == false then
        if icon then icon:Hide() end
        return
    end
    local iconPath = settings.armorIcons and settings.armorIcons[armorType]
    if not iconPath then
        if icon then icon:Hide() end
        return
    end
    if not icon then
        icon = GetOrCreateIcon(plate)
    end
    if icon.curPath ~= iconPath then
        icon.tex:SetTexture(iconPath)
        icon.curPath = iconPath
    end
    icon:Show()
end

local scanFrame = CreateFrame("Frame")
scanFrame:Show()
scanFrame:SetScript("OnUpdate", function(self, elapsed)
    self.t = (self.t or 0) + (elapsed or 0)
    if self.t < SCAN_INTERVAL then return end
    self.t = 0

    local settings = GetSettingsTable()
    if not settings.showArmorEnabled then
        for plate, icon in pairs(plates) do
            if icon then icon:Hide() end
        end
        targetPlate = nil
        mousePlate = nil
        return
    end

    wipe(found)
    for i = 1, WorldFrame:GetNumChildren() do
        local child = select(i, WorldFrame:GetChildren())
        if IsNamePlate(child) then
            found[child] = true
        end
    end
    for plate, icon in pairs(plates) do
        if not found[plate] and icon then
            icon:Hide()
        end
    end

    targetPlate = nil
    if UnitExists("target") and UnitIsPlayer("target") and not UnitIsFriend("player", "target") then
        for plate in pairs(found) do
            if plate:IsShown() and plate:GetAlpha() >= 0.99 and PlateMatchesUnit(plate, "target") then
                targetPlate = plate
                break
            end
        end
    end

    mousePlate = nil
    if UnitExists("mouseover") and UnitIsPlayer("mouseover") and not UnitIsFriend("player", "mouseover") then
        for plate in pairs(found) do
            if plate:IsShown() then
                local hl = GetHighlightRegion(plate)
                if hl and hl:IsShown() and hl:GetAlpha() > 0 and PlateMatchesUnit(plate, "mouseover") then
                    mousePlate = plate
                    break
                end
            end
        end
    end

    for plate in pairs(found) do
        UpdateAllPlateIcon(plate, settings)
    end
end)

-- The class is read from the nameplate health bar color, so enemy player
-- nameplates must show class colors. Some clients default this off (bars stay
-- red). Enable it once on login.
local cvFrame = CreateFrame("Frame")
cvFrame:RegisterEvent("PLAYER_LOGIN")
cvFrame:SetScript("OnEvent", function()
    if not GetCVar("ShowClassColorInNameplate") then return end
    if GetCVar("ShowClassColorInNameplate") ~= "1" then
        pcall(SetCVar, "ShowClassColorInNameplate", "1")
        print("DetaurBar: enabled class colors on nameplates (needed for armor icons over all enemies).")
    end
end)
