-- KeyLab_GearDashboard.lua
-- Fixed-footprint character gear dashboard.

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
local SPACING = Theme.spacing or { card = 14, column = 12, slotCard = 10 }
local HEADER = Theme.tabHeader or { x = 18, titleY = -18, titleSize = 16 }
local SLOT_GAP = SPACING.slotCard
local CARD_GAP = SPACING.card
local BADGE_HEIGHT = 16
local REFRESH_DEBOUNCE_SECONDS = 0.35
local ALT_ROW_HEIGHT = 26

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

local function TierDB()
    return KeyLab and KeyLab.TierSetDB or {}
end

local function IsVisible(frame)
    if not frame then return false end
    if frame.IsVisible then return frame:IsVisible() end
    return frame:IsShown()
end

local function SetBackdrop(frame, color, borderColor)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(color or COLORS.card))
    frame:SetBackdropBorderColor(unpack(borderColor or COLORS.border))
end

local function MakeText(parent, text, template, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    if size then fs:SetFont(STANDARD_TEXT_FONT, size, "") end
    fs:SetTextColor(unpack(color or COLORS.text))
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("MIDDLE")
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

local function MakeCard(parent, x, y, width, height, title)
    local card = MakeFrame(parent, x, y, width, height, COLORS.card, COLORS.border)
    card.title = MakeText(card, title, "GameFontNormal", nil, COLORS.muted, "CENTER")
    card.title:SetPoint("TOP", card, "TOP", 0, -9)
    card.title:SetSize(width - 20, 18)
    return card
end

local function MakeBadge(parent, width)
    local badge = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    badge:SetSize(width or 60, BADGE_HEIGHT)
    SetBackdrop(badge, COLORS.card, COLORS.softBorder)
    badge.text = MakeText(badge, "", "GameFontDisableSmall", 8, COLORS.text, "CENTER")
    badge.text:SetAllPoints(badge)
    badge.text:SetJustifyH("CENTER")
    badge.text:SetJustifyV("MIDDLE")
    return badge
end

local function Dimmed(color, scale, alpha)
    color = color or COLORS.gray
    scale = scale or 0.24
    return {
        math.min(1, color[1] * scale),
        math.min(1, color[2] * scale),
        math.min(1, color[3] * scale),
        alpha or 0.82,
    }
end

local function SetBadge(badge, text, color)
    if not badge then return end
    text = tostring(text or "")
    if text == "" then
        badge:Hide()
        return
    end
    color = color or COLORS.gray
    badge:Show()
    badge:SetBackdropColor(unpack(Dimmed(color)))
    badge:SetBackdropBorderColor(unpack(color))
    badge.text:SetText(text)
    badge.text:SetTextColor(unpack(COLORS.text))
end

local function TrackColor(trackName)
    return TRACK_COLORS[trackName] or COLORS.gray
end

local function FormatItemLevel(value)
    value = tonumber(value)
    if not value then return "-" end
    if math.floor(value) == value then return tostring(value) end
    return string.format("%.1f", value)
end

local function ShortText(value, maxLength)
    value = tostring(value or "")
    maxLength = tonumber(maxLength) or 20
    if #value <= maxLength then return value end
    return value:sub(1, math.max(1, maxLength - 3)) .. "..."
end

local function ShowItemTooltip(owner, itemLink, fallback)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if itemLink and itemLink ~= "" then
        GameTooltip:SetHyperlink(itemLink)
    else
        GameTooltip:AddLine(fallback or "Item", 1, 1, 1)
        GameTooltip:Show()
    end
end

local function HideTooltip()
    if GameTooltip then GameTooltip:Hide() end
end

local function MakeSlotCard(parent, x, y, slotName)
    local row = MakeFrame(parent, x, y, SLOT_WIDTH, SLOT_HEIGHT, COLORS.slot, COLORS.softBorder)
    row.slotName = slotName

    row.iconBox = MakeFrame(row, 7, -14, 42, 44, COLORS.icon, COLORS.softBorder)
    row.icon = row.iconBox:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("CENTER", row.iconBox, "CENTER", 0, 0)
    row.icon:SetSize(36, 36)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.name = MakeText(row, slotName, "GameFontNormalSmall", 10, COLORS.text)
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 57, -8)
    row.name:SetSize(63, BADGE_HEIGHT)
    row.name:SetWordWrap(false)

    row.tierBadge = MakeBadge(row, 58)
    row.tierBadge:SetPoint("TOPLEFT", row, "TOPLEFT", 121, -8)

    row.trackBadge = MakeBadge(row, 82)
    row.trackBadge:SetPoint("TOPLEFT", row, "TOPLEFT", 182, -8)

    row.rankBadge = MakeBadge(row, 40)
    row.rankBadge:SetPoint("TOPLEFT", row, "TOPLEFT", 267, -8)

    row.action = MakeText(row, "", "GameFontDisableSmall", 10, COLORS.text)
    row.action:SetPoint("TOPLEFT", row, "TOPLEFT", 57, -28)
    row.action:SetSize(249, 16)
    row.action:SetWordWrap(false)

    row.sourceLabel = MakeText(row, "", "GameFontDisableSmall", 8, COLORS.muted)
    row.sourceLabel:SetPoint("TOPLEFT", row, "TOPLEFT", 57, -49)
    row.sourceLabel:SetSize(68, 16)
    row.sourceLabel:SetWordWrap(false)

    row.sourceBadges = {}
    for index = 1, 4 do
        local badge = MakeBadge(row, 41)
        badge:SetPoint("TOPLEFT", row, "TOPLEFT", 127 + ((index - 1) * 44), -49)
        row.sourceBadges[index] = badge
        badge:SetScript("OnLeave", HideTooltip)
    end

    row:SetScript("OnEnter", function(self)
        if self.itemLink then ShowItemTooltip(self, self.itemLink, self.itemName) end
    end)
    row:SetScript("OnLeave", HideTooltip)
    return row
