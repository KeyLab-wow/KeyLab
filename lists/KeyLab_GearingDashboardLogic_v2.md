# KeyLab Gearing Dashboard Logic v2

This file replaces the older broad gearing-dashboard rules with a simplified Mythic+ focused system.

The Gear Dashboard should not try to be a full gearing guide for all WoW content. KeyLab is a Mythic+ addon, and Gear Targets are based on Mythic+ loot.

The dashboard should focus on:
- current equipped gear
- current character stats
- saved Gear Targets
- Mythic+ history from KeyLab encounters
- upgrade track/rank
- crests/currencies that affect M+ gearing
- tier/catalyst readiness
- crafted/voidforged/embellishment signals
- compact item-card badges

The dashboard should show conclusions, not raw database text.

## Core Philosophy

Gear Targets answers: What items do I want?

Gear Dashboard answers: What should I upgrade, polish, catalyst, craft, or run in Mythic+ next?

The dashboard is not a BIS simulator and should not recommend every possible content source.

Non-M+ content may exist in the database as reference data, but the dashboard should not center recommendations around raids, delves, prey hunts, or world content.

## Dashboard Availability

If the player is below level 90, show:

`Gear Dashboard becomes available at Level 90.`

If the player has no stored completed Mythic+ run, show:

`Complete at least one Mythic+ dungeon to unlock Gear Dashboard recommendations.`

Reason: KeyLab uses Mythic+ encounter history as the progression signal. If the player only raids, delves, or does world content, the dashboard does not have enough KeyLab data to make M+ recommendations.

## Data Flow

Do not put scan/parsing/scoring logic directly in the UI.

Expected flow:

```text
capture/KeyLab_GearCapture.lua
        ↓
analysis/KeyLab_GearingAnalysis.lua
        ↓
ui/KeyLab_GearDashboard.lua
```

Static rules live in:

```text
database/KeyLab_GearingDatabase.lua
```

UI displays final analyzed results only.

## Gear Capture Requirements

The gear capture layer should normalize raw WoW API and tooltip data into clean fields.

The dashboard should not rely on raw tooltip line type numbers where avoidable because multiple useful lines may have the same `type = 0`.

Capture should expose normalized fields such as:

```lua
{
    slotID = 1,
    slotName = "Head",
    itemLink = "...",
    itemID = 123456,
    itemLevel = 263,

    upgradeRawLine = "Upgrade Level: Hero 2/6",
    upgradeTrack = "Hero",
    upgradeRank = 2,
    upgradeMaxRank = 6,

    enchantDetected = true,
    emptySocketCount = 0,

    craftedIndicatorVisible = true,
    tierIndicatorVisible = true,

    embellishedDetected = true,
    embellishmentLine = "Unique-Equipped: Embellished (2)",

    ascendantVoidforgedDetected = true,

    primaryStatsShown = {},
    secondaryStatsShown = {},
    tooltipLinesRaw = {}
}
```

Raw tooltip lines should be kept for debugging/fallback only.

## Upgrade Track and Rank

Tooltip example:

`Upgrade Level: Hero 2/6`

Should normalize to:

```lua
upgradeTrack = "Hero"
upgradeRank = 2
upgradeMaxRank = 6
```

The `2/6` value is the item's current upgrade rank and max upgrade rank.

This matters because the dashboard can say:
- Hero 2/6: upgrade available
- Hero 6/6: maxed for this track

## Midnight Gear Track Reference

| Track | Item Level Range | M+ Source |
|---|---:|---|
| Unranked | 207-220 | Not M+ focused |
| Adventurer | 220-230 | Not M+ focused |
| Veteran | 233-246 | M0 / early transition only |
| Champion | 246-259 | M+1-5 |
| Hero | 259-272 | M+6-9 |
| Myth | 272-289 | M+10+ / highest gearing |

Actual reward tables may vary by season. This file is a logic guide, not a source of truth for Blizzard tuning.

## Mythic+ Crest Brackets

| Crest | Currency ID | M+ Source |
|---|---:|---|
| Champion Dawncrest | 3343 | M0 / M+2-3 |
| Hero Dawncrest | 3345 | M+4-8 |
| Myth Dawncrest | 3347 | M+9+ |

If the player is already successfully running higher keys, do not recommend lower keys just because a slot is low.

Example:
- Character has a Champion neck
- Highest recent completed key is +14
- Dashboard should recommend the player's real M+ lane, not beginner content.

## Currency / Upgrade Signals

Track these where possible:

