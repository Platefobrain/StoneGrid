-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

-- StoneGrid Menu - WotLK 3.3.5a
-- /sg              = toggle menu
-- /sg lock         = lock frames
-- /sg unlock       = unlock frames
-- /sg test         = toggle test mode
-- /sg test party   = party test
-- /sg test raid    = raid test

-- Module-level: only vars needed by functions defined OUTSIDE BuildMenu
local menuFrame
local lockLabel
local L
local profileImportPasteFrame
local profileExportPasteFrame

local eb      = {}  -- all edit boxes
local refresh = {}  -- all refresh/checkbox functions

local LANGUAGES = {
    { code = "enUS", native = "English"  },
    { code = "plPL", native = "Polski"   },
    { code = "deDE", native = "Deutsch"  },
    { code = "frFR", native = "Français" },
}

local function GetL()
    local lang = (StoneGrid_Config and StoneGrid_Config.Language) or GetLocale()
    if lang == "enGB" then lang = "enUS" end
    local locs = StoneGrid_Locales or {}
    return locs[lang] or locs["enUS"] or {}
end

local function OpenColorPicker(r, g, b, a, callback)
    local prevR, prevG, prevB, prevA = r, g, b, a
    ColorPickerFrame.func        = nil
    ColorPickerFrame.opacityFunc = nil
    ColorPickerFrame.cancelFunc  = nil
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame.hasOpacity = (a ~= nil)
    if a ~= nil then ColorPickerFrame.opacity = 1 - a end
    local function OnChange()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        local na = (a ~= nil) and (1 - OpacitySliderFrame:GetValue()) or nil
        callback(nr, ng, nb, na)
    end
    ColorPickerFrame.func        = OnChange
    ColorPickerFrame.opacityFunc = OnChange
    ColorPickerFrame.cancelFunc  = function() callback(prevR, prevG, prevB, prevA) end
    ColorPickerFrame:Show()
end

local function RefreshLockLabel()
    if not lockLabel or not L then return end
    if StoneGrid_Config.Locked then
        lockLabel:SetText(L.StatusLocked)
    else
        lockLabel:SetText(L.StatusUnlocked)
    end
end

