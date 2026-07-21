-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

StoneGrid_PvpDebuffs = {}

local PRIORITY_BY_NAME = {}
local lookupSignature = ""

local function AddSpell(pri, spellId)
    local name = GetSpellInfo(spellId)
    if not name then return end
    local key = name:lower()
    if not PRIORITY_BY_NAME[key] or pri < PRIORITY_BY_NAME[key] then
        PRIORITY_BY_NAME[key] = pri
    end
end

local function BuildLookup()
    local custom = (StoneGrid_Config and StoneGrid_Config.PvpDebuffCustom) or ""
    if next(PRIORITY_BY_NAME) and lookupSignature == custom then return end

    lookupSignature = custom
    wipe(PRIORITY_BY_NAME)

    for _, entry in ipairs(StoneGrid_PvpDebuffsDB or {}) do
        AddSpell(entry[1], entry[2])
    end

    if custom ~= "" then
        for part in custom:gmatch("[^,]+") do
            local spellId = tonumber(part:match("^%s*(.-)%s*$"))
            if spellId then
                AddSpell(1, spellId)
            end
        end
    end
end

function StoneGrid_PvpDebuffs:FindDebuff(unit)
    BuildLookup()
    local bestIcon, bestDur, bestExp, bestPri = nil, nil, nil, 999
    for i = 1, 40 do
        local name, _, icon, _, _, duration, expirationTime = UnitDebuff(unit, i)
        if not name then break end
        local pri = PRIORITY_BY_NAME[name:lower()]
        if pri and pri < bestPri then
            bestIcon = icon
            bestDur = duration or 0
            bestExp = expirationTime or 0
            bestPri = pri
        end
    end
    if bestIcon then
        return bestIcon, bestDur, bestExp
    end
end

function StoneGrid_PvpDebuffs:IsPvpDebuff(name)
    if not name then return false end
    BuildLookup()
    return PRIORITY_BY_NAME[name:lower()] ~= nil
end

function StoneGrid_PvpDebuffs:InitDefaults(cfg)
    if cfg.PvpDebuffCustom == nil then cfg.PvpDebuffCustom = "" end
end

function StoneGrid_PvpDebuffs:ReloadLookup()
    lookupSignature = ""
    wipe(PRIORITY_BY_NAME)
    BuildLookup()
end
