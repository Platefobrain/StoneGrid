-- StoneGrid
-- Copyright (c) 2026 Platefobrain
-- Licensed under the MIT License

-- Wartości domyślne aplikowane tylko jeśli brak zapisanych danych.
-- MUSI być wywołane po załadowaniu SavedVariables (czyli w ADDON_LOADED).
function StoneGrid_Config_Init()
    StoneGrid_Config = StoneGrid_Config or {}
    local c = StoneGrid_Config
    if c.PartyWidth   == nil then c.PartyWidth   = 150 end
    if c.PartyHeight  == nil then c.PartyHeight  = 30  end
    if c.PartySpacing == nil then c.PartySpacing = 3   end
    if c.PartyColumns == nil then c.PartyColumns = 1   end
    if c.PartyX       == nil then c.PartyX       = 0   end
    if c.PartyY       == nil then c.PartyY       = 0   end
    if c.RaidWidth    == nil then c.RaidWidth    = 80  end
    if c.RaidHeight   == nil then c.RaidHeight   = 20  end
    if c.RaidSpacing  == nil then c.RaidSpacing  = 3   end
    if c.RaidColumns  == nil then c.RaidColumns  = 5   end
    if c.RaidX        == nil then c.RaidX        = 0   end
    if c.RaidY        == nil then c.RaidY        = 0   end
    if c.Locked       == nil then c.Locked       = true end
    if c.BorderR      == nil then c.BorderR      = 0.3 end
    if c.BorderG      == nil then c.BorderG      = 0.3 end
    if c.BorderB      == nil then c.BorderB      = 0.3 end
    if c.BorderA      == nil then c.BorderA      = 1.0 end
    if c.BorderSize   == nil then c.BorderSize   = 1   end
    if c.HpBarR       == nil then c.HpBarR       = 0   end
    if c.HpBarG       == nil then c.HpBarG       = 0.8 end
    if c.HpBarB       == nil then c.HpBarB       = 0   end
    if c.HpBarA       == nil then c.HpBarA       = 1.0 end
    if c.HpBarClass   == nil then c.HpBarClass   = true end
    if c.NameClassColor == nil then c.NameClassColor = false end
    if c.HealBarR     == nil then c.HealBarR     = 0   end
    if c.HealBarG     == nil then c.HealBarG     = 0.8 end
    if c.HealBarB     == nil then c.HealBarB     = 0   end
    if c.HealBarA     == nil then c.HealBarA     = 0.5 end
    if c.HealBarDirectOnly == nil then c.HealBarDirectOnly = false end
    if c.HealBarIncludeOthers == nil then c.HealBarIncludeOthers = false end
    if c.BgDarkR      == nil then c.BgDarkR      = 0.1 end
    if c.BgDarkG      == nil then c.BgDarkG      = 0.1 end
    if c.BgDarkB      == nil then c.BgDarkB      = 0.1 end
    if c.BgDarkA      == nil then c.BgDarkA      = 1.0 end
    if c.ShowCooldown   == nil then c.ShowCooldown   = true         end
    if c.ShowBuffs      == nil then c.ShowBuffs      = true         end
    if c.BuffPosition   == nil then c.BuffPosition   = "TOPRIGHT"  end
    if c.BuffIconSize   == nil then c.BuffIconSize   = 12          end
    if c.BuffMaxIcons   == nil then c.BuffMaxIcons   = 4           end
    if c.BuffFilter     == nil then c.BuffFilter     = ""          end
    if c.BuffReverse    == nil then c.BuffReverse    = false       end
    if c.BuffOnlyMine   == nil then c.BuffOnlyMine   = false       end
    if c.ShowDebuffs    == nil then c.ShowDebuffs    = true        end
    if c.DebuffPosition == nil then c.DebuffPosition = "BOTTOMRIGHT" end
    if c.DebuffIconSize == nil then c.DebuffIconSize = 12          end
    if c.DebuffMaxIcons == nil then c.DebuffMaxIcons = 4           end
    if c.DebuffFilter   == nil then c.DebuffFilter   = ""          end
    if c.DebuffReverse      == nil then c.DebuffReverse      = false end
    if c.CooldownFontSize   == nil then c.CooldownFontSize   = 8    end
    if c.StackFontSize      == nil then c.StackFontSize      = 6    end
    if c.OutOfRangeCheck    == nil then c.OutOfRangeCheck    = true end
    if c.OutOfRangeAlpha    == nil then c.OutOfRangeAlpha    = 0.3  end
    if c.ShowRaidIcon       == nil then c.ShowRaidIcon       = true end
    if c.RaidIconPosition   == nil then c.RaidIconPosition   = "TOP" end
    if c.RaidIconSize       == nil then c.RaidIconSize       = 16   end
    if c.TargetHighlight    == nil then c.TargetHighlight    = true    end
    if c.TargetHighlightR   == nil then c.TargetHighlightR   = 1.0     end
    if c.TargetHighlightG   == nil then c.TargetHighlightG   = 0.8     end
    if c.TargetHighlightB   == nil then c.TargetHighlightB   = 0.0     end
    if c.TargetHighlightA   == nil then c.TargetHighlightA   = 1.0     end
    if c.ShowPartyPets      == nil then c.ShowPartyPets      = false   end
    if c.PartyPetWidth      == nil then c.PartyPetWidth      = 80      end
    if c.PartyPetHeight     == nil then c.PartyPetHeight     = 16      end
    if c.PartyPetSpacing    == nil then c.PartyPetSpacing    = 2       end
    if c.PartyPetPosition   == nil then c.PartyPetPosition   = "BOTTOM" end
    if c.PartyPetColumns    == nil then c.PartyPetColumns    = 1       end
    if c.ShowRaidPets       == nil then c.ShowRaidPets       = false   end
    if c.RaidPetWidth       == nil then c.RaidPetWidth       = 80      end
    if c.RaidPetHeight      == nil then c.RaidPetHeight      = 14      end
    if c.RaidPetSpacing     == nil then c.RaidPetSpacing     = 2       end
    if c.RaidPetPosition    == nil then c.RaidPetPosition    = "BOTTOM" end
    if c.RaidPetColumns     == nil then c.RaidPetColumns     = 5       end
    if c.RaidPetMax         == nil then c.RaidPetMax         = 0       end
    if c.ShowPartyPowerBar  == nil then c.ShowPartyPowerBar  = false   end
    if c.PartyPowerBarH     == nil then c.PartyPowerBarH     = 4       end
    if c.ShowRaidPowerBar   == nil then c.ShowRaidPowerBar   = false   end
    if c.RaidPowerBarH      == nil then c.RaidPowerBarH      = 3       end
    if c.ShowPartyStuns     == nil then c.ShowPartyStuns     = true    end
    if c.PartyCcIconSize    == nil then c.PartyCcIconSize    = 20      end
    if c.ShowRaidStuns      == nil then c.ShowRaidStuns      = true    end
    if c.RaidCcIconSize     == nil then c.RaidCcIconSize     = 16      end
    if c.HideBlizzardPartyFrames == nil then c.HideBlizzardPartyFrames = false end
    if c.CombatLogAutoDetect == nil then c.CombatLogAutoDetect = true  end
    if c.ShowMinimapButton  == nil then c.ShowMinimapButton  = true  end
    if c.MinimapAngle       == nil then c.MinimapAngle       = 220  end
    StoneGrid_RaidSizeInitDefaults(c)
    if StoneGrid_AuraSizeInitDefaults then StoneGrid_AuraSizeInitDefaults(c) end
end
