-- KeyLab_GroupDashboard.lua
-- Runtime roster, inspection, manual aura-check, and group-composition logic.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

local Analysis = KeyLab.GroupDashboardAnalysis or {}
KeyLab.GroupDashboardAnalysis = Analysis

local UtilityDB = KeyLab.GroupUtilityDB or {}
local INSPECT_INTERVAL = 2.0
local INSPECT_TIMEOUT = 6.0
local AURA_STEP_DELAY = 0.10

local state = Analysis.state or {
    active = false,
    inGroup = false,
    membersByGUID = {},
    order = {},
    listeners = {},
    inspectQueue = {},
    inspectQueued = {},
    activeInspect = nil,
    inspectSequence = 0,
    scan = {
        active = false,
        complete = false,
        generation = 0,
        pending = {},
        completed = {},
        message = "Join or form a group to check status.",
    },
    compositionDirty = true,
}
Analysis.state = state

local recordsByClass = {}
local dependencyLabels = {}
for _, dependency in ipairs(UtilityDB.dependencies or {}) do
    dependencyLabels[dependency.id] = dependency.label
end
for _, record in ipairs(UtilityDB.records or {}) do
    recordsByClass[record.classFile] = recordsByClass[record.classFile] or {}
    table.insert(recordsByClass[record.classFile], record)
end

local function SafeCall(func, ...)
    if type(func) ~= "function" then return false end
    return pcall(func, ...)
end

local function IsInActiveGroup()
    local okRaid, inRaid = SafeCall(IsInRaid)
    if okRaid and inRaid then return true end
    local okGroup, inGroup = SafeCall(IsInGroup)
    return okGroup and inGroup == true
end

local function IsPlayerUnit(unit)
    local ok, result = SafeCall(UnitIsUnit, unit, "player")
    return ok and result == true
end

local function UnitExistsSafe(unit)
    local ok, exists = SafeCall(UnitExists, unit)
    return ok and exists == true
end

local function UnitGUIDSafe(unit)
    local ok, guid = SafeCall(UnitGUID, unit)
    if ok and type(guid) == "string" and guid ~= "" then return guid end
end

local function UnitFullNameSafe(unit)
    local ok, name, realm = SafeCall(UnitFullName, unit)
    if not ok or type(name) ~= "string" or name == "" then
        ok, name = SafeCall(UnitName, unit)
        realm = nil
    end
    if not ok or type(name) ~= "string" or name == "" then return "Unknown", "Unknown" end
    local fullName = name
    if type(realm) == "string" and realm ~= "" then fullName = name .. "-" .. realm end
    return name, fullName
end

local function RoleLabel(role)
    if role == "TANK" then return "Tank" end
    if role == "HEALER" then return "Healer" end
    if role == "DAMAGER" then return "Damage" end
    return "No Role"
end

local function StandardSpecName(specID, className, apiSpecName)
    local mapping = KeyLab.Mapping and KeyLab.Mapping.ClassSpecs
    local entry = mapping and mapping.GetSpec and mapping.GetSpec(specID, className, apiSpecName)
    return entry and entry.specName or apiSpecName
end

local function GetPlayerSpec()
    local specGetter = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization or GetSpecialization
    local infoGetter = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo or GetSpecializationInfo
    local ok, specIndex = SafeCall(specGetter)
    if not ok or not specIndex then return nil, nil, nil end
    local infoOK, specID, specName, _, _, role = SafeCall(infoGetter, specIndex)
    if not infoOK or not specID then return nil, nil, nil end
    return specID, specName, role
end

