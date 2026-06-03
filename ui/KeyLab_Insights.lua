-- KeyLab_Insights.lua
-- Insights tab for KeyLab / M+ Journal
-- Purpose: concise reference information for encounter variables, character stats, spell queue window, macros, and sims.
-- No assets/images.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local Insights = {}
KeyLab.Tabs.Insights = Insights

-- =========================================================
-- EASY EDIT SETTINGS
-- =========================================================

local COLORS = {
    bg       = {0.025, 0.035, 0.075, 0.96},
    panel    = {0.035, 0.055, 0.105, 0.40},
    border   = {0.22, 0.42, 0.78, 0.45},
    gold     = {0.95, 0.72, 0.25, 1.0},
    title    = {0.70, 0.86, 1.00, 1.0},
    text     = {0.88, 0.90, 0.96, 1.0},
    muted    = {0.64, 0.70, 0.82, 1.0},
    accent   = {0.35, 0.68, 1.00, 1.0},
    divider  = {1, 1, 1, 0.14},
    softBg   = {0.030, 0.046, 0.090, 0.42},
}

local CONTENT_WIDTH = 900
local PAGE_PADDING = 6

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
    frame:SetBackdropColor(unpack(color or COLORS.panel))
    frame:SetBackdropBorderColor(unpack(borderColor or COLORS.border))
end

local function MakeText(parent, text, template, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")

    if size then
        fs:SetFont(STANDARD_TEXT_FONT, size, "")
    end

    fs:SetTextColor(unpack(color or COLORS.text))
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetText(text or "")
    return fs
end

local function BulletList(items)
    return "• " .. table.concat(items, "\n• ")
end

local function DashList(items)
    return "- " .. table.concat(items, "\n- ")
end

local function AddDivider(parent, y, width)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", PAGE_PADDING, y)
    line:SetSize(width or (CONTENT_WIDTH - (PAGE_PADDING * 2)), 1)
    line:SetColorTexture(unpack(COLORS.divider))
    return line
end

local function AddAccent(parent, x, y, height)
    local strip = parent:CreateTexture(nil, "ARTWORK")
    strip:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    strip:SetSize(3, height or 24)
    strip:SetColorTexture(unpack(COLORS.gold))
    return strip
end

local function AddSectionHeader(parent, y, title, subtitle)
    AddAccent(parent, PAGE_PADDING, y + 2, subtitle and 44 or 28)

    local h = MakeText(parent, title, "GameFontNormalLarge", nil, COLORS.gold, "LEFT")
    h:SetPoint("TOPLEFT", parent, "TOPLEFT", PAGE_PADDING + 12, y)
    h:SetSize(CONTENT_WIDTH - 36, 24)

    local nextY = y - 30

    if subtitle and subtitle ~= "" then
        local s = MakeText(parent, subtitle, "GameFontHighlightSmall", nil, COLORS.muted, "LEFT")
        s:SetPoint("TOPLEFT", parent, "TOPLEFT", PAGE_PADDING + 12, y - 25)
        s:SetSize(CONTENT_WIDTH - 36, 32)
        nextY = y - 62
    end

    AddDivider(parent, nextY + 8)
    return nextY - 12
end

local function AddTextBlock(parent, x, y, width, title, body)
    if title and title ~= "" then
        local h = MakeText(parent, title, "GameFontNormal", nil, COLORS.title, "LEFT")
        h:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        h:SetSize(width, 18)

        local b = MakeText(parent, body, "GameFontHighlightSmall", nil, COLORS.text, "LEFT")
        b:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -7)
        b:SetSize(width, 500)
        return b
    end

    local b = MakeText(parent, body, "GameFontHighlightSmall", nil, COLORS.text, "LEFT")
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    b:SetSize(width, 500)
    return b
end

local function AddSoftBox(parent, x, y, width, height, title, body)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    box:SetSize(width, height)
    SetBackdrop(box, COLORS.softBg, COLORS.border)

    local h = MakeText(box, title, "GameFontNormal", nil, COLORS.title, "LEFT")
    h:SetPoint("TOPLEFT", box, "TOPLEFT", 12, -10)
    h:SetSize(width - 24, 18)

    local b = MakeText(box, body, "GameFontHighlightSmall", nil, COLORS.text, "LEFT")
    b:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -7)
    b:SetSize(width - 24, height - 38)

    return box
