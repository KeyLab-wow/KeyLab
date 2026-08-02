local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.CraftingShoppingWindow = KeyLab.CraftingShoppingWindow or {}
local Window = KeyLab.CraftingShoppingWindow

--[[
KeyLab_CraftingShoppingWindow.lua

Renders the shopping plan calculated by KeyLab_CraftingAnalysis. It is purely
observational: it never searches, buys, posts, or interacts with the Auction
House. Opening the Auction House only controls this helper's visibility.
]]

local COLORS = {
    bg = {0.018, 0.026, 0.056, 0.98}, panel = {0.026, 0.046, 0.086, 0.96},
    rowA = {0.020, 0.034, 0.068, 0.94}, rowB = {0.030, 0.050, 0.092, 0.94},
    border = {0.240, 0.380, 0.620, 0.72}, gold = {0.820, 0.760, 0.580, 1},
    text = {0.940, 0.960, 0.990, 1}, muted = {0.680, 0.730, 0.820, 1},
    blue = {0.500, 0.680, 0.940, 1}, green = {0.470, 0.850, 0.550, 1},
}

local frame
local auctionHouseSessionClosed = false

local function Backdrop(target, color, border)
    target:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, edgeSize = 1,
    })
    target:SetBackdropColor(unpack(color or COLORS.panel))
    target:SetBackdropBorderColor(unpack(border or COLORS.border))
end

local function Text(parent, value, template, size, color)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    if size then fs:SetFont(STANDARD_TEXT_FONT, size, "") end
    fs:SetTextColor(unpack(color or COLORS.text)); fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP")
    fs:SetWordWrap(true); fs:SetText(value or "")
    return fs
end

local function SaveGeometry()
    if not frame or not KeyLab.DB or not KeyLab.DB.GetSettingTable then return end
    local settings = KeyLab.DB.GetSettingTable("craftingShoppingWindowPosition")
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    settings.point, settings.relativePoint = point, relativePoint
    settings.x, settings.y = math.floor((x or 0) + 0.5), math.floor((y or 0) + 0.5)
    settings.width, settings.height = math.floor(frame:GetWidth() + 0.5), math.floor(frame:GetHeight() + 0.5)
end

local function RestoreGeometry()
    local settings = KeyLab.DB and KeyLab.DB.GetSettingTable and KeyLab.DB.GetSettingTable("craftingShoppingWindowPosition") or {}
    frame:SetSize(math.max(680, math.min(1080, tonumber(settings.width) or 850)),
        math.max(460, math.min(800, tonumber(settings.height) or 650)))
    frame:ClearAllPoints()
    if settings.point then
        frame:SetPoint(settings.point, UIParent, settings.relativePoint or settings.point, tonumber(settings.x) or 0, tonumber(settings.y) or 0)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 80, 0)
    end
end

local function ClearCards()
    for _, card in ipairs(frame.cards or {}) do card:Hide() end
    frame.cardIndex = 0
end

local function AcquireCard(parent)
    frame.cardIndex = frame.cardIndex + 1
    local card = frame.cards[frame.cardIndex]
    if not card then
        card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        card.lines = {}
        frame.cards[frame.cardIndex] = card
    end
    card:Show()
    return card
end

local function SetLine(card, index, value, color, size)
    local line = card.lines[index]
    if not line then
        line = Text(card, "", "GameFontHighlightSmall", size or 11, color)
        card.lines[index] = line
    end
    line:ClearAllPoints(); line:SetPoint("TOPLEFT", 10, -9 - ((index - 1) * 22)); line:SetPoint("RIGHT", -10, 0)
    line:SetTextColor(unpack(color or COLORS.text)); line:SetText(value or ""); line:Show()
    for extra = index + 1, #card.lines do card.lines[extra]:Hide() end
end

