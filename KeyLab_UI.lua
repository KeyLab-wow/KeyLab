-- KeyLab_UI.lua
-- Main UI shell for KeyLab's shared Mythic+ and Raid journal.
--
-- Purpose:
--   Owns the main addon window, sidebar navigation, and tab switching.
--
-- Current UI direction:
--   Main-window artwork provides the shared visual foundation.
--   Colored panels, borders, and live text remain above the artwork for clarity.
--
-- Individual tab files own their own content inside the content frame.

local ADDON_NAME, KeyLab = ...

KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.RegisteredTabs = KeyLab.RegisteredTabs or {}

local Theme = KeyLab.UI.Theme or {}

-- =========================================================
-- EASY EDIT SETTINGS
-- Adjust layout/colors here first.
-- =========================================================

local CFG = {
    main = {
        width = 1200,
        height = 980,
        point = "CENTER",
        x = 0,
        y = 0,
    },

    menuOnly = {
        width = 228,
        bottomPadding = 22,
        automaticX = -210,
        automaticY = -190,
        helperButtonHeight = 30,
        helperButtonGap = 8,
        helperTopGap = 8,
    },

    close = {
        x = -22,
        y = -20,
        width = 28,
        height = 28,
    },

    sidebar = {
        x = 22,
        y = -128,
        width = 176,
        buttonHeight = 36,
        buttonGap = 8,
        modeHeight = 30,
        paddingTop = 12,
        paddingBottom = 12,
    },

    content = {
        x = 212,
        y = -112,
        width = 960,
        height = 820,
    },

    colors = Theme.colors or {
        windowBg = {0.018, 0.026, 0.056, 0.98},
        windowBorder = {0.240, 0.380, 0.620, 0.62},
        headerBg = {0.020, 0.034, 0.066, 0.64},
        headerBorder = {0.240, 0.380, 0.620, 0.58},
        sidebarBg = {0.016, 0.026, 0.052, 0.90},
        sidebarBorder = {0.220, 0.340, 0.560, 0.55},
        contentBg = {0.012, 0.020, 0.044, 0.86},
        contentBorder = {0.200, 0.320, 0.520, 0.46},
        buttonBg = {0.022, 0.038, 0.076, 0.82},
        buttonBorder = {0.220, 0.340, 0.560, 0.58},
        buttonHover = {0.300, 0.420, 0.600, 0.78},
        buttonSelected = {0.820, 0.760, 0.580, 1.0},
        buttonSelectedBg = {0.030, 0.050, 0.086, 0.95},
        gold = {0.820, 0.760, 0.580, 1.0},
        text = {0.940, 0.960, 0.990, 1.0},
        muted = {0.680, 0.730, 0.820, 1.0},
    },

    tabs = {
        "Home",
        "Performance",
        "Profiles",
        "Gear",
        "Guide Lists",
        "Group Dashboard",
        "Sequencer",
        "Settings",
    },
}

local ANALYSIS_ROUTES = {
    ["Encounters"] = { mplus = "M+ Encounters", raid = "Raid Encounters" },
    ["Summary"] = { mplus = "M+ Last Run", raid = "Raid Summary" },
    ["Talent Builds"] = { mplus = "M+ Talent Builds", raid = "Raid Talent Builds" },
    ["Stat Profiles"] = { mplus = "M+ Stat Profiles", raid = "Raid Stat Profiles" },
    ["Gear Profiles"] = { mplus = "M+ Gear Profiles", raid = "Raid Gear Profiles" },
    ["Trends"] = { mplus = "M+ Trends", raid = "Raid Trends" },
}

-- These destinations keep every existing tab implementation intact while the
-- sidebar presents related pages together. Gear Planning remains the owner of
-- its established views; the virtual destinations only choose which one opens.
local VIRTUAL_ROUTES = {
    ["Gear Guide"] = { tab = "Gear Planning", view = "guide" },
    ["Crafted Gear"] = { tab = "Gear Planning", view = "crafted" },
    ["Season 2 Info"] = { tab = "Gear Planning", view = "season2Info" },
    ["Wowhead Guide Lists"] = { tab = "Gear Planning", view = "WH" },
    ["Icy Veins Guide Lists"] = { tab = "Gear Planning", view = "IV" },
}

local NAVIGATION_SECTIONS = {
    { id = "Home", default = "Home" },
    {
        id = "Performance", default = "Summary",
        items = {
            { destination = "Summary" },
            { destination = "Encounters" },
            { destination = "Trends" },
            { destination = "Practice" },
            { destination = "Insights" },
        },
    },
    {
        id = "Profiles", default = "Winning Setups",
        items = {
            { destination = "Winning Setups" },
            { destination = "Talent Builds" },
            { destination = "Stat Profiles" },
            { destination = "Gear Profiles" },
        },
    },
    {
        id = "Gear", default = "Gear Dashboard",
        items = {
            { destination = "Gear Dashboard" },
            { destination = "Gear Targets" },
            { destination = "Crafted Gear" },
            { destination = "Season 2 Info" },
            { destination = "Gear Guide" },
        },
    },
    {
        id = "Guide Lists", default = "Wowhead Guide Lists",
        items = {
            { destination = "Wowhead Guide Lists", label = "Wowhead" },
            { destination = "Icy Veins Guide Lists", label = "Icy Veins" },
        },
    },
    { id = "Group Dashboard", default = "Group Dashboard" },
    { id = "Sequencer", default = "Sequencer" },
    { id = "Settings", default = "Settings" },
}

