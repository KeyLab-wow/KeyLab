# KeyLab gear-loot master database

The reviewed workbook is the source of truth. The addon database is a normalized runtime copy generated from the workbook's **Filtered Items** sheet.

## Counts and structure

- Included workbook rows: 5,986
- Unique items: 307
- Player specs: 40
- Loot sources: 12 (8 dungeons and 4 raids)
- `items[itemID]`: one canonical item record, plus its eligible specs and source-specific details
- `sources[sourceID]`: dungeon or raid identity; dungeon source IDs use `mapID`, raid source IDs use `instanceID`
- `bySpec[specID][sourceID]`: item IDs available to a spec from a source
- `statTextBySpec[itemID][specID]` and `statsBySpec[itemID][specID]`: spec-correct stats
- `dualWieldBySpec[itemID][specID]`: the workbook's authoritative Dual Wield eligibility, including Fury two-handed weapons
- `mnSeason`: Midnight season ownership at database, item, and source level

The exact 53-column header map lives in `mapping/KeyLab_GearLootColumnMapping.lua`. Future tabs can call:

```lua
local value = KeyLab.GearLootColumnMapping.GetValue(header, itemID, specID, sourceID)
```

`visibleIndex`, `index`, `captureIndex`, and `rowIndex` are audit coordinates. They intentionally remain workbook-only because they describe the probe capture process, not player-facing gear data. Every other column has a normalized runtime location.

## Regeneration

The reusable generator belongs at `DatabaseBuild/Scripts/build_keylab_gear_loot_database.mjs`. It validates the exact workbook header order and stops if the Season 2 workbook schema changes, preventing silent column drift.
