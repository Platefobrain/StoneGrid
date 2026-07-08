-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

-- Account-wide profiles: StoneGrid_ProfileDB = { profiles = {}, charActive = {} }

StoneGrid_ProfileDB = StoneGrid_ProfileDB or {}

local PROFILE_DEFAULT = "Default"
local PROFILE_EXPORT_PREFIX = "SG1:"
local PROFILE_EXPORT_VERSION = 1
local PROFILE_DB_KEYS = {
    profiles = true,
    charActive = true,
}

local function ProfileCharKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    if name and realm then return name .. "-" .. realm end
    return name or "Unknown"
end

local function ProfileCopyConfig(src)
    local t = {}
    if src then
        for k, v in pairs(src) do
            if type(v) == "table" then
                t[k] = ProfileCopyConfig(v)
            else
                t[k] = v
            end
        end
    end
    return t
end

local function ProfileStore()
    StoneGrid_ProfileDB.profiles = StoneGrid_ProfileDB.profiles or {}
    return StoneGrid_ProfileDB.profiles
end

local function MigrateFlatProfiles()
    StoneGrid_ProfileDB.profiles = StoneGrid_ProfileDB.profiles or {}
    local store = StoneGrid_ProfileDB.profiles
    for key, val in pairs(StoneGrid_ProfileDB) do
        if not PROFILE_DB_KEYS[key] and type(val) == "table" then
            if store[key] == nil then
                store[key] = val
            end
            StoneGrid_ProfileDB[key] = nil
        end
    end
end

local function MigrateLegacyProfiles()
    if not StoneGrid_Profiles then return end
    local store = StoneGrid_ProfileDB.profiles or {}
    for name, data in pairs(StoneGrid_Profiles) do
        if store[name] == nil then
            store[name] = data
        end
    end
    StoneGrid_ProfileDB.profiles = store
    StoneGrid_Profiles = nil
end

local function ProfileEnsureRaidSizeData(profile)
    if type(profile) ~= "table" then return end
    if profile.RaidBySize ~= nil then
        if profile.RaidEditSize == nil then profile.RaidEditSize = "25" end
        if profile.RaidSizeAuto == nil then profile.RaidSizeAuto = true end
        return
    end

    if not StoneGrid_RaidSizeInitDefaults then return end

    local seed = {}
    StoneGrid_RaidSizeInitDefaults(seed)
    profile.RaidBySize = ProfileCopyConfig(seed.RaidBySize)

    if StoneGrid_RaidSizes and StoneGrid_RaidLayoutKeys then
        for _, sz in ipairs(StoneGrid_RaidSizes) do
            local preset = profile.RaidBySize[sz]
            if preset then
                for _, key in ipairs(StoneGrid_RaidLayoutKeys) do
                    if profile[key] ~= nil then
                        preset[key] = profile[key]
                    end
                end
            end
        end
    end

    profile.RaidEditSize = profile.RaidEditSize or seed.RaidEditSize or "25"
    if profile.RaidSizeAuto == nil then profile.RaidSizeAuto = seed.RaidSizeAuto ~= false end
end

