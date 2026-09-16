# ForeverForge

Open-source World of Warcraft addons and tools by **0xgle**.

ForeverForge is the umbrella repository for experimental and production-ready addons focused on exploration, gathering, loot intelligence, routing and quality-of-life tools.

## Addons

### ForeverGather

**ForeverGather 2.2.0** is a gathering intelligence addon for WoW Classic Era.

It learns successful Mining, Herbalism and Skinning locations while you play, displays compact markers on the Minimap and World Map, and builds Smart Routes through learned locations.

Key features:

- Mining, Herbalism and Skinning location learning
- Hollow learned-node markers that keep Blizzard tracking dots visible
- Smart Route generation and optimization
- Route guidance on the Minimap and World Map
- Off-screen NEXT direction guidance
- Session analytics and confidence tracking
- GatherMate2 import
- TomTom integration
- Local-first data storage
- No movement, casting, targeting or protected-action automation

Source code is available under [`addons/ForeverGather`](addons/ForeverGather).

The ready-to-install package is available under [`releases`](releases).

## Installation

1. Download the current ForeverGather ZIP from the `releases` directory.
2. Extract the `ForeverGather` folder into:

```text
World of Warcraft/_classic_era_/Interface/AddOns/
```

3. Start or reload the game.
4. Open the addon with:

```text
/fg
```

## Repository structure

```text
ForeverForge/
├── addons/
│   └── ForeverGather/
├── releases/
├── README.md
├── LICENSE
└── .gitignore
```

## Author

**0xgle**

## License

MIT. See [`LICENSE`](LICENSE).
