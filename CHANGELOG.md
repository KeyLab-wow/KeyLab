# KeyLab Changelog

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
