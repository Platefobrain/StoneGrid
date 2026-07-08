-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

StoneGrid_Test = {}
StoneGrid_Test.partyActive = false
StoneGrid_Test.raidActive  = false
StoneGrid_Test.frames      = {}

local TEST_PARTY = {
    { name="Thoradin",    class="WARRIOR",     hp=1.00, power=0.45 },
    { name="Lyriel",      class="PRIEST",      hp=0.72, power=0.88 },
    { name="Grubnok",     class="SHAMAN",      hp=0.45, power=0.60 },
    { name="Sylvara",     class="MAGE",        hp=0.90, power=0.30 },
    { name="Duskblade",   class="ROGUE",       hp=0.30, power=0.75 },
}

local TEST_RAID = {
    { name="Thoradin",    class="WARRIOR",     hp=1.00, power=0.45 },
    { name="Lyriel",      class="PRIEST",      hp=0.72, power=0.88 },
    { name="Grubnok",     class="SHAMAN",      hp=0.45, power=0.60 },
    { name="Sylvara",     class="MAGE",        hp=0.90, power=0.30 },
    { name="Duskblade",   class="ROGUE",       hp=0.30, power=0.75 },
    { name="Kael",        class="PALADIN",     hp=0.60, power=0.95 },
    { name="Vexra",       class="WARLOCK",     hp=0.85, power=0.55 },
    { name="Ironpaw",     class="DRUID",       hp=0.20, power=0.40 },
    { name="Nythera",     class="HUNTER",      hp=0.55, power=0.70 },
    { name="Mordan",      class="DEATHKNIGHT", hp=0.95, power=0.60 },
    { name="Aelith",      class="PRIEST",      hp=0.40, power=1.00 },
    { name="Stonemane",   class="WARRIOR",     hp=0.78, power=0.20 },
    { name="Felpaw",      class="DRUID",       hp=1.00, power=0.80 },
    { name="Zircon",      class="MAGE",        hp=0.65, power=0.50 },
    { name="Razorwing",   class="HUNTER",      hp=0.88, power=0.65 },
    { name="Umbrax",      class="WARLOCK",     hp=0.33, power=0.42 },
    { name="Goldenshield",class="PALADIN",     hp=0.92, power=0.85 },
    { name="Blizzara",    class="SHAMAN",      hp=0.50, power=0.72 },
    { name="Crypt",       class="DEATHKNIGHT", hp=0.15, power=0.90 },
    { name="Swiftpetal",  class="ROGUE",       hp=0.70, power=0.55 },
    { name="Ashveil",     class="PRIEST",      hp=1.00, power=0.68 },
    { name="Boulderback", class="WARRIOR",     hp=0.62, power=0.35 },
    { name="Frostmere",   class="MAGE",        hp=0.48, power=0.22 },
    { name="Nightfen",    class="DRUID",       hp=0.83, power=0.90 },
    { name="Cinderpaw",   class="SHAMAN",      hp=0.37, power=0.48 },
    { name="Runestone",   class="DEATHKNIGHT", hp=0.58, power=0.77 },
    { name="Moonwhisper", class="PRIEST",      hp=0.91, power=0.63 },
    { name="Stormclaw",   class="SHAMAN",      hp=0.44, power=0.81 },
    { name="Emberstrike", class="MAGE",        hp=0.76, power=0.39 },
    { name="Shadowveil",  class="ROGUE",       hp=0.29, power=0.92 },
    { name="Sunward",     class="PALADIN",     hp=0.87, power=0.71 },
    { name="Wildshot",    class="HUNTER",      hp=0.53, power=0.66 },
    { name="Grimsteel",   class="WARRIOR",     hp=0.69, power=0.28 },
    { name="Voidspark",   class="WARLOCK",     hp=0.41, power=0.57 },
    { name="Leafsong",    class="DRUID",       hp=0.94, power=0.84 },
    { name="Frostbite",   class="MAGE",        hp=0.32, power=0.19 },
    { name="Bloodfang",   class="ROGUE",       hp=0.61, power=0.73 },
    { name="Lightforge",  class="PALADIN",     hp=0.79, power=0.88 },
    { name="Thunderhoof", class="SHAMAN",      hp=0.46, power=0.52 },
    { name="Darkbane",    class="DEATHKNIGHT", hp=0.18, power=0.95 },
    { name="Starbow",     class="HUNTER",      hp=0.86, power=0.74 },
    { name="Ironwill",    class="WARRIOR",     hp=0.71, power=0.33 },
    { name="Netherflame", class="WARLOCK",     hp=0.59, power=0.46 },
    { name="Silversong",  class="PRIEST",      hp=0.97, power=0.79 },
    { name="Oakheart",    class="DRUID",       hp=0.64, power=0.61 },
    { name="Flamecrest",  class="MAGE",        hp=0.51, power=0.27 },
    { name="Ghoststep",   class="ROGUE",       hp=0.35, power=0.68 },
    { name="Dawnshield",  class="PALADIN",     hp=0.89, power=0.91 },
    { name="Skysplitter", class="SHAMAN",      hp=0.42, power=0.58 },
    { name="Plagueborn",  class="DEATHKNIGHT", hp=0.22, power=0.87 },
    { name="Windtracker", class="HUNTER",      hp=0.74, power=0.69 },
    { name="Stonefist",   class="WARRIOR",     hp=0.66, power=0.41 },
    { name="Soulbrand",   class="WARLOCK",     hp=0.49, power=0.53 },
    { name="Brightmend",  class="PRIEST",      hp=0.93, power=0.82 },
    { name="Thornback",   class="DRUID",       hp=0.57, power=0.76 },
    { name="Arcspark",    class="MAGE",        hp=0.38, power=0.31 },
    { name="Nightblade",  class="ROGUE",       hp=0.81, power=0.64 },
    { name="Radiant",     class="PALADIN",     hp=0.73, power=0.86 },
    { name="Tidecaller",  class="SHAMAN",      hp=0.47, power=0.49 },
    { name="Gravechill",  class="DEATHKNIGHT", hp=0.26, power=0.93 },
    { name="Longshot",    class="HUNTER",      hp=0.84, power=0.72 },
    { name="Battleborn",  class="WARRIOR",     hp=0.68, power=0.37 },
    { name="Hexweaver",   class="WARLOCK",     hp=0.54, power=0.44 },
}

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

