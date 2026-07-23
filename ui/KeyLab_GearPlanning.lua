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
            "Before planning your gear, it is important to understand the major gearing systems that can shape your character throughout the season.\n\nThese long-term decisions form your Gearing Foundation and should generally be made before matching your remaining gear to your secondary-stat goals.",
            Tip(),
            "KeyLab does not choose your build or determine your Best in Slot gear.\n\nGear Planning explains the season's major gearing systems so you can make those decisions yourself. Once your Gearing Foundation is established, Gear Targets and the Stat Goal Matcher can help you plan dungeon and raid items for your remaining slots based on your chosen secondary-stat percentage goals.",
        }),
    },
    {
        title = "2. Tier Sets",
        body = Join({
            Heading("Why It Matters"),
            "Tier Sets provide powerful 2-piece and 4-piece bonuses that often have a greater impact on your character than secondary stats alone.",
            Heading("How to Get Tier Pieces"),
            "You can obtain Tier pieces through:\n" .. List({
                "Raid boss drops",
                "Great Vault rewards",
                "The Catalyst",
                "Other seasonal rewards when available",
            }) .. "\n\nMythic+ players can complete their Tier Set without raiding by converting eligible seasonal armor through the Catalyst.",
            Tip(),
            "For the most useful Stat Goal Matcher results, complete and equip your planned 4-piece Tier Set first.\n\nTier pieces are not included in the Stat Goal Matcher's Master Item Database. Keep your Tier pieces equipped so their secondary stats are included in the calculation. An Equipped + Bags run may surface owned Back, Wrist, Waist, or Feet armor that you want to convert for stats or appearance; those pieces can be saved as Catalyst Targets without counting toward the 2-piece or 4-piece bonus.\n\nUse the Gear Dashboard to track Tier progress and identify which dungeons offer eligible armor for your remaining Catalyst slots. Only four of the five eligible Tier slots are required for your 4-piece Tier Set.",
        }),
    },
    {
        title = "3. Crafted Items",
        body = Join({
            Heading("Why It Matters"),
            "Crafted Items are among the gearing choices you can directly control. Depending on the recipe, you may choose the item slot, secondary stats, and additional power effects.\n\nCrafted gear can provide valuable long-term pieces and should generally be planned before matching your remaining dungeon and raid gear.",
            Heading("What You Need to Know"),
            List({
                "Crafted gear is created through the Crafting Orders system.",
                "Missives allow you to choose eligible secondary stats.",
                "Embellishments add special power effects.",
                "You may equip up to two items marked 'Unique-Equipped: Embellished (2).'",
                "Crafted items without that restriction do not count toward the two-embellishment cap.",
            }),
            Tip(),
            "Choose and equip the crafted and embellished items you intend to keep before running the Stat Goal Matcher.\n\nCrafted items are not included in the matcher's recommendations. Their equipped secondary stats are included when KeyLab searches for dungeon and raid items that most closely fill the remaining percentage gaps.\n\nThe matcher does not recommend crafted items, select Missives, or evaluate which Embellishments you should use.",
        }),
    },
    {
        title = "4. Trinkets",
        body = Join({
            Heading("Why They Matter"),
            "Trinkets are often among the largest sources of character power each season. Unlike most equipment, they frequently provide unique Equip, Use, or Proc effects that cannot be evaluated through secondary stats alone.",
            Heading("What You Need to Know"),
            List({
                "Trinkets may provide Primary Stats, Secondary Stats, both, or neither.",
                "Some trinkets provide their power entirely through special effects.",
                "Trinkets can provide damage, healing, defensive, or utility effects.",
                "Many trinkets are intended for a particular role.",
                "Content type and future Blizzard tuning can change how individual trinkets perform.",
            }),
            Tip(),
            "Choose and equip any trinkets you intend to keep before running the Stat Goal Matcher. Their numeric secondary stats will be included in the calculation.\n\nIf a trinket slot is empty, the matcher may recommend an eligible dungeon or raid trinket only when it provides numeric Crit, Haste, Mastery, or Versatility that helps close your percentage gaps.\n\nThe matcher does not evaluate Equip, Use, or Proc effects. A Goal Match badge means the trinket's secondary stats fit the calculation; it does not mean Best in Slot.",
        }),
    },
    {
        title = "5. Stat Goal Matcher",
        body = Join({
            Heading("Why It Matters"),
            "The Stat Goal Matcher helps fill the remaining gaps after you have made the major gearing decisions for your character. For the most useful results, complete your 4-piece Tier Set and choose your crafted gear, embellishments, trinkets, set items, and other important pieces first.",
            Heading("How It Works"),
            List({
                "Keep your Tier Set, Crafted Items, Trinkets, Set Items, Embellished Items, and other committed gear equipped.",
                "Unequip only the slots you want KeyLab to evaluate.",
                "Choose Dungeon Items, Raid Items, or Dungeon and Raid Items.",
                "Enter desired percentages for Crit, Haste, Mastery, and Versatility.",
                "Enter the actual percentages you want to see on the Character panel; each stat may be set independently from 0% to 100%.",
                "Run the Stat Goal Matcher.",
                "Review Goal Match items and mark anything you want as a Target or Alternative.",
            }),
            "KeyLab includes the secondary-stat ratings from equipped gear and identifies the combination that most closely approaches your chosen percentages. The Master Item Database search uses eligible non-Tier dungeon and raid items; Equipped + Bags instead evaluates the eligible gear the character actually owns.",
            Tip(),
            "At least one eligible gear slot must be empty. Keep embellished items you intend to use equipped so you remain within the two-item cap.\n\nThe matcher compares secondary stats only. It does not evaluate item level, Tier bonuses, trinket effects, set effects, embellishments, or other special effects.\n\nA Goal Match is the closest available secondary-stat combination; it does not mean Best in Slot.",
        }),
    },
    {
        title = "6. Gear Targets",
        body = Join({
            Heading("Why It Matters"),
            "Gear Targets is where you create and manage the dungeon and raid item goals you want to pursue. You can choose targets manually or use the Stat Goal Matcher for secondary-stat guidance. Your saved choices provide the Gear Dashboard with the information it needs.",
            Heading("How It Works"),
            "Gear Targets displays eligible dungeon and raid items for your current class and specialization. You can:\n" .. List({
                "Browse eligible items without running the matcher.",
                "Filter by slot, source, item type, Primary Stats, Secondary Stats, and saved status.",
                "Hover over an item link to review its tooltip.",
                "Mark one item per slot as your Target.",
                "Mark additional items for that slot as Alternatives.",
                "Leave items Unmarked when you do not want to track them.",
                "Run the Stat Goal Matcher for help with remaining percentage gaps.",
            }) .. "\n\nA slot needs a Target before another item can be marked as its Alternative. Goal Match suggestions never select themselves; you decide whether each becomes a Target, Alternative, or remains Unmarked.",
            Tip(),
            "You do not have to use the Stat Goal Matcher. You can manually choose every item you want to pursue.\n\nGoal Match is KeyLab's secondary-stat suggestion. Target and Alternative are your saved decisions. Unmarked items are not currently part of your plan.\n\nThe Gear Dashboard uses your saved Targets and Alternatives to track progress toward the plan you chose.",
        }),
    },
    {
        title = "7. Gear Dashboard",
        body = Join({
            Heading("Why It Matters"),
            "The Gear Dashboard brings your selected goals together so you can review your current plan and track progress throughout the season.",
            Heading("What You Need to Know"),
            "Use the Gear Dashboard to:\n" .. List({
                "View equipped item level, upgrade tracks, and ranks by slot.",
                "Track progress toward your 4-piece Tier Set.",
                "Mark which of the five eligible Tier slots you have obtained.",
                "Identify dungeons with eligible armor for remaining Catalyst slots.",
                "View the Targets and Alternatives saved in Gear Targets.",
                "See the dungeon or raid source for each selected item.",
                "Track progress toward acquiring and equipping chosen gear.",
                "Identify relevant Hero and Myth track upgrade opportunities.",
            }) .. "\n\nOnly four of the five eligible Tier slots are required. After four are complete, KeyLab stops treating the fifth as a missing Tier requirement. The Dashboard receives its tracked-item information from Gear Targets.",
            Tip(),
            "After selecting Targets and Alternatives, use the Gear Dashboard as your progression guide.\n\nThe Dashboard does not choose your gear or determine Best in Slot. It organizes your goals, displays Tier and Catalyst progress, shows where selected items come from, and helps you follow your gearing progress as equipment changes.",
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

    local subtitle = Text(header, "Understand your major gearing decisions, then use KeyLab to plan the remaining slots around your goals.", "GameFontHighlightSmall", 12, COLORS.muted)
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