local function Section(parent, title, subtitle, entries, left, top, width)
    local count = math.max(1, #(entries or {}))
    local height = 64 + (count * 44)
    local section = AcquireCard(parent)
    section:ClearAllPoints(); section:SetPoint("TOPLEFT", left, -top); section:SetSize(width, height)
    Backdrop(section, COLORS.panel, COLORS.border)
    SetLine(section, 1, title, COLORS.gold, 14)
    SetLine(section, 2, subtitle, COLORS.muted, 10)

    section.rows = section.rows or {}
    for index = 1, count do
        local row = section.rows[index]
        if not row then
            row = CreateFrame("Frame", nil, section, "BackdropTemplate")
            row.name = Text(row, "", "GameFontHighlightSmall", 11, COLORS.text)
            row.name:SetPoint("TOPLEFT", 8, -5); row.name:SetPoint("RIGHT", -8, 0)
            row.count = Text(row, "", "GameFontHighlightSmall", 10, COLORS.muted)
            row.count:SetPoint("BOTTOMLEFT", 8, 4); row.count:SetPoint("RIGHT", -8, 0)
            section.rows[index] = row
        end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 9, -57 - ((index - 1) * 44)); row:SetPoint("TOPRIGHT", -9, -57 - ((index - 1) * 44)); row:SetHeight(39)
        Backdrop(row, index % 2 == 0 and COLORS.rowB or COLORS.rowA, COLORS.border)
        local entry = entries and entries[index]
        row:SetShown(entry ~= nil or (#(entries or {}) == 0 and index == 1))
        if entry then
            row.name:SetText(entry.name or "Material")
            row.count:SetText(entry.summary or string.format("Need %d  |  Own %d  |  Still needed %d",
                entry.required or 0, entry.owned or 0, entry.stillNeeded or 0))
            local complete = entry.complete
            if complete == nil then complete = (entry.stillNeeded or 0) == 0 end
            row.count:SetTextColor(unpack(complete and COLORS.green or COLORS.blue))
        else
            row.name:SetText("Nothing needed here.")
            row.count:SetText("")
        end
    end
    for index = count + 1, #(section.rows or {}) do section.rows[index]:Hide() end
    return height, section
end

local function CreateWindow()
    if frame then return frame end
    frame = CreateFrame("Frame", "KeyLabCraftingShoppingWindow", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(1000)
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:SetResizable(true)
    if frame.SetResizeBounds then frame:SetResizeBounds(680, 460, 1080, 800) end
    frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    Backdrop(frame, COLORS.bg, COLORS.gold)
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SaveGeometry() end)
    frame:SetScript("OnSizeChanged", function()
        if not frame or not frame:IsShown() then return end
        SaveGeometry()
        if not frame.resizeRefreshPending and C_Timer and C_Timer.After then
            frame.resizeRefreshPending = true
            C_Timer.After(0, function()
                if frame then frame.resizeRefreshPending = nil end
                if frame and frame:IsShown() and Window.Refresh then Window.Refresh() end
            end)
        end
    end)
    frame:SetScript("OnHide", SaveGeometry)

    local art = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    art:SetAllPoints(frame); art:SetTexture("Interface\\AddOns\\KeyLab\\Assets\\KeyLabWindowBackground.tga"); art:SetAlpha(0.28)
    local title = Text(frame, "Crafted Gear Shopping List", "GameFontNormal", 20, COLORS.gold)
    title:SetPoint("TOP", 0, -18)
    local subtitle = Text(frame, "Your saved crafted plan, ready for the Auction House.", nil, 11, COLORS.muted)
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)

    local close = CreateFrame("Button", nil, frame, "BackdropTemplate")
    close:SetSize(34, 34); close:SetPoint("TOPRIGHT", -10, -10); Backdrop(close, COLORS.panel, COLORS.gold)
    close.text = Text(close, "X", "GameFontNormal", 16, COLORS.gold); close.text:SetAllPoints(); close.text:SetJustifyH("CENTER"); close.text:SetJustifyV("MIDDLE")
    close:SetScript("OnClick", function()
        if AuctionHouseFrame and AuctionHouseFrame:IsShown() then auctionHouseSessionClosed = true end
        frame:Hide()
    end)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -70); scroll:SetPoint("BOTTOMRIGHT", -35, 48)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(780, 600); scroll:SetScrollChild(content)
    frame.scroll, frame.content, frame.cards = scroll, content, {}

    local footer = Text(frame, "KeyLab only shows the list. It never searches, buys, or posts anything for you.", nil, 10, COLORS.muted)
    footer:SetPoint("BOTTOMLEFT", 20, 18)
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(26, 26); grip:SetPoint("BOTTOMRIGHT", -3, 3); grip:EnableMouse(true)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); SaveGeometry() end)
    RestoreGeometry(); frame:Hide()
    return frame
end

function Window.Refresh()
    CreateWindow(); ClearCards()
    local result = KeyLab.CraftingAnalysis and KeyLab.CraftingAnalysis.GetShoppingList
        and KeyLab.CraftingAnalysis.GetShoppingList() or { planCount = 0, auctionHouse = {}, resources = {} }
    local contentWidth = math.max(620, frame.scroll:GetWidth() - 20)
    frame.content:SetWidth(contentWidth)
    local gap, columnWidth = 12, math.floor((contentWidth - 12) / 2)
    local leftHeight, leftCard = Section(frame.content, "Auction House Materials",
        "Materials still needed for every item in your crafted plan.", result.auctionHouse, 0, 0, columnWidth)
    local rightHeight, rightCard = Section(frame.content, "On Hand & Crafting Resources",
        "Covered materials, Sparks, Dawncrests, and PvP Heraldry at a glance.",
        result.resources, columnWidth + gap, 0, columnWidth)
    local totalHeight = math.max(leftHeight, rightHeight)
    leftCard:SetHeight(totalHeight)
    rightCard:SetHeight(totalHeight)
    frame.content:SetHeight(math.max(totalHeight, frame.scroll:GetHeight()))
end

function Window.Show(manual)
    local result = KeyLab.CraftingAnalysis and KeyLab.CraftingAnalysis.GetShoppingList and KeyLab.CraftingAnalysis.GetShoppingList() or nil
    if not manual and (auctionHouseSessionClosed or not result or (result.planCount or 0) == 0) then return end
    CreateWindow(); Window.Refresh(); frame:Show(); frame:Raise()
end

function Window.Hide() if frame then frame:Hide() end end
function Window.IsShown() return frame and frame:IsShown() or false end

local events = CreateFrame("Frame")
events:RegisterEvent("AUCTION_HOUSE_SHOW")
events:RegisterEvent("AUCTION_HOUSE_CLOSED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
events:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_HOUSE_SHOW" then
        auctionHouseSessionClosed = false
        C_Timer.After(0.20, function() Window.Show(false) end)
    elseif event == "AUCTION_HOUSE_CLOSED" then
        auctionHouseSessionClosed = false
        if frame then frame:Hide() end
    elseif frame and frame:IsShown() then
        Window.Refresh()
    end
end)

return Window
