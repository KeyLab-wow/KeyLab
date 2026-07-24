local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local Practice = {}
KeyLab.Tabs.Practice = Practice

local Theme = KeyLab.UI.Theme or {}
local Analysis = KeyLab.Analysis and KeyLab.Analysis.Practice or {}
local SPACING = Theme.spacing or { card = 14 }
local HEADER = Theme.tabHeader or { x = 18, titleY = -18, titleSize = 16 }

local COLORS = (Theme and Theme.colors) or {
    bg = {0.018, 0.026, 0.056, 0.96},
    cardBg = {0.026, 0.046, 0.086, 0.94},
    cardBorder = {0.240, 0.380, 0.620, 0.62},
    gold = {0.820, 0.760, 0.580, 1.0},
    text = {0.940, 0.960, 0.990, 1.0},
    muted = {0.680, 0.730, 0.820, 1.0},
    green = {0.420, 0.800, 0.470, 1.0},
    blue = {0.500, 0.680, 0.940, 1.0},
    orange = {0.940, 0.620, 0.280, 1.0},
    red = {0.920, 0.420, 0.400, 1.0},
    purple = {0.720, 0.560, 0.940, 1.0},
}

local TABLE_COLUMNS = {
    rank = { x = 14, width = 30, label = "#" },
    type = { x = 48, width = 66, label = "Type" },
    date = { x = 122, width = 120, label = "Date" },
    duration = { x = 250, width = 62, label = "Duration" },
    metric = { x = 320, width = 88, label = "Outcome" },
    spec = { x = 416, width = 100, label = "Spec" },
    sequence = { x = 524, width = 112, label = "Sequence Version" },
    build = { x = 644, width = 70, label = "Build" },
    status = { x = 722, width = 108, label = "Status" },
}

local PAGE_SIZE = 9

local NEW_SESSION_HEIGHT = 86
local LAYOUT = { newSessionY = -66 }
LAYOUT.filtersY = LAYOUT.newSessionY - NEW_SESSION_HEIGHT - SPACING.card
LAYOUT.tableY = LAYOUT.filtersY - 78 - SPACING.card
LAYOUT.detailsY = LAYOUT.tableY - 380 - SPACING.card

local METRIC_COLORS = {
    damageDone = COLORS.orange,
    dps = COLORS.orange,
    healingDoneWithAbsorbs = COLORS.green,
    hpsWithAbsorbs = COLORS.green,
}

local TALENT_BUILD_COLORS = {
    COLORS.blue,
    COLORS.purple,
    COLORS.green,
    COLORS.orange,
    COLORS.gold,
}

local STATUS_FILTER_OPTIONS = {
    { value = "all", label = "All Status" },
    { value = "unmarked", label = "Unmarked" },
}

local function ApplyColor(fs, color)
    if not fs or not color then return end
    fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function SetBackdrop(frame, color, borderColor)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(color or COLORS.cardBg))
    frame:SetBackdropBorderColor(unpack(borderColor or COLORS.cardBorder))
end

local function MakeText(parent, text, template, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    if size and STANDARD_TEXT_FONT then
        fs:SetFont(STANDARD_TEXT_FONT, size, "")
    end
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetText(text or "")
    ApplyColor(fs, color or COLORS.text)
    return fs
end

local function AddLine(parent, text, x, y, width, color, template)
    local fs = MakeText(parent, text, template or "GameFontHighlightSmall", nil, color or COLORS.text)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetSize(width or 200, 18)
    return fs
end

local function MakePanel(parent, x, y, width, height, title)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    panel:SetSize(width, height)
    SetBackdrop(panel, COLORS.cardBg, COLORS.cardBorder)

    if title and title ~= "" then
        AddLine(panel, title, 14, -10, width - 28, COLORS.gold, "GameFontNormal")
    end

    return panel
end

local function MakeMovableWindow(frame, dragHeight)
    if not frame then return end

    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    local drag = CreateFrame("Frame", nil, frame)
    drag:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    drag:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    drag:SetHeight(dragHeight or 44)
    drag:SetFrameLevel((frame:GetFrameLevel() or 0) + 1)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    drag:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)
end

local function MakeButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 110, height or 24)
    button:SetText(text or "")
    return button
end

local function MakeSmallButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 78, height or 20)
    SetBackdrop(button, COLORS.bg, COLORS.cardBorder)
    button.text = MakeText(button, text or "", "GameFontDisableSmall", nil, COLORS.text, "CENTER")
    button.text:SetAllPoints(button)
    button:SetScript("OnEnter", function(btn)
        btn:SetBackdropBorderColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 0.9)
    end)
    button:SetScript("OnLeave", function(btn)
        btn:SetBackdropBorderColor(COLORS.cardBorder[1], COLORS.cardBorder[2], COLORS.cardBorder[3], COLORS.cardBorder[4] or 1)
    end)
    return button
end

local function SetDropdownText(dropdown, text)
    if not dropdown then return end
    if UIDropDownMenu_SetText then
        UIDropDownMenu_SetText(dropdown, text or "Select")
    end
end

local function MakeDropdown(parent, width, x, y, labelText, onInitialize)
    local label = MakeText(parent, labelText, "GameFontDisableSmall", nil, COLORS.muted)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 2, y)
    label:SetSize(width + 30, 16)

    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 18, y - 18)
    UIDropDownMenu_SetWidth(dropdown, width or 150)
    UIDropDownMenu_Initialize(dropdown, onInitialize)
    return dropdown
end

