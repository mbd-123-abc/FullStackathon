# Sprites

Sprite asset layout for Slowbrew.

## Folders

| Folder | Content |
|--------|---------|
| `WalkIn.atlas/` | Walk-on animation frames (walk_in_0001.png … walk_in_000N.png) |
| `WalkOut.atlas/` | Walk-off animation frames (walk_out_0001.png … walk_out_000N.png) |
| `BrewStage1.atlas/` | Stage 1 — Heating water |
| `BrewStage2.atlas/` | Stage 2 — Steeping |
| `BrewStage3.atlas/` | Stage 3 — Pouring |
| `BrewStage4.atlas/` | Stage 4 — Presenting cup |

## Also place here

- `fallback.png` — static image shown if any atlas fails to load

## Frame naming convention

Each atlas folder contains PNG files named with the atlas prefix and a
zero-padded 4-digit counter, e.g. `walk_in_0001.png`. SpriteKit's
`SKTextureAtlas` will discover and sort them automatically.

## Minimum requirements

- Each atlas: minimum 4 distinct frames
- Walk animations: must complete within 3 seconds
- Each brew stage: minimum 1 second duration
