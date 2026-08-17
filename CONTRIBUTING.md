# Contributing

Thanks for helping improve Keyframe Tools.

## Dev setup (plugin)

1. Install [Rojo](https://rojo.space/).
2. From the repo root:

```powershell
./scripts/build-plugin.ps1
```

3. Copy `KeyframeTools.rbxm` into Studio’s **Plugins** folder and restart Studio.

For live edit, use your preferred plugin development workflow with `src/` as the plugin source tree (`default.project.json` maps `$path` → `src`).

## Dev setup (CLI)

```bash
cd cli
npm install
node src/index.js list path/to/pack.rbxm
```

## Guidelines

- Keep the tool **game-agnostic** (no project-specific branding or hard-coded places).
- Prefer small, focused PRs.
- Match existing Luau style (`--!strict`, clear module boundaries).
- Document user-facing behavior in `README.md` when you change the dock UI.

## Ideas

- Watched-folder auto-import
- R15-specific refine presets
- Export refined clip back to `.rbxm`
- Better preview (speed slider, scrubber)
