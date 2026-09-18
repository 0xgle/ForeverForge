# Classic Era test checklist

1. Open the Auction House: only ForeverMarket should be visible. Open bags, move
   the window, close with X/Escape, walk away from the NPC, and open it again.
2. Switch to Blizzard and back with `/fm`. Confirm there is only one visible panel
   and the session stays open. Disabling the addon restores the normal interface.
3. Search an item with over 50 auctions. Scroll to the bottom, change pages,
   and compare the unit price against the full-stack price.
4. Try name filtering, maximum price, sorting and exact-name matching.
5. Test buying and bidding on inexpensive items: cancel a confirmation first,
   then accept one. Verify the amount and quantity in your mailbox and activity log.
6. Add a watchlist item with Shift-click. Create two shopping groups, change
   quantities and limits, rename/delete an entry and search from a list.
7. Open Sell. Inventory should appear automatically. Select a cheap item and set
   5 items per stack, 2 stacks, and 1s per item: stack price should be 5s and total 10s.
   Check the deposit, minimum price and saved preset.
8. Post a cheap auction, find it in My auctions, select it and use Check price. Verify UNDERCUT/LOWEST-style status, then cancel it and check your mailbox.
9. On Sell, select an item and use Check + suggest. Verify the tab stays on Sell and the suggested unit price updates.
10. If a sold owner row is still present in the Classic owner cache, verify it appears as SOLD and its Cancel action is disabled.
   When posting multiple stacks, verify the actual number of auctions created.
9. Request a full scan. Buying from its results must be disabled until you search
   the item again. Subsequent scans must respect the server cooldown.
10. Relog and verify history, lists and presets. Test other characters, 1366x768,
    UI scaling and optional ForeverCore/ForeverBags integration.
11. Move stacks between bags: the list should update with the correct total.
    Check bound, quest and temporarily locked items.
12. Try selecting an item with an occupied cursor: the held item must be preserved.
13. Save a preset, select another item and return: the saved price should load.
    An item without history or a preset must not receive an invented price.
14. After posting, verify inventory quantities refresh. Cancelling confirmation
    must never post an auction.
15. Check every tab, help text and confirmations are English. Item names and
    game-generated messages should continue to follow the client locale. Confirm
    pre-existing user-created list names remain unchanged.

For errors, use `/console scriptErrors 1` and `/reload`. Record the full error,
`/fm debug` output, active tab and action. Use inexpensive items for transaction
tests: these are real operations involving your character's gold.

## 2.1 Flip & Empire checks

16. In Market, load an item with a meaningful local history and at least two price levels. Open **Flip Finder** and click **Analyze loaded**. Verify buy cost, exit plan, net profit, ROI and confidence are sensible and that an equal-price wall is not treated as an easy flip.
17. Add two inexpensive items to the watchlist with Shift-click and run **Watch scan**. The addon must respect the normal query throttle and keep partial results if Stop is pressed.
18. Click **Review** on a flip. ForeverMarket must refresh stale data before purchase; if the price no longer meets the configured filters it should warn you and must not silently keep the old profit claim.
19. Buy one inexpensive reviewed flip, then later sell it. In **Ledger > Empire**, switch the chart to **Flip profit** and verify realized profit appears only after a SOLD row is observed.
20. Log each test character once. In **Ledger > Empire**, confirm the account gold total and character rows reflect the latest seen gold for each character. Switch between **Net sales** and **Flip profit** charts.
21. Hover a tracked flip item and verify the tooltip shows tracked quantity and average flip cost.