local function ProfileEnsureAuraSizeData(profile)
    if type(profile) ~= "table" then return end
    if profile.BuffBySize ~= nil and profile.DebuffBySize ~= nil then
        if profile.BuffEditSize == nil then profile.BuffEditSize = "25" end
        if profile.DebuffEditSize == nil then profile.DebuffEditSize = "25" end
        for _, preset in pairs(profile.BuffBySize) do
            if type(preset) == "table" and preset.BuffMaxIcons == nil then
                preset.BuffMaxIcons = profile.BuffMaxIcons or 4
            end
        end
        for _, preset in pairs(profile.DebuffBySize) do
            if type(preset) == "table" and preset.DebuffMaxIcons == nil then
                preset.DebuffMaxIcons = profile.DebuffMaxIcons or 4
            end
        end
        return
    end

    if not StoneGrid_AuraSizeInitDefaults then return end

    local seed = {}
    StoneGrid_AuraSizeInitDefaults(seed)
    profile.BuffBySize = ProfileCopyConfig(seed.BuffBySize)
    profile.DebuffBySize = ProfileCopyConfig(seed.DebuffBySize)

    if profile.BuffIconSize ~= nil or profile.BuffMaxIcons ~= nil then
        for _, preset in pairs(profile.BuffBySize) do
            if type(preset) == "table" then
                if profile.BuffIconSize ~= nil then
                    preset.BuffIconSize = profile.BuffIconSize
                end
                if preset.BuffMaxIcons == nil and profile.BuffMaxIcons ~= nil then
                    preset.BuffMaxIcons = profile.BuffMaxIcons
                end
            end
        end
    end
    if profile.DebuffIconSize ~= nil or profile.DebuffMaxIcons ~= nil then
        for _, preset in pairs(profile.DebuffBySize) do
            if type(preset) == "table" then
                if profile.DebuffIconSize ~= nil then
                    preset.DebuffIconSize = profile.DebuffIconSize
                end
                if preset.DebuffMaxIcons == nil and profile.DebuffMaxIcons ~= nil then
                    preset.DebuffMaxIcons = profile.DebuffMaxIcons
                end
            end
        end
    end

    profile.BuffEditSize = profile.BuffEditSize or seed.BuffEditSize or "25"
    profile.DebuffEditSize = profile.DebuffEditSize or seed.DebuffEditSize or "25"

    if profile.BuffBySize and profile.BuffBySize["5"] == nil then
        profile.BuffBySize["5"] = {
            BuffIconSize = profile.BuffIconSize or 14,
            BuffMaxIcons = profile.BuffMaxIcons or 4,
        }
    end
    if profile.DebuffBySize and profile.DebuffBySize["5"] == nil then
        profile.DebuffBySize["5"] = {
            DebuffIconSize = profile.DebuffIconSize or 14,
            DebuffMaxIcons = profile.DebuffMaxIcons or 4,
        }
    end
end

local function ProfileApplyToConfig(profile)
    ProfileEnsureRaidSizeData(profile)
    ProfileEnsureAuraSizeData(profile)
    local copied = ProfileCopyConfig(profile)
    for k in pairs(StoneGrid_Config) do
        StoneGrid_Config[k] = nil
    end
    for k, v in pairs(copied) do
        StoneGrid_Config[k] = v
    end
end

local function ProfileMigrateAll()
    for _, profile in pairs(ProfileStore()) do
        ProfileEnsureRaidSizeData(profile)
        ProfileEnsureAuraSizeData(profile)
    end
end

local function RemoveProfileData(name)
    local profiles = ProfileStore()
    profiles[name] = nil
    StoneGrid_ProfileDB[name] = nil
    if StoneGrid_Profiles then
        StoneGrid_Profiles[name] = nil
    end
end

function StoneGrid_Profiles_GetActive()
    local key = ProfileCharKey()
    local charActive = StoneGrid_ProfileDB.charActive or {}
    local name = charActive[key] or PROFILE_DEFAULT
    if not ProfileStore()[name] then name = PROFILE_DEFAULT end
    return name
end

