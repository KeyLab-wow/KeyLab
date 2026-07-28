# KeyLab Changelog

## Version 1.8.101 - Main Window Artwork

Released July 28, 2026

- Added KeyLab's new dark blue and gold artwork as the main addon window background.
- Added the KeyLab key icon beside the live title in the header.
- Kept every panel, card, label, button, and tab as live UI above the artwork.

## Version 1.8.100 - Independent Activity Counts

Released July 27, 2026

- Changed the Home M+ Run and Raid Boss Pull totals into independent per-character season counters.
- Totals now continue increasing after Encounter history reaches its 50-record limit.
- Existing installs seed their starting totals from the records still available, while author screenshot data is ignored.
- Pruning or deleting an old Encounter record no longer lowers the Home activity totals.

## Version 1.8.99 - Practice Panel Spacing

Released July 27, 2026

- Added a consistent inner margin between the Practice panels and the tab's highlighted outer edge.
- Aligned New Session, Filters, Saved Practice Sessions, and Session Details to the same inset.

## Version 1.8.98 - Practice Details Room

Released July 27, 2026

- Limited each Saved Practice Sessions page to six sessions.
- Shortened the saved-session panel and moved its pager upward so Session Details remain comfortably visible.
- Kept the 25-session saved limit and all existing Practice records unchanged.

## Version 1.8.97 - Reserved Top 5 Layout

Released July 27, 2026

- Reserved space for all five leaderboard cards in Talent Builds, Stat Profiles, and Gear Profiles.
- Kept the matching open Encounter Details design beneath the complete Top 5 card area.

## Version 1.8.96 - Matching Profile Details

Released July 27, 2026

- Matched Talent Build and Stat Profile details to the open Encounter Details layout, including its size, padding, columns, dividers, fonts, and spacing.
- Matched Gear Profile details to the same open background treatment and footprint while preserving the equipped-item view.
- Standardized the details presentation without changing the saved leaderboard records.

## Version 1.8.95 - Profile Comparison Bars

Released July 27, 2026

- Added the colored comparison bar beneath each DPS or HPS value in Talent Builds, Stat Profiles, and Gear Profiles.
- DPS bars use blue and HPS bars use green while preserving the compact Encounter-style cards.

## Version 1.8.94 - Matching Profile Cards

Released July 27, 2026

- Matched Talent Build, Stat Profile, and Gear Profile cards to the compact size, fonts, colors, and borders used by Encounter cards.
- Matched the profile filter and details panels to the Encounter tab color scheme.
- Kept the restored DPS and HPS Performance Metric choice and full details views.
- Corrected the M+ Last Run content width so card borders are no longer clipped on the right.

## Version 1.8.93 - Restored Profile Comparisons

Released July 27, 2026

- Restored the DPS and HPS Performance Metric choice in Talent Builds, Stat Profiles, and Gear Profiles.
- Returned the Top 5 results to full-width, encounter-style selectable cards.
- Restored the detailed Run Details, Stats, Talent String, and Captured Outcomes view for Talent Builds and Stat Profiles.
- Restored the full equipped-item details view for Gear Profiles.
- Kept the permanent per-character and per-specialization season leaderboards unchanged.

## Version 1.8.92 - Consistent Tab Layout

Released July 27, 2026

- Added the same highlighted outer edge to every main tab window.
- Standardized tab title and description sizing across the addon.
- Evened out the spacing between tab descriptions, summaries, filters, and main content.
- Moved shared tab framing and header measurements into the UI theme so future tabs can match automatically.

## Version 1.8.91 - Season Journal Leaderboards

Released July 27, 2026

- Added permanent Top 5 DPS and Top 5 HPS leaderboards for Talent Builds, Stat Profiles, and Gear Profiles on both Mythic+ and Raid.
- Leaderboards are separate for each character and specialization. A lower result never replaces a better saved result.
- Kept up to 50 Mythic+ encounters and 50 raid boss pulls per character and specialization, with full pull details for the latest 10 of each.
- Added Performance Metric and High-to-Low or Low-to-High sorting to Mythic+ and Raid Encounters.
- Limited Practice to 25 sessions per character and specialization while keeping status-marked sessions first and protected.
- Removed automatic full-database release snapshots. Player Export and Import remain available for journal backups.
- Existing saved encounters seed the new leaderboards before the one-time storage cleanup runs.

## Version 1.8.90 - Focused Profile Comparisons

Released July 27, 2026

- Limited the Performance Metric choices in Talent Builds, Stat Profiles, and Gear Profiles to DPS and HPS.
- Applied the same focused choices to both Mythic+ and Raid comparisons.
- Existing saved metrics remain safely stored for encounter details and other analysis views.

## Version 1.8.89 - Reliable Capture Structure

Released July 27, 2026

- Restored one master Mythic+ run record as the shared source for Encounters, Last Run, Talent Builds, Stat Profiles, Gear Profiles, and Trends.
- Stopped the blank rolling combat session Blizzard starts after a completed dungeon from becoming an extra pull.
- Returned saved damage-meter fields to the metric mapping and removed unused raw per-pull source details from new records.
- Moved shared encounter and settings access out of the UI so capture, database, analysis, and display responsibilities stay separate.
- Older saved runs are read through the corrected pull and timer rules without changing or deleting their original records.

