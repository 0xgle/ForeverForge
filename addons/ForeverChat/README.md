# ForeverChat

Version 0.2.0-beta1 · by 0xgle

Chat, companions and dungeon recruitment in the visual language of the Forever family: obsidian, aged gold and restrained turquoise. Designed for WoW Classic Era / Hardcore 1.15.9, Interface 11509. Compatibility with a future Forever client is not yet verified.

## Install

1. Close WoW completely, because this update includes new textures.
2. Replace the old `ForeverChat` folder inside `_classic_era_/Interface/AddOns/` with the folder from this archive.
3. Check that the path is `Interface/AddOns/ForeverChat/ForeverChat.toc` (no doubled folder).
4. Enable ForeverChat in the character selection AddOns list. Enter the game and type `/fc`.

Existing prototype history and word filters migrate automatically. Your SavedVariables file is not part of the ZIP and should not be deleted. The HUD has a minimum height to keep sidebar cards and controls apart.

## Features

- Eight views: All, Group, Guild, Whispers, LFG radar, Trade, Alerts and Saved.
- Sixteen generated icon textures included and used in the interface; shared ForeverBags obsidian material.
- Search player names, channels and message text, including readable item names.
- Recent whispers and fresh LFG posts in a dedicated sidebar; click to draft a reply.
- Role filter (Any / Tank / Heal / DPS), dungeon search and configurable post expiry.
- LFG recognition includes LFM, LF2M and common Classic dungeon abbreviations. Dire Maul's full name is distinguished from Deadmines; ambiguous `DM` remains Deadmines.
- Click `[+]` beside a message to save it; click `[*]` to remove it. Up to 100 bookmarks per character, retained independently of the history limit.
- Scrolling up pauses the view. Incoming messages accumulate behind a Return to live button; reading is not interrupted.
- Native item/player links, optional class colors, timestamps and a copy conversation dialog.
- Configurable notifications, sound (off by default) and quiet notifications during combat.
- Word/phrase filters and bounded duplicate suppression. These affect ForeverChat, not Blizzard's chat.
- Drag the header to move; drag the bottom-right grip to resize. Lock, scale, font size, background opacity and compact view controls.
- Adjustable 200–2000 message history; character-separated records; option to discard captured history at logout. Explicitly saved messages remain saved.
- Optional minimap icon, off by default to keep the ForeverCore-oriented minimap clean. `/fc` and WoW key bindings remain available without it.
- Manual danger reports to other ForeverChat users in your party, raid and guild, with rate limiting.

## Settings

Click the cog or type `/fc settings`. Click a value to cycle it; changes apply immediately. The minimap toggle is independent of other Forever addons. No required dependency or external library.

## Commands

| Command | Action |
| --- | --- |
| `/fc` | Show / hide |
| `/fc settings` | Settings |
| `/fc compact` | Show / hide sidebar |
| `/fc lock` | Lock / unlock movement and resizing |
| `/fc copy` | Copy current filtered view |
| `/fc danger <text>` | Share a danger report |
| `/fc block <phrase>` | Filter future matching messages |
| `/fc unblock <phrase>` | Remove a filter |
| `/fc clear` | Clear current character's captured history; keep saved messages |
| `/fc reset` | Restore default size, scale and position |
| `/fc status` | Version, interface and initialization diagnostics |

## Scope and data

This is a companion HUD. Blizzard's original chat stays available and handles message entry and links. The buttons prepare native chat drafts; the player sends the message. Public chat is collected only from events the client actually receives. The addon does not automatically join channels, query hidden groups, send public advertisements or automatically invite players. Radar results are best-effort text interpretation, not authoritative group availability. Danger reports are player reports, not a guarantee that an area is safe.

History, favorites and settings remain in WoW SavedVariables on your computer. Shared danger reports travel through the game addon channel to group/guild members running ForeverChat. Peer count only includes recent addon greetings/reports and can take time to update. The chat store is bounded per character; character records are kept when switching alts.

## Validation

Lua 5.1 syntax and a simulated WoW frame/event harness passed. Covered: loading, chat routing, unread state, pause/resume, filters, LFG expiry and parsing, saved messages, settings callbacks, copy, layout controls, danger throttling and logout history behavior. Textures checked for power-of-two dimensions and manifest paths. Visual layout inspected using a renderer of the constructed frame tree. No live WoW client was available; this is a beta for in-game testing. See `Docs/TEST-CHECKLIST.md`.

## Rights

Copyright © 2026 0xgle. All rights reserved. See LICENSE.txt.
