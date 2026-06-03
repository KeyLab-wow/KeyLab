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

-- =========================================================
-- EASY EDIT SETTINGS
-- =========================================================

local COLORS = {
    bg       = {0.025, 0.035, 0.070, 0.96},
    panel    = {0.035, 0.055, 0.105, 0.94},
    box      = {0.030, 0.050, 0.095, 0.92},
    border   = {0.35, 0.55, 0.95, 0.55},
    divider  = {1.0, 1.0, 1.0, 0.13},
    gold     = {0.95, 0.76, 0.32, 1.0},
    text     = {0.88, 0.90, 0.96, 1.0},
    muted    = {0.62, 0.70, 0.82, 1.0},
    blue     = {0.38, 0.68, 1.0, 1.0},
    danger   = {1.0, 0.48, 0.38, 1.0},
}

local CONTENT_PAD = 24
local SECTION_GAP = 34
local ROW_GAP = 86

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

local function MakeDivider(parent, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y)
    line:SetPoint("RIGHT", parent, "RIGHT", -CONTENT_PAD, 0)
    line:SetHeight(1)
    line:SetColorTexture(unpack(COLORS.divider))
    return line
end

local function MakeSectionHeader(parent, title, y)
    local fs = MakeText(parent, title, "GameFontNormalLarge", nil, COLORS.gold, "LEFT")
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
    if StaticPopupDialogs["KEYLAB_CONFIRM_RESET"] then
        return
    end

    StaticPopupDialogs["KEYLAB_CONFIRM_RESET"] = {
        text = "Delete all saved KeyLab journal data for all characters?\n\nThis action cannot be undone.",
        button1 = YES,
        button2 = CANCEL,
        OnAccept = function()
            if KeyLab.DB and KeyLab.DB.ResetAll then
                KeyLab.DB.ResetAll()
            else
                KeyLabDB = {
                    version = KeyLab.version or "0.1.4",
                    trackingSince = date("%B %Y"),
                    settings = { completedMythicPlusOnly = true },
                    encounters = {},
                    builds = {},
                }
            end

            KeyLabCaptureDB = {
                version = KeyLab.version or "0.1.4",
                active = false,
                completedSeen = false,
                interrupted = false,
            }

            Print("Journal data has been reset.")

            if KeyLab.UI and KeyLab.UI.RefreshSelectedTab then
                KeyLab.UI:RefreshSelectedTab()
            elseif KeyLab.UI and KeyLab.UI.RefreshCurrentTab then
                KeyLab.UI.RefreshCurrentTab()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = STATICPOPUP_NUMDIALOGS,
    }
end

local function ExportJournalData()
    Print("Export system is not implemented yet.")
end

local function ImportJournalData()
    Print("Import system is not implemented yet.")
end

-- =========================================================
-- CONTENT BUILDERS
-- =========================================================

local function MakeDataAction(parent, y, title, description, buttonText, buttonColor, onClick)
    local titleText = MakeText(parent, title, "GameFontNormal", nil, COLORS.text, "LEFT")
    titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_PAD, y)
    titleText:SetPoint("RIGHT", parent, "RIGHT", -CONTENT_PAD, 0)
    titleText:SetHeight(18)

    local descColor = buttonColor == "danger" and COLORS.danger or COLORS.muted
    local body = MakeText(parent, description, "GameFontHighlightSmall", nil, descColor, "LEFT")
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
        "Exports saved KeyLab journal data for backup or transfer.",
        "Export Journal Data",
        nil,
        ExportJournalData
    )
    y = y - ROW_GAP

    MakeDataAction(
        content,
        y,
        "Import Journal Data",
        "Imports previously exported KeyLab journal data.",
        "Import Journal Data",
        nil,
        ImportJournalData
    )
    y = y - ROW_GAP

    MakeDataAction(
        content,
        y,
        "Delete / Reset Journal Data",
        "Permanently deletes saved KeyLab journal data for all characters. This action cannot be undone.",
        "Delete / Reset Data",
        "danger",
        function()
            StaticPopup_Show("KEYLAB_CONFIRM_RESET")
        end
    )
    y = y - ROW_GAP - SECTION_GAP

    MakeSectionHeader(content, "Credits", y)
    y = y - 52

    local purpose = MakeText(
        content,
        "KeyLab is a personal Mythic+ journal focused on real encounter outcomes, talent experimentation, stat priorities, and gameplay consistency.",
        "GameFontHighlightSmall",
        nil,
        COLORS.muted,
        "LEFT"
    )
    purpose:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PAD, y)
    purpose:SetWidth(840)
    purpose:SetHeight(34)
    y = y - 58

    local createdTitle = MakeText(content, "Created By", "GameFontNormal", nil, COLORS.gold, "LEFT")
    createdTitle:SetPoint("TOPLEFT", content, "TOPLEFT", CONTENT_PAD, y)
    createdTitle:SetWidth(240)

    local createdBody = MakeText(content, "Brione", "GameFontHighlightSmall", nil, COLORS.text, "LEFT")
    createdBody:SetPoint("TOPLEFT", createdTitle, "BOTTOMLEFT", 0, -8)
    createdBody:SetWidth(240)
    createdBody:SetHeight(42)

    local qaTitle = MakeText(content, "Special Quality Assurance Lead", "GameFontNormal", nil, COLORS.gold, "LEFT")
    qaTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 360, y)
    qaTitle:SetWidth(360)

    local qaBody = MakeText(
        content,
        "Blue\nChief Breakfast Inspector\nSenior Mashed Potato Consultant",
        "GameFontHighlightSmall",
        nil,
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

    local title = MakeText(frame, "Settings", "GameFontNormalLarge", nil, COLORS.gold, "LEFT")
    title:SetPoint("TOPLEFT", CONTENT_PAD, -22)
    title:SetSize(420, 30)

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -76)
    content:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    content:SetHeight(660)

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
