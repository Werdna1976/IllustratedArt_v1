# Illustrated 2.5D Platformer — Core Specs & Architecture

**Date:** 2026-09-27
**Engine:** Godot 4.7, Forward+ (D3D12 on Windows), Jolt Physics
**Status:** Draft for review

## 1. Goal

A side-scrolling platformer with painterly, AI-generated illustrated art. Depth is conveyed by flat painted plates placed at real Z-depths in a 3D scene and viewed through a perspective `Camera3D`, so parallax, fog, depth-of-field and lighting come from actual 3D geometry rather than hand-tuned scroll ratios.

This spec fixes the numbers everything else depends on: world scale, camera, level size, and per-layer texture sizes.

### Decisions made
| Topic | Decision |
|---|---|
| Depth approach | 2.5D: painted quads in 3D, perspective camera |
| Target resolution | Design at 1920×1080; texel density crisp through 1440p |
| Level shape | Mostly horizontal, 7 screens long × 1.5 screens tall |
| Painted-plate shading | Unshaded by default; gameplay/near layers may opt in to lit |
| Player physics | 3D (Jolt) on the z = 0 plane, Z axis locked |

## 2. World Scale & Camera

- **1 world unit = 1 m = 100 px at the gameplay plane** (at 1080p).
- One screen at the gameplay plane = **19.2 m × 10.8 m**.
- Camera: `Camera3D`, perspective, `keep_aspect = KEEP_HEIGHT`, **distance D = 20 m** in front of the gameplay plane (camera at world z = +20, looking down −Z; see axis note), **vertical FOV = 30.22°** (= 2·atan(5.4 / 20)).
- A layer at camera distance *d* scrolls at **20 / d** × gameplay speed, and its on-screen texel density at 1080p is **2000 / d px per metre**.
- **Invariant:** the camera's distance and FOV are fixed. Zoom, shake and cinematic moves are implemented as small dolly / translation / rotation offsets on the rig, never by changing FOV or the base distance. Section 4 sizes assume this.

> Axis convention: Godot cameras look down −Z. The camera sits at z = +20 looking toward −Z; "depth behind the gameplay plane" is therefore negative world Z. In this document, **depth z** means distance *behind* the gameplay plane (positive = farther from camera); implementation maps depth z → world Z = −z.

## 3. Level Dimensions

- **Width:** 7 screens = **134.4 m** (13,440 px at gameplay plane).
- **Height:** 1.5 screens = **16.2 m** (1,620 px).
- Camera is clamped so the viewport never shows beyond level bounds at the gameplay plane.
- Camera travel: **115.2 m** horizontal (134.4 − 19.2), **5.4 m** vertical (16.2 − 10.8).
- Target play time: 3–5 minutes per level.

## 4. Layer Stack & Plate Sizes

**Sizing formula** (implemented once, in `WorldSpec`; the table below is its output):

- Visible extent at camera distance *d*: `screen_extent × d / 20`, where screen extent at the gameplay plane is 10.8 m tall and `10.8 × aspect` m wide.
- Area a layer must cover over the whole level (camera clamped to level bounds):
  `span_w = level_w + screen_w × (d/20 − 1)`, `span_h = level_h + 10.8 × (d/20 − 1)`.
- Plate px = `span × (2000 / d) × 1.10` (10% margin for shake, dolly and look-ahead), rounded **up** to a multiple of 64 (with a 1e-6 tolerance so float noise never adds a step). Width is computed at the widest supported aspect, **21:9**.
- Plates are centred on the level centre, so they cover every camera position symmetrically.

| Layer | Depth z | Cam dist d | Scroll | Density | Plate size (px) |
|---|---|---|---|---|---|
| Foreground (DoF-blurred) | −8 m | 12 m | 1.67× | 167 px/m | Sparse props only, not a continuous plate |
| **Gameplay** | 0 m | 20 m | 1.00× | 100 px/m | **14,784 × 1,792** |
| Near BG | +10 m | 30 m | 0.67× | 67 px/m | **10,816 × 1,600** |
| Mid BG | +40 m | 60 m | 0.33× | 33 px/m | **6,784 × 1,408** |
| Far BG | +100 m | 120 m | 0.17× | 17 px/m | **4,800 × 1,344** |
| Sky | +400 m | 420 m | 0.05× | 4.8 px/m | **3,392 × 1,280** |

Key properties:
- Plate **height stays ~1,300–1,800 px at every depth**; only width shrinks with distance. One upscaled AI-output height (~1,536 px) serves all layers.
- **~23 painted strips per level** in 2,048-px-wide units: 8 gameplay, 6 near, 4 mid, 3 far, 2 sky.
- **Aspect ratios:** 16:9 to 21:9 are fully supported. Narrower aspects (16:10, 4:3) keep the same height and show less width. Wider than 21:9 (e.g. 32:9) switches the camera to keep 21:9's width and crops height, so plate edges are never visible.
- **Budget:** strips ≤ 2,048 px wide, BC7-compressed with mipmaps ≈ **86 MB VRAM per level**.

## 5. Rendering: Depth, Lighting, Camera