local function GetUnitTokens()
    local tokens = {}
    local okRaid, inRaid = SafeCall(IsInRaid)
    if okRaid and inRaid then
        local okCount, count = SafeCall(GetNumGroupMembers)
        count = okCount and tonumber(count) or 0
        for index = 1, count do
            local unit = "raid" .. index
            if UnitExistsSafe(unit) then table.insert(tokens, unit) end
        end
        return tokens
    end

    local okGroup, inGroup = SafeCall(IsInGroup)
    if not okGroup or not inGroup then return tokens end
    if UnitExistsSafe("player") then table.insert(tokens, "player") end
    local subgroupGetter = GetNumSubgroupMembers or GetNumPartyMembers
    local okCount, count = SafeCall(subgroupGetter)
    count = okCount and tonumber(count) or 0
    for index = 1, count do
        local unit = "party" .. index
        if UnitExistsSafe(unit) then table.insert(tokens, unit) end
    end
    return tokens
end

local function NotifyListeners(reason)
    state.compositionDirty = true
    for listener in pairs(state.listeners) do
        pcall(listener, reason or "update")
    end
end

local function ClearInspection()
    state.inspectQueue = {}
    state.inspectQueued = {}
    state.activeInspect = nil
    state.inspectSequence = (state.inspectSequence or 0) + 1
    SafeCall(ClearInspectPlayer)
end

local function ClearRoster()
    state.membersByGUID = {}
    state.order = {}
    ClearInspection()
    state.scan.generation = (state.scan.generation or 0) + 1
    state.scan.active = false
    state.scan.complete = false
    state.scan.pending = {}
    state.scan.completed = {}
    state.scan.message = "Join or form a group to check status."
    state.compositionDirty = true
end

local function UpdatePlayerMember(member)
    local specID, specName, role = GetPlayerSpec()
    if specID and specName then
        specName = StandardSpecName(specID, member.className, specName)
        member.specID = specID
        member.specName = specName
        member.specState = "Available"
        member.specRole = role
    else
        member.specID = nil
        member.specName = nil
        member.specState = "Unavailable"
    end

    local ok, _, equipped = SafeCall(GetAverageItemLevel)
    if ok and tonumber(equipped) and tonumber(equipped) > 0 then
        member.itemLevel = tonumber(equipped)
        member.itemLevelState = "Available"
    else
        member.itemLevel = nil
        member.itemLevelState = "Unavailable"
    end
end

local function UpdateMemberFromUnit(member, unit)
    member.unit = unit
    local name, fullName = UnitFullNameSafe(unit)
    member.name = name
    member.fullName = fullName

    local okClass, className, classFile, classID = SafeCall(UnitClass, unit)
    if okClass then
        member.className = className or member.className or "Unknown"
        member.classFile = classFile or member.classFile
        member.classID = classID or member.classID
    end

    local okRole, role = SafeCall(UnitGroupRolesAssigned, unit)
    if okRole then member.assignedRole = role end
    local okLeader, leader = SafeCall(UnitIsGroupLeader, unit)
    member.isLeader = okLeader and leader == true
    local okAssistant, assistant = SafeCall(UnitIsGroupAssistant, unit)
    member.isAssistant = okAssistant and assistant == true
    local okConnected, connected = SafeCall(UnitIsConnected, unit)
    member.connected = not okConnected or connected ~= false
    local okPlayer, isPlayerCharacter = SafeCall(UnitIsPlayer, unit)
    member.isNPC = okPlayer and isPlayerCharacter == false

    if IsPlayerUnit(unit) then
        member.isPlayer = true
        member.isNPC = false
        UpdatePlayerMember(member)
    else
        member.isPlayer = false
        if member.isNPC then
            member.specID = nil
            member.specName = nil
            member.itemLevel = nil
            member.specState = "Unavailable"
            member.itemLevelState = "Unavailable"
        else
            member.specState = member.specName and "Available" or (member.specState or "Loading")
            member.itemLevelState = member.itemLevel and "Available" or (member.itemLevelState or "Loading")
        end
    end
end

local ProcessNextInspection

local function ScheduleInspection(delay)
    if state.inspectTimerQueued then return end
    if not (C_Timer and C_Timer.After) then return end
    state.inspectTimerQueued = true
    C_Timer.After(tonumber(delay) or 0.1, function()
        state.inspectTimerQueued = false
        ProcessNextInspection()
    end)