local function GetNavigationLabel(category, mode)
    if category == "Summary" then
        return mode == "raid" and "Last Raid" or "Last Run"
    end
    if category == "Sequencer" then
        return "Macro Sequencer"
    end
    return category
end

-- =========================================================
-- SMALL UI HELPERS
-- =========================================================

local function ApplyColor(fs, color)
    if not fs or not color then return end

    if Theme.ApplyColor then
        Theme.ApplyColor(fs, color)
        return
    end

    fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function StylePanel(frame, bg, border)
    if not frame then return end

    if Theme.StylePanel then
        Theme.StylePanel(frame, bg, border)
        return
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })

    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function SafePrint(message)
    if KeyLab.Utils and KeyLab.Utils.Print then
        KeyLab.Utils.Print(message)
    elseif KeyLab.Print then
        KeyLab.Print(message)
    else
        print("|cffd6b35aKeyLab:|r " .. tostring(message))
    end
end

-- KeyLab's compact helper windows share the Preparation Panel anchor so they
-- always open in the same predictable place. The minimized PREP PANEL handle
-- deliberately keeps its own independent saved position.
function KeyLab.UI:AnchorPopupToPreparationPanel(frame)
    if not frame then return end

    local point, relativePoint, x, y
    local dashboard = KeyLab.GroupQuickUI
    if dashboard and dashboard.snapshot and dashboard.snapshot.GetPoint then
        point, _, relativePoint, x, y = dashboard.snapshot:GetPoint(1)
    end

    if not point then
        local positions = KeyLabDB and KeyLabDB.groupDashboardUI
            and KeyLabDB.groupDashboardUI.floatingPositions
        local saved = type(positions) == "table" and positions.snapshot or nil
        if type(saved) == "table" and type(saved.point) == "string" then
            point = saved.point
            relativePoint = saved.relativePoint or saved.point
            x = tonumber(saved.x) or 0
            y = tonumber(saved.y) or 0
        end
    end

    frame:ClearAllPoints()
    frame:SetPoint(point or "RIGHT", UIParent, relativePoint or point or "RIGHT", x or -24, y or 0)
end

local function FindRegisteredTab(name)
    for _, tab in ipairs(KeyLab.RegisteredTabs or {}) do
        if tab.name == name then
            return tab
        end
    end

    return nil
end

local function NormalizeContentMode(mode)
    return mode == "raid" and "raid" or "mplus"
end

local function GetSavedContentMode()
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.settings = type(KeyLabDB.settings) == "table" and KeyLabDB.settings or {}
    KeyLabDB.settings.contentMode = NormalizeContentMode(KeyLabDB.settings.contentMode)
    return KeyLabDB.settings.contentMode
end

local function SaveContentMode(mode)
    mode = NormalizeContentMode(mode)
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.settings = type(KeyLabDB.settings) == "table" and KeyLabDB.settings or {}
    KeyLabDB.settings.contentMode = mode
    return mode
end

local function IsAutoMenuOnlyEnabled()
    if KeyLab.DB and KeyLab.DB.GetSetting then
        return KeyLab.DB.GetSetting("autoMinimizeForBlizzardPanels", true) ~= false
    end
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.settings = type(KeyLabDB.settings) == "table" and KeyLabDB.settings or {}
    return KeyLabDB.settings.autoMinimizeForBlizzardPanels ~= false
end

local function GetAnalysisRoute(tabName)
    if ANALYSIS_ROUTES[tabName] then return tabName, nil end
    for category, routes in pairs(ANALYSIS_ROUTES) do
        if routes.mplus == tabName then return category, "mplus" end
        if routes.raid == tabName then return category, "raid" end
    end
    return nil, nil
end

local function ResolveNavigationTab(tabName, mode)
    local route = ANALYSIS_ROUTES[tabName]
    return route and route[NormalizeContentMode(mode)] or tabName
end

local function GetNavigationKey(tabName)
    local category = GetAnalysisRoute(tabName)
    if category == "Summary" or category == "Encounters" or category == "Trends" then return "Performance" end
    if category == "Talent Builds" or category == "Stat Profiles" or category == "Gear Profiles" then return "Profiles" end
    if tabName == "Practice" or tabName == "Insights" then return "Performance" end
    if tabName == "Winning Setups" then return "Profiles" end
    if tabName == "Gear Dashboard" or tabName == "Gear Targets" or tabName == "Gear Planning" then
        local view = KeyLab.Tabs and KeyLab.Tabs.GearPlanning and KeyLab.Tabs.GearPlanning.selectedView
        if tabName == "Gear Planning" and (view == "WH" or view == "IV") then return "Guide Lists" end
        return "Gear"
    end
    return tabName
end

local function GetVisibleNavigationTabs()
    local tabs = {}
    for _, tabName in ipairs(CFG.tabs or {}) do table.insert(tabs, tabName) end
    return tabs
end

local function GetNavigationSection(sectionID)
    for _, section in ipairs(NAVIGATION_SECTIONS) do
        if section.id == sectionID then return section end
    end
end

local function DestinationLabel(destination, mode)
    if VIRTUAL_ROUTES[destination] then
        if destination == "Wowhead Guide Lists" then return "Wowhead" end
        if destination == "Icy Veins Guide Lists" then return "Icy Veins" end
        return destination
    end
    return GetNavigationLabel(destination, mode)
end

local function GetTabObjectKey(tabName)
    local aliases = {
        ["M+ Encounters"] = "Encounters",
        ["M+ Last Run"] = "LastRun",
        ["Raid Summary"] = "RaidSummary",
        ["M+ Talent Builds"] = "TalentBuilds",
        ["M+ Stat Profiles"] = "StatProfiles",
        ["M+ Gear Profiles"] = "GearProfiles",
        ["M+ Trends"] = "Trends",
    }
    if aliases[tabName] then return aliases[tabName] end
    return tostring(tabName or ""):gsub("%s+", ""):gsub("%-", "")
