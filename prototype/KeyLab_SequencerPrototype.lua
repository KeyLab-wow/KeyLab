local ADDON_NAME, KeyLab = ...

KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

--[[
KeyLab_SequencerPrototype.lua

Purpose:
- Prove KeyLab's secure execution model on the current Retail client before the
  complete Sequencer editor is built.
- Require one physical keyboard or mouse activation for every outer step.
- Keep all protected frames and bindings separate from the main KeyLab UI.
- Expose only a small slash-command test harness; this is not the final editor.

Deliberate prototype limits:
- Three action blocks per version.
- Two temporary versions (A and B).
- One Global Modifier Action per version.
- Only workbook options already marked Known Working are accepted.
- The structured Action, nil form accepts reset=target only in this prototype.
]]

local Prototype = {}
KeyLab.SequencerPrototype = Prototype

local SECURE_BUTTON_NAME = "KeyLabSequencerPrototypeButton"
local MAX_BLOCKS = 3
local MAX_BLOCK_CHARS = 255
local MODIFIER_BUDGET_OVERHEAD = 16
local VERSION_NAMES = { A = true, B = true }
local MODE_NAMES = {
    sequential = "Sequential",
    priority = "Priority",
    reverse = "Reverse Priority",
}
local MODIFIER_NAMES = { CTRL = true, SHIFT = true, ALT = true }

local SAFE_SUPPORT_COMMANDS = {
    startattack = true,
    stopcasting = true,
    stopmacro = true,
    petattack = true,
    focus = true,
}

local PRIMARY_COMMANDS = {
    cast = true,
    use = true,
    castsequence = true,
}

local NEEDS_TEST_PATTERNS = {
    { pattern = "@mouseovertarget", label = "@mouseovertarget" },
    { pattern = "@arenapet", label = "@arenapet" },
    { pattern = "equipped", label = "equipped/noequipped" },
    { pattern = "pvpcombat", label = "pvpcombat/nopvpcombat" },
    { pattern = "/cancelqueuedspell", label = "/cancelqueuedspell" },
    { pattern = "/cqs", label = "/cqs" },
    { pattern = "/stopspelltarget", label = "/stopspelltarget" },
    { pattern = "/petautocasttoggle", label = "/petautocasttoggle" },
    { pattern = "reset=combat", label = "reset=combat" },
}

local function Print(message)
    Prototype.lastMessage = tostring(message or "")
    if KeyLab.Print then
        KeyLab.Print("Sequencer Prototype: " .. tostring(message))
    else
        print("|cffd4af37KeyLab Sequencer Prototype:|r " .. tostring(message))
    end
end

local function Trim(value)
    value = tostring(value or "")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")
    return value
end

local function DecodeNewlines(value)
    return Trim(value):gsub("\\n", "\n")
end

local function CopyArray(source)
    local result = {}
    for index = 1, MAX_BLOCKS do
        result[index] = source and source[index] or nil
    end
    return result
end

local function CopyVersion(source)
    source = type(source) == "table" and source or {}
    return {
        mode = MODE_NAMES[source.mode] and source.mode or "sequential",
        blocks = CopyArray(source.blocks),
        modifierKey = MODIFIER_NAMES[source.modifierKey] and source.modifierKey or nil,
        modifierAction = Trim(source.modifierAction),
    }
end

local function DefaultVersion()
    return {
        mode = "sequential",
        blocks = {},
        modifierKey = nil,
        modifierAction = "",
    }
end

local function EnsureDB()
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.sequencerPrototype = type(KeyLabDB.sequencerPrototype) == "table" and KeyLabDB.sequencerPrototype or {}

    local db = KeyLabDB.sequencerPrototype
    db.activeVersion = VERSION_NAMES[db.activeVersion] and db.activeVersion or "A"
    db.versions = type(db.versions) == "table" and db.versions or {}
    db.versions.A = type(db.versions.A) == "table" and db.versions.A or DefaultVersion()
    db.versions.B = type(db.versions.B) == "table" and db.versions.B or nil
    db.binding = Trim(db.binding):upper()
    db.forceBinding = db.forceBinding == true
    db.report = type(db.report) == "table" and db.report or {}
    return db
end

local function ActiveVersion()
    local db = EnsureDB()
    db.versions[db.activeVersion] = type(db.versions[db.activeVersion]) == "table"
        and db.versions[db.activeVersion]
        or DefaultVersion()
    return db.versions[db.activeVersion], db
end

