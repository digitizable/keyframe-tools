# Contributing

## Plugin

Install [Rojo](https://rojo.space/), then from the repo root:

```bash
./scripts/build-plugin.ps1
```

Copy `KeyframeTools.rbxm` into Studio’s Plugins folder and restart.

## CLI

```bash
cd cli
npm install
node src/index.js list path/to/pack.rbxm
```

## Notes

- Small PRs are easier to review
- Keep Luau style consistent with the rest of `src/` (`--!strict`)
- Mention UI changes in the README when they matter to users
