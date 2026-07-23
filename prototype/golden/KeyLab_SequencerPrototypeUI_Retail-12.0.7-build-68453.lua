local ADDON_NAME, KeyLab = ...

KeyLab = KeyLab or {}
_G.KeyLab = KeyLab
KeyLab.Tabs = KeyLab.Tabs or {}

local Sequencer = {}
KeyLab.Tabs.Sequencer = Sequencer

local Theme = KeyLab.UI and KeyLab.UI.Theme or {}
local COLORS = Theme.colors or {
    bg = {0.018, 0.026, 0.056, 0.98}, panel = {0.026, 0.046, 0.086, 0.84},
    border = {0.240, 0.380, 0.620, 0.62}, gold = {0.820, 0.760, 0.580, 1},
    text = {0.940, 0.960, 0.990, 1}, muted = {0.680, 0.730, 0.820, 1},
    blue = {0.500, 0.680, 0.940, 1}, green = {0.460, 0.780, 0.500, 1},
    red = {0.840, 0.440, 0.420, 1}, yellow = {0.840, 0.720, 0.420, 1},
}
local HEADER = Theme.tabHeader or { titleSize = 16 }
local ACTION_TYPES = {
    cast = "Cast Spell",
    use = "Use Item",
    actionnil = "Once Until Target Changes",
}
local MODE_LABELS = {
    sequential = "Sequential",
    priority = "Priority",
    reverse = "Reverse Priority",
}
local MODIFIER_LABELS = { OFF = "Off", CTRL = "Ctrl", SHIFT = "Shift", ALT = "Alt" }

local function Color(region, color)
    if Theme.ApplyColor then Theme.ApplyColor(region, color) elseif region and region.SetTextColor then region:SetTextColor(unpack(color)) end
end

local function Panel(parent, x, y, width, height, bg, border)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(width, height)
    if Theme.StylePanel then
        Theme.StylePanel(frame, bg or COLORS.panel, border or COLORS.border)
    else
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        frame:SetBackdropColor(unpack(bg or COLORS.panel))
        frame:SetBackdropBorderColor(unpack(border or COLORS.border))
    end
    return frame
end

local function Text(parent, value, template, size, color, justify)
    local fs
    if Theme.CreateText then
        fs = Theme.CreateText(parent, value, template or "GameFontNormal", size, color or COLORS.text, justify or "LEFT")
    else
        fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
        if size then fs:SetFont(STANDARD_TEXT_FONT, size, "") end
        fs:SetText(value or "")
        fs:SetTextColor(unpack(color or COLORS.text))
        fs:SetJustifyH(justify or "LEFT")
    end
    return fs
end

local function Button(parent, label, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 120, 28)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

local function EditBox(parent, width)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width or 240, 26)
    box:SetAutoFocus(false)
    box:SetTextInsets(6, 6, 0, 0)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return box
end

local function Dropdown(parent, width, options, getValue, setValue)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, width or 150)
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        for _, option in ipairs(options) do
            local optionValue = option.value
            local optionLabel = option.label
            local info = UIDropDownMenu_CreateInfo()
            info.text = optionLabel
            info.checked = getValue() == optionValue
            info.func = function()
                setValue(optionValue)
                UIDropDownMenu_SetText(dropdown, optionLabel)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    dropdown.RefreshText = function()
        local current = getValue()
        for _, option in ipairs(options) do
            if option.value == current then UIDropDownMenu_SetText(dropdown, option.label); return end
        end
        UIDropDownMenu_SetText(dropdown, options[1] and options[1].label or "")
    end
    dropdown:RefreshText()
    return dropdown
end

local function Trim(value)
    value = tostring(value or "")
    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function Prototype()
    return KeyLab.SequencerPrototype or {}
end

local function Print(message)
    if KeyLab.Print then KeyLab.Print("Sequencer: " .. tostring(message)) else print("KeyLab Sequencer: " .. tostring(message)) end
end

