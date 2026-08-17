-- KeyLab_UITheme.lua
-- Shared visual theme and lightweight UI helpers for KeyLab.
--
-- This intentionally uses only built-in WoW solid-color textures so the addon
-- does not need to load custom media files.

local ADDON_NAME, KeyLab = ...

KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}

local Theme = KeyLab.UI.Theme or {}
KeyLab.UI.Theme = Theme

Theme.colors = {
    -- Surfaces
    bg = {0.018, 0.026, 0.056, 0.98},
    windowBg = {0.018, 0.026, 0.056, 0.98},
    windowBorder = {0.240, 0.380, 0.620, 0.62},
    headerBg = {0.020, 0.034, 0.066, 0.64},
    headerBorder = {0.240, 0.380, 0.620, 0.58},
    sidebarBg = {0.016, 0.026, 0.052, 0.90},
    sidebarBorder = {0.220, 0.340, 0.560, 0.55},
    contentBg = {0.012, 0.020, 0.044, 0.86},
    contentBorder = {0.200, 0.320, 0.520, 0.46},
    controlBg = {0.026, 0.046, 0.088, 0.90},
    transparent = {0, 0, 0, 0},

    -- Panels and cards
    panel = {0.026, 0.046, 0.086, 0.84},
    card = {0.030, 0.052, 0.098, 0.84},
    cardBg = {0.030, 0.052, 0.098, 0.84},
    cardBorder = {0.240, 0.380, 0.620, 0.62},
    cardStrongBorder = {0.620, 0.560, 0.410, 0.70},
    border = {0.240, 0.380, 0.620, 0.62},
    softBorder = {0.185, 0.300, 0.500, 0.50},
    detailBg = {0.024, 0.042, 0.082, 0.88},
    detailBorder = {0.220, 0.340, 0.560, 0.56},
    noteBg = {0.030, 0.052, 0.094, 0.82},
    box = {0.026, 0.046, 0.086, 0.82},
    slot = {0.030, 0.052, 0.098, 0.76},
    icon = {0.012, 0.020, 0.044, 0.94},

    -- Buttons and badges
    buttonBg = {0.022, 0.038, 0.076, 0.82},
    buttonBorder = {0.220, 0.340, 0.560, 0.58},
    buttonHover = {0.300, 0.420, 0.600, 0.78},
    buttonSelected = {0.820, 0.760, 0.580, 1.0},
    buttonSelectedBg = {0.030, 0.050, 0.086, 0.95},
    badgeBg = {0.020, 0.034, 0.066, 0.80},
    badgeBorder = {0.220, 0.340, 0.560, 0.58},

    -- Progress bars
    barBg = {0.012, 0.020, 0.044, 0.92},
    barBorder = {0.185, 0.300, 0.500, 0.50},
    progressTrack = {0.012, 0.020, 0.044, 0.92},
    progressFill = {0.460, 0.780, 0.500, 0.95},

    -- Typography
    text = {0.940, 0.960, 0.990, 1.0},
    muted = {0.680, 0.730, 0.820, 1.0},
    soft = {0.780, 0.830, 0.900, 1.0},
    gold = {0.820, 0.760, 0.580, 1.0},
    goldDim = {0.660, 0.600, 0.460, 1.0},
    white = {0.900, 0.920, 0.960, 0.95},
    gray = {0.620, 0.670, 0.740, 1.0},
    divider = {0.440, 0.580, 0.780, 0.32},

    -- Shared analysis presentation. These names are the contract used by
    -- Encounters, Talent Builds, Stat Profiles, and Gear Profiles on both
    -- the Mythic+ and Raid sides.
    analysisPageBg = {0.018, 0.026, 0.056, 0.96},
    analysisFilterBg = {0.026, 0.046, 0.088, 0.78},
    analysisFilterBorder = {0.240, 0.380, 0.620, 0.54},
    analysisDropdownBg = {0.050, 0.086, 0.155, 0.96},
    analysisRowBg = {0.018, 0.032, 0.064, 0.42},
    analysisRowHoverBg = {0.030, 0.052, 0.098, 0.62},
    analysisRowSelectedBg = {0.030, 0.052, 0.098, 0.76},
    analysisRowRule = {0.440, 0.580, 0.780, 0.28},
    analysisDetailBg = {0.018, 0.030, 0.060, 0.70},
    analysisDetailRule = {0.440, 0.580, 0.780, 0.50},
    inputBg = {0.012, 0.020, 0.044, 0.94},
    inputBorder = {0.240, 0.380, 0.620, 0.62},

    -- Accents
    blue = {0.500, 0.680, 0.940, 0.95},
    green = {0.460, 0.780, 0.500, 0.95},
    yellow = {0.840, 0.720, 0.420, 0.95},
    warning = {0.840, 0.720, 0.420, 0.95},
    orange = {0.860, 0.580, 0.340, 0.95},
    red = {0.840, 0.440, 0.420, 0.95},
    purple = {0.680, 0.560, 0.880, 0.95},

    -- Stat accents
    crit = {0.840, 0.440, 0.420, 0.95},
    haste = {0.840, 0.720, 0.420, 0.95},
    mastery = {0.500, 0.680, 0.940, 0.95},
    versatility = {0.460, 0.780, 0.500, 0.95},
    fallback = {0.780, 0.830, 0.900, 0.90},
}

-- Upgrade-track accents are shared presentation tokens. Reference screens may
-- use these for borders, labels, and narrow accents, while retaining KeyLab's
-- dark surfaces and readable primary text.
Theme.gearTrackColors = {
    unranked = {0.470, 0.590, 0.540, 0.92},
    adventurer = {0.360, 0.620, 0.960, 0.95},
    veteran = {0.650, 0.490, 0.900, 0.95},
    champion = {0.930, 0.380, 0.300, 0.95},
    hero = {0.940, 0.570, 0.200, 0.95},
    myth = {0.940, 0.770, 0.300, 0.95},
}

function Theme.GetGearTrackColor(trackID)
    return Theme.gearTrackColors[tostring(trackID or ""):lower()]
        or Theme.colors.muted
end

Theme.fonts = {
    heading = "Fonts\\FRIZQT__.TTF",
    body = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
    titleSize = 32,
    sectionSize = 18,
    valueSize = 16,
    smallSize = 11,
}

Theme.backdrop = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false,
    edgeSize = 1,
    insets = nil,
}

Theme.card = {
    accentWidth = 0,
    showAccent = false,
    titleX = 14,
    titleY = -10,
}

Theme.analysisStyle = {
    pageBg = Theme.colors.analysisPageBg,
    filterBg = Theme.colors.analysisFilterBg,
    filterBorder = Theme.colors.analysisFilterBorder,
    rowBg = Theme.colors.analysisRowBg,
    rowHoverBg = Theme.colors.analysisRowHoverBg,
    rowSelectedBg = Theme.colors.analysisRowSelectedBg,
    rowRule = Theme.colors.analysisRowRule,
    selectedAccent = Theme.colors.gold,
    detailBg = Theme.colors.analysisDetailBg,
    detailRule = Theme.colors.analysisDetailRule,
    inputBg = Theme.colors.inputBg,
    inputBorder = Theme.colors.inputBorder,
}