## Version 1.8.88 - Reliable Last Run Results

Released July 27, 2026

- Updated Mythic+ capture to Blizzard's current completion-result fields for accurate timed or untimed results, official duration, remaining or overtime, and key upgrades.
- Stopped using active-combat duration as a substitute for the official Mythic+ timer.
- Corrected zero-value player metrics so they are not mislabeled as missing data.
- Both Last Run graphs now use the same saved pull list and matching pull numbers.
- Last Run returns to the top when the tab opens or a different saved run is selected.
- Existing saved records remain unchanged; older records without official timing now show that timer data is unavailable instead of reporting a false result.

## Version 1.8.87 - Gear Target Source Label

Released July 27, 2026

- Changed the Gear Dashboard's Upgrade Source label back to Target Source.

## Version 1.8.86 - Seven-Day Run History

Released July 26, 2026

- Added a seven-day history selector to M+ Last Run and Last Raid.
- Saved entries are limited to the current character's active specialization and listed newest first.
- Added a Return to Latest button while reviewing an older run or raid session.
- Older saved records remain safely stored and are not changed by the new read-only history views.

## Version 1.8.85 - Empty Bag Slot Repair

Released July 26, 2026

- Fixed the saved gear shopping list stopping before it opened when Blizzard returned no item value for an empty bag slot.
- Bag-owned Hero and Myth Target notes now safely skip empty slots and continue building the popup.
- Added an empty-bag-slot runtime regression test for the Premade Group window.

## Version 1.8.84 - Reliable Premade Group Popup

Released July 26, 2026

- Removed the obsolete requirement for Blizzard to provide a specific group-result number before opening the shopping list.
- The saved gear shopping list now opens directly from Premade Group result hovers and result-list updates.
- Added a search-panel fallback so Midnight Dungeon and Raid browsing can open the list even when Blizzard skips a hover argument.

## Version 1.8.83 - Saved Gear Shopping List

Released July 26, 2026

- Replaced the hover-specific dungeon section with one centered saved gear shopping list.
- Targets are grouped by their saved Dungeon, Raid, or other source and displayed as Slot - Item Name.
- Added a limited selection of saved Alternatives without crowding out the main Targets.
- Hero- and Myth-track Targets found in bags now show their bag status on the same item line.
- Equipped Myth-track Targets remain safely saved but are left off the shopping list.

## Version 1.8.82 - Accurate Premade Group Matching

Released July 26, 2026

- Premade Group popups now trust Blizzard's official primary activity name before any additional listing information.
- Player-written group titles and tooltip text can no longer replace a valid dungeon or raid match.
- Removed the broad result-list refresh hook that could mistake an unrelated number for a group result.
- Equipped Myth-track Targets remain safely saved but are excluded from dungeon and raid browsing recommendations.

## Version 1.8.81 - Catalyst and Voidcore Guidance

Released July 26, 2026

- Items outside the master database now show as Catalyst items when they have an upgrade track, while items without a track remain Crafted.
- Nebulous and Ascendant Voidcore availability now appears only when the player owns the required currency or bag item and the equipped item is eligible.
- Hero items without an available Voidcore continue to show Upgrade to Myth because Raid and weekly Vault rewards remain valid upgrade paths.
- Added Dungeon and Raid slot guidance for Hero Tier and Catalyst items, plus Tier options in Premade Group popups until the 4-piece set is complete.
- Equipped Myth-track Targets are hidden from dungeon and raid browsing popups, while the full saved Target collection remains unchanged.
- Added the bag-only Ascendant Voidcore count to the Gear Dashboard currency card.

## Version 1.8.80 - Dungeon and Raid Target Popup

Released July 26, 2026

- Added saved Gear Targets to Premade Group raid listings as well as dungeon listings.
- Updated the popup to use the same current slot assignments counted by the Gear Dashboard.
- Separated Dungeon, Raid, and Other Saved Targets so owned bag items and other non-group sources are still included in the total.
- Existing Targets, Alternatives, and legacy backup records remain unchanged.

## Version 1.8.79 - Clearer Macro Sequencer Hover

Released July 26, 2026

- Made Macro Sequencer buttons easier to identify while hovering with a gold border, gold text, and brighter background.
- Improved hover feedback for Sequencer dropdowns and Information section headings.
- Pixel-aligned and joined Information card borders to remove uneven lower-edge shadows.
- Macro execution, sequence advancement, bindings, versions, and saved records remain unchanged.

## Version 1.8.78 - Gear Dashboard Currency Card

Released July 26, 2026

- Replaced the Gear Dashboard legend with a Crests & Seasonal Currency card.
- Added live balances for Adventurer, Veteran, Champion, Hero, and Myth Dawncrests.
- Added live balances for Nebulous Voidcore and Dawnlight Manaflux.
- Equipped gear, Tier progress, Targets, and Alternatives remain unchanged.

## Version 1.8.77 - Clearer Gear Target Filters

Released July 26, 2026

