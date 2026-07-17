-- KeyLab_UI.lua
-- Main UI shell for KeyLab's shared Mythic+ and Raid journal.
--
-- Purpose:
--   Owns the main addon window, sidebar navigation, and tab switching.
--
-- Current UI direction:
--   No image assets required yet.
--   Uses simple colored panels, borders, and text so layout/card work can be tested first.
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

    close = {
        x = -22,
        y = -20,
        width = 28,
        height = 28,
    },

    title = {
        text = "KeyLab",
        x = 24,
        y = 0,
        font = (Theme.fonts and Theme.fonts.heading) or "Fonts\\FRIZQT__.TTF",
        size = (Theme.fonts and Theme.fonts.titleSize) or 32,
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
        "Encounters",
        "Summary",
        "Talent Builds",
        "Stat Profiles",
        "Gear Profiles",
        "Trends",
        "Practice",
        "Gear Planning",
        "Gear Targets",
        "Gear Dashboard",
        "Insights",
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

local OPTIONAL_TABS = {
    ["Gear Planning"] = true,
}

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
    return category or tabName
end

local function GetVisibleNavigationTabs()
    local tabs = {}
    for _, tabName in ipairs(CFG.tabs or {}) do
        if not OPTIONAL_TABS[tabName] or FindRegisteredTab(tabName) then table.insert(tabs, tabName) end
    end
    return tabs
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
    self.contentMode = GetSavedContentMode()
    self.navigationTabs = GetVisibleNavigationTabs()

    -- Header background with KeyLab title.
    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -14)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -14)
    header:SetHeight(78)
    StylePanel(header, CFG.colors.headerBg, CFG.colors.headerBorder)
    self.header = header

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", header, "LEFT", CFG.title.x, CFG.title.y)
    title:SetText(CFG.title.text)
    title:SetFont(CFG.title.font, CFG.title.size, "")
    title:SetTextColor(CFG.colors.gold[1], CFG.colors.gold[2], CFG.colors.gold[3], CFG.colors.gold[4] or 1)
    title:SetShadowColor(0, 0, 0, 0.85)
    title:SetShadowOffset(2, -2)
    self.title = title

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetSize(CFG.close.width, CFG.close.height)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", CFG.close.x, CFG.close.y)
    close:SetScript("OnClick", function()
        frame:Hide()
    end)
    self.closeButton = close

    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.sidebar.x - 8, CFG.sidebar.y + 12)

    local tabCount = #(self.navigationTabs or {})
    local sidebarHeight =
        (CFG.sidebar.paddingTop or 12)
        + (tabCount * CFG.sidebar.buttonHeight)
        + (math.max(0, tabCount - 1) * CFG.sidebar.buttonGap)
        + (CFG.sidebar.modeHeight or 30)
        + CFG.sidebar.buttonGap
        + (CFG.sidebar.paddingBottom or 12)

    sidebar:SetSize(CFG.sidebar.width + 16, sidebarHeight)
    StylePanel(sidebar, CFG.colors.sidebarBg, CFG.colors.sidebarBorder)
    self.sidebar = sidebar

    local content = CreateFrame("Frame", "KeyLabContentFrame", frame, "BackdropTemplate")
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", CFG.content.x, CFG.content.y)
    content:SetSize(CFG.content.width, CFG.content.height)
    StylePanel(content, CFG.colors.contentBg, CFG.colors.contentBorder)
    content:SetFrameLevel(frame:GetFrameLevel() + 5)
    self.content = content

    self.tabFrames = {}
    self.tabButtons = {}

    self:CreateTabButtons()

    self:SelectTab("Home")

    return frame
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

        button:SetScript("OnClick", function() KeyLab.UI:SetContentMode(mode) end)
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