local function ParseBlock(text)
    text = Trim(text)
    if text == "" then return { actionType = "cast", action = "" } end
    local action = text:match("^/castsequence%s+reset=target%s+(.+),%s*nil%s*$" )
    if action then return { actionType = "actionnil", action = Trim(action) } end
    action = text:match("^/cast%s+(.+)$")
    if action then return { actionType = "cast", action = Trim(action) } end
    action = text:match("^/use%s+(.+)$")
    if action then return { actionType = "use", action = Trim(action) } end
    return { actionType = "cast", action = "", unsupportedText = text }
end

local function BuildBlock(block)
    block = type(block) == "table" and block or {}
    local action = Trim(block.action)
    if action == "" then return "" end
    if block.actionType == "use" then return "/use " .. action end
    if block.actionType == "actionnil" then return "/castsequence reset=target " .. action .. ", nil" end
    return "/cast " .. action
end

local function BuildModifier(draft)
    local modifier = tostring(draft.modifierKey or "OFF"):upper()
    local action = Trim(draft.modifierAction)
    if modifier == "OFF" or action == "" then return "" end
    if draft.modifierType == "use" then return "/use " .. action end
    return "/cast " .. action
end

local function LoopText(mode, count)
    local loop = {}
    if mode == "priority" then
        for depth = 1, count do for index = 1, depth do table.insert(loop, index) end end
    elseif mode == "reverse" then
        for depth = 1, count do for index = depth, 1, -1 do table.insert(loop, index) end end
    else
        for index = 1, count do table.insert(loop, index) end
    end
    local result = {}
    for _, value in ipairs(loop) do table.insert(result, tostring(value)) end
    return #result > 0 and table.concat(result, "  >  ") or "Add at least one action."
end

function Sequencer:LoadDraft()
    local state = Prototype().GetEditorState and Prototype().GetEditorState() or {}
    self.draft = {
        activeVersion = state.activeVersion or "A",
        mode = state.mode or "sequential",
        binding = state.binding or "",
        forceBinding = false,
        modifierKey = state.modifierKey or "OFF",
        modifierType = tostring(state.modifierAction or ""):match("^/use%s+") and "use" or "cast",
        modifierAction = Trim(tostring(state.modifierAction or ""):gsub("^/%S+%s*", "")),
        blocks = {},
    }
    for index = 1, 3 do self.draft.blocks[index] = ParseBlock(state.blocks and state.blocks[index]) end
    self.loadedState = state
end

function Sequencer:BuildState()
    local blocks = {}
    for index = 1, 3 do blocks[index] = BuildBlock(self.draft.blocks[index]) end
    return {
        mode = self.draft.mode,
        blocks = blocks,
        binding = Trim(self.draft.binding):upper(),
        forceBinding = self.draft.forceBinding == true,
        modifierKey = self.draft.modifierKey ~= "OFF" and self.draft.modifierKey or nil,
        modifierAction = BuildModifier(self.draft),
    }
end

function Sequencer:SetStatus(message, kind)
    message = tostring(message or "")
    self.statusMessage = message
    if self.statusText then
        self.statusText:SetText(message)
        Color(self.statusText, kind == "error" and COLORS.red or kind == "success" and COLORS.green or COLORS.yellow)
    end
end

function Sequencer:RefreshGenerated()
    if not self.draft then return end
    local modifierText = BuildModifier(self.draft)
    local count = 0
    for index, row in ipairs(self.blockRows or {}) do
        local generated = BuildBlock(self.draft.blocks[index])
        if generated ~= "" then count = count + 1 end
        local effective = Prototype().GetEffectiveLength and Prototype().GetEffectiveLength(generated, modifierText) or #generated
        local previewText = generated ~= "" and generated or "No action configured"
        if generated ~= "" and modifierText ~= "" then
            previewText = previewText .. "  +  " .. tostring(self.draft.modifierKey):gsub("^%l", string.upper) .. " global action"
        end
        row.preview:SetText(previewText)
        row.count:SetText(tostring(effective) .. " / 255")
        Color(row.count, effective > 255 and COLORS.red or effective > 220 and COLORS.yellow or COLORS.muted)
    end
    if self.loopPreview then self.loopPreview:SetText("One full loop:  " .. LoopText(self.draft.mode, count)) end
    if self.versionDropdown then self.versionDropdown:RefreshText() end
    if self.modeDropdown then self.modeDropdown:RefreshText() end
    if self.modifierDropdown then self.modifierDropdown:RefreshText() end
    if self.modifierTypeDropdown then self.modifierTypeDropdown:RefreshText() end