- Clarified how Stamina and primary-stat filters can be combined, and placed Stamina first.
- Improved Stat Goal Guidance wording and now calls empty gear positions unequipped slots.
- Added a Sort label to every item-table column and improved filter and button spacing.
- Gear matching, saved Targets, and saved Alternatives remain unchanged.

## Version 1.8.76 - Clearer Practice Comparisons

Released July 26, 2026

- Added friendly Macro Sequence version guidance so rotations can be tracked with saved Practice sessions.
- Replaced the Practice specialization filter with the character's current specialization and renamed Outcome to Performance Metric.
- Added Baseline, Testing, Candidate, Current Best, Needs Test, Archived, and Exclude session statuses.
- Older Practice statuses remain safely stored and continue under the closest matching new status.

## Version 1.8.75 - Clearer Raid Trends Metric Filter

Released July 26, 2026

- Renamed the Metric filter heading to Performance Metric in Raid Trends.
- The selected metric and Raid Trends calculations remain unchanged.
- All saved raid records remain safely stored.

## Version 1.8.74 - Current-Spec M+ Trends

Released July 26, 2026

- Replaced the specialization filter in M+ Trends with the character's current specialization.
- Available dungeon choices and trend calculations now stay focused on the specialization currently being played.
- Trends saved under other specializations remain safely stored and appear again when that specialization is active.

## Version 1.8.73 - Gear Profile Filter Spacing

Released July 26, 2026

- Increased the spacing between filter headings and dropdowns in both M+ and Raid Gear Profiles.
- Aligned the Current Spec heading and specialization name with the same spacing used in other analysis tabs.
- This is a layout-only update; all filters and saved Gear Profile records remain unchanged.

## Version 1.8.72 - Clearer Gear Profile Metric Filter

Released July 26, 2026

- Renamed the Outcome filter heading to Performance Metric in both M+ and Raid Gear Profiles.
- The selected metric and Gear Profile ranking behavior remain unchanged.
- All saved Gear Profile records remain safely stored.

## Version 1.8.71 - Gear Profile Item Level Cards

Released July 26, 2026

- Replaced the two-trinket summary on M+ and Raid Gear Profile list cards with Average Item Level.
- The selected profile details continue to show the complete equipped item list.
- This is a display-only update; all saved Gear Profile records remain unchanged.

## Version 1.8.70 - Current-Spec Gear Profiles

Released July 26, 2026

- Replaced the specialization filter in both M+ and Raid Gear Profiles with the character's current specialization.
- Available dungeon, boss, key, and difficulty filters now stay focused on the specialization currently being played.
- Gear Profiles saved under other specializations remain safely stored and appear again when that specialization is active.

## Version 1.8.69 - Public Release Cleanup

Released July 26, 2026

- Removed the temporary Author Access tab after screenshot work was completed.
- Author-only screenshot controls are no longer available in the player interface.
- No saved player records were changed or removed.

## Version 1.8.68 - Protected Screenshot Data

Released July 25, 2026

- Restored the passcode-protected Author Access tab for adding realistic M+ and Raid screenshot data.
- Removed Preview wording from generated dungeon, boss, pull, gear, talent, and status text.
- Generated records now carry a private marker and matching ID prefix.
- Remove buttons delete only records carrying both exact markers, leaving all normal saved data unchanged.

## Version 1.8.67 - Clearer Stat Profile Metric Filter

Released July 25, 2026

- Renamed the Outcome filter heading to Performance Metric in both M+ and Raid Stat Profiles.
- The selected metric and all filtering behavior remain unchanged.
- All saved Stat Profile records remain safely stored.

## Version 1.8.66 - Raid Stat Detail Colors

Released July 25, 2026

- Added distinct colors for Crit, Haste, Mastery, and Versatility in Raid Stat Profile details.
- Other captured stats keep the standard text color for a cleaner, easier-to-scan list.
- This is a display-only update; all saved raid records remain unchanged.

## Version 1.8.65 - M+ Stat Profile Dungeon and Key Filters

Released July 25, 2026

- Added a Dungeon / Zone filter to M+ Stat Profiles.
- Added a Key Level filter to M+ Stat Profiles.
- Stat priority comparisons now recalculate from the selected dungeon, key level, or both.
- Current Spec filtering remains active, and all saved records remain unchanged.

## Version 1.8.64 - Current-Spec Stat Profiles

Released July 25, 2026

- Replaced the specialization filter in both M+ and Raid Stat Profiles with the character's current specialization.
- Stat Profile results and available raid filters now stay focused on the specialization currently being played.
- Profiles saved under other specializations remain safely stored and appear again when that specialization is active.

## Version 1.8.63 - Cleaner Stat Profile Empty States

Released July 25, 2026

- Removed the repeated instruction beneath empty M+ and Raid Stat Profile results.
- Empty Stat Profile views now show one short message without repeating how to add results.

## Version 1.8.62 - Clearer Talent Build Metric Filter

Released July 25, 2026

- Renamed the Outcome filter heading to Performance Metric in both M+ and Raid Talent Builds.
- The new heading more clearly describes the result used to compare and rank saved talent builds.

