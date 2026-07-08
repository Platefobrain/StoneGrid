local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("StoneGrid", "deDE")
if L then
    L["General"]  = "Allgemein" ; L["Sizes"] = "Größen" ; L["Colors"] = "Farben" ; L["Auras"] = "Auren"
    L["Language"] = "Sprache"
    L["Width:"] = "Breite:" ; L["Height:"] = "Höhe:" ; L["Spacing:"] = "Abstand:" ; L["Columns:"] = "Spalten:"
    L["Save Party"] = "Party speichern" ; L["Reset Party"] = "Party zurücksetzen"
    L["Save Raid"]  = "Raid speichern"  ; L["Reset Raid"]  = "Raid zurücksetzen"
    L["Unlock"] = "Entsperren" ; L["Lock"] = "Sperren"
    L["Detect Range"] = "Reichweite erkennen" ; L["Out of range opacity (%):"] = "Außer-Reichweite-Deckkraft (%):"
    L["Test Party"] = "Test Party" ; L["Test Raid"] = "Test Raid" ; L["Disable Test"] = "Test deaktivieren"
    L["HP Bar:"] = "HP-Leiste:" ; L["Class color"] = "Klassenfarbe"
    L["Incoming Heal:"] = "Eingehende Heilung:" ; L["Direct Heals only (no HoTs)"] = "Nur direkte Heilungen (keine HoTs)"
    L["Include other players' heals"] = "Heilung anderer Spieler einbeziehen"
    L["Missing HP Background:"] = "Fehl. HP Hintergrund:" ; L["Border color:"] = "Randfarbe:" ; L["Thickness (px):"] = "Stärke (px):"
    L["Save"] = "Speichern" ; L["Reset Colors"] = "Farben zurücksetzen" ; L["Reset"] = "Zurücksetzen"
    L["Show buffs"] = "Buffs anzeigen" ; L["Reverse"] = "Umkehren" ; L["Filter (comma-separated):"] = "Filter (kommagetrennt):"
    L["Show debuffs"] = "Debuffs anzeigen" ; L["Show cooldown icon"] = "Abklingzeit-Symbol anzeigen"
    L["Cooldown font (px):"] = "Abklingzeit-Schrift (px):" ; L["Stack font (px):"] = "Stapel-Schrift (px):"
    L["Top Left"] = "Oben Links" ; L["Top Center"] = "Oben Mitte" ; L["Top Right"] = "Oben Rechts"
    L["Mid Left"] = "Mitte Links" ; L["Mid Right"] = "Mitte Rechts"
    L["Bot Left"] = "Unten Links" ; L["Bot Center"] = "Unten Mitte" ; L["Bot Right"] = "Unten Rechts"
    L["Size (px):"] = "Größe (px):" ; L["Max:"] = "Max:"
end