end

function Sequencer:RefreshRuntime()
    if not self.runtimeText then return end
    local state = Prototype().GetEditorState and Prototype().GetEditorState() or {}
    local runtime = state.runtime or {}
    local versionText, buildText = "unknown", "unknown"
    if GetBuildInfo then versionText, buildText = GetBuildInfo() end
    local useOnKeyDown = runtime.useOnKeyDown == true
    local executedDown = tonumber(runtime.executedDownEvents) or 0
    local executedUp = tonumber(runtime.executedUpEvents) or 0
    local advances = tonumber(runtime.pressCount) or 0
    local oneEdgePassed = advances > 0
        and (executedDown + executedUp) == advances
        and ((useOnKeyDown and executedUp == 0) or ((not useOnKeyDown) and executedDown == 0))
    local edgeVerdict = advances > 0 and (oneEdgePassed and "PASS" or "CHECK") or "Awaiting presses"
    self.runtimeText:SetText(
        "Retail " .. tostring(versionText) .. "  •  Build " .. tostring(buildText) .. "  •  Applied Version " .. tostring(runtime.appliedVersion or "Not yet") ..
        "  •  Binding " .. tostring(runtime.appliedBinding or "Not yet") ..
        "  •  Modifier " .. tostring(runtime.appliedModifierKey or "Off") .. "\n" ..
        "Presses: " .. tostring(runtime.pressCount or 0) .. "  •  In Combat: " .. tostring(runtime.combatPresses or 0) .. "  •  Modifier: " .. tostring(runtime.modifierPresses or 0) ..
        "  •  Last Block: " .. tostring(runtime.lastBlock or "—") .. "  •  Next Block: " .. tostring(runtime.nextBlock or "—") .. "\n" ..
        "Edge mode: " .. (useOnKeyDown and "Key Down" or "Key Up") ..
        "  •  Down executed/events: " .. tostring(executedDown) .. "/" .. tostring(runtime.downEvents or 0) ..
        "  •  Up executed/events: " .. tostring(executedUp) .. "/" .. tostring(runtime.upEvents or 0) ..
        "  •  Ignored: " .. tostring(runtime.ignoredEdgeEvents or 0) .. "  •  One-edge filter: " .. edgeVerdict .. "\n" ..
        "Last reset: " .. tostring(runtime.lastResetReason or "Not recorded") .. "  •  For 10 physical presses, Presses must equal 10."
    )
end

function Sequencer:SetEdgeTestMode(useOnKeyDown)
    local api = Prototype()
    if not api.SetEdgeTestMode then self:SetStatus("The secure edge-test control is unavailable.", "error"); return end
    local ok, message = api.SetEdgeTestMode(useOnKeyDown)
    self:SetStatus(message or (ok and "Edge test applied." or "The edge test could not be applied."), ok and "success" or "error")
    self:RefreshRuntime()
end

function Sequencer:RestoreEdgeTestMode()
    local api = Prototype()
    if not api.RestoreEdgeTestMode then self:SetStatus("The secure edge-test control is unavailable.", "error"); return end
    local ok, message = api.RestoreEdgeTestMode()
    self:SetStatus(message or (ok and "WoW key-edge setting restored." or "The earlier setting could not be restored."), ok and "success" or "error")
    self:RefreshRuntime()
end

function Sequencer:RefreshEditorFields()
    self.loading = true
    if self.bindingBox then self.bindingBox:SetText(self.draft.binding or "") end
    for index, row in ipairs(self.blockRows or {}) do
        row.actionBox:SetText(self.draft.blocks[index].action or "")
        row.typeDropdown:RefreshText()
    end
    if self.modifierActionBox then self.modifierActionBox:SetText(self.draft.modifierAction or "") end
    self.loading = false
    self:RefreshGenerated()
    self:RefreshRuntime()