end

-- =========================================================
-- TAB REGISTRATION
-- =========================================================

function KeyLab.RegisterTab(name, createFunc)
    if not name or type(createFunc) ~= "function" then
        return
    end

    KeyLab.RegisteredTabs = KeyLab.RegisteredTabs or {}

    for _, tab in ipairs(KeyLab.RegisteredTabs) do
        if tab.name == name then
            tab.createFunc = createFunc
            return
        end
    end

    table.insert(KeyLab.RegisteredTabs, {
        name = name,
        createFunc = createFunc,
    })
end

-- =========================================================
-- MAIN UI
-- =========================================================

function KeyLab.UI:Create()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", "KeyLabMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(CFG.main.width, CFG.main.height)
    frame:SetPoint(CFG.main.point, UIParent, CFG.main.point, CFG.main.x, CFG.main.y)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:Hide()

    StylePanel(frame, CFG.colors.windowBg, CFG.colors.windowBorder)

    self.frame = frame
    frame:SetScript("OnShow", function()
        if KeyLab.GroupQuickUI and KeyLab.GroupQuickUI.HidePreparationForMain then
            KeyLab.GroupQuickUI:HidePreparationForMain()
        end
    end)
    frame:SetScript("OnHide", function()
        if KeyLab.GroupQuickUI and KeyLab.GroupQuickUI.HandleFloatingRefresh then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.05, function() KeyLab.GroupQuickUI:HandleFloatingRefresh("main window closed") end)
            else
                KeyLab.GroupQuickUI:HandleFloatingRefresh("main window closed")
            end
        end
    end)
    self.contentMode = GetSavedContentMode()
    self.navigationTabs = GetVisibleNavigationTabs()

    -- Presentation-only artwork. The source texture uses a WoW-safe
    -- 2048 x 1024 canvas with the 1200 x 980 window art in its visible region.
    local backgroundArtwork = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    backgroundArtwork:SetAllPoints(frame)
    backgroundArtwork:SetTexture("Interface\\AddOns\\KeyLab\\Assets\\KeyLabWindowBackground.tga")
    backgroundArtwork:SetTexCoord(0, CFG.main.width / 2048, 0, CFG.main.height / 1024)
    backgroundArtwork:SetAlpha(1)
    self.backgroundArtwork = backgroundArtwork

    -- Header background with the KeyLab logo.
    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -14)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -14)
    header:SetHeight(78)
    StylePanel(header, CFG.colors.headerBg, CFG.colors.headerBorder)
    self.header = header

    local titleIcon = header:CreateTexture(nil, "ARTWORK", nil, 1)
    titleIcon:SetTexture("Interface\\AddOns\\KeyLab\\Assets\\KeyLabKeyIcon.tga")
    titleIcon:SetTexCoord(0, 1, 1, 0)
    titleIcon:SetSize(58, 58)
    titleIcon:SetPoint("LEFT", header, "LEFT", 14, 0)
    self.titleIcon = titleIcon

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetSize(CFG.close.width, CFG.close.height)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", CFG.close.x, CFG.close.y)
    close:SetScript("OnClick", function()
        if GetNavigationKey(KeyLab.UI.selectedTab) == "Sequencer" and KeyLab.Tabs and KeyLab.Tabs.Sequencer
            and KeyLab.Tabs.Sequencer.RequestLeave then
            local allowed = KeyLab.Tabs.Sequencer:RequestLeave(function() frame:Hide() end)
            if not allowed then return end
        end
        frame:Hide()
    end)
    self.closeButton = close

    local menuOnlyButton = CreateFrame("Button", nil, frame, "BackdropTemplate")
    menuOnlyButton:SetSize(92, 30)
    menuOnlyButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -60, -38)
    StylePanel(menuOnlyButton, CFG.colors.buttonBg, CFG.colors.gold)

    local menuOnlyLabel = menuOnlyButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    menuOnlyLabel:SetPoint("CENTER")
    menuOnlyLabel:SetText("Minimize")
    ApplyColor(menuOnlyLabel, CFG.colors.gold)
    menuOnlyButton.label = menuOnlyLabel

    menuOnlyButton:SetScript("OnClick", function()
        KeyLab.UI:SetMenuOnly(not KeyLab.UI.isMenuOnly)
    end)
    menuOnlyButton:SetScript("OnEnter", function(button)
        button:SetBackdropBorderColor(unpack(CFG.colors.buttonHover))
        GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
        GameTooltip:SetText(KeyLab.UI.isMenuOnly and "Open KeyLab" or "Show Menu Only")
        GameTooltip:Show()
    end)
    menuOnlyButton:SetScript("OnLeave", function(button)
        button:SetBackdropBorderColor(unpack(CFG.colors.gold))
        GameTooltip:Hide()
    end)
    self.menuOnlyButton = menuOnlyButton

    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.sidebar.x - 8, CFG.content.y)

    local tabCount = #(self.navigationTabs or {})
    local sidebarHeight =
        (CFG.sidebar.paddingTop or 12)
        + (tabCount * CFG.sidebar.buttonHeight)
        + (math.max(0, tabCount - 1) * CFG.sidebar.buttonGap)
        + (CFG.sidebar.modeHeight or 30)
        + CFG.sidebar.buttonGap
        + (CFG.sidebar.paddingBottom or 12)
    local helperHeight = (CFG.menuOnly.helperTopGap or 8)
        + (2 * (CFG.menuOnly.helperButtonHeight or 30))
        + (CFG.menuOnly.helperButtonGap or 8)

    sidebar:SetSize(CFG.sidebar.width + 16, sidebarHeight)
    StylePanel(sidebar, CFG.colors.sidebarBg, CFG.colors.sidebarBorder)
    self.sidebar = sidebar
    self.standardSidebarHeight = sidebarHeight
    self.menuOnlySidebarHeight = sidebarHeight + helperHeight
    self.menuOnlyHeight = math.max(400,
        -CFG.sidebar.y + self.menuOnlySidebarHeight + (CFG.menuOnly.bottomPadding or 22))

    local content = CreateFrame("Frame", "KeyLabContentFrame", frame, "BackdropTemplate")
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.content.x, CFG.content.y)
    content:SetSize(CFG.content.width, CFG.content.height)
    StylePanel(content, CFG.colors.contentBg, CFG.colors.contentBorder)
    content:SetFrameLevel(frame:GetFrameLevel() + 5)
    self.content = content

    self.tabFrames = {}
    self.tabButtons = {}

    local helperY = self:CreateTabButtons()
    self:CreateMenuOnlyHelperButtons(helperY - (CFG.menuOnly.helperTopGap or 8))

    if not self.sequencerCombatEvents then
        local combatEvents = CreateFrame("Frame")
        combatEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
        combatEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
        combatEvents:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_REGEN_DISABLED" then
                if KeyLab.UI.frame then KeyLab.UI.frame:Hide() end
                if KeyLab.GroupQuickUI and KeyLab.GroupQuickUI.HideFloatingForCombat then
                    KeyLab.GroupQuickUI:HideFloatingForCombat()
                end
                if type(StaticPopup_Hide) == "function" then
                    for key in pairs(StaticPopupDialogs or {}) do
                        if tostring(key):match("^KEYLAB_") then StaticPopup_Hide(key) end
                    end
                end
            else
                if KeyLab.UI.isMenuOnly then KeyLab.UI:SetMenuOnly(false) end
                if KeyLab.GroupQuickUI and KeyLab.GroupQuickUI.HandleFloatingRefresh then
                    KeyLab.GroupQuickUI:HandleFloatingRefresh("combat ended")
                end
            end
            KeyLab.UI:RefreshSequencerNavigationState()
        end)
        self.sequencerCombatEvents = combatEvents
    end

    self:InstallAutoMenuOnlyHook()
    self:SelectTab("Home")

    return frame