local POWER_COLORS = {
    WARRIOR     = { 1.00, 0.00, 0.00 },  -- rage
    ROGUE       = { 1.00, 1.00, 0.00 },  -- energy
    DEATHKNIGHT = { 0.00, 0.82, 1.00 },  -- runic power
}

local function SetSolidTexture(tex, r, g, b, a)
    tex:SetVertexColor(1, 1, 1, 1)
    tex:SetTexture(r, g, b, a or 1)
end

local function ApplyTestBorder(f, cfg)
    local bs = cfg.BorderSize or 1
    if bs <= 0 then
        f.borderTop:Hide()
        f.borderBot:Hide()
        f.borderLeft:Hide()
        f.borderRight:Hide()
        return
    end

    local r, g, b, a = cfg.BorderR or 0.3, cfg.BorderG or 0.3, cfg.BorderB or 0.3, cfg.BorderA or 1

    f.borderTop:SetTexture(r, g, b, a)
    f.borderTop:ClearAllPoints()
    f.borderTop:SetPoint("TOPLEFT",     f, "TOPLEFT",     0,   0)
    f.borderTop:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT",    0,  -bs)
    f.borderTop:Show()

    f.borderBot:SetTexture(r, g, b, a)
    f.borderBot:ClearAllPoints()
    f.borderBot:SetPoint("TOPLEFT",     f, "BOTTOMLEFT",  0,  bs)
    f.borderBot:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0,   0)
    f.borderBot:Show()

    f.borderLeft:SetTexture(r, g, b, a)
    f.borderLeft:ClearAllPoints()
    f.borderLeft:SetPoint("TOPLEFT",     f, "TOPLEFT",    0,   0)
    f.borderLeft:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", bs,  0)
    f.borderLeft:Show()

    f.borderRight:SetTexture(r, g, b, a)
    f.borderRight:ClearAllPoints()
    f.borderRight:SetPoint("TOPLEFT",     f, "TOPRIGHT",    -bs, 0)
    f.borderRight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",  0,  0)
    f.borderRight:Show()
