local _, KeyLab = ...

KeyLab = KeyLab or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local Sequencer = {}
KeyLab.Tabs.Sequencer = Sequencer

local Theme = KeyLab.UITheme or {}
local COLORS = Theme.colors or {
    bg = {0.018, 0.026, 0.056, 0.98}, panel = {0.025, 0.040, 0.078, 0.94},
    border = {0.22, 0.34, 0.56, 0.62}, gold = {0.82, 0.76, 0.58, 1},
    text = {0.94, 0.96, 0.99, 1}, muted = {0.68, 0.73, 0.82, 1},
    green = {0.35, 0.88, 0.55, 1}, yellow = {1.0, 0.78, 0.28, 1},
    red = {1.0, 0.34, 0.34, 1}, blue = {0.46, 0.72, 1.0, 1},
}

local COMMAND_OPTIONS = {
    { value = "cast", label = "Cast Spell" },
    { value = "use", label = "Use Item" },
    { value = "castsequence", label = "Once Until Target Changes" },
    { value = "startattack", label = "Start Attack" },
    { value = "stopattack", label = "Stop Attack (Advanced)" },
    { value = "stopcasting", label = "Stop Casting" },
    { value = "stopmacro", label = "Stop Macro" },
    { value = "cancelaura", label = "Cancel Aura (Advanced)" },
    { value = "cancelform", label = "Cancel Form (Advanced)" },
    { value = "dismount", label = "Dismount (Advanced)" },
    { value = "petattack", label = "Pet Attack" },
    { value = "petfollow", label = "Pet Follow (Advanced)" },
    { value = "petpassive", label = "Pet Passive (Advanced)" },
    { value = "petassist", label = "Pet Assist (Advanced)" },
    { value = "focus", label = "Set Focus" },
    { value = "clearfocus", label = "Clear Focus (Advanced)" },
    { value = "target", label = "Change Selected Target (Advanced)" },
    { value = "cleartarget", label = "Clear Selected Target (Advanced)" },
    { value = "assist", label = "Assist Unit (Advanced)" },
    { value = "equip", label = "Equip (Advanced)" },
    { value = "equipslot", label = "Equip Slot (Advanced)" },
}

local PRIMARY = { cast = true, use = true, castsequence = true }

local function Lib()
    return KeyLab.SequencerLibrary or {}
end

local function Prototype()
    return KeyLab.SequencerPrototype or {}
end

local function Trim(value)
    value = tostring(value or "")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")
    return value
end

local function Color(region, color)
    if region and color then region:SetTextColor(color[1], color[2], color[3], color[4] or 1) end
end

local function Panel(parent, x, y, width, height, bg, border)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, y or 0)
    frame:SetSize(width, height)
    if Theme.StylePanel then
        Theme.StylePanel(frame, bg or COLORS.panel, border or COLORS.border)
    else
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        local fill, edge = bg or COLORS.panel, border or COLORS.border
        frame:SetBackdropColor(unpack(fill)); frame:SetBackdropBorderColor(unpack(edge))
    end
    return frame
end

local function Text(parent, value, template, size, color, justify)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    label:SetText(value or "")
    if size then local path = label:GetFont(); if path then label:SetFont(path, size, "") end end
    Color(label, color or COLORS.text)
    label:SetJustifyH(justify or "LEFT")
    label:SetJustifyV("TOP")
    return label
end

local function Button(parent, label, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 110, 24)
    button:SetText(label or "Button")
    button:SetScript("OnClick", onClick)
    return button
end

local function EditBox(parent, width, multiline)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width or 180, multiline and 54 or 22)
    box:SetAutoFocus(false)
    box:SetFontObject(multiline and "ChatFontNormal" or "GameFontHighlightSmall")
    box:SetMultiLine(multiline == true)
    if multiline then box:SetTextInsets(7, 7, 6, 6) end
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) if not multiline then self:ClearFocus() end end)
    return box
end

local function Dropdown(parent, width, optionsProvider, getValue, setValue)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, width or 150)
    dropdown.optionsProvider = optionsProvider
    dropdown.getValue = getValue
    dropdown.setValue = setValue
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        local options = type(optionsProvider) == "function" and optionsProvider() or optionsProvider or {}
        local current = getValue and getValue() or nil
        for _, option in ipairs(options) do
            local value, label = option.value, option.label
            local info = UIDropDownMenu_CreateInfo()
            info.text = label
            info.checked = current == value
            info.func = function()
                local accepted = setValue and setValue(value, option)
                if accepted == false then dropdown:RefreshText() else UIDropDownMenu_SetText(dropdown, label) end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    dropdown.RefreshText = function(self)
        local options = type(self.optionsProvider) == "function" and self.optionsProvider() or self.optionsProvider or {}
        local current = self.getValue and self.getValue() or nil
        for _, option in ipairs(options) do
            if option.value == current then UIDropDownMenu_SetText(self, option.label); return end
        end
        UIDropDownMenu_SetText(self, options[1] and options[1].label or "None")
    end
    dropdown:RefreshText()
    return dropdown
end

local function Confirm(key, textValue, onAccept)
    StaticPopupDialogs = StaticPopupDialogs or {}
    StaticPopupDialogs[key] = StaticPopupDialogs[key] or {
        text = "%s", button1 = YES, button2 = NO, timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
        OnAccept = function(_, data) if data and data.onAccept then data.onAccept() end end,
    }
    StaticPopup_Show(key, textValue, nil, { onAccept = onAccept })
end

local function Copy(value)
    return Lib().DeepCopy and Lib().DeepCopy(value) or value
end

local function ActionText(action)
    action = type(action) == "table" and action or {}
    return Trim(action.savedName) ~= "" and Trim(action.savedName) or Trim(action.text)
end

local function EnsureAction(clause)
    clause.action = type(clause.action) == "table" and clause.action or { text = Trim(clause.action), savedName = Trim(clause.action) }
    return clause.action
end

function Sequencer:SetStatus(message, kind)
    self.statusMessage = tostring(message or "")
    if self.statusText then
        self.statusText:SetText(self.statusMessage)
        Color(self.statusText, kind == "error" and COLORS.red or kind == "success" and COLORS.green or COLORS.yellow)
    end
    if self.recycleStatus then
        self.recycleStatus:SetText(self.statusMessage)
        Color(self.recycleStatus, kind == "error" and COLORS.red or kind == "success" and COLORS.green or COLORS.yellow)
    end
end

function Sequencer:MarkDirty(message)
    if self.loading then return end
    self.dirty = true
    self:SetStatus(message or "Unsaved changes.")
    self:RefreshEditorSummary()
end

function Sequencer:Collection()
    local collection = Lib().GetCollectionSnapshot and Lib().GetCollectionSnapshot() or { sequences = {}, order = {}, recycleBin = {} }
    return collection
end

function Sequencer:SequenceOptions()
    local collection = self:Collection()
    local options = {}
    for _, id in ipairs(collection.order or {}) do
        local sequence = collection.sequences[id]
        if sequence then table.insert(options, { value = id, label = sequence.name }) end
    end
    return options
end

function Sequencer:VersionOptions()
    local options = {}
    for _, id in ipairs(self.draft and self.draft.versionOrder or {}) do
        local version = self.draft.versions[id]
        if version then table.insert(options, { value = id, label = version.name .. (id == self.draft.activeVersionId and " (Active)" or "") }) end
    end
    return options
end

function Sequencer:CurrentVersion()
    return self.draft and self.draft.versions and self.draft.versions[self.editVersionId] or nil
end

function Sequencer:CurrentBlock()
    local version = self:CurrentVersion()
    return version and version.blocks and version.blocks[self.blockIndex] or nil
end

function Sequencer:CurrentCommand()
    local block = self:CurrentBlock()
    return block and block.commands and block.commands[self.commandIndex] or nil
end

function Sequencer:CurrentClause()
    local command = self:CurrentCommand()
    return command and command.clauses and command.clauses[self.clauseIndex] or nil
end

