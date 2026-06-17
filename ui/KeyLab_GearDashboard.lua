-- KeyLab_GearDashboard.lua
-- Character-profile style gearing dashboard UI.
--
-- Decision logic lives in analysis/KeyLab_GearingAnalysis.lua.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local GearDashboard = {}
KeyLab.Tabs.GearDashboard = GearDashboard

local Theme = KeyLab.UI and KeyLab.UI.Theme or {}

local COLORS = Theme.colors or {
    bg = {0.018, 0.026, 0.056, 0.98},
    card = {0.030, 0.052, 0.098, 0.84},
    slot = {0.030, 0.052, 0.098, 0.76},
    icon = {0.012, 0.020, 0.044, 0.94},
    border = {0.240, 0.380, 0.620, 0.62},
    softBorder = {0.185, 0.300, 0.500, 0.50},
    text = {0.940, 0.960, 0.990, 1.0},
    muted = {0.680, 0.730, 0.820, 1.0},
    gold = {0.820, 0.760, 0.580, 1.0},
    purple = {0.680, 0.560, 0.880, 0.95},
    blue = {0.500, 0.680, 0.940, 0.95},
    green = {0.460, 0.780, 0.500, 0.95},
    yellow = {0.840, 0.720, 0.420, 0.95},
    orange = {0.860, 0.580, 0.340, 0.95},
    red = {0.840, 0.440, 0.420, 0.95},
    gray = {0.620, 0.670, 0.740, 1.0},
    white = {0.900, 0.920, 0.960, 0.95},
}

local CONTENT_WIDTH = 960
local SLOT_WIDTH = 316
local CENTER_WIDTH = 292
local SLOT_HEIGHT = 72
local SLOT_GAP = 10
local STATUS_BADGE_SIZE = 26
local BADGE_HEIGHT = 16
local SLOT_BADGE_FONT_SIZE = 8
local REFRESH_DEBOUNCE_SECONDS = 0.35

local TRACK_COLORS = {
    Unranked = COLORS.gray,
    Adventurer = COLORS.green,
    Veteran = COLORS.blue,
    Champion = COLORS.yellow,
    Hero = COLORS.green,
    Myth = COLORS.purple,
}

local function Analysis()
    return KeyLab and KeyLab.GearingAnalysis or {}
end

local function Capture()
    return KeyLab and KeyLab.GearCapture or {}
end

local function IsVisible(frame)
    if not frame then return false end
    if frame.IsVisible then return frame:IsVisible() end
    return frame:IsShown()
end

local function SetBackdrop(frame, color, borderColor)
    local edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border"
    local edgeSize = 7
    local insets = { left = 2, right = 2, top = 2, bottom = 2 }
    if frame.GetHeight and (frame:GetHeight() or 0) <= 20 then
        edgeFile = "Interface\\Buttons\\WHITE8x8"
        edgeSize = 1
        insets = nil
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = edgeFile,
        tile = false,
        edgeSize = edgeSize,
        insets = insets,
    })
    frame:SetBackdropColor(unpack(color or COLORS.card))
    frame:SetBackdropBorderColor(unpack(borderColor or COLORS.border))
end

