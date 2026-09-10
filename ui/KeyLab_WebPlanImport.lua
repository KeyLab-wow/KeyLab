local _, KeyLab = ...
KeyLab = KeyLab or {}
KeyLab.WebPlanImport = KeyLab.WebPlanImport or {}
local Importer = KeyLab.WebPlanImport

local VALID_SLOTS = {
    Head=true, Neck=true, Shoulders=true, Back=true, Chest=true, Wrist=true,
    Hands=true, Waist=true, Legs=true, Feet=true, ["Finger 1"]=true,
    ["Finger 2"]=true, ["Trinket 1"]=true, ["Trinket 2"]=true,
    ["Main Hand"]=true, ["Off Hand"]=true,
}
local VALID_STATS = {crit=true, haste=true, mastery=true, versatility=true}
local BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local BASE64_VALUES = {}
for index = 1, #BASE64 do BASE64_VALUES[BASE64:sub(index,index)] = index - 1 end

local function Trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function Contains(list, wanted)
    for _, value in ipairs(list or {}) do if value == wanted then return true end end
    return false
end

local function DeepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, entry in pairs(value) do copy[DeepCopy(key, seen)] = DeepCopy(entry, seen) end
    return copy
end

local function RestoreTable(target, source)
    for key in pairs(target or {}) do target[key] = nil end
    for key, value in pairs(source or {}) do target[key] = DeepCopy(value) end
end

