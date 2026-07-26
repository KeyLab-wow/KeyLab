local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

--[[
KeyLab_JournalData.lua

Purpose:
- Own export, import, and reset helpers for the saved KeyLab journal database.
- Keep Settings UI buttons thin.
- Export/import KeyLabDB only. KeyLabCaptureDB is temporary capture state and is reset on import/reset.
]]

local EXPORT_TYPE = "KeyLabJournalData"
local EXPORT_VERSION = 1
local popupFrame
local pendingImportDB

local function Print(message)
    if KeyLab.Print then
        KeyLab.Print(message)
    else
        print("|cffd4af37KeyLab:|r " .. tostring(message))
    end
end

local function DeepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return nil
    end
    seen[value] = true

    local out = {}
    for key, child in pairs(value) do
        local keyCopy = DeepCopy(key, seen)
        local childCopy = DeepCopy(child, seen)
        if keyCopy ~= nil and childCopy ~= nil then
            out[keyCopy] = childCopy
        end
    end

    seen[value] = nil
    return out
end

local function IsIdentifier(value)
    return type(value) == "string" and value:match("^[A-Za-z_][A-Za-z0-9_]*$") ~= nil
end

local function SortedKeys(tbl)
    local keys = {}
    for key in pairs(tbl or {}) do
        table.insert(keys, key)
    end

    table.sort(keys, function(a, b)
        local typeA = type(a)
        local typeB = type(b)
        if typeA ~= typeB then return typeA < typeB end
        return tostring(a) < tostring(b)
    end)

    return keys
end

local function SerializeValue(value, indent, seen)
    indent = indent or 0
    seen = seen or {}

    local valueType = type(value)
    if valueType == "nil" then
        return "nil"
    elseif valueType == "number" then
        return tostring(value)
    elseif valueType == "boolean" then
        return value and "true" or "false"
    elseif valueType == "string" then
        return string.format("%q", value)
    elseif valueType ~= "table" then
        return "nil"
    end

    if seen[value] then
        return "{}"
    end
    seen[value] = true

    local pad = string.rep(" ", indent)
    local childPad = string.rep(" ", indent + 4)
    local lines = { "{" }

    for _, key in ipairs(SortedKeys(value)) do
        local child = value[key]
        local childType = type(child)
        if childType == "table" or childType == "string" or childType == "number" or childType == "boolean" then
            local keyText
            if IsIdentifier(key) then
                keyText = key
            else
                keyText = "[" .. SerializeValue(key, indent + 4, seen) .. "]"
            end
            table.insert(lines, childPad .. keyText .. " = " .. SerializeValue(child, indent + 4, seen) .. ",")
        end
    end

    table.insert(lines, pad .. "}")
    seen[value] = nil
    return table.concat(lines, "\n")
end

local function EnsureJournalDefaults(db)
    db = type(db) == "table" and db or {}
    db.version = db.version or (KeyLab.version or "0.1.5")
    db.trackingSince = db.trackingSince or (date and date("%B %Y") or "Imported")

    if type(db.settings) ~= "table" then db.settings = {} end
    if db.settings.completedMythicPlusOnly == nil then
        db.settings.completedMythicPlusOnly = true
    end
    if db.settings.contentMode ~= "raid" then db.settings.contentMode = "mplus" end

    if type(db.encounters) ~= "table" then db.encounters = {} end
    if type(db.raidEncounters) ~= "table" then db.raidEncounters = {} end
    if type(db.raidNights) ~= "table" then db.raidNights = {} end
    if type(db.builds) ~= "table" then db.builds = {} end
    if type(db.lootTargets) ~= "table" then db.lootTargets = {} end
    if type(db.lootTargetStatuses) ~= "table" then db.lootTargetStatuses = {} end
    if type(db.gearTargets) ~= "table" then db.gearTargets = {} end
    if type(db.tierSets) ~= "table" then db.tierSets = {} end
    if type(db.statGoals) ~= "table" then db.statGoals = {} end
    if type(db.statGoalMatcherResults) ~= "table" then db.statGoalMatcherResults = {} end
    if type(db.practiceSessions) ~= "table" then db.practiceSessions = {} end
    db.activePracticeSession = nil

    return db
end

local function ResetCaptureDB()
    if KeyLab.Capture and KeyLab.Capture.Sessions and KeyLab.Capture.Sessions.ResetCaptureDB then
        KeyLab.Capture.Sessions.ResetCaptureDB()
    else
        KeyLabCaptureDB = {
            version = KeyLab.version or "0.1.5",
            active = false,
            completedSeen = false,
            interrupted = false,
        }
    end
