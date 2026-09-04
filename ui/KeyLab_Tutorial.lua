-- KeyLab_Tutorial.lua
-- Optional, player-started guided tour for the KeyLab interface.

local _, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab
KeyLab.Tutorial = KeyLab.Tutorial or {}
local Tutorial = KeyLab.Tutorial

-- Use KeyLab's shared theme so the tour always matches the addon.
local Theme = KeyLab.UI and KeyLab.UI.Theme or {}
local Colors = Theme.colors or {
    bg={0.018,0.026,0.056,0.99}, panel={0.026,0.046,0.086,0.99},
    border={0.240,0.380,0.620,0.90}, gold={0.820,0.760,0.580,1},
    text={0.940,0.960,0.990,1}, muted={0.680,0.730,0.820,1}, blue={0.500,0.680,0.940,1},
}

local function ApplyColor(region,color)
    if not region or not color then return end
    if Theme.ApplyColor then Theme.ApplyColor(region,color) else region:SetTextColor(color[1],color[2],color[3],color[4] or 1) end
end
local function StylePanel(frame,background,border)
    if Theme.StylePanel then Theme.StylePanel(frame,background,border); return end
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    frame:SetBackdropColor(unpack(background)); frame:SetBackdropBorderColor(unpack(border))
end
local function Text(parent,value,size,color,justify)
    local fs=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
    fs:SetFont(STANDARD_TEXT_FONT,size or 12,""); fs:SetText(value or ""); fs:SetJustifyH(justify or "LEFT"); fs:SetJustifyV("TOP"); fs:SetWordWrap(true)
    ApplyColor(fs,color or Colors.text); return fs
end
local function Button(parent,label,width,height)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate"); b:SetSize(width or 96,height or 30); StylePanel(b,Colors.bg,Colors.border)
    b.label=Text(b,label or "",12,Colors.text,"CENTER"); b.label:SetPoint("CENTER"); b.label:SetSize((width or 96)-12,(height or 30)-6); b.label:SetJustifyV("MIDDLE")
    b:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(Colors.gold)); ApplyColor(self.label,Colors.gold) end)
    b:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(Colors.border)); ApplyColor(self.label,Colors.text) end)
    return b
end

local function CurrentTabContent()
    local ui=KeyLab.UI; local surface=ui and ui.tabFrames and ui.selectedTab and ui.tabFrames[ui.selectedTab]
    return surface and surface.tabContent or nil
end
local function Tab(name) return KeyLab.Tabs and KeyLab.Tabs[name] or nil end
local function Field(tabName,field) local tab=Tab(tabName); return tab and tab[field] or CurrentTabContent() end
local function Nav(name) return KeyLab.UI and KeyLab.UI.tabButtons and KeyLab.UI.tabButtons[name] or nil end
local function Mode(name) return KeyLab.UI and KeyLab.UI.modeButtons and KeyLab.UI.modeButtons[name] or nil end
local function HomeField(field) local h=Tab("Home"); return (h and h.frame and h.frame[field]) or (h and h[field]) or CurrentTabContent() end
local function HomeButton(name) local h=Tab("Home"); return h and h.frame and h.frame.subTabs and h.frame.subTabs[name] end
local function GearButton(name) local t=Tab("GearPlanning"); return t and ({guide=t.guideTab,crafted=t.craftedTab,season2Info=t.season2InfoTab})[name] end
local function GroupButton(name) local t=Tab("GroupDashboard"); return t and ({readiness=t.readinessTab,composition=t.compositionTab,targets=t.targetsTab})[name] end
local function SeqButton(name) local t=Tab("Sequencer"); return t and t.viewButtons and t.viewButtons[name] end
local function SeqField(field) return Field("Sequencer",field) end
local function MatcherField(field)
    local t=Tab("GearTargets"); local popup=t and t.preparationPopup
    return popup and (field and (popup[field] or t[field]) or popup) or Field("GearTargets","matcherButton")
end
local function PreparationField(field)
    local dashboard=Tab("GroupDashboard")
    local panel=dashboard and dashboard.snapshot
    local target=field=="handle" and dashboard and dashboard.snapshotHandle or field and panel and panel[field]
    return target and target:IsShown() and target or panel
end