-- Typography roles shared by every analysis result row. Tab files should use
-- these roles instead of choosing their own point sizes.
Theme.analysisText = {
    rowRank = { font = Theme.fonts.body, size = 12, color = Theme.colors.blue },
    rowRankSelected = { font = Theme.fonts.body, size = 12, color = Theme.colors.gold },
    rowTitle = { font = Theme.fonts.body, size = 12, color = Theme.colors.text },
    rowMeta = { font = Theme.fonts.body, size = 11, color = Theme.colors.muted },
    rowMetric = { font = Theme.fonts.body, size = 12, color = Theme.colors.blue },
}

-- Compatibility map for the older analysis-tab CFG tables. Keeping this map
-- in the theme lets the tabs retain their data-oriented CFG names while the
-- values themselves come from one addon-wide source.
Theme.analysisColors = {
    bg = Theme.colors.analysisPageBg,
    controlBg = Theme.colors.analysisFilterBg,
    cardBg = Theme.colors.analysisRowBg,
    cardBorder = Theme.colors.analysisRowRule,
    cardHoverBorder = Theme.colors.blue,
    cardSelectedBorder = Theme.colors.gold,
    detailBg = Theme.colors.analysisDetailBg,
    detailBorder = Theme.colors.analysisDetailRule,
    noteBg = Theme.colors.noteBg,
    text = Theme.colors.text,
    muted = Theme.colors.muted,
    soft = Theme.colors.soft,
    gold = Theme.colors.gold,
    blue = Theme.colors.blue,
    green = Theme.colors.green,
    warning = Theme.colors.warning,
    red = Theme.colors.red,
    divider = Theme.colors.divider,
    crit = Theme.colors.crit,
    haste = Theme.colors.haste,
    mastery = Theme.colors.mastery,
    versatility = Theme.colors.versatility,
    barBg = Theme.colors.barBg,
    barBorder = Theme.colors.barBorder,
    barFill = Theme.colors.blue,
    barFillSelected = Theme.colors.gold,
    fallbackBar = Theme.colors.fallback,
}

-- Shared spacing rhythm. Normal cards use one consistent gap throughout the
-- addon; compact lists and the fixed Gear Dashboard slot grid stay tighter so
-- their established card counts still fit without resizing.
Theme.spacing = {
    card = 14,
    column = 12,
    compactCard = 8,
    slotCard = 10,
    section = 18,
}

-- Shared Home/article-reader geometry. The Home tab owns its content, while
-- these values keep its navigation, list, reader, and scroll presentation in
-- the same theme contract as the rest of KeyLab.
Theme.homeLayout = {
    outerX = 18,
    outerRight = 18,
    titleY = -18,
    subtitleY = -48,
    subTabsY = -78,
    subTabHeight = 34,
    subTabGap = 8,
    subTabRuleY = -114,
    contentY = -128,
    contentBottom = 16,
    articleListWidth = 270,
    articlePaneGap = 16,
    panelPadding = 14,
    listRowHeight = 92,
    listRowGap = 2,
    readerPadding = 18,
    scrollBarWidth = 5,
}

Theme.articleText = {
    eyebrow = { font = Theme.fonts.body, size = 11, color = Theme.colors.blue },
    title = { font = Theme.fonts.body, size = 24, color = Theme.colors.gold },
    heading = { font = Theme.fonts.body, size = 18, color = Theme.colors.text },
    subheading = { font = Theme.fonts.body, size = 15, color = Theme.colors.text },
    body = { font = Theme.fonts.body, size = 12, color = Theme.colors.text },
    meta = { font = Theme.fonts.body, size = 11, color = Theme.colors.muted },
    footer = { font = Theme.fonts.body, size = 10, color = Theme.colors.muted },
}

-- Shared top-of-tab geometry. Analysis tabs reserve a third line for their
-- live summary before filters; standard tabs move directly from description
-- to content.
Theme.tabHeader = {
    x = 18,
    titleY = -18,
    titleSize = 16,
    titleWidth = 900,
    titleHeight = 24,
    descriptionGap = 8,
    descriptionY = -50,
    descriptionWidth = 900,
    descriptionHeight = 20,
    summaryY = -72,
    summaryWidth = 890,
    summaryHeight = 14,
    standardContentY = -86,
    analysisControlsY = -92,
    analysisContentY = -178,
}

Theme.badge = {
    height = 16,
    bg = Theme.colors.badgeBg,
    border = Theme.colors.badgeBorder,
}

Theme.progress = {
    height = 16,
    bg = Theme.colors.progressTrack,
    border = Theme.colors.barBorder,
    fill = Theme.colors.progressFill,
}

local function ResolveColor(color, fallback)
    if type(color) == "table" then
        return color
    end

    if type(color) == "string" and Theme.colors[color] then
        return Theme.colors[color]
    end

    if type(fallback) == "table" then
        return fallback
    end

    if type(fallback) == "string" and Theme.colors[fallback] then
        return Theme.colors[fallback]
    end

    return Theme.colors.text
end

local function Components(color, fallback)
    local c = ResolveColor(color, fallback)
    return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
end

function Theme.GetColor(color, fallback)
    return ResolveColor(color, fallback)
end

function Theme.WithAlpha(color, alpha)
    local c = ResolveColor(color, Theme.colors.text)
    return {c[1] or 1, c[2] or 1, c[3] or 1, alpha or c[4] or 1}
end

function Theme.Shade(color, scale, alpha)
    local c = ResolveColor(color, Theme.colors.text)
    scale = tonumber(scale) or 1
    return {
        math.min(1, (c[1] or 1) * scale),
        math.min(1, (c[2] or 1) * scale),
        math.min(1, (c[3] or 1) * scale),
        alpha or c[4] or 1,
    }
end

function Theme.ApplyColor(region, color, fallback)
    if not region or not region.SetTextColor then
        return
    end

    region:SetTextColor(Components(color, fallback or Theme.colors.text))
end

function Theme.ApplyTextRole(region, role, colorOverride)
    if not region then return end
    local style = Theme.analysisText and Theme.analysisText[role]
    if not style then
        Theme.ApplyColor(region, colorOverride or Theme.colors.text)
        return
    end
    if region.SetFont then
        region:SetFont(style.font or Theme.fonts.body, style.size or Theme.fonts.smallSize, style.flags or "")
    end
    if region.SetShadowColor then region:SetShadowColor(0, 0, 0, 0) end
    if region.SetShadowOffset then region:SetShadowOffset(0, 0) end
    Theme.ApplyColor(region, colorOverride or style.color or Theme.colors.text)
end

function Theme.FormatRank(index)
    return string.format("%02d", math.max(0, tonumber(index) or 0))
end

function Theme.StylePanel(frame, bg, border, edgeSize)
    if not frame or not frame.SetBackdrop then
        return
    end

    local resolvedEdgeSize = edgeSize or Theme.backdrop.edgeSize or 1
    local edgeFile = Theme.backdrop.edgeFile
    local insets = Theme.backdrop.insets

    if resolvedEdgeSize <= 1 or (frame.GetHeight and (frame:GetHeight() or 0) <= 20) then
        edgeFile = "Interface\\Buttons\\WHITE8x8"
        resolvedEdgeSize = 1
        insets = nil
    end

    local backdrop = {
        bgFile = Theme.backdrop.bgFile,
        edgeFile = edgeFile,
        tile = false,
        edgeSize = resolvedEdgeSize,
        insets = insets,
    }

    frame:SetBackdrop(backdrop)
    frame:SetBackdropColor(Components(bg, Theme.colors.cardBg))
    frame:SetBackdropBorderColor(Components(border, Theme.colors.cardBorder))
