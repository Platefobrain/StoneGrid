-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

StoneGrid_UnitFrame = {}

local MAX_AURA_SLOTS = 8

local HealComm
local function GetHealComm()
    if not HealComm then
        HealComm = LibStub and LibStub("LibHealComm-4.0", true)
    end
    return HealComm
end

local function SetSolidTexture(tex, r, g, b, a)
    tex:SetVertexColor(1, 1, 1, 1)
    tex:SetTexture(r, g, b, a or 1)
end

-- Pass UnitGUID("player") directly as the 4th arg (casterGUID) so LibHealComm
-- filters pendingHeals[playerGUID] in a single pass, instead of computing
-- total-others across two independent passes over pendingHeals (which can
-- race with incoming CTL/comm updates from other healers in a party/raid).
local function GetOwnHealAmount(hc, guid, bitFlag, time)
    if not hc or not guid then return 0 end
    local playerGUID = UnitGUID("player")
    if not playerGUID then return 0 end
    local own = hc:GetHealAmount(guid, bitFlag, time, playerGUID) or 0
    return own > 0 and own or 0
end

-- Match Grid2 defaults: direct + channel + HoT/bomb within the next few seconds.
local HEALCOMM_TIMEFRAME = 3

local function BuildHealFlags(hc, directOnly)
    local flags = bit.bor(hc.DIRECT_HEALS, hc.CHANNEL_HEALS)
    if not directOnly then
        flags = bit.bor(flags, hc.HOT_HEALS, hc.BOMB_HEALS)
    end
    return flags
end

local function SumHotTickHeal(hc, guid, ownOnly)
    if not hc or not guid then return 0 end
    local playerGUID = UnitGUID("player")
    if not playerGUID then return 0 end

    if hc.GetHotTickAmount then
        local total = 0
        for _, entry in ipairs(hc:GetHotTickAmount(guid)) do
            local isOwn = entry.casterGUID == playerGUID
            if ownOnly and isOwn or not ownOnly and not isOwn then
                local tick = tonumber(entry.tickAmount) or 0
                total = total + tick
            end
        end
        if total > 0 then return total end
    end

    local timeFrame = GetTime() + HEALCOMM_TIMEFRAME
    if ownOnly then
        return hc:GetHealAmount(guid, hc.HOT_HEALS, timeFrame, playerGUID) or 0
    end
    return hc:GetOthersHealAmount(guid, hc.HOT_HEALS, timeFrame) or 0
end

-- Returns total incoming heal (own + optional others).
local function GetIncomingHeal(hc, guid, directOnly, includeOthers)
    if not hc or not guid then return 0 end

    local mod       = hc:GetHealModifier(guid) or 1
    local flags     = BuildHealFlags(hc, directOnly)
    local timeFrame = GetTime() + HEALCOMM_TIMEFRAME

    if includeOthers then
        return (hc:GetHealAmount(guid, flags, timeFrame) or 0) * mod
    end

    local direct = GetOwnHealAmount(hc, guid, bit.bor(hc.DIRECT_HEALS, hc.CHANNEL_HEALS), nil)
    local hot    = directOnly and 0 or SumHotTickHeal(hc, guid, true)
    return (direct + hot) * mod
end

local function HealBarWidth(frameW, healAmount, maxhp)
    if healAmount <= 0 or maxhp <= 0 then return 0 end
    return math.max(1, frameW * math.min(healAmount, maxhp) / maxhp)
end

local function ApplyIncomingHealBar(frame, incoming, hp, maxhp, w, cfg)
    if maxhp <= 0 then
        frame.healBar:Hide()
        return
    end

    local hpW = math.max(0.01, w * hp / maxhp)
    frame.bgColor:SetWidth(hpW)

    local missing = maxhp - hp
    if incoming > 0 and missing > 0 then
        local healShow = math.min(incoming, missing)
        local healW    = HealBarWidth(w, healShow, maxhp)
        frame.healBar:ClearAllPoints()
        frame.healBar:SetPoint("TOPLEFT",    frame.bgColor, "TOPRIGHT", 0, 0)
        frame.healBar:SetPoint("BOTTOMLEFT", frame.bgColor, "BOTTOMRIGHT", 0, 0)
        frame.healBar:SetWidth(healW)
        SetSolidTexture(frame.healBar, cfg.HealBarR, cfg.HealBarG, cfg.HealBarB, cfg.HealBarA)
        frame.healBar:Show()
    else
        frame.healBar:Hide()
    end
end