local STEPS={
    {section="Start",title="Welcome to KeyLab",body="This tour shows where to click and what each page does. Use Next, Back, or Sections. Drag the top of this window whenever it covers something.",tab="Home",homeView="home",target=function() return HomeField("tourButton") end},
    {section="Start",title="Mythic+ and Raid",body="Mythic+ and Raid change Encounters, the latest summary, Talent Builds, Stat Profiles, Gear Profiles, and Trends. We will look at both sides.",tab="Home",target=function() return Mode("mplus") end},

    {section="Home",title="Three Home pages",body="Home contains News & Events, S2 Common Issues, and Game Updates. Use these buttons to move between them.",tab="Home",homeView="home",target=function() return HomeButton("news") end},
    {section="Home",title="Search every Home page",body="All three article pages use the search box at the top. Type a word to narrow the current page.",tab="Home",homeView="news",target=function() return HomeField("searchHost") end},
    {section="Home",title="News & Events",body="Use News & Events for useful World of Warcraft announcements and events found for KeyLab players.",tab="Home",homeView="news",target=function() return HomeButton("news") end},
    {section="Home",title="S2 Common Issues",body="Use S2 Common Issues to check tracked in-game and technical problems before troubleshooting your own setup.",tab="Home",homeView="issues",target=function() return HomeButton("issues") end},
    {section="Home",title="Game Updates",body="Use Game Updates for dated patch notes and completed hotfixes organized by category.",tab="Home",homeView="updates",target=function() return HomeButton("updates") end},

    {section="Runs",title="Open Mythic+",body="Click Mythic+. The next result pages use Mythic+ names and Mythic+ filter choices.",mode="mplus",tab="Encounters",target=function() return Mode("mplus") end},
    {section="Runs",title="Mythic+ Encounters",body="Filter saved runs by Dungeon, Key Level, Date, Performance Metric, and Sort. Select a row to see its setup and results.",mode="mplus",tab="Encounters",target=function() return Field("Encounters","dungeonDropdown") end},
    {section="Runs",title="Mythic+ Encounter filters",body="Key Level narrows difficulty. Date narrows when it happened. Performance Metric and Sort decide how the list is ordered.",mode="mplus",tab="Encounters",target=function() return Field("Encounters","keyDropdown") end},
    {section="Runs",title="Open Raid",body="Click Raid. The same result pages now use raid bosses and raid difficulties instead of dungeons and key levels.",mode="raid",tab="Encounters",target=function() return Mode("raid") end},
    {section="Runs",title="Raid Encounters",body="Filter individual boss pulls by Boss, Difficulty, Date, Performance Metric, and Sort. Select a pull for its saved details.",mode="raid",tab="Encounters",target=function() return Field("RaidEncounters","bossDropdown") end},
    {section="Runs",title="Raid Encounter filters",body="Difficulty separates raid levels. Date, Performance Metric, and Sort help you find the pull you want.",mode="raid",tab="Encounters",target=function() return Field("RaidEncounters","difficultyDropdown") end},
    {section="Runs",title="Last Run",body="On Mythic+, Summary is named Last Run. KeyLab keeps the latest 10 runs so you can reopen a recent full summary.",mode="mplus",tab="Summary",target=function() return Nav("Summary") end},
    {section="Runs",title="Last Raid",body="On Raid, Summary is named Last Raid. KeyLab keeps the latest 10 raid sessions and shows the boss pulls inside each one.",mode="raid",tab="Summary",target=function() return Nav("Summary") end},
    {section="Runs",title="Talent Builds: Mythic+",body="Only the top 5 saved builds are shown. Use Dungeon, Key Level, and Performance Metric, then select a build to inspect and copy it.",mode="mplus",tab="Talent Builds",target=function() return Field("TalentBuilds","dungeonDropdown") end},
    {section="Runs",title="Talent Builds: Raid",body="Only the top 5 builds for the chosen Boss, Difficulty, and Performance Metric are shown. This keeps unlike fights separate.",mode="raid",tab="Talent Builds",target=function() return Field("RaidTalentBuilds","bossDropdown") end},
    {section="Runs",title="Stat Profiles: Mythic+",body="Only the top 5 stat-priority profiles are shown. Filter by Dungeon, Key Level, and Performance Metric.",mode="mplus",tab="Stat Profiles",target=function() return Field("StatProfiles","dungeonDropdown") end},
    {section="Runs",title="Stat Profiles: Raid",body="Only the top 5 stat profiles for one Boss, Difficulty, and Performance Metric are shown. Select one for its exact percentages.",mode="raid",tab="Stat Profiles",target=function() return Field("RaidStatProfiles","bossDropdown") end},
    {section="Runs",title="Gear Profiles: Mythic+",body="Only the top 5 complete gear sets you used are shown. Filter by Dungeon, Key Level, and Performance Metric.",mode="mplus",tab="Gear Profiles",target=function() return Field("GearProfiles","primaryDropdown") end},
    {section="Runs",title="Gear Profiles: Raid",body="Only the top 5 complete gear sets for the chosen Boss, Difficulty, and Performance Metric are shown. Select one to see every item.",mode="raid",tab="Gear Profiles",target=function() return Field("RaidGearProfiles","primaryDropdown") end},
    {section="Runs",title="Trends changes too",body="Mythic+ Trends compares recent runs by dungeon. Raid Trends compares pull performance, execution, and consistency by boss and difficulty.",mode="mplus",tab="Trends",target=function() return Mode("mplus") end},

    {section="Practice",title="Start a Practice session",body="Choose single-target or multi-target, choose a test length, then start the session at a training dummy.",tab="Practice",target=function() return Field("Practice","startTypeDropdown") end},
    {section="Practice",title="Use a timed test",body="KeyLab recommends timed tests. Dummy areas can leave WoW stuck in combat. KeyLab saves the session when time ends, but you may need to leave the area afterward.",tab="Practice",target=function() return Field("Practice","startDurationDropdown") end},
    {section="Practice",title="Remember the rotation",body="Macro Sequence Version is optional. Choose it when testing a rotation so KeyLab remembers the exact version without handwritten notes. We will visit Macro Sequencer later.",tab="Practice",target=function() return Field("Practice","startSequenceDropdown") end},
    {section="Practice",title="Filter saved tests",body="Use Session Type, Test Length, Performance Metric, and Status to narrow the list. Select a row to read the full setup and result.",tab="Practice",target=function() return Field("Practice","typeFilterDropdown") end},

    {section="Gear Planning",title="Gear Planning Guide",body="The Guide provides gearing information and explains how Stat Goal Matcher, Gear Targets, and Gear Dashboard work together.",tab="Gear Planning",gearView="guide",target=function() return GearButton("guide") end},
    {section="Gear Planning",title="Crafted Gear",body="Search crafted items, review materials and options, and add an item to your plan. Open Shopping List shows everything the plan needs.",tab="Gear Planning",gearView="crafted",target=function() return GearButton("crafted") end},
    {section="Gear Planning",title="Shopping List at the Auction House",body="When you visit the Auction House, your saved Crafted Gear Shopping List opens automatically so you can compare materials with what you have.",tab="Gear Planning",gearView="crafted",target=function() return Field("GearPlanning","shoppingButton") end},
    {section="Gear Planning",title="Reward Sources",body="Season 2 Info has three menu choices. Reward Sources shows where gear comes from and the item levels available there.",tab="Gear Planning",gearView="season2Info",seasonView="rewardSources",target=function() local t=Tab("GearPlanning"); return t and t.season2InfoViewButtons and t.season2InfoViewButtons.rewardSources end},
    {section="Gear Planning",title="Upgrade Tracks",body="Upgrade Tracks shows each track and its item-level range. Use it to see how far an item can grow.",tab="Gear Planning",gearView="season2Info",seasonView="upgradeTracks",target=function() local t=Tab("GearPlanning"); return t and t.season2InfoViewButtons and t.season2InfoViewButtons.upgradeTracks end},
    {section="Gear Planning",title="Great Vault",body="Great Vault shows activity choices and the reward level each one can unlock.",tab="Gear Planning",gearView="season2Info",seasonView="greatVault",target=function() local t=Tab("GearPlanning"); return t and t.season2InfoViewButtons and t.season2InfoViewButtons.greatVault end},

    {section="Gear Targets",title="Browse Items",body="Browse Items chooses Dungeon and Raid together, Dungeon only, or Raid only. Slot and Loot Location narrow the list further.",tab="Gear Targets",target=function() return Field("GearTargets","itemTypeDropdown") end},
    {section="Gear Targets",title="Search and sort",body="Search Item finds a name. Click any column header to sort by that column; click it again to reverse the order.",tab="Gear Targets",target=function() return Field("GearTargets","searchBox") end},
    {section="Gear Targets",title="Show saved statuses",body="Show can display All Items, Goal Match Items, Targets, Alternatives, or Targets and Alternatives together.",tab="Gear Targets",target=function() return Field("GearTargets","statusDropdown") end},
    {section="Gear Targets",title="Primary-stat filters",body="For browsing, choose optional Stamina and at most one of Agility, Intellect, or Strength. These filters narrow the visible item list; they are not Stat Goal Matcher settings.",tab="Gear Targets",target=function() local t=Tab("GearTargets"); return t and t.primaryChecks and t.primaryChecks[1] and t.primaryChecks[1].button end},
    {section="Gear Targets",title="Secondary-stat filters",body="Choose up to two: Critical Strike, Haste, Mastery, or Versatility. These browsing filters help inspect stat pairs. The Matcher searches independently of the visible list.",tab="Gear Targets",target=function() local t=Tab("GearTargets"); return t and t.secondaryChecks and t.secondaryChecks[1] and t.secondaryChecks[1].button end},
    {section="Gear Targets",title="Unmarked, Target, Alternative",body="Targets are your plan. Alternatives are backup choices you also want to remember. Unmarked items are not saved to either list.",tab="Gear Targets",target=CurrentTabContent},
    {section="Gear Targets",title="Prepare your gear",body="Equip every item you want to keep. Unequip only the slots you want KeyLab to fill. For a full plan, unequip every eligible slot.",tab="Gear Targets",target=function() return Field("GearTargets","matcherButton") end},
    {section="Gear Targets",title="Open Matcher setup",body="The Stat Goal Matcher button opens this setup pop-up. Item source, matching style, weapon setup where needed, goal percentages, priority arrows, and Refresh Current Stats are all here. The tour opens setup only; it does not start a search.",tab="Gear Targets",matcherSetup=true,target=function() return MatcherField() end},
    {section="Gear Targets",title="Choose the search source",body="Choose Master Item Database or Equipped + Bags. With the database, include Dungeon, Raid, or Dungeon and Raid items. This choice does not change the Gear Targets browsing filters.",tab="Gear Targets",matcherSetup=true,target=function() return MatcherField("sourceDropdown") end},
    {section="Gear Targets",title="Refresh Current Stats",body="After changing equipment, use Refresh Current Stats here if needed. The current-stat comparisons and your goal entries now live inside this setup pop-up.",tab="Gear Targets",matcherSetup=true,target=function() return MatcherField("refreshStatsButton") end},
    {section="Gear Targets",title="Optional primary stat first",body="Choose None or your spec's primary stat. Choosing Agility for Feral makes it the #1 requirement and excludes Intellect-only weapons. Shared armor follows its item/spec rules. Rings, necklaces, and trinket handling are unchanged. There is no primary-stat percentage goal.",tab="Gear Targets",matcherSetup=true,target=function() return MatcherField("primaryDropdown") end},
    {section="Gear Targets",title="Choose a valid weapon setup",body="Specs with two valid arrangements choose Two-Handed or Dual Wield before starting. Specs whose core abilities require one setup show that requirement automatically. Dual Wield always means two compatible weapons; a shield or caster off-hand does not complete it.",tab="Gear Targets",matcherSetup=true,target=function() return MatcherField("weaponDropdown") end},
    {section="Gear Targets",title="Enter percentage goals",body="Enter the Crit, Haste, Mastery, and Versatility percentages wanted on your Character panel. Each may be 0% to 100%; they do not need to total 100%. Use ^ / v to order secondary priorities. If Primary first is selected, the secondary priorities follow it as #2 through #5.",tab="Gear Targets",matcherSetup=true,target=function() return MatcherField("goalPanel") end},
    {section="Gear Targets",title="Choose a matching style",body="Balanced looks for the smallest total gap from your goals. Favor Priority gives more weight to your #1 stat, then #2, #3, and #4. Goals and priorities are saved for the spec you are planning.",tab="Gear Targets",matcherSetup=true,target=function() return MatcherField("styleDropdown") end},
    {section="Gear Targets",title="Gear across your class's specs",body="The database search includes recorded loot from all specs of your class, while class and weapon-slot restrictions still apply. An item from another spec is not automatically a good choice for your role. Check its stats, effects, and Loot Spec label.",tab="Gear Targets",matcherSetup=true,target=function() return MatcherField("scopeDropdown") end},
    {section="Gear Targets",title="Start when ready",body="Leave at least one eligible slot empty, finish setup, and wait for the short countdown. Click Start Matcher while out of combat. Or choose Cancel and continue the tour without running it.",tab="Gear Targets",matcherSetup=true,target=function() return MatcherField("run") end},
    {section="Gear Targets",title="What the Matcher does",body="KeyLab locks equipped items, searches open slots, and projects the finished set. It compares secondary stats, not Tier bonuses, special effects, embellishments, or Best in Slot.",tab="Gear Targets",target=function() return Field("GearTargets","matcherStatusCard") end},
    {section="Gear Targets",title="Open the Results report",body="After a run, Results reopens the last report. It shows projected stats, chosen items, reduced-efficiency warnings, and important notes.",tab="Gear Targets",target=function() return Field("GearTargets","matcherResultsButton") end},
    {section="Gear Targets",title="Goal Match and Stat Support",body="Goal Match means the closest stat combination found, not Best in Slot. Trinket secondary stats are excluded from the goal projection. An open trinket slot may receive separate advisory Stat Support suggestions; KeyLab does not judge the effects.",tab="Gear Targets",target=CurrentTabContent},
    {section="Gear Targets",title="Mark the matched plan",body="Mark wanted Goal Match items as Target. Rings and trinkets use Finger 1 or 2 and Trinket 1 or 2 so both slots stay clear.",tab="Gear Targets",target=CurrentTabContent},
    {section="Gear Targets",title="Check loot spec before drops",body="Loot Spec under each item lists its recorded drop specs. The raid/M+ Gear Targets pop-ups also show Loot Spec Set; orange change-needed labels flag a mismatch. Use Preparation Panel to change loot spec before seeking the item. Raid loot rules may differ.",tab="Gear Targets",target=CurrentTabContent},
    {section="Gear Targets",title="Clear the tutorial plan",body="Clear Targets removes every Target for this specialization at once. This works like unmarking each Target one at a time.",tab="Gear Targets",target=function() return Field("GearTargets","clearTargetsButton") end},

    {section="Gear Dashboard",title="Equipped gear",body="Each slot shows item name, item level, upgrade track and rank, saved target, and target source. Hover an item for its normal WoW tooltip.",tab="Gear Dashboard",target=CurrentTabContent},
    {section="Gear Dashboard",title="Tier and Alternatives",body="Tier Set shows which eligible slots count. Alternative Items keeps saved backup choices visible in one place.",tab="Gear Dashboard",target=function() return Field("GearDashboard","tierCard") end},
    {section="Gear Dashboard",title="Crests and seasonal currency",body="This area shows the upgrade resources KeyLab can read from your bags and currency list.",tab="Gear Dashboard",target=function() return Field("GearDashboard","currencyCard") end},
    {section="Gear Dashboard",title="Myth Target Progress",body="A target counts complete only when that exact item is equipped on the Myth track. Hero and lower-track copies stay unfinished goals.",tab="Gear Dashboard",target=function() return Field("GearDashboard","progressCard") end},

    {section="Groups",title="Group Readiness",body="See each player, class and spec, item level, role, leader or assistant status, and checked auras. Use Check Group Status when everyone is nearby.",tab="Group Dashboard",groupView="readiness",target=function() return GroupButton("readiness") end},
    {section="Groups",title="Read aura icons",body="Hover player-card icons to identify buffs, food, oils, flasks, and other checked auras. Progress tells how many players were checked.",tab="Group Dashboard",groupView="readiness",target=function() return Field("GroupDashboard","readinessView") end},
    {section="Groups",title="Group Composition",body="Green highlighted rows mean the capability is present. Class/Spec is inherent. Talent and Pet columns are capabilities the player could have.",tab="Group Dashboard",groupView="composition",target=function() return GroupButton("composition") end},
    {section="Groups",title="Macro Targets requirements",body="Macro Targets works only after you create a Macro Sequence and mark a friendly-support block as a Group Target.",tab="Group Dashboard",groupView="targets",target=function() return GroupButton("targets") end},
    {section="Groups",title="Change a target in three clicks",body="Example: Misdirection is saved for your pet, but this group needs the tank. Choose the player, choose the marked macro, then Save Target.",tab="Group Dashboard",groupView="targets",target=function() return Field("GroupDashboard","targetsView") end},
    {section="Groups",title="Temporary targets",body="Assignments change only out of combat. If a raid member moves, choose Keep or Change. Leaving the group restores the original macro target.",tab="Group Dashboard",groupView="targets",target=function() return Field("GroupDashboard","applyTargetButton") end},

    {section="Preparation Panel",title="Your compact preparation hub",body="Minimize the main addon to open Preparation Panel. It is available solo or in a group, with talents, loot spec, shopping lists, and quick navigation. Drag the panel to move it. The tour highlights its controls without changing your setup.",preparationView="panel",target=function() return PreparationField() end},
    {section="Preparation Panel",title="Check and switch talent builds",body="See your current talent build here. Choose a saved build and press Switch when allowed. You can switch before an M+ key starts, but not during an active key or combat. After switching, the panel minimizes so you can see the game.",preparationView="panel",target=function() return PreparationField("talentDropdown") end},
    {section="Preparation Panel",title="Choose your loot specialization",body="Check Loot Spec, choose a spec from the dropdown, and press Set Loot Spec. Match it to the item you want before drops. This changes your loot setting, not your active talents. Current Spec follows your active specialization.",preparationView="panel",target=function() return PreparationField("lootDropdown") end},
    {section="Preparation Panel",title="Readiness at a glance",body="In a party or raid, Check Group Status checks nearby members. Five player rows are visible at a time; scroll for more. Group sections are hidden while solo. Open the full Group Dashboard for detailed readiness information.",preparationView="panel",target=function() return PreparationField("rosterScroll") end},
    {section="Preparation Panel",title="Confirmed group capabilities",body="The compact composition list shows only present Class/Spec capabilities, not possible Talent or Pet choices. The full Group Dashboard has the detailed columns. This section appears when you are grouped.",preparationView="panel",target=function() return PreparationField("capabilityScroll") end},
    {section="Preparation Panel",title="Open your shopping lists",body="Craft Shopping List opens your saved crafting materials. Gear Target List opens your saved dungeon and raid items, including their Loot Spec labels. These buttons open the existing lists without needing the full addon window.",preparationView="panel",target=function() return PreparationField("targetsButton") end},
    {section="Preparation Panel",title="Jump to a full addon page",body="Choose a destination in the Go To dropdown, then press Open. This restores the main addon directly to that page, including the detailed Group Dashboard. The dropdown keeps the compact panel small.",preparationView="panel",target=function() return PreparationField("navigation") end},
    {section="Preparation Panel",title="Minimize to the small handle",body="Use the panel's minus button to shrink it to the small PREP PANEL handle. The next step highlights that handle so you can recognize it during your runs.",preparationView="panel",target=function() return PreparationField("minimizeButton") end},
    {section="Preparation Panel",title="Click the handle to reopen",body="This is the minimized handle. Click it whenever you need Preparation Panel while out of combat, even when solo. You can drag it to a convenient spot. The panel and handle hide during combat; the handle returns afterward so you can prepare between pulls.",preparationView="handle",target=function() return PreparationField("handle") end},

    {section="Macros",title="Macro Sequencer",body="Build class- and spec-based sequences from your own WoW macros. One physical press tries one block; WoW always decides what can cast.",tab="Sequencer",sequencerView="editor",target=function() return SeqButton("editor") end},
    {section="Macros",title="Create or choose a Sequence",body="Choose an existing Sequence, or use New and give it a name. Copy duplicates one. Delete sends it to Recycle Bin.",tab="Sequencer",sequencerView="editor",target=function() return SeqField("sequenceDropdown") end},
    {section="Macros",title="Set a binding",body="Set adds a key or mouse button. Edit changes it. Delete removes it. Bindings belong to the current class, spec, and sequence.",tab="Sequencer",sequencerView="editor",target=function() return SeqField("bindingSetButton") end},
    {section="Macros",title="Add an example macro",body="Enter /cast [@pet] Misdirection in Create or Edit Macro. Choose Add to place it into Sequence of Macros below.",tab="Sequencer",sequencerView="editor",target=function() return SeqField("macroPanel") end},
    {section="Macros",title="Edit a saved block",body="Select a block to load it above. Clear starts fresh. Save updates it. Delete removes that block from this version.",tab="Sequencer",sequencerView="editor",target=function() return SeqField("macroSaveButton") end},
    {section="Macros",title="Order and enable blocks",body="Use each block's up and down arrows to change order. Enabled controls whether the saved block participates in the active sequence.",tab="Sequencer",sequencerView="editor",target=function() return SeqField("blocksPanel") end},
    {section="Macros",title="Choose sequence modes",body="Set All Macros applies a mode to the sequence. Individual groups can use their own mode. Information explains how every mode advances.",tab="Sequencer",sequencerView="editor",target=function() return SeqField("modeDropdown") end},
    {section="Macros",title="Mark a Group Target",body="Mark the Misdirection block as Group Target. Group Dashboard can then temporarily change @pet to a selected party or raid member.",tab="Sequencer",sequencerView="editor",target=function() return SeqField("blocksPanel") end},
    {section="Macros",title="Create Versions",body="Versions keep different setups for Mythic+, Raid, single target, or multi-target. New, Rename, Duplicate, Delete, and Activate Selected manage them.",tab="Sequencer",sequencerView="editor",target=function() return SeqField("versionsPanel") end},
    {section="Macros",title="Save and test",body="Choose Save Changes before leaving. Group Dashboard targets are temporary; the original /cast [@pet] Misdirection returns when the group ends.",tab="Sequencer",sequencerView="editor",target=function() return SeqField("saveChangesButton") end},
    {section="Macros",title="Binding List",body="Binding List shows each sequence, its active version, binding, and status for your current class and spec.",tab="Sequencer",sequencerView="binding",target=function() return SeqButton("binding") end},
    {section="Macros",title="Information and Recycle Bin",body="Information explains Sequencer rules and options. Recycle Bin can restore a deleted sequence or version for 30 days.",tab="Sequencer",sequencerView="information",target=function() return SeqButton("information") end},

    {section="Finish",title="Insights",body="Insights provides quick reference notes about encounters, stats, macros, spell queue behavior, and simulations.",tab="Insights",target=function() return Nav("Insights") end},
    {section="Finish",title="Settings",body="Settings controls window behavior, the Group Finder helper, backup instructions, and old-season data removal.",tab="Settings",target=function() return Nav("Settings") end},
    {section="Finish",title="Tour complete",body="You are ready to use KeyLab. Close the tour now. Take the Tour stays on Home whenever you want to start again.",tab="Home",homeView="home",target=function() return HomeField("tourButton") end},
}