local function NormalizeMode(value)
    value = Trim(value):lower():gsub("[%s_-]+", "")
    if value == "sequential" or value == "seq" then return "sequential" end
    if value == "priority" or value == "prio" then return "priority" end
    if value == "reverse" or value == "reversepriority" or value == "rev" then return "reverse" end
    return nil
end

local function NormalizeBinding(value)
    value = Trim(value):upper():gsub("%s+", "")
    value = value:gsub("^CONTROL%-", "CTRL-")
    if value == "" then return nil, "Enter a keyboard key or BUTTON4/BUTTON5." end
    if value == "BUTTON1" or value == "BUTTON2" then
        return nil, "BUTTON1 and BUTTON2 are reserved for normal mouse clicking. Use BUTTON3, BUTTON4, or BUTTON5."
    end
    if not value:match("^[A-Z0-9%-]+$") then
        return nil, "That binding contains unsupported characters. Examples: F, CTRL-F, BUTTON4."
    end
    return value
end

local function ModifierBinding(binding, modifierKey)
    if not modifierKey then return nil end
    if binding:find("CTRL-", 1, true) or binding:find("SHIFT-", 1, true) or binding:find("ALT-", 1, true) then
        return nil, "A Global Modifier Action requires an unmodified sequence binding in this prototype."
    end
    return modifierKey .. "-" .. binding
end

local function FindNeedsTestOption(text)
    local lowered = tostring(text or ""):lower()
    for _, entry in ipairs(NEEDS_TEST_PATTERNS) do
        if lowered:find(entry.pattern, 1, true) then return entry.label end
    end
    return nil
end

