**# ForeverForge

**A unified World of Warcraft addon ecosystem by [0xgle](https://github.com/0xgle).**

ForeverForge is a growing collection of original World of Warcraft addons designed to work independently or together as one consistent suite.

The project focuses on powerful quality-of-life tools, clean workflows, shared visual language and deeper gameplay intelligence without unattended gameplay automation.

> Built for players who want more information, better tools and less interface clutter.

---

## The Forever Suite

| Addon                  | Version       | Purpose                                                                       |
| ---------------------- | ------------- | ----------------------------------------------------------------------------- |
| **ForeverCore**        | `1.0.0-rc1`   | Central addon manager, profiles, diagnostics and Forever Suite hub            |
| **ForeverBags**        | `0.9.5-beta2` | Modern inventory replacement with search, categories, tags and merchant tools |
| **ForeverChat**        | `0.3.0-beta1` | Chat HUD, communication tools and LFG intelligence                            |
| **ForeverGather**      | `3.0.0-rc1`   | Gathering journal, resource atlas, analytics and smart routes                 |
| **ForeverMacroHelper** | `0.1.0-beta`  | Curated PvE/PvP macro library for every Classic class                         |
| **ForeverMarket**      | `2.0.0-beta1` | Auction House, trading, price intelligence, ledger and Trader Engine          |

All addons live under:

```text
addons/
```

---

# ForeverCore

### The command center of ForeverForge.

ForeverCore connects the suite through a shared management layer while keeping every addon independently installable.

Features include:

* Forever addon discovery
* Addon manager
* Dependency-aware enable / disable plans
* Account-wide addon profiles
* Profile import / export
* Favorites and search
* Diagnostics
* Memory information
* Activity history
* Core-only mode
* Shared launcher
* Minimap integration
* Forever module API
* Shared design language

Open it with:

```text
/fc
```

Source:

[`addons/ForeverCore`](addons/ForeverCore)

---

# ForeverBags

A modern inventory interface designed to make large inventories easier to understand and manage while preserving native WoW item interaction.

Highlights:

* Unified inventory
* Category sidebar
* Powerful search engine
* Item quality filters
* Favorites
* Custom item tags
* `Keep`, `Sell` and `Bank` states
* New-item tracking
* Character gold display
* Bank view
* Merchant integration
* Sell Junk
* Native drag, use and stack interaction
* Blizzard backpack button integration
* Existing bag-key integration

Power-search examples:

```text
q:epic
type:weapon
count:>=5
ilvl:>40
fav:true
new:true
tag:keep
id:12345
```

Open it with:

```text
/fb
```

Source:

[`addons/ForeverBags`](addons/ForeverBags)

---

# ForeverMarket

A powerful Auction House and trading toolkit combining an approachable workflow with more advanced market tools.

The long-term goal is simple:

> **TSM-style power without requiring a spreadsheet degree.**

Highlights:

* Auction House replacement
* Market search
* Inventory-first selling
* Buy and bid confirmations
* Local price history
* Deal detection
* Watchlists
* Shopping lists
* My Auctions
* Undercut detection
* My Bids
* Shopping Scan
* Groups
* Auctioning Operations
* Min / Normal / Max price rules
* Price expressions
* Post plans
* Cancel plans
* Trader Engine
* Market Advisor
* Inventory memory
* Crafting Profit
* Purchase and sale ledger
* Daily / weekly / all-time trading summaries

ForeverMarket uses local observations and explicitly avoids pretending uncertain market data is guaranteed profit.

Every transaction still requires player interaction.

Open it with:

```text
/fm
```

Source:

[`addons/ForeverMarket`](addons/ForeverMarket)

---

# ForeverGather

A gathering intelligence and expedition system for players who want more than static map pins.

Highlights:

* Mining location learning
* Herbalism location learning
* Skinning tracking
* Resource journal
* Resource atlas
* Gathering analytics
* Confidence tracking
* Minimap markers
* World Map integration
* Smart Routes
* Route optimization
* NEXT-node navigation
* Off-screen direction guidance
* Compact gathering HUD
* GatherMate2 data import
* TomTom integration
* Local-first data storage

ForeverGather learns from successful gathering actions instead of blindly filling your map with generated data.

Source:

[`addons/ForeverGather`](addons/ForeverGather)

---

# ForeverChat

A communication-focused HUD designed around a cleaner Classic experience.

Current direction includes:

* Custom chat presentation
* Communication intelligence
* LFG Radar
* ForeverForge visual integration
* ForeverCore integration
* Compact information-first interface

Source:

[`addons/ForeverChat`](addons/ForeverChat)

---

# ForeverMacroHelper

A curated macro library for Classic players.

Highlights:

* Macros for every class
* PvE macros
* PvP macros
* Searchable macro library
* One-click macro creation
* English localization
* Polish localization
* ForeverForge interface
* Saved configuration

Source:

[`addons/ForeverMacroHelper`](addons/ForeverMacroHelper)

---

# One ecosystem

ForeverForge is not intended to become a random collection of unrelated addons.

Every project follows the same principles:

### Consistent design

Shared dark fantasy / arcane visual language with interfaces designed to feel like parts of the same product.

### Modular architecture

Use one addon or the entire suite.

ForeverCore improves the experience but individual addons remain independently installable wherever possible.

### Local-first intelligence

Market data, gathering discoveries, profiles and other learned information are primarily stored locally.

### Player control

ForeverForge provides information, interfaces and recommendations.

It does not aim to play the game for you.

### Performance

The addons are designed around event-driven systems instead of unnecessary always-running update loops wherever possible.

### Original implementation

ForeverForge addons are independently developed.

Other popular addons may inspire workflows or usability ideas, but their source code is not required or bundled.

---

# Compatibility

Current development primarily targets:

```text
World of Warcraft Classic Era
Interface: 11509
```

Several addons are currently being developed and tested with future **World of Warcraft: Forever** compatibility in mind.

WoW: Forever is evolving, so API behavior and compatibility may change.

A matching `.toc` interface number does not by itself guarantee that every feature is compatible with another WoW client.

---

# Installation

Download or clone ForeverForge:

```bash
git clone https://github.com/0xgle/ForeverForge.git
```

Choose the addon you want from:

```text
ForeverForge/addons/
```

Copy the addon folder into your World of Warcraft addon directory.

For Classic Era:

```text
World of Warcraft/
└── _classic_era_/
    └── Interface/
        └── AddOns/
```

Example:

```text
Interface/
└── AddOns/
    ├── ForeverCore/
    ├── ForeverBags/
    ├── ForeverChat/
    ├── ForeverGather/
    ├── ForeverMacroHelper/
    └── ForeverMarket/
```

Make sure there is no additional nested folder.

Correct:

```text
AddOns/ForeverBags/ForeverBags.toc
```

Incorrect:

```text
AddOns/ForeverBags/ForeverBags/ForeverBags.toc
```

---

# Repository structure

```text
ForeverForge/
│
├── addons/
│   ├── ForeverBags/
│   ├── ForeverChat/
│   ├── ForeverCore/
│   ├── ForeverGather/
│   ├── ForeverMacroHelper/
│   └── ForeverMarket/
│
├── README.md
├── LICENSE
└── .gitignore
```

Each addon may contain its own documentation, changelog, testing notes and development resources.

---

# Development status

ForeverForge is under active development.

Several modules currently use:

```text
alpha
beta
release candidate
```

version labels.

Expect rapid iteration while features are tested against real WoW clients.

Bug reports, reproducible compatibility information and technical feedback are especially useful during this stage.

---

# Roadmap

ForeverForge is evolving toward a complete modular player toolkit covering areas such as:

* addon management
* inventory
* Auction House
* economy
* gathering
* chat
* macros
* UI
* character information
* exploration
* analytics
* quality-of-life systems

Future modules should integrate naturally with ForeverCore while remaining focused enough to be useful on their own.

---

# Contributing

ForeverForge is currently primarily developed by **0xgle**.

Issues and technical feedback can be submitted through GitHub.

When reporting a problem, include where possible:

```text
Addon:
Version:
WoW client:
Interface version:
Other enabled addons:
Steps to reproduce:
Expected result:
Actual result:
Error message:
```

---

# Disclaimer

ForeverForge is an independent community project.

It is not affiliated with, endorsed by or sponsored by Blizzard Entertainment.

**World of Warcraft**, **Warcraft** and related names and assets are trademarks of Blizzard Entertainment.

---

# Author

Created and developed by:

**0xgle**

GitHub: [github.com/0xgle](https://github.com/0xgle)

---

## ForeverForge

**One suite. One design language. Better tools for Azeroth.**

© 2026 0xgle.
**