local function SgMsg(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00StoneGrid:|r " .. text)
end

local function SaveActiveProfile()
    if StoneGrid_Profiles_Save then
        StoneGrid_Profiles_Save()
    end
end

local function NormalizeProfileImportStr(str)
    if type(str) ~= "string" then return "" end
    str = str:gsub("^%s+", ""):gsub("%s+$", "")
    return str:gsub("[\r\n]", "")
end

local function DoProfileImport(str)
    str = NormalizeProfileImportStr(str)
    local loc = GetL()
    if str == "" or not str:match("^SG1:") then
        SgMsg(loc.MsgProfileImportInvalid or "Invalid profile string.")
        return false
    end
    local ok, result = StoneGrid_Profiles_Import(str)
    if ok then
        SgMsg(loc.MsgProfileImported or ("Profile imported: " .. result))
        if StoneGrid_MenuRefresh then StoneGrid_MenuRefresh() end
        return true
    elseif result == "format" or result == "parse" then
        SgMsg(loc.MsgProfileImportInvalid or "Invalid profile string.")
    elseif result == "version" then
        SgMsg(loc.MsgProfileImportVersion or "Unsupported profile export version.")
    elseif result == "empty" then
        SgMsg(loc.MsgProfileImportEmpty or "Enter a profile name.")
    else
        SgMsg(loc.MsgProfileImportFailed or "Import failed.")
    end
    return false
end

local function ShowProfileImportPaste()
    if not profileImportPasteFrame then return end
    local loc = GetL()
    if profileImportPasteFrame.title then
        profileImportPasteFrame.title:SetText(loc.ProfileImportPasteTitle or "Import profile")
    end
    if profileImportPasteFrame.hint then
        profileImportPasteFrame.hint:SetText(loc.ProfileImportPasteHint or "Paste the profile string you received (Ctrl+V), then click OK.")
    end
    if eb.ProfileImportPaste then
        eb.ProfileImportPaste:SetText("")
        if profileImportPasteFrame.ResetScroll then
            profileImportPasteFrame.ResetScroll()
        end
    end
    profileImportPasteFrame:Show()
end

local function ShowProfileExportPaste(exported)
    if not profileExportPasteFrame or not exported then return end
    local loc = GetL()
    if profileExportPasteFrame.title then
        profileExportPasteFrame.title:SetText(loc.ProfileExportPasteTitle or "Export profile")
    end
    if profileExportPasteFrame.hint then
        profileExportPasteFrame.hint:SetText(loc.ProfileExportPasteHint or "Profile code is selected — press Ctrl+C, then send it to another player.")
    end
    profileExportPasteFrame.exportText = exported
    profileExportPasteFrame:Show()
end

StaticPopupDialogs["STONEGRID_NEW_PROFILE"] = {
    text = "Enter profile name:",
    button1 = OKAY,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 32,
    OnAccept = function(self)
        local name = self.editBox:GetText()
        if not name then return end
        local ok, err = StoneGrid_Profiles_Create(name)
        if ok then
            SgMsg("Profile created: " .. StoneGrid_Profiles_GetActive())
            if StoneGrid_MenuRefresh then StoneGrid_MenuRefresh() end
        elseif err == "exists" then
            SgMsg("Profile already exists.")
        else
            SgMsg("Invalid profile name.")
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        StaticPopupDialogs[parent.which].OnAccept(parent)
        parent:Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["STONEGRID_DELETE_PROFILE"] = {
    text = "Delete profile \"%s\"?",
    button1 = OKAY,
    button2 = CANCEL,
    OnAccept = function(self)
        local name = self.data
        if not name then return end
        local ok, err = StoneGrid_Profiles_Delete(name)
        if ok then
            SgMsg((L and L.MsgProfileDeleted) or ("Profile deleted: " .. name))
            if StoneGrid_MenuRefresh then StoneGrid_MenuRefresh() end
        elseif err == "protected" then
            SgMsg((L and L.MsgProfileProtected) or "Cannot delete Default profile.")
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

-- ============================================================
-- BUILD MENU
-- ============================================================
local function BuildMenu()
    if menuFrame then return end
    L = GetL()

    StaticPopupDialogs["STONEGRID_NEW_PROFILE"].text = L.ProfileNewPrompt or "Enter profile name:"
    StaticPopupDialogs["STONEGRID_DELETE_PROFILE"].text = L.ProfileDeleteConfirm or 'Delete profile "%s"?'

    -- panels & tabBg are local to BuildMenu (not accessed outside)
    local panelMain, panelParty, panelRaid, panelColors, panelBuffs, panelDebuffs, panelProfile
    local tabPanels, tabBgs = {}, {}
    local refreshTestPartyBtn, refreshTestRaidBtn
    local MENU_W, TAB_W, TAB_STEP = 422, 58, 60

    -- FRAME
    menuFrame = CreateFrame("Frame", "StoneGrid_MenuFrame", UIParent)
    menuFrame:SetSize(MENU_W, 640)
    menuFrame:SetPoint("CENTER")
    menuFrame:SetMovable(true)
    menuFrame:EnableMouse(true)
    menuFrame:RegisterForDrag("LeftButton")
    menuFrame:SetScript("OnDragStart", menuFrame.StartMoving)
    menuFrame:SetScript("OnDragStop",  menuFrame.StopMovingOrSizing)
    menuFrame:SetFrameStrata("DIALOG")
    menuFrame:Hide()

    local bg = menuFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0.114, 0.114, 0.114, 1.0)

    local border = menuFrame:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetTexture(0.28, 0.28, 0.28, 1)

    local titleBg = menuFrame:CreateTexture(nil, "ARTWORK")
    titleBg:SetPoint("TOPLEFT", 0, 0)
    titleBg:SetPoint("TOPRIGHT", 0, 0)
    titleBg:SetHeight(24)
    titleBg:SetTexture(0.10, 0.10, 0.10, 1.0)

    local titleTxt = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleTxt:SetPoint("TOP", menuFrame, "TOP", 0, -5)
    titleTxt:SetText("|cffffffffStone|r|cff007fd0Grid|r")

    local xBtn = CreateFrame("Button", nil, menuFrame)
    xBtn:SetSize(20, 20)
    xBtn:SetPoint("TOPRIGHT", -3, -2)
    local xT = xBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xT:SetAllPoints()
    xT:SetText("|cffff4444X|r")
    xBtn:SetScript("OnClick", function()
        if profileImportPasteFrame then profileImportPasteFrame:Hide() end
        menuFrame:Hide()
    end)

    local COL_ACTIVE   = {0.0, 0.498, 0.816}
    local COL_INACTIVE = {0.22, 0.22, 0.22}

    local function SetActiveTab(which)
        for key, panel in pairs(tabPanels) do
            if key == which then panel:Show() else panel:Hide() end
        end
        for key, tbg in pairs(tabBgs) do
            if key == which then
                tbg:SetTexture(COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], 0.95)
            else
                tbg:SetTexture(COL_INACTIVE[1], COL_INACTIVE[2], COL_INACTIVE[3], 0.95)
            end
        end
    end

    local tabDefs = {
        { key="main",    label=L.General  or "General" },
        { key="party",   label="Party"                 },
        { key="raid",    label="Raid"                  },
        { key="colors",  label=L.Colors   or "Colors"  },
        { key="buffs",   label=L.TabBuffs or "Buffs"   },
        { key="debuffs", label=L.TabDebuffs or "Debuffs" },
        { key="profile", label=L.TabProfile or "Profile" },
    }
    for i, td in ipairs(tabDefs) do
        local tab = CreateFrame("Button", nil, menuFrame)
        tab:SetSize(TAB_W, 22)
        tab:SetPoint("TOPLEFT", 2 + (i - 1) * TAB_STEP, -26)
        local tbg = tab:CreateTexture(nil, "BACKGROUND")
        tbg:SetAllPoints()
        local txt = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        txt:SetAllPoints()
        txt:SetText(td.label)
        txt:SetTextColor(0.780, 0.780, 0.780)
        tab:SetScript("OnClick", function() SetActiveTab(td.key) end)
        tabBgs[td.key] = tbg
    end
    tabBgs["main"]:SetTexture(COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], 0.95)
    for key, tbg in pairs(tabBgs) do
        if key ~= "main" then tbg:SetTexture(COL_INACTIVE[1], COL_INACTIVE[2], COL_INACTIVE[3], 0.95) end
    end

    local tabLine = menuFrame:CreateTexture(nil, "ARTWORK")
    tabLine:SetPoint("TOPLEFT", 0, -50)
    tabLine:SetPoint("TOPRIGHT", 0, -50)
    tabLine:SetHeight(1)
    tabLine:SetTexture(0.267, 0.267, 0.267, 1.0)

    local function CreateProfileShareScrollArea(f, editKey, cfg)
        local btnBottomPad = cfg.btnBottomPad or 14
        local btnRowH = cfg.btnRowH or 22
        local boxW = cfg.boxW or (MENU_W - 52)
        local SCROLLBAR_W = 12
        local SCROLL_GAP = 8
        local ARROW_H = 10
        local THUMB_H = 16
        local LINE_H = 14
        local CHAR_W = 6
        local COL_SCROLL_TRACK = {0.15, 0.15, 0.15}
        local COL_SCROLL_THUMB = {0.0, 0.498, 0.816}
        local scrollRightPad = 14 + SCROLL_GAP + SCROLLBAR_W

        local scroll = CreateFrame("ScrollFrame", cfg.scrollId, f)
        scroll:SetPoint("TOPLEFT", 14, -72)
        scroll:SetPoint("BOTTOMRIGHT", -scrollRightPad, btnBottomPad + btnRowH + 16)
        scroll:SetFrameLevel(f:GetFrameLevel() + 2)
        scroll:EnableMouseWheel(true)

        local edit = CreateFrame("EditBox", nil, scroll)
        eb[editKey] = edit
        edit:SetPoint("TOPLEFT", 0, 0)
        edit:SetPoint("TOPRIGHT", 0, 0)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(true)
        edit:EnableKeyboard(true)
        edit:EnableMouse(true)
        edit:SetMaxLetters(200000)
        edit:SetFontObject("GameFontHighlightSmall")
        edit:SetText("")
        local t = edit:CreateTexture(nil, "BACKGROUND")
        t:SetAllPoints()
        t:SetTexture(0, 0, 0, 0.7)
        local b = edit:CreateTexture(nil, "BORDER")
        b:SetPoint("TOPLEFT", -1, 1)
        b:SetPoint("BOTTOMRIGHT", 1, -1)
        b:SetTexture(0.35, 0.35, 0.35, 1)
        if cfg.onEscape then
            edit:SetScript("OnEscapePressed", cfg.onEscape)
        end
        edit:SetScript("OnMouseDown", function(self)
            self:SetFocus()
        end)
        scroll:SetScrollChild(edit)

        local barCol = CreateFrame("Frame", nil, f)
        barCol:SetWidth(SCROLLBAR_W)
        barCol:SetPoint("TOPLEFT", scroll, "TOPRIGHT", SCROLL_GAP, 0)
        barCol:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", SCROLL_GAP, 0)
        barCol:SetFrameLevel(f:GetFrameLevel() + 3)

        local scrollUp = CreateFrame("Button", nil, barCol)
        scrollUp:SetHeight(ARROW_H)
        scrollUp:SetPoint("TOPLEFT", barCol, "TOPLEFT")
        scrollUp:SetPoint("TOPRIGHT", barCol, "TOPRIGHT")
        scrollUp:SetFrameLevel(barCol:GetFrameLevel() + 2)
        local scrollUpBg = scrollUp:CreateTexture(nil, "BACKGROUND")
        scrollUpBg:SetAllPoints()
        scrollUpBg:SetTexture(0.22, 0.22, 0.22, 0.95)
        local scrollUpLbl = scrollUp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        scrollUpLbl:SetAllPoints()
        scrollUpLbl:SetText("^")
        scrollUpLbl:SetTextColor(0.9, 0.9, 0.9)

        local scrollDown = CreateFrame("Button", nil, barCol)
        scrollDown:SetHeight(ARROW_H)
        scrollDown:SetPoint("BOTTOMLEFT", barCol, "BOTTOMLEFT")
        scrollDown:SetPoint("BOTTOMRIGHT", barCol, "BOTTOMRIGHT")
        scrollDown:SetFrameLevel(barCol:GetFrameLevel() + 2)
        local scrollDownBg = scrollDown:CreateTexture(nil, "BACKGROUND")
        scrollDownBg:SetAllPoints()
        scrollDownBg:SetTexture(0.22, 0.22, 0.22, 0.95)
        local scrollDownLbl = scrollDown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        scrollDownLbl:SetAllPoints()
        scrollDownLbl:SetText("v")
        scrollDownLbl:SetTextColor(0.9, 0.9, 0.9)

        local track = CreateFrame("Frame", nil, barCol)
        track:SetPoint("TOPLEFT", scrollUp, "BOTTOMLEFT", 0, 0)
        track:SetPoint("BOTTOMRIGHT", scrollDown, "TOPRIGHT", 0, 0)
        track:SetFrameLevel(barCol:GetFrameLevel() + 1)
        local trackBg = track:CreateTexture(nil, "BACKGROUND")
        trackBg:SetAllPoints()
        trackBg:SetTexture(COL_SCROLL_TRACK[1], COL_SCROLL_TRACK[2], COL_SCROLL_TRACK[3], 0.95)

        local thumb = CreateFrame("Button", nil, track)
        thumb:SetSize(SCROLLBAR_W - 2, THUMB_H)
        thumb:SetFrameLevel(track:GetFrameLevel() + 2)
        local thumbBg = thumb:CreateTexture(nil, "BACKGROUND")
        thumbBg:SetAllPoints()
        thumbBg:SetTexture(COL_SCROLL_THUMB[1], COL_SCROLL_THUMB[2], COL_SCROLL_THUMB[3], 0.9)

        local function GetScrollRange()
            scroll:UpdateScrollChildRect()
            local viewH = scroll:GetHeight()
            local editH = edit:GetHeight()
            return math.max(0, editH - viewH)
        end

        local function GetThumbTravel()
            local trackH = track:GetHeight()
            if trackH < 1 then
                trackH = math.max(0, scroll:GetHeight() - ARROW_H * 2)
            end
            return math.max(0, trackH - thumb:GetHeight())
        end

        local function ClampScroll(offset)
            local range = GetScrollRange()
            if offset < 0 then return 0 end
            if offset > range then return range end
            return offset
        end

        local function EstimateEditHeight(text, width)
            if text == "" then return LINE_H + 4 end
            local lines = 1
            local lineLen = 0
            for i = 1, #text do
                local c = text:sub(i, i)
                if c == "\n" then
                    lines = lines + 1
                    lineLen = 0
                else
                    lineLen = lineLen + CHAR_W
                    if lineLen >= width then
                        lines = lines + 1
                        lineLen = CHAR_W
                    end
                end
            end
            return lines * LINE_H + 4
        end

        local function SyncScrollThumb()
            local range = GetScrollRange()
            if range <= 0 then
                scroll:SetVerticalScroll(0)
                thumb:Hide()
                scrollUp:Disable()
                scrollDown:Disable()
                return
            end
            thumb:Show()
            scrollUp:Enable()
            scrollDown:Enable()
            local offset = ClampScroll(scroll:GetVerticalScroll())
            if scroll:GetVerticalScroll() ~= offset then
                scroll:SetVerticalScroll(offset)
            end
            local thumbTravel = GetThumbTravel()
            local thumbOffset = 0
            if thumbTravel > 0 then
                thumbOffset = (offset / range) * thumbTravel
            end
            thumb:ClearAllPoints()
            thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, -thumbOffset)
        end

        local function UpdateEditHeight()
            local width = scroll:GetWidth()
            if width < 1 then width = boxW - scrollRightPad - 14 end
            edit:SetWidth(width)
            local minH = scroll:GetHeight()
            local h = EstimateEditHeight(edit:GetText(), width)
            edit:SetHeight(math.max(h, minH))
            SyncScrollThumb()
        end

        local function ResetScroll()
            scroll:SetVerticalScroll(0)
            UpdateEditHeight()
        end

        local function SetScrollOffset(offset)
            scroll:SetVerticalScroll(ClampScroll(offset))
            SyncScrollThumb()
        end

        local function ScrollBy(delta)
            local range = GetScrollRange()
            if range <= 0 then return end
            local step = LINE_H * 3
            SetScrollOffset(scroll:GetVerticalScroll() - delta * step)
        end

        edit:SetScript("OnTextChanged", UpdateEditHeight)
        edit:EnableMouseWheel(true)
        edit:SetScript("OnMouseWheel", function(_, delta) ScrollBy(delta) end)
        scroll:SetScript("OnMouseWheel", function(_, delta) ScrollBy(delta) end)
        scroll:SetScript("OnVerticalScroll", function()
            SyncScrollThumb()
        end)

        scrollUp:SetScript("OnClick", function()
            SetScrollOffset(scroll:GetVerticalScroll() - LINE_H * 3)
        end)

        scrollDown:SetScript("OnClick", function()
            SetScrollOffset(scroll:GetVerticalScroll() + LINE_H * 3)
        end)

        thumb:SetScript("OnMouseDown", function(self)
            local _, cy = GetCursorPosition()
            self.dragCY = cy
            self.dragScroll = scroll:GetVerticalScroll()
            self:SetScript("OnUpdate", function(btn)
                local range = GetScrollRange()
                local thumbTravel = GetThumbTravel()
                if range <= 0 or thumbTravel <= 0 then return end
                local _, ncy = GetCursorPosition()
                local scale = f:GetEffectiveScale()
                local delta = (ncy - btn.dragCY) / scale
                btn.dragCY = ncy
                local scrollDelta = delta * (range / thumbTravel)
                btn.dragScroll = ClampScroll(btn.dragScroll - scrollDelta)
                scroll:SetVerticalScroll(btn.dragScroll)
                SyncScrollThumb()
            end)
        end)
        thumb:SetScript("OnMouseUp", function(self)
            self:SetScript("OnUpdate", nil)
        end)

        return ResetScroll
    end

    local function CreateProfileImportPasteFrame()
        local loc = GetL()
        local f = CreateFrame("Frame", "StoneGrid_ImportPasteFrame", menuFrame)
        f:SetSize(MENU_W - 16, 252)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetFrameLevel(menuFrame:GetFrameLevel() + 30)
        f:Hide()

        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0.08, 0.08, 0.08, 0.98)

        local border = f:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetTexture(0.35, 0.35, 0.35, 1)

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.title:SetPoint("TOP", 0, -12)
        f.title:SetText(loc.ProfileImportPasteTitle or "Import profile")
        f.title:SetTextColor(0.0, 0.498, 0.816)

        f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f.hint:SetPoint("TOPLEFT", 14, -34)
        f.hint:SetPoint("TOPRIGHT", -14, -34)
        f.hint:SetJustifyH("LEFT")
        f.hint:SetText(loc.ProfileImportPasteHint or "Paste the profile string you received (Ctrl+V), then click OK.")
        f.hint:SetTextColor(0.75, 0.75, 0.75)

        local boxW = MENU_W - 52
        local btnW = math.floor((boxW - 10) / 2)
        local btnRowH = 22
        local btnBottomPad = 14

        local continueBtn = CreateFrame("Button", nil, f)
        continueBtn:SetSize(btnW, btnRowH)
        continueBtn:SetPoint("BOTTOMLEFT", 14, btnBottomPad)
        continueBtn:SetFrameLevel(f:GetFrameLevel() + 5)
        local continueBg = continueBtn:CreateTexture(nil, "BACKGROUND")
        continueBg:SetAllPoints()
        continueBg:SetTexture(0.0, 0.498, 0.816, 0.95)
        local continueLbl = continueBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        continueLbl:SetAllPoints()
        continueLbl:SetText(loc.ProfileImportContinue or "OK")
        continueLbl:SetTextColor(1, 1, 1)
        continueBtn:SetScript("OnClick", function()
            local str = eb.ProfileImportPaste and eb.ProfileImportPaste:GetText() or ""
            if NormalizeProfileImportStr(str) == "" then
                SgMsg(loc.MsgProfileImportMissing or "Paste a profile string first.")
                return
            end
            f:Hide()
            DoProfileImport(str)
        end)

        local cancelBtn = CreateFrame("Button", nil, f)
        cancelBtn:SetSize(btnW, btnRowH)
        cancelBtn:SetPoint("BOTTOMRIGHT", -14, btnBottomPad)
        cancelBtn:SetFrameLevel(f:GetFrameLevel() + 5)
        local cancelBg = cancelBtn:CreateTexture(nil, "BACKGROUND")
        cancelBg:SetAllPoints()
        cancelBg:SetTexture(0.22, 0.22, 0.22, 0.95)
        local cancelLbl = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cancelLbl:SetAllPoints()
        cancelLbl:SetText(CANCEL or "Cancel")
        cancelLbl:SetTextColor(0.9, 0.9, 0.9)
        cancelBtn:SetScript("OnClick", function() f:Hide() end)

        local btnSep = f:CreateTexture(nil, "ARTWORK")
        btnSep:SetPoint("BOTTOMLEFT", 10, btnBottomPad + btnRowH + 8)
        btnSep:SetPoint("BOTTOMRIGHT", -10, btnBottomPad + btnRowH + 8)
        btnSep:SetHeight(1)
        btnSep:SetTexture(0.267, 0.267, 0.267, 1.0)

        f.ResetScroll = CreateProfileShareScrollArea(f, "ProfileImportPaste", {
            btnBottomPad = btnBottomPad,
            btnRowH = btnRowH,
            boxW = boxW,
            scrollId = "StoneGridImportScroll",
            onEscape = function() f:Hide() end,
        })

        f:EnableKeyboard(true)
        f:SetScript("OnShow", function(self)
            self:SetScript("OnUpdate", function(sf)
                sf:SetScript("OnUpdate", nil)
                if sf.ResetScroll then sf.ResetScroll() end
                if eb.ProfileImportPaste then eb.ProfileImportPaste:SetFocus() end
            end)
        end)

        return f
    end

    local function CreateProfileExportPasteFrame()
        local loc = GetL()
        local f = CreateFrame("Frame", "StoneGrid_ExportPasteFrame", menuFrame)
        f:SetSize(MENU_W - 16, 252)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetFrameLevel(menuFrame:GetFrameLevel() + 30)
        f:Hide()

        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0.08, 0.08, 0.08, 0.98)

        local border = f:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetTexture(0.35, 0.35, 0.35, 1)

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.title:SetPoint("TOP", 0, -12)
        f.title:SetText(loc.ProfileExportPasteTitle or "Export profile")
        f.title:SetTextColor(0.0, 0.498, 0.816)

        f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f.hint:SetPoint("TOPLEFT", 14, -34)
        f.hint:SetPoint("TOPRIGHT", -14, -34)
        f.hint:SetJustifyH("LEFT")
        f.hint:SetText(loc.ProfileExportPasteHint or "Profile code is selected — press Ctrl+C, then send it to another player.")
        f.hint:SetTextColor(0.75, 0.75, 0.75)

        local boxW = MENU_W - 52
        local btnRowH = 22
        local btnBottomPad = 14

        local closeBtn = CreateFrame("Button", nil, f)
        closeBtn:SetSize(boxW, btnRowH)
        closeBtn:SetPoint("BOTTOM", 0, btnBottomPad)
        closeBtn:SetFrameLevel(f:GetFrameLevel() + 5)
        local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
        closeBg:SetAllPoints()
        closeBg:SetTexture(0.0, 0.498, 0.816, 0.95)
        local closeLbl = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        closeLbl:SetAllPoints()
        closeLbl:SetText(loc.ProfileExportClose or "Close")
        closeLbl:SetTextColor(1, 1, 1)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local btnSep = f:CreateTexture(nil, "ARTWORK")
        btnSep:SetPoint("BOTTOMLEFT", 10, btnBottomPad + btnRowH + 8)
        btnSep:SetPoint("BOTTOMRIGHT", -10, btnBottomPad + btnRowH + 8)
        btnSep:SetHeight(1)
        btnSep:SetTexture(0.267, 0.267, 0.267, 1.0)

        f.ResetScroll = CreateProfileShareScrollArea(f, "ProfileExportPaste", {
            btnBottomPad = btnBottomPad,
            btnRowH = btnRowH,
            boxW = boxW,
            scrollId = "StoneGridExportScroll",
            onEscape = function() f:Hide() end,
        })

        f:EnableKeyboard(true)
        f:SetScript("OnShow", function(self)
            self:SetScript("OnUpdate", function(sf)
                sf:SetScript("OnUpdate", nil)
                if eb.ProfileExportPaste then
                    eb.ProfileExportPaste:SetText(sf.exportText or "")
                    if sf.ResetScroll then sf.ResetScroll() end
                    eb.ProfileExportPaste:SetFocus()
                    eb.ProfileExportPaste:HighlightText()
                end
            end)
        end)

        return f
    end

    profileImportPasteFrame = CreateProfileImportPasteFrame()
    profileExportPasteFrame = CreateProfileExportPasteFrame()

    local function MakePanel()
        local p = CreateFrame("Frame", nil, menuFrame)
        p:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 0, -56)
        p:SetSize(MENU_W, 584)
        return p
    end
    panelMain    = MakePanel()
    panelParty   = MakePanel()  panelParty:Hide()
    panelRaid    = MakePanel()  panelRaid:Hide()
    panelColors  = MakePanel()  panelColors:Hide()
    panelBuffs   = MakePanel()  panelBuffs:Hide()
    panelDebuffs = MakePanel()  panelDebuffs:Hide()
    panelProfile = MakePanel()  panelProfile:Hide()
    tabPanels = {
        main    = panelMain,
        party   = panelParty,
        raid    = panelRaid,
        colors  = panelColors,
        buffs   = panelBuffs,
        debuffs = panelDebuffs,
        profile = panelProfile,
    }

    -- SHARED HELPERS
    local function SectionLabel(panel, text, y)
        local f = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetPoint("TOPLEFT", 12, y)
        f:SetText(text)
        f:SetTextColor(0.0, 0.498, 0.816)
        return f
    end

    local function Label(panel, text, y)
        local f = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f:SetPoint("TOPLEFT", 18, y)
        f:SetText(text)
        f:SetTextColor(0.765, 0.765, 0.765)
        return f
    end

    local function CenterLabel(panel, text, y)
        local f = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f:SetPoint("TOP", panel, "TOP", 0, y)
        f:SetText(text)
        f:SetTextColor(0.765, 0.765, 0.765)
        return f
    end

    local function ILabel(panel, text, x, y)
        local f = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f:SetPoint("TOPLEFT", x, y)
        f:SetText(text)
        f:SetTextColor(0.765, 0.765, 0.765)
        return f
    end

    local function Separator(panel, y)
        local s = panel:CreateTexture(nil, "ARTWORK")
        s:SetPoint("TOPLEFT", 10, y)
        s:SetPoint("TOPRIGHT", -10, y)
        s:SetHeight(1)
        s:SetTexture(0.267, 0.267, 0.267, 1.0)
    end

    -- Menu spacing (Debuffs [Position] grid reference)
    local SEP_GAP = 8
    local SEP_SECTION = 12
    local SECTION_CONTENT = 22
    local POS_GRID_ROW_STEP = 30
    local POS_GRID_BTN_H = 26
    local POS_GRID_HEIGHT = POS_GRID_ROW_STEP * 2 + POS_GRID_BTN_H
    local COOLDOWN_SECTION_H = 64
    local PET_POS_HEIGHT = 42
    local SMALL_EDIT_H = 20
    local FILTER_BLOCK_H = 44
    local ICON_SIZE_OPTS = { btnOffset = 30, sizeRowOffset = 66, labelOffset = 12 }

    local function SepAfter(bottomY) return bottomY - SEP_GAP end
    local function SectionAfterSep(sepY) return sepY - SEP_SECTION end
    local function PosGridLayout(yStart)
        local bottom = yStart - POS_GRID_HEIGHT
        local sepY = SepAfter(bottom)
        return bottom, sepY, SectionAfterSep(sepY)
    end

    local function EditBox(panel, y, val)
        local e = CreateFrame("EditBox", nil, panel)
        e:SetSize(54, 18)
        e:SetPoint("TOPRIGHT", -12, y)
        e:SetAutoFocus(false)
        e:SetNumeric(true)
        e:SetMaxLetters(4)
        e:SetFontObject("GameFontHighlightSmall")
        e:SetNumber(val or 0)
        local t = e:CreateTexture(nil, "BACKGROUND")
        t:SetAllPoints() t:SetTexture(0, 0, 0, 0.7)
        local b = e:CreateTexture(nil, "BORDER")
        b:SetPoint("TOPLEFT", -1, 1)
        b:SetPoint("BOTTOMRIGHT", 1, -1)
        b:SetTexture(0.35, 0.35, 0.35, 1)
        e:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
        e:SetScript("OnEnterPressed",  function(s) s:ClearFocus() end)
        return e
    end

    local function SmallEB(panel, x, y, val)
        local e = CreateFrame("EditBox", nil, panel)
        e:SetSize(42, 18)
        e:SetPoint("TOPLEFT", x, y)
        e:SetAutoFocus(false)
        e:SetNumeric(true)
        e:SetMaxLetters(4)
        e:SetFontObject("GameFontHighlightSmall")
        e:SetNumber(val or 0)
        local t = e:CreateTexture(nil, "BACKGROUND")
        t:SetAllPoints() t:SetTexture(0, 0, 0, 0.7)
        local b = e:CreateTexture(nil, "BORDER")
        b:SetPoint("TOPLEFT", -1, 1)
        b:SetPoint("BOTTOMRIGHT", 1, -1)
        b:SetTexture(0.35, 0.35, 0.35, 1)
        e:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
        e:SetScript("OnEnterPressed",  function(s) s:ClearFocus() end)
        return e
    end

    local METRIC_EB_X   = 240
    local METRIC_EB_GAP = 4
    local function MetricLabelAndEB(panel, text, y, val)
        local lbl = ILabel(panel, text, 0, y)
        lbl:ClearAllPoints()
        lbl:SetPoint("TOPLEFT", METRIC_EB_X - lbl:GetStringWidth() - METRIC_EB_GAP, y)
        local e = SmallEB(panel, METRIC_EB_X, y, val)
        return lbl, e
    end

    local function Btn(panel, label, x, y, w, fn)
        local btn = CreateFrame("Button", nil, panel)
        btn:SetSize(w, 22)
        btn:SetPoint("TOPLEFT", x, y)
        local bg2 = btn:CreateTexture(nil, "BACKGROUND")
        bg2:SetAllPoints() bg2:SetTexture(0.0, 0.498, 0.816, 0.95)
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints() lbl:SetText(label) lbl:SetTextColor(1, 1, 1)
        btn:SetScript("OnEnter", function() bg2:SetTexture(0.0, 0.60, 0.95, 0.95) end)
        btn:SetScript("OnLeave", function() bg2:SetTexture(0.0, 0.498, 0.816, 0.95) end)
        btn:SetScript("OnClick", fn)
        return btn, bg2
    end

    local SAVE_BTN_W  = 155
    local SAVE_BTN_GAP = 14
    local TEST_BTN_W  = 250
    -- Fixed bottom position for Save/Reset (and the separator above them),
    -- shared by every panel so they always sit ~10px from the panel's
    -- bottom edge instead of drifting based on how much content is above.
    local PANEL_H = 584
    local BOTTOM_BTN_Y = -(PANEL_H - 10 - 22)
    local BOTTOM_SEP_Y = BOTTOM_BTN_Y + 10
    local function CenteredSaveResetX()
        local total = SAVE_BTN_W + SAVE_BTN_GAP + SAVE_BTN_W
        local saveX = (MENU_W - total) / 2
        return saveX, saveX + SAVE_BTN_W + SAVE_BTN_GAP
    end
    local function CenteredBtnX(w)
        return (MENU_W - w) / 2
    end

    local function ProfileDropdown(panel, x, y, w)
        local open = false
        local rowPool = {}

        local root = CreateFrame("Frame", nil, panel)
        root:SetSize(w, 22)
        root:SetPoint("TOPLEFT", x, y)

        local btn = CreateFrame("Button", nil, root)
        btn:SetSize(w, 22)
        btn:SetPoint("TOPLEFT", 0, 0)
        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints()
        btnBg:SetTexture(0, 0, 0, 0.7)
        local btnBrd = btn:CreateTexture(nil, "BORDER")
        btnBrd:SetPoint("TOPLEFT", -1, 1)
        btnBrd:SetPoint("BOTTOMRIGHT", 1, -1)
        btnBrd:SetTexture(0.35, 0.35, 0.35, 1)
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btnText:SetPoint("LEFT", 8, 0)
        btnText:SetPoint("RIGHT", -20, 0)
        btnText:SetJustifyH("LEFT")
        local btnArrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btnArrow:SetPoint("RIGHT", -6, 0)
        btnArrow:SetText("v")
        btnArrow:SetTextColor(0.78, 0.78, 0.78)

        local list = CreateFrame("Frame", nil, root)
        list:SetFrameStrata("DIALOG")
        list:SetFrameLevel(root:GetFrameLevel() + 10)
        list:Hide()
        local listBg = list:CreateTexture(nil, "BACKGROUND")
        listBg:SetAllPoints()
        listBg:SetTexture(0.114, 0.114, 0.114, 0.98)
        local listBrd = list:CreateTexture(nil, "BORDER")
        listBrd:SetPoint("TOPLEFT", -1, 1)
        listBrd:SetPoint("BOTTOMRIGHT", 1, -1)
        listBrd:SetTexture(0.35, 0.35, 0.35, 1)

        local function StyleRow(row, name, activeName)
            if name == activeName then
                row.bg:SetTexture(COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], 0.95)
                row.lbl:SetTextColor(1, 1, 1)
            else
                row.bg:SetTexture(COL_INACTIVE[1], COL_INACTIVE[2], COL_INACTIVE[3], 0.95)
                row.lbl:SetTextColor(0.78, 0.78, 0.78)
            end
        end

        local function CloseList()
            open = false
            list:Hide()
            btnArrow:SetText("v")
            btnBrd:SetTexture(0.35, 0.35, 0.35, 1)
        end

        local function BuildList()
            local names = StoneGrid_Profiles_List()
            local active = StoneGrid_Profiles_GetActive()
            local n = #names
            list:SetSize(w, n * 22 + 4)
            list:ClearAllPoints()
            list:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)

            for i, name in ipairs(names) do
                local row = rowPool[i]
                if not row then
                    row = CreateFrame("Button", nil, list)
                    row:SetSize(w - 4, 20)
                    row.bg = row:CreateTexture(nil, "BACKGROUND")
                    row.bg:SetAllPoints()
                    row.lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    row.lbl:SetPoint("LEFT", 8, 0)
                    rowPool[i] = row
                end
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 2, -2 - (i - 1) * 22)
                row:Show()
                row.lbl:SetText(name)
                StyleRow(row, name, active)
                row:SetScript("OnClick", function()
                    if StoneGrid_Profiles_GetActive() ~= name then
                        StoneGrid_Profiles_Apply(name)
                        SgMsg((L.MsgProfileLoaded or "Profile loaded:") .. " " .. name)
                    end
                    btnText:SetText(name)
                    CloseList()
                end)
                row:SetScript("OnEnter", function()
                    row.bg:SetTexture(0.0, 0.60, 0.95, 0.95)
                    row.lbl:SetTextColor(1, 1, 1)
                end)
                row:SetScript("OnLeave", function()
                    StyleRow(row, name, StoneGrid_Profiles_GetActive())
                end)
            end
            for i = n + 1, #rowPool do
                rowPool[i]:Hide()
            end
        end

        local function OpenList()
            BuildList()
            open = true
            list:Show()
            btnArrow:SetText("^")
            btnBrd:SetTexture(COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], 0.95)
        end

        btn:SetScript("OnClick", function()
            if open then CloseList() else OpenList() end
        end)
        btn:SetScript("OnEnter", function()
            if not open then btnBrd:SetTexture(0.0, 0.60, 0.95, 0.95) end
        end)
        btn:SetScript("OnLeave", function()
            if not open then btnBrd:SetTexture(0.35, 0.35, 0.35, 1) end
        end)

        root:SetScript("OnHide", CloseList)

        return {
            Refresh = function()
                btnText:SetText(StoneGrid_Profiles_GetActive())
                CloseList()
                for i = 1, #rowPool do
                    rowPool[i]:Hide()
                end
            end,
        }
    end

    local function ColorSwatch(panel, y, label, cfgR, cfgG, cfgB, cfgA, onApply)
        Label(panel, label, y)
        local btn = CreateFrame("Button", nil, panel)
        btn:SetSize(32, 20)
        btn:SetPoint("TOPRIGHT", -12, y - 1)
        local bgTex = btn:CreateTexture(nil, "BACKGROUND")
        bgTex:SetAllPoints() bgTex:SetTexture(0.45, 0.45, 0.45, 1)
        local colorTex = btn:CreateTexture(nil, "ARTWORK")
        colorTex:SetAllPoints()
        local brdTex = btn:CreateTexture(nil, "OVERLAY")
        brdTex:SetPoint("TOPLEFT", -1, 1) brdTex:SetPoint("BOTTOMRIGHT", 1, -1)
        brdTex:SetTexture(0.7, 0.7, 0.7, 0.6)
        local function Refresh()
            local c = StoneGrid_Config
            colorTex:SetTexture(c[cfgR], c[cfgG], c[cfgB], cfgA and c[cfgA] or 1)
        end
        Refresh()
        btn:SetScript("OnClick", function()
            local c = StoneGrid_Config
            OpenColorPicker(c[cfgR], c[cfgG], c[cfgB], cfgA and c[cfgA] or nil, function(nr,ng,nb,na)
                c[cfgR]=nr c[cfgG]=ng c[cfgB]=nb
                if cfgA and na ~= nil then c[cfgA] = na end
                Refresh() onApply()
            end)
        end)
        return Refresh
    end

    local function Checkbox(panel, cfgKey, labelText, x, y)
        x = x or 18
        local btn = CreateFrame("Button", nil, panel)
        btn:SetSize(16, 16)
        btn:SetPoint("TOPLEFT", x, y)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        mark:SetAllPoints()
        local lbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", x + 20, y)
        lbl:SetText(labelText) lbl:SetTextColor(0.85, 0.85, 0.85)
        local function Refresh()
            if StoneGrid_Config[cfgKey] then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        Refresh()
        btn:SetScript("OnClick", function()
            StoneGrid_Config[cfgKey] = not StoneGrid_Config[cfgKey]
            Refresh() StoneGrid:UpdateAllAuras()
        end)
        return Refresh
    end

    local function FilterBox(panel, y, val)
        local w = MENU_W - 36
        local x = (MENU_W - w) / 2
        local e = CreateFrame("EditBox", nil, panel)
        e:SetSize(w, 28)
        e:SetPoint("TOPLEFT", x, y)
        e:SetAutoFocus(false) e:SetNumeric(false) e:SetMaxLetters(300)
        e:SetFontObject("GameFontHighlightSmall") e:SetText(val or "")
        local t = e:CreateTexture(nil, "BACKGROUND")
        t:SetAllPoints() t:SetTexture(0, 0, 0, 0.7)
        local b = e:CreateTexture(nil, "BORDER")
        b:SetPoint("TOPLEFT", -1, 1) b:SetPoint("BOTTOMRIGHT", 1, -1)
        b:SetTexture(0.35, 0.35, 0.35, 1)
        e:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
        e:SetScript("OnEnterPressed",  function(s) s:ClearFocus() end)
        return e
    end

    local function PosGrid(panel, yStart, cfgKey)
        local buttons = {}
        local btnW, btnH, rowStep, gap = 124, POS_GRID_BTN_H, POS_GRID_ROW_STEP, 8
        local gridW = btnW * 3 + gap * 2
        local startX = (MENU_W - gridW) / 2
        local function Refresh()
            local cur = StoneGrid_Config[cfgKey] or "TOPRIGHT"
            for key, pb in pairs(buttons) do
                if key == cur then
                    pb.bg:SetTexture(0.0, 0.498, 0.816, 0.95)
                    pb.txt:SetTextColor(1, 1, 1)
                else
                    pb.bg:SetTexture(0.22, 0.22, 0.22, 0.95)
                    pb.txt:SetTextColor(0.6, 0.6, 0.6)
                end
            end
        end
        local function PBtn(key, label, x, y)
            local btn = CreateFrame("Button", nil, panel)
            btn:SetSize(btnW, btnH) btn:SetPoint("TOPLEFT", x, y)
            btn.bg = btn:CreateTexture(nil, "BACKGROUND") btn.bg:SetAllPoints()
            btn.txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.txt:SetAllPoints() btn.txt:SetText(label)
            btn:SetScript("OnClick", function()
                StoneGrid_Config[cfgKey] = key Refresh() StoneGrid:UpdateAllAuras()
            end)
            buttons[key] = btn
        end
        PBtn("TOPLEFT",    L.TopLeft   or "Top Left",    startX,                 yStart)
        PBtn("TOP",        L.TopCenter or "Top Center",  startX + btnW + gap,    yStart)
        PBtn("TOPRIGHT",   L.TopRight  or "Top Right",   startX + 2 * (btnW + gap), yStart)
        PBtn("MIDLEFT",    L.MidLeft   or "Mid Left",    startX,                 yStart - rowStep)
        PBtn("MIDRIGHT",   L.MidRight  or "Mid Right",   startX + 2 * (btnW + gap), yStart - rowStep)
        PBtn("BOTTOMLEFT", L.BotLeft   or "Bot Left",    startX,                 yStart - rowStep * 2)
        PBtn("BOTTOM",     L.BotCenter or "Bot Center",  startX + btnW + gap,    yStart - rowStep * 2)
        PBtn("BOTTOMRIGHT",L.BotRight  or "Bot Right",   startX + 2 * (btnW + gap), yStart - rowStep * 2)
        Refresh()
        return Refresh
    end

    -- Pet position button row helper
    local function PetPosBtns(panel, cfgKey, y, onCreate)
        local lbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", 18, y) lbl:SetText(L.Position or "Position:") lbl:SetTextColor(0.65, 0.65, 0.65)
        local POS = { "RIGHT", "LEFT", "TOP", "BOTTOM" }
        local posbtns = {}
        local function Ref()
            local cur = StoneGrid_Config[cfgKey] or "BOTTOM"
            for _, p in ipairs(POS) do
                if posbtns[p] then
                    if p == cur then
                        posbtns[p].bg:SetTexture(0.0, 0.498, 0.816, 0.95)
                        posbtns[p].lbl:SetTextColor(1, 1, 1)
                    else
                        posbtns[p].bg:SetTexture(0.22, 0.22, 0.22, 0.95)
                        posbtns[p].lbl:SetTextColor(0.6, 0.6, 0.6)
                    end
                end
            end
        end
        for i, p in ipairs(POS) do
            local bx = 12 + (i - 1) * 66
            local pb = CreateFrame("Button", nil, panel)
            pb:SetSize(62, 22) pb:SetPoint("TOPLEFT", bx, y - 20)
            local pbg = pb:CreateTexture(nil, "BACKGROUND") pbg:SetAllPoints()
            local lt  = pb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lt:SetAllPoints() lt:SetText(p)
            posbtns[p] = { bg = pbg, lbl = lt }
            pb:SetScript("OnClick", function()
                StoneGrid_Config[cfgKey] = p
                Ref() onCreate()
            end)
        end
        Ref()
        return Ref
    end

    -- ============================================================
    -- PANEL MAIN
    -- ============================================================
    local MAIN_PAD = 28
    local MAIN_W = MENU_W - MAIN_PAD * 2
    local MAIN_X = MAIN_PAD
    local MAIN_BTN_GAP = 12
    local MAIN_LANG_BTN_W = math.floor((MAIN_W - MAIN_BTN_GAP) / 2)
    local MAIN_LOCK_BTN_W = math.floor((MAIN_W - MAIN_BTN_GAP) / 2)

    SectionLabel(panelMain, L.SectionLang or "[ Language ]", -10)

    local langBtns = {}
    refresh.langButton = function()
        local cur = (StoneGrid_Config and StoneGrid_Config.Language) or GetLocale()
        if cur == "enGB" then cur = "enUS" end
        for _, lb in ipairs(langBtns) do
            if lb.code == cur then
                lb.bg:SetTexture(COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], 0.95)
            else
                lb.bg:SetTexture(COL_INACTIVE[1], COL_INACTIVE[2], COL_INACTIVE[3], 0.95)
            end
        end
    end

    for i, lang in ipairs(LANGUAGES) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local bx  = MAIN_X + col * (MAIN_LANG_BTN_W + MAIN_BTN_GAP)
        local by  = -30 - row * 28
        local btn = CreateFrame("Button", nil, panelMain)
        btn:SetSize(MAIN_LANG_BTN_W, 22) btn:SetPoint("TOPLEFT", bx, by)
        local bgTex = btn:CreateTexture(nil, "BACKGROUND")
        bgTex:SetAllPoints()
        bgTex:SetTexture(COL_INACTIVE[1], COL_INACTIVE[2], COL_INACTIVE[3], 0.95)
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints() lbl:SetText(lang.native) lbl:SetTextColor(0.780, 0.780, 0.780)
        local code = lang.code
        btn:SetScript("OnClick", function()
            if StoneGrid_Config.Language ~= code then
                StoneGrid_Config.Language = code
                SaveActiveProfile()
                ReloadUI()
            end
        end)
        langBtns[#langBtns + 1] = { code = code, bg = bgTex }
    end
    refresh.langButton()

    local langSepY = -30 - math.ceil(#LANGUAGES / 2) * 28 - 4
    Separator(panelMain, langSepY)

    SectionLabel(panelMain, "[ " .. (L.Lock or "Lock") .. " ]", langSepY - 12)

    lockLabel = panelMain:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lockLabel:SetPoint("TOPLEFT", 12, langSepY - 28)
    RefreshLockLabel()

    Btn(panelMain, L.Unlock or "Unlock", MAIN_X, langSepY - 48, MAIN_LOCK_BTN_W, function()
        StoneGrid_Config.Locked=false
        StoneGrid_Party:SetLocked(false) StoneGrid_Raid:SetLocked(false)
        StoneGrid_Test:RefreshLock() RefreshLockLabel()
        SgMsg(L.MsgUnlocked or "Frames unlocked.")
    end)
    Btn(panelMain, L.Lock or "Lock", MAIN_X + MAIN_LOCK_BTN_W + MAIN_BTN_GAP, langSepY - 48, MAIN_LOCK_BTN_W, function()
        StoneGrid_Config.Locked=true
        StoneGrid_Party:SetLocked(true) StoneGrid_Raid:SetLocked(true)
        StoneGrid_Test:RefreshLock() RefreshLockLabel()
        SgMsg(L.MsgLocked or "Frames locked.")
    end)

    local lockSepY = langSepY - 78
    Separator(panelMain, lockSepY)

    SectionLabel(panelMain, L.SectionBlizzard or "[ Blizzard ]", lockSepY - 12)
    do
        local btn = CreateFrame("Button", nil, panelMain)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, lockSepY - 32)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelMain:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, lockSepY - 32)
        lbl2:SetText(L.HideBlizzardParty or "Hide Blizzard party frames")
        lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkHideParty = function()
            if StoneGrid_Config.HideBlizzardPartyFrames then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkHideParty()
        btn:SetScript("OnClick", function()
            local enable = not StoneGrid_Config.HideBlizzardPartyFrames
            StoneGrid_Config.HideBlizzardPartyFrames = enable
            SaveActiveProfile()
            refresh.chkHideParty()
            if enable then
                StoneGrid_ApplyBlizzardPartyFrames()
                SgMsg(L.MsgHidePartyOn or "Blizzard party frames hidden.")
            else
                SgMsg(L.MsgHidePartyOff or "Reload UI to restore Blizzard party frames.")
                ReloadUI()
            end
        end)
    end

    local blizzSepY = lockSepY - 56
    Separator(panelMain, blizzSepY)

    SectionLabel(panelMain, L.SectionCombatLog or "[ Combat log ]", blizzSepY - 12)
    do
        local btn = CreateFrame("Button", nil, panelMain)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, blizzSepY - 32)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelMain:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, blizzSepY - 32)
        lbl2:SetText(L.CombatLogAutoDetect or "Auto-fix in combat (stuck log)")
        lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkCombatLogAuto = function()
            if StoneGrid_Config.CombatLogAutoDetect then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkCombatLogAuto()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.CombatLogAutoDetect = not StoneGrid_Config.CombatLogAutoDetect
            SaveActiveProfile()
            refresh.chkCombatLogAuto()
        end)
    end

    local combatLogSepY = blizzSepY - 56
    Separator(panelMain, combatLogSepY)

    SectionLabel(panelMain, L.SectionRange or "[ Range ]", combatLogSepY - 12)
    do
        local btn = CreateFrame("Button", nil, panelMain)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, combatLogSepY - 32)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelMain:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, combatLogSepY - 32)
        lbl2:SetText(L.DetectRange or "Detect Range") lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.oorCheck = function()
            if StoneGrid_Config.OutOfRangeCheck then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.oorCheck()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.OutOfRangeCheck = not StoneGrid_Config.OutOfRangeCheck
            refresh.oorCheck() StoneGrid:UpdateAllRanges()
        end)
    end
    do
        local lbl2 = panelMain:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 18, combatLogSepY - 54)
        lbl2:SetText(L.OOROpacity or "Out of range opacity (%):") lbl2:SetTextColor(0.85, 0.85, 0.85)
        eb.OORAlpha = SmallEB(panelMain, 210, combatLogSepY - 52,
            math.floor((StoneGrid_Config.OutOfRangeAlpha or 0.3) * 100))
        local function ApplyAlpha()
            local a = eb.OORAlpha:GetNumber()
            if a >= 0 and a <= 100 then
                StoneGrid_Config.OutOfRangeAlpha = a / 100
                StoneGrid:UpdateAllRanges()
            end
        end
        eb.OORAlpha:SetScript("OnEnterPressed", function(s) s:ClearFocus() ApplyAlpha() end)
        eb.OORAlpha:SetScript("OnEditFocusLost", ApplyAlpha)
    end

    local raidIconSepY = combatLogSepY - 78
    Separator(panelMain, raidIconSepY)
    SectionLabel(panelMain, L.SectionRaidIcon or "[ Raid icon ]", raidIconSepY - 12)

    do
        local btn = CreateFrame("Button", nil, panelMain)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, raidIconSepY - 32)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelMain:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, raidIconSepY - 32)
        lbl2:SetText(L.ShowRaidIcon or "Show raid icon") lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkRaidIcon = function()
            if StoneGrid_Config.ShowRaidIcon then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkRaidIcon()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.ShowRaidIcon = not StoneGrid_Config.ShowRaidIcon
            refresh.chkRaidIcon()
            StoneGrid:UpdateAllRaidIcons()
        end)
    end

    refresh.raidIconPos = PetPosBtns(panelMain, "RaidIconPosition", raidIconSepY - 54, function()
        StoneGrid:UpdateAllRaidIcons()
    end)

    local settingsSepY = raidIconSepY - 104
    Separator(panelMain, settingsSepY)
    SectionLabel(panelMain, L.SectionSettings or "[ Settings ]", settingsSepY - 12)

    do
        local btn = CreateFrame("Button", nil, panelMain)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, settingsSepY - 32)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelMain:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, settingsSepY - 32)
        lbl2:SetText(L.ShowMinimapButton or "Show minimap button") lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkMinimap = function()
            if StoneGrid_Config.ShowMinimapButton ~= false then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkMinimap()
        btn:SetScript("OnClick", function()
            local on = StoneGrid_Config.ShowMinimapButton ~= false
            StoneGrid_Config.ShowMinimapButton = not on
            SaveActiveProfile()
            refresh.chkMinimap()
            if StoneGrid_Minimap then StoneGrid_Minimap:UpdateVisibility() end
        end)
    end

    -- ============================================================
    -- PANEL PARTY
    -- ============================================================
    SectionLabel(panelParty, L.SectionParty or "[ Party ]", -10)

    Label(panelParty, L.Width   or "Width:",   -30) eb.PW = EditBox(panelParty, -29, StoneGrid_Config.PartyWidth)
    Label(panelParty, L.Height  or "Height:",  -52) eb.PH = EditBox(panelParty, -51, StoneGrid_Config.PartyHeight)
    Label(panelParty, L.Columns or "Columns:", -74) eb.PC = EditBox(panelParty, -73, StoneGrid_Config.PartyColumns or 1)
    Label(panelParty, L.Spacing or "Spacing:", -96) eb.PS = EditBox(panelParty, -95, StoneGrid_Config.PartySpacing)

    -- Power bar row
    do
        local btn = CreateFrame("Button", nil, panelParty)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, -118)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelParty:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, -118) lbl2:SetText("Power bar") lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkPartyPowerBar = function()
            if StoneGrid_Config.ShowPartyPowerBar then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkPartyPowerBar()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.ShowPartyPowerBar = not StoneGrid_Config.ShowPartyPowerBar
            refresh.chkPartyPowerBar()
            if not StoneGrid_Test:IsActive() and not StoneGrid:ShouldUseRaidFrames() then StoneGrid_Party:Create() end
        end)
    end
    _, eb.PartyPowerH = MetricLabelAndEB(panelParty, "Power Height:", -118, StoneGrid_Config.PartyPowerBarH or 4)

    Separator(panelParty, -142)
    SectionLabel(panelParty, L.SectionCharmed or "[ Charmed ]", -154)
    do
        local btn = CreateFrame("Button", nil, panelParty)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, -174)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelParty:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, -174) lbl2:SetText(L.ShowPvpIcons or "Show PVP icons") lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkPartyStuns = function()
            if StoneGrid_Config.ShowPartyStuns then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkPartyStuns()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.ShowPartyStuns = not StoneGrid_Config.ShowPartyStuns
            refresh.chkPartyStuns()
            if not StoneGrid_Test:IsActive() and not StoneGrid:ShouldUseRaidFrames() then StoneGrid_Party:Create() end
        end)
    end
    ILabel(panelParty, L.SizePx or "Size (px):", 190, -174)
    eb.PartyCcSize = SmallEB(panelParty, 240, -174, StoneGrid_Config.PartyCcIconSize or 20)
    do
        local btn = CreateFrame("Button", nil, panelParty)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, -196)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelParty:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, -196) lbl2:SetText(L.ShowDungeonDebuffs or "Show dungeon debuffs") lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkDungeonDebuffs = function()
            if StoneGrid_Config.ShowDungeonDebuffs ~= false then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkDungeonDebuffs()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.ShowDungeonDebuffs = not (StoneGrid_Config.ShowDungeonDebuffs ~= false)
            refresh.chkDungeonDebuffs()
            if not StoneGrid_Test:IsActive() and not StoneGrid:ShouldUseRaidFrames() then StoneGrid_Party:Create() end
        end)
    end
    ILabel(panelParty, L.SizePx or "Size (px):", 190, -196)
    eb.DungeonDebuffSize = SmallEB(panelParty, 240, -196, StoneGrid_Config.DungeonDebuffIconSize or 20)

    Separator(panelParty, -222)

    -- Party Pets
    SectionLabel(panelParty, "[ Party Pets ]", -234)
    do
        local btn = CreateFrame("Button", nil, panelParty)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, -254)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelParty:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, -254) lbl2:SetText("Show Party Pets") lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkPartyPets = function()
            if StoneGrid_Config.ShowPartyPets then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkPartyPets()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.ShowPartyPets = not StoneGrid_Config.ShowPartyPets
            refresh.chkPartyPets()
            if not InCombatLockdown() and not StoneGrid:ShouldUseRaidFrames() then StoneGrid_Party:Create() end
        end)
    end

    refresh.partyPetPos = PetPosBtns(panelParty, "PartyPetPosition", -276, function()
        if not InCombatLockdown() and not StoneGrid:ShouldUseRaidFrames() then StoneGrid_Party:Create() end
    end)

    Separator(panelParty, -326)

    do
        ILabel(panelParty, L.Width   or "Width:",   18,  -340)
        eb.PPW = SmallEB(panelParty, 74, -339, StoneGrid_Config.PartyPetWidth)
        ILabel(panelParty, L.Height  or "Height:",  132, -340)
        eb.PPH = SmallEB(panelParty, 194, -339, StoneGrid_Config.PartyPetHeight)
    end
    do
        ILabel(panelParty, L.Spacing or "Spacing:", 18,  -362)
        eb.PPSp = SmallEB(panelParty, 74, -361, StoneGrid_Config.PartyPetSpacing)
        ILabel(panelParty, L.Columns or "Columns:", 132, -362)
        eb.PPCols = SmallEB(panelParty, 194, -361, StoneGrid_Config.PartyPetColumns or 1)
    end

    Separator(panelParty, -388)
    do
        local btn = CreateFrame("Button", nil, panelParty)
        btn:SetSize(TEST_BTN_W, 22) btn:SetPoint("TOPLEFT", CenteredBtnX(TEST_BTN_W), -400)
        local bg = btn:CreateTexture(nil, "BACKGROUND") bg:SetAllPoints()
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") lbl:SetAllPoints()
        refreshTestPartyBtn = function()
            if StoneGrid_Test:IsActive() then
                bg:SetTexture(0.85, 0.62, 0.0, 0.95)
                lbl:SetText((L.TestParty or "Test Party") .. "  [ ON ]")
            else
                bg:SetTexture(0.18, 0.52, 0.18, 0.95)
                lbl:SetText((L.TestParty or "Test Party") .. "  [ OFF ]")
            end
            lbl:SetTextColor(0.95, 0.95, 0.95)
        end
        refreshTestPartyBtn()
        btn:SetScript("OnClick", function()
            if StoneGrid_Test:IsActive() then
                StoneGrid_Test:Stop()
                SgMsg(L.MsgTestOff or "Test mode disabled.")
            else
                StoneGrid_Test:ShowParty()
            end
            refreshTestPartyBtn()
            if refreshTestRaidBtn then refreshTestRaidBtn() end
        end)
    end

    Separator(panelParty, BOTTOM_SEP_Y)

    local saveX, resetX = CenteredSaveResetX()
    Btn(panelParty, L.Save or "Save", saveX, BOTTOM_BTN_Y, SAVE_BTN_W, function()
        local pw,ph,pc,ps = eb.PW:GetNumber(), eb.PH:GetNumber(), eb.PC:GetNumber(), eb.PS:GetNumber()
        if pw>0 then StoneGrid_Config.PartyWidth=pw end
        if ph>0 then StoneGrid_Config.PartyHeight=ph end
        if pc>0 then StoneGrid_Config.PartyColumns=pc end
        if ps>=0 then StoneGrid_Config.PartySpacing=ps end
        local pbH = eb.PartyPowerH:GetNumber()
        if pbH > 0 then StoneGrid_Config.PartyPowerBarH = pbH end
        local ccS = eb.PartyCcSize and eb.PartyCcSize:GetNumber()
        if ccS and ccS > 0 then StoneGrid_Config.PartyCcIconSize = ccS end
        local dungeonS = eb.DungeonDebuffSize and eb.DungeonDebuffSize:GetNumber()
        if dungeonS and dungeonS > 0 then StoneGrid_Config.DungeonDebuffIconSize = dungeonS end
        local ppw = eb.PPW:GetNumber()    if ppw  > 0  then StoneGrid_Config.PartyPetWidth   = ppw  end
        local pph = eb.PPH:GetNumber()    if pph  > 0  then StoneGrid_Config.PartyPetHeight  = pph  end
        local pps = eb.PPSp:GetNumber()   if pps  >= 0 then StoneGrid_Config.PartyPetSpacing = pps  end
        local ppc = eb.PPCols:GetNumber() if ppc  > 0  then StoneGrid_Config.PartyPetColumns = ppc  end
        if not InCombatLockdown() and not StoneGrid:ShouldUseRaidFrames() then StoneGrid_Party:Create() end
        SaveActiveProfile()
        SgMsg(L.MsgPartySaved or "Party saved.")
    end)

    Btn(panelParty, L.Reset or "Reset", resetX, BOTTOM_BTN_Y, SAVE_BTN_W, function()
        StoneGrid_Config.PartyWidth=150 StoneGrid_Config.PartyHeight=30 StoneGrid_Config.PartyColumns=1 StoneGrid_Config.PartySpacing=3
        StoneGrid_Config.ShowPartyPowerBar=false StoneGrid_Config.PartyPowerBarH=4
        StoneGrid_Config.ShowPartyStuns=true StoneGrid_Config.PartyCcIconSize=20
        StoneGrid_Config.ShowDungeonDebuffs=true StoneGrid_Config.DungeonDebuffIconSize=20
        StoneGrid_Config.ShowPartyPets=false
        StoneGrid_Config.PartyPetWidth=80 StoneGrid_Config.PartyPetHeight=16
        StoneGrid_Config.PartyPetSpacing=2 StoneGrid_Config.PartyPetColumns=1
        StoneGrid_Config.PartyPetPosition="BOTTOM"
        eb.PW:SetNumber(150) eb.PH:SetNumber(30) eb.PC:SetNumber(1) eb.PS:SetNumber(3)
        eb.PartyPowerH:SetNumber(4) refresh.chkPartyPowerBar()
        if eb.PartyCcSize then eb.PartyCcSize:SetNumber(20) end
        if eb.DungeonDebuffSize then eb.DungeonDebuffSize:SetNumber(20) end
        if refresh.chkPartyStuns then refresh.chkPartyStuns() end
        if refresh.chkDungeonDebuffs then refresh.chkDungeonDebuffs() end
        if refresh.chkPartyPets then refresh.chkPartyPets() end
        eb.PPW:SetNumber(80) eb.PPH:SetNumber(16) eb.PPSp:SetNumber(2) eb.PPCols:SetNumber(1)
        refresh.partyPetPos()
        if not InCombatLockdown() and not StoneGrid:ShouldUseRaidFrames() then StoneGrid_Party:Create() end
        SgMsg(L.MsgPartyReset or "Party reset.")
    end)

    -- ============================================================
    -- PANEL RAID
    -- ============================================================
    local function SaveRaidEditToPreset()
        local sz = StoneGrid_Config.RaidEditSize or "25"
        local p = StoneGrid_GetRaidPreset(StoneGrid_Config, sz)
        for _, key in ipairs(StoneGrid_RaidLayoutKeys) do
            p[key] = StoneGrid_Config[key]
        end
    end

    local function LoadRaidEditFromPreset()
        local sz = StoneGrid_Config.RaidEditSize or "25"
        StoneGrid_SyncFlatRaidFromPreset(StoneGrid_Config, sz)
    end

    refresh.raidEditLoad = function()
        LoadRaidEditFromPreset()
        if eb.RW then eb.RW:SetNumber(StoneGrid_Config.RaidWidth or 80) end
        if eb.RH then eb.RH:SetNumber(StoneGrid_Config.RaidHeight or 20) end
        if eb.RC then eb.RC:SetNumber(StoneGrid_Config.RaidColumns or 5) end
        if eb.RS then eb.RS:SetNumber(StoneGrid_Config.RaidSpacing or 3) end
        if eb.RaidPowerH then eb.RaidPowerH:SetNumber(StoneGrid_Config.RaidPowerBarH or 3) end
        if eb.RaidCcSize then eb.RaidCcSize:SetNumber(StoneGrid_Config.RaidCcIconSize or 16) end
        if eb.RPW then eb.RPW:SetNumber(StoneGrid_Config.RaidPetWidth or 80) end
        if eb.RPH then eb.RPH:SetNumber(StoneGrid_Config.RaidPetHeight or 14) end
        if eb.RPSp then eb.RPSp:SetNumber(StoneGrid_Config.RaidPetSpacing or 2) end
        if eb.RPCols then eb.RPCols:SetNumber(StoneGrid_Config.RaidPetColumns or 5) end
        if eb.RaidPetMax then
            local sz = tonumber(StoneGrid_Config.RaidEditSize or "25") or 25
            eb.RaidPetMax:SetNumber(StoneGrid_Config.RaidPetMax or sz)
        end
        if refresh.chkRaidPowerBar then refresh.chkRaidPowerBar() end
        if refresh.chkRaidStuns then refresh.chkRaidStuns() end
        if refresh.chkRaidDebuffs then refresh.chkRaidDebuffs() end
        if eb.RaidRdSize then eb.RaidRdSize:SetNumber(StoneGrid_Config.RaidDebuffIconSize or 16) end
        if refresh.chkRaidPets then refresh.chkRaidPets() end
        if refresh.raidPetPos then refresh.raidPetPos() end
        if refresh.raidSizeButtons then refresh.raidSizeButtons() end
        if refresh.chkRaidSizeAuto then refresh.chkRaidSizeAuto() end
        if refresh.raidDetectLabel then refresh.raidDetectLabel() end
    end

    SectionLabel(panelRaid, L.SectionRaid or "[ Raid ]", -10)

    Label(panelRaid, L.Width   or "Width:",   -30) eb.RW = EditBox(panelRaid, -29, StoneGrid_Config.RaidWidth)
    Label(panelRaid, L.Height  or "Height:",  -52) eb.RH = EditBox(panelRaid, -51, StoneGrid_Config.RaidHeight)
    Label(panelRaid, L.Columns or "Columns:", -74) eb.RC = EditBox(panelRaid, -73, StoneGrid_Config.RaidColumns)
    Label(panelRaid, L.Spacing or "Spacing:", -96) eb.RS = EditBox(panelRaid, -95, StoneGrid_Config.RaidSpacing)
    LoadRaidEditFromPreset()

    -- Power bar row
    do
        local btn = CreateFrame("Button", nil, panelRaid)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, -118)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelRaid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, -118) lbl2:SetText("Power bar") lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkRaidPowerBar = function()
            if StoneGrid_Config.ShowRaidPowerBar then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkRaidPowerBar()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.ShowRaidPowerBar = not StoneGrid_Config.ShowRaidPowerBar
            SaveRaidEditToPreset()
            refresh.chkRaidPowerBar()
            if not StoneGrid_Test:IsActive() and StoneGrid:ShouldUseRaidFrames() then StoneGrid_Raid:Create() end
        end)
    end
    _, eb.RaidPowerH = MetricLabelAndEB(panelRaid, "Power Height:", -118, StoneGrid_Config.RaidPowerBarH or 3)

    Separator(panelRaid, -142)
    SectionLabel(panelRaid, L.SectionCharmed or "[ Charmed ]", -154)
    do
        local btn = CreateFrame("Button", nil, panelRaid)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, -174)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelRaid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, -174) lbl2:SetText(L.ShowPvpIcons or "Show PVP icons") lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkRaidStuns = function()
            if StoneGrid_Config.ShowRaidStuns then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkRaidStuns()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.ShowRaidStuns = not StoneGrid_Config.ShowRaidStuns
            SaveRaidEditToPreset()
            refresh.chkRaidStuns()
            if not StoneGrid_Test:IsActive() and StoneGrid:ShouldUseRaidFrames() then StoneGrid_Raid:Create() end
        end)
    end
    ILabel(panelRaid, L.SizePx or "Size (px):", 190, -174)
    eb.RaidCcSize = SmallEB(panelRaid, 240, -174, StoneGrid_Config.RaidCcIconSize or 16)

    do
        local btn = CreateFrame("Button", nil, panelRaid)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, -196)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelRaid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, -196) lbl2:SetText(L.ShowRaidDebuffs or "Show raid debuffs") lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkRaidDebuffs = function()
            if StoneGrid_Config.ShowRaidDebuffs then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkRaidDebuffs()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.ShowRaidDebuffs = not StoneGrid_Config.ShowRaidDebuffs
            SaveRaidEditToPreset()
            refresh.chkRaidDebuffs()
            if not StoneGrid_Test:IsActive() and StoneGrid:ShouldUseRaidFrames() then StoneGrid_Raid:Create() end
            StoneGrid:UpdateAllAuras()
        end)
    end
    ILabel(panelRaid, L.SizePx or "Size (px):", 190, -196)
    eb.RaidRdSize = SmallEB(panelRaid, 240, -196, StoneGrid_Config.RaidDebuffIconSize or 16)

    Separator(panelRaid, -222)

    -- Raid Pets
    SectionLabel(panelRaid, "[ Raid Pets ]", -234)
    do
        local btn = CreateFrame("Button", nil, panelRaid)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, -254)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelRaid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, -254) lbl2:SetText("Show Raid Pets") lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkRaidPets = function()
            if StoneGrid_Config.ShowRaidPets then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkRaidPets()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.ShowRaidPets = not StoneGrid_Config.ShowRaidPets
            SaveRaidEditToPreset()
            refresh.chkRaidPets()
            if not InCombatLockdown() and StoneGrid:ShouldUseRaidFrames() then StoneGrid_Raid:Create() end
        end)
    end
    ILabel(panelRaid, L.RaidPetMax or "Max pets:", 132, -254)
    eb.RaidPetMax = SmallEB(panelRaid, 194, -253, StoneGrid_Config.RaidPetMax or tonumber(StoneGrid_Config.RaidEditSize or "25") or 25)
    eb.RaidPetMax:SetScript("OnEnterPressed", function(s)
        s:ClearFocus()
        local n = s:GetNumber()
        if n >= 0 then
            StoneGrid_Config.RaidPetMax = n
            SaveRaidEditToPreset()
        end
        if not InCombatLockdown() and StoneGrid:ShouldUseRaidFrames() then StoneGrid_Raid:Create() end
        if StoneGrid_Test.raidActive then StoneGrid_Test:ShowRaid() end
    end)

    refresh.raidPetPos = PetPosBtns(panelRaid, "RaidPetPosition", -276, function()
        SaveRaidEditToPreset()
        if not InCombatLockdown() and StoneGrid:ShouldUseRaidFrames() then StoneGrid_Raid:Create() end
    end)

    Separator(panelRaid, -326)

    do
        ILabel(panelRaid, L.Width   or "Width:",   18,  -340)
        eb.RPW = SmallEB(panelRaid, 74, -339, StoneGrid_Config.RaidPetWidth)
        ILabel(panelRaid, L.Height  or "Height:",  132, -340)
        eb.RPH = SmallEB(panelRaid, 194, -339, StoneGrid_Config.RaidPetHeight)
    end
    do
        ILabel(panelRaid, L.Spacing or "Spacing:", 18,  -362)
        eb.RPSp = SmallEB(panelRaid, 74, -361, StoneGrid_Config.RaidPetSpacing)
        ILabel(panelRaid, L.Columns or "Columns:", 132, -362)
        eb.RPCols = SmallEB(panelRaid, 194, -361, StoneGrid_Config.RaidPetColumns or 5)
    end

    Separator(panelRaid, -388)
    SectionLabel(panelRaid, L.RaidSizeSection or "[ Raid Size ]", -400)

    local RAID_SIZE_PAD = 28
    local RAID_SIZE_W = MENU_W - RAID_SIZE_PAD * 2
    local RAID_SIZE_BTN_GAP = 6
    local RAID_SIZE_BTN_W = math.floor((RAID_SIZE_W - RAID_SIZE_BTN_GAP * (#StoneGrid_RaidSizes - 1)) / #StoneGrid_RaidSizes)
    local RAID_SIZE_ROW_W = RAID_SIZE_BTN_W * #StoneGrid_RaidSizes + RAID_SIZE_BTN_GAP * (#StoneGrid_RaidSizes - 1)
    local RAID_SIZE_X = math.floor((MENU_W - RAID_SIZE_ROW_W) / 2)

    do
        local btn = CreateFrame("Button", nil, panelRaid)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, -422)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelRaid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, -422)
        lbl2:SetText(L.RaidSizeAuto or "Auto-detect size in raid")
        lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkRaidSizeAuto = function()
            if StoneGrid_Config.RaidSizeAuto ~= false then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkRaidSizeAuto()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.RaidSizeAuto = not (StoneGrid_Config.RaidSizeAuto ~= false)
            refresh.chkRaidSizeAuto()
            if refresh.raidDetectLabel then refresh.raidDetectLabel() end
            if not InCombatLockdown() and StoneGrid:ShouldUseRaidFrames() then StoneGrid_Raid:Create() end
        end)
    end

    local raidDetectLabel = panelRaid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    raidDetectLabel:SetPoint("TOPLEFT", 18, -444)
    raidDetectLabel:SetWidth(MENU_W - 36)
    raidDetectLabel:SetJustifyH("LEFT")
    raidDetectLabel:SetTextColor(0.65, 0.65, 0.65)
    refresh.raidDetectLabel = function()
        local detected = StoneGrid_DetectRaidSize()
        if detected then
            raidDetectLabel:SetText((L.RaidSizeDetected or "Detected now:") .. " " .. detected)
        else
            raidDetectLabel:SetText(L.RaidSizeSolo or "Detected now: not in raid")
        end
    end
    refresh.raidDetectLabel()

    local raidSizeBtns = {}
    refresh.raidSizeButtons = function()
        local cur = StoneGrid_Config.RaidEditSize or "25"
        for _, rb in ipairs(raidSizeBtns) do
            if rb.size == cur then
                rb.bg:SetTexture(COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], 0.95)
                rb.lbl:SetTextColor(1, 1, 1)
            else
                rb.bg:SetTexture(COL_INACTIVE[1], COL_INACTIVE[2], COL_INACTIVE[3], 0.95)
                rb.lbl:SetTextColor(0.78, 0.78, 0.78)
            end
        end
    end

    for i, sz in ipairs(StoneGrid_RaidSizes) do
        local bx = RAID_SIZE_X + (i - 1) * (RAID_SIZE_BTN_W + RAID_SIZE_BTN_GAP)
        local btn = CreateFrame("Button", nil, panelRaid)
        btn:SetSize(RAID_SIZE_BTN_W, 22)
        btn:SetPoint("TOPLEFT", bx, -466)
        local bgTex = btn:CreateTexture(nil, "BACKGROUND")
        bgTex:SetAllPoints()
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetAllPoints()
        lbl:SetText(sz)
        btn:SetScript("OnClick", function()
            SaveRaidEditToPreset()
            StoneGrid_Config.RaidEditSize = sz
            refresh.raidEditLoad()
            if StoneGrid_Test.raidActive then StoneGrid_Test:ShowRaid() end
        end)
        raidSizeBtns[#raidSizeBtns + 1] = { size = sz, bg = bgTex, lbl = lbl }
    end
    refresh.raidSizeButtons()

    Separator(panelRaid, -494)
    do
        local btn = CreateFrame("Button", nil, panelRaid)
        btn:SetSize(TEST_BTN_W, 22) btn:SetPoint("TOPLEFT", CenteredBtnX(TEST_BTN_W), -506)
        local bg = btn:CreateTexture(nil, "BACKGROUND") bg:SetAllPoints()
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") lbl:SetAllPoints()
        refreshTestRaidBtn = function()
            if StoneGrid_Test:IsActive() then
                bg:SetTexture(0.85, 0.62, 0.0, 0.95)
                lbl:SetText((L.TestRaid or "Test Raid") .. "  [ ON ]")
            else
                bg:SetTexture(0.18, 0.52, 0.18, 0.95)
                lbl:SetText((L.TestRaid or "Test Raid") .. "  [ OFF ]")
            end
            lbl:SetTextColor(0.95, 0.95, 0.95)
        end
        refreshTestRaidBtn()
        btn:SetScript("OnClick", function()
            if StoneGrid_Test:IsActive() then
                StoneGrid_Test:Stop()
                SgMsg(L.MsgTestOff or "Test mode disabled.")
            else
                StoneGrid_Test:ShowRaid()
            end
            refreshTestRaidBtn()
            if refreshTestPartyBtn then refreshTestPartyBtn() end
        end)
    end

    Separator(panelRaid, BOTTOM_SEP_Y)

    local saveX, resetX = CenteredSaveResetX()
    Btn(panelRaid, L.Save or "Save", saveX, BOTTOM_BTN_Y, SAVE_BTN_W, function()
        local rw,rh,rc,rs = eb.RW:GetNumber(), eb.RH:GetNumber(), eb.RC:GetNumber(), eb.RS:GetNumber()
        if rw>0 then StoneGrid_Config.RaidWidth=rw end
        if rh>0 then StoneGrid_Config.RaidHeight=rh end
        if rc>0 then StoneGrid_Config.RaidColumns=rc end
        if rs>=0 then StoneGrid_Config.RaidSpacing=rs end
        local pbH = eb.RaidPowerH:GetNumber()
        if pbH > 0 then StoneGrid_Config.RaidPowerBarH = pbH end
        local ccS = eb.RaidCcSize and eb.RaidCcSize:GetNumber()
        if ccS and ccS > 0 then StoneGrid_Config.RaidCcIconSize = ccS end
        local rdS = eb.RaidRdSize and eb.RaidRdSize:GetNumber()
        if rdS and rdS > 0 then StoneGrid_Config.RaidDebuffIconSize = rdS end
        local rpw = eb.RPW:GetNumber()    if rpw  > 0  then StoneGrid_Config.RaidPetWidth   = rpw  end
        local rph = eb.RPH:GetNumber()    if rph  > 0  then StoneGrid_Config.RaidPetHeight  = rph  end
        local rps = eb.RPSp:GetNumber()   if rps  >= 0 then StoneGrid_Config.RaidPetSpacing = rps  end
        local rpc = eb.RPCols:GetNumber() if rpc  > 0  then StoneGrid_Config.RaidPetColumns = rpc  end
        local rpm = eb.RaidPetMax and eb.RaidPetMax:GetNumber()
        if rpm ~= nil and rpm >= 0 then StoneGrid_Config.RaidPetMax = rpm end
        SaveRaidEditToPreset()
        if not InCombatLockdown() and StoneGrid:ShouldUseRaidFrames() then StoneGrid_Raid:Create() end
        if StoneGrid_Test.raidActive then StoneGrid_Test:ShowRaid() end
        SaveActiveProfile()
        SgMsg(L.MsgRaidSaved or "Raid saved.")
    end)

    Btn(panelRaid, L.Reset or "Reset", resetX, BOTTOM_BTN_Y, SAVE_BTN_W, function()
        local sz = StoneGrid_Config.RaidEditSize or "25"
        local p = StoneGrid_GetRaidPreset(StoneGrid_Config, sz)
        p.RaidWidth=80 p.RaidHeight=20 p.RaidColumns=5 p.RaidSpacing=3
        p.ShowRaidPowerBar=false p.RaidPowerBarH=3
        p.ShowRaidStuns=true p.RaidCcIconSize=16
        p.ShowRaidDebuffs=true p.RaidDebuffIconSize=16
        p.ShowRaidPets=false
        p.RaidPetWidth=80 p.RaidPetHeight=14
        p.RaidPetSpacing=2 p.RaidPetColumns=5
        p.RaidPetPosition="BOTTOM"
        p.RaidPetMax=tonumber(sz) or 0
        refresh.raidEditLoad()
        if not InCombatLockdown() and StoneGrid:ShouldUseRaidFrames() then StoneGrid_Raid:Create() end
        SaveActiveProfile()
        SgMsg(L.MsgRaidReset or "Raid reset.")
    end)

    -- ============================================================
    -- PANEL COLORS
    -- ============================================================
    SectionLabel(panelColors, L.BarColors or "[ Bar Colors ]", -10)

    refresh.swatchHp = ColorSwatch(panelColors, -34, L.HpBar or "HP Bar:",
        "HpBarR","HpBarG","HpBarB","HpBarA", function() StoneGrid:UpdateAll() end)

    refresh.swatchBg = ColorSwatch(panelColors, -58, L.MissingHpBg or "Missing HP Background:",
        "BgDarkR","BgDarkG","BgDarkB","BgDarkA", function() StoneGrid:UpdateBgDarkColors() end)

    refresh.swatchBorder = ColorSwatch(panelColors, -82, L.BorderColor or "Border color:",
        "BorderR","BorderG","BorderB","BorderA", function() StoneGrid:UpdateBorderColors() end)

    Label(panelColors, L.BorderSize or "Border:", -120)
    eb.BorderSize = EditBox(panelColors, -119, StoneGrid_Config.BorderSize)
    eb.BorderSize:SetNumeric(true)

    do
        local btn = CreateFrame("Button", nil, panelColors)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, -142)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.5, 0.5, 0.7, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local chkLabel = panelColors:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        chkLabel:SetPoint("TOPLEFT", 38, -142)
        chkLabel:SetText(L.ClassColor or "Class bar color") chkLabel:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkHpClass = function()
            if StoneGrid_Config.HpBarClass then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkHpClass()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.HpBarClass = not StoneGrid_Config.HpBarClass
            refresh.chkHpClass() StoneGrid:UpdateAll()
        end)
    end

    do
        local btn = CreateFrame("Button", nil, panelColors)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, -164)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.5, 0.5, 0.7, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local chkLabel = panelColors:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        chkLabel:SetPoint("TOPLEFT", 38, -164)
        chkLabel:SetText(L.NameClassColor or "Class name color") chkLabel:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkNameClass = function()
            if StoneGrid_Config.NameClassColor then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkNameClass()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.NameClassColor = not StoneGrid_Config.NameClassColor
            refresh.chkNameClass() StoneGrid:UpdateAll()
        end)
    end

    Separator(panelColors, -190)

    SectionLabel(panelColors, L.SectionIncomingHeal or "[ Incoming Heal ]", -202)

    refresh.swatchHeal = ColorSwatch(panelColors, -216, L.IncomingHeal or "Incoming Heal:",
        "HealBarR","HealBarG","HealBarB","HealBarA", function() StoneGrid:UpdateHealBarColors() end)

    do
        local function HealBarCheckbox(x, y, cfgKey, labelText)
            local btn = CreateFrame("Button", nil, panelColors)
            btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", x, y)
            local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
            local brd = btn:CreateTexture(nil, "BORDER")
            brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
            brd:SetTexture(0.40, 0.40, 0.40, 1)
            local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
            local lbl = panelColors:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("TOPLEFT", x + 20, y) lbl:SetText(labelText) lbl:SetTextColor(0.85, 0.85, 0.85)
            local function Refresh()
                if StoneGrid_Config[cfgKey] then
                    box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
                else
                    box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
                end
            end
            Refresh()
            btn:SetScript("OnClick", function()
                StoneGrid_Config[cfgKey] = not StoneGrid_Config[cfgKey]
                Refresh()
                StoneGrid:UpdateHealBars()
            end)
            return Refresh
        end

        refresh.chkShowOwnHot = HealBarCheckbox(18, -246, "ShowOwnHot",
            L.ShowOwnHot or "Show incoming HoT healing (mine)")
        refresh.chkShowOwnDirect = HealBarCheckbox(18, -272, "ShowOwnDirect",
            L.ShowOwnDirect or "Show incoming direct healing (mine)")
        refresh.chkIncludeOthersHot = HealBarCheckbox(18, -298, "IncludeOthersHot",
            L.IncludeOthersHot or "Include other players' HoT healing")
        refresh.chkIncludeOthersDirect = HealBarCheckbox(18, -324, "IncludeOthersDirect",
            L.IncludeOthersDirect or "Include other players' direct healing")
    end

    Separator(panelColors, -348)
    SectionLabel(panelColors, "[ Target ]", -360)
    do
        local btn = CreateFrame("Button", nil, panelColors)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, -382)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl2 = panelColors:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl2:SetPoint("TOPLEFT", 38, -382) lbl2:SetText("Target highlight") lbl2:SetTextColor(0.85, 0.85, 0.85)
        refresh.chkTargetHL = function()
            if StoneGrid_Config.TargetHighlight then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        refresh.chkTargetHL()
        btn:SetScript("OnClick", function()
            StoneGrid_Config.TargetHighlight = not StoneGrid_Config.TargetHighlight
            refresh.chkTargetHL()
            StoneGrid:UpdateBorderColors()
        end)
    end

    refresh.swatchTarget = ColorSwatch(panelColors, -406, "Color:",
        "TargetHighlightR", "TargetHighlightG", "TargetHighlightB", "TargetHighlightA",
        function() StoneGrid:UpdateBorderColors() end)

    Separator(panelColors, BOTTOM_SEP_Y)

    Btn(panelColors, L.Save or "Save", saveX, BOTTOM_BTN_Y, SAVE_BTN_W, function()
        local s = eb.BorderSize:GetNumber()
        if s >= 0 then StoneGrid_Config.BorderSize = s end
        StoneGrid:UpdateBorderColors()
        StoneGrid:UpdateBgDarkColors()
        StoneGrid:UpdateHealBarColors()
        StoneGrid:UpdateAll()
        SaveActiveProfile()
        SgMsg(L.MsgColorsSaved or "Colors saved.")
    end)

    Btn(panelColors, L.Reset or "Reset", resetX, BOTTOM_BTN_Y, SAVE_BTN_W, function()
        local c = StoneGrid_Config
        c.HpBarR=0    c.HpBarG=0.8  c.HpBarB=0    c.HpBarA=1.0 c.HpBarClass=true
        c.NameClassColor=false
        c.HealBarR=0  c.HealBarG=0.8 c.HealBarB=0  c.HealBarA=0.5
        c.ShowOwnHot=true c.ShowOwnDirect=true c.IncludeOthersHot=false c.IncludeOthersDirect=false
        c.BgDarkR=0.1 c.BgDarkG=0.1 c.BgDarkB=0.1 c.BgDarkA=1.0
        c.BorderR=0.3 c.BorderG=0.3 c.BorderB=0.3 c.BorderA=1.0 c.BorderSize=1
        c.TargetHighlight=true
        c.TargetHighlightR=1.0 c.TargetHighlightG=0.8 c.TargetHighlightB=0.0 c.TargetHighlightA=1.0
        if refresh.chkHpClass       then refresh.chkHpClass()       end
        if refresh.chkNameClass     then refresh.chkNameClass()     end
        if refresh.chkShowOwnHot          then refresh.chkShowOwnHot()          end
        if refresh.chkShowOwnDirect       then refresh.chkShowOwnDirect()       end
        if refresh.chkIncludeOthersHot    then refresh.chkIncludeOthersHot()    end
        if refresh.chkIncludeOthersDirect then refresh.chkIncludeOthersDirect() end
        if refresh.chkTargetHL      then refresh.chkTargetHL()      end
        if refresh.swatchHp         then refresh.swatchHp()         end
        if refresh.swatchHeal        then refresh.swatchHeal()       end
        if refresh.swatchBg          then refresh.swatchBg()         end
        if refresh.swatchBorder      then refresh.swatchBorder()     end
        if refresh.swatchTarget      then refresh.swatchTarget()     end
        if eb.BorderSize             then eb.BorderSize:SetNumber(1) end
        StoneGrid:UpdateAll()
        SgMsg(L.MsgColorsReset or "Colors reset.")
    end)

    -- ============================================================
    -- SHARED COOLDOWN-ICON SECTION (on both Buffs & Debuffs tabs)
    -- ============================================================
    local cdChecks = {}
    refresh.chkCooldown = function()
        for _, r in ipairs(cdChecks) do r() end
    end
    local function SyncCooldownEBs()
        local c = StoneGrid_Config
        if eb.BuffCdFont      then eb.BuffCdFont:SetNumber(c.CooldownFontSize or 8)      end
        if eb.DebuffCdFont    then eb.DebuffCdFont:SetNumber(c.CooldownFontSize or 8)    end
        if eb.BuffStackFont   then eb.BuffStackFont:SetNumber(c.StackFontSize or 6)      end
        if eb.DebuffStackFont then eb.DebuffStackFont:SetNumber(c.StackFontSize or 6)    end
    end
    local function CooldownSection(panel, y, cdKey, stackKey)
        local btn = CreateFrame("Button", nil, panel)
        btn:SetSize(16, 16) btn:SetPoint("TOPLEFT", 18, y)
        local box = btn:CreateTexture(nil, "BACKGROUND") box:SetAllPoints()
        local brd = btn:CreateTexture(nil, "BORDER")
        brd:SetPoint("TOPLEFT", -1, 1) brd:SetPoint("BOTTOMRIGHT", 1, -1)
        brd:SetTexture(0.40, 0.40, 0.40, 1)
        local mark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") mark:SetAllPoints()
        local lbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", 38, y) lbl:SetText(L.ShowCooldown or "Show cooldown")
        lbl:SetTextColor(0.85, 0.85, 0.85)
        local function RefreshChk()
            if StoneGrid_Config.ShowCooldown then
                box:SetTexture(0.2, 0.6, 0.2, 1) mark:SetText("|cffffffff+|r")
            else
                box:SetTexture(0.15, 0.15, 0.15, 1) mark:SetText("")
            end
        end
        RefreshChk()
        cdChecks[#cdChecks + 1] = RefreshChk
        btn:SetScript("OnClick", function()
            StoneGrid_Config.ShowCooldown = not StoneGrid_Config.ShowCooldown
            refresh.chkCooldown() StoneGrid:UpdateAllAuras()
        end)

        ILabel(panel, L.CooldownFont or "Cooldown font (px):", 18, y - 24)
        eb[cdKey] = SmallEB(panel, 160, y - 24, StoneGrid_Config.CooldownFontSize or 8)

        ILabel(panel, L.StackFont or "Stack font (px):", 18, y - 46)
        eb[stackKey] = SmallEB(panel, 160, y - 46, StoneGrid_Config.StackFontSize or 6)
        return y - COOLDOWN_SECTION_H
    end

    -- ============================================================
    -- PANEL BUFFS
    -- ============================================================
    local function AuraSizeButtonLabel(sz)
        return sz
    end

    local function BuildAuraSizePicker(panel, sectionY, editKey, refreshKey, saveFn, loadFn, opts)
        opts = opts or {}
        local labelOffset = opts.labelOffset or 12
        local btnOffset   = opts.btnOffset or 34
        local sizeRowOffset = opts.sizeRowOffset or 82

        Separator(panel, sectionY)
        SectionLabel(panel, L.AuraIconSizeSection or "[ Icon size ]", sectionY - labelOffset)

        local buttons = {}
        local btnGap = 6
        local n = #StoneGrid_AuraSizes
        local rowW = MENU_W - 28 * 2
        local btnW = math.floor((rowW - btnGap * (n - 1)) / n)
        local totalW = btnW * n + btnGap * (n - 1)
        local startX = math.floor((MENU_W - totalW) / 2)
        refresh[refreshKey] = function()
            local cur = StoneGrid_Config[editKey] or "25"
            for _, rb in ipairs(buttons) do
                if rb.size == cur then
                    rb.bg:SetTexture(COL_ACTIVE[1], COL_ACTIVE[2], COL_ACTIVE[3], 0.95)
                    rb.lbl:SetTextColor(1, 1, 1)
                else
                    rb.bg:SetTexture(COL_INACTIVE[1], COL_INACTIVE[2], COL_INACTIVE[3], 0.95)
                    rb.lbl:SetTextColor(0.78, 0.78, 0.78)
                end
            end
        end

        local btnY = sectionY - btnOffset
        for i, sz in ipairs(StoneGrid_AuraSizes) do
            local bx = startX + (i - 1) * (btnW + btnGap)
            local btn = CreateFrame("Button", nil, panel)
            btn:SetSize(btnW, 22)
            btn:SetPoint("TOPLEFT", bx, btnY)
            local bgTex = btn:CreateTexture(nil, "BACKGROUND")
            bgTex:SetAllPoints()
            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetAllPoints()
            lbl:SetText(AuraSizeButtonLabel(sz))
            btn:SetScript("OnClick", function()
                saveFn()
                StoneGrid_Config[editKey] = sz
                loadFn()
                StoneGrid:UpdateAllAuras()
            end)
            buttons[#buttons + 1] = { size = sz, bg = bgTex, lbl = lbl }
        end
        refresh[refreshKey]()
        return sectionY - sizeRowOffset
    end

    local function SaveBuffIconToPreset()
        local sz = StoneGrid_Config.BuffEditSize or "25"
        local p = StoneGrid_GetBuffPreset(StoneGrid_Config, sz)
        local bs = eb.BuffIconSize and eb.BuffIconSize:GetNumber()
        local bm = eb.BuffMaxIcons and eb.BuffMaxIcons:GetNumber()
        if bs and bs > 0 then p.BuffIconSize = bs end
        if bm and bm > 0 then p.BuffMaxIcons = bm end
    end

    local function LoadBuffIconFromPreset()
        local sz = StoneGrid_Config.BuffEditSize or "25"
        StoneGrid_SyncFlatBuffFromPreset(StoneGrid_Config, sz)
        if eb.BuffIconSize then eb.BuffIconSize:SetNumber(StoneGrid_Config.BuffIconSize or 12) end
        if eb.BuffMaxIcons then eb.BuffMaxIcons:SetNumber(StoneGrid_Config.BuffMaxIcons or 4) end
        if refresh.buffSizeButtons then refresh.buffSizeButtons() end
    end

    refresh.buffEditLoad = LoadBuffIconFromPreset

    SectionLabel(panelBuffs, L.Buffs or "[ Buffs ]", -8)

    refresh.chkBuffs       = Checkbox(panelBuffs, "ShowBuffs",   L.ShowBuffs    or "Show buffs",    18,  -28)
    refresh.chkBuffReverse = Checkbox(panelBuffs, "BuffReverse", L.Reverse      or "Reverse",       190, -28)
    refresh.chkMyBuffs     = Checkbox(panelBuffs, "BuffOnlyMine",L.BuffOnlyMine or "Only my buffs", 18,  -50)

    Label(panelBuffs, L.FilterLabel or "Filter (comma-separated):", -76)
    eb.BuffFilter = FilterBox(panelBuffs, -92, StoneGrid_Config.BuffFilter)

    Label(panelBuffs, L.Position or "Position:", -126)
    local buffPosY = -144
    refresh.buffPos = PosGrid(panelBuffs, buffPosY, "BuffPosition")

    local _, buffPosSepY, buffCooldownTitleY = PosGridLayout(buffPosY)
    Separator(panelBuffs, buffPosSepY)
    SectionLabel(panelBuffs, L.SectionCooldowns or "[ Cooldowns ]", buffCooldownTitleY)
    local buffCooldownBottom = CooldownSection(panelBuffs, buffCooldownTitleY - SECTION_CONTENT, "BuffCdFont", "BuffStackFont")

    local buffIconSizeSepY = SepAfter(buffCooldownBottom)
    local buffIconSizeY = BuildAuraSizePicker(panelBuffs, buffIconSizeSepY, "BuffEditSize", "buffSizeButtons", SaveBuffIconToPreset, LoadBuffIconFromPreset, ICON_SIZE_OPTS)
    ILabel(panelBuffs, L.SizePx or "Size (px):", 18, buffIconSizeY)
    eb.BuffIconSize = SmallEB(panelBuffs, 90, buffIconSizeY, StoneGrid_Config.BuffIconSize)
    ILabel(panelBuffs, L.Max or "Max:", 190, buffIconSizeY)
    eb.BuffMaxIcons = SmallEB(panelBuffs, 240, buffIconSizeY, StoneGrid_Config.BuffMaxIcons)
    LoadBuffIconFromPreset()

    Separator(panelBuffs, BOTTOM_SEP_Y)

    Btn(panelBuffs, L.Save or "Save", saveX, BOTTOM_BTN_Y, SAVE_BTN_W, function()
        local c = StoneGrid_Config
        local bs=eb.BuffIconSize:GetNumber()  local bm=eb.BuffMaxIcons:GetNumber()
        local cf=eb.BuffCdFont:GetNumber()    local sf=eb.BuffStackFont:GetNumber()
        if bs>0 then c.BuffIconSize=bs end     if bm>0 then c.BuffMaxIcons=bm end
        if cf>0 then c.CooldownFontSize=cf end if sf>0 then c.StackFontSize=sf end
        c.BuffFilter = eb.BuffFilter:GetText()
        SaveBuffIconToPreset()
        SyncCooldownEBs()
        StoneGrid:UpdateAllAuras()
        SaveActiveProfile()
        SgMsg(L.MsgBuffsSaved or "Buff settings saved.")
    end)

    Btn(panelBuffs, L.Reset or "Reset", resetX, BOTTOM_BTN_Y, SAVE_BTN_W, function()
        local c = StoneGrid_Config
        c.ShowBuffs=true c.BuffPosition="TOPRIGHT" c.BuffIconSize=12 c.BuffMaxIcons=4 c.BuffFilter=""
        c.BuffReverse=false c.BuffOnlyMine=false
        c.ShowCooldown=true c.CooldownFontSize=8 c.StackFontSize=6
        c.BuffEditSize = "25"
        if StoneGrid_AuraSizeInitDefaults then
            local seed = {}
            StoneGrid_AuraSizeInitDefaults(seed)
            c.BuffBySize = seed.BuffBySize
        end
        if refresh.chkBuffs       then refresh.chkBuffs()       end
        if refresh.chkMyBuffs     then refresh.chkMyBuffs()     end
        if refresh.chkBuffReverse then refresh.chkBuffReverse() end
        if refresh.buffPos        then refresh.buffPos()        end
        LoadBuffIconFromPreset()
        if eb.BuffFilter   then eb.BuffFilter:SetText("")     end
        refresh.chkCooldown()
        SyncCooldownEBs()
        StoneGrid:UpdateAllAuras()
        SgMsg(L.MsgBuffsReset or "Buff settings reset.")
    end)

    -- ============================================================
    -- PANEL DEBUFFS
    -- ============================================================
    local function SaveDebuffIconToPreset()
        local sz = StoneGrid_Config.DebuffEditSize or "25"
        local p = StoneGrid_GetDebuffPreset(StoneGrid_Config, sz)
        local ds = eb.DebuffIconSize and eb.DebuffIconSize:GetNumber()
        local dm = eb.DebuffMaxIcons and eb.DebuffMaxIcons:GetNumber()
        if ds and ds > 0 then p.DebuffIconSize = ds end
        if dm and dm > 0 then p.DebuffMaxIcons = dm end
    end

    local function LoadDebuffIconFromPreset()
        local sz = StoneGrid_Config.DebuffEditSize or "25"
        StoneGrid_SyncFlatDebuffFromPreset(StoneGrid_Config, sz)
        if eb.DebuffIconSize then eb.DebuffIconSize:SetNumber(StoneGrid_Config.DebuffIconSize or 12) end
        if eb.DebuffMaxIcons then eb.DebuffMaxIcons:SetNumber(StoneGrid_Config.DebuffMaxIcons or 4) end
        if refresh.debuffSizeButtons then refresh.debuffSizeButtons() end
    end

    refresh.debuffEditLoad = LoadDebuffIconFromPreset

    -- ============================================================
    -- Sub-page pager: Debuffs tab has more content than reliably fits.
    -- Page 1 = core debuff settings. Page 2 = Extra Spells (PVP/Dungeon/Raid
    -- custom IDs). Both are children of panelDebuffs so Save/Reset (parented
    -- directly to panelDebuffs) work for either page's fields regardless of
    -- which one is currently shown.
    -- ============================================================
    local debuffPage1 = CreateFrame("Frame", nil, panelDebuffs)
    debuffPage1:SetAllPoints(panelDebuffs)
    local debuffPage2 = CreateFrame("Frame", nil, panelDebuffs)
    debuffPage2:SetAllPoints(panelDebuffs)

    do
        local page = 1
        local btn1 = CreateFrame("Button", nil, panelDebuffs)
        btn1:SetSize(22, 20) btn1:SetPoint("TOP", panelDebuffs, "TOP", -13, -6)
        local brd1 = btn1:CreateTexture(nil, "BACKGROUND")
        brd1:SetPoint("TOPLEFT", -1, 1) brd1:SetPoint("BOTTOMRIGHT", 1, -1) brd1:SetTexture(0.40, 0.40, 0.40, 1)
        local bg1 = btn1:CreateTexture(nil, "BORDER") bg1:SetAllPoints()
        local txt1 = btn1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") txt1:SetAllPoints() txt1:SetText("1")
        txt1:SetTextColor(0.780, 0.780, 0.780)

        local btn2 = CreateFrame("Button", nil, panelDebuffs)
        btn2:SetSize(22, 20) btn2:SetPoint("TOP", panelDebuffs, "TOP", 13, -6)
        local brd2 = btn2:CreateTexture(nil, "BACKGROUND")
        brd2:SetPoint("TOPLEFT", -1, 1) brd2:SetPoint("BOTTOMRIGHT", 1, -1) brd2:SetTexture(0.40, 0.40, 0.40, 1)
        local bg2 = btn2:CreateTexture(nil, "BORDER") bg2:SetAllPoints()
        local txt2 = btn2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") txt2:SetAllPoints() txt2:SetText("2")
        txt2:SetTextColor(0.780, 0.780, 0.780)

        local function RefreshPager()
            local c1 = page == 1 and COL_ACTIVE or COL_INACTIVE
            local c2 = page == 2 and COL_ACTIVE or COL_INACTIVE
            bg1:SetTexture(c1[1], c1[2], c1[3], 0.95)
            bg2:SetTexture(c2[1], c2[2], c2[3], 0.95)
        end
        local function SetPage(p)
            page = p
            if p == 1 then debuffPage1:Show() debuffPage2:Hide()
            else debuffPage1:Hide() debuffPage2:Show() end
            RefreshPager()
        end
        btn1:SetScript("OnClick", function() SetPage(1) end)
        btn2:SetScript("OnClick", function() SetPage(2) end)
        SetPage(1)
    end

    SectionLabel(debuffPage1, L.Debuffs or "[ Debuffs ]", -26)

    refresh.chkDebuffs       = Checkbox(debuffPage1, "ShowDebuffs",   L.ShowDebuffs or "Show debuffs", 18,  -46)
    refresh.chkDebuffReverse = Checkbox(debuffPage1, "DebuffReverse", L.Reverse     or "Reverse",      190, -46)

    Label(debuffPage1, L.DebuffHideLabel or "Hide (comma-separated):", -72)
    eb.DebuffFilter = FilterBox(debuffPage1, -88, StoneGrid_Config.DebuffFilter)

    Label(debuffPage1, L.Position or "Position:", -122)
    local debuffPosY = -140
    refresh.debuffPos = PosGrid(debuffPage1, debuffPosY, "DebuffPosition")

    local _, debuffPosSepY, debuffCooldownTitleY = PosGridLayout(debuffPosY)
    Separator(debuffPage1, debuffPosSepY)
    SectionLabel(debuffPage1, L.SectionCooldowns or "[ Cooldowns ]", debuffCooldownTitleY)
    local debuffCooldownBottom = CooldownSection(debuffPage1, debuffCooldownTitleY - SECTION_CONTENT, "DebuffCdFont", "DebuffStackFont")

    local debuffIconSizeSepY = SepAfter(debuffCooldownBottom)
    local debuffIconSizeY = BuildAuraSizePicker(debuffPage1, debuffIconSizeSepY, "DebuffEditSize", "debuffSizeButtons", SaveDebuffIconToPreset, LoadDebuffIconFromPreset, ICON_SIZE_OPTS)
    ILabel(debuffPage1, L.SizePx or "Size (px):", 18, debuffIconSizeY)
    eb.DebuffIconSize = SmallEB(debuffPage1, 90, debuffIconSizeY, StoneGrid_Config.DebuffIconSize)
    ILabel(debuffPage1, L.Max or "Max:", 190, debuffIconSizeY)
    eb.DebuffMaxIcons = SmallEB(debuffPage1, 240, debuffIconSizeY, StoneGrid_Config.DebuffMaxIcons)
    LoadDebuffIconFromPreset()

    -- Page 2: Extra Spells, laid out fresh from the top instead of chained
    -- below page 1 -- this is the block that used to overflow the panel.
    local debuffExtraTitleY = -26
    SectionLabel(debuffPage2, L.SectionExtraSpells or "[ Extra spells ]", debuffExtraTitleY)

    local pvpExtraTitleY = debuffExtraTitleY - SECTION_CONTENT
    SectionLabel(debuffPage2, L.SectionExtraPvp or "[ PVP ]", pvpExtraTitleY)
    local pvpCustomLabelY = pvpExtraTitleY - SECTION_CONTENT
    Label(debuffPage2, L.PvpDebuffCustomLabel or "Extra PVP spell IDs (comma-separated):", pvpCustomLabelY)
    eb.PvpDebuffCustom = FilterBox(debuffPage2, pvpCustomLabelY - 16, StoneGrid_Config.PvpDebuffCustom or "")

    local dungeonExtraSepY = SepAfter(pvpCustomLabelY - 16 - 28)
    Separator(debuffPage2, dungeonExtraSepY)
    local dungeonExtraTitleY = SectionAfterSep(dungeonExtraSepY)
    SectionLabel(debuffPage2, L.SectionExtraDungeon or "[ Dungeon ]", dungeonExtraTitleY)
    local dungeonCustomLabelY = dungeonExtraTitleY - SECTION_CONTENT
    Label(debuffPage2, L.DungeonDebuffCustomLabel or "Extra dungeon spell IDs (comma-separated):", dungeonCustomLabelY)
    eb.DungeonDebuffCustom = FilterBox(debuffPage2, dungeonCustomLabelY - 16, StoneGrid_Config.DungeonDebuffCustom or "")

    local raidExtraSepY = SepAfter(dungeonCustomLabelY - 16 - 28)
    Separator(debuffPage2, raidExtraSepY)
    local raidExtraTitleY = SectionAfterSep(raidExtraSepY)
    SectionLabel(debuffPage2, L.SectionExtraRaid or "[ Raid ]", raidExtraTitleY)
    local raidCustomLabelY = raidExtraTitleY - SECTION_CONTENT
    Label(debuffPage2, L.RaidDebuffCustomLabel or "Extra raid spell IDs (comma-separated):", raidCustomLabelY)
    eb.RaidDebuffCustom = FilterBox(debuffPage2, raidCustomLabelY - 16, StoneGrid_Config.RaidDebuffCustom or "")

    -- Save/Reset stay fixed to panelDebuffs itself (not either page), pinned
    -- to the shared bottom position (BOTTOM_SEP_Y/BOTTOM_BTN_Y) used by
    -- every panel now.
    Separator(panelDebuffs, BOTTOM_SEP_Y)

    Btn(panelDebuffs, L.Save or "Save", saveX, BOTTOM_BTN_Y, SAVE_BTN_W, function()
        local c = StoneGrid_Config
        local ds=eb.DebuffIconSize:GetNumber()  local dm=eb.DebuffMaxIcons:GetNumber()
        local cf=eb.DebuffCdFont:GetNumber()    local sf=eb.DebuffStackFont:GetNumber()
        if ds>0 then c.DebuffIconSize=ds end   if dm>0 then c.DebuffMaxIcons=dm end
        if cf>0 then c.CooldownFontSize=cf end if sf>0 then c.StackFontSize=sf end
        c.DebuffFilter = eb.DebuffFilter:GetText()
        if eb.PvpDebuffCustom then c.PvpDebuffCustom = eb.PvpDebuffCustom:GetText() end
        if eb.RaidDebuffCustom then c.RaidDebuffCustom = eb.RaidDebuffCustom:GetText() end
        if eb.DungeonDebuffCustom then c.DungeonDebuffCustom = eb.DungeonDebuffCustom:GetText() end
        SaveDebuffIconToPreset()
        if StoneGrid_PvpDebuffs then StoneGrid_PvpDebuffs:ReloadLookup() end
        if StoneGrid_RaidDebuffs then StoneGrid_RaidDebuffs:UpdateZoneSpells() end
        if StoneGrid_DungeonDebuffs then StoneGrid_DungeonDebuffs:UpdateZoneSpells() end
        SyncCooldownEBs()
        StoneGrid:UpdateAllAuras()
        SaveActiveProfile()
        SgMsg(L.MsgDebuffsSaved or "Debuff settings saved.")
    end)

    Btn(panelDebuffs, L.Reset or "Reset", resetX, BOTTOM_BTN_Y, SAVE_BTN_W, function()
        local c = StoneGrid_Config
        c.ShowDebuffs=true c.DebuffPosition="BOTTOMRIGHT" c.DebuffIconSize=12 c.DebuffMaxIcons=4 c.DebuffFilter=""
        c.DebuffReverse=false
        c.ShowCooldown=true c.CooldownFontSize=8 c.StackFontSize=6
        c.DebuffEditSize = "25"
        if StoneGrid_AuraSizeInitDefaults then
            local seed = {}
            StoneGrid_AuraSizeInitDefaults(seed)
            c.DebuffBySize = seed.DebuffBySize
        end
        if refresh.chkDebuffs       then refresh.chkDebuffs()       end
        if refresh.chkDebuffReverse then refresh.chkDebuffReverse() end
        if refresh.debuffPos        then refresh.debuffPos()        end
        LoadDebuffIconFromPreset()
        if eb.DebuffFilter   then eb.DebuffFilter:SetText("")     end
        if eb.PvpDebuffCustom then eb.PvpDebuffCustom:SetText("") end
        if eb.RaidDebuffCustom then eb.RaidDebuffCustom:SetText("") end
        if eb.DungeonDebuffCustom then eb.DungeonDebuffCustom:SetText("") end
        if StoneGrid_PvpDebuffs then
            StoneGrid_PvpDebuffs:InitDefaults(c)
            StoneGrid_PvpDebuffs:ReloadLookup()
        end
        if StoneGrid_RaidDebuffs then
            StoneGrid_RaidDebuffs:InitDefaults(c)
            StoneGrid_RaidDebuffs:UpdateZoneSpells()
        end
        if StoneGrid_DungeonDebuffs then
            StoneGrid_DungeonDebuffs:InitDefaults(c)
            StoneGrid_DungeonDebuffs:UpdateZoneSpells()
        end
        refresh.chkCooldown()
        SyncCooldownEBs()
        StoneGrid:UpdateAllAuras()
        SgMsg(L.MsgBuffsReset or "Buff settings reset.")
    end)

    -- ============================================================
    -- PANEL PROFILE
    -- ============================================================
    SectionLabel(panelProfile, L.SectionProfile or "[ Profile ]", -10)
    Label(panelProfile, L.ProfileActive or "Active profile:", -34)

    local profilePicker = ProfileDropdown(panelProfile, 18, -48, MENU_W - 36)
    refresh.profileDrop = function()
        profilePicker:Refresh()
    end
    refresh.profileDrop()

    Label(panelProfile, L.ProfileHint or "Profiles are shared account-wide.", -88)
    do
        local hint = panelProfile:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOPLEFT", 18, -102)
        hint:SetWidth(MENU_W - 36)
        hint:SetJustifyH("LEFT")
        hint:SetText(L.ProfileHintLong or "Use Save on other tabs to store settings in the active profile. Pick the same profile on another character to load it.")
        hint:SetTextColor(0.65, 0.65, 0.65)
    end

    Btn(panelProfile, L.ProfileNew or "New", 18, -140, 185, function()
        StaticPopup_Show("STONEGRID_NEW_PROFILE")
    end)

    Btn(panelProfile, L.ProfileDelete or "Delete", 213, -140, 185, function()
        local name = StoneGrid_Profiles_GetActive()
        if name == "Default" then
            SgMsg(L.MsgProfileProtected or "Cannot delete Default profile.")
            return
        end
        StaticPopup_Show("STONEGRID_DELETE_PROFILE", name, nil, name)
    end)

    Separator(panelProfile, -168)
    SectionLabel(panelProfile, L.SectionProfileShare or "[ Share ]", -180)

    do
        local hint = panelProfile:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOPLEFT", 18, -202)
        hint:SetWidth(MENU_W - 36)
        hint:SetJustifyH("LEFT")
        hint:SetText(L.ProfileShareHint or "Export: send your settings to someone (Ctrl+C). Import: paste a profile string you received.")
        hint:SetTextColor(0.65, 0.65, 0.65)
    end

    Btn(panelProfile, L.ProfileExport or "Export", 18, -248, 185, function()
        SaveActiveProfile()
        local name = StoneGrid_Profiles_GetActive()
        local exported = StoneGrid_Profiles_Export and StoneGrid_Profiles_Export(name)
        if not exported then
            SgMsg(L.MsgProfileExportFailed or "Export failed.")
            return
        end
        ShowProfileExportPaste(exported)
    end)

    Btn(panelProfile, L.ProfileImport or "Import", 213, -248, 185, function()
        ShowProfileImportPaste()
    end)

    Separator(panelProfile, -278)
    SectionLabel(panelProfile, L.SectionInfo or "[ Info ]", -290)
    local ver = panelProfile:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ver:SetPoint("TOPLEFT", 18, -306)
    ver:SetText((L.VersionLabel or "Version:") .. " 0.0.1a     " .. (L.AuthorLabel or "Author:") .. " platefobrain")
    ver:SetTextColor(0.65, 0.65, 0.65)
end  -- BuildMenu

-- ============================================================
-- SHOW MENU
-- ============================================================
local function ShowMenu()
    if eb.PW  then eb.PW:SetNumber(StoneGrid_Config.PartyWidth)   end
    if eb.PH  then eb.PH:SetNumber(StoneGrid_Config.PartyHeight)  end
    if eb.PC  then eb.PC:SetNumber(StoneGrid_Config.PartyColumns or 1) end
    if eb.PS  then eb.PS:SetNumber(StoneGrid_Config.PartySpacing)  end
    if refresh.raidEditLoad then refresh.raidEditLoad() end
    if eb.PPW    then eb.PPW:SetNumber(StoneGrid_Config.PartyPetWidth)      end
    if eb.PPH    then eb.PPH:SetNumber(StoneGrid_Config.PartyPetHeight)     end
    if eb.PPSp   then eb.PPSp:SetNumber(StoneGrid_Config.PartyPetSpacing)   end
    if eb.PPCols then eb.PPCols:SetNumber(StoneGrid_Config.PartyPetColumns or 1) end
    if refresh.chkPartyPets  then refresh.chkPartyPets()  end
    if refresh.partyPetPos   then refresh.partyPetPos()   end
    if refresh.chkHpClass    then refresh.chkHpClass()    end
    if refresh.chkNameClass  then refresh.chkNameClass()  end
    if refresh.swatchHp      then refresh.swatchHp()      end
    if refresh.swatchHeal    then refresh.swatchHeal()    end
    if refresh.swatchBg      then refresh.swatchBg()      end
    if refresh.swatchBorder  then refresh.swatchBorder()  end
    if eb.BorderSize         then eb.BorderSize:SetNumber(StoneGrid_Config.BorderSize) end
    if refresh.chkTargetHL   then refresh.chkTargetHL()   end
    if refresh.swatchTarget  then refresh.swatchTarget()  end
    if refresh.chkBuffs      then refresh.chkBuffs()      end
    if refresh.chkMyBuffs    then refresh.chkMyBuffs()    end
    if refresh.chkDebuffs    then refresh.chkDebuffs()    end
    if refresh.chkBuffReverse   then refresh.chkBuffReverse()   end
    if refresh.chkDebuffReverse then refresh.chkDebuffReverse() end
    if refresh.buffPos       then refresh.buffPos()       end
    if refresh.debuffPos     then refresh.debuffPos()     end
    if refresh.buffEditLoad  then refresh.buffEditLoad()  end
    if refresh.debuffEditLoad then refresh.debuffEditLoad() end
    if eb.BuffFilter      then eb.BuffFilter:SetText(StoneGrid_Config.BuffFilter   or "")  end
    if eb.DebuffFilter    then eb.DebuffFilter:SetText(StoneGrid_Config.DebuffFilter or "") end
    if eb.PvpDebuffCustom then eb.PvpDebuffCustom:SetText(StoneGrid_Config.PvpDebuffCustom or "") end
    if eb.RaidDebuffCustom then eb.RaidDebuffCustom:SetText(StoneGrid_Config.RaidDebuffCustom or "") end
    if eb.DungeonDebuffCustom then eb.DungeonDebuffCustom:SetText(StoneGrid_Config.DungeonDebuffCustom or "") end
    if refresh.chkCooldown then refresh.chkCooldown()      end
    if eb.BuffCdFont      then eb.BuffCdFont:SetNumber(StoneGrid_Config.CooldownFontSize or 8)      end
    if eb.DebuffCdFont    then eb.DebuffCdFont:SetNumber(StoneGrid_Config.CooldownFontSize or 8)    end
    if eb.BuffStackFont   then eb.BuffStackFont:SetNumber(StoneGrid_Config.StackFontSize or 6)      end
    if eb.DebuffStackFont then eb.DebuffStackFont:SetNumber(StoneGrid_Config.StackFontSize or 6)    end
    if refresh.chkPartyStuns then refresh.chkPartyStuns() end
    if refresh.chkDungeonDebuffs then refresh.chkDungeonDebuffs() end
    if eb.PartyCcSize then eb.PartyCcSize:SetNumber(StoneGrid_Config.PartyCcIconSize or 20) end
    if eb.DungeonDebuffSize then eb.DungeonDebuffSize:SetNumber(StoneGrid_Config.DungeonDebuffIconSize or 20) end
    if refresh.oorCheck   then refresh.oorCheck()   end
    if refresh.chkHideParty then refresh.chkHideParty() end
    if refresh.chkRaidIcon then refresh.chkRaidIcon() end
    if refresh.raidIconPos then refresh.raidIconPos() end
    if refresh.chkMinimap then refresh.chkMinimap() end
    if eb.OORAlpha then
        eb.OORAlpha:SetNumber(math.floor((StoneGrid_Config.OutOfRangeAlpha or 0.3) * 100))
    end
    if refresh.langButton then refresh.langButton() end
    if refresh.profileDrop then refresh.profileDrop() end
    menuFrame:Show()
end

function StoneGrid_MenuRefresh()
    if refresh.profileDrop then refresh.profileDrop() end
    if not menuFrame or not menuFrame:IsShown() then return end
    ShowMenu()
end

-- ============================================================
-- TOGGLE MENU
-- ============================================================
local function ToggleMenu()
    BuildMenu()
    RefreshLockLabel()
    if menuFrame:IsShown() then
        if profileImportPasteFrame then profileImportPasteFrame:Hide() end
        menuFrame:Hide()
    else
        ShowMenu()
    end
end

function StoneGrid_ToggleMenu()
    ToggleMenu()
end

-- ============================================================
-- SLASH COMMANDS
-- ============================================================
SLASH_STONEGRID1 = "/stonegrid"
SLASH_STONEGRID2 = "/sg"
SlashCmdList["STONEGRID"] = function(msg)
    msg = msg and msg:lower():match("^%s*(.-)%s*$") or ""
    local LL = GetL()
    if msg == "lock" then
        StoneGrid_Config.Locked = true
        StoneGrid_Party:SetLocked(true) StoneGrid_Raid:SetLocked(true)
        StoneGrid_Test:RefreshLock()
        if menuFrame then RefreshLockLabel() end
        SgMsg(LL.MsgLocked or "Frames locked.")
    elseif msg == "unlock" then
        StoneGrid_Config.Locked = false
        StoneGrid_Party:SetLocked(false) StoneGrid_Raid:SetLocked(false)
        StoneGrid_Test:RefreshLock()
        if menuFrame then RefreshLockLabel() end
        SgMsg(LL.MsgUnlocked or "Frames unlocked.")
    elseif msg == "test party" then
        StoneGrid_Test:ShowParty()
    elseif msg == "test raid" then
        StoneGrid_Test:ShowRaid()
    elseif msg == "test" then
        if StoneGrid_Test:IsActive() then
            StoneGrid_Test:Stop()
        else
            SgMsg("/sg test party  |  /sg test raid")
        end
    else
        ToggleMenu()
    end
end
