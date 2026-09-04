local _, KeyLab = ...
local Talents = {listeners={}, message=""}
KeyLab.GuideTalents = Talents
local signatureCache = {}

local function Safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value, detail = pcall(fn, ...)
    if ok and not (issecretvalue and issecretvalue(value)) then return value, detail end
end
local function Spec() return KeyLab.LootTargetsDB.GetCurrentSpecID() end
local function Store(specID)
    KeyLabDB = KeyLabDB or {}
    KeyLabDB.guideTalents = KeyLabDB.guideTalents or {}
    local key = KeyLab.LootTargetsDB.GetCurrentCharacterKey()
    KeyLabDB.guideTalents[key] = KeyLabDB.guideTalents[key] or {}
    local root = KeyLabDB.guideTalents[key]
    root[specID or Spec()] = root[specID or Spec()] or {managed={}}
    return root[specID or Spec()]
end
function Talents.Notify(message)
    if message then Talents.message = message end
    for _, callback in ipairs(Talents.listeners) do pcall(callback) end
end
function Talents.Listen(callback) table.insert(Talents.listeners,callback) end

function Talents.IsKeyActive()
    local active = C_ChallengeMode and Safe(C_ChallengeMode.IsChallengeModeActive)
    if active ~= nil then return active == true end
    local mapID = C_ChallengeMode and Safe(C_ChallengeMode.GetActiveChallengeMapID)
    if type(mapID)=="number" and mapID>0 then return true end
    return Talents.challengeActive == true
end
function Talents.CanAct()
    if InCombatLockdown and InCombatLockdown() then return false,"Unavailable during combat." end
    if Talents.IsKeyActive() then return false,"Talent changes are locked while a Mythic+ key is active." end
    if Talents.pendingSwitch then return false,"Waiting for the talent switch to finish." end
    if C_ClassTalents and C_ClassTalents.CanEditTalents then
        local allowed, reason = Safe(C_ClassTalents.CanEditTalents)
        if allowed ~= true then return false, reason or "Talents cannot be changed right now." end
    end
    return C_ClassTalents ~= nil, "Talent system unavailable."
end

local function Parser()
    if not ClassTalentImportExportMixin or not ExportUtil then
        local loader = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
        Safe(loader,"Blizzard_PlayerSpells")
    end
    if not ClassTalentImportExportMixin or not ExportUtil then return nil end
    return setmetatable({}, {__index=ClassTalentImportExportMixin})
end