end

function Sequencer:ApplyEditor()
    if InCombatLockdown and InCombatLockdown() then self:SetStatus("Sequencer editing is unavailable during combat.", "error"); return end
    local api = Prototype()
    if not api.ApplyEditorState then self:SetStatus("The secure prototype is unavailable.", "error"); return end
    local ok, message = api.ApplyEditorState(self:BuildState())
    self:SetStatus(message or (ok and "Secure test applied." or "The secure test could not be applied."), ok and "success" or "error")
    if ok then self:LoadDraft(); self:RefreshEditorFields() else self:RefreshRuntime() end
end

function Sequencer:ChangeVersion(value)
    if InCombatLockdown and InCombatLockdown() then self:SetStatus("Versions cannot be changed during combat.", "error"); return end
    local api = Prototype()
    if not api.SaveEditorState or not api.ActivateVersion then self:SetStatus("The secure prototype is unavailable.", "error"); return end
    local saved, saveMessage = api.SaveEditorState(self:BuildState())
    if not saved then self:SetStatus(saveMessage or "Finish the current setup before changing versions.", "error"); return end
    local ok, message = api.ActivateVersion(value)
    self:SetStatus(message or (ok and "Version changed." or "Version could not be changed."), ok and "success" or "error")
    self:LoadDraft()
    self:RefreshEditorFields()
end

function Sequencer:StopBindingCapture()
    if self.captureOverlay then
        self.captureOverlay:EnableKeyboard(false)
        self.captureOverlay:Hide()
    end
end

function Sequencer:SetCapturedBinding(binding)
    self:StopBindingCapture()
    if not binding or binding == "" then self:SetStatus("Binding capture cancelled."); return end
    self.draft.binding = binding
    self.bindingBox:SetText(binding)
    self:SetStatus("Binding captured: " .. binding .. ". Choose Apply Secure Test when ready.", "success")
end

function Sequencer:StartBindingCapture()
    if InCombatLockdown and InCombatLockdown() then self:SetStatus("Bindings cannot be changed during combat.", "error"); return end
    local overlay = self.captureOverlay
    if not overlay then
        overlay = CreateFrame("Button", "KeyLabSequencerBindingCapture", UIParent, "BackdropTemplate")
        overlay:SetAllPoints(UIParent)
        overlay:SetFrameStrata("TOOLTIP")
        overlay:EnableMouse(true)
        overlay:EnableKeyboard(true)
        if overlay.SetPropagateKeyboardInput then overlay:SetPropagateKeyboardInput(false) end
        overlay:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        overlay:SetBackdropColor(0.01, 0.02, 0.05, 0.88)
        local prompt = Text(overlay, "Press a keyboard key or mouse button\n\nEscape cancels", "GameFontNormalLarge", 20, COLORS.gold, "CENTER")
        prompt:SetPoint("CENTER")
        prompt:SetSize(520, 100)
        overlay:SetScript("OnKeyDown", function(_, key)
            if key == "ESCAPE" then Sequencer:SetCapturedBinding(nil); return end
            if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then return end
            local parts = {}
            if IsControlKeyDown and IsControlKeyDown() then table.insert(parts, "CTRL") end
            if IsShiftKeyDown and IsShiftKeyDown() then table.insert(parts, "SHIFT") end
            if IsAltKeyDown and IsAltKeyDown() then table.insert(parts, "ALT") end
            table.insert(parts, tostring(key):upper())
            Sequencer:SetCapturedBinding(table.concat(parts, "-"))
        end)
        overlay:SetScript("OnMouseDown", function(_, button)
            local map = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }
            if map[button] then Sequencer:SetCapturedBinding(map[button]) end
        end)
        self.captureOverlay = overlay
    end
    overlay:Show()
    overlay:EnableKeyboard(true)
end

