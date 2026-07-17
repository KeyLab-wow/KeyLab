-- KeyLab_Home.lua
-- Home tab for KeyLab / M+ Journal.

local addonName, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local HOME = {}
KeyLab.Tabs.Home = HOME
local EncounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData or {}
local SPACING = KeyLab.UI.Theme and KeyLab.UI.Theme.spacing or { card = 14, column = 12 }
local HEADER = KeyLab.UI.Theme and KeyLab.UI.Theme.tabHeader or { titleSize = 16 }

local COLORS = {
    bg         = {0.018, 0.026, 0.056, 0.96},
    panel      = {0.026, 0.046, 0.086, 0.84},
    important  = {0.030, 0.052, 0.094, 0.82},
    border     = {0.240, 0.380, 0.620, 0.62},
    warnBorder = {0.620, 0.560, 0.410, 0.70},
    text       = {0.940, 0.960, 0.990, 1.0},
    muted      = {0.680, 0.730, 0.820, 1.0},
    title      = {0.820, 0.760, 0.580, 1.0},
    accent     = {0.500, 0.680, 0.940, 1.0},
    warning    = {0.840, 0.720, 0.420, 1.0},
    divider    = {0.440, 0.580, 0.780, 0.32},
}

local CFG = {
    x = 24,
    y = -24,
    width = 880,
    gap = SPACING.card,
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

    return panel
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
    if EncounterData.EncounterMatchesCurrentCharacter then
        return EncounterData.EncounterMatchesCurrentCharacter(encounter, { allowMissingIdentity = true })
    end

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
    if EncounterData.IsCompletedEncounter then
        return EncounterData.IsCompletedEncounter(encounter)
    end

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

    if type(encounter.metrics) == "table" and next(encounter.metrics) ~= nil then
        return true
    end

    return false
end

local function CountEncounters()
    if EncounterData.GetEncounterList then
        return #EncounterData.GetEncounterList({
            includeInterrupted = false,
            includeExcluded = false,
            completedOnly = true,
            allowMissingIdentity = true,
        })
    end

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

local function FormatHomeDate(value)
    value = tonumber(value)
    if not value then return "-" end
    return date("%b %d %I:%M %p", value)
end

local function GetLatestRunState()
    local analysis = KeyLab.LastRunAnalysis
    if analysis and type(analysis.BuildState) == "function" then
        local ok, state = pcall(analysis.BuildState)
        if ok and type(state) == "table" then
            return state
        end
    end

    return { hasRun = false }
end

