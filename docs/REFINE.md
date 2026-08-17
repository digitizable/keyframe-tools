# Refine pass (technical)

Applied in-place to a `KeyframeSequence` by the plugin.

## Pipeline

1. Read all keyframes (sorted by `Time`).
2. For each R6-style limb pose name (`HumanoidRootPart`, `Torso`, `Head`, arms, legs):
   - Convert `Pose.CFrame` → position + Euler YXZ.
3. **Unwrap** euler channels so smoothing doesn’t jump ±π.
4. **Loop-aware moving average** (triangle weights, circular index).
5. **Clamps**
   - Arm/leg position magnitude (Pose translation — often the “detached arm” cause).
   - Arm X/Z euler limits; optional scale.
   - Torso/head limits; torso Y bob scale.
   - Optional force HumanoidRootPart identity.
6. **Loop finish**
   - Soft blend last N frames toward first.
   - Force last frame poses = first frame poses.
7. Write CFrames back; set **Cubic / InOut** easing when enabled.
8. Tag attributes: `KeyframeToolsRefined`, `KeyframeToolsVersion`.

## Presets

| Preset | Intent |
|--------|--------|
| Default | General cleanup |
| Walk | Milder arms/torso |
| Run | Stricter arm position/rotation (sprint-safe) |

## Metrics (Analyze)

- **maxArmPos / maxLegPos** — max Pose translation magnitude (studs). Walk-like arms are often &lt; ~0.35; broken imports can exceed 1.0.
- **maxJump** — largest per-frame change in euler-pos space (rough jitter meter).
