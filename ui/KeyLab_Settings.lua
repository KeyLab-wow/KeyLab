-- KeyLab_Settings.lua
-- Settings tab for KeyLab / M+ Journal
-- Purpose: backup guidance, protected reset controls, and credits.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local Settings = {}
KeyLab.Tabs.Settings = Settings
local Theme = KeyLab.UI.Theme or {}
local HEADER = Theme.tabHeader or { titleSize = 16, standardContentY = -86 }

-- =========================================================
-- EASY EDIT SETTINGS
-- =========================================================

local COLORS = {
    bg       = {0.018, 0.026, 0.056, 0.96},
    panel    = {0.026, 0.046, 0.086, 0.94},
    box      = {0.030, 0.052, 0.098, 0.92},
    border   = {0.240, 0.380, 0.620, 0.62},
    divider  = {0.440, 0.580, 0.780, 0.32},
    gold     = {0.820, 0.760, 0.580, 1.0},
    text     = {0.940, 0.960, 0.990, 1.0},
    muted    = {0.680, 0.730, 0.820, 1.0},
    blue     = {0.500, 0.680, 0.940, 1.0},
    danger   = {0.840, 0.440, 0.420, 1.0},
}

local CONTENT_PAD = 24
local SECTION_GAP = 34
local ROW_GAP = 86
local FONT_PAGE_TITLE = HEADER.titleSize
local FONT_SECTION_TITLE = 17
local FONT_ACTION_TITLE = 13
local FONT_BODY = 12
local FONT_BODY_SPACING = 2

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

    if fs.SetSpacing then
        fs:SetSpacing(FONT_BODY_SPACING)
    end

    fs:SetTextColor(unpack(color or COLORS.text))
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetText(text or "")
    return fs
end

local function MakeDivider(parent, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y)
    line:SetPoint("RIGHT", parent, "RIGHT", -CONTENT_PAD, 0)
    line:SetHeight(1)
    line:SetColorTexture(unpack(COLORS.divider))
    return line
end

local function MakeSectionHeader(parent, title, y)
    local fs = MakeText(parent, title, "GameFontNormalLarge", FONT_SECTION_TITLE, COLORS.gold, "LEFT")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y)
    fs:SetPoint("RIGHT", parent, "RIGHT", -CONTENT_PAD, 0)
    fs:SetHeight(24)

    MakeDivider(parent, y - 30)

    return fs
end

local function MakeButton(parent, label, x, y, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 220, 28)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

local function Print(message)
    if KeyLab.Utils and KeyLab.Utils.Print then
        KeyLab.Utils.Print(message)
    elseif KeyLab.Print then
        KeyLab.Print(message)
    else
        print("|cffd6b35aKeyLab:|r " .. tostring(message))
    end
end

-- =========================================================
-- POPUPS / ACTIONS
-- =========================================================

local function RegisterResetPopup()
    -- Reset confirmation is registered by KeyLab_JournalData.lua.
end

local function RegisterSeasonOnePopup()
    if not StaticPopupDialogs or StaticPopupDialogs.KEYLAB_ERASE_MN_S1 then return end
    StaticPopupDialogs.KEYLAB_ERASE_MN_S1 = {
        text = "Erase MN S1 Data?\n\n"
            .. "This removes MN S1 Mythic+ and Raid Data from:\n\n"
            .. "- Encounters\n"
            .. "- Stat Profiles\n"
            .. "- Talent Builds\n"
            .. "- Gear Profiles\n"
            .. "- Last Run\n"
            .. "- Last Raid\n"
            .. "- Trends\n"
            .. "- Practice\n"
            .. "- Saved Gear Targets\n"
            .. "- Alternatives\n"
            .. "- Goal Matches\n\n"
            .. "This can not be undone.",
        button1 = "Erase MN S1 Data",
        button2 = "Cancel",
        OnAccept = function()
            if not (KeyLab.SeasonData and KeyLab.SeasonData.EraseSeason1) then
                Print("Season data tools are not available.")
                return
            end
            local report = KeyLab.SeasonData.EraseSeason1()
            local total = 0
            for _, count in pairs(report or {}) do total = total + (tonumber(count) or 0) end
            Print(string.format("Midnight Season 1 data erased: %d saved record%s removed. Macro Sequences were not changed.", total, total == 1 and "" or "s"))
            if KeyLab.RefreshTabs then KeyLab.RefreshTabs() end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

-- =========================================================
-- CONTENT BUILDERS
-- =========================================================

local function MakeDataAction(parent, y, title, description, buttonText, buttonColor, onClick)
    local titleText = MakeText(parent, title, "GameFontNormal", FONT_ACTION_TITLE, COLORS.text, "LEFT")
    titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y)
    titleText:SetPoint("RIGHT", parent, "RIGHT", -CONTENT_PAD, 0)
    titleText:SetHeight(18)

    local descColor = buttonColor == "danger" and COLORS.danger or COLORS.muted
    local body = MakeText(parent, description, "GameFontHighlightSmall", FONT_BODY, descColor, "LEFT")
    body:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -6)
    body:SetWidth(560)
    body:SetHeight(40)

    local button = Theme.CreateButton and Theme.CreateButton(parent, buttonText, 210, 28)
        or MakeButton(parent, buttonText, 640, y + 2, 210, onClick)
    if Theme.CreateButton then
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 640, y + 2)
        button:SetScript("OnClick", onClick)
    end
