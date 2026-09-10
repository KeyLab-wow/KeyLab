local _, KeyLab = ...
local UI = {}
KeyLab.UI.GuideRecommendations = UI
local Theme, Guides, Talents = KeyLab.UI.Theme, KeyLab.GuideRecommendations, KeyLab.GuideTalents
local C = Theme.colors
local function Text(parent,value,size,color)
    return Theme.CreateText(parent,value,"GameFontHighlight",size or 12,color or C.text)
end
local function SetBadge(badge,value,color)
    color=color or C.blue
    Theme.SetBadge(badge,value,C.badgeBg or C.panel,C.transparent,color)
    -- Solid theme rules avoid the backdrop edge texture dropping a thin edge
    -- on lower scroll rows at fractional UI coordinates. Keep this local.
    badge.edgeRules=badge.edgeRules or {}
    for _,edge in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
        local rule=badge.edgeRules[edge]
        if not rule then
            rule=Theme.CreateRule(badge,edge,color,1)
            badge.edgeRules[edge]=rule
        end
        rule:SetColorTexture(unpack(color))
    end
end
local function SizeBadgeEdges(badge)
    local scale=badge:GetEffectiveScale() or 1
    local thickness=math.max(1,1/math.max(0.01,scale))
    badge.edgeRules.TOP:SetHeight(thickness); badge.edgeRules.BOTTOM:SetHeight(thickness)
    badge.edgeRules.LEFT:SetWidth(thickness); badge.edgeRules.RIGHT:SetWidth(thickness)
end
local function FitBadgeToText(badge,minWidth,maxWidth)
    if not badge then return end
    local measured=badge.text and badge.text.GetStringWidth and badge.text:GetStringWidth() or 0
    if measured<=0 and badge.text and badge.text.GetText then measured=#tostring(badge.text:GetText() or "")*7 end
    badge:SetWidth(math.max(minWidth or 56,math.min(maxWidth or 190,math.ceil(measured+24))))
    SizeBadgeEdges(badge)
end
local function Badge(parent,value,width,color)
    local badge=Theme.CreateBadge(parent,value,width,23)
    SetBadge(badge,value,color)
    return badge
end
local function SetCraftControlState(button,planned,recipe)
    if not button then return end
    local function ApplyAddedStyle(self)
        self:SetBackdropColor(C.green[1]*0.16,C.green[2]*0.16,C.green[3]*0.16,0.92)
        self:SetBackdropBorderColor(unpack(C.green))
        Theme.ApplyColor(self.label,C.green)
    end
    if not button.guideCraftStatusHooks then
        button.guideCraftStatusHooks=true
        button:HookScript("OnEnter",function(self) if self.addedToPlan then ApplyAddedStyle(self) end end)
        button:HookScript("OnLeave",function(self) if self.addedToPlan then ApplyAddedStyle(self) end end)
    end
    button.addedToPlan=planned==true
    button:SetWidth(planned and 108 or (recipe and 118 or 145))
    button:SetText(planned and "Added to Plan" or (recipe and "Configure Craft" or "Not in Crafted Plans"))
    button:SetEnabled(recipe~=nil and not planned)
    if planned then ApplyAddedStyle(button) end
end
local function Item(parent,id,name,x,y,width,fontSize)
    local button=CreateFrame("Button",nil,parent)
    button:SetPoint("TOPLEFT",x,y); button:SetSize(width,22)
    button.icon=button:CreateTexture(nil,"ARTWORK"); button.icon:SetSize(20,20); button.icon:SetPoint("LEFT",0,0)
    button.text=Text(button,name,fontSize or 13,C.text); button.text:SetPoint("LEFT",button.icon,"RIGHT",8,0); button.text:SetSize(width-36,22)
    button.text:SetJustifyV("MIDDLE")
    button.text:SetWordWrap(false)
    button:SetScript("OnEnter",function()
        if not GameTooltip or not id then return end
        local item=Guides.GetItem(id)
        local recipe=Guides.GetRecipe(id)
        local link=item and (item.link or item.itemLink) or recipe and recipe.itemLink
        GameTooltip:SetOwner(button,"ANCHOR_RIGHT")
        if link then GameTooltip:SetHyperlink(link)
        elseif GameTooltip.SetItemByID then GameTooltip:SetItemByID(id)
        else GameTooltip:SetHyperlink("item:"..id) end
        if item and item.guideSupplemental then GameTooltip:AddLine("BoE Trash Drop - captured max-level link unavailable.",1,0.8,0.3,true) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    local function icon()
        local item=Guides.GetItem(id)
        button.icon:SetTexture(item and item.icon or C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id) or 134400)
    end
    icon()
    if id and Item and _G.Item and _G.Item.CreateFromItemID then
        local obj=_G.Item:CreateFromItemID(id)
        if obj and obj.ContinueOnItemLoad then obj:ContinueOnItemLoad(icon) end
    end
    return button
