# ForeverMarket 2.4.0-debug7

Diagnostic build for WoW Forever Auction House posting. This build intentionally keeps the rc6 posting behaviour and adds detailed instrumentation only.

## Debug procedure
1. Open the Auction House.
2. Type `/fmdebug clear`.
3. Select one cheap item in Sell.
4. Click Post and confirm once.
5. Wait 3 seconds.
6. Type `/fmdebug`, click **Snapshot**, then **Select all**, press **Ctrl+C**, and paste the log into ChatGPT.

---

# ForeverMarket

**2.4.0-debug7 · by 0xgle · WoW Forever · Interface 16001 / 11509**

ForeverMarket is an Auction House addon for the Forever suite with market search,
inventory-first selling, owned-auction management, shopping lists, local price
history, Trader Engine, Flip Finder and Empire analytics.

ForeverMarket is standalone. No other Auction House addon is required.

## Installation

1. Close WoW Forever.
2. Remove the previous `ForeverMarket` folder from `Interface/AddOns/`.
3. Copy the `ForeverMarket` folder from this ZIP into `Interface/AddOns/`.
4. Confirm the final path is `Interface/AddOns/ForeverMarket/ForeverMarket.toc`.
5. Start WoW Forever and enable ForeverMarket.

Keep your `WTF` folder if you want to preserve saved prices, presets, shopping
lists, watchlists and settings.

## Auction House integration

ForeverMarket now takes over the Auction House visually while keeping the real
Blizzard Auction House session open in the background.

Talk to an auctioneer and open the Auction House. ForeverMarket opens as its own
large top-level window instead of being squeezed inside `AuctionHouseFrame`. The
native frame stays technically open but invisible so `C_AuctionHouse` remains
connected to the live server session. A legacy backend remains available for
compatible legacy Auction House clients.

`/fm` and the ForeverCore Marketplace launcher open ForeverMarket only when an
Auction House session is active. They do not create a tradable Auction House away
from an auctioneer.

Use **Blizzard AH** or `/fm blizzard` to reveal the standard Blizzard interface
without closing the session. The ForeverMarket close button closes the Auction
House panel/session through the native UI path.

## Modern Auction House reliability

The modern backend uses a dedicated request service instead of issuing exact-item
queries directly from individual UI modules. It waits for the Auction House
throttle, resolves item-key data, validates that search results are complete and
retries incomplete responses before Buy or Sell can act on them.

For item purchases, ForeverMarket refreshes the exact auction list and then keeps
the final `PlaceBid` call on the user's confirmation click. Commodity purchases
use the server's staged purchase flow: live search, start purchase, server price
update and final confirmation. Posting and cancellation are handled the same way:
server queries may be queued, but protected actions remain user initiated.

If WoW Forever requests an additional posting confirmation, ForeverMarket uses
its own second confirmation when the client exposes the modern confirm API. The
Blizzard confirmation path is kept only as a compatibility fallback.

## Core features

- **Market:** live item search, category/subcategory filtering, level and quality
  filters, local result filtering, sorting and price-history comparison.
- **Modern Auction House browsing:** receives native browse-result batches and
  requests additional results until the current search is complete.
- **Buy:** item auctions and commodities use the native Auction House purchase
  flow and require a final user confirmation.
- **Sell:** select items directly from the ForeverMarket bag list, review price,
  quantity, duration and deposit, then confirm posting.
- **My auctions:** load owned auctions, show sold/active state, compare current
  market pricing and cancel eligible auctions with confirmation.
- **Deals:** compare current prices against your own locally collected history.
- **Watchlist and Shopping:** keep items and shopping targets between sessions.
- **Trader Engine:** groups, pricing rules and reviewable post/cancel plans.
- **Flip Finder:** evaluates loaded offers against local price observations and
  configured fees before presenting candidates for review.
- **Ledger / Empire:** local transaction records, inventory snapshots and
  account-wide character summaries.
- **Crafting:** remembered crafting data and local reagent/value estimates.
- **ForeverCore:** optional launcher/settings integration through API v1.

All transactions remain user initiated. ForeverMarket does not perform unattended
buying, posting, cancelling or mail collection.

## Selling

Open the **Sell** tab and click an eligible item from the bag list. ForeverMarket
uses the item's real bag location for the active Auction House API.

Review the unit price, quantity, duration and deposit before clicking **Post auction**.
Modern retail-style Auction House builds reject posting prices with unsupported
copper precision, so ForeverMarket normalizes sell prices to a server-valid tick
before posting. If the client requires an additional post confirmation, the
confirmation remains user initiated.

Recognized bound, quest and otherwise ineligible items are excluded where the
client exposes enough information to identify them. Final eligibility is always
decided by the game server.

## Price data

ForeverMarket stores its own local observations. Price history is separated by
realm and faction. It represents observed asking prices, not guaranteed completed
sale prices.

Deals, Advisor, Flip Finder and pricing rules are analytical tools based on your
local observations. They do not guarantee future prices or profit.

## Commands

| Command | Action |
| --- | --- |
| `/fm` | Open the full ForeverMarket window during an active Auction House session |
| `/fm settings` | Open ForeverMarket directly on Settings during an active Auction House session |
| `/fm blizzard` | Return to the standard Blizzard Auction House |
| `/fm scan` | Start a market scan using the active Auction House backend |
| `/fm reset` | Reset the saved ForeverMarket window position |
| `/fm debug` | Print build, detected Auction House backend, session state and last error |

## Compatibility

ForeverMarket 2.4.0-debug7 detects the Auction House implementation at runtime:

- **Modern:** `C_AuctionHouse` + `AuctionHouseFrame`
- **Legacy fallback:** `QueryAuctionItems` + legacy auction functions

The release TOC declares Interface `16001` and `11509` for the current WoW Forever
client families used by this project.

Some modern Auction House clients do not expose a separate bidder-list API.
On those clients, bidding is handled through current market offers rather than a
standalone My Bids list.

## Release contents

The release ZIP contains the runtime addon, media assets, README and changelog.
Development scripts and local build helpers are not included.

Copyright 2026 0xgle. All rights reserved.
