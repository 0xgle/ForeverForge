# Artwork manifest

Generated with the built-in ImageGen tool. The PNG originals are included in
DeveloperTools/ArtSources; game-ready files are in ForeverCore/Media.

Sanctum.tga: RGB, 1024x512, uncompressed.
Icons.tga: RGB, 1024x1024, uncompressed, sixteen cells in a 4x4 grid.
Core.tga: RGB, 128x128, uncompressed, minimap emblem from the atlas source.

Technical conversion resized the hero, normalized atlas row boundaries and
cropped the minimap emblem. UI labels, frames and buttons are live Lua widgets.

## Hero generation prompt

Use case: stylized-concept. Create a production game UI BACKGROUND ASSET, not a screenshot, no text, no interface controls. Wide landscape 1536x1024. ForeverCore fantasy addon control room aesthetic: enormous ancient circular astrolabe / arcane gateway in rightmost third, antique dark gold metal, luminous turquoise crystal core, engraved stone architecture, atmospheric deep midnight teal fog, cinematic hand-painted premium fantasy RPG texture. Left 60 percent extremely dark calm near-black stone with subtle teal mist and barely visible engraved circular lines for text overlay. Outer edges dark. Main brilliant turquoise orb at x=79%, y=45%, the ring fits entirely inside right 40%. Restrained gold filigree, high craftsmanship, clean dramatic composition, no humanoids, no letters, no logos, no borders. This raster will be converted to a WoW TGA UI texture.

## Icon atlas generation prompt

Use case: stylized-concept. Asset type: one square 1024x1024 GAME ICON ATLAS with exactly 4x4 perfectly even square cells of 256x256 each, no gutters or outer border. Sixteen ornate fantasy RPG inventory UI icons hand painted and rendered, each centered entirely within its cell with 25px dark padding; consistent dark charcoal teal background, antique gold metal edges, bright small magical accents, legible bold silhouettes. Row1: turquoise crystal in gold astrolabe ring (brand emblem); ornate leather backpack; luminous herbs and gold sickle; parchment speech bubble. Row2: compass; gold gear with teal center; scroll with wax seal; magnifying glass over glowing runes. Row3: gold star; turquoise shield; hourglass; book with golden clasp. Row4: small gold hammer; crossed sword and shield; turquoise feather quill; crystal constellation. No letters no labels no text no numbers, no imagery crossing between the sixteen cells. Make luxurious polished cohesive original fantasy artwork for ForeverCore addon.
