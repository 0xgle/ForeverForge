# Visual update: 0.9.5-beta1

## Completed offline

- Parsed every Lua source file using Lua 5.1.
- Constructed main and settings frames in a mocked UI runtime.
- Checked category counts, search, empty results, favorites, bank and merchant views.
- Checked active and hover styling and object reuse across repeated refreshes.
- Checked native slot attachment and that decorative hover frames cannot receive mouse input.
- Compared native slot construction, item binding/click handlers, merchant logic, data and database modules against 0.9.4-beta3.
- Inspected an offline layout rendering; this is not a screenshot from WoW.

## Required in Classic Era

1. Exit WoW; back up the existing ForeverBags addon folder, then replace it with this package.
2. Keep `WTF` / SavedVariables untouched. Start the game, open `/fb`, check `/fb version`.
3. Check the title, background, left categories and item icons at your usual UI scale.
4. Hover items: actual icons must remain visible. Check tooltips and stack counts.
5. Test left/right click, drag, shift-click and stack splitting with low-value items.
6. Open via backpack button and existing bag shortcut; test closing with Escape.
7. Search, switch categories, view bank cache and alternate characters.
8. At a merchant verify the footer, stats and Sell Junk button do not overlap. Review sale behavior using expendable junk only.
9. Try icon sizes 34–54 and UI scales 0.75–1.35. Scroll a full inventory and verify contents remain within the scroll area.
10. Check settings credits, reload persistence and combat behavior before wider distribution.

The offline runtime cannot validate Blizzard secure execution, real font metrics, GPU texture rendering or client-specific behavior.
