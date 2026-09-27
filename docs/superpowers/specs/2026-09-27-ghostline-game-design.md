# Cyberpunk: Ghostline — Game Design

**Date:** 2026-09-27
**Status:** Draft — author's concept; open proposals at the end await decisions
**Technical spec:** `2026-09-27-illustrated-platformer-design.md` (rendering, scale, camera, tooling)

An 8-level illustrated 2.5D action-platformer adventure.

## 1. Premise & Tone

In a sprawling megacity whose infrastructure, transport and security forces are owned by one corporation, a former corporate enforcer discovers that the city's new automated security network is being trained on the memories and combat instincts of people who have disappeared.

The player is a disgraced street fighter carrying an **experimental blade that can disrupt the network**. Goal: reach the central broadcast tower and expose what is happening before the system goes fully operational. The journey climbs from the city's underground to its highest rooftops; each level has its own visual identity, a new melee challenge and a piece of the story.

**Tone:** Ghost in the Shell atmosphere, neon-soaked streets, industrial scale, expressive character animation, fast and readable melee combat.

**Key characters:** the player (disgraced street fighter); **Moth** (hacker ally who decodes the data); the corporation; the network's architect (copied into the system).

## 2. The Eight Levels

| # | Level | Setting / role | Story beat | Scenery | Combat focus | Boss / set piece |
|---|---|---|---|---|---|---|
| 1 | **The Last Train** | Underground subway · tutorial · escape | A stolen-data deal goes wrong in an abandoned station; drones seal exits, a security squad moves in. | Flooded tracks, broken ads, flickering fluorescents, trains passing in tunnels, steam-filled platforms. | Movement, basic attacks, dodge, parry, simple enemy patterns; fight a small squad, escape on a departing train. | **Set piece:** sprint along the roof of an accelerating train through a tunnel, jumping obstacles, evading security. |
| 2 | **The Neon Bazaar** | Underground market / street level · investigation | Reach Moth in a black-market district; the local gang has sold your location to security. | Crowded alleys, noodle stalls, holographic signs, overhead cables, balconies, rain-soaked streets. | Varied melee enemies: quick knife fighters, shielded guards, attackers from above. Kick open barriers; use elevated routes to reposition. | **Set piece:** chase across awnings and balconies amid flickering neon ads. |
| 3 | **The Iron District** | Industrial zone · factory · first major challenge | The data comes from a complex building experimental security hardware; infiltrate to retrieve source records. | Giant robotic assembly arms, molten-metal furnaces, suspended walkways, cargo lifts, huge ventilation shafts. | Heavy armored enemies, timed attacks, stagger, punishing slow attacks; moving platforms and machinery as hazards. | **Boss: The Foundry Warden** — armored machine, telegraphed attacks, vulnerable cooling system. **Set piece:** escape a collapsing production floor. |
| 4 | **The Ghostline Express** | Elevated railway · moving train · midgame spectacle | Source records move to the upper district on a secure maglev; board from a maintenance platform. | Moving trains, vast skylines, bridges between skyscrapers, lit stations, rain clouds. | Cramped cars and open roofs; ranged enemies force movement while combat stays melee-first. | **Boss:** corporate sword specialist who mirrors your movement and punishes predictable sequences. **Set piece:** fight between cars on a huge bridge, then leap to a second train. |
| 5 | **The Sunken Quarter** | Flooded residential district · exploration · revelation | The missing were sent to an abandoned district; descend to an underground memory-processing facility. | Half-submerged apartment blocks, glowing signs under water, broken skybridges, overgrown rooftops, flooded transit tunnels. | Vertical traversal, ambushes, agile enemies, electric hazards, branching routes. | **Reveal:** the system uses captured memories to predict and counter resistance. **Set piece:** explore a submerged tower, escape as flood defenses activate. |
| 6 | **The Garden of Glass** | Corporate district · infiltration · contrast | Emerge in the executives' district — clean, quiet, heavily monitored. | Glass towers, elevated gardens, indoor waterfalls, immaculate plazas, private skybridges, illuminated atriums. | Elite guards, coordinated groups, defensive formations; rewards parry, positioning, deliberate play. | **Mini-boss:** elite guard pair alternating attacks and covering each other. **Set piece:** a corporate reception in an indoor garden, from bright atrium into a dark service network. |
| 7 | **Above the Storm** | Rooftops · vertical ascent · final approach | The network is about to activate citywide; reach the broadcast tower before the upload completes. | Skyscraper roofs, giant antennas, rooftop gardens, storm clouds, aviation lights, lightning over the city. | Toughest regular enemies; aggressive fighters with support units; demanding platforming, wind gusts, exposed traversal. | **Boss:** security commander with a fast moveset and a drone that controls parts of the arena. **Set piece:** climb the outside of the tower in a thunderstorm. |
| 8 | **Ghost in the Machine** | Broadcast tower · finale · resolution | The network was shaped by a copy of the corporation's original security architect; it believes it protects the city by eliminating uncertainty. | Immense server chambers, suspended walkways, holographic city memories, huge machinery, a luminous core high above the streets. | Final gauntlet testing everything: parry, dodge, aerials, stagger, environment. | **Final boss:** the system's combat avatar — adapts to repeated patterns; phases shift between the real server chamber and simulated memories of earlier levels. **Ending choice:** destroy the core, or broadcast the records to the city. |

## 3. Combat

Principle: introduce new *uses* of a small, fixed moveset rather than piling on mechanics.

**Moveset**

| Move | Role |
|---|---|
| Light attack | Fast, reliable combo starter |
| Heavy attack | Slower; breaks enemy defenses |
| Parry | Rewards timing; opens counterattacks |
| Dodge | Quick repositioning; avoids attacks |
| Launcher | Sends certain enemies airborne for follow-ups |
| Finisher | Cinematic end to a staggered enemy |

**Progression**

| Levels | Combat development |
|---|---|
| 1–2 | Basic attacks, dodge, parry, enemy telegraphs |
| 3–4 | Heavy enemies, stagger, aerial combat, moving arenas |
| 5–6 | Ambushes, multiple enemy roles, coordinated encounters |
| 7 | Advanced enemy combinations, demanding traversal |
| 8 | Adaptation, mastery, final test of every mechanic |

**Signature effect:** the experimental blade briefly illuminates whenever it disrupts a network-controlled enemy — a consistent visual signature from the first subway fight to the final boss.

## 4. Visual Progression

Underground darkness → the city's brightest heights.

| Levels | Palette & space |
|---|---|
| 1–2 | Dark, cramped, saturated neon; low ceilings, tight close-up spaces |
| 3–4 | Industrial orange, steel blue; motion and enormous structures |
| 5 | Cool blues, reflective surfaces, fog, quiet abandoned spaces |
| 6 | Bright, clean, warm, almost unnaturally perfect |
| 7 | Deep navy, white lightning, high contrast, huge vertical spaces |
| 8 | Luminous cyan, white and gold; increasingly surreal architecture |

Per-level palettes map directly onto the technical spec's per-level environment (fog colour, colour-grading LUT, key light).

## 5. Open Proposals

Pending the author's decisions; see the design discussion of 2026-09-27. Once decided, accepted items move into the sections above and into the technical spec.