end

local function AddColumnDivider(parent, x, y, height)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    line:SetSize(1, height)
    line:SetColorTexture(unpack(COLORS.divider))
    return line
end

-- =========================================================
-- CONTENT
-- =========================================================

local function BuildInsights(content)
    local y = -4

    -- Encounter Variables
    y = AddSectionHeader(content, y, "Encounter Variables", "Gameplay factors that can change real Mythic+ outcomes from run to run.")

    local colW = 270
    AddTextBlock(content, PAGE_PADDING + 12, y, colW, "Core Variables", BulletList({
        "Movement",
        "Positioning",
        "Reaction timing",
        "Target switching",
        "Interrupt pressure",
        "Survivability",
    }))

    AddColumnDivider(content, 310, y + 4, 122)

    AddTextBlock(content, 330, y, colW, "Run Flow", BulletList({
        "Uptime during mechanics",
        "Cooldown timing",
        "Encounter pacing",
        "Consistency under pressure",
        "Group movement",
        "Recovery after mistakes",
    }))

    AddColumnDivider(content, 620, y + 4, 122)

    AddTextBlock(content, 640, y, 245, "Pressure Points", "Different encounters may reward different strengths. A build or stat setup that feels strong in one dungeon may feel weaker when movement, interrupts, or survivability pressure changes.")

    y = y - 150

    -- Encounter Pressures
    y = AddSectionHeader(content, y, "Encounter Pressures", "")

    AddTextBlock(content, PAGE_PADDING + 12, y, 410, "Ranged Encounter Pressures", BulletList({
        "Cast interruption",
        "Movement disruption",
        "Line-of-sight interruption",
        "Target swapping",
        "Maintaining uptime while moving",
        "Camera repositioning",
    }))

    AddColumnDivider(content, 455, y + 4, 128)

    AddTextBlock(content, 480, y, 390, "Melee Encounter Pressures", BulletList({
        "Avoidable damage pressure",
        "Ground effect exposure",
        "Positional awareness",
        "Frontal management",
        "Boss movement",
        "Survivability tradeoffs",
        "Reaction timing under pressure",
    }))

    y = y - 158

    -- Character Stats Reference
    y = AddSectionHeader(content, y, "Character Stats Reference", "Stats can affect pacing, burst, survivability, and specialization-specific mechanics.")

    AddSoftBox(content, PAGE_PADDING + 12, y, 280, 92, "Primary Stats", "Strength\nAgility\nIntellect\nStamina")
    AddSoftBox(content, 318, y, 280, 92, "Secondary Stats", "Haste\nCritical Strike\nMastery\nVersatility")
    AddSoftBox(content, 624, y, 260, 92, "Tertiary Stats", "Avoidance\nLeech\nSpeed\nParry, Block, Dodge, Miss")

    y = y - 120

    AddTextBlock(content, PAGE_PADDING + 12, y, 410, "Haste can affect:", DashList({
        "casting speed",
        "global cooldowns",
        "resource generation",
        "gameplay pacing",
    }))

    AddColumnDivider(content, 455, y + 4, 112)

    AddTextBlock(content, 480, y, 390, "Versatility can affect:", DashList({
        "damage done",
        "healing done",
        "damage reduction",
        "overall survivability",
    }))

    y = y - 132

    AddTextBlock(content, PAGE_PADDING + 12, y, 410, "Critical Strike can affect:", DashList({
        "chance to deal increased damage or healing",
        "burst potential",
        "reactive healing strength",
        "certain class and talent interactions",
    }))

    AddColumnDivider(content, 455, y + 4, 145)

    AddTextBlock(content, 480, y, 390, "Mastery can affect:", DashList({
        "specialization-specific mechanics",
        "healing effectiveness",
        "defensive strength",
        "ability interactions",
    }) .. "\n\nEach specialization has a unique Mastery effect. Different encounters and builds may benefit differently from Mastery.")

    y = y - 170

    -- Spell Queue Window
    y = AddSectionHeader(content, y, "Spell Queue Window", "A game setting that changes how early the client accepts your next ability input.")

    AddTextBlock(content, PAGE_PADDING + 12, y, 520, "", "Spell Queue Window affects how early the game accepts your next ability input before your current cast or global cooldown ends.\n\nDifferent values may change how responsive combat feels depending on latency and playstyle.")

    AddSoftBox(content, 575, y, 310, 116, "Commands",
        "Check Current:\n/dump GetCVar(\"SpellQueueWindow\")\n\nChange:\n/console SpellQueueWindow NUMBER\n\n400 ms = Blizzard default")

    y = y - 150

    -- Macros
    y = AddSectionHeader(content, y, "Macros", "Macros can reduce targeting friction, support different playstyles, and improve comfort.")

    AddTextBlock(content, PAGE_PADDING + 12, y, 270, "Macros can help:", DashList({
        "Simplify repetitive actions",
        "Support different playstyles",
        "Improve comfort or accessibility",
        "Reduce targeting overhead",
        "Improve reaction speed",
    }))

    AddColumnDivider(content, 310, y + 4, 160)

    AddTextBlock(content, 330, y, 250, "Common Macro Targets", "@focus\n@target\n@targettarget\n@focustarget\n@party1-4\n@raid1-40\n@player\n@mouseover\n@cursor\n@playername\n@buttonX")

    AddColumnDivider(content, 610, y + 4, 160)

    AddTextBlock(content, 630, y, 250, "Location-Targeted Examples", "/cast [@player] Angelic Feather\n\n/cast [@player] Healing Rain\n\n/cast [@player] Cataclysm")

    y = y - 190

    -- Conditional Macro Examples
    y = AddSectionHeader(content, y, "Conditional Macro Examples", "")

    AddTextBlock(content, PAGE_PADDING + 12, y, 870, "", "Macros can combine different targeting conditions to support utility, off-healing, dispels, and combat resurrection abilities from a single keybind.\n\nThese types of macros can help reduce targeting friction and improve reaction speed during fast-paced encounters.")

    y = y - 88

    AddSoftBox(content, PAGE_PADDING + 12, y, 278, 125, "Party 3 Example",
        "/cast [mod:ctrl, @party3] Cleanse; [@party3, dead] Intercession; [@party3, nochanneling] Flash Heal")

    AddSoftBox(content, 315, y, 278, 125, "Party 4 Example",
        "/use [@party4, dead] Emergency Soul Link\n/cast [mod:ctrl, @party4] Purify; [@party4, nochanneling] Penance")

    AddSoftBox(content, 618, y, 266, 125, "Party 2 Example",
        "/use [@party2, dead] Emergency Soul Link\n/cast [@party2, nochanneling] Healing Surge")

    y = y - 158

    -- Sims
    y = AddSectionHeader(content, y, "Sims", "")

    AddTextBlock(content, PAGE_PADDING + 12, y, 870, "", "Simulation tools are often used to test builds, stats, and gear combinations in controlled environments.\n\nReal encounter results may still vary depending on mechanics, group composition, movement, and playstyle.")

    y = y - 90

    content:SetHeight(math.abs(y) + 30)
end

-- =========================================================
-- CREATE TAB
-- =========================================================

function Insights:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabInsightsTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})

    local title = MakeText(frame, "Insights", "GameFontNormalLarge", nil, COLORS.gold, "LEFT")
    title:SetPoint("TOPLEFT", 18, -18)
    title:SetSize(420, 28)

    local subtitle = MakeText(frame, "Reference notes for encounter variables, character stats, spell queue window, macros, and sims.", "GameFontHighlightSmall", nil, COLORS.muted, "LEFT")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetSize(820, 24)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -74)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 18)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(CONTENT_WIDTH, 1000)
    scrollFrame:SetScrollChild(content)

    BuildInsights(content)

    self.frame = frame
    self.content = content

    return frame
end

function KeyLab_CreateInsightsTab(parent)
    return Insights:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Insights", function(parent)
        return Insights:Create(parent)
    end)
end

return Insights
