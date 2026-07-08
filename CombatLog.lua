-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

StoneGrid_CombatLog = {}

local lastEventTime = 0
local lastPlayerHealth
local lastResetTime = 0
local RESET_COOLDOWN = 5
local STUCK_THRESHOLD = 2.5

local function GetL()
    local lang = (StoneGrid_Config and StoneGrid_Config.Language) or GetLocale()
    if lang == "enGB" then lang = "enUS" end
    local locs = StoneGrid_Locales or {}
    return locs[lang] or locs["enUS"] or {}
end

local function Announce(msg)
    local text = "|cff00ff00StoneGrid:|r " .. msg
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    end
end

function StoneGrid_CombatLog:RecordEvent()
    lastEventTime = GetTime()
end

function StoneGrid_CombatLog:DoClear()
    if CombatLogClearEntries then
        CombatLogClearEntries()
    end

    if not self._resetFrame then
        self._resetFrame = CreateFrame("Frame")
    end
    local count = 0
    self._resetFrame:SetScript("OnUpdate", function(frame)
        if CombatLogClearEntries then
            CombatLogClearEntries()
        end
        count = count + 1
        if count >= 5 then
            frame:SetScript("OnUpdate", nil)
        end
    end)
end

function StoneGrid_CombatLog:ResetCombatLog()
    local now = GetTime()
    if now - lastResetTime < RESET_COOLDOWN then
        return
    end
    lastResetTime = now

    local L = GetL()
    Announce(L.MsgCombatLogAuto or "Combat log: auto-fix")

    self:DoClear()

    lastEventTime = now
    lastPlayerHealth = UnitHealth("player")
end

function StoneGrid_CombatLog:OnPlayerHealth()
    if not StoneGrid_Config or not StoneGrid_Config.CombatLogAutoDetect then
        return
    end
    if not UnitAffectingCombat("player") then
        lastPlayerHealth = UnitHealth("player")
        return
    end

    local hp = UnitHealth("player")
    if lastPlayerHealth and hp < lastPlayerHealth then
        if GetTime() - lastEventTime > STUCK_THRESHOLD then
            self:ResetCombatLog()
        end
    end
    lastPlayerHealth = hp
end