function Sequencer:LoadSequence(sequenceID, versionID)
    local options = self:SequenceOptions()
    if not sequenceID then sequenceID = options[1] and options[1].value end
    self.selectedSequenceId = sequenceID
    self.draft = sequenceID and Lib().GetSequenceCopy and Lib().GetSequenceCopy(sequenceID) or nil
    self.editVersionId = self.draft and (versionID or self.draft.activeVersionId or self.draft.versionOrder[1]) or nil
    self.blockIndex, self.commandIndex, self.clauseIndex, self.conditionIndex = 1, 1, 1, 1
    self.dirty = false
    self:RefreshEditorFields()
end

function Sequencer:DiscardDraft()
    local selected, version = self.selectedSequenceId, self.editVersionId
    self:LoadSequence(selected, version)
    self:SetStatus("Unsaved changes discarded.")
end

function Sequencer:SaveDraft(afterSave)
    if not self.draft then self:SetStatus("Create a sequence first.", "error"); return false end
    local valid, bindingMessage, conflictType = Lib().CheckBinding(self.draft.binding, self.draft.id)
    if not valid and conflictType == "keylab" then self:SetStatus(bindingMessage, "error"); return false end
    if not valid and conflictType == "wow" and not self.draft.forceBinding then
        Confirm("KEYLAB_SEQUENCE_REPLACE_BINDING", bindingMessage .. " Temporarily replace it while KeyLab is loaded?", function()
            Sequencer.draft.forceBinding = true
            Sequencer:SaveDraft(afterSave)
        end)
        return false
    end
    local ok, message = Lib().SaveSequence(self.draft)
    self:SetStatus(message, ok and "success" or "error")
    if ok then
        local sequenceID, versionID = self.draft.id, self.editVersionId
        self:LoadSequence(sequenceID, versionID)
        if afterSave then afterSave() end
    end
    return ok
end

function Sequencer:RequestSwitch(callback)
    if not self.dirty then callback(); return true end
    StaticPopupDialogs = StaticPopupDialogs or {}
    StaticPopupDialogs.KEYLAB_SEQUENCE_UNSAVED = StaticPopupDialogs.KEYLAB_SEQUENCE_UNSAVED or {
        text = "This sequence has unsaved changes.", button1 = "Save", button2 = "Discard", button3 = CANCEL,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        OnAccept = function(_, data) if data then Sequencer:SaveDraft(data.callback) end end,
        OnCancel = function(_, data, reason) if reason == "clicked" and data and data.callback then Sequencer:DiscardDraft(); data.callback() end end,
        OnAlt = function() end,
    }
    StaticPopup_Show("KEYLAB_SEQUENCE_UNSAVED", nil, nil, { callback = callback })
    return false
end

function Sequencer:RequestLeave(callback)
    if not self.dirty or (InCombatLockdown and InCombatLockdown()) then return true end
    self:RequestSwitch(function() if callback then callback() end end)
    return false
end