end

local function RefreshAllUI()
    if KeyLab.RefreshTabs then
        KeyLab.RefreshTabs()
    end
    if KeyLab.UI and KeyLab.UI.RefreshSelectedTab then
        KeyLab.UI:RefreshSelectedTab()
    end
    if KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.RefreshVisible then
        KeyLab.GearTargetsWindow.RefreshVisible()
    end
end

local function ResetGearingRuntimeState(preserveMatcherResults)
    if KeyLab.ResetGearingRuntimeState then
        KeyLab.ResetGearingRuntimeState(preserveMatcherResults)
        return
    end
    if KeyLab.StatGoalMatcher then
        if KeyLab.StatGoalMatcher.Cancel then KeyLab.StatGoalMatcher.Cancel() end
        if not preserveMatcherResults and KeyLab.StatGoalMatcher.ClearAllResults then KeyLab.StatGoalMatcher.ClearAllResults() end
    end
    if KeyLab.GearCapture and KeyLab.GearCapture.MarkAllSlotsChanged then KeyLab.GearCapture.MarkAllSlotsChanged() end
end

local function RaisePopupFrame(frame)
    if not frame then return end

    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(900)

    if frame.SetToplevel then
        frame:SetToplevel(true)
    end

    if frame.Raise then
        frame:Raise()
    end
end

local function ShowRaisedStaticPopup(name)
    local dialog = StaticPopup_Show(name)
    RaisePopupFrame(dialog)
    return dialog
end

local function ValidateImportPayload(payload)
    if type(payload) ~= "table" then
        return nil
    end

    if payload.exportType == EXPORT_TYPE and type(payload.data) == "table" then
        return EnsureJournalDefaults(DeepCopy(payload.data))
    end

    if payload.keyLabExportType == EXPORT_TYPE and type(payload.keyLabDB) == "table" then
        return EnsureJournalDefaults(DeepCopy(payload.keyLabDB))
    end

    if type(payload.settings) == "table" or type(payload.encounters) == "table" or type(payload.builds) == "table" then
        return EnsureJournalDefaults(DeepCopy(payload))
    end

    return nil
end

local function ParseImportText(text)
    text = tostring(text or "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end

    local source = text
    if not source:match("^%-%-") and not source:match("^return%s") then
        source = "return " .. source
    end

    local loader = loadstring or load
    if not loader then return nil end

    local chunk, loadError = loader(source)
    if not chunk then
        return nil, loadError
    end

    if setfenv then
        setfenv(chunk, {})
    end

    local ok, payload = pcall(chunk)
    if not ok then
        return nil, payload
    end

    return ValidateImportPayload(payload)
end

local function RegisterImportConfirmPopup()
    if StaticPopupDialogs["KEYLAB_CONFIRM_IMPORT_JOURNAL"] then return end

    StaticPopupDialogs["KEYLAB_CONFIRM_IMPORT_JOURNAL"] = {
        text = "Import this KeyLab journal data?\n\nThis will replace your current saved KeyLab journal database.",
        button1 = YES,
        button2 = CANCEL,
        OnAccept = function()
            if not pendingImportDB then
                Print("Import failed. Invalid data.")
                return
            end

            KeyLabDB = EnsureJournalDefaults(DeepCopy(pendingImportDB))
            pendingImportDB = nil
            if KeyLab.LootTargetsDB and KeyLab.LootTargetsDB.MigrateLegacy then
                KeyLab.LootTargetsDB.MigrateLegacy()
            end
            if KeyLab.StatGoalsDB and KeyLab.StatGoalsDB.CleanupLegacy then
                KeyLab.StatGoalsDB.CleanupLegacy()
            end
            ResetGearingRuntimeState(true)
            ResetCaptureDB()
            if popupFrame then
                popupFrame:Hide()
            end
            RefreshAllUI()
            Print("Journal data imported.")
        end,
        OnCancel = function()
            pendingImportDB = nil
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = STATICPOPUP_NUMDIALOGS,
    }
end

local function RegisterResetConfirmPopup()
    if StaticPopupDialogs["KEYLAB_CONFIRM_RESET_JOURNAL_DATA"] then return end

    StaticPopupDialogs["KEYLAB_CONFIRM_RESET_JOURNAL_DATA"] = {
        text = "Permanently delete saved KeyLab journal data for all characters?\n\nThis deletes encounters, stat profiles, talent/build data, practice sessions, gear targets, Tier Set selections, stat goals, and settings. This cannot be undone.",
        button1 = YES,
        button2 = CANCEL,
        OnAccept = function()
            if KeyLab.ResetJournalData then
                KeyLab:ResetJournalData()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = STATICPOPUP_NUMDIALOGS,
    }
end

local function EnsureTextPopup()
    if popupFrame then return popupFrame end

    local frame = CreateFrame("Frame", "KeyLabJournalDataPopup", UIParent, "BackdropTemplate")
    frame:SetSize(720, 520)
    frame:SetPoint("CENTER")
    RaisePopupFrame(frame)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetScript("OnShow", RaisePopupFrame)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.015, 0.022, 0.050, 0.98)
    frame:SetBackdropBorderColor(0.42, 0.62, 1.0, 0.92)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
    frame.title:SetTextColor(0.95, 0.76, 0.32, 1.0)

    frame.body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.body:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -6)
    frame.body:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    frame.body:SetJustifyH("LEFT")
    frame.body:SetTextColor(0.72, 0.78, 0.90, 1.0)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() frame:Hide() end)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -82)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 58)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("ChatFontNormal")
    edit:SetSize(650, 390)
    edit:SetTextInsets(6, 6, 6, 6)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(edit)
    frame.editBox = edit

    frame.action = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.action:SetSize(150, 26)
    frame.action:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -92, 18)

    frame.cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.cancel:SetSize(80, 26)
    frame.cancel:SetPoint("LEFT", frame.action, "RIGHT", 8, 0)
    frame.cancel:SetText(CANCEL)
    frame.cancel:SetScript("OnClick", function() frame:Hide() end)

    popupFrame = frame
    return popupFrame