end

Theme.SetBackdrop = Theme.StylePanel

function Theme.CreateText(parent, text, template, size, color, justify, fontPath)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")

    if size then
        fs:SetFont(fontPath or Theme.fonts.body, size, "")
    end

    fs:SetTextColor(Components(color, Theme.colors.text))
    if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 0) end
    if fs.SetShadowOffset then fs:SetShadowOffset(0, 0) end
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetText(text or "")

    return fs
end

function Theme.CreatePanel(parent, x, y, width, height, bg, border)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, y or 0)
    panel:SetSize(width or 100, height or 100)
    Theme.StylePanel(panel, bg or Theme.colors.panel, border or Theme.colors.cardBorder)
    return panel
end

function Theme.CreateRule(parent, anchor, color, thickness)
    if not parent then return nil end
    local rule = parent:CreateTexture(nil, "ARTWORK")
    local edge = anchor or "BOTTOM"
    local size = tonumber(thickness) or 1
    if edge == "TOP" then
        rule:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        rule:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
        rule:SetHeight(size)
    elseif edge == "LEFT" then
        rule:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        rule:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
        rule:SetWidth(size)
    elseif edge == "RIGHT" then
        rule:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
        rule:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
        rule:SetWidth(size)
    else
        rule:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
        rule:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
        rule:SetHeight(size)
    end
    rule:SetColorTexture(Components(color, Theme.colors.divider))
    return rule
end

function Theme.CreateFieldUnderline(parent, x, labelY, width, color)
    if not parent then return nil end
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, (tonumber(labelY) or 0) - 48)
    line:SetSize(width or 120, 1)
    line:SetColorTexture(Components(color, Theme.colors.blue))
    return line
end

function Theme.CreateAnalysisFilterLabel(parent, text, x, width)
    if not parent then return nil end
    local layout = Theme.analysisLayout
    local label = Theme.CreateText(parent, text or "", "GameFontDisableSmall", nil, Theme.colors.muted)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x or layout.filterPadding, layout.filterLabelY)
    label:SetSize(width or 160, layout.filterLabelHeight or 18)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    return label
end

function Theme.StyleAnalysisPage(frame)
    Theme.StylePanel(frame, Theme.analysisStyle.pageBg, Theme.colors.transparent, 0)
end

function Theme.StyleAnalysisRow(frame, state)
    if not frame then return end
    state = state or "normal"
    local background = Theme.analysisStyle.rowBg
    if state == "selected" then
        background = Theme.analysisStyle.rowSelectedBg
    elseif state == "hover" then
        background = Theme.analysisStyle.rowHoverBg
    end
    Theme.StylePanel(frame, background, Theme.colors.transparent, 0)

    if not frame.keylabTopRule then
        frame.keylabTopRule = Theme.CreateRule(frame, "TOP", Theme.analysisStyle.rowRule, 1)
        frame.keylabBottomRule = Theme.CreateRule(frame, "BOTTOM", Theme.analysisStyle.rowRule, 1)
        frame.keylabSelectedAccent = Theme.CreateRule(frame, "LEFT", Theme.analysisStyle.selectedAccent, 3)
    end
    frame.keylabTopRule:Show()
    frame.keylabBottomRule:Show()
    frame.keylabSelectedAccent:SetShown(state == "selected")
    if frame.rankText then
        Theme.ApplyTextRole(frame.rankText, state == "selected" and "rowRankSelected" or "rowRank")
    end
end

function Theme.StyleAnalysisDetails(frame)
    if not frame then return end
    Theme.StylePanel(frame, Theme.analysisStyle.detailBg, Theme.colors.transparent, 0)
    if not frame.keylabDrawerRule then
        frame.keylabDrawerRule = Theme.CreateRule(frame, "TOP", Theme.analysisStyle.detailRule, 1)
    end
    frame.keylabDrawerRule:Show()
end

function Theme.CreateInput(parent, width, height)
    local input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    input:SetSize(width or 160, height or 28)
    input:SetAutoFocus(false)
    input:SetFont(Theme.fonts.body, 11, "")
    input:SetTextColor(Components(Theme.colors.text))
    input:SetTextInsets(8, 8, 0, 0)
    Theme.StylePanel(input, Theme.analysisStyle.inputBg, Theme.analysisStyle.inputBorder, 1)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    input:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(Components(Theme.colors.gold))
    end)
    input:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(Components(Theme.analysisStyle.inputBorder))
    end)
    return input
end

function Theme.AddAccent(frame, color, width)
    if not frame then
        return nil
    end

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(width or Theme.card.accentWidth or 3)
    accent:SetColorTexture(Components(color, Theme.colors.goldDim))
    frame.accent = accent

    return accent
end

function Theme.CreateCard(parent, x, y, width, height, title, accentColor, options)
    options = options or {}

    local card = Theme.CreatePanel(
        parent,
        x,
        y,
        width,
        height,
        options.bg or Theme.colors.cardBg,
        options.border or Theme.colors.cardBorder
    )

    if options.showAccent == true or Theme.card.showAccent == true then
        Theme.AddAccent(card, accentColor or options.accentColor or Theme.colors.goldDim, options.accentWidth)
    end

    if title and title ~= "" then
        local titleText = Theme.CreateText(card, title, "GameFontNormal", nil, Theme.colors.gold)
        titleText:SetPoint("TOPLEFT", card, "TOPLEFT", options.titleX or Theme.card.titleX, options.titleY or Theme.card.titleY)
        titleText:SetSize(width - ((options.titleX or Theme.card.titleX) * 2), 18)
        card.title = titleText
    end

    return card
end

function Theme.CreateTabHeader(parent, title, subtitle, options)
    options = options or {}
    local header = Theme.tabHeader
    local x = options.x or header.x
    local y = options.y or header.titleY
    local width = options.width or header.titleWidth

    local titleText = Theme.CreateText(parent, title, "GameFontNormalLarge", header.titleSize, Theme.colors.gold)
    titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    titleText:SetSize(width, header.titleHeight)

    local subtitleText
    if subtitle and subtitle ~= "" then
        subtitleText = Theme.CreateText(parent, subtitle, "GameFontHighlightSmall", nil, Theme.colors.muted)
        subtitleText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -(header.descriptionGap or 8))
        subtitleText:SetSize(options.descriptionWidth or header.descriptionWidth, options.descriptionHeight or header.descriptionHeight)
    end

    return titleText, subtitleText
end

function Theme.CreateSectionHeader(parent, title, subtitle, x, y, width)
    return Theme.CreateTabHeader(parent, title, subtitle, {
        x = x,
        y = y,
        width = width,
        descriptionWidth = width,
    })
end

-- Shared analysis-tab structure -------------------------------------------
-- Analysis tabs use this one
-- geometry source on both the Mythic+ and Raid sides. Individual tab files
-- still own the data displayed inside their result and detail cards, but not
-- the placement, margins, filter spacing, or pagination styling.
Theme.analysisLayout = {
    outerX = 12,
    width = 928,
    nameDescY = -8,
    nameDescHeight = 66,
    titleX = 6,
    titleY = -8,
    titleWidth = 720,
    titleHeight = 22,
    descriptionY = -35,
    descriptionWidth = 720,
    descriptionHeight = 18,
    filterY = -86,
    filterHeight = 96,
    filterPadding = 18,
    summaryX = 16,
    summaryY = -10,
    summaryWidth = 896,
    summaryHeight = 14,
    filterLabelY = -36,
    filterLabelHeight = 18,
    filterControlOffsetX = -18,
    filterControlOffsetY = -18,
    resultsY = -196,
    pageSize = 5,
    cardHeight = 44,
    cardGap = 8,
    resultsHeight = 252,
    detailsY = -466,
    detailsHeight = 300,
    pagerY = 18,
    pagerLabelX = 18,
    pagerLabelWidth = 360,
    pagerButtonWidth = 90,
    pagerButtonHeight = 24,
    pagerRight = 12,
    pagerButtonGap = 10,
}

