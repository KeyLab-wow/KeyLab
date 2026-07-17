local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.GearTargetsWindow = KeyLab.GearTargetsWindow or {}
local GearWindow = KeyLab.GearTargetsWindow

--[[
KeyLab_GearTargetsWindow.lua

Purpose:
- Standalone KeyLab-styled Gear Targets window.
- Opens manually from Home or automatically while browsing Premade Group dungeons.
-- Reads slot-based Targets through LootTargetsDB and item details from the master item database.
- Does not depend on Blizzard's Adventure Guide.
]]

local CFG = {
    width = 430,
    minHeight = 245,
    maxHeight = 560,
    colors = {
        bg = {0.018, 0.026, 0.056, 0.98},
        panel = {0.026, 0.046, 0.086, 0.96},
        border = {0.240, 0.380, 0.620, 0.62},
        gold = {0.820, 0.760, 0.580, 1.0},
        text = {0.940, 0.960, 0.990, 1.0},
        muted = {0.680, 0.730, 0.820, 1.0},
        blue = {0.500, 0.680, 0.940, 1.0},
        warning = {0.840, 0.720, 0.420, 1.0},
    },
    maxThisDungeonItemsShown = 10,
    maxOtherDungeonsShown = 8,
}

local frame

local function SetBackdrop(f, color, borderColor)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    f:SetBackdropColor(unpack(color or CFG.colors.panel))
    f:SetBackdropBorderColor(unpack(borderColor or CFG.colors.border))
end

local function EnsureSettingsDB()
    KeyLabDB = KeyLabDB or {}
    KeyLabDB.settings = KeyLabDB.settings or {}
    KeyLabDB.settings.gearTargetsWindow = KeyLabDB.settings.gearTargetsWindow or {}
    return KeyLabDB.settings.gearTargetsWindow
end

local function SavePosition(f)
    if not f then return end
    local settings = EnsureSettingsDB()
    local point, _, relativePoint, xOfs, yOfs = f:GetPoint(1)
    settings.point = point
    settings.relativePoint = relativePoint
    settings.x = xOfs
    settings.y = yOfs
end

local function RestorePosition(f)
    local settings = KeyLabDB and KeyLabDB.settings and KeyLabDB.settings.gearTargetsWindow
    if settings and settings.point then
        f:ClearAllPoints()
        f:SetPoint(settings.point, UIParent, settings.relativePoint or settings.point, settings.x or -90, settings.y or 10)
        return true
    end
    return false
end

local function AddLine(f, text, color, indent)
    f.lineIndex = (f.lineIndex or 0) + 1
    local fs = f.lines[f.lineIndex]
    if not fs then
        fs = f.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(false)
        f.lines[f.lineIndex] = fs
    end
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", f.content, "TOPLEFT", 12 + (indent or 0), -((f.lineIndex - 1) * 21))
    fs:SetPoint("RIGHT", f.content, "RIGHT", -10, 0)
    fs:SetTextColor(unpack(color or CFG.colors.text))
    fs:SetText(text or "")
    fs:Show()
    return fs
end

local function AddBlank(f)
    AddLine(f, " ", CFG.colors.muted)
end

local function HideUnusedLines(f)
    for i = (f.lineIndex or 0) + 1, #(f.lines or {}) do
        f.lines[i]:Hide()
    end
end

local function StripColorCodes(text)
    return tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function NormalizeName(value)
    value = tostring(value or "")
    value = value:gsub("[%p%c%s]+", "")
    return string.lower(value)
end

local function CurrentSpecID()
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetCurrentSpecID then
        return KeyLab.LootTargetsDB.GetCurrentSpecID()
    end
    return nil
end

local function GetTrackedTable()
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetTrackedTable then
        return KeyLab.LootTargetsDB.GetTrackedTable(CurrentSpecID()) or {}
    end
    return {}
end

local function GetTrackedList()
    if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetSavedTargetsForSpec then
        return KeyLab.LootTargetsDB.GetSavedTargetsForSpec(CurrentSpecID()) or {}
    end
    return {}