end

local function CreateTestFrame(parent, data, w, h, pbH)
    local slotH = h + (pbH or 0)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(w, slotH)

    local cfg = StoneGrid_Config or {}
    local c = CLASS_COLORS[data.class] or { r=0.5, g=0.5, b=0.5 }
    local inset = pbH or 0
    local bs  = math.max(0, cfg.BorderSize or 1)

    local bgDark = f:CreateTexture(nil, "BACKGROUND")
    bgDark:SetPoint("TOPLEFT",     f, "TOPLEFT",     0, 0)
    bgDark:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, inset)
    bgDark:SetTexture(cfg.BgDarkR or 0.1, cfg.BgDarkG or 0.1, cfg.BgDarkB or 0.1, cfg.BgDarkA or 1)

    local barR, barG, barB, barA
    if cfg.HpBarClass then
        barR, barG, barB, barA = c.r, c.g, c.b, 1
    else
        barR = cfg.HpBarR or 0
        barG = cfg.HpBarG or 0.8
        barB = cfg.HpBarB or 0
        barA = cfg.HpBarA or 1
    end

    local bgColor = f:CreateTexture(nil, "BORDER")
    bgColor:SetPoint("TOPLEFT",    f, "TOPLEFT",    0, 0)
    bgColor:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, inset)
    bgColor:SetWidth(math.max(0.01, w * data.hp))
    bgColor:SetTexture(barR, barG, barB, barA)

    local txt = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("CENTER", f, "CENTER", 0, inset / 2)
    txt:SetText(data.name)
    if cfg.NameClassColor then
        txt:SetTextColor(c.r, c.g, c.b)
    else
        txt:SetTextColor(1, 1, 1)
    end

    if pbH and pbH > 0 then
        local pwr = data.power or 0.75
        local pc  = POWER_COLORS[data.class] or { 0.00, 0.00, 1.00 }

        local pwrBg = f:CreateTexture(nil, "ARTWORK")
        pwrBg:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  bs, bs)
        pwrBg:SetPoint("TOPRIGHT",    f, "BOTTOMRIGHT", -bs, bs + pbH)
        SetSolidTexture(pwrBg, 0.15, 0.15, 0.15, 1)

        local pwrBar = f:CreateTexture(nil, "ARTWORK")
        pwrBar:SetPoint("TOPLEFT",    pwrBg, "TOPLEFT",    0, 0)
        pwrBar:SetPoint("BOTTOMLEFT", pwrBg, "BOTTOMLEFT", 0, 0)
        pwrBar:SetWidth(math.max(0.01, math.min(w * pwr, w - 2 * bs)))
        SetSolidTexture(pwrBar, pc[1], pc[2], pc[3], 1)
    end

    f.borderTop   = f:CreateTexture(nil, "OVERLAY")
    f.borderBot   = f:CreateTexture(nil, "OVERLAY")
    f.borderLeft  = f:CreateTexture(nil, "OVERLAY")
    f.borderRight = f:CreateTexture(nil, "OVERLAY")
    ApplyTestBorder(f, cfg)

    return f
end