StoneGrid_Locales = StoneGrid_Locales or {}
StoneGrid_Locales["deDE"] = {
    NativeName   = "Deutsch",
    Title        = "StoneGrid - Einstellungen",
    General      = "Allgemein",
    Sizes        = "Größen",
    Colors       = "Farben",
    Auras        = "Auren",
    TabBuffs     = "Buffs",
    TabDebuffs   = "Debuffs",
    TabProfile   = "Profile",
    BorderSize   = "Border:",
    Language     = "Sprache",
    Width        = "Breite:",
    Height       = "Höhe:",
    Spacing      = "Abstand:",
    Columns      = "Spalten:",
    SaveParty    = "Party speichern",
    ResetParty   = "Party zurücksetzen",
    SaveRaid     = "Raid speichern",
    ResetRaid    = "Raid zurücksetzen",
    Unlock       = "Entsperren",
    Lock         = "Sperren",
    DetectRange  = "Reichweite erkennen",
    OOROpacity   = "Außer-Reichweite-Deckkraft (%):",
    ShowRaidIcon = "Raid-Icon anzeigen",
    Position     = "Position:",
    SectionStuns = "[ Stuns ]",
    ShowStuns    = "CC-Icons anzeigen",
    TestParty    = "Test Party",
    TestRaid     = "Test Raid",
    RaidPetMax   = "Max. Begleiter:",
    DisableTest  = "Test deaktivieren",
    StatusLocked   = "|cff44ff44Status: GESPERRT|r",
    StatusUnlocked = "|cffffff00Status: ENTSPERRT – Rahmen ziehen|r",
    SectionParty   = "[ Party ]",
    SectionRaid    = "[ Schlachtzug ]",
    SectionRange   = "[ Reichweite ]",
    SectionBlizzard = "[ Blizzard ]",
    HideBlizzardParty = "Blizzard-Partyframes ausblenden",
    ShowMinimapButton = "Minimap-Button anzeigen",
    MinimapTooltipTitle = "StoneGrid",
    MinimapTooltipClick = "Linksklick: Einstellungen",
    MinimapTooltipDrag  = "Ziehen: Icon verschieben",
    SectionRaidIcon = "[ Raid icon ]",
    SectionTest    = "[ Test ]",
    SectionLang    = "[ Sprache ]",
    SectionInfo    = "[ Info ]",
    SectionSettings = "[ Einstellungen ]",
    BarColors    = "[ Balkenfarben ]",
    HpBar        = "HP-Leiste:",
    ClassColor   = "Klassenfarbe (Balken)",
    NameClassColor = "Klassenfarbe (Name)",
    IncomingHeal = "Eingehende Heilung:",
    DirectOnly   = "Nur direkte Heilungen (keine HoTs)",
    SectionIncomingHeal = "[ Incoming Heal ]",
    IncludeOthers = "Heilung anderer Spieler einbeziehen",
    MissingHpBg  = "Fehl. HP Hintergrund:",
    BorderColor  = "Randfarbe:",
    BorderThick  = "Stärke (px):",
    Save         = "Speichern",
    ResetColors  = "Farben zurücksetzen",
    Buffs        = "[ Buffs ]",
    ShowBuffs    = "Buffs anzeigen",
    BuffOnlyMine = "Nur meine Buffs",
    Reverse      = "Umkehren",
    FilterLabel  = "Filter (kommagetrennt):",
    Debuffs      = "[ Debuffs ]",
    ShowDebuffs  = "Debuffs anzeigen",
    ShowCooldown = "Abklingzeit-Symbol anzeigen",
    CooldownFont = "Abklingzeit-Schrift (px):",
    StackFont    = "Stapel-Schrift (px):",
    Reset        = "Zurücksetzen",
    TopLeft      = "Oben Links",    TopCenter = "Oben Mitte",    TopRight  = "Oben Rechts",
    MidLeft      = "Mitte Links",   MidRight  = "Mitte Rechts",
    BotLeft      = "Unten Links",   BotCenter = "Unten Mitte",   BotRight  = "Unten Rechts",
    SizePx       = "Größe (px):",
    Max          = "Max:",
    MsgPartySaved  = "Party gespeichert.",
    MsgPartyReset  = "Party zurückgesetzt.",
    MsgRaidSaved   = "Raid gespeichert.",
    MsgRaidReset   = "Raid zurückgesetzt.",
    MsgLocked      = "Rahmen gesperrt.",
    MsgUnlocked    = "Rahmen entsperrt.",
    MsgHidePartyOn = "Blizzard-Partyframes ausgeblendet.",
    MsgHidePartyOff = "UI neu laden, um Blizzard-Partyframes wiederherzustellen.",
    MsgTestOff     = "Testmodus deaktiviert.",
    MsgColorsReset = "Farben zurückgesetzt.",
    MsgBuffsReset  = "Buff-Einstellungen zurückgesetzt.",
    MsgLangChanged = "Sprache geändert. Menü neu aufgebaut.",
    VersionLabel   = "Version:",
    AuthorLabel    = "Autor:",
}
