-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

StoneGrid_Minimap = {}

local btn
local dragging = false
local dragMoved = false
local dragStartX, dragStartY
local MINIMAP_RADIUS = 80
local DRAG_THRESHOLD_SQ = 16
local DEG = math.pi / 180

local function Rad(deg)
    return deg * DEG
end

local function Deg(rad)
    return rad / DEG
end

local function GetAngle()
    return StoneGrid_Config and StoneGrid_Config.MinimapAngle or 220
end

local function SetPosition(angle)
    if not btn or not Minimap then return end
    angle = angle % 360
    if angle < 0 then angle = angle + 360 end
    local rad = Rad(angle)
    local x = math.cos(rad) * MINIMAP_RADIUS
    local y = math.sin(rad) * MINIMAP_RADIUS
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function UpdateDrag()
    if not dragging or not btn or not Minimap then return end
    local cx, cy = GetCursorPosition()
    if not dragMoved then
        local dx = cx - dragStartX
        local dy = cy - dragStartY
        if dx * dx + dy * dy < DRAG_THRESHOLD_SQ then return end
        dragMoved = true
    end
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    local angle = Deg(math.atan2(cy - my, cx - mx))
    if StoneGrid_Config then
        StoneGrid_Config.MinimapAngle = angle
    end
    SetPosition(angle)
end

function StoneGrid_Minimap:UpdateVisibility()
    if not btn then return end
    if StoneGrid_Config and StoneGrid_Config.ShowMinimapButton == false then
        btn:Hide()
        return
    end
    SetPosition(GetAngle())
    btn:Show()
end

function StoneGrid_Minimap:Init()
    if btn then
        self:UpdateVisibility()
        return
    end
    if not Minimap then return end

    btn = CreateFrame("Button", "StoneGridMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("HIGH")
    btn:SetFrameLevel(8)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp")

    btn:SetNormalTexture("Interface\\Icons\\INV_Misc_StoneTablet_02")
    local normal = btn:GetNormalTexture()
    if normal then
        normal:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        normal:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -5)
        normal:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -7, 5)
    end

    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

    btn:SetScript("OnEnter", function(self)
        local locs = StoneGrid_Locales or {}
        local lang = (StoneGrid_Config and StoneGrid_Config.Language) or GetLocale()
        if lang == "enGB" then lang = "enUS" end
        local L = locs[lang] or locs["enUS"] or {}
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L.MinimapTooltipTitle or "StoneGrid")
        GameTooltip:AddLine(L.MinimapTooltipClick or "Left-click: settings", 1, 1, 1)
        GameTooltip:AddLine(L.MinimapTooltipDrag or "Drag: move icon", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    btn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            dragStartX, dragStartY = GetCursorPosition()
            dragging = true
            dragMoved = false
            self:SetScript("OnUpdate", UpdateDrag)
        end
    end)

    btn:SetScript("OnClick", function(_, button)
        if button == "LeftButton" and not dragMoved and StoneGrid_ToggleMenu then
            StoneGrid_ToggleMenu()
        end
        dragMoved = false
    end)

    btn:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:SetScript("OnUpdate", nil)
            dragging = false
            if dragMoved and StoneGrid_Profiles_Save then
                StoneGrid_Profiles_Save()
            end
        end
    end)

    self:UpdateVisibility()
end
