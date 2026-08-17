-- Gear Planning: a compact reference guide for KeyLab's gearing workflow.

local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.Tabs = KeyLab.Tabs or {}

local GearPlanning = {}
KeyLab.Tabs.GearPlanning = GearPlanning
local Theme = KeyLab.UI.Theme or {}
local HEADER = Theme.tabHeader or { titleSize = 16 }
local SEASON2_DATA = KeyLab.Season2GearInfo or {}

local COLORS = Theme.colors or {
    bg = {0.018, 0.026, 0.056, 0.96},
    panel = {0.026, 0.046, 0.086, 0.92},
    buttonBg = {0.022, 0.038, 0.076, 0.86},
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

local function ItemIcon(itemID)
    itemID = tonumber(itemID)
    if not itemID then return 134400 end
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, itemID)
        if ok and icon then return icon end
    end
    if C_Item and C_Item.GetItemInfoInstant then
        local ok, _, _, _, _, icon = pcall(C_Item.GetItemInfoInstant, itemID)
        if ok and icon then return icon end
    end
    return 134400
end

local function ShowItemTooltip(owner, itemID, itemLink, recipeItemLevel)
    itemID = tonumber(itemID)
    if not itemID or not GameTooltip then return end
    if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if itemLink and itemLink ~= "" then
        GameTooltip:SetHyperlink(itemLink)
    elseif GameTooltip.SetItemByID then
        GameTooltip:SetItemByID(itemID)
    else
        GameTooltip:SetHyperlink("item:" .. tostring(itemID))
    end
    if tonumber(recipeItemLevel) then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(
            "KeyLab Recipe Item Level",
            tostring(tonumber(recipeItemLevel)),
            COLORS.muted[1], COLORS.muted[2], COLORS.muted[3],
            COLORS.gold[1], COLORS.gold[2], COLORS.gold[3]
        )
    end
    GameTooltip:Show()
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
    return "|cFF3C6E71" .. tostring(value) .. "|r"
end

