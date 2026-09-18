# In-game acceptance checks

Target: Classic Era / Hardcore 1.15.9. Not yet run in the game client.

1. Enable Lua errors with `/console scriptErrors 1`, then `/reload`. Verify `/fc status` reports initialized=true.
2. Open `/fc`. Verify title, generated icons, tab labels and sidebar at default size, minimum size and your UI scale.
3. Receive and send a whisper. Check tab unread counts, toast, Reply draft and sidebar reply.
4. Click an item link and player link. Shift-click native links if supported by the client.
5. Scroll up, receive messages, confirm no jump. Click Return to live.
6. Join a desired LFG channel manually. Test role filter, dungeon search, LF2M and expiry.
7. Save a message with [+], change tabs, clear ordinary history, then verify Saved retains the bookmark after reload.
8. Resize, move, lock, reload and check the saved position. Test `/fc reset`.
9. Check all settings, copy with Ctrl+A/Ctrl+C, compact reflow and optional minimap icon.
10. Verify notifications are suppressed in combat when enabled.
11. With a second ForeverChat user in the party/guild, send `/fc danger Patrol near road` and inspect reception.
12. Disable history retention, logout fully and login. Captured history should be gone; bookmarks remain.
13. Switch to another character. The new character should not display another character's whispers.
14. Enable ForeverBags and ForeverCore alongside the addon; check the launch flow available in your Core version and confirm no duplicate minimap icon unless explicitly enabled.