local function SafeNumber(value)
    if KeyLab.Utils and KeyLab.Utils.SafeNumber then
        return KeyLab.Utils.SafeNumber(value)
    end
    value = tonumber(value)
    if type(value) ~= "number" then return nil end
    if value ~= value then return nil end
    return value
end

local function Clamp(value, minimum, maximum)
    value = SafeNumber(value) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function FormatNumber(value)
    if KeyLab.Formatters and KeyLab.Formatters.Number then
        return KeyLab.Formatters.Number(value)
    end
    value = SafeNumber(value)
    if not value then return "-" end
    if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
    if value >= 1000 then return string.format("%.1fK", value / 1000) end
    return tostring(math.floor(value + 0.5))
end

local function FormatMetric(metricKey, value)
    if value == nil then return "-" end
    if KeyLab.Formatters and KeyLab.Formatters.Metric then
        return KeyLab.Formatters.Metric(metricKey, value)
    end
    return FormatNumber(value)
end

local function FormatDuration(value)
    if KeyLab.Formatters and KeyLab.Formatters.Duration then
        return KeyLab.Formatters.Duration(value)
    end
    value = SafeNumber(value)
    if not value then return "-" end
    local seconds = math.max(0, math.floor(value + 0.5))
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    return string.format("%d:%02d", minutes, seconds)
end

local function FormatDate(value)
    value = SafeNumber(value)
    if not value then return "-" end
    return date("%b %d %I:%M %p", value)
end

local function Print(message)
    if KeyLab.Utils and KeyLab.Utils.Print then
        KeyLab.Utils.Print(message)
    elseif KeyLab.Print then
        KeyLab.Print(message)
    else
        print("|cffd6b35aKeyLab:|r " .. tostring(message))
    end
end

local function Capture()
    return KeyLab.Capture and KeyLab.Capture.Practice or {}
end

local function PracticeDB()
    return KeyLab.DB and KeyLab.DB.Practice or {}
end

local function MetricOptions()
    return Analysis.GetMetricOptions and Analysis.GetMetricOptions() or {
        { key = "damageDone", label = "Damage Done" },
        { key = "dps", label = "DPS" },
        { key = "healingDoneWithAbsorbs", label = "Healing Done" },
        { key = "hpsWithAbsorbs", label = "HPS" },
    }
end

local function TestTypeOptions()
    return Analysis.GetTestTypeOptions and Analysis.GetTestTypeOptions() or {
        { key = "ST", label = "ST" },
        { key = "MT", label = "MT" },
        { key = "Party Healing", label = "Party Heal" },
        { key = "Group Healing", label = "Group Heal" },
    }
end

local function DurationOptions(includeAll)
    local options = {}
    if includeAll then table.insert(options, { value = nil, label = "All Lengths" }) end
    table.insert(options, { value = 30, label = "30 Seconds" })
    table.insert(options, { value = 60, label = "60 Seconds" })
    table.insert(options, { value = 120, label = "2 Minutes" })
    table.insert(options, { value = "manual", label = "Manual" })
    return options
end

local function MetricLabel(metricKey)
    if Analysis.GetMetricLabel then
        return Analysis.GetMetricLabel(metricKey)
    end
    return metricKey or "Outcome"
end

local function MetricValue(session, metricKey)
    if Analysis.GetMetricValue then
        return Analysis.GetMetricValue(session, metricKey)
    end
    return SafeNumber(session and session.metrics and session.metrics[metricKey])
end

local function GetSessions()
    return Analysis.GetSessions and Analysis.GetSessions() or {}
end

local function GetSequenceVersionOptions()
    local options = {
        { sequenceID = nil, versionID = nil, label = "Auto-detect KeyLab use (optional)" },
    }
    local library = KeyLab.SequencerLibrary or {}
    if not library.GetCollectionSnapshot then return options end

    local ok, collection = pcall(library.GetCollectionSnapshot)
    if not ok or type(collection) ~= "table" then return options end
    for _, sequenceID in ipairs(collection.order or {}) do
        local sequence = collection.sequences and collection.sequences[sequenceID]
        local versionID = sequence and sequence.activeVersionId
        local version = sequence and sequence.versions and sequence.versions[versionID]
        if sequence and version then
            table.insert(options, {
                sequenceID = sequenceID,
                versionID = versionID,
                sequenceName = tostring(sequence.name or "Sequence"),
                versionName = tostring(version.name or "Version"),
                className = collection.className,
                specName = collection.specName,
                label = tostring(sequence.name or "Sequence") .. " - " .. tostring(version.name or "Version"),
            })
        end
    end
    return options
end

local function GetSelectedSequenceUsage()
    local selectedID = Practice.selectedStartSequenceID
    if not selectedID then return nil end
    for _, option in ipairs(GetSequenceVersionOptions()) do
        if option.sequenceID == selectedID then
            return {
                sequenceID = option.sequenceID,
                versionID = option.versionID,
                sequenceName = option.sequenceName,
                versionName = option.versionName,
                className = option.className,
                specName = option.specName,
            }
        end
    end
    Practice.selectedStartSequenceID = nil
    return nil
end

local function SequenceUsageLabel(sequenceUsage)
    if type(sequenceUsage) ~= "table" then return "Not selected" end
    local sequenceName = tostring(sequenceUsage.sequenceName or "")
    local versionName = tostring(sequenceUsage.versionName or "")
    if sequenceName == "" and versionName == "" then return "Not selected" end
    if sequenceName == "" then return versionName end
    if versionName == "" then return sequenceName end
    return sequenceName .. " - " .. versionName