local function MakeText(parent, text, template, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    if size then fs:SetFont(STANDARD_TEXT_FONT, size, "") end
    fs:SetTextColor(unpack(color or COLORS.text))
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetText(text or "")
    return fs
end

local function MakeFrame(parent, x, y, width, height, bg, border)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(width, height)
    SetBackdrop(frame, bg or COLORS.card, border or COLORS.border)
    return frame
end

local function MakeCenterCard(parent, x, y, width, height, title)
    local card = MakeFrame(parent, x, y, width, height, COLORS.card, COLORS.border)
    local titleText = MakeText(card, title, "GameFontNormal", nil, COLORS.muted, "CENTER")
    titleText:SetPoint("TOP", card, "TOP", 0, -10)
    titleText:SetSize(width - 20, 18)
    card.title = titleText
    return card
end

local function FormatItemLevel(value)
    value = tonumber(value)
    if not value then return "-" end
    if math.floor(value) == value then return tostring(value) end
    return string.format("%.1f", value)
end

local function TrackColor(trackName)
    return TRACK_COLORS[trackName] or COLORS.gray
end

local function StateColor(stateKey)
    if stateKey == "done" then return COLORS.green end
    if stateKey == "missing" then return COLORS.red end
    if stateKey == "target" then return COLORS.yellow end
    if stateKey == "craft" then return COLORS.purple end
    if stateKey == "upgrade" then return COLORS.yellow end
    if stateKey == "priority" then return COLORS.orange end
    if stateKey == "na" then return COLORS.gray end
    return COLORS.orange
end

local function ActivityColor(activity)
    if activity and activity.colorKey == "purple" then return COLORS.purple end
    if activity and activity.colorKey == "blue" then return COLORS.blue end
    if activity and activity.colorKey == "green" then return COLORS.green end
    if activity and activity.colorKey == "yellow" then return COLORS.yellow end
    if activity and activity.colorKey == "orange" then return COLORS.orange end
    return COLORS.blue
end

local function BadgeColor(badge)
    local key = badge and badge.key
    local kind = badge and badge.kind
    if kind == "missing" then return COLORS.red end
    if kind == "complete" then return COLORS.green end
    if kind == "target" or key == "tier" then return COLORS.yellow end
    if kind == "craft" or key == "crafted" then return COLORS.purple end
    if kind == "polish" then return COLORS.orange end
    return COLORS.blue
end

local function BadgeText(badge)
    local key = badge and badge.key
    if key == "enchant" then return "Enchant" end
    if key == "gem" then return "Gem" end
    if key == "embellishment" then return "Embellish" end
    return ""
end

local function RankColor(plan)
    local rank = tonumber(plan and plan.upgradeRank)
    local maxRank = tonumber(plan and plan.upgradeMaxRank)
    if rank and maxRank and rank >= maxRank then return COLORS.green end
    if rank and rank >= 4 then return COLORS.yellow end
    if rank then return COLORS.orange end
    return COLORS.white
end

local function Dimmed(color, scale, alpha)
    color = color or COLORS.gray
    scale = scale or 0.22
    return {
        math.min(1, color[1] * scale),
        math.min(1, color[2] * scale),
        math.min(1, color[3] * scale),
        alpha or 0.92,
    }
end

local function Softened(color, scale, alpha)
    color = color or COLORS.gray
    scale = scale or 0.70
    return {
        math.min(1, color[1] * scale),
        math.min(1, color[2] * scale),
        math.min(1, color[3] * scale),
        alpha or 0.78,
    }
end

local function IsUsefulSourceText(sourceText)
    sourceText = tostring(sourceText or "")
    if sourceText == "" then return false end
    if sourceText == "Upgrade" then return false end
    return true
end

local function ShouldShowSource(plan)
    if not plan or plan.blank then return false end
    return IsUsefulSourceText(plan.sourceText)
end

local function StatusBadgeText(plan)
    local text = plan and (plan.statusText or plan.reasonText) or ""
    return text
end

local function MakeBadge(parent)
    local badge = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    badge:SetSize(64, BADGE_HEIGHT)
    SetBackdrop(badge, COLORS.card, COLORS.softBorder)
    badge.text = MakeText(badge, "", "GameFontDisableSmall", 10, COLORS.text, "CENTER")
    badge.text:SetAllPoints(badge)
    badge.text:SetJustifyH("CENTER")
    badge.text:SetJustifyV("MIDDLE")
    return badge
end

local function SetBadge(badge, text, bg, border, textColor)
    if not badge then return end
    text = tostring(text or "")
    if text == "" then
        badge:Hide()
        return
    end
    badge:Show()
    badge:SetBackdropColor(unpack(bg or COLORS.card))
    badge:SetBackdropBorderColor(unpack(border or COLORS.softBorder))
    badge.text:SetText(text)
    badge.text:SetTextColor(unpack(textColor or COLORS.text))
end

local function SetOutlineBadge(badge, text, borderColor, textColor)
    SetBadge(badge, text, COLORS.card, borderColor or COLORS.softBorder, textColor or COLORS.text)
end

local function MakeSlotCard(parent, x, y, slotName)
    local row = MakeFrame(parent, x, y, SLOT_WIDTH, SLOT_HEIGHT, COLORS.slot, COLORS.border)
    row.slotName = slotName
    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
    row.accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1, 1)
    row.accent:SetWidth(3)
    row.accent:SetColorTexture(0, 0, 0, 0)

    row.iconBox = MakeFrame(row, 8, -9, 46, 54, COLORS.icon, COLORS.softBorder)
    row.icon = row.iconBox:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("CENTER", row.iconBox, "CENTER", 0, 0)
    row.icon:SetSize(38, 38)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.name = MakeText(row, slotName, "GameFontNormal", nil, COLORS.text)
    row.name:SetPoint("LEFT", row, "LEFT", 64, 10)
    row.name:SetSize(68, 18)

    row.trackBadge = MakeBadge(row)
    row.trackBadge:SetPoint("TOPLEFT", row, "TOPLEFT", 138, -9)
    row.trackBadge:SetSize(102, BADGE_HEIGHT)
    row.trackBadge.text:SetFont(STANDARD_TEXT_FONT, SLOT_BADGE_FONT_SIZE, "")

    row.rankBadge = MakeBadge(row)
    row.rankBadge:SetPoint("TOPLEFT", row, "TOPLEFT", 246, -9)
    row.rankBadge:SetSize(60, BADGE_HEIGHT)
    row.rankBadge.text:SetFont(STANDARD_TEXT_FONT, SLOT_BADGE_FONT_SIZE, "")

    row.sourceBadge = MakeBadge(row)
    row.sourceBadge:SetPoint("TOPLEFT", row, "TOPLEFT", 238, -31)
    row.sourceBadge:SetSize(68, BADGE_HEIGHT)
    row.sourceBadge.text:SetFont(STANDARD_TEXT_FONT, SLOT_BADGE_FONT_SIZE, "")

    row.statusBadge = MakeBadge(row)
    row.statusBadge:SetPoint("TOPLEFT", row, "TOPLEFT", 138, -31)
    row.statusBadge:SetSize(94, BADGE_HEIGHT)
    row.statusBadge.text:SetFont(STANDARD_TEXT_FONT, SLOT_BADGE_FONT_SIZE, "")

    row.detailBadges = {}
    local detailWidths = { 54, 34, 66 }
    local detailX = 138
    for i = 1, 3 do
        local badge = MakeBadge(row)
        badge:SetPoint("TOPLEFT", row, "TOPLEFT", detailX, -53)
        badge:SetSize(detailWidths[i], BADGE_HEIGHT)
        badge.text:SetFont(STANDARD_TEXT_FONT, SLOT_BADGE_FONT_SIZE, "")
        row.detailBadges[i] = badge
        detailX = detailX + detailWidths[i] + 4
    end

    return row