end

local function SortItems(items)
    table.sort(items, function(a, b)
        if tostring(a.dungeonName or "") ~= tostring(b.dungeonName or "") then
            return tostring(a.dungeonName or "") < tostring(b.dungeonName or "")
        end
        if tostring(a.slot or "") ~= tostring(b.slot or "") then
            return tostring(a.slot or "") < tostring(b.slot or "")
        end
        return StripColorCodes(a.name or a.itemID) < StripColorCodes(b.name or b.itemID)
    end)
end

local function AddItem(f, item, indent)
    local slot = item.slot and item.slot ~= "" and (" — " .. item.slot) or ""
    AddLine(f, "• " .. StripColorCodes(item.name or ("Item " .. tostring(item.itemID))) .. slot, CFG.colors.text, indent or 16)
end

local function FindMapIDFromResultNames(resultNames)
    if type(resultNames) ~= "table" or not KeyLab.GearLootMapping or not KeyLab.GearLootMapping.GetDungeonList then
        return nil
    end

    local lookup = {}
    for _, dungeon in ipairs(KeyLab.GearLootMapping.GetDungeonList() or {}) do
        lookup[NormalizeName(dungeon.name)] = dungeon.mapID
    end

    for _, name in ipairs(resultNames) do
        local normalized = NormalizeName(name)
        for dungeonKey, mapID in pairs(lookup) do
            if normalized == dungeonKey or normalized:find(dungeonKey, 1, true) or dungeonKey:find(normalized, 1, true) then
                return mapID
            end
        end
    end
    return nil
end

local function GetDungeonName(mapID)
    local db = KeyLab.GearLootDatabase
    return db and db.dungeons and db.dungeons[mapID] and db.dungeons[mapID].name or nil
end

local function EnsureFrame()
    if frame then return frame end

    frame = CreateFrame("Frame", "KeyLabGearTargetsWindow", UIParent, "BackdropTemplate")
    frame:SetSize(CFG.width, CFG.minHeight)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self.userMoved = true
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
    end)
    SetBackdrop(frame, CFG.colors.bg, CFG.colors.border)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
    frame.title:SetText("KeyLab Gear Targets")
    frame.title:SetTextColor(unpack(CFG.colors.gold))

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
    frame.subtitle:SetPoint("RIGHT", frame, "RIGHT", -44, 0)
    frame.subtitle:SetText("Targets saved from KeyLab's loot database")
    frame.subtitle:SetTextColor(unpack(CFG.colors.muted))

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function()
        frame.manualOpen = false
        frame.autoOpen = false
        frame:Hide()
    end)

    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -62)
    frame.content:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    frame.content:SetHeight(CFG.maxHeight - 75)
    frame.lines = {}

    if not RestorePosition(frame) then
        frame:SetPoint("RIGHT", UIParent, "RIGHT", -90, 10)
    end

    frame:Hide()
    return frame
end