local function DecodeBase64Url(value)
    value = Trim(value):gsub("-", "+"):gsub("_", "/"):gsub("%s+", "")
    value = value:gsub("=+$", "")
    local output, accumulator, bitCount = {}, 0, 0
    for index = 1, #value do
        local digit = BASE64_VALUES[value:sub(index,index)]
        if digit == nil then return nil, "The import code contains an invalid character." end
        accumulator = accumulator * 64 + digit
        bitCount = bitCount + 6
        while bitCount >= 8 do
            bitCount = bitCount - 8
            local divisor = 2 ^ bitCount
            local byte = math.floor(accumulator / divisor)
            accumulator = accumulator - byte * divisor
            output[#output+1] = string.char(byte)
        end
    end
    return table.concat(output)
end

local function DecodeJSON(source)
    local index, length = 1, #source
    local ParseValue
    local function Skip()
        while index <= length and source:sub(index,index):match("%s") do index = index + 1 end
    end
    local function Fail(message) error(message .. " near character " .. tostring(index), 0) end
    local function ParseString()
        if source:sub(index,index) ~= '"' then Fail("Expected a string") end
        index = index + 1
        local out = {}
        while index <= length do
            local char = source:sub(index,index)
            index = index + 1
            if char == '"' then return table.concat(out) end
            if char == "\\" then
                local escaped = source:sub(index,index)
                index = index + 1
                local replacements = {['"']='"', ['\\']='\\', ['/']='/', b='\b', f='\f', n='\n', r='\r', t='\t'}
                if replacements[escaped] then out[#out+1] = replacements[escaped]
                elseif escaped == "u" then
                    local hex = source:sub(index,index+3)
                    if not hex:match("^%x%x%x%x$") then Fail("Invalid Unicode escape") end
                    index = index + 4
                    local code = tonumber(hex, 16)
                    if code < 128 then out[#out+1] = string.char(code)
                    elseif code < 2048 then out[#out+1] = string.char(192 + math.floor(code/64), 128 + code%64)
                    else out[#out+1] = string.char(224 + math.floor(code/4096), 128 + math.floor(code/64)%64, 128 + code%64) end
                else Fail("Invalid string escape") end
            else out[#out+1] = char end
        end
        Fail("Unterminated string")
    end
    local function ParseNumber()
        local value = source:sub(index):match("^-?%d+%.?%d*[eE]?[+-]?%d*")
        if not value or value == "" then Fail("Invalid number") end
        index = index + #value
        return tonumber(value)
    end
    local function ParseArray()
        index = index + 1
        local out = {}
        Skip()
        if source:sub(index,index) == "]" then index=index+1; return out end
        while true do
            out[#out+1] = ParseValue()
            Skip()
            local char = source:sub(index,index)
            if char == "]" then index=index+1; return out end
            if char ~= "," then Fail("Expected a comma or closing bracket") end
            index=index+1
        end
    end
    local function ParseObject()
        index = index + 1
        local out = {}
        Skip()
        if source:sub(index,index) == "}" then index=index+1; return out end
        while true do
            Skip()
            local key = ParseString()
            Skip()
            if source:sub(index,index) ~= ":" then Fail("Expected a colon") end
            index=index+1
            out[key] = ParseValue()
            Skip()
            local char = source:sub(index,index)
            if char == "}" then index=index+1; return out end
            if char ~= "," then Fail("Expected a comma or closing brace") end
            index=index+1
        end
    end
    ParseValue = function()
        Skip()
        local char = source:sub(index,index)
        if char == '"' then return ParseString() end
        if char == "{" then return ParseObject() end
        if char == "[" then return ParseArray() end
        if char == "-" or char:match("%d") then return ParseNumber() end
        if source:sub(index,index+3) == "true" then index=index+4; return true end
        if source:sub(index,index+4) == "false" then index=index+5; return false end
        if source:sub(index,index+3) == "null" then index=index+4; return nil end
        Fail("Unsupported JSON value")
    end
    local ok, result = pcall(ParseValue)
    if not ok then return nil, result end
    Skip()
    if index <= length then return nil, "Unexpected text after the plan data." end
    return result
end

local function ItemClosesOffHand(item, specID)
    if not item then return false end
    if item.slot ~= "Two-Hand" and item.slot ~= "Ranged" then return false end
    local mapping = KeyLab.GearLootMapping
    return not (mapping and mapping.IsTargetDualWieldEligible and mapping.IsTargetDualWieldEligible(item, specID))
end

local function ValidateGoals(payload, specID)
    local goals = type(payload.goals) == "table" and payload.goals or {}
    local values = type(goals.values) == "table" and goals.values or {}
    local order, seen = {}, {}
    for _, key in ipairs(type(goals.order) == "table" and goals.order or {}) do
        if not VALID_STATS[key] or seen[key] then return nil, "The secondary-stat priority is invalid." end
        seen[key]=true; order[#order+1]=key
    end
    for _, key in ipairs({"crit","mastery","haste","versatility"}) do if not seen[key] then order[#order+1]=key end end
    local normalizedValues = {}
    for key in pairs(VALID_STATS) do
        local value = tonumber(values[key]) or 0
        if value < 0 or value > 100 then return nil, "Each stat goal must be from 0% to 100%." end
        normalizedValues[key]=value
    end
    local primary = goals.primary
    if primary == "none" then primary=nil end
    local mapping = KeyLab.GearLootMapping
    local expected = mapping and mapping.GetPrimaryStatForSpec and mapping.GetPrimaryStatForSpec(specID)
    if primary and primary ~= expected then return nil, "The Primary First choice does not match this specialization." end
    local weapon = goals.weapon
    if mapping and mapping.ResolveMatcherWeaponSetup then
        local resolved, valid, message = mapping.ResolveMatcherWeaponSetup(specID, weapon)
        if not valid then return nil, message end
        weapon=resolved
    end
    return {order=order, values=normalizedValues, primary=primary, weapon=weapon, style=goals.style == "priority" and "priority" or "balanced"}
end

local function ValidateRecords(records, status, specID, targetsBySlot, seenItems, targetItemIDs)
    local mapping = KeyLab.GearLootMapping
    local out = {}
    if type(records) ~= "table" then return out end
    for _, record in ipairs(records) do
        local itemID, sourceID, slot = tonumber(record.itemID), tonumber(record.sourceID), tostring(record.slot or "")
        local item = itemID and mapping and mapping.GetItem and mapping.GetItem(itemID, specID, nil, sourceID)
        if not item then return nil, "Item " .. tostring(itemID or "?") .. " is not in KeyLab's current Season 2 database." end
        if not VALID_SLOTS[slot] or not Contains(mapping.GetTargetSlotInstances(item, specID), slot) then
            return nil, item.name .. " cannot be saved in " .. (slot ~= "" and slot or "that slot") .. "."
        end
        if not item.sources or not item.sources[sourceID] then return nil, item.name .. " does not have that saved source." end
        if status == "target" then
            if targetsBySlot[slot] then return nil, "The plan has more than one Target for " .. slot .. "." end
            local existingSlot = seenItems[itemID]
            local slots = mapping.GetTargetSlotInstances(item, specID)
            local multiWeapon = Contains(slots,"Main Hand") and Contains(slots,"Off Hand")
            if existingSlot and existingSlot ~= slot and not multiWeapon then return nil, item.name .. " is repeated in two Target slots." end
            targetsBySlot[slot]=itemID; seenItems[itemID]=slot
        else
            if not targetsBySlot[slot] then return nil, "An Alternative for " .. slot .. " has no Target in that slot." end
            if targetsBySlot[slot] == itemID then return nil, item.name .. " cannot be both Target and Alternative for " .. slot .. "." end
            if targetItemIDs and targetItemIDs[itemID] then return nil, item.name .. " is already a Target in " .. targetItemIDs[itemID] .. "." end
            if seenItems[itemID] then return nil, item.name .. " is repeated as an Alternative." end
            seenItems[itemID]=slot
        end
        out[#out+1] = {item=item,itemID=itemID,sourceID=sourceID,slot=slot,status=status}
    end
    return out
end

function Importer.Decode(code)
    code = Trim(code)
    if code:sub(1,5) ~= "KLG1:" then return nil, "The code must begin with KLG1:." end
    local json, decodeError = DecodeBase64Url(code:sub(6))
    if not json then return nil, decodeError end
    local payload, jsonError = DecodeJSON(json)
    if not payload then return nil, "KeyLab could not read the plan: " .. tostring(jsonError) end
    if payload.kind ~= "keylab-gear-plan" or tonumber(payload.version) ~= 1 then return nil, "This is not a supported KeyLab Gear Plan code." end
    if payload.season ~= "MN_S2" then return nil, "This plan is for a different KeyLab season." end
    local specID = tonumber(payload.specID)
    local currentSpec = KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.GetCurrentSpecID and KeyLab.LootTargetsDB.GetCurrentSpecID()
    if not specID or specID ~= currentSpec then
        local db = KeyLab.GearLootDatabase
        local planned = db and db.specs and db.specs[specID]
        return nil, "Switch to " .. tostring(planned and planned.specName or "the plan's specialization") .. " before importing this plan."
    end
    local goals, goalError = ValidateGoals(payload, specID)
    if not goals then return nil, goalError end
    local targetsBySlot, seenItems = {}, {}
    local targets, targetError = ValidateRecords(payload.targets, "target", specID, targetsBySlot, seenItems)
    if not targets then return nil, targetError end
    local alternatives, alternativeError = ValidateRecords(payload.alternatives, "alternative", specID, targetsBySlot, {}, seenItems)
    if not alternatives then return nil, alternativeError end
    local mainID, offID = targetsBySlot["Main Hand"], targetsBySlot["Off Hand"]
    local mapping = KeyLab.GearLootMapping
    local main = mainID and mapping.GetItem(mainID, specID)
    local off = offID and mapping.GetItem(offID, specID)
    if offID and main and ItemClosesOffHand(main, specID) then return nil, main.name .. " closes the Off Hand slot." end
    if off and off.slot == "Off Hand" and (not main or (main.slot ~= "One-Hand" and main.slot ~= "Main Hand")) then
        return nil, off.name .. " requires a one-handed Main Hand Target."
    end
    payload.specID=specID; payload.goals=goals; payload.targets=targets; payload.alternatives=alternatives
    return payload
end

local function GetCraftConflicts(payload)
    local crafts = KeyLab.CraftedPlansDB
    if not crafts then return nil end
    local all, seen = {}, {}
    for _, record in ipairs(payload.targets or {}) do
        local closes = record.slot == "Main Hand" and ItemClosesOffHand(record.item, payload.specID)
        for _, conflict in ipairs(crafts.GetConflicts(payload.specID, record.slot, nil, closes, false)) do
            local key = tostring(conflict.kind)..":"..tostring(conflict.id)..":"..tostring(conflict.slot)
            if not seen[key] then seen[key]=true; all[#all+1]=conflict end
        end
    end
    return crafts.ConflictDetails(all)
end

local function ApplyGoals(payload)
    local db, goals = KeyLab.StatGoalsDB, payload.goals
    if not db then return false, "Stat Goal storage is unavailable." end
    local ok, message = db.SetTargets(payload.specID, goals.values)
    -- A website plan may intentionally keep every value at zero. Store those
    -- values directly, then let the normal matcher require a non-zero goal.
    if not ok and message == "Enter your stat goal percentages before running the matcher." then
        for key, value in pairs(goals.values) do db.SetTarget(payload.specID, key, value) end
        ok=true
    end
    if not ok then return false, message end
    local stored = db.GetGoals(payload.specID)
    stored.displayOrder = DeepCopy(goals.order)
    db.SetMatchStyle(payload.specID, goals.style)
    ok, message = db.SetPrimaryStat(payload.specID, goals.primary or "none")
    if not ok then return false, message end
    ok, message = db.SetWeaponSetup(payload.specID, goals.weapon)
    if not ok then return false, message end
    return true
end

function Importer.Apply(payload)
    if InCombatLockdown and InCombatLockdown() then return false, "Wait until combat ends." end
    local db = KeyLab.LootTargetsDB
    if not db or db.GetCurrentSpecID() ~= payload.specID then return false, "Your specialization changed. Reopen the import." end
    local store = db.GetSpecStore(payload.specID, "MN_S2")
    local backup = DeepCopy(store)
    local conflicts = GetCraftConflicts(payload)
    if conflicts and #conflicts.conflicts > 0 and KeyLab.CraftedPlansDB then KeyLab.CraftedPlansDB.ApplyConflicts(conflicts, payload.specID) end
    db.ClearSpec(payload.specID, "MN_S2")
    table.sort(payload.targets, function(a,b)
        if a.slot == "Main Hand" then return true end
        if b.slot == "Main Hand" then return false end
        return a.slot < b.slot
    end)
    for _, record in ipairs(payload.targets) do
        local ok, message = db.SetTargetForSlot(payload.specID, record.item, record.slot, record.sourceID, true)
        if not ok then RestoreTable(store, backup); return false, "No plan was imported: " .. tostring(message) end
    end
    for _, record in ipairs(payload.alternatives) do
        local ok, message = db.SetAlternativeForSlot(payload.specID, record.item, record.slot, record.sourceID)
        if not ok then RestoreTable(store, backup); return false, "No plan was imported: " .. tostring(message) end
    end
    local ok, message = ApplyGoals(payload)
    if not ok then RestoreTable(store, backup); return false, "Items were restored because Stat Goals could not be saved: " .. tostring(message) end
    return true, conflicts
end

local function PreviewText(payload)
    local database = KeyLab.GearLootDatabase
    local spec = database and database.specs and database.specs[payload.specID]
    local lines = {
        (spec and (spec.className .. " - " .. spec.specName) or ("Spec " .. payload.specID)),
        "Season: Midnight Season 2",
        "",
        "Stat Goal Matcher",
        "Primary First: " .. (payload.goals.primary or "None"),
        "Match Style: " .. (payload.goals.style == "priority" and "Favor Priority" or "Balanced"),
        "Priority: " .. table.concat(payload.goals.order, " > "),
        string.format("Goals: Crit %g%% | Mastery %g%% | Haste %g%% | Versatility %g%%",
            payload.goals.values.crit, payload.goals.values.mastery, payload.goals.values.haste, payload.goals.values.versatility),
        "",
        "Targets (" .. #payload.targets .. ")",
    }
    table.sort(payload.targets, function(a,b) return a.slot < b.slot end)
    for _, record in ipairs(payload.targets) do lines[#lines+1] = "• " .. record.slot .. " - " .. record.item.name end
    lines[#lines+1]=""
    lines[#lines+1]="Alternatives (" .. #payload.alternatives .. ")"
    table.sort(payload.alternatives, function(a,b) return a.slot < b.slot end)
    for _, record in ipairs(payload.alternatives) do lines[#lines+1] = "• " .. record.slot .. " - " .. record.item.name end
    local conflicts = GetCraftConflicts(payload)
    if conflicts and #conflicts.conflicts > 0 then
        lines[#lines+1]=""
        lines[#lines+1]="Crafted Plans that will be replaced"
        lines[#lines+1]=conflicts.text
    end
    return table.concat(lines, "\n")
end

local function ColorComponents(color)
    return color[1] or color.r or 1, color[2] or color.g or 1, color[3] or color.b or 1, color[4] or color.a or 1
end

local function EnsureWindow()
    if Importer.frame then return Importer.frame end
    local theme = KeyLab.UI and KeyLab.UI.Theme
    local colors = theme and theme.colors or {
        background={0.01,0.02,0.05,0.98}, panel={0.03,0.06,0.12,1}, border={0.15,0.29,0.47,1},
        gold={0.84,0.77,0.56,1}, text={0.93,0.95,1,1}, muted={0.68,0.73,0.82,1}, green={0.44,0.84,0.55,1},
    }
    local frame = CreateFrame("Frame", "KeyLabWebPlanImportFrame", UIParent, "BackdropTemplate")
    frame:SetSize(760, 650)
    if KeyLab.UI and KeyLab.UI.AnchorPopupToPreparationPanel then KeyLab.UI:AnchorPopupToPreparationPanel(frame)
    else frame:SetPoint("RIGHT", UIParent, "RIGHT", -24, 0) end
    frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:EnableMouse(true)
    frame:SetMovable(true); frame:RegisterForDrag("LeftButton"); frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    frame:SetBackdropColor(ColorComponents(colors.background)); frame:SetBackdropBorderColor(ColorComponents(colors.gold))
    if theme and theme.AddPopupLogo then theme.AddPopupLogo(frame) end
    local title = frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    title:SetPoint("TOP",frame,"TOP",0,-18); title:SetText("Import Website Gear Plan"); title:SetTextColor(ColorComponents(colors.gold))
    local subtitle = frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    subtitle:SetPoint("TOP",title,"BOTTOM",0,-5); subtitle:SetSize(650,32); subtitle:SetText("Paste the complete KLG1 code. KeyLab validates and previews it before changing Targets, Alternatives, or Stat Goals."); subtitle:SetTextColor(ColorComponents(colors.muted))
    local close = theme and theme.CreateButton and theme.CreateButton(frame,"X",30,28) or CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
    close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-12,-12); if not close.label then close:SetSize(30,28); close:SetText("X") end
    close:SetScript("OnClick",function() frame:Hide() end)

    local inputBorder = CreateFrame("Frame",nil,frame,"BackdropTemplate")
    inputBorder:SetPoint("TOPLEFT",frame,"TOPLEFT",28,-88); inputBorder:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-28,-88); inputBorder:SetHeight(112)
    inputBorder:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    inputBorder:SetBackdropColor(ColorComponents(colors.panel)); inputBorder:SetBackdropBorderColor(ColorComponents(colors.border))
    local edit = CreateFrame("EditBox",nil,inputBorder)
    edit:SetPoint("TOPLEFT",inputBorder,"TOPLEFT",9,-8); edit:SetPoint("BOTTOMRIGHT",inputBorder,"BOTTOMRIGHT",-9,8); edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetMaxLetters(0); edit:SetFontObject("ChatFontNormal"); edit:SetTextInsets(2,2,2,2)
    edit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)

    local previewButton = theme and theme.CreateButton and theme.CreateButton(frame,"Preview Plan",120,28) or CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
    previewButton:SetPoint("TOPLEFT",inputBorder,"BOTTOMLEFT",0,-10); if not previewButton.label then previewButton:SetSize(120,28); previewButton:SetText("Preview Plan") end
    local status = frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    status:SetPoint("LEFT",previewButton,"RIGHT",12,0); status:SetSize(560,32); status:SetJustifyH("LEFT"); status:SetTextColor(ColorComponents(colors.muted))

    local scroll = CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",previewButton,"BOTTOMLEFT",0,-12); scroll:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-48,58)
    local content = CreateFrame("Frame",nil,scroll); content:SetSize(670,1); scroll:SetScrollChild(content)
    local preview = content:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    preview:SetPoint("TOPLEFT",content,"TOPLEFT",4,-4); preview:SetSize(650,1); preview:SetJustifyH("LEFT"); preview:SetJustifyV("TOP"); preview:SetTextColor(ColorComponents(colors.text))
    local apply = theme and theme.CreateButton and theme.CreateButton(frame,"Import This Plan",150,30) or CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
    apply:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-28,18); if not apply.label then apply:SetSize(150,30); apply:SetText("Import This Plan") end
    if theme and theme.StylePrimaryActionButton then theme.StylePrimaryActionButton(apply) end
    apply:Disable()

    local function SetPreview(text)
        preview:SetText(text or "")
        local height = math.max(260, preview:GetStringHeight()+12)
        content:SetHeight(height); preview:SetHeight(height)
    end
    previewButton:SetScript("OnClick",function()
        local payload, message = Importer.Decode(edit:GetText())
        frame.pendingPayload=payload
        if not payload then status:SetText(message or "This plan could not be read."); status:SetTextColor(1,.42,.32); SetPreview(""); apply:Disable(); return end
        status:SetText("Plan validated. Review every line before importing."); status:SetTextColor(ColorComponents(colors.green)); SetPreview(PreviewText(payload)); apply:Enable()
    end)
    apply:SetScript("OnClick",function()
        local payload=frame.pendingPayload
        if not payload then return end
        local ok, message = Importer.Apply(payload)
        if not ok then status:SetText(message or "The plan was not imported."); status:SetTextColor(1,.42,.32); return end
        status:SetText("Website plan imported successfully."); status:SetTextColor(ColorComponents(colors.green)); apply:Disable()
        if KeyLab.GearTargets and KeyLab.GearTargets.Refresh then KeyLab.GearTargets:Refresh() end
        if KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.RefreshVisible then KeyLab.GearTargetsWindow.RefreshVisible() end
        if KeyLab.GearDashboard and KeyLab.GearDashboard.Refresh then KeyLab.GearDashboard:Refresh() end
        if KeyLab.Print then KeyLab.Print("Website Gear Plan imported for the current specialization.") end
    end)
    frame.editBox=edit; frame.status=status; frame.preview=preview; frame.applyButton=apply; frame:Hide(); Importer.frame=frame
    return frame
end

function Importer.Open()
    if InCombatLockdown and InCombatLockdown() then if KeyLab.Print then KeyLab.Print("Wait until combat ends to import a website plan.") end; return end
    local frame=EnsureWindow(); frame.pendingPayload=nil; frame.editBox:SetText(""); frame.status:SetText(""); frame.preview:SetText(""); frame.applyButton:Disable()
    if KeyLab.UI and KeyLab.UI.AnchorPopupToPreparationPanel then KeyLab.UI:AnchorPopupToPreparationPanel(frame) end
    frame:Show(); frame:Raise(); frame.editBox:SetFocus()
end

return Importer