local SECTIONS,seen={},{}
for index,step in ipairs(STEPS) do if not seen[step.section] then seen[step.section]=true; table.insert(SECTIONS,{label=step.section,step=index}) end end

local function CreateHighlight()
    local f=CreateFrame("Frame","KeyLabTutorialHighlight",UIParent); f:SetFrameStrata("TOOLTIP"); f:SetFrameLevel(900); f:EnableMouse(false)
    f.fill=f:CreateTexture(nil,"BACKGROUND"); f.fill:SetAllPoints(f); f.fill:SetColorTexture(Colors.gold[1],Colors.gold[2],Colors.gold[3],0.08)
    f.edges={}; for _,side in ipairs({"top","bottom","left","right"}) do local e=f:CreateTexture(nil,"OVERLAY"); e:SetColorTexture(Colors.gold[1],Colors.gold[2],Colors.gold[3],1); f.edges[side]=e end
    f.edges.top:SetPoint("TOPLEFT"); f.edges.top:SetPoint("TOPRIGHT"); f.edges.top:SetHeight(3)
    f.edges.bottom:SetPoint("BOTTOMLEFT"); f.edges.bottom:SetPoint("BOTTOMRIGHT"); f.edges.bottom:SetHeight(3)
    f.edges.left:SetPoint("TOPLEFT"); f.edges.left:SetPoint("BOTTOMLEFT"); f.edges.left:SetWidth(3)
    f.edges.right:SetPoint("TOPRIGHT"); f.edges.right:SetPoint("BOTTOMRIGHT"); f.edges.right:SetWidth(3)
    f.badge=CreateFrame("Frame",nil,f,"BackdropTemplate"); f.badge:SetSize(112,24); f.badge:SetPoint("BOTTOM",f,"TOP",0,5); StylePanel(f.badge,Colors.bg,Colors.gold)
    f.lookHere=Text(f.badge,"LOOK HERE",11,Colors.gold,"CENTER"); f.lookHere:SetAllPoints(f.badge); f.lookHere:SetJustifyV("MIDDLE")
    f.elapsed=0; f:SetScript("OnUpdate",function(self,elapsed) self.elapsed=(self.elapsed or 0)+elapsed; local a=0.72+(0.28*math.sin(self.elapsed*4)); for _,e in pairs(self.edges) do e:SetAlpha(a) end; self.badge:SetAlpha(a) end)
    f:Hide(); return f
