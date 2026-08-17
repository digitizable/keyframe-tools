# Changelog

## 1.0.0

### Plugin

- Import `KeyframeSequence`s from `.rbxm` / `.rbxmx` via Studio file picker
- Import from Explorer selection (including `AnimSaves` packs)
- Configurable destination + optional ServerStorage mirror
- In-place refine: loop-aware smooth, limb clamps, loop seam fix, cubic easing
- Walk / Run refine presets
- Analyze selected sequences (keys, max arm/leg pose translation, max jump)
- Preview on selected Humanoid rig; stop preview

### CLI

- `list` / `inspect` / `export-json` for offline `.rbxm` packs (`rbx-reader`)