function Sequencer:BuildViewTabs(frame)
    self.viewButtons = {}
    for index, definition in ipairs({
        { key = "editor", label = "Editor" },
        { key = "information", label = "Information" },
        { key = "recycle", label = "Recycle Bin" },
    }) do
        local viewKey = definition.key
        local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 18 + ((index - 1) * 150), -72)
        button:SetSize(138, 30)
        if Theme.StylePanel then Theme.StylePanel(button, COLORS.panel, COLORS.border) end
        button.label = Text(button, definition.label, "GameFontNormal", nil, COLORS.text, "CENTER")
        button.label:SetAllPoints(button)
        button.label:SetJustifyV("MIDDLE")
        button:SetScript("OnClick", function() Sequencer:SetView(viewKey) end)
        self.viewButtons[viewKey] = button
    end
end

function Sequencer:SetView(view)
    self.selectedView = view or "editor"
    for key, panel in pairs(self.views or {}) do panel:SetShown(key == self.selectedView) end
    for key, button in pairs(self.viewButtons or {}) do
        local active = key == self.selectedView
        if button.SetBackdropBorderColor then button:SetBackdropBorderColor(unpack(active and COLORS.gold or COLORS.border)) end
        Color(button.label, active and COLORS.gold or COLORS.text)
    end
    if self.selectedView == "editor" then self:Refresh() end
end