local CLASS_COLORS = {
    WARRIOR     = { r=0.78, g=0.61, b=0.43 },
    PALADIN     = { r=0.96, g=0.55, b=0.73 },
    HUNTER      = { r=0.67, g=0.83, b=0.45 },
    ROGUE       = { r=1.00, g=0.96, b=0.41 },
    PRIEST      = { r=1.00, g=1.00, b=1.00 },
    DEATHKNIGHT = { r=0.77, g=0.12, b=0.23 },
    SHAMAN      = { r=0.00, g=0.44, b=0.87 },
    MAGE        = { r=0.41, g=0.80, b=0.94 },
    WARLOCK     = { r=0.58, g=0.51, b=0.79 },
    DRUID       = { r=1.00, g=0.49, b=0.04 },
}

local function GetClassColor(unit)
    local _, class = UnitClass(unit)
    local c = class and CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return 0.5, 0.5, 0.5
end

local RAID_TARGET_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"

-- atlas 4x2, kazda komorka 0.25 x 0.25
local RAID_TARGET_COORDS = {
    [1] = {0,     0.25,  0,     0.25 }, -- star
    [2] = {0.25,  0.5,   0,     0.25 }, -- circle
    [3] = {0.5,   0.75,  0,     0.25 }, -- diamond
    [4] = {0.75,  1,     0,     0.25 }, -- triangle
    [5] = {0,     0.25,  0.25,  0.5  }, -- moon
    [6] = {0.25,  0.5,   0.25,  0.5  }, -- square
    [7] = {0.5,   0.75,  0.25,  0.5  }, -- cross
    [8] = {0.75,  1,     0.25,  0.5  }, -- skull
}

local function SetRaidTargetIconTexture(texture, index)
    local coords = RAID_TARGET_COORDS[index]
    if not coords then return false end
    texture:SetTexture(RAID_TARGET_TEXTURE)
    texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    return true
end

local function GetPowerBarColor(powerType)
    if     powerType == 0 then return 0.00, 0.00, 1.00  -- mana
    elseif powerType == 1 then return 1.00, 0.00, 0.00  -- rage
    elseif powerType == 2 then return 1.00, 0.50, 0.25  -- focus
    elseif powerType == 3 then return 1.00, 1.00, 0.00  -- energy
    elseif powerType == 6 then return 0.00, 0.82, 1.00  -- runic power
    end
    return 0.00, 0.00, 1.00
end

local function HpBottomInset(frame)
    if frame.showPowerBar and frame.powerBarH and frame.powerBarH > 0 then
        return frame.powerBarH
    end
    return 0
end

local function HpCenterYOffset(frame)
    return HpBottomInset(frame) / 2
end

local function ApplyHpTextPosition(frame)
    frame.text:ClearAllPoints()
    frame.text:SetPoint("CENTER", frame.visual, "CENTER", 0, HpCenterYOffset(frame))
end

local function ApplyHpBarLayout(frame)
    local v     = frame.visual
    local inset = HpBottomInset(frame)

    frame.bgDark:ClearAllPoints()
    frame.bgDark:SetPoint("TOPLEFT",     v, "TOPLEFT",     0, 0)
    frame.bgDark:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", 0, inset)

    frame.bgColor:ClearAllPoints()
    frame.bgColor:SetPoint("TOPLEFT",    v, "TOPLEFT",    0, 0)
    frame.bgColor:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", 0, inset)
end

local function PositionRaidIcon(icon, frame, pos)
    local visual = frame.visual
    icon:ClearAllPoints()
    local bs  = math.max(0, (StoneGrid_Config and StoneGrid_Config.BorderSize) or 1)
    local pad = bs + 1
    if pos == "LEFT" then
        icon:SetPoint("TOPLEFT", visual, "TOPLEFT", pad, -pad)
    elseif pos == "RIGHT" then
        icon:SetPoint("TOPRIGHT", visual, "TOPRIGHT", -pad, -pad)
    elseif pos == "BOTTOM" then
        local y = pad
        if frame.showPowerBar and frame.powerBarH and frame.powerBarH > 0 then
            y = pad + frame.powerBarH + 1
        end
        icon:SetPoint("BOTTOM", visual, "BOTTOM", 0, y)
    else -- TOP
        icon:SetPoint("TOP", visual, "TOP", 0, -pad)
    end
end

local function BottomIconOffset(frame)
    local bs = math.max(0, (StoneGrid_Config and StoneGrid_Config.BorderSize) or 1)
    if frame.showPowerBar and frame.powerBarH and frame.powerBarH > 0 then
        return bs + frame.powerBarH + 1
    end
    return bs + 1
end