function HOME:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabHomeTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})

    local y = CFG.y
    local width = CFG.width
    local gap = CFG.gap
    local halfW = (width - gap) / 2
    local pairWidth = (halfW * 2) + SPACING.column
    local pairX = CFG.x + ((width - pairWidth) / 2)

    local hero = MakePanel(frame, CFG.x, y, width, 150, false)

    local title = MakeText(hero, "KeyLab Journal", HEADER.titleSize, COLORS.title, "LEFT")
    title:SetPoint("TOPLEFT", hero, "TOPLEFT", 16, -14)
    title:SetSize(360, 26)

    local subtitle = MakeText(
        hero,
        "A personal Mythic+ and Raid performance lab for encounter results, stat, talent and gear experiments, gearing plans, and the patterns that work for your characters.",
        12,
        COLORS.text,
        "LEFT"
    )
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetSize(540, 38)

    local rhythm = MakeText(hero, "Try a build.\nAdjust your stats.\nRun content.\nReview the results.", 14, COLORS.title, "LEFT")
    rhythm:SetPoint("TOPLEFT", hero, "TOPLEFT", 16, -78)
    rhythm:SetSize(560, 66)

    local sinceLabel = MakeText(hero, "Tracking Since", 11, COLORS.muted, "LEFT")
    sinceLabel:SetPoint("TOPLEFT", hero, "TOPLEFT", 620, -22)
    sinceLabel:SetSize(120, 16)

    local trackingValue = MakeText(hero, "Not started yet", 15, COLORS.accent, "LEFT")
    trackingValue:SetPoint("TOPLEFT", sinceLabel, "BOTTOMLEFT", 0, -4)
    trackingValue:SetSize(180, 22)

    local runsLabel = MakeText(hero, "Completed M+ Runs", 11, COLORS.muted, "LEFT")
    runsLabel:SetPoint("TOPLEFT", hero, "TOPLEFT", 620, -78)
    runsLabel:SetSize(120, 16)

    local runsValue = MakeText(hero, "0", 15, COLORS.accent, "LEFT")
    runsValue:SetPoint("TOPLEFT", runsLabel, "BOTTOMLEFT", 0, -4)
    runsValue:SetSize(180, 22)

    y = y - 150 - gap

    local latest = MakePanel(frame, CFG.x, y, width, 106, false)

    local latestTitle = MakeText(latest, "Latest M+ Run", 14, COLORS.title, "LEFT")
    latestTitle:SetPoint("TOPLEFT", latest, "TOPLEFT", 14, -12)
    latestTitle:SetSize(150, 18)

    local latestDungeonLabel = MakeText(latest, "Dungeon", 10, COLORS.muted, "LEFT")
    latestDungeonLabel:SetPoint("TOPLEFT", latest, "TOPLEFT", 14, -38)
    latestDungeonLabel:SetSize(180, 14)

    local latestDungeon = MakeText(latest, "No completed run yet", 13, COLORS.text, "LEFT")
    latestDungeon:SetPoint("TOPLEFT", latest, "TOPLEFT", 14, -56)
    latestDungeon:SetSize(270, 22)

    local latestKeyLabel = MakeText(latest, "Key", 10, COLORS.muted, "CENTER")
    latestKeyLabel:SetPoint("TOPLEFT", latest, "TOPLEFT", 320, -38)
    latestKeyLabel:SetSize(80, 14)

    local latestKey = MakeText(latest, "-", 13, COLORS.accent, "CENTER")
    latestKey:SetPoint("TOPLEFT", latest, "TOPLEFT", 320, -56)
    latestKey:SetSize(80, 22)

    local latestResultLabel = MakeText(latest, "Result", 10, COLORS.muted, "CENTER")
    latestResultLabel:SetPoint("TOPLEFT", latest, "TOPLEFT", 444, -38)
    latestResultLabel:SetSize(120, 14)

    local latestResult = MakeText(latest, "-", 13, COLORS.warning, "CENTER")
    latestResult:SetPoint("TOPLEFT", latest, "TOPLEFT", 444, -56)
    latestResult:SetSize(120, 22)

    local latestSavedLabel = MakeText(latest, "Saved", 10, COLORS.muted, "RIGHT")
    latestSavedLabel:SetPoint("TOPRIGHT", latest, "TOPRIGHT", -16, -38)
    latestSavedLabel:SetSize(190, 14)

    local latestSaved = MakeText(latest, "-", 12, COLORS.muted, "RIGHT")
    latestSaved:SetPoint("TOPRIGHT", latest, "TOPRIGHT", -16, -56)
    latestSaved:SetSize(190, 22)

    local latestHint = MakeText(latest, "Choose Mythic+ and open Summary to review the full run, group lineup, totals, and pull graph.", 11, COLORS.muted, "LEFT")
    latestHint:SetPoint("TOPLEFT", latest, "TOPLEFT", 14, -84)
    latestHint:SetSize(width - 28, 18)

    y = y - 106 - gap

    local releaseNoteHeight = 132
    local releaseNote = MakePanel(frame, CFG.x, y, width, releaseNoteHeight, false)

    local releaseTitle = MakeText(releaseNote, "What's New in KeyLab 1.6.0", 14, COLORS.title, "LEFT")
    releaseTitle:SetPoint("TOPLEFT", releaseNote, "TOPLEFT", 14, -12)
    releaseTitle:SetSize(280, 18)

    local releaseBody = MakeText(
        releaseNote,
        "Complete Raid support adds Encounters, Summary, Talent Builds, Stat Profiles, Gear Profiles, and Trends alongside shared Mythic+ | Raid navigation. This update also adds Gear Planning, the Master Item Database, Stat Goal Matcher, redesigned Gear Targets and Gear Dashboard, and timed Practice Sessions.\n\n" ..
        "Previously saved encounters remain in your journal. New Raid, profile, ranking, and gear fields appear only on encounters captured with this version.",
        11,
        COLORS.muted,
        "LEFT"
    )
    releaseBody:SetPoint("TOPLEFT", releaseTitle, "BOTTOMLEFT", 0, -8)
    releaseBody:SetSize(width - 28, 92)

    y = y - releaseNoteHeight - gap

    local required = MakePanel(frame, pairX, y, halfW, 170, true)

    local reqTitle = MakeText(required, "Required Blizzard Setting", 14, COLORS.warning, "LEFT")
    reqTitle:SetPoint("TOPLEFT", required, "TOPLEFT", 14, -12)
    reqTitle:SetSize(halfW - 28, 20)

    local reqBody = MakeText(
        required,
        "KeyLab uses Blizzard's built-in Damage Meter data to capture Mythic+ runs, raid boss pulls, and Practice outcomes.\n\n" ..
        "Before running content:\n" ..
        "- Game Menu > Gameplay Enhancements\n" ..
        "- Under Damage Meter, enable Damage Meter\n" ..
        "- Enable Auto Reset Damage Meter",
        12,
        COLORS.text,
        "LEFT"
    )
    reqBody:SetPoint("TOPLEFT", reqTitle, "BOTTOMLEFT", 0, -8)
    reqBody:SetSize(halfW - 28, 126)

    local macro = MakePanel(frame, pairX + halfW + SPACING.column, y, halfW, 170, false)

    local macroTitle = MakeText(macro, "Open KeyLab Quickly", 14, COLORS.title, "LEFT")
    macroTitle:SetPoint("TOPLEFT", macro, "TOPLEFT", 14, -12)
    macroTitle:SetSize(halfW - 28, 20)

    local macroBody = MakeText(
        macro,
        "Use the minimap icon to open or close the journal.\n\n" ..
        "You can also type /keylab, or create a General Macro named KeyLab with /keylab as the command.",
        12,
        COLORS.text,
        "LEFT"
    )
    macroBody:SetPoint("TOPLEFT", macroTitle, "BOTTOMLEFT", 0, -8)
    macroBody:SetSize(halfW - 28, 116)

    frame.summarySince = trackingValue
    frame.summaryRuns = runsValue
    frame.latestDungeon = latestDungeon
    frame.latestKey = latestKey
    frame.latestResult = latestResult
    frame.latestSaved = latestSaved

    function frame:Refresh()
        self.summarySince:SetText(GetTrackingSinceText())
        self.summaryRuns:SetText(tostring(CountEncounters()))

        local state = GetLatestRunState()
        if state and state.hasRun then
            self.latestDungeon:SetText(tostring(state.dungeonName or "Unknown Dungeon"))
            self.latestKey:SetText("+" .. tostring(state.keyLevel or 0))
            self.latestResult:SetText(tostring(state.resultText or "Completed"))
            self.latestSaved:SetText(FormatHomeDate(state.timestamp))
        else
            self.latestDungeon:SetText("No completed run yet")
            self.latestKey:SetText("-")
            self.latestResult:SetText("-")
            self.latestSaved:SetText("-")
        end
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