function Sequencer:BuildEditor(frame)
    local view = CreateFrame("Frame", nil, frame)
    view:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -116)
    view:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 16)
    self.views.editor = view

    local setup = Panel(view, 0, 0, 906, 106)
    local setupTitle = Text(setup, "Secure Test Setup", "GameFontNormal", nil, COLORS.gold)
    setupTitle:SetPoint("TOPLEFT", 14, -10)
    local edgeLabel = Text(setup, "Edge Test:", "GameFontHighlightSmall", nil, COLORS.muted)
    edgeLabel:SetPoint("TOPLEFT", 562, -14)
    local keyDownTest = Button(setup, "Key Down", 72, function() Sequencer:SetEdgeTestMode(true) end)
    keyDownTest:SetSize(72, 24)
    keyDownTest:SetPoint("TOPLEFT", 628, -7)
    local keyUpTest = Button(setup, "Key Up", 72, function() Sequencer:SetEdgeTestMode(false) end)
    keyUpTest:SetSize(72, 24)
    keyUpTest:SetPoint("TOPLEFT", 706, -7)
    local restoreEdge = Button(setup, "Restore", 96, function() Sequencer:RestoreEdgeTestMode() end)
    restoreEdge:SetSize(96, 24)
    restoreEdge:SetPoint("TOPLEFT", 784, -7)

    local versionLabel = Text(setup, "Version", "GameFontHighlightSmall", nil, COLORS.muted)
    versionLabel:SetPoint("TOPLEFT", 14, -34)
    self.versionDropdown = Dropdown(setup, 120, {
        { value = "A", label = "Version A" }, { value = "B", label = "Version B" },
    }, function() return Sequencer.draft.activeVersion end, function(value) Sequencer:ChangeVersion(value) end)
    self.versionDropdown:SetPoint("TOPLEFT", setup, "TOPLEFT", 0, -48)

    local modeLabel = Text(setup, "Sequence Mode", "GameFontHighlightSmall", nil, COLORS.muted)
    modeLabel:SetPoint("TOPLEFT", 190, -34)
    self.modeDropdown = Dropdown(setup, 160, {
        { value = "sequential", label = "Sequential" }, { value = "priority", label = "Priority" }, { value = "reverse", label = "Reverse Priority" },
    }, function() return Sequencer.draft.mode end, function(value) Sequencer.draft.mode = value; Sequencer:RefreshGenerated() end)
    self.modeDropdown:SetPoint("TOPLEFT", setup, "TOPLEFT", 176, -48)

    local bindingLabel = Text(setup, "Assigned Binding", "GameFontHighlightSmall", nil, COLORS.muted)
    bindingLabel:SetPoint("TOPLEFT", 420, -34)
    self.bindingBox = EditBox(setup, 170)
    self.bindingBox:SetPoint("TOPLEFT", 420, -58)
    self.bindingBox:SetScript("OnTextChanged", function(box)
        if Sequencer.loading then return end
        Sequencer.draft.binding = tostring(box:GetText() or ""):upper()
    end)
    local capture = Button(setup, "Capture Binding", 150, function() Sequencer:StartBindingCapture() end)
    capture:SetPoint("TOPLEFT", 610, -56)
    local clear = Button(setup, "Clear Binding", 120, function()
        local ok = Prototype().Unbind and Prototype().Unbind()
        if ok then Sequencer.draft.binding = ""; Sequencer.bindingBox:SetText(""); Sequencer:SetStatus("Prototype binding cleared.", "success") end
    end)
    clear:SetPoint("TOPLEFT", 770, -56)

    local actions = Panel(view, 0, -120, 906, 304)
    local actionTitle = Text(actions, "Action Blocks", "GameFontNormal", nil, COLORS.gold)
    actionTitle:SetPoint("TOPLEFT", 14, -10)
    local actionHelp = Text(actions, "Choose one action type and enter one spell or item for each block. Leave unused blocks empty.", "GameFontHighlightSmall", nil, COLORS.muted)
    actionHelp:SetPoint("TOPLEFT", 160, -11)
    actionHelp:SetSize(710, 18)

    self.blockRows = {}
    for index = 1, 3 do
        local blockIndex = index
        local row = Panel(actions, 14, -38 - ((blockIndex - 1) * 84), 878, 74, COLORS.bg, COLORS.border)
        local number = Text(row, "Block " .. blockIndex, "GameFontNormal", nil, COLORS.gold)
        number:SetPoint("TOPLEFT", 12, -10)
        local typeDropdown = Dropdown(row, 190, {
            { value = "cast", label = "Cast Spell" }, { value = "use", label = "Use Item" }, { value = "actionnil", label = "Once Until Target Changes" },
        }, function() return Sequencer.draft.blocks[blockIndex].actionType end, function(value) Sequencer.draft.blocks[blockIndex].actionType = value; Sequencer:RefreshGenerated() end)
        typeDropdown:SetPoint("TOPLEFT", row, "TOPLEFT", 82, -2)
        local actionLabel = Text(row, "Action:", "GameFontHighlightSmall", nil, COLORS.muted)
        actionLabel:SetPoint("TOPLEFT", 366, -15)
        local actionBox = EditBox(row, 356)
        actionBox:SetPoint("TOPLEFT", 420, -8)
        actionBox:SetScript("OnTextChanged", function(box)
            if Sequencer.loading then return end
            Sequencer.draft.blocks[blockIndex].action = box:GetText() or ""
            Sequencer:RefreshGenerated()
        end)
        local count = Text(row, "0 / 255", "GameFontHighlightSmall", nil, COLORS.muted, "RIGHT")
        count:SetPoint("TOPRIGHT", -12, -13)
        count:SetSize(80, 16)
        local preview = Text(row, "No action configured", "GameFontDisableSmall", 11, COLORS.muted)
        preview:SetPoint("TOPLEFT", 96, -47)
        preview:SetSize(750, 16)
        self.blockRows[blockIndex] = { frame = row, typeDropdown = typeDropdown, actionBox = actionBox, count = count, preview = preview }
    end

    local modifier = Panel(view, 0, -438, 906, 94)
    local modifierTitle = Text(modifier, "Global Modifier Action", "GameFontNormal", nil, COLORS.gold)
    modifierTitle:SetPoint("TOPLEFT", 14, -10)
    local modifierHelp = Text(modifier, "Optional. One Ctrl, Shift, or Alt action is available from every block and still advances the sequence.", "GameFontHighlightSmall", nil, COLORS.muted)
    modifierHelp:SetPoint("TOPLEFT", 190, -11)
    modifierHelp:SetSize(690, 18)
    self.modifierDropdown = Dropdown(modifier, 110, {
        { value = "OFF", label = "Off" }, { value = "CTRL", label = "Ctrl" }, { value = "SHIFT", label = "Shift" }, { value = "ALT", label = "Alt" },
    }, function() return Sequencer.draft.modifierKey end, function(value) Sequencer.draft.modifierKey = value; Sequencer:RefreshGenerated() end)
    self.modifierDropdown:SetPoint("TOPLEFT", modifier, "TOPLEFT", 0, -43)
    self.modifierTypeDropdown = Dropdown(modifier, 130, {
        { value = "cast", label = "Cast Spell" }, { value = "use", label = "Use Item" },
    }, function() return Sequencer.draft.modifierType end, function(value) Sequencer.draft.modifierType = value; Sequencer:RefreshGenerated() end)
    self.modifierTypeDropdown:SetPoint("TOPLEFT", modifier, "TOPLEFT", 150, -43)
    local modifierActionLabel = Text(modifier, "Action:", "GameFontHighlightSmall", nil, COLORS.muted)
    modifierActionLabel:SetPoint("TOPLEFT", 316, -56)
    self.modifierActionBox = EditBox(modifier, 470)
    self.modifierActionBox:SetPoint("TOPLEFT", 370, -49)
    self.modifierActionBox:SetScript("OnTextChanged", function(box)
        if Sequencer.loading then return end
        Sequencer.draft.modifierAction = box:GetText() or ""
        Sequencer:RefreshGenerated()
    end)

    self.loopPreview = Text(view, "One full loop:", "GameFontHighlightSmall", nil, COLORS.blue)
    self.loopPreview:SetPoint("TOPLEFT", 10, -548)
    self.loopPreview:SetSize(880, 18)

    local apply = Button(view, "Apply Secure Test", 180, function() Sequencer:ApplyEditor() end)
    apply:SetPoint("TOPLEFT", 0, -570)
    local reset = Button(view, "Reset Sequence", 150, function()
        local ok = Prototype().Reset and Prototype().Reset("editor Reset Sequence")
        Sequencer:SetStatus(ok and "Sequence returned to Block 1." or Prototype().GetLastMessage(), ok and "success" or "error")
        Sequencer:RefreshRuntime()
    end)
    reset:SetPoint("TOPLEFT", 192, -570)
    local refresh = Button(view, "Refresh Test Results", 170, function() Sequencer:RefreshRuntime(); Sequencer:SetStatus("Test results refreshed.") end)
    refresh:SetPoint("TOPLEFT", 354, -570)

    self.statusText = Text(view, "Choose your actions and binding, then select Apply Secure Test.", "GameFontHighlightSmall", nil, COLORS.yellow)
    self.statusText:SetPoint("TOPLEFT", 544, -571)
    self.statusText:SetSize(352, 34)

    local runtime = Panel(view, 0, -610, 906, 78)
    local runtimeTitle = Text(runtime, "Secure Test Results", "GameFontNormal", nil, COLORS.gold)
    runtimeTitle:SetPoint("TOPLEFT", 14, -9)
    self.runtimeText = Text(runtime, "No secure test has been applied yet.", "GameFontHighlightSmall", nil, COLORS.text)
    self.runtimeText:SetPoint("TOPLEFT", 170, -9)
    self.runtimeText:SetSize(720, 66)