-- CC: stuns, roots, fears, cyclone, incap, slows (spell IDs -> localized names at load)
local CC_SPELLS
local CC_SPELL_IDS = {
    -- stuns
    {1, 408}, {1, 7922}, {1, 1833}, {1, 8643}, {1, 853}, {1, 10308},
    {1, 12809}, {1, 22570}, {1, 8983}, {1, 44572}, {1, 30283}, {1, 46968},
    {1, 24394}, {1, 19577}, {1, 20549}, {1, 30153}, {1, 20253}, {1, 12355},
    -- fear
    {2, 5782}, {2, 8122}, {2, 5246}, {2, 5484}, {2, 6358}, {2, 1513},
    -- cyclone
    {3, 33786},
    -- incap
    {4, 118}, {4, 12824}, {4, 12825}, {4, 12826}, {4, 28271}, {4, 28272},
    {4, 61305}, {4, 6770}, {4, 2094}, {4, 1776}, {4, 2637}, {4, 19386},
    {4, 3355}, {4, 14309}, {4, 20066}, {4, 605},
    -- root
    {5, 339}, {5, 53308}, {5, 122}, {5, 33395}, {5, 19675}, {5, 50245},
    {5, 4167}, {5, 19185}, {5, 23694}, {5, 55536},
    -- slow / immobilize
    {6, 3409}, {6, 1715}, {6, 5116}, {6, 18223}, {6, 31589}, {6, 8056},
    {6, 12323}, {6, 6136}, {6, 116}, {6, 120},
}

local function EnsureCcSpells()
    if CC_SPELLS then return end
    CC_SPELLS = {}
    for _, entry in ipairs(CC_SPELL_IDS) do
        local pri, id = entry[1], entry[2]
        local name = GetSpellInfo(id)
        if name then
            local key = name:lower()
            if not CC_SPELLS[key] or pri < CC_SPELLS[key] then
                CC_SPELLS[key] = pri
            end
        end
    end
end

local function FindCcDebuff(unit)
    EnsureCcSpells()
    local bestIcon, bestDur, bestExp, bestPri = nil, nil, nil, 999
    for i = 1, 40 do
        local name, _, icon, _, _, duration, expirationTime = UnitDebuff(unit, i)
        if not name then break end
        local pri = CC_SPELLS[name:lower()]
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

local function IsCcDebuff(name)
    if not name then return false end
    EnsureCcSpells()
    return CC_SPELLS[name:lower()] ~= nil
end

