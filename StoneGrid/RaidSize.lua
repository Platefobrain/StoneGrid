-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

StoneGrid_RaidSizes = { "10", "15", "25", "40" }
StoneGrid_AuraSizes = { "5", "10", "15", "25", "40" }

StoneGrid_RaidLayoutKeys = {
    "RaidWidth", "RaidHeight", "RaidSpacing", "RaidColumns", "RaidX", "RaidY",
    "ShowRaidPowerBar", "RaidPowerBarH",
    "ShowRaidStuns", "RaidCcIconSize",
    "ShowRaidPets", "RaidPetWidth", "RaidPetHeight", "RaidPetSpacing",
    "RaidPetColumns", "RaidPetPosition", "RaidPetMax",
}

local PVP_MAP_FILE_SIZE = {
    WarsongGulch = "10",
    ArathiBasin = "15",
    NetherstormArena = "15",
    AlteracValley = "40",
    StrandoftheAncients = "15",
    IsleofConquest = "40",
}

-- GetInstanceInfo() instanceMapId (WotLK 3.3+), most reliable in BG
local PVP_INSTANCE_MAP_SIZE = {
    [489] = "10", -- Warsong Gulch
    [529] = "15", -- Arathi Basin
    [566] = "15", -- Eye of the Storm
    [30]  = "40", -- Alterac Valley
    [607] = "15", -- Strand of the Ancients
    [628] = "40", -- Isle of Conquest
}

-- Localized zone / instance names
local PVP_ZONE_SIZE = {
    ["Warsong Gulch"] = "10",
    ["Arathi Basin"] = "15",
    ["Eye of the Storm"] = "15",
    ["Alterac Valley"] = "40",
    ["Strand of the Ancients"] = "15",
    ["Isle of Conquest"] = "40",
    ["Arathibecken"] = "15",
    ["Auge des Sturms"] = "15",
    ["Kriegshymnenschlucht"] = "10",
    ["Bassin d'Arathi"] = "15",
    ["L'Œil du cyclone"] = "15",
    ["Goulet des Chanteguerres"] = "10",
    ["Oko Burzy"] = "15",
    ["Низина Арати"] = "15",
    ["Око Бури"] = "15",
    ["Ущелье Песни Войны"] = "10",
    ["Dolina Arathi"] = "15",
    ["Dolina Alterac"] = "40",
    ["Brzeg Starozytnych"] = "15",
    ["Brzeg Starożytnych"] = "15",
    ["Ujscie Warsongow"] = "10",
    ["Ujście Warsongów"] = "10",
    ["Wyspa Konkordii"] = "40",
    ["Insel der Eroberung"] = "40",
    ["Ile de la Conquete"] = "40",
    ["Ile de la Conquête"] = "40",
}

local PVP_MAXPLAYERS_SIZE = {
    [10] = "10", [15] = "15", [25] = "25", [40] = "40",
    [20] = "10", [30] = "15", [50] = "25", [80] = "40",
}

local function RaidGroupCount()
    local n = GetNumRaidMembers()
    if n > 0 then return n + 1 end
    n = GetNumPartyMembers()
    if n > 0 then return n + 1 end
    return 0
end

local function BucketByCount(count)
    if count <= 10 then return "10" end
    if count <= 15 then return "15" end
    if count <= 25 then return "25" end
    return "40"
end

local function BucketByGroupCount(count, ...)
    for i = select("#", ...) - 1, 1, -1 do
        if count > select(i, ...) then
            return tostring(select(i + 1, ...))
        end
    end
    return "10"
end

local function DetectPvpMapSize()
    if SetMapToCurrentZone then
        SetMapToCurrentZone()
    end
    if GetMapInfo then
        local mapName, fileName = GetMapInfo()
        if fileName and PVP_MAP_FILE_SIZE[fileName] then
            return PVP_MAP_FILE_SIZE[fileName]
        end
        if mapName and PVP_MAP_FILE_SIZE[mapName] then
            return PVP_MAP_FILE_SIZE[mapName]
        end
    end
end

local function DetectPvpZoneName(name)
    if not name or name == "" then return nil end
    if PVP_ZONE_SIZE[name] then return PVP_ZONE_SIZE[name] end
    return nil
end