end

function KeyLab.UI:SetMenuOnly(enabled)
    if InCombatLockdown and InCombatLockdown() then
        if self.frame then self.frame:Hide() end
        return
    end
    self:Create()
    enabled = enabled == true
    if enabled and KeyLab.GroupQuickUI and KeyLab.GroupQuickUI.OpenPreparationPanel then
        self.isMenuOnly = true
        self.frame:Hide()
        KeyLab.GroupQuickUI:OpenPreparationPanel()
        return
    end
    if self.isMenuOnly == enabled then return end

    self.isMenuOnly = enabled

    if enabled then
        self.frame:SetSize(CFG.menuOnly.width, self.menuOnlyHeight or CFG.main.height)
        self.frame:ClearAllPoints()
        self.frame:SetPoint(
            "TOPRIGHT",
            UIParent,
            "TOPRIGHT",
            CFG.menuOnly.automaticX or -210,
            CFG.menuOnly.automaticY or -190
        )
        self.content:Hide()
        self.titleIcon:Show()
        if self.sidebar then self.sidebar:SetHeight(self.menuOnlySidebarHeight or self.standardSidebarHeight) end
        for _, button in ipairs(self.menuOnlyHelperButtons or {}) do button:Show() end

        self.closeButton:ClearAllPoints()
        self.closeButton:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -10, -20)

        self.menuOnlyButton:ClearAllPoints()
        self.menuOnlyButton:SetSize(52, 30)
        self.menuOnlyButton:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -44, -38)
        self.menuOnlyButton.label:SetText("Open")

        if self.backgroundArtwork then
            self.backgroundArtwork:SetTexCoord(0, CFG.menuOnly.width / 2048, 0, (self.menuOnlyHeight or CFG.main.height) / 1024)
        end
        return
    end

    self.frame:SetSize(CFG.main.width, CFG.main.height)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self.titleIcon:Show()
    if self.sidebar then self.sidebar:SetHeight(self.standardSidebarHeight or self.sidebar:GetHeight()) end
    for _, button in ipairs(self.menuOnlyHelperButtons or {}) do button:Hide() end

    self.closeButton:ClearAllPoints()
    self.closeButton:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", CFG.close.x, CFG.close.y)

    self.menuOnlyButton:ClearAllPoints()
    self.menuOnlyButton:SetSize(92, 30)
    self.menuOnlyButton:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -60, -38)
    self.menuOnlyButton.label:SetText("Minimize")

    if self.backgroundArtwork then
        self.backgroundArtwork:SetTexCoord(0, CFG.main.width / 2048, 0, CFG.main.height / 1024)
    end
    self.content:Show()
    if self.selectedTab and self.tabFrames and self.tabFrames[self.selectedTab] then
        self.tabFrames[self.selectedTab]:Show()
    end
end

