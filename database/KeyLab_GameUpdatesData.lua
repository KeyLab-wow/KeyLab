-- KeyLab_GameUpdatesData.lua
-- Data source for the Home tab's News & Events and Game Updates readers.
--
-- Official article wording belongs here rather than in KeyLab_Home.lua. The
-- starter tuning article below contains only the text present in the approved
-- design reference; future posts can be added without changing the reader UI.

local ADDON_NAME, KeyLab = ...

KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

local Data = KeyLab.GameUpdatesData or {}
KeyLab.GameUpdatesData = Data

Data.articles = {
    {
        id = "curse-of-ulatek-2026-08-11",
        internalTab = "news",
        category = "CONTENT UPDATE",
        title = "Curse of Ula’tek Is Now Live",
        publicationDate = "Aug 11, 2026",
        publicationSort = 20260811,
        sourceLabel = "Official World of Warcraft news",
        articleType = "article",
        sections = {
            {
                paragraphs = {
                    "The Curse of Ula’tek content update launched on August 11, with Midnight Season 2 beginning August 18.",
                },
            },
            {
                heading = "Explore the Coiled Isle",
                paragraphs = {
                    "The new outdoor zone includes:",
                },
                changes = {
                    { text = "Vaults of Atal’Utek group activities and public events" },
                    { text = "Curse Surges with rare elites at five rotating locations" },
                    { text = "Cursed Fishing unlocked by defeating rare elites" },
                    { text = "A zone-specific talent tree with power and quality-of-life perks" },
                    { text = "New quests and activities" },
                },
            },
            {
                heading = "New Group Content",
                changes = {
                    { text = "Altar of Fangs: A new three-boss dungeon available through Mythic 0. It joins the Mythic+ rotation when Season 2 begins." },
                    { text = "Venomous Abyss: A new eight-boss raid opening with Season 2." },
                    { text = "Lairs: Instanced world-boss encounters with scaling difficulty through flexible Mythic for 15–25 players." },
                    { text = "New Delves: The Ring of Glory, Gnarldor Isle, and the Venomfall Deeps Nemesis Delve." },
                },
                afterParagraphs = {
                    "Bountiful Delves and tiers above Tier 7 become available when Season 2 begins.",
                },
            },
            {
                heading = "Midnight Season 2",
                paragraphs = {
                    "Season 2 begins August 18 and includes:",
                },
                changes = {
                    { text = "Venomous Abyss raid" },
                    { text = "New Mythic+ season and dungeon rotation" },
                    { text = "New PvP season" },
                    { text = "Arenas versus bots" },
                    { text = "New Prey targets, affixes, and hunts" },
                    { text = "Bountiful Delves" },
                    { text = "New Arcantina quests" },
                },
            },
            {
                heading = "Mythic+ Rotation",
                changes = {
                    { text = "Altar of Fangs" },
                    { text = "Murder Row" },
                    { text = "Den of Nalorakk" },
                    { text = "The Blinding Vale" },
                    { text = "Voidscar Arena" },
                    { text = "Kings’ Rest" },
                    { text = "Ruby Life Pools" },
                    { text = "Temple of Sethraliss" },
                },
            },
            {
                heading = "Interface Updates",
                changes = {
                    { text = "The Cooldown Manager can now track trinkets and potions." },
                    { text = "Players can ping their action bars and Cooldown Manager to share spell availability." },
                    { text = "Players can ping their own unit frames to communicate information such as their current health." },
                    { text = "Healers can configure which healing buffs appear on Raid Frames and set their display priority." },
                },
            },
            {
                heading = "Housing and Social Features",
                changes = {
                    { text = "Save, export, and import complete homes or individual rooms." },
                    { text = "Reset a home and return placed items to storage." },
                    { text = "Review which items are owned or missing before importing a blueprint." },
                    { text = "Use Pet Beds to let companion pets roam inside the home." },
                    { text = "Complete four new neighborhood Endeavors." },
                    { text = "Connect Battle.net and Discord to communicate with guildmates in and out of the game." },
                },
            },
        },
        footer = "Source: Official World of Warcraft news",
    },
    {
        id = "twitch-drop-sorcerers-grassy-garb-2026-08-11",
        internalTab = "news",
        category = "TWITCH DROP",
        menuTitle = "Twitch Drop: Sorcerer’s Grassy Garb",
        title = "Earn the Sorcerer’s Grassy Garb Twitch Drop",
        publicationDate = "August 11, 2026",
        publicationSort = 20260811,
        sourceLabel = "Blizzard Entertainment — Official World of Warcraft News",
        articleType = "article",
        sections = {
            {
                paragraphs = {
                    "Watch eligible World of Warcraft streams on Twitch to earn the Ensemble: Sorcerer’s Grassy Garb transmog set.",
                },
            },
            {
                heading = "Availability",
                changes = {
                    { text = "Starts: August 11 at 10:00 AM PDT" },
                    { text = "Ends: September 8 at 10:00 AM PDT" },
                    { text = "Watch Time Required: 4 hours" },
                },
                afterParagraphs = {
                    "You can watch any eligible stream in the World of Warcraft category and switch between channels without losing progress.",
                    "Watching multiple channels simultaneously will not increase your progress.",
                },
            },
            {
                heading = "Connect Your Accounts",
                paragraphs = {
                    "Your Twitch and Battle.net accounts must be connected through the Battle.net Connections page.",
                    "If you recently changed your password or account information, you may need to reconnect them.",
                    "After connecting a Twitch account, there is a seven-day cooldown before a different Twitch account can be connected.",
                },
            },
            {
                heading = "Claiming the Reward",
                changes = {
                    { text = "Claim the completed reward through the Twitch channel or your Twitch Drops Inventory." },
                    { text = "The first Battle.net region you log into after claiming will receive the reward." },
                    { text = "Delivery may take up to 24 hours." },
                    { text = "Earned rewards expire after seven days if a Battle.net account has not been connected." },
                },
            },
            {
                heading = "Supported Devices",
                paragraphs = {
                    "Drops can be earned and claimed through:",
                },
                changes = {
                    { text = "PC or Mac web browsers" },
                    { text = "Twitch for Android" },
                    { text = "Twitch for iOS" },
                },
                afterParagraphs = {
                    "Twitch apps on consoles, smart televisions, and other TV devices do not support Drops.",
                },
            },
            {
                heading = "Eligibility",
                paragraphs = {
                    "The promotion is available in participating regions worldwide.",
                    "The reward is not available in World of Warcraft Classic and requires an active World of Warcraft subscription or game time.",
                },
            },
        },
        footer = "Source: Blizzard Entertainment — Official World of Warcraft News",
    },
    {
        id = "curse-of-ulatek-pre-season-details-2026-08-10",
        internalTab = "news",
        category = "PRE-SEASON",
        menuTitle = "Curse of Ula’tek Pre-Season Details",
        title = "Curse of Ula’tek Pre-Season Details",
        publicationDate = "August 10, 2026",
        publicationSort = 20260810,
        sourceLabel = "Blizzard Entertainment — Official World of Warcraft News",
        articleType = "article",
        sections = {
            {
                paragraphs = {
                    "The Curse of Ula’tek update launches during the week of August 11. Season 2 begins with a one-week pre-season period before its full launch on August 18.",
                },
            },
            {
                heading = "Season 1 Ends",
                changes = {
                    { text = "Season 1 competitive PvP ends at 10:00 PM PDT the night before regional maintenance." },
                    { text = "Mythic+ and PvP percentile cutoffs will be calculated when maintenance begins." },
                },
            },
            {
                heading = "Great Vault and Crafting",
                changes = {
                    { text = "The Great Vault during pre-season will contain rewards earned during the final week of Season 1." },
                    { text = "Season 2 Great Vault progress begins during pre-season." },
                    { text = "The first Season 2 Great Vault rewards can be claimed on August 18." },
                    { text = "Season 2 Crafting Sparks begin dropping during pre-season." },
                    { text = "The first Season 2 Great Vault’s World row is limited to Champion 3/6 gear." },
                    { text = "Later Great Vaults can award up to Hero 1/6 gear from the World row." },
                },
            },
            {
                heading = "Voidcore Bonus Rolls",
                paragraphs = {
                    "Voidcore bonus rolls will not be available in the first Season 2 Great Vault.",
                    "They become available during the week of August 25 and can be selected by players who have unlocked at least three Great Vault panes.",
                },
            },
            {
                heading = "Outdoor Content",
                paragraphs = {
                    "The following Season 2 activities are available during pre-season:",
                },
                changes = {
                    { text = "Curse Surges" },
                    { text = "Vaults of Atal’Utek" },
                    { text = "Rare enemies and outdoor rewards" },
                    { text = "Pinnacle Caches containing Season 2 Veteran gear" },
                },
            },
            {
                heading = "Dungeons",
                paragraphs = {
                    "The Season 2 dungeon pool will be available on Heroic and Mythic 0 difficulty, including the new Altar of Fangs dungeon.",
                    "During pre-season only:",
                },
                changes = {
                    { text = "Mythic 0 dungeons award Champion 1/6 gear." },
                    { text = "Mythic 0 dungeons use a weekly lockout." },
                    { text = "Mythic+ does not begin until Season 2 launches on August 18." },
                },
            },
            {
                heading = "Delves",
                changes = {
                    { text = "Delve difficulties 1–11 will be available." },
                    { text = "The ? Nemesis difficulty will also be available." },
                    { text = "Bountiful Delves and seasonal Delve progression begin with Season 2." },
                },
            },
            {
                heading = "Lairs",
                paragraphs = {
                    "The Tidebound Grotto will be available on World difficulty.",
                },
                changes = {
                    { text = "Rewards are Season 2 Veteran gear." },
                    { text = "Gear is bind-on-pickup, like raid gear." },
                    { text = "Lairs use a weekly lockout." },
                    { text = "Once Voidcores become available, only one can be used on a Lair each week." },
                },
            },
            {
                heading = "Prey",
                paragraphs = {
                    "Hard Mode Prey will be available during pre-season and awards Season 2 Veteran gear.",
                },
            },
        },
        footer = "Source: Blizzard Entertainment — Official World of Warcraft News",
    },
    {
        id = "curse-of-ulatek-housing-updates-2026-08-10",
        internalTab = "news",
        category = "HOUSING UPDATE",
        menuTitle = "Curse of Ula’tek Housing Updates",
        title = "New Housing Blueprints, Pets, and More",
        publicationDate = "August 10, 2026",
        publicationSort = 20260810,
        sourceLabel = "Blizzard Entertainment — Official World of Warcraft News",
        articleType = "article",
        sections = {
            {
                paragraphs = {
                    "The Curse of Ula’tek update adds new ways to save, share, and customize your home.",
                },
            },
            {
                heading = "Housing Blueprints",
                paragraphs = {
                    "Blueprints allow you to save and restore:",
                },
                changes = {
                    { text = "A single room" },
                    { text = "Your complete interior" },
                    { text = "Your exterior" },
                    { text = "Your entire home" },
                },
            },
            {
                paragraphs = {
                    "Blueprint codes can be shared through chat or copied to your clipboard. Shared designs can also be imported across regions outside China.",
                    "Before importing, you can review:",
                },
                changes = {
                    { text = "Required rooms and decor" },
                    { text = "Housing budget requirements" },
                    { text = "Items you already own" },
                    { text = "Missing items" },
                    { text = "Other layout details" },
                },
            },
            {
                paragraphs = {
                    "Blueprints can still be imported when some items are missing.",
                    "You can save up to 50 Blueprints, with 10 additional auto-save slots. An auto-save is created whenever you import a Blueprint.",
                    "Blueprint exporting is set to No One by default. This permission controls who can import your layout into their own Blueprint collection.",
                },
            },
            {
                heading = "Resetting Your Home",
                paragraphs = {
                    "A new Reset option returns placed items to storage, allowing you to reset:",
                },
                changes = {
                    { text = "Your entire house" },
                    { text = "The interior" },
                    { text = "The exterior" },
                },
            },
            {
                heading = "Companion Pets at Home",
                paragraphs = {
                    "Pet Beds allow noncombat companion pets to appear inside your house or in its outdoor area.",
                    "Pet Beds are sold for 50 gold each by:",
                },
                changes = {
                    { text = "Perry Winkles in Founder’s Point" },
                    { text = "Agratha in Razorwind Shores" },
                },
            },
            {
                paragraphs = {
                    "You can place:",
                },
                changes = {
                    { text = "Up to 100 Pet Beds indoors" },
                    { text = "Up to 25 Pet Beds outdoors" },
                },
                afterParagraphs = {
                    "Indoor pets can be set to Stationary or Roaming. Outdoor pets are currently stationary. Some companion pets cannot be placed.",
                },
            },
            {
                heading = "Additional House Levels and Rooms",
                paragraphs = {
                    "Houses can now reach Level 12, unlocking increased limits and larger exteriors.",
                    "New Artisanal Room plans are available for:",
                },
                changes = {
                    { text = "Blood elf" },
                    { text = "Human" },
                    { text = "Night elf" },
                    { text = "Orc" },
                },
                afterParagraphs = {
                    "Cross-faction room styles can be purchased from neighborhood smugglers.",
                    "Room plans generally cost 50 Community Coupons, while Westfall Barn plans cost 75 and Barn Facade plans cost 200.",
                    "Purchased room-plan items must be used before the rooms become available in the House Editor.",
                },
            },
            {
                heading = "Dye Updates",
                paragraphs = {
                    "Housing dye crafting has been simplified:",
                },
                changes = {
                    { text = "Old dye pigments and housing dye items in your inventory or bank will be converted through in-game mail." },
                    { text = "Dyeable decor will display all available colors without requiring separate items for every shade." },
                    { text = "Previously available darker colors will return." },
                    { text = "Housing dye pigments are being retired." },
                    { text = "Alchemists and scribes can use herbs directly at the dye station to create dyes through simplified dye categories." },
                },
            },
            {
                heading = "More Decorating Options",
                changes = {
                    { text = "New decor categories have been added for Pet Beds, Vines, and Hanging Plants." },
                    { text = "Blueprint imports will prioritize appropriate dyed items without replacing decor you have already dyed." },
                    { text = "The entry room can now be moved anywhere inside the house, including to another floor." },
                },
            },
        },
        footer = "Source: Blizzard Entertainment — Official World of Warcraft News",
    },
    {
        id = "four-new-neighborhood-endeavors-2026-08-10",
        internalTab = "news",
        category = "HOUSING EVENT",
        menuTitle = "Four New Neighborhood Endeavors",
        title = "Four New Neighborhood Endeavors",
        publicationDate = "August 10, 2026",
        publicationSort = 20260810,
        sourceLabel = "Blizzard Entertainment — Official World of Warcraft News",
        articleType = "article",
        sections = {
            {
                paragraphs = {
                    "Four new Endeavors are coming to player neighborhoods with new activities, vendors, milestone rewards, and Housing decor.",
                    "The Knock-off Amani Endeavor becomes available with the launch of Curse of Ula’tek. The remaining Endeavors will appear as new visitors arrive in your neighborhood.",
                },
            },
            {
                heading = "Knock-off Amani",
                changes = {
                    { text = "Visitors: Amani troll traders" },
                    { text = "Vendor: Griftah" },
                    { text = "Special Access: Portal to the Coiled Isle" },
                    { text = "New Currency: Griftah’s Token of Appreciation" },
                },
                afterParagraphs = {
                    "Tokens can be earned from certain Endeavor tasks and exchanged with Griftah.",
                    "Housing rewards include Amani fences, rugs, crates, anvils, wells, decorative plinths, and shrines dedicated to the Amani loa. Additional items unlock as the neighborhood reaches Endeavor milestones.",
                },
            },
            {
                heading = "Every Bakar Has Its Day",
                changes = {
                    { text = "Visitors: Ohn’ahran centaurs" },
                    { text = "Vendor: Roshai Lightstep" },
                },
                afterParagraphs = {
                    "Rewards include Maruukai furniture, rugs, storage baskets, barricades, cooking decor, pet dishes, and items for bakar.",
                    "Additional rewards unlock across four Endeavor milestones.",
                },
            },
            {
                heading = "Candle Culture",
                changes = {
                    { text = "Visitors: Kobolds from the Ringing Deeps" },
                    { text = "Vendor: Timicky" },
                    { text = "Special Access: Portal to the Ringing Deeps" },
                },
                afterParagraphs = {
                    "Rewards include Kobold furniture, crates, candles, hanging ropes, treasure, lighting, and a Warrens Candlecooker.",
                    "Additional rewards unlock across four Endeavor milestones, with a final item available after proving neighborhood candle mastery.",
                },
            },
            {
                heading = "Vacation Season",
                changes = {
                    { text = "Visitors: Tortollans" },
                    { text = "Vendor: Taifa" },
                },
                afterParagraphs = {
                    "Rewards include Tortollan travel supplies, tents, storage, display racks, cooking decor, lamps, and sea-themed decorations.",
                    "Additional rewards unlock across four Endeavor milestones.",
                },
            },
            {
                heading = "Neighborhood Changes",
                paragraphs = {
                    "Completing both new and previous Endeavors may add new features or decorations around your neighborhood.",
                    "Most vendor rewards are purchased with Community Coupons, with additional items becoming available as Endeavor milestones are completed.",
                },
            },
        },
        footer = "Source: Blizzard Entertainment — Official World of Warcraft News",
    },
    {
        id = "hotfixes-2026-08-19",
        internalTab = "updates",
        category = "HOTFIXES",
        menuTitle = "Hotfixes: August 19, 2026",
        title = "Hotfixes: August 19, 2026",
        publicationDate = "August 19, 2026",
        publicationSort = 20260819,
        sourceLabel = "Blizzard Entertainment — Official World of Warcraft Hotfixes",
        articleType = "hotfixes",
        introduction = "Here you'll find a list of hotfixes that address various issues related to World of Warcraft: Midnight, Mists of Pandaria Classic, Season of Discovery, Burning Crusade Classic, WoW Classic Era, and Hardcore. Some of the hotfixes below take effect the moment they were implemented, while others may require scheduled realm restarts to go into effect. Please keep in mind that some issues cannot be addressed without a client-side patch update. This list will be updated as additional hotfixes are applied.",
        hotfixDates = {
            {
                id = "2026-08-19",
                label = "August 19, 2026",
                publicationSort = 20260819,
                categories = {
                    {
                        id = "classes",
                        label = "Classes",
                        submenus = {
                            {
                                id = "death-knight",
                                label = "Death Knight",
                                sections = {
                                    {
                                        heading = "General",
                                        content = {
                                            { type = "change", text = "Resolved an issue causing Army of the Dead Epidemic Orders to cast from the Death Knight instead of the Lesser Ghoul." },
                                        },
                                    },
                                    {
                                        heading = "Unholy",
                                        content = {
                                            { type = "change", text = "Resolved an issue causing Forbidden Knowledge Rank 4 to not have a chance to activate when the Dread Plague target has a damage absorb effect." },
                                            { type = "change", text = "Resolved an issue causing Transfusion to not empower already summoned Lesser Ghouls." },
                                            { type = "change", text = "Resolved an issue causing Lord of the Dead to occasionally have a delay in between casts." },
                                            { type = "change", text = "Dark Simulacrum can now be tracked through the Cooldown Manager." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "druid",
                                label = "Druid",
                                sections = {
                                    {
                                        heading = "Restoration",
                                        content = {
                                            { type = "change", text = "Fixed an issue where Rejuvenation could be removed early if the player gained or lost haste while it was active." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "hunter",
                                label = "Hunter",
                                sections = {
                                    {
                                        heading = "Marksmanship",
                                        content = {
                                            { type = "change", text = "Corrected an issue where Rapid Fire fired fewer shots than intended when hitting a second target with the Aspect of the Hydra talent." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "paladin",
                                label = "Paladin",
                                sections = {
                                    {
                                        heading = "Retribution",
                                        content = {
                                            { type = "change", text = "Fixed an issue where Paladins talented into Radiant Glory would not have Avenging Wrath be applied after casting Wake of Ashes while silenced." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "shaman",
                                label = "Shaman",
                                sections = {
                                    {
                                        heading = "Restoration",
                                        content = {
                                            { type = "change", text = "Totemic: Corrected an issue where the Whirling Water effect was not properly working." },
                                        },
                                    },
                                },
                            },
                        },
                    },
                    {
                        id = "delves",
                        label = "Delves",
                        content = {
                            { type = "change", text = "Fixed an issue where the “Seasonal Refresher: Midnight” quest could not be completed." },
                            { type = "change", text = "Fasten from Engorged Gnarlticks on Gnarldor Isle should now be removed properly when leaving a delve." },
                        },
                    },
                    {
                        id = "dungeons-and-raids",
                        label = "Dungeons and Raids",
                        submenus = {
                            {
                                id = "the-blinding-vale",
                                label = "The Blinding Vale",
                                sections = {
                                    {
                                        heading = "Ikuzz the Light Hunter",
                                        content = {
                                            { type = "change", text = "Resolved an issue preventing Death Knights from casting Consumption after the Death Knight has been picked up by Bloodthirsty Gaze." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "ruby-life-pools",
                                label = "Ruby Life Pools",
                                sections = {
                                    {
                                        heading = "Kyrakka and Erkhart Stormvein",
                                        content = {
                                            { type = "change", text = "Addressed an issue where Ekhart could target an unexpected player with Stormslam." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "temple-of-sethraliss",
                                label = "Temple of Sethraliss",
                                content = {
                                    { type = "change", text = "Fixed an issue where Spark Channeler could be turned unexpectedly." },
                                    { type = "change", text = "Fixed an issue where Static Anomaly creatures did not contribute properly to the enemy forces count." },
                                    { type = "change", text = "The enemy forces requirement has been adjusted to take this fix into account. This change does not affect routing." },
                                },
                            },
                            {
                                id = "the-venomous-abyss",
                                label = "The Venomous Abyss",
                                sections = {
                                    {
                                        heading = "General",
                                        content = {
                                            { type = "change", text = "Resolved an issue where the door to The Twin Fangs room would close upon engaging combat but would not reopen, preventing players from backtracking to the entrance of the raid." },
                                        },
                                    },
                                    {
                                        heading = "Nek’zali the Soulcaller",
                                        content = {
                                            { type = "change", text = "Addressed an issue preventing Nek'zali from leashing near the entrance of the play space." },
                                        },
                                    },
                                    {
                                        heading = "Vashnik, The Malignant",
                                        content = {
                                            { type = "change", text = "Fixed an issue causing Shrouded Venom to sometimes evade after spawning." },
                                        },
                                    },
                                    {
                                        heading = "The Lost Explorers",
                                        content = {
                                            { type = "change", text = "Resolved an issue where Trader Gebbo would sometimes not despawn." },
                                        },
                                    },
                                    {
                                        heading = "The Twin Fangs",
                                        content = {
                                            { type = "change", text = "Resolved an issue causing Coiling Ichor to impact game client performance." },
                                            { type = "change", text = "Resolved an issue where Zul'jarra and Orweyna could fail to path across the bridge after The Twin Fangs were defeated." },
                                        },
                                    },
                                    {
                                        heading = "The Coiled Altar",
                                        content = {
                                            { type = "change", text = "Fixed an issue where the encounter would end unexpectedly." },
                                            { type = "change", text = "Resolved an issue causing Hex Lord Malacrass and Zul'jan to regain too much health during their intermission." },
                                        },
                                    },
                                },
                            },
                        },
                    },
                    {
                        id = "items",
                        label = "Items",
                        content = {
                            { type = "change", text = "Aman'muso, Warlord's Vengeance is again restricted to the main-hand slot only." },
                            { type = "developer_note", text = "Developers’ notes: The recent change to this weapon was more disruptive than anticipated and resulted in adverse incentives for certain specializations. This does not impact Zatha'tek, Breath of Corruption." },
                        },
                    },
                    {
                        id = "player-versus-player",
                        label = "Player versus Player",
                        content = {
                            { type = "change", text = "Conqueror's Venomous Lacquer should now add PvP item level to tier shoulders when used." },
                        },
                    },
                    {
                        id = "quests",
                        label = "Quests",
                        content = {
                            { type = "change", text = "Players above level 80 can once again complete \"Step Into the Light\"." },
                            { type = "change", text = "The weekly quest \"Midnight: Vaults of Atal'Utek\" no longer incorrectly suggests that it rewards two Sparks of Tide. This was a UI typo only." },
                            { type = "change", text = "Fixed an issue that would prevent \"Purging the Vaults\" or \"Vaults of Atal'Utek: A Toxic Tour\" quests from being completed if you already had Trovehunter's Bounty in your inventory." },
                            { type = "change", text = "The required Quest Item for “Seeking Knowledge Week 5 of 5: Off-World Magic” can now drop from Elite Rares, Overseers, and Rivals on Val and Naigtal." },
                        },
                    },
                },
            },
            {
                id = "2026-08-18",
                label = "August 18, 2026",
                publicationSort = 20260818,
                categories = {
                    {
                        id = "classes",
                        label = "Classes",
                        submenus = {
                            {
                                id = "death-knight",
                                label = "Death Knight",
                                sections = {
                                    {
                                        heading = "Blood",
                                        content = {
                                            { type = "change", text = "Deathbringer: Resolved an issue causing Echoing Fury to grnt Exterminate stacks on Reaper’s Mark casts." },
                                            { type = "change", text = "San’layn: Visceral Strength now grants 6% strength (was 10%)." },
                                            { type = "change", text = "San’layn: Transfusion increases Dancing Rune Weapon damage by 5% (was 10%)." },
                                            { type = "developer_note", text = "Developers’ notes: The tooltip will be updated at a later date to reflect the new value." },
                                        },
                                    },
                                    {
                                        heading = "Frost",
                                        content = {
                                            { type = "change", text = "All ability and auto-attack damage increased by 9%." },
                                            { type = "change", text = "Venomous Abyss 2-piece set bonus updated – Now grants 1% attack speed per stack (was 2%), and now increases Icy Death Torrent damage by 2% per stack (was 4%)." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "demon-hunter",
                                label = "Demon Hunter",
                                sections = {
                                    {
                                        heading = "Devourer",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: Devourer’s 4-piece set bonus is performing significantly above expectations, so we’re reducing its power. To compensate for this set bonus reduction, we’re increasing all ability damage. Additionally, Devourer has been overperforming, mostly in single target, so we are reducing the damage of Reap/Cull/Eradicate while increasing the AoE damage portion of Eradicate to reduce the impact of the change in AoE combat." },
                                            { type = "change", text = "All ability damage increased by 14%. Does not affect PvP combat." },
                                            { type = "change", text = "Reap/Cull/Eradicate damage reduced by 12%." },
                                            { type = "change", text = "Eradicate’s area-of-effect damage increased to 90% of base damage (was 85%)." },
                                            { type = "change", text = "Venomous Abyss 4-piece set bonus updated – Now generates 2 soul fragments (was 8 soul fragments) and increases Reap damage by 10% (was 20%)." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "druid",
                                label = "Druid",
                                sections = {
                                    {
                                        heading = "Restoration",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: We’re increasing Restoration Druid’s healing and damage as both aspects are underperforming relative to other healers." },
                                            { type = "change", text = "All healing increased by 4%. Does not affect PvP combat." },
                                            { type = "change", text = "All damage increased by 20%. Does not affect PvP combat." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "hunter",
                                label = "Hunter",
                                sections = {
                                    {
                                        heading = "General",
                                        content = {
                                            { type = "change", text = "Reduced the size of several Hydra creatures after they have been tamed." },
                                        },
                                    },
                                    {
                                        heading = "Beast Mastery",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: The new Venomous Abyss tier set bonus isn’t quite as strong as we would like it to be, so we’re increasing the effects of the 4-piece set bonus." },
                                            { type = "change", text = "Venomous Abyss 4-piece set bonus updated – Now causes Cobra Shot to benefit from Beast Cleave at 30% effectiveness per stack (was 20%) or strike your target for an additional 20% damage per stack (was 15%)." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "mage",
                                label = "Mage",
                                sections = {
                                    {
                                        heading = "Arcane",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: The Venomous Abyss set bonus is overperforming our target tuning for set bonuses. However, the amount we need to reduce its value by would be a greater impact than intended to Arcane’s overall damage, so we are also making a small positive adjustment to Arcane’s baseline." },
                                            { type = "change", text = "All ability damage increased by 3%." },
                                            { type = "change", text = "Venomous Abyss 2-piece set bonus updated – Arcane Missiles damage bonus reduced to 5% (was 20%)." },
                                            { type = "change", text = "Venomous Abyss 4-piece set bonus updated – Cumulative Power damage bonus per stack reduced to 3% (was 5%)." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "monk",
                                label = "Monk",
                                sections = {
                                    {
                                        heading = "Mistweaver",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: Mistweaver has been underperforming so we are targeting increases to its casted healing and the Venomous Abyss 4-set bonus to improve its performance and maintain build diversity." },
                                            { type = "change", text = "All healing increased by 8%. Does not affect PvP combat." },
                                            { type = "change", text = "Venomous Abyss 4-piece set bonus updated – Activation rate increased by 33%." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "paladin",
                                label = "Paladin",
                                sections = {
                                    {
                                        heading = "Retribution",
                                        content = {
                                            { type = "change", text = "All ability damage increased by 6%. Does not affect PvP combat." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "priest",
                                label = "Priest",
                                sections = {
                                    {
                                        heading = "Discipline",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: We’re reducing Discipline’s damage done and offsetting this in Atonement to not affect their overall healing, as their damage has been overperforming compared to other healers. At the same time, we’re increasing the damage of Entropic Rift to minimize the impact this will have on Voidweaver’s dungeon viability and help maintain high damage as one of its strengths." },
                                            { type = "change", text = "All damage reduced by 30%. Does not affect PvP combat." },
                                            { type = "change", text = "Oracle: Entropic Rift damage increased by 20%." },
                                            { type = "change", text = "Oracle: Atonement now transfers 46% of damage into healing (was 32%). Does not affect PvP combat." },
                                            { type = "change", text = "Oracle: Void Shield reflects 10% of damage (was 15%)." },
                                        },
                                    },
                                    {
                                        heading = "Holy",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: We’re increasing the healing throughput of Oracle so that it can serve as a competitive option against Archon. Furthermore, we are increasing the mana regeneration of Enlightenment to further help Holy Priest’s mana economy." },
                                            { type = "change", text = "Enlightenment now regenerates mana 25% faster (was 10%)." },
                                            { type = "change", text = "Words of the Wise now increases the healing of Holy Word: Serenity and Holy Word: Sanctify by 40% (was 10%). Does not affect PvP combat." },
                                            { type = "change", text = "Prompt Prognosis healing increased by 55%. Does not affect PvP combat." },
                                            { type = "change", text = "Preventive Measures now increases Prayer of Mending healing by 40% (was 15%). Does not affect PvP combat." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "rogue",
                                label = "Rogue",
                                sections = {
                                    {
                                        heading = "Assassination",
                                        content = {
                                            { type = "change", text = "All damage increased by 4%." },
                                        },
                                    },
                                    {
                                        heading = "Subtlety",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: Subtlety’s 4-piece set bonus is overperforming expectations, so its effectiveness is being reduced. An overall buff to Subtlety’s damage is being applied to compensate." },
                                            { type = "change", text = "All damage increased by 6%." },
                                            { type = "change", text = "The Venomous Abyss 4-set bonus has been updated – Effectiveness reduced to 60% (was 100%)." },
                                            { type = "change", text = "Shadow Dance now cancels when swapping talents." },
                                            { type = "change", text = "Shadow Dance can no longer be cancelled manually." },
                                            { type = "change", text = "Deathstalker: Lingering Darkness now cancels when swapping talents." },
                                            { type = "change", text = "Deathstalker: Lingering Darkness now cancels when a raid encounter starts." },
                                            { type = "change", text = "Deathstalker: Lingering Darkness now cancels when an M+ dungeon starts." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "shaman",
                                label = "Shaman",
                                sections = {
                                    {
                                        heading = "Elemental",
                                        content = {
                                            { type = "change", text = "Corrected an issue where the Venomous Abyss 4-piece set bonus Overcharge! buff was sometimes not consumed when casting a Maelstrom spending ability." },
                                            { type = "change", text = "All damage dealt increased by 5%." },
                                            { type = "developer_note", text = "Developers' notes: We discovered and fixed a tricky bug that was active on the PTR, that was increasing the amount of free Maelstrom spending abilities Elemental Shaman could get from the Venomous Abyss 4-piece set bonus. This was inflating their damage dealt, so alongside the bug fix, we're increasing their damage to compensate." },
                                        },
                                    },
                                    {
                                        heading = "Enhancement",
                                        content = {
                                            { type = "change", text = "All damage increased by 5%." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "warlock",
                                label = "Warlock",
                                sections = {
                                    {
                                        heading = "General",
                                        content = {
                                            { type = "change", text = "Hellcaller: Fixed an issue where Blackened Soul would not function with mouse-over casting." },
                                        },
                                    },
                                    {
                                        heading = "Affliction",
                                        content = {
                                            { type = "change", text = "Fixed an issue where Withering Bolt would not account for Wither." },
                                        },
                                    },
                                    {
                                        heading = "Demonology",
                                        content = {
                                            { type = "change", text = "Burning Cleave (granted by Antoran Armaments) now strikes enemies in a circular area, rather than a cone. The tooltip for Burning Cleave will be updated in a future patch." },
                                            { type = "developer_note", text = "Developers’ notes: We are increasing the throughput of the Venomous Abyss 2-set bonus for Demonology so that its performance is closer to other specialization tier set bonuses." },
                                            { type = "change", text = "Venomous Abyss 2-piece set bonus updated – Wild Imps now Implode at 350% effectiveness to their main target (was 250%) and 315% effectiveness to other targets (was 225%)." },
                                        },
                                    },
                                    {
                                        heading = "Destruction",
                                        content = {
                                            { type = "change", text = "Fixed an issue where Conflagration of Chaos would not guarantee a Conflagrate or Shadowburn to critically strike." },
                                            { type = "change", text = "Fixed an issue where Shadowburn would not apply its debuff after dealing damage to a Havoc target." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "warrior",
                                label = "Warrior",
                                sections = {
                                    {
                                        heading = "General",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: Fury’s 4-piece set bonus is currently overperforming, but Fury is in a good place overall and we don’t want to disrupt that, so we’re moving some of the value out of the 4-piece bonus and into Fury’s baseline. Additionally, Slayer has been overperforming for both specs due to a bug causing Executioner to provide double value which was recently hotfixed. This fix has brought overall Arms performance down into our intended range, but we’re happy with where Fury has been, so their baseline damage has been increased below to compensate for this fix as well as the set bonus change." },
                                        },
                                    },
                                    {
                                        heading = "Fury",
                                        content = {
                                            { type = "change", text = "All damage increased by 6%." },
                                            { type = "change", text = "Venomous Abyss 4-piece set bonus updated – Bloodthirst damage increased by 10%, and during Recklessness, Bloodthirst increases the critical strike bonus of Recklessness by 3%, up to 6% (was 5%, up to 10%)." },
                                        },
                                    },
                                    {
                                        heading = "Protection",
                                        content = {
                                            { type = "change", text = "Mountain Thane: Fixed an issue that would sometimes disable the bonus Thunder Clap damage from Crashing Thunder." },
                                        },
                                    },
                                },
                            },
                        },
                    },
                    {
                        id = "delves",
                        label = "Delves",
                        content = {
                            { type = "change", text = "The initial Ancient Golem in the Game Night variant of the Ring of Glory delve no longer attacks before being activated." },
                            { type = "change", text = "“Delve into the Earth” should no longer be blocked if selecting a combat roll for Brann failed to advance the quest while outside a delve." },
                            { type = "change", text = "Fixed an issue where Dundun's Favor would prevent Mislaid Curiosities from being looted by more than one party member." },
                        },
                    },
                    {
                        id = "dungeons",
                        label = "Dungeons",
                        submenus = {
                            {
                                id = "general",
                                label = "General",
                                content = {
                                    { type = "change", text = "The lockout for Mythic difficulty for Season 2 dungeons now resets daily." },
                                },
                            },
                            {
                                id = "the-blinding-vale",
                                label = "The Blinding Vale",
                                sections = {
                                    {
                                        heading = "Thorny Saptor",
                                        content = {
                                            { type = "change", text = "Hunting Leap visibility of ground visual improved." },
                                        },
                                    },
                                    {
                                        heading = "Ziekket",
                                        content = {
                                            { type = "change", text = "Lightbloom’s Essence periodic damage reduced by 25%." },
                                        },
                                    },
                                    {
                                        heading = "Altar of Fangs",
                                        content = {
                                            { type = "change", text = "Added a way for players to return to the entrance from the chamber of Rav’i." },
                                            { type = "change", text = "Hunting Leap visibility of ground visual improved." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "den-of-nalorakk",
                                label = "Den of Nalorakk",
                                sections = {
                                    {
                                        heading = "General",
                                        content = {
                                            { type = "change", text = "Barrel of Apples are now interactable without requiring opposable thumbs. Nature finds a way." },
                                        },
                                    },
                                    {
                                        heading = "Warding Incense",
                                        content = {
                                            { type = "change", text = "Increased Versatility buff to 5% (was 3%)." },
                                            { type = "change", text = "Now benefits all allies in the instance." },
                                            { type = "change", text = "Now persists through death." },
                                        },
                                    },
                                    {
                                        heading = "Sentinel of Winter",
                                        content = {
                                            { type = "change", text = "Rimeshatter soak area visual updated." },
                                        },
                                    },
                                    {
                                        heading = "Spirit of Hunger",
                                        content = {
                                            { type = "change", text = "Insatiable Hunger debuff now limited to 5 stacks." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "kings-rest",
                                label = "Kings’ Rest",
                                sections = {
                                    {
                                        heading = "General",
                                        content = {
                                            { type = "change", text = "The Council of Tribes" },
                                            { type = "change", text = "Encounter now ends immediately after defeating Zanazal the Wise." },
                                        },
                                    },
                                    {
                                        heading = "Dazar, The First King",
                                        content = {
                                            { type = "change", text = "Impaling Spear ground visual updated to improve visibility." },
                                        },
                                    },
                                    {
                                        heading = "Shadow of Zul",
                                        content = {
                                            { type = "change", text = "Dark Revelation now prefers non-tank players." },
                                        },
                                    },
                                    {
                                        heading = "Ghostly Brute",
                                        content = {
                                            { type = "change", text = "Seismic Upheaval visual updated to improve visual clarity." },
                                        },
                                    },
                                    {
                                        heading = "Honored Raptor",
                                        content = {
                                            { type = "change", text = "Hunting Leap visibility of ground visual improved." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "murder-row",
                                label = "Murder Row",
                                sections = {
                                    {
                                        heading = "General",
                                        content = {
                                            { type = "change", text = "Reduced required enemy forces to 655 (was 690)." },
                                            { type = "change", text = "Removed the creature pack of a Corrupted Warlock and two Wrathguard Flayers before Xathuux the Annihilator." },
                                        },
                                    },
                                    {
                                        heading = "Cantina event",
                                        content = {
                                            { type = "change", text = "Five Star Review duration increased to 5 minutes (was 4 minutes)." },
                                            { type = "change", text = "Food Missiles now targets specific locations around the room." },
                                        },
                                    },
                                    {
                                        heading = "Felmaster Lucsei",
                                        content = {
                                            { type = "change", text = "Blade Dance now has a 2-second cast time, and impact damage reduced by 10%." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "ruby-life-pools",
                                label = "Ruby Life Pools",
                                sections = {
                                    {
                                        heading = "Melidrussa Chillworn",
                                        content = {
                                            { type = "change", text = "Hailburst cast time increased to 3 seconds (was 2 seconds)." },
                                        },
                                    },
                                    {
                                        heading = "Kyrakka and Erkhart Stormvein",
                                        content = {
                                            { type = "heading", text = "Flaming Embers" },
                                            { type = "change", text = "Reduced radius of each ember to 5 yards (was 7 yards)." },
                                            { type = "change", text = "Reduced amount of randomness in the spawn pattern." },
                                            { type = "change", text = "Kyrakka no longer immediately begins casting after she lands for the final phase of the encounter, allowing for her to be repositioned" },
                                            { type = "change", text = "Increased the movement speed of Kyrakka after she lands for the final phase of the encounter" },
                                            { type = "change", text = "Addressed an issue where Kyrakka could melee attack unexpected targets after landing for the final phase" },
                                        },
                                    },
                                    {
                                        heading = "Flashfrost Chillweaver",
                                        content = {
                                            { type = "change", text = "Ice Shield precast visual visibility improved." },
                                        },
                                    },
                                    {
                                        heading = "Earthbound Guardian",
                                        content = {
                                            { type = "change", text = "Multiple applications of the Earthbound’s Imprint debuff can no longer overlap." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "temple-of-sethraliss",
                                label = "Temple of Sethraliss",
                                sections = {
                                    {
                                        heading = "Avatar of Sethraliss",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: With the changes below, we’re reducing the amount of passive healing done to the boss via Cleansed Lifeforce to make player healing more impactful. Additionally, we are adjusting some mechanical tuning surrounding Corrupted Lifeforce to encourage more group participation in this mechanic. To counterbalance this adjustment, we’re providing more time for the group to handle this mechanic and also increasing its visibility within the Avatar’s chamber." },
                                            { type = "heading", text = "Corrupted Guardian" },
                                            { type = "change", text = "Corrupted Lifeforce time to soak increased to 6 seconds (was 4.5 seconds) and visibility improved." },
                                            { type = "heading", text = "Corruption" },
                                            { type = "change", text = "Reduced physical vulnerability to 250% (was 300%)." },
                                            { type = "change", text = "Increased periodic damage by 33%." },
                                            { type = "heading", text = "Tainted Strike" },
                                            { type = "change", text = "Reduced periodic damage by 50%." },
                                            { type = "change", text = "Capped applications at 2." },
                                            { type = "change", text = "Increased duration to 25 seconds." },
                                            { type = "heading", text = "Cleansed Lifeforce" },
                                            { type = "change", text = "The passive healing aura can no longer grow beyond 3 applications." },
                                            { type = "change", text = "Slowed the tick rate of the passive healing to every 3 seconds (was every 2 seconds)." },
                                            { type = "heading", text = "Faithless Tormentor" },
                                            { type = "change", text = "Reduced the size of the fixate visual over the head of the healer." },
                                            { type = "change", text = "Fixed an issue where Faithless Tormentors could melee their fixate target from further than intended." },
                                            { type = "heading", text = "Essence Defiler" },
                                            { type = "change", text = "Defiling Taint is now displayed as a debuff on the Avatar’s unit frame." },
                                            { type = "heading", text = "Lightning Serpent" },
                                            { type = "change", text = "Multiple applications of the Lingering Storm debuff can no longer overlap." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "voidscar-arena",
                                label = "Voidscar Arena",
                                sections = {
                                    {
                                        heading = "General",
                                        content = {
                                            { type = "change", text = "Proof of Mastery and Proof of Endurance are now buffs." },
                                        },
                                    },
                                    {
                                        heading = "Aegyra the Unyielding",
                                        content = {
                                            { type = "change", text = "Champion’s Spear health reduced by 15%." },
                                        },
                                    },
                                    {
                                        heading = "Raj’kess the Spellstorm",
                                        content = {
                                            { type = "change", text = "Disruption Orb disruption cast time reduced to 13 seconds (was 15 seconds)." },
                                        },
                                    },
                                },
                            },
                        },
                    },
                    {
                        id = "items",
                        label = "Items",
                        content = {
                            { type = "change", text = "Fixed an issue with Hunter's Ritual Stone providing more stats than intended." },
                            { type = "change", text = "Shirts collected from Free T-Shirt Day can now be sold to vendors." },
                            { type = "change", text = "Zatha'tek, Breath of Corruption may now be equipped in either weapon slot." },
                            { type = "change", text = "Aman'muso, Warlord's Vengeance may now be equipped in either weapon slot." },
                            { type = "change", text = "Preternatural Antivenom - fixed an issue preventing the healing effect from consistently triggering after the aura has been applied to an ally depending on the source of incoming damage." },
                            { type = "change", text = "Preyhunter's Trophy Stand cannot be used in areas where toys are restricted" },
                        },
                    },
                    {
                        id = "player-versus-player",
                        label = "Player versus Player",
                        submenus = {
                            {
                                id = "training-grounds-arenas",
                                label = "Training Grounds: Arenas",
                                content = {
                                    { type = "change", text = "The damage of enemy game-controlled opponents has been reduced in Training Grounds: Arena." },
                                    { type = "change", text = "Resolved an issue that prevented “Week 1 of 3: Gladiator's Distinction” quest credit from being earned in Training Grounds: Arenas." },
                                },
                            },
                            {
                                id = "general",
                                label = "General",
                                content = {
                                    { type = "change", text = "Resolved an issue that could prevent quest credit for “Sparks of War: The Coiled Isle”." },
                                    { type = "change", text = "The PvP trinket set bonus now increases primary stat by 20% for damage dealers and tanks (was 15%)." },
                                    { type = "developer_note", text = "Developers’ notes: We’ve felt the pace of PvP combat has been slower than intended, so we’re increasing the primary stat of non-healer specializations to increase overall outgoing damage." },
                                },
                            },
                            {
                                id = "demon-hunter",
                                label = "Demon Hunter",
                                sections = {
                                    {
                                        heading = "Devourer",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: Devourer Demon Hunters are both very threatening and very defensible during Void Metamorphosis and Surrender to the Void has provided the opportunity to increase the duration of those windows too significantly, so its Fury generation effect is being reduced." },
                                            { type = "change", text = "Surrender to the Void now increases Fury generated by 60% (was 100%)." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "druid",
                                label = "Druid",
                                sections = {
                                    {
                                        heading = "Restoration",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: Restoration Druid received several changes in Curse of Ula’tek that improved its throughput beyond what we would like in PvP." },
                                            { type = "change", text = "All healing reduced by 5% in PvP combat." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "mage",
                                label = "Mage",
                                sections = {
                                    {
                                        heading = "Fire",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: Fire Mage’s Venomous Abyss tier set bonus is particularly difficult to take advantage of in PvP combat, so we’re making a few tweaks with the objective of increasing its usability. We’re also decreasing Meteor’s damage to reduce Fire Mage’s burst capabilities." },
                                            { type = "change", text = "Pyroblast damage increased by 10% in PvP combat." },
                                            { type = "change", text = "Meteor damage decreased by 20% in PvP combat." },
                                            { type = "change", text = "Comet Storm damage decreased by 20% in PvP combat." },
                                            { type = "change", text = "Venomous Abyss 4-piece set bonus updated – Now decreases the cast time of Pyroblast and Flamestrike by 30% (was 10%) and increases Pyroclasm’s damage bonus by 5% (was 10%) in PvP combat." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "paladin",
                                label = "Paladin",
                                sections = {
                                    {
                                        heading = "Holy",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: Holy Paladin’s throughput has been higher than we would like, and Judgment has been too effective as an offensive tool. Avenging Crusader’s effectiveness is being increased to offset the decrease to Judgment’s damage." },
                                            { type = "change", text = "All healing decreased by 5% in PvP combat." },
                                            { type = "change", text = "Judgment damage decreased by 30% in PvP combat." },
                                            { type = "change", text = "Avenging Crusader now transfers 80% of damage done into healing in PvP combat (was 55%)." },
                                        },
                                    },
                                    {
                                        heading = "Retribution",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: Retribution had been contributing to longer PvP matches during Season 1 due to their frequent access to team utility. We’re shifting some of that effectiveness into more consistent offensive power, and additionally giving Templar an increase to Hammer of Light damage so they are a solid offensive alternative to Herald of the Sun." },
                                            { type = "change", text = "All damage increased by 8% in PvP combat." },
                                            { type = "change", text = "Final Verdict damage increased by 15% in PvP combat." },
                                            { type = "change", text = "Hammer of Light damage increased by 25% in PvP combat." },
                                            { type = "change", text = "Sacrifice of the Just now reduces Blessing of Sacrifice’s cooldown by 30 seconds in PvP combat (was 60 seconds)." },
                                            { type = "change", text = "Unbreakable Spirit reduces the cooldown of affected spells by 20% in PvP combat (was 30%)." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "shaman",
                                label = "Shaman",
                                sections = {
                                    {
                                        heading = "Restoration",
                                        content = {
                                            { type = "developer_note", text = "Developers’ notes: We’re making some targeted adjustments to primarily improve Farseer’s viability as we begin season 2. We’re also reducing the effectiveness of Storm Conduit which we feel has been too powerful under the right circumstances." },
                                            { type = "change", text = "All healing increased by 4% in PvP combat." },
                                            { type = "change", text = "Storm Conduit now reduces the cooldown of affected spells by 2 seconds (was 4 seconds)." },
                                            { type = "change", text = "Storm Conduit now reduces the duration of interrupts on Lightning Bolt and Chain Lightning by 40% (was 65%)." },
                                            { type = "change", text = "Farseer: Healing Wave, Healing Surge, and Chain Heal healing from Ancestors increased by 35% in PvP combat." },
                                            { type = "change", text = "Farseer: Hydrobubble absorption increased by 35% in PvP combat." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "warlock",
                                label = "Warlock",
                                sections = {
                                    {
                                        heading = "Destruction",
                                        content = {
                                            { type = "change", text = "Soul Fire damage reduced by 30% in PvP combat." },
                                        },
                                    },
                                },
                            },
                        },
                    },
                    {
                        id = "professions",
                        label = "Professions",
                        submenus = {
                            {
                                id = "general",
                                label = "General",
                                content = {
                                    { type = "change", text = "Fixed an issue where players were not receiving Tidal Spark Dust from quests such as “Trailing Xal'atath” and “Midnight: World Tour”." },
                                    { type = "change", text = "Raised the base cap of Tidal Spark Dust to 3 (was 1)." },
                                },
                            },
                            {
                                id = "cooking",
                                label = "Cooking",
                                content = {
                                    { type = "change", text = "Fixed a bug where the tooltips for Hearty Loa's Gathering, Hearty Amani Cornucopia, and Hearty Feast of Knowledge listed incorrect stat values." },
                                },
                            },
                        },
                    },
                    {
                        id = "quests",
                        label = "Quests",
                        content = {
                            { type = "change", text = "“Trailing Xal'atath” and “Midnight: World Tour” should now correctly award Tidal Spark Dust." },
                            { type = "change", text = "Fixed bug preventing the “Sparks of War” related quests from displaying Spark of Tides as a potential quest reward." },
                            { type = "change", text = "Fixed an issue that would prevent \"Purging the Vaults\" or \"Vaults of Atal'Utek: A Toxic Tour\" quests from being completed if you already had Codex of the Soulcoilers in your inventory." },
                            { type = "change", text = "For “A Grave Concern”, the Budget Friendly gravestone in the Silvermoon Delve hub is now available for anyone to use." },
                        },
                    },
                },
            },
        },
        footer = "Source: Blizzard Entertainment — Official World of Warcraft Hotfixes",
    },
    {
        id = "class-tuning-2026-08-18",
        internalTab = "updates",
        category = "CLASS TUNING",
        menuTitle = "Class Tuning Incoming - August 18",
        title = "Class Tuning Incoming - August 18",
        publicationDate = "August 14, 2026",
        publicationSort = 20260814,
        effectiveDate = "Effective August 18, 2026",
        author = "Linxy - Community Manager",
        sourceLabel = "Official World of Warcraft Forums",
        articleType = "class_tuning",
        introduction = "With the first week of the Curse of Ula’tek content update, we’re making some adjustments to low and high performers to start Season 2 next week. We’ve identified several tier sets that would greatly overperform our expected targets if we didn’t make targeted adjustments to bring their throughput to more expected power levels. At the same time, we’re increasing affected specs baseline abilities to limit the impact of the changes to their tier set bonuses.",
        modes = {
            {
                id = "class",
                label = "CLASS CHANGES",
                classes = {
                    {
                        id = "death-knight",
                        name = "Death Knight",
                        specializations = {
                            {
                                id = "blood",
                                name = "Blood",
                                content = {
                                    { type = "heading", text = "San’layn" },
                                    { type = "change", text = "Visceral Strength now grants 6% strength (was 10%)." },
                                    { type = "change", text = "Transfusion increases Dancing Rune Weapon damage by 5% (was 10%)." },
                                    { type = "developer_note", text = "The tooltip will be updated at a later date to reflect the new value." },
                                },
                            },
                            {
                                id = "frost",
                                name = "Frost",
                                content = {
                                    { type = "change", text = "All ability damage increased by 9%." },
                                    { type = "change", text = "The Venomous Abyss 2-set bonus has been updated - Now grants 1% attack speed per stack (was 2%). Now increases Icy Death Torrent damage by 2% per stack (was 4%)." },
                                },
                            },
                        },
                    },
                    {
                        id = "demon-hunter",
                        name = "Demon Hunter",
                        specializations = {
                            {
                                id = "devourer",
                                name = "Devourer",
                                content = {
                                    { type = "developer_note", text = "Devourer’s 4-piece set bonus is performing significantly above expectations, so we are reducing its power. To compensate for this set bonus reduction, we are increasing all ability damage. Additionally, Devourer has been overperforming, mostly in single target, so we are reducing the damage of Reap/Cull/Eradicate while increasing the AoE damage portion of Eradicate to reduce the impact of the change in AoE combat." },
                                    { type = "change", text = "All ability damage increased by 14%. Does not affect PvP combat." },
                                    { type = "change", text = "Reap/Cull/Eradicate damage reduced by 12%." },
                                    { type = "change", text = "Eradicate’s area-of-effect damage increased to 90% of base damage (was 85%)." },
                                    { type = "change", text = "The Venomous Abyss 4-set bonus has been updated - Now generates 2 soul fragments (was 8 soul fragments) and increases Reap damage by 10% (was 20%)." },
                                },
                            },
                        },
                    },
                    {
                        id = "druid",
                        name = "Druid",
                        specializations = {
                            {
                                id = "restoration",
                                name = "Restoration",
                                content = {
                                    { type = "developer_note", text = "We’re increasing Restoration Druid’s healing and damage as both aspects are underperforming relative to other healers." },
                                    { type = "change", text = "All healing increased by 4%. Does not affect PvP combat." },
                                    { type = "change", text = "All damage increased by 20%. Does not affect PvP combat." },
                                },
                            },
                        },
                    },
                    {
                        id = "hunter",
                        name = "Hunter",
                        specializations = {
                            {
                                id = "beast-mastery",
                                name = "Beast Mastery",
                                content = {
                                    { type = "developer_note", text = "The new Venomous Abyss tier set bonus isn’t quite as strong as we would like it to be, so we are increasing the effects of the 4-set bonus." },
                                    { type = "change", text = "The Venomous Abyss 4-set bonus has been updated - Now causes Cobra Shot to benefit from Beast Cleave at 30% effectiveness per stack (was 20%), or strike your target for an additional 20% damage per stack (was 15%)." },
                                },
                            },
                        },
                    },
                    {
                        id = "mage",
                        name = "Mage",
                        specializations = {
                            {
                                id = "arcane",
                                name = "Arcane",
                                content = {
                                    { type = "developer_note", text = "The Venomous Abyss set bonus is overperforming our target tuning for set bonuses. However, the amount we need to reduce its value by would be a greater impact than intended to Arcane’s overall damage, so we are also making a small positive adjustment to Arcane’s baseline." },
                                    { type = "change", text = "All ability damage increased by 3%." },
                                    { type = "change", text = "Venomous Abyss 2-set bonus has been updated - Arcane Missiles damage bonus reduced to 5% (was 20%)." },
                                    { type = "change", text = "Venomous Abyss 4-set bonus has been updated - Cumulative Power damage bonus per stack reduced to 3% (was 5%)." },
                                },
                            },
                        },
                    },
                    {
                        id = "monk",
                        name = "Monk",
                        specializations = {
                            {
                                id = "mistweaver",
                                name = "Mistweaver",
                                content = {
                                    { type = "developer_note", text = "Mistweaver has been underperforming so we are targeting increases to its casted healing and the Venomous Abyss 4-set bonus to improve its performance and maintain build diversity." },
                                    { type = "change", text = "All healing increased by 8%. Does not affect PvP combat." },
                                    { type = "change", text = "Venomous Abyss 4-set bonus has been updated - Activation rate increased by 33%." },
                                },
                            },
                        },
                    },
                    {
                        id = "priest",
                        name = "Priest",
                        specializations = {
                            {
                                id = "discipline",
                                name = "Discipline",
                                content = {
                                    { type = "developer_note", text = "We are reducing Discipline Priest’s damage done and offsetting this in Atonement to not affect their overall healing as their damage has been overperforming compared to other healers. At the same time, we are increasing the damage of Entropic Rift to minimize the impact this will have on Voidweaver’s dungeon viability and help maintain high damage as one of its strengths." },
                                    { type = "change", text = "All damage reduced by 30%. Does not affect PvP combat." },
                                    { type = "change", text = "Entropic Rift damage increased by 20%." },
                                    { type = "change", text = "Atonement now transfers 46% of damage into healing (was 32%). Does not affect PvP combat." },
                                },
                            },
                            {
                                id = "holy",
                                name = "Holy",
                                content = {
                                    { type = "developer_note", text = "We are increasing the healing throughput of Oracle so that it can serve as a competitive option against Archon. Furthermore, we are increasing the mana regeneration of Enlightenment to further help Holy Priest’s mana economy." },
                                    { type = "change", text = "Enlightenment now regenerates mana 25% faster (was 10%)." },
                                    { type = "heading", text = "Oracle" },
                                    { type = "change", text = "Words of the Wise now increases the healing of Holy Word: Serenity and Holy Word: Sanctify by 40% (was 10%). Does not affect PvP combat." },
                                    { type = "change", text = "Prompt Prognosis healing increased by 55%. Does not affect PvP combat." },
                                    { type = "change", text = "Preventive Measures now increases Prayer of Mending healing by 40% (was 15%). Does not affect PvP combat." },
                                },
                            },
                        },
                    },
                    {
                        id = "rogue",
                        name = "Rogue",
                        specializations = {
                            {
                                id = "assassination",
                                name = "Assassination",
                                content = {
                                    { type = "change", text = "All damage increased by 4%." },
                                },
                            },
                            {
                                id = "subtlety",
                                name = "Subtlety",
                                content = {
                                    { type = "developer_note", text = "Subtlety’s 4-piece set bonus is overperforming expectation, so its effectiveness is being reduced. An overall buff to Subtlety’s damage is being applied to compensate." },
                                    { type = "change", text = "All damage increased by 6%." },
                                    { type = "change", text = "The Venomous Abyss 4-set bonus has been updated - Effectiveness reduced to 60% (was 100%)." },
                                },
                            },
                        },
                    },
                    {
                        id = "shaman",
                        name = "Shaman",
                        specializations = {
                            {
                                id = "enhancement",
                                name = "Enhancement",
                                content = {
                                    { type = "change", text = "All damage increased by 5%." },
                                },
                            },
                        },
                    },
                    {
                        id = "warlock",
                        name = "Warlock",
                        specializations = {
                            {
                                id = "demonology",
                                name = "Demonology",
                                content = {
                                    { type = "developer_note", text = "We are increasing the throughput of the Venomous Abyss 2-set bonus for Demonology so that its performance is closer to other specialization tier set bonuses." },
                                    { type = "change", text = "The Venomous Abyss 2-set bonus has been updated - Wild Imps now Implode at 350% effectiveness to their main target (was 250%) and 315% effectiveness to other targets (was 225%)." },
                                },
                            },
                        },
                    },
                    {
                        id = "warrior",
                        name = "Warrior",
                        content = {
                            { type = "developer_note", text = "Fury’s 4pc set bonus is currently overperforming, but Fury is in a good place overall and we don’t want to disrupt that, so we’re moving some of the value out of the 4pc bonus and into Fury’s baseline. Additionally, Slayer has been overperforming for both specs due to a bug causing Executioner to provide double value which was recently hotfixed. This fix has brought overall Arms performance down into our intended range, but we’re happy with where Fury has been, so their baseline damage has been increased below to compensate for this fix as well as the set bonus change." },
                        },
                        specializations = {
                            {
                                id = "fury",
                                name = "Fury",
                                content = {
                                    { type = "change", text = "All damage increased by 6%." },
                                    { type = "change", text = "The Venomous Abyss 4-set bonus has been updated - Bloodthirst damage increased by 10%. During Recklessness Bloodthirst increases the critical strike bonus of Recklessness by 3%, up to 6%. (was 5%, up to 10%)." },
                                },
                            },
                        },
                    },
                },
            },
            {
                id = "pvp",
                label = "PLAYER VERSUS PLAYER",
                classes = {
                    {
                        id = "general",
                        name = "General",
                        content = {
                            { type = "change", text = "The PvP trinket set bonus now increases primary stat by 20% for damage dealers and tanks (was 15%)." },
                            { type = "developer_note", text = "We’ve felt the pace of PvP combat has been slower than intended, so we’re increasing the primary stat of non-healer specializations to increase overall outgoing damage." },
                        },
                        specializations = {},
                    },
                    {
                        id = "demon-hunter",
                        name = "Demon Hunter",
                        specializations = {
                            {
                                id = "devourer",
                                name = "Devourer",
                                content = {
                                    { type = "developer_note", text = "Devourer Demon Hunters are both very threatening and very defensible during Void Metamorphosis and Surrender to the Void has provided the opportunity to increase the duration of those windows too significantly, so its Fury generation effect is being reduced." },
                                    { type = "change", text = "Surrender to the Void now increases Fury generated by 60% (was 100%)." },
                                },
                            },
                        },
                    },
                    {
                        id = "druid",
                        name = "Druid",
                        specializations = {
                            {
                                id = "restoration",
                                name = "Restoration",
                                content = {
                                    { type = "developer_note", text = "Restoration Druid received several changes in Curse of Ula’tek that improved its throughput beyond what we would like in PvP." },
                                    { type = "change", text = "All healing reduced by 5% in PvP combat." },
                                },
                            },
                        },
                    },
                    {
                        id = "mage",
                        name = "Mage",
                        specializations = {
                            {
                                id = "fire",
                                name = "Fire",
                                content = {
                                    { type = "developer_note", text = "Fire Mage’s Venomous Abyss tier set bonus is particularly difficult to take advantage of in PvP combat, so we’re making a few tweaks with the objective of increasing its usability. We’re also decreasing Meteor’s damage to reduce Fire Mage’s burst capabilities." },
                                    { type = "change", text = "Pyroblast damage increased by 10% in PvP combat." },
                                    { type = "change", text = "Meteor damage decreased by 20% in PvP combat." },
                                    { type = "change", text = "Comet Storm damage decreased by 20% in PvP combat." },
                                    { type = "change", text = "The Venomous Abyss 4-set bonus has been updated - Now decreases the cast time of Pyroblast and Flamestrike by 30% (was 10%) and increases Pyroclasm’s damage bonus by 5% (was 10%) in PvP combat." },
                                },
                            },
                        },
                    },
                    {
                        id = "paladin",
                        name = "Paladin",
                        specializations = {
                            {
                                id = "holy",
                                name = "Holy",
                                content = {
                                    { type = "developer_note", text = "Holy Paladin’s throughput has been higher than we would like, and Judgment has been too effective as an offensive tool. Avenging Crusader’s effectiveness is being increased to offset the decrease to Judgment’s damage." },
                                    { type = "change", text = "All healing decreased by 5% in PvP combat." },
                                    { type = "change", text = "Judgment damage decreased by 30% in PvP combat." },
                                    { type = "change", text = "Avenging Crusader now transfers 80% of damage done into healing in PvP combat (was 55%)." },
                                },
                            },
                            {
                                id = "retribution",
                                name = "Retribution",
                                content = {
                                    { type = "developer_note", text = "Retribution had been contributing to longer PvP matches during Season 1 due to their frequent access to team utility. We’re shifting some of that effectiveness into more consistent offensive power, and additionally giving Templar an increase to Hammer of Light damage so they are a solid offensive alternative to Herald of the Sun." },
                                    { type = "change", text = "All damage increased by 8% in PvP combat." },
                                    { type = "change", text = "Final Verdict damage increased by 15% in PvP combat." },
                                    { type = "change", text = "Hammer of Light damage increased by 25% in PvP combat." },
                                    { type = "change", text = "Sacrifice of the Just now reduces Blessing of Sacrifice’s cooldown by 30 seconds in PvP combat (was 60 seconds)." },
                                    { type = "change", text = "Unbreakable Spirit reduces the cooldown of affected spells by 20% in PvP combat (was 30%)." },
                                },
                            },
                        },
                    },
                    {
                        id = "shaman",
                        name = "Shaman",
                        specializations = {
                            {
                                id = "restoration",
                                name = "Restoration",
                                content = {
                                    { type = "developer_note", text = "We’re making some targeted adjustments to primarily improve Farseer’s viability as we begin season 2. We’re also reducing the effectiveness of Storm Conduit which we feel has been too powerful under the right circumstances." },
                                    { type = "change", text = "All healing increased by 4% in PvP combat." },
                                    { type = "change", text = "Storm Conduit now reduces the cooldown of affected spells by 2 seconds (was 4 seconds)." },
                                    { type = "change", text = "Storm Conduit now reduces the duration of interrupts on Lightning Bolt and Chain Lightning by 40% (was 65%)." },
                                    { type = "heading", text = "Farseer" },
                                    { type = "change", text = "Healing Wave, Healing Surge, and Chain Heal healing from Ancestors increased by 35% in PvP combat." },
                                    { type = "change", text = "Hydrobubble absorption increased by 35% in PvP combat." },
                                },
                            },
                        },
                    },
                    {
                        id = "warlock",
                        name = "Warlock",
                        specializations = {
                            {
                                id = "destruction",
                                name = "Destruction",
                                content = {
                                    { type = "change", text = "Soul Fire damage reduced by 30% in PvP combat." },
                                },
                            },
                        },
                    },
                },
            },
        },
        footer = "Source: Official World of Warcraft Forums",
    },
    {
        id = "hotfixes-2026-08-14",
        internalTab = "updates",
        category = "HOTFIXES",
        menuTitle = "Hotfixes: August 14, 2026",
        title = "Hotfixes: August 14, 2026",
        publicationDate = "August 14, 2026",
        publicationSort = 20260814,
        sourceLabel = "Blizzard Entertainment — Official World of Warcraft Hotfixes",
        articleType = "hotfixes",
        introduction = "Here you'll find a list of hotfixes that address various issues related to World of Warcraft: Midnight, Mists of Pandaria Classic, Season of Discovery, Burning Crusade Classic, WoW Classic Era, and Hardcore. Some of the hotfixes below take effect the moment they were implemented, while others may require scheduled realm restarts to go into effect. Please keep in mind that some issues cannot be addressed without a client-side patch update. This list will be updated as additional hotfixes are applied.",
        hotfixDates = {
            {
                id = "2026-08-14",
                label = "August 14, 2026",
                publicationSort = 20260814,
                categories = {
                    {
                        id = "achievements",
                        label = "Achievements",
                        content = {
                            { type = "change", text = "Reaching Renown 20 with Zul'jaara's Forces now correctly grants Zul'jarra's Forces Champion." },
                            { type = "change", text = "Family Battler of Outland and all associated type- Battler of Outland achievements now require Bloodknight Antairi (was incorrectly Gorma Asaan)." },
                        },
                    },
                    {
                        id = "classes",
                        label = "Classes",
                        submenus = {
                            {
                                id = "evoker",
                                label = "Evoker",
                                sections = {
                                    {
                                        heading = "Devastation",
                                        content = {
                                            { type = "change", text = "Shattering Star now correctly benefits from Mastery: Giantkiller." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "warrior",
                                label = "Warrior",
                                sections = {
                                    {
                                        heading = "Arms, Fury",
                                        content = {
                                            { type = "change", text = "Slayer: Fixed a bug that was causing Executioner to have double the intended effect." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "warlock",
                                label = "Warlock",
                                sections = {
                                    {
                                        heading = "General",
                                        content = {
                                            { type = "change", text = "Fixed an issue where Warlock pets would continually learn Soul Leech." },
                                        },
                                    },
                                    {
                                        heading = "Demonology",
                                        content = {
                                            { type = "change", text = "Soul Harvester: fixed an issue where Shadow Bolt and Hand of Gul'dan would be disabled in the cooldown manager." },
                                        },
                                    },
                                },
                            },
                        },
                    },
                    {
                        id = "delves",
                        label = "Delves",
                        content = {
                            { type = "change", text = "Fixed an issue where Gorgoneion Gaze would not trigger." },
                            { type = "change", text = "Fixed an issue where Ula'tek's Gift would not deal damage." },
                            { type = "change", text = "Fixed an issue where Ula'tek's Gift would not apply more stacks while poisoned." },
                        },
                    },
                    {
                        id = "dungeons-and-raids",
                        label = "Dungeons and Raids",
                        submenus = {
                            {
                                id = "general",
                                label = "General",
                                content = {
                                    { type = "change", text = "Archmage Timear again permits players to queue for the Raid Finder wings of Tomb of Sargeras." },
                                },
                            },
                            {
                                id = "ruby-life-pools",
                                label = "Ruby Life Pools",
                                sections = {
                                    {
                                        heading = "Thunderhead",
                                        content = {
                                            { type = "change", text = "Fixed an issue where Electrical Discharge would sometimes fail to hit players." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "voidscar-arena",
                                label = "Voidscar Arena",
                                content = {
                                    { type = "change", text = "Addressed an issue where Brutok's Smashing Charge can charge through doors." },
                                },
                            },
                        },
                    },
                    {
                        id = "items",
                        label = "Items",
                        submenus = {
                            {
                                id = "general",
                                label = "General",
                                content = {
                                    { type = "change", text = "Void-Twisted Sporbits no longer grant Nebulous Voidcores. Nebulous Voidcores obtained in this way after the end of Season 1 have been removed for Season 2." },
                                    { type = "change", text = "Tanks may now roll Need on Zul'jin's Guillotine Technique." },
                                    { type = "change", text = "Survival Hunters may now roll Need on two-handed axes and swords with Agility." },
                                },
                            },
                            {
                                id = "trinkets",
                                label = "Trinkets",
                                content = {
                                    { type = "change", text = "Coiled Fangstone: damage increased by 15%." },
                                    { type = "change", text = "Crucible of Erratic Energies: critical strike reduced by 15%." },
                                    { type = "change", text = "Fang of Umbral Malignance: damage increased by 15%." },
                                    { type = "change", text = "First Mate's Shellward: damage increased by 25%." },
                                    { type = "change", text = "Font of Venomous Rage: damage increased by 20%." },
                                    { type = "change", text = "Gaze of the Alnseer: primary stat reduced by 20%." },
                                    { type = "change", text = "Gebbo's Bottomless Bag: secondary stat effects reduced by 29%." },
                                    { type = "change", text = "Hex Lord's Dooming Idol: intellect lost per stack reduced by 33% and intellect granted on use per stack increased by 15%." },
                                    { type = "change", text = "Idol of the Howling Nexus: agility and strength on proc increased by 5%." },
                                    { type = "change", text = "Knot of Writhing Serpents: damage increased by 15%." },
                                    { type = "change", text = "Knot of Writhing Serpents no longer drops for healing specializations." },
                                    { type = "change", text = "Kyrakka's Searing Embers: healing increased by 80% and damage increased by 50%." },
                                    { type = "change", text = "Mindpiercer's Sigil: damage increased by 15%." },
                                    { type = "change", text = "Mycolic Medicine: all healing increased by 30%." },
                                    { type = "change", text = "Preternatural Antivenom: healing increased by 30% and fixed an issue preventing the healing effect from consistently triggering after the aura has been applied to an ally depending on the source of incoming damage." },
                                    { type = "change", text = "Sapling of the Dawnroot: damage increased by 15%." },
                                    { type = "change", text = "Soulcoiler Ritual Vessel: absorb reduced by 15%." },
                                    { type = "change", text = "Sszorak's Ferocity: damage increased by 15%." },
                                    { type = "change", text = "Tiny Electromental in a Jar: damage increased by 15%." },
                                    { type = "change", text = "Tumor of the Swarm: damage increased by 15% and healing increased by 40%." },
                                    { type = "change", text = "Unstable Felheart Crystal: absorb increased by 30%." },
                                    { type = "change", text = "Vaelgor's Final Stare: mastery reduced by 10%." },
                                    { type = "change", text = "Vashnik's Sanguine Rancor: damage increased by 15%." },
                                    { type = "change", text = "Vexhul's Everflowing Gland: damage increased by 15%." },
                                },
                            },
                        },
                    },
                    {
                        id = "lairs",
                        label = "Lairs",
                        content = {
                            { type = "change", text = "Resolved an issue causing some Bubblefin Shorerunners to not despawn when reaching the Alluring Bubble." },
                        },
                    },
                    {
                        id = "player-versus-player",
                        label = "Player Versus Player",
                        content = {
                            { type = "change", text = "Fixed an issue where Ula'tek's Gift was dealing more damage to players than expected." },
                        },
                    },
                    {
                        id = "professions",
                        label = "Professions",
                        content = {
                            { type = "change", text = "Fixed an issue that prevented Flat Snakeskin Canopy from being crafted." },
                            { type = "change", text = "Fixed an issue that prevented Flat Snakeskin Canopy from being added to the decor collection when used." },
                        },
                    },
                    {
                        id = "quests",
                        label = "Quests",
                        content = {
                            { type = "change", text = "Fixed a bug causing Amani Endeavor daily quests to only be offered weekly." },
                            { type = "change", text = "Players on the quest “Void Walk With Me” are now correctly advanced in the “Traitor's Due” story when entering The Shadow Enclave." },
                            { type = "change", text = "“Story of a Memorable Victory” no longer drops outside of the Dragon Isles." },
                            { type = "change", text = "Fixed an issue preventing progress on the quest “Cut Her Strings” in Voidstorm." },
                            { type = "change", text = "“Awe of She” is no longer stalled by weather effects on the player." },
                            { type = "change", text = "Fixed a bug preventing players who are seated before entering the Worldsoul Terror as Nek'zali from properly interacting with Injured Hunters on “Fuel the Calling”." },
                        },
                    },
                    {
                        id = "trading-post",
                        label = "Trading Post",
                        content = {
                            { type = "change", text = "The Trading Post activity \"Complete 'A Call for Aid' Storyline\" should now require only quests within that storyline." },
                        },
                    },
                },
            },
            {
                id = "2026-08-13",
                label = "August 13, 2026",
                publicationSort = 20260813,
                categories = {
                    {
                        id = "classes",
                        label = "Classes",
                        submenus = {
                            {
                                id = "general",
                                label = "General",
                                content = {
                                    { type = "change", text = "Spirit Walk in the Vaults of Atal'utek should now apply to pets." },
                                },
                            },
                            {
                                id = "warlock",
                                label = "Warlock",
                                sections = {
                                    {
                                        heading = "Affliction",
                                        content = {
                                            { type = "change", text = "Fixed an issue where Seed of Corruption would not consume Shard Instability on cast." },
                                        },
                                    },
                                },
                            },
                        },
                    },
                    {
                        id = "delves",
                        label = "Delves",
                        content = {
                            { type = "change", text = "Fixed an issue where the Delve Shadowguard Point: Shadowguard Survivor would not grant Great Vault credit upon completion." },
                            { type = "change", text = "Fixed a bug causing Ritual Sites to appear to grant Great Vault rewards that were inconsistent with the available Tiers. Next week, the Great Vault will reward the intended tiers 1-6 for week 1 activities." },
                            { type = "change", text = "Fixed an issue with the Corrosive Codex that caused Corrosive Powers unlocked on one character to not show up as available options in the Corrosive Codex for other characters." },
                        },
                    },
                    {
                        id = "dungeons",
                        label = "Dungeons",
                        submenus = {
                            {
                                id = "general",
                                label = "General",
                                content = {
                                    { type = "change", text = "Players who have not yet completed precursor campaign quests should now be able to be summoned to the Vaults of Atal’Utek by Altar of Fangs dungeon groups." },
                                },
                            },
                            {
                                id = "altar-of-fangs",
                                label = "Altar of Fangs",
                                content = {
                                    { type = "change", text = "Addressed an issue where Uncoiled Writhe constantly switches target with Spiteful Hunt." },
                                    { type = "change", text = "Addressed an issue where interacting with Infusion Totem may fail to trigger the event." },
                                },
                            },
                            {
                                id = "voidscar-arena",
                                label = "Voidscar Arena",
                                content = {
                                    { type = "change", text = "Addressed an issue where defeating Aegyra the Unyielding while she's channeling Earthsplitter can fail to open the door to the arena." },
                                },
                            },
                        },
                    },
                    {
                        id = "items",
                        label = "Items",
                        content = {
                            { type = "change", text = "Fixed an issue that caused Venomjade Necklace to sometimes be invisible." },
                        },
                    },
                    {
                        id = "lairs",
                        label = "Lairs",
                        content = {
                            { type = "change", text = "Players cannot receive loot from Nymrissa Wavecaller more than once per week in World difficulty." },
                        },
                    },
                    {
                        id = "player-versus-player",
                        label = "Player Versus Player",
                        content = {
                            { type = "change", text = "Gorgoneion Gaze no longer petrifies players indefinitely." },
                            { type = "change", text = "Fixed a bug preventing Otherworldly Sparks of War from dropping in Naigtal and Val activities. The Naigtal and Val Sparks of War quests will no longer be offered when Season 2 begins." },
                        },
                    },
                    {
                        id = "professions",
                        label = "Professions",
                        content = {
                            { type = "change", text = "[With realm restarts] Jewelcrafting and Tailoring Profession Knowledge books from the forces of Zul'jarra should now correctly award profession Knowledge. Players who got the books prior to this fix should be given the Knowledge retroactively." },
                            { type = "change", text = "Fixed an issue that caused Contract: Zul'jarra's Forces to sometimes incorrectly apply Amani Tribe Contract when used." },
                        },
                    },
                    {
                        id = "quests",
                        label = "Quests",
                        content = {
                            { type = "change", text = "Fixed an issue where players could begin Curse of Ula'tek campaign quests without first completing the main Midnight campaign." },
                            { type = "developer_note", text = "The Curse of Ula'tek campaign was intended to require account completion of the main Midnight campaign before it could be started, as completing these features out of order could result in players being in a misleading or confusing state. Players who have not yet started the Curse of Ula’tek campaign must now complete the main Midnight campaign on one character per account. Any player-characters who have already started the Curse of Ula'tek campaign should be unaffected and can continue it and complete it." },
                            { type = "change", text = "Players who completed \"Legends of the Haranir\" quests split among multiple characters will now be able to resume \"The Empty Cradle\" questline." },
                            { type = "change", text = "“Cold As Ice” no longer sends players on a cold canoe ride into the abyss." },
                            { type = "change", text = "Removed an incorrect map marker for “A Suspicious Stew”." },
                            { type = "change", text = "Bob has been found and returned to his bartending." },
                        },
                    },
                    {
                        id = "world",
                        label = "World",
                        content = {
                            { type = "change", text = "Fixed a bug that could cause players to disconnect when entering the Lunarfall Garrison Excavation area." },
                        },
                    },
                },
            },
        },
        footer = "Source: Blizzard Entertainment — Official World of Warcraft Hotfixes",
    },
}

local function CopyAndSort(tabID)
    local results = {}
    for _, article in ipairs(Data.articles) do
        if article.internalTab == tabID then
            results[#results + 1] = article
        end
    end
    table.sort(results, function(left, right)
        local leftSort = tonumber(left.publicationSort) or 0
        local rightSort = tonumber(right.publicationSort) or 0
        if leftSort == rightSort then return tostring(left.title or "") < tostring(right.title or "") end
        return leftSort > rightSort
    end)
    return results
end

function Data.GetArticles(tabID)
    return CopyAndSort(tabID)
end

function Data.GetArticle(articleID)
    for _, article in ipairs(Data.articles) do
        if article.id == articleID then return article end
    end
end

function Data.GetNewest(tabID)
    return CopyAndSort(tabID)[1]
end

return Data