function StoneGrid_UnitFrame:Create(parent, unit, w, h)
    -- Secure button: tylko i wyłącznie obsługa kliknięć (targeting).
    -- Brak dzieci, brak tekstur — nigdy nie wywołujemy na nim Show/Hide/SetAlpha
    -- z poziomu niesecure kodu podczas walki (combat lockdown).
    local f = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    f.unit = unit
    f:SetSize(w, h)
    f:EnableMouse(true)
    f:RegisterForClicks("LeftButtonUp")
    f:SetAttribute("type1", "target")
    f:SetAttribute("unit",  unit)

    -- Visual frame: zwykły (niesecure) Frame — można swobodnie Show/Hide/SetAlpha
    -- nawet podczas walki. Pozycja ustawiana w Party/Raid:Create() niezależnie od f.
    -- WAŻNE: f i v NIE są zakotwiczone do siebie — cross-anchoring secure↔niesecure
    -- sprawia że WoW traktuje niesecure frame jako restricted (blokuje Show/Hide).
    -- EnableMouse=false (domyślnie dla Frame) — kliknięcia przechodzą do f powyżej.
    local v = CreateFrame("Frame", nil, parent)
    v:SetSize(w, h)
    f.visual = v

    -- Ciemne tło (brakujące HP)
    f.bgDark = v:CreateTexture(nil, "BACKGROUND")
    f.bgDark:SetAllPoints(v)
    f.bgDark:SetTexture(0.1, 0.1, 0.1, 1)

    -- Kolorowy pasek HP
    f.bgColor = v:CreateTexture(nil, "BORDER")
    f.bgColor:SetPoint("TOPLEFT",    v, "TOPLEFT",    0, 0)
    f.bgColor:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", 0, 0)
    f.bgColor:SetWidth(w)

    -- Pasek incoming heals (ARTWORK — nad paskiem HP, pod ikonami)
    f.healBar = v:CreateTexture(nil, "ARTWORK")
    f.healBar:SetPoint("TOPLEFT",    v, "TOPLEFT",    0, 0)
    f.healBar:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", 0, 0)
    f.healBar:SetTexture(0, 0.8, 0, 0.5)
    f.healBar:SetWidth(0.01)
    f.healBar:Hide()

    -- Tekst
    f.text = v:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.text:SetPoint("CENTER", v, "CENTER")
    f.text:SetTextColor(1, 1, 1)

    -- Border (4 tekstury OVERLAY na v)
    f.borderTop   = v:CreateTexture(nil, "OVERLAY")
    f.borderBot   = v:CreateTexture(nil, "OVERLAY")
    f.borderLeft  = v:CreateTexture(nil, "OVERLAY")
    f.borderRight = v:CreateTexture(nil, "OVERLAY")

    -- Power bar — cienki pasek na dole ramki (wewnątrz borderu)
    f.powerBarBg = v:CreateTexture(nil, "ARTWORK")
    f.powerBarBg:Hide()
    f.powerBar = v:CreateTexture(nil, "ARTWORK")
    f.powerBar:Hide()
    f.showPowerBar = false
    f.powerBarH    = 0

    -- Sloty ikon buffów/debuffów — dzieci v (niesecure), więc Show/Hide działa w combat
    local function MakeIconSlot(parent)
        local slot = CreateFrame("Frame", nil, parent)

        slot.tex = slot:CreateTexture(nil, "ARTWORK")
        slot.tex:SetAllPoints()

        slot.cd = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
        slot.cd:SetAllPoints()
        slot.cd:SetDrawEdge(false)

        slot.timer = slot:CreateFontString(nil, "OVERLAY")
        slot.timer:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        slot.timer:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.timer:SetJustifyH("CENTER")
        slot.timer:Hide()

        slot.stackText = slot:CreateFontString(nil, "OVERLAY")
        slot.stackText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        slot.stackText:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 1)
        slot.stackText:SetJustifyH("RIGHT")
        slot.stackText:SetTextColor(1, 1, 1)
        slot.stackText:Hide()

        slot._elapsed = 0
        slot:SetScript("OnUpdate", function(self, dt)
            self._elapsed = self._elapsed + dt
            if self._elapsed < 0.1 then return end
            self._elapsed = 0
            local t = self.timer
            if not self.expTime then t:Hide() return end
            local rem = self.expTime - GetTime()
            if rem <= 0 then
                t:SetText("") t:Hide()
                self.expTime = nil
                return
            end
            t:Show()
            if rem >= 3600 then
                t:SetText(math.floor(rem / 3600).."h")
                t:SetTextColor(0.7, 0.7, 0.7)
            elseif rem >= 60 then
                t:SetText(math.floor(rem / 60).."m")
                t:SetTextColor(0.7, 0.7, 0.7)
            else
                t:SetText(math.floor(rem))
                t:SetTextColor(1, 0.65, 0)
            end
        end)

        slot:Hide()
        return slot
    end

    f.buffIcons = {}
    for i = 1, MAX_AURA_SLOTS do f.buffIcons[i]  = MakeIconSlot(v) end
    f.debuffIcons = {}
    for i = 1, MAX_AURA_SLOTS do f.debuffIcons[i] = MakeIconSlot(v) end

    f.raidIcon = v:CreateTexture(nil, "OVERLAY")
    f.raidIcon:SetSize(16, 16)
    f.raidIcon:Hide()

    f.ccSlot = MakeIconSlot(v)
    f.ccSlot:SetPoint("CENTER", v, "CENTER", 0, 0)
    f.ccSlot:Hide()
    f.showCc = false
    f.ccIconSize = 20

    -- visual zaczyna ukryty; f (secure) zawsze widoczny — kliknięcie na pustym slocie
    -- próbuje targetować nieistniejącą jednostkę, co po prostu nic nie robi
    v:Hide()
    return f
end