end

local function MakeActivityRow(parent, y, width)
    width = width or 250
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    row:SetSize(width, 18)
    row.blocks = {}

    for i = 1, 5 do
        local block = row:CreateTexture(nil, "ARTWORK")
        block:SetPoint("LEFT", row, "LEFT", (i - 1) * 15, 0)
        block:SetSize(10, 10)
        row.blocks[i] = block
    end

    row.label = MakeText(row, "", "GameFontNormal", nil, COLORS.text)
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label:SetSize(width, 18)
    return row
end

local function MakeProgressBar(parent)
    local bar = MakeFrame(parent, 20, -46, 252, 16, COLORS.barBg or {0.012, 0.020, 0.044, 0.92}, COLORS.softBorder)
    bar.fill = bar:CreateTexture(nil, "ARTWORK")
    bar.fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, -1)
    bar.fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 1, 1)
    bar.fill:SetWidth(1)
    bar.fill:SetColorTexture(unpack(COLORS.green))
    return bar
end

function GearDashboard:Build()
    if not self.frame then return end

    local title = MakeText(self.frame, "Gear Dashboard", "GameFontNormalLarge", nil, COLORS.gold, "LEFT")
    title:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 18, -18)
    title:SetSize(420, 28)
    self.title = title

    local subtitle = MakeText(self.frame, "See your Mythic+ gearing path at a glance: upgrade priorities, target progress, dungeon hints, and polish reminders.", "GameFontHighlightSmall", nil, COLORS.muted, "LEFT")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetSize(900, 20)
    self.subtitle = subtitle

    self.leftSlots = {}
    self.rightSlots = {}

    local leftX, centerX, rightX = 8, 332, 632
    local topY = -76

    for index, slotName in ipairs(Analysis().LeftSlots or {}) do
        self.leftSlots[slotName] = MakeSlotCard(self.frame, leftX, topY - ((index - 1) * (SLOT_HEIGHT + SLOT_GAP)), slotName)
    end

    for index, slotName in ipairs(Analysis().RightSlots or {}) do
        self.rightSlots[slotName] = MakeSlotCard(self.frame, rightX, topY - ((index - 1) * (SLOT_HEIGHT + SLOT_GAP)), slotName)
    end

    self.itemLevelCard = MakeCenterCard(self.frame, centerX, -76, CENTER_WIDTH, 92, "Current Item Level")
    self.itemLevelValue = MakeText(self.itemLevelCard, "-", "GameFontNormalLarge", 32, COLORS.purple, "CENTER")
    self.itemLevelValue:SetPoint("CENTER", self.itemLevelCard, "CENTER", 0, -6)
    self.itemLevelValue:SetSize(CENTER_WIDTH - 20, 34)
    self.itemLevelSubtext = MakeText(self.itemLevelCard, "", "GameFontDisableSmall", nil, COLORS.muted, "CENTER")
    self.itemLevelSubtext:SetPoint("BOTTOM", self.itemLevelCard, "BOTTOM", 0, 9)
    self.itemLevelSubtext:SetSize(CENTER_WIDTH - 20, 14)

    self.priorityCard = MakeCenterCard(self.frame, centerX, -180, CENTER_WIDTH, 174, "Upgrade Priority Slots")
    self.priorityRows = {}
    for i = 1, 3 do
        local row = MakeFrame(self.priorityCard, 18, -44 - ((i - 1) * 38), CENTER_WIDTH - 36, 28, COLORS.slot, COLORS.softBorder)
        row.slot = MakeText(row, "-", "GameFontDisableSmall", nil, COLORS.text)
        row.slot:SetPoint("LEFT", row, "LEFT", 10, 0)
        row.slot:SetSize(CENTER_WIDTH - 56, 18)
        self.priorityRows[i] = row
    end

    self.legendCard = MakeCenterCard(self.frame, centerX, -366, CENTER_WIDTH, 104, "Status Legend")
    self:BuildLegend(self.legendCard)

    self.blockMessageText = MakeText(self.frame, "", "GameFontDisableSmall", nil, COLORS.orange, "CENTER")
    self.blockMessageText:SetPoint("TOP", self.legendCard, "BOTTOM", 0, -14)
    self.blockMessageText:SetSize(CENTER_WIDTH - 18, 44)

    self.progressCard = MakeCenterCard(self.frame, centerX, -608, CENTER_WIDTH, 110, "Gear Target Progress")
    self.progressBar = MakeProgressBar(self.progressCard)
    self.progressText = MakeText(self.progressCard, "-", "GameFontHighlightSmall", nil, COLORS.text)
    self.progressText:SetPoint("TOPLEFT", self.progressBar, "BOTTOMLEFT", 0, -8)
    self.progressText:SetSize(150, 18)
    self.progressPercent = MakeText(self.progressCard, "-", "GameFontHighlightSmall", nil, COLORS.text, "RIGHT")
    self.progressPercent:SetPoint("TOPRIGHT", self.progressBar, "BOTTOMRIGHT", 0, -8)
    self.progressPercent:SetSize(80, 18)
    self.progressHint = MakeText(self.progressCard, "", "GameFontDisableSmall", nil, COLORS.muted, "CENTER")
    self.progressHint:SetPoint("BOTTOM", self.progressCard, "BOTTOM", 0, 8)
    self.progressHint:SetSize(CENTER_WIDTH - 24, 14)

    self.activityCard = MakeCenterCard(self.frame, 176, -728, 608, 104, "Next Steps You Can Do")
    self.activityRows = {}
    for i = 1, 4 do
        self.activityRows[i] = MakeActivityRow(self.activityCard, -32 - ((i - 1) * 17), 560)
    end
    self.activityNote = MakeText(self.activityCard, "", "GameFontDisableSmall", nil, COLORS.muted, "CENTER")
    self.activityNote:SetPoint("BOTTOM", self.activityCard, "BOTTOM", 0, 6)
    self.activityNote:SetSize(560, 12)
    self.activityNote:Hide()