end

local function MakeProgressBar(parent, x, y, width, height)
    local bar = MakeFrame(parent, x, y, width, height, {0.012, 0.020, 0.044, 0.92}, COLORS.softBorder)
    bar.fill = bar:CreateTexture(nil, "ARTWORK")
    bar.fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, -1)
    bar.fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 1, 1)
    bar.fill:SetWidth(1)
    bar.fill:SetColorTexture(unpack(COLORS.green))
    bar.fillWidth = width - 2
    return bar
end

function GearDashboard:BuildLegend(parent)
    local items = {
        { label = "Tier", color = COLORS.green },
        { label = "Need Tier", color = COLORS.yellow },
        { label = "Dungeon", color = COLORS.blue },
        { label = "Raid (Weekly)", color = COLORS.purple },
    }
    for index, item in ipairs(items) do
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        local dot = MakeFrame(parent, 14 + (column * 150), -31 - (row * 21), 14, 14, Dimmed(item.color), item.color)
        local label = MakeText(parent, item.label, "GameFontDisableSmall", 9, COLORS.muted)
        label:SetPoint("LEFT", dot, "RIGHT", 6, 0)
        label:SetSize(125, 14)
        label:SetWordWrap(false)
    end
end

function GearDashboard:BuildTierCard(parent)
    self.tierCount = MakeText(parent, "0 / 4", "GameFontHighlightSmall", 11, COLORS.gold, "RIGHT")
    self.tierCount:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -14, -10)
    self.tierCount:SetSize(70, 16)

    self.tierChecks = {}
    local slots = TierDB().GetSlots and TierDB().GetSlots() or { "Head", "Shoulders", "Chest", "Hands", "Legs" }
    for index, slotName in ipairs(slots) do
        local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", parent, "TOPLEFT", 23, -31 - ((index - 1) * 25))
        check:SetSize(22, 22)
        check.slotName = slotName
        check.label = MakeText(parent, slotName, "GameFontHighlightSmall", 11, COLORS.text)
        check.label:SetPoint("LEFT", check, "RIGHT", 5, 0)
        check.label:SetSize(170, 20)
        check:SetScript("OnClick", function(button)
            local checked = button:GetChecked() == true
            local current = TierDB().GetState and TierDB().GetState() or { count = 0 }
            if checked and not (current.slots and current.slots[button.slotName]) and (tonumber(current.count) or 0) >= 4 then
                button:SetChecked(false)
                GearDashboard.tierHelp:SetText("Uncheck one Tier slot before choosing another.")
                GearDashboard.tierHelp:SetTextColor(unpack(COLORS.orange))
                return
            end
            if TierDB().SetChecked then TierDB().SetChecked(button.slotName, checked) end
            GearDashboard:Refresh()
        end)
        self.tierChecks[slotName] = check
    end

    self.tierComplete = MakeText(parent, "", "GameFontHighlightSmall", 11, COLORS.green, "CENTER")
    self.tierComplete:SetPoint("TOP", parent, "TOP", 0, -154)
    self.tierComplete:SetSize(CENTER_WIDTH - 24, 18)

    self.tierHelp = MakeText(parent, "Only 4 of the 5 eligible slots are required for your 4-piece Tier Set.", "GameFontDisableSmall", 9, COLORS.muted, "CENTER")
    self.tierHelp:SetPoint("BOTTOM", parent, "BOTTOM", 0, 8)
    self.tierHelp:SetSize(CENTER_WIDTH - 28, 26)
