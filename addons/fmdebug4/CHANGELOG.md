# ForeverMarket 2.4.0-debug4

- Diagnostic A/B: force whole-silver posting prices on WOW_PROJECT_MAINLINE.
- Modern AH silently rejects copper-valued listings on this client.
- No other posting-flow changes from debug3.

- Diagnostic build: removed all C_Item.LockItem/UnlockItem calls from the modern sell flow after runtime logs showed the selected auction item remained locked when PostCommodity was called.
- No other auction posting behavior changed from debug2.

## 2.4.0-debug4

- Fixed Debug.lua syntax error at the debug window logging toggle.
- No Auction House transaction logic changed from debug3; this build only makes the diagnostic harness load correctly.
- Scanned addon Lua sources for the same invalid method-reference pattern.

## 2.4.0-debug4
- Diagnostic build based on rc6; posting behaviour intentionally unchanged.
- Added `/fmdebug` live Auction House diagnostic window.
- Logs selected item, ItemLocation, commodity detection, throttle state, post counts, form values, PostItem/PostCommodity arguments and return value, native CachePendingPost availability, AH events, UI errors, bag updates and timeout snapshots.
- Use `/fmdebug clear` before reproducing one failed sale, then copy the full log.

# ForeverMarket 2.4.0-debug4

## 2.4.0-debug4 - Native AH context + direct posting path

- ForeverMarket now runs as a large child overlay of `AuctionHouseFrame` instead of a detached `UIParent` window.
- Blizzard AH is no longer alpha-hidden or mouse-disabled while ForeverMarket is active.
- Rebuilt modern Sell around the live bag `ItemLocation`, `GetAvailablePostCount`, `GetItemCommodityStatus`, and direct `PostItem` / `PostCommodity` calls.
- Uses Blizzard `CachePendingPost` only when the client explicitly requests native confirmation.
- No longer reports a post as successful merely because the Lua function returned; acceptance is verified by the bag slot/quantity changing.
- Added a clear failure status when the server silently rejects a post.


- Rebuilt modern AH query scheduling to send one queued request per Blizzard throttle-ready state.
- Restored server-ready gating before PostItem/PostCommodity to prevent silent posting failures.
- Sell is now fully independent from owned-auction loading.
- Added hard timeout for My Auctions so `Loading your auctions...` cannot remain forever.
- Removed automatic owned-auction query immediately after posting.
- Item commodity type is resolved before enabling Post, preventing commodity items from being sent through the normal-item posting API.
- Modern price normalization now respects Classic/Mists-style copper pricing when appropriate.
- Added explicit SERVER READY / SERVER BUSY state to the Sell summary.
- Protected post calls now surface Lua/API errors instead of silently leaving the UI unchanged.

# ForeverMarket Changelog

## 2.4.0-debug4 - Selling path rebuild

- Replaced ForeverMarket's custom modern post-confirm step with the client-native pending-post path used by WoW Forever: `PostItem` / `PostCommodity` followed by the matching `CachePendingPost` only when the client requests another confirmation.
- Removed direct `ConfirmPostItem` / `ConfirmPostCommodity` calls from ForeverMarket.
- Removed the query-throttle gate from protected posting actions; posting now runs directly from the user's confirmation click.
- Decoupled Sell from My Auctions refreshes. A submitted auction no longer leaves the main HUD stuck on `Loading your auctions...`.
- Owned-auction queries now have deterministic cache fallbacks and always clear their loading state, even when `OWNED_AUCTIONS_UPDATED` is delayed or omitted.
- Background owned-auction refreshes after posting are silent and cannot overwrite Sell status.
- Successful owned-auction reads now report either the loaded count or an explicit empty result.
- Kept the ForeverMarket UI, data model and module structure independent; the working addon was used only to validate WoW Forever's expected Auction House API flow.

## 2.4.0-rc2 - Modern purchase receipt fix

- Removed the blocking `Waiting for server confirmation` state from modern Buy/Bid flows.
- Modern item purchases now submit `PlaceBid` directly from the confirmation click and immediately release the UI.
- Commodity final confirmation no longer locks ForeverMarket if the client omits `COMMODITY_PURCHASE_SUCCEEDED`.
- Added short-lived error correlation for `UI_ERROR_MESSAGE` and optional success receipts without making those events mandatory.
- Successful/submitted purchases automatically refresh live market results instead of leaving the Deals screen frozen.
- Purchase errors are still shown immediately, while a missing receipt event is treated as a client limitation rather than a failed trade.

## 2.4.0-rc1 - Modern AH reliability rebuild

