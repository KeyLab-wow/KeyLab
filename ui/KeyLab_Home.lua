-- KeyLab_Home.lua
-- Home overview plus the News & Events and Game Updates article readers.

local ADDON_NAME, KeyLab = ...

KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local HOME = {}
KeyLab.Tabs.Home = HOME

local Theme = KeyLab.UI.Theme
local Data = KeyLab.GameUpdatesData or {}
local Colors = Theme.colors
local Layout = Theme.homeLayout
local EncounterData = KeyLab.Analysis and KeyLab.Analysis.EncounterData or {}

local function CountEncounters()
    if not EncounterData.GetEncounterList then return 0 end
    return #EncounterData.GetEncounterList({
        includeInterrupted = false,
        includeExcluded = false,
        completedOnly = true,
        allowMissingIdentity = true,
    })
end

local function CountRaidBossPulls()
    if not (KeyLab.RaidAnalysis and type(KeyLab.RaidAnalysis.GetEncounters) == "function") then return 0 end
    local encounters = KeyLab.RaidAnalysis.GetEncounters()
    return type(encounters) == "table" and #encounters or 0
end

local function GetActivityCounts()
    local counters = KeyLab.DB and KeyLab.DB.ActivityCounters
    if counters and counters.GetCurrentCounts then return counters.GetCurrentCounts() end
    return { mplusRuns = CountEncounters(), raidBossPulls = CountRaidBossPulls() }
end

local function GetTrackingSinceText()
    if KeyLab.DB and KeyLab.DB.GetTrackingSince then return KeyLab.DB.GetTrackingSince() end
    return "Not started yet"
end

local function GetLatestRunState()
    local analysis = KeyLab.LastRunAnalysis
    if analysis and type(analysis.BuildState) == "function" then
        local ok, state = pcall(analysis.BuildState)
        if ok and type(state) == "table" then return state end
    end
    return { hasRun = false }
end

local function FormatHomeDate(value)
    value = tonumber(value)
    if not value then return "-" end
    return date("%b %d %I:%M %p", value)
end

local function Text(parent, value, size, color, justify)
    return Theme.CreateText(parent, value or "", "GameFontNormal", size or 12, color or Colors.text, justify or "LEFT")
end

local function ConfigureText(region, value, size, color, width, justify)
    region:ClearAllPoints()
    region:SetFont(Theme.fonts.body, size or 12, "")
    Theme.ApplyColor(region, color or Colors.text)
    region:SetJustifyH(justify or "LEFT")
    region:SetJustifyV("TOP")
    region:SetWordWrap(true)
    region:SetWidth(math.max(1, width or 1))
    region:SetHeight(1000)
    region:SetText(value or "")
    local height = math.max((size or 12) + 4, math.ceil(region:GetStringHeight() or 0))
    region:SetHeight(height)
    region:Show()
    return height
end

local function CreatePreviewCard(parent, label)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    Theme.StylePanel(card, Colors.cardBg, Colors.cardBorder)
    card.accent = Theme.AddAccent(card, Colors.gold, 3)
    card.label = Text(card, label, 10, Colors.blue)
    card.label:SetPoint("TOPLEFT", card, "TOPLEFT", 16, -14)
    card.label:SetSize(230, 16)
    card.title = Text(card, "", 15, Colors.gold)
    card.title:SetPoint("TOPLEFT", card.label, "BOTTOMLEFT", 0, -7)
    card.title:SetPoint("RIGHT", card, "RIGHT", -16, 0)
    card.title:SetHeight(42)
    card.meta = Text(card, "", 11, Colors.muted)
    card.meta:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 16, 16)
    card.meta:SetPoint("RIGHT", card, "RIGHT", -16, 0)
    card.meta:SetHeight(18)
    card:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(Colors.blue))
        Theme.ApplyColor(self.title, Colors.text)
    end)
    card:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(Colors.cardBorder))
        Theme.ApplyColor(self.title, Colors.gold)
    end)
    return card
end