function GearWindow.Refresh(resultNames)
    local f = EnsureFrame()
    f.currentResultNames = resultNames
    f.lineIndex = 0

    local tracked = GetTrackedTable()
    local total = 0
    for _, enabled in pairs(tracked) do if enabled then total = total + 1 end end

    local mapID = FindMapIDFromResultNames(resultNames)
    local specID = CurrentSpecID()

    if mapID and KeyLab.GearLootMapping and KeyLab.GearLootMapping.GetTargetSummaryForDungeon then
        local dungeonName = GetDungeonName(mapID) or "This Dungeon"
        local summary = KeyLab.GearLootMapping.GetTargetSummaryForDungeon(tracked, mapID, specID)

        AddLine(f, dungeonName .. " Gear Targets", CFG.colors.gold)
        AddLine(f, "This Dungeon", CFG.colors.blue)
        if #(summary.thisDungeon or {}) == 0 then
            AddLine(f, "No tracked items for this dungeon.", CFG.colors.muted, 16)
        else
            for i, item in ipairs(summary.thisDungeon) do
                if i > CFG.maxThisDungeonItemsShown then
                    AddLine(f, "+ " .. tostring(#summary.thisDungeon - CFG.maxThisDungeonItemsShown) .. " more", CFG.colors.muted, 16)
                    break
                end
                AddItem(f, item, 16)
            end
        end

        AddBlank(f)
        AddLine(f, "Other Targets", CFG.colors.blue)
        if #(summary.otherDungeons or {}) == 0 then
            AddLine(f, "No other tracked dungeon targets.", CFG.colors.muted, 16)
        else
            for i, info in ipairs(summary.otherDungeons) do
                if i > CFG.maxOtherDungeonsShown then
                    AddLine(f, "+ more dungeons", CFG.colors.muted, 16)
                    break
                end
                AddLine(f, tostring(info.dungeonName) .. " (" .. tostring(info.count) .. " item" .. (info.count == 1 and "" or "s") .. ")", CFG.colors.text, 16)
            end
        end

        total = summary.totalTargets or total
    else
        AddLine(f, "Tracked Gear", CFG.colors.gold)
        local targets = GetTrackedList()
        SortItems(targets)
        if #targets == 0 then
            AddLine(f, "No Gear Targets saved yet.", CFG.colors.muted)
            AddLine(f, "Open the Gear Targets tab and choose items as Targets.", CFG.colors.text, 16)
        else
            local byDungeon, names = {}, {}
            for _, item in ipairs(targets) do
                local dungeonName = item.dungeonName or "Unknown Source"
                if not byDungeon[dungeonName] then
                    byDungeon[dungeonName] = {}
                    table.insert(names, dungeonName)
                end
                table.insert(byDungeon[dungeonName], item)
            end
            table.sort(names)
            for _, dungeonName in ipairs(names) do
                AddBlank(f)
                AddLine(f, dungeonName, CFG.colors.gold)
                SortItems(byDungeon[dungeonName])
                for _, item in ipairs(byDungeon[dungeonName]) do
                    AddItem(f, item, 16)
                end
            end
        end
    end

    AddBlank(f)
    AddLine(f, "Total Targets: " .. tostring(total), CFG.colors.muted)
    HideUnusedLines(f)

    local neededHeight = 78 + ((f.lineIndex or 0) * 22)
    f:SetHeight(math.max(CFG.minHeight, math.min(CFG.maxHeight, neededHeight)))
end

function GearWindow.AnchorDefaultForLFG()
    local f = EnsureFrame()
    if f.userMoved or f.manualOpen then return end
    f:ClearAllPoints()
    f:SetPoint("RIGHT", UIParent, "RIGHT", -90, 10)
end

function GearWindow.ShowManual()
    local f = EnsureFrame()
    if not f.userMoved then
        f:ClearAllPoints()
        f:SetPoint("RIGHT", UIParent, "RIGHT", -90, 10)
    end
    f.manualOpen = true
    GearWindow.Refresh(nil)
    f:Show()
end

function GearWindow.ToggleManual()
    local f = EnsureFrame()
    if f:IsShown() and f.manualOpen then
        f.manualOpen = false
        f.autoOpen = false
        f:Hide()
    else
        GearWindow.ShowManual()
    end
end

function GearWindow.ShowForLFG(resultNames)
    local f = EnsureFrame()
    f.autoOpen = true
    f.currentResultNames = resultNames
    GearWindow.AnchorDefaultForLFG()
    GearWindow.Refresh(resultNames)
    f:Show()
end

function GearWindow.HideAuto()
    local f = EnsureFrame()
    f.autoOpen = false
    f.currentResultNames = nil
    if not f.manualOpen then
        f:Hide()
    else
        GearWindow.Refresh(nil)
    end
end

function GearWindow.RefreshVisible()
    local f = EnsureFrame()
    if f:IsShown() then
        GearWindow.Refresh(f.currentResultNames)
    end
end

return GearWindow