local function DetectPvpMaxPlayersSize(maxPlayers)
    if not maxPlayers or maxPlayers <= 0 then return nil end
    if PVP_MAXPLAYERS_SIZE[maxPlayers] then
        return PVP_MAXPLAYERS_SIZE[maxPlayers]
    end
    if maxPlayers <= 10 then return "10" end
    if maxPlayers <= 15 then return "15" end
    if maxPlayers <= 20 then return "10" end
    if maxPlayers <= 30 then return "15" end
    if maxPlayers <= 40 then return "40" end
    if maxPlayers <= 50 then return "25" end
    return "40"
end

local function DetectBattlegroundSize()
    local name, instType, _, _, maxPlayers, _, _, instanceMapId = GetInstanceInfo()

    if instanceMapId and PVP_INSTANCE_MAP_SIZE[instanceMapId] then
        return PVP_INSTANCE_MAP_SIZE[instanceMapId]
    end

    local zoneSize = DetectPvpZoneName(name)
    if zoneSize then return zoneSize end

    if GetRealZoneText then
        zoneSize = DetectPvpZoneName(GetRealZoneText())
        if zoneSize then return zoneSize end
    end

    if GetZoneText then
        zoneSize = DetectPvpZoneName(GetZoneText())
        if zoneSize then return zoneSize end
    end

    if IsInInstance() then
        zoneSize = DetectPvpMapSize()
        if zoneSize then return zoneSize end
    end

    if instType == "pvp" or instType == "none" or IsInInstance() then
        zoneSize = DetectPvpMaxPlayersSize(maxPlayers)
        if zoneSize then return zoneSize end
    end

    return nil
end

function StoneGrid_DetectRaidSize()
    if GetNumRaidMembers() == 0 then return nil end

    local bgSize = DetectBattlegroundSize()
    if bgSize then return bgSize end

    local inInstance, instType = IsInInstance()
    if inInstance and instType == "pvp" then
        return BucketByGroupCount(RaidGroupCount(), 0, 10, 15, 25, 40)
    end

    if inInstance and instType == "arena" then
        local maxPlayers = select(5, GetInstanceInfo())
        if maxPlayers and maxPlayers > 0 then
            return BucketByCount(maxPlayers)
        end
        return "10"
    end

    if inInstance and instType == "raid" then
        local maxPlayers = select(5, GetInstanceInfo())
        if maxPlayers and maxPlayers > 0 then
            return BucketByCount(maxPlayers)
        end
    end

    return BucketByGroupCount(RaidGroupCount(), 0, 10, 25, 40)
end

function StoneGrid_RaidSizeDefaults(base)
    base = base or {}
    return {
        RaidWidth = base.RaidWidth or 80,
        RaidHeight = base.RaidHeight or 20,
        RaidSpacing = base.RaidSpacing or 3,
        RaidColumns = base.RaidColumns or 5,
        RaidX = base.RaidX or 0,
        RaidY = base.RaidY or 0,
        ShowRaidPowerBar = base.ShowRaidPowerBar or false,
        RaidPowerBarH = base.RaidPowerBarH or 3,
        ShowRaidStuns = base.ShowRaidStuns ~= false,
        RaidCcIconSize = base.RaidCcIconSize or 16,
        ShowRaidPets = base.ShowRaidPets or false,
        RaidPetWidth = base.RaidPetWidth or 80,
        RaidPetHeight = base.RaidPetHeight or 14,
        RaidPetSpacing = base.RaidPetSpacing or 2,
        RaidPetColumns = base.RaidPetColumns or 5,
        RaidPetPosition = base.RaidPetPosition or "BOTTOM",
        RaidPetMax = base.RaidPetMax or 0,
    }
end

function StoneGrid_RaidSizeInitDefaults(cfg)
    if cfg.RaidEditSize == nil then cfg.RaidEditSize = "25" end
    if cfg.RaidSizeAuto == nil then cfg.RaidSizeAuto = true end

    if cfg.RaidBySize == nil then
        cfg.RaidBySize = {}
        local base = StoneGrid_RaidSizeDefaults(cfg)
        for _, sz in ipairs(StoneGrid_RaidSizes) do
            local preset = StoneGrid_RaidSizeDefaults(base)
            preset.RaidPetMax = tonumber(sz) or 0
            cfg.RaidBySize[sz] = preset
        end
        cfg.RaidBySize["10"].RaidWidth = 100
        cfg.RaidBySize["10"].RaidHeight = 24
        cfg.RaidBySize["15"].RaidWidth = 90
        cfg.RaidBySize["15"].RaidHeight = 22
        cfg.RaidBySize["40"].RaidWidth = 60
        cfg.RaidBySize["40"].RaidHeight = 16
        cfg.RaidBySize["40"].RaidColumns = 8
        cfg.RaidBySize["40"].RaidCcIconSize = 14
    end

    for _, sz in ipairs(StoneGrid_RaidSizes) do
        if cfg.RaidBySize[sz] == nil then
            cfg.RaidBySize[sz] = StoneGrid_RaidSizeDefaults(cfg)
        elseif cfg.RaidBySize[sz].RaidPetMax == nil then
            cfg.RaidBySize[sz].RaidPetMax = tonumber(sz) or 0
        end
    end