function StoneGrid_UnitFrame:Update(frame)
    local unit   = frame.unit
    local visual = frame.visual

    if not UnitExists(unit) then
        visual:Hide()
        return
    end

    visual:Show()

    local w   = frame:GetWidth()
    local cfg = StoneGrid_Config

    if UnitIsDeadOrGhost(unit) then
        frame.bgColor:SetWidth(0.01)
        frame.healBar:Hide()
        frame.bgDark:SetTexture(cfg.BgDarkR, cfg.BgDarkG, cfg.BgDarkB, cfg.BgDarkA)
        frame.text:SetText("DEAD")
        frame.text:SetTextColor(0.7, 0.7, 0.7)
        ApplyHpTextPosition(frame)
        StoneGrid_UnitFrame:UpdateRaidIcon(frame)
        StoneGrid_UnitFrame:UpdateCcIcon(frame)
        StoneGrid_UnitFrame:UpdateAuras(frame)
        return
    elseif not UnitIsConnected(unit) then
        frame.bgColor:SetWidth(0.01)
        frame.healBar:Hide()
        frame.bgDark:SetTexture(cfg.BgDarkR, cfg.BgDarkG, cfg.BgDarkB, cfg.BgDarkA)
        frame.text:SetText("OFFLINE")
        frame.text:SetTextColor(0.5, 0.5, 0.5)
        ApplyHpTextPosition(frame)
        StoneGrid_UnitFrame:UpdateRaidIcon(frame)
        StoneGrid_UnitFrame:UpdateCcIcon(frame)
        StoneGrid_UnitFrame:UpdateAuras(frame)
        return
    end

    local hp    = UnitHealth(unit)
    local maxhp = UnitHealthMax(unit)
    local pct   = (maxhp > 0) and (hp / maxhp) or 1

    ApplyHpBarLayout(frame)

    local r, g, b = GetClassColor(unit)
    frame.bgDark:SetTexture(cfg.BgDarkR, cfg.BgDarkG, cfg.BgDarkB, cfg.BgDarkA)
    if cfg.HpBarClass then
        frame.bgColor:SetTexture(r, g, b, 1)
    else
        frame.bgColor:SetTexture(cfg.HpBarR, cfg.HpBarG, cfg.HpBarB, cfg.HpBarA)
    end

    local hc       = GetHealComm()
    local incoming = 0
    if hc and maxhp > 0 then
        local guid = UnitGUID(unit)
        if guid then
            incoming = GetIncomingHeal(hc, guid, cfg.HealBarDirectOnly, cfg.HealBarIncludeOthers)
        end
    end
    ApplyIncomingHealBar(frame, incoming, hp, maxhp, w, cfg)

    frame.text:SetText(UnitName(unit))
    if cfg.NameClassColor then
        frame.text:SetTextColor(r, g, b)
    else
        frame.text:SetTextColor(1, 1, 1)
    end
    ApplyHpTextPosition(frame)

    StoneGrid_UnitFrame:UpdateBorder(frame)
    StoneGrid_UnitFrame:UpdateRaidIcon(frame)
    StoneGrid_UnitFrame:UpdateCcIcon(frame)
    StoneGrid_UnitFrame:UpdateAuras(frame)
    StoneGrid_UnitFrame:UpdatePowerBar(frame)
end

function StoneGrid_UnitFrame:UpdateRaidIcon(frame)
    local icon = frame.raidIcon
    if not icon then return end

    local cfg = StoneGrid_Config
    if not cfg or not cfg.ShowRaidIcon then
        icon:Hide()
        return
    end

    local unit = frame.unit
    if not UnitExists(unit) then
        icon:Hide()
        return
    end

    local index = GetRaidTargetIndex(unit)
    if not index or index == 0 then
        icon:Hide()
        return
    end

    local size = cfg.RaidIconSize or 16
    icon:SetSize(size, size)
    PositionRaidIcon(icon, frame, cfg.RaidIconPosition or "TOP")
    if not SetRaidTargetIconTexture(icon, index) then
        icon:Hide()
        return
    end
    icon:Show()
end

function StoneGrid_UnitFrame:UpdateCcIcon(frame)
    local slot = frame.ccSlot
    if not slot then return end

    if not frame.showCc then
        slot:Hide()
        slot.expTime = nil
        return
    end

    local unit = frame.unit
    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
        slot:Hide()
        slot.expTime = nil
        return
    end

    local icon, dur, exp = FindCcDebuff(unit)
    if not icon then
        slot:Hide()
        slot.expTime = nil
        return
    end

    local cfg = StoneGrid_Config or {}
    local size = frame.ccIconSize or 20
    slot:ClearAllPoints()
    slot:SetSize(size, size)
    slot:SetPoint("CENTER", frame.visual, "CENTER", 0, HpCenterYOffset(frame))
    slot.tex:SetTexture(icon)

    local showCD = cfg.ShowCooldown
    if showCD and dur and dur > 0 and exp and exp > 0 then
        local fs = cfg.CooldownFontSize or math.max(7, math.floor(size * 0.65))
        slot.cd:SetReverse(false)
        slot.cd:SetCooldown(exp - dur, dur)
        slot.expTime = exp
        slot.timer:SetFont("Fonts\\FRIZQT__.TTF", fs, "OUTLINE")
    else
        slot.cd:SetCooldown(0, 0)
        slot.expTime = nil
        slot.timer:SetText("")
        slot.timer:Hide()
    end
    slot.stackText:Hide()
    slot:Show()
