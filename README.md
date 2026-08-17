# Keyframe Tools

Roblox Studio plugin and small CLI for `KeyframeSequence` packs.

Import sequences from `.rbxm` / `.rbxmx` (or from selection), refine them in place, check a few pose stats, and preview on a rig.

## Install (plugin)

1. Download **KeyframeTools.rbxm** from [Releases](https://github.com/digitizable/keyframe-tools/releases/latest)
2. Studio → **Plugins** → **Plugins Folder**
3. Drop the file in and restart Studio

Build from source:

```bash
rojo build default.project.json -o KeyframeTools.rbxm
# or: ./scripts/build-plugin.ps1
```

## Plugin

- **Import .rbxm** — Studio file picker; pulls nested sequences (e.g. under `AnimSaves`)
- **Import selection** — copy sequences from whatever you have selected
- **Destination** — defaults to `ReplicatedStorage.Animations` (optional ServerStorage mirror)
- **Refine** — smooth, clamp limb pose translations, fix loop seams, cubic easing  
  Presets: Walk, Run, default
- **Analyze** — key count, max arm/leg pose translation, max frame jump
- **Preview** — play the selected sequence on a selected model with a Humanoid

More detail on the refine pass: [docs/REFINE.md](docs/REFINE.md)

## CLI

```bash
cd cli
npm install
node src/index.js list path/to/pack.rbxm
node src/index.js inspect path/to/pack.rbxm Walk
node src/index.js export-json path/to/pack.rbxm Walk ./walk.json
```

## License

[MIT](LICENSE)
