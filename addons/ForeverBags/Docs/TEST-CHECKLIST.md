# In-game beta test checklist

1. Character screen: addon appears and enables without dependency errors.
2. `/fb` opens the window; drag, close, reopen, `/reload` and position persists.
3. Inventory displays the same bag items/counts as Blizzard's bags.
4. Left-click/drag item pickup/move works; right-click usable items works; Shift-click works; test a stack split modifier if available.
5. Search updates while typing; test `q:rare`, `type:weapon`, `count:>1`.
6. Category buttons and each sort mode work.
7. Click the small star corner: left-click favorite, right-click tag; both persist through `/reload`.
8. Visit bank: bank view populates. Close bank and confirm cached bank view remains.
9. Log another character, open `/fb`, then return to the first and verify Alts ownership.
10. Loot a new item and verify Discoveries records it.
11. Visit merchant: Sell Junk button appears. Test with one grey item first.
12. `/fb settings`: scale/columns/item size/sectioned/empty-slot settings update live.
13. Press the existing normal bag key (usually `B`): ForeverBags should toggle without opening Blizzard bag frames.
14. Click the normal backpack button on the WoW action bar: ForeverBags should toggle. Equipped bag-slot buttons should remain available for normal bag management.
15. `/fb settings`: disable and re-enable "Use ForeverBags for WoW bag button + bag key" and verify native behavior returns/restores.
16. Repeatedly right-click consumables, drag items, Shift-click links and split stacks; confirm no "ForeverBags has been blocked" popup appears.
17. Reload during combat and after combat to watch for taint/protected-action errors.
18. If a Lua error occurs, enable `/console scriptErrors 1`, reproduce it and copy the full stack trace.
