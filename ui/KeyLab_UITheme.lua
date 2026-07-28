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

return Theme
