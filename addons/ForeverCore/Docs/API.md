# ForeverCore integration API v1

ForeverCore manages installed addons without requiring changes to their source. For a richer launcher, add `## OptionalDeps: ForeverCore` and `## X-Forever-Suite: 1` to your addon's TOC. Keep its existing optional dependencies on that same line.

Register after your own initialization, e.g. during PLAYER_LOGIN:

```lua
if ForeverCore and ForeverCore.apiVersion == 1 then
    ForeverCore:RegisterModule("ForeverExample", {
        title = "ForeverExample",
        description = "A short description of this addon.",
        icon = 16,
        open = function() MyAddon:Toggle() end,
        settings = function() MyAddon:OpenSettings() end,
    })
end
```

The identifier must be the exact installed addon folder. `title` is required; `description`, `icon`, `open` and `settings` are optional. `icon` is an integer 1–16; default 1. Callbacks receive no arguments. `settings` must be a distinct function that opens your own settings UI. Omit unsupported functions; Core will not show their buttons. Callbacks should be fast and avoid protected actions.

Core invokes callbacks outside combat and catches errors with pcall. It does not override the global error handler. Registration is process-local; repeat it on login. For load-on-demand modules, register on ADDON_LOADED after initializing the module, not just PLAYER_LOGIN.

## Shared textures

`ForeverCore.media` is the texture-path prefix. `Media/Icons.tga` contains a 4x4 row-major atlas:

| Index | Artwork |
| --- | --- |
| 1 | Core crystal |
| 2 | Backpack |
| 3 | Gathering herbs |
| 4 | Chat |
| 5 | Compass |
| 6 | Settings gear |
| 7 | Profile scroll |
| 8 | Diagnostics |
| 9 | Favorite star |
| 10 | Shield |
| 11 | Hourglass |
| 12 | Book |
| 13 | Hammer |
| 14 | Combat |
| 15 | Quill |
| 16 | Constellation |

`ForeverCore.T` is an internal theme helper, not a versioned public widget contract. Modules should own their UI and saved state. This API does not synchronize theme or profiles into existing addons and does not change their databases. `RegisterModule` replaces an existing registration for the same identifier.

## Legacy fallback

A loaded folder named ForeverChat exposing `/foreverchat` is discovered through the registered SlashCmdList and SLASH_* values. Core calls that registered callback with an empty message. No slash command is guessed or executed from imported profile data.

## Profile format

```text
FCORE1|Gathering|suite
ForeverBags=1
ForeverChat=0
ForeverGather=1
```

Scope is `suite` or `all`. Values are 0/1 only. Names cannot contain a vertical bar or newline. Addon identifiers are constrained to ASCII word characters, underscores, hyphens and dots. Missing addons are skipped. Core never calls loadstring on imported content.
