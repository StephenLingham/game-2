# Project notes

## Non-negotiable visual language

The game's art style is **everything is a rectangle**.

- Characters, equipment silhouettes, environments, scenery, UI decoration, attacks, animation accents, particles, and future visual effects must be built from rectangles.
- Do not add raster images, imported textures, circles, polygons, curved primitives, or conventional illustrated sprites.
- Animation and particle effects are encouraged, provided every visible particle or animated component is rectangular.
- Depth and visual richness should come from layered rectangles, careful color palettes, transparency, scale, motion, lighting bands, and composition.
- UI controls should keep square corners so the interface belongs to the same visual system.

## Colour direction

- The whole game should use a bright, happy colour scheme.
- Prefer clear sky blues, vivid grass and leaf greens, warm sunshine yellows, and other cheerful high-contrast colours.
- Avoid gloomy, muddy, or predominantly dark presentation; darker colours should be limited to readable text, outlines, and small contrast details.

## Gameplay/UI conventions

- Boss names are intentionally not displayed above bosses during combat.
- Inventory items use a grid, hover details, and rarity color coding.
- Equipped gear is presented on a rectangular character outline at its anatomical slot.
- Escape during a run opens a pause menu; Save & Exit must preserve the exact run level, health values, timer, combat clocks, and selected background.
- Every level currently uses the single rectangle-built sunny meadow environment: blue sky, green grass, and varied rectangular trees.

## Verification

- Run the Godot smoke test after gameplay changes.
- Inspect new visual code for non-rectangle drawing calls and texture/image dependencies.