local function CreateHomeOverview(parent, owner)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)

    panel.welcome = Theme.CreatePanel(panel, 0, 0, 100, 112, Colors.panel, Colors.cardBorder)
    panel.welcomeTitle = Text(panel.welcome, "Welcome to KeyLab", 20, Colors.gold)
    panel.welcomeTitle:SetPoint("TOPLEFT", panel.welcome, "TOPLEFT", 18, -16)
    panel.welcomeTitle:SetSize(480, 28)
    panel.welcomeBody = Text(
        panel.welcome,
        "Your personal journal for Mythic+, raids, practice, gearing, and the latest news and game updates.",
        12,
        Colors.text
    )
    panel.welcomeBody:SetPoint("TOPLEFT", panel.welcomeTitle, "BOTTOMLEFT", 0, -8)
    panel.welcomeBody:SetPoint("RIGHT", panel.welcome, "RIGHT", -18, 0)
    panel.welcomeBody:SetHeight(40)

    panel.newsPreview = CreatePreviewCard(panel, "NEWEST NEWS & EVENTS")
    panel.updatePreview = CreatePreviewCard(panel, "NEWEST GAME UPDATE")

    panel.journal = Theme.CreatePanel(panel, 0, 0, 100, 126, Colors.detailBg, Colors.detailBorder)
    panel.journalTitle = Text(panel.journal, "Your KeyLab Journal", 14, Colors.gold)
    panel.journalTitle:SetPoint("TOPLEFT", panel.journal, "TOPLEFT", 16, -13)
    panel.journalTitle:SetSize(220, 20)

    panel.dependency = Theme.CreatePanel(panel, 0, 0, 100, 112, Colors.noteBg, Colors.cardStrongBorder)
    Theme.AddAccent(panel.dependency, Colors.gold, 3)
    panel.dependencyTitle = Text(panel.dependency, "Blizzard Damage Meter Required", 15, Colors.gold)
    panel.dependencyTitle:SetPoint("TOPLEFT", panel.dependency, "TOPLEFT", 18, -15)
    panel.dependencyTitle:SetPoint("RIGHT", panel.dependency, "RIGHT", -18, 0)
    panel.dependencyTitle:SetHeight(22)
    panel.dependencyBody = Text(
        panel.dependency,
        "KeyLab depends on Blizzard's Damage Meter to save Mythic+ runs, raid boss pulls, and Practice results. Open Game Menu > Options > Gameplay Enhancements, then turn on Damage Meter and Auto Reset Damage Meter.",
        12,
        Colors.text
    )
    panel.dependencyBody:SetPoint("TOPLEFT", panel.dependencyTitle, "BOTTOMLEFT", 0, -9)
    panel.dependencyBody:SetPoint("RIGHT", panel.dependency, "RIGHT", -18, 0)
    panel.dependencyBody:SetHeight(56)

    local metricDefinitions = {
        { key = "since", label = "Tracking Since", width = 250 },
        { key = "runs", label = "Completed M+ Runs", width = 150 },
        { key = "pulls", label = "Raid Boss Pulls", width = 150 },
        { key = "latest", label = "Latest M+ Run", width = 250 },
    }
    panel.metrics = {}
    for _, definition in ipairs(metricDefinitions) do
        local metric = CreateFrame("Frame", nil, panel.journal)
        metric:SetSize(definition.width, 58)
        metric.label = Text(metric, definition.label, 10, Colors.muted)
        metric.label:SetPoint("TOPLEFT", metric, "TOPLEFT", 0, 0)
        metric.label:SetSize(definition.width, 16)
        metric.value = Text(metric, "-", 13, Colors.blue)
        metric.value:SetPoint("TOPLEFT", metric.label, "BOTTOMLEFT", 0, -5)
        metric.value:SetSize(definition.width, 30)
        panel.metrics[definition.key] = metric
    end

    function panel:Layout()
        local width = math.max(500, self:GetWidth() or 500)
        self.welcome:ClearAllPoints()
        self.welcome:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
        self.welcome:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
        self.welcome:SetHeight(112)

        local gap = Theme.spacing.card
        local previewWidth = math.floor((width - gap) / 2)
        self.newsPreview:ClearAllPoints()
        self.newsPreview:SetPoint("TOPLEFT", self.welcome, "BOTTOMLEFT", 0, -gap)
        self.newsPreview:SetSize(previewWidth, 146)
        self.updatePreview:ClearAllPoints()
        self.updatePreview:SetPoint("TOPRIGHT", self.welcome, "BOTTOMRIGHT", 0, -gap)
        self.updatePreview:SetSize(previewWidth, 146)

        self.journal:ClearAllPoints()
        self.journal:SetPoint("TOPLEFT", self.newsPreview, "BOTTOMLEFT", 0, -gap)
        self.journal:SetPoint("TOPRIGHT", self.updatePreview, "BOTTOMRIGHT", 0, -gap)
        self.journal:SetHeight(126)

        self.dependency:ClearAllPoints()
        self.dependency:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
        self.dependency:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
        self.dependency:SetHeight(112)

        local x = 16
        for _, key in ipairs({ "since", "runs", "pulls", "latest" }) do
            local metric = self.metrics[key]
            metric:ClearAllPoints()
            metric:SetPoint("TOPLEFT", self.journal, "TOPLEFT", x, -48)
            x = x + metric:GetWidth() + 18
        end
    end

    function panel:Refresh()
        local newestNews = Data.GetNewest and Data.GetNewest("news")
        local newestUpdate = Data.GetNewest and Data.GetNewest("updates")
        if newestNews then
            self.newsPreview.title:SetText(newestNews.title or "News & Events")
            self.newsPreview.meta:SetText((newestNews.category or "NEWS") .. "  •  " .. (newestNews.publicationDate or ""))
            self.newsPreview:SetScript("OnClick", function() owner:SelectSubTab("news", newestNews.id) end)
        end
        if newestUpdate then
            self.updatePreview.title:SetText(newestUpdate.title or "Game Updates")
            self.updatePreview.meta:SetText((newestUpdate.category or "UPDATE") .. "  •  " .. (newestUpdate.publicationDate or ""))
            self.updatePreview:SetScript("OnClick", function() owner:SelectSubTab("updates", newestUpdate.id) end)
        end

        local counts = GetActivityCounts()
        self.metrics.since.value:SetText(GetTrackingSinceText())
        self.metrics.runs.value:SetText(tostring(counts.mplusRuns or 0))
        self.metrics.pulls.value:SetText(tostring(counts.raidBossPulls or 0))
        local state = GetLatestRunState()
        if state and state.hasRun then
            self.metrics.latest.value:SetText(
                tostring(state.dungeonName or "Unknown Dungeon") .. "  +" .. tostring(state.keyLevel or 0)
                    .. "  •  " .. FormatHomeDate(state.timestamp)
            )
        else
            self.metrics.latest.value:SetText("No completed run yet")
        end
        self:Layout()
    end

    panel:SetScript("OnSizeChanged", function(self) self:Layout() end)
    return panel
