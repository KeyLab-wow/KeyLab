--[[
KeyLab Addon Architecture Guide

This file is documentation only.
Do not load this file in the TOC unless comments-only documentation files are desired.
Do not place runtime code here.

Folder responsibilities:

database/
- Static data only
- Season rules
- Gear tracks
- Currency IDs
- Loot tables
- Trinket fallback data
- No calculations
- No UI

mapping/
- Lookup relationships only
- Loot-to-spec mapping
- Slot mapping
- Stat mapping
- Dungeon mapping
- No scoring logic
- No UI

capture/
- Live WoW API reads only
- Equipped gear scans
- Player stats
- Currency counts
- Encounter capture
- Talent/stat snapshots
- No recommendations
- No UI layout

analysis/
- Decision logic
- Scoring
- Recommendations
- Gear priority calculations
- Item usefulness
- Stat goal guidance
- Activity suggestions
- No frame creation
- No raw static database tables

ui/
- Frames
- Buttons
- Tabs
- Layout
- Font strings
- Visual display only
- No database tables
- No scoring logic
- No direct gear scanning if capture/analysis helpers exist

utils/
- Generic helpers
- Formatting
- Colors
- Sorting
- Safe table helpers
- Tooltip helper functions
- No feature-specific business rules

Expected data flow:

capture/
    -> analysis/
        -> ui/

database/ and mapping/ feed analysis.

Examples:

Gear Dashboard:
capture/KeyLab_GearCapture.lua
    reads equipped gear, currencies, player stats

analysis/KeyLab_GearingAnalysis.lua
    calculates upgrade priority slots, activity guidance, tier/craft signals

ui/KeyLab_GearDashboard.lua
    displays the dashboard only

Gear Targets:
database/KeyLab_GearLootDatabase.lua
mapping/KeyLab_GearLootMapping.lua
analysis/KeyLab_ItemAnalysis.lua
ui/KeyLab_GearTargets.lua

Rules for future edits:

1. If fixing layout, edit ui/.
2. If fixing calculations, edit analysis/.
3. If fixing live WoW API reads, edit capture/.
4. If fixing static data, edit database/.
5. If fixing lookup relationships, edit mapping/.
6. If fixing formatting/helper reuse, edit utils/.

Do not move working logic between folders unless specifically requested.

Before changing code:
- Identify which layer owns the bug.
- Change the smallest number of files possible.
- Do not rewrite working systems while fixing a small issue.
]]