- Added a dedicated ForeverMarket Auction Service for WoW Forever's modern `C_AuctionHouse` backend.
- Added throttled query queuing instead of firing browse, owned-auction and exact-item requests directly at the server.
- Exact-item searches now wait for item-key cache readiness, validate `HasSearchResults` / full-result state and retry incomplete responses before exposing them to Buy or Sell.
- Rebuilt Deals/Market Buy so purchases always refresh the exact live item before any protected action is offered.
- Item purchases use the correct item-result sort shape and keep `PlaceBid` directly on the user's confirmation click path.
- Commodity purchases now follow the full live-search -> start purchase -> server price -> final confirmation -> confirm purchase sequence.
- Sell now performs an exact live market search for the selected item and applies a current suggestion before posting when no preset is saved.
- Posting, buying and cancelling protected actions are no longer deferred through query/timer callbacks after the user confirmation click.
- Corrected modern `PostItem` / `PostCommodity` return handling: the boolean indicates an additional native confirmation requirement, not a failed post.
- When the game requires an extra native post confirmation, ForeverMarket temporarily reveals the Blizzard Auction House and returns to the Sell view after server acceptance.
- Owned-auction refresh now uses the same throttle-aware transport as other modern AH queries.
- `/fm debug` now reports throttle readiness, queued queries and exact-item search state.
- No external Auction House addon is required.

## 2.3.4
- Fixed `Interaction Failed` when buying commodity deals on modern Auction House clients.
- Commodity purchases now load live commodity search results before starting a purchase, matching the required modern AH sequence.
- Added a two-step server price confirmation flow and clean cancellation/reset handling.
- `UI_ERROR_MESSAGE` now resets pending commodity purchases instead of leaving the Buy flow stuck.
- Corrected modern AH search ordering: commodity results use sort order `0`, item results use sort order `4`.

## 2.3.3 - Auction House bag auto-open fix

- Prevented external bag windows from covering the full ForeverMarket interface when opening an auctioneer.
- ForeverMarket now closes automatically opened Blizzard/third-party bag windows after the Auction House interaction starts.
- Inventory scanning remains fully functional in the background and the Sell view continues to use ForeverMarket's built-in bag item list.
- Bag suppression only runs while the ForeverMarket window is active; manually opened bags are not continuously forced closed.

## 2.3.2 - Full-window Auction House takeover

- ForeverMarket now opens as its own large top-level window instead of being scaled down inside the Blizzard Auction House frame.
- The native Auction House remains technically open but is visually concealed while ForeverMarket is active, preserving the live server session and modern `C_AuctionHouse` backend.
- Added safe native-frame restore when switching to Blizzard AH, closing the Auction House, entering combat or ending the auctioneer interaction.
- `/fm` reopens the full ForeverMarket window only while an Auction House session is active.
- Renamed the in-app return action to **Blizzard AH** for clarity.
- The ForeverMarket close button now closes through the native Auction House panel path instead of merely revealing the Blizzard UI.

## 2.3.1 - WoW Forever tooltip compatibility hotfix

- Fixed a login error caused by attempting to hook the removed `OnTooltipSetItem` frame script.
- Item price tooltips now use the modern `TooltipDataProcessor` item post-call API when available.
- Added a protected legacy tooltip fallback so unsupported tooltip scripts can never stop ForeverMarket from loading.
- No changes to the 2.3.0 modern Auction House backend or native Auction House integration.

## 2.3.0
- Added native WoW Forever Auction House integration: ForeverMarket now runs inside the active Auction House session instead of opening as an unrelated standalone market window.
- Added a dedicated ForeverMarket Auction House tab for clients using `AuctionHouseFrame`.
- Added automatic Auction House backend detection with modern `C_AuctionHouse` support and a legacy API fallback.
- Reworked market browsing for modern Auction House results, including live result paging, item-class filters, quality filters, exact-name filtering and local price-history analysis.
- Added modern purchase flows for item auctions and commodities with final user confirmation.
- Added modern owned-auction loading and cancellation through the active Auction House session.
- Added modern bag-to-sell selection, deposit calculation and posting through the native Auction House API.
- Preserved server-side confirmation flows when the client requires an additional native posting confirmation.
- `/fm` and the ForeverCore Marketplace launcher now select ForeverMarket inside an open Auction House; they no longer create a tradable Auction House away from an auctioneer.
- Added support for both Interface `16001` and `11509`.
- Kept defensive event registration so unavailable events cannot prevent the addon from loading.
- No external Auction House addon is required.

## 2.2.5
- Improved item-information compatibility on Forever clients where legacy global item APIs are unavailable.
- Added guarded item-cache loading and bound-item checks for inventory-first selling.
- Improved Marketplace startup stability and ForeverCore launcher compatibility.

## 2.2.2
- Added safe event registration so unavailable client events no longer prevent ForeverMarket from loading.
- Expanded Auction House result, owned-auction and transaction event compatibility.
- Added guarded result polling for clients that expose legacy query functions without every legacy result event.
- Improved owner/bid cache refreshes and sell-slot updates after inventory changes.

## 2.2.1
- Reworked Market search layout for readability.
- Added persistent labels for category, subcategory, level and quality filters.
- Separated Auction House browse controls from local result filters.
- Increased vertical spacing around the results table.
- Corrected the runtime version shown in the footer.

## 2.2.0
- Added Auction House category and subcategory browsing to Market.
- Added minimum/maximum level filters, item quality filter and Usable-only toggle.
- Added Browse action for category-first searches with an empty item name.
- Category filters persist while paging through Auction House results.
- Compacted the market result rows to preserve the existing detail and paging layout.

## 2.1.0