Theme.analysisFourFilterWidths = { 185, 90, 170, 180 }

Theme.practiceLayout = {
    outerX = Theme.analysisLayout.outerX,
    width = Theme.analysisLayout.width,
    newSessionY = Theme.analysisLayout.filterY,
    newSessionHeight = 96,
    filtersY = -196,
    filtersHeight = 96,
    tableY = -306,
    pageSize = 5,
    detailsY = -592,
    detailsHeight = 192,
}

function Theme.GetFilterPositions(widths, options)
    options = options or {}
    local layout = Theme.analysisLayout
    local cardWidth = tonumber(options.cardWidth) or layout.width
    local padding = tonumber(options.padding) or layout.filterPadding
    local count = #(widths or {})
    local positions = {}
    if count == 0 then return positions, 0 end

    local used = 0
    for _, width in ipairs(widths) do used = used + (tonumber(width) or 0) end
    local available = math.max(0, cardWidth - (padding * 2))
    local gap = count > 1 and math.max(8, (available - used) / (count - 1)) or 0
    local x = padding
    for index, width in ipairs(widths) do
        positions[index] = math.floor(x + 0.5)
        x = x + (tonumber(width) or 0) + gap
    end
    return positions, gap
end

function Theme.CreateNameDescCard(parent, title, description, options)
    options = options or {}
    local layout = Theme.analysisLayout
    local card = CreateFrame("Frame", nil, parent)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", layout.outerX, layout.nameDescY)
    card:SetSize(layout.width, layout.nameDescHeight)

    local titleText = Theme.CreateText(card, title or "", "GameFontNormalLarge", Theme.tabHeader.titleSize, Theme.colors.gold)
    titleText:SetPoint("TOPLEFT", card, "TOPLEFT", layout.titleX, layout.titleY)
    titleText:SetSize(layout.titleWidth, layout.titleHeight)

    local descriptionText = Theme.CreateText(card, description or "", "GameFontHighlightSmall", nil, Theme.colors.muted)
    descriptionText:SetPoint("TOPLEFT", card, "TOPLEFT", layout.titleX, layout.descriptionY)
    descriptionText:SetSize(layout.descriptionWidth, layout.descriptionHeight)

    local seasonFilter
    if options.seasonFilter ~= false and KeyLab.UI.SeasonFilter and KeyLab.UI.SeasonFilter.Attach then
        seasonFilter = KeyLab.UI.SeasonFilter.Attach(card, { x = -2, y = -2 })
        parent.keylabSeasonFilter = seasonFilter
    end
    return card, titleText, descriptionText, seasonFilter
end

function Theme.CreateAnalysisPage(parent, title, description, options)
    options = options or {}
    local layout = Theme.analysisLayout
    local page = {}

    page.nameDescCard, page.title, page.description, page.seasonFilter = Theme.CreateNameDescCard(parent, title, description, options)

    page.filterHeaderCard = Theme.CreatePanel(
        parent,
        layout.outerX,
        layout.filterY,
        layout.width,
        layout.filterHeight,
        Theme.analysisStyle.filterBg,
        Theme.analysisStyle.filterBorder
    )
    page.summaryText = Theme.CreateText(page.filterHeaderCard, options.summaryText or "", "GameFontDisableSmall", nil, Theme.colors.soft)
    page.summaryText:SetPoint("TOPLEFT", page.filterHeaderCard, "TOPLEFT", layout.summaryX, layout.summaryY)
    page.summaryText:SetSize(layout.summaryWidth, layout.summaryHeight)
    page.summaryText:SetShown(options.showSummary == true)

    page.encountersCards = CreateFrame("Frame", nil, parent)
    page.encountersCards:SetPoint("TOPLEFT", parent, "TOPLEFT", layout.outerX, layout.resultsY)
    page.encountersCards:SetSize(layout.width, layout.resultsHeight)

    if options.details ~= false then
        page.detailsCard = Theme.CreatePanel(
            parent,
            layout.outerX,
            layout.detailsY,
            layout.width,
            tonumber(options.detailsHeight) or layout.detailsHeight,
            Theme.analysisStyle.detailBg,
            Theme.colors.transparent
        )
        Theme.StyleAnalysisDetails(page.detailsCard)
    end

    parent.nameDescCard = page.nameDescCard
    parent.filterHeaderCard = page.filterHeaderCard
    parent.encountersCards = page.encountersCards
    parent.detailsCard = page.detailsCard
    return page
end

local function ApplyKeyLabButtonStyle(button, hovered)
    if not button then return end
    local enabled = button.IsEnabled and button:IsEnabled()
    local border = enabled and hovered and Theme.colors.buttonHover or Theme.colors.buttonBorder
    local text = enabled and (hovered and Theme.colors.gold or Theme.colors.text) or Theme.colors.muted
    button:SetBackdropColor(Components(Theme.colors.buttonBg))
    button:SetBackdropBorderColor(Components(border))
    Theme.ApplyColor(button.label, text)
end

function Theme.CreateButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 90, height or 24)
    Theme.StylePanel(button, Theme.colors.buttonBg, Theme.colors.buttonBorder)
    button.label = Theme.CreateText(button, text or "", "GameFontHighlightSmall", 11, Theme.colors.text, "CENTER")
    button.label:SetAllPoints(button)
    button.label:SetJustifyH("CENTER")
    button.label:SetJustifyV("MIDDLE")
    button.SetText = function(self, value)
        self.label:SetText(value or "")
    end
    button:SetScript("OnEnter", function(self) ApplyKeyLabButtonStyle(self, true) end)
    button:SetScript("OnLeave", function(self) ApplyKeyLabButtonStyle(self, false) end)
    button:HookScript("OnEnable", function(self) ApplyKeyLabButtonStyle(self, false) end)
    button:HookScript("OnDisable", function(self) ApplyKeyLabButtonStyle(self, false) end)
    ApplyKeyLabButtonStyle(button, false)
    return button
end