function KeyLab.UI:InstallAutoMenuOnlyHook()
    if self.autoMenuOnlyHookInstalled then return end
    if type(hooksecurefunc) ~= "function" or type(ShowUIPanel) ~= "function" then return end

    hooksecurefunc("ShowUIPanel", function()
        local ui = KeyLab.UI
        if not (ui and ui.frame and ui.frame:IsShown()) then return end
        if ui.isMenuOnly or not IsAutoMenuOnlyEnabled() then return end
        ui:SetMenuOnly(true)
    end)
    self.autoMenuOnlyHookInstalled = true
end

function KeyLab.UI:RefreshContentModeSelector()
    local selected = NormalizeContentMode(self.contentMode or GetSavedContentMode())
    for mode, button in pairs(self.modeButtons or {}) do
        local active = mode == selected
        local bg = active and (CFG.colors.buttonSelectedBg or CFG.colors.buttonBg) or CFG.colors.buttonBg
        local border = active and CFG.colors.buttonSelected or CFG.colors.buttonBorder
        button:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
        button:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
        ApplyColor(button.label, active and CFG.colors.gold or CFG.colors.text)
    end
    for _, entries in pairs(self.navigationChildButtons or {}) do
        for _, entry in ipairs(entries) do
            if entry.button and entry.button.label then
                entry.button.label:SetText(entry.label or DestinationLabel(entry.destination, selected))
            end
        end
    end
    self:RefreshNavigationButtons()
end

function KeyLab.UI:CreateContentModeSelector(y)
    local row = CreateFrame("Frame", nil, self.frame)
    row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.sidebar.x, y)
    row:SetSize(CFG.sidebar.width, CFG.sidebar.modeHeight or 30)
    self.modeSelector = row
    self.modeButtons = {}

    local gap = 6
    local width = (CFG.sidebar.width - gap) / 2
    for index, definition in ipairs({
        { mode = "mplus", label = "Mythic+" },
        { mode = "raid", label = "Raid" },
    }) do
        local mode = definition.mode
        local button = CreateFrame("Button", nil, row, "BackdropTemplate")
        button:SetPoint("TOPLEFT", row, "TOPLEFT", (index - 1) * (width + gap), 0)
        button:SetSize(width, CFG.sidebar.modeHeight or 30)
        StylePanel(button, CFG.colors.buttonBg, CFG.colors.buttonBorder)

        local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("CENTER")
        label:SetText(definition.label)
        ApplyColor(label, CFG.colors.text)
        button.label = label

        button:SetScript("OnClick", function()
            if KeyLab.UI.isMenuOnly then KeyLab.UI:SetMenuOnly(false) end
            KeyLab.UI:SetContentMode(mode)
        end)
        button:SetScript("OnEnter", function(self)
            if NormalizeContentMode(KeyLab.UI.contentMode) ~= mode then
                self:SetBackdropBorderColor(unpack(CFG.colors.buttonHover))
            end
        end)
        button:SetScript("OnLeave", function() KeyLab.UI:RefreshContentModeSelector() end)
        self.modeButtons[mode] = button
    end
    self:RefreshContentModeSelector()
end

local function CreateNavigationButton(parent, width, height, fontObject)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    StylePanel(button, CFG.colors.buttonBg, CFG.colors.buttonBorder)
    local accent
    if Theme.AddAccent then
        accent = Theme.AddAccent(button, CFG.colors.gold, 3)
    else
        accent = button:CreateTexture(nil, "ARTWORK")
        accent:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        accent:SetWidth(3)
        accent:SetColorTexture(unpack(CFG.colors.gold))
    end
    accent:Hide(); button.accent = accent
    local label = button:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormal")
    label:SetPoint("LEFT", button, "LEFT", 14, 0)
    label:SetWidth(width - 24); label:SetJustifyH("LEFT")
    ApplyColor(label, CFG.colors.text); button.label = label
    return button
end

function KeyLab.UI:LayoutNavigationButtons()
    local y = CFG.sidebar.y
    local childHeight, childGap = 27, 4
    for _, section in ipairs(NAVIGATION_SECTIONS) do
        local button = self.tabButtons and self.tabButtons[section.id]
        if button then
            button:ClearAllPoints(); button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.sidebar.x, y); button:Show()
            y = y - CFG.sidebar.buttonHeight - CFG.sidebar.buttonGap
        end
        if section.id == "Home" and self.modeSelector then
            self.modeSelector:ClearAllPoints(); self.modeSelector:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.sidebar.x, y)
            y = y - (CFG.sidebar.modeHeight or 30) - CFG.sidebar.buttonGap
        end
        local expanded = self.expandedNavigationSection == section.id and type(section.items) == "table"
        for _, entry in ipairs(self.navigationChildButtons and self.navigationChildButtons[section.id] or {}) do
            entry.button:SetShown(expanded)
            if expanded then
                entry.button:ClearAllPoints()
                entry.button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.sidebar.x + 10, y)
                y = y - childHeight - childGap
            end
        end
        if expanded then y = y - 4 end
    end
    local usedHeight = -y + CFG.sidebar.y + (CFG.sidebar.paddingTop or 12) + (CFG.sidebar.paddingBottom or 12)
    if self.sidebar then
        self.standardSidebarHeight = math.max(usedHeight, 360)
        self.sidebar:SetHeight(self.standardSidebarHeight)
    end
    return y
end

function KeyLab.UI:IsDestinationSelected(destination)
    local virtual = VIRTUAL_ROUTES[destination]
    if virtual then
        local view = KeyLab.Tabs and KeyLab.Tabs.GearPlanning and KeyLab.Tabs.GearPlanning.selectedView
        return self.selectedTab == virtual.tab and view == virtual.view
    end
    local category = GetAnalysisRoute(destination)
    if category then return self.selectedTab == ResolveNavigationTab(category, self.contentMode) end
    return self.selectedTab == destination