end

function StoneGrid_GetRaidPreset(cfg, sizeKey)
    if not cfg or not cfg.RaidBySize then
        return StoneGrid_RaidSizeDefaults(cfg)
    end
    return cfg.RaidBySize[sizeKey] or cfg.RaidBySize["25"] or StoneGrid_RaidSizeDefaults(cfg)
end

function StoneGrid_GetActiveRaidSize(cfg)
    if cfg and cfg.RaidSizeAuto == false and cfg.RaidEditSize then
        return cfg.RaidEditSize
    end
    return StoneGrid_DetectRaidSize() or cfg.RaidEditSize or "25"
end

function StoneGrid_GetActiveRaidLayout(cfg)
    local sizeKey = StoneGrid_GetActiveRaidSize(cfg)
    local preset = StoneGrid_GetRaidPreset(cfg, sizeKey)
    local layout = {}
    for _, key in ipairs(StoneGrid_RaidLayoutKeys) do
        if preset[key] ~= nil then
            layout[key] = preset[key]
        elseif cfg[key] ~= nil then
            layout[key] = cfg[key]
        end
    end
    layout._sizeKey = sizeKey
    return layout
end

function StoneGrid_SyncFlatRaidFromPreset(cfg, sizeKey)
    local preset = StoneGrid_GetRaidPreset(cfg, sizeKey)
    for _, key in ipairs(StoneGrid_RaidLayoutKeys) do
        if preset[key] ~= nil then
            cfg[key] = preset[key]
        end
    end
end

StoneGrid_BuffIconLayoutKeys = { "BuffIconSize" }
StoneGrid_DebuffIconLayoutKeys = { "DebuffIconSize" }

local AURA_ICON_DEFAULTS = {
    ["5"]  = 14,
    ["10"] = 14,
    ["15"] = 13,
    ["25"] = 12,
    ["40"] = 10,
}

local function UsingRaidFrames()
    if GetNumRaidMembers() == 0 then return false end
    local inInstance, instType = IsInInstance()
    if inInstance and instType == "arena" then return false end
    return true
end

function StoneGrid_BuffIconSizeDefaults(base)
    base = base or {}
    return {
        BuffIconSize = base.BuffIconSize or 12,
        BuffMaxIcons = base.BuffMaxIcons or 4,
    }
end

function StoneGrid_DebuffIconSizeDefaults(base)
    base = base or {}
    return {
        DebuffIconSize = base.DebuffIconSize or 12,
        DebuffMaxIcons = base.DebuffMaxIcons or 4,
    }
end

function StoneGrid_AuraSizeInitDefaults(cfg)
    if cfg.BuffEditSize == nil then cfg.BuffEditSize = "25" end
    if cfg.DebuffEditSize == nil then cfg.DebuffEditSize = "25" end

    if cfg.BuffBySize == nil then
        cfg.BuffBySize = {}
        for _, sz in ipairs(StoneGrid_AuraSizes) do
            cfg.BuffBySize[sz] = {
                BuffIconSize = AURA_ICON_DEFAULTS[sz] or cfg.BuffIconSize or 12,
                BuffMaxIcons = cfg.BuffMaxIcons or 4,
            }
        end
    end

    if cfg.DebuffBySize == nil then
        cfg.DebuffBySize = {}
        for _, sz in ipairs(StoneGrid_AuraSizes) do
            cfg.DebuffBySize[sz] = {
                DebuffIconSize = AURA_ICON_DEFAULTS[sz] or cfg.DebuffIconSize or 12,
                DebuffMaxIcons = cfg.DebuffMaxIcons or 4,
            }
        end
    end

    for _, sz in ipairs(StoneGrid_AuraSizes) do
        if cfg.BuffBySize[sz] == nil then
            cfg.BuffBySize[sz] = StoneGrid_BuffIconSizeDefaults(cfg)
        elseif cfg.BuffBySize[sz].BuffMaxIcons == nil then
            cfg.BuffBySize[sz].BuffMaxIcons = cfg.BuffMaxIcons or 4
        end
        if cfg.DebuffBySize[sz] == nil then
            cfg.DebuffBySize[sz] = StoneGrid_DebuffIconSizeDefaults(cfg)
        elseif cfg.DebuffBySize[sz].DebuffMaxIcons == nil then
            cfg.DebuffBySize[sz].DebuffMaxIcons = cfg.DebuffMaxIcons or 4
        end
    end
