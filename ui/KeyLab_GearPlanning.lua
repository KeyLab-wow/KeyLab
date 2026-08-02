-- Gear Planning: a compact reference guide for KeyLab's gearing workflow.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local GearPlanning = {}
KeyLab.Tabs.GearPlanning = GearPlanning
local HEADER = KeyLab.UI.Theme and KeyLab.UI.Theme.tabHeader or { titleSize = 16 }

local COLORS = {
    bg = {0.018, 0.026, 0.056, 0.96},
    panel = {0.026, 0.046, 0.086, 0.92},
    body = {0.022, 0.038, 0.076, 0.86},
    border = {0.240, 0.380, 0.620, 0.62},
    hover = {0.300, 0.420, 0.600, 0.78},
    gold = {0.820, 0.760, 0.580, 1.0},
    text = {0.940, 0.960, 0.990, 1.0},
    muted = {0.680, 0.730, 0.820, 1.0},
}

local ITEM_LEVEL_COLORS = {
    [246] = {0.64, 0.21, 0.93, 1}, -- Epic / purple
    [201] = {0.00, 0.44, 0.87, 1}, -- Rare / blue
    [175] = {0.12, 1.00, 0.00, 1}, -- Uncommon / green
    [165] = {0.00, 0.44, 0.87, 1}, -- Rare / blue
}

local function ItemLevelColor(itemLevel)
    return ITEM_LEVEL_COLORS[tonumber(itemLevel)] or COLORS.text
end

local function SetBackdrop(frame, background, border)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(background))
    frame:SetBackdropBorderColor(unpack(border))
end

local function Text(parent, value, template, size, color)
    local fontString = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    if size then fontString:SetFont(STANDARD_TEXT_FONT, size, "") end
    fontString:SetTextColor(unpack(color or COLORS.text))
    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("TOP")
    fontString:SetWordWrap(true)
    fontString:SetText(value or "")
    return fontString
end

local function Heading(value)
    return "|cFFD1C29A" .. tostring(value) .. "|r"
end

local function Tip()
    return "|cFF80ADEFKeyLab Tip|r"
end

local function List(items)
    return "- " .. table.concat(items, "\n- ")
end

local function Join(parts)
    return table.concat(parts, "\n\n")
end

local function Button(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 120, height or 28)
    SetBackdrop(button, COLORS.body, COLORS.border)
    button.text = Text(button, label or "Button", "GameFontHighlightSmall", 11, COLORS.text)
    button.text:SetAllPoints(button)
    button.text:SetJustifyH("CENTER")
    button.text:SetJustifyV("MIDDLE")
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.060, 0.095, 0.160, 0.98)
        self:SetBackdropBorderColor(unpack(COLORS.gold))
        self.text:SetTextColor(unpack(COLORS.gold))
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.body))
        self:SetBackdropBorderColor(unpack(self.selected and COLORS.gold or COLORS.border))
        self.text:SetTextColor(unpack(self.selected and COLORS.gold or COLORS.text))
    end)
    button.SetSelected = function(self, selected)
        self.selected = selected == true
        self:GetScript("OnLeave")(self)
    end
    return button
end

local function EditBox(parent, width)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(width or 180, 26)
    box:SetAutoFocus(false)
    box:SetFontObject("GameFontHighlightSmall")
    box:SetTextInsets(8, 8, 2, 2)
    SetBackdrop(box, COLORS.body, COLORS.border)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return box
end