end

function GearDashboard:BuildLegend(parent)
    local items = {
        { label = "Complete", color = COLORS.green },
        { label = "Priority Upgrade", color = COLORS.orange },
        { label = "Upgrade", color = COLORS.yellow },
        { label = "Missing", color = COLORS.red },
        { label = "N/A", color = COLORS.gray },
    }

    for index, item in ipairs(items) do
        local x = 18 + (((index - 1) % 2) * 138)
        local y = -34 - (math.floor((index - 1) / 2) * 22)
        local dot = MakeFrame(parent, x, y, 16, 16, COLORS.card, item.color)
        local label = MakeText(parent, item.label, "GameFontDisableSmall", nil, COLORS.muted)
        label:SetPoint("LEFT", dot, "RIGHT", 8, 0)
        label:SetSize(106, 16)
    end
end

function GearDashboard:RefreshSlotRow(row, plan)
    if not row or not plan then return end

    row.name:SetText(plan.displayName or plan.slot or "-")
    row.icon:SetTexture((plan.blank and nil) or plan.texture or "Interface\\Icons\\INV_Misc_QuestionMark")

    local stateColor = StateColor(plan.stateKey)
    if plan.blank then
        row:SetBackdropBorderColor(unpack(COLORS.softBorder))
        row.accent:SetColorTexture(0, 0, 0, 0)
        SetBadge(row.trackBadge, "")
        SetBadge(row.rankBadge, "")
        SetBadge(row.sourceBadge, "")
        SetBadge(row.statusBadge, "")
        for _, badge in ipairs(row.detailBadges or {}) do
            SetBadge(badge, "")
        end
        return
    end

    row:SetBackdropBorderColor(unpack(COLORS.softBorder))
    row.accent:SetColorTexture(0, 0, 0, 0)

    local showSource = ShouldShowSource(plan)
    local rankColor = RankColor(plan)
    SetOutlineBadge(row.trackBadge, plan.trackLabel or plan.trackName or "Unranked", COLORS.white, COLORS.text)
    SetOutlineBadge(row.rankBadge, plan.rankText or "", rankColor, COLORS.text)
    SetOutlineBadge(row.statusBadge, StatusBadgeText(plan), stateColor, COLORS.text)
    SetOutlineBadge(row.sourceBadge, showSource and plan.sourceText or "", COLORS.white, COLORS.text)

    local analyzedBadges = plan.badges or {}
    for index, badgeFrame in ipairs(row.detailBadges or {}) do
        local badge = analyzedBadges[index]
        if badge then
            local color = BadgeColor(badge)
            SetOutlineBadge(badgeFrame, BadgeText(badge), color, COLORS.text)
        else
            SetBadge(badgeFrame, "")
        end
    end
