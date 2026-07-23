-- Gear Planning: a compact reference guide for KeyLab's gearing workflow.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local GearPlanning = {}
KeyLab.Tabs.GearPlanning = GearPlanning
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

local function Tip()
    return "|cFF80ADEFKeyLab Tip|r"
end

local function List(items)
    return "- " .. table.concat(items, "\n- ")
end

local function Join(parts)
    return table.concat(parts, "\n\n")
end

local SECTIONS = {
    {
        title = "1. Welcome to Gear Planning",
        body = Join({
            Heading("Why It Matters"),
            "Your Tier Set, crafted gear, embellishments, trinkets, and other important items shape the rest of your gear plan.\n\nMake those choices first. Then KeyLab can help you plan the remaining slots around your secondary-stat goals.",
            Tip(),
            "KeyLab does not choose your build or tell you what is Best in Slot.\n\nGear Planning explains the tools and helps you build a plan based on the choices you make.",
        }),
    },
    {
        title = "2. Tier Sets",
        body = Join({
            Heading("Why It Matters"),
            "Tier Sets give powerful 2-piece and 4-piece bonuses. These bonuses often matter more than secondary stats alone.",
            Heading("How to Get Tier Pieces"),
            "You can get Tier pieces from:\n" .. List({
                "Raid bosses",
                "The Great Vault",
                "The Catalyst",
                "Other seasonal rewards when available",
            }) .. "\n\nMythic+ players can use the Catalyst to turn eligible seasonal armor into Tier pieces.",
            Tip(),
            "For the best Stat Goal Matcher results, finish and equip your planned 4-piece Tier Set first.\n\nTier pieces are not in the Master Item Database. Keep them equipped so their stats are included in the match.\n\nYou only need four of the five Tier slots. Use the Gear Dashboard to track your Tier pieces and find dungeons that drop armor for the Catalyst.",
        }),
    },
    {
        title = "3. Crafted Items",
        body = Join({
            Heading("Why It Matters"),
            "Crafted gear gives you more control over your plan. Depending on the recipe, you may choose the slot, secondary stats, and special effects.\n\nPlan the crafted items you want to keep before matching the rest of your gear.",
            Heading("What You Need to Know"),
            List({
                "Crafted gear is made through Crafting Orders.",
                "Missives let you choose allowed secondary stats.",
                "Embellishments add special effects.",
                "You may equip up to two items marked 'Unique-Equipped: Embellished (2).'",
                "Crafted items without that label do not count toward the two-item limit.",
            }),
            Tip(),
            "Equip the crafted and embellished items you want to keep before running the Stat Goal Matcher.\n\nThe matcher includes their equipped stats, but it does not recommend crafted items, choose Missives, or judge Embellishments.",
        }),
    },
    {
        title = "4. Trinkets",
        body = Join({
            Heading("Why They Matter"),
            "Trinkets can be a major source of power. Many have special Equip, Use, or Proc effects that secondary stats cannot measure.",
            Heading("What You Need to Know"),
            List({
                "Trinkets may have primary stats, secondary stats, both, or neither.",
                "Some trinkets get most of their power from special effects.",
                "Trinkets may help with damage, healing, defense, or utility.",
                "Some trinkets are made for certain roles.",
                "Blizzard tuning can change how well a trinket performs.",
            }),
            Tip(),
            "Equip the trinkets you want to keep before running the Stat Goal Matcher.\n\nIf a trinket slot is empty, KeyLab may match a dungeon or raid trinket that has Crit, Haste, Mastery, or Versatility.\n\nKeyLab does not judge trinket effects. A Goal Match is not a Best in Slot claim.",
        }),
    },
    {
        title = "5. Stat Goal Matcher",
        body = Join({
            Heading("Why It Matters"),
            "The Stat Goal Matcher helps fill your open gear slots after you have chosen the important pieces you want to keep.",
            Heading("How It Works"),
            List({
                "Equip your Tier, crafted, embellished, trinket, set, and other keeper items.",
                "Unequip only the slots you want KeyLab to fill.",
                "Choose the Master Item Database or gear owned by this character.",
                "If using the database, choose Dungeon, Raid, or Dungeon and Raid items.",
                "Enter the Crit, Haste, Mastery, and Versatility percentages you want to see on your Character panel.",
                "Each goal may be set from 0% to 100%. The four goals do not need to total 100%.",
                "Choose Balanced or Favor Priority.",
                "Run the matcher and review the suggested set.",
                "Mark any item you want as a Target or Alternative.",
            }),
            "KeyLab checks the full finished gear set and finds the combination that comes closest to your goals.",
            Tip(),
            "At least one eligible slot must be empty.\n\nThe matcher compares secondary stats. It does not judge Tier bonuses, trinket effects, set effects, embellishments, or Best in Slot.\n\nResults may include projected upgrades and reduced-stat-efficiency warnings. A Goal Match means 'closest match found,' not 'best item in the game.'",
        }),
    },
    {
        title = "6. Gear Targets",
        body = Join({
            Heading("Why It Matters"),
            "Gear Targets is where you choose the dungeon and raid items you want to pursue.\n\nChoose items yourself or use the Stat Goal Matcher for help. Your saved choices appear on the Gear Dashboard.",
            Heading("How It Works"),
            List({
                "Browse gear for your current class and spec.",
                "Filter by slot, source, item type, stats, or saved status.",
                "Hover over an item to read its tooltip.",
                "Save one Target for each slot.",
                "Save other acceptable items as Alternatives.",
                "Leave items Unmarked when they are not part of your plan.",
            }) .. "\n\nA slot must have a Target before it can have an Alternative.\n\nGoal Match suggestions do not select themselves. You decide what becomes a Target, Alternative, or stays Unmarked.",
            Tip(),
            "You do not have to run the Stat Goal Matcher. You can choose every Target yourself.\n\nGoal Match is KeyLab's stat suggestion. Target and Alternative are your choices.",
        }),
    },
    {
        title = "7. Gear Dashboard",
        body = Join({
            Heading("Why It Matters"),
            "The Gear Dashboard puts your current gear and saved goals in one place.",
            Heading("What You Can See"),
            List({
                "Equipped item levels and upgrade tracks",
                "Progress toward your 4-piece Tier Set",
                "The Tier slots you chose",
                "Dungeons that drop armor for your remaining Catalyst slots",
                "Saved Targets and Alternatives",
                "Dungeon and raid sources",
                "Target progress",
                "Hero and Myth upgrade options",
            }) .. "\n\nYou only need four of the five Tier slots. After four are checked, KeyLab stops treating the fifth slot as missing Tier.",
            Tip(),
            "Use the Gear Dashboard to follow the plan you created in Gear Targets.\n\nThe Dashboard does not choose your gear or decide Best in Slot. It organizes your choices and shows where to get them.",
        }),
    },
}

function GearPlanning:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabGearPlanningTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -14)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -14)
    header:SetHeight(68)
    SetBackdrop(header, COLORS.panel, COLORS.border)

    local title = Text(header, "Gear Planning", "GameFontNormalLarge", HEADER.titleSize, COLORS.gold)
    title:SetPoint("TOPLEFT", header, "TOPLEFT", 16, -10)
    title:SetSize(420, 24)

    local subtitle = Text(header, "Learn the main gearing choices, then plan the open slots around your goals.", "GameFontHighlightSmall", 12, COLORS.muted)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetSize(850, 24)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -98)
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

function KeyLab_CreateGearPlanningTab(parent)
    return GearPlanning:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Gear Planning", function(parent) return GearPlanning:Create(parent) end)
end

return GearPlanning
