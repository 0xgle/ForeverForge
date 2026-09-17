# Development verification

These files are not loaded by the addon. Install only the ForeverMarket folder.

From the directory containing `build/`, run:

    python3 build/DeveloperTools/run_lua.py build/DeveloperTools/test.lua
    python3 build/DeveloperTools/render_layout.py

When using this distribution, place the extracted contents under a `build/` folder
so the paths match. The Lua runner uses system liblua5.4 via ctypes. The addon
uses the Lua 5.1-compatible subset; this harness is not a WoW client emulator.
The renderer requires Pillow and DejaVuSans.

Tests exercise actual addon files with a mocked WoW API. Layout PNGs represent
simulated frames and sample data, not live gameplay. The green P icon is a test
placeholder only; the addon uses GetAuctionItemInfo textures inside the game.

Read-only implementation reference used to check AH lifecycle and posting calls:
https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_AuctionUI/Classic/Blizzard_AuctionUI.lua