end

local function ResetArticlePool(reader)
    reader.poolCursor = {}
    for kind, objects in pairs(reader.pool or {}) do
        for _, object in ipairs(objects) do
            object:Hide()
            object:ClearAllPoints()
            -- OnClick is a valid script only for the pooled Button objects.
            -- Calling SetScript("OnClick") on an ordinary Frame interrupts the
            -- next article render in WoW before the newly selected post opens.
            if kind == "tab" then
                object:SetScript("OnClick", nil)
            end
        end
    end
end

local function Acquire(reader, kind)
    reader.pool = reader.pool or {}
    reader.poolCursor = reader.poolCursor or {}
    reader.pool[kind] = reader.pool[kind] or {}
    local index = (reader.poolCursor[kind] or 0) + 1
    reader.poolCursor[kind] = index
    local object = reader.pool[kind][index]
    if object then object:Show(); return object end

    local canvas = reader.scroll.content
    if kind == "text" then
        object = Text(canvas, "", 12, Colors.text)
    elseif kind == "panel" or kind == "note" then
        object = CreateFrame("Frame", nil, canvas, "BackdropTemplate")
    elseif kind == "tab" then
        object = Theme.CreateTextTabButton(canvas, "", 100, 30)
    end
    reader.pool[kind][index] = object
    return object
end

local function AddText(reader, value, size, color, x, y, width, justify)
    local region = Acquire(reader, "text")
    local height = ConfigureText(region, value, size, color, width, justify)
    region:SetPoint("TOPLEFT", reader.scroll.content, "TOPLEFT", x, -y)
    return region, height
end

local function AddDeveloperNote(reader, note, x, y, width)
    local panel = Acquire(reader, "note")
    Theme.StylePanel(panel, Colors.noteBg, Colors.cardBorder)
    if not panel.keylabAccent then panel.keylabAccent = Theme.AddAccent(panel, Colors.gold, 3) end
    if not panel.noteLabel then
        -- These regions must belong to the note card. When they were children
        -- of the scroll canvas, the card backdrop rendered over them and made
        -- the blue/white text appear nearly black.
        panel.noteLabel = Text(panel, "", 10, Colors.blue)
        panel.noteBody = Text(panel, "", 12, Colors.text)
    end
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", reader.scroll.content, "TOPLEFT", x, -y)
    panel:SetWidth(width)

    local label = panel.noteLabel
    local labelHeight = ConfigureText(label, "DEVELOPERS’ NOTES", 10, Colors.blue, width - 30)
    label:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -12)
    local body = panel.noteBody
    local bodyHeight = ConfigureText(body, note or "", 12, Colors.text, width - 30)
    body:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -7)
    local height = 12 + labelHeight + 7 + bodyHeight + 14
    panel:SetHeight(height)
    return height
end

local function AddChange(reader, change, level, x, y, width)
    level = tonumber(level) or 0
    local changeText = type(change) == "table" and change.text or tostring(change or "")
    local indent = level * 20
    local bullet = level > 0 and "◦" or "•"
    local bulletText = Acquire(reader, "text")
    ConfigureText(bulletText, bullet, 14, Colors.blue, 14, "CENTER")
    bulletText:SetPoint("TOPLEFT", reader.scroll.content, "TOPLEFT", x + indent, -y + 1)
    local _, bodyHeight = AddText(reader, changeText, 12, Colors.text, x + indent + 22, y, width - indent - 22)
    y = y + math.max(18, bodyHeight) + 8
    for _, child in ipairs(type(change) == "table" and (change.children or {}) or {}) do
        local childValue = type(child) == "table" and child or { text = tostring(child) }
        y = AddChange(reader, childValue, level + 1, x, y, width)
    end
    return y
end

local function FindByID(items, id)
    for _, item in ipairs(items or {}) do if item.id == id then return item end end
end

local function RenderClassContentBlocks(reader, blocks, x, y, width)
    for _, block in ipairs(blocks or {}) do
        if block.type == "developer_note" then
            y = y + AddDeveloperNote(reader, block.text or "", x, y, width) + 14
        elseif block.type == "heading" then
            local _, height = AddText(reader, block.text or "", 14, Colors.text, x, y, width)
            y = y + height + 9
        else
            y = AddChange(reader, { text = block.text or "" }, 0, x, y, width)
        end
    end
    return y