local function Tip()
    return "|cFF284B63KeyLab Tip|r"
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
    SetBackdrop(button, COLORS.buttonBg, COLORS.border)
    button.text = Text(button, label or "Button", "GameFontHighlightSmall", 11, COLORS.text)
    button.text:SetAllPoints(button)
    button.text:SetJustifyH("CENTER")
    button.text:SetJustifyV("MIDDLE")
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(1.0, 1.0, 1.0, 1.0)
        self:SetBackdropBorderColor(unpack(COLORS.gold))
        self.text:SetTextColor(unpack(COLORS.gold))
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.buttonBg))
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
    SetBackdrop(box, COLORS.buttonBg, COLORS.border)
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
    if Theme.StyleDropdownField then Theme.StyleDropdownField(dropdown) end
    dropdown:SetScript("OnEnter", function(self)
        if Theme.ApplyDropdownFieldState then Theme.ApplyDropdownFieldState(self, true) end
    end)
    dropdown:SetScript("OnLeave", function(self)
        if Theme.ApplyDropdownFieldState then Theme.ApplyDropdownFieldState(self, false) end
    end)
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
    local nextTop = 0
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
                row.title:SetTextColor(0.235, 0.431, 0.443, 1)
            else
                row.title:SetText(tostring(display.title or "Optional Reagent") .. "  |cFF284B63Optional|r")
                row.title:SetTextColor(unpack(COLORS.text))
            end
            row.detail:SetText(display.detail or "")
            row.detail:SetShown(display.detail ~= nil and display.detail ~= "")
            row.dropdown:SetShown(display.kind == "optional")
            if display.kind == "optional" then
                row.dropdown:SetEnabled(plan ~= nil)
                row.dropdown:SetAlpha(plan and 1 or 0.45)
                row.dropdown:RefreshText()
            end
            local rowHeight
            if display.kind == "optional" then rowHeight = 60
            elseif display.detail and display.detail ~= "" then rowHeight = 43
            else rowHeight = 31 end
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -nextTop)
            row:SetPoint("TOPRIGHT", 0, -nextTop)
            row:SetHeight(rowHeight)
            nextTop = nextTop + rowHeight + 6
        end
    end
    local height = math.max(250, nextTop)
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
            row.icon:SetTexture(ItemIcon(recipe.itemID))
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
        SetBackdrop(row, index % 2 == 0 and COLORS.buttonBg or COLORS.bg, COLORS.border)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(31, 31); row.icon:SetPoint("LEFT", 7, 0)
        row.name = Text(row, "", "GameFontHighlightSmall", 11, COLORS.text); row.name:SetPoint("TOPLEFT", 46, -6); row.name:SetPoint("RIGHT", -70, 0)
        row.meta = Text(row, "", "GameFontHighlightSmall", 10, COLORS.muted); row.meta:SetPoint("BOTTOMLEFT", 46, 5)
        row.status = Text(row, "", "GameFontHighlightSmall", 9, COLORS.gold); row.status:SetPoint("RIGHT", -8, 0); row.status:SetJustifyH("RIGHT")
        row:SetScript("OnClick", function(selfRow)
            if not selfRow.recipe then return end
            self.selectedRecipeID = selfRow.recipe.recipeID
            self:RefreshRecipes()
        end)
        row:SetScript("OnEnter", function(selfRow)
            selfRow:SetBackdropBorderColor(unpack(COLORS.gold))
            if selfRow.recipe then
                ShowItemTooltip(
                    selfRow,
                    selfRow.recipe.itemID,
                    selfRow.recipe.itemLink,
                    selfRow.recipe.iLvlMin
                )
            end
        end)
        row:SetScript("OnLeave", function(selfRow)
            selfRow:SetBackdropBorderColor(unpack(selfRow.recipe and selfRow.recipe.recipeID == self.selectedRecipeID and COLORS.gold or COLORS.border))
            if GameTooltip then GameTooltip:Hide() end
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
        SetBackdrop(row, index % 2 == 0 and COLORS.buttonBg or COLORS.bg, COLORS.border)
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

local function Season2Track(trackID)
    return SEASON2_DATA.GetTrack and SEASON2_DATA.GetTrack(trackID) or nil
end

local function Season2TrackLabel(trackID, override)
    local track = Season2Track(trackID)
    return override or (track and track.label) or tostring(trackID or "")
end

local function WrappedTextHeight(fontString, value, width, fontSize, minimum)
    value = tostring(value or "")
    width = math.max(20, tonumber(width) or 20)
    fontString:SetWidth(width)
    fontString:SetHeight(1000)
    fontString:SetText(value)
    fontString:Show()
    local measured = fontString.GetStringHeight and fontString:GetStringHeight() or 0
    if not measured or measured <= 1 then
        local charactersPerLine = math.max(1, math.floor(width / math.max(5, (fontSize or 11) * 0.52)))
        measured = math.ceil(math.max(1, #value) / charactersPerLine) * ((fontSize or 11) + 3)
    end
    return math.max(tonumber(minimum) or 1, math.ceil(measured))
end

function GearPlanning:ResetSeason2Canvas(canvas)
    canvas.keylabUsed = {}
    for kind, pool in pairs(canvas.keylabPools or {}) do
        for _, object in ipairs(pool) do
            object:Hide()
            object:ClearAllPoints()
            if kind == "tab" or kind == "trackButton" then
                object:SetScript("OnClick", nil)
            end
        end
    end
end

function GearPlanning:AcquireSeason2Object(canvas, kind)
    canvas.keylabPools = canvas.keylabPools or {}
    canvas.keylabUsed = canvas.keylabUsed or {}
    local pool = canvas.keylabPools[kind] or {}
    canvas.keylabPools[kind] = pool
    local index = (canvas.keylabUsed[kind] or 0) + 1
    canvas.keylabUsed[kind] = index
    local object = pool[index]
    if object then
        object:Show()
        return object
    end

    if kind == "text" then
        object = Theme.CreateText(canvas, "", "GameFontHighlightSmall", 11, COLORS.text)
    elseif kind == "panel" then
        object = CreateFrame("Frame", nil, canvas, "BackdropTemplate")
    elseif kind == "callout" then
        object = CreateFrame("Frame", nil, canvas, "BackdropTemplate")
        object.accent = object:CreateTexture(nil, "ARTWORK")
        object.accent:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0)
        object.accent:SetPoint("BOTTOMLEFT", object, "BOTTOMLEFT", 0, 0)
        object.accent:SetWidth(3)
        object.heading = Theme.CreateText(object, "", "GameFontDisableSmall", 10, COLORS.blue)
        object.heading:SetPoint("TOPLEFT", object, "TOPLEFT", 14, -10)
        object.heading:SetPoint("TOPRIGHT", object, "TOPRIGHT", -14, -10)
        object.heading:SetHeight(14)
        object.body = Theme.CreateText(object, "", "GameFontHighlightSmall", 11, COLORS.soft or COLORS.text)
        object.body:SetPoint("TOPLEFT", object, "TOPLEFT", 14, -30)
        object.body:SetPoint("TOPRIGHT", object, "TOPRIGHT", -14, -30)
    elseif kind == "detail" then
        object = CreateFrame("Frame", nil, canvas, "BackdropTemplate")
        object.accent = object:CreateTexture(nil, "ARTWORK")
        object.accent:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0)
        object.accent:SetPoint("BOTTOMLEFT", object, "BOTTOMLEFT", 0, 0)
        object.accent:SetWidth(3)
        object.title = Theme.CreateText(object, "", "GameFontNormal", 19, COLORS.gold)
        object.meta = Theme.CreateText(object, "", "GameFontHighlightSmall", 11, COLORS.muted)
        object.itemHeading = Theme.CreateText(object, "ITEM LEVELS", "GameFontDisableSmall", 10, COLORS.blue)
        object.note = Theme.CreateText(object, "", "GameFontHighlightSmall", 11, COLORS.soft or COLORS.text)
    elseif kind == "tab" then
        object = Theme.CreateTextTabButton(canvas, "", 120, 32, { fontSize = 11 })
    elseif kind == "trackButton" then
        object = CreateFrame("Button", nil, canvas, "BackdropTemplate")
        object.label = Theme.CreateText(object, "", "GameFontHighlightSmall", 11, COLORS.text, "CENTER")
        object.label:SetPoint("TOPLEFT", object, "TOPLEFT", 7, -7)
        object.label:SetPoint("TOPRIGHT", object, "TOPRIGHT", -7, -7)
        object.label:SetHeight(15)
        object.meta = Theme.CreateText(object, "", "GameFontDisableSmall", 10, COLORS.muted, "CENTER")
        object.meta:SetPoint("BOTTOMLEFT", object, "BOTTOMLEFT", 7, 6)
        object.meta:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", -7, 6)
        object.meta:SetHeight(13)
    elseif kind == "chip" then
        object = Theme.CreateGearTrackBadge(canvas, "", "unranked", 70, 25)
    elseif kind == "row" then
        object = CreateFrame("Frame", nil, canvas, "BackdropTemplate")
        object.accent = object:CreateTexture(nil, "ARTWORK")
        object.accent:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0)
        object.accent:SetPoint("BOTTOMLEFT", object, "BOTTOMLEFT", 0, 0)
        object.accent:SetWidth(3)
        object.cells = {}
        for cellIndex = 1, 4 do
            local cell = Theme.CreateText(object, "", "GameFontHighlightSmall", 11, COLORS.text)
            object.cells[cellIndex] = cell
        end
    end
    pool[index] = object
    object:Show()
    return object
