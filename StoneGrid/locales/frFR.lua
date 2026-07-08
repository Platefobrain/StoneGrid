local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("StoneGrid", "frFR")
if L then
    L["General"]  = "Général" ; L["Sizes"] = "Tailles" ; L["Colors"] = "Couleurs" ; L["Auras"] = "Auras"
    L["Language"] = "Langue"
    L["Width:"] = "Largeur:" ; L["Height:"] = "Hauteur:" ; L["Spacing:"] = "Espacement:" ; L["Columns:"] = "Colonnes:"
    L["Save Party"] = "Sauver groupe" ; L["Reset Party"] = "Réinit. groupe"
    L["Save Raid"]  = "Sauver raid"   ; L["Reset Raid"]  = "Réinit. raid"
    L["Unlock"] = "Déverrouiller" ; L["Lock"] = "Verrouiller"
    L["Detect Range"] = "Détecter la portée" ; L["Out of range opacity (%):"] = "Opacité hors portée (%):"
    L["Test Party"] = "Test groupe" ; L["Test Raid"] = "Test raid" ; L["Disable Test"] = "Désactiver test"
    L["HP Bar:"] = "Barre HP:" ; L["Class color"] = "Couleur de classe"
    L["Incoming Heal:"] = "Soins entrants:" ; L["Direct Heals only (no HoTs)"] = "Soins directs uniquement (sans HoTs)"
    L["Include other players' heals"] = "Inclure les soins des autres joueurs"
    L["Missing HP Background:"] = "Fond HP manquant:" ; L["Border color:"] = "Couleur bordure:" ; L["Thickness (px):"] = "Épaisseur (px):"
    L["Save"] = "Sauvegarder" ; L["Reset Colors"] = "Réinit. couleurs" ; L["Reset"] = "Réinitialiser"
    L["Show buffs"] = "Afficher les buffs" ; L["Reverse"] = "Inverser" ; L["Filter (comma-separated):"] = "Filtre (noms séparés par virgule):"
    L["Show debuffs"] = "Afficher les debuffs" ; L["Show cooldown icon"] = "Afficher icône de recharge"
    L["Cooldown font (px):"] = "Police recharge (px):" ; L["Stack font (px):"] = "Police pile (px):"
    L["Top Left"] = "Haut Gauche" ; L["Top Center"] = "Haut Centre" ; L["Top Right"] = "Haut Droite"
    L["Mid Left"] = "Mil. Gauche" ; L["Mid Right"] = "Mil. Droite"
    L["Bot Left"] = "Bas Gauche" ; L["Bot Center"] = "Bas Centre" ; L["Bot Right"] = "Bas Droite"
    L["Size (px):"] = "Taille (px):" ; L["Max:"] = "Max:"
end

StoneGrid_Locales = StoneGrid_Locales or {}
StoneGrid_Locales["frFR"] = {
    NativeName   = "Français",
    Title        = "StoneGrid - Paramètres",
    General      = "Général",
    Sizes        = "Tailles",
    Colors       = "Couleurs",
    Auras        = "Auras",
    TabBuffs     = "Buffs",
    TabDebuffs   = "Debuffs",
    TabProfile   = "Profil",
    BorderSize   = "Border:",
    Language     = "Langue",
    Width        = "Largeur:",
    Height       = "Hauteur:",
    Spacing      = "Espacement:",
    Columns      = "Colonnes:",
    SaveParty    = "Sauver groupe",
    ResetParty   = "Réinit. groupe",
    SaveRaid     = "Sauver raid",
    ResetRaid    = "Réinit. raid",
    Unlock       = "Déverrouiller",
    Lock         = "Verrouiller",
    DetectRange  = "Détecter la portée",
    OOROpacity   = "Opacité hors portée (%):",
    ShowRaidIcon = "Afficher icône raid",
    Position     = "Position:",
    SectionStuns = "[ Stuns ]",
    ShowStuns    = "Afficher icônes CC",
    TestParty    = "Test groupe",
    TestRaid     = "Test raid",
    RaidPetMax   = "Max familiers:",
    DisableTest  = "Désactiver test",
    StatusLocked   = "|cff44ff44Statut: VERROUILLÉ|r",
    StatusUnlocked = "|cffffff00Statut: DÉVERROUILLÉ – glisser cadres|r",
    SectionParty   = "[ Groupe ]",
    SectionRaid    = "[ Raid ]",
    SectionRange   = "[ Portée ]",
    SectionBlizzard = "[ Blizzard ]",
    HideBlizzardParty = "Masquer les cadres de groupe Blizzard",
    ShowMinimapButton = "Afficher le bouton minimap",
    MinimapTooltipTitle = "StoneGrid",
    MinimapTooltipClick = "Clic gauche : réglages",
    MinimapTooltipDrag  = "Glisser : déplacer l'icône",
    SectionRaidIcon = "[ Raid icon ]",
    SectionTest    = "[ Test ]",
    SectionLang    = "[ Langue ]",
    SectionInfo    = "[ Infos ]",
    SectionSettings = "[ Réglages ]",
    BarColors    = "[ Couleurs des barres ]",
    HpBar        = "Barre HP:",
    ClassColor   = "Couleur de classe (barre)",
    NameClassColor = "Couleur de classe (nom)",
    IncomingHeal = "Soins entrants:",
    DirectOnly   = "Soins directs uniquement (sans HoTs)",
    SectionIncomingHeal = "[ Incoming Heal ]",
    IncludeOthers = "Inclure les soins des autres joueurs",
    MissingHpBg  = "Fond HP manquant:",
    BorderColor  = "Couleur bordure:",
    BorderThick  = "Épaisseur (px):",
    Save         = "Sauvegarder",
    ResetColors  = "Réinit. couleurs",
    Buffs        = "[ Buffs ]",
    ShowBuffs    = "Afficher les buffs",
    BuffOnlyMine = "Mes buffs seulement",
    Reverse      = "Inverser",
    FilterLabel  = "Filtre (noms séparés par virgule):",
    Debuffs      = "[ Debuffs ]",
    ShowDebuffs  = "Afficher les debuffs",
    ShowCooldown = "Afficher icône de recharge",
    CooldownFont = "Police recharge (px):",
    StackFont    = "Police pile (px):",
    Reset        = "Réinitialiser",
    TopLeft      = "Haut Gauche",   TopCenter = "Haut Centre",   TopRight  = "Haut Droite",
    MidLeft      = "Mil. Gauche",   MidRight  = "Mil. Droite",
    BotLeft      = "Bas Gauche",    BotCenter = "Bas Centre",    BotRight  = "Bas Droite",
    SizePx       = "Taille (px):",
    Max          = "Max:",
    MsgPartySaved  = "Groupe sauvegardé.",
    MsgPartyReset  = "Groupe réinitialisé.",
    MsgRaidSaved   = "Raid sauvegardé.",
    MsgRaidReset   = "Raid réinitialisé.",
    MsgLocked      = "Cadres verrouillés.",
    MsgUnlocked    = "Cadres déverrouillés.",
    MsgHidePartyOn = "Cadres de groupe Blizzard masqués.",
    MsgHidePartyOff = "Rechargez l'UI pour restaurer les cadres de groupe Blizzard.",
    MsgTestOff     = "Mode test désactivé.",
    MsgColorsReset = "Couleurs réinitialisées.",
    MsgBuffsReset  = "Paramètres de buff réinitialisés.",
    MsgLangChanged = "Langue changée. Menu reconstruit.",
    VersionLabel   = "Version:",
    AuthorLabel    = "Auteur:",
}
