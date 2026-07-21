-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

StoneGrid_Party = {}
StoneGrid_Party.frames    = {}
StoneGrid_Party.petFrames = {}
StoneGrid_Party._pool     = {}

StoneGrid_Party.container = CreateFrame("Frame", "StoneGrid_PartyContainer", UIParent)
StoneGrid_Party.container:SetMovable(true)
StoneGrid_Party.container:SetClampedToScreen(true)
StoneGrid_Party.container:EnableMouse(false)
StoneGrid_Party.container:Hide()

local partyHandle = CreateFrame("Frame", nil, StoneGrid_Party.container)
partyHandle:SetHeight(14)
partyHandle:SetPoint("BOTTOMLEFT",  StoneGrid_Party.container, "TOPLEFT",  0, 2)
partyHandle:SetPoint("BOTTOMRIGHT", StoneGrid_Party.container, "TOPRIGHT", 0, 2)
partyHandle:EnableMouse(false)
partyHandle:Hide()

local partyHandleBg = partyHandle:CreateTexture(nil, "BACKGROUND")
partyHandleBg:SetAllPoints()
partyHandleBg:SetTexture(0, 0, 0, 0.25)

local partyHandleText = partyHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
partyHandleText:SetAllPoints()
partyHandleText:SetText("Drag Me")
partyHandleText:SetTextColor(0.8, 0.8, 0.8, 1)

partyHandle:SetScript("OnMouseDown", function(self, btn)
    if btn == "LeftButton" then StoneGrid_Party.container:StartMoving() end
end)
partyHandle:SetScript("OnMouseUp", function()
    StoneGrid_Party.container:StopMovingOrSizing()
    local cx, cy = UIParent:GetCenter()
    -- save position of member frames, not container corner
    StoneGrid_Config.PartyX = StoneGrid_Party.container:GetLeft() - cx + (StoneGrid_Party.memOffX or 0)
    StoneGrid_Config.PartyY = StoneGrid_Party.container:GetTop()  - cy + (StoneGrid_Party.memOffY or 0)
end)

StoneGrid_Party.handle = partyHandle

function StoneGrid_Party:SetLocked(locked)
    if locked then
        self.handle:EnableMouse(false)
        self.handle:Hide()
    else
        self.handle:EnableMouse(true)
        if self.container:IsShown() then self.handle:Show() end
    end
end

function StoneGrid_Party:Create()
    self:Clear()

    local pool = self._pool
    local container = self.container
    local function Acquire(unit, w, h)
        if #pool > 0 then
            return StoneGrid_UnitFrame:Reuse(table.remove(pool), unit, w, h)
        end
        return StoneGrid_UnitFrame:Create(container, unit, w, h)
    end

    local cfg = StoneGrid_Config
    local w, h, sp = cfg.PartyWidth, cfg.PartyHeight, cfg.PartySpacing
    local cols  = math.max(1, cfg.PartyColumns or 1)
    local count = 1 + GetNumPartyMembers()

    local petUnits = {}
    if cfg.ShowPartyPets then
        if UnitExists("pet") then petUnits[#petUnits+1] = "pet" end
        for i = 1, GetNumPartyMembers() do
            local u = "partypet"..i
            if UnitExists(u) then petUnits[#petUnits+1] = u end
        end
    end

    local pw    = cfg.PartyPetWidth    or 80
    local ph    = cfg.PartyPetHeight   or 16
    local psp   = cfg.PartyPetSpacing  or 2
    local pcols = math.max(1, cfg.PartyPetColumns  or 1)
    local pos   = cfg.PartyPetPosition or "RIGHT"
    local pc    = #petUnits
    local GAP   = 4

    -- power bar effective slot height (HP = h, power bar = pbH below HP inside frame)
    local pbH   = cfg.ShowPartyPowerBar and math.max(1, cfg.PartyPowerBarH or 4) or 0
    local slotH = h + pbH

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

    -- store so OnMouseUp can convert container pos → member pos
    self.memOffX = memX
    self.memOffY = memY

    self.container:SetSize(totalW, totalH)
    self.container:ClearAllPoints()
    -- shift container so member frames land at (PartyX, PartyY)
    self.container:SetPoint("TOPLEFT", UIParent, "CENTER", cfg.PartyX - memX, cfg.PartyY - memY)
    self.container:Show()

    if cfg.Locked then
        self.handle:EnableMouse(false)
        self.handle:Hide()
    else
        self.handle:EnableMouse(true)
        self.handle:Show()
    end

    local units = {"player"}
    for i = 1, count - 1 do units[i+1] = "party"..i end

    for i, unit in ipairs(units) do
        local col = (i-1) % cols
        local row = math.floor((i-1) / cols)
        local f  = Acquire(unit, w, slotH)
        local ox = memX + col * (w + sp)
        local oy = memY - row * (slotH + sp)
        f:SetPoint("TOPLEFT",        ox, oy)
        f.visual:SetPoint("TOPLEFT", ox, oy)
        f.showPowerBar = pbH > 0
        f.powerBarH    = pbH
        f.showPvp      = cfg.ShowPartyStuns
        f.pvpIconSize  = cfg.PartyCcIconSize or 20
        f.showPve      = cfg.ShowDungeonDebuffs ~= false
        f.pveMode      = "dungeon"
        f.pveIconSize  = cfg.DungeonDebuffIconSize or cfg.PartyCcIconSize or 20
        self.frames[unit] = f
        StoneGrid_UnitFrame:Update(f)
        StoneGrid_UnitFrame:UpdateRange(f)
        StoneGrid_UnitFrame:UpdateAuras(f)
    end

    for i, unit in ipairs(petUnits) do
        local col = (i-1) % pcols
        local row = math.floor((i-1) / pcols)
        local f   = Acquire(unit, pw, ph)
        local ox  = petX + col * (pw + psp)
        local oy  = petY - row * (ph + psp)
        f:SetPoint("TOPLEFT",        ox, oy)
        f.visual:SetPoint("TOPLEFT", ox, oy)
        self.petFrames[unit] = f
        StoneGrid_UnitFrame:Update(f)
        StoneGrid_UnitFrame:UpdateRange(f)
        StoneGrid_UnitFrame:UpdateAuras(f)
    end
end

function StoneGrid_Party:UpdateAll()
    for _, f in pairs(self.frames)    do StoneGrid_UnitFrame:Update(f) end
    for _, f in pairs(self.petFrames) do StoneGrid_UnitFrame:Update(f) end
end

function StoneGrid_Party:UpdateAllAuras()
    for _, f in pairs(self.frames)    do StoneGrid_UnitFrame:UpdateAuras(f) end
    for _, f in pairs(self.petFrames) do StoneGrid_UnitFrame:UpdateAuras(f) end
end

function StoneGrid_Party:UpdateHealBars()
    for _, f in pairs(self.frames)    do StoneGrid_UnitFrame:UpdateHealBar(f) end
    for _, f in pairs(self.petFrames) do StoneGrid_UnitFrame:UpdateHealBar(f) end
end

function StoneGrid_Party:Clear()
    for _, f in pairs(self.frames) do
        f:Hide()
        if f.visual then f.visual:Hide() end
        self._pool[#self._pool + 1] = f
    end
    wipe(self.frames)
    for _, f in pairs(self.petFrames) do
        f:Hide()
        if f.visual then f.visual:Hide() end
        self._pool[#self._pool + 1] = f
    end
    wipe(self.petFrames)
    self.container:Hide()
    self.handle:Hide()
end