end

local function MakeBackupInstructions(parent, y)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y)
    card:SetSize(862, 184)
    SetBackdrop(card, COLORS.box, COLORS.border)

    local title = MakeText(
        card,
        "Moving to a New Computer or Reinstalling Windows",
        "GameFontNormal",
        FONT_ACTION_TITLE,
        COLORS.gold,
        "LEFT"
    )
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -12)
    title:SetPoint("RIGHT", card, "RIGHT", -14, 0)
    title:SetHeight(18)

    local body = MakeText(
        card,
        "KeyLab keeps its data in WoW's SavedVariables folder.\n\n"
        .. "1. Close World of Warcraft completely.\n"
        .. "2. Open World of Warcraft\\_retail_\\WTF\\Account\\<Your Account>\\SavedVariables.\n"
        .. "3. Copy KeyLab.lua and, if present, KeyLab.lua.bak somewhere safe.\n"
        .. "4. With WoW closed on the new installation, place the copied file(s) back in that same folder before starting the game.\n\n"
        .. "This keeps your journal, gear plans, Practice sessions, settings, and personal Macro Sequences. KeyLab does not import backup text inside the addon.",
        "GameFontHighlightSmall",
        FONT_BODY,
        COLORS.text,
        "LEFT"
    )
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    body:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -14, 12)
end

local function BuildWindowSettings(parent, y)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y)
    card:SetSize(862, 104)
    SetBackdrop(card, COLORS.box, COLORS.border)

    local check = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -13)
    check:SetSize(24, 24)

    local label = MakeText(
        card,
        "Automatically Minimize for WoW Windows",
        "GameFontNormal",
        FONT_ACTION_TITLE,
        COLORS.text,
        "LEFT"
    )
    label:SetPoint("LEFT", check, "RIGHT", 5, 0)
    label:SetSize(500, 22)

    local description = MakeText(
        card,
        "When a regular WoW window opens, KeyLab switches to its menu-only view. KeyLab helper and results popups stay visible.",
        "GameFontHighlightSmall",
        FONT_BODY,
        COLORS.muted,
        "LEFT"
    )
    description:SetPoint("TOPLEFT", card, "TOPLEFT", 17, -48)
    description:SetSize(820, 42)

    local function RefreshControl()
        local enabled = true
        if KeyLab.DB and KeyLab.DB.GetSetting then
            enabled = KeyLab.DB.GetSetting("autoMinimizeForBlizzardPanels", true) ~= false
        end
        check:SetChecked(enabled)
    end

    check:SetScript("OnClick", function(button)
        if KeyLab.DB and KeyLab.DB.SetSetting then
            KeyLab.DB.SetSetting("autoMinimizeForBlizzardPanels", button:GetChecked() == true)
        end
        RefreshControl()
    end)

    RefreshControl()
    return RefreshControl
end

local function BuildGroupFinderSettings(parent, y)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y)
    card:SetSize(862, 104)
    SetBackdrop(card, COLORS.box, COLORS.border)

    local check = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -13)
    check:SetSize(24, 24)

    local label = MakeText(
        card,
        "Automatically Show Group Finder Helper",
        "GameFontNormal",
        FONT_ACTION_TITLE,
        COLORS.text,
        "LEFT"
    )
    label:SetPoint("LEFT", check, "RIGHT", 5, 0)
    label:SetSize(430, 22)

    local description = MakeText(
        card,
        "Show your saved gear shopping list while browsing Premade Group dungeons and raids. If you close it, it stays closed until you leave Group Finder.",
        "GameFontHighlightSmall",
        FONT_BODY,
        COLORS.muted,
        "LEFT"
    )
    description:SetPoint("TOPLEFT", card, "TOPLEFT", 17, -48)
    description:SetSize(590, 42)

    local openButton = MakeButton(card, "Open Group Finder Helper", 635, -39, 205, function()
        if not (KeyLab.LFGTooltips and KeyLab.LFGTooltips.OpenManual
            and KeyLab.LFGTooltips.OpenManual()) then
            Print("Group Finder Helper is not available yet.")
        end
    end)

    local function RefreshControl()
        local enabled = true
        if KeyLab.LFGTooltips and KeyLab.LFGTooltips.IsAutoShowEnabled then
            enabled = KeyLab.LFGTooltips.IsAutoShowEnabled()
        elseif KeyLab.DB and KeyLab.DB.GetSetting then
            enabled = KeyLab.DB.GetSetting("autoShowGroupFinderHelper", true) ~= false
        end
        check:SetChecked(enabled)
        if enabled then openButton:Hide() else openButton:Show() end
    end

    check:SetScript("OnClick", function(button)
        local enabled = button:GetChecked() == true
        if KeyLab.LFGTooltips and KeyLab.LFGTooltips.SetAutoShowEnabled then
            KeyLab.LFGTooltips.SetAutoShowEnabled(enabled)
        elseif KeyLab.DB and KeyLab.DB.SetSetting then
            KeyLab.DB.SetSetting("autoShowGroupFinderHelper", enabled)
        end
        RefreshControl()
    end)

    RefreshControl()
    return RefreshControl