-- A restrained primary-action treatment for one important action on a page.
-- It uses the same KeyLab button structure with a brighter navy surface and
-- gold identification instead of adding a glow or Blizzard texture.
function Theme.StylePrimaryActionButton(button)
    if not button then return button end
    if not button.keylabPrimaryAccent then
        button.keylabPrimaryAccent = Theme.CreateRule(button, "BOTTOM", Theme.colors.gold, 2)
    end

    local function ApplyPrimaryStyle(self, state)
        local enabled = not self.IsEnabled or self:IsEnabled()
        local background = Theme.colors.analysisDropdownBg
        local border = Theme.colors.goldDim
        local text = Theme.colors.gold
        if not enabled then
            background = Theme.colors.buttonBg
            border = Theme.colors.buttonBorder
            text = Theme.colors.muted
        elseif state == "pressed" then
            background = Theme.colors.buttonSelectedBg
            border = Theme.colors.gold
        elseif state == "hover" then
            background = Theme.WithAlpha(Theme.colors.buttonHover, 0.42)
            border = Theme.colors.gold
            text = Theme.colors.text
        end
        self:SetBackdropColor(Components(background))
        self:SetBackdropBorderColor(Components(border))
        Theme.ApplyColor(self.label, text)
        self.keylabPrimaryAccent:SetShown(enabled)
        self.keylabPrimaryAccent:SetColorTexture(Components(enabled and Theme.colors.gold or Theme.colors.buttonBorder))
    end

    button:SetScript("OnEnter", function(self) ApplyPrimaryStyle(self, "hover") end)
    button:SetScript("OnLeave", function(self) ApplyPrimaryStyle(self, "rest") end)
    button:SetScript("OnMouseDown", function(self) ApplyPrimaryStyle(self, "pressed") end)
    button:SetScript("OnMouseUp", function(self)
        ApplyPrimaryStyle(self, self:IsMouseOver() and "hover" or "rest")
    end)
    button:HookScript("OnEnable", function(self) ApplyPrimaryStyle(self, "rest") end)
    button:HookScript("OnDisable", function(self) ApplyPrimaryStyle(self, "rest") end)
    ApplyPrimaryStyle(button, "rest")
    return button
end

-- Flat text tabs used by Home's internal navigation, article modes, and class
-- navigation. They deliberately avoid Blizzard tab textures.
function Theme.CreateTextTabButton(parent, text, width, height, options)
    options = options or {}
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 120, height or 30)
    Theme.StylePanel(button, Theme.colors.transparent, Theme.colors.transparent, 0)

    button.label = Theme.CreateText(
        button,
        text or "",
        "GameFontHighlightSmall",
        options.fontSize or 11,
        Theme.colors.text,
        "CENTER"
    )
    button.label:SetPoint("LEFT", button, "LEFT", 7, 0)
    button.label:SetPoint("RIGHT", button, "RIGHT", -7, 0)
    button.label:SetHeight((height or 30) - 4)
    button.label:SetJustifyV("MIDDLE")

    button.underline = button:CreateTexture(nil, "ARTWORK")
    button.underline:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", options.underlineInset or 4, 0)
    button.underline:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -(options.underlineInset or 4), 0)
    button.underline:SetHeight(options.underlineHeight or 2)
    button.underline:SetColorTexture(Components(Theme.colors.gold))

    function button:SetSelected(selected)
        self.selected = selected == true
        self.underline:SetShown(self.selected)
        Theme.ApplyColor(self.label, self.selected and Theme.colors.gold or Theme.colors.text)
        self:SetBackdropColor(Components(Theme.colors.transparent))
    end

    button:SetScript("OnEnter", function(self)
        if not self.selected then Theme.ApplyColor(self.label, Theme.colors.blue) end
        self:SetBackdropColor(Components(Theme.WithAlpha(Theme.colors.controlBg, 0.56)))
    end)
    button:SetScript("OnLeave", function(self)
        Theme.ApplyColor(self.label, self.selected and Theme.colors.gold or Theme.colors.text)
        self:SetBackdropColor(Components(Theme.colors.transparent))
    end)
    button:SetSelected(false)
    return button
end

-- Lays out variable-width buttons in as many rows as needed. Buttons may
-- provide keylabDesiredWidth; otherwise their label width is measured.
function Theme.LayoutWrappedButtons(buttons, container, availableWidth, options)
    options = options or {}
    local x = 0
    local row = 1
    local height = tonumber(options.buttonHeight) or 28
    local columnGap = tonumber(options.columnGap) or 10
    local rowGap = tonumber(options.rowGap) or 6
    local horizontalPadding = tonumber(options.horizontalPadding) or 18
    availableWidth = math.max(1, tonumber(availableWidth) or 1)

    for _, button in ipairs(buttons or {}) do
        local measured = button.keylabDesiredWidth
        if not measured and button.label and button.label.GetStringWidth then
            measured = math.ceil(button.label:GetStringWidth() + horizontalPadding)
        end
        local buttonWidth = math.max(
            tonumber(options.minWidth) or 64,
            math.min(tonumber(options.maxWidth) or availableWidth, tonumber(measured) or 90)
        )
        if x > 0 and (x + buttonWidth) > availableWidth then
            row = row + 1
            x = 0
        end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", container, "TOPLEFT", x, -((row - 1) * (height + rowGap)))
        button:SetSize(buttonWidth, height)
        button:Show()
        x = x + buttonWidth + columnGap
    end

    local totalHeight = (row * height) + ((row - 1) * rowGap)
    if #(buttons or {}) == 0 then totalHeight = 0 end
    container:SetHeight(math.max(1, totalHeight))
    return totalHeight, row
end