end

function Sequencer:BuildInformation(frame)
    local view = Panel(frame, 18, -116, 906, 684, COLORS.bg, COLORS.border)
    self.views.information = view
    local title = Text(view, "Testing the Secure Sequencer", "GameFontNormalLarge", 18, COLORS.gold)
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetSize(850, 24)
    local body = Text(view,
        "This editor is the safe Retail prototype. It uses one physical key or mouse press for every attempted action. KeyLab advances the outer block on every press, even when WoW cannot perform that spell or item.\n\n" ..
        "HOW TO TEST\n" ..
        "1. In Editor, choose a spell or item for Block 1. Add Blocks 2 and 3 if wanted.\n" ..
        "2. Choose Sequential, Priority, or Reverse Priority. The full press order is shown below the blocks.\n" ..
        "3. Select Capture Binding and press an unused keyboard key or Button 3, 4, or 5.\n" ..
        "4. Select Apply Secure Test, then use that binding at a training dummy.\n" ..
        "5. Leave combat and return here. Secure Test Results shows total presses, combat presses, modifier presses, and the next block.\n\n" ..
        "ONCE UNTIL TARGET CHANGES\n" ..
        "This generates the approved Action, nil form. WoW remembers the action for the selected target and resets its internal castsequence when the selected target changes. This is separate from KeyLab's outer block order.\n\n" ..
        "CURRENT PROTOTYPE LIMITS\n" ..
        "The prototype has three blocks and two test versions. Selected-target changes do not reset KeyLab's outer loop. Editing, applying, resetting, and changing bindings are unavailable during combat. Options still marked Needs Test in the workbook remain hidden. The complete sequence library, named versions, larger block lists, and recycle-bin recovery come after the secure execution behavior passes Retail testing.\n\n" ..
        "KEY DOWN / KEY UP EDGE TEST\n" ..
        "The Editor's Key Down and Key Up buttons temporarily change WoW's ActionButtonUseKeyDown setting and reapply the secure test with fresh counters. Press the assigned binding exactly 10 complete times, then refresh the results. Presses must equal 10, only the selected edge may show as executed, and One-edge filter must say PASS. Select Restore afterward to return WoW to the setting it had before the test.",
        "GameFontHighlightSmall", 13, COLORS.text)
    body:SetPoint("TOPLEFT", 20, -58)
    body:SetSize(852, 590)
    if body.SetSpacing then body:SetSpacing(3) end
