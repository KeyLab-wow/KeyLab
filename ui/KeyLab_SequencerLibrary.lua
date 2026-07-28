local _, KeyLab = ...

KeyLab = KeyLab or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local Sequencer = {}
KeyLab.Tabs.Sequencer = Sequencer

local Theme = (KeyLab.UI and KeyLab.UI.Theme) or KeyLab.UITheme or {}
local COLORS = Theme.colors or {
    bg={0.018,0.026,0.056,0.98}, panel={0.026,0.046,0.086,0.92}, card={0.030,0.052,0.098,0.88},
    border={0.240,0.380,0.620,0.62}, softBorder={0.185,0.300,0.500,0.50}, gold={0.820,0.760,0.580,1},
    text={0.940,0.960,0.990,1}, muted={0.680,0.730,0.820,1}, green={0.460,0.780,0.500,1},
    yellow={0.840,0.720,0.420,1}, red={0.840,0.440,0.420,1}, buttonBg={0.022,0.038,0.076,0.90},
    buttonBorder={0.220,0.340,0.560,0.58}, buttonHover={0.300,0.420,0.600,0.78},
}

local function Lib() return KeyLab.SequencerLibrary or {} end
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
        frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        frame:SetBackdropColor(unpack(bg or COLORS.panel)); frame:SetBackdropBorderColor(unpack(border or COLORS.border))
    end
    return frame
end
local function FullViewPanel(parent)
    local frame=Panel(parent,18,-112,906,688,COLORS.bg,COLORS.border)
    frame:ClearAllPoints(); frame:SetPoint("TOPLEFT",parent,"TOPLEFT",18,-112); frame:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-18,16)
    return frame
end
local function Text(parent, value, template, size, color, justify)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    label:SetText(value or "")
    if size then local path=label:GetFont(); if path then label:SetFont(path,size,"") end end
    Color(label, color or COLORS.text)
    label:SetJustifyH(justify or "LEFT"); label:SetJustifyV("TOP"); label:SetWordWrap(true)
    return label
end
local function Style(frame, bg, border)
    if Theme.StylePanel then Theme.StylePanel(frame,bg or COLORS.buttonBg,border or COLORS.buttonBorder)
    else
        frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        frame:SetBackdropColor(unpack(bg or COLORS.buttonBg)); frame:SetBackdropBorderColor(unpack(border or COLORS.buttonBorder))
    end
end
local BUTTON_HOVER_BG=COLORS.buttonSelectedBg or {0.040,0.068,0.120,0.96}
local function ApplyButtonRestingStyle(button)
    if not button then return end
    if button.SetBackdropColor then button:SetBackdropColor(unpack(button.defaultBg or COLORS.buttonBg)) end
    if button.SetBackdropBorderColor then button:SetBackdropBorderColor(unpack(button.defaultBorder or COLORS.buttonBorder or COLORS.border)) end
    Color(button.label,button.defaultText or COLORS.text)
end
local function ApplyButtonHoverStyle(button)
    if not button then return end
    if button.SetBackdropColor then button:SetBackdropColor(unpack(BUTTON_HOVER_BG)) end
    if button.SetBackdropBorderColor then button:SetBackdropBorderColor(unpack(COLORS.gold)) end
    Color(button.label,COLORS.gold)
end
local function Button(parent, label, width, onClick, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 90, height or 24); Style(button)
    button.defaultBorder=COLORS.buttonBorder or COLORS.border
    button.defaultBg=COLORS.buttonBg
    button.defaultText=COLORS.text
    button.label = Text(button,label,"GameFontHighlightSmall",nil,COLORS.text,"CENTER")
    button.label:SetAllPoints(); button.label:SetJustifyV("MIDDLE")
    button:SetScript("OnClick",onClick)
    button:SetScript("OnEnter",ApplyButtonHoverStyle)
    button:SetScript("OnLeave",ApplyButtonRestingStyle)
    return button
end
local function ButtonAccent(button,border,textColor)
    if not button then return end
    button.defaultBorder=border or COLORS.buttonBorder or COLORS.border
    button.defaultText=textColor or COLORS.text
    ApplyButtonRestingStyle(button)
end
local function EditBox(parent, width)
    local box=CreateFrame("EditBox",nil,parent,"BackdropTemplate")
    box:SetSize(width or 180,24); box:SetAutoFocus(false); box:SetFontObject("GameFontHighlightSmall"); box:SetTextInsets(7,7,2,2)
    Style(box,COLORS.controlBg or COLORS.buttonBg,COLORS.softBorder or COLORS.border)
    box:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    return box
