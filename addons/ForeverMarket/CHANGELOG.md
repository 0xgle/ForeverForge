# 2.2.1-beta1
- Reworked Market search layout for readability.
- Added persistent labels for category, subcategory, level and quality filters.
- Separated Auction House browse controls from local result filters.
- Increased vertical spacing around the results table.
- Corrected the runtime version shown in the footer.

# Changelog

## 2.2.0-beta1
- Added Auction House category and subcategory browsing to Market.
- Added minimum/maximum level filters, item quality filter and Usable-only toggle.
- Added Browse action for category-first searches with an empty item name.
- Category filters persist while paging through Auction House results.
- Compacted the market result rows to preserve the existing detail and paging layout.

# 2.1.0-beta1

- Added **Flip Finder** with configurable minimum ROI, minimum net profit, per-auction investment cap and history-sample requirement.
- Added **watchlist flip scan** plus analysis of the currently loaded Market results.
- Flip valuation includes the configured Auction House cut and caps the exit plan by local history and the next live competing price. Equal-price walls are rejected instead of being presented as easy flips.
- **Review** always uses a live auction row; stale scan results are refreshed before purchase. If the refreshed auction no longer meets the filters, it is shown for manual review without being tagged as a tracked flip.
- Purchases entered through Flip Finder are tagged as tracked flip inventory. Later SOLD rows are matched against their average cost basis to calculate realized flip profit.
- Added **Empire Ledger** with account-wide latest-gold snapshots for every character that has loaded the addon.
- Added 14-day in-game charts for **Net Sales** and **Realized Flip Profit** across all recorded characters/realms.
- Added per-character rows for current gold, 7-day net sales and 7-day realized flip profit.
- Added tracked flip cost information to item tooltips.
- Reworked the left navigation spacing so Flip Finder fits the existing ForeverForge visual system without overlapping utility panels.
- Extended the simulated Classic Era regression suite to **102 assertions**.

# 2.0.0-beta1

- Added **Trader Engine** with item Groups and per-group Auctioning Operations.
- Added custom local price expressions with `FMMarket`, `FMRecent`, `FMHistorical`, `FMMinBuyout`, `FMAvgBuy`, `FMAvgSell`, `FMVendorSell` and `FMCrafting`.
- Added `min()`, `max()` and `avg()` functions for price rules such as `max(80% FMMarket, 120% FMAvgBuy)`.
- Added live **Post Scan** and **Cancel Scan** plans; post results can be pushed into the Sell form for final review.
- Added **My Bids** using the Classic Era bidder list, including WINNING / OUTBID states.
- Added batch **Shopping Scan** with stored availability and best eligible price per shopping entry.
- Added **Forever Advisor** market signals from local price history and remembered inventory.
- Added **Ledger** for purchases, post/cancel actions, observed sold auctions, 1-day / 7-day / all-time summaries and average buy/sell sources.
- Added cross-character inventory snapshots for bags, bank and mailbox when those locations are visited.
- Added **Crafting Profit** memory for opened professions, reagent cost estimation, market value, craftable quantity and shopping-list generation.
- Preserved the Classic Era zero-argument owner/bidder query fixes and the `SOLD + count=0` owner-auction handling from 1.2.
- Extended the simulated Classic Era regression suite to **92 assertions**.

# 1.2.0-beta1

- **My Auctions 2.0:** select an auction and use **Check price** to compare it with current competing buyouts.
- Added owner-auction states: `UNDERCUT`, `MATCHED`, `LOWEST`, `ONLY YOU`, `BID ONLY`, `SOLD`, and `NOT CHECKED`.
- Added **Undercut only** filtering for checked owned auctions plus sold/undercut summary counts.
- Fixed Classic Era sold owner rows (`count = 0`, `saleStatus = 1`) being silently discarded.
- Sold auctions are shown in My Auctions and cannot be cancelled.
- **Sell:** **Check + suggest** now performs an exact market lookup without leaving the Sell tab and applies the suggested unit price.
- Sell panel now shows a fresh live lowest competitor and competing-auction count when available.
- Preserved all existing safety checks, confirmations, local price memory and Classic Era owner-list fixes.

# 1.1.2-beta1

- Fixed **My auctions** on Classic Era by calling `GetOwnerAuctionItems()` with the correct zero-argument signature.
- Removed fake owner-list server paging; owned auctions now use the loaded owner list plus the existing local scroll.
- Added a fallback owner-cache read when `AUCTION_OWNED_LIST_UPDATE` is delayed or omitted.
- Automatically refreshes owned auctions shortly after a successful post or cancellation.
- Improved loading/empty-state text for **My auctions**.

# 1.1.1-beta1

- English interface on every client locale: tabs, buttons, field labels, tooltips,
  confirmations, status messages, diagnostics and built-in activity log labels.
- English README, testing checklist and release notes.
- Preserved saved prices, presets, watchlists and user-created shopping list names.
- Reviewed English text in the existing layout; 67 simulated checks pass, including Classic Era owned-auction regression coverage.

# 1.1.0-beta1

- Replaced drag-and-drop selling with a clickable backpack/equipped-bag list.
- Automatic inventory refresh on bag, item-lock and item-cache updates.
- Exact-link grouping, quantity totals, name search and list paging.
- Exclusion of recognized bound, quest and bind-on-pickup items; locked-item labels.
- Fresh bag-slot resolution before selection and protection for an occupied cursor.
- Automatic preset loading or suggestions from existing price observations.
- Separate summary and posting confirmation; inventory scans never trade.

# 1.0.0-beta1

- ForeverBags/ForeverCore visual theme and one visible Auction House panel.
- Reversible switch to Blizzard, result scrolling, server pages, sorting and filters.
- Live-offer validation and confirmations for purchases, bids and cancellations.
- Native sell slot, deposits, unit prices, minimum prices and presets.
- Own auctions, named shopping lists, watchlist, price history and activity log.
- Realm/faction data separation and preservation of archived 0.9.0 prices.
- Bounded price history, fewer duplicate observations and local sorting.
- Legacy StartAuction and native PostAuction confirmation support.
- Optional ForeverCore launcher integration, price tooltips and diagnostics.