-- Use Blizzard's version/spec checks and parser. Do not copy a hand-coded
-- talent bit layout or mistake the optional tree hash for a build change.
function Talents.Decode(code, specID)
    local parser = Parser()
    if not parser then return nil,"Blizzard's talent importer is not available." end
    local ok, entries, signature = pcall(function()
        local stream = ExportUtil.MakeImportDataStream(code)
        local valid, version, codeSpec, hash = parser:ReadLoadoutHeader(stream)
        assert(valid and codeSpec == specID,"This talent string is not for the current specialization.")
        assert(version == C_Traits.GetLoadoutSerializationVersion(),"This talent string uses an older format.")
        local treeID = C_ClassTalents.GetTraitTreeForSpec(specID)
        assert(treeID,"Talent tree is not available yet.")
        assert(parser:IsHashEmpty(hash) or parser:HashEquals(hash,C_Traits.GetTreeHash(treeID)),"This build needs an updated talent string.")
        local content = parser:ReadLoadoutContent(stream,treeID)
        local imported = parser:ConvertToImportLoadoutEntryInfo(C_ClassTalents.GetActiveConfigID(),treeID,content)
        assert(#imported > 0,"This talent string contains no purchased talents.")
        local parts = {}
        for index, node in ipairs(content) do
            -- ReadLoadoutContent returns selected/granted, NOT isNodePurchased.
            if node.isNodeSelected and not node.isNodeGranted then
                parts[#parts+1] = table.concat({index,node.isPartiallyRanked and node.partialRanksPurchased or "full",node.isChoiceNode and node.choiceNodeSelection or 0},":")
            end
        end
        assert(#parts > 0,"This talent string contains no purchased talents.")
        return imported,table.concat(parts,";")
    end)
    if not ok then return nil,tostring(entries) end
    return entries,signature
end
local function Signature(code, specID)
    if type(code) ~= "string" then return nil end
    local key = tostring(specID)..":"..code
    if signatureCache[key] then return signatureCache[key] end
    local entries, signature = Talents.Decode(code,specID)
    if entries then signatureCache[key]=signature; return signature end
end
function Talents.GetLoadouts()
    local list = {}
    if not C_ClassTalents or not C_Traits then return list end
    for _, id in ipairs(Safe(C_ClassTalents.GetConfigIDsBySpecID,Spec()) or {}) do
        local info = Safe(C_Traits.GetConfigInfo,id)
        if info and type(info.name)=="string" and not info.name:find("^KL%-stage%-") then
            list[#list+1]={id=id,name=info.name,code=Safe(C_Traits.GenerateImportString,id)}
        end
    end
    table.sort(list,function(a,b) return a.name<b.name end)
    return list
end
function Talents.GetActiveName()
    if not C_ClassTalents then return "Talents unavailable" end
    if Talents.pendingSwitch and Talents.pendingSwitch.specID==Spec() then
        return Talents.pendingSwitch.previousName.." (switching...)"
    end
    local activeID = Safe(C_ClassTalents.GetActiveConfigID)
    local staged = C_Traits and Safe(C_Traits.ConfigHasStagedChanges,activeID)
    local code = C_Traits and Safe(C_Traits.GenerateImportString,activeID)
    local selected = Safe(C_ClassTalents.GetLastSelectedSavedConfigID,Spec())
    local matched, selectedConfig
    local signature = not staged and Signature(code,Spec())
    for _, config in ipairs(Talents.GetLoadouts()) do
        if config.id == selected then selectedConfig=config end
        local same=not staged and code and (config.code==code or (signature and signature==Signature(config.code,Spec())))
        if same then
            if config.id==activeID or config.id==selected then return config.name end
            matched=matched or config.name
        end
    end
    -- A stale last-selected ID must not hide a different, verified active
    -- loadout. Only use the old name as a modified/staged fallback.
    if matched then return matched end
    if selectedConfig then return selectedConfig.name..(staged and " (changes not applied)" or " (modified)") end
    return "Custom / unsaved talents"
end
function Talents.GetState(build)
    local specID, list = Spec(), Talents.GetLoadouts()
    local tracked = Store().managed[build.key]
    local named
    for _, config in ipairs(list) do
        if config.name==build.savedName then
            if named then return {label="Name conflict",conflict=true} end
            named=config
        end
    end
    local desired = Signature(build.code,specID)
    if tracked then
        for _, config in ipairs(list) do
            if config.id == tracked.configID and (config.code==build.code or (desired and desired==Signature(config.code,specID))) then
                return {id=config.id,name=config.name,label="Added",added=true,managed=true}
            end
        end
    end
    if named then
        local same = named.code==build.code or (desired and desired==Signature(named.code,specID))
        return {id=named.id,name=named.name,label=same and "Matching Build Found" or "Update Available",existing=true,update=not same,managed=tracked and tracked.configID==named.id}
    end
    for _, config in ipairs(list) do
        if config.code==build.code or (desired and desired==Signature(config.code,specID)) then
            return {id=config.id,name=config.name,label="Matching Build Found",existing=true}
        end
    end
    return {label="Not Added"}
end

local function FindByName(name, specID)
    local found
    for _, id in ipairs(Safe(C_ClassTalents.GetConfigIDsBySpecID,specID) or {}) do
        local info = Safe(C_Traits.GetConfigInfo,id)
        if info and info.name == name then if found then return nil end; found=id end
    end
    return found
end

function Talents.FinishPending()
    local store, specID = Store(),Spec()
    local pending = store.pending
    if not pending or pending.specID ~= specID then return end
    local can = Talents.CanAct()
    if not can then return end
    local id = pending.newID or FindByName(pending.importName,specID)
    if not id then return end
    if C_ClassTalents.IsConfigPopulated and Safe(C_ClassTalents.IsConfigPopulated,id) ~= true then return end
    local code = Safe(C_Traits.GenerateImportString,id)
    local signature = Signature(code,specID)
    if not signature or signature ~= Signature(pending.code,specID) then
        Talents.Notify("Imported talents did not match the requested build. The previous build was kept.")
        return
    end
    pending.newID = id
    if pending.oldID then
        -- Verify the old record still has our intended name before touching it.
        local old = Safe(C_Traits.GetConfigInfo,pending.oldID)
        if old and old.name ~= pending.savedName then
            Talents.Notify("The existing loadout was renamed. Update paused; no existing build was removed.")
            return
        end
        -- A verified replacement exists before deletion; failures keep the
        -- replacement staged and recover on a later user click or reload.
        if old and Safe(C_ClassTalents.DeleteConfig,pending.oldID) ~= true then
            Talents.Notify("Blizzard could not replace that loadout yet. The previous build was kept.")
            return
        end
        pending.oldID = nil
    end
    if pending.importName ~= pending.savedName then
        if Safe(C_ClassTalents.RenameConfig,id,pending.savedName) ~= true then
            Talents.Notify("The updated build is saved, but its final name could not be applied yet.")
            return
        end
    end
    store.managed[pending.key]={configID=id,code=pending.code,date=pending.date,name=pending.savedName}
    store.pending=nil
    Talents.Notify("Saved "..pending.savedName..". Use Switch when you want to activate it.")
end

function Talents.Save(build, update)
    local can, reason = Talents.CanAct()
    if not can then Talents.Notify(reason); return false end
    local specID=Spec()
    local recordValid=false
    for _, record in ipairs(KeyLab.GuideRecommendationsData.records) do
        if record.specID==specID then for _, candidate in ipairs(record.talents) do if candidate==build then recordValid=true end end end
    end
    if not recordValid then Talents.Notify("Your specialization changed. Select a build for the current spec."); return false end
    if Store().pending then
        Talents.FinishPending()
        if Store().pending then Talents.Notify("A talent import is still pending. Wait for it to finish before importing another."); return false end
    end
    local state=Talents.GetState(build)
    if state.conflict then Talents.Notify("More than one loadout has this name. Rename the duplicate in Talents first."); return false end
    if state.added and not state.update then Talents.Notify("Already saved as "..state.name.."."); return false end
    if state.existing and not state.update then
        -- A deliberate Add acknowledges a verified identical saved build;
        -- don't create a duplicate or silently claim KeyLab added it on view.
        Store().managed[build.key]={configID=state.id,code=build.code,date=build.date,name=state.name}
        Talents.Notify("Already saved as "..state.name..". Linked without adding a duplicate.")
        return true
    end
    if (state.update == true) ~= (update == true) then Talents.Notify(update and "Add this build first." or "Use Update for the existing build."); return false end
    local entries,errorText=Talents.Decode(build.code,specID)
    if not entries then Talents.Notify(errorText); return false end
    -- An open Blizzard talent window auto-activates newly created configs.
    -- Require it closed instead of modifying Blizzard's event handlers.
    -- IsShown stays true on the selected child tab when its parent window is
    -- closed. IsVisible includes hidden ancestors, so closing Talents unblocks.
    if PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame and PlayerSpellsFrame.TalentsFrame:IsVisible() then
        Talents.Notify("Close the game's Talents window first. Add/Update saves without switching your active build."); return false
    end
    if C_ClassTalents.CanCreateNewConfig and Safe(C_ClassTalents.CanCreateNewConfig) ~= true then
        Talents.Notify("Your talent loadout list is full. Free one slot first; existing builds were kept."); return false
    end
    local name=update and ("KL-stage-"..build.revision) or build.savedName
    local pending={key=build.key,code=build.code,date=build.date,specID=specID,savedName=build.savedName,importName=name,oldID=update and state.id or nil}
    Store().pending=pending
    local success, err=Safe(C_ClassTalents.ImportLoadout,C_ClassTalents.GetActiveConfigID(),entries,name,build.code)
    if success ~= true then Store().pending=nil; Talents.Notify(err or "Blizzard could not import this build. Existing builds were kept."); return false end
    Talents.Notify("Saving "..build.savedName.."...")
    Talents.FinishPending()
    return true
end

local function SyncTalentWindowSelection(specID,id,activeID)
    local frame=PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    if not frame or not frame.LoadSystem or not frame.SetSelectedSavedConfigID then return end
    -- Match Blizzard's SELECTED_LOADOUT_CHANGED display path. A saved ID can
    -- already be selected in the API while the loaded window retains its old
    -- selection. Never load/apply again just to synchronize that dropdown.
    if Safe(frame.IsInspecting,frame)~=false or Safe(frame.GetSpecID,frame)~=specID then return end
    if Safe(C_ClassTalents.GetLastSelectedSavedConfigID,specID)~=id then return end
    if Safe(frame.LoadSystem.IsSelectionIDValid,frame.LoadSystem,id)~=true then return end
    Safe(frame.CheckUpdateLastSelectedConfigID,frame,id)
    if Safe(frame.LoadSystem.GetSelectionID,frame.LoadSystem)~=id then
        Safe(frame.SetSelectedSavedConfigID,frame,id,false,true)
    end
    -- The window unregisters trait-update events while hidden. Refresh its
    -- cached tree from the ACTIVE config as Blizzard does on a config update;
    -- native LoadTalentTree defers rendering until visible if it is closed.
    -- This redraws the talent UI; it does not call LoadConfig or CommitConfig.
    Safe(frame.SetConfigID,frame,activeID,true)
end

function Talents.FinishSwitch()
    local pending=Talents.pendingSwitch
    if not pending or pending.loading then return end
    if pending.specID~=Spec() then
        Talents.pendingSwitch=nil
        Talents.Notify("Specialization changed; the previous switch is no longer being tracked.")
        return
    end
    if InCombatLockdown and InCombatLockdown() then return end
    local activeID=Safe(C_ClassTalents.GetActiveConfigID)
    if not activeID or Safe(C_Traits.ConfigHasStagedChanges,activeID)~=false then return end
    local code=Safe(C_Traits.GenerateImportString,activeID)
    local signature=Signature(code,pending.specID)
    if not code or not (code==pending.code or (signature and signature==Signature(pending.code,pending.specID))) then return end
    -- Only record the selected saved loadout once the active config really
    -- matches and no staged changes remain. A loaded preview is not a switch.
    Talents.pendingSwitch=nil
    Safe(C_ClassTalents.UpdateLastSelectedSavedConfigID,pending.specID,pending.id)
    SyncTalentWindowSelection(pending.specID,pending.id,activeID)
    Talents.Notify("Active build: "..pending.name..".")
end

function Talents.Switch(id)
    local can, reason=Talents.CanAct()
    if not can then Talents.Notify(reason); return false end
    local found
    for _, config in ipairs(Talents.GetLoadouts()) do if config.id==id then found=config end end
    if not found then Talents.Notify("That loadout is no longer available for this spec."); return false end
    local pending={id=id,name=found.name,code=found.code,specID=Spec(),activeID=Safe(C_ClassTalents.GetActiveConfigID),previousName=Talents.GetActiveName(),loading=true}
    Talents.pendingSwitch=pending
    local result,err=Safe(C_ClassTalents.LoadConfig,id,true)
    local results=Enum and Enum.LoadConfigResult or {}
    if result==nil or result==results.Error then
        Talents.pendingSwitch=nil; Talents.Notify(err or "Blizzard could not switch talents."); return false
    end
    if Talents.pendingSwitch~=pending then return false end
    if result==results.Ready then
        -- Ready means staged, not committed. Complete the user's one Switch
        -- click with the same saved-config commit used by Apply Changes.
        local allowed=not (InCombatLockdown and InCombatLockdown()) and not Talents.IsKeyActive()
        local success=allowed and Safe(C_ClassTalents.CommitConfig,id)
        if success~=true then
            Talents.pendingSwitch=nil
            Talents.Notify("Blizzard could not apply the selected build. No switch was confirmed; check Talents and try again.")
            return false
        end
    end
    pending.loading=false
    if Talents.pendingSwitch~=pending then return false end
    Talents.Notify("Switching to "..found.name.."...")
    Talents.FinishSwitch()
    -- Bounded status reads cover commit data arriving after the notification.
    -- Never retry LoadConfig/CommitConfig or run a persistent update loop.
    if C_Timer and C_Timer.After then
        for _,delay in ipairs({0.5,2,5}) do C_Timer.After(delay,function()
            if Talents.pendingSwitch==pending then Talents.FinishSwitch() end
        end) end
    end
    -- Final timeout, not another automatic Load/Commit attempt.
    if C_Timer and C_Timer.After then C_Timer.After(30,function()
        if Talents.pendingSwitch~=pending then return end
        Talents.FinishSwitch()
        if Talents.pendingSwitch==pending then
            Talents.pendingSwitch=nil
            Talents.Notify("The talent switch was not confirmed. Check Talents, then try Switch again when ready.")
        end
    end) end
    -- Use the existing Minimize action only after the switch is accepted.
    -- Do not create/open the main window when switching from the mini panel.
    local ui=KeyLab.UI
    if ui and ui.frame and ui.frame:IsShown() and not ui.isMenuOnly
        and not (InCombatLockdown and InCombatLockdown()) then
        Safe(ui.SetMenuOnly,ui,true)
    end
    return true
end

local events=CreateFrame("Frame")
for _, event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_SPECIALIZATION_CHANGED","ACTIVE_COMBAT_CONFIG_CHANGED","TRAIT_CONFIG_CREATED","TRAIT_CONFIG_UPDATED","TRAIT_CONFIG_DELETED","TRAIT_CONFIG_LIST_UPDATED","SELECTED_LOADOUT_CHANGED","PLAYER_TALENT_UPDATE","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","CHALLENGE_MODE_START","CHALLENGE_MODE_COMPLETED","CHALLENGE_MODE_RESET","CONFIG_COMMIT_FAILED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event,unit)
    if event=="PLAYER_SPECIALIZATION_CHANGED" and unit~="player" then return end
    if event=="CHALLENGE_MODE_START" then Talents.challengeActive=true end
    if event=="CHALLENGE_MODE_COMPLETED" or event=="CHALLENGE_MODE_RESET" then Talents.challengeActive=false end
    if event=="CONFIG_COMMIT_FAILED" then
        local pending=Talents.pendingSwitch
        if not pending or unit==nil or unit==pending.activeID or unit==pending.id then
            Talents.pendingSwitch=nil
            Talents.message="Blizzard could not apply the talent change. No switch was confirmed."
        end
    end
    if InCombatLockdown and InCombatLockdown() then Talents.Notify(); return end
    if Talents.refreshQueued then return end
    Talents.refreshQueued=true
    local function refresh()
        Talents.refreshQueued=false
        Talents.FinishSwitch()
        Talents.FinishPending()
        Talents.Notify()
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.15,refresh) else refresh() end
end)