end

local function RenderNormalArticle(reader, article, x, y, width)
    for _, section in ipairs(article.sections or {}) do
        if section.heading then
            local _, height = AddText(reader, section.heading, 18, Colors.text, x, y, width)
            y = y + height + 14
        end
        for _, paragraph in ipairs(section.paragraphs or {}) do
            local _, height = AddText(reader, paragraph, 12, Colors.text, x, y, width)
            y = y + height + 14
        end
        for _, note in ipairs(section.developerNotes or {}) do y = y + AddDeveloperNote(reader, note, x, y, width) + 14 end
        for _, change in ipairs(section.changes or {}) do y = AddChange(reader, change, 0, x, y, width) end
        for _, paragraph in ipairs(section.afterParagraphs or {}) do
            local _, height = AddText(reader, paragraph, 12, Colors.text, x, y, width)
            y = y + height + 14
        end
        y = y + 12
    end
    return y
end

local function RenderClassArticle(reader, article, x, y, width)
    if article.introduction and article.introduction ~= "" then
        local _, introHeight = AddText(reader, article.introduction, 12, Colors.text, x, y, width)
        y = y + introHeight + 18
    end

    local modes = article.modes or {}
    local selectedMode = FindByID(modes, reader.selectedModeID) or modes[1]
    if not selectedMode then return y end
    reader.selectedModeID = selectedMode.id

    local modeHost = Acquire(reader, "panel")
    Theme.StylePanel(modeHost, Colors.transparent, Colors.cardBorder)
    modeHost:ClearAllPoints()
    modeHost:SetPoint("TOPLEFT", reader.scroll.content, "TOPLEFT", x, -y)
    modeHost:SetSize(width, 38)
    local modeWidth = width / math.max(1, #modes)
    for index, mode in ipairs(modes) do
        local modeData = mode
        local button = Acquire(reader, "tab")
        button.label:SetText(modeData.label or modeData.id or "MODE")
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", modeHost, "TOPLEFT", (index - 1) * modeWidth, 0)
        button:SetSize(modeWidth, 38)
        button:SetSelected(modeData.id == selectedMode.id)
        button:SetScript("OnClick", function()
            reader.selectedModeID = modeData.id
            reader.selectedClassID = nil
            reader:Render(true)
        end)
    end
    y = y + 50

    local classes = selectedMode.classes or {}
    if #classes == 0 then
        local _, height = AddText(reader, "No class entries are included in this section yet.", 12, Colors.muted, x, y, width)
        return y + height + 20
    end

    local selectedClass = FindByID(classes, reader.selectedClassID) or classes[1]
    reader.selectedClassID = selectedClass.id
    local classHost = Acquire(reader, "panel")
    Theme.StylePanel(classHost, Colors.transparent, Colors.transparent, 0)
    classHost:ClearAllPoints()
    classHost:SetPoint("TOPLEFT", reader.scroll.content, "TOPLEFT", x, -y)
    classHost:SetWidth(width)
    local classButtons = {}
    for _, classData in ipairs(classes) do
        local classButtonData = classData
        local button = Acquire(reader, "tab")
        button.label:SetText(string.upper(classButtonData.name or "CLASS"))
        button.keylabDesiredWidth = math.ceil(button.label:GetStringWidth() + 24)
        button:SetSelected(classButtonData.id == selectedClass.id)
        button:SetScript("OnClick", function()
            reader.selectedClassID = classButtonData.id
            reader:Render(true)
        end)
        classButtons[#classButtons + 1] = button
    end
    local classNavHeight = Theme.LayoutWrappedButtons(classButtons, classHost, width, {
        buttonHeight = 30,
        columnGap = 8,
        rowGap = 5,
        minWidth = 74,
        horizontalPadding = 24,
    })
    y = y + classNavHeight + 20

    local _, headingHeight = AddText(reader, string.upper(selectedClass.name or "CLASS"), 19, Colors.text, x, y, width)
    y = y + headingHeight + 14
    if #(selectedClass.content or {}) > 0 then
        y = RenderClassContentBlocks(reader, selectedClass.content, x, y, width)
        y = y + 8
    end
    local specs = selectedClass.specializations or {}
    if #specs == 0 then
        if #(selectedClass.content or {}) > 0 then return y + 10 end
        local _, emptyHeight = AddText(reader, "No specialization changes are included in the supplied article data.", 12, Colors.muted, x, y, width)
        return y + emptyHeight + 18
    end

    for index, spec in ipairs(specs) do
        local specData = spec
        if index > 1 then
            local divider = Acquire(reader, "panel")
            Theme.StylePanel(divider, Colors.divider, Colors.transparent, 0)
            divider:ClearAllPoints()
            divider:SetPoint("TOPLEFT", reader.scroll.content, "TOPLEFT", x, -y)
            divider:SetSize(width, 1)
            y = y + 16
        end
        local _, specHeadingHeight = AddText(reader, specData.name or "Specialization", 15, Colors.gold, x, y, width)
        y = y + specHeadingHeight + 12
        if #(specData.content or {}) > 0 then
            y = RenderClassContentBlocks(reader, specData.content, x, y, width)
        else
            for _, note in ipairs(specData.developerNotes or {}) do y = y + AddDeveloperNote(reader, note, x, y, width) + 14 end
            for _, change in ipairs(specData.changes or {}) do y = AddChange(reader, change, 0, x, y, width) end
        end
        if #(specData.content or {}) == 0 and #(specData.developerNotes or {}) == 0 and #(specData.changes or {}) == 0 then
            local _, emptyHeight = AddText(reader, "No supplied change text is available for this specialization.", 12, Colors.muted, x, y, width)
            y = y + emptyHeight + 12
        end
        y = y + 10
    end
    return y
end

local function RenderWrappedArticleNavigation(reader, items, selectedID, x, y, width, onSelect, options)
    options = options or {}
    if #(items or {}) == 0 then return y end

    if options.caption then
        local _, captionHeight = AddText(reader, options.caption, 10, Colors.blue, x, y, width)
        y = y + captionHeight + 5
    end

    local host = Acquire(reader, "panel")
    Theme.StylePanel(host, Colors.transparent, Colors.transparent, 0)
    host:ClearAllPoints()
    host:SetPoint("TOPLEFT", reader.scroll.content, "TOPLEFT", x, -y)
    host:SetWidth(width)
    local buttons = {}
    for _, item in ipairs(items or {}) do
        local itemData = item
        local button = Acquire(reader, "tab")
        button.label:SetText(string.upper(itemData.label or itemData.title or itemData.id or "OPTION"))
        button.keylabDesiredWidth = math.ceil(button.label:GetStringWidth() + (options.horizontalPadding or 24))
        button:SetSelected(itemData.id == selectedID)
        button:SetScript("OnClick", function() onSelect(itemData) end)
        buttons[#buttons + 1] = button
    end
    local navHeight = Theme.LayoutWrappedButtons(buttons, host, width, {
        buttonHeight = options.buttonHeight or 30,
        columnGap = options.columnGap or 8,
        rowGap = options.rowGap or 5,
        minWidth = options.minWidth or 74,
        maxWidth = width,
        horizontalPadding = options.horizontalPadding or 24,
    })
    return y + navHeight + (options.bottomGap or 14)
end

local function RenderSegmentedArticleNavigation(reader, items, selectedID, x, y, width, onSelect)
    if #(items or {}) == 0 then return y end
    local host = Acquire(reader, "panel")
    Theme.StylePanel(host, Colors.transparent, Colors.cardBorder)
    host:ClearAllPoints()
    host:SetPoint("TOPLEFT", reader.scroll.content, "TOPLEFT", x, -y)
    host:SetSize(width, 38)
    local buttonWidth = width / #items
    for index, item in ipairs(items) do
        local itemData = item
        local button = Acquire(reader, "tab")
        button.label:SetText(string.upper(itemData.label or itemData.title or itemData.id or "OPTION"))
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", host, "TOPLEFT", (index - 1) * buttonWidth, 0)
        button:SetSize(buttonWidth, 38)
        button:SetSelected(itemData.id == selectedID)
        button:SetScript("OnClick", function() onSelect(itemData) end)
    end
    return y + 50
end

local function RenderHotfixBlocks(reader, blocks, x, y, width)
    for _, block in ipairs(blocks or {}) do
        if block.type == "developer_note" then
            y = y + AddDeveloperNote(reader, block.text or "", x, y, width) + 14
        elseif block.type == "heading" then
            local _, height = AddText(reader, block.text or "", 15, Colors.text, x, y, width)
            y = y + height + 10
        else
            y = AddChange(reader, { text = block.text or "" }, 0, x, y, width)
        end
    end
    return y
end

local function RenderHotfixArticle(reader, article, x, y, width)
    if article.introduction and article.introduction ~= "" then
        local _, introHeight = AddText(reader, article.introduction, 12, Colors.text, x, y, width)
        y = y + introHeight + 18
    end

    local dates = article.hotfixDates or {}
    local selectedDate = FindByID(dates, reader.selectedHotfixDateID) or dates[1]
    if not selectedDate then return y end
    reader.selectedHotfixDateID = selectedDate.id
    y = RenderSegmentedArticleNavigation(reader, dates, selectedDate.id, x, y, width, function(dateData)
        reader.selectedHotfixDateID = dateData.id
        local firstCategory = dateData.categories and dateData.categories[1]
        reader.selectedHotfixCategoryID = firstCategory and firstCategory.id or nil
        local firstSubmenu = firstCategory and firstCategory.submenus and firstCategory.submenus[1]
        reader.selectedHotfixSubmenuID = firstSubmenu and firstSubmenu.id or nil
        reader:Render(true)
    end)

    local categories = selectedDate.categories or {}
    local selectedCategory = FindByID(categories, reader.selectedHotfixCategoryID) or categories[1]
    if not selectedCategory then return y end
    reader.selectedHotfixCategoryID = selectedCategory.id
    y = RenderWrappedArticleNavigation(reader, categories, selectedCategory.id, x, y, width, function(categoryData)
        reader.selectedHotfixCategoryID = categoryData.id
        local firstSubmenu = categoryData.submenus and categoryData.submenus[1]
        reader.selectedHotfixSubmenuID = firstSubmenu and firstSubmenu.id or nil
        reader:Render(true)
    end, {
        caption = "CATEGORY",
        minWidth = 82,
        horizontalPadding = 24,
        bottomGap = 18,
    })

    local selectedSubmenu
    local submenus = selectedCategory.submenus or {}
    if #submenus > 0 then
        selectedSubmenu = FindByID(submenus, reader.selectedHotfixSubmenuID) or submenus[1]
        reader.selectedHotfixSubmenuID = selectedSubmenu.id
        y = RenderWrappedArticleNavigation(reader, submenus, selectedSubmenu.id, x, y, width, function(submenuData)
            reader.selectedHotfixSubmenuID = submenuData.id
            reader:Render(true)
        end, {
            caption = "SECTION",
            minWidth = 78,
            horizontalPadding = 24,
            bottomGap = 18,
        })
    else
        reader.selectedHotfixSubmenuID = nil
    end

    local _, categoryHeight = AddText(reader, selectedCategory.label or "HOTFIXES", 19, Colors.text, x, y, width)
    y = y + categoryHeight + 12
    if selectedSubmenu then
        local _, submenuHeight = AddText(reader, selectedSubmenu.label or "General", 15, Colors.gold, x, y, width)
        y = y + submenuHeight + 12
        for _, section in ipairs(selectedSubmenu.sections or {}) do
            if section.heading then
                local _, headingHeight = AddText(reader, section.heading, 14, Colors.text, x, y, width)
                y = y + headingHeight + 9
            end
            y = RenderHotfixBlocks(reader, section.content, x, y, width)
            y = y + 8
        end
        if #(selectedSubmenu.sections or {}) == 0 then
            y = RenderHotfixBlocks(reader, selectedSubmenu.content, x, y, width)
        end
    else
        y = RenderHotfixBlocks(reader, selectedCategory.content, x, y, width)
    end
    return y + 10
end

local function CreateArticleListEntry(reader, article)
    local entry = CreateFrame("Button", nil, reader.listScroll.content, "BackdropTemplate")
    entry:SetHeight(Layout.listRowHeight)
    Theme.StylePanel(entry, Colors.transparent, Colors.transparent, 0)
    entry.accent = Theme.AddAccent(entry, Colors.gold, 3)
    entry.title = Text(entry, article.menuTitle or article.title or "Untitled", 12, Colors.text)
    entry.title:SetPoint("TOPLEFT", entry, "TOPLEFT", 14, -11)
    entry.title:SetPoint("RIGHT", entry, "RIGHT", -10, 0)
    entry.title:SetHeight(38)
    entry.category = Text(entry, string.upper(article.category or "ARTICLE"), 10, Colors.blue)
    entry.category:SetPoint("TOPLEFT", entry.title, "BOTTOMLEFT", 0, -4)
    entry.category:SetPoint("RIGHT", entry, "RIGHT", -10, 0)
    entry.category:SetHeight(15)
    entry.date = Text(entry, article.publicationDate or "", 10, Colors.muted)
    entry.date:SetPoint("TOPLEFT", entry.category, "BOTTOMLEFT", 0, -2)
    entry.date:SetPoint("RIGHT", entry, "RIGHT", -10, 0)
    entry.date:SetHeight(15)
    entry.bottomRule = Theme.CreateRule(entry, "BOTTOM", Colors.divider, 1)
    entry.article = article
    entry:SetScript("OnClick", function() reader:SelectArticle(article.id) end)
    entry:SetScript("OnEnter", function(self)
        if not self.selected then self:SetBackdropColor(unpack(Theme.WithAlpha(Colors.controlBg, 0.45))) end
    end)
    entry:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(self.selected and Colors.analysisRowSelectedBg or Colors.transparent))
    end)
    return entry
end

local function CreateArticleReader(parent, tabID)
    local reader = CreateFrame("Frame", nil, parent)
    reader:SetAllPoints(parent)
    reader.tabID = tabID
    reader.articles = Data.GetArticles and Data.GetArticles(tabID) or {}
    reader.entries = {}

    reader.listPanel = CreateFrame("Frame", nil, reader, "BackdropTemplate")
    reader.listPanel:SetPoint("TOPLEFT", reader, "TOPLEFT", 0, 0)
    reader.listPanel:SetPoint("BOTTOMLEFT", reader, "BOTTOMLEFT", 0, 0)
    reader.listPanel:SetWidth(Layout.articleListWidth)
    Theme.StylePanel(reader.listPanel, Colors.analysisRowBg, Colors.cardBorder)

    reader.readerPanel = CreateFrame("Frame", nil, reader, "BackdropTemplate")
    reader.readerPanel:SetPoint("TOPLEFT", reader.listPanel, "TOPRIGHT", Layout.articlePaneGap, 0)
    reader.readerPanel:SetPoint("TOPRIGHT", reader, "TOPRIGHT", 0, 0)
    reader.readerPanel:SetPoint("BOTTOMRIGHT", reader, "BOTTOMRIGHT", 0, 0)
    Theme.StylePanel(reader.readerPanel, Colors.transparent, Colors.transparent, 0)

    reader.listScroll = Theme.CreateScrollArea(reader.listPanel, { step = Layout.listRowHeight })
    reader.listScroll:SetPoint("TOPLEFT", reader.listPanel, "TOPLEFT", 8, -8)
    reader.listScroll:SetPoint("BOTTOMRIGHT", reader.listPanel, "BOTTOMRIGHT", -5, 8)

    reader.scroll = Theme.CreateScrollArea(reader.readerPanel, { step = 48 })
    reader.scroll:SetPoint("TOPLEFT", reader.readerPanel, "TOPLEFT", 0, 0)
    reader.scroll:SetPoint("BOTTOMRIGHT", reader.readerPanel, "BOTTOMRIGHT", 0, 0)

    for index, article in ipairs(reader.articles) do
        local entry = CreateArticleListEntry(reader, article)
        entry:SetPoint("TOPLEFT", reader.listScroll.content, "TOPLEFT", 0, -((index - 1) * (Layout.listRowHeight + Layout.listRowGap)))
        reader.entries[index] = entry
    end
    reader.listScroll:SetContentHeight(math.max(1, #reader.entries * (Layout.listRowHeight + Layout.listRowGap)))

    function reader:UpdateListSelection()
        for _, entry in ipairs(self.entries) do
            local selected = entry.article.id == self.selectedArticleID
            entry.selected = selected
            entry.accent:SetShown(selected)
            entry:SetBackdropColor(unpack(selected and Colors.analysisRowSelectedBg or Colors.transparent))
            Theme.ApplyColor(entry.title, selected and Colors.gold or Colors.text)
        end
    end

    function reader:SelectArticle(articleID)
        local article = Data.GetArticle and Data.GetArticle(articleID)
        if not article or article.internalTab ~= self.tabID then article = self.articles[1] end
        if not article then return end
        self.selectedArticleID = article.id
        self.selectedArticle = article
        self.selectedModeID = article.modes and article.modes[1] and article.modes[1].id or nil
        local firstClass = article.modes and article.modes[1] and article.modes[1].classes and article.modes[1].classes[1]
        self.selectedClassID = firstClass and firstClass.id or nil
        local firstHotfixDate = article.hotfixDates and article.hotfixDates[1]
        self.selectedHotfixDateID = firstHotfixDate and firstHotfixDate.id or nil
        local firstHotfixCategory = firstHotfixDate and firstHotfixDate.categories and firstHotfixDate.categories[1]
        self.selectedHotfixCategoryID = firstHotfixCategory and firstHotfixCategory.id or nil
        local firstHotfixSubmenu = firstHotfixCategory and firstHotfixCategory.submenus and firstHotfixCategory.submenus[1]
        self.selectedHotfixSubmenuID = firstHotfixSubmenu and firstHotfixSubmenu.id or nil
        self:UpdateListSelection()
        self:Render(true)
    end

    function reader:Render(resetScroll)
        if self.rendering then return end
        self.rendering = true
        local previousScroll = self.scroll.viewport:GetVerticalScroll() or 0
        ResetArticlePool(self)
        local article = self.selectedArticle
        local viewportWidth = math.max(320, self.scroll.viewport:GetWidth() or 320)
        local x = Layout.readerPadding
        local width = math.max(260, viewportWidth - (Layout.readerPadding * 2))
        local y = 8

        if not article then
            local _, emptyHeight = AddText(self, "No articles are available yet.", 12, Colors.muted, x, y, width)
            y = y + emptyHeight
        else
            local eyebrow = string.upper(article.category or "ARTICLE")
            local articleDate = article.effectiveDate or article.publicationDate
            if articleDate and articleDate ~= "" then eyebrow = eyebrow .. "  •  " .. string.upper(articleDate) end
            local _, eyebrowHeight = AddText(self, eyebrow, 10, Colors.blue, x, y, width)
            y = y + eyebrowHeight + 10
            local _, titleHeight = AddText(self, article.title or "Untitled", 24, Colors.gold, x, y, width)
            y = y + titleHeight + 10

            local bylineParts = {}
            if article.author then bylineParts[#bylineParts + 1] = article.author end
            if article.source then bylineParts[#bylineParts + 1] = article.source end
            if article.sourceLabel then bylineParts[#bylineParts + 1] = article.sourceLabel end
            if #bylineParts > 0 then
                local _, bylineHeight = AddText(self, table.concat(bylineParts, "  •  "), 11, Colors.muted, x, y, width)
                y = y + bylineHeight + 18
            else
                y = y + 8
            end

            if article.articleType == "class_tuning" then
                y = RenderClassArticle(self, article, x, y, width)
            elseif article.articleType == "hotfixes" then
                y = RenderHotfixArticle(self, article, x, y, width)
            else
                y = RenderNormalArticle(self, article, x, y, width)
            end

            local divider = Acquire(self, "panel")
            Theme.StylePanel(divider, Colors.divider, Colors.transparent, 0)
            divider:ClearAllPoints()
            divider:SetPoint("TOPLEFT", self.scroll.content, "TOPLEFT", x, -y)
            divider:SetSize(width, 1)
            y = y + 14
            local _, footerHeight = AddText(self, article.footer or article.sourceLabel or "", 10, Colors.muted, x, y, width)
            y = y + footerHeight
        end

        self.scroll:SetContentHeight(y + 20)
        if resetScroll then self.scroll:ScrollToTop() else self.scroll:SetScroll(previousScroll) end
        self.lastRenderWidth = viewportWidth
        self.rendering = false
    end

    function reader:Refresh(preferredArticleID)
        self.listScroll:Refresh()
        self.scroll:Refresh()
        if preferredArticleID then
            self:SelectArticle(preferredArticleID)
        elseif not self.selectedArticle then
            local newest = self.articles[1]
            if newest then self:SelectArticle(newest.id) else self:Render(true) end
        else
            self:Render(false)
        end
    end

    reader.readerPanel:SetScript("OnSizeChanged", function()
        local width = reader.scroll.viewport:GetWidth() or 0
        if reader:IsShown() and math.abs(width - (reader.lastRenderWidth or 0)) > 2 then reader:Render(false) end
    end)
    reader.listPanel:SetScript("OnSizeChanged", function()
        local width = math.max(1, reader.listScroll.viewport:GetWidth() or 1)
        reader.listScroll.content:SetWidth(width)
        for _, entry in ipairs(reader.entries) do entry:SetWidth(width) end
        reader.listScroll:Refresh()
    end)
    return reader
end

function HOME:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabHomeTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    Theme.StylePanel(frame, Colors.bg, Colors.transparent, 0)

    frame.title = Text(frame, "Home", 20, Colors.gold)
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", Layout.outerX, Layout.titleY)
    frame.title:SetSize(500, 28)
    frame.subtitle = Text(frame, "The latest official World of Warcraft news, tuning, and hotfixes.", 12, Colors.muted)
    frame.subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", Layout.outerX, Layout.subtitleY)
    frame.subtitle:SetSize(700, 22)

    frame.subTabRule = frame:CreateTexture(nil, "ARTWORK")
    frame.subTabRule:SetPoint("TOPLEFT", frame, "TOPLEFT", Layout.outerX, Layout.subTabRuleY)
    frame.subTabRule:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -Layout.outerRight, Layout.subTabRuleY)
    frame.subTabRule:SetHeight(1)
    frame.subTabRule:SetColorTexture(unpack(Colors.divider))

    frame.subTabs = {}
    local definitions = {
        { id = "home", label = "HOME", width = 76 },
        { id = "news", label = "NEWS & EVENTS", width = 132 },
        { id = "updates", label = "GAME UPDATES", width = 132 },
    }
    local previous
    for _, definition in ipairs(definitions) do
        local tabDefinition = definition
        local button = Theme.CreateTextTabButton(frame, tabDefinition.label, tabDefinition.width, Layout.subTabHeight, { fontSize = 11 })
        if previous then
            button:SetPoint("TOPLEFT", previous, "TOPRIGHT", Layout.subTabGap, 0)
        else
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", Layout.outerX, Layout.subTabsY)
        end
        button:SetScript("OnClick", function() frame:SelectSubTab(tabDefinition.id) end)
        frame.subTabs[tabDefinition.id] = button
        previous = button
    end

    frame.contentHost = CreateFrame("Frame", nil, frame)
    frame.contentHost:SetPoint("TOPLEFT", frame, "TOPLEFT", Layout.outerX, Layout.contentY)
    frame.contentHost:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -Layout.outerRight, Layout.contentBottom)
    frame.panels = {}
    frame.panels.home = CreateHomeOverview(frame.contentHost, frame)
    frame.panels.news = CreateArticleReader(frame.contentHost, "news")
    frame.panels.updates = CreateArticleReader(frame.contentHost, "updates")

    function frame:SelectSubTab(tabID, articleID)
        tabID = self.panels[tabID] and tabID or "home"
        self.selectedSubTab = tabID
        for id, panel in pairs(self.panels) do panel:SetShown(id == tabID) end
        for id, button in pairs(self.subTabs) do button:SetSelected(id == tabID) end
        local panel = self.panels[tabID]
        if tabID == "home" then panel:Refresh() else panel:Refresh(articleID) end
    end

    function frame:Refresh()
        self:SelectSubTab(self.selectedSubTab or "home")
    end

    frame:SetScript("OnShow", function(self) self:Refresh() end)
    frame:SelectSubTab("home")
    return frame
end

function KeyLab_CreateHomeTab(parent)
    return HOME:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Home", function(parent) return HOME:Create(parent) end)
end

return HOME