-- A texture-free, independently scrolling viewport with a slim KeyLab thumb.
-- The returned object owns reusable scrolling behavior and exposes
-- SetContentHeight, ScrollToTop, SetScroll, and Refresh methods.
function Theme.CreateScrollArea(parent, options)
    options = options or {}
    local area = CreateFrame("Frame", nil, parent)
    area.scrollBarWidth = tonumber(options.scrollBarWidth) or Theme.homeLayout.scrollBarWidth
    area.step = tonumber(options.step) or 38

    area.viewport = CreateFrame("ScrollFrame", nil, area)
    area.viewport:SetPoint("TOPLEFT", area, "TOPLEFT", 0, 0)
    area.viewport:SetPoint("BOTTOMRIGHT", area, "BOTTOMRIGHT", -(area.scrollBarWidth + 7), 0)
    area.viewport:EnableMouseWheel(true)

    area.content = CreateFrame("Frame", nil, area.viewport)
    area.content:SetPoint("TOPLEFT", area.viewport, "TOPLEFT", 0, 0)
    area.content:SetSize(1, 1)
    area.viewport:SetScrollChild(area.content)

    area.track = CreateFrame("Frame", nil, area, "BackdropTemplate")
    area.track:SetPoint("TOPRIGHT", area, "TOPRIGHT", -1, -2)
    area.track:SetPoint("BOTTOMRIGHT", area, "BOTTOMRIGHT", -1, 2)
    area.track:SetWidth(area.scrollBarWidth)
    area.track:EnableMouse(true)
    Theme.StylePanel(area.track, Theme.colors.barBg, Theme.colors.transparent, 0)

    area.thumb = CreateFrame("Button", nil, area.track, "BackdropTemplate")
    area.thumb:SetPoint("TOPLEFT", area.track, "TOPLEFT", 0, 0)
    area.thumb:SetPoint("TOPRIGHT", area.track, "TOPRIGHT", 0, 0)
    area.thumb:SetHeight(30)
    Theme.StylePanel(area.thumb, Theme.colors.blue, Theme.colors.transparent, 0)

    local function GetRange(self)
        local viewportHeight = math.max(1, self.viewport:GetHeight() or 1)
        return math.max(0, (self.contentHeight or 1) - viewportHeight), viewportHeight
    end

    function area:Refresh()
        local viewportWidth = math.max(1, self.viewport:GetWidth() or 1)
        self.content:SetWidth(viewportWidth)
        local range, viewportHeight = GetRange(self)
        local trackHeight = math.max(1, self.track:GetHeight() or 1)
        local contentHeight = math.max(viewportHeight, self.contentHeight or viewportHeight)
        local thumbHeight = math.max(24, math.min(trackHeight, trackHeight * (viewportHeight / contentHeight)))
        local scroll = math.max(0, math.min(range, self.viewport:GetVerticalScroll() or 0))
        local travel = math.max(0, trackHeight - thumbHeight)
        local offset = range > 0 and ((scroll / range) * travel) or 0
        self.thumb:ClearAllPoints()
        self.thumb:SetPoint("TOPLEFT", self.track, "TOPLEFT", 0, -offset)
        self.thumb:SetPoint("TOPRIGHT", self.track, "TOPRIGHT", 0, -offset)
        self.thumb:SetHeight(thumbHeight)
        self.track:SetShown(range > 0)
    end

    function area:SetContentHeight(height)
        self.contentHeight = math.max(1, math.ceil(tonumber(height) or 1))
        self.content:SetHeight(self.contentHeight)
        self:SetScroll(self.viewport:GetVerticalScroll() or 0)
    end

    function area:SetScroll(value)
        local range = GetRange(self)
        self.viewport:SetVerticalScroll(math.max(0, math.min(range, tonumber(value) or 0)))
        self:Refresh()
    end

    function area:ScrollToTop()
        self:SetScroll(0)
    end

    area.viewport:SetScript("OnMouseWheel", function(_, delta)
        area:SetScroll((area.viewport:GetVerticalScroll() or 0) - (delta * area.step))
    end)
    area.viewport:SetScript("OnSizeChanged", function() area:Refresh() end)
    area.track:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        local _, cursorY = GetCursorPosition()
        local scale = UIParent and UIParent:GetEffectiveScale() or 1
        local top = area.track:GetTop() or 0
        local range = GetRange(area)
        local trackHeight = math.max(1, area.track:GetHeight() or 1)
        area:SetScroll(((top - (cursorY / scale)) / trackHeight) * range)
    end)
    area.thumb:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        local _, cursorY = GetCursorPosition()
        area.dragStartY = cursorY
        area.dragStartScroll = area.viewport:GetVerticalScroll() or 0
        area:SetScript("OnUpdate", function(self)
            if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
                self:SetScript("OnUpdate", nil)
                return
            end
            local _, currentY = GetCursorPosition()
            local scale = UIParent and UIParent:GetEffectiveScale() or 1
            local range = GetRange(self)
            local trackHeight = math.max(1, self.track:GetHeight() or 1)
            local thumbHeight = math.max(1, self.thumb:GetHeight() or 1)
            local travel = math.max(1, trackHeight - thumbHeight)
            local deltaPixels = (self.dragStartY - currentY) / scale
            self:SetScroll(self.dragStartScroll + ((deltaPixels / travel) * range))
        end)
    end)
    area.thumb:SetScript("OnMouseUp", function()
        area:SetScript("OnUpdate", nil)
    end)
    area.thumb:SetScript("OnHide", function()
        area:SetScript("OnUpdate", nil)
    end)
    area:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
    return area
end

function Theme.CreatePager(parent)
    local layout = Theme.analysisLayout
    local pager = {}
    pager.pageText = Theme.CreateText(parent, "Page 1 / 1", "GameFontDisableSmall", nil, Theme.colors.muted)
    pager.pageText:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", layout.pagerLabelX, layout.pagerY)
    pager.pageText:SetSize(layout.pagerLabelWidth, layout.pagerButtonHeight)
    pager.pageText:SetJustifyV("MIDDLE")

    pager.nextButton = Theme.CreateButton(parent, "Next", layout.pagerButtonWidth, layout.pagerButtonHeight)
    pager.nextButton:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -layout.pagerRight, layout.pagerY)
    pager.prevButton = Theme.CreateButton(parent, "Back", layout.pagerButtonWidth, layout.pagerButtonHeight)
    pager.prevButton:SetPoint("RIGHT", pager.nextButton, "LEFT", -layout.pagerButtonGap, 0)
    return pager
end

function Theme.CreateBadge(parent, text, width, height, borderColor, textColor)
    local badge = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    badge:SetSize(width or 64, height or Theme.badge.height)
    Theme.StylePanel(badge, Theme.badge.bg, borderColor or Theme.badge.border, 1)

    badge.text = Theme.CreateText(badge, text or "", "GameFontDisableSmall", Theme.fonts.smallSize, textColor or Theme.colors.text, "CENTER")
    badge.text:SetAllPoints(badge)
    badge.text:SetJustifyH("CENTER")
    badge.text:SetJustifyV("MIDDLE")

    return badge
end

function Theme.SetBadge(badge, text, bg, border, textColor)
    if not badge then
        return
    end

    text = tostring(text or "")
    if text == "" then
        badge:Hide()
        return
    end

    badge:Show()
    if badge.SetBackdropColor then
        badge:SetBackdropColor(Components(bg, Theme.badge.bg))
    end
    if badge.SetBackdropBorderColor then
        badge:SetBackdropBorderColor(Components(border, Theme.badge.border))
    end
    if badge.text then
        badge.text:SetText(text)
        Theme.ApplyColor(badge.text, textColor or Theme.colors.text)
    end
end

function Theme.CreateGearTrackBadge(parent, text, trackID, width, height)
    local color = Theme.GetGearTrackColor(trackID)
    local badge = Theme.CreateBadge(parent, text, width or 104, height or 24, color, color)
    badge.trackID = trackID

    function badge:SetTrack(nextTrackID, nextText)
        self.trackID = nextTrackID
        local nextColor = Theme.GetGearTrackColor(nextTrackID)
        Theme.SetBadge(
            self,
            nextText or "",
            Theme.colors.badgeBg,
            nextColor,
            nextColor
        )
    end

    return badge
end

function Theme.CreateProgressBar(parent, width, height, fillColor)
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetSize(width or 100, height or Theme.progress.height)
    Theme.StylePanel(bar, Theme.progress.bg, Theme.progress.border, 1)

    bar.fill = bar:CreateTexture(nil, "ARTWORK")
    bar.fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, -1)
    bar.fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 1, 1)
    bar.fill:SetWidth(1)
    bar.fill:SetColorTexture(Components(fillColor, Theme.progress.fill))

    return bar
end

function Theme.SetProgressBar(bar, value, maxValue, fillColor)
    if not bar or not bar.fill then
        return
    end

    value = tonumber(value) or 0
    maxValue = tonumber(maxValue) or 1

    local pct = 0
    if maxValue > 0 then
        pct = math.max(0, math.min(1, value / maxValue))
    end

    local width = bar:GetWidth() or 1
    bar.fill:SetWidth(math.max(1, (width - 2) * pct))
    bar.fill:SetColorTexture(Components(fillColor, Theme.progress.fill))
end

-- Shared KeyLab dropdown ----------------------------------------------------
--
-- This replaces Blizzard's textured UIDropDownMenu control while retaining a
-- small compatibility layer for older tab code that already builds its menu
-- choices with UIDropDownMenu_CreateInfo / UIDropDownMenu_AddButton. Both the
-- closed control and the open list use KeyLab's solid-color theme.

local activeDropdown

local function HideDropdownTooltip()
    if GameTooltip then GameTooltip:Hide() end
end

local function DropdownInfoChecked(info)
    if type(info and info.checked) == "function" then
        local ok, checked = pcall(info.checked)
        return ok and checked == true
    end
    return info and info.checked == true
end

