-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

StoneGrid_Utils = {}

function StoneGrid_Utils:IsValidUnit(unit)
    return UnitExists(unit)
end

local function SafeHideFrame(frame)
    if not frame then return end
    if InCombatLockdown() then
        if StoneGrid then StoneGrid._pendingBlizzardPartyHide = true end
        return
    end
    frame:Hide()
end

local function InstallPartyHideHook(frame)
    if not frame or frame._StoneGridPartyHooked then return end
    frame._StoneGridPartyHooked = true
    frame:UnregisterAllEvents()
    frame:SetScript("OnShow", function(self)
        SafeHideFrame(self)
    end)
end

local function HideBlizzardPartyFrame(frame)
    if not frame then return end
    InstallPartyHideHook(frame)
    SafeHideFrame(frame)
end

function StoneGrid_ApplyBlizzardPartyFrames()
    if not StoneGrid_Config or not StoneGrid_Config.HideBlizzardPartyFrames then return end

    if InCombatLockdown() then
        if StoneGrid then StoneGrid._pendingBlizzardPartyHide = true end
        for i = 1, 4 do
            InstallPartyHideHook(_G["PartyMemberFrame"..i])
            InstallPartyHideHook(_G["PartyMemberFrame"..i.."PetFrame"])
        end
        local bg = _G.PartyMemberBackground
        if bg then InstallPartyHideHook(bg) end
        return
    end

    if StoneGrid then StoneGrid._pendingBlizzardPartyHide = nil end

    for i = 1, 4 do
        HideBlizzardPartyFrame(_G["PartyMemberFrame"..i])
        HideBlizzardPartyFrame(_G["PartyMemberFrame"..i.."PetFrame"])
    end

    local bg = _G.PartyMemberBackground
    if bg then HideBlizzardPartyFrame(bg) end
end