local function SplitLines(text)
    local lines = {}
    text = tostring(text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    for line in (text .. "\n"):gmatch("(.-)\n") do
        line = Trim(line)
        if line ~= "" then table.insert(lines, line) end
    end
    return lines
end

local function ValidateActionNil(line)
    local lowered = tostring(line or ""):lower()
    if not lowered:find("reset=target", 1, true) then
        return false, "The prototype only exposes the confirmed reset=target Action, nil form."
    end
    if lowered:find("reset=combat", 1, true) then
        return false, "reset=combat remains hidden until its Retail test passes."
    end
    local commaCount = select(2, lowered:gsub(",", ""))
    if commaCount ~= 1 or not lowered:match(",%s*nil%s*$") then
        return false, "Use exactly one action followed by nil: /castsequence reset=target Action, nil"
    end
    return true
end

local function ValidateBlock(text, modifierOnly)
    text = Trim(text)
    if text == "" then return false, "The action block is empty." end
    if #text > MAX_BLOCK_CHARS then
        return false, "The action block is " .. tostring(#text) .. " characters; the maximum is 255."
    end

    local needsTest = FindNeedsTestOption(text)
    if needsTest then
        return false, tostring(needsTest) .. " is still marked Needs Test and is unavailable in the prototype."
    end

    local lines = SplitLines(text)
    local primaryCount = 0
    local primarySeen = false
    for _, line in ipairs(lines) do
        local command = line:match("^/(%S+)")
        if not command then
            return false, "Every non-empty line must begin with an approved slash command."
        end
        command = command:lower()

        if PRIMARY_COMMANDS[command] then
            primaryCount = primaryCount + 1
            primarySeen = true
            local remainder = Trim(line:match("^/%S+%s*(.*)$"))
            if remainder == "" then return false, "/" .. command .. " requires an action." end
            if command == "castsequence" then
                local valid, message = ValidateActionNil(line)
                if not valid then return false, message end
            end
        elseif SAFE_SUPPORT_COMMANDS[command] and not modifierOnly then
            if primarySeen then
                return false, "Supporting commands must appear above the primary action."
            end
        else
            return false, "/" .. command .. " is not exposed by the secure prototype."
        end
    end

    if primaryCount ~= 1 then
        return false, "Each block must contain exactly one /cast, /use, or structured Action, nil primary action."
    end
    if modifierOnly and #lines ~= 1 then
        return false, "The one Global Modifier Action must be a single primary-action line in version one."
    end
    return true
end

local function CollectBlocks(version)
    local blocks = {}
    local emptySeen = false
    for index = 1, MAX_BLOCKS do
        local text = Trim(version.blocks and version.blocks[index])
        if text == "" then
            emptySeen = true
        else
            if emptySeen then return nil, "Action blocks must be contiguous; fill the earlier empty block first." end
            local valid, message = ValidateBlock(text, false)
            if not valid then return nil, "Block " .. tostring(index) .. ": " .. tostring(message) end
            table.insert(blocks, text)
        end
    end
    if #blocks == 0 then return nil, "Add at least one action block before applying the prototype." end
    return blocks
end

local function BuildLoop(mode, blockCount)
    local result = {}
    if mode == "sequential" then
        for index = 1, blockCount do table.insert(result, index) end
    elseif mode == "priority" then
        for depth = 1, blockCount do
            for index = 1, depth do table.insert(result, index) end
        end
    elseif mode == "reverse" then
        for depth = 1, blockCount do
            for index = depth, 1, -1 do table.insert(result, index) end
        end
    end
    return result
end

local function LoopText(loop)
    local values = {}
    for _, blockIndex in ipairs(loop or {}) do table.insert(values, tostring(blockIndex)) end
    return table.concat(values, " -> ")
end

local secureButton = CreateFrame("Button", SECURE_BUTTON_NAME, nil, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
secureButton:RegisterForClicks("AnyDown", "AnyUp")

SecureHandlerWrapScript(secureButton, "OnClick", secureButton, [=[
    local useDown = self:GetAttribute("useOnKeyDown")
    local shouldExecute = (down and useDown) or ((not down) and (not useDown))
    if down then
        self:SetAttribute("downEvents", (tonumber(self:GetAttribute("downEvents")) or 0) + 1)
    else
        self:SetAttribute("upEvents", (tonumber(self:GetAttribute("upEvents")) or 0) + 1)
    end
    if shouldExecute then
        if down then
            self:SetAttribute("executedDownEvents", (tonumber(self:GetAttribute("executedDownEvents")) or 0) + 1)
        else
            self:SetAttribute("executedUpEvents", (tonumber(self:GetAttribute("executedUpEvents")) or 0) + 1)
        end
        local cursor = tonumber(self:GetAttribute("cursor")) or 1
        local loopLength = tonumber(self:GetAttribute("loopLength")) or 1
        local blockIndex = tonumber(self:GetAttribute("loop" .. cursor)) or 1
        local modifierKey = self:GetAttribute("modifierKey")
        -- The companion modifier binding securely invokes RightButton while the
        -- ordinary sequence binding invokes LeftButton. This avoids relying on
        -- modifier-key state APIs inside the restricted snippet.
        local useModifier = modifierKey and button == "RightButton"

        local macrotext
        if useModifier then
            macrotext = self:GetAttribute("modifierMacro")
        else
            macrotext = self:GetAttribute("block" .. blockIndex)
        end

        self:SetAttribute("type", "macro")
        self:SetAttribute("macrotext", macrotext)
        self:SetAttribute("lastBlock", blockIndex)
        self:SetAttribute("lastWasModifier", useModifier)
        self:SetAttribute("pressCount", (tonumber(self:GetAttribute("pressCount")) or 0) + 1)
        if useModifier then
            self:SetAttribute("modifierPresses", (tonumber(self:GetAttribute("modifierPresses")) or 0) + 1)
        end

        local combatState = SecureCmdOptionParse("[combat]1;0")
        if combatState == "1" then
            self:SetAttribute("combatPresses", (tonumber(self:GetAttribute("combatPresses")) or 0) + 1)
        end

        cursor = (cursor % loopLength) + 1
        self:SetAttribute("cursor", cursor)
    else
        -- Remove the prepared protected action before WoW handles the ignored
        -- edge. The opposite edge must neither execute nor advance.
        self:SetAttribute("type", nil)
        self:SetAttribute("macrotext", nil)
        self:SetAttribute("ignoredEdgeEvents", (tonumber(self:GetAttribute("ignoredEdgeEvents")) or 0) + 1)
    end
]=])

local bindingOwner = CreateFrame("Frame", "KeyLabSequencerPrototypeBindingOwner", nil)

local function InCombat()
    return InCombatLockdown and InCombatLockdown() == true
end

local function RequireOutOfCombat(action)
    if not InCombat() then return true end
    Print(tostring(action or "That change") .. " is unavailable during combat. The active secure prototype remains usable.")
    return false
end

local function BindingConflict(binding)
    if not binding or binding == "" or not GetBindingAction then return nil end
    local action = GetBindingAction(binding)
    if action and action:find(SECURE_BUTTON_NAME, 1, true) then return nil end
    if action and action ~= "" then return action end
    return nil
end

local function ClearBindings()
    if ClearOverrideBindings then ClearOverrideBindings(bindingOwner) end
end

local function ApplyBindings(binding, companionBinding, allowConflict)
    local conflict = BindingConflict(binding)
    local companionConflict = BindingConflict(companionBinding)
    if not allowConflict and (conflict or companionConflict) then
        local conflictBinding = conflict and binding or companionBinding
        local conflictAction = conflict or companionConflict
        return false, tostring(conflictBinding) .. " is already assigned to " .. tostring(conflictAction)
            .. ". Use /klseq bindforce " .. tostring(binding) .. " only if you want the prototype to override it temporarily."
    end

    ClearBindings()
    local ok, err = pcall(SetOverrideBindingClick, bindingOwner, true, binding, SECURE_BUTTON_NAME, "LeftButton")
    if not ok then return false, "The direct binding could not be applied: " .. tostring(err) end
    if companionBinding then
        ok, err = pcall(SetOverrideBindingClick, bindingOwner, true, companionBinding, SECURE_BUTTON_NAME, "RightButton")
        if not ok then
            ClearBindings()
            return false, "The modifier companion binding could not be applied: " .. tostring(err)
        end
    end
    return true
end

local function SetRuntimeReset(reason)
    if InCombat() then
        Prototype.pendingResetReason = reason or "pending reset"
        return false
    end
    secureButton:SetAttribute("cursor", 1)
    secureButton:SetAttribute("lastResetReason", tostring(reason or "manual"))
    secureButton:SetAttribute("resetCount", (tonumber(secureButton:GetAttribute("resetCount")) or 0) + 1)
    local db = EnsureDB()
    db.report.lastResetReason = tostring(reason or "manual")
    db.report.lastResetAt = time and time() or 0
    return true
end

function Prototype.Apply(reason)
    if not RequireOutOfCombat("Applying the prototype") then
        Prototype.pendingApply = true
        return false
    end

    local version, db = ActiveVersion()
    local blocks, blockError = CollectBlocks(version)
    if not blocks then Print(blockError); return false end

    local mode = MODE_NAMES[version.mode] and version.mode or "sequential"
    local loop = BuildLoop(mode, #blocks)
    local binding, bindingError = NormalizeBinding(db.binding)
    if not binding then Print(bindingError); return false end

    local modifierKey = MODIFIER_NAMES[version.modifierKey] and version.modifierKey or nil
    local modifierAction = Trim(version.modifierAction)
    local companionBinding
    if modifierKey then
        local valid, message = ValidateBlock(modifierAction, true)
        if not valid then Print("Global Modifier Action: " .. tostring(message)); return false end
        companionBinding, message = ModifierBinding(binding, modifierKey)
        if not companionBinding then Print(message); return false end
        for index, block in ipairs(blocks) do
            local effectiveLength = #block + #modifierAction + MODIFIER_BUDGET_OVERHEAD
            if effectiveLength > MAX_BLOCK_CHARS then
                Print("Block " .. tostring(index) .. " uses " .. tostring(effectiveLength)
                    .. " of 255 effective characters after the Global Modifier Action is included.")
                return false
            end
        end
    elseif modifierAction ~= "" then
        Print("Choose CTRL, SHIFT, or ALT for the saved Global Modifier Action, or turn it off.")
        return false
    end

    secureButton:SetAttribute("type", "macro")
    secureButton:SetAttribute("macrotext", nil)
    secureButton:SetAttribute("useOnKeyDown", GetCVarBool and GetCVarBool("ActionButtonUseKeyDown") or false)
    secureButton:SetAttribute("cursor", 1)
    secureButton:SetAttribute("mode", mode)
    secureButton:SetAttribute("activeVersion", db.activeVersion)
    secureButton:SetAttribute("blockCount", #blocks)
    secureButton:SetAttribute("loopLength", #loop)
    secureButton:SetAttribute("modifierKey", modifierKey)
    secureButton:SetAttribute("modifierMacro", modifierKey and modifierAction or nil)
    secureButton:SetAttribute("pressCount", 0)
    secureButton:SetAttribute("combatPresses", 0)
    secureButton:SetAttribute("modifierPresses", 0)
    secureButton:SetAttribute("downEvents", 0)
    secureButton:SetAttribute("upEvents", 0)
    secureButton:SetAttribute("executedDownEvents", 0)
    secureButton:SetAttribute("executedUpEvents", 0)
    secureButton:SetAttribute("ignoredEdgeEvents", 0)
    secureButton:SetAttribute("lastBlock", nil)
    secureButton:SetAttribute("lastWasModifier", false)
    secureButton:SetAttribute("resetCount", 0)
    secureButton:SetAttribute("lastResetReason", tostring(reason or "apply"))

    for index = 1, MAX_BLOCKS do secureButton:SetAttribute("block" .. index, blocks[index]) end
    for index = 1, 6 do secureButton:SetAttribute("loop" .. index, loop[index]) end

    local bound, bindError = ApplyBindings(binding, companionBinding, db.forceBinding)
    if not bound then Print(bindError); return false end

    Prototype.pendingApply = false
    Prototype.pendingResetReason = nil
    db.report.lastAppliedAt = time and time() or 0
    db.report.lastAppliedReason = tostring(reason or "manual")
    db.report.lastAppliedMode = mode
    db.report.lastAppliedVersion = db.activeVersion
    db.report.lastLoop = LoopText(loop)
    db.report.lastBinding = binding
    db.report.lastCompanionBinding = companionBinding

    Print(MODE_NAMES[mode] .. " Version " .. db.activeVersion .. " applied to " .. binding
        .. (companionBinding and (" and " .. companionBinding) or "") .. ".")
    Print("Loop: " .. LoopText(loop) .. ". Each position requires a new physical press.")
    return true
end

function Prototype.Reset(reason)
    if not RequireOutOfCombat("Resetting the prototype") then return false end
    if SetRuntimeReset(reason or "manual Reset Sequence") then
        Print("The outer loop was reset to its first position.")
        return true
    end
    return false
end

function Prototype.Unbind()
    if not RequireOutOfCombat("Clearing the prototype binding") then return false end
    ClearBindings()
    local db = EnsureDB()
    db.binding = ""
    db.forceBinding = false
    Prototype.pendingApply = false
    Print("Prototype bindings cleared. Your original WoW bindings were not changed.")
    return true
end

function Prototype.GetLastMessage()
    return Prototype.lastMessage or ""
end

function Prototype.GetEffectiveLength(blockText, modifierAction)
    blockText = Trim(blockText)
    modifierAction = Trim(modifierAction)
    if modifierAction == "" then return #blockText end
    return #blockText + #modifierAction + MODIFIER_BUDGET_OVERHEAD
end

function Prototype.GetEditorState()
    local version, db = ActiveVersion()
    local cursor = tonumber(secureButton:GetAttribute("cursor")) or 1
    local versionBlocks = CopyArray(version.blocks)
    return {
        activeVersion = db.activeVersion,
        mode = version.mode or "sequential",
        blocks = versionBlocks,
        modifierKey = version.modifierKey,
        modifierAction = version.modifierAction or "",
        binding = db.binding or "",
        forceBinding = db.forceBinding == true,
        report = db.report,
        runtime = {
            pressCount = tonumber(secureButton:GetAttribute("pressCount")) or 0,
            combatPresses = tonumber(secureButton:GetAttribute("combatPresses")) or 0,
            modifierPresses = tonumber(secureButton:GetAttribute("modifierPresses")) or 0,
            lastBlock = secureButton:GetAttribute("lastBlock"),
            nextBlock = secureButton:GetAttribute("loop" .. cursor),
            lastResetReason = secureButton:GetAttribute("lastResetReason") or db.report.lastResetReason,
            appliedVersion = secureButton:GetAttribute("activeVersion"),
            appliedMode = secureButton:GetAttribute("mode"),
            appliedBinding = db.report.lastBinding,
            appliedCompanionBinding = db.report.lastCompanionBinding,
            appliedModifierKey = secureButton:GetAttribute("modifierKey"),
            useOnKeyDown = secureButton:GetAttribute("useOnKeyDown") == true,
            downEvents = tonumber(secureButton:GetAttribute("downEvents")) or 0,
            upEvents = tonumber(secureButton:GetAttribute("upEvents")) or 0,
            executedDownEvents = tonumber(secureButton:GetAttribute("executedDownEvents")) or 0,
            executedUpEvents = tonumber(secureButton:GetAttribute("executedUpEvents")) or 0,
            ignoredEdgeEvents = tonumber(secureButton:GetAttribute("ignoredEdgeEvents")) or 0,
        },
    }
end

local function SetActionButtonUseKeyDown(value)
    value = value == true
    if C_CVar and C_CVar.SetCVar then
        C_CVar.SetCVar("ActionButtonUseKeyDown", value and "1" or "0")
        return true
    end
    if SetCVar then
        SetCVar("ActionButtonUseKeyDown", value and "1" or "0")
        return true
    end
    return false
end

function Prototype.SetEdgeTestMode(useOnKeyDown)
    if not RequireOutOfCombat("Changing WoW's action-key edge setting") then
        return false, Prototype.GetLastMessage()
    end
    local db = EnsureDB()
    if db.report.edgeTestOriginalUseOnKeyDown == nil then
        db.report.edgeTestOriginalUseOnKeyDown = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown") == true or false
    end
    if not SetActionButtonUseKeyDown(useOnKeyDown == true) then
        return false, "This client did not expose a supported ActionButtonUseKeyDown setter."
    end
    local applied = Prototype.Apply(useOnKeyDown and "Key Down edge test" or "Key Up edge test")
    return applied == true, Prototype.GetLastMessage()
end

function Prototype.RestoreEdgeTestMode()
    if not RequireOutOfCombat("Restoring WoW's action-key edge setting") then
        return false, Prototype.GetLastMessage()
    end
    local db = EnsureDB()
    local original = db.report.edgeTestOriginalUseOnKeyDown
    if original == nil then return false, "No earlier WoW action-key setting was recorded." end
    if not SetActionButtonUseKeyDown(original == true) then
        return false, "This client did not expose a supported ActionButtonUseKeyDown setter."
    end
    db.report.edgeTestOriginalUseOnKeyDown = nil
    local applied = Prototype.Apply("restored WoW key-edge setting")
    return applied == true, Prototype.GetLastMessage()
end

function Prototype.SaveEditorState(state)
    if not RequireOutOfCombat("Saving the Sequencer editor") then
        return false, Prototype.GetLastMessage()
    end
    state = type(state) == "table" and state or {}

    local currentVersion, db = ActiveVersion()
    local candidate = {
        mode = NormalizeMode(state.mode or currentVersion.mode),
        blocks = CopyArray(state.blocks or currentVersion.blocks),
        modifierKey = state.modifierKey and Trim(state.modifierKey):upper() or nil,
        modifierAction = Trim(state.modifierAction),
    }
    if not candidate.mode then return false, "Choose Sequential, Priority, or Reverse Priority." end
    if candidate.modifierKey == "" then candidate.modifierKey = nil end
    if candidate.modifierKey and not MODIFIER_NAMES[candidate.modifierKey] then
        return false, "Choose Ctrl, Shift, Alt, or Off for the Global Modifier Action."
    end

    local blocks, blockError = CollectBlocks(candidate)
    if not blocks then return false, blockError end

    if candidate.modifierKey then
        local valid, validationMessage = ValidateBlock(candidate.modifierAction, true)
        if not valid then return false, "Global Modifier Action: " .. tostring(validationMessage) end
        for index, block in ipairs(blocks) do
            local effectiveLength = Prototype.GetEffectiveLength(block, candidate.modifierAction)
            if effectiveLength > MAX_BLOCK_CHARS then
                return false, "Block " .. tostring(index) .. " uses " .. tostring(effectiveLength)
                    .. " of 255 characters after the Global Modifier Action is included."
            end
        end
    elseif candidate.modifierAction ~= "" then
        return false, "Choose Ctrl, Shift, or Alt for the Global Modifier Action, or clear its action."
    end

    local binding = Trim(state.binding ~= nil and state.binding or db.binding)
    if binding ~= "" then
        local normalized, bindingMessage = NormalizeBinding(binding)
        if not normalized then return false, bindingMessage end
        binding = normalized
    end

    currentVersion.mode = candidate.mode
    currentVersion.blocks = CopyArray(candidate.blocks)
    currentVersion.modifierKey = candidate.modifierKey
    currentVersion.modifierAction = candidate.modifierAction
    db.binding = binding
    db.forceBinding = state.forceBinding == true
    return true, "Editor changes saved."
end

function Prototype.ApplyEditorState(state)
    local saved, message = Prototype.SaveEditorState(state)
    if not saved then
        Print(message)
        return false, message
    end
    local applied = Prototype.Apply("Sequencer editor")
    return applied == true, Prototype.GetLastMessage()
end

function Prototype.ActivateVersion(versionName)
    if not RequireOutOfCombat("Changing the active Sequencer version") then
        return false, Prototype.GetLastMessage()
    end
    local currentVersion, db = ActiveVersion()
    local wanted = Trim(versionName):upper()
    if not VERSION_NAMES[wanted] then return false, "Choose Version A or B." end
    if wanted ~= db.activeVersion and type(db.versions[wanted]) ~= "table" then
        db.versions[wanted] = CopyVersion(currentVersion)
    end
    db.activeVersion = wanted
    if Trim(db.binding) == "" then
        SetRuntimeReset("version change")
        Print("Version " .. wanted .. " selected and reset. Capture a binding before applying the secure test.")
        return true, Prototype.GetLastMessage()
    end
    local applied = Prototype.Apply("version change")
    return applied == true, Prototype.GetLastMessage()
end

function Prototype.PrepareForAddonReset()
    Prototype.pendingApply = false
    Prototype.pendingResetReason = nil
    if KeyLab.Tabs and KeyLab.Tabs.Sequencer then
        KeyLab.Tabs.Sequencer.draft = nil
        KeyLab.Tabs.Sequencer.preserveDraft = false
    end
    if InCombat() then
        Prototype.pendingClearBindings = true
        return false
    end
    ClearBindings()
    Prototype.pendingClearBindings = false
    return true
end

function Prototype.Status()
    local version, db = ActiveVersion()
    local blocks = {}
    for index = 1, MAX_BLOCKS do
        if Trim(version.blocks and version.blocks[index]) ~= "" then table.insert(blocks, version.blocks[index]) end
    end
    local loop = BuildLoop(version.mode or "sequential", #blocks)
    local cursor = tonumber(secureButton:GetAttribute("cursor")) or 1
    local nextBlock = secureButton:GetAttribute("loop" .. cursor)
    local binding = db.binding ~= "" and db.binding or "Not set"

    Print("Version " .. tostring(db.activeVersion) .. " | " .. tostring(MODE_NAMES[version.mode] or version.mode)
        .. " | Binding " .. tostring(binding) .. " | Blocks " .. tostring(#blocks) .. ".")
    if GetBuildInfo then
        local versionText, buildText = GetBuildInfo()
        Print("Retail client " .. tostring(versionText or "unknown") .. " (build " .. tostring(buildText or "unknown") .. ").")
    end
    Print("Configured loop: " .. (#loop > 0 and LoopText(loop) or "No complete loop") .. ".")
    Print("Applied presses=" .. tostring(secureButton:GetAttribute("pressCount") or 0)
        .. " combat=" .. tostring(secureButton:GetAttribute("combatPresses") or 0)
        .. " modifier=" .. tostring(secureButton:GetAttribute("modifierPresses") or 0)
        .. " lastBlock=" .. tostring(secureButton:GetAttribute("lastBlock") or "none")
        .. " nextBlock=" .. tostring(nextBlock or "none") .. ".")
    Print("Last reset: " .. tostring(secureButton:GetAttribute("lastResetReason") or db.report.lastResetReason or "not recorded")
        .. (Prototype.pendingApply and " | Apply pending until combat ends." or ""))
end

local function PrintHelp()
    Print("The visual test editor is available from KeyLab's Sequencer tab. These slash commands remain optional diagnostic tools.")
    Print("/klseq block 1 /cast Spell Name  - set Block 1 (up to Block 3). Use \\n between support and primary lines.")
    Print("/klseq mode sequential|priority|reverse")
    Print("/klseq modifier ctrl|shift|alt /cast Utility Spell  - one Global Modifier Action, or /klseq modifier off")
    Print("/klseq bind F  or  /klseq bind BUTTON4  - refuses existing bindings; bindforce explicitly overrides for this session.")
    Print("/klseq apply | status | reset | version A|B | unbind | clear")
    Print("Action, nil example: /klseq block 3 /castsequence reset=target Hunter's Mark, nil")
end

local function RefuseConfigurationInCombat()
    if not InCombat() then return false end
    Print("Configuration is locked during combat. The already-applied secure sequence remains active.")
    return true
end

local function HandleSlash(message)
    message = Trim(message)
    if message == "" or message:lower() == "help" then PrintHelp(); return end

    local command, arguments = message:match("^(%S+)%s*(.-)%s*$")
    command = tostring(command or ""):lower()
    arguments = tostring(arguments or "")

    if command == "status" or command == "report" then Prototype.Status(); return end
    if command == "help" then PrintHelp(); return end
    if RefuseConfigurationInCombat() then return end

    local version, db = ActiveVersion()
    if command == "block" then
        local indexText, blockText = arguments:match("^(%d+)%s+(.+)$")
        local index = tonumber(indexText)
        if not index or index < 1 or index > MAX_BLOCKS then
            Print("Choose Block 1, 2, or 3.")
            return
        end
        blockText = DecodeNewlines(blockText)
        if blockText:lower() == "clear" then
            version.blocks[index] = nil
            Print("Block " .. tostring(index) .. " cleared. Run /klseq apply after the remaining blocks are contiguous.")
            return
        end
        local valid, validationMessage = ValidateBlock(blockText, false)
        if not valid then Print("Block " .. tostring(index) .. ": " .. tostring(validationMessage)); return end
        version.blocks[index] = blockText
        Print("Block " .. tostring(index) .. " saved for Version " .. db.activeVersion .. " (" .. tostring(#blockText) .. "/255). Run /klseq apply.")
        return
    end

    if command == "mode" then
        local mode = NormalizeMode(arguments)
        if not mode then Print("Choose sequential, priority, or reverse."); return end
        version.mode = mode
        Print("Version " .. db.activeVersion .. " mode set to " .. MODE_NAMES[mode] .. ". Run /klseq apply.")
        return
    end

    if command == "modifier" then
        if Trim(arguments):lower() == "off" then
            version.modifierKey = nil
            version.modifierAction = ""
            Print("Global Modifier Action turned off for Version " .. db.activeVersion .. ". Run /klseq apply.")
            return
        end
        local modifier, action = arguments:match("^(%S+)%s+(.+)$")
        modifier = tostring(modifier or ""):upper()
        action = DecodeNewlines(action)
        if not MODIFIER_NAMES[modifier] then Print("Choose CTRL, SHIFT, or ALT."); return end
        local valid, validationMessage = ValidateBlock(action, true)
        if not valid then Print("Global Modifier Action: " .. tostring(validationMessage)); return end
        version.modifierKey = modifier
        version.modifierAction = action
        Print(modifier .. " Global Modifier Action saved for Version " .. db.activeVersion .. ". Run /klseq apply.")
        return
    end

    if command == "bind" or command == "bindforce" then
        local binding, bindingMessage = NormalizeBinding(arguments)
        if not binding then Print(bindingMessage); return end
        db.binding = binding
        db.forceBinding = command == "bindforce"
        Print("Prototype binding set to " .. binding .. (db.forceBinding and " with explicit temporary override permission." or ".")
            .. " Run /klseq apply.")
        return
    end

    if command == "version" then
        local wanted = Trim(arguments):upper()
        if not VERSION_NAMES[wanted] then Print("Choose Version A or B."); return end
        if wanted ~= db.activeVersion and type(db.versions[wanted]) ~= "table" then
            db.versions[wanted] = CopyVersion(version)
            Print("Version " .. wanted .. " was created from Version " .. db.activeVersion .. " for prototype testing.")
        end
        db.activeVersion = wanted
        Prototype.Apply("version change")
        return
    end

    if command == "apply" then Prototype.Apply("manual apply"); return end
    if command == "reset" then Prototype.Reset("manual Reset Sequence"); return end
    if command == "unbind" then Prototype.Unbind(); return end
    if command == "clear" then
        ClearBindings()
        KeyLabDB.sequencerPrototype = nil
        EnsureDB()
        Print("All prototype-only settings and bindings were cleared.")
        return
    end

    Print("Unknown prototype command. Use /klseq help.")
end

SLASH_KEYLABSEQUENCERPROTOTYPE1 = "/keylabseq"
SLASH_KEYLABSEQUENCERPROTOTYPE2 = "/klseq"
SlashCmdList["KEYLABSEQUENCERPROTOTYPE"] = HandleSlash

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then EnsureDB() end
        return
    end

    if event == "PLAYER_LOGIN" then
        local db = EnsureDB()
        if db.binding ~= "" then
            if InCombat() then
                Prototype.pendingApply = true
            else
                Prototype.Apply("login or reload")
            end
        end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        local db = EnsureDB()
        db.report.lastCombatStartedAt = time and time() or 0
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        local db = EnsureDB()
        db.report.lastCombatEndedAt = time and time() or 0
        if Prototype.pendingClearBindings then
            ClearBindings()
            Prototype.pendingClearBindings = false
            Prototype.pendingApply = false
            Prototype.pendingResetReason = nil
        elseif Prototype.pendingApply then
            Prototype.Apply("deferred until combat ended")
        else
            SetRuntimeReset("combat end")
        end
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" and (arg1 == nil or arg1 == "player") then
        if InCombat() then
            Prototype.pendingResetReason = "specialization change"
        else
            SetRuntimeReset("specialization change")
        end
    end
end)

Prototype.secureButton = secureButton
Prototype.bindingOwner = bindingOwner