| KeyLab Name | Blizzard Name | ID | Type | Purpose |
|---|---|---:|---|---|
| championCrests | Champion Dawncrest | 3343 | Currency | Upgrade Champion-track gear / M+2-3 source signal |
| heroCrests | Hero Dawncrest | 3345 | Currency | Upgrade Hero-track gear / M+4-8 source signal |
| mythCrests | Myth Dawncrest | 3347 | Currency | Upgrade Myth-track gear / M+9+ source signal |
| catalystCharges | Dawnlight Manaflux | 3378 | Currency | Convert eligible items into tier |
| nebulousVoidcores | Nebulous Voidcore | 3418 | Currency | Reroll/source-related seasonal gear signal |
| ascendantVoidcore | Ascendant Voidcore | 268552 | Item | Upgrade eligible crafted weapons and max Hero/Myth trinkets to Ascendant Voidforged |
| radiantSparkDust | Radiant Spark Dust | 3212 | Currency | Spark/crafting progress |
| radiantJewelbinder | Radiant Jewelbinder | 263897 | Item | Vault vendor socket/jewel-related upgrade item |

## Ascendant Voidforged Logic

Ascendant Voidforged applies to:
1. Crafted weapons at Tier 5 max quality can be upgraded
2. Hero or Myth trinkets upgraded to max rank 6/6 can be upgraded 

### Crafted Weapon Detection

A crafted weapon candidate should have:

```lua
slotID = 16
craftedIndicatorVisible = true
```

Useful tooltip clues:
- `Quality: |A:Professions-Icon-Quality-Tier5-Small:26:26:0:-1|a`
- `Radiance Crafted`
- `Ascendant Voidforged`

### Trinket Detection

Trinket candidates:
- slotID 13
- slotID 14

Only check Hero/Myth trinkets that are max rank:

```lua
upgradeTrack = "Hero" or "Myth"
upgradeRank = 6
upgradeMaxRank = 6
```

Useful tooltip clue:
- `Ascendant Voidforged: Hero`
- `Ascendant Voidforged: Myth`

If eligible and not voidforged, show a Voidforge badge.

## Crafted Gear Logic

Crafted items are intentional gearing choices.

If a slot has a crafted item, do not mark it as bad just because a dungeon item exists.

Crafted weapons are especially important and can supersede normal dungeon target logic because the player chose:
- stats
- embellishment
- enchant
- upgrade path

| Crafted Type | Base ilvl | Upgrade Path | Approx Cap |
|---|---:|---|---:|
| Hero Craft | 259 | Hero Dawncrests | 272 |
| Myth Craft | 272 | Myth Dawncrests | 285 |

Sparks:
- weapons generally require 4 sparks
- most armor/jewelry crafts require 2 sparks

## Embellishment Logic

Tooltip clue:

`Unique-Equipped: Embellished (2)`

Normalize to:

```lua
embellishedDetected = true
```

Rules:
- Maximum 2 embellishments equipped.
- Crafted trinkets should not be expected to have embellishments.
- Crafted non-trinket items may have embellishments.
- Missing embellishment should only be flagged when the item/slot is expected to support it and the player's plan calls for it.

## Enchant Logic

Only check enchants on enchantable slots.

| Slot ID | Slot Name | Enchantable |
|---:|---|---|
| 1 | Head | Yes |
| 2 | Neck | No |
| 3 | Shoulder | Yes |
| 5 | Chest | Yes |
| 7 | Legs | Yes |
| 8 | Feet | Yes |
| 11 | Finger 1 | Yes |
| 12 | Finger 2 | Yes |
| 16 | Main Hand / Ranged | Yes |

Do not treat every slot as enchantable.

Use `enchantDetected = true` when available.

Tooltip notes:
- Real enchant lines should start with `Enchanted:`
- Illusory Adornments do not count as real enchants.

Missing enchant should produce a polish badge, not necessarily make the slot a priority upgrade.

## Gem Logic

Use `emptySocketCount`.

If `emptySocketCount > 0`, show a Gem polish badge.

Do not try to hardcode a universal list of gem-capable slots because Blizzard can add sockets to many item types.

Missing gems should produce a polish badge, not necessarily make the slot a priority upgrade.

## Tier Logic

Eligible tier slots:
- Head
- Shoulders
- Chest
- Hands
- Legs

Only 4 pieces are required for a 4-piece bonus.

Rules:
- If the player has fewer than 4 tier pieces, tier-eligible Hero/Myth pieces can show a Tier/Catalyst badge.
- Once the player has 4 tier pieces, stop marking remaining tier slots as priority purely for tier.
- After 4-piece is active, tier slots return to normal upgrade logic.
- If a Myth-tier piece drops in a tier slot, the player may want to catalyst it to restart/upgrade that tier slot at Myth level.