end

function GearDashboard:BuildAlternativesCard(parent)
    self.altHeaderItem = MakeText(parent, "Alternative Item", "GameFontHighlightSmall", 10, COLORS.gold)
    self.altHeaderItem:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -31)
    self.altHeaderItem:SetSize(156, 18)
    self.altHeaderSource = MakeText(parent, "Source", "GameFontHighlightSmall", 10, COLORS.gold)
    self.altHeaderSource:SetPoint("TOPLEFT", parent, "TOPLEFT", 174, -31)
    self.altHeaderSource:SetSize(88, 18)

    self.altScroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    self.altScroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -52)
    self.altScroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -28, 12)
    self.altContent = CreateFrame("Frame", nil, self.altScroll)
    self.altContent:SetSize(248, 1)
    self.altScroll:SetScrollChild(self.altContent)
    self.altRows = {}

    self.altEmpty = MakeText(parent, "No Alternative items saved.", "GameFontDisableSmall", 10, COLORS.muted, "CENTER")
    self.altEmpty:SetPoint("CENTER", self.altScroll, "CENTER", 0, 0)
    self.altEmpty:SetSize(220, 20)
end

function GearDashboard:GetAlternativeRow(index)
    if self.altRows[index] then return self.altRows[index] end
    local row = CreateFrame("Frame", nil, self.altContent, "BackdropTemplate")
    row:SetPoint("TOPLEFT", self.altContent, "TOPLEFT", 0, -((index - 1) * ALT_ROW_HEIGHT))
    row:SetSize(248, ALT_ROW_HEIGHT - 2)
    SetBackdrop(row, index % 2 == 0 and {0.028, 0.045, 0.082, 0.72} or {0.020, 0.034, 0.068, 0.58}, COLORS.softBorder)
    row.item = MakeText(row, "", "GameFontDisableSmall", 9, COLORS.text)
    row.item:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.item:SetSize(154, ALT_ROW_HEIGHT - 4)
    row.item:SetWordWrap(false)
    row.source = MakeText(row, "", "GameFontDisableSmall", 9, COLORS.muted)
    row.source:SetPoint("LEFT", row, "LEFT", 164, 0)
    row.source:SetSize(78, ALT_ROW_HEIGHT - 4)
    row.source:SetWordWrap(false)
    row:SetScript("OnEnter", function(self)
        if not GameTooltip or not self.data then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.data.itemLink then GameTooltip:SetHyperlink(self.data.itemLink) else GameTooltip:AddLine(self.data.name or "Item", 1, 1, 1) end
        if self.data.sourceText and self.data.sourceText ~= "" then
            GameTooltip:AddLine("Source: " .. self.data.sourceText, 0.75, 0.82, 0.95, true)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", HideTooltip)
    self.altRows[index] = row
    return row
end

function GearDashboard:Build()
    if not self.frame then return end

    self.title = MakeText(self.frame, "Gear Dashboard", "GameFontNormalLarge", HEADER.titleSize, COLORS.gold)
    self.title:SetPoint("TOPLEFT", self.frame, "TOPLEFT", HEADER.x, HEADER.titleY)
    self.title:SetSize(420, 28)
    self.subtitle = MakeText(self.frame, "See your equipped gear, Tier progress, Targets, and Alternatives at a glance.", "GameFontHighlightSmall", nil, COLORS.muted)
    self.subtitle:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -4)
    self.subtitle:SetSize(900, 20)

    self.leftSlots, self.rightSlots = {}, {}
    local columnsWidth = SLOT_WIDTH + CENTER_WIDTH + SLOT_WIDTH + (SPACING.column * 2)
    local leftX = (CONTENT_WIDTH - columnsWidth) / 2
    local centerX = leftX + SLOT_WIDTH + SPACING.column
    local rightX = centerX + CENTER_WIDTH + SPACING.column
    local topY = -76
    for index, slotName in ipairs(Analysis().LeftSlots or {}) do
        self.leftSlots[slotName] = MakeSlotCard(self.frame, leftX, topY - ((index - 1) * (SLOT_HEIGHT + SLOT_GAP)), slotName)
    end
    for index, slotName in ipairs(Analysis().RightSlots or {}) do
        self.rightSlots[slotName] = MakeSlotCard(self.frame, rightX, topY - ((index - 1) * (SLOT_HEIGHT + SLOT_GAP)), slotName)
    end

    self.itemLevelCard = MakeCard(self.frame, centerX, -76, CENTER_WIDTH, 92, "Current Item Level")
    self.itemLevelValue = MakeText(self.itemLevelCard, "-", "GameFontNormalLarge", 32, COLORS.purple, "CENTER")
    self.itemLevelValue:SetPoint("CENTER", self.itemLevelCard, "CENTER", 0, -5)
    self.itemLevelValue:SetSize(CENTER_WIDTH - 20, 34)
    self.itemLevelSubtext = MakeText(self.itemLevelCard, "", "GameFontDisableSmall", 9, COLORS.muted, "CENTER")
    self.itemLevelSubtext:SetPoint("BOTTOM", self.itemLevelCard, "BOTTOM", 0, 8)
    self.itemLevelSubtext:SetSize(CENTER_WIDTH - 20, 14)

    local tierY = -76 - 92 - CARD_GAP
    self.tierCard = MakeCard(self.frame, centerX, tierY, CENTER_WIDTH, 210, "Tier Set")
    self.tierCard.title:SetJustifyH("LEFT")
    self.tierCard.title:ClearAllPoints()
    self.tierCard.title:SetPoint("TOPLEFT", self.tierCard, "TOPLEFT", 14, -9)
    self.tierCard.title:SetSize(120, 18)
    self:BuildTierCard(self.tierCard)

    local alternativesY = tierY - 210 - CARD_GAP
    self.alternativesCard = MakeCard(self.frame, centerX, alternativesY, CENTER_WIDTH, 404, "Alternative Items")
    self:BuildAlternativesCard(self.alternativesCard)

    local footerY = topY - (7 * (SLOT_HEIGHT + SLOT_GAP)) - SLOT_HEIGHT - CARD_GAP
    self.legendCard = MakeCard(self.frame, leftX, footerY, SLOT_WIDTH, 78, "Status Legend")
    self.legendCard.title:SetPoint("TOP", self.legendCard, "TOP", 0, -7)
    self:BuildLegend(self.legendCard)

    self.progressCard = MakeCard(self.frame, rightX, footerY, SLOT_WIDTH, 78, "Gear Target Progress")
    self.progressCard.title:SetPoint("TOP", self.progressCard, "TOP", 0, -7)
    self.progressBar = MakeProgressBar(self.progressCard, 16, -31, 284, 14)
    self.progressText = MakeText(self.progressCard, "0 / 0 Targets Equipped", "GameFontDisableSmall", 9, COLORS.text)
    self.progressText:SetPoint("TOPLEFT", self.progressBar, "BOTTOMLEFT", 0, -5)
    self.progressText:SetSize(200, 16)
    self.progressPercent = MakeText(self.progressCard, "-", "GameFontDisableSmall", 9, COLORS.text, "RIGHT")
    self.progressPercent:SetPoint("TOPRIGHT", self.progressBar, "BOTTOMRIGHT", 0, -5)
    self.progressPercent:SetSize(70, 16)