end

function StoneGrid_UnitFrame:UpdateBorder(frame)
    local cfg = StoneGrid_Config
    local bs  = cfg.BorderSize or 1
    local r, g, b, a = cfg.BorderR, cfg.BorderG, cfg.BorderB, cfg.BorderA

    -- target highlight overrides colour and ensures minimum border thickness
    if cfg.TargetHighlight and UnitExists(frame.unit) and UnitIsUnit(frame.unit, "target") then
        r = cfg.TargetHighlightR or 1
        g = cfg.TargetHighlightG or 0.8
        b = cfg.TargetHighlightB or 0
        a = cfg.TargetHighlightA or 1
        bs = math.max(bs, 1)
    end

    if bs <= 0 then
        frame.borderTop:Hide()
        frame.borderBot:Hide()
        frame.borderLeft:Hide()
        frame.borderRight:Hide()
        return
    end

    local v = frame.visual

    frame.borderTop:SetTexture(r, g, b, a)
    frame.borderTop:ClearAllPoints()
    frame.borderTop:SetPoint("TOPLEFT",     v, "TOPLEFT",     0,   0)
    frame.borderTop:SetPoint("BOTTOMRIGHT", v, "TOPRIGHT",    0,  -bs)
    frame.borderTop:Show()

    frame.borderBot:SetTexture(r, g, b, a)
    frame.borderBot:ClearAllPoints()
    frame.borderBot:SetPoint("TOPLEFT",     v, "BOTTOMLEFT",  0,  bs)
    frame.borderBot:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", 0,   0)
    frame.borderBot:Show()

    frame.borderLeft:SetTexture(r, g, b, a)
    frame.borderLeft:ClearAllPoints()
    frame.borderLeft:SetPoint("TOPLEFT",     v, "TOPLEFT",    0,   0)
    frame.borderLeft:SetPoint("BOTTOMRIGHT", v, "BOTTOMLEFT", bs,  0)
    frame.borderLeft:Show()

    frame.borderRight:SetTexture(r, g, b, a)
    frame.borderRight:ClearAllPoints()
    frame.borderRight:SetPoint("TOPLEFT",     v, "TOPRIGHT",    -bs, 0)
    frame.borderRight:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT",  0,  0)
    frame.borderRight:Show()
end

function StoneGrid_UnitFrame:UpdateHealBar(frame)
    local unit = frame.unit
    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
        frame.healBar:Hide()
        return
    end

    local hp    = UnitHealth(unit)
    local maxhp = UnitHealthMax(unit)
    if maxhp == 0 then
        frame.healBar:Hide()
        return
    end

    ApplyHpBarLayout(frame)

    local hc = GetHealComm()
    local incoming = 0
    if hc then
        local guid = UnitGUID(unit)
        if guid then
            local cfg2 = StoneGrid_Config
            incoming = GetIncomingHeal(hc, guid, cfg2 and cfg2.HealBarDirectOnly, cfg2 and cfg2.HealBarIncludeOthers)
        end
    end

    ApplyIncomingHealBar(frame, incoming, hp, maxhp, frame:GetWidth(), StoneGrid_Config or {})
end

local function ParseFilter(str)
    local t = {}
    if str and str ~= "" then
        for part in str:gmatch("[^,]+") do
            local name = part:match("^%s*(.-)%s*$")
            if name ~= "" then t[name:lower()] = true end
        end
    end
    return t
end

local function PositionIcon(slot, frame, pos, i, total, size)
    local step = size + 1
    local v = frame.visual
    local botOff = BottomIconOffset(frame)
    slot:ClearAllPoints()
    if pos == "TOPLEFT" then
        slot:SetPoint("TOPLEFT",     v, "TOPLEFT",     (i-1)*step + 1, -1)
    elseif pos == "TOP" then
        local half = math.floor((total - 1) * step / 2)
        slot:SetPoint("TOP",         v, "TOP",          -half + (i-1)*step, -1)
    elseif pos == "TOPRIGHT" then
        slot:SetPoint("TOPRIGHT",    v, "TOPRIGHT",    -(i-1)*step - 1, -1)
    elseif pos == "MIDLEFT" then
        slot:SetPoint("LEFT",        v, "LEFT",         (i-1)*step + 1,  0)
    elseif pos == "MIDRIGHT" or pos == "MID" then
        slot:SetPoint("RIGHT",       v, "RIGHT",       -(i-1)*step - 1,  0)
    elseif pos == "BOTTOMLEFT" then
        slot:SetPoint("BOTTOMLEFT",  v, "BOTTOMLEFT",  (i-1)*step + 1,  botOff)
    elseif pos == "BOTTOM" then
        local half = math.floor((total - 1) * step / 2)
        slot:SetPoint("BOTTOM",      v, "BOTTOM",       -half + (i-1)*step, botOff)
    elseif pos == "BOTTOMRIGHT" then
        slot:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -(i-1)*step - 1,  botOff)
    else
        slot:SetPoint("TOPRIGHT",    v, "TOPRIGHT",    -(i-1)*step - 1, -1)
    end