end

function Sequencer:BuildRecycleBin(frame)
    local view = Panel(frame, 18, -116, 906, 684, COLORS.bg, COLORS.border)
    self.views.recycle = view
    local title = Text(view, "Recycle Bin", "GameFontNormalLarge", 18, COLORS.gold)
    title:SetPoint("TOPLEFT", 20, -18)
    local body = Text(view,
        "Nothing has been deleted.\n\nThe secure prototype does not create permanent sequence-library entries yet. The complete editor will keep deleted sequences and versions here for 30 days, with Restore and Permanently Delete controls.",
        "GameFontHighlightSmall", 13, COLORS.muted)
    body:SetPoint("TOPLEFT", 20, -62)
    body:SetSize(850, 120)
end

function Sequencer:Refresh()
    if not self.draft then self:LoadDraft() end
    if self.selectedView == "editor" or not self.selectedView then
        if self.preserveDraft then
            self.preserveDraft = false
        else
            self:LoadDraft()
        end
        self:RefreshEditorFields()
    end
end

function Sequencer:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabSequencerTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    if Theme.StylePanel then Theme.StylePanel(frame, COLORS.bg, {0, 0, 0, 0}) end
    self.frame = frame
    self.views = {}
    self:LoadDraft()

    local title = Text(frame, "Sequencer", "GameFontNormalLarge", HEADER.titleSize, COLORS.gold)
    title:SetPoint("TOPLEFT", 18, -18)
    title:SetSize(900, 20)
    local description = Text(frame, "Build and test press-by-press spell or item sequences through KeyLab's protected Retail execution prototype.", "GameFontHighlightSmall", nil, COLORS.muted)
    description:SetPoint("TOPLEFT", 18, -43)
    description:SetSize(890, 16)

    self:BuildViewTabs(frame)
    self:BuildEditor(frame)
    self:BuildInformation(frame)
    self:BuildRecycleBin(frame)
    self:SetView("editor")

    frame.Refresh = function() Sequencer:Refresh() end
    frame:SetScript("OnShow", function() Sequencer:Refresh() end)
    frame:SetScript("OnHide", function()
        Sequencer:StopBindingCapture()
        if Sequencer.draft then Sequencer.preserveDraft = true end
    end)
    return frame
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Sequencer", function(parent) return Sequencer:Create(parent) end)
end

return Sequencer
