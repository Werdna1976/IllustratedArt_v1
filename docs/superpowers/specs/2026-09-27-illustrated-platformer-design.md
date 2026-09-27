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

A layer at camera distance *d* must cover `travel + visible_extent(d)`, where `visible_extent(d) = screen_extent × d / 20`. Pixel size = metres × 2000/d. Final authoring sizes add ~10% margin for shake, dolly and look-ahead.

| Layer | Depth z | Cam dist d | Scroll | Density | Authoring plate size (px) |
|---|---|---|---|---|---|
| Foreground (DoF-blurred) | −8 m | 12 m | 1.67× | 167 px/m | Sparse props only; authored at half density (~83 px/m) |
| **Gameplay** | 0 m | 20 m | 1.00× | 100 px/m | **13,440 × 1,800** |
| Near BG | +10 m | 30 m | 0.67× | 67 px/m | **9,600 × 1,600** |
| Mid BG | +40 m | 60 m | 0.33× | 33 px/m | **5,760 × 1,400** |
| Far BG | +100 m | 120 m | 0.17× | 17 px/m | **3,840 × 1,300** |
| Sky | ~+400 m | ~420 m | ~0.05× | — | **2,560 × 1,440** single plate |

Key properties:
- Plate **height stays ~1,300–1,800 px at every depth**; only width shrinks with distance. One upscaled AI-output height (~1,536 px) serves all layers.
- **~16 painted plates per level:** 7 gameplay, 5 near, 3 mid, 2 far, 1 sky (counted in 2,048-px-wide units, rounded).
- **Ultrawide (21:9)** adds ~3% to background widths; covered by the margin. Supported aspect range: 16:9 to 21:9. Narrower aspects (16:10, 4:3) show extra height and are clamped by level bounds.
- **Budget:** plates split into strips ≤ 2,048 px wide, BC7-compressed with mipmaps ≈ **75 MB VRAM per level**.

## 5. Rendering: Depth, Lighting, Camera

### 5.1 Plates
- Each plate strip is a `MeshInstance3D` quad using one shared shader `shaders/plate.gdshader`: alpha-scissor/alpha-blend, `unshaded` by default; a `lit` variant for gameplay/near layers.
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
- Jolt Physics, physics tick **120 Hz**.

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
shaders/   plate.gdshader
art/       levels/<level>/, characters/
addons/    plate_importer/
docs/
```

## 9. Milestones

**M1 — Specs proof (this spec's implementation scope):**
- Project settings from Section 6.
- One test level at full size (134.4 × 16.2 m) with **script-generated placeholder gradient plates** at the exact sizes in Section 4 (with grid/labels so scroll speed and density are visible).
- Full layer stack, depth fog, DoF, one directional + one omni light.
- CameraRig: follow, look-ahead, dead-zone, bounds clamp.
- Capsule player: run + jump on simple collision.
- Success: traversing the level shows correct parallax at every layer, no plate edges visible at 16:9 or 21:9, stable 60+ fps.

**Later milestones (out of M1 scope):** plate importer plugin, real AI art for a first level, character art/animation, normal-mapped lit plates, volumetric fog, cinematic camera triggers, chunk streaming for longer levels.