local function CreateHandle(container, xKey, yKey)
    local handle = CreateFrame("Frame", nil, container)
    handle:SetHeight(14)
    handle:SetPoint("BOTTOMLEFT",  container, "TOPLEFT",  0, 2)
    handle:SetPoint("BOTTOMRIGHT", container, "TOPRIGHT", 0, 2)
    handle:EnableMouse(false)
    handle:Hide()

    local bg = handle:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.25)

    local txt = handle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetAllPoints()
    txt:SetText("Drag Me")
    txt:SetTextColor(0.8, 0.8, 0.8, 1)

    handle:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then container:StartMoving() end
    end)
    handle:SetScript("OnMouseUp", function()
        container:StopMovingOrSizing()
        local cx, cy = UIParent:GetCenter()
        StoneGrid_Config[xKey] = container:GetLeft() - cx
        StoneGrid_Config[yKey] = container:GetTop()  - cy
    end)

    return handle
end

local testPartyContainer = CreateFrame("Frame", "StoneGrid_TestPartyContainer", UIParent)
testPartyContainer:SetMovable(true)
testPartyContainer:SetClampedToScreen(true)
testPartyContainer:EnableMouse(false)
testPartyContainer:Hide()

local testRaidContainer = CreateFrame("Frame", "StoneGrid_TestRaidContainer", UIParent)
testRaidContainer:SetMovable(true)
testRaidContainer:SetClampedToScreen(true)
testRaidContainer:EnableMouse(false)
testRaidContainer:Hide()

local testPartyHandle = CreateHandle(testPartyContainer, "PartyX", "PartyY")
local testRaidHandle  = CreateHandle(testRaidContainer,  "RaidX",  "RaidY")

local function SetHandleLocked(handle, container, locked)
    if locked then
        handle:EnableMouse(false)
        handle:Hide()
    else
        handle:EnableMouse(true)
        if container:IsShown() then handle:Show() end
    end
end

