local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.GearTargetsWindow = KeyLab.GearTargetsWindow or {}
local GearWindow = KeyLab.GearTargetsWindow

--[[
KeyLab_GearTargetsWindow.lua

Purpose:
- Standalone KeyLab-styled saved gear shopping list.
- Opens manually or while browsing Premade Group dungeon and raid listings.
- Shows the current specialization's still-needed Targets and a few Alternatives.
- Groups saved items by their recorded dungeon or raid instead of trying to
  infer the activity underneath the mouse.
]]

local CFG = {
    width = 620,
    minHeight = 310,
    maxHeight = 720,
    lineHeight = 19,
    maxAlternativesShown = 8,
    colors = {
        bg = {0.018, 0.026, 0.056, 0.98},
        panel = {0.026, 0.046, 0.086, 0.96},
        border = {0.240, 0.380, 0.620, 0.62},
        gold = {0.820, 0.760, 0.580, 1.0},
        text = {0.940, 0.960, 0.990, 1.0},
        muted = {0.680, 0.730, 0.820, 1.0},
        blue = {0.500, 0.680, 0.940, 1.0},
    },
}

local frame
local SLOT_SORT = {
    ["Head"] = 1, ["Neck"] = 2, ["Shoulders"] = 3, ["Back"] = 4,
    ["Chest"] = 5, ["Wrist"] = 6, ["Hands"] = 7, ["Waist"] = 8,
    ["Legs"] = 9, ["Feet"] = 10, ["Finger 1"] = 11, ["Finger 2"] = 12,
    ["Trinket 1"] = 13, ["Trinket 2"] = 14, ["Main Hand"] = 15, ["Off Hand"] = 16,
}

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
    fs:SetPoint("TOPLEFT", f.content, "TOPLEFT", 12 + (indent or 0),
        -((f.lineIndex - 1) * CFG.lineHeight))
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
    for index = (f.lineIndex or 0) + 1, #(f.lines or {}) do
        f.lines[index]:Hide()
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

local function GetTrackedList()
    if not (KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetSavedTargetsForSpec) then return {} end
    local out = {}
    for _, item in ipairs(KeyLab.LootTargetsDB.GetSavedTargetsForSpec(CurrentSpecID()) or {}) do
        -- Pending legacy records remain preserved in SavedVariables, but only
        -- assigned slot Targets belong in this shopping list.
        if item.slotInstance then table.insert(out, item) end
    end
    return out
end

local function GetAlternativesList()
    if not (KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetAllAlternativesForSpec) then return {} end
    local out = {}
    for _, item in ipairs(KeyLab.LootTargetsDB.GetAllAlternativesForSpec(CurrentSpecID()) or {}) do
        if item.slotInstance then table.insert(out, item) end
    end
    return out
end

local function GetDashboardState()
    if not (KeyLab.GearingAnalysis and KeyLab.GearingAnalysis.GetDashboardState) then return nil end
    local ok, state = pcall(KeyLab.GearingAnalysis.GetDashboardState)
    return ok and type(state) == "table" and state or nil
end

local function SlotHasCompletedMythTarget(state, slotInstance)
    local plan = state and state.plansBySlot and state.plansBySlot[slotInstance]
    return plan and plan.targetEquipped == true and plan.isMythTrack == true or false
end

local function GetTargetsStillNeeded(targets, state)
    local out = {}
    for _, item in ipairs(targets or {}) do
        if not SlotHasCompletedMythTarget(state, item.slotInstance) then
            table.insert(out, item)
        end
    end
    return out
end

local function GetAlternativesStillNeeded(alternatives, state)
    local out = {}
    for _, item in ipairs(alternatives or {}) do
        if not SlotHasCompletedMythTarget(state, item.slotInstance) then
            table.insert(out, item)
        end
    end
    return out
end