end
local activeDropdown
local function Dropdown(parent,width,optionsProvider,getValue,setValue)
    width=width or 150
    local dropdown=CreateFrame("Button",nil,parent,"BackdropTemplate")
    dropdown:SetSize(width,24); Style(dropdown,COLORS.controlBg or COLORS.buttonBg,COLORS.softBorder or COLORS.border)
    dropdown.defaultBg=COLORS.controlBg or COLORS.buttonBg; dropdown.defaultBorder=COLORS.softBorder or COLORS.border; dropdown.defaultText=COLORS.text
    dropdown.label=Text(dropdown,"None","GameFontHighlightSmall",11,COLORS.text); dropdown.label:SetPoint("LEFT",8,0); dropdown.label:SetPoint("RIGHT",-24,0); dropdown.label:SetHeight(22); dropdown.label:SetJustifyV("MIDDLE")
    dropdown.arrow=Text(dropdown,"v","GameFontNormal",12,COLORS.gold,"CENTER"); dropdown.arrow:SetPoint("RIGHT",-5,0); dropdown.arrow:SetSize(16,20); dropdown.arrow:SetJustifyV("MIDDLE")
    dropdown.optionsProvider=optionsProvider; dropdown.getValue=getValue; dropdown.setValue=setValue
    dropdown.menu=CreateFrame("Frame",nil,UIParent,"BackdropTemplate"); dropdown.menu:SetFrameStrata("TOOLTIP"); dropdown.menu:SetFrameLevel(9000); dropdown.menu:SetWidth(width); dropdown.menu:Hide(); Style(dropdown.menu,COLORS.bg,COLORS.gold)
    dropdown.menu.rows={}; dropdown.menu.offset=1; dropdown.menu:EnableMouseWheel(true)
    local function PopulateMenu()
        local options=type(optionsProvider)=="function" and optionsProvider() or optionsProvider or {}
        local visible=math.min(10,math.max(1,#options)); local maxOffset=math.max(1,#options-visible+1)
        dropdown.menu.offset=math.max(1,math.min(dropdown.menu.offset or 1,maxOffset)); dropdown.menu:SetHeight((visible*24)+4)
        for rowIndex=1,10 do
            local row=dropdown.menu.rows[rowIndex]
            if not row then
                row=CreateFrame("Button",nil,dropdown.menu,"BackdropTemplate"); row:SetHeight(22); Style(row,COLORS.card or COLORS.panel,COLORS.softBorder or COLORS.border)
                row.defaultBg=COLORS.card or COLORS.panel; row.defaultBorder=COLORS.softBorder or COLORS.border; row.defaultText=COLORS.text
                row.label=Text(row,"","GameFontHighlightSmall",11,COLORS.text); row.label:SetPoint("LEFT",7,0); row.label:SetPoint("RIGHT",-5,0); row.label:SetHeight(20); row.label:SetJustifyV("MIDDLE")
                row:SetScript("OnClick",function()
                    local option=row.option; if not option then return end
                    local accepted=setValue and setValue(option.value,option)
                    dropdown.menu:Hide(); if activeDropdown==dropdown then activeDropdown=nil end
                    if accepted~=false then dropdown:RefreshText() end
                end)
                row:SetScript("OnEnter",ApplyButtonHoverStyle)
                row:SetScript("OnLeave",ApplyButtonRestingStyle)
                dropdown.menu.rows[rowIndex]=row
            end
            local option=options[dropdown.menu.offset+rowIndex-1]; row.option=option; row:SetShown(option~=nil)
            if option then
                row:ClearAllPoints(); row:SetPoint("TOPLEFT",2,-2-((rowIndex-1)*24)); row:SetPoint("TOPRIGHT",-2,-2-((rowIndex-1)*24)); row.label:SetText(option.label)
                local selected=getValue and getValue()==option.value
                row.defaultBorder=selected and COLORS.gold or (COLORS.softBorder or COLORS.border)
                row.defaultText=selected and COLORS.gold or COLORS.text
                ApplyButtonRestingStyle(row)
            end
        end
    end
    dropdown.menu:SetScript("OnMouseWheel",function(_,delta)
        local options=type(optionsProvider)=="function" and optionsProvider() or optionsProvider or {}; local visible=math.min(10,math.max(1,#options)); local maxOffset=math.max(1,#options-visible+1)
        dropdown.menu.offset=math.max(1,math.min(maxOffset,(dropdown.menu.offset or 1)-delta)); PopulateMenu()
    end)
    dropdown:SetScript("OnClick",function()
        if dropdown.menu:IsShown() then dropdown.menu:Hide(); activeDropdown=nil; return end
        if activeDropdown and activeDropdown.menu then activeDropdown.menu:Hide() end
        activeDropdown=dropdown; dropdown.menu.offset=1; dropdown.menu:ClearAllPoints(); dropdown.menu:SetPoint("TOPLEFT",dropdown,"BOTTOMLEFT",0,-2); PopulateMenu(); dropdown.menu:Show()
    end)
    dropdown:SetScript("OnHide",function() dropdown.menu:Hide(); if activeDropdown==dropdown then activeDropdown=nil end end)
    dropdown:SetScript("OnEnter",ApplyButtonHoverStyle)
    dropdown:SetScript("OnLeave",ApplyButtonRestingStyle)
    dropdown.RefreshText=function(self)
        local options=type(self.optionsProvider)=="function" and self.optionsProvider() or self.optionsProvider or {}
        local current=self.getValue and self.getValue() or nil
        for _,option in ipairs(options) do if option.value==current then self.label:SetText(option.label); return end end
        self.label:SetText(options[1] and options[1].label or "None")
    end
    dropdown:RefreshText()
    return dropdown
end
local function Confirm(key,textValue,onAccept)
    StaticPopupDialogs=StaticPopupDialogs or {}
    StaticPopupDialogs[key]=StaticPopupDialogs[key] or {
        text="%s",button1=YES,button2=NO,timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
        OnAccept=function(_,data) if data and data.onAccept then data.onAccept() end end,
    }
    StaticPopup_Show(key,textValue,nil,{onAccept=onAccept})
end
local function Copy(value) return Lib().DeepCopy and Lib().DeepCopy(value) or value end
local function InCombat() return InCombatLockdown and InCombatLockdown() end
local function DeepEqual(left,right,seen)
    if left==right then return true end
    if type(left)~=type(right) then return false end
    if type(left)~="table" then return false end
    seen=seen or {}; if seen[left] and seen[left]==right then return true end; seen[left]=right
    for key,value in pairs(left) do if not DeepEqual(value,right[key],seen) then return false end end
    for key in pairs(right) do if left[key]==nil then return false end end
    return true
end
local function LineCount(value)
    value=tostring(value or ""):gsub("\r\n","\n"):gsub("\r","\n")
    local count=1
    for _ in value:gmatch("\n") do count=count+1 end
    return count
end

-- Read-only teaching references. These live only in the editor UI: they are
-- never stored in a class/spec collection, assigned a secure slot, included in
-- the Binding List, or exposed to the sequencer execution library.
local EXAMPLE_SEQUENCES={
    {
        id="__keylab_example_disc_4",name="Disc Priest DPS",binding="",forceBinding=false,isExample=true,
        activeVersionId="__keylab_example_disc_4_default",versionOrder={"__keylab_example_disc_4_default","__keylab_example_disc_4_sba"},
        versions={
            __keylab_example_disc_4_default={
                id="__keylab_example_disc_4_default",name="Version Default",mode="priority",blocks={
                    {enabled=true,macroText="/castsequence [@target, nochanneling] Shadow Word: Pain, Mind Blast"},
                    {enabled=true,macroText="/cast [@target, nochanneling] Penance"},
                    {enabled=true,macroText="/cast [@target, nochanneling] Smite"},
                },
            },
            __keylab_example_disc_4_sba={
                id="__keylab_example_disc_4_sba",name="SBA",mode="sequential",blocks={
                    {enabled=true,macroText="/cast [@target, nochanneling] Single-Button Assistant"},
                },
            },
        },
    },
    {
        id="__keylab_example_bm_pgup",name="BM Hunter Pet Call Back",binding="",forceBinding=false,isExample=true,
        activeVersionId="__keylab_example_bm_pgup_default",versionOrder={"__keylab_example_bm_pgup_default"},
        versions={
            __keylab_example_bm_pgup_default={
                id="__keylab_example_bm_pgup_default",name="Version Default",mode="sequential",blocks={
                    {enabled=true,macroText="/petpassive\n/petfollow\n/stopattack\n/use [@pet] Dash"},
                },
            },
        },
    },
    {
        id="__keylab_example_bm_4",name="BM Hunter DPS",binding="",forceBinding=false,isExample=true,
        activeVersionId="__keylab_example_bm_4_testing",versionOrder={"__keylab_example_bm_4_testing"},
        versions={
            __keylab_example_bm_4_testing={
                id="__keylab_example_bm_4_testing",name="Testing",mode="priority",blocks={
                    {enabled=true,macroText="/petattack\n/startattack\n/castsequence reset=target Hunter's Mark, nil\n/cast [mod:ctrl,@player] Binding Shot; [@target] Bestial Wrath"},
                    {enabled=true,macroText="/use [nopet, nodead] Call Pet 1\n/use [pet, dead] Revive Pet\n/castsequence reset=target Hunter's Mark, nil\n/cast [mod:ctrl,@player] Binding Shot; Wild Thrash"},
                    {enabled=true,macroText="/use [nopet, nodead] Call Pet 1\n/use [pet, dead] Revive Pet\n/castsequence reset=target Hunter's Mark, nil\n/cast [mod:ctrl,@player] Binding Shot; Kill Command"},
                    {enabled=true,macroText="/use [nopet, nodead] Call Pet 1\n/use [pet, dead] Revive Pet\n/castsequence reset=target Hunter's Mark, nil\n/castsequence [mod:ctrl,@player] Binding Shot; Cobra Shot, Barbed Shot"},
                },
            },
        },
    },
}
local EXAMPLE_BY_ID={}
for _,example in ipairs(EXAMPLE_SEQUENCES) do EXAMPLE_BY_ID[example.id]=example end

local function SetControlEnabled(control,enabled)
    if not control then return end
    if enabled then
        if control.Enable then control:Enable() elseif control.SetEnabled then control:SetEnabled(true) end
        if control.SetAlpha then control:SetAlpha(1) end
    else
        if control.Disable then control:Disable() elseif control.SetEnabled then control:SetEnabled(false) end
        if control.SetAlpha then control:SetAlpha(0.45) end
    end
end

function Sequencer:Collection()
    return Lib().GetCollectionSnapshot and Lib().GetCollectionSnapshot() or {sequences={},order={},recycleBin={}}
end
function Sequencer:SequenceOptions()
    local collection=self:Collection(); local options={}
    for _,id in ipairs(collection.order or {}) do
        local sequence=collection.sequences[id]
        if sequence then table.insert(options,{value=id,label=sequence.name}) end
    end
    for _,example in ipairs(EXAMPLE_SEQUENCES) do
        table.insert(options,{value=example.id,label="[Example] "..example.name})
    end
    return options
end
function Sequencer:CurrentVersion()
    return self.draft and self.draft.versions and self.draft.versions[self.editVersionId] or nil
end
function Sequencer:CurrentBlock()
    local version=self:CurrentVersion()
    return version and version.blocks and version.blocks[self.selectedBlockIndex] or nil
end
function Sequencer:HasUnsavedChanges()
    if self.viewOnly then
        self.dirty=false; self.editorChanged=false
        return false
    end
    if self.editorChanged and self.macroEdit and (self.macroEdit:GetText() or "")==tostring(self.editorBaseline or "") then
        self.editorChanged=false
    end
    if self.dirty and self.draft and self.savedBaseline and DeepEqual(self.draft,self.savedBaseline) then
        self.dirty=false
    end
    return self.dirty==true or self.editorChanged==true
end

function Sequencer:RefreshStatusLabels()
    local color=self.statusKind=="error" and COLORS.red or self.statusKind=="success" and COLORS.green or COLORS.yellow
    if self.statusText then self.statusText:SetText(self.statusScope=="editor" and self.statusMessage or "Ready."); Color(self.statusText,self.statusScope=="editor" and color or COLORS.muted) end
    if self.bindingStatus then self.bindingStatus:SetText(self.statusScope=="binding" and self.statusMessage or ""); Color(self.bindingStatus,color) end
    if self.recycleStatus then self.recycleStatus:SetText(self.statusScope=="recycle" and self.statusMessage or ""); Color(self.recycleStatus,color) end
end
function Sequencer:SetStatus(message,kind)
    self.statusMessage=tostring(message or "")
    self.statusKind=kind; self.statusScope=self.selectedView or "editor"; self:RefreshStatusLabels()
end
function Sequencer:RefreshFooter()
    if not self.footerRuntime then return end
    if self.viewOnly then
        self.footerRuntime:SetText("Reference Example   |   Read Only   |   No binding or execution")
        Color(self.footerRuntime,COLORS.gold)
        return
    end
    local runtime=self.draft and Lib().GetRuntime and Lib().GetRuntime(self.draft.id) or nil
    self.footerRuntime:SetText("Runtime: "..(runtime and "Active" or "Idle").."   |   Last Block: "..tostring(runtime and runtime.lastBlock or "-").."   |   "..(self:HasUnsavedChanges() and "Unsaved" or "Saved"))
    Color(self.footerRuntime,self:HasUnsavedChanges() and COLORS.yellow or COLORS.muted)
end
function Sequencer:MarkDirty(message)
    if self.loading or self.viewOnly then return end
    self.dirty=true; self:SetStatus(message or "Unsaved changes."); self:RefreshFooter(); self:RefreshVersionRows()
end
function Sequencer:SetEditorText(value)
    value=tostring(value or "")
    self.loading=true
    if self.macroEdit then self.macroEdit:SetText(value); self.macroEdit:SetCursorPosition(0) end
    self.loading=false; self.editorBaseline=value; self.editorChanged=false; self:RefreshMacroValidation(); self:RefreshFooter()
end
function Sequencer:LoadSelectedBlock()
    local block=self:CurrentBlock()
    if not block then self:SetEditorText(""); return end
    local text,message
    if Lib().GetBlockText then text,message=Lib().GetBlockText(block) else text,message=Lib().GenerateBlock(block) end
    self:SetEditorText(text or "")
    if not text and message then self:SetStatus(message,"error") end
end
function Sequencer:LoadSequence(sequenceID,versionID)
    local options=self:SequenceOptions()
    if not sequenceID then sequenceID=options[1] and options[1].value end
    self.selectedSequenceId=sequenceID
    local example=EXAMPLE_BY_ID[sequenceID]
    self.viewOnly=example~=nil
    self.draft=example and Copy(example) or (sequenceID and Lib().GetSequenceCopy and Lib().GetSequenceCopy(sequenceID) or nil)
    self.savedBaseline=Copy(self.draft)
    self.editVersionId=self.draft and (versionID or self.draft.activeVersionId or self.draft.versionOrder[1]) or nil
    local version=self:CurrentVersion()
    self.selectedBlockIndex=version and #(version.blocks or {})>0 and 1 or nil
    self.dirty=false; self.editorChanged=false
    self.loading=true
    if self.sequenceNameBox then self.sequenceNameBox:SetText(self.draft and self.draft.name or "") end
    self.loading=false
    self:LoadSelectedBlock(); self:RefreshEditor()
    if self.viewOnly then self:SetStatus("Read-only reference example. It cannot be edited, bound, saved, or executed.","success") end
end
function Sequencer:DiscardDraft()
    local sequenceID,versionID=self.selectedSequenceId,self.editVersionId
    self:LoadSequence(sequenceID,versionID); self:SetStatus("Unsaved changes discarded.")
end

function Sequencer:SaveDraft(afterSave)
    if self.viewOnly then self:SetStatus("Reference examples are read-only and cannot be saved or executed.","error"); return false end
    if not self.draft then self:SetStatus("Create a sequence first.","error"); return false end
    if self.editorChanged then self:SetStatus("Use Add or Save in the macro editor before Save Changes.","error"); return false end
    local valid,bindingMessage,conflictType
    if Lib().CheckSequenceBinding then valid,bindingMessage,conflictType=Lib().CheckSequenceBinding(self.draft) else valid,bindingMessage,conflictType=Lib().CheckBinding(self.draft.binding,self.draft.id) end
    if not valid and conflictType=="keylab" then self:SetStatus(bindingMessage,"error"); return false end
    if not valid and conflictType=="wow" and not self.draft.forceBinding then
        Confirm("KEYLAB_SEQUENCE_REPLACE_BINDING",bindingMessage.." Temporarily replace it while KeyLab is loaded?",function()
            Sequencer.draft.forceBinding=true; Sequencer:SaveDraft(afterSave)
        end)
        return false
    end
    local ok,message=Lib().SaveSequence(self.draft)
    self:SetStatus(message,ok and "success" or "error")
    if ok then
        local sequenceID,versionID=self.draft.id,self.editVersionId
        self:LoadSequence(sequenceID,versionID)
        if afterSave then afterSave() end
    end
    return ok
end
function Sequencer:RequestSwitch(callback)
    if not self:HasUnsavedChanges() then callback(); return true end
    StaticPopupDialogs=StaticPopupDialogs or {}
    StaticPopupDialogs.KEYLAB_SEQUENCE_UNSAVED=StaticPopupDialogs.KEYLAB_SEQUENCE_UNSAVED or {
        text="This sequence has unsaved changes.",button1="Save Changes",button2="Discard",button3=CANCEL,
        timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
        OnAccept=function(_,data) if data then Sequencer:SaveDraft(data.callback) end end,
        OnCancel=function(_,data,reason) if reason=="clicked" and data and data.callback then Sequencer:DiscardDraft(); data.callback() end end,
        OnAlt=function() end,
    }
    StaticPopup_Show("KEYLAB_SEQUENCE_UNSAVED",nil,nil,{callback=callback}); return false
end
function Sequencer:RequestEditorDiscard(callback)
    if self.viewOnly then self.editorChanged=false; callback(); return end
    if not self.editorChanged then callback(); return end
    Confirm("KEYLAB_SEQUENCE_DISCARD_EDITOR","Discard the macro text currently being edited?",callback)
end
function Sequencer:RequestLeave(callback)
    if not self:HasUnsavedChanges() or InCombat() then return true end
    self:RequestSwitch(function() if callback then callback() end end); return false
end

function Sequencer:RefreshMacroValidation()
    if not self.macroEdit then return end
    local value=self.macroEdit:GetText() or ""
    ButtonAccent(self.macroAddButton); ButtonAccent(self.macroSaveButton)
    if self.viewOnly then
        self.characterCount:SetText(tostring(#value).." / 255 characters"); Color(self.characterCount,COLORS.muted)
        self.validationText:SetText("Read-only example block. Select the blocks below to explore how the sequence is arranged."); Color(self.validationText,COLORS.green)
        return
    end
    if Trim(value)=="" then
        self.characterCount:SetText(tostring(#value).." / 255 characters"); Color(self.characterCount,COLORS.muted)
        self.validationText:SetText("Enter a macro block. Add becomes available when the block is ready."); Color(self.validationText,COLORS.muted)
        return
    end
    local valid,message
    if Lib().ValidateMacroText then valid,message=Lib().ValidateMacroText(value) else message="Validation is unavailable." end
    self.characterCount:SetText(tostring(#value).." / 255 characters")
    Color(self.characterCount,#value>255 and COLORS.red or #value>220 and COLORS.yellow or COLORS.muted)
    if valid and not self.selectedBlockIndex then
        self.validationText:SetText("Ready to add. Choose Add to place this macro in Sequence Blocks."); Color(self.validationText,COLORS.green); ButtonAccent(self.macroAddButton,COLORS.green,COLORS.green)
    elseif valid and self.editorChanged then
        self.validationText:SetText("Ready. Choose Save to update this block, or Add to make a new one."); Color(self.validationText,COLORS.green); ButtonAccent(self.macroSaveButton,COLORS.green,COLORS.green); ButtonAccent(self.macroAddButton,COLORS.green,COLORS.green)
    elseif valid then
        self.validationText:SetText("Block selected. Edit it and choose Save, or choose Clear to start a new block."); Color(self.validationText,COLORS.green)
    else self.validationText:SetText("Invalid: "..tostring(message)); Color(self.validationText,COLORS.red) end
end
function Sequencer:ClearMacroEditor()
    if self.viewOnly then self:SetStatus("Reference examples are read-only.","error"); return end
    self.selectedBlockIndex=nil; self:SetEditorText(""); self:SetStatus("Macro editor cleared.")
    self:RefreshBlockRows()
end
function Sequencer:AddMacroBlock()
    if self.viewOnly then self:SetStatus("Reference examples are read-only.","error"); return end
    local version=self:CurrentVersion(); if not version then self:SetStatus("Choose a version first.","error"); return end
    local value=self.macroEdit:GetText() or ""
    local valid,message=Lib().ValidateMacroText(value)
    if not valid then self:SetStatus(message,"error"); return end
    if #(version.blocks or {})>=(Lib().MAX_BLOCKS or 50) then self:SetStatus("This version already has 50 blocks.","error"); return end
    version.blocks=version.blocks or {}; table.insert(version.blocks,{enabled=true,macroText=value})
    self.selectedBlockIndex=#version.blocks; self.editorBaseline=value; self.editorChanged=false; self:MarkDirty("Macro block added."); self:RefreshEditor()
end
function Sequencer:SaveMacroBlock()
    if self.viewOnly then self:SetStatus("Reference examples are read-only.","error"); return end
    local block=self:CurrentBlock(); if not block then self:SetStatus("Select a block to update.","error"); return end
    local value=self.macroEdit:GetText() or ""; local valid,message=Lib().ValidateMacroText(value)
    if not valid then self:SetStatus(message,"error"); return end
    local enabled=block.enabled~=false
    self:CurrentVersion().blocks[self.selectedBlockIndex]={enabled=enabled,macroText=value}
    self.editorBaseline=value; self.editorChanged=false; self:MarkDirty("Selected macro block updated."); self:RefreshEditor()
end
function Sequencer:DeleteMacroBlock()
    if self.viewOnly then self:SetStatus("Reference examples are read-only.","error"); return end
    local version=self:CurrentVersion(); local index=self.selectedBlockIndex
    if not version or not index or not version.blocks[index] then self:SetStatus("Select a block to delete.","error"); return end
    Confirm("KEYLAB_SEQUENCE_DELETE_BLOCK","Delete block "..tostring(index).."?",function()
        table.remove(version.blocks,index); Sequencer.selectedBlockIndex=nil; Sequencer:SetEditorText("")
        Sequencer:MarkDirty("Macro block deleted."); Sequencer:RefreshEditor()
    end)
end
function Sequencer:SelectBlock(index)
    if index==self.selectedBlockIndex then return end
    self:RequestEditorDiscard(function()
        Sequencer.selectedBlockIndex=index; Sequencer:LoadSelectedBlock(); Sequencer:RefreshBlockRows()
    end)
end
function Sequencer:MoveBlock(index,direction)
    if self.viewOnly then self:SetStatus("Reference examples are read-only.","error"); return end
    local version=self:CurrentVersion(); local other=index+direction
    if not version or not version.blocks[index] or not version.blocks[other] then return end
    version.blocks[index],version.blocks[other]=version.blocks[other],version.blocks[index]
    if self.selectedBlockIndex==index then self.selectedBlockIndex=other elseif self.selectedBlockIndex==other then self.selectedBlockIndex=index end
    self:MarkDirty("Block order changed."); self:RefreshBlockRows()
end

function Sequencer:AcquireBlockRow(poolIndex)
    self.blockRows=self.blockRows or {}; if self.blockRows[poolIndex] then return self.blockRows[poolIndex] end
    local row=CreateFrame("Frame",nil,self.blocksContent); row:SetWidth(626)
    row.number=CreateFrame("Frame",nil,row,"BackdropTemplate"); row.number:SetSize(34,34); Style(row.number,COLORS.buttonBg,COLORS.gold)
    row.number:SetPoint("LEFT",4,0); row.numberText=Text(row.number,"","GameFontNormal",14,COLORS.gold,"CENTER"); row.numberText:SetAllPoints(); row.numberText:SetJustifyV("MIDDLE")
    row.enabled=CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate"); row.enabled:SetSize(24,24); row.enabled:SetPoint("LEFT",50,0)
    row.enabledLabel=Text(row,"Enabled","GameFontHighlightSmall",11,COLORS.text); row.enabledLabel:SetPoint("LEFT",76,0); row.enabledLabel:SetSize(54,18); row.enabledLabel:SetJustifyV("MIDDLE")
    row.card=CreateFrame("Button",nil,row,"BackdropTemplate"); row.card:SetPoint("TOPLEFT",136,0); row.card:SetPoint("BOTTOMRIGHT",0,0); Style(row.card,COLORS.card or COLORS.panel,COLORS.softBorder or COLORS.border)
    row.textScroll=CreateFrame("ScrollFrame",nil,row.card); row.textScroll:SetPoint("TOPLEFT",10,-7); row.textScroll:SetPoint("BOTTOMRIGHT",-48,7); row.textScroll:EnableMouse(true); row.textScroll:EnableMouseWheel(true)
    row.textChild=CreateFrame("Frame",nil,row.textScroll); row.textChild:SetWidth(420); row.textScroll:SetScrollChild(row.textChild)
    row.macroText=Text(row.textChild,"","ChatFontNormal",11,COLORS.text); row.macroText:SetPoint("TOPLEFT",0,0); row.macroText:SetWidth(420); row.macroText:SetNonSpaceWrap(false)
    row.innerTrack=CreateFrame("Frame",nil,row.card,"BackdropTemplate"); row.innerTrack:SetPoint("TOPRIGHT",-39,-7); row.innerTrack:SetPoint("BOTTOMRIGHT",-36,7); Style(row.innerTrack,COLORS.bg,COLORS.softBorder or COLORS.border)
    row.innerThumb=row.innerTrack:CreateTexture(nil,"ARTWORK"); row.innerThumb:SetColorTexture(unpack(COLORS.gold)); row.innerThumb:SetPoint("TOPLEFT",1,-1); row.innerThumb:SetPoint("TOPRIGHT",-1,-1); row.innerThumb:SetHeight(14)
    row.up=Button(row.card,"^",20,function() Sequencer:MoveBlock(row.index,-1) end,20); row.up:SetPoint("TOPRIGHT",-8,-5)
    row.down=Button(row.card,"v",20,function() Sequencer:MoveBlock(row.index,1) end,20); row.down:SetPoint("BOTTOMRIGHT",-8,5)
    local function select() Sequencer:SelectBlock(row.index) end
    row.card:SetScript("OnClick",select); row.textScroll:SetScript("OnMouseDown",select)
    row.enabled:SetScript("OnClick",function(box)
        local version=Sequencer:CurrentVersion(); local block=version and version.blocks[row.index]
        if block then block.enabled=box:GetChecked()==true; Sequencer:MarkDirty("Block enabled state changed."); Sequencer:RefreshBlockRows() end
    end)
    row.enabledLabel:EnableMouse(true); row.enabledLabel:SetScript("OnMouseDown",function() row.enabled:Click() end)
    row.textScroll:SetScript("OnMouseWheel",function(scroll,delta)
        if not row.longText then Sequencer:ScrollBlocks(delta); return end
        local range=scroll:GetVerticalScrollRange() or 0
        local current=scroll:GetVerticalScroll() or 0
        local target=math.max(0,math.min(range,current-(delta*18)))
        if target==current then Sequencer:ScrollBlocks(delta) else scroll:SetVerticalScroll(target) end
    end)
    row.textScroll:SetScript("OnVerticalScroll",function(scroll,offset)
        local range=scroll:GetVerticalScrollRange() or 0; local track=math.max(1,(row.innerTrack:GetHeight() or 20)-16)
        row.innerThumb:ClearAllPoints(); row.innerThumb:SetPoint("TOPLEFT",1,-1-(range>0 and (offset/range)*track or 0)); row.innerThumb:SetPoint("TOPRIGHT",-1,-1-(range>0 and (offset/range)*track or 0))
    end)
    self.blockRows[poolIndex]=row; return row
end
function Sequencer:RefreshBlockRows()
    if not self.blocksContent then return end
    local version=self:CurrentVersion(); local blocks=version and version.blocks or {}; local y=0
    for index,block in ipairs(blocks) do
        local row=self:AcquireBlockRow(index); row.index=index; row:Show(); row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-y)
        local macroText=Lib().GetBlockText and Lib().GetBlockText(block) or Lib().GenerateBlock(block) or "Invalid block"
        local lines=LineCount(macroText); local visible=math.min(4,math.max(1,lines)); local height=math.max(50,18+(visible*14))
        row:SetHeight(height); row.numberText:SetText(tostring(index)); row.enabled:SetChecked(block.enabled~=false); row.macroText:SetText(macroText)
        SetControlEnabled(row.enabled,not self.viewOnly)
        row.textChild:SetHeight(math.max(height-14,lines*14+4)); row.textScroll:SetVerticalScroll(0); row.longText=lines>4; row.innerTrack:SetShown(row.longText)
        if row.card.SetBackdropBorderColor then row.card:SetBackdropBorderColor(unpack(index==self.selectedBlockIndex and COLORS.gold or (COLORS.softBorder or COLORS.border))) end
        row.up:SetShown(index>1); row.down:SetShown(index<#blocks); SetControlEnabled(row.up,not self.viewOnly); SetControlEnabled(row.down,not self.viewOnly); y=y+height+8
    end
    for index=#blocks+1,#(self.blockRows or {}) do self.blockRows[index]:Hide() end
    self.blocksContent:SetHeight(math.max(1,y)); self.blocksEmpty:SetShown(#blocks==0)
    if self.blockCountText then self.blockCountText:SetText(tostring(#blocks).." / 50 blocks") end
end

function Sequencer:NewSequence()
    self:RequestSwitch(function()
        local id,message=Lib().CreateSequence(); Sequencer:SetStatus(message,id and "success" or "error")
        if id then Sequencer:LoadSequence(id); Sequencer.sequenceNameBox:SetFocus(); Sequencer.sequenceNameBox:HighlightText() end
    end)
end
function Sequencer:DuplicateSequence()
    if self.viewOnly then self:SetStatus("Reference examples cannot be copied into the executable library.","error"); return end
    if not self.draft then return end
    self:RequestSwitch(function()
        local id,message=Lib().DuplicateSequence(Sequencer.draft.id); Sequencer:SetStatus(message,id and "success" or "error"); if id then Sequencer:LoadSequence(id) end
    end)
end
function Sequencer:DeleteSequence()
    if self.viewOnly then self:SetStatus("Reference examples are built in and cannot be deleted.","error"); return end
    if not self.draft then return end
    local id,name=self.draft.id,self.draft.name
    Confirm("KEYLAB_SEQUENCE_DELETE","Delete "..tostring(name).."? It remains recoverable for 30 days.",function()
        local ok,message=Lib().DeleteSequence(id); Sequencer:SetStatus(message,ok and "success" or "error"); Sequencer:LoadSequence(nil)
    end)
end

function Sequencer:AddVersion(duplicate)
    if self.viewOnly then self:SetStatus("Reference examples are read-only.","error"); return end
    if not self.draft then return end
    local id,message=Lib().NewVersion(self.draft,duplicate and nil or "Version Default",duplicate and self.editVersionId or nil)
    self:SetStatus(message,id and "success" or "error")
    if id then
        self.editVersionId=id; self.selectedBlockIndex=duplicate and 1 or nil
        if duplicate then self:LoadSelectedBlock() else self:SetEditorText("") end
        self:MarkDirty(); self:RefreshEditor()
    end
end
function Sequencer:RenameVersion()
    if self.viewOnly then self:SetStatus("Reference examples are read-only.","error"); return end
    local version=self:CurrentVersion(); if not version then return end
    StaticPopupDialogs=StaticPopupDialogs or {}
    StaticPopupDialogs.KEYLAB_RENAME_VERSION={
        text="Rename version",button1=SAVE,button2=CANCEL,hasEditBox=true,timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
        OnShow=function(self,data) local box=self.EditBox or self.editBox; if box then box:SetText(data.current or ""); box:HighlightText(); box:SetFocus() end end,
        OnAccept=function(self,data) local box=self.EditBox or self.editBox; local value=Trim(box and box:GetText() or ""); if value~="" then data.accept(value) end end,
    }
    StaticPopup_Show("KEYLAB_RENAME_VERSION",nil,nil,{current=version.name,accept=function(value)
        version.name=value; Sequencer:MarkDirty("Version renamed."); Sequencer:RefreshVersionRows()
    end})
end
function Sequencer:DeleteVersion()
    if self.viewOnly then self:SetStatus("Reference examples are read-only.","error"); return end
    if not self.draft or #(self.draft.versionOrder or {})<=1 then self:SetStatus("A sequence must keep at least one version.","error"); return end
    local sequenceID,versionID=self.draft.id,self.editVersionId; local version=self:CurrentVersion()
    local committed=Lib().GetSequenceCopy and Lib().GetSequenceCopy(sequenceID) or nil
    if committed and not (committed.versions and committed.versions[versionID]) then
        self.draft.versions[versionID]=nil
        for index,id in ipairs(self.draft.versionOrder) do if id==versionID then table.remove(self.draft.versionOrder,index); break end end
        self.editVersionId=self.draft.versionOrder[1]; self.selectedBlockIndex=nil; self:SetEditorText(""); self:MarkDirty("Unsaved version removed."); self:RefreshEditor(); return
    end
    Confirm("KEYLAB_VERSION_DELETE","Delete version "..tostring(version and version.name or "").."? It remains recoverable for 30 days.",function()
        Sequencer:RequestSwitch(function()
            local ok,message=Lib().DeleteVersion(sequenceID,versionID); Sequencer:SetStatus(message,ok and "success" or "error"); Sequencer:LoadSequence(sequenceID)
        end)
    end)
end
function Sequencer:SelectVersion(versionID)
    if versionID==self.editVersionId then return end
    self:RequestEditorDiscard(function()
        Sequencer.editVersionId=versionID; local version=Sequencer:CurrentVersion(); Sequencer.selectedBlockIndex=version and #(version.blocks or {})>0 and 1 or nil
        Sequencer:LoadSelectedBlock(); Sequencer:RefreshEditor()
    end)
end
function Sequencer:ActivateVersion()
    if self.viewOnly then self:SetStatus("Reference examples cannot be activated or executed.","error"); return end
    if not self.draft then return end
    local sequenceID,versionID=self.draft.id,self.editVersionId
    local activate=function()
        local ok,message=Lib().ActivateVersion(sequenceID,versionID); Sequencer:SetStatus(message,ok and "success" or "error"); Sequencer:LoadSequence(sequenceID,versionID)
    end
    if self:HasUnsavedChanges() then self:SaveDraft(activate) else activate() end
end
function Sequencer:AcquireVersionRow(index)
    self.versionRows=self.versionRows or {}; if self.versionRows[index] then return self.versionRows[index] end
    local row=CreateFrame("Button",nil,self.versionsContent,"BackdropTemplate"); row:SetSize(178,34); Style(row,COLORS.card or COLORS.panel,COLORS.softBorder or COLORS.border)
    row.label=Text(row,"","GameFontHighlightSmall",11,COLORS.text); row.label:SetPoint("LEFT",10,0); row.label:SetPoint("RIGHT",-6,0); row.label:SetHeight(26); row.label:SetJustifyV("MIDDLE")
    row:SetScript("OnClick",function() Sequencer:SelectVersion(row.versionID) end)
    self.versionRows[index]=row; return row
end
function Sequencer:RefreshVersionRows()
    if not self.versionsContent then return end
    local order=self.draft and self.draft.versionOrder or {}; local y=0
    for index,id in ipairs(order) do
        local version=self.draft.versions[id]; local row=self:AcquireVersionRow(index); row.versionID=id; row:Show(); row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-y)
        local active=id==self.draft.activeVersionId; row.label:SetText((self.viewOnly and active and "Shown:  " or active and "*  " or "")..tostring(version and version.name or "Missing"))
        Color(row.label,active and COLORS.gold or COLORS.text)
        if row.SetBackdropBorderColor then row:SetBackdropBorderColor(unpack(id==self.editVersionId and COLORS.gold or (COLORS.softBorder or COLORS.border))) end
        y=y+40
    end
    for index=#order+1,#(self.versionRows or {}) do self.versionRows[index]:Hide() end
    self.versionsContent:SetHeight(math.max(1,y))
    local version=self:CurrentVersion(); local blockCount=version and #(version.blocks or {}) or 0
    self.versionSummary:SetText(tostring(#order).." / 20 versions\n"..tostring(blockCount).." / 50 blocks\n"..tostring(version and (Lib().MODE_NAMES[version.mode] or version.mode) or "No mode"))
end

local function CapturedBinding(key)
    key=tostring(key or ""):upper()
    if key=="LSHIFT" or key=="RSHIFT" or key=="LCTRL" or key=="RCTRL" or key=="LALT" or key=="RALT" or key=="UNKNOWN" then return nil end
    local parts={}
    if IsControlKeyDown and IsControlKeyDown() then table.insert(parts,"CTRL") end
    if IsShiftKeyDown and IsShiftKeyDown() then table.insert(parts,"SHIFT") end
    if IsAltKeyDown and IsAltKeyDown() then table.insert(parts,"ALT") end
    table.insert(parts,key); return table.concat(parts,"-")
end
function Sequencer:EnsureCaptureOverlay()
    if self.captureOverlay then return end
    local overlay=CreateFrame("Frame","KeyLabSequencerBindingCapture",UIParent,"BackdropTemplate")
    overlay:SetAllPoints(UIParent); overlay:SetFrameStrata("TOOLTIP"); overlay:SetFrameLevel(10000); if overlay.SetToplevel then overlay:SetToplevel(true) end
    Style(overlay,{0.01,0.02,0.04,0.88},COLORS.gold); overlay:Hide(); overlay:EnableMouse(true); overlay:EnableKeyboard(true); overlay:SetPropagateKeyboardInput(false)
    local box=Panel(overlay,0,0,430,128,COLORS.panel,COLORS.gold); box:ClearAllPoints(); box:SetPoint("CENTER"); box:SetFrameLevel(10001)
    local title=Text(box,"Press a key or mouse button","GameFontNormalLarge",17,COLORS.gold,"CENTER"); title:SetPoint("TOP",0,-22); title:SetSize(400,24)
    local help=Text(box,"Escape cancels. Mouse buttons 1 and 2 stay reserved.","GameFontHighlightSmall",11,COLORS.muted,"CENTER"); help:SetPoint("TOP",0,-58); help:SetSize(400,20)
    local cancel=Button(box,"Cancel",86,function() overlay:Hide(); overlay:EnableKeyboard(false) end); cancel:SetPoint("BOTTOM",0,14)
    overlay:SetScript("OnKeyDown",function(_,key) if key=="ESCAPE" then overlay:Hide(); overlay:EnableKeyboard(false); return end; local binding=CapturedBinding(key); if binding then Sequencer:AcceptCapturedBinding(binding) end end)
    overlay:SetScript("OnMouseDown",function(_,button) local number=button and button:match("Button(%d+)"); if number then Sequencer:AcceptCapturedBinding(CapturedBinding("BUTTON"..number)) end end)
    self.captureOverlay=overlay
end
function Sequencer:StartBindingCapture(target)
    if self.viewOnly then self:SetStatus("Reference examples cannot be assigned a key or mouse binding.","error"); return end
    if InCombat() then self:SetStatus("Bindings cannot be changed during combat.","error"); return end
    self:EnsureCaptureOverlay(); self.captureTarget=target or "sequence"; self.captureOverlay:Show(); self.captureOverlay:EnableKeyboard(true); if self.captureOverlay.Raise then self.captureOverlay:Raise() end
end
function Sequencer:AcceptCapturedBinding(binding)
    if not binding then return end
    self.captureOverlay:Hide(); self.captureOverlay:EnableKeyboard(false)
    if not self.draft then return end
    local okay,message,conflictType=Lib().CheckBinding(binding,self.draft.id)
    if not okay and conflictType=="keylab" then self:SetStatus(message,"error"); return end
    local apply=function(force)
        Sequencer.draft.binding=binding; Sequencer.draft.forceBinding=force==true; Sequencer:MarkDirty("Binding set to "..binding.."."); Sequencer:RefreshEditor()
    end
    if not okay and conflictType=="wow" then Confirm("KEYLAB_SEQUENCE_CAPTURE_CONFLICT",message.." Temporarily replace it while KeyLab is loaded?",function() apply(true) end) else apply(false) end
end
function Sequencer:ClearBinding()
    if self.viewOnly then self:SetStatus("Reference examples do not have bindings.","error"); return end
    if not self.draft then return end
    if InCombat() then self:SetStatus("Bindings cannot be changed during combat.","error"); return end
    self.draft.binding=""; self.draft.forceBinding=false; self:MarkDirty("Binding removed."); self:RefreshEditor()
end

function Sequencer:RefreshHeader()
    if not self.sequenceDropdown then return end
    self.sequenceDropdown:RefreshText()
    self.bindingValue:SetText(self.viewOnly and "Disabled" or (self.draft and Trim(self.draft.binding)~="" and self.draft.binding or "Unbound"))
end
function Sequencer:RefreshEditor()
    if not self.editorBuilt then return end
    local editable=not self.viewOnly
    SetControlEnabled(self.sequenceNameBox,editable); SetControlEnabled(self.sequenceCopyButton,editable); SetControlEnabled(self.sequenceDeleteButton,editable)
    SetControlEnabled(self.bindingSetButton,editable); SetControlEnabled(self.bindingEditButton,editable); SetControlEnabled(self.bindingDeleteButton,editable)
    SetControlEnabled(self.macroEdit,editable); SetControlEnabled(self.macroClearButton,editable); SetControlEnabled(self.macroAddButton,editable); SetControlEnabled(self.macroSaveButton,editable); SetControlEnabled(self.macroDeleteButton,editable)
    SetControlEnabled(self.modeDropdown,editable); SetControlEnabled(self.versionNewButton,editable); SetControlEnabled(self.versionRenameButton,editable); SetControlEnabled(self.versionDuplicateButton,editable); SetControlEnabled(self.versionDeleteButton,editable); SetControlEnabled(self.versionActivateButton,editable)
    SetControlEnabled(self.resetSequenceButton,editable); SetControlEnabled(self.saveChangesButton,editable)
    if self.macroEditorTitle then self.macroEditorTitle:SetText(self.viewOnly and "Reference Macro Block" or "Create or Edit Macro Block") end
    if self.versionsTitle then self.versionsTitle:SetText(self.viewOnly and "Example Versions" or "Versions") end
    self:RefreshHeader(); self.modeDropdown:RefreshText(); self:RefreshMacroValidation(); self:RefreshBlockRows(); self:RefreshVersionRows(); self:RefreshFooter()
end

function Sequencer:RefreshBindingList()
    if not self.bindingListContent then return end
    local collection=self:Collection(); local y=0; self.bindingRows=self.bindingRows or {}
    for index,id in ipairs(collection.order or {}) do
        local sequence=collection.sequences[id]; local row=self.bindingRows[index]
        if not row then
            row=CreateFrame("Frame",nil,self.bindingListContent,"BackdropTemplate"); row:SetSize(840,44); Style(row,COLORS.card or COLORS.panel,COLORS.cardBorder or COLORS.border)
            row.binding=Text(row,"","ChatFontNormal",11,COLORS.text); row.binding:SetPoint("LEFT",12,0); row.binding:SetSize(105,30); row.binding:SetJustifyV("MIDDLE")
            row.sequence=CreateFrame("Button",nil,row); row.sequence:SetSize(260,30); row.sequence:SetPoint("LEFT",122,0)
            row.sequence.label=Text(row.sequence,"","GameFontHighlightSmall",11,COLORS.text,"CENTER"); row.sequence.label:SetAllPoints(); row.sequence.label:SetJustifyV("MIDDLE")
            row.sequence:SetScript("OnClick",function() Sequencer:RequestSwitch(function() Sequencer:LoadSequence(row.sequenceID); Sequencer:SetView("editor") end) end)
            row.sequence:SetScript("OnEnter",function() Color(row.sequence.label,COLORS.gold) end); row.sequence:SetScript("OnLeave",function() Color(row.sequence.label,COLORS.text) end)
            row.version=Text(row,"","GameFontHighlightSmall",11,COLORS.text); row.version:SetPoint("LEFT",392,0); row.version:SetSize(155,30); row.version:SetJustifyV("MIDDLE")
            row.state=Text(row,"","GameFontHighlightSmall",10,COLORS.muted); row.state:SetPoint("LEFT",550,0); row.state:SetSize(145,30); row.state:SetJustifyV("MIDDLE")
            row.edit=Button(row,"Edit",58,function() Sequencer:RequestSwitch(function() Sequencer:LoadSequence(row.sequenceID); Sequencer:SetView("editor"); Sequencer:StartBindingCapture("sequence") end) end); row.edit:SetPoint("RIGHT",-68,0)
            row.delete=Button(row,"Delete",58,function()
                if Sequencer.draft and Sequencer.draft.id==row.sequenceID and Sequencer:HasUnsavedChanges() then
                    Sequencer:SetStatus("Save or discard the open sequence before removing its binding here.","error"); return
                end
                local sequenceCopy=Lib().GetSequenceCopy(row.sequenceID); if not sequenceCopy then return end
                Confirm("KEYLAB_BINDING_LIST_DELETE","Remove the binding from "..tostring(sequenceCopy.name).."?",function()
                    sequenceCopy.binding=""; sequenceCopy.forceBinding=false; local ok,message=Lib().SaveSequence(sequenceCopy); Sequencer:SetStatus(message,ok and "success" or "error")
                    if ok and Sequencer.draft and Sequencer.draft.id==row.sequenceID then Sequencer:LoadSequence(row.sequenceID) end
                    Sequencer:RefreshBindingList()
                end)
            end); row.delete:SetPoint("RIGHT",-6,0)
            self.bindingRows[index]=row
        end
        row.sequenceID=id; row:Show(); row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-y)
        if row.SetBackdropBorderColor then row:SetBackdropBorderColor(unpack(COLORS.cardBorder or COLORS.border)) end
        local version=sequence.versions and sequence.versions[sequence.activeVersionId]; local okay,state=true,"Active"
        if Lib().GetBindingStatus then okay,state=Lib().GetBindingStatus(id) end
        row.binding:SetText(Trim(sequence.binding)~="" and sequence.binding or "Unbound"); Color(row.binding,Trim(sequence.binding)=="" and COLORS.muted or COLORS.gold)
        row.sequence.label:SetText(sequence.name); Color(row.sequence.label,COLORS.text); row.version:SetText(version and version.name or "Missing")
        row.state:SetText(state or (okay and "Active" or "Conflict")); Color(row.state,okay and COLORS.green or COLORS.red)
        row.delete:SetShown(Trim(sequence.binding)~=""); y=y+52
    end
    for index=#(collection.order or {})+1,#self.bindingRows do self.bindingRows[index]:Hide() end
    self.bindingListContent:SetHeight(math.max(1,y>0 and y-8 or 1)); self.bindingEmpty:SetShown(#(collection.order or {})==0)
end

function Sequencer:RefreshRecycleBin()
    if not self.recycleRows then return end
    local entries=Lib().GetRecycleBin and Lib().GetRecycleBin() or {}; self.recyclePage=math.max(1,self.recyclePage or 1)
    local perPage=8; local maxPage=math.max(1,math.ceil(#entries/perPage)); self.recyclePage=math.min(self.recyclePage,maxPage)
    for rowIndex,row in ipairs(self.recycleRows) do
        local entry=entries[((self.recyclePage-1)*perPage)+rowIndex]
        row.entry=entry; row.restoreButton.recycleEntry=entry; row.deleteButton.recycleEntry=entry; row.frame:SetShown(entry~=nil)
        if entry then row.name:SetText((entry.type=="sequence" and "Sequence: " or "Version: ")..tostring(entry.name)..(entry.sequenceName and ("  |  from "..tostring(entry.sequenceName)) or "")); row.days:SetText(tostring(entry.daysRemaining).." days remaining") end
    end
    self.recyclePageText:SetText("Page "..tostring(self.recyclePage).." / "..tostring(maxPage).."  |  "..tostring(#entries).." items"); self.recycleEmpty:SetShown(#entries==0)
end

function Sequencer:ShowRestoreNamePrompt(entry,initialName,message)
    if not self.restoreNameDialog then
        local dialog=Panel(UIParent,0,0,430,154,COLORS.panel,COLORS.gold); dialog:ClearAllPoints(); dialog:SetPoint("CENTER"); dialog:SetFrameStrata("TOOLTIP"); dialog:SetFrameLevel(10000); dialog:Hide()
        local title=Text(dialog,"Restore Sequence with a New Name","GameFontNormalLarge",16,COLORS.gold,"CENTER"); title:SetPoint("TOP",0,-16); title:SetSize(400,22)
        dialog.message=Text(dialog,"","GameFontHighlightSmall",11,COLORS.red,"CENTER"); dialog.message:SetPoint("TOP",0,-46); dialog.message:SetSize(400,30)
        dialog.nameBox=EditBox(dialog,300); dialog.nameBox:SetPoint("TOP",0,-82)
        local restore=Button(dialog,"Restore",88,function() Sequencer:AttemptRestore(dialog.entry,dialog.nameBox:GetText()) end); restore:SetPoint("BOTTOMRIGHT",-116,14)
        local cancel=Button(dialog,"Cancel",88,function() dialog:Hide() end); cancel:SetPoint("BOTTOMRIGHT",-18,14)
        self.restoreNameDialog=dialog
    end
    local dialog=self.restoreNameDialog; dialog.entry=entry; dialog.message:SetText(message or "Choose a unique sequence name.")
    dialog.nameBox:SetText(tostring(initialName or "")); dialog.nameBox:SetFocus(); dialog.nameBox:HighlightText(); dialog:Show()
end

function Sequencer:AttemptRestore(entry,requestedName)
    if not entry then return end
    local id,message,reason,suggestion=Lib().RestoreDeleted(entry.id,requestedName)
    if reason=="name_conflict" or reason=="invalid_name" then
        self:ShowRestoreNamePrompt(entry,requestedName~=nil and requestedName or suggestion,message); return
    end
    if self.restoreNameDialog then self.restoreNameDialog:Hide() end
    self:SetStatus(message,id and "success" or "error"); self:RefreshRecycleBin()
end

function Sequencer:SetView(view)
    self.selectedView=view or "editor"
    for key,panel in pairs(self.views or {}) do panel:SetShown(key==self.selectedView) end
    for key,button in pairs(self.viewButtons or {}) do
        local active=key==self.selectedView
        ButtonAccent(button,active and COLORS.gold or (COLORS.buttonBorder or COLORS.border),active and COLORS.gold or COLORS.text)
    end
    self:RefreshStatusLabels()
    if self.selectedView=="binding" then self:RefreshBindingList() elseif self.selectedView=="recycle" then self:RefreshRecycleBin() elseif self.selectedView=="editor" then self:RefreshEditor() end
end

function Sequencer:BuildTop(frame)
    self.viewButtons={}
    local definitions={{key="editor",label="Editor",width=128},{key="binding",label="Binding List",width=138},{key="information",label="Information",width=138},{key="recycle",label="Recycle Bin",width=138}}
    local x=18
    for _,definition in ipairs(definitions) do
        local button=Button(frame,definition.label,definition.width,function() Sequencer:SetView(definition.key) end,30); button:SetPoint("TOPLEFT",x,-78); self.viewButtons[definition.key]=button; x=x+definition.width+8
    end
end
function Sequencer:BuildMacroEditor(parent)
    local panel=Panel(parent,0,-92,680,204); self.macroPanel=panel
    local title=Text(panel,"Create or Edit Macro Block","GameFontNormal",15,COLORS.gold); title:SetPoint("TOPLEFT",12,-10); title:SetSize(410,20); self.macroEditorTitle=title
    self.characterCount=Text(panel,"0 / 255 characters","GameFontHighlightSmall",11,COLORS.muted,"RIGHT"); self.characterCount:SetPoint("TOPRIGHT",-12,-12); self.characterCount:SetSize(190,18)
    local shell=Panel(panel,12,-36,656,112,COLORS.bg,COLORS.softBorder or COLORS.border)
    local scroll=CreateFrame("ScrollFrame",nil,shell,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",8,-7); scroll:SetPoint("BOTTOMRIGHT",-26,7)
    local edit=CreateFrame("EditBox",nil,scroll); edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:EnableMouse(true); edit:SetFontObject("ChatFontNormal"); edit:SetTextColor(unpack(COLORS.text)); edit:SetHighlightColor(COLORS.gold[1],COLORS.gold[2],COLORS.gold[3],0.35); if edit.SetCursorColor then edit:SetCursorColor(unpack(COLORS.gold)) end; edit:SetWidth(604); edit:SetHeight(96); edit:SetTextInsets(2,2,2,2); scroll:SetScrollChild(edit)
    local caret=edit:CreateTexture(nil,"OVERLAY",nil,7); caret:SetColorTexture(COLORS.gold[1],COLORS.gold[2],COLORS.gold[3],1); caret:SetSize(2,14); caret:SetPoint("TOPLEFT",edit,"TOPLEFT",2,-2); caret:Hide()
    local function FocusEditorFromBlankArea()
        edit:SetFocus(); edit:SetCursorPosition(#(edit:GetText() or ""))
    end
    local function EditorTextHeight(box)
        if box.GetStringHeight then
            local measured=tonumber(box:GetStringHeight())
            if measured and measured>0 then return measured+12 end
        end
        local rows=0
        for line in (tostring(box:GetText() or "").."\n"):gmatch("(.-)\n") do
            rows=rows+math.max(1,math.ceil(#line/78))
        end
        return math.max(96,(rows*14)+12)
    end
    local function RefreshEditorScrollRange()
        -- UpdateScrollChildRect is not available on every Retail ScrollFrame.
        -- Resizing the scroll child refreshes the native range; only call the
        -- optional helper on clients that expose it, then keep the offset valid.
        if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
        local range=scroll:GetVerticalScrollRange() or 0
        local offset=scroll:GetVerticalScroll() or 0
        if offset>range then scroll:SetVerticalScroll(range) end
    end
    shell:EnableMouse(true); shell:SetScript("OnMouseUp",function(_,button) if button=="LeftButton" and not edit:HasFocus() then FocusEditorFromBlankArea() end end)
    scroll:EnableMouse(true); scroll:SetScript("OnMouseUp",function(_,button) if button=="LeftButton" and not edit:HasFocus() then FocusEditorFromBlankArea() end end)
    scroll:SetScript("OnSizeChanged",function(self)
        edit:SetWidth(math.max(40,(self:GetWidth() or 608)-4)); edit:SetHeight(math.max(self:GetHeight() or 96,EditorTextHeight(edit))); RefreshEditorScrollRange()
    end)
    edit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    edit:SetScript("OnEditFocusGained",function() caret:Show() end)
    edit:SetScript("OnEditFocusLost",function() caret:Hide() end)
    edit:SetScript("OnTextChanged",function(box)
        box:SetHeight(math.max(scroll:GetHeight() or 96,EditorTextHeight(box))); RefreshEditorScrollRange()
        if not Sequencer.loading and not Sequencer.viewOnly then Sequencer.editorChanged=true; Sequencer:RefreshFooter() end
        Sequencer:RefreshMacroValidation()
    end)
    edit:SetScript("OnCursorChanged",function(_,x,y,w,h) caret:ClearAllPoints(); caret:SetPoint("TOPLEFT",edit,"TOPLEFT",(x or 0)+1,y or 0); caret:SetHeight(math.max(12,h or 14)); caret:SetShown(edit:HasFocus()); local offset=scroll:GetVerticalScroll(); local height=scroll:GetHeight(); if -(y or 0)<offset then scroll:SetVerticalScroll(math.max(0,-(y or 0))) elseif -(y or 0)+(h or 14)>offset+height then scroll:SetVerticalScroll(-(y or 0)+(h or 14)-height) end end)
    self.macroEdit=edit
    self.validationText=Text(panel,"Enter a macro block. Add becomes available when the block is ready.","GameFontHighlightSmall",11,COLORS.muted); self.validationText:SetPoint("TOPLEFT",14,-154); self.validationText:SetSize(430,38)
    local clear=Button(panel,"Clear",58,function() Sequencer:ClearMacroEditor() end); clear:SetPoint("BOTTOMRIGHT",-210,10)
    local add=Button(panel,"Add",58,function() Sequencer:AddMacroBlock() end); add:SetPoint("BOTTOMRIGHT",-146,10)
    local save=Button(panel,"Save",58,function() Sequencer:SaveMacroBlock() end); save:SetPoint("BOTTOMRIGHT",-82,10)
    local delete=Button(panel,"Delete",66,function() Sequencer:DeleteMacroBlock() end); delete:SetPoint("BOTTOMRIGHT",-10,10)
    self.macroClearButton=clear; self.macroAddButton=add; self.macroSaveButton=save; self.macroDeleteButton=delete
end
function Sequencer:ScrollBlocks(delta)
    local scroll=self.blocksScroll
    if not scroll then return end
    local range=scroll:GetVerticalScrollRange() or 0
    local current=scroll:GetVerticalScroll() or 0
    scroll:SetVerticalScroll(math.max(0,math.min(range,current-((tonumber(delta) or 0)*46))))
end
function Sequencer:BuildBlocks(parent)
    local panel=Panel(parent,0,-306,680,306); self.blocksPanel=panel
    local title=Text(panel,"Sequence Blocks","GameFontNormal",15,COLORS.gold); title:SetPoint("TOPLEFT",12,-10)
    local modeLabel=Text(panel,"Mode","GameFontHighlightSmall",11,COLORS.muted); modeLabel:SetPoint("TOPRIGHT",-160,-13)
    self.modeDropdown=Dropdown(panel,135,{{value="sequential",label="Sequential"},{value="priority",label="Priority"},{value="reverse",label="Reverse Priority"}},function() local v=Sequencer:CurrentVersion(); return v and v.mode end,function(value) local v=Sequencer:CurrentVersion(); if v then v.mode=value; Sequencer:MarkDirty("Sequence mode changed."); Sequencer:RefreshEditor() end end)
    self.modeDropdown:SetPoint("TOPRIGHT",-12,-7)
    local scroll=CreateFrame("ScrollFrame",nil,panel,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",10,-42); scroll:SetPoint("BOTTOMRIGHT",-30,28); scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel",function(_,delta) Sequencer:ScrollBlocks(delta) end); self.blocksScroll=scroll
    local content=CreateFrame("Frame",nil,scroll); content:SetWidth(626); content:SetHeight(1); scroll:SetScrollChild(content); self.blocksContent=content
    self.blocksEmpty=Text(panel,"Enter a supported macro above, then choose Add.","GameFontHighlightSmall",12,COLORS.muted,"CENTER"); self.blocksEmpty:SetPoint("CENTER",0,-8); self.blocksEmpty:SetSize(610,30)
    self.blockCountText=Text(panel,"0 / 50 blocks","GameFontHighlightSmall",10,COLORS.muted); self.blockCountText:SetPoint("BOTTOMLEFT",12,8)
end
function Sequencer:BuildVersions(parent)
    local panel=Panel(parent,690,-92,216,520); self.versionsPanel=panel
    local title=Text(panel,"Versions","GameFontNormal",15,COLORS.gold); title:SetPoint("TOPLEFT",12,-12); self.versionsTitle=title
    local scroll=CreateFrame("ScrollFrame",nil,panel,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",10,-42); scroll:SetPoint("BOTTOMRIGHT",-28,166)
    local content=CreateFrame("Frame",nil,scroll); content:SetWidth(178); content:SetHeight(1); scroll:SetScrollChild(content); self.versionsContent=content
    local new=Button(panel,"New",54,function() Sequencer:AddVersion(false) end); new:SetPoint("BOTTOMLEFT",10,130)
    local rename=Button(panel,"Rename",60,function() Sequencer:RenameVersion() end); rename:SetPoint("BOTTOMLEFT",68,130)
    local duplicate=Button(panel,"Duplicate",72,function() Sequencer:AddVersion(true) end); duplicate:SetPoint("BOTTOMLEFT",132,130)
    local delete=Button(panel,"Delete",60,function() Sequencer:DeleteVersion() end); delete:SetPoint("BOTTOMLEFT",10,100)
    local activate=Button(panel,"Activate Selected",132,function() Sequencer:ActivateVersion() end); activate:SetPoint("BOTTOMRIGHT",-10,100)
    self.versionNewButton=new; self.versionRenameButton=rename; self.versionDuplicateButton=duplicate; self.versionDeleteButton=delete; self.versionActivateButton=activate
    self.versionSummary=Text(panel,"0 / 20 versions\n0 / 50 blocks\nSequential","GameFontHighlightSmall",11,COLORS.muted); self.versionSummary:SetPoint("BOTTOMLEFT",12,16); self.versionSummary:SetSize(190,68)
end
function Sequencer:BuildEditor(frame)
    local view=CreateFrame("Frame",nil,frame); view:SetPoint("TOPLEFT",18,-112); view:SetPoint("BOTTOMRIGHT",-18,16); self.views.editor=view
    local header=Panel(view,0,0,906,82)
    local seqLabel=Text(header,"Sequence","GameFontHighlightSmall",11,COLORS.muted); seqLabel:SetPoint("TOPLEFT",12,-10)
    self.sequenceDropdown=Dropdown(header,175,function() return Sequencer:SequenceOptions() end,function() return Sequencer.selectedSequenceId end,function(value) return Sequencer:RequestSwitch(function() Sequencer:LoadSequence(value) end) end); self.sequenceDropdown:SetPoint("TOPLEFT",12,-34)
    local nameLabel=Text(header,"Sequence Name","GameFontHighlightSmall",11,COLORS.muted); nameLabel:SetPoint("TOPLEFT",200,-10)
    self.sequenceNameBox=EditBox(header,210); self.sequenceNameBox:SetPoint("TOPLEFT",200,-34); self.sequenceNameBox:SetScript("OnTextChanged",function(box) if not Sequencer.loading and Sequencer.draft then Sequencer.draft.name=box:GetText(); Sequencer:MarkDirty() end end)
    local createLabel=Text(header,"Create a Sequence","GameFontHighlightSmall",11,COLORS.muted); createLabel:SetPoint("TOPLEFT",426,-10)
    local new=Button(header,"New",50,function() Sequencer:NewSequence() end); new:SetPoint("TOPLEFT",426,-34)
    local copy=Button(header,"Copy",50,function() Sequencer:DuplicateSequence() end); copy:SetPoint("TOPLEFT",480,-34); self.sequenceCopyButton=copy
    local del=Button(header,"Delete",58,function() Sequencer:DeleteSequence() end); del:SetPoint("TOPLEFT",534,-34); self.sequenceDeleteButton=del
    local bindingPanel=Panel(header,610,-8,286,64,COLORS.bg,COLORS.softBorder or COLORS.border)
    local bindTitle=Text(bindingPanel,"Key / Mouse Binding","GameFontHighlightSmall",11,COLORS.muted,"CENTER"); bindTitle:SetPoint("TOP",0,-6); bindTitle:SetSize(260,16)
    self.bindingValue=Text(bindingPanel,"Unbound","ChatFontNormal",11,COLORS.gold,"CENTER"); self.bindingValue:SetPoint("TOPLEFT",8,-30); self.bindingValue:SetSize(72,22); self.bindingValue:SetJustifyV("MIDDLE")
    local set=Button(bindingPanel,"Set",48,function() Sequencer:StartBindingCapture("sequence") end); set:SetPoint("TOPLEFT",84,-29); self.bindingSetButton=set
    local edit=Button(bindingPanel,"Edit",48,function() Sequencer:StartBindingCapture("sequence") end); edit:SetPoint("TOPLEFT",136,-29); self.bindingEditButton=edit
    local delete=Button(bindingPanel,"Delete",70,function() Sequencer:ClearBinding() end); delete:SetPoint("TOPLEFT",188,-29); self.bindingDeleteButton=delete
    self:BuildMacroEditor(view); self:BuildBlocks(view); self:BuildVersions(view)
    local footer=Panel(view,0,-622,906,62)
    self.footerRuntime=Text(footer,"Runtime: Idle   |   Last Block: -   |   Saved","GameFontHighlightSmall",11,COLORS.muted); self.footerRuntime:SetPoint("TOPLEFT",12,-10); self.footerRuntime:SetSize(590,18)
    local reset=Button(footer,"Reset Sequence",104,function() if Sequencer.draft and not Sequencer.viewOnly then local ok,message=Lib().ResetSequence(Sequencer.draft.id,"editor Reset Sequence"); Sequencer:SetStatus(message,ok and "success" or "error"); Sequencer:RefreshFooter() end end); reset:SetPoint("BOTTOMLEFT",10,8); self.resetSequenceButton=reset
    self.statusText=Text(footer,"Ready.","GameFontHighlightSmall",10,COLORS.yellow); self.statusText:SetPoint("BOTTOMLEFT",122,11); self.statusText:SetSize(570,18)
    local save=Button(footer,"Save Changes",132,function() Sequencer:SaveDraft() end,30); save:SetPoint("RIGHT",-10,0); self.saveChangesButton=save
    self.editorBuilt=true
end
function Sequencer:BuildBindingList(frame)
    local view=FullViewPanel(frame); self.views.binding=view
    local title=Text(view,"Binding List","GameFontNormalLarge",18,COLORS.gold); title:SetPoint("TOPLEFT",20,-18)
    local help=Text(view,"Bindings for your current class and spec. Select a sequence to open it in the Editor.","GameFontHighlightSmall",11,COLORS.muted); help:SetPoint("TOPLEFT",20,-48); help:SetSize(860,18)
    local headings={{"Binding",32,105},{"Sequence",142,250},{"Active Version",412,150},{"Status",570,140}}
    for _,item in ipairs(headings) do local label=Text(view,item[1],"GameFontHighlightSmall",11,COLORS.gold); label:SetPoint("TOPLEFT",item[2],-82); label:SetSize(item[3],18) end
    local scroll=CreateFrame("ScrollFrame",nil,view,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",20,-104); scroll:SetPoint("BOTTOMRIGHT",-34,54)
    local content=CreateFrame("Frame",nil,scroll); content:SetWidth(840); content:SetHeight(1); scroll:SetScrollChild(content); self.bindingListContent=content
    self.bindingEmpty=Text(view,"No sequences exist for this class and specialization.","GameFontHighlightSmall",12,COLORS.muted,"CENTER"); self.bindingEmpty:SetPoint("CENTER",0,20); self.bindingEmpty:SetSize(820,30)
    self.bindingStatus=Text(view,"","GameFontHighlightSmall",11,COLORS.yellow); self.bindingStatus:SetPoint("BOTTOMLEFT",20,20); self.bindingStatus:SetSize(860,20)
end
local function InfoHeading(value) return "|cFFD1C29A"..tostring(value).."|r" end
local function InfoTip() return "|cFF80ADEFKeyLab Tip|r" end
local function InfoList(items) return "- "..table.concat(items,"\n- ") end
local function InfoJoin(parts) return table.concat(parts,"\n\n") end

local INFORMATION_SECTIONS={
    {
        title="1. Welcome to the KeyLab Macro Sequencer",
        body=InfoJoin({
            InfoHeading("What It Does"),
            "Create a complete rotation by arranging individual macros into a sequence. Then bind the sequence to a keyboard key or mouse button.\n\nEach physical press tries one planned block. KeyLab never presses keys, chooses abilities, or decides what is best for you.",
            InfoTip(),
            "KeyLab chooses which saved block to try. World of Warcraft decides whether that block can run.",
        }),
    },
    {
        title="2. One Press, One Step",
        body=InfoJoin({
            "Each full keyboard or mouse-button press moves the sequence forward by one step.\n\nThis works whether WoW casts on key-down or key-up. Only the active part of the press can run the block. The other part is ignored.\n\nHolding a key does not create more presses. Every step needs a new physical press.",
            InfoHeading("Important"),
            "A step is used when KeyLab tries it, even if the action cannot run because of:\n"..InfoList({
                "The Global Cooldown",
                "A cooldown",
                "Not enough resources",
                "The wrong target",
                "Range or line of sight",
                "A missing item",
                "Another WoW rule",
            }).."\n\nKeyLab does not check the result, retry the block, or choose a different action.",
        }),
    },
    {
        title="3. Sequence Blocks",
        body=InfoJoin({
            "A sequence contains one or more macro blocks. Each block may contain several supported WoW macro lines, up to 255 characters total.",
            InfoHeading("Example"),
            "/startattack\n/petattack\n/autoshot\n/cast [mod:ctrl,@player] Binding Shot; [@target] Kill Command",
            "One press tries the whole selected block. WoW checks its commands, conditions, targets, cooldowns, and other rules.\n\nUse the arrows to move a block. Turn off Enabled to keep a block saved without using it.\n\nThe Sequence menu also includes read-only examples. You can study them, but you cannot edit, bind, save, activate, or run them.",
        }),
    },
    {
        title="4. Sequence Modes",
        body=InfoJoin({
            InfoHeading("Sequential"),
            "Tries each enabled block in order, then starts again.\n\n1 -> 2 -> 3 -> 4 -> 1\n\nThis is the simplest and most predictable mode.",
            InfoHeading("Priority"),
            "Returns to earlier blocks more often as it moves through the sequence. Put actions you want tried more often near the beginning.\n\nLong Priority sequences may feel repetitive.",
            InfoHeading("Reverse Priority"),
            "Works in the opposite direction and returns to later blocks more often.",
            InfoTip(),
            "Start with Sequential. If you use Priority or Reverse Priority, begin with a few blocks and add more only if the sequence still feels smooth.",
        }),
    },
    {
        title="5. Versions",
        body=InfoJoin({
            "Create named versions for different situations, such as:\n"..InfoList({
                "Mythic+",
                "Raid",
                "Delves",
                "PvP",
                "Single Target",
                "Multi-Target",
            }),
            "Only one version is active at a time. You must change it yourself while out of combat.\n\nThe binding belongs to the sequence, so changing versions does not change its key or mouse button.\n\nPractice Sessions save the sequence and active version used during the test.",
        }),
    },
    {
        title="6. Key and Mouse Bindings",
        body=InfoJoin({
            "Each sequence may have one keyboard or mouse-button binding.\n\nThe Binding List shows:\n"..InfoList({
                "Binding",
                "Sequence",
                "Active version",
                "Status",
            }),
            "Bindings are saved for your current class and spec. One binding cannot control two KeyLab sequences for the same class and spec.\n\nSequence names must also be unique for that class and spec.\n\nUse Set to add a binding, Edit to change it, or Delete to remove it.",
        }),
    },
    {
        title="7. Macro Conditions",
        body=InfoJoin({
            "WoW macro conditions can change what a block tries.",
            InfoHeading("Example"),
            "/cast [mod:ctrl,@player] Binding Shot; [@target] Kill Command",
            "Hold Ctrl to try Binding Shot at your location. Without Ctrl, the macro tries Kill Command on your target.\n\nCommon modifiers:\n\n[mod:ctrl]\n[mod:shift]\n[mod:alt]\n\nWoW reads all targets and conditions. If a combination is not valid, it will not run.",
        }),
    },
    {
        title="8. Action, Nil",
        body=InfoJoin({
            "WoW can use /castsequence, reset=target, and nil to try an action once for each selected target.",
            InfoHeading("Example"),
            "/castsequence reset=target Hunter's Mark, nil",
            "The macro tries Hunter's Mark once, then reaches nil. When WoW detects a new selected target, it resets the cast sequence.\n\nWoW—not KeyLab—tracks the target and controls this reset.",
        }),
    },
    {
        title="9. Global Cooldown and Spell Queue",
        body=InfoJoin({
            "KeyLab does not add its own Global Cooldown, delay, timer, click rate, or Spell Queue Window.\n\nWoW decides:\n"..InfoList({
                "When the Global Cooldown starts and ends",
                "Whether an ability is ready",
                "Whether a spell enters the spell queue",
                "Whether the action runs",
            }),
            "Pressing faster cannot bypass these rules. It can move past blocks while their actions are unavailable.",
            InfoTip(),
            "A steady rhythm near your Global Cooldown is usually easier to follow than pressing as fast as possible.",
        }),
    },
    {
        title="10. Changes During Combat",
        body=InfoJoin({
            "Your saved sequence can run in combat, but WoW does not allow protected setup changes during combat.\n\nWhile in combat, you cannot:\n"..InfoList({
                "Open the Sequencer Editor",
                "Add, edit, delete, turn on, turn off, or move blocks",
                "Change the sequence mode",
                "Activate another version",
                "Add or change a binding",
                "Save protected sequence changes",
            }),
            "Leave combat to make these changes.",
        }),
    },
    {
        title="11. Supported Use",
        body=InfoJoin({
            "The KeyLab Macro Sequencer is made for normal WoW macro commands and conditions.\n\nIt does not provide:\n"..InfoList({
                "Automatic key presses",
                "Timed casting",
                "Cooldown or resource decisions",
                "Proc or aura checks",
                "Automatic rotation choices",
                "Automatic content switching",
                "Input broadcasting",
                "Sequence importing, exporting, or sharing",
                "Lua or script execution",
            }),
            "/run, /script, /dump, and /click are not supported.\n\nEvery action needs a direct player press. WoW always decides whether it can run.",
        }),
    },
    {
        title="12. Recycle Bin",
        body=InfoJoin({
            "Deleted sequences and versions stay in the Recycle Bin for 30 days.\n\nYou can restore them during that time. A restored sequence still needs a unique name. You may also need to set its binding again if that binding is now in use.\n\nAfter 30 days, the deleted item is removed for good.",
        }),
    },
}

function Sequencer:BuildInformation(frame)
    local view=FullViewPanel(frame); self.views.information=view
    local header=Panel(view,14,-14,878,68,COLORS.panel,COLORS.border)
    local title=Text(header,"KeyLab Macro Sequencer","GameFontNormalLarge",18,COLORS.gold); title:SetPoint("TOPLEFT",16,-10); title:SetSize(500,24)
    local subtitle=Text(header,"One press moves one step. World of Warcraft always decides what can cast.","GameFontHighlightSmall",12,COLORS.muted); subtitle:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-6); subtitle:SetSize(840,22)
    local scroll=CreateFrame("ScrollFrame",nil,view,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",18,-98); scroll:SetPoint("BOTTOMRIGHT",-30,18)
    local content=CreateFrame("Frame",nil,scroll); content:SetSize(840,520); scroll:SetScrollChild(content)
    local accordionColors={
        panel=COLORS.panel,
        body=COLORS.card or COLORS.buttonBg or COLORS.panel,
        border=COLORS.border,
        hover=COLORS.gold,
        hoverBg=BUTTON_HOVER_BG,
        gold=COLORS.gold,
        text=COLORS.text,
    }
    self.informationAccordion=KeyLab.UI.Accordion.Create(content,{
        sections=INFORMATION_SECTIONS,
        colors=accordionColors,
        width=830,
        left=4,
        minHeight=520,
        pixelSnap=true,
        joinBody=true,
    })
    self.informationContent=content
end
function Sequencer:BuildRecycleBin(frame)
    local view=FullViewPanel(frame); self.views.recycle=view
    local title=Text(view,"Recycle Bin","GameFontNormalLarge",18,COLORS.gold); title:SetPoint("TOPLEFT",20,-18)
    local help=Text(view,"Deleted sequences and versions stay here for 30 days. If an old binding is already in use, the restored sequence stays unbound.","GameFontHighlightSmall",12,COLORS.muted); help:SetPoint("TOPLEFT",20,-48); help:SetSize(860,34)
    self.recycleRows={}
    for index=1,8 do
        local row=Panel(view,20,-88-((index-1)*64),866,56)
        row:SetFrameLevel(view:GetFrameLevel()+2)
        row.name=Text(row,"","GameFontNormal",nil,COLORS.text); row.name:SetPoint("TOPLEFT",12,-9); row.name:SetSize(520,18)
        row.days=Text(row,"","GameFontHighlightSmall",11,COLORS.muted); row.days:SetPoint("TOPLEFT",12,-31)
        local restore=Button(row,"Restore",76,function(button)
            local entry=button.recycleEntry
            if entry then Sequencer:AttemptRestore(entry) else Sequencer:SetStatus("That Recycle Bin item is no longer available.","error") end
        end); restore:SetPoint("TOPRIGHT",-116,-16); restore:SetFrameLevel(row:GetFrameLevel()+3)
        local remove=Button(row,"Delete Forever",104,function(button)
            local entry=button.recycleEntry
            if not entry then Sequencer:SetStatus("That Recycle Bin item is no longer available.","error"); return end
            local deletedID,deletedName=entry.id,entry.name
            Confirm("KEYLAB_RECYCLE_DELETE","Permanently delete "..tostring(deletedName).."? This cannot be undone.",function()
                local ok,message=Lib().PermanentlyDelete(deletedID)
                Sequencer:SetStatus(message,ok and "success" or "error"); Sequencer:RefreshRecycleBin()
            end)
        end); remove:SetPoint("TOPRIGHT",-6,-16); remove:SetFrameLevel(row:GetFrameLevel()+3)
        self.recycleRows[index]={frame=row,name=row.name,days=row.days,restoreButton=restore,deleteButton=remove,entry=nil}
    end
    self.recycleEmpty=Text(view,"Nothing has been deleted for this class and specialization.","GameFontHighlightSmall",13,COLORS.muted,"CENTER"); self.recycleEmpty:SetPoint("TOP",0,-130); self.recycleEmpty:SetSize(860,30)
    local prev=Button(view,"Previous",80,function() Sequencer.recyclePage=math.max(1,(Sequencer.recyclePage or 1)-1); Sequencer:RefreshRecycleBin() end); prev:SetPoint("BOTTOMLEFT",20,18)
    local nextButton=Button(view,"Next",80,function() Sequencer.recyclePage=(Sequencer.recyclePage or 1)+1; Sequencer:RefreshRecycleBin() end); nextButton:SetPoint("BOTTOMLEFT",104,18)
    self.recyclePageText=Text(view,"Page 1 / 1","GameFontHighlightSmall",11,COLORS.muted); self.recyclePageText:SetPoint("BOTTOMLEFT",198,23)
    self.recycleStatus=Text(view,"","GameFontHighlightSmall",11,COLORS.yellow); self.recycleStatus:SetPoint("BOTTOMLEFT",390,23); self.recycleStatus:SetSize(490,18)
end

function Sequencer:Refresh()
    if not self.draft and not self:HasUnsavedChanges() then self:LoadSequence(self.selectedSequenceId) else self:RefreshEditor() end
    if self.selectedView=="binding" then self:RefreshBindingList() elseif self.selectedView=="recycle" then self:RefreshRecycleBin() end
end
function Sequencer:Create(parent)
    local frame=CreateFrame("Frame","KeyLabSequencerTab",parent,"BackdropTemplate"); frame:SetAllPoints(parent)
    if Theme.StylePanel then Theme.StylePanel(frame,COLORS.bg,{0,0,0,0}) end
    self.frame=frame; self.views={}; self.selectedView="editor"
    Theme.CreateTabHeader(
        frame,
        "Macro Sequencer",
        "Build class and spec Macro Sequences from the exact macro blocks you want to use."
    )
    self:BuildTop(frame); self:BuildEditor(frame); self:BuildBindingList(frame); self:BuildInformation(frame); self:BuildRecycleBin(frame)
    self:LoadSequence(nil); self:SetView("editor")
    frame.Refresh=function() Sequencer:Refresh() end
    frame:SetScript("OnShow",function() Sequencer:Refresh() end)
    frame:SetScript("OnHide",function() if Sequencer.captureOverlay then Sequencer.captureOverlay:EnableKeyboard(false); Sequencer.captureOverlay:Hide() end end)
    return frame
end

if KeyLab.RegisterTab then KeyLab.RegisterTab("Sequencer",function(parent) return Sequencer:Create(parent) end) end

return Sequencer