end

function GearDashboard:RefreshPrioritySlots(state)
    for index, row in ipairs(self.priorityRows or {}) do
        local plan = state.priorityPlans and state.priorityPlans[index]
        if plan then
            row:Show()
            local color = StateColor(plan.stateKey)
            row:SetBackdropBorderColor(unpack(color))
            row.slot:SetText(plan.displayName or plan.slot or "-")
            row.slot:SetTextColor(unpack(COLORS.text))
        else
            row:Show()
            row:SetBackdropBorderColor(unpack(COLORS.green))
            row.slot:SetText(index == 1 and "No priority slot" or "-")
            row.slot:SetTextColor(unpack(COLORS.muted))
        end
    end
end

function GearDashboard:RefreshActivities(state)
    for index, row in ipairs(self.activityRows or {}) do
        local activity = state.activities and state.activities[index]
        if activity then
            row:Show()
            for i = 1, 5 do
                row.blocks[i]:Hide()
            end
            row.label:SetText(activity.label or "-")
            row.label:SetTextColor(unpack(COLORS.text))
        else
            row:Hide()
        end
    end

    self.activityNote:SetText("")
    self.activityNote:Hide()
end

function GearDashboard:RefreshProgress(state)
    local progress = state.progress or {}
    local total = tonumber(progress.total) or 0
    local acquired = tonumber(progress.acquired) or 0
    local pct = total > 0 and math.max(0, math.min(1, acquired / total)) or 0

    self.progressBar:Show()
    self.progressBar.fill:SetWidth(math.max(1, 250 * pct))
    self.progressText:SetSize(150, 18)
    self.progressText:SetText(acquired .. " / " .. total .. " Targets Acquired")
    self.progressText:SetTextColor(unpack(COLORS.text))
    self.progressPercent:Show()
    self.progressPercent:SetText(total > 0 and (math.floor((pct * 100) + 0.5) .. "%") or "-")
    self.progressHint:SetText(total > 0 and "Saved targets drive dungeon hints." or "")
    self.progressHint:SetTextColor(unpack(COLORS.muted))

    if state.blockedMessage then
        self.blockMessageText:SetText(state.blockedMessage)
        self.blockMessageText:SetTextColor(unpack(COLORS.orange))
    else
        self.blockMessageText:SetText("")
    end