local function TrackFromTooltipData(data)
    if type(data) ~= "table" then return nil end
    for _, line in ipairs(data.lines or {}) do
        local values = { line.leftText or "", line.rightText or "" }
        for _, raw in ipairs(values) do
            local text = tostring(raw or "")
            text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            local lower = string.lower(text)
            if lower:match("myth%s+%d+/%d+") then return "Myth" end
            if lower:match("hero%s+%d+/%d+") then return "Hero" end
        end
    end
    return nil
end

local function ParseBagTrack(bagID, bagSlot)
    if not (C_TooltipInfo and C_TooltipInfo.GetBagItem) then return nil end
    local ok, data = pcall(C_TooltipInfo.GetBagItem, bagID, bagSlot)
    return ok and TrackFromTooltipData(data) or nil
end

local function GetBagItems()
    local out = {}
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemID) then
        return out
    end

    local bagIDs, seen = { 0 }, { [0] = true }
    local maxBag = tonumber(NUM_BAG_SLOTS) or 4
    for bagID = 1, maxBag do
        table.insert(bagIDs, bagID)
        seen[bagID] = true
    end
    local reagentBag = Enum and Enum.BagIndex and tonumber(Enum.BagIndex.ReagentBag) or 5
    if reagentBag and not seen[reagentBag] then table.insert(bagIDs, reagentBag) end

    for _, bagID in ipairs(bagIDs) do
        local rawSlotCount = C_Container.GetContainerNumSlots(bagID)
        local slotCount = tonumber(rawSlotCount) or 0
        for bagSlot = 1, slotCount do
            -- Empty Retail bag slots may return no Lua values at all. Capture
            -- the call first so tonumber always receives one value (nil).
            local rawItemID = C_Container.GetContainerItemID(bagID, bagSlot)
            local itemID = tonumber(rawItemID)
            if itemID then
                local track = ParseBagTrack(bagID, bagSlot)
                local current = out[itemID]
                if not current or track == "Myth" or (track == "Hero" and current.track ~= "Myth") then
                    out[itemID] = { track = track }
                end
            end
        end
    end
    return out
end

local function SortItems(items)
    table.sort(items, function(a, b)
        local slotA = tostring(a.slotInstance or a.slot or "")
        local slotB = tostring(b.slotInstance or b.slot or "")
        local orderA = SLOT_SORT[slotA] or 99
        local orderB = SLOT_SORT[slotB] or 99
        if orderA ~= orderB then return orderA < orderB end
        if slotA ~= slotB then return slotA < slotB end
        return StripColorCodes(a.name or a.itemID) < StripColorCodes(b.name or b.itemID)
    end)
end

local function AddItem(f, item, bagItems, isAlternative)
    local slotName = item.slotInstance or item.slot or "Gear"
    local itemName = StripColorCodes(item.name or ("Item " .. tostring(item.itemID)))
    local suffix = isAlternative and " (Alternative)" or ""
    local bagRecord = bagItems and bagItems[tonumber(item.itemID)]
    local bagTrack = bagRecord and (bagRecord.track or item.upgradeTrack)
    if bagTrack == "Hero" or bagTrack == "Myth" then
        suffix = suffix .. " (In Bags - " .. bagTrack .. ")"
    end
    AddLine(f, tostring(slotName) .. " - " .. itemName .. suffix,
        isAlternative and CFG.colors.blue or CFG.colors.text, 22)
end

local function GetTargetSource(item)
    local mapping = KeyLab.GearLootMapping
    local source
    if item and item.sourceID and mapping and mapping.GetSource then
        source = mapping.GetSource(item.sourceID)
    end

    if (not source or (source.sourceType ~= "Dungeon" and source.sourceType ~= "Raid"))
        and item and mapping and mapping.GetItemSources then
        for _, candidate in ipairs(mapping.GetItemSources(item.itemID, CurrentSpecID()) or {}) do
            if candidate.sourceType == "Dungeon" or candidate.sourceType == "Raid" then
                source = candidate
                break
            end
        end
    end

    local sourceName = source and (source.name or source.sourceName)
        or item and item.sourceName
        or "Other Saved Gear"
    local sourceType = source and source.sourceType or item and item.sourceType
    if sourceType ~= "Dungeon" and sourceType ~= "Raid" then sourceType = "Other" end
    if sourceType == "Other" and (sourceName == "Bags" or tostring(sourceName):find("^Bags %- ")) then
        sourceName = "Other Saved Gear"
    end
    return {
        sourceID = source and tonumber(source.sourceID) or tonumber(item and item.sourceID),
        sourceName = sourceName,
        sourceType = sourceType,
    }
