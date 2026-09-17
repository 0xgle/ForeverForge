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
