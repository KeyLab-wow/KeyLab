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
        id = "curse-of-ulatek-common-issues-2026-08-26",
        internalTab = "issues",
        category = "KNOWN ISSUES",
        menuTitle = "Curse of Ula'tek Common Issues",
        title = "Midnight 12.1: Curse of Ula'tek - Common Issues",
        publicationDate = "Updated August 26, 2026",
        publicationSort = 20260826,
        sourceLabel = "Blizzard Support — World of Warcraft",
        articleType = "game_update",
        modes = {
            {
                id = "in-game-issues",
                label = "In-Game Issues",
                categories = {
                    {
                        id = "in-game-main-article",
                        label = "In-Game Issues — Main Article",
                        content = {
                            { type = "paragraph", text = "Updated: August 26, 2026  •  Article ID: 000358474  •  Product: World of Warcraft" },
                            { type = "paragraph", text = "Welcome back, adventurers! We hope you are once again ready to fight alongside your friends for this world. While this list is not all-encompassing, below you will find frequently reported issues currently being investigated:" },
                            { type = "heading", text = "Housing" },
                            { type = "change", text = "No issues currently being tracked" },
                            { type = "heading", text = "Character" },
                            { type = "change", text = "No issues currently being tracked" },
                            { type = "heading", text = "Quests" },
                            { type = "change", text = "Can't Complete Quest - Offensively Defensive" },
                            { type = "change", text = "Didn't Receive Spark of Tides Reward from Quest - Turn Back the Surge" },
                            { type = "heading", text = "Items" },
                            { type = "change", text = "Crafting Order Not Delivered" },
                            { type = "paragraph", text = "If you have an issue that is not on listed above, please check our support page: https://us.support.blizzard.com/en/help/games/wow" },
                        },
                    },
                    {
                        id = "offensively-defensive",
                        label = "Offensively Defensive",
                        content = {
                            { type = "paragraph", text = "Updated: August 19, 2026  •  Article ID: 000386033  •  Product: World of Warcraft" },
                            { type = "heading", text = "Common Problems" },
                            { type = "change", text = "The game crashes whenever I try to mount Ata the Wind-Master" },
                            { type = "change", text = "I cannot progress past the quest Offensively Defensive" },
                            { type = "change", text = "Cannot mount Ata" },
                            { type = "paragraph", text = "We have received several reports of this issue and can confirm it is not working as intended. Customer Support does not have a workaround or resolution that can be provided. We apologize for any inconvenience while our developers work as quickly as possible to resolve the issue." },
                            { type = "paragraph", text = "If you discover a new issue, please submit a new Bug report: https://support.blizzard.com/article/000015043" },
                            { type = "paragraph", text = "Note: Bugs submitted in-game do not receive a personal response. Instead, they'll be directed to the teams responsible for addressing them." },
                        },
                    },
                    {
                        id = "spark-of-tides",
                        label = "Didn't Receive Spark of Tides",
                        content = {
                            { type = "paragraph", text = "Updated: August 21, 2026  •  Article ID: 000386001  •  Product: World of Warcraft" },
                            { type = "heading", text = "Common Problems" },
                            { type = "change", text = "Spark of Tides not received" },
                            { type = "change", text = "Quest isn't giving the advertised quest reward" },
                            { type = "change", text = "Missing quest reward from Turn back the Surge" },
                            { type = "paragraph", text = "We have received several reports of this issue and can confirm it is not working as intended. Customer Support does not have a workaround or resolution that can be provided. We apologize for any inconvenience while our developers work as quickly as possible to resolve the issue. Please check our blue post for more information: https://us.forums.blizzard.com/en/wow/t/some-people-can-get-3-sparks-this-week-and-others-only-2/2335523/2" },
                            { type = "paragraph", text = "If you discover a new issue, please submit a new Bug report: https://support.blizzard.com/article/000015043" },
                            { type = "paragraph", text = "Bugs submitted in-game do not receive a personal response. Instead, they'll be directed to the teams responsible for addressing them." },
                        },
                    },
                    {
                        id = "crafting-order-not-delivered",
                        label = "Crafting Order Not Delivered",
                        content = {
                            { type = "paragraph", text = "Updated: August 21, 2026  •  Article ID: 000331001  •  Product: World of Warcraft" },
                            { type = "heading", text = "Common Problems" },
                            { type = "change", text = "I requested an item to be recrafted from a guild mate but didn't receive my item." },
                            { type = "change", text = "I crafted an item for a guild mate and it was not delivered to the person requesting it." },
                            { type = "paragraph", text = "We have received several reports of this issue and are investigating it. It's likely that the delivery is just delayed, or the item was retrieved and deleted or sold. Be sure to check the item restoration service to see if the item can be restored there: https://support.blizzard.com/article/000016572" },
                            { type = "paragraph", text = "If you don't receive the item after some time, please submit a new Bug report: https://support.blizzard.com/article/000015043" },
                            { type = "paragraph", text = "Note: Bugs submitted in-game do not receive a personal response. Instead, they'll be directed to the teams responsible for addressing them." },
                        },
                    },
                },
            },
            {
                id = "technical-issues",
                label = "Technical Issues",
                categories = {
                    {
                        id = "technical-main-article",
                        label = "Technical Issues — Main Article",
                        content = {
                            { type = "paragraph", text = "Updated: August 26, 2026  •  Article ID: 000358474  •  Product: World of Warcraft" },
                            { type = "paragraph", text = "Welcome back, adventurers! We hope you are once again ready to fight alongside your friends for this world. While this list is not all-encompassing, below you will find frequently reported issues currently being investigated:" },
                            { type = "heading", text = "Account" },
                            { type = "change", text = "No issues currently being tracked" },
                            { type = "heading", text = "Client" },
                            { type = "change", text = "Disconnected in Alliance Garrison Lunarfall Excavation" },
                            { type = "paragraph", text = "If you have an issue that is not on listed above, please check our support page: https://us.support.blizzard.com/en/help/games/wow" },
                        },
                    },
                    {
                        id = "lunarfall-excavation-disconnect",
                        label = "Disconnected in Lunarfall Excavation",
                        content = {
                            { type = "paragraph", text = "Updated: August 19, 2026  •  Article ID: 000386048  •  Product: World of Warcraft" },
                            { type = "heading", text = "Common Problems" },
                            { type = "change", text = "All my characters get disconnected when entering the Alliance garrison mine" },
                            { type = "paragraph", text = "This issue is currently planned to be fixed in a future patch. Please keep an eye on our official blogs and social media channels for announcements from our developers." },
                            { type = "paragraph", text = "Avoid going into the Lunarfall Excavation for the time being. If you have a character currently in there, try using the stuck character service to move them: https://support.blizzard.com/help/product/wow/197/834/solution" },
                            { type = "paragraph", text = "If you discover a new issue, please submit a new Bug report: https://support.blizzard.com/article/000015043" },
                            { type = "paragraph", text = "Note: Bugs submitted in-game do not receive a personal response. Instead, they'll be directed to the teams responsible for addressing them." },
                        },
                    },
                },
            },
        },
        footer = "Source: Blizzard Support — World of Warcraft",
    },
    {
        id = "venomous-abyss-race-to-world-first-2026-08-18",
        internalTab = "news",
        category = "RAID EVENT",
        menuTitle = "Venomous Abyss Race to World First",
        title = "The Race Through The Venomous Abyss Is Underway",
        publicationDate = "August 18, 2026",
        publicationSort = 20260818,
        sourceLabel = "Blizzard Entertainment — Official World of Warcraft News",
        articleType = "article",
        sections = {
            {
                paragraphs = {
                    "Midnight Season 2's Race to World First has begun. Leading guilds are progressing through The Venomous Abyss in a live competition to secure the world's first defeat of Ula’tek.",
                    "The event offers a close look at high-end raid strategy as teams refine positioning, cooldown plans, compositions, and execution pull by pull.",
                },
            },
            {
                heading = "Guild Broadcasts",
                changes = {
                    { text = "Liquid — twitch.tv/teamliquid, youtube.com/@TeamLiquidMMO, and tl.gg/Roku" },
                    { text = "Echo — twitch.tv/echo_esports and youtube.com/@EchoEsports" },
                    { text = "Method — twitch.tv/method" },
                },
            },
            {
                heading = "Progress and Additional Coverage",
                changes = {
                    { text = "BlizzardWatch — blizzardwatch.com/tag/world-first/" },
                    { text = "Method Raid Progress — method.gg/raidprogress" },
                    { text = "Raider.IO — raider.io/rwf and youtube.com/@RaiderIO_WoW" },
                    { text = "Warcraft Logs — warcraftlogs.com/rwf" },
                    { text = "Wowhead — wowhead.com/news/midnight-season-2-race-to-world-first-livestreams-coverage-and-news-382351" },
                },
            },
            {
                heading = "The Finish Line",
                paragraphs = {
                    "The race concludes when one guild earns the first confirmed Ula’tek kill. Until then, every new phase reached and boss defeated can reshape the standings.",
                },
            },
        },
        footer = "Source: Blizzard Entertainment — Official World of Warcraft News",
    },
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
        id = "nymrissa-wavecaller-tuning-2026-08-22",
        internalTab = "updates",
        category = "HOTFIXES",
        menuTitle = "Nymrissa Wavecaller Tuning Changes",
        title = "Nymrissa Wavecaller Tuning Changes",
        publicationDate = "August 22, 2026",
        publicationSort = 20260822,
        sourceLabel = "Limestone — WoW Developer",
        articleType = "hotfixes",
        introduction = "Hello,\n\nWe just sent a hotfix with the following changes to Nymrissa Wavecaller on Mythic difficulty:",
        hotfixDates = {
            {
                id = "2026-08-22",
                label = "August 22, 2026",
                publicationSort = 20260822,
                categories = {
                    {
                        id = "raids",
                        label = "Raids",
                        content = {
                            { type = "change", text = "Abyssal Rain’s initial damage reduced by 12.5% on Mythic difficulty" },
                            { type = "change", text = "Abyssal Rain’s periodic damage reduced by 20% on Mythic difficulty" },
                            { type = "change", text = "Reduced Abyssal Rain’s damage scaling based on group size for larger groups" },
                            { type = "change", text = "Frost Burst damage reduced by 40%" },
                        },
                    },
                },
            },
        },
        footer = "Source: Blizzard Entertainment — https://us.forums.blizzard.com/en/wow/t/2340109/1",
    },
    {
        id = "hotfixes-2026-08-21",
        internalTab = "updates",
        category = "HOTFIXES",
        menuTitle = "Hotfixes: August 21, 2026",
        title = "Hotfixes: August 21, 2026",
        publicationDate = "August 21, 2026",
        publicationSort = 20260821,
        sourceLabel = "Blizzard Entertainment — Official World of Warcraft Hotfixes",
        articleType = "hotfixes",
        introduction = "Here you'll find a list of hotfixes that address various issues related to World of Warcraft: Midnight, Mists of Pandaria Classic, Season of Discovery, Burning Crusade Classic, WoW Classic Era, and Hardcore. Some of the hotfixes below take effect the moment they were implemented, while others may require scheduled realm restarts to go into effect. Please keep in mind that some issues cannot be addressed without a client-side patch update. This list will be updated as additional hotfixes are applied.",
        hotfixDates = {
            {
                id = "2026-08-21",
                label = "August 21, 2026",
                publicationSort = 20260821,
                categories = {
                    {
                        id = "delves",
                        label = "Delves",
                        content = {
                            { type = "change", text = "Phantasmal Spore Toxin and Frostheart Venom will now properly be removed when leaving the delve." },
                            { type = "change", text = "Illusory Deceit no longer incorrectly scales the number of Twilight Illusions based on the number of players during Infiltrator Gulkat's encounter in The Darkway." },
                            { type = "change", text = "Players may now only pick up and carry one Oddball Ingredient at a time." },
                        },
                    },
                    {
                        id = "dungeons-and-raids",
                        label = "Dungeons and Raids",
                        submenus = {
                            {
                                id = "altar-of-fangs",
                                label = "Altar of Fangs",
                                sections = {
                                    {
                                        heading = "General",
                                        content = {
                                            { type = "change", text = "Ravenous Descendant’s Ravenous now grants 10% attack speed per stack (was 20%), and movement speed reduced by 20%." },
                                            { type = "change", text = "Twinfang Harrower’s Paralyzing Shots initial damage reduced by 50%." },
                                            { type = "change", text = "Venom Leech’s Septic Spatter no longer creates a puddle at the leech’s corpse location." },
                                            { type = "change", text = "Ritual Chieftain’s Blood Sacrifice absorb reduced by 10%." },
                                            { type = "change", text = "Caustic Mist Totem’s Unstable Totem damage reduced by 10%." },
                                            { type = "change", text = "High Evolutionist’s Evolve cooldown increased, Envenom cast time increased to 3 seconds (was 2.5 seconds), and Mass Envenom cast time increased to 3.5 seconds (was 2.5 seconds)." },
                                            { type = "change", text = "Bloodletter’s Bloodletting now procs less frequently." },
                                            { type = "change", text = "Ascendant Serpent health reduced by 10%." },
                                        },
                                    },
                                    {
                                        heading = "Rav’i",
                                        content = {
                                            { type = "change", text = "Feeding Frenzy no longer increases the rate of Messy Eater and Carrion Burst." },
                                            { type = "change", text = "Fresh Meat piles now display a warning visual when Rav’i is close enough to eat from them." },
                                            { type = "change", text = "Hydrastrike damage reduced by 33%." },
                                        },
                                    },
                                    {
                                        heading = "Zul’jan",
                                        content = {
                                            { type = "change", text = "The initial cast of Ritual of the Fang now occurs a few seconds later in the encounter." },
                                            { type = "change", text = "Ritual of the Fang cast time increased to 5 seconds (was 4 seconds)." },
                                            { type = "change", text = "Fang Empowered damage reduced by 20%." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "the-venomous-abyss",
                                label = "The Venomous Abyss",
                                sections = {
                                    {
                                        heading = "Vashnik the Malignant",
                                        content = {
                                            { type = "change", text = "Reduced target scaling for Adaptive infection to be less punishing for larger group sizes." },
                                            { type = "change", text = "Fixed an issue causing Thinned Blood to be cast on non-mythic difficulties." },
                                        },
                                    },
                                    {
                                        heading = "The Lost Explorers",
                                        content = {
                                            { type = "change", text = "Resolved an issue causing Final Ascension to inflict less damage than intended." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "ulatek",
                                label = "Ula’tek",
                                content = {
                                    { type = "change", text = "Adjusted the Caustic Waves from the Gore Rattler so they remain above the floor of the main platform." },
                                    { type = "change", text = "The tooltip for Ula'tek's Volatile Purge no longer contains an error." },
                                },
                            },
                        },
                    },
                    {
                        id = "housing",
                        label = "Housing",
                        content = {
                            { type = "change", text = "Previewing decor in the Decor Catalog will now show accurate Voidlight Marl prices for decor sold by Silvermoon's Disguised Decor Duel Vendor." },
                        },
                    },
                    {
                        id = "items",
                        label = "Items",
                        content = {
                            { type = "change", text = "Hex Lord's Dooming Idol - Hex Lord's Doom stacks are no longer removed upon ending a Mythic+ boss encounter." },
                        },
                    },
                    {
                        id = "prey",
                        label = "Prey",
                        content = {
                            { type = "change", text = "Fixed an issue that prevented alts from being able to access the Prey portal between Silvermoon and The Coiled Isle." },
                        },
                    },
                },
            },
            {
                id = "2026-08-20",
                label = "August 20, 2026",
                publicationSort = 20260820,
                categories = {
                    {
                        id = "classes",
                        label = "Classes",
                        submenus = {
                            {
                                id = "demon-hunter",
                                label = "Demon Hunter",
                                sections = {
                                    {
                                        heading = "Havoc",
                                        content = {
                                            { type = "change", text = "Aldrachi Reaver: Fixed an issue where Evasive Action was not granting an extra cast of Vengeful Retreat." },
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
                                            { type = "change", text = "Fixed an issue where the tooltip for Tranquility incorrectly described how long it extended heal over time effects." },
                                            { type = "change", text = "Fixed an issue where Overgrowth was applying healing over time effects to the incorrect target when used in tandem with Soul of the Forest." },
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
                                            { type = "change", text = "Corrected an issue where Hunters could benefit from the Precise Shots effect twice by casting Arcane Shot or Multi-Shot as Rapid Fire finishes channeling while talented into Unload." },
                                            { type = "change", text = "Corrected an issue where the AoE damage from Explosive Shot was not properly reduced by damage taken reduction effects." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "priest",
                                label = "Priest",
                                sections = {
                                    {
                                        heading = "Holy",
                                        content = {
                                            { type = "change", text = "Fixed an issue where casting Benediction and queuing a Holy Word would consume the proc." },
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
                                            { type = "change", text = "Resolved an issue causing Master of the Elements to not increase the damage of Earthquake." },
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
                                            { type = "change", text = "Hellcaller: Fixed an issue where Blackened Soul could trigger from Unstable Affliction periodic damage." },
                                        },
                                    },
                                    {
                                        heading = "Affliction",
                                        content = {
                                            { type = "change", text = "Fixed an issue where Malefic Grasp was not affected by Withering Bolt." },
                                            { type = "change", text = "Fixed an issue where Withering Bolt did not account for Wither when increasing Shadowbolt Volley damage." },
                                            { type = "change", text = "Fixed an issue where Wither would not count toward Darkglare Eye Beam damage increase." },
                                            { type = "change", text = "Fixed an issue where the Unstable Affliction granted by Venomous Abyss 4-piece set bonus would not grant a stack of Wither." },
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
                            { type = "change", text = "Fixed an issue where if Azta'rec killed a player it would display that Zek'vir has burrowed away and did not drop loot." },
                        },
                    },
                    {
                        id = "dungeons-and-raids",
                        label = "Dungeons and Raids",
                        submenus = {
                            {
                                id = "ruby-life-pools",
                                label = "Ruby Life Pools",
                                sections = {
                                    {
                                        heading = "Thunderhead and Flamegullet",
                                        content = {
                                            { type = "change", text = "Fixed an issue where certain abilities could cause their breath spells to cancel unexpectedly." },
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
                                            { type = "change", text = "Fixed an issue where the progress bar could reach 100% when the Avatar reached 99% health." },
                                        },
                                    },
                                },
                            },
                            {
                                id = "the-venomous-abyss",
                                label = "The Venomous Abyss",
                                sections = {
                                    {
                                        heading = "General",
                                        content = {
                                            { type = "change", text = "Resolved an issue where players could fall through the world in The Serpent Warren." },
                                        },
                                    },
                                    {
                                        heading = "Vashnik the Malignant",
                                        content = {
                                            { type = "change", text = "Fixed an issue causing Stygian Burst to inflict damage in a larger area than intended." },
                                            { type = "change", text = "Shrouded Venom health redistributed and now have 40% health and 60% shields." },
                                            { type = "change", text = "Fixed an issue causing players to get hit multiple times from the same wave in a short period of time." },
                                            { type = "change", text = "Fixed a rare issue where players using Harpoon on a Venom while inside the Malignant Cavity would cause them to fall through the playspace." },
                                        },
                                    },
                                    {
                                        heading = "The Coiled Altar",
                                        content = {
                                            { type = "change", text = "Fixed an issue where the encounter would rarely fail to properly transition to Phase 3 at the end of the intermission." },
                                        },
                                    },
                                    {
                                        heading = "Ula’tek",
                                        content = {
                                            { type = "change", text = "Blight Vein damage reduced on Heroic difficulty." },
                                            { type = "change", text = "Grasping Fangs now targets three players per side on Heroic difficulty, no matter the instance group size." },
                                            { type = "change", text = "Volatile Purge's area of effect now scales with raid size in Normal and Heroic difficulties. The effect radius is largest in a 10-player raid and gradually decreases as raid size increases, reaching its smallest size in a 30-player raid." },
                                            { type = "change", text = "Resolved an issue causing the damage of Spectral Coils to unintentionally scale on non-Mythic difficulties." },
                                            { type = "change", text = "Spectral Coils now requires 40% of the raid to reduce its damage to a minimum value." },
                                            { type = "change", text = "Spectral Coils adjusted on Heroic difficulty so it has more consistent timing." },
                                            { type = "change", text = "Corrected an issue where the Blight Vein debuff did not properly inflict its damage based on the number of stacks applied, on Heroic and Mythic difficulties." },
                                            { type = "change", text = "Corrected an issue where Hunters’ Stampede pets from the Pack Leader hero talents would not properly damage the Heart of Ula'tek during the encounter." },
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
                            { type = "change", text = "Companion Command Crystal is now bind-on-pickup." },
                        },
                    },
                    {
                        id = "omnium-folio",
                        label = "Omnium Folio",
                        content = {
                            { type = "change", text = "Fixed an issue with a previous change to the Omnium Folio's Rune of Unleashed Fire that resulted in pulling enemies you were not in combat with." },
                        },
                    },
                    {
                        id = "prey",
                        label = "Prey",
                        content = {
                            { type = "change", text = "Decreased the damage and slow effect of Toxic Snare." },
                        },
                    },
                    {
                        id = "quests",
                        label = "Quests",
                        content = {
                            { type = "change", text = "\"The Venomous Abyss\" campaign quest should now complete for players who were dead at the end of the last encounter." },
                            { type = "change", text = "Fixed an issue that reduced player-characters' turn speed after starting the world quest \"Swift of Foot\"." },
                        },
                    },
                    {
                        id = "treasures",
                        label = "Treasures",
                        content = {
                            { type = "change", text = "Fixed an issue where the Unguarded Chest would spawn without Farthik the Plunderer." },
                        },
                    },
                },
            },
        },
        footer = "Source: Blizzard Entertainment — Official World of Warcraft Hotfixes",
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
        id = "item-adjustment-2026-08-25",
        internalTab = "updates",
        category = "ITEM ADJUSTMENT",
        menuTitle = "Item Adjustment Incoming - August 25",
        title = "Item Adjustment Incoming - August 25",
        publicationDate = "August 18, 2026",
        publicationSort = 20260818,
        effectiveDate = "Effective August 25, 2026",
        author = "Kaivax - Community Manager",
        sourceLabel = "Official World of Warcraft Forums",
        introduction = "With a hotfix that will go live with scheduled weekly maintenance on August 25, we’re adjusting one item:",
        sections = {
            {
                heading = "Items",
                changes = {
                    { text = "Aqirbane Reliquary now grants a smaller quantity of all secondary stats (was a large quantity of only Critical Strike). Its first on-equip effect is unchanged, and its second on-equip effect has been updated to increase a random secondary stat (was only Critical Strike) while decreasing the other three." },
                },
            },
        },
        footer = "Source: Official World of Warcraft Forums",
    },
    {
        id = "class-tuning-2026-08-25",
        internalTab = "updates",
        category = "CLASS TUNING",
        menuTitle = "Class Tuning Incoming – August 25",
        title = "Class Tuning Incoming – August 25",
        publicationDate = "August 21, 2026",
        publicationSort = 20260821,
        effectiveDate = "Effective August 25, 2026",
        author = "Kaivax - Community Manager",
        sourceLabel = "Official World of Warcraft Forums",
        articleType = "class_tuning",
        introduction = "As we previously indicated, we’re doing broad class tuning each week for the first three weeks of the Curse of Ula’tek content update. With scheduled weekly maintenance in each region, we’ll make the following tuning adjustments.",
        modes = {
            {
                id = "class",
                label = "CLASS CHANGES",
                classes = {
                    {
                        id = "death-knight",
                        name = "Death Knight",
                        content = {
                            { type = "developer_note", text = "Frost Death Knight has performed under our expectations at the beginning of Curse of Ula’tek, especially in the Venomous Abyss raid." },
                        },
                        specializations = {
                            {
                                id = "frost",
                                name = "Frost",
                                content = {
                                    { type = "change", text = "All ability damage and melee damage increased by 6%." },
                                    { type = "change", text = "Obliterate damage increased by 15%." },
                                },
                            },
                        },
                    },
                    {
                        id = "demon-hunter",
                        name = "Demon Hunter",
                        specializations = {
                            {
                                id = "havoc",
                                name = "Havoc",
                                content = {
                                    { type = "change", text = "All damage increased by 3%." },
                                },
                            },
                            {
                                id = "vengeance",
                                name = "Vengeance",
                                content = {
                                    { type = "change", text = "Mastery: Fel Blood effectiveness increased by 24%." },
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
                                    { type = "developer_note", text = "These changes are intended to address Rejuvenation and Wild Growth feeling weak in season 2, particularly in dungeons. We’re also increasing the power of the 4-piece class set to make sure it’s an impactful and noticeable set bonus. These changes are accompanied by slight nerfs to their raid healing to keep them around the same power in raid while increasing their power in dungeons." },
                                    { type = "change", text = "4-piece class set bonus increases Genesis duration by 8 seconds (was 4 seconds)." },
                                    { type = "change", text = "Rejuvenation and Germination healing increased by 15%." },
                                    { type = "change", text = "Wild Growth healing increased by 10%." },
                                    { type = "change", text = "Nature’s Bounty replicates 10% of Regrowth’s healing (was 20%)." },
                                    { type = "change", text = "Everbloom heals 5 targets (was 6 targets)." },
                                    { type = "change", text = "Everbloom heals for 48% of Lifebloom’s final heal (was 40%)." },
                                },
                            },
                        },
                    },
                    {
                        id = "evoker",
                        name = "Evoker",
                        specializations = {
                            {
                                id = "preservation",
                                name = "Preservation",
                                content = {
                                    { type = "developer_note", text = "We’re further increasing some of the Preservation triage heals to help them keep up with other healers in dungeons." },
                                    { type = "change", text = "Verdant Embrace healing increased by 25%. Does not apply to PvP combat." },
                                    { type = "change", text = "Living Flame healing increased by 20%. Does not apply to PvP combat." },
                                    { type = "change", text = "Dream Simulacrum increases healing of Verdant Embrace by 40% (was 30%)." },
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
                                    { type = "developer_note", text = "We’re looking to increase Beast Mastery area damage and cleave capabilities." },
                                    { type = "change", text = "Wild Thrash now deals 300% increased damage when striking more than 2 targets (was 200%)." },
                                    { type = "change", text = "Beast Cleave now causes your pets to strike nearby enemies for 70% of the damage dealt (was 55%)." },
                                },
                            },
                            {
                                id = "survival",
                                name = "Survival",
                                content = {
                                    { type = "change", text = "All damage dealt by you and your pets increased by 4%." },
                                },
                            },
                        },
                    },
                    {
                        id = "mage",
                        name = "Mage",
                        specializations = {
                            {
                                id = "frost",
                                name = "Frost",
                                content = {
                                    { type = "developer_note", text = "We’re primarily focused on Frost’s performance in Mythic Keystone dungeons. The recent removal of the health increase from Improved Ice Barrier had a greater effect on Frost’s overall survivability than intended. We like the symmetry of the three Improved Barrier talents having one additional effect, and Frost has historically had a slightly larger absorb than Arcane and Fire, so we’re baking it into the baseline absorb amount rather than re-attaching it to Improved Ice Barrier. We’re also making some targeted increases to Frost’s area of effect damage." },
                                    { type = "change", text = "Ice Barrier absorb amount increased to 35% of maximum health (was 30%). Does not apply to PvP combat." },
                                    { type = "change", text = "Blizzard damage increased by 10%." },
                                    { type = "change", text = "Frostbite Talent: Shatter damage to nearby enemies increased by 10%." },
                                    { type = "change", text = "Frostfire: Isothermic Core - Meteor damage increased by 25%." },
                                },
                            },
                        },
                    },
                    {
                        id = "monk",
                        name = "Monk",
                        specializations = {
                            {
                                id = "brewmaster",
                                name = "Brewmaster",
                                content = {
                                    { type = "developer_note", text = "We’re adjusting the absorption of Celestial Brew and Celestial Infusion to improve its impact as a defensive option and to help address pain points players are experiencing in some encounters." },
                                    { type = "change", text = "All damage increased by 3%." },
                                    { type = "change", text = "Celestial Brew and Celestial Infusion absorb value increased by 20%." },
                                },
                            },
                        },
                    },
                    {
                        id = "paladin",
                        name = "Paladin",
                        specializations = {
                            {
                                id = "retribution",
                                name = "Retribution",
                                content = {
                                    { type = "developer_note", text = "We’re increasing the damage of the Curse of Ula’tek 4-piece set bonus Divine Arbiter significantly, to make sure its rotational ask is worth executing." },
                                    { type = "change", text = "Class Set 4-piece Divine Arbiter main target damage increased by 150%." },
                                    { type = "change", text = "Class Set 4-piece Divine Arbiter secondary target damage increased by 75%." },
                                },
                            },
                        },
                    },
                    {
                        id = "warlock",
                        name = "Warlock",
                        content = {
                            { type = "developer_note", text = "We’re increasing the throughput of Affliction and Demonology by primarily focusing on their single-target tools with a secondary focus on their multi-target kit. Additionally, we’re considerably increasing the damage of Warlock demons so that they have a larger contribution to overall throughput. This should also help a bit more with aggro concerns during solo play." },
                            { type = "change", text = "Imp, Voidwalker, Sayaad, and Felhunter damage increased by 350%." },
                        },
                        specializations = {
                            {
                                id = "affliction",
                                name = "Affliction",
                                content = {
                                    { type = "change", text = "Unstable Affliction damage increased by 15%. Does not apply to PvP combat." },
                                    { type = "change", text = "Hellcaller – Blackened Soul damage increased by 20%. Does not apply to PvP combat." },
                                    { type = "change", text = "Wrath of Nathreza damage increased by 35%. Does not apply to PvP combat." },
                                    { type = "change", text = "Shadow of Nathreza damage increased by 25%. Does not apply to PvP combat." },
                                    { type = "change", text = "Agony damage increased by 20%. Does not apply to PvP combat." },
                                    { type = "change", text = "Corruption damage increased by 15%. Does not apply to PvP combat." },
                                    { type = "change", text = "Hellcaller – Wither damage increased by 10%. Does not apply to PvP combat." },
                                },
                            },
                            {
                                id = "demonology",
                                name = "Demonology",
                                content = {
                                    { type = "change", text = "Shadow Bolt damage increased by 35%. Does not apply to PvP combat." },
                                    { type = "change", text = "Demonbolt damage increased by 30%." },
                                    { type = "change", text = "Wild Imp damage increased by 20%." },
                                    { type = "change", text = "Summon Felguard damage increased by 20%." },
                                    { type = "change", text = "Demons summoned by Dominion of Argus damage increased by 20%. Does not apply to PvP combat." },
                                    { type = "change", text = "Call Dreadstalkers damage increased by 30%." },
                                },
                            },
                            {
                                id = "destruction",
                                name = "Destruction",
                                content = {
                                    { type = "change", text = "Rain of Fire damage increased by 30%." },
                                },
                            },
                        },
                    },
                    {
                        id = "warrior",
                        name = "Warrior",
                        specializations = {
                            {
                                id = "protection",
                                name = "Protection",
                                content = {
                                    { type = "change", text = "Fight Through the Flames reduces Magic damage by 8% (was 6%)." },
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
                        id = "demon-hunter",
                        name = "Demon Hunter",
                        content = {
                            { type = "developer_note", text = "We feel the defensive kits of Devourer and Havoc are too powerful, so we are reducing some of their passive and active defenses to make them more viable targets for opponents." },
                            { type = "change", text = "Glimpse now reduces damage taken by 20% while active (was 25%)." },
                        },
                        specializations = {
                            {
                                id = "devourer",
                                name = "Devourer",
                                content = {
                                    { type = "change", text = "Void Ray damage increased by 33% in PvP combat." },
                                    { type = "change", text = "Blur now reduces damage taken by 15% in PvP combat (was 25%)." },
                                    { type = "change", text = "Armor of Souls now increases Armor by 65% (was 100%)." },
                                },
                            },
                            {
                                id = "havoc",
                                name = "Havoc",
                                content = {
                                    { type = "change", text = "Blur now reduces damage taken by 15% in PvP combat (was 25%)." },
                                    { type = "change", text = "Desperate Instincts now reduces damage taken by 5% while below 35% health in PvP combat (was 10%)." },
                                },
                            },
                        },
                    },
                    {
                        id = "druid",
                        name = "Druid",
                        specializations = {
                            {
                                id = "feral",
                                name = "Feral",
                                content = {
                                    { type = "developer_note", text = "Feral’s sustained damage is lower than our intended target, so we’re targeting their primary damage over time effects to improve this. We’re also targeting a buff for Druid of the Claw which has fallen behind Wildstalker in viability." },
                                    { type = "change", text = "Druid of the Claw: Ravage damage increased by 20% in PvP combat." },
                                    { type = "change", text = "Rip damage increased by 15% in PvP combat." },
                                    { type = "change", text = "Rake damage increased by 15% in PvP combat." },
                                },
                            },
                        },
                    },
                    {
                        id = "evoker",
                        name = "Evoker",
                        specializations = {
                            {
                                id = "augmentation",
                                name = "Augmentation",
                                content = {
                                    { type = "developer_note", text = "Augmentation has been underplayed in PvP, especially arenas, for some time. We’re increasing both their damage support capabilities and their personal damage to increase their viability." },
                                    { type = "change", text = "Damage increased by 10% in PvP combat." },
                                    { type = "change", text = "Ebon Might grants 10% primary stat in PvP combat (was 8%)." },
                                    { type = "change", text = "Inferno’s Blessing damage increased by 25% in PvP combat." },
                                },
                            },
                        },
                    },
                    {
                        id = "hunter",
                        name = "Hunter",
                        content = {
                            { type = "developer_note", text = "Sentinel Hunters are slightly too strong during burst windows in PvP, so we’re reducing the damage of Moonlight Chakram and increasing the throughput of rotational abilities to compensate." },
                        },
                        specializations = {
                            {
                                id = "marksmanship",
                                name = "Marksmanship",
                                content = {
                                    { type = "change", text = "Sentinel: Moonlight Chakram damage reduced by 30% in PvP combat." },
                                    { type = "change", text = "Rapid Fire damage increased by 15% in PvP combat." },
                                    { type = "change", text = "Arcane Shot damage increased by 15% in PvP combat." },
                                },
                            },
                            {
                                id = "survival",
                                name = "Survival",
                                content = {
                                    { type = "change", text = "Sentinel: Moonlight Chakram damage reduced by 30% in PvP combat." },
                                    { type = "change", text = "Raptor Strike and Raptor Swipe damage increased by 20% in PvP combat." },
                                    { type = "change", text = "Kill Command damage increased by 15% in PvP combat." },
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
                                    { type = "developer_note", text = "Fire Mage execute windows and hard cast Pyroblast damage have been higher than we would like, so we’re reducing the effectiveness of Molten Fury and Pyroclasm in PvP." },
                                    { type = "change", text = "Pyroclasm now increases the damage of Pyroblast and Flamestrike by 180% in PvP combat (was 230%)." },
                                    { type = "change", text = "vMolten Fury now increases damage to targets below 35% health by 10% in PvP combat (was 15%)." },
                                },
                            },
                        },
                    },
                    {
                        id = "monk",
                        name = "Monk",
                        specializations = {
                            {
                                id = "windwalker",
                                name = "Windwalker",
                                content = {
                                    { type = "change", text = "Rushing Wind Kick damage reduced by 20% in PvP combat." },
                                    { type = "change", text = "Rising Sun Kick damage reduced by 10% in PvP combat." },
                                    { type = "change", text = "Tigereye Brew now increases critical strike damage by 3/6% in PvP combat (was 5/10%)." },
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
                                    { type = "developer_note", text = "Holy Paladin throughput has increased with recent changes past our targets for them in PvP." },
                                    { type = "change", text = "All healing reduced by 4% in PvP combat." },
                                },
                            },
                            {
                                id = "protection",
                                name = "Protection",
                                content = {
                                    { type = "developer_note", text = "Protection Paladins have been extending the duration of the matches that they participate in with frequent access to group utility. We’re reducing the effectiveness of Blessing of Sacrifice and Guardian of the Forgotten Queen to bring them in line." },
                                    { type = "change", text = "Guardian of the Forgotten Queen duration reduced to 6 seconds." },
                                    { type = "change", text = "Guardian of the Forgotten Queen cooldown increased to 4 minutes." },
                                    { type = "change", text = "Guardian of the Forgotten Queen now has a 6 second internal cooldown." },
                                    { type = "change", text = "Sacrifice of the Just reduces the cooldown of Blessing of Sacrifice by 30 seconds in PvP combat (was 60 seconds)." },
                                },
                            },
                            {
                                id = "retribution",
                                name = "Retribution",
                                content = {
                                    { type = "developer_note", text = "Retribution’s personal durability has been higher than we would like considering their complete team defensive package, and Templar’s damage has not been competitive with Herald of the Sun, so we’re increasing some sources specific to its hero tree." },
                                    { type = "change", text = "Shield of Vengeance absorption reduced by 25% in PvP combat." },
                                    { type = "change", text = "Divine Protection now reduces damage taken by 20% in PvP combat (was 25%)." },
                                    { type = "change", text = "Templar: Seal of the Templar now increases the damage of Templar’s Verdict by 35% (was 25%)." },
                                    { type = "change", text = "Templar: Hammer of Light’s damage increased by 10% in PvP combat." },
                                },
                            },
                        },
                    },
                    {
                        id = "priest",
                        name = "Priest",
                        content = {
                            { type = "developer_note", text = "Mindgames has fallen behind other spells and has been an underutilized talent for some time, so we’re increasing its viability to offer all Priest specializations more PvP talent options." },
                            { type = "change", text = "Mindgames direct damage increased by 150%." },
                            { type = "change", text = "Mindgames healing and damage reversal increased by 150%." },
                        },
                        specializations = {
                            {
                                id = "discipline",
                                name = "Discipline",
                                content = {
                                    { type = "change", text = "Flash Heal and Shadow Mend healing increased by 20% in PvP combat." },
                                    { type = "change", text = "Atonement healing increased by 5% in PvP combat." },
                                },
                            },
                            {
                                id = "holy",
                                name = "Holy",
                                content = {
                                    { type = "developer_note", text = "Holy Priest is vastly overperforming due to a mixture of overall healing increases from the patch as well as some generous PvP specific healing increases to Prayer of Mending and Holy Word: Serenity. We’re reducing these PvP increases to Prayer of Mending, Holy Word: Serenity, and Prompt Prognosis which are all powerful instant cast spells." },
                                    { type = "change", text = "Enlightenment regenerates mana 10% faster in PvP combat (was 25%)." },
                                    { type = "change", text = "Prayer of Mending healing reduced by 25% in PvP combat." },
                                    { type = "change", text = "Holy Word: Serenity healing reduced by 15% in PvP combat." },
                                    { type = "change", text = "Oracle: Prompt Prognosis healing reduced by 25% in PvP combat." },
                                },
                            },
                            {
                                id = "shadow",
                                name = "Shadow",
                                content = {
                                    { type = "developer_note", text = "We feel Shadow is lacking in kill power, so we’re increasing some of its primary sources of burst." },
                                    { type = "change", text = "Shadow Word: Madness damage increased by 15% in PvP combat." },
                                    { type = "change", text = "Void Volley damage increased by 15% in PvP combat." },
                                    { type = "change", text = "Shadow Word: Death damage increased by 15% in PvP combat." },
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
                                    { type = "developer_note", text = "Burst from Assassination’s Apex Talent is exceeding expectations and is getting toned down. Additionally, damage from Fatebound Coins is higher than intended and is being reduced." },
                                    { type = "change", text = "Kingsbane initial damage reduced by 12% in PvP combat." },
                                    { type = "change", text = "Implacable (Rank 3) Physical and Nature damage reduced by 15% in PvP combat." },
                                    { type = "change", text = "Fatebound: Fatebound Coin (Tails) damage reduced by 10% in PvP combat." },
                                },
                            },
                            {
                                id = "outlaw",
                                name = "Outlaw",
                                content = {
                                    { type = "developer_note", text = "Outlaw’s damage and kill pressure is lower than we’d expect, so we’re putting more damage into core finishing moves." },
                                    { type = "change", text = "Dispatch damage increased by 20% in PvP combat." },
                                    { type = "change", text = "Between the Eyes damage increased by 12% in PvP combat." },
                                },
                            },
                            {
                                id = "subtlety",
                                name = "Subtlety",
                                content = {
                                    { type = "developer_note", text = "Subtlety’s steady damage pressure is low, without which it can be difficult to create windows that capitalize on their burst potential. We’re increasing * Eviscerate damage moderately and Goremaw’s Bite bleed damage significantly to increase the frequency of these windows." },
                                    { type = "change", text = "Eviscerate damage increased by 10% in PvP combat." },
                                    { type = "change", text = "Goremaw’s Bite bleeding damage increased by 33% in PvP combat." },
                                },
                            },
                        },
                    },
                    {
                        id = "shaman",
                        name = "Shaman",
                        specializations = {
                            {
                                id = "elemental",
                                name = "Elemental",
                                content = {
                                    { type = "developer_note", text = "Elemental is lacking the sustained pressure we expect, so we’re targeting core damage sources to improve its viability." },
                                    { type = "change", text = "Stormbringer: Tempest damage increased by 10% in PvP combat." },
                                    { type = "change", text = "Lava Burst damage increased by 10% in PvP combat." },
                                    { type = "change", text = "Earth Shock damage increased by 10% in PvP combat." },
                                    { type = "change", text = "Earthquake damage increased by 10% in PvP combat." },
                                },
                            },
                            {
                                id = "restoration",
                                name = "Restoration",
                                content = {
                                    { type = "developer_note", text = "Restoration Shaman is slightly too strong compared to other healers (barring Holy Priest). We’re making some small adjustments to their mana and the Totemic hero talent tree to better balance their mana and throughput." },
                                    { type = "change", text = "Mana regeneration is now reduced by 65% in PvP combat (was 60%)." },
                                    { type = "change", text = "Totemic: Splitstream now causes Healing Stream Totem to heal an additional ally at 15% effectiveness in PvP combat (was 30%)." },
                                    { type = "change", text = "Totemic: Earthsurge now causes allies affected by your Earthliving to receive 5% additional healing from you in PvP combat (was 15%)." },
                                },
                            },
                        },
                    },
                    {
                        id = "warlock",
                        name = "Warlock",
                        specializations = {
                            {
                                id = "affliction",
                                name = "Affliction",
                                content = {
                                    { type = "developer_note", text = "We’re increasing Affliction’s ability to maintain spread pressure by adjusting Agony’s damage and making a small adjustment to Unstable Affliction’s backlash damage to make dispelling all their damage over time effects more punishing." },
                                    { type = "change", text = "Agony damage increased by 50% in PvP combat." },
                                    { type = "change", text = "Unstable Affliction backlash damage increased by 20%." },
                                },
                            },
                            {
                                id = "demonology",
                                name = "Demonology",
                                content = {
                                    { type = "developer_note", text = "We feel too much of Demonology’s damage is focused on Wicked Reaping and Power Siphon, so we’re reducing the power of these effects and increasing overall damage through our game-wide Demonology changes above." },
                                    { type = "change", text = "Soul Harvester: Wicked Reaping damage reduced by 50% in PvP combat." },
                                    { type = "change", text = "Soul Harvester: Necrolyte Teachings now causes Power Siphon to increase the damage of Demonbolt by an additional 10% in PvP combat (was 20%)." },
                                    { type = "change", text = "Power Siphon now increases the damage of your next 2 Demonbolts by 20% in PvP combat (was 30%)." },
                                },
                            },
                            {
                                id = "destruction",
                                name = "Destruction",
                                content = {
                                    { type = "developer_note", text = "Destruction is lacking in finishing power, so we’re increasing the damage of their primary nuke spells to allow for more burst potential." },
                                    { type = "change", text = "Chaos Bolt damage increased by 15% in PvP combat." },
                                    { type = "change", text = "Shadowburn damage increased by 30% in PvP combat." },
                                },
                            },
                        },
                    },
                    {
                        id = "warrior",
                        name = "Warrior",
                        specializations = {
                            {
                                id = "arms",
                                name = "Arms",
                                content = {
                                    { type = "developer_note", text = "To compensate for the reduction in Fueled by Violence self-healing, we’re increasing Arms’ Hero Talents throughput by increasing Slayer’s Strike and Demolish damage in PvP." },
                                    { type = "change", text = "Colossus: Demolish damage increased by 15% in PvP combat." },
                                    { type = "change", text = "Slayer: Slayer’s Strike damage increased by 15% in PvP combat." },
                                    { type = "change", text = "Fueled by Violence healing reduced by 15% in PvP combat." },
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

local suppliedNewsArticles = {
    {
        id = "class-tuning-incoming-2026-09-01",
        internalTab = "news",
        category = "UPCOMING TUNING",
        menuTitle = "Class Tuning Incoming - September 1",
        title = "More Class Tuning Arrives September 1",
        publicationDate = "August 28, 2026",
        publicationSort = 20260828,
        sourceLabel = "Linxy — World of Warcraft Community Manager",
        articleType = "article",
        sections = {
            {
                paragraphs = {
                    "Blizzard has another class-tuning pass planned for the September 1 weekly reset, with a focus on underperforming Raid and Mythic+ specializations and a broad round of PvP adjustments.",
                },
            },
            {
                heading = "PvE Highlights",
                changes = {
                    { text = "Damage increases are planned for Frost Death Knight, Havoc Demon Hunter, Balance and Feral Druid, Beast Mastery and Survival Hunter, Fire and Frost Mage, Windwalker Monk, and Protection Paladin." },
                    { text = "Vengeance Demon Hunter receives stronger mitigation and Fel Devastation healing." },
                    { text = "Restoration Druid and Mistweaver Monk receive healing increases; Discipline Priest receives a lower Shadow Mend mana cost." },
                },
            },
            {
                heading = "PvP Direction",
                paragraphs = {
                    "The PvP changes aim to reduce overall defensiveness and healing while improving offensive options for lower-performing specializations.",
                },
            },
        },
        footer = "Source: World of Warcraft official forums — Class Tuning Incoming - September 1",
    },
    {
        id = "raid-bonus-roll-update-2026-08-28",
        internalTab = "news",
        category = "LOOT UPDATE",
        menuTitle = "Raid Bonus Roll Update",
        title = "Raid Bonus Rolls Will Require Loot Eligibility",
        publicationDate = "August 28, 2026",
        publicationSort = 20260828,
        sourceLabel = "Kaivax — World of Warcraft Community Manager",
        articleType = "article",
        sections = {
            {
                paragraphs = {
                    "Beginning with the September 1 weekly reset, Bonus Rolls can only be used when a player is still eligible to receive loot from that raid encounter and difficulty.",
                    "After a boss has locked you out of loot for the week, repeat kills on that same difficulty will no longer offer a Bonus Roll.",
                },
            },
        },
        footer = "Source: Kaivax — Raid Bonus Roll Update",
    },
    {
        id = "venomous-abyss-story-mode-rf-wing-2-2026-08-25",
        internalTab = "news",
        category = "RAID OPENING",
        menuTitle = "Venomous Abyss Story Mode & Wing 2",
        title = "Story Mode and Raid Finder Wing 2 Are Open",
        publicationDate = "August 25, 2026",
        publicationSort = 20260825,
        sourceLabel = "Blizzard Entertainment — Official World of Warcraft News",
        articleType = "article",
        sections = {
            {
                paragraphs = {
                    "The Venomous Abyss Story Mode and Raid Finder Wing 2 are now available. Wing 2, The Essence of Venom, features Entombed Sentinels and Vashnik the Malignant.",
                },
            },
            {
                heading = "At a Glance",
                changes = {
                    { text = "Raid Finder minimum item level: 273" },
                    { text = "September 1: Wing 3 — The Lost Explorers and Sszorak" },
                    { text = "September 8: Wing 4 — The Coiled Altar and Ula’tek" },
                },
            },
        },
        footer = "Source: Blizzard Entertainment — Official World of Warcraft News",
    },
    {
        id = "northrend-cup-2026-08-25",
        internalTab = "news",
        category = "SKYRIDING EVENT",
        menuTitle = "Northrend Cup",
        title = "The Northrend Cup Returns",
        publicationDate = "August 25, 2026",
        publicationSort = 20260825,
        sourceLabel = "Blizzard Entertainment — Official World of Warcraft News",
        articleType = "article",
        sections = {
            {
                paragraphs = {
                    "The Northrend Cup runs August 25 through September 8, bringing twelve Skyriding courses across Northrend in Normal, Advanced, and Reverse variations.",
                    "Earn Riders of Azeroth Badges for cosmetics, and complete every race at Gold for the Northrend Racer title and Frosted Riders of Azeroth Tabard.",
                },
            },
        },
        footer = "Source: Blizzard Entertainment — Official World of Warcraft News",
    },
    {
        id = "fixing-misplaced-sparks-of-tides-2026-08-25",
        internalTab = "news",
        category = "ITEM UPDATE",
        menuTitle = "Fixing Misplaced Sparks of Tides",
        title = "Missing Spark of Tides Cleanup Is Underway",
        publicationDate = "August 25, 2026",
        publicationSort = 20260825,
        sourceLabel = "Kaivax — World of Warcraft Community Manager",
        articleType = "article",
        sections = {
            {
                paragraphs = {
                    "Blizzard addressed issues affecting players who were missing Spark of Tides items during weekly maintenance.",
                    "Additional cleanup waves will continue through the week, including rare cases where players received Sparks above the intended cap.",
                },
            },
        },
        footer = "Source: Kaivax — Fixing Misplaced Sparks of Tides - August 25",
    },
    {
        id = "september-trading-post-2026-08-24",
        internalTab = "news",
        category = "TRADING POST",
        menuTitle = "September Trading Post",
        title = "September Celebrates Friendship at the Trading Post",
        publicationDate = "August 24, 2026",
        publicationSort = 20260824,
        sourceLabel = "Blizzard Entertainment — Official World of Warcraft News",
        articleType = "article",
        sections = {
            {
                paragraphs = {
                    "September's Trading Post celebrates friendship and BlizzCon 2026 with new Leafmimic mounts, the returning Gummi pet, colorful transmog, and more.",
                    "Special Outlet vendors in Dornogal and Silvermoon City will also offer discounted and returning items throughout the month.",
                },
            },
        },
        footer = "Source: Blizzard Entertainment — Official World of Warcraft News",
    },
}

for index = #suppliedNewsArticles, 1, -1 do
    table.insert(Data.articles, 1, suppliedNewsArticles[index])
end

-- Game Updates is a completed-update record. Reuse the already approved
-- Blizzard hotfix records above, split them into one dated entry each, and
-- keep upcoming August 25 announcements in News & Events instead.
local function FindStoredArticle(articleID)
    for _, article in ipairs(Data.articles) do
        if article.id == articleID then return article end
    end
end

local function FindStoredHotfixDate(articleID, dateID)
    local article = FindStoredArticle(articleID)
    for _, dateData in ipairs(article and article.hotfixDates or {}) do
        if dateData.id == dateID then return dateData end
    end
end

local august17Hotfix = {
    id = "2026-08-17",
    label = "August 17, 2026",
    publicationSort = 20260817,
    categories = {
        {
            id = "classes",
            label = "Classes",
            submenus = {
                {
                    id = "hunter",
                    label = "Hunter",
                    sections = {
                        {
                            heading = "Beast Mastery",
                            content = {
                                { type = "change", text = "Corrected an issue where Dire Beast Kill Commands from the Wildspeaker Talent did not properly benefit from Killer Instinct, Alpha Predator, Specialized Arsenal, or Savagery." },
                            },
                        },
                    },
                },
                {
                    id = "priest",
                    label = "Priest",
                    sections = {
                        {
                            heading = "Holy",
                            content = {
                                { type = "change", text = "Corrected an issue where swapping from Shadow to Holy specializations could improperly cause Shadow Word: Pain to not turn into Holy Fire." },
                            },
                        },
                    },
                },
                {
                    id = "shaman",
                    label = "Shaman",
                    sections = {
                        {
                            heading = "General",
                            content = {
                                { type = "change", text = "Corrected an issue where swapping between specs may incorrectly cause Lava Burst to show up as Primal Strike in your spellbook." },
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
                                { type = "change", text = "Fixed an issue where the tooltip of Shadowburn would not display the correct duration." },
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
                { type = "change", text = "In Delves, Ula'tek's Amphisbaena Writhing Strike poison can only get one aura at a time. Damage reduced 25%, and the cooldown on Writhing Strike increased." },
                { type = "change", text = "Fixed an issue causing Corrosive Bilespear to not proc at higher ranks." },
            },
        },
        {
            id = "lairs",
            label = "Lairs",
            content = {
                { type = "change", text = "Resolved an issue causing the sharks to not bite in The Tidebound Grotto." },
            },
        },
        {
            id = "naigtal-and-val",
            label = "Naigtal and Val",
            content = {
                { type = "change", text = "Players in Heroic World Tier can again talk with a sprit healer to exit Heroic World Tier and resurrect." },
            },
        },
        {
            id = "quests",
            label = "Quests",
            content = {
                { type = "change", text = "Ofi the Sly should now properly accept that the concoction is complete for \"Acceptable Apprentice\"." },
                { type = "change", text = "Fixed an issue preventing characters under level 90 from completing activities related to Saltheril's Soiree and Abundance." },
            },
        },
    },
}

local HOTFIX_CATEGORY_IDS = {
    ["Classes"] = "classes",
    ["Delves"] = "delves",
    ["Dungeons and Raids"] = "dungeons-and-raids",
    ["Housing"] = "housing",
    ["Items"] = "items",
    ["Items and Rewards"] = "items-and-rewards",
    ["Mounts"] = "mounts",
    ["Omnium Folio"] = "omnium-folio",
    ["Player versus Player"] = "player-versus-player",
    ["Prey"] = "prey",
    ["Quests"] = "quests",
}

local function ParseSuppliedHotfixDate(id, label, publicationSort, sourceText)
    local dateData = {
        id = id,
        label = label,
        publicationSort = publicationSort,
        categories = {},
    }
    local currentCategory

    for sourceLine in (tostring(sourceText or "") .. "\n"):gmatch("(.-)\r?\n") do
        local leading = sourceLine:match("^(%s*)") or ""
        local text = sourceLine:gsub("^%s+", ""):gsub("%s+$", "")
        text = text:gsub("^%-%s*", "")
        if text ~= "" and text ~= "Hotfixes" and text ~= label then
            local categoryID = HOTFIX_CATEGORY_IDS[text]
            if categoryID then
                currentCategory = {
                    id = categoryID,
                    label = text,
                    content = {},
                    sourceRows = {},
                }
                dateData.categories[#dateData.categories + 1] = currentCategory
            elseif currentCategory then
                currentCategory.sourceRows[#currentCategory.sourceRows + 1] = {
                    indent = #leading,
                    text = text,
                }
            end
        end
    end

    for _, category in ipairs(dateData.categories) do
        for index, row in ipairs(category.sourceRows) do
            local nextRow = category.sourceRows[index + 1]
            local lower = row.text:lower()
            local blockType = "change"
            if lower:find("^developer") and (lower:find("notes:") or lower:find("note:")) then
                blockType = "developer_note"
            elseif nextRow and nextRow.indent > row.indent then
                blockType = "heading"
            end
            category.content[#category.content + 1] = {
                type = blockType,
                text = row.text,
            }
        end
        category.sourceRows = nil
    end

    return dateData
end

local august27Hotfix = ParseSuppliedHotfixDate("2026-08-27", "August 27, 2026", 20260827, [=[
August 27, 2026
- Classes
  - Demon Hunter
    - Fixed an issue that allowed Blur's recent PvP adjustments to affect PvE situations. Blur damage reduction outside of PvP is restored to previous intended values.
  - Evoker
    - Flameshaper: Fixed an issue where Lifecinders incorrectly stated that it required Renewing Blaze.
    - Preservation
      - Fixed an issue where Emerald Communion would loop its visual even after the effect had ended.
  - Rogue
    - Deathstalker: Fixed an issue where Deathstalker's Mark would be removed when a target becomes unattackable. Darkest Night will now be granted when Deathstalker's Mark is removed from an unattackable target.
  - Paladin
    - Protection
      - Fixed an issue where Blessed Hammer could not hit Ula'tek's Venomous Heart.
  - Warlock
    - Destruction
      - Fixed an issue where Mayhem would sometimes become untracked when refreshed while active.
  Delves
  - Fixed an issue that caused Mislaid Curiosities to not spawn in The Darkway variant Eggsplosive Growth.
  Dungeons and Raids
  - Temple of Sethraliss
    - Fixed an issue where the Voidbound Emisssary M+ affix creature could cause Galvazzt to despawn.
  - The Venomous Abyss
    - Vashnik the Malignant
      - Reduced the damage of Siphoning Infection by 33% on Raid Finder difficulty.
      - Reduced the damage of Siphon Blood by 33% on Raid Finder difficulty.
      - Reduced the healing reduction 80% (was 100%) on Raid Finder difficulty.
      - Increased the healing of Siphoning Infection by 10% on Normal difficulty.
      - Increased the healing of Siphoning Infection by 500% on Raid Finder difficulty.
    - The Twin Fangs
      - Resolved an issue that could cause Caustic Globule/Barbed Bulwark world indicators to clear prior to the missile impact.
    - The Coiled Altar
      - Fixed an issue where bringing Zul'jan to 1 health at the end of the intermission would prevent him from being killable during phase 3.
  Items
  - Fixed an issue that prevented Contract: Zul'jarra's Forces from applying to your entire Warband.
  - Sszorak's Ferocity - The Tempest poison tornado effect is now only visible to the trinket wearer and its size has been reduced.
  Mounts
  - Increased the size of several writhe mounts to be more consistent.
  Player versus Player
  - Fixed an issue that prevented players from earning progress towards their next Vicious Saddle.
]=])

local august26Hotfix = ParseSuppliedHotfixDate("2026-08-26", "August 26, 2026", 20260826, [=[
August 26, 2026
Classes
- Demon Hunter
  - Devourer
    - Fixed an issue that prevented the effect of the Devourer 2-piece set bonus (Soulburst) from displaying correctly.
- Paladin
  - Protection
    - Fixed an issue where Avenger's Shield could sometimes fail to activate Glory of the Vanguard while Divine Resonance was active.
- Priest
  - Holy
    - Fixed an issue where Divine Hymn would put Guardian Spirit on a 60-second cooldown with Guardian Angel talented.
- Shaman
  - Elemental
    - Farseer: Corrected an issue where Maelstrom Supremacy did not increase the healing of Healing Surge.
- Warrior
  - Fixed a bug that could cause Sudden Death to incorrectly increase cooldowns.
Delves
- Fixed a bug that could cause the Undergraduates in the Infiltrator Garand encounter to spawn in unintended locations.
- Fixed an issue causing Gnok to cast Ejecting Decay while moving, and Upheaval no longer targets pets.
Dungeons and Raids
- The Venemous Abyss
  - Story Mode: Dungeon followers will now properly lead players when Dungeon Assistance is toggled on.
  - The Lost Explorers
    - Evokers’ Cauterizing Flame should now properly remove the Splinters effect during this encounter.
  - Ula’tek
    - Fixed an issue where the targeting of Mother's Wrath could fail, causing Ula'tek to use her raid wide damage despite the tank being in the bubble.
    - Fixed an issue that could cause unintended duplicate applications of Doomscale Shell.
Items and Rewards
- Players who are offered a Silvermoon Splendor in their Great Vault can still select that option and receive a Nebulous Voidcore.
- Fixed an issue where raid armor rewards from the Coiled Altar and Ula'tek could not be catalyzed if sourced from the Great Vault or Voidcore rolls. Existing items may now catalyzed.
- Fixed an issue where some Season 2 items could not have a socket added.
- "Overflowing" caches for reaching maximum Renown should now contain Veteran Mistcrests during Season 2.
Player versus Player
- Resolved an issue that prevented Training Grounds: Arena from ending the match when the game-controlled opponents surrender.
]=])

local august25Hotfix = ParseSuppliedHotfixDate("2026-08-25", "August 25, 2026", 20260825, [=[
August 25, 2026
Classes
- Death Knight
  - Developers' notes: Frost Death Knight has performed under our expectations at the beginning of Curse of Ula'tek, especially in the Venomous Abyss raid.
  - Frost
    - All ability damage and melee damage increased by 6%.
    - Obliterate damage increased by 15%.
  - Unholy
    - Resolved an issue causing the Unholy Devotion attack speed increase to also reduce attack damage and therefore have a neutral effect.
- Demon Hunter
  - Havoc
    - All damage increased by 3%.
  - Vengeance
    - Mastery: Fel Blood effectiveness increased by 24%.
- Druid
  - Restoration
    - Developers’ notes: These changes are intended to address Rejuvenation and Wild Growth feeling weak in season 2, particularly in dungeons. We’re also increasing the power of the 4-piece class set to make sure it's an impactful and noticeable set bonus. These changes are accompanied by slight nerfs to their raid healing to keep them around the same power in raid while increasing their power in dungeons.
    - 4-piece class set bonus increases Genesis duration by 8 seconds (was 4 seconds).
    - Rejuvenation and Germination healing increased by 15%. Does not apply to PvP combat.
    - Wild Growth healing increased by 10%.
    - Nature's Bounty replicates 10% of Regrowth's healing (was 20%).
    - Everbloom heals 5 targets (was 6 targets).
    - Everbloom heals for 48% of Lifebloom's final heal (was 40%). Does not apply to PvP combat.
- Evoker
  - Preservation
    - Developers’ notes: We’re further increasing some of the Preservation triage heals to help them keep up with other healers in dungeons.
    - Verdant Embrace healing increased by 25%. Does not apply to PvP combat.
    - Living Flame healing increased by 20%. Does not apply to PvP combat.
    - Dream Simulacrum increases healing of Verdant Embrace by 40% (was 30%).
- Hunter
  - Beast Mastery
    - Developers’ notes: We’re looking to increase Beast Mastery area damage and cleave capabilities.
    - Wild Thrash now deals 300% increased damage when striking more than 2 targets (was 200%).
    - Beast Cleave now causes your pets to strike nearby enemies for 70% of the damage dealt (was 55%).
  - Survival
    - All damage dealt by you and your pets increased by 4%.
- Mage
  - Frost
    - Developers' notes: We're primarily focused on Frost's performance in Mythic Keystone dungeons. The recent removal of the health increase from Improved Ice Barrier had a greater effect on Frost's overall survivability than intended. We like the symmetry of the three Improved Barrier talents having one additional effect, and Frost has historically had a slightly larger absorb than Arcane and Fire, so we're baking it into the baseline absorb amount rather than re-attaching it to Improved Ice Barrier. We're also making some targeted increases to Frost's area of effect damage.
    - Ice Barrier absorb amount increased to 35% of maximum health (was 30%). Does not apply to PvP combat.
    - Blizzard damage increased by 10%.
    - Frostbite Talent: Shatter damage to nearby enemies increased by 10%.
    - Frostfire: Isothermic Core - Meteor damage increased by 25%.
- Monk
  - Brewmaster
    - Developers’ note: We’re adjusting the absorption of Celestial Brew and Celestial Infusion to improve its impact as a defensive option and to help address pain points players are experiencing in some encounters.
    - All damage increased by 3%.
    - Celestial Brew and Celestial Infusion absorb value increased by 20%.
- Paladin
  - Retribution
    - Developers' notes: We're increasing the damage of the Curse of Ula'tek 4-piece set bonus Divine Arbiter significantly, to make sure its rotational ask is worth executing.
    - Class Set 4-piece Divine Arbiter main target damage increased by 150%.
    - Class Set 4-piece Divine Arbiter secondary target damage increased by 75%.
- Warlock
  - Developers’ notes: We’re increasing the throughput of Affliction and Demonology by primarily focusing on their single-target tools with a secondary focus on their multi-target kit. Additionally, we’re considerably increasing the damage of Warlock demons so that they have a larger contribution to overall throughput. This should also help a bit more with aggro concerns during solo play.
  - Imp, Voidwalker, Sayaad, and Felhunter damage increased by 350%.
  - Affliction
    - Unstable Affliction damage increased by 15%. Does not apply to PvP combat.
    - Hellcaller – Blackened Soul damage increased by 20%. Does not apply to PvP combat.
    - Wrath of Nathreza damage increased by 35%. Does not apply to PvP combat.
    - Shadow of Nathreza damage increased by 25%. Does not apply to PvP combat.
    - Agony damage increased by 20%. Does not apply to PvP combat.
    - Corruption damage increased by 15%. Does not apply to PvP combat.
    - Hellcaller – Wither damage increased by 10%. Does not apply to PvP combat.
  - Demonology
    - Shadow Bolt damage increased by 35%. Does not apply to PvP combat.
    - Demonbolt damage increased by 30%.
    - Wild Imp damage increased by 20%.
    - Summon Felguard damage increased by 20%.
    - Demons summoned by Dominion of Argus damage increased by 20%. Does not apply to PvP combat.
    - Call Dreadstalkers damage increased by 30%.
  - Destruction
    - Rain of Fire damage increased by 30%.
- Warrior
  - Protection
    - Fight Through the Flames reduces Magic damage by 8% (was 6%).
Delves
- Fixed an issue where Valeera could no longer gain experience from mislaid curiosities.
Dungeons and Raids
- The Tidebound Grotto
  - Health of Nymrissa Wavecaller reduced by 5% on Heroic difficulty and 10% on Mythic difficulty.
  - Abyssal Rain's initial damage reduced by 12.5%.
  - Abyssal Rain's periodic damage reduced by 12% on Heroic difficulty and 20% on Mythic difficulty.
  - Reduced Abyssal Rain’s damage scaling for larger groups.
  - Frost Burst damage reduced by 40%.
  - Shatter now occurs after 40 seconds (was 30 seconds).
  - Chilling Frost duration reduced by 1.5 seconds.
  - Reduced the number Bubblefin Frostscales that appear with each wave of murlocs to 2 (was 3).
- Altar of Fangs
  - Removed one High Evolutionist in the area after Rav'i.
- The Blinding Vale
  - Increased enemy forces requirement to 686 (was 655).
  - Adjusted spawning in the last area to reduce creature density.
  - Removed a Radiant Spellsower before Ziekket.
  - Potatoad Matriarch
    - Increased enemy forces value to 60 (was 30).
    - Reduced health by 10%.
    - Toxic Spew initial damage reduced by 50%.
    - Toadspawn target radius reduced to 3-7 yards (was 10 yards), and eggs now finish hatching even if the Matriarch is dead.
  - Ikuzz the Light Hunter
    - Addressed an issue where Bloodthorn Root is affected by disorient effects.
- Den of Nalorakk
  - Reduced the number of Earthwhisper Tenders in the first area by 2.
  - Thornclaw Gatherer
    - Rotten Supplies cooldown increased to 17 seconds (was 14 seconds).
- Kings' Rest
  - Finished Mummy and Half-Finished Mummy are now marked as elites.
  - Risen Hexer now casts Shadow Bolt (was Shadowfrost Bolt).
  - Phantom Hex Priest now uses Shadow magic (was Nature).
  - Increased Shadow of Zul’s ability cooldown.
  - Bloodsworn Assassin’s Sudden Rupture now prefers not targeting the same player consecutively.
  - The Council of Tribes
    - Kula the Butcher’s Whirling Axes visual updated.
    - Aka'ali the Conqueror and Zanazal the Wise now wait briefly before attacking players.
- Murder Row
  - Addressed an issue where Malefic Wave can sometimes fail to hit players.
  - Addressed an issue where Row Snitch can be uninteractable.
  - Lithiel Cinderfury
    - Fingers of Gul’dan now prefers non-tank players.
    - Fingers of Gul’Dan number of targets reduced to 4 (was 5).
    - Fingers of Gul’dan number of Wild Imps summoned increased to 4 (was 3).
- Ruby Life Pools
  - Replaced the Flashfrost Chillweaver nearest to Defier Draghar with a Deepstone Earthshaper, and moved one of the preceding Earthbound Guardians next to this creature.
    - Adjusted enemy forces requirement to keep routing the same as before.
  - Deepstone Earthshaper’s health reduced by 8%, and Techtonic Strikes damage vulnerability reduced to 25% (was 35%).
  - Flashfrost Chillweaver’s health reduced by 10%.
  - Primalist Cinderweaver’s Living Bomb periodic damage and explosion damage reduced by 10%.
- Temple of Sethraliss
  - Replaced a Faithless Subjugator with a Lightning Serpent.
    - Adjusted enemy forces requirement to keep routing the same as before.
  - Swarming Krolusks now idle for longer after spawning before attacking.
- Voidscar Arena
  - Adjusted spawning of a pack near the Harrower to be closer to the stairs.
  - Taz'Rah
    - Nether Dash line visuals now turn more smoothly.
  - Atroxus
    - Addressed issues with the voice lines not matching the spells.
- The Venomous Abyss
  - Reduced the number of creature spawns throughout the zone.
  - Reduced the blood required to open doors throughout the Venomous Abyss.
  - Reduced the damage of Venom Withdrawal by 30%.
  - Reduced the duration of Venom Withdrawal by 50%.
  - Reduced the health of Serpent Wards by 75%.
  - The Lost Explorers
    - Resolved an issue where Hoji did not immediately stop casting when the encounter ends, preventing the encounter from completing.
  - Vashnik the Malignant
    - Fixed an issue causing the Solidified Snake Venom to not spawn for the achievement.
    - Fixed an issue causing Burning Venom to not move towards the Malignant Cavity after being gripped.
    - Reduced the number of Malignant Totems per cast.
    - Adjusted the spawn locations of Malignant Totems.
    - Fixed a bug causing Imbibe to inflict more damage than intended on Normal and Heroic difficulties.
  - The Coiled Altar
    - Fixed an issue where Sever's vulnerability aura lasted longer than intended.
    - Malacrass now casts Dreadmarch on all players 10 seconds after he enrages.
    - Reduced Malacrass’s phase 3 health by 10% on Normal and Heroic difficulties.
    - Eternal Nightfall is no longer affected by Curse of Tongues or similar effects.
    - Reduced the absorb value of Veil of Twilight by 15% on Normal and Heroic difficulties.
  - Ula’tek
    - Corrected the target location of Ula'tek's Venomous Heart so that AoE spells more consistently hit it and Ula'tek.
    - Fixed a bug preventing the encounter from resetting when no players were alive in Ula’tek’s room.
    - Increased the duration of Greasy Hatchling to 35 seconds (was 20 seconds).
    - Players are now protected against being targeted by Virulent Spit while crossing the venom pools.
    - Resolved an issue causing Death Knights’ Necrotic Coil to have pathing issues.
    - Causing the Doomscale Warden to cast Shadow Molt early no longer resets their spell record timings.
    - Reduced the number of players required to successfully soak Serpent's Bite across the range of raid sizes.
    - Players affected by Calcified Corpse now radiate massive raid damage on Heroic and Mythic difficulties.
    - An erroneous tenth stack of Stone Venom is no longer applied to the current target during Ula'tek's Mother's Wrath.
Housing
- Previewing decor in the Decor Catalog will now show accurate Voidlight Marl prices for decor sold by Silvermoon's Disguised Decor Duel Vendor.
Omnium Folio
- Fixed a bug that where the Rune of Lingering did not always activate for healers.
Player versus Player
- In Training Grounds, Arena opponents will now properly display their surrender animation when forfeiting their match after a teammate has died.
- Demon Hunter
  - Developers’ notes: We feel the defensive kits of Devourer and Havoc are too powerful, so we are reducing some of their passive and active defenses to make them more viable targets for opponents.
  - Glimpse now reduces damage taken by 20% while active (was 25%).
  - Devourer
    - Void Ray damage increased by 33% in PvP combat.
    - Blur now reduces damage taken by 15% in PvP combat (was 25%).
    - Armor of Souls now increases Armor by 65% (was 100%).
  - Havoc
    - Blur now reduces damage taken by 15% in PvP combat (was 25%).
    - Desperate Instincts now reduces damage taken by 5% while below 35% health in PvP combat (was 10%).
- Druid
  - Feral
    - Developers’ notes: Feral’s sustained damage is lower than our intended target, so we’re targeting their primary damage over time effects to improve this. We’re also targeting a buff for Druid of the Claw which has fallen behind Wildstalker in viability.
    - Druid of the Claw: Ravage damage increased by 20% in PvP combat.
    - Rip damage increased by 15% in PvP combat.
    - Rake damage increased by 15% in PvP combat.
- Evoker
  - Augmentation
    - Developers’ notes: Augmentation has been underplayed in PvP, especially arenas, for some time. We're increasing both their damage support capabilities and their personal damage to increase their viability.
    - Damage increased by 10% in PvP combat.
    - Ebon Might grants 10% primary stat in PvP combat (was 8%).
    - Inferno's Blessing damage increased by 25% in PvP combat.
- Hunter
  - Developers’ notes: Sentinel Hunters are slightly too strong during burst windows in PvP, so we're reducing the damage of Moonlight Chakram and increasing the throughput of rotational abilities to compensate.
  - Marksmanship
    - Sentinel: Moonlight Chakram damage reduced by 30% in PvP combat.
    - Rapid Fire damage increased by 15% in PvP combat.
    - Arcane Shot damage increased by 15% in PvP combat.
  - Survival
    - Sentinel: Moonlight Chakram damage reduced by 30% in PvP combat.
    - Raptor Strike and Raptor Swipe damage increased by 20% in PvP combat.
    - Kill Command damage increased by 15% in PvP combat.
- Mage
  - Fire
    - Developers’ notes: Fire Mage execute windows and hard cast Pyroblast damage have been higher than we would like, so we're reducing the effectiveness of Molten Fury and Pyroclasm in PvP.
    - Burnout now explodes for 50% of remaining Ignite damage in PvP combat (was 75%).
    - Pyroclasm now increases the damage of Pyroblast and Flamestrike by 180% in PvP combat (was 230%).
    - Molten Fury now increases damage to targets below 35% health by 10% in PvP combat (was 15%).
- Monk
  - Brewmaster
    - Fixed an issue where Hot Trub PvP talent was incorrectly counting as both a Disorient and an Incapacitate. It now counts as an Incapacitate only.
  - Windwalker
    - Rushing Wind Kick damage reduced by 20% in PvP combat.
    - Rising Sun Kick damage reduced by 10% in PvP combat.
    - Tigereye Brew now increases critical strike damage by 3/6% in PvP combat (was 5/10%).
- Paladin
  - Holy
    - Developer's notes: Holy Paladin throughput has increased with recent changes past our targets for them in PvP.
    - All healing reduced by 4% in PvP combat.
  - Protection
    - Developers’ note: Protection Paladins have been extending the duration of the matches that they participate in with frequent access to group utility. We're reducing the effectiveness of Blessing of Sacrifice and Guardian of the Forgotten Queen to bring them in line.
    - Guardian of the Forgotten Queen duration reduced to 6 seconds.
    - Guardian of the Forgotten Queen cooldown increased to 4 minutes.
    - Guardian of the Forgotten Queen now has a 6 second internal cooldown.
    - Sacrifice of the Just reduces the cooldown of Blessing of Sacrifice by 30 seconds in PvP combat (was 60 seconds).
  - Retribution
    - Developers' notes: Retribution's personal durability has been higher than we would like considering their complete team defensive package, and Templar's damage has not been competitive with Herald of the Sun, so we're increasing some sources specific to its hero tree.
    - Shield of Vengeance absorption reduced by 25% in PvP combat.
    - Divine Protection now reduces damage taken by 20% in PvP combat (was 25%).
    - Templar: Seal of the Templar now increases the damage of Templar's Verdict by 35% (was 25%).
    - Templar: Hammer of Light's damage increased by 10% in PvP combat.
- Priest
  - Developers’ notes: Mindgames has fallen behind other spells and has been an underutilized talent for some time, so we're increasing its viability to offer all Priest specializations more PvP talent options.
  - Mindgames direct damage increased by 150%.
  - Mindgames healing and damage reversal increased by 150%.
  - Discipline
    - Flash Heal and Shadow Mend healing increased by 20% in PvP combat.
    - Atonement healing increased by 5% in PvP combat.
  - Holy
    - Developers’ notes: Holy Priest is vastly overperforming due to a mixture of overall healing increases from the patch as well as some generous PvP specific healing increases to Prayer of Mending and Holy Word: Serenity. We’re reducing these PvP increases to Prayer of Mending, Holy Word: Serenity, and Prompt Prognosis which are all powerful instant cast spells.
    - Enlightenment regenerates mana 10% faster in PvP combat (was 25%).
    - Prayer of Mending healing reduced by 25% in PvP combat.
    - Holy Word: Serenity healing reduced by 15% in PvP combat.
    - Oracle: Prompt Prognosis healing reduced by 25% in PvP combat.
  - Shadow
    - Developers’ notes: We feel Shadow is lacking in kill power, so we’re increasing some of its primary sources of burst.
    - Shadow Word: Madness damage increased by 15% in PvP combat.
    - Void Volley damage increased by 15% in PvP combat.
    - Shadow Word: Death damage increased by 15% in PvP combat.
- Rogue
  - Assassination
    - Developers’ notes: Burst from Assassination’s Apex Talent is exceeding expectations and is getting toned down. Additionally, damage from Fatebound Coins is higher than intended and is being reduced.
    - Kingsbane initial damage reduced by 12% in PvP combat.
    - Implacable (Rank 3) Physical and Nature damage reduced by 15% in PvP combat.
    - Fatebound: Fatebound Coin (Tails) damage reduced by 10% in PvP combat.
  - Outlaw
    - Developers’ notes: Outlaw’s damage and kill pressure is lower than we’d expect, so we’re putting more damage into core finishing moves.
    - Dispatch damage increased by 20% in PvP combat.
    - Between the Eyes damage increased by 12% in PvP combat.
  - Subtlety
    - Developers’ notes: Subtlety’s steady damage pressure is low, without which it can be difficult to create windows that capitalize on their burst potential. We’re increasing Eviscerate damage moderately and Goremaw’s Bite bleed damage significantly to increase the frequency of these windows.
    - Eviscerate damage increased by 10% in PvP combat.
    - Goremaw's Bite bleeding damage increased by 33% in PvP combat.
- Shaman
  - Elemental
    - Developers’ notes: Elemental is lacking the sustained pressure we expect, so we’re targeting core damage sources to improve its viability.
    - Stormbringer: Tempest damage increased by 10% in PvP combat.
    - Lava Burst damage increased by 10% in PvP combat.
    - Earth Shock damage increased by 10% in PvP combat.
    - Earthquake damage increased by 10% in PvP combat.
  - Restoration
    - Developers’ notes: Restoration Shaman is slightly too strong compared to other healers (barring Holy Priest). We’re making some small adjustments to their mana and the Totemic hero talent tree to better balance their mana and throughput.
    - Mana regeneration is now reduced by 65% in PvP combat (was 60%).
    - Totemic: Splitstream now causes Healing Stream Totem to heal an additional ally at 15% effectiveness in PvP combat (was 30%).
    - Totemic: Earthsurge now causes allies affected by your Earthliving to receive 5% additional healing from you in PvP combat (was 15%).
- Warlock
  - Affliction
    - Developers’ notes: We’re increasing Affliction’s ability to maintain spread pressure by adjusting Agony’s damage and making a small adjustment to Unstable Affliction’s backlash damage to make dispelling all their damage over time effects more punishing.
    - Agony damage increased by 50% in PvP combat.
    - Unstable Affliction backlash damage increased by 20%.
  - Demonology
    - Developers’ notes: We feel too much of Demonology’s damage is focused on Wicked Reaping and Power Siphon, so we’re reducing the power of these effects and increasing overall damage through our game-wide Demonology changes above.
    - Soul Harvester: Wicked Reaping damage reduced by 50% in PvP combat.
    - Soul Harvester: Necrolyte Teachings now causes Power Siphon to increase the damage of Demonbolt by an additional 10% in PvP combat (was 20%).
    - Power Siphon now increases the damage of your next 2 Demonbolts by 20% in PvP combat (was 30%).
  - Destruction
    - Developers’ notes: Destruction is lacking in finishing power, so we’re increasing the damage of their primary nuke spells to allow for more burst potential.
    - Chaos Bolt damage increased by 15% in PvP combat.
    - Shadowburn damage increased by 30% in PvP combat.
- Warrior
  - Arms
    - Developers’ notes: To compensate for the reduction in Fueled by Violence self-healing, we're increasing Arms’ Hero Talents throughput by increasing Slayer's Strike and Demolish damage in PvP.
    - Colossus: Demolish damage increased by 15% in PvP combat.
    - Slayer: Slayer’s Strike damage increased by 5% in PvP combat.
    - Fueled by Violence healing reduced by 15% in PvP combat.
Prey
- Fixed a bug where the spell Noxious Spitfall was targeting players not on the threat list.
- Fixed a bug where Ral'kala's invulnerability shield would interfere with his timed despawn.
- Pack Hunters and Pack Ambushers will no longer spawn Venom-Bloated Pythons.
Quests
- Fixed an issue causing Li Li Stormstout to comment when the player exits “The War Within Recap”.
- Fixed an issue preventing Soridormi from offering the “Legacy of the Amani” campaign chapter skip.
- The weekly quests "Turn Back the Surge" and "Sparks of War: Eversong Woods" no longer incorrectly suggest that they reward two Sparks of Tide.
]=])

local suppliedHotfixDates = {
    august27Hotfix,
    august26Hotfix,
    august25Hotfix,
    FindStoredHotfixDate("hotfixes-2026-08-21", "2026-08-21"),
    FindStoredHotfixDate("hotfixes-2026-08-21", "2026-08-20"),
    FindStoredHotfixDate("hotfixes-2026-08-19", "2026-08-19"),
    FindStoredHotfixDate("hotfixes-2026-08-19", "2026-08-18"),
    august17Hotfix,
    FindStoredHotfixDate("hotfixes-2026-08-14", "2026-08-14"),
    FindStoredHotfixDate("hotfixes-2026-08-14", "2026-08-13"),
}

local function SplitHotfixModes(categories)
    local pve, pvp = {}, {}
    for _, category in ipairs(categories or {}) do
        local isPvP = category.id == "player-versus-player"
            or category.label == "Player versus Player"
        if isPvP then
            pvp[#pvp + 1] = category
        else
            pve[#pve + 1] = category
        end
    end
    return {
        { id = "pve", label = "PvE", categories = pve },
        { id = "pvp", label = "PvP", categories = pvp },
    }
end

local rebuiltArticles = {}
local moveToNews = {
    ["item-adjustment-2026-08-25"] = true,
    ["class-tuning-2026-08-25"] = true,
}

for _, article in ipairs(Data.articles) do
    if article.internalTab == "news" or article.internalTab == "issues" then
        rebuiltArticles[#rebuiltArticles + 1] = article
    elseif moveToNews[article.id] then
        article.internalTab = "news"
        rebuiltArticles[#rebuiltArticles + 1] = article
    end
end

for _, dateData in ipairs(suppliedHotfixDates) do
    if dateData then
        rebuiltArticles[#rebuiltArticles + 1] = {
            id = "game-update-hotfixes-" .. dateData.id,
            internalTab = "updates",
            updateType = "Hotfixes",
            category = "HOTFIXES",
            menuTitle = "Hotfixes",
            title = "Hotfixes",
            publicationDate = dateData.label,
            publicationSort = dateData.publicationSort,
            sourceLabel = "Blizzard Entertainment — Official World of Warcraft Hotfixes",
            articleType = "game_update",
            modes = SplitHotfixModes(dateData.categories),
            footer = "Source: Blizzard Entertainment — Official World of Warcraft Hotfixes",
        }
    end
end

Data.articles = rebuiltArticles

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