end

local function QueueInspection(member)
    if not member or member.isPlayer or not member.guid then return end
    if member.isNPC then
        member.specState = "Unavailable"
        member.itemLevelState = "Unavailable"
        return
    end
    if member.specName and member.itemLevel then return end
    if state.inspectQueued[member.guid] or (state.activeInspect and state.activeInspect.guid == member.guid) then return end
    state.inspectQueued[member.guid] = true
    table.insert(state.inspectQueue, member.guid)
    if not member.specName then member.specState = "Loading" end
    if not member.itemLevel then member.itemLevelState = "Loading" end
end

local function QueueUnknownInspections()
    if not state.active then return end
    for _, guid in ipairs(state.order) do QueueInspection(state.membersByGUID[guid]) end
    ScheduleInspection(0.1)
end

local function RemoveMissingFromScan(present)
    local newPending = {}
    for _, guid in ipairs(state.scan.pending or {}) do
        if present[guid] then table.insert(newPending, guid) end
    end
    state.scan.pending = newPending
    for guid in pairs(state.scan.completed or {}) do
        if not present[guid] then state.scan.completed[guid] = nil end
    end
end

local function AddNewMembersToScan()
    if not state.scan.active then return end
    local pendingSet = {}
    for _, guid in ipairs(state.scan.pending or {}) do pendingSet[guid] = true end
    for _, guid in ipairs(state.order) do
        if not state.scan.completed[guid] and not pendingSet[guid] then
            table.insert(state.scan.pending, guid)
            pendingSet[guid] = true
            local member = state.membersByGUID[guid]
            if member then
                member.auraState = "Unchecked"
                member.auraResults = nil
            end
        end
    end
end

function Analysis.RefreshRoster(reason)
    if not IsInActiveGroup() then
        local hadGroup = state.inGroup
        state.inGroup = false
        if hadGroup or #state.order > 0 then ClearRoster() end
        NotifyListeners(reason or "solo")
        return
    end

    state.inGroup = true
    local tokens = GetUnitTokens()
    local present = {}
    for _, unit in ipairs(tokens) do
        local guid = UnitGUIDSafe(unit)
        if guid then
            present[guid] = true
            local member = state.membersByGUID[guid]
            if not member then
                member = {
                    guid = guid,
                    specState = "Loading",
                    itemLevelState = "Loading",
                    auraState = "Unchecked",
                }
                state.membersByGUID[guid] = member
                table.insert(state.order, guid)
            end
            UpdateMemberFromUnit(member, unit)
        end
    end

    local newOrder = {}
    for _, guid in ipairs(state.order) do
        if present[guid] then
            table.insert(newOrder, guid)
        else
            state.membersByGUID[guid] = nil
            state.inspectQueued[guid] = nil
        end
    end
    state.order = newOrder
    RemoveMissingFromScan(present)
    AddNewMembersToScan()
    QueueUnknownInspections()
    NotifyListeners(reason or "roster")
end

local function MarkInspectUnavailable(member, label)
    if not member then return end
    label = label or "Unavailable"
    if not member.specName then member.specState = label end
    if not member.itemLevel then member.itemLevelState = label end
end

local function FinishInspection(active, timedOut)
    if not active or state.activeInspect ~= active then return end
    local member = state.membersByGUID[active.guid]
    if timedOut and member then MarkInspectUnavailable(member, "Unavailable") end
    state.activeInspect = nil
    SafeCall(ClearInspectPlayer)
    NotifyListeners(timedOut and "inspect-timeout" or "inspect-ready")
    ScheduleInspection(INSPECT_INTERVAL)
end