local function CaptureDropdownOptions(dropdown)
    local options = {}
    if type(dropdown.initialize) ~= "function" then return options end

    local originalCreateInfo = _G.UIDropDownMenu_CreateInfo
    local originalAddButton = _G.UIDropDownMenu_AddButton
    _G.UIDropDownMenu_CreateInfo = function() return {} end
    _G.UIDropDownMenu_AddButton = function(info, level)
        if level == nil or level == 1 then table.insert(options, info or {}) end
    end

    local ok, err = pcall(dropdown.initialize, dropdown, 1)
    _G.UIDropDownMenu_CreateInfo = originalCreateInfo
    _G.UIDropDownMenu_AddButton = originalAddButton
    if not ok and KeyLab.Print then
        KeyLab.Print("A dropdown could not be opened: " .. tostring(err))
    end
    return options
end

local function SetDropdownRestingStyle(dropdown, hovered)
    if not dropdown or not dropdown.button then return end
    local enabled = dropdown.enabled ~= false
    local text = enabled and Theme.colors.text or Theme.colors.muted
    local background = dropdown.keylabRestingBackground or Theme.colors.controlBg
    dropdown.button:SetBackdropColor(Components(background))
    dropdown.button:SetBackdropBorderColor(Components(Theme.colors.transparent))
    Theme.ApplyColor(dropdown.label, text)
    Theme.ApplyColor(dropdown.arrow, enabled and Theme.colors.gold or Theme.colors.muted)
    if dropdown.bottomRule then
        local line = Theme.colors.softBorder
        if enabled and dropdown.menu and dropdown.menu:IsShown() then
            line = Theme.colors.gold
        elseif enabled and hovered then
            line = Theme.colors.blue
        end
        dropdown.bottomRule:SetColorTexture(Components(line))
    end
end