Catalyst currency:
- Dawnlight Manaflux, Currency ID 3378

## Gear Target Integration

Gear Targets are Mythic+ loot focused.

Use saved Gear Targets to show:
- target missing
- BIS target missing
- acquired
- dungeon/source hint
- slot still being chased

Saved targets should help identify where the player wants a replacement, but they should not override all upgrade logic.

A Myth item is progression complete even if it is not the exact target item.

It may show `BIS target missing`, but should not be treated as a weak slot.

## Item Card Badge Layout

Each item card should use compact badge sections instead of long sentence-style text.

Suggested badge/data sections:
- Track
- Item Level
- Upgrade Rank
- Tier
- Voidforge
- Gem
- Enchant
- Embellishment
- Target
- BIS
- Dungeon(s)

Because space is limited, combine polish badges where needed.

Examples:
- `Hero 3/6 | ilvl 263` / `Target: NPX` / `Needs: Gem / Enchant`
- `Myth 1/6 | ilvl 272` / `BIS Missing: SKY`
- `Crafted Hero` / `Needs: Voidforge / Enchant`

Avoid long repeated messages where possible.

## Upgrade Priority Slots

Rename from `Weakest Slots` to:

`Upgrade Priority Slots`

Reason: the dashboard is not showing shame/weakness. It is showing next meaningful upgrade opportunities.

### Base Score

| Condition | Score |
|---|---:|
| Missing item | +100 |
| Adventurer / Unranked | +80 |
| Veteran | +60 |
| Champion | +40 |
| Hero | +20 |
| Myth | +0 |

### Additional Modifiers

| Condition | Score |
|---|---:|
| Saved target item not acquired | +15 |
| Hero/Myth tier-capable slot missing tier and fewer than 4 tier pieces | +30 |
| Crafted item planned but missing | +10 |
| Missing enchant | +5 |
| Empty socket(s) | +5 |
| Missing embellishment when expected | +5 |
| Eligible for Ascendant Voidforge and not voidforged | +10 |

Polish issues such as enchant/gem should not always outrank real gear track upgrades unless scores make that happen intentionally.

## Myth Gear Rule

Myth-track gear is considered progression complete.

Do not place Myth-track gear in Upgrade Priority Slots only because it is not the player's exact target/BIS item.

Allowed:
- show `BIS Target Missing`
- show target dungeon/source
- show polish issues
- show voidforge/catalyst signal if applicable

Not allowed:
- mark Myth item as a weak slot just because it is not target gear
- recommend replacing Myth gear as a general priority

## Highest Value Activities

Simplify this section.

Do not show broad raid/delve/world-content recommendations as main activities.

Main logic:
- Use recent KeyLab Mythic+ history.
- Use current gear upgrade needs.
- Use crest needs.
- Use current key capability.
- Recommend the Mythic+ lane that matches the player's real progress.

Examples:
- Need Hero crests and recent M+4-8 completions: `M+ 4-8 for Hero Dawncrests`
- Need Myth crests and recent M+9+ completions: `M+ 9+ for Myth Dawncrests`
- Already completing +10 or higher: `Keep running your current M+ lane`

Do not insult experienced players by recommending low content solely because a slot is low.

## Activities / Progress Panel

This panel should show useful M+ and currency signals:
- current M+ lane
- highest completed key
- highest timed key
- needed crest type
- whether enough crests exist to upgrade something
- whether enough hero or myth crests exist to craft something
- catalyst charges available
- voidcore availability
- spark/crafted readiness
- target dungeon count

Possible messages:
- `Need Myth Dawncrests: run M+ 9+`
- `Hero item can still be upgraded`
- `4-piece tier complete`
- `Catalyst charge available`
- `Voidforge upgrade available`

## What Not To Do

Do not turn the dashboard into a general WoW gearing guide.

Do not display raw database tables.

Do not recommend raids/delves/world content as activities.

Do not rely only on tooltip `type` numbers.

Do not put gear scanning inside UI files.

Do not place scoring in mapping files.

Do not make Myth gear a priority upgrade just because it is not target gear.

## Summary

The Gear Dashboard v2 should be simpler:

1. Capture what the player is wearing.
2. Normalize track/rank/enchant/gem/crafted/tier/voidforge data.
3. Compare against Gear Targets.
4. Check Mythic+ history.
5. Check currencies.
6. Show compact item-card badges.
7. Recommend M+ lane and upgrades.

The goal is not to tell the player every place gear exists.

The goal is to answer:

> Based on my current character and my Mythic+ goals, what should I upgrade or run next?