ProcessNextInspection = function()
    if not state.active or state.activeInspect or #state.inspectQueue == 0 then return end
    local inCombat = (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player"))
    if inCombat then
        for _, guid in ipairs(state.inspectQueue) do MarkInspectUnavailable(state.membersByGUID[guid], "Waiting for combat") end
        NotifyListeners("inspect-combat")
        return
    end
    if InspectFrame and InspectFrame.IsShown and InspectFrame:IsShown() then
        ScheduleInspection(1.0)
        return
    end

    while #state.inspectQueue > 0 do
        local guid = table.remove(state.inspectQueue, 1)
        state.inspectQueued[guid] = nil
        local member = state.membersByGUID[guid]
        local unit = member and member.unit
        if member and unit and UnitExistsSafe(unit) and UnitGUIDSafe(unit) == guid then
            if not member.connected then
                MarkInspectUnavailable(member, "Unavailable")
            else
                local rangeOK, interact = SafeCall(CheckInteractDistance, unit, 1)
                local inspectOK, canInspect = SafeCall(CanInspect, unit)
                if not rangeOK or interact ~= true or not inspectOK or canInspect ~= true then
                    MarkInspectUnavailable(member, "Out of range")
                else
                    member.specState = member.specName and "Available" or "Inspecting"
                    member.itemLevelState = member.itemLevel and "Available" or "Inspecting"
                    state.inspectSequence = (state.inspectSequence or 0) + 1
                    local active = { guid = guid, unit = unit, sequence = state.inspectSequence }
                    state.activeInspect = active
                    local notifyOK = SafeCall(NotifyInspect, unit)
                    if not notifyOK then
                        MarkInspectUnavailable(member, "Unavailable")
                        state.activeInspect = nil
                        ScheduleInspection(INSPECT_INTERVAL)
                    elseif C_Timer and C_Timer.After then
                        C_Timer.After(INSPECT_TIMEOUT, function()
                            if state.activeInspect == active then FinishInspection(active, true) end
                        end)
                    end
                    NotifyListeners("inspect-start")
                    return
                end
            end
        end
    end
    NotifyListeners("inspect-queue-finished")
end

function Analysis.HandleInspectReady(guid)
    local active = state.activeInspect
    if not active or guid ~= active.guid then return end
    local member = state.membersByGUID[guid]
    local unit = member and member.unit
    if not member or not unit or UnitGUIDSafe(unit) ~= guid then
        FinishInspection(active, true)
        return
    end

    local inspectSpecGetter = C_SpecializationInfo and C_SpecializationInfo.GetInspectSpecialization or GetInspectSpecialization
    local specOK, specID = SafeCall(inspectSpecGetter, unit)
    specID = specOK and tonumber(specID) or nil
    if specID and specID > 0 then
        local inspectInfoGetter = GetSpecializationInfoByID
        local infoOK, _, specName, _, _, role = SafeCall(inspectInfoGetter, specID)
        if infoOK and type(specName) == "string" and specName ~= "" then
            specName = StandardSpecName(specID, member.className, specName)
            member.specID = specID
            member.specName = specName
            member.specRole = role
            member.specState = "Available"
        else
            member.specState = "Unavailable"
        end
    else
        member.specState = "Unavailable"
    end

    local itemGetter = C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel
    local itemOK, itemLevel = SafeCall(itemGetter, unit)
    itemLevel = itemOK and tonumber(itemLevel) or nil
    if itemLevel and itemLevel > 0 then
        member.itemLevel = itemLevel
        member.itemLevelState = "Available"
    else
        member.itemLevel = nil
        member.itemLevelState = "Unavailable"
    end
    FinishInspection(active, false)
end

local function CountScanCompleted()
    local count = 0
    for _, guid in ipairs(state.order) do
        if state.scan.completed[guid] then count = count + 1 end
    end
    return count
end

local function AddPlayerWeaponEnhancements(member, helpfulAuras)
    if not member or not member.isPlayer or type(helpfulAuras) ~= "table" then return end
    local getter = C_PaperDollInfo and C_PaperDollInfo.GetTemporaryEnchantmentInfo
    if type(getter) ~= "function" then return end

    for _, slot in ipairs({ 16, 17 }) do
        local ok, enchantInfo = SafeCall(getter, slot)
        local enchantID = ok and type(enchantInfo) == "table" and tonumber(enchantInfo.enchantID) or nil
        if enchantID and enchantID > 0 then
            local icon
            local textureOK, texture = SafeCall(GetInventoryItemTexture, "player", slot)
            if textureOK then icon = texture end
            helpfulAuras[#helpfulAuras + 1] = {
                name = slot == 16 and "Main-Hand Weapon Enhancement" or "Off-Hand Weapon Enhancement",
                icon = icon,
                applications = tonumber(enchantInfo.chargesRemaining) or 0,
                duration = enchantInfo.hasExpirationTime and (tonumber(enchantInfo.remainingTimeMs) or 0) / 1000 or nil,
                enchantID = enchantID,
                inventorySlot = slot,
                tooltipUnit = "player",
                isWeaponEnhancement = true,
            }
        end
    end
end

local function ScanMemberAuras(member)
    local unit = member and member.unit
    if not member or not unit or UnitGUIDSafe(unit) ~= member.guid then
        return "Unavailable", nil, "Unavailable — the roster changed before this player could be checked."
    end
    if not member.connected then return "Unavailable", nil, "Unavailable — player is offline." end
    if member.isNPC then return "Unavailable", nil, "Follower or NPC group member — aura check skipped." end

    if not member.isPlayer then
        local visibleOK, visible = SafeCall(UnitIsVisible, unit)
        if not visibleOK or visible ~= true then
            return "Out of range", nil, "Out of range — no aura was marked missing."
        end
    end

    local auraListGetter = C_UnitAuras and C_UnitAuras.GetUnitAuras
    local auraGetter = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    if type(auraListGetter) ~= "function" and type(auraGetter) ~= "function" then
        return "Unavailable", nil, "Unavailable — the aura API did not provide usable information."
    end

    local foundBySpellID = {}
    local helpfulAuras = {}
    local seenAuras = {}
    local function AddHelpfulAura(auraData)
        if type(auraData) ~= "table" then return end
        local spellID = tonumber(auraData.spellId or auraData.spellID)
        local name = auraData.name
        local icon = auraData.icon
        local key = auraData.auraInstanceID or (tostring(spellID or "") .. "|" .. tostring(name or ""))
        if seenAuras[key] then return end
        seenAuras[key] = true
        if spellID then foundBySpellID[spellID] = true end
        if icon or spellID then
            helpfulAuras[#helpfulAuras + 1] = {
                spellID = spellID,
                name = name,
                icon = icon,
                applications = tonumber(auraData.applications or auraData.charges) or 0,
                duration = tonumber(auraData.duration),
                expirationTime = tonumber(auraData.expirationTime),
            }
        end
    end
    if type(auraListGetter) == "function" then
        local ok, auras = SafeCall(auraListGetter, unit, "HELPFUL")
        if not ok or type(auras) ~= "table" then
            return "Unavailable", nil, "Unavailable — the aura API did not provide usable information."
        end
        for _, auraData in ipairs(auras) do
            AddHelpfulAura(auraData)
        end
    else
        for index = 1, 80 do
            local ok, auraData = SafeCall(auraGetter, unit, index, "HELPFUL")
            if not ok then return "Unavailable", nil, "Unavailable — the aura API did not provide usable information." end
            if not auraData then break end
            AddHelpfulAura(auraData)
        end
    end

    local results = {}
    for _, aura in ipairs(UtilityDB.readinessAuras or {}) do
        local present = false
        for _, spellID in ipairs(aura.spellIDs or {}) do
            if foundBySpellID[tonumber(spellID)] then present = true break end
        end
        results[aura.id] = present
    end
    AddPlayerWeaponEnhancements(member, helpfulAuras)
    return "Checked", results, nil, helpfulAuras
end

local ProcessNextAuraMember

local function FinishAuraScan(message)
    state.scan.active = false
    state.scan.complete = true
    state.scan.message = message or ("Checked " .. CountScanCompleted() .. " of " .. #state.order .. ".")
    NotifyListeners("aura-complete")
end

ProcessNextAuraMember = function(generation)
    if generation ~= state.scan.generation or not state.scan.active then return end
    if not state.inGroup then
        FinishAuraScan("The group ended before the status check finished.")
        return
    end
    if (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) then
        state.scan.active = false
        state.scan.complete = false
        state.scan.message = "Group status cannot be checked during combat. Try again afterward."
        NotifyListeners("aura-combat")
        return
    end

    local guid = table.remove(state.scan.pending, 1)
    if not guid then
        FinishAuraScan()
        return
    end
    local member = state.membersByGUID[guid]
    if member then
        member.auraState = "Checking"
        NotifyListeners("aura-member-start")
        local scanOK, auraState, results, message, helpfulAuras = SafeCall(ScanMemberAuras, member)
        if not scanOK then
            auraState = "Unavailable"
            results = nil
            message = "Unavailable — Blizzard protected this player's aura information."
            helpfulAuras = nil
        end
        if state.membersByGUID[guid] == member and UnitGUIDSafe(member.unit) == guid then
            member.auraState = auraState
            member.auraResults = results
            member.presentAuras = helpfulAuras
            member.auraMessage = message
            state.scan.completed[guid] = true
        end
    end
    state.scan.message = "Checking " .. CountScanCompleted() .. " of " .. #state.order .. "…"
    NotifyListeners("aura-progress")
    if C_Timer and C_Timer.After then
        C_Timer.After(AURA_STEP_DELAY, function() ProcessNextAuraMember(generation) end)
    else
        ProcessNextAuraMember(generation)
    end
end

function Analysis.StartAuraCheck()
    if not state.inGroup or #state.order == 0 then
        state.scan.message = "Join or form a group before checking status."
        NotifyListeners("aura-solo")
        return false
    end
    if (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) then
        state.scan.active = false
        state.scan.complete = false
        state.scan.message = "Group status cannot be checked during combat. Try again afterward."
        NotifyListeners("aura-combat")
        return false
    end

    state.scan.generation = (state.scan.generation or 0) + 1
    state.scan.active = true
    state.scan.complete = false
    state.scan.pending = {}
    state.scan.completed = {}
    for _, guid in ipairs(state.order) do
        table.insert(state.scan.pending, guid)
        local member = state.membersByGUID[guid]
        if member then
            member.auraState = "Unchecked"
            member.auraResults = nil
            member.presentAuras = nil
            member.auraMessage = nil
        end
    end
    state.scan.message = "Checking 0 of " .. #state.order .. "…"
    NotifyListeners("aura-start")
    ProcessNextAuraMember(state.scan.generation)
    return true
end

function Analysis.StopAuraCheck()
    if not state.scan.active then return false end
    state.scan.generation = (state.scan.generation or 0) + 1
    state.scan.active = false
    state.scan.complete = false
    state.scan.pending = {}
    state.scan.message = "Group status check stopped after " .. CountScanCompleted() .. " of " .. #state.order .. "."
    NotifyListeners("aura-stopped")
    return true
end

local function SpecMatches(record, specName)
    if type(specName) ~= "string" or specName == "" then return false end
    for _, allowed in ipairs(record.specs or {}) do
        if allowed == "All" or allowed == specName then return true end
    end
    return false
end

local function NewDependencyCounts()
    return { class_spec = 0, talent = 0, pet = 0, talent_pet = 0 }
end

local function NewChoiceCounts()
    return { class_spec = 0, talent = 0, pet = 0, talent_pet = 0 }
end

local function BuildComposition()
    local composition = {
        inGroup = state.inGroup,
        totalMembers = #state.order,
        knownMembers = 0,
        named = {},
        categories = {},
    }
    local namedSeen, categorySeen, choiceSeen = {}, {}, {}
    for _, definition in ipairs(UtilityDB.namedEffects or {}) do
        composition.named[definition.id] = {
            definition = definition,
            providerCount = 0,
            counts = NewDependencyCounts(),
            choices = NewChoiceCounts(),
            providers = {},
        }
        namedSeen[definition.id] = {}
    end
    for _, definition in ipairs(UtilityDB.categories or {}) do
        composition.categories[definition.id] = {
            definition = definition,
            counts = NewDependencyCounts(),
            choices = NewChoiceCounts(),
            providers = {},
        }
        categorySeen[definition.id] = {}
        choiceSeen[definition.id] = {}
    end

    for _, guid in ipairs(state.order) do
        local member = state.membersByGUID[guid]
        if member and member.classFile and member.specName then
            composition.knownMembers = composition.knownMembers + 1
            for _, record in ipairs(recordsByClass[member.classFile] or {}) do
                if SpecMatches(record, member.specName) then
                    if record.namedEffect and composition.named[record.namedEffect] and not namedSeen[record.namedEffect][guid] then
                        namedSeen[record.namedEffect][guid] = true
                        local named = composition.named[record.namedEffect]
                        local dependency = record.dependency or "talent"
                        local isChoice = record.choiceKey ~= nil
                        named.providerCount = named.providerCount + 1
                        if isChoice then
                            named.choices[dependency] = (named.choices[dependency] or 0) + 1
                        else
                            named.counts[dependency] = (named.counts[dependency] or 0) + 1
                        end
                        table.insert(named.providers, {
                            guid = guid,
                            name = member.name or member.fullName or "Unknown",
                            className = member.className,
                            specName = member.specName,
                            ability = record.ability,
                            dependency = record.dependency,
                            dependencyLabel = record.choiceKey and "Talent Choice" or (dependencyLabels[record.dependency] or record.dependency),
                            choice = isChoice,
                            availability = record.availability,
                            whatItDoes = record.whatItDoes,
                        })
                    end

                    for _, mapping in ipairs(record.categories or {}) do
                        local category = composition.categories[mapping.id]
                        if category then
                            local dependency = mapping.dependency or record.dependency or "build"
                            local providerKey = guid .. "|" .. tostring(record.actionKey)
                            local isChoice = record.choiceKey ~= nil
                            local choiceKey = guid .. "|" .. tostring(record.choiceKey or "")
                            if isChoice then
                                if not choiceSeen[mapping.id][choiceKey] then
                                    choiceSeen[mapping.id][choiceKey] = true
                                    category.choices[dependency] = (category.choices[dependency] or 0) + 1
                                    table.insert(category.providers, {
                                        name = member.name or member.fullName or "Unknown",
                                        className = member.className,
                                        specName = member.specName,
                                        ability = record.ability,
                                        dependency = dependency,
                                        dependencyLabel = dependencyLabels[dependency] or dependency,
                                        choice = true,
                                        availability = record.availability,
                                        whatItDoes = record.whatItDoes,
                                        targetScope = record.targetScope,
                                    })
                                end
                            elseif not categorySeen[mapping.id][providerKey] then
                                categorySeen[mapping.id][providerKey] = true
                                category.counts[dependency] = (category.counts[dependency] or 0) + 1
                                table.insert(category.providers, {
                                    name = member.name or member.fullName or "Unknown",
                                    className = member.className,
                                    specName = member.specName,
                                    ability = record.ability,
                                    dependency = dependency,
                                    dependencyLabel = dependencyLabels[dependency] or dependency,
                                    choice = false,
                                    availability = record.availability,
                                    whatItDoes = record.whatItDoes,
                                    targetScope = record.targetScope,
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    return composition
end

function Analysis.GetComposition()
    if state.compositionDirty or not state.composition then
        state.composition = BuildComposition()
        state.compositionDirty = false
    end
    return state.composition
end

function Analysis.GetRoster()
    local roster = {}
    for index, guid in ipairs(state.order) do
        local member = state.membersByGUID[guid]
        if member then
            member.arrivalIndex = index
            member.roleLabel = RoleLabel((member.assignedRole and member.assignedRole ~= "NONE") and member.assignedRole or member.specRole)
            table.insert(roster, member)
        end
    end
    return roster
end

function Analysis.GetScanState()
    return {
        active = state.scan.active == true,
        complete = state.scan.complete == true,
        message = state.scan.message,
        completed = CountScanCompleted(),
        total = #state.order,
    }
end

function Analysis.IsInGroup()
    return state.inGroup == true
end

function Analysis.AddListener(listener)
    if type(listener) == "function" then state.listeners[listener] = true end
end

function Analysis.RemoveListener(listener)
    state.listeners[listener] = nil
end

function Analysis.SetActive(active, source)
    state.activeConsumers = state.activeConsumers or {}
    source = tostring(source or "default")
    state.activeConsumers[source] = active == true or nil
    state.active = next(state.activeConsumers) ~= nil
    if state.active then
        Analysis.RefreshRoster("activate")
        QueueUnknownInspections()
    end
end

function Analysis.QueueRosterRefresh(reason)
    state.pendingRosterReason = reason or state.pendingRosterReason or "event"
    if state.rosterTimerQueued then return end
    state.rosterTimerQueued = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0.20, function()
            state.rosterTimerQueued = false
            local queuedReason = state.pendingRosterReason
            state.pendingRosterReason = nil
            Analysis.RefreshRoster(queuedReason)
        end)
    else
        state.rosterTimerQueued = false
        Analysis.RefreshRoster(state.pendingRosterReason)
        state.pendingRosterReason = nil
    end
end

function Analysis.Start()
    if state.eventFrame then return end
    local frame = CreateFrame("Frame")
    state.eventFrame = frame
    local events = {
        "GROUP_ROSTER_UPDATE",
        "INSPECT_READY",
        "PARTY_LEADER_CHANGED",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_REGEN_ENABLED",
        "PLAYER_ROLES_ASSIGNED",
        "PLAYER_SPECIALIZATION_CHANGED",
        "PLAYER_TALENT_UPDATE",
        "TRAIT_CONFIG_UPDATED",
        "UNIT_CONNECTION",
        "UNIT_NAME_UPDATE",
        "UNIT_PET",
    }
    for _, event in ipairs(events) do pcall(frame.RegisterEvent, frame, event) end
    frame:SetScript("OnEvent", function(_, event, arg1)
        if event == "INSPECT_READY" then
            Analysis.HandleInspectReady(arg1)
        elseif event == "PLAYER_REGEN_ENABLED" then
            QueueUnknownInspections()
        elseif event == "PLAYER_TALENT_UPDATE" or event == "TRAIT_CONFIG_UPDATED" or event == "UNIT_PET" then
            state.compositionDirty = true
            NotifyListeners(event)
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
            if arg1 == nil or arg1 == "player" then
                local playerGUID = UnitGUIDSafe("player")
                local member = playerGUID and state.membersByGUID[playerGUID]
                if member then UpdatePlayerMember(member) end
            else
                local guid = UnitGUIDSafe(arg1)
                local member = guid and state.membersByGUID[guid]
                if member and not member.isPlayer then
                    member.specID = nil
                    member.specName = nil
                    member.specState = "Loading"
                    QueueInspection(member)
                end
            end
            state.compositionDirty = true
            QueueUnknownInspections()
            NotifyListeners(event)
        else
            Analysis.QueueRosterRefresh(event)
        end
    end)
    Analysis.RefreshRoster("start")
end

Analysis.Start()

return Analysis
