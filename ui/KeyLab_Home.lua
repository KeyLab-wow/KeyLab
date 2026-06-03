-- KeyLab_Home.lua
-- Home tab for KeyLab / M+ Journal
-- Purpose: simple landing page with tracking summary, required setup, quick access, and what KeyLab records.
-- Assets intentionally omitted for now.

local addonName, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local HOME = {}
KeyLab.Tabs.Home = HOME

-- =========================================================
-- EASY EDIT SETTINGS
-- =========================================================

local COLORS = {
    bg         = {0.015, 0.025, 0.055, 0.96},
    panel      = {0.030, 0.045, 0.085, 0.72},
    important  = {0.080, 0.055, 0.025, 0.72},
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

-- =========================================================
-- BASIC HELPERS
-- =========================================================

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

local function MakeDivider(parent, y, width)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", CFG.x, y)
    line:SetSize(width or CFG.width, 1)
    line:SetColorTexture(unpack(COLORS.divider))
    return line
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

    local encounterName =
        player.name
        or player.characterName
        or player.character
        or encounter.characterName
        or encounter.playerName
        or encounter.character

    local encounterRealm =
        player.realm
        or player.realmName
        or player.server
        or encounter.realm
        or encounter.realmName
        or encounter.server

    local encounterFull =
        player.fullName
        or player.characterFullName
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
        -- Older test records may not have character identity saved.
        -- Keep those visible instead of hiding historical data unexpectedly.
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

local function FilterCurrentCharacterEncounters(encounters)
    local filtered = {}

    for _, encounter in ipairs(encounters or {}) do
        if EncounterMatchesCurrentCharacter(encounter) then
            table.insert(filtered, encounter)
        end
    end

    return filtered
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

    -- Backward compatibility with earlier test records.
    if encounter.result == "Timed" or encounter.result == "Untimed" or encounter.result == "Depleted" then
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

-- =========================================================
-- CREATE TAB
-- =========================================================

function HOME:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabHomeTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})

    local y = CFG.y

    local title = MakeText(frame, "KeyLab Journal", 18, COLORS.title, "LEFT")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.x, y)
    title:SetSize(CFG.width, 24)

    y = y - 28

    local subtitle = MakeText(
        frame,
        "KeyLab is a personal Mythic+ journal focused on real encounter outcomes, talent and stat priority experimentation, and gameplay consistency.",
        12,
        COLORS.text,
        "LEFT"
    )
    subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.x, y)
    subtitle:SetSize(CFG.width, 34)

    y = y - 56
    MakeDivider(frame, y, CFG.width)
    y = y - 28

    local tracking = MakeText(frame, "Tracking Since: ", 13, COLORS.text, "LEFT")
    tracking:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.x, y)
    tracking:SetSize(200, 18)

    local trackingValue = MakeText(frame, "Not started yet", 13, COLORS.accent, "LEFT")
    trackingValue:SetPoint("LEFT", tracking, "RIGHT", 2, 0)
    trackingValue:SetSize(280, 18)

    y = y - 54
    MakeDivider(frame, y, CFG.width)
    y = y - 28

    local steps = MakeText(
        frame,
        "Try a build.\nAdjust your stats.\nRun content.\nReview the results.",
        15,
        COLORS.title,
        "LEFT"
    )
    steps:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.x, y)
    steps:SetSize(CFG.width, 84)

    y = y - 102
    MakeDivider(frame, y, CFG.width)
    y = y - 22

    -- Important setup and access panels.
    local halfW = (CFG.width - CFG.gap) / 2
    local panelH = 210

    local required = MakePanel(frame, CFG.x, y, halfW, panelH, true)

    local reqTitle = MakeText(required, "Required Blizzard Setting", 14, COLORS.warning, "LEFT")
    reqTitle:SetPoint("TOPLEFT", required, "TOPLEFT", 14, -12)
    reqTitle:SetSize(halfW - 28, 20)

    local reqBody = MakeText(
        required,
        "KeyLab uses Blizzard's built-in Damage Meter data to capture completed Mythic+ outcomes.\n\n" ..
        "Enable these settings before running keys:\n" ..
        "1. Open Game Menu.\n" ..
        "2. Select Gameplay Enhancements.\n" ..
        "3. Under Damage Meter, check:\n" ..
        "   • Enable Damage Meter\n" ..
        "   • Auto Reset Damage Meter\n" ..
        "4. Close the options window.",
        12,
        COLORS.text,
        "LEFT"
    )
    reqBody:SetPoint("TOPLEFT", reqTitle, "BOTTOMLEFT", 0, -8)
    reqBody:SetSize(halfW - 28, panelH - 42)

    local macro = MakePanel(frame, CFG.x + halfW + CFG.gap, y, halfW, panelH, false)

    local macroTitle = MakeText(macro, "Open KeyLab Quickly", 14, COLORS.title, "LEFT")
    macroTitle:SetPoint("TOPLEFT", macro, "TOPLEFT", 14, -12)
    macroTitle:SetSize(halfW - 28, 20)

    local macroBody = MakeText(
        macro,
        "Use /keylab to open or close the journal.\n\n" ..
        "To make an action bar button:\n" ..
        "1. Open Game Menu.\n" ..
        "2. Choose Macros.\n" ..
        "3. In General Macros tab click New.\n" ..
        "4. Name it KeyLab and choose any icon.\n" ..
        "5. In Enter Macro Commands, add:\n" ..
        "   /keylab\n" ..
        "6. Save it and drag the macro icon to an action bar.",
        12,
        COLORS.text,
        "LEFT"
    )
    macroBody:SetPoint("TOPLEFT", macroTitle, "BOTTOMLEFT", 0, -8)
    macroBody:SetSize(halfW - 28, panelH - 42)

    y = y - panelH - 26
    MakeDivider(frame, y, CFG.width)
    y = y - 28

    local tracksTitle = MakeText(frame, "What KeyLab Tracks", 15, COLORS.title, "LEFT")
    tracksTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.x, y)
    tracksTitle:SetSize(CFG.width, 22)

    y = y - 34

    local tracksBody = MakeText(
        frame,
        "• Dungeon\n" ..
        "• Key Level\n" ..
        "• Affixes\n" ..
        "• Talent String\n" ..
        "• Character Stats\n" ..
        "• Metric Outcomes\n" ..
        "• Stat Profiles",
        13,
        COLORS.text,
        "LEFT"
    )
    tracksBody:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.x, y)
    tracksBody:SetSize(CFG.width, 150)

    frame.summarySince = trackingValue

    function frame:Refresh()
        self.summarySince:SetText(GetTrackingSinceText())
    end

    frame:SetScript("OnShow", function(self)
        self:Refresh()
    end)

    frame:Refresh()

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
