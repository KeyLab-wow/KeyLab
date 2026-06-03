-- KeyLab_UI.lua
-- Main UI shell for KeyLab / M+ Journal
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
        font = "Fonts\\FRIZQT__.TTF",
        size = 32,
    },

    sidebar = {
        x = 22,
        y = -128,
        width = 176,
        buttonHeight = 36,
        buttonGap = 8,
        paddingTop = 12,
        paddingBottom = 12,
    },

    content = {
        x = 212,
        y = -112,
        width = 960,
        height = 820,
    },

    colors = {
        windowBg = {0.015, 0.020, 0.050, 0.98},
        windowBorder = {0.24, 0.36, 0.68, 0.92},

        headerBg = {0.035, 0.045, 0.090, 0.00},
        headerBorder = {0.24, 0.36, 0.68, 0.95},

        sidebarBg = {0.020, 0.028, 0.065, 0.70},
        sidebarBorder = {0.16, 0.24, 0.44, 0.72},

        contentBg = {0.025, 0.032, 0.070, 0.60},
        contentBorder = {0.12, 0.20, 0.38, 0.45},

        buttonBg = {0.030, 0.050, 0.110, 0.72},
        buttonBorder = {0.18, 0.28, 0.50, 0.80},
        buttonHover = {0.16, 0.32, 0.62, 0.95},
        buttonSelected = {0.34, 0.58, 1.00, 1.00},

        gold = {1.00, 0.86, 0.46, 1},
        text = {0.92, 0.92, 0.95, 1},
        muted = {0.82, 0.84, 0.90, 1},
    },

    tabs = {
        "Home",
        "Encounters",
        "Talent Builds",
        "Stat Profiles",
        "Trends",
        "Insights",
        "Settings",
    },
}

-- =========================================================
-- SMALL UI HELPERS
-- =========================================================

local function ApplyColor(fs, color)
    if not fs or not color then return end
    fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function StylePanel(frame, bg, border)
    if not frame then return end

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

local function GetTabObjectKey(tabName)
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

    local tabCount = #(CFG.tabs or {})
    local sidebarHeight =
        (CFG.sidebar.paddingTop or 12)
        + (tabCount * CFG.sidebar.buttonHeight)
        + (math.max(0, tabCount - 1) * CFG.sidebar.buttonGap)
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
    self:CreateTabFrames()

    self:SelectTab("Home")

    return frame
end

function KeyLab.UI:CreateTabButtons()
    local y = CFG.sidebar.y

    for _, tabName in ipairs(CFG.tabs) do
        local button = CreateFrame("Button", nil, self.frame, "BackdropTemplate")
        button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", CFG.sidebar.x, y)
        button:SetSize(CFG.sidebar.width, CFG.sidebar.buttonHeight)
        StylePanel(button, CFG.colors.buttonBg, CFG.colors.buttonBorder)

        local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", button, "LEFT", 14, 0)
        label:SetWidth(CFG.sidebar.width - 24)
        label:SetJustifyH("LEFT")
        label:SetText(tabName)
        ApplyColor(label, CFG.colors.text)
        button.label = label

        button:SetScript("OnClick", function()
            KeyLab.UI:SelectTab(tabName)
        end)

        button:SetScript("OnEnter", function(self)
            if KeyLab.UI.selectedTab ~= tabName then
                self:SetBackdropBorderColor(CFG.colors.buttonHover[1], CFG.colors.buttonHover[2], CFG.colors.buttonHover[3], CFG.colors.buttonHover[4])
            end
        end)

        button:SetScript("OnLeave", function(self)
            if KeyLab.UI.selectedTab ~= tabName then
                self:SetBackdropBorderColor(CFG.colors.buttonBorder[1], CFG.colors.buttonBorder[2], CFG.colors.buttonBorder[3], CFG.colors.buttonBorder[4])
            end
        end)

        self.tabButtons[tabName] = button
        y = y - CFG.sidebar.buttonHeight - CFG.sidebar.buttonGap
    end
end

function KeyLab.UI:CreateTabFrames()
    for _, tabName in ipairs(CFG.tabs) do
        local reg = FindRegisteredTab(tabName)

        if reg and reg.createFunc then
            local ok, tabFrameOrError = pcall(reg.createFunc, self.content)

            if ok and tabFrameOrError then
                local tabFrame = tabFrameOrError
                tabFrame:SetParent(self.content)
                tabFrame:SetAllPoints(self.content)
                tabFrame:Hide()
                self.tabFrames[tabName] = tabFrame
            elseif not ok then
                SafePrint("Error creating tab " .. tostring(tabName) .. ": " .. tostring(tabFrameOrError))
            end
        else
            SafePrint("Tab not registered yet: " .. tostring(tabName))
        end
    end
end

function KeyLab.UI:RefreshSelectedTab()
    local tabName = self.selectedTab
    if not tabName then return end

    local tabObjectKey = GetTabObjectKey(tabName)
    local tabObject = KeyLab.Tabs and KeyLab.Tabs[tabObjectKey]

    if tabObject and type(tabObject.Refresh) == "function" then
        pcall(function()
            tabObject:Refresh()
        end)
    end
end

function KeyLab.UI:SelectTab(tabName)
    self:Create()

    self.selectedTab = tabName

    for name, tabFrame in pairs(self.tabFrames or {}) do
        if name == tabName then
            tabFrame:Show()
        else
            tabFrame:Hide()
        end
    end

    for name, button in pairs(self.tabButtons or {}) do
        if name == tabName then
            button:SetBackdropColor(0.055, 0.085, 0.160, 0.90)
            button:SetBackdropBorderColor(CFG.colors.buttonSelected[1], CFG.colors.buttonSelected[2], CFG.colors.buttonSelected[3], CFG.colors.buttonSelected[4])
            ApplyColor(button.label, CFG.colors.gold)
        else
            button:SetBackdropColor(CFG.colors.buttonBg[1], CFG.colors.buttonBg[2], CFG.colors.buttonBg[3], CFG.colors.buttonBg[4])
            button:SetBackdropBorderColor(CFG.colors.buttonBorder[1], CFG.colors.buttonBorder[2], CFG.colors.buttonBorder[3], CFG.colors.buttonBorder[4])
            ApplyColor(button.label, CFG.colors.text)
        end
    end

    self:RefreshSelectedTab()
end

function KeyLab.UI:Show()
    self:Create()
    self.frame:Show()
    self:RefreshSelectedTab()
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
        self:RefreshSelectedTab()
    end
end