end

function KeyLab.UI:RefreshNavigationButtons()
    local selectedSection = GetNavigationKey(self.selectedTab)
    if self.selectedTab == "Gear Planning" then selectedSection = GetNavigationKey("Gear Planning") end
    for sectionID, button in pairs(self.tabButtons or {}) do
        local selected = sectionID == selectedSection
        local bg = selected and (CFG.colors.buttonSelectedBg or CFG.colors.buttonBg) or CFG.colors.buttonBg
        local border = selected and CFG.colors.buttonSelected or CFG.colors.buttonBorder
        button:SetBackdropColor(unpack(bg)); button:SetBackdropBorderColor(unpack(border))
        ApplyColor(button.label, selected and CFG.colors.gold or CFG.colors.text)
        if button.accent then button.accent:SetShown(selected) end
    end
    for _, entries in pairs(self.navigationChildButtons or {}) do
        for _, entry in ipairs(entries) do
            local selected = self:IsDestinationSelected(entry.destination)
            local bg = selected and (CFG.colors.buttonSelectedBg or CFG.colors.buttonBg) or CFG.colors.buttonBg
            local border = selected and CFG.colors.buttonSelected or CFG.colors.buttonBorder
            entry.button:SetBackdropColor(unpack(bg)); entry.button:SetBackdropBorderColor(unpack(border))
            ApplyColor(entry.button.label, selected and CFG.colors.gold or CFG.colors.text)
            if entry.button.accent then entry.button.accent:SetShown(selected) end
        end
    end
end

function KeyLab.UI:CreateTabButtons()
    self.navigationChildButtons = {}
    for _, section in ipairs(NAVIGATION_SECTIONS) do
        local tabName = section.id
        local button = CreateNavigationButton(self.frame, CFG.sidebar.width, CFG.sidebar.buttonHeight, "GameFontNormal")
        button.label:SetText(GetNavigationLabel(tabName, self.contentMode or GetSavedContentMode()))

        button:SetScript("OnClick", function()
            if KeyLab.UI.isMenuOnly then KeyLab.UI:SetMenuOnly(false) end
            if type(section.items) == "table" and #section.items > 0 then
                KeyLab.UI.expandedNavigationSection = section.id
                KeyLab.UI:LayoutNavigationButtons()
            end
            KeyLab.UI:SelectTab(section.default)
        end)

        button:SetScript("OnEnter", function(self)
            if GetNavigationKey(KeyLab.UI.selectedTab) ~= tabName then
                self:SetBackdropBorderColor(CFG.colors.buttonHover[1], CFG.colors.buttonHover[2], CFG.colors.buttonHover[3], CFG.colors.buttonHover[4])
            end
        end)

        button:SetScript("OnLeave", function(self)
            if GetNavigationKey(KeyLab.UI.selectedTab) ~= tabName then
                self:SetBackdropBorderColor(CFG.colors.buttonBorder[1], CFG.colors.buttonBorder[2], CFG.colors.buttonBorder[3], CFG.colors.buttonBorder[4])
            end
        end)

        self.tabButtons[tabName] = button
        if tabName == "Home" then self:CreateContentModeSelector(CFG.sidebar.y - CFG.sidebar.buttonHeight - CFG.sidebar.buttonGap) end

        self.navigationChildButtons[section.id] = {}
        for _, definition in ipairs(section.items or {}) do
            local entry = {
                destination = definition.destination,
                label = definition.label,
            }
            local child = CreateNavigationButton(self.frame, CFG.sidebar.width - 10, 27, "GameFontHighlightSmall")
            child.label:SetText(entry.label or DestinationLabel(entry.destination, self.contentMode or GetSavedContentMode()))
            child:SetScript("OnClick", function()
                if KeyLab.UI.isMenuOnly then KeyLab.UI:SetMenuOnly(false) end
                KeyLab.UI:SelectTab(entry.destination)
            end)
            child:SetScript("OnEnter", function(self)
                if not KeyLab.UI:IsDestinationSelected(entry.destination) then self:SetBackdropBorderColor(unpack(CFG.colors.buttonHover)) end
            end)
            child:SetScript("OnLeave", function() KeyLab.UI:RefreshNavigationButtons() end)
            entry.button = child
            table.insert(self.navigationChildButtons[section.id], entry)
        end
    end
    self.expandedNavigationSection = "Performance"
    return self:LayoutNavigationButtons()
end

function KeyLab.UI:CreateMenuOnlyHelperButtons(y)
    self.menuOnlyHelperButtons = {}
    local height = CFG.menuOnly.helperButtonHeight or 30
    local gap = CFG.menuOnly.helperButtonGap or 8
    local definitions = {
        {
            label = "Gear & Catalyst Runs",
            tooltip = "Reopen the saved Gear Target and Tier-slot dungeon list.",
            onClick = function()
                if KeyLab.LFGTooltips and KeyLab.LFGTooltips.ReopenShoppingList then
                    KeyLab.LFGTooltips.ReopenShoppingList()
                elseif KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.ShowManual then
                    KeyLab.GearTargetsWindow.ShowManual()
                end
            end,
        },
        {
            label = "Crafting Shopping List",
            tooltip = "Reopen the materials list for your saved crafted gear plan.",
            onClick = function()
                if KeyLab.CraftingShoppingWindow and KeyLab.CraftingShoppingWindow.Show then
                    KeyLab.CraftingShoppingWindow.Show(true)
                end
            end,
        },
    }

    for index, definition in ipairs(definitions) do
        local button = CreateFrame("Button", nil, self.frame, "BackdropTemplate")
        button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.sidebar.x,
            y - ((index - 1) * (height + gap)))
        button:SetSize(CFG.sidebar.width, height)
        StylePanel(button, CFG.colors.buttonSelectedBg or CFG.colors.buttonBg, CFG.colors.buttonBorder)
        local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("CENTER")
        label:SetSize(CFG.sidebar.width - 16, height - 4)
        label:SetText(definition.label)
        ApplyColor(label, CFG.colors.gold)
        button.label = label
        button.helperTooltip = definition.tooltip
        button:SetScript("OnClick", definition.onClick)
        button:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(unpack(CFG.colors.buttonHover))
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.helperTooltip or "KeyLab Helper")
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(unpack(CFG.colors.buttonBorder))
            GameTooltip:Hide()
        end)
        button:Hide()
        table.insert(self.menuOnlyHelperButtons, button)
    end