## Version 1.8.61 - Cleaner Talent Build Empty States

Released July 25, 2026

- Removed the repeated instruction beneath empty M+ and Raid Talent Build results.
- Empty Talent Build views now show one short message without repeating how to add results.

## Version 1.8.60 - Saved Journal Protection

Released July 25, 2026

- KeyLab now saves a protected copy of the existing journal before a new release initializes or runs data migrations.
- Each release copy is created only once, so later reloads cannot overwrite that protected starting point.
- The newest three release copies are retained and include encounters, raid pulls, Practice sessions, sequencer libraries, gear records, settings, and other saved entries.
- Future updates will add fields and read older records without replacing established player history.

## Version 1.8.59 - Talent Build Name Safeguards

Released July 25, 2026

- Prevented a specialization name such as Beast Mastery from being mistaken for a player-named talent loadout.
- M+ and Raid Talent Builds now match the current specialization by its stable specialization ID first.
- Player-named loadouts still appear when available, with numbered Talent Variant labels kept for older builds whose names cannot be found.

## Version 1.8.58 - Player-Named Talent Builds

Released July 25, 2026

- M+ and Raid Talent Builds now use the loadout names players created in Talents & Spellbook.
- New runs and boss pulls save the active loadout name alongside the unchanged talent import string.
- Existing builds can use names from talent loadouts that are still saved on the character.
- Numbered Talent Variant labels remain as a safe fallback when an older loadout name is unavailable.

## Version 1.8.57 - Talent Build Stat Colors

Released July 25, 2026

- Added the established Crit, Haste, Mastery, and Versatility colors to the details section in M+ Talent Builds.
- Added the same stat colors to the details section in Raid Talent Builds.
- Talent Build stats now match the visual language used in Stat Profiles and Encounters.

## Version 1.8.56 - Current-Spec Talent Builds

Released July 25, 2026

- Replaced the specialization filter in both M+ Talent Builds and Raid Talent Builds with the character's current specialization.
- Talent build results and available dungeon, key, boss, and difficulty filters now stay focused on the specialization currently being played.
- Builds saved under other specializations remain safely stored and appear again when that specialization is active.

## Version 1.8.55 - Last Raid Wording

Released July 25, 2026

- Replaced the player-facing "raid night" wording in Last Raid with "raid session."
- Updated both the tab description and the message shown before a raid session has been saved.

## Version 1.8.54 - Missing Metric Markers

Released July 25, 2026

- Pulls with missing graph data now display an M marker beneath the pull number.
- Added an in-card key explaining that M means the metric data was not returned.

## Version 1.8.53 - Clearer Missing Pull Metrics

Released July 25, 2026

- Zero values now stay visible on Last Run pull graphs instead of blending into the graph border.
- Missing pull metrics now leave a clear gap instead of connecting across data Blizzard's Damage Meter did not return.
- Added a Last Run note that Blizzard's Damage Meter may not return every metric for every pull.

## Version 1.8.52 - Raid Pull Count on Home

Released July 25, 2026

- Added the current character's saved Raid Boss Pull count to the Home summary.
- Completed M+ runs and raid boss pulls are now easy to see together.

## Version 1.8.51 - Clearer Encounter Stats

Released July 25, 2026

- Added matching colors for Crit, Haste, Mastery, and Versatility in the M+ and Raid Encounter detail panels.
- Encounter stats now use the same familiar colors shown in Stat Profiles.

## Version 1.8.50 - Current-Spec Encounters

Released July 25, 2026

- Replaced the specialization filter on both M+ Encounters and Raid Encounters with the character's current specialization.
- Encounter history and available filters now stay focused on the specialization currently being played.
- Runs saved under other specializations remain safely stored and appear again when that specialization is active.

## Version 1.8.49 - Reliable Practice Stat Capture

Released July 24, 2026

- Practice sessions now safely fill missing stat values from the end-of-session snapshot while keeping valid start-of-session values unchanged.
- Existing end-of-session refreshes can recover a stat snapshot when WoW briefly withholds the values at session start.
- Sessions without saved stats now show **Not captured** instead of four empty stat values.

## Version 1.8.48 - Clearer Sequencer Introduction

Released July 23, 2026

- Clarified that players create a complete rotation by arranging individual macros into a sequence.

## Version 1.8.47 - Practice Setup Comparison

Released July 23, 2026

- Practice sessions now save and display the Spell Queue Window value used when the test began.
- Added colored Build A, Build B, and Build C-style labels for distinct captured talent builds.
- Added the talent-build label to both the saved session list and Session Details, making build changes easy to spot when the same sequence version was used.
- Older sessions remain available and show **Not captured** for setup details they did not save.

## Version 1.8.46 - Empty Stat Goal Guidance

Released July 23, 2026

- Added a clear prompt when all four Stat Goal Matcher percentages are still 0%.
- Individual stats may still use a 0% goal when at least one other stat has a percentage entered.
- Prevented an all-zero goal set from opening or running the matcher.

## Version 1.8.45 - Friendlier Player Text

Released July 23, 2026

