# In-game test pass

Target: English WoW Classic Era 1.15.9. These are tests to run, not claims of completed in-game testing.

1. Enable Lua errors with `/console scriptErrors 1`, then reload. The library must start closed. Open with `/fmh` and close with Escape.
2. Check class filters, PvE/PvP, search, favorites and scrolling. Read one long description. Check 1080p and a smaller window; no text should overlap controls.
3. Create one General macro, then drag the book icon to a bar. Verify the character tab of `/macro` contains one entry. Create/update again: no duplicate.
4. Edit a body, switch templates, return and reload. The draft must survive. Reset body must not change the installed macro until Update is clicked.
5. Create an account macro with the same name and different content. Creating/updating the character macro must leave the account macro intact.
6. Edit a managed character macro in `/macro`. Update/Delete in the addon must preserve that external edit and report the conflict. Rename it to allow a fresh template to be created.
7. Fill character slots, preview a pack, and confirm no partial changes occur from insufficient capacity. With space free, install a pack; existing macros must remain unchanged. Repeat: no duplicates.
8. Enter combat: Create/Update/Delete and pickup must be unavailable. Leaving combat must not perform a deferred action. Browse and close the window normally.
9. Test actual casts on characters with the required spells, talents, stances and equipment. Test mouseover, target and self fallback separately. Test Shift bindings. Confirm multi-press stance changes and totem sequence behavior.
10. Test pet recall, Scatter Shot, Feign Death and CC away from dangerous pulls; they do not remove existing DoTs or guarantee survival. Check no unexpected pet attacks occur.
11. Confirm English game client restriction and Classic project restriction. Enable/disable the minimap launcher in settings, drag it, then reload.

Report the first Lua error, game build, class, macro title and reproduction steps. Disable error popups later with `/console scriptErrors 0` if desired.