end

local function RecordUpdateDate(record)
    local latest
    for _, build in ipairs(record and record.talents or {}) do
        local value=tostring(build.date or "")
        if value~="" and (not latest or value>latest) then latest=value end
    end
    return latest or "Not recorded"
end

local SLOT_COLUMNS = {
    {"Head","Neck","Shoulders","Back","Chest","Wrist","Main Hand","Off Hand"},
    {"Hands","Waist","Legs","Feet","Finger 1","Finger 2","Trinket 1","Trinket 2"},
}
local function Hover(frame,title,body)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter",function()
        if not GameTooltip then return end
        GameTooltip:SetOwner(frame,"ANCHOR_RIGHT")
        GameTooltip:AddLine(title,1,1,1,true)
        if body and body~="" then GameTooltip:AddLine(body,0.8,0.85,1,true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end

function UI.Create(parent,source)
    local view=CreateFrame("Frame",nil,parent)
    view:SetAllPoints(parent); view.source=source; view.pages={}; view.mode="talents"
    view.active=Text(view,"",15,C.gold)
    view.active:SetPoint("TOPLEFT",12,-8); view.active:SetPoint("RIGHT",-290,0); view.active:SetHeight(24)
    view.updated=Text(view,"",11,C.blue)
    view.updated:SetPoint("TOPRIGHT",-12,-8); view.updated:SetSize(266,24); view.updated:SetJustifyH("RIGHT")
    view.message=Text(view,"Add saves; Update replaces; Switch activates. Green Added means a confirmed Add or Update.",11,C.muted)
    view.message:SetPoint("TOPLEFT",12,-36); view.message:SetPoint("RIGHT",-12,0); view.message:SetHeight(32)
    view.talentTab=Theme.CreateTextTabButton(view,"Talent Builds",150,28); view.talentTab:SetPoint("TOPLEFT",12,-72)
    view.gearTab=Theme.CreateTextTabButton(view,"Gear Lists",150,28); view.gearTab:SetPoint("LEFT",view.talentTab,"RIGHT",8,0)
    view.scroll=Theme.CreateScrollArea(view,{step=48})
    view.scroll:SetPoint("TOPLEFT",0,-110); view.scroll:SetPoint("BOTTOMRIGHT",0,0)
    function view:SetMode(mode)
        self.mode=mode; self:Layout(); self.scroll:ScrollToTop()
    end
    view.talentTab:SetScript("OnClick",function() view:SetMode("talents") end)
    view.gearTab:SetScript("OnClick",function() view:SetMode("gear") end)

    function view:BuildPage(record)
        local page=CreateFrame("Frame",nil,self.scroll.content)
        page:SetPoint("TOPLEFT",0,0); page:SetPoint("TOPRIGHT",0,0)
        page.record=record; page.talentRows={}; page.profiles={}
        page.talents=CreateFrame("Frame",nil,page); page.talents:SetAllPoints(page)
        page.gear=CreateFrame("Frame",nil,page); page.gear:SetAllPoints(page)
        for buildIndex,build in ipairs(record.talents) do
            local selector=Theme.CreateTextTabButton(page.talents,build.name,180,30,{fontSize=11})
            selector.buildIndex=buildIndex
            selector:SetScript("OnClick",function()
                page.selectedTalent=buildIndex; self:Layout(); self.scroll:ScrollToTop()
            end)
            local row=CreateFrame("Frame",nil,page.talents,"BackdropTemplate")
            Theme.StylePanel(row,C.panel,C.border); Theme.CreateRule(row,"TOP",C.border,1)
            row:SetHeight(132)
            local name=Text(row,build.savedName,14,C.text)
            name:SetPoint("TOPLEFT",10,-6); name:SetPoint("RIGHT",-10,0); name:SetHeight(32)
            local saved=Text(row,build.name,11,C.muted)
            saved:SetPoint("TOPLEFT",10,-39); saved:SetPoint("RIGHT",-10,0); saved:SetHeight(16)
            row.label=Badge(row,build.label,80,build.recommended and C.gold or C.blue); row.label:SetPoint("TOPLEFT",10,-58)
            row.state=Badge(row,"Not Added",96,C.muted); row.state:SetPoint("LEFT",row.label,"RIGHT",8,0)
            row.add=Theme.CreateButton(row,"Add",70,26); row.add:SetPoint("BOTTOMLEFT",10,10)
            row.update=Theme.CreateButton(row,"Update",76,26); row.update:SetPoint("LEFT",row.add,"RIGHT",6,0)
            row.switch=Theme.CreateButton(row,"Switch",76,26); row.switch:SetPoint("LEFT",row.update,"RIGHT",6,0)
            row.add:SetScript("OnClick",function() Talents.Save(build,false) end)
            row.update:SetScript("OnClick",function() Talents.Save(build,true) end)
            row.switch:SetScript("OnClick",function() local s=Talents.GetState(build); if s.id then Talents.Switch(s.id) end end)
            Hover(row.label,build.label,build.note)
            row.build=build; row.selector=selector; page.talentRows[#page.talentRows+1]=row
        end
        page.selector=Theme.CreateLegacyDropdown(page.gear)
        page.selector:SetPoint("TOPLEFT",-4,0)
        page.selector.initialize=function(_,level)
            for index,section in ipairs(page.profiles) do
                local info=UIDropDownMenu_CreateInfo()
                info.text=section.profile.name; info.checked=page.selectedProfile==index
                info.func=function()
                    page.selectedProfile=index; self:Layout(); self.scroll:ScrollToTop()
                end
                UIDropDownMenu_AddButton(info,level)
            end
        end
        page.apply=Theme.CreateButton(page.gear,"Set Gear Targets",166,28)
        page.apply:SetPoint("TOPRIGHT",-12,-8); Theme.StylePrimaryActionButton(page.apply)
        page.apply:SetScript("OnClick",function()
            local section=page.profiles[page.selectedProfile]
            if not section then return end
            local choices={}
            for slot,value in pairs(section.choices) do choices[slot]=value end
            KeyLab.UI.RunPlanChange(record.specID,function(approval)
                return Guides.ApplyProfile(record,section.profile,choices,approval)
            end,function(ok,message)
                section.statusMessage=message; section.statusOK=ok
                self:Layout()
            end)
        end)
        page.gearIntro=Text(page.gear,"Replaces this spec's Targets; Alternatives stay. No Undo. Add crafted items separately. Catalyst rows show the original item and the Tier item it creates; only four core Tier pieces are needed.",12,C.muted)
        page.gearIntro:SetPoint("TOPLEFT",12,-43); page.gearIntro:SetPoint("RIGHT",-12,0); page.gearIntro:SetHeight(34)
        page.status=Text(page.gear,"",12,C.blue); page.status:SetPoint("TOPLEFT",12,-80); page.status:SetPoint("RIGHT",-12,0); page.status:SetHeight(32)
        for _,profile in ipairs(record.profiles) do
            local section={profile=profile,choices={},slots={}}
            section.body=CreateFrame("Frame",nil,page.gear)
            section.body:SetPoint("TOPLEFT",0,-116); section.body:SetPoint("RIGHT",0,0)
            local grouped={}
            for index,data in ipairs(profile.items) do
                grouped[data.slot]=grouped[data.slot] or {}
                table.insert(grouped[data.slot],{data=data,index=index})
            end
            for _,column in ipairs(SLOT_COLUMNS) do
                for _,slotName in ipairs(column) do
                    local slot=CreateFrame("Frame",nil,section.body,"BackdropTemplate")
                    Theme.StylePanel(slot,C.panel,C.border); Theme.CreateRule(slot,"TOP",C.border,1)
                    slot.title=Text(slot,slotName,12,C.gold); slot.title:Hide()
                    slot.rows={}; section.slots[slotName]=slot
                    for _,entry in ipairs(grouped[slotName] or {}) do
                        local data,index=entry.data,entry.index
                        local row=CreateFrame("Frame",nil,slot)
                        row.data=data; row.index=index
                        local original=data.originalID and data.originalID~=data.itemID and Guides.GetItem(data.originalID,record.specID)
                        local hasOriginal=data.originalID and data.originalID~=data.itemID
                        local primaryName=original and original.name or (hasOriginal and "Original item - needs review" or data.name)
                        row.primary=Item(row,hasOriginal and data.originalID or data.itemID,slotName.." - "..primaryName,8,0,350,13)
                        if hasOriginal then row.secondary=Item(row,data.itemID,"Use Catalyst to create: "..data.name,8,-21,350,11) end
                        row.source=Text(row,(data.native and "Native Tier - " or "")..(original and (original.displaySourceName or original.sourceName) or data.source),10,C.blue)
                        row.source:SetPoint("TOPLEFT",8,hasOriginal and -43 or -22); row.source:SetPoint("RIGHT",-8,0); row.source:SetHeight(15)
                        row.height=hasOriginal and 62 or 44
                        if data.note then Hover(row,data.name,data.note) end
                        if Guides.IsCrafted(data) then
                            local recipe=Guides.GetRecipe(data.itemID)
                            row.recipe=recipe
                            local planned=recipe and KeyLab.CraftedPlansDB and KeyLab.CraftedPlansDB.IsPlanned
                                and KeyLab.CraftedPlansDB.IsPlanned(recipe.recipeID,record.specID)
                            row.craft=Theme.CreateButton(row,"Configure Craft",118,20)
                            row.craft:SetPoint("TOPRIGHT",-8,-22)
                            SetCraftControlState(row.craft,planned,recipe)
                            row.source:SetPoint("RIGHT",row.craft,"LEFT",-8,0)
                            row.craft:SetScript("OnClick",function()
                                if record.specID~=Guides.CurrentSpec() then self:Refresh(); return end
                                KeyLab.Tabs.GearPlanning:OpenGuideCraft(recipe.recipeID,record.specID,source)
                            end)
                        end
                        if #grouped[slotName]>1 then
                            row.choose=Theme.CreateButton(row,"Use this item",108,20); row.choose:SetPoint("TOPLEFT",8,-row.height)
                            row.height=row.height+22
                            row.choose:SetScript("OnClick",function()
                                section.choices[data.slot]=index
                                for _,r in ipairs(slot.rows) do if r.choose then r.choose:SetText(section.choices[data.slot]==r.index and "Selected" or "Use this item") end end
                            end)
                        end
                        slot.rows[#slot.rows+1]=row
                    end
                    if #slot.rows==0 then
                        slot.empty=Text(slot,slotName.." - Not listed in this profile",11,C.muted); slot.empty:SetPoint("TOPLEFT",8,-6); slot.empty:SetHeight(18)
                    end
                end
            end
            page.profiles[#page.profiles+1]=section
        end
        page.selectedTalent=1; page.selectedProfile=1
        return page
    end
    function view:Layout()
        local page=self.page
        if not page then return end
        local width=math.max(600,self.scroll.content:GetWidth() or 900)
        local gear=self.mode=="gear"
        page.gear:SetShown(gear); page.talents:SetShown(not gear)
        self.talentTab:SetSelected(not gear); self.gearTab:SetSelected(gear)
        local height
        if not gear then
            -- Match the sectioned Home readers: choose one clearly named topic,
            -- then read only that recommendation below it.
            local columns=width>=820 and 3 or 2
            local cellWidth=(width-24-(columns-1)*8)/columns
            local selectorRows=math.max(1,math.ceil(#page.talentRows/columns))
            local detailY=(selectorRows*36)+10
            for index,row in ipairs(page.talentRows) do
                row.selector:ClearAllPoints()
                row.selector:SetPoint("TOPLEFT",12+((index-1)%columns)*(cellWidth+8),-math.floor((index-1)/columns)*36)
                row.selector:SetWidth(cellWidth); row.selector:SetSelected(index==page.selectedTalent)
                local selected=index==page.selectedTalent
                row:SetShown(selected)
                if selected then
                    row:ClearAllPoints(); row:SetPoint("TOPLEFT",12,-detailY); row:SetPoint("TOPRIGHT",-12,-detailY); row:SetHeight(132)
                end
                FitBadgeToText(row.label,56,170)
                FitBadgeToText(row.state,72,190)
            end
            height=detailY+140
        else
            page.selector:SetKeyLabWidth(math.max(250,width-220))
            local selected=page.profiles[page.selectedProfile]
            page.selector:SetDisplayText(selected and selected.profile.name or "No gear profiles")
            page.apply:SetEnabled(selected~=nil and not (InCombatLockdown and InCombatLockdown()))
            page.status:SetText(selected and selected.statusMessage or "Hover either item icon for its tooltip. Configure Craft opens your crafting plan.")
            page.status:SetTextColor(unpack(selected and selected.statusMessage and (selected.statusOK and C.green or C.gold) or C.muted))
            local cellWidth=(width-34)/2
            height=116
            for _,section in ipairs(page.profiles) do
                local shown=section==selected; section.body:SetShown(shown)
                if shown then
                    local maxHeight=0
                    for col,column in ipairs(SLOT_COLUMNS) do
                        local y=0
                        for _,slotName in ipairs(column) do
                            local slot=section.slots[slotName]
                            slot:ClearAllPoints(); slot:SetPoint("TOPLEFT",12+(col-1)*(cellWidth+10),-y); slot:SetWidth(cellWidth)
                            local rowY=4
                            for _,row in ipairs(slot.rows) do
                                row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-rowY); row:SetWidth(cellWidth); row:SetHeight(row.height)
                                for _,item in ipairs({row.primary,row.secondary}) do item:SetWidth(cellWidth-16); item.text:SetWidth(cellWidth-52) end
                                rowY=rowY+row.height
                            end
                            local slotHeight=math.max(32,rowY+2); slot:SetHeight(slotHeight)
                            y=y+slotHeight+4
                        end
                        maxHeight=math.max(maxHeight,y)
                    end
                    section.body:SetHeight(maxHeight)
                    height=height+maxHeight
                end
            end
        end
        page:SetHeight(height+8); self.scroll:SetContentHeight(height+8)
    end
    function view:Refresh()
        if not self:IsShown() then return end
        local record=Guides.GetRecord(source)
        if not record then
            if self.page then self.page:Hide() end
            self.page=nil; self.active:SetText("No recommendations for this specialization."); return
        end
        if self.page then self.page:Hide() end
        self.pages[record.specID]=self.pages[record.specID] or self:BuildPage(record)
        local changed=self.page~=self.pages[record.specID]
        self.page=self.pages[record.specID]; self.page:Show()
        self.active:SetText(record.source.." - "..record.specName.."  |  Current build: "..Talents.GetActiveName())
        self.updated:SetText("Last Guide Update: "..RecordUpdateDate(record))
        self.message:SetText(Talents.message~="" and Talents.message or "Add saves; Update replaces; Switch activates. Green Added means a confirmed Add or Update.")
        local can=Talents.CanAct()
        for _,row in ipairs(self.page.talentRows) do
            local state=Talents.GetState(row.build)
            local color=state.update and C.gold or state.added and C.green or C.muted
            SetBadge(row.state,state.label,color)
            if state.existing and not state.update then
                Hover(row.state,"Matching Build Found","Existing loadout: "..state.name.."\n\nThis loadout already has the same talent choices. KeyLab has not added a separate copy of this recommendation.\n\nAdd links this recommendation to that loadout without duplicating it. Switch uses the existing loadout.")
            else
                row.state:EnableMouse(false)
                row.state:SetScript("OnEnter",nil); row.state:SetScript("OnLeave",nil)
            end
            row.add:SetEnabled(can and not state.added and not state.update and not state.conflict)
            row.update:SetEnabled(can and state.update==true)
            row.switch:SetEnabled(can and state.id~=nil)
        end
        for _,section in ipairs(self.page.profiles or {}) do
            for _,slot in pairs(section.slots or {}) do
                for _,row in ipairs(slot.rows or {}) do
                    if row.craft then
                        local planned=row.recipe and KeyLab.CraftedPlansDB and KeyLab.CraftedPlansDB.IsPlanned
                            and KeyLab.CraftedPlansDB.IsPlanned(row.recipe.recipeID,record.specID)
                        SetCraftControlState(row.craft,planned,row.recipe)
                    end
                end
            end
        end
        self:Layout()
        if changed then self.scroll:ScrollToTop() end
    end
    view:SetScript("OnShow",function() view:Refresh() end)
    view:SetScript("OnHide",function() if view.page then view.page.selector.menu:Hide() end end)
    view.scroll.viewport:HookScript("OnSizeChanged",function() if view:IsShown() then view:Layout() end end)
    Talents.Listen(function() view:Refresh() end)
    return view
end
