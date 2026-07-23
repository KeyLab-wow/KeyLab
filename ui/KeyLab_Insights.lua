-- Insights: compact reference notes presented as expandable sections.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local Insights = {}
KeyLab.Tabs.Insights = Insights
local HEADER = KeyLab.UI.Theme and KeyLab.UI.Theme.tabHeader or { titleSize = 16 }

local COLORS = {
    bg = {0.018, 0.026, 0.056, 0.96},
    panel = {0.026, 0.046, 0.086, 0.92},
    body = {0.022, 0.038, 0.076, 0.86},
    border = {0.240, 0.380, 0.620, 0.62},
    hover = {0.300, 0.420, 0.600, 0.78},
    gold = {0.820, 0.760, 0.580, 1.0},
    text = {0.940, 0.960, 0.990, 1.0},
    muted = {0.680, 0.730, 0.820, 1.0},
}

local function SetBackdrop(frame, background, border)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(background))
    frame:SetBackdropBorderColor(unpack(border))
end

local function Text(parent, value, template, size, color)
    local fontString = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    if size then fontString:SetFont(STANDARD_TEXT_FONT, size, "") end
    fontString:SetTextColor(unpack(color or COLORS.text))
    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("TOP")
    fontString:SetWordWrap(true)
    fontString:SetText(value or "")
    return fontString
end

local function Heading(value)
    return "|cFFD1C29A" .. tostring(value) .. "|r"
end

local function List(items)
    return "- " .. table.concat(items, "\n- ")
end

local function Join(parts)
    return table.concat(parts, "\n\n")
end

local SECTIONS = {
    {
        title = "Encounter Variables",
        body = Join({
            "Real Mythic+ results can change from run to run, even when you use the same setup.",
            Heading("Core Variables"),
            List({
                "Movement",
                "Positioning",
                "Reaction timing",
                "Target switching",
                "Interrupt pressure",
                "Survivability",
            }),
            Heading("Run Flow"),
            List({
                "Uptime during mechanics",
                "Cooldown timing",
                "Encounter pacing",
                "Consistency under pressure",
                "Group movement",
                "Recovery after mistakes",
            }),
            Heading("Pressure Points"),
            "Different dungeons reward different strengths. A setup that feels great in one run may feel weaker when movement, interrupts, damage, or survival needs change.",
        }),
    },
    {
        title = "Encounter Pressures",
        body = Join({
            Heading("Ranged Encounter Pressures"),
            List({
                "Cast interruption",
                "Movement disruption",
                "Line-of-sight interruption",
                "Target swapping",
                "Maintaining uptime while moving",
                "Camera repositioning",
            }),
            Heading("Melee Encounter Pressures"),
            List({
                "Avoidable damage pressure",
                "Ground effect exposure",
                "Positional awareness",
                "Frontal management",
                "Boss movement",
                "Survivability tradeoffs",
                "Reaction timing under pressure",
            }),
        }),
    },
    {
        title = "Character Stats Reference",
        body = Join({
            "Stats can change your damage, healing, survival, and how your spec feels to play.",
            Heading("Primary Stats"),
            "Strength, Agility, Intellect, and Stamina",
            Heading("Secondary Stats"),
            "Haste, Critical Strike, Mastery, and Versatility",
            Heading("Tertiary and Defensive Stats"),
            "Avoidance, Leech, Speed, Parry, Block, Dodge, and Miss",
            Heading("Haste can affect"),
            List({ "Casting speed", "Global cooldowns", "Resource generation", "Gameplay pacing" }),
            Heading("Versatility can affect"),
            List({ "Damage done", "Healing done", "Damage reduction", "Overall survivability" }),
            Heading("Critical Strike can affect"),
            List({
                "Chance to deal increased damage or healing",
                "Burst potential",
                "Reactive healing strength",
                "Certain class and talent interactions",
            }),
            Heading("Mastery can affect"),
            List({
                "Specialization-specific mechanics",
                "Healing effectiveness",
                "Defensive strength",
                "Ability interactions",
            }) .. "\n\nMastery works differently for each spec, so its value can change with your build and the content you play.",
        }),
    },
    {
        title = "Spell Queue Window",
        body = Join({
            "Spell Queue Window controls how early WoW accepts your next ability before the current cast or Global Cooldown ends. Different values may feel better depending on your latency and key-press rhythm.",
            Heading("Check Current Value"),
            "/dump GetCVar(\"SpellQueueWindow\")",
            Heading("Change the Value"),
            "/console SpellQueueWindow NUMBER",
            "Blizzard's default is 400 ms.",
        }),
    },
    {
        title = "Macros",
        body = Join({
            "Macros can make targeting and repeated actions faster and more comfortable.",
            Heading("Macros can help"),
            List({
                "Simplify repetitive actions",
                "Support different playstyles",
                "Improve comfort or accessibility",
                "Reduce targeting overhead",
                "Improve reaction speed",
            }),
            Heading("Common Macro Targets"),
            "@focus, @target, @targettarget, @focustarget, @party1-4, @raid1-40, @player, @mouseover, @cursor, @playername, and @buttonX",
            Heading("Location-Targeted Examples"),
            "/cast [@player] Angelic Feather\n/cast [@player] Healing Rain\n/cast [@player] Cataclysm",
        }),
    },
    {
        title = "Conditional Macro Examples",
        body = Join({
            "One macro can use conditions to handle utility, healing, dispels, or combat resurrection for a chosen player. This can save time during fast fights.",
            Heading("Party 3 Example"),
            "/cast [mod:ctrl, @party3] Cleanse; [@party3, dead] Intercession; [@party3, nochanneling] Flash Heal",
            Heading("Party 4 Example"),
            "/use [@party4, dead] Emergency Soul Link\n/cast [mod:ctrl, @party4] Purify; [@party4, nochanneling] Penance",
            Heading("Party 2 Example"),
            "/use [@party2, dead] Emergency Soul Link\n/cast [@party2, nochanneling] Healing Surge",
        }),
    },
    {
        title = "Sims",
        body = "Sims test builds, stats, and gear in controlled conditions.\n\nReal results can be different because of mechanics, movement, group makeup, mistakes, and your own playstyle.\n\nTheory proposes. Real play tests. KeyLab remembers.",
    },
}

function Insights:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabInsightsTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -14)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -14)
    header:SetHeight(62)
    SetBackdrop(header, COLORS.panel, COLORS.border)

    local title = Text(header, "Insights", "GameFontNormalLarge", HEADER.titleSize, COLORS.gold)
    title:SetPoint("TOPLEFT", header, "TOPLEFT", 16, -10)
    title:SetSize(420, 24)

    local subtitle = Text(header, "Quick notes about combat results, stats, macros, the spell queue, and sims.", "GameFontHighlightSmall", 12, COLORS.muted)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetSize(850, 24)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -90)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 18)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(900, 520)
    scroll:SetScrollChild(content)

    self.accordion = KeyLab.UI.Accordion.Create(content, {
        sections = SECTIONS,
        colors = COLORS,
        width = 884,
        left = 8,
        minHeight = 520,
    })
    self.frame = frame
    self.content = content
    return frame
end

function KeyLab_CreateInsightsTab(parent)
    return Insights:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Insights", function(parent) return Insights:Create(parent) end)
end

return Insights