end

local function BuildTargetGroups(targets, alternatives)
    local groupsByKey, groups = {}, {}
    local function AddToGroup(item, isAlternative)
        local info = GetTargetSource(item)
        local key = info.sourceID and ("id:" .. tostring(info.sourceID))
            or (info.sourceType .. ":" .. NormalizeName(info.sourceName))
        local group = groupsByKey[key]
        if not group then
            group = {
                sourceID = info.sourceID,
                sourceName = info.sourceName,
                sourceType = info.sourceType,
                targets = {},
                alternatives = {},
            }
            groupsByKey[key] = group
            table.insert(groups, group)
        end
        table.insert(isAlternative and group.alternatives or group.targets, item)
    end

    for _, item in ipairs(targets or {}) do AddToGroup(item, false) end
    for _, item in ipairs(alternatives or {}) do AddToGroup(item, true) end

    local typeOrder = { Dungeon = 1, Raid = 2, Other = 3 }
    table.sort(groups, function(a, b)
        local orderA = typeOrder[a.sourceType] or 9
        local orderB = typeOrder[b.sourceType] or 9
        if orderA ~= orderB then return orderA < orderB end
        return tostring(a.sourceName or "") < tostring(b.sourceName or "")
    end)
    for _, group in ipairs(groups) do
        SortItems(group.targets)
        SortItems(group.alternatives)
    end
    return groups
end

local function FilterGroups(groups, sourceType)
    local out = {}
    for _, group in ipairs(groups or {}) do
        if group.sourceType == sourceType then table.insert(out, group) end
    end
    return out
end

local function AddGroupSection(f, title, groups, bagItems, alternativeBudget)
    if #(groups or {}) == 0 then return end
    local sectionStarted = false
    for _, group in ipairs(groups) do
        local canShowAlternative = alternativeBudget.value > 0 and #(group.alternatives or {}) > 0
        if #(group.targets or {}) > 0 or canShowAlternative then
            if not sectionStarted then
                AddBlank(f)
                AddLine(f, title, CFG.colors.blue)
                sectionStarted = true
            end
            AddLine(f, tostring(group.sourceName), CFG.colors.gold, 10)
            for _, item in ipairs(group.targets or {}) do
                AddItem(f, item, bagItems, false)
            end
            for _, item in ipairs(group.alternatives or {}) do
                if alternativeBudget.value > 0 then
                    AddItem(f, item, bagItems, true)
                    alternativeBudget.value = alternativeBudget.value - 1
                    alternativeBudget.shown = alternativeBudget.shown + 1
                end
            end
        end
    end
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
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    SetBackdrop(frame, CFG.colors.bg, CFG.colors.border)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
    frame.title:SetText("KeyLab Gear Targets")
    frame.title:SetTextColor(unpack(CFG.colors.gold))

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
    frame.subtitle:SetPoint("RIGHT", frame, "RIGHT", -44, 0)
    frame.subtitle:SetText("Your saved shopping list while browsing groups")
    frame.subtitle:SetTextColor(unpack(CFG.colors.muted))

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function()
        frame.manualOpen = false
        frame.autoOpen = false
        frame:Hide()
    end)

    frame.scroll = CreateFrame("ScrollFrame", nil, frame)
    frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -62)
    frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
    frame.scroll:EnableMouseWheel(true)
    frame.scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local maximum = math.max(0, (frame.content:GetHeight() or 0) - (self:GetHeight() or 0))
        self:SetVerticalScroll(math.max(0, math.min(maximum, current - (delta * 48))))
    end)

    frame.content = CreateFrame("Frame", nil, frame.scroll)
    frame.content:SetWidth(CFG.width - 38)
    frame.content:SetHeight(1)
    frame.scroll:SetScrollChild(frame.content)
    frame.lines = {}

    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:Hide()
    return frame