- Rewrote player-facing explanations across Home, tabs, guides, prompts, matcher results, settings, and empty states in a shorter, friendlier voice.
- Renamed player-facing **KeyLab Action Sequencer** references to **KeyLab Macro Sequencer**.
- Simplified Gear Planning, Macro Sequencer Information, Insights, and Stat Goal Matcher guidance without changing how they work.
- Kept saved data, commands, filters, statuses, calculations, and addon behavior unchanged.

## Version 1.8.44 - Example Names and Read-Only Switching

Released July 22, 2026

- Renamed the built-in references to **Disc Priest DPS**, **BM Hunter DPS**, and **BM Hunter Pet Call Back**.
- Fixed read-only block and version selection being mistaken for unsaved macro editing.
- Reference examples now bypass save/discard prompts completely while remaining non-editable, unbound, and non-executable.

## Version 1.8.43 - Read-Only Sequencer Examples

Released July 22, 2026

- Added built-in DISC 4, BM PGUP, and BM 4 / Testing examples to the Sequence dropdown as clearly labeled read-only references.
- Kept reference examples outside every class/spec library, secure button, Binding List, Practice result, Recycle Bin, and SavedVariables record.
- Disabled editing, saving, copying, deleting, activating, resetting, and key or mouse binding while a reference example is displayed.
- Added mouse-wheel scrolling to the complete Sequence Blocks list, including wheel handoff from multiline block previews at their scroll limits.
- Left the proven secure execution engine unchanged.

## Version 1.8.42 - Multi-Sequence Practice Tracking

Released July 22, 2026

- Practice auto-detection now records every KeyLab sequence and active version used during a session, ordered by actual use.
- Saved session rows summarize additional sequences, while Session Details lists each detected sequence/version and its press count.
- Sessions where the player does not use KeyLab's sequencer now say **No KeyLab sequence used** instead of implying that something was forgotten.
- Manual sequence/version selection remains available as an override for controlled comparison tests.
- This is read-only practice reporting; the proven secure sequencer execution engine is unchanged.

## Version 1.8.41 - Automatic Practice Sequence Detection

Released July 22, 2026

- Changed the Practice sequence selector's default from **Not tracked** to **Auto-detect KeyLab use**.
- Added read-only practice snapshots of the secure sequencer counters so a completed session can identify the sequence and active version actually pressed during the test.
- When multiple KeyLab sequences are used, records the sequence with the most combat presses, then total presses, while retaining a count of additional sequences used.
- Preserved manual sequence/version selection as an explicit override.
- Left the golden secure click body, bindings, block cursor, resets, and advancement behavior unchanged.

## Version 1.8.40 - Non-Set Catalyst Targets

Released July 22, 2026

- Allowed owned Stat Goal Matcher results for Back, Wrist, Waist, and Feet to be saved as Gear Targets or Alternatives for Catalyst stat or appearance planning.
- Kept Head, Shoulders, Chest, Hands, and Legs as the only true Tier Set slots; non-set Catalyst Targets never count toward the 2-piece or 4-piece bonus.
- Preserved the name, item link, slot, source, upgrade track, rank, and item-level details of owned matcher items that are not present in the Master Item Database.
- Updated saved-target enrichment so these owned Catalyst Targets remain identifiable in Gear Targets and Gear Dashboard views after a reload.

## Version 1.8.39 - Matcher Results Presentation

Released July 22, 2026

- Rebuilt the Stat Goal Matcher Results window with KeyLab-themed summary cards instead of a single dense text report.
- Added aligned Current, Goal, Projected, and Result columns with clear color-coded goal differences.
- Separated chosen items into readable slot rows with track, item-level projection, and source details.
- Added a dedicated reduced-efficiency card that explains it evaluates the complete projected set through WoW's underlying rating conversion.
- Separated player guidance into numbered notes and retained the planning-estimate explanation in its own footer card.

## Version 1.8.38 - Owned Versatility Recognition

Released July 22, 2026

- Corrected Equipped + Bags item scanning to recognize WoW's plain `ITEM_MOD_VERSATILITY` stat key without requiring the word `RATING`.
- Retained the rating requirement for Crit, Haste, and Mastery so unrelated item fields cannot be mistaken for secondary rating.
- Added development regression checks for both plain and rating-form Versatility keys.
- Invalidated matcher results calculated without owned-item Versatility so the next run rebuilds projections, availability notes, chosen items, and reduced-efficiency results correctly.

## Version 1.8.37 - Matcher Results Popup Repair

Released July 22, 2026

- Corrected the results report text cleaner so it returns only the cleaned source name instead of also returning Lua's replacement count.
- Fixed the `table.insert` error that prevented the Stat Goal Matcher Results window from opening.
- Confirmed the popup opens only after a newly completed matcher run or an explicit **Results** click; loading or reloading the addon does not open it.

## Version 1.8.36 - Matcher Results Button Repair

Released July 22, 2026

- Kept the currently displayed completed matcher result directly available to the **Results** button.
- Raised the button above the green status card and explicitly registered its left-click action.
- Made the results popup anonymous so a partially created named frame cannot block a later reopening attempt.
- Replaced dynamic font-height measurement with a stable line-count layout for the scrollable report.
- Added visible KeyLab messages if no result is available or the results window encounters an opening error.