end

function GearPlanning:AddSeason2Text(canvas, value, x, cursor, width, fontSize, color, justify)
    local fontString = self:AcquireSeason2Object(canvas, "text")
    fontString:ClearAllPoints()
    fontString:SetPoint("TOPLEFT", canvas, "TOPLEFT", x or 0, -(cursor or 0))
    fontString:SetFont(Theme.fonts.body or STANDARD_TEXT_FONT, fontSize or 11, "")
    Theme.ApplyColor(fontString, color or COLORS.text)
    fontString:SetJustifyH(justify or "LEFT")
    fontString:SetJustifyV("TOP")
    local height = WrappedTextHeight(fontString, value, width, fontSize, (fontSize or 11) + 3)
    fontString:SetHeight(height)
    return (cursor or 0) + height, fontString
end

function GearPlanning:AddSeason2Callout(canvas, cursor, width, heading, body, accentColor)
    local panel = self:AcquireSeason2Object(canvas, "callout")
    local accent = accentColor or COLORS.blue
    panel:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -cursor)
    panel:SetWidth(width)
    Theme.StylePanel(panel, COLORS.noteBg or COLORS.panel, COLORS.softBorder or COLORS.border)
    panel.accent:SetColorTexture(unpack(accent))
    Theme.ApplyColor(panel.heading, accent)
    panel.heading:SetText(tostring(heading or ""))
    Theme.ApplyColor(panel.body, COLORS.soft or COLORS.text)
    local bodyHeight = WrappedTextHeight(panel.body, body, width - 28, 11, 16)
    panel.body:SetHeight(bodyHeight)
    local panelHeight = 42 + bodyHeight
    panel:SetHeight(panelHeight)
    return cursor + panelHeight + 12
end

