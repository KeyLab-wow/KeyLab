-- KeyLab_Settings.lua
-- Settings tab for KeyLab / M+ Journal
-- Purpose: simple local journal data controls and credits.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local Settings = {}
KeyLab.Tabs.Settings = Settings
local HEADER = KeyLab.UI.Theme and KeyLab.UI.Theme.tabHeader or { titleSize = 16 }

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

local function ExportJournalData()
    if KeyLab.ShowExportPopup then
        KeyLab:ShowExportPopup()
    else
        Print("Export system is not available.")
    end
end

local function ImportJournalData()
    if KeyLab.ShowImportPopup then
        KeyLab:ShowImportPopup()
    else
        Print("Import system is not available.")
    end
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

    MakeButton(parent, buttonText, 640, y + 2, 210, onClick)
end

local function BuildSettings(content)
    local y = -6

    MakeSectionHeader(content, "Data Management", y)
    y = y - 50

    MakeDataAction(
        content,
        y,
        "Export Journal Data",
        "Copy your saved KeyLab data for backup or transfer.",
        "Export Journal Data",
        nil,
        ExportJournalData
    )
    y = y - ROW_GAP

    MakeDataAction(
        content,
        y,
        "Import Journal Data",
        "Load KeyLab data that you exported earlier.",
        "Import Journal Data",
        nil,
        ImportJournalData
    )
    y = y - ROW_GAP

    MakeDataAction(
        content,
        y,
        "Delete / Reset Journal Data",
        "Permanently delete all saved KeyLab data for every character. This cannot be undone.",
        "Delete / Reset Data",
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

    local createdBody = MakeText(content, "Brione", "GameFontHighlightSmall", FONT_BODY, COLORS.text, "LEFT")
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
end

-- =========================================================
-- CREATE TAB
-- =========================================================

function Settings:Create(parent)
    RegisterResetPopup()

    local frame = CreateFrame("Frame", "KeyLabSettingsTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})

    local title = MakeText(frame, "Settings", "GameFontNormalLarge", FONT_PAGE_TITLE, COLORS.gold, "LEFT")
    title:SetPoint("TOPLEFT", CONTENT_PAD, -22)
    title:SetSize(420, 30)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -68)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 14)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(910)
    content:SetHeight(660)
    scroll:SetScrollChild(content)

    BuildSettings(content)

    function frame:Refresh()
        -- Placeholder for future settings refresh if needed.
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