- Added **Flip Finder** with configurable minimum ROI, minimum net profit, per-auction investment cap and history-sample requirement.
- Added **watchlist flip scan** plus analysis of the currently loaded Market results.
- Flip valuation includes the configured Auction House cut and caps the exit plan by local history and the next live competing price. Equal-price walls are rejected instead of being presented as easy flips.
- **Review** always uses a live auction row; stale scan results are refreshed before purchase. If the refreshed auction no longer meets the filters, it is shown for manual review without being tagged as a tracked flip.
- Purchases entered through Flip Finder are tagged as tracked flip inventory. Later SOLD rows are matched against their average cost basis to calculate realized flip profit.
- Added **Empire Ledger** with account-wide latest-gold snapshots for every character that has loaded the addon.
- Added 14-day in-game charts for **Net Sales** and **Realized Flip Profit** across all recorded characters/realms.
- Added per-character rows for current gold, 7-day net sales and 7-day realized flip profit.
- Added tracked flip cost information to item tooltips.
- Reworked the left navigation spacing so Flip Finder fits the existing Forever visual system without overlapping utility panels.

## 2.0.0

- Added **Trader Engine** with item Groups and per-group Auctioning Operations.
- Added custom local price expressions with `FMMarket`, `FMRecent`, `FMHistorical`, `FMMinBuyout`, `FMAvgBuy`, `FMAvgSell`, `FMVendorSell` and `FMCrafting`.
- Added `min()`, `max()` and `avg()` functions for price rules such as `max(80% FMMarket, 120% FMAvgBuy)`.
- Added live **Post Scan** and **Cancel Scan** plans; post results can be pushed into the Sell form for final review.
- Added **My Bids** using the WoW Forever bidder list, including WINNING / OUTBID states.
- Added batch **Shopping Scan** with stored availability and best eligible price per shopping entry.
- Added **Forever Advisor** market signals from local price history and remembered inventory.
- Added **Ledger** for purchases, post/cancel actions, observed sold auctions, 1-day / 7-day / all-time summaries and average buy/sell sources.
- Added cross-character inventory snapshots for bags, bank and mailbox when those locations are visited.
- Added **Crafting Profit** memory for opened professions, reagent cost estimation, market value, craftable quantity and shopping-list generation.
- Preserved the WoW Forever zero-argument owner/bidder query fixes and the `SOLD + count=0` owner-auction handling from 1.2.

## 1.2.0

- **My Auctions 2.0:** select an auction and use **Check price** to compare it with current competing buyouts.
- Added owner-auction states: `UNDERCUT`, `MATCHED`, `LOWEST`, `ONLY YOU`, `BID ONLY`, `SOLD`, and `NOT CHECKED`.
- Added **Undercut only** filtering for checked owned auctions plus sold/undercut summary counts.
- Fixed WoW Forever sold owner rows (`count = 0`, `saleStatus = 1`) being silently discarded.
- Sold auctions are shown in My Auctions and cannot be cancelled.
- **Sell:** **Check + suggest** now performs an exact market lookup without leaving the Sell tab and applies the suggested unit price.
- Sell panel now shows a fresh live lowest competitor and competing-auction count when available.
- Preserved all existing safety checks, confirmations, local price memory and WoW Forever owner-list fixes.

## 1.1.2

- Fixed **My auctions** on WoW Forever by calling `GetOwnerAuctionItems()` with the correct zero-argument signature.
- Removed fake owner-list server paging; owned auctions now use the loaded owner list plus the existing local scroll.
- Added a fallback owner-cache read when `AUCTION_OWNED_LIST_UPDATE` is delayed or omitted.
- Automatically refreshes owned auctions shortly after a successful post or cancellation.
- Improved loading/empty-state text for **My auctions**.

## 1.1.1

- English interface on every client locale: tabs, buttons, field labels, tooltips,
  confirmations, status messages, diagnostics and built-in activity log labels.
- English README, release notes.
- Preserved saved prices, presets, watchlists and user-created shopping list names.

## 1.1.0

- Replaced drag-and-drop selling with a clickable backpack/equipped-bag list.
- Automatic inventory refresh on bag, item-lock and item-cache updates.
- Exact-link grouping, quantity totals, name search and list paging.
- Exclusion of recognized bound, quest and bind-on-pickup items; locked-item labels.
- Fresh bag-slot resolution before selection and protection for an occupied cursor.
- Automatic preset loading or suggestions from existing price observations.
- Separate summary and posting confirmation; inventory scans never trade.

## 1.0.0

- ForeverBags/ForeverCore visual theme and one visible Auction House panel.
- Reversible switch to Blizzard, result scrolling, server pages, sorting and filters.
- Live-offer validation and confirmations for purchases, bids and cancellations.
- Native sell slot, deposits, unit prices, minimum prices and presets.
- Own auctions, named shopping lists, watchlist, price history and activity log.
- Realm/faction data separation and preservation of archived 0.9.0 prices.
- Bounded price history, fewer duplicate observations and local sorting.
- Legacy StartAuction and native PostAuction confirmation support.
- Optional ForeverCore launcher integration, price tooltips and diagnostics.