function KeyLab.UI:CreateTabButtons()
    local y = CFG.sidebar.y

    for _, tabName in ipairs(self.navigationTabs or GetVisibleNavigationTabs()) do
        local button = CreateFrame("Button", nil, self.frame, "BackdropTemplate")
        button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.sidebar.x, y)
        button:SetSize(CFG.sidebar.width, CFG.sidebar.buttonHeight)
        StylePanel(button, CFG.colors.buttonBg, CFG.colors.buttonBorder)

        local accent
        if Theme.AddAccent then
            accent = Theme.AddAccent(button, CFG.colors.gold, 3)
        else
            accent = button:CreateTexture(nil, "ARTWORK")
            accent:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
            accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
            accent:SetWidth(3)
            accent:SetColorTexture(CFG.colors.gold[1], CFG.colors.gold[2], CFG.colors.gold[3], CFG.colors.gold[4] or 1)
        end
        accent:Hide()
        button.accent = accent

        local label
        if Theme.CreateText then
            label = Theme.CreateText(button, tabName, "GameFontNormal", nil, CFG.colors.text)
        else
            label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetText(tabName)
            ApplyColor(label, CFG.colors.text)
        end
        label:SetPoint("LEFT", button, "LEFT", 14, 0)
        label:SetWidth(CFG.sidebar.width - 24)
        label:SetJustifyH("LEFT")
        button.label = label

        button:SetScript("OnClick", function()
            KeyLab.UI:SelectTab(tabName)
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
        y = y - CFG.sidebar.buttonHeight - CFG.sidebar.buttonGap
        if tabName == "Home" then
            self:CreateContentModeSelector(y)
            y = y - (CFG.sidebar.modeHeight or 30) - CFG.sidebar.buttonGap
        end
    end
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

    local ok, tabFrameOrError = pcall(reg.createFunc, self.content)
    if not ok then
        SafePrint("Error creating tab " .. tostring(tabName) .. ": " .. tostring(tabFrameOrError))
        return nil
    end

    if not tabFrameOrError then return nil end

    local tabFrame = tabFrameOrError
    tabFrame:SetParent(self.content)
    tabFrame:SetAllPoints(self.content)
    tabFrame:Hide()
    self.tabFrames[tabName] = tabFrame
    return tabFrame
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
    self:Create()

    local category, explicitMode = GetAnalysisRoute(tabName)
    if explicitMode then
        self.contentMode = SaveContentMode(explicitMode)
        self:RefreshContentModeSelector()
    elseif category then
        tabName = ResolveNavigationTab(category, self.contentMode or GetSavedContentMode())
    end

    local selectedFrame = self:CreateTabFrame(tabName)
    if not selectedFrame then return end

    local previousTab = self.selectedTab
    self.selectedTab = tabName

    if previousTab and previousTab ~= tabName and self.tabFrames and self.tabFrames[previousTab] then
        self.tabFrames[previousTab]:Hide()
    end

    if self.frame and self.frame:IsShown() then
        selectedFrame:Show()
    end

    local selectedNavigation = GetNavigationKey(tabName)
    for name, button in pairs(self.tabButtons or {}) do
        if name == selectedNavigation then
            local selectedBg = CFG.colors.buttonSelectedBg or {0.055, 0.085, 0.160, 0.90}
            button:SetBackdropColor(selectedBg[1], selectedBg[2], selectedBg[3], selectedBg[4] or 1)
            button:SetBackdropBorderColor(CFG.colors.buttonSelected[1], CFG.colors.buttonSelected[2], CFG.colors.buttonSelected[3], CFG.colors.buttonSelected[4])
            ApplyColor(button.label, CFG.colors.gold)
            if button.accent then button.accent:Show() end
        else
            button:SetBackdropColor(CFG.colors.buttonBg[1], CFG.colors.buttonBg[2], CFG.colors.buttonBg[3], CFG.colors.buttonBg[4])
            button:SetBackdropBorderColor(CFG.colors.buttonBorder[1], CFG.colors.buttonBorder[2], CFG.colors.buttonBorder[3], CFG.colors.buttonBorder[4])
            ApplyColor(button.label, CFG.colors.text)
            if button.accent then button.accent:Hide() end
        end
    end

    self:RefreshSelectedTab()

end

function KeyLab.UI:Show()
    self:Create()
    self.frame:Show()
    self:SelectTab(self.selectedTab or "Home")
end

function KeyLab.UI:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function KeyLab.UI:Toggle()
    self:Create()

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
        self:SelectTab(self.selectedTab or "Home")
    end
end
