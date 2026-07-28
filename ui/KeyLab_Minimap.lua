local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Minimap = KeyLab.Minimap or {}

local MinimapButton = KeyLab.Minimap

--[[
KeyLab_Minimap.lua

Purpose:
- Small draggable minimap launcher for the KeyLab window.
- Keeps minimap-button behavior separate from the main UI shell.
]]

local ICON_TEXTURE = "Interface\\Icons\\INV_Misc_Key_05"
local DEFAULT_ANGLE = 225
local DEFAULT_RADIUS = 106
local DRAG_THRESHOLD = 5

local function GetSettings()
    if KeyLab.DB and KeyLab.DB.GetSettingTable then
        return KeyLab.DB.GetSettingTable("minimapIcon")
    end
    return {}
end

local function Atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end

    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi / 2
    elseif x == 0 and y < 0 then
        return -math.pi / 2
    end

    return 0
end

local function ToggleKeyLab()
    if KeyLab.UI and KeyLab.UI.Toggle then
        KeyLab.UI:Toggle()
    elseif KeyLab.Print then
        KeyLab.Print("UI is not available.")
    end
end

local function ShowTooltip(button)
    if not GameTooltip then return end

    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("KeyLab", 0.82, 0.76, 0.58)
    GameTooltip:AddLine("Left-click: open or close KeyLab", 0.94, 0.96, 0.99)
    GameTooltip:AddLine("Drag: move around the minimap", 0.68, 0.73, 0.82)
    GameTooltip:Show()
end

function MinimapButton.UpdatePosition()
    local button = MinimapButton.button
    if not button or not Minimap then return end

    local settings = GetSettings()
    local angle = math.rad(tonumber(settings.angle) or DEFAULT_ANGLE)
    local radius = tonumber(settings.radius) or DEFAULT_RADIUS
    if radius < DEFAULT_RADIUS then
        radius = DEFAULT_RADIUS
        settings.radius = radius
    end
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)

    if settings.hidden == true then
        button:Hide()
    else
        button:Show()
    end
end

function MinimapButton.ToggleHidden()
    local settings = GetSettings()
    settings.hidden = not settings.hidden
    MinimapButton.UpdatePosition()

    if KeyLab.Print then
        KeyLab.Print("Minimap icon " .. (settings.hidden and "hidden. Use /keylab minimap to show it again." or "shown."))
    end
end

function MinimapButton.Create()
    if MinimapButton.button or not Minimap then
        return MinimapButton.button
    end

    local button = CreateFrame("Button", "KeyLabMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
    button:RegisterForClicks("LeftButtonUp")
    button:EnableMouse(true)

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture(ICON_TEXTURE)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetSize(22, 22)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("CENTER", button, "CENTER", 10, -10)
    border:SetSize(54, 54)
    button.border = border

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(button)
    button.highlight = highlight

    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    button:SetScript("OnMouseDown", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            self.dragging = true
            self.wasDragged = false
            local startX, startY = GetCursorPosition()
            self.dragStartX = startX or 0
            self.dragStartY = startY or 0
            self:SetScript("OnUpdate", function(frame)
                if not frame.dragging or not Minimap then return end

                local centerX, centerY = Minimap:GetCenter()
                local cursorX, cursorY = GetCursorPosition()
                local rawDx = (cursorX or 0) - (frame.dragStartX or 0)
                local rawDy = (cursorY or 0) - (frame.dragStartY or 0)
                if not frame.wasDragged and ((rawDx * rawDx) + (rawDy * rawDy)) < (DRAG_THRESHOLD * DRAG_THRESHOLD) then
                    return
                end

                local scale = UIParent and UIParent:GetEffectiveScale() or 1
                cursorX = cursorX / scale
                cursorY = cursorY / scale

                local angle = math.deg(Atan2(cursorY - centerY, cursorX - centerX))
                local settings = GetSettings()
                settings.angle = angle
                settings.radius = DEFAULT_RADIUS
                frame.wasDragged = true
                MinimapButton.UpdatePosition()
            end)
        end
    end)

    button:SetScript("OnMouseUp", function(self, mouseButton)
        if mouseButton ~= "LeftButton" then return end

        local wasDragged = self.wasDragged == true
        self.dragging = false
        self.wasDragged = false
        self.dragStartX = nil
        self.dragStartY = nil
        self:SetScript("OnUpdate", nil)

        if not wasDragged then
            ToggleKeyLab()
        end
    end)

    MinimapButton.button = button
    MinimapButton.UpdatePosition()
    return button
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
    MinimapButton.Create()
end)

return MinimapButton
