# Ghostline — Movesheet Template (for ChatGPT)

*Use this to design the player's moves. Each move gets one **move card** (text, filled in below) plus one **pose strip** image. Claude turns these into game animations on the cutout rig, so poses must be readable, side-on, and use the character exactly as in the art brief (`player-character-brief.md`, v3: Ghostblade in the left/organic hand, short blade in the right/cybernetic hand).*

## Rules for every move

- **Side view, facing right**, same character, same scale (720 px tall), plain background.
- **3–5 key poses per move**, left to right: **anticipation → strike → follow-through → recovery**. Mark which one is the moment of contact.
- **Blades in front of the body:** diagonal front arcs are the default (high→low, low→high). Spins, cross-cuts and big sweeps are for enders and specials. No plain overhead chops.
- **Show the arc:** draw the blade's path as a curved trail on the pose strip (lime for the Ghostblade, thin white for the short blade), so the trail shape is clear.
- Feet stay grounded unless it's an air move. Each pose must work as a **joint rotation** of the parts: no new body parts and no perspective turns toward the camera.

## Move card

```
Move:            (name, e.g. "Ghost Arc")
ID:              (short id, e.g. L1)
Input:           (e.g. Light / Heavy / Light after L1 / Block tap / Dodge then Light)
State:           (Sheathed → Drawn / Drawn / Air)
Blades:          (Ghostblade / Short / Both)
Purpose:         (opener, extender, launcher, guard break, finisher, counter...)
Timing:          startup ___ s | active ___ s | recovery ___ s   (typical light 0.08/0.08/0.2, heavy 0.3/0.12/0.4)
Key poses:       1) ...  2) ... (contact)  3) ...  4) ...
Arc:             (blade, direction e.g. "Ghostblade high-back → low-front diagonal", width: tight / wide / full spin)
Trail style:     (Ghostblade: lime data-ghost that breaks into pixels; Short: thin white steel streak)
Effect on enemy: (damage light/medium/heavy; knockback; launches; staggers; breaks guard)
Cancels into:    (which moves can follow, and when)
Notes:           (camera shake, hit-stop, sound idea, hair motion)
```

## Starter set to design

| ID | Move | Notes |
|---|---|---|
| DRAW | Draw to stance | Cross-draw both blades into the **defensive dual stance**. It should look fast and cool. |
| SHEATHE | Sheathe | Both blades back to the hips, into a relaxed stance. |
| STANCE | Drawn idle | Guarded, both blades ready, with a subtle breathing loop. |
| RUN_S / RUN_D | Run sheathed / drawn | Sheathed: free arms, hand on the long hilt. Drawn: blades low and trailing. |
| L1–L4 | Light combo | Alternate blades: fast, flowing, readable. L4 is a two-blade ender. |
| H1 | Heavy | A wide Ghostblade cut with a step-in that breaks guards. |
| X | Cross-slash | Both blades cut in an X. A combo ender. |
| QD | Quick-draw | The metal arm snaps the short blade out mid-combo (if it's sheathed) and extends the string. |
| LAUNCH / AIR1–3 | Launcher and air string | A rising cut, then short aerial cuts. |
| BLOCK | Crossed-blade block (hold) | Blades crossed in front, guarding. |
| PARRY / COUNTER | Timed block, then counter | Deflect, then a fast counter combo (2–3 hits). |
| ROLL / ROLL_ATK | Dodge roll, then roll attack | A low forward roll, then a rising slash out of it. |
| FINISH | Finisher on a staggered enemy | A cinematic multi-cut ending in a held pose, trails dissolving. |

Deliver the cards as markdown and the pose strips as PNGs named by ID (`L1.png`, `H1.png`, …).
