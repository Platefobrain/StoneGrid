-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

StoneGrid = {}

function StoneGrid:ApplySettings()
    if not StoneGrid_Config then return end
    StoneGrid_Config_Init()
    StoneGrid_ApplyBlizzardPartyFrames()
    self:UpdateLayout()
    self:UpdateAll()
end

-- Raid layout for real raids/BG groups; arena always uses party frames.
function StoneGrid:ShouldUseRaidFrames()
    if GetNumRaidMembers() == 0 then return false end
    local inInstance, instType = IsInInstance()
    if inInstance and instType == "arena" then return false end
    return true
end

function StoneGrid:UpdateLayout()
    if not StoneGrid_Config then return end
    if InCombatLockdown() then
        self._pendingLayout = true
        return
    end
    if self:ShouldUseRaidFrames() then
        StoneGrid_Party:Clear()
        StoneGrid_Raid:Create()
    else
        StoneGrid_Raid:Clear()
        StoneGrid_Party:Create()
    end
    StoneGrid:UpdateHealBars()
end

function StoneGrid:UpdateUnit(unit)
    local f = StoneGrid_Party.frames[unit] or StoneGrid_Party.petFrames[unit]
    if f then StoneGrid_UnitFrame:Update(f) end

    f = StoneGrid_Raid.frames[unit] or StoneGrid_Raid.petFrames[unit]
    if f then StoneGrid_UnitFrame:Update(f) end
end

function StoneGrid:UpdateAll()
    if not StoneGrid_Config then return end
    StoneGrid_Party:UpdateAll()
    StoneGrid_Raid:UpdateAll()
end

function StoneGrid:UpdateHealBars()
    StoneGrid_Party:UpdateHealBars()
    StoneGrid_Raid:UpdateHealBars()
end

function StoneGrid:UpdateHealBar(unit)
    local f = StoneGrid_Party.frames[unit] or StoneGrid_Party.petFrames[unit]
    if f then StoneGrid_UnitFrame:UpdateHealBar(f) end

    f = StoneGrid_Raid.frames[unit] or StoneGrid_Raid.petFrames[unit]
    if f then StoneGrid_UnitFrame:UpdateHealBar(f) end
end

function StoneGrid:UpdateBorderColors()
    local function apply(frames)
        for _, f in pairs(frames) do StoneGrid_UnitFrame:UpdateBorder(f) end
    end
    apply(StoneGrid_Party.frames)
    apply(StoneGrid_Party.petFrames)
    apply(StoneGrid_Raid.frames)
    apply(StoneGrid_Raid.petFrames)
end

function StoneGrid:UpdateBgDarkColors()
    local cfg = StoneGrid_Config
    local function apply(frames)
        for _, f in pairs(frames) do
            if f.bgDark then
                f.bgDark:SetTexture(cfg.BgDarkR, cfg.BgDarkG, cfg.BgDarkB, cfg.BgDarkA)
            end
        end
    end
    apply(StoneGrid_Party.frames)
    apply(StoneGrid_Party.petFrames)
    apply(StoneGrid_Raid.frames)
    apply(StoneGrid_Raid.petFrames)
end

function StoneGrid:UpdateHealBarColors()
    local cfg = StoneGrid_Config
    local function apply(frames)
        for _, f in pairs(frames) do
            if f.healBar and f.healBar:IsShown() then
                f.healBar:SetTexture(cfg.HealBarR, cfg.HealBarG, cfg.HealBarB, cfg.HealBarA)
            end
        end
    end
    apply(StoneGrid_Party.frames)
    apply(StoneGrid_Party.petFrames)
    apply(StoneGrid_Raid.frames)
    apply(StoneGrid_Raid.petFrames)
end

function StoneGrid:UpdateAuras(unit)
    local f = StoneGrid_Party.frames[unit] or StoneGrid_Party.petFrames[unit]
    if f then StoneGrid_UnitFrame:UpdateAuras(f) end

    f = StoneGrid_Raid.frames[unit] or StoneGrid_Raid.petFrames[unit]
    if f then StoneGrid_UnitFrame:UpdateAuras(f) end
end

function StoneGrid:UpdateAllAuras()
    local function apply(frames)
        for _, f in pairs(frames) do StoneGrid_UnitFrame:UpdateAuras(f) end
    end
    apply(StoneGrid_Party.frames)
    apply(StoneGrid_Party.petFrames)
    apply(StoneGrid_Raid.frames)
    apply(StoneGrid_Raid.petFrames)
end

function StoneGrid:UpdateAllRaidIcons()
    if not StoneGrid_Config then return end
    local function apply(frames)
        for _, f in pairs(frames) do StoneGrid_UnitFrame:UpdateRaidIcon(f) end
    end
    apply(StoneGrid_Party.frames)
    apply(StoneGrid_Party.petFrames)
    apply(StoneGrid_Raid.frames)
    apply(StoneGrid_Raid.petFrames)
end

function StoneGrid:UpdateAllRanges()
    if not StoneGrid_Config then return end
    local function apply(frames)
        for _, f in pairs(frames) do StoneGrid_UnitFrame:UpdateRange(f) end
    end
    apply(StoneGrid_Party.frames)
    apply(StoneGrid_Party.petFrames)
    apply(StoneGrid_Raid.frames)
    apply(StoneGrid_Raid.petFrames)
end

function StoneGrid:UpdateAllPowerBars()
    if not StoneGrid_Config then return end
    local function apply(frames)
        for _, f in pairs(frames) do StoneGrid_UnitFrame:UpdatePowerBar(f) end
    end
    apply(StoneGrid_Party.frames)
    apply(StoneGrid_Raid.frames)
end

function StoneGrid:GetUnitByGUID(guid)
    if not guid then return end

    local hc = LibStub and LibStub("LibHealComm-4.0", true)
    if hc and hc.decompressGUID and hc.decompressGUID[guid] then
        guid = hc.decompressGUID[guid]
    end

    local function match(frames)
        for unit in pairs(frames) do
            if UnitExists(unit) and UnitGUID(unit) == guid then
                return unit
            end
        end
    end

    local unit = match(StoneGrid_Party.frames)
        or match(StoneGrid_Party.petFrames)
        or match(StoneGrid_Raid.frames)
        or match(StoneGrid_Raid.petFrames)

    if unit then return unit end

    if hc and hc.guidToUnit and hc.guidToUnit[guid] then
        unit = hc.guidToUnit[guid]
        if StoneGrid_Party.frames[unit] or StoneGrid_Party.petFrames[unit]
            or StoneGrid_Raid.frames[unit] or StoneGrid_Raid.petFrames[unit] then
            return unit
        end
    end
end