function GearPlanning:CreateRewardTable(canvas, section, cursor, width)
    cursor = cursor or 0
    local nextCursor = self:AddSeason2Text(canvas, section.title or "Rewards", 2, cursor, width - 4, 14, COLORS.gold)
    cursor = nextCursor + 8

    if section.notice and section.notice ~= "" then
        cursor = self:AddSeason2Callout(canvas, cursor, width, "SEASON AVAILABILITY", section.notice, COLORS.warning)
    end

    local columns = section.columns or {}
    local header = self:AcquireSeason2Object(canvas, "row")
    header:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -cursor)
    header:SetWidth(width)
    Theme.StylePanel(header, COLORS.controlBg or COLORS.buttonBg, COLORS.border)
    header.accent:Hide()

    local columnX = 10
    local usableWidth = width - 20
    local headerHeight = 29
    for index, column in ipairs(columns) do
        local cellWidth = math.floor(usableWidth * (column.weight or (1 / math.max(1, #columns))))
        if index == #columns then cellWidth = usableWidth - columnX + 10 end
        local cell = header.cells[index]
        cell:Show()
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", header, "TOPLEFT", columnX, -7)
        cell:SetFont(Theme.fonts.body or STANDARD_TEXT_FONT, 10, "")
        Theme.ApplyColor(cell, COLORS.blue)
        cell:SetJustifyH((column.key == "itemLevel" or column.key == "pvpItemLevel") and "CENTER" or "LEFT")
        local headerTextWidth = math.max(20, cellWidth - 8)
        local measured = WrappedTextHeight(cell, string.upper(tostring(column.label or "")), headerTextWidth, 10, 14)
        cell:SetSize(headerTextWidth, measured)
        headerHeight = math.max(headerHeight, measured + 14)
        columnX = columnX + cellWidth
    end
    for index = #columns + 1, 4 do header.cells[index]:Hide() end
    header:SetHeight(headerHeight)
    cursor = cursor + headerHeight

    for rowIndex, values in ipairs(section.rows or {}) do
        local row = self:AcquireSeason2Object(canvas, "row")
        local trackColor = Theme.GetGearTrackColor(values.track)
        local rowBackground = rowIndex % 2 == 0 and (COLORS.cardBg or COLORS.panel) or (COLORS.contentBg or COLORS.bg)
        Theme.StylePanel(row, rowBackground, COLORS.softBorder or COLORS.border)
        row.accent:Show()
        row.accent:SetColorTexture(unpack(trackColor))

        local rowHeight = 35
        columnX = 10
        for index, column in ipairs(columns) do
            local cellWidth = math.floor(usableWidth * (column.weight or (1 / math.max(1, #columns))))
            if index == #columns then cellWidth = usableWidth - columnX + 10 end
            local rawValue = values[column.key]
            if column.key == "track" then rawValue = Season2TrackLabel(values.track, values.trackLabel) end
            if rawValue == nil or rawValue == "" then rawValue = "—" end
            local cell = row.cells[index]
            cell:Show()
            cell:ClearAllPoints()
            cell:SetFont(Theme.fonts.body or STANDARD_TEXT_FONT, 11, "")
            Theme.ApplyColor(cell, column.key == "track" and trackColor or COLORS.text)
            cell:SetJustifyH((column.key == "itemLevel" or column.key == "pvpItemLevel") and "CENTER" or "LEFT")
            local cellTextWidth = math.max(20, cellWidth - 10)
            local measured = WrappedTextHeight(cell, rawValue, cellTextWidth, 11, 15)
            rowHeight = math.max(rowHeight, measured + 14)
            cell:SetPoint("TOPLEFT", row, "TOPLEFT", columnX, -7)
            cell:SetSize(cellTextWidth, measured)
            columnX = columnX + cellWidth
        end
        for index = #columns + 1, 4 do row.cells[index]:Hide() end
        row:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -cursor)
        row:SetSize(width, rowHeight)
        cursor = cursor + rowHeight
    end
    return cursor + 16
end

function GearPlanning:RenderSeason2RewardSource()
    local sourceID = self.season2SelectedSource or "dungeons"
    local source = SEASON2_DATA.GetRewardSource and SEASON2_DATA.GetRewardSource(sourceID)
    if not source or not self.season2RewardScroll then return end
    local scroll = self.season2RewardScroll
    local canvas = scroll.content
    self:ResetSeason2Canvas(canvas)
    local width = math.max(360, (scroll.viewport:GetWidth() or 600) - 2)
    local cursor = 0
    cursor = self:AddSeason2Text(canvas, source.title or source.label, 2, cursor, width - 4, 17, COLORS.gold)
    cursor = cursor + 3
    cursor = self:AddSeason2Text(canvas, source.description or "", 2, cursor, width - 4, 11, COLORS.muted)
    cursor = cursor + 12
    if source.note and source.note ~= "" then
        cursor = self:AddSeason2Callout(canvas, cursor, width, "GOOD TO KNOW", source.note, COLORS.blue)
    end
    local hasVaultSection = false
    for _, section in ipairs(source.sections or {}) do
        cursor = self:CreateRewardTable(canvas, section, cursor, width)
        hasVaultSection = hasVaultSection or section.greatVault == true
    end
    if hasVaultSection and SEASON2_DATA.weeklyRewards then
        cursor = self:AddSeason2Callout(
            canvas,
            cursor,
            width,
            SEASON2_DATA.weeklyRewards.heading,
            SEASON2_DATA.weeklyRewards.body,
            COLORS.blue
        )
    end
    scroll:SetContentHeight(cursor + 4)
end

function GearPlanning:StyleSeason2TrackButton(button, selected)
    local color = Theme.GetGearTrackColor(button.trackID)
    button.selected = selected == true
    Theme.StylePanel(
        button,
        button.selected and (COLORS.controlBg or COLORS.buttonBg) or (COLORS.contentBg or COLORS.bg),
        button.selected and color or (COLORS.softBorder or COLORS.border)
    )
    Theme.ApplyColor(button.label, button.selected and color or COLORS.text)
    Theme.ApplyColor(button.meta, button.selected and color or COLORS.muted)
end

function GearPlanning:RenderUpgradeTrackView()
    local scroll = self.season2FullScroll
    if not scroll then return end
    local canvas = scroll.content
    self:ResetSeason2Canvas(canvas)
    local width = math.max(500, (scroll.viewport:GetWidth() or 800) - 2)
    local cursor = 0
    cursor = self:AddSeason2Text(canvas, "Choose an Upgrade Track", 2, cursor, width - 4, 15, COLORS.gold)
    cursor = cursor + 4
    cursor = self:AddSeason2Text(
        canvas,
        "Select a track to see every item level in its Season 2 upgrade path.",
        2,
        cursor,
        width - 4,
        11,
        COLORS.muted
    )
    cursor = cursor + 12

    local tracks = SEASON2_DATA.tracks or {}
    local gap = 8
    local columns = width >= 720 and 3 or 2
    local cardWidth = math.floor((width - ((columns - 1) * gap)) / columns)
    local cardHeight = 48
    local rowCount = math.ceil(#tracks / columns)
    for index, track in ipairs(tracks) do
        local button = self:AcquireSeason2Object(canvas, "trackButton")
        local column = (index - 1) % columns
        local rowIndex = math.floor((index - 1) / columns)
        button.trackID = track.id
        button.label:SetText(string.upper(track.label or track.id or ""))
        button.meta:SetText(track.range or "")
        button:SetPoint("TOPLEFT", canvas, "TOPLEFT", column * (cardWidth + gap), -(cursor + (rowIndex * (cardHeight + gap))))
        button:SetSize(cardWidth, cardHeight)
        self:StyleSeason2TrackButton(button, (self.season2SelectedTrack or "champion") == track.id)
        button:SetScript("OnEnter", function(selfButton)
            if not selfButton.selected then
                selfButton:SetBackdropBorderColor(unpack(Theme.GetGearTrackColor(selfButton.trackID)))
                Theme.ApplyColor(selfButton.label, Theme.GetGearTrackColor(selfButton.trackID))
            end
        end)
        button:SetScript("OnLeave", function(selfButton)
            GearPlanning:StyleSeason2TrackButton(selfButton, selfButton.selected)
        end)
        button:SetScript("OnClick", function(selfButton)
            GearPlanning.season2SelectedTrack = selfButton.trackID
            GearPlanning:RenderUpgradeTrackView()
            scroll:ScrollToTop()
        end)
    end
    cursor = cursor + (rowCount * cardHeight) + ((rowCount - 1) * gap) + 18

    local selected = Season2Track(self.season2SelectedTrack or "champion") or tracks[1]
    if selected then
        local color = Theme.GetGearTrackColor(selected.id)
        local detail = self:AcquireSeason2Object(canvas, "detail")
        detail:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -cursor)
        detail:SetWidth(width)
        Theme.StylePanel(detail, COLORS.detailBg or COLORS.panel, color)
        detail.accent:SetColorTexture(unpack(color))

        local cardCursor = 14
        detail.title:ClearAllPoints()
        detail.title:SetPoint("TOPLEFT", detail, "TOPLEFT", 16, -cardCursor)
        detail.title:SetWidth(width - 32)
        detail.title:SetFont(Theme.fonts.body or STANDARD_TEXT_FONT, 19, "")
        Theme.ApplyColor(detail.title, color)
        local titleHeight = WrappedTextHeight(detail.title, selected.label, width - 32, 19, 22)
        detail.title:SetHeight(titleHeight)
        cardCursor = cardCursor + titleHeight + 2

        detail.meta:ClearAllPoints()
        detail.meta:SetPoint("TOPLEFT", detail, "TOPLEFT", 16, -cardCursor)
        detail.meta:SetWidth(width - 32)
        Theme.ApplyColor(detail.meta, COLORS.muted)
        local metaHeight = WrappedTextHeight(
            detail.meta,
            "Season 2 item-level range: " .. tostring(selected.range or ""),
            width - 32,
            11,
            15
        )
        detail.meta:SetHeight(metaHeight)
        cardCursor = cardCursor + metaHeight + 16

        detail.itemHeading:ClearAllPoints()
        detail.itemHeading:SetPoint("TOPLEFT", detail, "TOPLEFT", 16, -cardCursor)
        detail.itemHeading:SetWidth(width - 32)
        detail.itemHeading:SetHeight(14)
        detail.itemHeading:SetText("ITEM LEVELS")
        cardCursor = cardCursor + 22

        local chipX = 16
        local chipY = cardCursor
        local chipHeight = 25
        for _, itemLevel in ipairs(selected.itemLevels or {}) do
            local label = tostring(itemLevel)
            local chipWidth = math.max(60, math.ceil(#label * 8) + 22)
            if chipX + chipWidth > width - 16 then
                chipX = 16
                chipY = chipY + chipHeight + 7
            end
            local chip = self:AcquireSeason2Object(canvas, "chip")
            chip:SetParent(detail)
            chip:SetTrack(selected.id, label)
            chip:SetPoint("TOPLEFT", detail, "TOPLEFT", chipX, -chipY)
            chip:SetSize(chipWidth, chipHeight)
            chipX = chipX + chipWidth + 7
        end
        cardCursor = chipY + chipHeight + 14
        if selected.note and selected.note ~= "" then
            detail.note:Show()
            detail.note:ClearAllPoints()
            detail.note:SetPoint("TOPLEFT", detail, "TOPLEFT", 16, -cardCursor)
            detail.note:SetWidth(width - 32)
            local noteHeight = WrappedTextHeight(detail.note, selected.note, width - 32, 11, 15)
            detail.note:SetHeight(noteHeight)
            cardCursor = cardCursor + noteHeight + 4
        else
            detail.note:Hide()
        end
        detail:SetHeight(cardCursor + 10)
        cursor = cursor + cardCursor + 22
    end
    scroll:SetContentHeight(cursor + 4)
end

function GearPlanning:RenderGreatVaultView()
    local scroll = self.season2FullScroll
    if not scroll then return end
    local canvas = scroll.content
    self:ResetSeason2Canvas(canvas)
    local width = math.max(500, (scroll.viewport:GetWidth() or 800) - 2)
    local cursor = 0
    cursor = self:AddSeason2Text(canvas, "Great Vault Rewards", 2, cursor, width - 4, 17, COLORS.gold)
    cursor = cursor + 3
    cursor = self:AddSeason2Text(
        canvas,
        "Choose a weekly activity source to view only its Great Vault reward table.",
        2,
        cursor,
        width - 4,
        11,
        COLORS.muted
    )
    cursor = cursor + 12

    local sourceOrder = SEASON2_DATA.greatVaultSourceOrder or {}
    local gap = 6
    local buttonWidth = math.floor((width - ((#sourceOrder - 1) * gap)) / math.max(1, #sourceOrder))
    for index, sourceID in ipairs(sourceOrder) do
        local source = SEASON2_DATA.GetRewardSource and SEASON2_DATA.GetRewardSource(sourceID)
        local selectedSourceID = sourceID
        local button = self:AcquireSeason2Object(canvas, "tab")
        button.label:SetText(string.upper((source and source.label) or sourceID))
        button:SetPoint("TOPLEFT", canvas, "TOPLEFT", (index - 1) * (buttonWidth + gap), -cursor)
        button:SetSize(buttonWidth, 34)
        button:SetSelected((self.season2SelectedVaultSource or "dungeons") == sourceID)
        button:SetScript("OnClick", function()
            GearPlanning.season2SelectedVaultSource = selectedSourceID
            GearPlanning:RenderGreatVaultView()
            scroll:ScrollToTop()
        end)
    end
    cursor = cursor + 48

    if SEASON2_DATA.weeklyRewards then
        cursor = self:AddSeason2Callout(
            canvas,
            cursor,
            width,
            SEASON2_DATA.weeklyRewards.heading,
            SEASON2_DATA.weeklyRewards.body,
            COLORS.blue
        )
    end

    local selectedSourceID = self.season2SelectedVaultSource or "dungeons"
    local source = SEASON2_DATA.GetRewardSource and SEASON2_DATA.GetRewardSource(selectedSourceID)
    if source then
        cursor = self:AddSeason2Text(canvas, source.label .. " Great Vault", 2, cursor, width - 4, 15, COLORS.gold)
        cursor = cursor + 10
        for _, section in ipairs(SEASON2_DATA.GetGreatVaultSections and SEASON2_DATA.GetGreatVaultSections(selectedSourceID) or {}) do
            cursor = self:CreateRewardTable(canvas, section, cursor, width)
        end
    end
    scroll:SetContentHeight(cursor + 4)
end

function GearPlanning:SelectGearSource(sourceID)
    if not SEASON2_DATA.rewardSources or not SEASON2_DATA.rewardSources[sourceID] then return end
    self.season2SelectedSource = sourceID
    for id, button in pairs(self.season2SourceButtons or {}) do
        local selected = id == sourceID
        button.selected = selected
        Theme.StylePanel(
            button,
            selected and (COLORS.controlBg or COLORS.buttonBg) or (COLORS.transparent or {0, 0, 0, 0}),
            COLORS.transparent or {0, 0, 0, 0}
        )
        button.accent:SetShown(selected)
        Theme.ApplyColor(button.label, selected and COLORS.gold or COLORS.text)
    end
    self:RenderSeason2RewardSource()
    if self.season2RewardScroll then self.season2RewardScroll:ScrollToTop() end
end

function GearPlanning:SelectSeason2InfoView(viewID)
    if viewID ~= "upgradeTracks" and viewID ~= "greatVault" then viewID = "rewardSources" end
    self.season2SelectedInfoView = viewID
    for id, button in pairs(self.season2InfoViewButtons or {}) do
        button:SetSelected(id == viewID)
    end
    if self.season2RewardPane then self.season2RewardPane:SetShown(viewID == "rewardSources") end
    if self.season2FullScroll then self.season2FullScroll:SetShown(viewID ~= "rewardSources") end
    if viewID == "rewardSources" then
        self:SelectGearSource(self.season2SelectedSource or "dungeons")
    elseif viewID == "upgradeTracks" then
        self:RenderUpgradeTrackView()
        self.season2FullScroll:ScrollToTop()
    else
        self:RenderGreatVaultView()
        self.season2FullScroll:ScrollToTop()
    end
end

function GearPlanning:CreateUpgradeTrackRibbon(parent)
    local ribbon = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    ribbon:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -116)
    ribbon:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -14, -116)
    ribbon:SetHeight(76)
    Theme.StylePanel(ribbon, COLORS.contentBg or COLORS.bg, COLORS.softBorder or COLORS.border)
    local title = Theme.CreateText(ribbon, "UPGRADE TRACKS AT A GLANCE", "GameFontDisableSmall", 10, COLORS.blue)
    title:SetPoint("TOPLEFT", ribbon, "TOPLEFT", 10, -8)
    title:SetHeight(14)

    ribbon.cards = {}
    for _, track in ipairs(SEASON2_DATA.tracks or {}) do
        if track.showInRibbon then
            local card = CreateFrame("Frame", nil, ribbon, "BackdropTemplate")
            Theme.StylePanel(card, COLORS.badgeBg or COLORS.buttonBg, Theme.GetGearTrackColor(track.id))
            card.label = Theme.CreateText(card, track.ribbonLabel or string.upper(track.label), "GameFontHighlightSmall", 10, Theme.GetGearTrackColor(track.id), "CENTER")
            card.label:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -7)
            card.label:SetPoint("TOPRIGHT", card, "TOPRIGHT", -5, -7)
            card.label:SetHeight(13)
            card.range = Theme.CreateText(card, track.range or "", "GameFontHighlightSmall", 11, COLORS.text, "CENTER")
            card.range:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 5, 5)
            card.range:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -5, 5)
            card.range:SetHeight(14)
            ribbon.cards[#ribbon.cards + 1] = card
        end
    end

    function ribbon:LayoutCards()
        local count = #self.cards
        local available = math.max(300, (self:GetWidth() or 800) - 20)
        local gap = 6
        local width = math.floor((available - ((count - 1) * gap)) / math.max(1, count))
        for index, card in ipairs(self.cards) do
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", self, "TOPLEFT", 10 + ((index - 1) * (width + gap)), -28)
            card:SetSize(width, 39)
        end
    end
    ribbon:SetScript("OnSizeChanged", function(selfRibbon) selfRibbon:LayoutCards() end)
    ribbon:LayoutCards()
    return ribbon
end

function GearPlanning:CreateGearSourceSelector(parent)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    panel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    panel:SetWidth(190)
    Theme.StylePanel(panel, COLORS.contentBg or COLORS.bg, COLORS.softBorder or COLORS.border)
    local title = Theme.CreateText(panel, "GEAR SOURCE", "GameFontDisableSmall", 10, COLORS.blue)
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -10)
    title:SetHeight(14)

    local scroll = Theme.CreateScrollArea(panel, { step = 32 })
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -34)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -5, 8)
    self.season2SourceButtons = {}
    local cursor = 0
    for _, sourceID in ipairs(SEASON2_DATA.rewardSourceOrder or {}) do
        local source = SEASON2_DATA.rewardSources and SEASON2_DATA.rewardSources[sourceID]
        if source then
            local selectedSourceID = sourceID
            local button = CreateFrame("Button", nil, scroll.content, "BackdropTemplate")
            button:SetPoint("TOPLEFT", scroll.content, "TOPLEFT", 0, -cursor)
            button:SetPoint("TOPRIGHT", scroll.content, "TOPRIGHT", 0, -cursor)
            button:SetHeight(35)
            Theme.StylePanel(button, COLORS.transparent or {0, 0, 0, 0}, COLORS.transparent or {0, 0, 0, 0})
            button.accent = button:CreateTexture(nil, "ARTWORK")
            button.accent:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
            button.accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
            button.accent:SetWidth(3)
            button.accent:SetColorTexture(unpack(COLORS.gold))
            button.accent:Hide()
            button.label = Theme.CreateText(button, source.label, "GameFontHighlightSmall", 11, COLORS.text)
            button.label:SetPoint("LEFT", button, "LEFT", 12, 0)
            button.label:SetPoint("RIGHT", button, "RIGHT", -8, 0)
            button.label:SetHeight(18)
            button.label:SetJustifyV("MIDDLE")
            button:SetScript("OnEnter", function(selfButton)
                if not selfButton.selected then
                    Theme.ApplyColor(selfButton.label, COLORS.blue)
                    selfButton:SetBackdropColor(unpack(Theme.WithAlpha(COLORS.controlBg or COLORS.buttonBg, 0.56)))
                end
            end)
            button:SetScript("OnLeave", function(selfButton)
                if not selfButton.selected then
                    Theme.ApplyColor(selfButton.label, COLORS.text)
                    selfButton:SetBackdropColor(unpack(COLORS.transparent or {0, 0, 0, 0}))
                end
            end)
            button:SetScript("OnClick", function() GearPlanning:SelectGearSource(selectedSourceID) end)
            self.season2SourceButtons[sourceID] = button
            cursor = cursor + 38
        end
    end
    scroll:SetContentHeight(cursor)
    self.season2SourceScroll = scroll
    return panel
end

function GearPlanning:BuildSeason2InfoView(parent)
    local view = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    view:SetAllPoints(parent)
    Theme.StylePanel(view, COLORS.panel, COLORS.border)
    self.season2InfoView = view

    local title = Theme.CreateText(view, SEASON2_DATA.title or "Midnight Season 2 Gear Guide", "GameFontNormal", 17, COLORS.gold)
    title:SetPoint("TOPLEFT", view, "TOPLEFT", 14, -13)
    title:SetPoint("RIGHT", view, "RIGHT", -130, 0)
    title:SetHeight(22)
    local description = Theme.CreateText(
        view,
        SEASON2_DATA.description or "See where gear comes from, which upgrade track it uses, and what the Great Vault can reward.",
        "GameFontHighlightSmall",
        11,
        COLORS.muted
    )
    description:SetPoint("TOPLEFT", view, "TOPLEFT", 14, -40)
    description:SetPoint("RIGHT", view, "RIGHT", -130, 0)
    description:SetHeight(18)
    local seasonBadge = Theme.CreateBadge(view, SEASON2_DATA.season or "MN S2", 82, 30, COLORS.border, COLORS.text)
    seasonBadge:SetPoint("TOPRIGHT", view, "TOPRIGHT", -14, -14)

    local viewTabs = CreateFrame("Frame", nil, view, "BackdropTemplate")
    viewTabs:SetPoint("TOPLEFT", view, "TOPLEFT", 14, -70)
    viewTabs:SetSize(510, 34)
    Theme.StylePanel(viewTabs, COLORS.contentBg or COLORS.bg, COLORS.softBorder or COLORS.border)
    self.season2InfoViewButtons = {}
    local tabDefinitions = {
        { id = "rewardSources", label = "REWARD SOURCES", width = 175 },
        { id = "upgradeTracks", label = "UPGRADE TRACKS", width = 175 },
        { id = "greatVault", label = "GREAT VAULT", width = 160 },
    }
    local tabX = 0
    for _, definition in ipairs(tabDefinitions) do
        local selectedViewID = definition.id
        local button = Theme.CreateTextTabButton(viewTabs, definition.label, definition.width, 34, { fontSize = 10, underlineInset = 0 })
        button:SetPoint("TOPLEFT", viewTabs, "TOPLEFT", tabX, 0)
        button:SetScript("OnClick", function() GearPlanning:SelectSeason2InfoView(selectedViewID) end)
        self.season2InfoViewButtons[definition.id] = button
        tabX = tabX + definition.width
    end

    self.season2TrackRibbon = self:CreateUpgradeTrackRibbon(view)

    local contentHost = CreateFrame("Frame", nil, view)
    contentHost:SetPoint("TOPLEFT", view, "TOPLEFT", 14, -202)
    contentHost:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", -14, 14)
    self.season2ContentHost = contentHost

    local rewardPane = CreateFrame("Frame", nil, contentHost)
    rewardPane:SetAllPoints(contentHost)
    self.season2RewardPane = rewardPane
    self.season2SourcePanel = self:CreateGearSourceSelector(rewardPane)
    local rewardPanel = CreateFrame("Frame", nil, rewardPane, "BackdropTemplate")
    rewardPanel:SetPoint("TOPLEFT", self.season2SourcePanel, "TOPRIGHT", 10, 0)
    rewardPanel:SetPoint("BOTTOMRIGHT", rewardPane, "BOTTOMRIGHT", 0, 0)
    Theme.StylePanel(rewardPanel, COLORS.contentBg or COLORS.bg, COLORS.softBorder or COLORS.border)
    local rewardScroll = Theme.CreateScrollArea(rewardPanel, { step = 40 })
    rewardScroll:SetPoint("TOPLEFT", rewardPanel, "TOPLEFT", 12, -12)
    rewardScroll:SetPoint("BOTTOMRIGHT", rewardPanel, "BOTTOMRIGHT", -6, 12)
    rewardScroll.content.keylabPools = {}
    self.season2RewardScroll = rewardScroll

    local fullScroll = Theme.CreateScrollArea(contentHost, { step = 40 })
    fullScroll:SetAllPoints(contentHost)
    fullScroll.content.keylabPools = {}
    self.season2FullScroll = fullScroll
    fullScroll:Hide()

    rewardScroll.viewport:HookScript("OnSizeChanged", function(_, width)
        if rewardPane:IsShown() and width and width > 50 then GearPlanning:RenderSeason2RewardSource() end
    end)
    fullScroll.viewport:HookScript("OnSizeChanged", function(_, width)
        if not fullScroll:IsShown() or not width or width <= 50 then return end
        if GearPlanning.season2SelectedInfoView == "upgradeTracks" then
            GearPlanning:RenderUpgradeTrackView()
        elseif GearPlanning.season2SelectedInfoView == "greatVault" then
            GearPlanning:RenderGreatVaultView()
        end
    end)
    return view
end

function GearPlanning:RefreshSeason2Info()
    if not self.season2InfoView then return end
    if self.season2TrackRibbon then self.season2TrackRibbon:LayoutCards() end
    self:SelectSeason2InfoView(self.season2SelectedInfoView or "rewardSources")
end

function GearPlanning:ShowView(name)
    if name ~= "crafted" and name ~= "season2Info" then name = "guide" end
    self.selectedView = name
    self.guideView:SetShown(self.selectedView == "guide")
    self.craftedView:SetShown(self.selectedView == "crafted")
    self.season2InfoView:SetShown(self.selectedView == "season2Info")
    self.guideTab:SetSelected(self.selectedView == "guide")
    self.craftedTab:SetSelected(self.selectedView == "crafted")
    self.season2InfoTab:SetSelected(self.selectedView == "season2Info")
    if self.selectedView == "crafted" then self:RefreshRecipes() end
    if self.selectedView == "season2Info" then self:RefreshSeason2Info() end
end

function GearPlanning:Create(parent)
    local frame = CreateFrame("Frame", "KeyLabGearPlanningTab", parent, "BackdropTemplate")
    frame:SetAllPoints(parent)
    SetBackdrop(frame, COLORS.bg, {0, 0, 0, 0})

    KeyLab.UI.Theme.CreateTabHeader(
        frame,
        "Gear Planning",
        "Review general gearing information, choose crafted items for a convenient Auction House materials list, and check Season 2 reward sources and upgrade tracks."
    )

    self.guideTab = Button(frame, "Guide", 170, 34); self.guideTab:SetPoint("TOPLEFT", 18, -72)
    self.craftedTab = Button(frame, "Crafted Gear", 170, 34); self.craftedTab:SetPoint("LEFT", self.guideTab, "RIGHT", 10, 0)
    self.season2InfoTab = Button(frame, "Season 2 Info", 170, 34); self.season2InfoTab:SetPoint("LEFT", self.craftedTab, "RIGHT", 10, 0)
    local views = CreateFrame("Frame", nil, frame)
    views:SetPoint("TOPLEFT", 18, -116); views:SetPoint("BOTTOMRIGHT", -34, 18)
    self.guideView = self:BuildGuideView(views)
    self:BuildCraftedView(views)
    self:BuildSeason2InfoView(views)
    self.guideTab:SetScript("OnClick", function() self:ShowView("guide") end)
    self.craftedTab:SetScript("OnClick", function() self:ShowView("crafted") end)
    self.season2InfoTab:SetScript("OnClick", function() self:ShowView("season2Info") end)
    self.frame = frame
    self.recipePage, self.recipeSearch = 1, ""
    self.season2SelectedInfoView = "rewardSources"
    self.season2SelectedSource = "dungeons"
    self.season2SelectedTrack = "champion"
    self.season2SelectedVaultSource = "dungeons"
    self:ShowView("guide")
    frame:SetScript("OnShow", function()
        if self.selectedView == "crafted" then self:RefreshRecipes() end
        if self.selectedView == "season2Info" then self:RefreshSeason2Info() end
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