end

function KeyLab.UI:ShowSequencerCombatMessage(draftPreserved)
    local dialogs = _G.StaticPopupDialogs
    if type(dialogs) ~= "table" or type(StaticPopup_Show) ~= "function" then return end
    if not dialogs["KEYLAB_SEQUENCER_COMBAT"] then
        dialogs["KEYLAB_SEQUENCER_COMBAT"] = {
            text = "The Macro Sequencer Editor cannot open during combat. Your saved sequence and binding still work. Leave combat to edit it.",
            button1 = OKAY,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    if draftPreserved and KeyLab.Tabs and KeyLab.Tabs.Sequencer and KeyLab.Tabs.Sequencer.SetStatus then
        KeyLab.Tabs.Sequencer.preserveDraft = true
        KeyLab.Tabs.Sequencer:SetStatus("Combat began while editing. Your current fields were preserved for this session.")
    end
    StaticPopup_Show("KEYLAB_SEQUENCER_COMBAT")
end

function KeyLab.UI:RefreshSequencerNavigationState()
    local button = self.tabButtons and self.tabButtons["Sequencer"]
    if not button then return end
    local inCombat = InCombatLockdown and InCombatLockdown()
    if inCombat then
        button:SetBackdropColor(0.28, 0.035, 0.045, 0.94)
        button:SetBackdropBorderColor(0.84, 0.22, 0.22, 1)
        if button.label then button.label:SetTextColor(1.0, 0.78, 0.78, 1) end
        if button.accent then button.accent:Hide() end
        return
    end

    local selected = GetNavigationKey(self.selectedTab) == "Sequencer"
    local bg = selected and (CFG.colors.buttonSelectedBg or CFG.colors.buttonBg) or CFG.colors.buttonBg
    local border = selected and CFG.colors.buttonSelected or CFG.colors.buttonBorder
    button:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    button:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    ApplyColor(button.label, selected and CFG.colors.gold or CFG.colors.text)
    if button.accent then button.accent:SetShown(selected) end
end

function KeyLab.UI:CreateTabFrame(tabName)
    if not tabName then return nil end
    self.tabFrames = self.tabFrames or {}
    if self.tabFrames[tabName] then
        return self.tabFrames[tabName]
    end

    local reg = FindRegisteredTab(tabName)
    if not reg or not reg.createFunc then
        SafePrint("Tab not registered yet: " .. tostring(tabName))
        return nil
    end

    -- Every tab sits inside the same shared surface. Keeping the visible outer
    -- edge here prevents individual tab backgrounds from covering it.
    local surface = CreateFrame("Frame", nil, self.content, "BackdropTemplate")
    surface:SetAllPoints(self.content)
    surface:SetFrameLevel(self.content:GetFrameLevel() + 1)
    StylePanel(
        surface,
        CFG.colors.contentBg,
        (KeyLab.UI.Theme and KeyLab.UI.Theme.colors and KeyLab.UI.Theme.colors.cardBorder) or CFG.colors.contentBorder
    )

    local ok, tabFrameOrError = pcall(reg.createFunc, surface)
    if not ok then
        surface:Hide()
        SafePrint("Error creating tab " .. tostring(tabName) .. ": " .. tostring(tabFrameOrError))
        return nil
    end

    if not tabFrameOrError then
        surface:Hide()
        return nil
    end

    local tabFrame = tabFrameOrError
    tabFrame:SetParent(surface)
    tabFrame:ClearAllPoints()
    tabFrame:SetPoint("TOPLEFT", surface, "TOPLEFT", 1, -1)
    tabFrame:SetPoint("BOTTOMRIGHT", surface, "BOTTOMRIGHT", -1, 1)
    tabFrame:SetFrameLevel(surface:GetFrameLevel() + 1)
    surface.tabContent = tabFrame
    if type(tabFrame.Refresh) == "function" then
        surface.Refresh = function()
            tabFrame:Refresh()
        end
    end
    surface:Hide()
    self.tabFrames[tabName] = surface
    return surface
end

function KeyLab.UI:RefreshSelectedTab()
    local savedMode = GetSavedContentMode()
    if NormalizeContentMode(self.contentMode) ~= savedMode then
        self.contentMode = savedMode
        self:RefreshContentModeSelector()
        local category = GetAnalysisRoute(self.selectedTab)
        if category and ResolveNavigationTab(category, savedMode) ~= self.selectedTab then
            self:SelectTab(category)
            return
        end
    end

    local tabName = self.selectedTab
    if not tabName then return end

    local tabFrame = self.tabFrames and self.tabFrames[tabName]
    if not tabFrame then return end

    local visible = tabFrame.IsVisible and tabFrame:IsVisible() or tabFrame:IsShown()
    if not visible then return end

    if tabFrame and type(tabFrame.Refresh) == "function" then
        pcall(function()
            tabFrame:Refresh()
        end)
        return
    end

    local tabObjectKey = GetTabObjectKey(tabName)
    local tabObject = KeyLab.Tabs and KeyLab.Tabs[tabObjectKey]

    if tabObject and type(tabObject.Refresh) == "function" then
        pcall(function()
            tabObject:Refresh()
        end)
    end
end

function KeyLab.UI:SetContentMode(mode)
    self:Create()
    mode = NormalizeContentMode(mode)
    local previousMode = NormalizeContentMode(self.contentMode or GetSavedContentMode())
    self.contentMode = SaveContentMode(mode)
    self:RefreshContentModeSelector()
    if previousMode == mode then return end

    local category = GetAnalysisRoute(self.selectedTab)
    if category then
        self:SelectTab(category)
    else
        self:RefreshSelectedTab()
    end
end

function KeyLab.UI:SelectTab(tabName)
    if InCombatLockdown and InCombatLockdown() then
        if self.frame then self.frame:Hide() end
        return
    end
    self:Create()

    local requestedDestination = tabName
    local virtualRoute = VIRTUAL_ROUTES[tabName]
    if virtualRoute then tabName = virtualRoute.tab end

    local category, explicitMode = GetAnalysisRoute(tabName)
    if explicitMode then
        self.contentMode = SaveContentMode(explicitMode)
        self:RefreshContentModeSelector()
    elseif category then
        tabName = ResolveNavigationTab(category, self.contentMode or GetSavedContentMode())
    end

    if GetNavigationKey(self.selectedTab) == "Sequencer" and GetNavigationKey(tabName) ~= "Sequencer"
        and KeyLab.Tabs and KeyLab.Tabs.Sequencer and KeyLab.Tabs.Sequencer.RequestLeave
        and not (InCombatLockdown and InCombatLockdown()) then
        local allowed = KeyLab.Tabs.Sequencer:RequestLeave(function() KeyLab.UI:SelectTab(requestedDestination) end)
        if not allowed then return end
    end

    local selectedFrame = self:CreateTabFrame(tabName)
    if not selectedFrame then return end

    local previousTab = self.selectedTab
    self.selectedTab = tabName

    if previousTab and previousTab ~= tabName and self.tabFrames and self.tabFrames[previousTab] then
        self.tabFrames[previousTab]:Hide()
    end

    if self.frame and self.frame:IsShown() and not self.isMenuOnly then
        if self.content then self.content:Show() end
        selectedFrame:Show()
    end

    if virtualRoute and KeyLab.Tabs and KeyLab.Tabs.GearPlanning and KeyLab.Tabs.GearPlanning.ShowView then
        KeyLab.Tabs.GearPlanning:ShowView(virtualRoute.view)
    end

    local selectedNavigation = GetNavigationKey(tabName)
    local section = GetNavigationSection(selectedNavigation)
    if section and type(section.items) == "table" and #section.items > 0 then
        self.expandedNavigationSection = selectedNavigation
    elseif requestedDestination == "Home" then
        self.expandedNavigationSection = nil
    end
    self:LayoutNavigationButtons()

    if selectedNavigation ~= "Sequencer" then self.lastNonSequencerTab = tabName end
    self:RefreshNavigationButtons()

    self:RefreshSelectedTab()
    self:RefreshSequencerNavigationState()

end

function KeyLab.UI:GetPreparationDestinations()
    local choices = {}
    for _, section in ipairs(NAVIGATION_SECTIONS) do
        if type(section.items) == "table" and #section.items > 0 then
            for _, item in ipairs(section.items) do
                local route = ANALYSIS_ROUTES[item.destination]
                if route then
                    for _, mode in ipairs({"mplus", "raid"}) do
                        choices[#choices+1] = {
                            value = route[mode],
                            label = section.id .. " - " .. (mode == "raid" and "Raid " or "Mythic+ ") .. GetNavigationLabel(item.destination, mode),
                        }
                    end
                else
                    choices[#choices+1] = {
                        value = item.destination,
                        label = section.id .. " - " .. (item.label or DestinationLabel(item.destination, self.contentMode)),
                    }
                end
            end
        else
            choices[#choices+1] = { value = section.default, label = GetNavigationLabel(section.id, self.contentMode) }
        end
    end
    return choices
end

function KeyLab.UI:NotifyGearPlanningView(view)
    if self.selectedTab ~= "Gear Planning" then return end
    self.expandedNavigationSection = (view == "WH" or view == "IV") and "Guide Lists" or "Gear"
    self:LayoutNavigationButtons()
    self:RefreshNavigationButtons()
end

function KeyLab.UI:Show()
    if InCombatLockdown and InCombatLockdown() then return end
    self:Create()
    if self.isMenuOnly then self:SetMenuOnly(false) end
    self.frame:Show()
    self:SelectTab(self.selectedTab or "Home")
end

function KeyLab.UI:Hide()
    if self.frame then
        if GetNavigationKey(self.selectedTab) == "Sequencer" and KeyLab.Tabs and KeyLab.Tabs.Sequencer
            and KeyLab.Tabs.Sequencer.RequestLeave then
            local allowed = KeyLab.Tabs.Sequencer:RequestLeave(function() KeyLab.UI.frame:Hide() end)
            if not allowed then return end
        end
        self.frame:Hide()
    end
end

function KeyLab.UI:Toggle()
    if InCombatLockdown and InCombatLockdown() then
        if self.frame then self.frame:Hide() end
        return
    end
    self:Create()

    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
