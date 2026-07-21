-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

StoneGrid_DungeonDebuffs = {}

local DDDB = StoneGrid_DungeonDebuffsDB or {}

local MODULE_KEYS = { "Classic", "The Burning Crusade", "The Lich King" }

local curZone
local spells_order = {}

local function GetCurrentZone()
    local current_zone_on_worldmap = GetCurrentMapAreaID() - 1
    SetMapToCurrentZone()
    local zone = GetCurrentMapAreaID() - 1
    if zone ~= current_zone_on_worldmap then
        SetMapByID(current_zone_on_worldmap)
    end
    return zone
end

local function CollectZoneSpells(cfg, zone)
    wipe(spells_order)
    if not zone or not cfg then return end

    local order = 0
    for _, module in ipairs(MODULE_KEYS) do
        local instances = DDDB[module]
        local instance = instances and instances[zone]
        if instance then
            for _, spells in pairs(instance) do
                for _, spellId in ipairs(spells) do
                    order = order + 1
                    local name = GetSpellInfo(spellId)
                    if name then
                        local key = name:lower()
                        if not spells_order[key] then
                            spells_order[key] = order
                        end
                    end
                end
            end
        end
    end

    local custom = cfg.DungeonDebuffCustom
    if custom and custom ~= "" then
        for part in custom:gmatch("[^,]+") do
            local spellId = tonumber(part:match("^%s*(.-)%s*$"))
            if spellId then
                order = order + 1
                local name = GetSpellInfo(spellId)
                if name then
                    local key = name:lower()
                    if not spells_order[key] then
                        spells_order[key] = order
                    end
                end
            end
        end
    end
end

function StoneGrid_DungeonDebuffs:UpdateZoneSpells()
    local cfg = StoneGrid_Config
    if not cfg then return end
    curZone = GetCurrentZone()
    CollectZoneSpells(cfg, curZone)
end

function StoneGrid_DungeonDebuffs:FindDungeonDebuff(unit)
    if not next(spells_order) then return end

    local bestOrder, bestIcon, bestDur, bestExp, bestName = 99999
    for i = 1, 40 do
        local name, _, icon, _, _, duration, expirationTime = UnitDebuff(unit, i)
        if not name then break end
        local order = spells_order[name:lower()]
        if order and order < bestOrder then
            bestOrder = order
            bestIcon = icon
            bestDur = duration or 0
            bestExp = expirationTime or 0
            bestName = name
        end
    end

    if bestIcon then
        return bestIcon, bestDur, bestExp, bestName
    end
end

function StoneGrid_DungeonDebuffs:IsDungeonDebuff(name)
    if not name or not next(spells_order) then return false end
    return spells_order[name:lower()] ~= nil
end

function StoneGrid_DungeonDebuffs:InitDefaults(cfg)
    if cfg.DungeonDebuffCustom == nil then
        if cfg.PartyDebuffCustom ~= nil then
            cfg.DungeonDebuffCustom = cfg.PartyDebuffCustom
        else
            cfg.DungeonDebuffCustom = ""
        end
    end
end