end

function GearWindow.Refresh()
    local f = EnsureFrame()
    f.currentResultNames = nil
    f.lineIndex = 0

    local allTargets = GetTrackedList()
    local allAlternatives = GetAlternativesList()
    local dashboardState = GetDashboardState()
    local targets = GetTargetsStillNeeded(allTargets, dashboardState)
    local alternatives = GetAlternativesStillNeeded(allAlternatives, dashboardState)
    local groups = BuildTargetGroups(targets, alternatives)
    local bagItems = GetBagItems()
    local alternativeBudget = { value = CFG.maxAlternativesShown, shown = 0 }

    AddLine(f, "Saved Gear Shopping List", CFG.colors.gold)
    AddLine(f, "Still-needed Targets and saved Alternatives, grouped by where they drop.", CFG.colors.muted)

    if #targets == 0 and #alternatives == 0 then
        AddBlank(f)
        AddLine(f, "No gear is currently needed from your saved plan.", CFG.colors.muted)
        AddLine(f, "Open Gear Targets to choose items you want to track.", CFG.colors.text)
    else
        AddGroupSection(f, "Dungeon Gear", FilterGroups(groups, "Dungeon"), bagItems, alternativeBudget)
        AddGroupSection(f, "Raid Gear", FilterGroups(groups, "Raid"), bagItems, alternativeBudget)
        AddGroupSection(f, "Other Saved Gear", FilterGroups(groups, "Other"), bagItems, alternativeBudget)
    end

    AddBlank(f)
    AddLine(f, "Targets Still Needed: " .. tostring(#targets)
        .. "  |  Alternatives Shown: " .. tostring(alternativeBudget.shown)
        .. " of " .. tostring(#alternatives), CFG.colors.muted)
    local hiddenAlternatives = #alternatives - alternativeBudget.shown
    if hiddenAlternatives > 0 then
        AddLine(f, "+ " .. tostring(hiddenAlternatives) .. " more Alternative"
            .. (hiddenAlternatives == 1 and "" or "s") .. " saved in Gear Targets.", CFG.colors.muted)
    end
    AddLine(f, "Equipped Myth-track Targets stay saved and are left off this list.", CFG.colors.muted)
    HideUnusedLines(f)

    local contentHeight = math.max(1, (f.lineIndex or 0) * CFG.lineHeight)
    f.content:SetHeight(contentHeight)
    f.scroll:SetVerticalScroll(0)
    local screenHeight = UIParent and UIParent.GetHeight and UIParent:GetHeight() or CFG.maxHeight + 80
    local maximumHeight = math.min(CFG.maxHeight, math.max(CFG.minHeight, screenHeight - 80))
    local neededHeight = 82 + contentHeight
    f:SetHeight(math.max(CFG.minHeight, math.min(maximumHeight, neededHeight)))
end

function GearWindow.AnchorDefaultForLFG()
    local f = EnsureFrame()
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

function GearWindow.ShowManual()
    local f = EnsureFrame()
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f.manualOpen = true
    GearWindow.Refresh()
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

function GearWindow.ShowForLFG()
    local f = EnsureFrame()
    local needsRefresh = not f:IsShown() or not f.autoOpen
    f.autoOpen = true
    f.currentResultNames = nil
    GearWindow.AnchorDefaultForLFG()
    if needsRefresh then GearWindow.Refresh() end
    f:Show()
end

function GearWindow.HideAuto()
    local f = EnsureFrame()
    f.autoOpen = false
    f.currentResultNames = nil
    if not f.manualOpen then
        f:Hide()
    else
        GearWindow.Refresh()
    end
end

function GearWindow.RefreshVisible()
    local f = EnsureFrame()
    if f:IsShown() then GearWindow.Refresh() end
end

return GearWindow
