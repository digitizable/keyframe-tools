# Keyframe Tools

**Open-source Roblox Studio plugin + CLI** for working with `KeyframeSequence` animation packs.

Import Moon / Animation Editor `.rbxm` dumps, refine locomotion clips (smooth, clamp, fix loops), analyze pose stats, and preview on a selected rig — without hand-rolling import scripts.

Not tied to any specific game project.

---

## What’s included

| Piece | Purpose |
|--------|---------|
| **Studio plugin** | Import, refine, analyze, preview |
| **CLI** (`cli/`) | List / inspect / export sequences from `.rbxm` offline |

---

## Studio plugin

### Features

1. **Import `.rbxm` / `.rbxmx`**  
   Uses Studio’s file picker. Finds `KeyframeSequence`s (including under `AnimSaves`).

2. **Import from selection**  
   Point at a dummy / pack already in the place.

3. **Copy to destination**  
   Default: `ReplicatedStorage.Animations`  
   Optional mirror: `ServerStorage.Animations`  
   (paths are editable in the dock)

4. **Refine selection**  
   In-place pass on selected sequences:
   - loop-aware smoothing  
   - arm/leg **position clamps** (reduces “detached limb” look)  
   - torso/head limits + optional root identity  
   - soft loop blend + **perfect first/last seam**  
   - **Cubic InOut** pose easing  

   Presets: **Walk** (milder) · **Run** (stronger arm clamps) · default

5. **Analyze selection**  
   Reports key count, max arm/leg pose translation, max frame jump.

6. **Preview**  
   Plays the selected sequence on a **selected Model with a Humanoid** (R6 or R15).

### Install

**Option A — build with Rojo**

```powershell
# from repo root
./scripts/build-plugin.ps1
```

Then:

1. Studio → **Plugins** → **Plugins Folder**
2. Copy `KeyframeTools.rbxm` into that folder  
3. Restart Studio  
4. Toolbar: **Keyframe Tools**

**Option B — rebuild from source**

```bash
rojo build default.project.json -o KeyframeTools.rbxm
```

Entry script: `src/init.server.luau`.

### Typical workflow

1. Export or download an animation pack as `.rbxm` (e.g. dummy + `AnimSaves`).  
2. Open **Keyframe Tools** dock.  
3. **Import .rbxm** → sequences land under your destination folder.  
4. Select a sequence → **Run preset** (if sprint) or **Walk preset** → **Refine selection**.  
5. Select an R6 dummy + sequence → **Preview**.  
6. Wire sequences into your game’s Animate / controller however you like.

---

## CLI

Offline inspection (no Studio):

```bash
cd cli
npm install
node src/index.js list ../path/to/pack.rbxm
node src/index.js inspect ../path/to/pack.rbxm Walk
node src/index.js export-json ../path/to/pack.rbxm Walk ./walk.json
```

Optional global bin after `npm link` in `cli/`:

```bash
keyframe-tools list ./pack.rbxm
```

---

## Project layout

```
keyframe-tools/
  default.project.json    # Rojo → KeyframeTools.rbxm
  src/
    init.server.luau      # toolbar + dock (plugin entry)
    Config.luau
    Util.luau
    Import.luau
    Refine.luau
    Preview.luau
    Ui.luau
  cli/                    # Node helpers (rbx-reader)
  scripts/build-plugin.ps1
  docs/REFINE.md
  README.md
  LICENSE
```

---

## Design notes

### Why a plugin (not only an agent/script)?

Studio plugins can use **`PromptImportFile`** and a stable UI. Large KeyframeSequence payloads don’t need to be pasted through chat or MCP.

### What refine does *not* do

- It does not invent a good walk from scratch.  
- It does not replace Moon Animator / Animation Editor for art direction.  
- It **does** fix common mechanical issues after import (loop pops, extreme Pose translations, jitter).

### R6 tips

R6 hip/shoulder `C0` uses ±90° Y. Naive world-space X rotations often read as floss. Prefer editor-authored clips, then refine.

---

## License

MIT — use it in any project, commercial or not.

---

## Contributing

PRs welcome: UI polish, R15-specific refine, FBX paths, Rojo sync from a watched folder, etc.
