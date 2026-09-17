# ForeverCore — The Sanctum

The command center for the Forever addon collection. Created by **0xgle**.

Version **1.0.0-rc1**. Target: **WoW Classic Era 1.15.9 / Interface 11509**, including its Hardcore realms. This release candidate is ready for in-game acceptance testing. It has not been run inside the WoW client. Compatibility with a different client, including Forever, is not yet certified.

## Install

1. Fully exit World of Warcraft.
2. Extract the `ForeverCore` folder into `World of Warcraft/_classic_era_/Interface/AddOns/`.
3. Check that `AddOns/ForeverCore/ForeverCore.toc` exists, without an extra nested folder.
4. Start WoW and enable ForeverCore in the character-selection AddOns list.
5. Enter the world and type `/fc`, or click the turquoise crystal next to the minimap.

Other Forever addons remain installed separately. ForeverCore does not replace or bundle them. No external Lua libraries are required. Bindings.xml is automatically discovered by WoW.

## Features

- Sanctum dashboard with custom arcane artwork, a coordinated 16-icon atlas and quick launch cards.
- Automatic detection of installed folders beginning with `Forever`, registered modules and `X-Forever-Suite: 1` addons.
- Switch between the Forever collection and all installed addons. Search, favorite and paginate the list.
- Stage changes, inspect a dependency-aware plan, apply it to the current character and reload separately.
- Enabling an addon stages its installed dependencies. Disabling a dependency stages dependent addons off as well.
- ForeverCore protects itself from disabling within its own panel.
- Account-wide named profiles containing enabled states, with character-specific application.
- Plain-text profile import/export: no Lua execution, 64 KB size cap, 500 entries, 50 profiles, duplicate protection.
- Manual memory measurement, diagnostic report, local activity history and bounded callback-error log.
- Undo the last apply. Core-only mode stages other Forever addons off while retaining saved data.
- Scale controls, draggable window, automatic screen fit, movable minimap launcher and optional LibDataBroker launcher when the library already exists.
- Key binding under AddOns > ForeverCore, Escape dismissal and slash commands.

## Existing addons

Direct launch adapters were checked against ForeverBags 0.9.4-beta3 and ForeverGather 3.0.0-rc1 source. Bags exposes both Open and Config. Gather exposes its main panel.

Other Forever addons get an Open button if they expose a slash command matching their folder name, for example `/foreverchat` for `ForeverChat`. Addons with different commands still appear in the manager; register a module to provide Open and Config callbacks. See `Docs/API.md`.

The displayed profile is the last profile applied through Core, not a guarantee that nothing was subsequently changed in WoW's own addon list. Profiles store enabled states only, not another addon's bags, routes, filters, layout or SavedVariables. Staged states are included when saving a new profile.

## Commands

| Command | Action |
| --- | --- |
| `/fc` or `/forevercore` | Toggle ForeverCore |
| `/fc addons` | Open the addon manager |
| `/fc profiles` | Open profiles |
| `/fc diag` | Open diagnostics |
| `/fc minimap` | Toggle the minimap button |
| `/fc reset` | Center the window and reset its scale |
| `/fc help` | Show command help |

## Applying changes

Click Enabled/Disabled, then **Review**, inspect the list and click **Apply changes**. Click **Reload UI** when ready. Unchecking an addon does not unload its currently executing code; reload finishes the change. Changes are restricted during combat. Dependencies outside the Forever suite may be included in a plan; they are explicitly listed before application.

Profiles with explicitly conflicting dependency states are rejected without applying anything. Unknown, uninstalled profile entries are skipped with a message. Import never downloads addons. Addons cannot update or download their own files from the internet.

Undo restores the previous enabled states from the last successful application. It does not revert addon settings or game data. Core-only mode can be blocked by a non-Forever addon that requires a Forever module; the chat message names that dependency.

## Design and implementation

Original event-driven Lua, split into API compatibility, manager, profiles, integration, theme, UI and lifecycle modules. Widgets are created lazily and reused. There is no idle OnUpdate loop; a temporary OnUpdate runs only while dragging the minimap button. Memory is sampled on request. No bags, chat frames, action bars, CVars, game key bindings or global error handlers are replaced.

Original AI-assisted artwork is packaged as uncompressed, power-of-two TGA textures. Live font strings and controls remain separate from artwork. UI language: English. Polish installation guide included. Artwork prompts and conversion details are in `Docs/ARTWORK.md`.

## Validation and release status

Automated logic and mocked-UI checks are documented in `Docs/QA.md`. Those checks do not simulate WoW's secure execution system, exact fonts, texture rendering or real client addon APIs. Complete the included in-game checklist before publishing this as a stable 1.0.0 release.

Copyright 2026 0xgle. All rights reserved. See LICENSE.txt.