local function PopulateDropdownMenu(dropdown)
    local options = CaptureDropdownOptions(dropdown)
    dropdown.capturedOptions = options
    local visible = math.min(12, math.max(1, #options))
    local maxOffset = math.max(1, #options - visible + 1)
    dropdown.menu.offset = math.max(1, math.min(dropdown.menu.offset or 1, maxOffset))
    local menuWidth = dropdown.keylabWidth or 150
    for _, info in ipairs(options) do
        menuWidth = math.max(menuWidth, math.min(380, (#tostring(info.text or "") * 6) + 28))
    end
    dropdown.menu:SetWidth(menuWidth)
    dropdown.menu:SetHeight((visible * 24) + 4)

    for rowIndex = 1, 12 do
        local row = dropdown.menu.rows[rowIndex]
        if not row then
            row = CreateFrame("Button", nil, dropdown.menu, "BackdropTemplate")
            row:SetHeight(22)
            Theme.StylePanel(row, Theme.colors.card, Theme.colors.softBorder)
            row.label = Theme.CreateText(row, "", "GameFontHighlightSmall", 11, Theme.colors.text)
            row.label:SetPoint("LEFT", row, "LEFT", 7, 0)
            row.label:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            row.label:SetHeight(20)
            row.label:SetJustifyV("MIDDLE")
            row:SetScript("OnClick", function(self)
                local info = self.info
                if not info or info.disabled or info.isTitle then return end
                if type(info.func) == "function" then
                    info.func(self, info.arg1, info.arg2, DropdownInfoChecked(info))
                end
                if not info.keepShownOnClick then
                    dropdown.menu:Hide()
                    if activeDropdown == dropdown then activeDropdown = nil end
                else
                    PopulateDropdownMenu(dropdown)
                end
            end)
            row:SetScript("OnEnter", function(self)
                local info = self.info or {}
                if not info.disabled and not info.isTitle then
                    self:SetBackdropBorderColor(Components(Theme.colors.buttonHover))
                    self:SetBackdropColor(Components(Theme.colors.controlBg))
                end
                if GameTooltip and info.tooltipTitle then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(tostring(info.tooltipTitle), Components(Theme.colors.gold))
                    if info.tooltipText then
                        local r, g, b = Components(Theme.colors.text)
                        GameTooltip:AddLine(tostring(info.tooltipText), r, g, b, true)
                    end
                    GameTooltip:Show()
                end
            end)
            row:SetScript("OnLeave", function(self)
                local info = self.info or {}
                local checked = DropdownInfoChecked(info)
                self:SetBackdropBorderColor(Components(checked and Theme.colors.gold or Theme.colors.softBorder))
                self:SetBackdropColor(Components(Theme.colors.card))
                HideDropdownTooltip()
            end)
            dropdown.menu.rows[rowIndex] = row
        end

        local info = options[dropdown.menu.offset + rowIndex - 1]
        row.info = info
        row:SetShown(info ~= nil)
        if info then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", dropdown.menu, "TOPLEFT", 2, -2 - ((rowIndex - 1) * 24))
            row:SetPoint("TOPRIGHT", dropdown.menu, "TOPRIGHT", -2, -2 - ((rowIndex - 1) * 24))
            local checked = DropdownInfoChecked(info)
            local prefix = checked and not info.notCheckable and "•  " or ""
            row.label:SetText(prefix .. tostring(info.text or ""))
            if info.isTitle then
                Theme.ApplyColor(row.label, Theme.colors.gold)
            elseif info.disabled then
                Theme.ApplyColor(row.label, Theme.colors.muted)
            elseif checked then
                Theme.ApplyColor(row.label, Theme.colors.gold)
            else
                Theme.ApplyColor(row.label, Theme.colors.text)
            end
            row:SetBackdropColor(Components(Theme.colors.card))
            row:SetBackdropBorderColor(Components(checked and Theme.colors.gold or Theme.colors.softBorder))
            row:EnableMouse(not info.disabled and not info.isTitle)
        end
    end
end

function Theme.CreateLegacyDropdown(parent, name)
    local dropdown = CreateFrame("Frame", name, parent)
    dropdown.keylabDropdown = true
    dropdown.enabled = true
    dropdown:SetSize(182, 40)

    dropdown.button = CreateFrame("Button", nil, dropdown, "BackdropTemplate")
    dropdown.button:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 16, -8)
    dropdown.button:SetSize(150, 24)
    Theme.StylePanel(dropdown.button, Theme.colors.controlBg, Theme.colors.transparent, 0)
    dropdown.bottomRule = Theme.CreateRule(dropdown.button, "BOTTOM", Theme.colors.softBorder, 1)
    dropdown.label = Theme.CreateText(dropdown.button, "Select", "GameFontHighlightSmall", 11, Theme.colors.text)
    dropdown.label:SetPoint("LEFT", dropdown.button, "LEFT", 8, 0)
    dropdown.label:SetPoint("RIGHT", dropdown.button, "RIGHT", -25, 0)
    dropdown.label:SetHeight(22)
    dropdown.label:SetJustifyV("MIDDLE")
    dropdown.arrow = Theme.CreateText(dropdown.button, "v", "GameFontNormal", 12, Theme.colors.gold, "CENTER")
    dropdown.arrow:SetPoint("RIGHT", dropdown.button, "RIGHT", -5, 0)
    dropdown.arrow:SetSize(16, 20)
    dropdown.arrow:SetJustifyV("MIDDLE")

    dropdown.menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dropdown.menu:SetFrameStrata("TOOLTIP")
    dropdown.menu:SetFrameLevel(9000)
    dropdown.menu:SetClampedToScreen(true)
    dropdown.menu:SetSize(150, 28)
    dropdown.menu:Hide()
    dropdown.menu.rows = {}
    dropdown.menu.offset = 1
    dropdown.menu:EnableMouseWheel(true)
    Theme.StylePanel(dropdown.menu, Theme.colors.bg, Theme.colors.gold)

    function dropdown:SetKeyLabWidth(width)
        width = math.max(60, tonumber(width) or 150)
        self.keylabWidth = width
        self:SetWidth(width + 32)
        self.button:SetWidth(width)
        self.menu:SetWidth(width)
    end

    function dropdown:SetDisplayText(text)
        self.displayText = tostring(text or "")
        self.label:SetText(self.displayText)
    end

    function dropdown:SetKeyLabEnabled(enabled)
        self.enabled = enabled ~= false
        self.button:SetEnabled(self.enabled)
        if not self.enabled then self.menu:Hide() end
        SetDropdownRestingStyle(self, false)
    end

    function dropdown:OpenMenu(anchor, x, y)
        if self.enabled == false then return end
        if activeDropdown and activeDropdown ~= self and activeDropdown.menu then activeDropdown.menu:Hide() end
        activeDropdown = self
        self.menu.offset = 1
        PopulateDropdownMenu(self)
        self.menu:ClearAllPoints()
        local owner = anchor or self.button
        self.menu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", tonumber(x) or 0, tonumber(y) or -2)
        self.menu:Show()
        SetDropdownRestingStyle(self, false)
    end

    function dropdown:ToggleMenu(anchor, x, y)
        if self.menu:IsShown() then
            self.menu:Hide()
            if activeDropdown == self then activeDropdown = nil end
        else
            self:OpenMenu(anchor, x, y)
        end
    end

    dropdown.menu:SetScript("OnMouseWheel", function(_, delta)
        local options = dropdown.capturedOptions or CaptureDropdownOptions(dropdown)
        local visible = math.min(12, math.max(1, #options))
        local maxOffset = math.max(1, #options - visible + 1)
        dropdown.menu.offset = math.max(1, math.min(maxOffset, (dropdown.menu.offset or 1) - delta))
        PopulateDropdownMenu(dropdown)
    end)
    dropdown.menu:SetScript("OnHide", function()
        HideDropdownTooltip()
        if activeDropdown == dropdown then activeDropdown = nil end
        SetDropdownRestingStyle(dropdown, false)
    end)
    dropdown.button:SetScript("OnClick", function() dropdown:ToggleMenu() end)
    dropdown.button:SetScript("OnEnter", function() SetDropdownRestingStyle(dropdown, true) end)
    dropdown.button:SetScript("OnLeave", function() SetDropdownRestingStyle(dropdown, false) end)
    dropdown:HookScript("OnHide", function()
        dropdown.menu:Hide()
        if activeDropdown == dropdown then activeDropdown = nil end
    end)
    dropdown:SetKeyLabWidth(150)
    SetDropdownRestingStyle(dropdown, false)
    return dropdown
end

-- Applies the brighter KeyLab dropdown-field treatment to both the shared
-- compatibility dropdown and custom button-based dropdowns. Tabs keep their
-- own option and selection logic; the theme owns the field presentation.
function Theme.ApplyDropdownFieldState(dropdown, hovered)
    if not dropdown then return end
    if dropdown.button then
        SetDropdownRestingStyle(dropdown, hovered == true)
        return
    end

    local background = hovered and Theme.colors.buttonSelectedBg or Theme.colors.analysisDropdownBg
    local border = hovered and Theme.colors.blue or Theme.colors.analysisFilterBorder
    if dropdown.SetBackdropColor then dropdown:SetBackdropColor(Components(background)) end
    if dropdown.SetBackdropBorderColor then dropdown:SetBackdropBorderColor(Components(border)) end
    Theme.ApplyColor(dropdown.label or dropdown.text, hovered and Theme.colors.gold or Theme.colors.text)
    Theme.ApplyColor(dropdown.arrow, Theme.colors.gold)
end

function Theme.StyleDropdownField(dropdown)
    if not dropdown then return dropdown end
    if dropdown.button then
        dropdown.keylabRestingBackground = Theme.colors.analysisDropdownBg
    else
        dropdown.keylabRestingBackground = Theme.colors.analysisDropdownBg
        dropdown.defaultBg = Theme.colors.analysisDropdownBg
        dropdown.defaultBorder = Theme.colors.analysisFilterBorder
        dropdown.defaultText = Theme.colors.text
    end
    Theme.ApplyDropdownFieldState(dropdown, false)
    return dropdown
end

-- Compatibility name retained for analysis tabs already using this helper.
Theme.StyleAnalysisFilterDropdown = Theme.StyleDropdownField

function Theme.SetDropdownText(dropdown, text)
    if dropdown and dropdown.keylabDropdown and dropdown.SetDisplayText then
        dropdown:SetDisplayText(text)
    end
end

-- Compatibility routing lets existing tab callbacks keep their proven menu
-- choice logic while the actual widget and menu are entirely KeyLab-styled.
if not Theme.dropdownCompatibilityInstalled then
    Theme.dropdownCompatibilityInstalled = true
    local originals = {
        initialize = _G.UIDropDownMenu_Initialize,
        setWidth = _G.UIDropDownMenu_SetWidth,
        setText = _G.UIDropDownMenu_SetText,
        disable = _G.UIDropDownMenu_DisableDropDown,
        enable = _G.UIDropDownMenu_EnableDropDown,
        toggle = _G.ToggleDropDownMenu,
    }
    Theme.originalDropdownFunctions = originals

    _G.UIDropDownMenu_Initialize = function(dropdown, initialize, ...)
        if dropdown and dropdown.keylabDropdown then dropdown.initialize = initialize; return end
        if originals.initialize then return originals.initialize(dropdown, initialize, ...) end
    end
    _G.UIDropDownMenu_SetWidth = function(dropdown, width, ...)
        if dropdown and dropdown.keylabDropdown then dropdown:SetKeyLabWidth(width); return end
        if originals.setWidth then return originals.setWidth(dropdown, width, ...) end
    end
    _G.UIDropDownMenu_SetText = function(dropdown, text, ...)
        if dropdown and dropdown.keylabDropdown then dropdown:SetDisplayText(text); return end
        if originals.setText then return originals.setText(dropdown, text, ...) end
    end
    _G.UIDropDownMenu_DisableDropDown = function(dropdown, ...)
        if dropdown and dropdown.keylabDropdown then dropdown:SetKeyLabEnabled(false); return end
        if originals.disable then return originals.disable(dropdown, ...) end
    end
    _G.UIDropDownMenu_EnableDropDown = function(dropdown, ...)
        if dropdown and dropdown.keylabDropdown then dropdown:SetKeyLabEnabled(true); return end
        if originals.enable then return originals.enable(dropdown, ...) end
    end
    _G.ToggleDropDownMenu = function(level, value, dropdown, anchor, x, y, ...)
        if dropdown and dropdown.keylabDropdown then dropdown:ToggleMenu(anchor, x, y); return end
        if originals.toggle then return originals.toggle(level, value, dropdown, anchor, x, y, ...) end
    end
    -- Leave CloseDropDownMenus on Blizzard's original implementation. UIParent
    -- can call it during mouse input; routing it to the custom menu would hide
    -- the clicked row before its normal button click can complete.
end

return Theme