end

function StoneGrid_UnitFrame:UpdateAuras(frame)
    if frame.buffIcons then
        for _, s in ipairs(frame.buffIcons) do
            s.expTime = nil ; s:Hide()
        end
        for _, s in ipairs(frame.debuffIcons) do
            s.expTime = nil ; s:Hide()
        end

        local unit = frame.unit
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            local cfg = StoneGrid_Config
            local showCD = cfg.ShowCooldown

            local function RenderIcons(slots, icons, pos, size, showCDArg, reverseAnim)
                local total   = #icons
                local fs      = cfg.CooldownFontSize or math.max(7, math.floor(size * 0.65))
                local fsStack = cfg.StackFontSize    or math.max(6, math.floor(size * 0.33))
                for i, aura in ipairs(icons) do
                    local slot = slots[i]
                    slot:SetSize(size, size)
                    PositionIcon(slot, frame, pos, i, total, size)
                    slot.tex:SetTexture(aura.tex)
                    if showCDArg and aura.dur > 0 then
                        if slot.cd.SetReverse then slot.cd:SetReverse(reverseAnim) end
                        slot.cd:SetCooldown(aura.exp - aura.dur, aura.dur)
                        slot.expTime = aura.exp
                        slot.timer:SetFont("Fonts\\FRIZQT__.TTF", fs, "OUTLINE")
                    else
                        if slot.cd.SetReverse then slot.cd:SetReverse(false) end
                        slot.cd:SetCooldown(0, 0)
                        slot.expTime = nil
                        slot.timer:SetText("") slot.timer:Hide()
                    end
                    if aura.stack and aura.stack > 1 then
                        slot.stackText:SetFont("Fonts\\FRIZQT__.TTF", fsStack, "OUTLINE")
                        slot.stackText:SetText(aura.stack)
                        slot.stackText:Show()
                    else
                        slot.stackText:SetText("") slot.stackText:Hide()
                    end
                    slot:Show()
                end
            end

            if cfg.ShowBuffs then
                local size = StoneGrid_GetActiveBuffIconSize and StoneGrid_GetActiveBuffIconSize(cfg) or cfg.BuffIconSize or 12
                local maxN = math.min(
                    (StoneGrid_GetActiveBuffMaxIcons and StoneGrid_GetActiveBuffMaxIcons(cfg)) or cfg.BuffMaxIcons or 4,
                    MAX_AURA_SLOTS)
                local pos  = cfg.BuffPosition or "TOPRIGHT"
                local flt  = ParseFilter(cfg.BuffFilter or "")
                local icons = {}
                for i = 1, 40 do
                    if #icons >= maxN then break end
                    local name, _, icon, count, _, duration, expTime, casterUnit = UnitBuff(unit, i)
                    if not name then break end
                    if duration and duration > 0 then
                        local passFilter = not next(flt) or flt[name:lower()]
                        local passMine   = not cfg.BuffOnlyMine or casterUnit == "player"
                        if passFilter and passMine then
                            icons[#icons + 1] = { tex=icon, dur=duration, exp=expTime or 0, stack=count or 0 }
                        end
                    end
                end
                RenderIcons(frame.buffIcons, icons, pos, size, showCD, not cfg.BuffReverse)
            end

            if cfg.ShowDebuffs then
                local size = StoneGrid_GetActiveDebuffIconSize and StoneGrid_GetActiveDebuffIconSize(cfg) or cfg.DebuffIconSize or 12
                local maxN = math.min(
                    (StoneGrid_GetActiveDebuffMaxIcons and StoneGrid_GetActiveDebuffMaxIcons(cfg)) or cfg.DebuffMaxIcons or 4,
                    MAX_AURA_SLOTS)
                local pos  = cfg.DebuffPosition or "BOTTOMRIGHT"
                local flt  = ParseFilter(cfg.DebuffFilter or "")
                local merged = {}
                local order  = {}
                for i = 1, 40 do
                    local name, _, icon, count, _, duration, expTime = UnitDebuff(unit, i)
                    if not name then break end
                    if not next(flt) or flt[name:lower()] then
                        if not (frame.showCc and IsCcDebuff(name)) then
                            local key = name:lower()
                            local entry = merged[key]
                            if entry then
                                local exp = expTime or 0
                                if exp > entry.exp then
                                    entry.dur = duration or 0
                                    entry.exp = exp
                                    entry.tex = icon
                                end
                                entry.stack = (entry.stack or 0) + (count or 0)
                            else
                                merged[key] = { tex=icon, dur=duration or 0, exp=expTime or 0, stack=count or 0 }
                                order[#order + 1] = key
                            end
                        end
                    end
                end
                local icons = {}
                for _, key in ipairs(order) do
                    if #icons >= maxN then break end
                    icons[#icons + 1] = merged[key]
                end
                RenderIcons(frame.debuffIcons, icons, pos, size, showCD, not cfg.DebuffReverse)
            end
        end
    end

    StoneGrid_UnitFrame:UpdateCcIcon(frame)
end

-- Resetuje istniejącą ramkę do ponownego użycia (unika tworzenia nowych obiektów).
-- Wywoływane z puli ramek w Party/Raid:Create().
function StoneGrid_UnitFrame:Reuse(f, unit, w, h)
    f.unit = unit
    f:SetAttribute("unit", unit)
    f:ClearAllPoints()
    f:SetSize(w, h)
    f.visual:ClearAllPoints()
    f.visual:SetSize(w, h)
    f.showPowerBar = false
    f.powerBarH    = 0
    if f.powerBarBg then f.powerBarBg:Hide() end
    if f.powerBar   then
        f.powerBar:Hide()
        f.powerBar:SetVertexColor(1, 1, 1, 1)
    end
    f.visual:Hide()
    f:Show()  -- secure button musi być widoczny żeby odbierać kliknięcia
    return f
end

function StoneGrid_UnitFrame:UpdateRange(frame)
    local cfg = StoneGrid_Config
    if not cfg then return end

    local visual = frame.visual

    if not cfg.OutOfRangeCheck then
        visual:SetAlpha(1)
        return
    end
    local unit = frame.unit
    if UnitIsUnit(unit, "player") then
        visual:SetAlpha(1)
        return
    end
    if not UnitExists(unit) or not UnitIsConnected(unit) then
        visual:SetAlpha(1)
        return
    end

    local inRange = UnitInRange and UnitInRange(unit)
    if not inRange then
        visual:SetAlpha(cfg.OutOfRangeAlpha or 0.3)
    else
        visual:SetAlpha(1)
    end
end

function StoneGrid_UnitFrame:UpdatePowerBar(frame)
    if not frame.powerBar then return end

    if not frame.showPowerBar or frame.powerBarH <= 0 then
        frame.powerBarBg:Hide()
        frame.powerBar:Hide()
        return
    end

    local unit = frame.unit
    if not UnitExists(unit) or not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
        frame.powerBarBg:Hide()
        frame.powerBar:Hide()
        return
    end

    local powerType = UnitPowerType(unit)
    local pw    = UnitPower(unit, powerType) or 0
    local maxpw = UnitPowerMax(unit, powerType) or 0

    local w    = frame:GetWidth()
    local pbH  = frame.powerBarH
    local v    = frame.visual
    local bs   = math.max(0, (StoneGrid_Config and StoneGrid_Config.BorderSize) or 1)
    local r, g, b = GetPowerBarColor(powerType)

    local pct  = (maxpw > 0) and (pw / maxpw) or 0
    local barW = math.max(0.01, w * pct)

    frame.powerBarBg:ClearAllPoints()
    frame.powerBarBg:SetPoint("BOTTOMLEFT",  v, "BOTTOMLEFT",  bs, bs)
    frame.powerBarBg:SetPoint("TOPRIGHT",    v, "BOTTOMRIGHT", -bs, bs + pbH)
    SetSolidTexture(frame.powerBarBg, 0.15, 0.15, 0.15, 1)
    frame.powerBarBg:Show()

    frame.powerBar:ClearAllPoints()
    frame.powerBar:SetPoint("TOPLEFT",    frame.powerBarBg, "TOPLEFT",    0, 0)
    frame.powerBar:SetPoint("BOTTOMLEFT", frame.powerBarBg, "BOTTOMLEFT", 0, 0)
    frame.powerBar:SetWidth(math.min(barW, w - 2 * bs))
    SetSolidTexture(frame.powerBar, r, g, b, 1)
    frame.powerBar:Show()
end
