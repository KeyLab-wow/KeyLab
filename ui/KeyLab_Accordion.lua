-- Shared compact accordion used by KeyLab's informational tabs.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}

local Accordion = {}
KeyLab.UI.Accordion = Accordion
local THEME_SPACING = KeyLab.UI.Theme and KeyLab.UI.Theme.spacing or { compactCard = 8 }

local DEFAULT_COLORS = {
    panel = {0.026, 0.046, 0.086, 0.92},
    body = {0.022, 0.038, 0.076, 0.86},
    border = {0.240, 0.380, 0.620, 0.62},
    hover = {0.300, 0.420, 0.600, 0.78},
    gold = {0.820, 0.760, 0.580, 1.0},
    text = {0.940, 0.960, 0.990, 1.0},
}

local function Color(colors, key)
    return colors and colors[key] or DEFAULT_COLORS[key]
end

local function SetBackdrop(frame, background, border)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(background))
    frame:SetBackdropBorderColor(unpack(border))
end

local function BodyHeight(fontString, text)
    local measured = fontString.GetStringHeight and tonumber(fontString:GetStringHeight()) or 0
    if measured and measured > 0 then return math.ceil(measured) + 30 end

    local clean = tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local lineCount = 1
    for _ in clean:gmatch("\n") do lineCount = lineCount + 1 end
    local wrappedLines = math.ceil(#clean / 105)
    return math.max(70, math.max(lineCount, wrappedLines) * 17 + 30)
end

function Accordion.Create(content, options)
    options = options or {}
    local colors = options.colors or DEFAULT_COLORS
    local width = tonumber(options.width) or 884
    local left = tonumber(options.left) or 8
    local headerHeight = tonumber(options.headerHeight) or 42
    local gap = tonumber(options.gap) or THEME_SPACING.compactCard or 8
    local minHeight = tonumber(options.minHeight) or 420
    local pixelSnap = options.pixelSnap == true
    local joinBody = options.joinBody == true

    local function Point(region, ...)
        if pixelSnap and PixelUtil and PixelUtil.SetPoint then
            PixelUtil.SetPoint(region, ...)
        else
            region:SetPoint(...)
        end
    end

    local function Size(region, widthValue, heightValue)
        if pixelSnap and PixelUtil and PixelUtil.SetSize then
            PixelUtil.SetSize(region, widthValue, heightValue)
        else
            region:SetSize(widthValue, heightValue)
        end
    end

    local function Height(region, value)
        if pixelSnap and PixelUtil and PixelUtil.SetHeight then
            PixelUtil.SetHeight(region, value)
        else
            region:SetHeight(value)
        end
    end

    local controller = {
        content = content,
        sections = {},
        openIndex = tonumber(options.openIndex),
    }

    for index, definition in ipairs(options.sections or {}) do
        local section = { definition = definition }
        local header = CreateFrame("Button", nil, content, "BackdropTemplate")
        Size(header, width, headerHeight)
        SetBackdrop(header, Color(colors, "panel"), Color(colors, "border"))

        -- A BackdropTemplate's one-pixel top edge can fade when its ScrollFrame
        -- lands between physical pixels. Keep a separate snapped edge above the
        -- backdrop so every collapsed card retains the same crisp top line.
        local topEdge = header:CreateTexture(nil, "OVERLAY", nil, 7)
        Point(topEdge, "TOPLEFT", header, "TOPLEFT", 0, 0)
        Point(topEdge, "TOPRIGHT", header, "TOPRIGHT", 0, 0)
        Height(topEdge, 1)
        topEdge:SetColorTexture(unpack(Color(colors, "border")))

        local indicator = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        indicator:SetFont(STANDARD_TEXT_FONT, 16, "")
        indicator:SetPoint("LEFT", header, "LEFT", 14, 0)
        indicator:SetSize(22, 22)
        indicator:SetJustifyH("CENTER")
        indicator:SetTextColor(unpack(Color(colors, "gold")))

        local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetFont(STANDARD_TEXT_FONT, 14, "")
        title:SetPoint("LEFT", indicator, "RIGHT", 10, 0)
        title:SetPoint("RIGHT", header, "RIGHT", -14, 0)
        title:SetJustifyH("LEFT")
        title:SetText(tostring(definition.title or ("Section " .. index)))
        title:SetTextColor(unpack(Color(colors, "text")))

        local body = CreateFrame("Frame", nil, content, "BackdropTemplate")
        body:SetWidth(width)
        SetBackdrop(body, Color(colors, "body"), Color(colors, "border"))
        body:Hide()

        local bodyText = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bodyText:SetFont(STANDARD_TEXT_FONT, 12, "")
        bodyText:SetPoint("TOPLEFT", body, "TOPLEFT", 16, -14)
        bodyText:SetWidth(width - 32)
        bodyText:SetJustifyH("LEFT")
        bodyText:SetJustifyV("TOP")
        bodyText:SetWordWrap(true)
        if bodyText.SetSpacing then bodyText:SetSpacing(3) end
        bodyText:SetTextColor(unpack(Color(colors, "text")))
        bodyText:SetText(tostring(definition.body or ""))

        section.header = header
        section.indicator = indicator
        section.title = title
        section.topEdge = topEdge
        section.body = body
        section.bodyText = bodyText
        controller.sections[index] = section

        header:SetScript("OnClick", function()
            controller.openIndex = controller.openIndex == index and nil or index
            controller:Layout()
        end)
        header:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(unpack(Color(colors, "hover")))
            topEdge:SetColorTexture(unpack(Color(colors, "hover")))
            if colors.hoverBg then self:SetBackdropColor(unpack(colors.hoverBg)) end
            title:SetTextColor(unpack(Color(colors, "gold")))
        end)
        header:SetScript("OnLeave", function(self)
            local active = controller.openIndex == index
            self:SetBackdropColor(unpack(Color(colors, "panel")))
            self:SetBackdropBorderColor(unpack(active and Color(colors, "gold") or Color(colors, "border")))
            topEdge:SetColorTexture(unpack(active and Color(colors, "gold") or Color(colors, "border")))
            title:SetTextColor(unpack(active and Color(colors, "gold") or Color(colors, "text")))
        end)
    end

    function controller:Layout()
        local y = -4
        for index, section in ipairs(self.sections) do
            local expanded = self.openIndex == index
            section.header:ClearAllPoints()
            Point(section.header, "TOPLEFT", self.content, "TOPLEFT", left, y)
            section.indicator:SetText(expanded and "-" or "+")
            section.title:SetTextColor(unpack(expanded and Color(colors, "gold") or Color(colors, "text")))
            section.header:SetBackdropBorderColor(unpack(expanded and Color(colors, "gold") or Color(colors, "border")))
            section.topEdge:SetColorTexture(unpack(expanded and Color(colors, "gold") or Color(colors, "border")))
            y = y - headerHeight

            section.body:ClearAllPoints()
            if expanded then
                section.bodyText:SetWidth(width - 32)
                local height = BodyHeight(section.bodyText, section.definition.body)
                Height(section.body, height)
                local bodyY = joinBody and (y + 1) or y
                Point(section.body, "TOPLEFT", self.content, "TOPLEFT", left, bodyY)
                Height(section.bodyText, height - 28)
                section.body:Show()
                y = bodyY - height
            else
                section.body:Hide()
            end
            y = y - gap
        end
        Height(self.content, math.max(minHeight, math.abs(y) + 12))
    end

    controller:Layout()
    return controller
end

return Accordion