end

local function BuildSettings(content)
    local y = -6

    MakeSectionHeader(content, "Window Behavior", y)
    y = y - 50

    local refreshWindow = BuildWindowSettings(content, y)
    y = y - 104 - SECTION_GAP

    MakeSectionHeader(content, "Group Finder Helper", y)
    y = y - 50

    local refreshGroupFinder = BuildGroupFinderSettings(content, y)
    y = y - 104 - SECTION_GAP

    MakeSectionHeader(content, "Back Up or Move KeyLab", y)
    y = y - 50

    MakeBackupInstructions(content, y)
    y = y - 204

    MakeSectionHeader(content, "Season Data", y)
    y = y - 50

    MakeDataAction(
        content,
        y,
        "Erase Midnight Season 1 Player Data",
        "Deletes MN S1 encounters, raid pulls/nights, derived profiles and trends, Practice sessions, saved matcher results, and all MN S1 Targets, Alternatives, and pending target choices. Macro Sequences and MN S2 data are preserved.",
        "Erase MN S1 Data",
        "danger",
        function()
            RegisterSeasonOnePopup()
            if StaticPopup_Show then StaticPopup_Show("KEYLAB_ERASE_MN_S1") end
        end
    )
    y = y - ROW_GAP - SECTION_GAP

    MakeDataAction(
        content,
        y,
        "Reset KeyLab",
        "Permanently delete all KeyLab data, including Macro Sequences, bindings, and the Recycle Bin. This cannot be undone.",
        "Reset All KeyLab Data",
        "danger",
        function()
            if KeyLab.ShowResetJournalDataConfirmation then
                KeyLab:ShowResetJournalDataConfirmation()
            else
                Print("Reset system is not available.")
            end
        end
    )
    y = y - ROW_GAP - SECTION_GAP

    MakeSectionHeader(content, "Credits", y)
    y = y - 52

    local purpose = MakeText(
        content,
        "KeyLab brings Mythic+, raids, practice tests, build comparisons, gear planning, and Macro Sequences together in one personal journal.",
        "GameFontHighlightSmall",
        FONT_BODY,
        COLORS.muted,
        "LEFT"
    )
    purpose:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PAD, y)
    purpose:SetWidth(840)
    purpose:SetHeight(34)
    y = y - 58

    local createdTitle = MakeText(content, "Created By", "GameFontNormal", FONT_ACTION_TITLE, COLORS.gold, "LEFT")
    createdTitle:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PAD, y)
    createdTitle:SetWidth(240)

    local createdBody = MakeText(content, "Brione - KeyLabwow", "GameFontHighlightSmall", FONT_BODY, COLORS.text, "LEFT")
    createdBody:SetPoint("TOPLEFT", createdTitle, "BOTTOMLEFT", 0, -8)
    createdBody:SetWidth(240)
    createdBody:SetHeight(42)

    local qaTitle = MakeText(content, "Special Quality Assurance Lead", "GameFontNormal", FONT_ACTION_TITLE, COLORS.gold, "LEFT")
    qaTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 360, y)
    qaTitle:SetWidth(360)

    local qaBody = MakeText(
        content,
        "Blue\nChief Breakfast Inspector\nSenior Mashed Potato Consultant",
        "GameFontHighlightSmall",
        FONT_BODY,
        COLORS.text,
        "LEFT"
    )
    qaBody:SetPoint("TOPLEFT", qaTitle, "BOTTOMLEFT", 0, -8)
    qaBody:SetWidth(420)
    qaBody:SetHeight(62)

    y = y - 104

    content:SetHeight(math.abs(y) + 40)
    return function()
        if refreshWindow then refreshWindow() end
        if refreshGroupFinder then refreshGroupFinder() end
    end
end

-- =========================================================
-- CREATE TAB
-- =========================================================

function Settings:Create(parent)
    RegisterResetPopup()
    RegisterSeasonOnePopup()

    local frame = CreateFrame("Frame", "KeyLabSettingsTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})

    Theme.CreateTabHeader(
        frame,
        "Settings",
        "Choose KeyLab options, find backup instructions, or reset your saved data."
    )

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, HEADER.standardContentY)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 14)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(910)
    content:SetHeight(660)
    scroll:SetScrollChild(content)

    local refreshSettings = BuildSettings(content)

    function frame:Refresh()
        if refreshSettings then refreshSettings() end
    end

    return frame
end

function KeyLab_CreateSettingsTab(parent)
    return Settings:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Settings", function(parent)
        return Settings:Create(parent)
    end)
end

return Settings