local activeDropdown
local function Dropdown(parent, width, optionsProvider, getValue, setValue)
    local dropdown = Button(parent, "", width or 170, 26)
    dropdown.text:ClearAllPoints()
    dropdown.text:SetPoint("LEFT", 8, 0)
    dropdown.text:SetPoint("RIGHT", -24, 0)
    dropdown.text:SetJustifyH("LEFT")
    dropdown.arrow = Text(dropdown, "v", "GameFontNormal", 12, COLORS.gold)
    dropdown.arrow:SetPoint("RIGHT", -7, 0)
    dropdown.arrow:SetJustifyV("MIDDLE")
    dropdown.optionsProvider, dropdown.getValue, dropdown.setValue = optionsProvider, getValue, setValue
    dropdown.menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dropdown.menu:SetFrameStrata("TOOLTIP")
    dropdown.menu:SetFrameLevel(9000)
    dropdown.menu:SetWidth(width or 170)
    dropdown.menu:Hide()
    SetBackdrop(dropdown.menu, COLORS.bg, COLORS.gold)
    dropdown.menu.rows, dropdown.menu.offset = {}, 1
    dropdown.menu:EnableMouseWheel(true)

    local function Populate()
        local options = type(optionsProvider) == "function" and optionsProvider() or optionsProvider or {}
        local visible = math.min(10, math.max(1, #options))
        local maxOffset = math.max(1, #options - visible + 1)
        dropdown.menu.offset = math.max(1, math.min(dropdown.menu.offset or 1, maxOffset))
        dropdown.menu:SetHeight((visible * 25) + 4)
        for index = 1, 10 do
            local row = dropdown.menu.rows[index]
            if not row then
                row = Button(dropdown.menu, "", (width or 170) - 4, 23)
                row.text:SetJustifyH("LEFT")
                row.text:ClearAllPoints()
                row.text:SetPoint("LEFT", 6, 0)
                row.text:SetPoint("RIGHT", -5, 0)
                row:SetScript("OnClick", function(self)
                    if self.option and setValue then setValue(self.option.value, self.option) end
                    dropdown.menu:Hide()
                    if activeDropdown == dropdown then activeDropdown = nil end
                    dropdown:RefreshText()
                end)
                dropdown.menu.rows[index] = row
            end
            local option = options[dropdown.menu.offset + index - 1]
            row.option = option
            row:SetShown(option ~= nil)
            if option then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 2, -2 - ((index - 1) * 25))
                row.text:SetText(option.label or "")
            end
        end
    end
    dropdown.menu:SetScript("OnMouseWheel", function(_, delta)
        local options = type(optionsProvider) == "function" and optionsProvider() or optionsProvider or {}
        local visible = math.min(10, math.max(1, #options))
        dropdown.menu.offset = math.max(1, math.min(math.max(1, #options - visible + 1), (dropdown.menu.offset or 1) - delta))
        Populate()
    end)
    dropdown:SetScript("OnClick", function()
        if dropdown.menu:IsShown() then dropdown.menu:Hide(); activeDropdown = nil; return end
        if activeDropdown and activeDropdown.menu then activeDropdown.menu:Hide() end
        activeDropdown = dropdown
        dropdown.menu.offset = 1
        dropdown.menu:ClearAllPoints()
        dropdown.menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
        Populate()
        dropdown.menu:Show()
    end)
    dropdown:SetScript("OnHide", function()
        dropdown.menu:Hide()
        if activeDropdown == dropdown then activeDropdown = nil end
    end)
    dropdown.RefreshText = function(self)
        local options = type(optionsProvider) == "function" and optionsProvider() or optionsProvider or {}
        local current = getValue and getValue() or nil
        for _, option in ipairs(options) do
            if option.value == current then self.text:SetText(option.label or ""); return end
        end
        self.text:SetText(options[1] and options[1].label or "None")
    end
    dropdown:RefreshText()
    return dropdown
end

local SECTIONS = {
    {
        title = "1. Welcome to Gear Planning",
        body = Join({
            Heading("Why It Matters"),
            "Your Tier Set, crafted gear, embellishments, trinkets, and other important items shape the rest of your gear plan.\n\nMake those choices first. Then KeyLab can help you plan the remaining slots around your secondary-stat goals.",
            Tip(),
            "KeyLab does not choose your build or tell you what is Best in Slot.\n\nGear Planning explains the tools and helps you build a plan based on the choices you make.",
        }),
    },
    {
        title = "2. Tier Sets",
        body = Join({
            Heading("Why It Matters"),
            "Tier Sets give powerful 2-piece and 4-piece bonuses. These bonuses often matter more than secondary stats alone.",
            Heading("How to Get Tier Pieces"),
            "You can get Tier pieces from:\n" .. List({
                "Raid bosses",
                "The Great Vault",
                "The Catalyst",
                "Other seasonal rewards when available",
            }) .. "\n\nMythic+ players can use the Catalyst to turn eligible seasonal armor into Tier pieces.",
            Tip(),
            "For the best Stat Goal Matcher results, finish and equip your planned 4-piece Tier Set first.\n\nTier pieces are not in the Master Item Database. Keep them equipped so their stats are included in the match.\n\nYou only need four of the five Tier slots. Use the Gear Dashboard to track your Tier pieces and find dungeons that drop armor for the Catalyst.",
        }),
    },
    {
        title = "3. Crafted Items",
        body = Join({
            Heading("Why It Matters"),
            "Crafted gear gives you more control over your plan. Depending on the recipe, you may choose the slot, secondary stats, and special effects.\n\nPlan the crafted items you want to keep before matching the rest of your gear.",
            Heading("What You Need to Know"),
            List({
                "Crafted gear is made through Crafting Orders.",
                "Missives let you choose allowed secondary stats.",
                "Embellishments add special effects.",
                "You may equip up to two items marked 'Unique-Equipped: Embellished (2).'",
                "Crafted items without that label do not count toward the two-item limit.",
            }),
            Tip(),
            "Equip the crafted and embellished items you want to keep before running the Stat Goal Matcher.\n\nThe matcher includes their equipped stats, but it does not recommend crafted items, choose Missives, or judge Embellishments.",
        }),
    },
    {
        title = "4. Trinkets",
        body = Join({
            Heading("Why They Matter"),
            "Trinkets can be a major source of power. Many have special Equip, Use, or Proc effects that secondary stats cannot measure.",
            Heading("What You Need to Know"),
            List({
                "Trinkets may have primary stats, secondary stats, both, or neither.",
                "Some trinkets get most of their power from special effects.",
                "Trinkets may help with damage, healing, defense, or utility.",
                "Some trinkets are made for certain roles.",
                "Blizzard tuning can change how well a trinket performs.",
            }),
            Tip(),
            "Equip the trinkets you want to keep before running the Stat Goal Matcher.\n\nIf a trinket slot is empty, KeyLab may match a dungeon or raid trinket that has Crit, Haste, Mastery, or Versatility.\n\nKeyLab does not judge trinket effects. A Goal Match is not a Best in Slot claim.",
        }),
    },
    {
        title = "5. Stat Goal Matcher",
        body = Join({
            Heading("Why It Matters"),
            "The Stat Goal Matcher helps fill your open gear slots after you have chosen the important pieces you want to keep.",
            Heading("How It Works"),
            List({
                "Equip your Tier, crafted, embellished, trinket, set, and other keeper items.",
                "Unequip only the slots you want KeyLab to fill.",
                "Choose the Master Item Database or gear owned by this character.",
                "If using the database, choose Dungeon, Raid, or Dungeon and Raid items.",
                "Enter the Crit, Haste, Mastery, and Versatility percentages you want to see on your Character panel.",
                "Each goal may be set from 0% to 100%. The four goals do not need to total 100%.",
                "Choose Balanced or Favor Priority.",
                "Run the matcher and review the suggested set.",
                "Mark any item you want as a Target or Alternative.",
            }),
            "KeyLab checks the full finished gear set and finds the combination that comes closest to your goals.",
            Tip(),
            "At least one eligible slot must be empty.\n\nThe matcher compares secondary stats. It does not judge Tier bonuses, trinket effects, set effects, embellishments, or Best in Slot.\n\nResults may include projected upgrades and reduced-stat-efficiency warnings. A Goal Match means 'closest match found,' not 'best item in the game.'",
        }),
    },
    {
        title = "6. Gear Targets",
        body = Join({
            Heading("Why It Matters"),
            "Gear Targets is where you choose the dungeon and raid items you want to pursue.\n\nChoose items yourself or use the Stat Goal Matcher for help. Your saved choices appear on the Gear Dashboard.",
            Heading("How It Works"),
            List({
                "Browse gear for your current class and spec.",
                "Filter by slot, source, item type, stats, or saved status.",
                "Hover over an item to read its tooltip.",
                "Save one Target for each slot.",
                "Save other acceptable items as Alternatives.",
                "Leave items Unmarked when they are not part of your plan.",
            }) .. "\n\nA slot must have a Target before it can have an Alternative.\n\nGoal Match suggestions do not select themselves. You decide what becomes a Target, Alternative, or stays Unmarked.",
            Tip(),
            "You do not have to run the Stat Goal Matcher. You can choose every Target yourself.\n\nGoal Match is KeyLab's stat suggestion. Target and Alternative are your choices.",
        }),
    },
    {
        title = "7. Gear Dashboard",
        body = Join({
            Heading("Why It Matters"),
            "The Gear Dashboard puts your current gear and saved goals in one place.",
            Heading("What You Can See"),
            List({
                "Equipped item levels and upgrade tracks",
                "Progress toward your 4-piece Tier Set",
                "The Tier slots you chose",
                "Dungeons that drop armor for your remaining Catalyst slots",
                "Saved Targets and Alternatives",
                "Dungeon and raid sources",
                "Target progress",
                "Hero and Myth upgrade options",
            }) .. "\n\nYou only need four of the five Tier slots. After four are checked, KeyLab stops treating the fifth slot as missing Tier.",
            Tip(),
            "Use the Gear Dashboard to follow the plan you created in Gear Targets.\n\nThe Dashboard does not choose your gear or decide Best in Slot. It organizes your choices and shows where to get them.",
        }),
    },
}

function GearPlanning:RefreshRecipeEditor()
    if not self.craftedView then return end
    local analysis, plans = KeyLab.CraftingAnalysis, KeyLab.CraftedPlansDB
    local recipe = analysis and analysis.GetRecipe and analysis.GetRecipe(self.selectedRecipeID) or nil
    self.recipeEditorEmpty:SetShown(not recipe)
    self.recipeEditorContent:SetShown(recipe ~= nil)
    if not recipe then return end
    local plan = plans.GetPlan(recipe.recipeID)
    self.recipeTitle:SetText(recipe.name or "Crafted Item")
    self.recipeTitle:SetTextColor(unpack(ItemLevelColor(recipe.iLvlMin)))
    self.recipeMeta:SetText("Item Level " .. tostring(recipe.iLvlMin or "-") .. "  |  "
        .. (recipe.slot or "Gear") .. "  |  "
        .. tostring((KeyLab.CraftedRecipeDatabase.professionNames or {})[recipe.professionID] or "Profession"))
    self.planButton.text:SetText(plan and "Remove from Plan" or "Add to Plan")
    self.planButton:SetSelected(plan ~= nil)
    self.reagentHint:SetText(plan
        and "Required materials are added automatically. Choose any optional reagents you want."
        or "Add this item to your plan. Required materials will be added automatically.")

    local displayRows = analysis.GetRecipeDisplayRows(recipe.recipeID)
    for index, row in ipairs(self.reagentRows) do
        local display = displayRows[index]
        row:SetShown(display ~= nil)
        if display then
            row.recipeID, row.slotIndex = recipe.recipeID, display.slotIndex
            if display.kind == "required" or display.kind == "requiredCurrency" then
                row.title:SetText(tostring(display.quantity or 0) .. " x " .. tostring(display.title or "Material"))
                row.title:SetTextColor(unpack(COLORS.text))
            elseif display.kind == "power" then
                row.title:SetText(tostring(display.title or "Power") .. "  |  " .. tostring(display.quantity or 80) .. " crests needed")
                row.title:SetTextColor(unpack(COLORS.gold))
            elseif display.kind == "heraldry" then
                row.title:SetText(tostring(display.title or "Competitor's Heraldry") .. "  |  Need " .. tostring(display.quantity or 1))
                row.title:SetTextColor(0.35, 0.95, 0.50, 1)
            else
                row.title:SetText(tostring(display.title or "Optional Reagent") .. "  |cFF80ADEFOptional|r")
                row.title:SetTextColor(unpack(COLORS.text))
            end
            row.detail:SetText(display.detail or "")
            row.dropdown:SetShown(display.kind == "optional")
            if display.kind == "optional" then
                row.dropdown:SetEnabled(plan ~= nil)
                row.dropdown:SetAlpha(plan and 1 or 0.45)
                row.dropdown:RefreshText()
            end
        end
    end
    local height = math.max(250, #displayRows * 66)
    self.reagentContent:SetHeight(height)
end

function GearPlanning:RefreshRecipes()
    if not self.craftedView then return end
    local analysis = KeyLab.CraftingAnalysis
    self.filteredRecipes = analysis and analysis.GetRecipes and analysis.GetRecipes({
        search = self.recipeSearch,
        slot = self.slotFilter,
        professionID = self.professionFilter,
        weaponType = self.weaponTypeFilter,
        armorType = self.armorTypeFilter,
        iLvlMin = self.itemLevelFilter,
        isPvP = self.pvpFilter,
        plannedOnly = self.plannedOnly,
        currentCharacterOnly = false,
    }) or {}
    local pageSize = #self.recipeRows
    local maxPage = math.max(1, math.ceil(#self.filteredRecipes / pageSize))
    self.recipePage = math.max(1, math.min(self.recipePage or 1, maxPage))
    local plans = KeyLab.CraftedPlansDB
    for rowIndex, row in ipairs(self.recipeRows) do
        local recipe = self.filteredRecipes[((self.recipePage - 1) * pageSize) + rowIndex]
        row.recipe = recipe
        row:SetShown(recipe ~= nil)
        if recipe then
            row.name:SetText(recipe.name or "Crafted Item")
            row.name:SetTextColor(unpack(ItemLevelColor(recipe.iLvlMin)))
            row.meta:SetText("iLvl " .. tostring(recipe.iLvlMin or "-") .. "  |  "
                .. (recipe.slot or "Gear") .. "  |  "
                .. tostring((KeyLab.CraftedRecipeDatabase.professionNames or {})[recipe.professionID] or "Profession"))
            local planned = plans and plans.IsPlanned and plans.IsPlanned(recipe.recipeID)
            row.status:SetText(planned and "PLANNED" or "")
            row.status:SetTextColor(unpack(planned and COLORS.gold or COLORS.muted))
            row:SetBackdropBorderColor(unpack(recipe.recipeID == self.selectedRecipeID and COLORS.gold or COLORS.border))
        end
    end
    self.recipeCount:SetText(string.format("%d item(s)  |  Page %d / %d", #self.filteredRecipes, self.recipePage, maxPage))
    self.recipeBack:SetEnabled(self.recipePage > 1)
    self.recipeNext:SetEnabled(self.recipePage < maxPage)
    local count = plans and plans.GetPlans and #plans.GetPlans() or 0
    self.planCount:SetText(count .. " item(s) in your crafted plan")
    self:RefreshRecipeEditor()
end

function GearPlanning:BuildGuideView(parent)
    local view = CreateFrame("Frame", nil, parent)
    view:SetAllPoints(parent)
    local scroll = CreateFrame("ScrollFrame", nil, view, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", -18, 0)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(900, 520)
    scroll:SetScrollChild(content)
    self.accordion = KeyLab.UI.Accordion.Create(content, {
        sections = SECTIONS, colors = COLORS, width = 874, left = 8, minHeight = 520,
    })
    return view
end

function GearPlanning:BuildCraftedView(parent)
    local view = CreateFrame("Frame", nil, parent)
    view:SetAllPoints(parent)
    self.craftedView = view

    local filters = CreateFrame("Frame", nil, view, "BackdropTemplate")
    filters:SetPoint("TOPLEFT", 0, 0); filters:SetPoint("TOPRIGHT", 0, 0); filters:SetHeight(132)
    SetBackdrop(filters, COLORS.panel, COLORS.border)
    local searchLabel = Text(filters, "Search Crafted Gear", nil, 11, COLORS.muted); searchLabel:SetPoint("TOPLEFT", 14, -10)
    self.searchBox = EditBox(filters, 255); self.searchBox:SetPoint("TOPLEFT", 14, -31)
    self.searchBox:SetScript("OnTextChanged", function(box, userInput)
        if not userInput then return end
        self.recipeSearch = box:GetText() or ""; self.recipePage = 1; self:RefreshRecipes()
    end)
    local slotLabel = Text(filters, "Slot", nil, 11, COLORS.muted); slotLabel:SetPoint("TOPLEFT", 285, -10)
    self.slotDropdown = Dropdown(filters, 145,
        function() return KeyLab.CraftingAnalysis.GetSlotOptions() end,
        function() return self.slotFilter end,
        function(value) self.slotFilter = value; self.recipePage = 1; self:RefreshRecipes() end)
    self.slotDropdown:SetPoint("TOPLEFT", 285, -31)
    local professionLabel = Text(filters, "Profession", nil, 11, COLORS.muted); professionLabel:SetPoint("TOPLEFT", 444, -10)
    self.professionDropdown = Dropdown(filters, 175,
        function() return KeyLab.CraftingAnalysis.GetProfessionOptions() end,
        function() return self.professionFilter end,
        function(value) self.professionFilter = value; self.recipePage = 1; self:RefreshRecipes() end)
    self.professionDropdown:SetPoint("TOPLEFT", 444, -31)
    self.shoppingButton = Button(filters, "Open Shopping List", 180, 30)
    self.shoppingButton:SetPoint("TOPRIGHT", -14, -31)
    self.shoppingButton:SetScript("OnClick", function()
        if KeyLab.CraftingShoppingWindow and KeyLab.CraftingShoppingWindow.Show then KeyLab.CraftingShoppingWindow.Show(true) end
    end)

    local weaponLabel = Text(filters, "Weapon Type", nil, 11, COLORS.muted); weaponLabel:SetPoint("TOPLEFT", 14, -72)
    self.weaponTypeDropdown = Dropdown(filters, 165,
        function() return KeyLab.CraftingAnalysis.GetWeaponTypeOptions() end,
        function() return self.weaponTypeFilter end,
        function(value)
            self.weaponTypeFilter = value
            if value then self.armorTypeFilter = nil; self.armorTypeDropdown:RefreshText() end
            self.recipePage = 1; self:RefreshRecipes()
        end)
    self.weaponTypeDropdown:SetPoint("TOPLEFT", 14, -93)

    local armorLabel = Text(filters, "Armor Type", nil, 11, COLORS.muted); armorLabel:SetPoint("TOPLEFT", 193, -72)
    self.armorTypeDropdown = Dropdown(filters, 145,
        function() return KeyLab.CraftingAnalysis.GetArmorTypeOptions() end,
        function() return self.armorTypeFilter end,
        function(value)
            self.armorTypeFilter = value
            if value then self.weaponTypeFilter = nil; self.weaponTypeDropdown:RefreshText() end
            self.recipePage = 1; self:RefreshRecipes()
        end)
    self.armorTypeDropdown:SetPoint("TOPLEFT", 193, -93)

    local levelLabel = Text(filters, "Item Level", nil, 11, COLORS.muted); levelLabel:SetPoint("TOPLEFT", 352, -72)
    self.itemLevelDropdown = Dropdown(filters, 120,
        function() return KeyLab.CraftingAnalysis.GetItemLevelOptions() end,
        function() return self.itemLevelFilter end,
        function(value)
            self.itemLevelFilter = value
            if value and tonumber(value) ~= 175 and self.pvpFilter == true then
                self.pvpFilter = nil
                self.pvpDropdown:RefreshText()
            end
            self.recipePage = 1; self:RefreshRecipes()
        end)
    self.itemLevelDropdown:SetPoint("TOPLEFT", 352, -93)

    local pvpLabel = Text(filters, "PvP Items", nil, 11, COLORS.muted); pvpLabel:SetPoint("TOPLEFT", 486, -72)
    self.pvpDropdown = Dropdown(filters, 145,
        function() return KeyLab.CraftingAnalysis.GetPvPOptions() end,
        function() return self.pvpFilter end,
        function(value)
            self.pvpFilter = value
            if value == true then self.itemLevelFilter = 175; self.itemLevelDropdown:RefreshText() end
            self.recipePage = 1; self:RefreshRecipes()
        end)
    self.pvpDropdown:SetPoint("TOPLEFT", 486, -93)

    local plannedLabel = Text(filters, "Plan", nil, 11, COLORS.muted); plannedLabel:SetPoint("TOPLEFT", 645, -72)
    self.plannedDropdown = Dropdown(filters, 145,
        function() return KeyLab.CraftingAnalysis.GetPlanStatusOptions() end,
        function() return self.plannedOnly == true end,
        function(value) self.plannedOnly = value == true; self.recipePage = 1; self:RefreshRecipes() end)
    self.plannedDropdown:SetPoint("TOPLEFT", 645, -93)

    local listPanel = CreateFrame("Frame", nil, view, "BackdropTemplate")
    listPanel:SetPoint("TOPLEFT", filters, "BOTTOMLEFT", 0, -10)
    listPanel:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, 0)
    listPanel:SetWidth(432); SetBackdrop(listPanel, COLORS.panel, COLORS.border)
    local listTitle = Text(listPanel, "Crafted Items", "GameFontNormal", 15, COLORS.gold); listTitle:SetPoint("TOPLEFT", 14, -12)
    self.recipeRows = {}
    for index = 1, 8 do
        local row = CreateFrame("Button", nil, listPanel, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 12, -39 - ((index - 1) * 49)); row:SetPoint("TOPRIGHT", -12, -39 - ((index - 1) * 49)); row:SetHeight(43)
        SetBackdrop(row, index % 2 == 0 and COLORS.body or COLORS.bg, COLORS.border)
        row.name = Text(row, "", "GameFontHighlightSmall", 11, COLORS.text); row.name:SetPoint("TOPLEFT", 9, -6); row.name:SetPoint("RIGHT", -70, 0)
        row.meta = Text(row, "", "GameFontHighlightSmall", 10, COLORS.muted); row.meta:SetPoint("BOTTOMLEFT", 9, 5)
        row.status = Text(row, "", "GameFontHighlightSmall", 9, COLORS.gold); row.status:SetPoint("RIGHT", -8, 0); row.status:SetJustifyH("RIGHT")
        row:SetScript("OnClick", function(selfRow)
            if not selfRow.recipe then return end
            self.selectedRecipeID = selfRow.recipe.recipeID
            self:RefreshRecipes()
        end)
        row:SetScript("OnEnter", function(selfRow) selfRow:SetBackdropBorderColor(unpack(COLORS.gold)) end)
        row:SetScript("OnLeave", function(selfRow)
            selfRow:SetBackdropBorderColor(unpack(selfRow.recipe and selfRow.recipe.recipeID == self.selectedRecipeID and COLORS.gold or COLORS.border))
        end)
        self.recipeRows[index] = row
    end
    self.recipeCount = Text(listPanel, "", nil, 10, COLORS.muted); self.recipeCount:SetPoint("BOTTOMLEFT", 14, 14)
    self.recipeBack = Button(listPanel, "Back", 72, 26); self.recipeBack:SetPoint("BOTTOMRIGHT", -92, 10)
    self.recipeNext = Button(listPanel, "Next", 72, 26); self.recipeNext:SetPoint("BOTTOMRIGHT", -12, 10)
    self.recipeBack:SetScript("OnClick", function() self.recipePage = math.max(1, (self.recipePage or 1) - 1); self:RefreshRecipes() end)
    self.recipeNext:SetScript("OnClick", function() self.recipePage = (self.recipePage or 1) + 1; self:RefreshRecipes() end)

    local editor = CreateFrame("Frame", nil, view, "BackdropTemplate")
    editor:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 10, 0); editor:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
    SetBackdrop(editor, COLORS.panel, COLORS.border)
    self.recipeEditorEmpty = Text(editor, "Select a crafted item to review its materials.", "GameFontHighlight", 13, COLORS.muted)
    self.recipeEditorEmpty:SetPoint("CENTER", 0, 20)
    self.recipeEditorContent = CreateFrame("Frame", nil, editor); self.recipeEditorContent:SetAllPoints(editor)
    self.recipeTitle = Text(self.recipeEditorContent, "", "GameFontNormal", 16, COLORS.gold); self.recipeTitle:SetPoint("TOPLEFT", 15, -12); self.recipeTitle:SetPoint("RIGHT", -150, 0)
    self.recipeMeta = Text(self.recipeEditorContent, "", nil, 11, COLORS.muted); self.recipeMeta:SetPoint("TOPLEFT", 15, -36)
    self.planButton = Button(self.recipeEditorContent, "Add to Plan", 140, 28); self.planButton:SetPoint("TOPRIGHT", -14, -12)
    self.planButton:SetScript("OnClick", function()
        if not self.selectedRecipeID then return end
        KeyLab.CraftedPlansDB.Toggle(self.selectedRecipeID)
        self:RefreshRecipes()
    end)
    self.reagentHint = Text(self.recipeEditorContent, "", nil, 10, COLORS.muted); self.reagentHint:SetPoint("TOPLEFT", 15, -57)
    local reagentScroll = CreateFrame("ScrollFrame", nil, self.recipeEditorContent, "UIPanelScrollFrameTemplate")
    reagentScroll:SetPoint("TOPLEFT", 10, -78); reagentScroll:SetPoint("BOTTOMRIGHT", -28, 42)
    self.reagentContent = CreateFrame("Frame", nil, reagentScroll); self.reagentContent:SetSize(390, 300); reagentScroll:SetScrollChild(self.reagentContent)
    self.reagentRows = {}
    for index = 1, 20 do
        local row = CreateFrame("Frame", nil, self.reagentContent, "BackdropTemplate")
        row:SetPoint("TOPLEFT", 0, -((index - 1) * 66)); row:SetPoint("TOPRIGHT", 0, -((index - 1) * 66)); row:SetHeight(60)
        SetBackdrop(row, index % 2 == 0 and COLORS.body or COLORS.bg, COLORS.border)
        row.title = Text(row, "", nil, 10, COLORS.text); row.title:SetPoint("TOPLEFT", 8, -6); row.title:SetPoint("RIGHT", -8, 0)
        row.detail = Text(row, "", nil, 9, COLORS.muted); row.detail:SetPoint("TOPLEFT", 8, -25); row.detail:SetPoint("RIGHT", -8, 0)
        row.dropdown = Dropdown(row, 350,
            function() return KeyLab.CraftingAnalysis.GetChoiceOptions(row.recipeID, row.slotIndex) end,
            function()
                local plan = KeyLab.CraftedPlansDB.GetPlan(row.recipeID)
                return KeyLab.CraftingAnalysis.GetChoiceValue(plan, row.slotIndex)
            end,
            function(value, option)
                if value == "none" then KeyLab.CraftedPlansDB.SetChoice(row.recipeID, row.slotIndex, nil, nil)
                else KeyLab.CraftedPlansDB.SetChoice(row.recipeID, row.slotIndex, option.kind, option.id) end
                self:RefreshRecipes()
            end)
        row.dropdown:SetPoint("BOTTOMLEFT", 8, 5)
        self.reagentRows[index] = row
    end
    self.planCount = Text(editor, "", nil, 10, COLORS.gold); self.planCount:SetPoint("BOTTOMLEFT", 15, 14)
    return view
end

function GearPlanning:ShowView(name)
    self.selectedView = name == "crafted" and "crafted" or "guide"
    self.guideView:SetShown(self.selectedView == "guide")
    self.craftedView:SetShown(self.selectedView == "crafted")
    self.guideTab:SetSelected(self.selectedView == "guide")
    self.craftedTab:SetSelected(self.selectedView == "crafted")
    if self.selectedView == "crafted" then self:RefreshRecipes() end
end

function GearPlanning:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabGearPlanningTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})

    KeyLab.UI.Theme.CreateTabHeader(
        frame,
        "Gear Planning",
        "Learn the main gearing choices, then plan the open slots around your goals."
    )

    self.guideTab = Button(frame, "Guide", 170, 34); self.guideTab:SetPoint("TOPLEFT", 18, -72)
    self.craftedTab = Button(frame, "Crafted Gear", 170, 34); self.craftedTab:SetPoint("LEFT", self.guideTab, "RIGHT", 10, 0)
    local views = CreateFrame("Frame", nil, frame)
    views:SetPoint("TOPLEFT", 18, -116); views:SetPoint("BOTTOMRIGHT", -34, 18)
    self.guideView = self:BuildGuideView(views)
    self:BuildCraftedView(views)
    self.guideTab:SetScript("OnClick", function() self:ShowView("guide") end)
    self.craftedTab:SetScript("OnClick", function() self:ShowView("crafted") end)
    self.frame = frame
    self.recipePage, self.recipeSearch = 1, ""
    self:ShowView("guide")
    frame:SetScript("OnShow", function()
        if self.selectedView == "crafted" then self:RefreshRecipes() end
    end)
    return frame
end

function KeyLab_CreateGearPlanningTab(parent)
    return GearPlanning:Create(parent)
end

if KeyLab.RegisterTab then
    KeyLab.RegisterTab("Gear Planning", function(parent) return GearPlanning:Create(parent) end)
end

return GearPlanning