## Version 1.8.35 - Clear Matcher Results Access

Released July 22, 2026

- Shortened the completed Stat Goal Matcher summary so it fits inside the green status card without clipping.
- Added a visible **Results** button to reopen the complete matcher report.
- Added explicit report notices when a current stat is already above its goal or the chosen set projects above a goal.
- Retained the dedicated diminishing-returns/reduced-efficiency section for all four secondary stats.
- Invalidated the immediately preceding saved result so the expanded messages are populated by a fresh matcher run.

## Version 1.8.34 - Slot-Aware Stat Goal Matching

Released July 22, 2026

- Normalized Master Item Database candidates to a neutral per-slot comparison budget so captured tooltip item levels no longer bias the search.
- Preserved each item's secondary-stat identity, proportions, and relative reduced budget while keeping its original name, source, item level, and tooltip information for display.
- Made bounded searches slot-aware by considering available stats, remaining deficits, and what future open slots can still achieve.
- Projected equipped and bag items to the maximum of their identified owned upgrade track while retaining the live Character-panel percentages as **Current**.
- Kept detected gem and enchant secondary ratings at their present values instead of multiplying them with an item's upgrade projection.
- Changed Myth track, primary stat, stamina, and item level from absolute winners into close-result preferences after stat-goal fit.
- Added an automatic results window listing chosen items, Current/Goal/Projected percentages, upgrade assumptions, unreachable goals, unavailable open-slot stats, locked-stat conflicts, and projected reduced-efficiency notices.
- Added click-to-reopen behavior to the green matcher result card.
- Confirmed Crit, Haste, Mastery, and Versatility goals remain independent 0%–100% values and are not required to total 100%.
- Invalidated results from the previous scoring model so older matches cannot appear under the new calculation.
- Added a non-automatic development regression suite covering normalization, stat identity, owned-track projection, slot availability, softened Myth preference, and Exact/Bounded search agreement.

## Version 1.8.33 - Macro Editor Appearance Rollback

Released July 21, 2026

- Restored the Macro Sequencer editor implementation used before the clipboard experiment.
- Removed the standard input-box template that introduced an unwanted horizontal texture in the editor.
- Retained the visible gold insertion cursor and click-anywhere editing behavior.
- Retained the abandoned-binding recognition introduced in version 1.8.30.
- The proven secure execution engine and its golden backup remain unchanged.

## Version 1.8.32 - Mouse Text Selection Repair

Released July 21, 2026

- Restored native click-and-drag text selection throughout the Macro Sequencer editor.
- Removed the ScrollFrame mouse-release handler that could move the cursor and cancel a selection after dragging.
- Limited texture hiding to the standard input border so the gold selection highlight remains visible.
- The editor still fills the complete entry area, allowing players to click blank space to place the cursor.
- The proven secure execution engine and its golden backup remain unchanged.

## Version 1.8.31 - Macro Editor Clipboard Repair

Released July 21, 2026

- Restored native text selection, Copy, Cut, and Paste keyboard behavior in the Macro Sequencer editor.
- Retained the custom KeyLab editor appearance by hiding the standard input-box textures.
- Retained the visible gold insertion cursor and click-anywhere editing behavior.
- The proven secure execution engine and its golden backup remain unchanged.

## Version 1.8.30 - Abandoned Binding Recognition

Released July 21, 2026

- KeyLab now recognizes saved `CLICK` bindings whose addon-created target button no longer exists.
- Abandoned bindings left in WoW's account-wide binding file by an uninstalled addon no longer produce a misleading replacement confirmation.
- The same physical key can continue to be assigned independently in every KeyLab class/specialization collection.
- Active WoW actions and live addon buttons remain protected by the existing replacement confirmation.
- The proven secure execution engine and its golden backup remain unchanged.

## Version 1.8.29 - Action Sequencer Information Guide

Released July 21, 2026

- Rebuilt the Macro Sequencer **Information** page as a twelve-section expandable guide using the same plus/minus accordion design as Gear Planning.
- Introduced the full feature name **KeyLab Action Sequencer** within the guide while retaining **Macro Sequencer** in the main addon navigation.
- Added approachable guidance for one-press/one-step behavior, Action Blocks, sequence modes, versions, bindings, macro conditionals, Action/Nil, the Global Cooldown, combat restrictions, supported use, and the Recycle Bin.
- Removed the Development Edge Test panel, test-binding controls, test results, and related diagnostic editor actions from the public Sequencer interface.
- The proven secure execution engine and its golden backup remain unchanged.

## Version 1.8.28 - Optional Priority-Weighted Matching

Released July 21, 2026

- Added a **Matching Style** choice to the Stat Goal Matcher preparation window for both the Master Item Database and Equipped + Bags sources.
- **Balanced** retains the existing closest-total-percentage behavior.
- **Favor Priority** uses the player's #1 through #4 arrow order to place progressively more weight on unmet higher-priority Character-panel percentage goals.
- Once a stat reaches its goal, additional percentage receives only a light penalty so the matcher can continue filling lower-priority gaps rather than blindly stacking the first stat.
- Matching Style is remembered separately for each character specialization.
- Changing the priority order or Matching Style clears the previous result so it can be recalculated with the new preference.
- Owned matching retains Myth-track, primary-stat, stamina, and item-level priority in both styles.