function StoneGrid_Profiles_List()
    local names = {}
    for name in pairs(ProfileStore()) do
        names[#names + 1] = name
    end
    table.sort(names, function(a, b)
        if a == PROFILE_DEFAULT then return true end
        if b == PROFILE_DEFAULT then return false end
        return a < b
    end)
    return names
end

function StoneGrid_Profiles_Apply(name)
    local profiles = ProfileStore()
    if not name or not profiles[name] then return false end

    ProfileApplyToConfig(profiles[name])

    StoneGrid_ProfileDB.charActive = StoneGrid_ProfileDB.charActive or {}
    StoneGrid_ProfileDB.charActive[ProfileCharKey()] = name
    StoneGrid_Config_Init()
    if StoneGrid and StoneGrid.ApplySettings then
        StoneGrid:ApplySettings()
    end
    if StoneGrid_MenuRefresh then
        StoneGrid_MenuRefresh()
    end
    return true
end

function StoneGrid_Profiles_Save(name)
    name = name or StoneGrid_Profiles_GetActive()
    local profiles = ProfileStore()
    if not name or not profiles[name] then return false end
    ProfileEnsureRaidSizeData(StoneGrid_Config)
    profiles[name] = ProfileCopyConfig(StoneGrid_Config)
    return true
end

function StoneGrid_Profiles_Create(name)
    if type(name) ~= "string" then return false, "empty" end
    name = name:match("^%s*(.-)%s*$")
    if not name or name == "" then return false, "empty" end
    local profiles = ProfileStore()
    if profiles[name] then return false, "exists" end
    ProfileEnsureRaidSizeData(StoneGrid_Config)
    profiles[name] = ProfileCopyConfig(StoneGrid_Config)
    StoneGrid_Profiles_Apply(name)
    return true
end

function StoneGrid_Profiles_Delete(name)
    if not name or name == PROFILE_DEFAULT then return false, "protected" end
    local profiles = ProfileStore()
    if not profiles[name] then return false, "missing" end

    local switchDefault = (StoneGrid_Profiles_GetActive() == name)
    RemoveProfileData(name)

    StoneGrid_ProfileDB.charActive = StoneGrid_ProfileDB.charActive or {}
    for k, active in pairs(StoneGrid_ProfileDB.charActive) do
        if active == name then
            StoneGrid_ProfileDB.charActive[k] = PROFILE_DEFAULT
        end
    end

    if switchDefault then
        StoneGrid_Profiles_Apply(PROFILE_DEFAULT)
    elseif StoneGrid_MenuRefresh then
        StoneGrid_MenuRefresh()
    end
    return true
end

local function ProfileSerializeValue(v, seen)
    local tv = type(v)
    if tv == "number" or tv == "boolean" then
        return tostring(v)
    elseif tv == "string" then
        return string.format("%q", v)
    elseif tv == "table" then
        seen = seen or {}
        if seen[v] then return "nil" end
        seen[v] = true
        local parts = {}
        for k, val in pairs(v) do
            local keyStr
            if type(k) == "string" then
                keyStr = string.format("[%q]", k)
            elseif type(k) == "number" then
                keyStr = "[" .. k .. "]"
            else
                keyStr = "[" .. string.format("%q", tostring(k)) .. "]"
            end
            parts[#parts + 1] = keyStr .. "=" .. ProfileSerializeValue(val, seen)
        end
        seen[v] = nil
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "nil"
end

local function ProfileParseExport(str)
    if type(str) ~= "string" then return nil, "empty" end
    str = str:gsub("^%s+", ""):gsub("%s+$", "")
    str = str:gsub("[\r\n]", "")
    if str:sub(1, #PROFILE_EXPORT_PREFIX) ~= PROFILE_EXPORT_PREFIX then
        return nil, "format"
    end
    local body = str:sub(#PROFILE_EXPORT_PREFIX + 1)
    if body == "" then return nil, "format" end
    local fn, err = loadstring("return " .. body)
    if not fn then return nil, "parse" end
    local ok, payload = pcall(fn)
    if not ok or type(payload) ~= "table" then return nil, "parse" end
    if payload.v ~= PROFILE_EXPORT_VERSION or type(payload.d) ~= "table" then
        return nil, "version"
    end
    return payload
end

function StoneGrid_Profiles_Export(name)
    name = name or StoneGrid_Profiles_GetActive()
    if not name then return nil end
    StoneGrid_Profiles_Save(name)
    local profile = ProfileStore()[name]
    if not profile then return nil end
    ProfileEnsureRaidSizeData(profile)
    ProfileEnsureAuraSizeData(profile)
    local payload = {
        v = PROFILE_EXPORT_VERSION,
        d = ProfileCopyConfig(profile),
    }
    return PROFILE_EXPORT_PREFIX .. ProfileSerializeValue(payload)
end

function StoneGrid_Profiles_Import(str, name)
    local payload, err = ProfileParseExport(str)
    if not payload then return false, err end

    name = name or StoneGrid_Profiles_GetActive()
    if type(name) ~= "string" then return false, "empty" end
    name = name:match("^%s*(.-)%s*$")
    if not name or name == "" then return false, "empty" end

    local profileData = ProfileCopyConfig(payload.d)
    ProfileEnsureRaidSizeData(profileData)
    ProfileEnsureAuraSizeData(profileData)
    ProfileStore()[name] = profileData
    StoneGrid_Profiles_Apply(name)
    return true, name
end

function StoneGrid_Profiles_Init()
    StoneGrid_ProfileDB = StoneGrid_ProfileDB or {}
    StoneGrid_ProfileDB.charActive = StoneGrid_ProfileDB.charActive or {}
    StoneGrid_ProfileDB.profiles = StoneGrid_ProfileDB.profiles or {}
    StoneGrid_Config = StoneGrid_Config or {}

    MigrateFlatProfiles()
    MigrateLegacyProfiles()

    local profiles = ProfileStore()
    if not profiles[PROFILE_DEFAULT] then
        profiles[PROFILE_DEFAULT] = ProfileCopyConfig(StoneGrid_Config)
    end
    ProfileMigrateAll()

    local active = StoneGrid_Profiles_GetActive()
    local profile = profiles[active]
    if profile then
        ProfileApplyToConfig(profile)
    end
end
