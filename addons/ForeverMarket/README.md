# ForeverMarket

**1.1.2-beta1 · by 0xgle · Classic Era 1.15.9 / Interface 11509**

An English-language Auction House addon for the ForeverForge suite, with market
search, inventory-first selling, shopping lists and local price history.
Its workflow is inspired by Auctionator and TradeSkillMaster, with an original
implementation. Neither addon is required. This is not full TSM feature parity.

## Installation

1. Close WoW and keep a backup of your previous ForeverMarket folder.
2. Replace `ForeverMarket` in
   `World of Warcraft/_classic_era_/Interface/AddOns/` with the folder in this ZIP.
3. Confirm the final path is `AddOns/ForeverMarket/ForeverMarket.toc`.
4. Start the game and enable ForeverMarket. For a newer Classic Era interface
   number, enable **Load out of date AddOns** if needed.
5. Visit an auctioneer. ForeverMarket opens as the only visible Auction House
   panel. Use `/fm` to open shopping lists and history away from an auctioneer.

Keep your WTF folder. Saved prices, shopping lists, presets and settings remain
intact. Version 0.9.0 prices lacked realm/faction information, so they are retained
under `legacy` in SavedVariables rather than mixed into a new realm's history.
Your watchlist is carried forward.

Disable other Auction House replacements during testing. ForeverBags and
ForeverCore can stay enabled. ForeverCore is optional.

## Selling from your bags

Open **Sell**. Your backpack and four equipped bags appear on the left; the auction
form is on the right. Click an item to prepare it. A saved price preset is loaded
automatically, or a price is suggested from available local observations.

Check the unit price, stack size, stack count and duration, then click **Post auction**
and confirm. Selecting an item never posts it. If no price data is available, enter
a price or use **Check market**; the addon does not invent a valuation.

The list refreshes when bags change. Identical item links are grouped with their
combined quantity, while different variants remain separate. Search and paging
work across the list. The quantity shown in the list is your inventory total;
the form and confirmation determine how many items will actually be posted.

Recognized bound, quest, bind-on-pickup and loot-containing items are excluded.
Locked stacks are marked. Final auction eligibility is decided by the game.
Scanning only reads your bags; it does not move items or execute transactions.
Put down any item on your cursor before selecting another item. Bank storage and
equipped gear are not scanned.

## Features

- **Market:** name and exact-name search, server pages, scrolling through all
  results on a page, sortable columns, name filter, maximum unit price and buyout filter.
- **Buy and bid:** a total-cost confirmation, a fresh comparison against the live
  auction before submitting, and checks against own or outdated auctions.
- **Deals:** configurable threshold compared with local history or the median of
  loaded results. Tooltips identify the reference source; discounts do not guarantee profit.
- **Full scans:** requested only when the server permits them. A first-page query
  is never presented as a full scan. Search a scanned item again before buying.
- **Sell:** price per item, stack quantities, 12/24/48-hour durations, deposit and
  estimated proceeds after your configured fee. Starting bid equals buyout.
- **Price suggestions:** lowest other-seller price in recent results, or the latest
  historical minimum; the status message identifies the source and its age.
- **Item presets:** unit price, minimum price, stack size and duration.
- **My auctions:** refresh, paging and cancellation with confirmation.
- **Watchlist:** Shift-click a market row. Watched items remain available between searches.
- **Shopping lists:** named groups, desired quantities and unit price limits,
  editing/removal, and manually initiated searches.
- **Price history:** separated by realm and faction, with one observation per
  item/query, at most 90 observations per item and 2,500 items. Observations within
  a minute are combined. Random-suffix variants have separate price keys.
- **Tooltips:** local median unit price, data age and sample count.
- **Activity log:** the latest 200 requests distinguish submission, server acceptance,
  errors and missing confirmation. This is not a ledger of actual mailbox receipts.
- **Settings:** undercut amount, deal threshold, fee, scale and automatic opening.
- **ForeverCore:** optional launcher and settings integration through API v1.

## Appearance and language

The frame and icons use the author's ForeverBags/ForeverForge artwork. Actual item
icons come from WoW. Drag the header to move the window; position and scale are saved.

All addon-owned labels, tooltips, status messages and confirmations are English on
all client locales. Item names, game-generated errors and game confirmation dialogs
follow the WoW client language. User-created names and saved list contents are preserved.
Older built-in activity log labels are displayed in English without rewriting history.

## One visible Auction House panel

ForeverMarket parks the Blizzard panel off-screen while preserving the Auction
House session and its native handlers. **Blizzard** restores the standard panel
without closing the session. `/fm` switches back. Closing ForeverMarket while it
owns the Auction House view also closes that session.

## Commands

| Command | Action |
| --- | --- |
| `/fm` | Toggle ForeverMarket |
| `/fm settings` | Open settings |
| `/fm blizzard` | Restore the Blizzard interface |
| `/fm scan` | Request a full scan |
| `/fm reset` | Center the window without deleting data |
| `/fm debug` | Print client/API/session diagnostics and the last error |

## Compatibility and limitations

Target: **Classic Era**, Interface 11509. WoW Forever/Mainline clients with a
different auction API, including `C_AuctionHouse`, require a separate adapter.
This package leaves trading to Blizzard when the legacy API is unavailable.

Filters and Deals cover loaded results, not the entire server without a scan.
History tracks asking prices, not completed sale prices. Queries and full scans
are subject to server limits.

For a neutral Auction House, manually set the fee to 15% instead of 5%.
Neutral markets are not detected automatically; history is separated by realm
and faction, not by auctioneer. Avoid mixing neutral and faction scans if you
need separate valuations.

Shopping quantities are a plan, not an automatic order. This build does not
include crafting, TSM operations, desktop-app data, automated mail collection,
automatic reposting or realized-profit accounting. Every transaction requires
a click and confirmation. The server may still reject an auction that disappears
between confirmation and processing.

## Verification

The existing 63-assertion simulated-API suite passes with the English interface.
It covers loading, every panel, switching interfaces, stale offers, query limits,
unit/stack pricing, confirmations, data migration and inventory-first selling.
Frame-model renders were reviewed for layout. These checks are not live WoW tests.

Use `TESTING.md` before publishing. `DeveloperTools` contains the test harness and
simulated previews; only the `ForeverMarket` folder belongs in AddOns.

Copyright 2026 0xgle. All rights reserved.