end

local function RefreshDashboard(self)
    if not IsVisible(self.frame) then return end
    self.refreshQueued = false

    local state
    if Analysis().GetDashboardState then
        state = Analysis().GetDashboardState()
    else
        state = { plansBySlot = {}, priorityPlans = {}, activities = {}, progress = {} }
    end

    self.itemLevelValue:SetText(state.itemLevel and FormatItemLevel(state.itemLevel) or "-")
    self.itemLevelSubtext:SetText(state.currentStatPriorityText or state.statPriorityText or "Stats unavailable")
    self.itemLevelSubtext:SetTextColor(unpack(state.statPriorityMismatch and COLORS.orange or COLORS.muted))

    for _, slotName in ipairs(Analysis().LeftSlots or {}) do
        self:RefreshSlotRow(self.leftSlots and self.leftSlots[slotName], state.plansBySlot and state.plansBySlot[slotName])
    end
    for _, slotName in ipairs(Analysis().RightSlots or {}) do
        self:RefreshSlotRow(self.rightSlots and self.rightSlots[slotName], state.plansBySlot and state.plansBySlot[slotName])
    end

    self:RefreshPrioritySlots(state)
    self:RefreshActivities(state)
    self:RefreshProgress(state)
end

function GearDashboard:Refresh()
    if self.isRefreshing then
        self.refreshQueued = false
        self.refreshPending = true
        return
    end

    self.isRefreshing = true
    local ok = pcall(RefreshDashboard, self)
    self.isRefreshing = false

    if not ok then
        self.refreshQueued = false
    end

    if self.refreshPending then
        self.refreshPending = false
        self:QueueRefresh()
    end
end

function GearDashboard:QueueRefresh(delay)
    if not IsVisible(self.frame) or self.refreshQueued then return end

    self.refreshQueued = true
    delay = tonumber(delay) or REFRESH_DEBOUNCE_SECONDS

    if C_Timer and C_Timer.After then
        C_Timer.After(delay, function()
            GearDashboard.refreshQueued = false
            if IsVisible(GearDashboard.frame) then
                GearDashboard:Refresh()
            end
        end)
    else
        self.refreshQueued = false
        self:Refresh()
    end
end

function GearDashboard:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabGearDashboardTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})
    self.frame = frame

    self:Build()

    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    frame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    frame:SetScript("OnEvent", function(_, event, slotID)
        if event == "PLAYER_EQUIPMENT_CHANGED" and Capture().MarkSlotChanged then
            Capture().MarkSlotChanged(slotID)
        elseif event == "ITEM_DATA_LOAD_RESULT" and Capture().MarkAllSlotsChanged then
            Capture().MarkAllSlotsChanged()
        end
        GearDashboard:QueueRefresh()
    end)
    frame:SetScript("OnShow", function() GearDashboard:Refresh() end)

    return frame
end

function KeyLab_CreateGearDashboardTab(parent)
    return GearDashboard:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Gear Dashboard", function(parent)
        return GearDashboard:Create(parent)
    end)
end

return GearDashboard
