-- KeyLab_Home.lua
-- Home tab for KeyLab / M+ Journal.

local addonName, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local HOME = {}
KeyLab.Tabs.Home = HOME

local COLORS = {
    bg         = {0.015, 0.025, 0.055, 0.96},
    panel      = {0.030, 0.045, 0.085, 0.78},
    important  = {0.080, 0.055, 0.025, 0.74},
    border     = {0.24, 0.36, 0.68, 0.55},
    warnBorder = {0.95, 0.72, 0.25, 0.85},
    text       = {0.86, 0.90, 0.96, 1.0},
    muted      = {0.62, 0.68, 0.78, 1.0},
    title      = {0.95, 0.78, 0.34, 1.0},
    accent     = {0.58, 0.78, 1.00, 1.0},
    warning    = {1.00, 0.80, 0.38, 1.0},
    divider    = {1, 1, 1, 0.13},
}

local CFG = {
    x = 24,
    y = -24,
    width = 880,
    gap = 14,
}

local function SetBackdrop(frame, color, borderColor)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })

    frame:SetBackdropColor(unpack(color or COLORS.bg))
    frame:SetBackdropBorderColor(unpack(borderColor or {0, 0, 0, 0}))
end

local function MakeText(parent, text, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(STANDARD_TEXT_FONT, size or 12, "")
    fs:SetTextColor(unpack(color or COLORS.text))
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetText(text or "")
    return fs
end

local function MakePanel(parent, x, y, width, height, important)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    panel:SetSize(width, height)
    SetBackdrop(panel, important and COLORS.important or COLORS.panel, important and COLORS.warnBorder or COLORS.border)

    if important then
        local strip = panel:CreateTexture(nil, "ARTWORK")
        strip:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
        strip:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
        strip:SetWidth(3)
        strip:SetColorTexture(unpack(COLORS.warning))
    end

    return panel
end

local function MakeButton(parent, label, width, height, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 150, height or 26)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

local function NormalizeKeyLabName(value)
    value = tostring(value or "")
    value = value:gsub("%s+", "")
    value = value:gsub("'", "")
    value = value:gsub("%-+", "-")
    return string.lower(value)
end

local function GetCurrentCharacterIdentity()
    local name, realm

    if UnitFullName then
        name, realm = UnitFullName("player")
    end

    if not name or name == "" then
        name = UnitName and UnitName("player") or nil
    end

    if (not realm or realm == "") and GetRealmName then
        realm = GetRealmName()
    end

    return name, realm
end

local function EncounterMatchesCurrentCharacter(encounter)
    if type(encounter) ~= "table" then
        return false
    end

    local currentName, currentRealm = GetCurrentCharacterIdentity()
    if not currentName or currentName == "" then
        return true
    end

    local player = encounter.player or {}
    local character = encounter.character or {}
    local context = encounter.context or {}
    local capture = encounter.capture or {}

    local encounterName =
        player.name
        or player.characterName
        or player.character
        or player.playerName
        or character.name
        or character.characterName
        or context.characterName
        or context.playerName
        or capture.characterName
        or capture.playerName
        or encounter.characterName
        or encounter.playerName
        or encounter.character
        or encounter.name

    local encounterRealm =
        player.realm
        or player.realmName
        or player.server
        or character.realm
        or character.realmName
        or context.realm
        or context.realmName
        or capture.realm
        or capture.realmName
        or encounter.realm
        or encounter.realmName
        or encounter.server

    local encounterFull =
        player.fullName
        or player.characterFullName
        or character.fullName
        or character.characterFullName
        or context.characterFullName
        or context.fullName
        or capture.characterFullName
        or capture.fullName
        or encounter.characterFullName
        or encounter.fullName

    local currentNameKey = NormalizeKeyLabName(currentName)
    local currentRealmKey = NormalizeKeyLabName(currentRealm)
    local currentFullKey = currentNameKey
    if currentRealmKey ~= "" then
        currentFullKey = currentFullKey .. "-" .. currentRealmKey
    end

    if encounterFull and encounterFull ~= "" then
        local fullKey = NormalizeKeyLabName(encounterFull)
        if fullKey == currentFullKey or fullKey == currentNameKey then
            return true
        end
    end

    if not encounterName or encounterName == "" then
        return true
    end

    if NormalizeKeyLabName(encounterName) ~= currentNameKey then
        return false
    end

    if encounterRealm and encounterRealm ~= "" and currentRealmKey ~= "" then
        return NormalizeKeyLabName(encounterRealm) == currentRealmKey
    end

    return true
end

local function IsCompletedEncounter(encounter)
    if type(encounter) ~= "table" then return false end

    local flags = encounter.flags
    if type(flags) == "table" then
        if flags.interrupted == true then return false end
        if flags.excludedFromComparisons == true then return false end
    end

    if encounter.status == "capture_failed" or encounter.excludeFromComparisons == true then
        return false
    end

    if encounter.completed == true or encounter.isComplete == true then
        return true
    end

    if encounter.result == "Completed" or encounter.result == "Complete" then
        return true
    end

    if encounter.result == "Timed" or encounter.result == "Untimed" or encounter.result == "Depleted" then
        return true
    end

    if type(encounter.challenge) == "table" or type(encounter.metrics) == "table" then
        return true
    end

    return false
end

local function CountEncounters()
    local list = nil

    if KeyLab.DB and KeyLab.DB.Encounters and KeyLab.DB.Encounters.GetFiltered then
        list = KeyLab.DB.Encounters.GetFiltered({
            includeInterrupted = false,
            includeExcluded = true,
        })
    elseif type(KeyLabDB) == "table" then
        list = KeyLabDB.encounters or {}
    else
        return 0
    end

    local count = 0
    for _, encounter in pairs(list or {}) do
        if EncounterMatchesCurrentCharacter(encounter) and IsCompletedEncounter(encounter) then
            count = count + 1
        end
    end

    return count
end

local function GetTrackingSinceText()
    if KeyLab.DB and KeyLab.DB.GetTrackingSince then
        return KeyLab.DB.GetTrackingSince()
    end

    if KeyLabDB and KeyLabDB.trackingSince then
        return KeyLabDB.trackingSince
    end

    return "Not started yet"
end

function HOME:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabHomeTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})

    local y = CFG.y
    local width = CFG.width
    local gap = CFG.gap
    local halfW = (width - gap) / 2

    local hero = MakePanel(frame, CFG.x, y, width, 132, false)

    local title = MakeText(hero, "KeyLab Journal", 20, COLORS.title, "LEFT")
    title:SetPoint("TOPLEFT", hero, "TOPLEFT", 16, -14)
    title:SetSize(360, 26)

    local subtitle = MakeText(
        hero,
        "A personal Mythic+ journal for real run outcomes, stat experiments, target gear, and the patterns that work for your characters.",
        12,
        COLORS.text,
        "LEFT"
    )
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetSize(540, 38)

    local rhythm = MakeText(hero, "Try a build. Tune your stats. Target gear. Review results.", 14, COLORS.title, "LEFT")
    rhythm:SetPoint("TOPLEFT", hero, "TOPLEFT", 16, -94)
    rhythm:SetSize(560, 22)

    local sinceLabel = MakeText(hero, "Tracking Since", 11, COLORS.muted, "LEFT")
    sinceLabel:SetPoint("TOPLEFT", hero, "TOPLEFT", 620, -22)
    sinceLabel:SetSize(120, 16)

    local trackingValue = MakeText(hero, "Not started yet", 15, COLORS.accent, "LEFT")
    trackingValue:SetPoint("TOPLEFT", sinceLabel, "BOTTOMLEFT", 0, -4)
    trackingValue:SetSize(180, 22)

    local runsLabel = MakeText(hero, "Completed Runs", 11, COLORS.muted, "LEFT")
    runsLabel:SetPoint("TOPLEFT", hero, "TOPLEFT", 620, -78)
    runsLabel:SetSize(120, 16)

    local runsValue = MakeText(hero, "0", 15, COLORS.accent, "LEFT")
    runsValue:SetPoint("TOPLEFT", runsLabel, "BOTTOMLEFT", 0, -4)
    runsValue:SetSize(180, 22)

    y = y - 132 - gap

    local gearPanel = MakePanel(frame, CFG.x, y, width, 126, false)

    local gearTitle = MakeText(gearPanel, "Selected Gear Targets Window", 15, COLORS.title, "LEFT")
    gearTitle:SetPoint("TOPLEFT", gearPanel, "TOPLEFT", 14, -12)
    gearTitle:SetSize(width - 220, 20)

    local gearBody = MakeText(
        gearPanel,
        "Opens a small companion window with the items you marked Target or BIS in the Gear Targets tab. Keep it open while browsing Premade Groups to quickly see target drops for the dungeon you are considering.",
        12,
        COLORS.text,
        "LEFT"
    )
    gearBody:SetPoint("TOPLEFT", gearTitle, "BOTTOMLEFT", 0, -8)
    gearBody:SetSize(width - 238, 56)

    local gearHint = MakeText(
        gearPanel,
        "Use the sidebar Gear Targets tab to browse loot, set stat goals, and mark items.",
        11,
        COLORS.muted,
        "LEFT"
    )
    gearHint:SetPoint("TOPLEFT", gearPanel, "TOPLEFT", 14, -92)
    gearHint:SetSize(width - 238, 18)

    local openTargets = MakeButton(gearPanel, "Open Selected Items", 178, 28, function()
        if KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.ShowManual then
            KeyLab.GearTargetsWindow.ShowManual()
        end
    end)
    openTargets:SetPoint("TOPRIGHT", gearPanel, "TOPRIGHT", -18, -48)

    y = y - 126 - gap

    local required = MakePanel(frame, CFG.x, y, halfW, 170, true)

    local reqTitle = MakeText(required, "Required Blizzard Setting", 14, COLORS.warning, "LEFT")
    reqTitle:SetPoint("TOPLEFT", required, "TOPLEFT", 14, -12)
    reqTitle:SetSize(halfW - 28, 20)

    local reqBody = MakeText(
        required,
        "KeyLab uses Blizzard's built-in Damage Meter data to capture completed Mythic+ outcomes.\n\n" ..
        "Before running keys:\n" ..
        "- Game Menu > Gameplay Enhancements\n" ..
        "- Under Damage Meter, enable Damage Meter\n" ..
        "- Enable Auto Reset Damage Meter",
        12,
        COLORS.text,
        "LEFT"
    )
    reqBody:SetPoint("TOPLEFT", reqTitle, "BOTTOMLEFT", 0, -8)
    reqBody:SetSize(halfW - 28, 126)

    local macro = MakePanel(frame, CFG.x + halfW + gap, y, halfW, 170, false)

    local macroTitle = MakeText(macro, "Open KeyLab Quickly", 14, COLORS.title, "LEFT")
    macroTitle:SetPoint("TOPLEFT", macro, "TOPLEFT", 14, -12)
    macroTitle:SetSize(halfW - 28, 20)

    local macroBody = MakeText(
        macro,
        "Use /keylab to open or close the journal.\n\n" ..
        "For an action bar button, create a General Macro named KeyLab, add /keylab as the command, then drag it to an action bar.",
        12,
        COLORS.text,
        "LEFT"
    )
    macroBody:SetPoint("TOPLEFT", macroTitle, "BOTTOMLEFT", 0, -8)
    macroBody:SetSize(halfW - 28, 116)

    y = y - 170 - gap

    local tracks = MakePanel(frame, CFG.x, y, width, 158, false)

    local tracksTitle = MakeText(tracks, "What KeyLab Tracks", 15, COLORS.title, "LEFT")
    tracksTitle:SetPoint("TOPLEFT", tracks, "TOPLEFT", 14, -12)
    tracksTitle:SetSize(width - 28, 22)

    local tracksIntro = MakeText(
        tracks,
        "KeyLab keeps personal run context together so you can compare what changed and what actually worked.",
        12,
        COLORS.muted,
        "LEFT"
    )
    tracksIntro:SetPoint("TOPLEFT", tracksTitle, "BOTTOMLEFT", 0, -4)
    tracksIntro:SetSize(width - 28, 20)

    local leftTracks = MakeText(
        tracks,
        "- Dungeon and key level\n" ..
        "- Affixes\n" ..
        "- Talent string\n" ..
        "- Character stats",
        12,
        COLORS.text,
        "LEFT"
    )
    leftTracks:SetPoint("TOPLEFT", tracks, "TOPLEFT", 24, -62)
    leftTracks:SetSize(360, 84)

    local rightTracks = MakeText(
        tracks,
        "- Metric outcomes\n" ..
        "- Stat profiles\n" ..
        "- Gear targets\n" ..
        "- Personal notes and trends",
        12,
        COLORS.text,
        "LEFT"
    )
    rightTracks:SetPoint("TOPLEFT", tracks, "TOPLEFT", 454, -62)
    rightTracks:SetSize(360, 84)

    frame.summarySince = trackingValue
    frame.summaryRuns = runsValue

    function frame:Refresh()
        self.summarySince:SetText(GetTrackingSinceText())
        self.summaryRuns:SetText(tostring(CountEncounters()))
    end

    frame:SetScript("OnShow", function(self)
        self:Refresh()
    end)

    return frame
end

function KeyLab_CreateHomeTab(parent)
    return HOME:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Home", function(parent)
        return HOME:Create(parent)
    end)
end

return HOME