## Version 1.8.27 - Character-Percentage Goal Matching

Released July 21, 2026

- Changed Stat Goal Matcher goals to represent the actual Crit, Haste, Mastery, and Versatility percentages shown on WoW's Character panel.
- The four goals are now independent and no longer need to total 100%.
- Candidate combinations are scored by projecting the completed set's Character-panel percentages with WoW's live combat-rating conversion for the current character and level.
- Currently worn tier, crafted, embellished, gemmed, enchanted, and other equipped contributions remain part of the calculation; open slots are filled toward the percentage gaps.
- **Equipped + Bags Only** uses the live stats of each owned item while retaining Myth-track, primary-stat, stamina, and item-level priority.
- Previous rating-share matcher results are automatically ignored so they cannot appear as current Character-percentage matches.

## Version 1.8.26 - Clear Current Stat Display

Released July 21, 2026

- Corrected the misleading **Now** values in Stat Goal Guidance so they display the same live percentages shown on WoW's Character panel.
- Added a separate **Share** value for each secondary stat. Share is the stat's portion of the character's total equipped secondary rating and remains the value compared with the saved 100% distribution goals.
- **Refresh Current Stats** now visibly refreshes both the Character-panel percentages and the equipped-rating shares.
- The Stat Goal Matcher calculation and its existing saved goals remain unchanged.

## Version 1.8.25 - Myth-First Owned Gear Matching

Released July 21, 2026

- Updated **Equipped + Bags Only** matching to prioritize owned Myth-track pieces before optimizing secondary-stat percentages.
- After Myth-track priority, owned combinations favor higher primary stat, stamina, and item level before comparing the saved secondary-stat goals.
- Master Item Database matching retains its existing secondary-stat behavior.

## Version 1.8.24 - Owned-Gear Stat Goal Matching

Released July 21, 2026

- Added an **Equipped + Bags Only** source option to the Stat Goal Matcher preparation popup.
- Owned-gear runs keep equipped items locked and fill intentionally unequipped slots using only equippable gear currently in that character's bags.
- Owned items use their live item-link secondary stats, including eligible items that are not present in KeyLab's Master Item Database.
- Selected owned matches can appear in the Gear Targets results list with **Bags** as their source.
- The existing Master Item Database search remains the default and retains its Dungeon/Raid scope options.

## Version 1.8.23 - Visible Macro Caret

Released July 21, 2026

- Added a dedicated solid gold insertion caret that follows the active cursor position in the multiline macro editor.
- The custom caret remains visible while the editor has focus even when the Retail client does not render its native EditBox cursor.
- The secure one-press, one-step execution engine remains unchanged.

## Version 1.8.22 - Macro Editor Focus Fix

Released July 21, 2026

- Restored normal cursor placement and typing inside the multiline macro editor.
- Added an explicit bright gold text cursor so the insertion point remains visible against the dark editor background.
- Blank-space clicks still focus the editor without overriding clicks made directly in the text.
- The secure one-press, one-step execution engine remains unchanged.

## Version 1.8.21 - Retail Macro Text Height Fix

Released July 21, 2026

- Fixed the remaining multiline macro editor Lua error caused by Retail EditBox objects not exposing a direct text-height method.
- Added a safe fallback height calculation for multiline and wrapped macro text.
- The secure one-press, one-step execution engine remains unchanged.

## Version 1.8.20 - Macro Editor Scroll Fix

Released July 21, 2026

- Fixed repeated Lua errors when opening the Macro Sequencer or editing a multiline macro block on Retail clients where the optional scroll-frame refresh method is unavailable.
- Preserved multiline resizing, cursor tracking, and click-anywhere editor focus behavior.
- The secure one-press, one-step execution engine remains unchanged.

## Version 1.8.19 — Gear Targets Stat Refresh

Released July 21, 2026

- Added a **Refresh Current Stats** button to Stat Goal Guidance.
- Refreshing now forces a new scan of all equipped secondary stats before recalculating the **Now**, **Below**, **At Goal**, and **Above** labels.
- Opening Gear Targets now forces a fresh equipment-stat scan instead of relying on an older cached snapshot.
- Equipment changes now receive a follow-up refresh after WoW finishes updating the new item data, preventing comparisons from remaining one change behind.

## Version 1.8.18 — Macro Sequencer Update

Released July 20, 2026

This release introduces KeyLab's new Macro Sequencer: a class- and specialization-specific sequence library built around the Retail-proven one-press, one-step secure execution engine.

### Macro Sequencer

- Added the new **Macro Sequencer** sidebar tab.
- Added separate **Editor**, **Binding List**, **Information**, and **Recycle Bin** views.
- Added class- and specialization-specific sequence collections.
- Added support for up to 50 sequences per specialization, 20 versions per sequence, and 50 macro blocks per version.
- Every newly created sequence now receives a ready-to-use **Version Default** automatically.
- Added sequence creation, copying, renaming, deletion, and recovery.
- Added version creation, duplication, renaming, deletion, and manual activation.
- Added **Sequential**, **Priority**, and **Reverse Priority** sequence modes.
- Added a manual **Reset Sequence** control.
- Sequences, versions, blocks, and bindings continue to use stable internal IDs, so renaming does not break their relationships.

