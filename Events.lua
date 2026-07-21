-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

StoneGrid_Events = CreateFrame("Frame")
local deferredUnits = {}
local healCommHooked = false

local function DeferUnitUpdate(unit)
    if unit then deferredUnits[unit] = true end
end

local function IsTrackedUnit(unit)
    return StoneGrid_Party.frames[unit] or StoneGrid_Party.petFrames[unit]
        or StoneGrid_Raid.frames[unit] or StoneGrid_Raid.petFrames[unit]
end

local function EnsureHealCommHooks()
    if healCommHooked then return end
    local hc = LibStub and LibStub("LibHealComm-4.0", true)
    if not hc then return end
    healCommHooked = true

    local function OnHealUpdate(event, arg1, arg2, arg3, arg4, ...)
        if not StoneGrid_Config then return end

        if event == "HealComm_ModifierChanged" then
            -- Fire("HealComm_ModifierChanged", guid, modifier) -- only this
            -- one unit's prediction changed, nothing else needs a refresh.
            local unit = arg1 and StoneGrid:GetUnitByGUID(arg1)
            if unit then StoneGrid:UpdateHealBar(unit) end
            return
        end

        -- HealStarted/HealUpdated/HealDelayed/HealStopped all fire as
        -- (casterGUID, spellID, bitType, endTime/interrupted, ...destGUIDs).
        -- Update exactly the units whose predicted heal changed instead of
        -- sweeping every tile in the party/raid on every single tick.
        for i = 1, select("#", ...) do
            local guid = select(i, ...)
            if type(guid) == "string" and guid ~= "" then
                local unit = StoneGrid:GetUnitByGUID(guid)
                if unit then StoneGrid:UpdateHealBar(unit) end
            end
        end
    end

    hc.RegisterCallback(StoneGrid_Events, "HealComm_HealStarted", OnHealUpdate)
    hc.RegisterCallback(StoneGrid_Events, "HealComm_HealUpdated", OnHealUpdate)
    hc.RegisterCallback(StoneGrid_Events, "HealComm_HealDelayed", OnHealUpdate)
    hc.RegisterCallback(StoneGrid_Events, "HealComm_HealStopped", OnHealUpdate)
    hc.RegisterCallback(StoneGrid_Events, "HealComm_ModifierChanged", OnHealUpdate)
end

StoneGrid_Events:RegisterEvent("ADDON_LOADED")
StoneGrid_Events:RegisterEvent("PLAYER_ENTERING_WORLD")
StoneGrid_Events:RegisterEvent("PARTY_MEMBERS_CHANGED")
StoneGrid_Events:RegisterEvent("RAID_ROSTER_UPDATE")
StoneGrid_Events:RegisterEvent("UNIT_PET")
StoneGrid_Events:RegisterEvent("UNIT_HEALTH")
StoneGrid_Events:RegisterEvent("UNIT_MAXHEALTH")
StoneGrid_Events:RegisterEvent("UNIT_CONNECTION")
StoneGrid_Events:RegisterEvent("UNIT_POWER")
StoneGrid_Events:RegisterEvent("UNIT_MAXPOWER")
StoneGrid_Events:RegisterEvent("UNIT_DISPLAYPOWER")
StoneGrid_Events:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
StoneGrid_Events:RegisterEvent("UNIT_AURA")
StoneGrid_Events:RegisterEvent("UNIT_SPELLCAST_START")
StoneGrid_Events:RegisterEvent("UNIT_SPELLCAST_STOP")
StoneGrid_Events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
StoneGrid_Events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
StoneGrid_Events:RegisterEvent("PLAYER_REGEN_ENABLED")
StoneGrid_Events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
StoneGrid_Events:RegisterEvent("RAID_TARGET_UPDATE")
StoneGrid_Events:RegisterEvent("PLAYER_TARGET_CHANGED")
StoneGrid_Events:RegisterEvent("ZONE_CHANGED_NEW_AREA")

