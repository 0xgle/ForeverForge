# Asset provenance

Sixteen new icons were generated with the built-in image generation tool as one atlas. The atlas was split into cells and converted to uncompressed RGBA TGA, 128 × 128 pixels, for the game client. Every icon is referenced in UI.lua or Settings.lua. Original source is included as `Docs/icon-source.png`.

The common `Media/obsidian.tga` comes from the user's ForeverBags 0.9.4-beta3 package, preserving the suite's material. A separate new panel generation could not be completed because the generator reached its usage limit. No placeholder panel is claimed as generated artwork.

## Generation prompt

Production fantasy UI atlas: 4 x 4 medallion icons, aged gold, obsidian and cyan accents; chat, group, guild, whisper, radar, trade, danger, saved, search, settings, lock, unlock, book, close, down, quill; no text.

## Runtime assets

`Media/chat.tga`, `group.tga`, `guild.tga`, `whisper.tga`, `radar.tga`, `trade.tga`, `alert.tga`, `star.tga`, `search.tga`, `settings.tga`, `lock.tga`, `unlock.tga`, `book.tga`, `close.tga`, `down.tga`, `quill.tga`.

The UI preview is a code-derived layout rendering for review, not a screenshot from a running WoW client. All text is drawn by game font strings at runtime, never baked into the generated art.