local function GetTestRaidInfo(cfg)
    local sizeKey = cfg.RaidEditSize or "25"
    local count = tonumber(sizeKey) or 25
    count = math.max(1, math.min(count, #TEST_RAID))
    local layout = StoneGrid_GetRaidPreset(cfg, sizeKey)
    return layout, count, sizeKey
end

local function BuildTestRaidRoster(count)
    local roster = {}
    for i = 1, count do
        roster[i] = TEST_RAID[i]
    end
    return roster
end

function StoneGrid_Test:ShowParty()
    self:HideAll()
    if not InCombatLockdown() then
        StoneGrid_Party:Clear()
        StoneGrid_Raid:Clear()
    end

    local cfg = StoneGrid_Config
    local w, h, sp = cfg.PartyWidth, cfg.PartyHeight, cfg.PartySpacing
    local cols  = math.max(1, cfg.PartyColumns or 1)
    local count   = #TEST_PARTY
    local pw      = cfg.PartyPetWidth    or 80
    local ph      = cfg.PartyPetHeight   or 16
    local psp     = cfg.PartyPetSpacing  or 2
    local pcols   = math.max(1, cfg.PartyPetColumns  or 1)
    local pos     = cfg.PartyPetPosition or "RIGHT"
    local pc      = cfg.ShowPartyPets and count or 0
    local GAP     = 4

    local pbH      = cfg.ShowPartyPowerBar and math.max(1, cfg.PartyPowerBarH or 4) or 0
    local slotH    = h + pbH

    local prows    = (pc > 0) and math.ceil(pc / pcols) or 0
    local petGridW = (pc > 0) and (pcols * pw + (pcols - 1) * psp) or 0
    local petGridH = (pc > 0) and (prows  * ph + (prows  - 1) * psp) or 0
    local rows     = math.ceil(count / cols)
    local membersW = cols * w + (cols - 1) * sp
    local membersH = rows * slotH + (rows - 1) * sp

    local totalW, totalH, memX, memY, petX, petY
    if pos == "LEFT" then
        totalW = (pc > 0 and (petGridW + GAP) or 0) + membersW
        totalH = math.max(membersH, petGridH)
        memX, memY = (pc > 0 and (petGridW + GAP) or 0), 0
        petX, petY = 0, 0
    elseif pos == "TOP" then
        totalW = math.max(membersW, petGridW)
        totalH = membersH + (pc > 0 and (petGridH + GAP) or 0)
        memX, memY = 0, -(pc > 0 and (petGridH + GAP) or 0)
        petX, petY = 0, 0
    elseif pos == "BOTTOM" then
        totalW = math.max(membersW, petGridW)
        totalH = membersH + (pc > 0 and (petGridH + GAP) or 0)
        memX, memY = 0, 0
        petX, petY = 0, -(membersH + GAP)
    else -- RIGHT
        totalW = membersW + (pc > 0 and (GAP + petGridW) or 0)
        totalH = math.max(membersH, petGridH)
        memX, memY = 0, 0
        petX, petY = membersW + GAP, 0
    end

    testPartyContainer:SetSize(totalW, totalH)
    testPartyContainer:ClearAllPoints()
    testPartyContainer:SetPoint("TOPLEFT", UIParent, "CENTER", cfg.PartyX - memX, cfg.PartyY - memY)
    testPartyContainer:Show()

    SetHandleLocked(testPartyHandle, testPartyContainer, cfg.Locked)
    testPartyHandle:SetScript("OnMouseUp", function()
        testPartyContainer:StopMovingOrSizing()
        local cx, cy = UIParent:GetCenter()
        StoneGrid_Config.PartyX = testPartyContainer:GetLeft() - cx + memX
        StoneGrid_Config.PartyY = testPartyContainer:GetTop()  - cy + memY
    end)

    for i, data in ipairs(TEST_PARTY) do
        local col = (i-1) % cols
        local row = math.floor((i-1) / cols)
        local f = CreateTestFrame(testPartyContainer, data, w, h, pbH)
        f:SetPoint("TOPLEFT", memX + col * (w + sp), memY - row * (slotH + sp))
        self.frames[#self.frames + 1] = f
    end

    if pc > 0 then
        for i = 1, pc do
            local col = (i-1) % pcols
            local row = math.floor((i-1) / pcols)
            local f   = CreateTestFrame(testPartyContainer, TEST_PARTY[i], pw, ph)
            f:SetPoint("TOPLEFT", petX + col * (pw + psp), petY - row * (ph + psp))
            self.frames[#self.frames + 1] = f
        end
    end

    self.partyActive = true
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00StoneGrid Test:|r Party (5 graczy). /sg test aby wylaczyc.")
end

function StoneGrid_Test:ShowRaid()
    self:HideAll()
    if not InCombatLockdown() then
        StoneGrid_Party:Clear()
        StoneGrid_Raid:Clear()
    end

    local cfg = StoneGrid_Config
    local layout, count, sizeKey = GetTestRaidInfo(cfg)
    local roster = BuildTestRaidRoster(count)
    local w, h, sp = layout.RaidWidth, layout.RaidHeight, layout.RaidSpacing
    local cols  = layout.RaidColumns
    local pw    = layout.RaidPetWidth    or 80
    local ph    = layout.RaidPetHeight   or 14
    local psp   = layout.RaidPetSpacing  or 2
    local pcols = math.max(1, layout.RaidPetColumns  or cols)
    local pos   = layout.RaidPetPosition or "RIGHT"
    local pc    = 0
    if layout.ShowRaidPets then
        local maxPets = layout.RaidPetMax
        if not maxPets or maxPets <= 0 then maxPets = count end
        pc = math.min(maxPets, count)
    end
    local GAP   = 4

    local pbH   = layout.ShowRaidPowerBar and math.max(1, layout.RaidPowerBarH or 3) or 0
    local slotH = h + pbH

    local rows     = math.ceil(count / cols)
    local membersW = cols * w + (cols - 1) * sp
    local membersH = rows * slotH + (rows - 1) * sp

    local prows    = (pc > 0) and math.ceil(pc / pcols) or 0
    local petGridW = (pc > 0) and (pcols * pw + (pcols - 1) * psp) or 0
    local petGridH = (pc > 0) and (prows  * ph + (prows  - 1) * psp) or 0

    local totalW, totalH, memX, memY, petX, petY
    if pos == "LEFT" then
        totalW = (pc > 0 and (petGridW + GAP) or 0) + membersW
        totalH = math.max(membersH, petGridH)
        memX, memY = (pc > 0 and (petGridW + GAP) or 0), 0
        petX, petY = 0, 0
    elseif pos == "TOP" then
        totalW = math.max(membersW, petGridW)
        totalH = membersH + (pc > 0 and (petGridH + GAP) or 0)
        memX, memY = 0, -(pc > 0 and (petGridH + GAP) or 0)
        petX, petY = 0, 0
    elseif pos == "BOTTOM" then
        totalW = math.max(membersW, petGridW)
        totalH = membersH + (pc > 0 and (petGridH + GAP) or 0)
        memX, memY = 0, 0
        petX, petY = 0, -(membersH + GAP)
    else -- RIGHT
        totalW = membersW + (pc > 0 and (GAP + petGridW) or 0)
        totalH = math.max(membersH, petGridH)
        memX, memY = 0, 0
        petX, petY = membersW + GAP, 0
    end

    testRaidContainer:SetSize(totalW, totalH)
    testRaidContainer:ClearAllPoints()
    testRaidContainer:SetPoint("TOPLEFT", UIParent, "CENTER", cfg.RaidX - memX, cfg.RaidY - memY)
    testRaidContainer:Show()

    SetHandleLocked(testRaidHandle, testRaidContainer, cfg.Locked)
    testRaidHandle:SetScript("OnMouseUp", function()
        testRaidContainer:StopMovingOrSizing()
        local cx, cy = UIParent:GetCenter()
        StoneGrid_Config.RaidX = testRaidContainer:GetLeft() - cx + memX
        StoneGrid_Config.RaidY = testRaidContainer:GetTop()  - cy + memY
    end)

    for i, data in ipairs(roster) do
        local col = (i-1) % cols
        local row = math.floor((i-1) / cols)
        local f   = CreateTestFrame(testRaidContainer, data, w, h, pbH)
        f:SetPoint("TOPLEFT", memX + col * (w + sp), memY - row * (slotH + sp))
        self.frames[#self.frames + 1] = f
    end

    if pc > 0 then
        for i = 1, pc do
            local col = (i-1) % pcols
            local row = math.floor((i-1) / pcols)
            local f   = CreateTestFrame(testRaidContainer, roster[i], pw, ph)
            f:SetPoint("TOPLEFT", petX + col * (pw + psp), petY - row * (ph + psp))
            self.frames[#self.frames + 1] = f
        end
    end

    self.raidActive = true
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00StoneGrid Test:|r Raid (" .. count .. " graczy, preset " .. sizeKey .. "). /sg test aby wylaczyc.")
end

function StoneGrid_Test:RefreshLock()
    if self.partyActive then SetHandleLocked(testPartyHandle, testPartyContainer, StoneGrid_Config.Locked) end
    if self.raidActive  then SetHandleLocked(testRaidHandle,  testRaidContainer,  StoneGrid_Config.Locked) end
end

function StoneGrid_Test:HideAll()
    testPartyHandle:Hide()
    testRaidHandle:Hide()
    testPartyContainer:Hide()
    testRaidContainer:Hide()
    for _, f in ipairs(self.frames) do f:Hide() end
    self.frames = {}
    self.partyActive = false
    self.raidActive  = false
end

function StoneGrid_Test:IsActive()
    return self.partyActive or self.raidActive
end

function StoneGrid_Test:Stop()
    self:HideAll()
    StoneGrid:UpdateLayout()
end