function Sequencer:RefreshEditorSummary()
    if not self.summaryText then return end
    local collection = self:Collection()
    local sequenceCount = #(collection.order or {})
    local version = self:CurrentVersion()
    local loopText, loopCount, blockCount = version and Lib().GetLoopPreview(version) or nil
    if not loopText then loopText, loopCount, blockCount = "Complete the current block to preview the loop.", 0, 0 end
    if #loopText > 360 then loopText = loopText:sub(1, 357) .. "..." end
    self.summaryText:SetText(
        tostring(collection.className or "Current Class") .. " / " .. tostring(collection.specName or "Current Spec") ..
        "  |  " .. tostring(sequenceCount) .. "/50 sequences  |  " ..
        tostring(self.draft and #(self.draft.versionOrder or {}) or 0) .. "/20 versions  |  " ..
        tostring(version and #(version.blocks or {}) or 0) .. "/50 blocks" ..
        (self.dirty and "  |  UNSAVED" or "") .. "\n" ..
        "One full loop (" .. tostring(loopCount or 0) .. " presses): " .. tostring(loopText)
    )
    Color(self.summaryText, self.dirty and COLORS.yellow or COLORS.muted)
    if self.priorityNotice then
        local show = version and version.mode ~= "sequential" and (blockCount or 0) > 3
        self.priorityNotice:SetText(show and ("Responsiveness notice: this priority loop expands to " .. tostring(loopCount) .. " presses before repeating.") or "")
    end
end

function Sequencer:RefreshGenerated()
    local block = self:CurrentBlock()
    local version = self:CurrentVersion()
    local generated, errorText = block and Lib().GenerateBlock(block) or nil
    local modifierText = ""
    if version and version.modifierKey and version.modifierCommand then
        modifierText = Lib().GenerateCommand(version.modifierCommand) or ""
    end
    local effective = generated and (#generated + (modifierText ~= "" and (#modifierText + 16) or 0)) or 0
    if self.generatedText then
        self.generatedText:SetText(generated or (errorText or "No complete generated action."))
        Color(self.generatedText, generated and COLORS.text or COLORS.red)
    end
    if self.characterCount then
        self.characterCount:SetText(tostring(effective) .. " / 255 effective characters")
        Color(self.characterCount, effective > 255 and COLORS.red or effective > 220 and COLORS.yellow or COLORS.muted)
    end
    self:RefreshEditorSummary()
end

function Sequencer:RefreshEditorFields()
    if not self.editorBuilt then return end
    self.loading = true
    local draft, version, block, command, clause = self.draft, self:CurrentVersion(), self:CurrentBlock(), self:CurrentCommand(), self:CurrentClause()
    self.sequenceDropdown:RefreshText(); self.versionDropdown:RefreshText(); self.blockDropdown:RefreshText()
    self.commandDropdown:RefreshText(); self.clauseDropdown:RefreshText(); self.targetDropdown:RefreshText()
    self.commandTypeDropdown:RefreshText(); self.modeDropdown:RefreshText(); self.modifierDropdown:RefreshText(); self.modifierTypeDropdown:RefreshText()
    self.sequenceNameBox:SetText(draft and draft.name or "")
    self.bindingBox:SetText(draft and draft.binding or "")
    self.versionNameBox:SetText(version and version.name or "")
    self.blockEnabled:SetChecked(block and block.enabled ~= false)
    local action = clause and EnsureAction(clause) or {}
    self.actionBox:SetText(ActionText(action))
    local condition = clause and clause.conditions and clause.conditions[self.conditionIndex] or nil
    self.conditionDropdown:RefreshText()
    local actionHint = command and (command.kind == "cast" and "Spell" or command.kind == "use" and "Item name, item ID, or inventory slot" or command.kind == "castsequence" and "Spell (reset=target and nil are generated)" or command.kind == "equipslot" and "Slot 16 or 17 followed by item" or "Optional command argument") or "Action"
    local spellsByID
    if Lib().GetSpellbook then local _, byID = Lib().GetSpellbook(); spellsByID = byID end
    local unavailable = tonumber(action.spellID) and (not spellsByID or not spellsByID[tonumber(action.spellID)])
    if unavailable then actionHint = "Unavailable: " .. ActionText(action) .. " (" .. tostring(action.spellID) .. ")" end
    self.actionHint:SetText(actionHint)
    Color(self.actionHint, unavailable and COLORS.red or COLORS.muted)
    if self.conditionEditBox then self.conditionEditBox:SetText(condition or "") end
    local modifierAction = version and version.modifierCommand and version.modifierCommand.clauses and version.modifierCommand.clauses[1] and EnsureAction(version.modifierCommand.clauses[1]) or {}
    self.modifierActionBox:SetText(ActionText(modifierAction))
    self.modifierTargetDropdown:RefreshText()
    self.loading = false
    self:RefreshGenerated()
    self:RefreshRuntime()
end

function Sequencer:BlockOptions()
    local options = {}
    local version = self:CurrentVersion()
    for index, block in ipairs(version and version.blocks or {}) do
        table.insert(options, { value = index, label = "Block " .. tostring(index) .. (block.enabled == false and " (Disabled)" or "") })
    end
    return options
end

function Sequencer:CommandOptions()
    local options = {}
    local block = self:CurrentBlock()
    for index, command in ipairs(block and block.commands or {}) do
        table.insert(options, { value = index, label = tostring(index) .. ". /" .. tostring(command.kind or "cast") })
    end
    return options
end

function Sequencer:ClauseOptions()
    local options = {}
    local command = self:CurrentCommand()
    for index in ipairs(command and command.clauses or {}) do table.insert(options, { value = index, label = "Clause " .. tostring(index) }) end
    return options
end

function Sequencer:ConditionOptions()
    local options = {}
    local clause = self:CurrentClause()
    for index, condition in ipairs(clause and clause.conditions or {}) do table.insert(options, { value = index, label = condition }) end
    if #options == 0 then table.insert(options, { value = 1, label = "No conditions" }) end
    return options
end

function Sequencer:TargetOptions()
    local options = { { value = "", label = "No temporary target" } }
    for _, value in ipairs(Lib().TARGET_OPTIONS or {}) do if value ~= "" then table.insert(options, { value = value, label = value }) end end
    return options
end

function Sequencer:ConditionPickerOptions()
    local options = {}
    for _, value in ipairs(Lib().CONDITION_OPTIONS or {}) do table.insert(options, { value = value, label = value }) end
    return options
end

function Sequencer:SpellOptions()
    local spells = Lib().GetSpellbook and Lib().GetSpellbook() or {}
    local options = {}
    for _, spell in ipairs(spells or {}) do table.insert(options, { value = spell.spellID, label = spell.label, spell = spell }) end
    if #options == 0 then table.insert(options, { value = 0, label = "No active spells found" }) end
    return options
end

function Sequencer:AddBlock(duplicate)
    local version = self:CurrentVersion()
    if not version then return end
    if #(version.blocks or {}) >= (Lib().MAX_BLOCKS or 50) then self:SetStatus("This version already has 50 blocks.", "error"); return end
    local source = duplicate and self:CurrentBlock()
    table.insert(version.blocks, source and Copy(source) or Lib().DefaultBlock())
    self.blockIndex = #version.blocks; self.commandIndex, self.clauseIndex = 1, 1
    self:MarkDirty(duplicate and "Block duplicated." or "Block added.")
    self:RefreshEditorFields()
end

function Sequencer:DeleteBlock()
    local version = self:CurrentVersion()
    if not version or #version.blocks <= 1 then self:SetStatus("A version must keep at least one block.", "error"); return end
    table.remove(version.blocks, self.blockIndex)
    self.blockIndex = math.min(self.blockIndex, #version.blocks); self.commandIndex, self.clauseIndex = 1, 1
    self:MarkDirty("Block removed from the draft."); self:RefreshEditorFields()
end

function Sequencer:MoveBlock(delta)
    local version = self:CurrentVersion(); if not version then return end
    local destination = self.blockIndex + delta
    if destination < 1 or destination > #version.blocks then return end
    version.blocks[self.blockIndex], version.blocks[destination] = version.blocks[destination], version.blocks[self.blockIndex]
    self.blockIndex = destination
    self:MarkDirty("Block order changed."); self:RefreshEditorFields()
end

function Sequencer:AddCommand()
    local block = self:CurrentBlock(); if not block then return end
    local insertAt = #block.commands + 1
    for index, command in ipairs(block.commands) do if PRIMARY[command.kind] then insertAt = index; break end end
    table.insert(block.commands, insertAt, Lib().DefaultCommand("startattack", ""))
    self.commandIndex, self.clauseIndex = insertAt, 1
    self:MarkDirty("Supporting command added above the primary action."); self:RefreshEditorFields()
end

function Sequencer:DeleteCommand()
    local block = self:CurrentBlock(); if not block or #block.commands <= 1 then self:SetStatus("A block must keep its primary command.", "error"); return end
    table.remove(block.commands, self.commandIndex)
    self.commandIndex = math.min(self.commandIndex, #block.commands); self.clauseIndex = 1
    self:MarkDirty("Command removed."); self:RefreshEditorFields()
end

function Sequencer:MoveCommand(delta)
    local block = self:CurrentBlock(); if not block then return end
    local destination = self.commandIndex + delta
    if destination < 1 or destination > #block.commands then return end
    block.commands[self.commandIndex], block.commands[destination] = block.commands[destination], block.commands[self.commandIndex]
    self.commandIndex = destination
    self:MarkDirty("Command order changed."); self:RefreshEditorFields()
end

function Sequencer:AddClause()
    local command = self:CurrentCommand(); if not command then return end
    if command.kind == "castsequence" then self:SetStatus("Once Until Target Changes supports one clause.", "error"); return end
    table.insert(command.clauses, Lib().DefaultClause("")); self.clauseIndex = #command.clauses
    self:MarkDirty("Fallback clause added."); self:RefreshEditorFields()
end

function Sequencer:DeleteClause()
    local command = self:CurrentCommand(); if not command or #command.clauses <= 1 then self:SetStatus("A command must keep at least one clause.", "error"); return end
    table.remove(command.clauses, self.clauseIndex); self.clauseIndex = math.min(self.clauseIndex, #command.clauses)
    self:MarkDirty("Clause removed."); self:RefreshEditorFields()
end

function Sequencer:MoveClause(delta)
    local command = self:CurrentCommand(); if not command then return end
    local destination = self.clauseIndex + delta
    if destination < 1 or destination > #command.clauses then return end
    command.clauses[self.clauseIndex], command.clauses[destination] = command.clauses[destination], command.clauses[self.clauseIndex]
    self.clauseIndex = destination
    self:MarkDirty("Clause order changed."); self:RefreshEditorFields()
end

function Sequencer:AddCondition(value)
    local clause = self:CurrentClause(); value = Trim(value)
    if not clause or value == "" then return end
    table.insert(clause.conditions, value); self.conditionIndex = #clause.conditions
    self:MarkDirty("Condition added."); self:RefreshEditorFields()
end

function Sequencer:DeleteCondition()
    local clause = self:CurrentClause(); if not clause or #(clause.conditions or {}) == 0 then return end
    table.remove(clause.conditions, self.conditionIndex); self.conditionIndex = math.max(1, math.min(self.conditionIndex, #clause.conditions))
    self:MarkDirty("Condition removed."); self:RefreshEditorFields()
end

function Sequencer:MoveCondition(delta)
    local clause = self:CurrentClause(); if not clause then return end
    local destination = self.conditionIndex + delta
    if destination < 1 or destination > #clause.conditions then return end
    clause.conditions[self.conditionIndex], clause.conditions[destination] = clause.conditions[destination], clause.conditions[self.conditionIndex]
    self.conditionIndex = destination
    self:MarkDirty("Condition order changed."); self:RefreshEditorFields()
end

function Sequencer:SelectSpell(option, modifier)
    if not option or not option.spell then return end
    local spell = option.spell
    local action
    if modifier then
        local version = self:CurrentVersion(); if not version then return end
        version.modifierCommand = version.modifierCommand or Lib().DefaultCommand("cast", "")
        action = EnsureAction(version.modifierCommand.clauses[1])
    else
        local clause = self:CurrentClause(); if not clause then return end
        action = EnsureAction(clause)
    end
    action.spellID, action.savedName, action.text, action.skillLine = spell.spellID, spell.name, spell.name, spell.skillLine
    self:MarkDirty("Spell selected from the live spellbook."); self:RefreshEditorFields()
end

function Sequencer:StartBindingCapture(target)
    if InCombatLockdown and InCombatLockdown() then self:SetStatus("Bindings cannot be changed during combat.", "error"); return end
    self.captureTarget = target or "sequence"
    local overlay = self.captureOverlay
    if not overlay then
        overlay = CreateFrame("Button", "KeyLabSequencerBindingCapture", UIParent, "BackdropTemplate")
        overlay:SetAllPoints(UIParent); overlay:SetFrameStrata("TOOLTIP"); overlay:EnableMouse(true); overlay:EnableKeyboard(true)
        if overlay.SetPropagateKeyboardInput then overlay:SetPropagateKeyboardInput(false) end
        overlay:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" }); overlay:SetBackdropColor(0.01, 0.02, 0.05, 0.90)
        local prompt = Text(overlay, "Press one keyboard key or mouse button\n\nEscape cancels", "GameFontNormalLarge", 20, COLORS.gold, "CENTER")
        prompt:SetPoint("CENTER"); prompt:SetSize(560, 100)
        overlay:SetScript("OnKeyDown", function(_, key)
            if key == "ESCAPE" then Sequencer:SetCapturedBinding(nil); return end
            if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then return end
            local parts = {}
            if IsControlKeyDown and IsControlKeyDown() then table.insert(parts, "CTRL") end
            if IsShiftKeyDown and IsShiftKeyDown() then table.insert(parts, "SHIFT") end
            if IsAltKeyDown and IsAltKeyDown() then table.insert(parts, "ALT") end
            table.insert(parts, tostring(key):upper()); Sequencer:SetCapturedBinding(table.concat(parts, "-"))
        end)
        overlay:SetScript("OnMouseDown", function(_, button)
            local map = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }
            if map[button] then Sequencer:SetCapturedBinding(map[button]) end
        end)
        self.captureOverlay = overlay
    end
    overlay:Show(); overlay:EnableKeyboard(true)
end

function Sequencer:SetCapturedBinding(binding)
    if self.captureOverlay then self.captureOverlay:EnableKeyboard(false); self.captureOverlay:Hide() end
    if not binding then self:SetStatus("Binding capture cancelled."); return end
    if self.captureTarget == "diagnostic" then
        local okay, message = Lib().CheckBinding(binding, nil)
        if not okay then self:SetStatus("Choose an unused diagnostic binding. " .. tostring(message), "error"); return end
        self.diagnosticBinding = binding
        if self.diagnosticBindingBox then self.diagnosticBindingBox:SetText(binding) end
        self:SetStatus("Diagnostic binding captured: " .. binding .. ".", "success")
        return
    end
    if not self.draft then return end
    local okay, message, conflictType = Lib().CheckBinding(binding, self.draft.id)
    if not okay and conflictType == "keylab" then self:SetStatus(message, "error"); return end
    if not okay and conflictType == "wow" then
        Confirm("KEYLAB_SEQUENCE_CAPTURE_CONFLICT", message .. " Temporarily replace it while KeyLab is loaded?", function()
            Sequencer.draft.binding = binding; Sequencer.draft.forceBinding = true
            Sequencer:MarkDirty("Binding captured with replacement approval."); Sequencer:RefreshEditorFields()
        end)
    else
        self.draft.binding = binding; self.draft.forceBinding = false
        self:MarkDirty("Binding captured: " .. binding .. "."); self:RefreshEditorFields()
    end
end

function Sequencer:RefreshRuntime()
    if not self.runtimeText then return end
    local runtime = self.draft and Lib().GetRuntime and Lib().GetRuntime(self.draft.id) or nil
    self.runtimeText:SetText(runtime and (
        "Applied presses " .. tostring(runtime.pressCount) .. "  |  combat " .. tostring(runtime.combatPresses) ..
        "  |  modifier " .. tostring(runtime.modifierPresses) .. "  |  last block " .. tostring(runtime.lastBlock or "-") ..
        "  |  next block " .. tostring(runtime.nextBlock or "-") .. "  |  last reset " .. tostring(runtime.lastResetReason or "-")
    ) or "Save the selected sequence to configure its protected button.")
end

function Sequencer:NewSequence()
    self:RequestSwitch(function()
        local id, message = Lib().CreateSequence("New Sequence")
        Sequencer:SetStatus(message, id and "success" or "error")
        if id then Sequencer:LoadSequence(id); if Sequencer.sequenceNameBox then Sequencer.sequenceNameBox:SetFocus(); Sequencer.sequenceNameBox:HighlightText() end end
    end)
end

function Sequencer:DuplicateSequence()
    if not self.draft then return end
    self:RequestSwitch(function()
        local id, message = Lib().DuplicateSequence(Sequencer.selectedSequenceId)
        Sequencer:SetStatus(message, id and "success" or "error")
        if id then Sequencer:LoadSequence(id) end
    end)
end

function Sequencer:DeleteSequence()
    if not self.draft then return end
    local id, name = self.draft.id, self.draft.name
    Confirm("KEYLAB_SEQUENCE_DELETE", "Delete " .. tostring(name) .. "? All versions will be recoverable for 30 days.", function()
        local ok, message = Lib().DeleteSequence(id); Sequencer:SetStatus(message, ok and "success" or "error"); Sequencer:LoadSequence(nil)
    end)
end

function Sequencer:AddVersion(duplicate)
    if not self.draft then return end
    local id, message = Lib().NewVersion(self.draft, duplicate and nil or "Version Default", duplicate and self.editVersionId or nil)
    self:SetStatus(message, id and "success" or "error")
    if id then self.editVersionId = id; self.blockIndex, self.commandIndex, self.clauseIndex = 1, 1, 1; self:MarkDirty(); self:RefreshEditorFields(); if self.versionNameBox then self.versionNameBox:SetFocus(); self.versionNameBox:HighlightText() end end
end

function Sequencer:DeleteVersion()
    if not self.draft then return end
    local sequenceID, versionID = self.draft.id, self.editVersionId
    local version = self:CurrentVersion()
    local committed = Lib().GetSequenceCopy and Lib().GetSequenceCopy(sequenceID) or nil
    if committed and not (committed.versions and committed.versions[versionID]) then
        self.draft.versions[versionID] = nil
        for index, id in ipairs(self.draft.versionOrder) do if id == versionID then table.remove(self.draft.versionOrder, index); break end end
        self.editVersionId = self.draft.versionOrder[1]
        self.blockIndex, self.commandIndex, self.clauseIndex = 1, 1, 1
        self:MarkDirty("Unsaved version removed from the draft."); self:RefreshEditorFields()
        return
    end
    Confirm("KEYLAB_VERSION_DELETE", "Delete version " .. tostring(version and version.name or "") .. "? It can be restored for 30 days.", function()
        Sequencer:RequestSwitch(function()
            local ok, message = Lib().DeleteVersion(sequenceID, versionID); Sequencer:SetStatus(message, ok and "success" or "error"); Sequencer:LoadSequence(sequenceID)
        end)
    end)
end

function Sequencer:ActivateVersion()
    if not self.draft then return end
    local sequenceID, versionID = self.draft.id, self.editVersionId
    local after = function()
        local ok, message = Lib().ActivateVersion(sequenceID, versionID)
        Sequencer:SetStatus(message, ok and "success" or "error"); Sequencer:LoadSequence(sequenceID, versionID)
    end
    if self.dirty then self:SaveDraft(after) else after() end
end

function Sequencer:PrepareEdgeTest()
    local version = self:CurrentVersion()
    local runtime, message = version and Lib().ValidateVersion(version) or nil
    local binding = Trim(self.diagnosticBinding)
    if not runtime then self:SetStatus(message or "Choose a complete version first.", "error"); return end
    if binding == "" then self:SetStatus("Capture an unused diagnostic binding first.", "error"); return end
    local okay, conflict = Lib().CheckBinding(binding, nil)
    if not okay then self:SetStatus("Choose an unused diagnostic binding. " .. tostring(conflict), "error"); return end
    local blocks = {}
    for index = 1, math.min(3, #runtime.blocks) do blocks[index] = runtime.blocks[index] end
    local ok, result = Prototype().ApplyEditorState({
        mode = runtime.mode, blocks = blocks, binding = binding, forceBinding = false,
        modifierKey = runtime.modifierKey, modifierAction = runtime.modifierText,
    })
    self:SetStatus(result or (ok and "Edge Test prepared." or "Edge Test could not be prepared."), ok and "success" or "error")
    self:RefreshDiagnostic()
end

function Sequencer:SetEdgeMode(useDown)
    local ok, message = Prototype().SetEdgeTestMode(useDown)
    self:SetStatus(message, ok and "success" or "error"); self:RefreshDiagnostic()
end

function Sequencer:RestoreEdgeMode()
    local ok, message = Prototype().RestoreEdgeTestMode()
    if ok and Prototype().Unbind then Prototype().Unbind() end
    self:SetStatus(message, ok and "success" or "error"); self:RefreshDiagnostic()
end

function Sequencer:RefreshDiagnostic()
    if not self.diagnosticResults then return end
    local state = Prototype().GetEditorState and Prototype().GetEditorState() or {}
    local runtime = state.runtime or {}
    local useDown = runtime.useOnKeyDown == true
    local executedDown, executedUp = tonumber(runtime.executedDownEvents) or 0, tonumber(runtime.executedUpEvents) or 0
    local presses = tonumber(runtime.pressCount) or 0
    local pass = presses > 0 and executedDown + executedUp == presses and ((useDown and executedUp == 0) or (not useDown and executedDown == 0))
    self.diagnosticResults:SetText(
        "Mode: " .. (useDown and "Key Down" or "Key Up") .. "  |  Presses: " .. tostring(presses) ..
        "  |  Down executed/events: " .. tostring(executedDown) .. "/" .. tostring(runtime.downEvents or 0) ..
        "  |  Up executed/events: " .. tostring(executedUp) .. "/" .. tostring(runtime.upEvents or 0) ..
        "  |  Ignored: " .. tostring(runtime.ignoredEdgeEvents or 0) .. "  |  One-edge filter: " .. (presses > 0 and (pass and "PASS" or "CHECK") or "Awaiting presses")
    )
    Color(self.diagnosticResults, pass and COLORS.green or COLORS.muted)
end

function Sequencer:SetView(view)
    self.selectedView = view or "editor"
    for key, panel in pairs(self.views or {}) do panel:SetShown(key == self.selectedView) end
    for key, button in pairs(self.viewButtons or {}) do
        local active = key == self.selectedView
        if button.SetBackdropBorderColor then button:SetBackdropBorderColor(unpack(active and COLORS.gold or COLORS.border)) end
        Color(button.label, active and COLORS.gold or COLORS.text)
    end
    if self.selectedView == "recycle" then self:RefreshRecycleBin() elseif self.selectedView == "information" then self:RefreshDiagnostic() else self:RefreshEditorFields() end
end

function Sequencer:BuildTop(frame)
    self.viewButtons = {}
    for index, definition in ipairs({ { key = "editor", label = "Editor" }, { key = "information", label = "Information" }, { key = "recycle", label = "Recycle Bin" } }) do
        local button = Panel(frame, 18 + ((index - 1) * 150), -72, 138, 30)
        button:EnableMouse(true)
        button.label = Text(button, definition.label, "GameFontNormal", nil, COLORS.text, "CENTER")
        button.label:SetAllPoints(button); button.label:SetJustifyV("MIDDLE")
        button:SetScript("OnMouseDown", function() Sequencer:SetView(definition.key) end)
        self.viewButtons[definition.key] = button
    end
end

function Sequencer:BuildEditor(frame)
    local view = CreateFrame("Frame", nil, frame); view:SetPoint("TOPLEFT", 18, -112); view:SetPoint("BOTTOMRIGHT", -18, 16)
    self.views.editor = view

    local library = Panel(view, 0, 0, 906, 100)
    local heading = Text(library, "Class / Specialization Sequence Library", "GameFontNormal", nil, COLORS.gold); heading:SetPoint("TOPLEFT", 12, -10)
    self.sequenceDropdown = Dropdown(library, 170, function() return Sequencer:SequenceOptions() end, function() return Sequencer.selectedSequenceId end, function(value)
        return Sequencer:RequestSwitch(function() Sequencer:LoadSequence(value) end)
    end); self.sequenceDropdown:SetPoint("TOPLEFT", -4, -30)
    self.sequenceNameBox = EditBox(library, 190); self.sequenceNameBox:SetPoint("TOPLEFT", 214, -38)
    self.sequenceNameBox:SetScript("OnTextChanged", function(box) if not Sequencer.loading and Sequencer.draft then Sequencer.draft.name = box:GetText(); Sequencer:MarkDirty() end end)
    local capture = Button(library, "Capture Binding", 125, function() Sequencer:StartBindingCapture("sequence") end); capture:SetPoint("TOPLEFT", 414, -36)
    self.bindingBox = EditBox(library, 100); self.bindingBox:SetPoint("TOPLEFT", 544, -38)
    self.bindingBox:SetScript("OnTextChanged", function(box) if not Sequencer.loading and Sequencer.draft then Sequencer.draft.binding = tostring(box:GetText() or ""):upper(); Sequencer.draft.forceBinding = false; Sequencer:MarkDirty() end end)
    local clearBind = Button(library, "Clear", 55, function() if Sequencer.draft then Sequencer.draft.binding = ""; Sequencer.draft.forceBinding = false; Sequencer:MarkDirty("Binding cleared in draft."); Sequencer:RefreshEditorFields() end end); clearBind:SetPoint("TOPLEFT", 650, -36)
    local newSequence = Button(library, "New", 55, function() Sequencer:NewSequence() end); newSequence:SetPoint("TOPLEFT", 716, -36)
    local duplicateSequence = Button(library, "Duplicate", 75, function() Sequencer:DuplicateSequence() end); duplicateSequence:SetPoint("TOPLEFT", 775, -36)
    local deleteSequence = Button(library, "Delete", 55, function() Sequencer:DeleteSequence() end); deleteSequence:SetPoint("TOPLEFT", 853, -36)
    self.summaryText = Text(library, "", "GameFontHighlightSmall", 11, COLORS.muted); self.summaryText:SetPoint("TOPLEFT", 12, -70); self.summaryText:SetSize(880, 30)

    local versionPanel = Panel(view, 0, -112, 906, 84)
    local versionHeading = Text(versionPanel, "Version", "GameFontNormal", nil, COLORS.gold); versionHeading:SetPoint("TOPLEFT", 12, -10)
    self.versionDropdown = Dropdown(versionPanel, 150, function() return Sequencer:VersionOptions() end, function() return Sequencer.editVersionId end, function(value)
        return Sequencer:RequestSwitch(function() Sequencer.editVersionId = value; Sequencer.blockIndex, Sequencer.commandIndex, Sequencer.clauseIndex = 1, 1, 1; Sequencer:RefreshEditorFields() end)
    end); self.versionDropdown:SetPoint("TOPLEFT", -4, -30)
    self.versionNameBox = EditBox(versionPanel, 170); self.versionNameBox:SetPoint("TOPLEFT", 195, -38)
    self.versionNameBox:SetScript("OnTextChanged", function(box) local version = Sequencer:CurrentVersion(); if not Sequencer.loading and version then version.name = box:GetText(); Sequencer:MarkDirty() end end)
    local activate = Button(versionPanel, "Activate", 75, function() Sequencer:ActivateVersion() end); activate:SetPoint("TOPLEFT", 374, -36)
    local addVersion = Button(versionPanel, "New", 55, function() Sequencer:AddVersion(false) end); addVersion:SetPoint("TOPLEFT", 455, -36)
    local copyVersion = Button(versionPanel, "Duplicate", 78, function() Sequencer:AddVersion(true) end); copyVersion:SetPoint("TOPLEFT", 514, -36)
    local deleteVersion = Button(versionPanel, "Delete", 55, function() Sequencer:DeleteVersion() end); deleteVersion:SetPoint("TOPLEFT", 596, -36)
    local modeLabel = Text(versionPanel, "Mode", "GameFontHighlightSmall", nil, COLORS.muted); modeLabel:SetPoint("TOPLEFT", 670, -12)
    self.modeDropdown = Dropdown(versionPanel, 150, { {value="sequential",label="Sequential"},{value="priority",label="Priority"},{value="reverse",label="Reverse Priority"} }, function() local v=Sequencer:CurrentVersion(); return v and v.mode end, function(value) local v=Sequencer:CurrentVersion(); if v then v.mode=value; Sequencer:MarkDirty("Sequence mode changed."); Sequencer:RefreshGenerated() end end)
    self.modeDropdown:SetPoint("TOPLEFT", 650, -30)

    local blockPanel = Panel(view, 0, -208, 906, 84)
    local blockHeading = Text(blockPanel, "Action Blocks", "GameFontNormal", nil, COLORS.gold); blockHeading:SetPoint("TOPLEFT", 12, -10)
    self.blockDropdown = Dropdown(blockPanel, 120, function() return Sequencer:BlockOptions() end, function() return Sequencer.blockIndex end, function(value) Sequencer.blockIndex=value; Sequencer.commandIndex,Sequencer.clauseIndex=1,1; Sequencer:RefreshEditorFields() end)
    self.blockDropdown:SetPoint("TOPLEFT", -4, -30)
    local addBlock=Button(blockPanel,"+ Block",68,function() Sequencer:AddBlock(false) end); addBlock:SetPoint("TOPLEFT",148,-36)
    local copyBlock=Button(blockPanel,"Duplicate",76,function() Sequencer:AddBlock(true) end); copyBlock:SetPoint("TOPLEFT",220,-36)
    local removeBlock=Button(blockPanel,"- Block",68,function() Sequencer:DeleteBlock() end); removeBlock:SetPoint("TOPLEFT",300,-36)
    local upBlock=Button(blockPanel,"Move Up",70,function() Sequencer:MoveBlock(-1) end); upBlock:SetPoint("TOPLEFT",372,-36)
    local downBlock=Button(blockPanel,"Move Down",82,function() Sequencer:MoveBlock(1) end); downBlock:SetPoint("TOPLEFT",446,-36)
    self.blockEnabled = CreateFrame("CheckButton", nil, blockPanel, "UICheckButtonTemplate"); self.blockEnabled:SetPoint("TOPLEFT", 540, -34); self.blockEnabled:SetSize(24,24)
    local enabledLabel=Text(blockPanel,"Enabled","GameFontHighlightSmall",nil,COLORS.text); enabledLabel:SetPoint("TOPLEFT",565,-40)
    self.blockEnabled:SetScript("OnClick",function(box) local block=Sequencer:CurrentBlock(); if block then block.enabled=box:GetChecked()==true; Sequencer:MarkDirty("Block enabled state changed."); Sequencer:RefreshEditorFields() end end)
    self.priorityNotice=Text(blockPanel,"","GameFontHighlightSmall",11,COLORS.yellow); self.priorityNotice:SetPoint("TOPLEFT",650,-39); self.priorityNotice:SetSize(240,32)

    local builder = Panel(view, 0, -304, 906, 232)
    local builderHeading=Text(builder,"Structured Command / Clause Builder","GameFontNormal",nil,COLORS.gold); builderHeading:SetPoint("TOPLEFT",12,-10)
    self.commandDropdown=Dropdown(builder,120,function() return Sequencer:CommandOptions() end,function() return Sequencer.commandIndex end,function(value) Sequencer.commandIndex=value;Sequencer.clauseIndex=1;Sequencer:RefreshEditorFields() end); self.commandDropdown:SetPoint("TOPLEFT",-4,-30)
    local addCommand=Button(builder,"+ Command",82,function() Sequencer:AddCommand() end); addCommand:SetPoint("TOPLEFT",148,-36)
    local removeCommand=Button(builder,"-",28,function() Sequencer:DeleteCommand() end); removeCommand:SetPoint("TOPLEFT",234,-36)
    local commandUp=Button(builder,"Up",38,function() Sequencer:MoveCommand(-1) end); commandUp:SetPoint("TOPLEFT",266,-36)
    local commandDown=Button(builder,"Down",48,function() Sequencer:MoveCommand(1) end); commandDown:SetPoint("TOPLEFT",308,-36)
    self.commandTypeDropdown=Dropdown(builder,190,COMMAND_OPTIONS,function() local c=Sequencer:CurrentCommand();return c and c.kind end,function(value)
        local command=Sequencer:CurrentCommand(); if command then command.kind=value; command.reset=value=="castsequence" and "target" or nil; if value=="castsequence" then while #command.clauses>1 do table.remove(command.clauses) end end; Sequencer:MarkDirty("Command type changed."); Sequencer:RefreshEditorFields() end
    end); self.commandTypeDropdown:SetPoint("TOPLEFT",366,-30)
    self.clauseDropdown=Dropdown(builder,100,function() return Sequencer:ClauseOptions() end,function() return Sequencer.clauseIndex end,function(value) Sequencer.clauseIndex=value;Sequencer.conditionIndex=1;Sequencer:RefreshEditorFields() end); self.clauseDropdown:SetPoint("TOPLEFT",572,-30)
    local addClause=Button(builder,"+ Clause",66,function() Sequencer:AddClause() end); addClause:SetPoint("TOPLEFT",692,-36)
    local removeClause=Button(builder,"-",28,function() Sequencer:DeleteClause() end); removeClause:SetPoint("TOPLEFT",762,-36)
    local clauseUp=Button(builder,"Up",38,function() Sequencer:MoveClause(-1) end); clauseUp:SetPoint("TOPLEFT",794,-36)
    local clauseDown=Button(builder,"Down",48,function() Sequencer:MoveClause(1) end); clauseDown:SetPoint("TOPLEFT",836,-36)

    local targetLabel=Text(builder,"Target","GameFontHighlightSmall",nil,COLORS.muted); targetLabel:SetPoint("TOPLEFT",12,-82)
    self.targetDropdown=Dropdown(builder,150,function() return Sequencer:TargetOptions() end,function() local c=Sequencer:CurrentClause();return c and c.target or "" end,function(value) local c=Sequencer:CurrentClause();if c then c.target=value;Sequencer:MarkDirty("Temporary target changed.");Sequencer:RefreshEditorFields() end end); self.targetDropdown:SetPoint("TOPLEFT",-4,-96)
    local removeTarget=Button(builder,"-",28,function() local c=Sequencer:CurrentClause();if c then c.target="";Sequencer:MarkDirty("Temporary target removed.");Sequencer:RefreshEditorFields() end end);removeTarget:SetPoint("TOPLEFT",148,-102)
    self.conditionChoice="exists"
    self.conditionChoiceDropdown=Dropdown(builder,120,function() return Sequencer:ConditionPickerOptions() end,function() return Sequencer.conditionChoice end,function(value) Sequencer.conditionChoice=value end); self.conditionChoiceDropdown:SetPoint("TOPLEFT",178,-96)
    local addCondition=Button(builder,"+ Condition",82,function() Sequencer:AddCondition(Sequencer.conditionChoice) end); addCondition:SetPoint("TOPLEFT",316,-102)
    self.conditionDropdown=Dropdown(builder,120,function() return Sequencer:ConditionOptions() end,function() return Sequencer.conditionIndex end,function(value) Sequencer.conditionIndex=value end); self.conditionDropdown:SetPoint("TOPLEFT",404,-96)
    local removeCondition=Button(builder,"-",28,function() Sequencer:DeleteCondition() end); removeCondition:SetPoint("TOPLEFT",542,-102)
    local conditionUp=Button(builder,"Up",38,function() Sequencer:MoveCondition(-1) end); conditionUp:SetPoint("TOPLEFT",574,-102)
    local conditionDown=Button(builder,"Down",48,function() Sequencer:MoveCondition(1) end); conditionDown:SetPoint("TOPLEFT",616,-102)
    self.conditionEditBox=EditBox(builder,210);self.conditionEditBox:SetPoint("TOPLEFT",404,-132)
    self.conditionEditBox:SetScript("OnTextChanged",function(box)
        if Sequencer.loading then return end
        local clause=Sequencer:CurrentClause();local value=Trim(box:GetText())
        if clause and clause.conditions and clause.conditions[Sequencer.conditionIndex] then
            clause.conditions[Sequencer.conditionIndex]=value;Sequencer:MarkDirty("Condition edited.");Sequencer:RefreshGenerated()
        end
    end)
    self.actionHint=Text(builder,"Action","GameFontHighlightSmall",nil,COLORS.muted); self.actionHint:SetPoint("TOPLEFT",678,-82); self.actionHint:SetSize(210,18)
    self.actionBox=EditBox(builder,210); self.actionBox:SetPoint("TOPLEFT",678,-104)
    self.actionBox:SetScript("OnTextChanged",function(box) if Sequencer.loading then return end; local clause=Sequencer:CurrentClause(); if clause then local action=EnsureAction(clause); action.text=box:GetText();action.savedName=box:GetText();action.spellID=nil;action.skillLine=nil;Sequencer:MarkDirty();Sequencer:RefreshGenerated() end end)
    self.spellDropdown=Dropdown(builder,210,function() return Sequencer:SpellOptions() end,function() return 0 end,function(_,option) Sequencer:SelectSpell(option,false) end); self.spellDropdown:SetPoint("TOPLEFT",662,-132)
    local refreshSpells=Button(builder,"Refresh Spells",100,function() Lib().RefreshSpellbook();Sequencer.spellDropdown:RefreshText();Sequencer:SetStatus("Live spellbook refreshed.","success") end); refreshSpells:SetPoint("TOPLEFT",774,-170)

    local previewLabel=Text(builder,"Generated current block","GameFontHighlightSmall",nil,COLORS.muted); previewLabel:SetPoint("TOPLEFT",12,-154)
    self.generatedText=Text(builder,"","ChatFontNormal",11,COLORS.text); self.generatedText:SetPoint("TOPLEFT",12,-174); self.generatedText:SetSize(630,42)
    self.characterCount=Text(builder,"0 / 255","GameFontHighlightSmall",11,COLORS.muted,"RIGHT"); self.characterCount:SetPoint("TOPRIGHT",-18,-174); self.characterCount:SetSize(230,18)

    local footer=Panel(view,0,-548,906,124)
    local modifierTitle=Text(footer,"Global Modifier Action","GameFontNormal",nil,COLORS.gold);modifierTitle:SetPoint("TOPLEFT",12,-10)
    self.modifierDropdown=Dropdown(footer,90,{{value="",label="Off"},{value="CTRL",label="Ctrl"},{value="SHIFT",label="Shift"},{value="ALT",label="Alt"}},function() local v=Sequencer:CurrentVersion();return v and (v.modifierKey or "") end,function(value) local v=Sequencer:CurrentVersion();if v then v.modifierKey=value~="" and value or nil;if v.modifierKey and not v.modifierCommand then v.modifierCommand=Lib().DefaultCommand("cast","") end;Sequencer:MarkDirty("Global Modifier Action changed.");Sequencer:RefreshEditorFields() end end);self.modifierDropdown:SetPoint("TOPLEFT",-4,-30)
    self.modifierTypeDropdown=Dropdown(footer,100,{{value="cast",label="Cast Spell"},{value="use",label="Use Item"}},function() local v=Sequencer:CurrentVersion();return v and v.modifierCommand and v.modifierCommand.kind or "cast" end,function(value) local v=Sequencer:CurrentVersion();if v then v.modifierCommand=v.modifierCommand or Lib().DefaultCommand(value,"");v.modifierCommand.kind=value;Sequencer:MarkDirty();Sequencer:RefreshEditorFields() end end);self.modifierTypeDropdown:SetPoint("TOPLEFT",106,-30)
    self.modifierActionBox=EditBox(footer,250);self.modifierActionBox:SetPoint("TOPLEFT",226,-38)
    self.modifierActionBox:SetScript("OnTextChanged",function(box) if Sequencer.loading then return end;local v=Sequencer:CurrentVersion();if v then v.modifierCommand=v.modifierCommand or Lib().DefaultCommand("cast","");local action=EnsureAction(v.modifierCommand.clauses[1]);action.text=box:GetText();action.savedName=box:GetText();action.spellID=nil;Sequencer:MarkDirty();Sequencer:RefreshGenerated() end end)
    self.modifierTargetDropdown=Dropdown(footer,110,function() return Sequencer:TargetOptions() end,function() local v=Sequencer:CurrentVersion();return v and v.modifierCommand and v.modifierCommand.clauses[1].target or "" end,function(value) local v=Sequencer:CurrentVersion();if v then v.modifierCommand=v.modifierCommand or Lib().DefaultCommand("cast","");v.modifierCommand.clauses[1].target=value;Sequencer:MarkDirty("Modifier target changed.");Sequencer:RefreshGenerated() end end);self.modifierTargetDropdown:SetPoint("TOPLEFT",474,-30)
    self.modifierSpellDropdown=Dropdown(footer,130,function() return Sequencer:SpellOptions() end,function() return 0 end,function(_,option) Sequencer:SelectSpell(option,true) end);self.modifierSpellDropdown:SetPoint("TOPLEFT",596,-30)
    local save=Button(footer,"Save Changes",110,function() Sequencer:SaveDraft() end);save:SetPoint("TOPLEFT",750,-36)
    local reset=Button(footer,"Reset Sequence",110,function() if Sequencer.draft then local ok,msg=Lib().ResetSequence(Sequencer.draft.id,"editor Reset Sequence");Sequencer:SetStatus(msg,ok and "success" or "error");Sequencer:RefreshRuntime() end end);reset:SetPoint("TOPLEFT",12,-78)
    local runtimeRefresh=Button(footer,"Refresh Runtime",110,function() Sequencer:RefreshRuntime() end);runtimeRefresh:SetPoint("TOPLEFT",126,-78)
    local discard=Button(footer,"Discard",70,function() Sequencer:DiscardDraft() end);discard:SetPoint("TOPLEFT",240,-78)
    self.runtimeText=Text(footer,"","GameFontHighlightSmall",11,COLORS.muted);self.runtimeText:SetPoint("TOPLEFT",320,-76);self.runtimeText:SetSize(568,34)
    self.statusText=Text(view,"Ready.","GameFontHighlightSmall",11,COLORS.yellow);self.statusText:SetPoint("BOTTOMLEFT",4,2);self.statusText:SetSize(896,18)
    self.editorBuilt=true
end

function Sequencer:BuildInformation(frame)
    local view=Panel(frame,18,-112,906,688,COLORS.bg,COLORS.border);self.views.information=view
    local title=Text(view,"Sequencer Information","GameFontNormalLarge",18,COLORS.gold);title:SetPoint("TOPLEFT",20,-18)
    local body=Text(view,
        "KeyLab configures the Retail-proven secure execution engine. One complete keyboard or mouse press advances exactly one outer sequence position whether WoW uses the down or up edge. The opposite edge is cleared and cannot execute or advance.\n\n" ..
        "WoW alone decides whether the attempted spell, item, equipment action, target, or condition can execute. A failed attempt still consumes its KeyLab outer position. KeyLab does not inspect cooldowns, resources, procs, auras, success, readiness, or the GCD, and it never advances from time or polling.\n\n" ..
        "Sequential visits each enabled block once. Priority expands 1; 1,2; 1,2,3. Reverse Priority expands 1; 2,1; 3,2,1. Modifier presses use the proven companion secure binding and advance normally.\n\n" ..
        "Once Until Target Changes generates /castsequence reset=target Action, nil. WoW tracks its inner Action/nil state. reset=target watches the actually selected target, not @mouseover or another temporary target. It is not aura-duration tracking.\n\n" ..
        "Blocks are limited to 255 effective characters including the Global Modifier Action budget. Advanced equipment commands are available, but only valid Main Hand and Off Hand weapon-slot changes are expected during combat; WoW enforces the final item, class, and state rules.\n\n" ..
        "Editing, saving, activating versions, changing bindings, deleting, restoring, and manual reset are unavailable during combat. Combat end, login/reload, specialization change, manual version activation, and Reset Sequence return the outer cursor to its first position.",
        "GameFontHighlightSmall",12,COLORS.text);body:SetPoint("TOPLEFT",20,-54);body:SetSize(866,338);if body.SetSpacing then body:SetSpacing(3) end
    local diagnostic=Panel(view,18,-408,870,252)
    local diagTitle=Text(diagnostic,"Development Edge Test - preserved golden prototype","GameFontNormal",nil,COLORS.gold);diagTitle:SetPoint("TOPLEFT",12,-10)
    local diagHelp=Text(diagnostic,"Use an unused diagnostic binding. Prepare loads the first three enabled blocks of the edited version into the unchanged prototype. Run exactly 10 complete presses for keyboard/down, mouse/down, keyboard/up, and mouse/up. Each pass must show Presses 10 and PASS. Restore returns WoW's original edge setting.","GameFontHighlightSmall",11,COLORS.muted);diagHelp:SetPoint("TOPLEFT",12,-34);diagHelp:SetSize(846,54)
    local capture=Button(diagnostic,"Capture Test Binding",140,function() Sequencer:StartBindingCapture("diagnostic") end);capture:SetPoint("TOPLEFT",12,-94)
    self.diagnosticBindingBox=EditBox(diagnostic,100);self.diagnosticBindingBox:SetPoint("TOPLEFT",160,-96);self.diagnosticBindingBox:SetScript("OnTextChanged",function(box) if not Sequencer.loading then Sequencer.diagnosticBinding=tostring(box:GetText() or ""):upper() end end)
    local prepare=Button(diagnostic,"Prepare Edge Test",125,function() Sequencer:PrepareEdgeTest() end);prepare:SetPoint("TOPLEFT",270,-94)
    local down=Button(diagnostic,"Key Down",80,function() Sequencer:SetEdgeMode(true) end);down:SetPoint("TOPLEFT",401,-94)
    local up=Button(diagnostic,"Key Up",70,function() Sequencer:SetEdgeMode(false) end);up:SetPoint("TOPLEFT",487,-94)
    local restore=Button(diagnostic,"Restore",70,function() Sequencer:RestoreEdgeMode() end);restore:SetPoint("TOPLEFT",563,-94)
    local refresh=Button(diagnostic,"Refresh Results",110,function() Sequencer:RefreshDiagnostic() end);refresh:SetPoint("TOPLEFT",639,-94)
    self.diagnosticResults=Text(diagnostic,"No diagnostic run prepared.","GameFontHighlightSmall",11,COLORS.muted);self.diagnosticResults:SetPoint("TOPLEFT",12,-136);self.diagnosticResults:SetSize(846,54)
    local regression=Text(diagnostic,"After the four passes, briefly recheck the modifier action and Once Until Target Changes. This diagnostic remains intentionally separate from the permanent library.","GameFontHighlightSmall",11,COLORS.yellow);regression:SetPoint("TOPLEFT",12,-200);regression:SetSize(846,38)
end

function Sequencer:RefreshRecycleBin()
    if not self.recycleRows then return end
    local entries=Lib().GetRecycleBin and Lib().GetRecycleBin() or {}
    self.recyclePage=math.max(1,self.recyclePage or 1);local perPage=8;local maxPage=math.max(1,math.ceil(#entries/perPage));self.recyclePage=math.min(self.recyclePage,maxPage)
    for rowIndex,row in ipairs(self.recycleRows) do
        local entry=entries[((self.recyclePage-1)*perPage)+rowIndex]
        row.entry=entry;row.frame:SetShown(entry~=nil)
        if entry then
            row.name:SetText((entry.type=="sequence" and "Sequence: " or "Version: ")..tostring(entry.name)..(entry.sequenceName and ("  |  from "..tostring(entry.sequenceName)) or ""))
            row.days:SetText(tostring(entry.daysRemaining).." days remaining")
        end
    end
    self.recyclePageText:SetText("Page "..tostring(self.recyclePage).." / "..tostring(maxPage).."  |  "..tostring(#entries).." items")
    self.recycleEmpty:SetShown(#entries==0)
end

function Sequencer:BuildRecycleBin(frame)
    local view=Panel(frame,18,-112,906,688,COLORS.bg,COLORS.border);self.views.recycle=view
    local title=Text(view,"Recycle Bin","GameFontNormalLarge",18,COLORS.gold);title:SetPoint("TOPLEFT",20,-18)
    local help=Text(view,"Deleted sequences and versions remain recoverable for 30 days. A restored sequence is left unbound if its old binding is now in use.","GameFontHighlightSmall",12,COLORS.muted);help:SetPoint("TOPLEFT",20,-48);help:SetSize(860,34)
    self.recycleRows={}
    for index=1,8 do
        local row=Panel(view,20,-88-((index-1)*64),866,56)
        row.name=Text(row,"","GameFontNormal",nil,COLORS.text);row.name:SetPoint("TOPLEFT",12,-9);row.name:SetSize(520,18)
        row.days=Text(row,"","GameFontHighlightSmall",11,COLORS.muted);row.days:SetPoint("TOPLEFT",12,-31)
        local restore=Button(row,"Restore",76,function() local entry=row.entry;if entry then local id,msg=Lib().RestoreDeleted(entry.id);Sequencer:SetStatus(msg,id and "success" or "error");Sequencer:RefreshRecycleBin() end end);restore:SetPoint("TOPRIGHT",-112,-16)
        local remove=Button(row,"Delete Forever",104,function() local entry=row.entry;if entry then Confirm("KEYLAB_RECYCLE_DELETE","Permanently delete "..tostring(entry.name).."? This cannot be undone.",function() local ok,msg=Lib().PermanentlyDelete(entry.id);Sequencer:SetStatus(msg,ok and "success" or "error");Sequencer:RefreshRecycleBin() end) end end);remove:SetPoint("TOPRIGHT",-4,-16)
        self.recycleRows[index]={frame=row,name=row.name,days=row.days,entry=nil}
    end
    self.recycleEmpty=Text(view,"Nothing has been deleted for this class and specialization.","GameFontHighlightSmall",13,COLORS.muted,"CENTER");self.recycleEmpty:SetPoint("TOP",0,-130);self.recycleEmpty:SetSize(860,30)
    local prev=Button(view,"Previous",80,function() Sequencer.recyclePage=math.max(1,(Sequencer.recyclePage or 1)-1);Sequencer:RefreshRecycleBin() end);prev:SetPoint("BOTTOMLEFT",20,18)
    local nextButton=Button(view,"Next",80,function() Sequencer.recyclePage=(Sequencer.recyclePage or 1)+1;Sequencer:RefreshRecycleBin() end);nextButton:SetPoint("BOTTOMLEFT",104,18)
    self.recyclePageText=Text(view,"Page 1 / 1","GameFontHighlightSmall",11,COLORS.muted);self.recyclePageText:SetPoint("BOTTOMLEFT",198,23)
    self.recycleStatus=Text(view,"","GameFontHighlightSmall",11,COLORS.yellow);self.recycleStatus:SetPoint("BOTTOMLEFT",390,23);self.recycleStatus:SetSize(490,18)
end

function Sequencer:Refresh()
    if not self.draft and not self.dirty then self:LoadSequence(self.selectedSequenceId) else self:RefreshEditorFields() end
    if self.selectedView=="recycle" then self:RefreshRecycleBin() elseif self.selectedView=="information" then self:RefreshDiagnostic() end
end

function Sequencer:Create(parent)
    local frame=CreateFrame("Frame","KeyLabSequencerTab",parent,"BackdropTemplate");frame:SetAllPoints(parent)
    if Theme.StylePanel then Theme.StylePanel(frame,COLORS.bg,{0,0,0,0}) end
    self.frame=frame;self.views={};self.selectedView="editor";self.diagnosticBinding=self.diagnosticBinding or ""
    local title=Text(frame,"Sequencer","GameFontNormalLarge",20,COLORS.gold);title:SetPoint("TOPLEFT",18,-18);title:SetSize(900,22)
    local description=Text(frame,"Configure the proven secure press-by-press engine with class/spec sequences, named versions, live spells, bindings, and recoverable deletion.","GameFontHighlightSmall",nil,COLORS.muted);description:SetPoint("TOPLEFT",18,-45);description:SetSize(900,18)
    self:BuildTop(frame);self:BuildEditor(frame);self:BuildInformation(frame);self:BuildRecycleBin(frame)
    self:LoadSequence(nil);self:SetView("editor")
    frame.Refresh=function() Sequencer:Refresh() end
    frame:SetScript("OnShow",function() Sequencer:Refresh() end)
    frame:SetScript("OnHide",function() if Sequencer.captureOverlay then Sequencer.captureOverlay:EnableKeyboard(false);Sequencer.captureOverlay:Hide() end end)
    return frame
end

if KeyLab.RegisterTab then KeyLab.RegisterTab("Sequencer",function(parent) return Sequencer:Create(parent) end) end

return Sequencer
