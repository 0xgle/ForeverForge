FOREVER GATHER 2.2.0 — CLASSIC ERA
===================================
Author: 0xgle

Forever Gather is a local-first gathering intelligence addon for Mining, Herbalism and Skinning.
It learns successful gathering locations while you play, shows compact map/minimap markers, and can build
Smart Routes through learned locations. The primary navigation layer is the Minimap and World Map.
The /fg window is the Route Atlas — a compact map & route helper and session dashboard.

CORE FEATURES
- Mining + Herbalism + Skinning location learning
- Successful-loot validation to reduce false node records
- Premium Minimap + World Map pins
- Hollow learned-node rings so Blizzard live tracking dots remain visible
- Skinning density heatmap
- Confidence levels and observed respawn model
- Smart Route builder with clustering, confidence weighting and route optimization
- Route lines on Minimap and World Map
- Off-screen NEXT guidance at the Minimap edge
- Auto-advancing NEXT route marker
- Focus Mode for one resource
- Session analytics + recent session history
- Loot observations per gathering point
- GatherMate2 import
- TomTom next-stop integration
- Zone export, Diagnostics and Data Doctor
- Skill-aware node filtering
- Cached map data and pooled UI objects for performance
- Individually generated premium graphics for logo, minimap button and profession/navigation icons

COMMANDS
/fg                     Open Route Atlas
/fg bar                 Toggle compact Field Bar
/fg route               Build Smart Route
/fg route clear         Clear route
/fg route next          Send next route stop to TomTom
/fg focus <name>        Focus one resource
/fg focus clear         Clear focus
/fg reset               Start a new session
/fg import gathermate   Import GatherMate2 mining/herb locations
/fg diag                Open diagnostics
/fg export              Export current-zone data
/fg prune               Run Data Doctor
/fg test mine           Add a test mining pin
/fg test herb           Add a test herb pin
/fg test skin           Add a test skinning pin

INSTALL
Copy the ForeverGather folder to:
World of Warcraft/_classic_era_/Interface/AddOns/

For debugging during testing:
/console scriptErrors 1
/reload

Forever Gather performs no movement, targeting, casting, protected actions or combat automation.
