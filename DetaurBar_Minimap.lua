-- DetaurBar_Minimap.lua
-- Minimap button with drag-to-reposition.

DetaurBar = DetaurBar or {}
if not DetaurBar.UI then DetaurBar.UI = {} end

local minimapButton = CreateFrame("Button", "DetaurBarMinimapButton", Minimap)
minimapButton:SetSize(31, 31)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local minimapIcon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapIcon:SetSize(20, 20)
minimapIcon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
minimapIcon:SetTexture("Interface\\Icons\\Spell_Nature_BloodLust")
minimapButton.icon = minimapIcon

local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetSize(53, 53)
minimapBorder:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", -2, 1)
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapButton.border = minimapBorder

function DetaurBar.UI.UpdateMinimapPosition()
    local angle = DetaurBarDB and DetaurBarDB.minimapAngle or 45
    local x = math.cos(math.rad(angle)) * 80
    local y = math.sin(math.rad(angle)) * 80
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function(self)
        local mx, my = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        mx, my = mx / scale, my / scale
        local cx, cy = Minimap:GetCenter()

        local dy = my - cy
        local dx = mx - cx
        local angle = math.deg(math.atan2(dy, dx))

        if DetaurBarDB then
            DetaurBarDB.minimapAngle = angle
        end
        DetaurBar.UI.UpdateMinimapPosition()
    end)
end)

minimapButton:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        DetaurBar.UI.ToggleVisibility()
    elseif button == "RightButton" then
        if DetaurBar.Enemy and DetaurBar.Enemy.ToggleMonitor then
            DetaurBar.Enemy.ToggleMonitor()
        end
    end
end)

minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("DetaurBar", 1.0, 0.82, 0.0)
    GameTooltip:AddLine("Left-click to toggle organizer.", 1.0, 1.0, 1.0)
    GameTooltip:AddLine("Right-click to toggle enemy monitor.", 1.0, 1.0, 1.0)
    GameTooltip:AddLine("Drag to reposition around the minimap.", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

minimapButton:Show()
DetaurBar.UI.UpdateMinimapPosition()