end

function KeyLab:ExportJournalData()
    local db = EnsureJournalDefaults(DeepCopy(KeyLabDB or {}))
    local payload = {
        exportType = EXPORT_TYPE,
        exportVersion = EXPORT_VERSION,
        keyLabVersion = KeyLab.version or "unknown",
        exportedAt = date and date("%Y-%m-%d %H:%M:%S") or "unknown",
        data = db,
    }

    return "-- KeyLab Journal Data Export\n-- Paste this text into KeyLab's Import Journal Data popup.\nreturn " .. SerializeValue(payload, 0)
end

function KeyLab:ShowExportPopup()
    local text = self:ExportJournalData()
    local frame = EnsureTextPopup()
    frame.title:SetText("Export Journal Data")
    frame.body:SetText("Copy the text below and save it somewhere safe.")
    frame.editBox:SetText(text)
    frame.editBox:SetCursorPosition(0)
    frame.action:SetText("Select All")
    frame.action:SetScript("OnClick", function()
        frame.editBox:SetFocus()
        frame.editBox:HighlightText()
    end)
    frame:Show()
    frame.editBox:SetFocus()
    frame.editBox:HighlightText()
    Print("Journal data exported.")
end

function KeyLab:ImportJournalData(text)
    RegisterImportConfirmPopup()

    local db = ParseImportText(text)
    if not db then
        Print("Import failed. Invalid data.")
        return false
    end

    pendingImportDB = db
    ShowRaisedStaticPopup("KEYLAB_CONFIRM_IMPORT_JOURNAL")
    return true
end

function KeyLab:ShowImportPopup()
    local frame = EnsureTextPopup()
    frame.title:SetText("Import Journal Data")
    frame.body:SetText("Paste a previous KeyLab journal export below, then import it.")
    frame.editBox:SetText("")
    frame.action:SetText("Import")
    frame.action:SetScript("OnClick", function()
        KeyLab:ImportJournalData(frame.editBox:GetText())
    end)
    frame:Show()
    frame.editBox:SetFocus()
end

function KeyLab:ResetJournalData()
    if KeyLab.DB and KeyLab.DB.ResetAll then
        KeyLab.DB.ResetAll()
    else
        KeyLabDB = EnsureJournalDefaults({})
    end

    ResetGearingRuntimeState()
    ResetCaptureDB()
    RefreshAllUI()
    Print("Journal data reset.")
    return true
end

function KeyLab:ShowResetJournalDataConfirmation()
    RegisterResetConfirmPopup()
    ShowRaisedStaticPopup("KEYLAB_CONFIRM_RESET_JOURNAL_DATA")
end

function KeyLab:RefreshSettingsTab()
    RefreshAllUI()
end

RegisterImportConfirmPopup()
RegisterResetConfirmPopup()