end

function StoneGrid_GetBuffPreset(cfg, sizeKey)
    if not cfg or not cfg.BuffBySize then
        return StoneGrid_BuffIconSizeDefaults(cfg)
    end
    return cfg.BuffBySize[sizeKey] or cfg.BuffBySize["5"] or cfg.BuffBySize["25"] or StoneGrid_BuffIconSizeDefaults(cfg)
end

function StoneGrid_GetDebuffPreset(cfg, sizeKey)
    if not cfg or not cfg.DebuffBySize then
        return StoneGrid_DebuffIconSizeDefaults(cfg)
    end
    return cfg.DebuffBySize[sizeKey] or cfg.DebuffBySize["5"] or cfg.DebuffBySize["25"] or StoneGrid_DebuffIconSizeDefaults(cfg)
end

function StoneGrid_SyncFlatBuffFromPreset(cfg, sizeKey)
    local preset = StoneGrid_GetBuffPreset(cfg, sizeKey)
    if preset.BuffIconSize ~= nil then
        cfg.BuffIconSize = preset.BuffIconSize
    end
    if preset.BuffMaxIcons ~= nil then
        cfg.BuffMaxIcons = preset.BuffMaxIcons
    end
end

function StoneGrid_SyncFlatDebuffFromPreset(cfg, sizeKey)
    local preset = StoneGrid_GetDebuffPreset(cfg, sizeKey)
    if preset.DebuffIconSize ~= nil then
        cfg.DebuffIconSize = preset.DebuffIconSize
    end
    if preset.DebuffMaxIcons ~= nil then
        cfg.DebuffMaxIcons = preset.DebuffMaxIcons
    end
end

function StoneGrid_GetActiveBuffIconSize(cfg)
    cfg = cfg or StoneGrid_Config
    if not cfg then return 12 end
    if UsingRaidFrames() then
        local sizeKey = StoneGrid_GetActiveRaidSize(cfg)
        local preset = StoneGrid_GetBuffPreset(cfg, sizeKey)
        return preset.BuffIconSize or cfg.BuffIconSize or 12
    end
    local preset = StoneGrid_GetBuffPreset(cfg, "5")
    return preset.BuffIconSize or cfg.BuffIconSize or 12
end

function StoneGrid_GetActiveDebuffIconSize(cfg)
    cfg = cfg or StoneGrid_Config
    if not cfg then return 12 end
    if UsingRaidFrames() then
        local sizeKey = StoneGrid_GetActiveRaidSize(cfg)
        local preset = StoneGrid_GetDebuffPreset(cfg, sizeKey)
        return preset.DebuffIconSize or cfg.DebuffIconSize or 12
    end
    local preset = StoneGrid_GetDebuffPreset(cfg, "5")
    return preset.DebuffIconSize or cfg.DebuffIconSize or 12
end

function StoneGrid_GetActiveBuffMaxIcons(cfg)
    cfg = cfg or StoneGrid_Config
    if not cfg then return 4 end
    if UsingRaidFrames() then
        local sizeKey = StoneGrid_GetActiveRaidSize(cfg)
        local preset = StoneGrid_GetBuffPreset(cfg, sizeKey)
        return preset.BuffMaxIcons or cfg.BuffMaxIcons or 4
    end
    local preset = StoneGrid_GetBuffPreset(cfg, "5")
    return preset.BuffMaxIcons or cfg.BuffMaxIcons or 4
end

function StoneGrid_GetActiveDebuffMaxIcons(cfg)
    cfg = cfg or StoneGrid_Config
    if not cfg then return 4 end
    if UsingRaidFrames() then
        local sizeKey = StoneGrid_GetActiveRaidSize(cfg)
        local preset = StoneGrid_GetDebuffPreset(cfg, sizeKey)
        return preset.DebuffMaxIcons or cfg.DebuffMaxIcons or 4
    end
    local preset = StoneGrid_GetDebuffPreset(cfg, "5")
    return preset.DebuffMaxIcons or cfg.DebuffMaxIcons or 4
end
