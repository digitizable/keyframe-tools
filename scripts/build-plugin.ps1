# Build KeyframeTools.rbxm for Studio's Plugins folder.
# Requires: rojo on PATH (https://rojo.space)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$out = Join-Path $root "KeyframeTools.rbxm"
if (-not (Get-Command rojo -ErrorAction SilentlyContinue)) {
	Write-Error "rojo not found on PATH. Install from https://rojo.space then re-run."
}

rojo build default.project.json -o $out
Write-Host "Built: $out"
Write-Host ""
Write-Host "Install:"
Write-Host "  1. Open Studio → Plugins → Plugins Folder"
Write-Host "  2. Copy KeyframeTools.rbxm into that folder"
Write-Host "  3. Restart Studio (or reload plugins)"
Write-Host "  4. Toolbar: Keyframe Tools"