### 5.1 Plates
- Each plate strip is a `MeshInstance3D` quad with a `StandardMaterial3D`: alpha-scissor transparency, unshaded by default, per-pixel lit for gameplay/near layers when lighting is wanted. The sky plate sets `disable_fog`. (A custom shader is deferred until a feature needs one.)
- Quad size in metres = strip px ÷ layer density (px/m).

### 5.2 Environment (one `WorldEnvironment` per level)
- **Depth fog** tinted per-level haze colour — primary depth cue.
- **DoF blur:** far blur on far BG + sky; near blur on foreground. Gameplay plane in focus.
- **Glow** for emissive elements.
- **Tonemap + per-level colour-grading LUT** to unify AI art across generation batches.
- **Volumetric fog:** optional per-level toggle for light shafts between layers.

### 5.3 Lighting
- One `DirectionalLight3D` per level for mood/colour.
- `OmniLight3D` / `SpotLight3D` for local sources; cull masks restrict them to gameplay + near layers.
- Soft player-follow rim/fill light to separate the character from backgrounds.
- Normal maps for gameplay plates: optional, later milestone.

### 5.4 CameraRig (`scenes/camera_rig.tscn`)
- Smoothed follow of the player, horizontal look-ahead, vertical dead-zone.
- Clamp to level bounds at the gameplay plane.
- Additive offsets: dolly (zoom), trauma-based shake, scripted cinematic nudges via trigger `Area3D`s. All offsets are bounded to stay within the 10% plate margin.

### 5.5 Physics
- `CharacterBody3D` player and `StaticBody3D` level collision exist only at z = 0; player Z axis locked.
- Jolt Physics, physics tick **120 Hz**, with **physics interpolation on** so movement and camera stay smooth at any refresh rate.
- **Actor render offset:** collision lives at z = 0, but actor and platform *visuals* render at **z = +0.5 m** so they always draw in front of the gameplay plate (which sits exactly at z = 0). The 2.5% perspective difference is negligible.

## 6. Project Settings

| Setting | Value |
|---|---|
| `display/window/size/viewport_width × height` | 1920 × 1080 |
| `display/window/stretch/mode` | `canvas_items` (existing) |
| `display/window/stretch/aspect` | `expand` (existing); UI authored for 16:9 with anchors |
| Renderer | Forward+ (existing), D3D12 (existing) |
| `rendering/anti_aliasing/quality/msaa_3d` | 4× |
| TAA | Off (smears animated sprites) |
| VSync | On |
| `physics/common/physics_ticks_per_second` | 120 |
| `physics/common/physics_interpolation` | On |
| 3D physics engine | Jolt (existing) |

## 7. Art Pipeline

1. Generate at the model's native resolution (~1,536×1,024 / 1,344×768).
2. Upscale 2×.
3. Paint-over / stitch to the layer's plate size (Section 4).
4. Export PNG (alpha for gameplay, near and foreground layers).
5. Place at `art/levels/<level>/<layer>.png`.
6. Editor plugin `addons/plate_importer/` slices into ≤ 2,048-px strips, applies BC7 + mipmaps, and generates the layer's quads at the correct depth and scale.

**Style guide rules:** shared prompt template, per-game palette, consistent key-light direction; contrast and saturation decrease with layer depth (fog supplies part of this, so plates should not over-fade).

## 8. Folder Layout

```
scenes/    level/, camera_rig.tscn, player.tscn, parallax_layer.tscn
scripts/
art/       levels/<level>/, characters/
addons/    plate_importer/
docs/
```

## 9. Dev Tooling (token-efficient by design)

Tools print terse summaries; full output goes to git-ignored logs under `.godot/`.

| Tool | Purpose |
|---|---|
| `bash tools/run_tests.sh [-v]` | Headless test suite (`tests/*_test.gd`, `test_*` methods, any engine error fails the test). Prints only failures + `N passed, M failed`; `-v` for the full log. |
| `bash tools/capture.sh <name> <WxH> <frames> [args]` | Runs the main scene in a window at any size (including 21:9) and saves one frame to `.godot/captures/<name>.png` via the `DebugCapture` autoload. Movie Maker is not used: it crops non-16:9 windows to 1920×1080. |
| Test-level user args | `--autorun` (player runs right), `--spawn-x=<m>` (spawn position). |

## 10. Milestones

**M1 — Specs proof (this spec's implementation scope):**
- Project settings from Section 6.
- One test level at full size (134.4 × 16.2 m) with **script-generated placeholder gradient plates** at the exact sizes in Section 4 (with grid/labels so scroll speed and density are visible).
- Full layer stack, depth fog, DoF, one directional + one omni light.
- CameraRig: follow, look-ahead, dead-zone, bounds clamp.
- Capsule player: run + jump on simple collision.
- Success: traversing the level shows correct parallax at every layer, no plate edges visible at 16:9 or 21:9, stable 60+ fps.

**Later milestones (out of M1 scope):** plate importer plugin, real AI art for a first level, character art/animation, normal-mapped lit plates, volumetric fog, cinematic camera triggers, chunk streaming for longer levels.
