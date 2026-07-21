-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

StoneGrid_Raid = {}
StoneGrid_Raid.frames    = {}
StoneGrid_Raid.petFrames = {}
StoneGrid_Raid._pool     = {}

StoneGrid_Raid.container = CreateFrame("Frame", "StoneGrid_RaidContainer", UIParent)
StoneGrid_Raid.container:SetMovable(true)
StoneGrid_Raid.container:SetClampedToScreen(true)
StoneGrid_Raid.container:EnableMouse(false)
StoneGrid_Raid.container:Hide()

local raidHandle = CreateFrame("Frame", nil, StoneGrid_Raid.container)
raidHandle:SetHeight(14)
raidHandle:SetPoint("BOTTOMLEFT",  StoneGrid_Raid.container, "TOPLEFT",  0, 2)
raidHandle:SetPoint("BOTTOMRIGHT", StoneGrid_Raid.container, "TOPRIGHT", 0, 2)
raidHandle:EnableMouse(false)
raidHandle:Hide()

local raidHandleBg = raidHandle:CreateTexture(nil, "BACKGROUND")
raidHandleBg:SetAllPoints()
raidHandleBg:SetTexture(0, 0, 0, 0.25)

local raidHandleText = raidHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
raidHandleText:SetAllPoints()
raidHandleText:SetText("Drag Me")
raidHandleText:SetTextColor(0.8, 0.8, 0.8, 1)

raidHandle:SetScript("OnMouseDown", function(self, btn)
    if btn == "LeftButton" then StoneGrid_Raid.container:StartMoving() end
end)
raidHandle:SetScript("OnMouseUp", function()
    StoneGrid_Raid.container:StopMovingOrSizing()
    local cx, cy = UIParent:GetCenter()
    StoneGrid_Config.RaidX = StoneGrid_Raid.container:GetLeft() - cx + (StoneGrid_Raid.memOffX or 0)
    StoneGrid_Config.RaidY = StoneGrid_Raid.container:GetTop()  - cy + (StoneGrid_Raid.memOffY or 0)
end)

StoneGrid_Raid.handle = raidHandle

function StoneGrid_Raid:SetLocked(locked)
    if locked then
        self.handle:EnableMouse(false)
        self.handle:Hide()
    else
        self.handle:EnableMouse(true)
        if self.container:IsShown() then self.handle:Show() end
    end
end

function StoneGrid_Raid:Create()
    self:Clear()

    local pool = self._pool
    local container = self.container
    local function Acquire(unit, w, h)
        if #pool > 0 then
            return StoneGrid_UnitFrame:Reuse(table.remove(pool), unit, w, h)
        end
        return StoneGrid_UnitFrame:Create(container, unit, w, h)
    end

    local cfg   = StoneGrid_Config
    local layout = StoneGrid_GetActiveRaidLayout(cfg)
    local w, h, sp = layout.RaidWidth, layout.RaidHeight, layout.RaidSpacing
    local cols  = layout.RaidColumns
    local count = GetNumRaidMembers()
    if count == 0 then return end

    local petUnits = {}
    if layout.ShowRaidPets then
        local maxPets = layout.RaidPetMax
        if not maxPets or maxPets <= 0 then maxPets = count end
        local shown = 0
        for i = 1, count do
            if shown >= maxPets then break end
            local u = "raidpet"..i
            if UnitExists(u) then
                petUnits[#petUnits+1] = u
                shown = shown + 1
            end
        end
    end

    local pw    = layout.RaidPetWidth    or 80
    local ph    = layout.RaidPetHeight   or 14
    local psp   = layout.RaidPetSpacing  or 2
    local pcols = math.max(1, layout.RaidPetColumns  or cols)
    local pos   = layout.RaidPetPosition or "RIGHT"
    local pc    = #petUnits
    local GAP   = 4

    -- power bar effective slot height (HP = h, power bar = pbH below HP inside frame)
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

    -- store so OnMouseUp can convert container pos → member pos
    self.memOffX = memX
    self.memOffY = memY

    self.container:SetSize(totalW, totalH)
    self.container:ClearAllPoints()
    -- shift container so raid member frames land at (RaidX, RaidY)
    self.container:SetPoint("TOPLEFT", UIParent, "CENTER", layout.RaidX - memX, layout.RaidY - memY)
    self.container:Show()

    self.handle:ClearAllPoints()
    self.handle:SetWidth(totalW)
    self.handle:SetPoint("BOTTOMLEFT", self.container, "TOPLEFT", 0, 2)

    if cfg.Locked then
        self.handle:EnableMouse(false)
        self.handle:Hide()
    else
        self.handle:EnableMouse(true)
        self.handle:Show()
    end

    for i = 1, count do
        local unit = "raid"..i
        local col  = (i-1) % cols
        local row  = math.floor((i-1) / cols)
        local f    = Acquire(unit, w, slotH)
        local x    = memX + col * (w + sp)
        local y    = memY - row * (slotH + sp)
        f:SetPoint("TOPLEFT",        x, y)
        f.visual:SetPoint("TOPLEFT", x, y)
        f.showPowerBar = pbH > 0
        f.powerBarH    = pbH
        f.showPvp      = layout.ShowRaidStuns
        f.pvpIconSize  = layout.RaidCcIconSize or 16
        f.showPve      = layout.ShowRaidDebuffs
        f.pveMode      = "raid"
        f.pveIconSize  = layout.RaidDebuffIconSize or 16
        self.frames[unit] = f
        StoneGrid_UnitFrame:Update(f)
        StoneGrid_UnitFrame:UpdateRange(f)
        StoneGrid_UnitFrame:UpdateAuras(f)
    end

    for i, unit in ipairs(petUnits) do
        local col = (i-1) % pcols
        local row = math.floor((i-1) / pcols)
        local f   = Acquire(unit, pw, ph)
        local x   = petX + col * (pw + psp)
        local y   = petY - row * (ph + psp)
        f:SetPoint("TOPLEFT",        x, y)
        f.visual:SetPoint("TOPLEFT", x, y)
        self.petFrames[unit] = f
        StoneGrid_UnitFrame:Update(f)
        StoneGrid_UnitFrame:UpdateRange(f)
        StoneGrid_UnitFrame:UpdateAuras(f)
    end
end

function StoneGrid_Raid:UpdateAll()
    for _, f in pairs(self.frames)    do StoneGrid_UnitFrame:Update(f) end
    for _, f in pairs(self.petFrames) do StoneGrid_UnitFrame:Update(f) end
end

function StoneGrid_Raid:UpdateAllAuras()
    for _, f in pairs(self.frames)    do StoneGrid_UnitFrame:UpdateAuras(f) end
    for _, f in pairs(self.petFrames) do StoneGrid_UnitFrame:UpdateAuras(f) end
end

function StoneGrid_Raid:UpdateHealBars()
    for _, f in pairs(self.frames)    do StoneGrid_UnitFrame:UpdateHealBar(f) end
    for _, f in pairs(self.petFrames) do StoneGrid_UnitFrame:UpdateHealBar(f) end
end

function StoneGrid_Raid:Clear()
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