StoneGrid_Events:SetScript("OnEvent", function(_, event, ...)
    local arg1 = ...

    if event == "ADDON_LOADED" and arg1 == "StoneGrid" then
        StoneGrid_Profiles_Init()
        StoneGrid_Config_Init()
        StoneGrid_ApplyBlizzardPartyFrames()
        if StoneGrid_PvpDebuffs then StoneGrid_PvpDebuffs:ReloadLookup() end
        if StoneGrid_DungeonDebuffs then StoneGrid_DungeonDebuffs:UpdateZoneSpells() end
        if StoneGrid_RaidDebuffs then StoneGrid_RaidDebuffs:UpdateZoneSpells() end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00StoneGrid|r zaladowany. /sg = menu")
        EnsureHealCommHooks()
    end

    if event == "PLAYER_ENTERING_WORLD" then
        if StoneGrid_Minimap then StoneGrid_Minimap:Init() end
        EnsureHealCommHooks()
        StoneGrid_ApplyBlizzardPartyFrames()
        if StoneGrid_Config and (not StoneGrid_Test or not StoneGrid_Test:IsActive()) then
            StoneGrid:UpdateLayout()
            StoneGrid:UpdateAll()
        end
    end

    if event == "PARTY_MEMBERS_CHANGED"
    or event == "RAID_ROSTER_UPDATE"
    or event == "UNIT_PET"
    or event == "ZONE_CHANGED_NEW_AREA" then
        if StoneGrid_DungeonDebuffs then StoneGrid_DungeonDebuffs:UpdateZoneSpells() end
        if StoneGrid_RaidDebuffs then StoneGrid_RaidDebuffs:UpdateZoneSpells() end
        StoneGrid_ApplyBlizzardPartyFrames()
        if not InCombatLockdown() then
            StoneGrid:UpdateLayout()
        else
            StoneGrid._pendingLayout = true
        end
    end

    if event == "UNIT_HEALTH"
    or event == "UNIT_MAXHEALTH"
    or event == "UNIT_CONNECTION"
    or event == "UNIT_POWER"
    or event == "UNIT_MAXPOWER"
    or event == "UNIT_DISPLAYPOWER" then
        if StoneGrid_Config then
            StoneGrid:UpdateUnit(arg1)
            if event == "UNIT_DISPLAYPOWER" then
                DeferUnitUpdate(arg1)
            end
            if event == "UNIT_HEALTH" and arg1 == "player" and StoneGrid_CombatLog then
                StoneGrid_CombatLog:OnPlayerHealth()
            end
        end
    end

    if event == "UPDATE_SHAPESHIFT_FORM" then
        if StoneGrid_Config then
            StoneGrid:UpdateUnit("player")
            DeferUnitUpdate("player")
        end
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if StoneGrid_CombatLog then StoneGrid_CombatLog:RecordEvent() end
        if not StoneGrid_Config then return end
        local subEvent = select(2, ...)
        if subEvent == "SWING_DAMAGE"
        or subEvent == "SPELL_DAMAGE"
        or subEvent == "RANGE_DAMAGE"
        or subEvent == "SPELL_PERIODIC_DAMAGE"
        or subEvent == "DAMAGE_SHIELD"
        or subEvent == "ENVIRONMENTAL_DAMAGE"
        or subEvent == "UNIT_DIED"
        or subEvent == "SPELL_HEAL"
        or subEvent == "SPELL_PERIODIC_HEAL"
        or subEvent == "SPELL_AURA_APPLIED"
        or subEvent == "SPELL_AURA_REFRESH"
        or subEvent == "SPELL_AURA_APPLIED_DOSE"
        or subEvent == "SPELL_AURA_REMOVED" then
            -- args after "subEvent" are: sourceGUID, sourceName, sourceFlags,
            -- destGUID, destName, destFlags, ... (3.3.5a has no raid-flag
            -- fields). destGUID is therefore select(6, ...), NOT select(8, ...)
            -- -- the old code was reading destFlags as if it were destGUID,
            -- which meant GetUnitByGUID() never matched anything and this
            -- whole "instant update" branch was silently dead for everyone.
            local destGUID = select(6, ...)
            local unit = destGUID and StoneGrid:GetUnitByGUID(destGUID)
            if unit then
                if subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL" then
                    StoneGrid:UpdateHealBar(unit)
                elseif (StoneGrid_Config.ShowOwnHot or StoneGrid_Config.IncludeOthersHot)
                and (subEvent == "SPELL_AURA_APPLIED"
                  or subEvent == "SPELL_AURA_REFRESH"
                  or subEvent == "SPELL_AURA_APPLIED_DOSE"
                  or subEvent == "SPELL_AURA_REMOVED") then
                    local sourceGUID = select(3, ...)
                    if sourceGUID == UnitGUID("player") then
                        StoneGrid:UpdateHealBar(unit)
                    end
                else
                    StoneGrid:UpdateUnit(unit)
                end
                if subEvent == "UNIT_DIED" then StoneGrid:UpdateAuras(unit) end
            end
        end
    end

    if event == "UNIT_SPELLCAST_START" and IsTrackedUnit(arg1) then
        if StoneGrid_Config then StoneGrid:UpdateHealBars() end
    end

    if (event == "UNIT_SPELLCAST_STOP"
     or event == "UNIT_SPELLCAST_INTERRUPTED"
     or event == "UNIT_SPELLCAST_SUCCEEDED") and IsTrackedUnit(arg1) then
        if StoneGrid_Config then StoneGrid:UpdateHealBars() end
    end

    if event == "UNIT_AURA" then
        if StoneGrid_Config then
            StoneGrid:UpdateAuras(arg1)
            if (StoneGrid_Config.ShowOwnHot or StoneGrid_Config.IncludeOthersHot) and IsTrackedUnit(arg1) then
                StoneGrid:UpdateHealBar(arg1)
            end
        end
    end

    if event == "RAID_TARGET_UPDATE" then
        if StoneGrid_Config then StoneGrid:UpdateAllRaidIcons() end
    end

    if event == "PLAYER_TARGET_CHANGED" then
        if StoneGrid_Config then StoneGrid:UpdateBorderColors() end
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if StoneGrid_Config then
            if StoneGrid._pendingBlizzardPartyHide then
                StoneGrid._pendingBlizzardPartyHide = nil
                StoneGrid_ApplyBlizzardPartyFrames()
            end
            if StoneGrid._pendingLayout then
                StoneGrid._pendingLayout = false
                StoneGrid:UpdateLayout()
            else
                StoneGrid:UpdateAll()
            end
        end
    end
end)

local _rangeTimer = 0
local _castRefreshTimer = 0
local CAST_HEALBAR_REFRESH_INTERVAL = 0.15
StoneGrid_Events:SetScript("OnUpdate", function(_, dt)
    if StoneGrid_Config and UnitCastingInfo("player") then
        _castRefreshTimer = _castRefreshTimer + dt
        if _castRefreshTimer >= CAST_HEALBAR_REFRESH_INTERVAL then
            _castRefreshTimer = 0
            StoneGrid:UpdateHealBars()
        end
    else
        -- Not casting right now -- reset so the *next* cast start refreshes
        -- immediately instead of waiting out a stale partial interval.
        _castRefreshTimer = CAST_HEALBAR_REFRESH_INTERVAL
    end

    local deferred = deferredUnits
    if next(deferred) then
        for unit in pairs(deferred) do
            StoneGrid:UpdateUnit(unit)
            deferred[unit] = nil
        end
    end

    _rangeTimer = _rangeTimer + dt
    if _rangeTimer >= 0.5 then
        _rangeTimer = 0
        StoneGrid:UpdateAllRanges()
        StoneGrid:UpdateAllPowerBars()
        StoneGrid:UpdateHealBars()
    end
end)