### Multiline Macro Blocks

- Added a direct multiline WoW macro editor with an exact 255-character counter.
- Macro blocks preserve the player's entered text and line breaks.
- A single block may contain multiple supported `/cast`, `/use`, or `/castsequence` commands.
- Supporting commands may appear before or after primary actions.
- Added clear ready-to-add feedback: the **Add** button turns green when the block is valid.
- Clicking anywhere inside the macro entry area now places the editing cursor.
- Added line-specific validation messages for unsupported commands, conditions, targets, empty actions, and malformed brackets.
- Added support for normal comma-separated castsequences, including optional `reset=` rules.
- Retained support for the one-cast-per-target pattern: `/castsequence reset=target Action, nil`.
- Intentionally blocks `/run`, `/script`, `/dump`, and `/click`.

### Bindings

- Added direct keyboard and mouse-button binding capture.
- Added **Set**, **Edit**, and **Delete** binding controls.
- Added support for special keys such as Insert.
- Binding capture now appears above the KeyLab window.
- Added conflict detection for both KeyLab sequences and existing WoW/addon bindings.
- Binding conflicts clearly identify the key and current assignment before replacement.
- Added a dedicated Binding List showing binding, sequence, active version, and status.
- Viewing or switching between unchanged sequences no longer produces unnecessary save-or-discard prompts.

### Sequence Names and Recycle Bin

- Sequence names must now be unique within the current class/spec collection.
- Name comparisons ignore capitalization and leading or trailing spaces.
- Copies receive the next available name, such as `BM INS Copy`, `BM INS Copy 2`, and `BM INS Copy 3`.
- Restored name conflicts receive an available `Restored` name suggestion.
- The same sequence name may still be used by a different class or specialization.
- Fixed **Restore** and **Delete Forever** controls in the Recycle Bin.
- Deleted sequences and versions remain recoverable for 30 days unless permanently deleted.
- Restored sequences are returned unbound if their old binding is already in use.

### Practice Integration

- Added a **Sequence / Active Version** selector when starting a Practice session.
- Practice tracks the selected sequence and the version that was active when the session began.
- Saved sessions retain both stable IDs and the displayed sequence/version names.
- Added the recorded sequence version to the Saved Practice Sessions table.
- Added the recorded sequence version to Session Details.
- Added a **Not tracked** option for sessions that do not use a KeyLab sequence.
- Existing Practice sessions display **Not selected** and remain fully usable.
- Practice tracking records the selection only; it never activates or changes a sequence.

### Interface Improvements

- Redesigned the editor around the addon’s established dark blue and gold visual style.
- Replaced mismatched Blizzard-style Sequencer dropdowns with KeyLab-styled controls.
- Reorganized sequence creation, naming, binding, version, and block controls for a clearer workflow.
- Improved card borders, spacing, scrolling, selection highlights, and reorder controls.
- Updated the page and sidebar name from **Sequencer** to **Macro Sequencer**.
- Improved validation wording so valid text is no longer mistaken for an error before it is added.
- Kept the Binding List, Editor, and other internal views aligned to the same content area.

### Secure Execution Safeguards

- Preserved the exact Retail-tested secure execution engine without redesigning its advancement behavior.
- One complete physical keyboard or mouse press advances exactly one outer sequence step.
- WoW continues to decide whether individual macro commands execute successfully.
- Failed or unavailable actions still consume their predetermined outer sequence position.
- No timing, delays, polling, readiness detection, cooldown checks, proc checks, aura checks, resource checks, success detection, GCD management, SpellQueueWindow management, or automated inputs were added.
- Protected buttons, attributes, versions, and bindings remain restricted by combat lockdown.
- The four-pass diagnostic **Edge Test** remains available in the Information view.
- Preserved the exact Retail 12.0.7 build 68453 prototype as an immutable golden backup for regression comparison.

### Fixes

- Fixed a castsequence generation error caused by an invalid table insertion argument.
- Removed the retired one-primary-action-per-block restriction.
- Removed the retired rule that allowed only `/castsequence reset=target Action, nil`.
- Fixed misleading unsupported-macro feedback before adding a valid block.
- Fixed Insert-key bindings not being retained.
- Fixed unnecessary save/discard prompts when no sequence changes were made.
- Fixed Recycle Bin row buttons not acting on the selected deleted item.
- Fixed uneven Binding List card borders, spacing, and content height.
- Fixed Sequencer arrow controls displaying as unsupported rectangle glyphs.

### Development and Preview Data

- Expanded optional screenshot preview data with realistic Midnight Season 1 Mythic+ and raid performances, trends, and metrics.
- Used current dungeon and raid boss names without visible `[Preview]` prefixes on dungeon or boss labels.
- Removed the temporary passcode-protected Author Access tab after preview data was cleared.