end

function Tutorial:Create()
    if self.frame then return self.frame end
    local f=CreateFrame("Frame","KeyLabGuidedTourFrame",UIParent,"BackdropTemplate"); f:SetSize(520,278)
    local anchor=KeyLab.UI and KeyLab.UI.frame or UIParent; f:SetPoint("BOTTOM",anchor,"BOTTOM",0,24)
    f:SetFrameStrata("TOOLTIP"); f:SetFrameLevel(950); f:SetClampedToScreen(true); f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) self:StartMoving() end); f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end); StylePanel(f,Colors.bg,Colors.gold)
    Theme.AddPopupLogo(f)
    f.eyebrow=Text(f,"KEYLAB TOUR  •  DRAG TO MOVE",11,Colors.blue); f.eyebrow:SetPoint("TOPLEFT",66,-15); f.eyebrow:SetSize(230,18)
    f.progress=Text(f,"",11,Colors.muted,"RIGHT"); f.progress:SetPoint("TOPRIGHT",-18,-15); f.progress:SetSize(190,18)
    f.title=Text(f,"",20,Colors.gold); f.title:SetPoint("TOPLEFT",18,-55); f.title:SetPoint("RIGHT",-18,0); f.title:SetHeight(32)
    f.body=Text(f,"",14,Colors.text); f.body:SetPoint("TOPLEFT",f.title,"BOTTOMLEFT",0,-9); f.body:SetPoint("RIGHT",-18,0); f.body:SetHeight(116); f.body:SetSpacing(4)
    f.back=Button(f,"Back",82,32); f.back:SetPoint("BOTTOMLEFT",18,15)
    f.sections=Button(f,"Sections",106,32); f.sections:SetPoint("LEFT",f.back,"RIGHT",8,0)
    f.close=Button(f,"Close",82,32); f.close:SetPoint("BOTTOMRIGHT",-18,15)
    f.next=Button(f,"Next",82,32); f.next:SetPoint("RIGHT",f.close,"LEFT",-8,0)
    f.menu=CreateFrame("Frame",nil,f,"BackdropTemplate"); f.menu:SetSize(250,20+(#SECTIONS*30)); f.menu:SetPoint("BOTTOM",f.sections,"TOP",0,8); f.menu:SetFrameLevel(f:GetFrameLevel()+10); StylePanel(f.menu,Colors.bg,Colors.gold); f.menu:Hide(); f.menu.buttons={}
    for index,def in ipairs(SECTIONS) do local s=def; local b=Button(f.menu,s.label,222,26); b:SetPoint("TOPLEFT",14,-10-((index-1)*30)); b:SetScript("OnClick",function() f.menu:Hide(); Tutorial:ShowStep(s.step) end); f.menu.buttons[index]=b end
    f.back:SetScript("OnClick",function() Tutorial:ShowStep((Tutorial.stepIndex or 1)-1) end)
    f.next:SetScript("OnClick",function() local i=Tutorial.stepIndex or 1; if i>=#STEPS then Tutorial:Stop() else Tutorial:ShowStep(i+1) end end)
    f.sections:SetScript("OnClick",function() f.menu:SetShown(not f.menu:IsShown()) end); f.close:SetScript("OnClick",function() Tutorial:Stop() end); f:SetScript("OnHide",function() f.menu:Hide() end)
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:SetScript("OnEvent",function() if Tutorial.active then Tutorial:Stop() end end)
    self.frame=f; self.highlight=CreateHighlight(); return f
end

function Tutorial:PrepareStep(step)
    local ui=KeyLab.UI; if not ui then return false end
    if InCombatLockdown and InCombatLockdown() then if KeyLab.Print then KeyLab.Print("Leave combat before starting the KeyLab tour.") end; return false end
    if not step.matcherSetup and self.matcherTourPopup then
        self.matcherTourPopup:Hide(); self.matcherTourPopup=nil
    end
    self.showingPreparation=step.preparationView~=nil
    local dashboard=Tab("GroupDashboard")
    if step.preparationView and dashboard and dashboard.OpenPreparationPanel then
        if ui.frame and ui.frame:IsShown() then ui:SetMenuOnly(true) end
        if dashboard.EnsureGroupSnapshot then dashboard:EnsureGroupSnapshot() end
        if step.preparationView=="handle" then dashboard:MinimizePreparationPanel()
        else dashboard:OpenPreparationPanel() end
        return true
    end
    ui:Show(); if ui.isMenuOnly then ui:SetMenuOnly(false) end
    if step.mode and ui.SetContentMode then ui:SetContentMode(step.mode) end
    if step.tab then ui:SelectTab(step.tab) end
    if step.homeView and Tab("Home") and Tab("Home").frame then Tab("Home").frame:SelectSubTab(step.homeView) end
    if step.gearView and Tab("GearPlanning") then Tab("GearPlanning"):ShowView(step.gearView) end
    if step.seasonView and Tab("GearPlanning") then Tab("GearPlanning"):SelectSeason2InfoView(step.seasonView) end
    if step.groupView and Tab("GroupDashboard") then Tab("GroupDashboard"):SetView(step.groupView) end
    if step.sequencerView and Tab("Sequencer") then Tab("Sequencer"):SetView(step.sequencerView) end
    local targets=Tab("GearTargets")
    if step.matcherSetup and targets and targets.OpenPreparationPopup then
        local popup=targets.preparationPopup
        if not popup or not popup:IsShown() then
            targets:OpenPreparationPopup()
            self.matcherTourPopup=targets.preparationPopup
        end
    end
    return true
end
function Tutorial:HighlightTarget(target)
    local h=self.highlight; if not h then return end; h:Hide(); h:ClearAllPoints()
    if not target or not target.IsShown or not target:IsShown() then return end
    h:SetPoint("TOPLEFT",target,"TOPLEFT",-6,6); h:SetPoint("BOTTOMRIGHT",target,"BOTTOMRIGHT",6,-6); h.elapsed=0; h:Show()
end
function Tutorial:ShowStep(index)
    index=math.max(1,math.min(#STEPS,tonumber(index) or 1)); local step=STEPS[index]; if not self:PrepareStep(step) then return end
    local f=self:Create(); self.active=true; self.stepIndex=index
    f.eyebrow:SetText("KEYLAB TOUR  •  "..tostring(step.section or "").."  •  DRAG TO MOVE"); f.progress:SetText("Step "..index.." of "..#STEPS)
    f.title:SetText(step.title or "KeyLab"); f.body:SetText(step.body or ""); f.back:SetEnabled(index>1); f.back:SetAlpha(index>1 and 1 or 0.45); f.next.label:SetText(index==#STEPS and "Finish" or "Next"); f:Show()
    local function ApplyTarget() if not Tutorial.active or Tutorial.stepIndex~=index then return end; local t=type(step.target)=="function" and step.target() or CurrentTabContent(); Tutorial:HighlightTarget(t or CurrentTabContent()) end
    if C_Timer and C_Timer.After then C_Timer.After(0,ApplyTarget) else ApplyTarget() end
end
function Tutorial:Start()
    if InCombatLockdown and InCombatLockdown() then if KeyLab.Print then KeyLab.Print("Leave combat before starting the KeyLab tour.") end; return end
    self:Create(); local main=KeyLab.UI and KeyLab.UI.frame
    if main and not self.mainFrameHooked then main:HookScript("OnHide",function() if Tutorial.active and not Tutorial.showingPreparation then Tutorial:Stop() end end); self.mainFrameHooked=true end
    self:ShowStep(1)
end
function Tutorial:Stop()
    self.active=false
    self.showingPreparation=nil
    if self.matcherTourPopup then self.matcherTourPopup:Hide(); self.matcherTourPopup=nil end
    if self.frame then self.frame:Hide() end
    if self.highlight then self.highlight:Hide() end
end