end

function GearDashboard:RefreshSourceBadges(row, plan)
    local sources = plan.guidanceSources or {}
    row.sourceLabel:SetText(#sources > 0 and (plan.sourceLabel or "Sources:") or "")
    local visibleCount = math.min(#sources, 4)
    for index, badge in ipairs(row.sourceBadges or {}) do
        badge.sourceTooltip = nil
        badge:SetScript("OnEnter", nil)
        if index <= visibleCount then
            local source = sources[index]
            local remaining = #sources - 3
            if index == 4 and #sources > 4 then
                local names = {}
                for sourceIndex = 4, #sources do table.insert(names, sources[sourceIndex].name) end
                SetBadge(badge, "+" .. tostring(remaining), COLORS.gold)
                badge.sourceTooltip = table.concat(names, "\n")
            else
                SetBadge(badge, ShortText(source.code, 7), source.sourceType == "Raid" and COLORS.purple or COLORS.blue)
                badge.sourceTooltip = source.name .. (source.sourceType == "Raid" and "\nWeekly raid opportunity" or "\nRepeatable dungeon source")
            end
            badge:SetScript("OnEnter", function(self)
                if not GameTooltip or not self.sourceTooltip then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                for line in tostring(self.sourceTooltip):gmatch("[^\n]+") do GameTooltip:AddLine(line, 0.85, 0.90, 1.0) end
                GameTooltip:Show()
            end)
        else
            SetBadge(badge, "")
        end
    end
end

function GearDashboard:RefreshSlotRow(row, plan)
    if not row or not plan then return end
    row.name:SetText(plan.displayName or plan.slotName or "-")
    row.icon:SetTexture(plan.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.icon:SetDesaturated(plan.blank == true)
    row.itemLink = plan.itemLink
    row.itemName = plan.target and plan.target.name or plan.displayName

    SetBadge(row.tierBadge, plan.tierBadge, plan.tierChecked and COLORS.green or COLORS.yellow)
    SetBadge(row.trackBadge, plan.trackLabel, TrackColor(plan.trackName))
    SetBadge(row.rankBadge, plan.rankText, TrackColor(plan.trackName))
    row.action:SetText(plan.actionText or "")
    if plan.targetEquipped or plan.tierChecked then
        row.action:SetTextColor(unpack(COLORS.green))
    elseif plan.tierNeeded then
        row.action:SetTextColor(unpack(COLORS.yellow))
    else
        row.action:SetTextColor(unpack(COLORS.text))
    end
    self:RefreshSourceBadges(row, plan)
end

function GearDashboard:RefreshTier(state)
    local tier = state.tier or { slots = {}, count = 0, complete = false }
    local count = tonumber(tier.count) or 0
    self.tierCount:SetText(math.min(count, 4) .. " / 4")
    for slotName, check in pairs(self.tierChecks or {}) do check:SetChecked(tier.slots and tier.slots[slotName] == true) end
    if tier.complete then
        self.tierComplete:SetText("4-Piece Complete")
        self.tierComplete:Show()
        self.tierHelp:SetText("Uncheck one slot first if you want to change which four Tier pieces you use.")
    else
        self.tierComplete:SetText("")
        self.tierComplete:Hide()
        self.tierHelp:SetText("Only 4 of the 5 eligible slots are required for your 4-piece Tier Set.")
    end
    self.tierHelp:SetTextColor(unpack(COLORS.muted))
end

function GearDashboard:RefreshAlternatives(state)
    local alternatives = state.alternatives or {}
    for index, item in ipairs(alternatives) do
        local row = self:GetAlternativeRow(index)
        row.data = item
        row.item:SetText(ShortText(item.name, 25))
        local codes = {}
        for _, source in ipairs(item.sources or {}) do table.insert(codes, source.code or source.name) end
        row.source:SetText(ShortText(#codes > 0 and table.concat(codes, ", ") or item.sourceText, 13))
        row.source:SetTextColor(unpack((item.sources and item.sources[1] and item.sources[1].sourceType == "Raid") and COLORS.purple or COLORS.muted))
        row:Show()
    end
    for index = #alternatives + 1, #(self.altRows or {}) do self.altRows[index]:Hide() end
    self.altContent:SetHeight(math.max(1, #alternatives * ALT_ROW_HEIGHT))
    self.altEmpty:SetShown(#alternatives == 0)
end

function GearDashboard:RefreshProgress(state)
    local progress = state.progress or {}
    local total = tonumber(progress.total) or 0
    local equipped = tonumber(progress.equipped) or 0
    local pct = total > 0 and math.max(0, math.min(1, equipped / total)) or 0
    self.progressBar.fill:SetWidth(math.max(1, self.progressBar.fillWidth * pct))
    self.progressText:SetText(equipped .. " / " .. total .. " Targets Equipped")
    self.progressPercent:SetText(total > 0 and (math.floor((pct * 100) + 0.5) .. "%") or "-")
end

local function RefreshDashboard(self)
    if not IsVisible(self.frame) then return end
    self.refreshQueued = false
    local state = Analysis().GetDashboardState and Analysis().GetDashboardState() or { plansBySlot = {}, tier = {}, alternatives = {}, progress = {} }
    self.itemLevelValue:SetText(FormatItemLevel(state.itemLevel))
    self.itemLevelSubtext:SetText(state.specName and ("Current Spec: " .. state.specName) or "Current Spec")
    for _, slotName in ipairs(Analysis().LeftSlots or {}) do self:RefreshSlotRow(self.leftSlots[slotName], state.plansBySlot[slotName]) end
    for _, slotName in ipairs(Analysis().RightSlots or {}) do self:RefreshSlotRow(self.rightSlots[slotName], state.plansBySlot[slotName]) end
    self:RefreshTier(state)
    self:RefreshAlternatives(state)
    self:RefreshProgress(state)
end

function GearDashboard:Refresh()
    if self.isRefreshing then
        self.refreshPending = true
        return
    end
    self.isRefreshing = true
    local ok = pcall(RefreshDashboard, self)
    self.isRefreshing = false
    if not ok then self.refreshQueued = false end
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
            if IsVisible(GearDashboard.frame) then GearDashboard:Refresh() end
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
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
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
    KeyLab.RegisterTab("Gear Dashboard", function(parent) return GearDashboard:Create(parent) end)
end

return GearDashboard