end

local function SessionSequenceUsages(session)
    if type(session) ~= "table" then return {} end
    if type(session.sequenceUsages) == "table" and #session.sequenceUsages > 0 then
        return session.sequenceUsages
    end
    if type(session.sequenceUsage) == "table" then
        return { session.sequenceUsage }
    end
    return {}
end

local function SessionSequenceSummary(session)
    local usages = SessionSequenceUsages(session)
    if #usages == 0 then
        return session and session.sequenceUsageDetection == "none" and "No KeyLab sequence used" or "Not selected"
    end
    local label = SequenceUsageLabel(usages[1])
    if #usages > 1 then
        label = label .. " +" .. tostring(#usages - 1) .. " more"
    end
    return label
end

local function SessionSequenceDetails(session)
    local usages = SessionSequenceUsages(session)
    if #usages == 0 then return SessionSequenceSummary(session) end
    local labels = {}
    for _, usage in ipairs(usages) do
        local label = SequenceUsageLabel(usage)
        local combatPresses = tonumber(usage.combatPresses) or 0
        local presses = combatPresses > 0 and combatPresses or tonumber(usage.pressCount)
        if presses and presses > 0 then
            label = label .. " (" .. tostring(presses) .. " press" .. (presses == 1 and "" or "es") .. ")"
        end
        table.insert(labels, label)
    end
    return table.concat(labels, ";  ")
end

local function ShortText(value, maxLength)
    value = tostring(value or "")
    maxLength = maxLength or 24
    if string.len(value) <= maxLength then return value end
    return string.sub(value, 1, maxLength - 3) .. "..."
end

local function StatLine(stats)
    stats = stats or {}
    if stats.crit == nil
        and stats.haste == nil
        and stats.mastery == nil
        and stats.versatility == nil
    then
        return "Not captured"
    end
    return "Crit " .. FormatNumber(stats.crit)
        .. "  Haste " .. FormatNumber(stats.haste)
        .. "  Mastery " .. FormatNumber(stats.mastery)
        .. "  Vers " .. FormatNumber(stats.versatility)
end

local function TalentString(session)
    local value = session and session.talents and session.talents.talentString
    return type(value) == "string" and value ~= "" and value or nil
end

local function BuildLetter(index)
    index = math.max(1, math.floor(tonumber(index) or 1))
    local label = ""
    while index > 0 do
        local remainder = (index - 1) % 26
        label = string.char(65 + remainder) .. label
        index = math.floor((index - 1) / 26)
    end
    return label
end

local function BuildTalentLabels(sessions)
    local buildsByString = {}
    for _, session in ipairs(sessions or {}) do
        local talentString = TalentString(session)
        if talentString then
            local timestamp = SafeNumber(session.timestamp) or 0
            local build = buildsByString[talentString]
            if not build then
                build = { talentString = talentString, firstTimestamp = timestamp }
                buildsByString[talentString] = build
            elseif timestamp < build.firstTimestamp then
                build.firstTimestamp = timestamp
            end
        end
    end

    local builds = {}
    for _, build in pairs(buildsByString) do table.insert(builds, build) end
    table.sort(builds, function(a, b)
        if a.firstTimestamp ~= b.firstTimestamp then return a.firstTimestamp < b.firstTimestamp end
        return a.talentString < b.talentString
    end)

    local labels = {}
    for index, build in ipairs(builds) do
        labels[build.talentString] = {
            label = "Build " .. BuildLetter(index),
            color = TALENT_BUILD_COLORS[((index - 1) % #TALENT_BUILD_COLORS) + 1],
        }
    end
    return labels
end

local function TalentBuildInfo(session)
    local talentString = TalentString(session)
    local info = talentString and Practice.talentBuildLabels and Practice.talentBuildLabels[talentString]
    return info or { label = "Not captured", color = COLORS.muted }
end

local function StatusLabel(status)
    if PracticeDB().GetStatusLabel then
        return PracticeDB().GetStatusLabel(status)
    end
    if status == "baseline" then return "Baseline" end
    if status == "favorite" then return "Favorite" end
    if status == "review" then return "Review" end
    if status == "ignore" then return "Ignore" end
    return "Unmarked"
end

local function StatusOptions()
    return PracticeDB().GetStatusOptions and PracticeDB().GetStatusOptions() or {
        { value = nil, label = "Unmarked" },
        { value = "baseline", label = "Baseline" },
        { value = "favorite", label = "Favorite" },
        { value = "review", label = "Review" },
        { value = "ignore", label = "Ignore" },
    }
end

local function StatusFilterOptions()
    local options = {}
    for _, option in ipairs(STATUS_FILTER_OPTIONS) do
        table.insert(options, option)
    end
    for _, option in ipairs(StatusOptions()) do
        if option.value ~= nil then
            table.insert(options, { value = option.value, label = option.label })
        end
    end
    return options
end

local function FindOptionLabel(options, value, fallback)
    for _, option in ipairs(options or {}) do
        if option.value == value or option.key == value then
            return option.label or option.text
        end
    end
    return fallback or "All"
end

local function RegisterCopyTalentPopup()
    if StaticPopupDialogs["KEYLAB_PRACTICE_COPY_TALENT"] then return end

    StaticPopupDialogs["KEYLAB_PRACTICE_COPY_TALENT"] = {
        text = "Practice Session Talent String",
        button1 = "Close",
        hasEditBox = true,
        editBoxWidth = 420,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self, data)
            local editBox = self.editBox or self.EditBox
            if editBox then
                editBox:SetText(tostring(data or ""))
                editBox:SetFocus()
                editBox:HighlightText()
            end
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
    }
end

local function RegisterDeletePopup()
    if StaticPopupDialogs["KEYLAB_DELETE_PRACTICE_SESSION"] then return end

    StaticPopupDialogs["KEYLAB_DELETE_PRACTICE_SESSION"] = {
        text = "Delete this practice session?",
        button1 = "Delete",
        button2 = "Cancel",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnAccept = function(_, data)
            if PracticeDB().DeleteSession and PracticeDB().DeleteSession(data) then
                if Practice.selectedSessionID == data then
                    Practice.selectedSessionID = nil
                end
                Print("Practice session deleted.")
                Practice:Refresh()
            end
        end,
    }
end

local statusMenuFrame = nil

local function GetStatusMenuFrame()
    if not statusMenuFrame then
        statusMenuFrame = CreateFrame("Frame", "KeyLabPracticeStatusMenu", UIParent, "UIDropDownMenuTemplate")
    end
    return statusMenuFrame
end

local function OpenStatusMenu(anchor, sessionID, currentStatus)
    if not UIDropDownMenu_Initialize or not UIDropDownMenu_CreateInfo or not UIDropDownMenu_AddButton or not ToggleDropDownMenu then
        return
    end

    local menu = GetStatusMenuFrame()
    UIDropDownMenu_Initialize(menu, function(_, level)
        for _, option in ipairs(StatusOptions()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = ((currentStatus == option.value) and "* " or "  ") .. tostring(option.label or StatusLabel(option.value))
            info.func = function()
                if PracticeDB().SetStatus then
                    PracticeDB().SetStatus(sessionID, option.value)
                end
                if CloseDropDownMenus then CloseDropDownMenus() end
                Practice:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    ToggleDropDownMenu(1, nil, menu, anchor, 0, 0)
end

local function RefreshPracticeSoon()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if Practice.content then
                Practice:Refresh()
            end
        end)
    elseif Practice.content then
        Practice:Refresh()
    end
end

local function TryUpdateSessionTotals(sessionID)
    if not sessionID or not Capture().TryUpdateSessionTotals then
        return false
    end

    local ok, updated = pcall(Capture().TryUpdateSessionTotals, sessionID)
    return ok and updated == true
end

local function ScheduleSessionRefreshes(sessionID)
    RefreshPracticeSoon()

    if not sessionID or not C_Timer or not C_Timer.After then
        return
    end

    for _, delay in ipairs({ 0.5, 1.5, 3.0, 6.0 }) do
        C_Timer.After(delay, function()
            TryUpdateSessionTotals(sessionID)
            RefreshPracticeSoon()
        end)
    end
end

local function EnsureMonitor()
    if Practice.monitor then return Practice.monitor end

    local frame = CreateFrame("Frame", "KeyLabPracticeMonitor", UIParent, "BackdropTemplate")
    frame:SetSize(360, 180)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(950)
    frame:EnableMouse(true)
    SetBackdrop(frame, COLORS.cardBg, COLORS.cardBorder)
    MakeMovableWindow(frame, 128)
    frame:Hide()

    frame.title = MakeText(frame, "Practice Session Started", "GameFontNormalLarge", 18, COLORS.gold)
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -18)
    frame.title:SetSize(324, 24)

    frame.timer = MakeText(frame, "0:00", "GameFontNormalLarge", 24, COLORS.green, "CENTER")
    frame.timer:SetPoint("TOP", frame, "TOP", 0, -54)
    frame.timer:SetSize(320, 32)

    frame.note = MakeText(frame, "Let pets and leftover damage finish, then choose Stop. KeyLab will save the test time.", "GameFontHighlightSmall", nil, COLORS.muted, "CENTER")
    frame.note:SetPoint("TOP", frame.timer, "BOTTOM", 0, -10)
    frame.note:SetSize(310, 34)

    local function FinishStop(quiet)
        local ok, resultOrError = false, "Practice session could not stop."
        if Capture().StopSession then
            local callOk, a, b = pcall(Capture().StopSession)
            if callOk then
                ok, resultOrError = a, b
            else
                resultOrError = tostring(a or resultOrError)
            end
        end

        if ok and type(resultOrError) == "table" then
            frame.pendingStop = false
            frame.stopRetryElapsed = 0
            frame:Hide()
            Practice.selectedSessionID = resultOrError.id
            Practice.selectedSpec = nil
            Practice.selectedTypeFilter = nil
            Practice.selectedDurationFilter = resultOrError.targetDurationSeconds or "manual"
            Practice.selectedStatusFilter = "all"
            if KeyLab.UI and KeyLab.UI.Show then
                KeyLab.UI:Show()
                KeyLab.UI:SelectTab("Practice")
            end
            ScheduleSessionRefreshes(resultOrError.id)
            return true
        end

        frame.pendingStop = true
        local message = tostring(resultOrError or "Stop marked. Waiting for damage meter totals.")
        if message:find("No new practice damage meter data", 1, true) then
            message = "Stop marked. Waiting for damage meter totals."
        end
        frame.note:SetText(message)
        ApplyColor(frame.note, COLORS.orange)
        if frame.stop then
            frame.stop:SetText("Waiting...")
        end
        if not quiet then
            Print(message)
        end
        return false
    end

    frame.stop = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.stop:SetSize(130, 28)
    frame.stop:SetPoint("BOTTOM", frame, "BOTTOM", 0, 18)
    frame.stop:SetText("Stop Session")
    frame.stop:SetScript("OnClick", function()
        frame.pendingStop = true
        frame.stopRetryElapsed = 0
        FinishStop(false)
    end)

    frame:SetScript("OnUpdate", function(self, elapsed)
        local active = Capture().GetActiveSession and Capture().GetActiveSession()
        if not active then
            self:Hide()
            return
        end
        local endTime = tonumber(active.stoppedAt) or time()
        local elapsedSeconds = math.max(0, endTime - (tonumber(active.startedAt) or endTime))
        local targetDuration = tonumber(active.targetDurationSeconds)
        if targetDuration then
            self.timer:SetText(FormatDuration(math.min(elapsedSeconds, targetDuration)) .. " / " .. FormatDuration(targetDuration))
            if elapsedSeconds >= targetDuration and not self.pendingStop then
                self.pendingStop = true
                self.stopRetryElapsed = 0
                self.note:SetText("Test complete. Snapshotting Damage Done from Blizzard's active meter session.")
                ApplyColor(self.note, COLORS.orange)
                if self.stop then self.stop:SetText("Snapshotting...") end
                FinishStop(true)
            end
        else
            self.timer:SetText(FormatDuration(elapsedSeconds))
        end

        if self.pendingStop then
            self.stopRetryElapsed = (self.stopRetryElapsed or 0) + (elapsed or 0)
            if self.stopRetryElapsed >= 0.75 then
                self.stopRetryElapsed = 0
                FinishStop(true)
            end
        end
    end)

    Practice.monitor = frame
    return frame
end

function Practice:ShowMonitor()
    local monitor = EnsureMonitor()
    monitor.pendingStop = false
    monitor.stopRetryElapsed = 0
    local active = Capture().GetActiveSession and Capture().GetActiveSession()
    local targetDuration = active and tonumber(active.targetDurationSeconds)
    if targetDuration then
        monitor.title:SetText("Practice Session - " .. FormatDuration(targetDuration))
        monitor.note:SetText("KeyLab will save the Damage Done total when the timer ends.")
    else
        monitor.title:SetText("Practice Session - Manual")
        monitor.note:SetText("Choose Stop when the test ends. KeyLab will save the active Damage Meter totals.")
    end
    ApplyColor(monitor.note, COLORS.muted)
    if monitor.stop then
        monitor.stop:SetText("Stop Session")
    end
    monitor:Show()
end

function Practice:SelectSession(session)
    self.selectedSessionID = session and session.id or nil
    self.selectedSession = session
    self:Refresh()
end

local function FindSelectedSession(sessions)
    if Practice.selectedSessionID then
        for _, session in ipairs(sessions or {}) do
            if session.id == Practice.selectedSessionID then
                return session
            end
        end
    end
    if type(sessions) ~= "table" or #sessions == 0 then
        return nil
    end
    local totalPages = math.max(1, math.ceil(#sessions / PAGE_SIZE))
    Practice.currentPage = Clamp(Practice.currentPage or 1, 1, totalPages)
    local startIndex = ((Practice.currentPage - 1) * PAGE_SIZE) + 1
    return sessions[startIndex] or sessions[1]
end

function Practice:RefreshDropdowns(baseSessions)
    SetDropdownText(self.startTypeDropdown, FindOptionLabel(TestTypeOptions(), self.selectedStartType or "ST", "ST"))
    SetDropdownText(self.startDurationDropdown, FindOptionLabel(DurationOptions(false), self.selectedStartDuration or 60, "60 Seconds"))

    local sequenceText = "Auto-detect KeyLab use (optional)"
    local selectedUsage = GetSelectedSequenceUsage()
    if selectedUsage then sequenceText = SequenceUsageLabel(selectedUsage) end
    SetDropdownText(self.startSequenceDropdown, sequenceText)

    local specText = "All Specs"
    if self.selectedSpec then specText = self.selectedSpec end
    SetDropdownText(self.specDropdown, specText)

    SetDropdownText(self.typeFilterDropdown, self.selectedTypeFilter and FindOptionLabel(TestTypeOptions(), self.selectedTypeFilter, "All Types") or "All Types")
    SetDropdownText(self.durationFilterDropdown, self.selectedDurationFilter and FindOptionLabel(DurationOptions(true), self.selectedDurationFilter, "All Lengths") or "All Lengths")
    SetDropdownText(self.outcomeDropdown, MetricLabel(self.selectedMetricKey or "damageDone"))

    local statusText = "All Status"
    for _, option in ipairs(StatusFilterOptions()) do
        if option.value == (self.selectedStatusFilter or "all") then
            statusText = option.label
            break
        end
    end
    SetDropdownText(self.statusFilterDropdown, statusText)
end

function Practice:BuildNewSession(parent)
    local panel = MakePanel(parent, 0, LAYOUT.newSessionY, 908, NEW_SESSION_HEIGHT, "New Session")
    local active = Capture().GetActiveSession and Capture().GetActiveSession()
    local actionX = 756

    if active then
        local lengthText = active.targetDurationSeconds and FormatDuration(active.targetDurationSeconds) or "Manual"
        AddLine(panel, "Session running: " .. tostring(active.testType or "Practice") .. "  |  " .. lengthText, 16, -42, 350, COLORS.green, "GameFontNormal")
        local activeSequenceText = active.sequenceUsageAutoDetect and "Auto-detecting KeyLab use" or SequenceUsageLabel(active.sequenceUsage)
        AddLine(panel, "Sequence: " .. activeSequenceText, 16, -66, 700, COLORS.text, "GameFontHighlightSmall")
        local showTimer = MakeButton(panel, "Show Timer", 120, 24)
        showTimer:SetPoint("TOPLEFT", panel, "TOPLEFT", actionX, -34)
        showTimer:SetScript("OnClick", function()
            Practice:ShowMonitor()
        end)
        return panel
    end

    self.startTypeDropdown = MakeDropdown(panel, 105, 16, -36, "Session Type", function(_, level)
        for _, option in ipairs(TestTypeOptions()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.func = function()
                Practice.selectedStartType = option.key
                Practice:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)


    self.startDurationDropdown = MakeDropdown(panel, 95, 151, -36, "Test Length", function(_, level)
        for _, option in ipairs(DurationOptions(false)) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.func = function()
                Practice.selectedStartDuration = option.value
                Practice:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.startSequenceDropdown = MakeDropdown(panel, 390, 276, -36, "Sequence / Active Version", function(_, level)
        for _, option in ipairs(GetSequenceVersionOptions()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.checked = option.sequenceID == Practice.selectedStartSequenceID
            info.func = function()
                Practice.selectedStartSequenceID = option.sequenceID
                Practice:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local start = MakeButton(panel, "Start Session", 126, 26)
    start:SetPoint("TOPLEFT", panel, "TOPLEFT", actionX, -38)
    start:SetScript("OnClick", function()
        local ok, resultOrError
        if Capture().StartSession then
            local duration = Practice.selectedStartDuration
            if duration == "manual" then duration = nil end
            ok, resultOrError = Capture().StartSession(Practice.selectedStartType or "ST", duration, GetSelectedSequenceUsage())
        end
        if ok then
            if KeyLab.UI and KeyLab.UI.Hide then
                KeyLab.UI:Hide()
            end
            Practice:ShowMonitor()
        else
            Print(resultOrError or "Practice session could not start.")
        end
    end)

    return panel
end

function Practice:BuildFilters(parent, baseSessions)
    local panel = MakePanel(parent, 0, LAYOUT.filtersY, 908, 78, "Filters")

    self.specDropdown = MakeDropdown(panel, 120, 16, -34, "Spec", function(_, level)
        local options = Analysis.GetSpecOptions and Analysis.GetSpecOptions(baseSessions) or { { value = nil, text = "All Specs" } }
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                Practice.selectedSpec = option.value
                Practice.selectedSessionID = nil
                Practice.currentPage = 1
                Practice:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.typeFilterDropdown = MakeDropdown(panel, 115, 174, -34, "Session Type", function(_, level)
        local all = UIDropDownMenu_CreateInfo()
        all.text = "All Types"
        all.func = function()
            Practice.selectedTypeFilter = nil
            Practice.selectedSessionID = nil
            Practice.currentPage = 1
            Practice:Refresh()
        end
        UIDropDownMenu_AddButton(all, level)

        for _, option in ipairs(TestTypeOptions()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.func = function()
                Practice.selectedTypeFilter = option.key
                Practice.selectedSessionID = nil
                Practice.currentPage = 1
                Practice:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)


    self.durationFilterDropdown = MakeDropdown(panel, 105, 324, -34, "Test Length", function(_, level)
        for _, option in ipairs(DurationOptions(true)) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.func = function()
                Practice.selectedDurationFilter = option.value
                Practice.selectedSessionID = nil
                Practice.currentPage = 1
                Practice:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.outcomeDropdown = MakeDropdown(panel, 120, 462, -34, "Outcome", function(_, level)
        for _, option in ipairs(MetricOptions()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.func = function()
                Practice.selectedMetricKey = option.key
                Practice.selectedSessionID = nil
                Practice.currentPage = 1
                Practice:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self.statusFilterDropdown = MakeDropdown(panel, 120, 620, -34, "Status", function(_, level)
        for _, option in ipairs(StatusFilterOptions()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.func = function()
                Practice.selectedStatusFilter = option.value
                Practice.selectedSessionID = nil
                Practice.currentPage = 1
                Practice:Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    self:RefreshDropdowns(baseSessions)
    return panel
end

function Practice:BuildSessionTable(parent, sessions, baseCount)
    local panel = MakePanel(parent, 0, LAYOUT.tableY, 908, 380, "Saved Practice Sessions")
    local totalPages = math.max(1, math.ceil(#sessions / PAGE_SIZE))
    self.currentPage = Clamp(self.currentPage or 1, 1, totalPages)
    local startIndex = ((self.currentPage - 1) * PAGE_SIZE) + 1
    local endIndex = math.min(#sessions, startIndex + PAGE_SIZE - 1)

    local summary = tostring(#sessions) .. " session(s) shown"
    if baseCount and baseCount ~= #sessions then
        summary = summary .. "  |  " .. tostring(baseCount) .. " saved"
    end
    summary = summary .. "  |  ranked by " .. MetricLabel(self.selectedMetricKey)
    AddLine(panel, summary, 14, -34, 720, COLORS.blue, "GameFontDisableSmall")
    if #sessions > 0 then
        AddLine(panel, "Gold = best result. Build labels mark talent changes.", 540, -34, 330, COLORS.muted, "GameFontDisableSmall")
    end

    if #sessions == 0 then
        AddLine(panel, "No practice sessions matched these filters.", 14, -64, 830, COLORS.muted, "GameFontNormal")
        return panel
    end

    for _, col in pairs(TABLE_COLUMNS) do
        AddLine(panel, col.label, col.x, -58, col.width, COLORS.muted, "GameFontDisableSmall")
    end

    local maxMetric = nil
    for _, session in ipairs(sessions or {}) do
        local value = MetricValue(session, self.selectedMetricKey)
        if value ~= nil and (not maxMetric or value > maxMetric) then
            maxMetric = value
        end
    end

    for index = startIndex, endIndex do
        local session = sessions[index]
        local rowNumber = index - startIndex + 1
        local y = -84 - ((rowNumber - 1) * 27)
        local metricValue = MetricValue(session, self.selectedMetricKey)
        local metricColor = METRIC_COLORS[self.selectedMetricKey] or COLORS.blue
        if metricValue and maxMetric and metricValue == maxMetric then
            metricColor = COLORS.gold
        end

        local row = CreateFrame("Button", nil, panel, "BackdropTemplate")
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, y + 5)
        row:SetSize(828, 25)
        SetBackdrop(row, COLORS.bg, session == self.selectedSession and COLORS.gold or COLORS.cardBorder)
        row:SetScript("OnClick", function()
            Practice:SelectSession(session)
        end)

        AddLine(row, tostring(index) .. ".", TABLE_COLUMNS.rank.x - 8, -5, TABLE_COLUMNS.rank.width, COLORS.gold, "GameFontDisableSmall")
        AddLine(row, ShortText(session.testType or "ST", 12), TABLE_COLUMNS.type.x - 8, -5, TABLE_COLUMNS.type.width, COLORS.text, "GameFontDisableSmall")
        AddLine(row, FormatDate(session.timestamp), TABLE_COLUMNS.date.x - 8, -5, TABLE_COLUMNS.date.width, COLORS.text, "GameFontDisableSmall")
        AddLine(row, FormatDuration(session.durationSeconds), TABLE_COLUMNS.duration.x - 8, -5, TABLE_COLUMNS.duration.width, COLORS.text, "GameFontDisableSmall")
        AddLine(row, FormatMetric(self.selectedMetricKey, metricValue), TABLE_COLUMNS.metric.x - 8, -5, TABLE_COLUMNS.metric.width, metricColor, "GameFontDisableSmall")
        AddLine(row, ShortText(session.player and session.player.spec or "-", 14), TABLE_COLUMNS.spec.x - 8, -5, TABLE_COLUMNS.spec.width, COLORS.text, "GameFontDisableSmall")
        AddLine(row, ShortText(SessionSequenceSummary(session), 22), TABLE_COLUMNS.sequence.x - 8, -5, TABLE_COLUMNS.sequence.width, COLORS.muted, "GameFontDisableSmall")
        local buildInfo = TalentBuildInfo(session)
        AddLine(row, buildInfo.label, TABLE_COLUMNS.build.x - 8, -5, TABLE_COLUMNS.build.width, buildInfo.color, "GameFontDisableSmall")

        local statusButton = MakeSmallButton(row, StatusLabel(session.status) .. " v", TABLE_COLUMNS.status.width, 20)
        statusButton:SetPoint("TOPLEFT", row, "TOPLEFT", TABLE_COLUMNS.status.x - 8, -2)
        statusButton:SetScript("OnClick", function(btn)
            OpenStatusMenu(btn, session.id, session.status)
        end)

        local delete = MakeButton(panel, "Delete", 62, 22)
        delete:SetPoint("TOPLEFT", panel, "TOPLEFT", 842, y + 2)
        delete:SetScript("OnClick", function()
            RegisterDeletePopup()
            StaticPopup_Show("KEYLAB_DELETE_PRACTICE_SESSION", nil, nil, session.id)
        end)
    end

    local pageText = AddLine(panel, string.format("Page %d / %d", self.currentPage, totalPages), 14, -352, 160, COLORS.muted, "GameFontDisableSmall")
    pageText:SetJustifyH("LEFT")

    local back = MakeButton(panel, "Back", 82, 24)
    back:SetPoint("TOPLEFT", panel, "TOPLEFT", 686, -344)
    back:SetScript("OnClick", function()
        Practice.currentPage = math.max(1, (Practice.currentPage or 1) - 1)
        Practice.selectedSessionID = nil
        Practice:Refresh()
    end)
    if self.currentPage <= 1 then back:Disable() end

    local nextButton = MakeButton(panel, "Next", 82, 24)
    nextButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 782, -344)
    nextButton:SetScript("OnClick", function()
        Practice.currentPage = math.min(totalPages, (Practice.currentPage or 1) + 1)
        Practice.selectedSessionID = nil
        Practice:Refresh()
    end)
    if self.currentPage >= totalPages then nextButton:Disable() end

    return panel
end

function Practice:BuildDetails(parent, session)
    local panel = MakePanel(parent, 0, LAYOUT.detailsY, 908, 192, "Session Details")
    if not session then
        AddLine(panel, "Select a saved Practice Session to see its setup and results.", 14, -44, 830, COLORS.muted, "GameFontNormal")
        return panel
    end

    AddLine(panel, tostring(session.testType or "Practice") .. "  |  " .. FormatDate(session.timestamp) .. "  |  " .. FormatDuration(session.durationSeconds) .. "  |  " .. StatusLabel(session.status), 14, -36, 760, COLORS.text, "GameFontNormal")
    local hasNotice = false
    if session.capturePending then
        hasNotice = true
        AddLine(panel, "Session stopped. KeyLab will add Blizzard's totals automatically when they become available.", 14, -58, 760, COLORS.orange, "GameFontDisableSmall")
    elseif session.captureError then
        hasNotice = true
        AddLine(panel, "Saved setup only: no damage meter totals were available for this session.", 14, -58, 760, COLORS.orange, "GameFontDisableSmall")
    end

    local metrics = {
        { key = "damageDone", label = "Damage Done" },
        { key = "dps", label = "DPS" },
        { key = "healingDoneWithAbsorbs", label = "Healing" },
        { key = "hpsWithAbsorbs", label = "HPS" },
    }
    local metricLabelY = hasNotice and -78 or -66
    local metricValueY = hasNotice and -96 or -84
    for index, metric in ipairs(metrics) do
        local x = 14 + ((index - 1) * 150)
        AddLine(panel, metric.label, x, metricLabelY, 120, COLORS.muted, "GameFontDisableSmall")
        AddLine(panel, FormatMetric(metric.key, MetricValue(session, metric.key)), x, metricValueY, 120, METRIC_COLORS[metric.key] or COLORS.blue, "GameFontNormalLarge")
    end

    AddLine(panel, "Stats", 14, -122, 70, COLORS.gold, "GameFontNormal")
    AddLine(panel, StatLine(session.stats), 84, -122, 420, COLORS.text, "GameFontHighlightSmall")
    AddLine(panel, "Sequence(s)", 515, -122, 76, COLORS.gold, "GameFontNormal")
    local sequenceDetails = AddLine(panel, ShortText(SessionSequenceDetails(session), 92), 594, -122, 280, COLORS.text, "GameFontHighlightSmall")
    sequenceDetails:SetHeight(38)

    local talentString = TalentString(session)
    local buildInfo = TalentBuildInfo(session)
    AddLine(panel, "Talent Build", 14, -146, 86, COLORS.gold, "GameFontNormal")
    AddLine(panel, buildInfo.label, 104, -146, 110, buildInfo.color, "GameFontHighlightSmall")
    AddLine(panel, "Spell Queue", 250, -146, 90, COLORS.gold, "GameFontNormal")
    local spellQueueWindow = SafeNumber(session.spellQueueWindow)
    AddLine(panel, spellQueueWindow and (FormatNumber(spellQueueWindow) .. " ms") or "Not captured", 344, -146, 120, COLORS.text, "GameFontHighlightSmall")

    AddLine(panel, "Talent String", 14, -170, 86, COLORS.gold, "GameFontNormal")
    AddLine(panel, talentString and ShortText(talentString, 88) or "No talent string captured", 104, -170, 670, COLORS.text, "GameFontDisableSmall")
    if talentString then
        local copy = MakeButton(panel, "Copy", 70, 22)
        copy:SetPoint("TOPLEFT", panel, "TOPLEFT", 790, -164)
        copy:SetScript("OnClick", function()
            RegisterCopyTalentPopup()
            StaticPopup_Show("KEYLAB_PRACTICE_COPY_TALENT", nil, nil, talentString)
        end)
    end

    return panel
end

function Practice:Refresh()
    if not self.content then return end

    for _, child in ipairs({ self.content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, region in ipairs({ self.content:GetRegions() }) do
        region:Hide()
    end

    self.selectedMetricKey = self.selectedMetricKey or "damageDone"
    self.selectedStartType = self.selectedStartType or "ST"
    self.selectedStartDuration = self.selectedStartDuration or 60
    self.selectedStatusFilter = self.selectedStatusFilter or "all"

    local title = MakeText(self.content, "Practice", "GameFontNormalLarge", HEADER.titleSize, COLORS.gold)
    title:SetPoint("TOPLEFT", self.content, "TOPLEFT", HEADER.x, HEADER.titleY)
    title:SetSize(880, 24)

    local subtitle = MakeText(self.content, "Test your setup at a training dummy and compare the results you save.", "GameFontHighlightSmall", nil, COLORS.muted)
    subtitle:SetPoint("TOPLEFT", self.content, "TOPLEFT", 18, -44)
    subtitle:SetSize(860, 16)

    local baseSessions = GetSessions()
    self.talentBuildLabels = BuildTalentLabels(baseSessions)
    self:BuildNewSession(self.content)
    self:BuildFilters(self.content, baseSessions)

    local filtered = Analysis.FilterSessions and Analysis.FilterSessions(baseSessions, {
        spec = self.selectedSpec,
        testType = self.selectedTypeFilter,
        duration = self.selectedDurationFilter,
        status = self.selectedStatusFilter,
    }) or baseSessions

    if Analysis.SortSessionsByMetric then
        Analysis.SortSessionsByMetric(filtered, self.selectedMetricKey)
    end

    self.selectedSession = FindSelectedSession(filtered)
    self.selectedSessionID = self.selectedSession and self.selectedSession.id or nil

    self:BuildSessionTable(self.content, filtered, #baseSessions)
    self:BuildDetails(self.content, self.selectedSession)
end

function Practice:Create(parent)
    RegisterDeletePopup()
    RegisterCopyTalentPopup()

    local frame = CreateFrame("Frame", "KeyLabPracticeTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})

    local content = CreateFrame("Frame", nil, frame)
    content:SetAllPoints(frame)

    self.frame = frame
    self.content = content

    frame.Refresh = function()
        Practice:Refresh()
    end
    frame:SetScript("OnShow", function()
        Practice:Refresh()
    end)

    return frame
end

function KeyLab_CreatePracticeTab(parent)
    return Practice:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Practice", function(parent)
        return Practice:Create(parent)
    end)
end

return Practice
