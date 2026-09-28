# Amoeba Game — Map

## Destination

A lean, decisions-first design spec — not a full GDD — sufficient to unblock building a playable vertical-slice prototype: the core grow/absorb loop, the two signature levels (the whale level and the gravity-planet level), and enough of the 5-class amoeba roster and 8-ability roster to prove the "every level solvable multiple ways" premise actually holds up in play.

## Notes

- Domain glossary lives at [CONTEXT.md](../../CONTEXT.md) — consult it for canonical terms (Orb, Absorb, Amoeba, Class, Ability, Loadout, Ammo, Growth, Fragment, Shatter, Food). Update it, don't restate it, when a ticket resolves a term.
- Assumed working constraints (not yet pushed back on by the user): solo/hobby pace, no fixed deadline, leaning Godot for a 2D physics-driven prototype, no specific target audience yet ("the game you want to play" first).
- Art direction is locked (see Decisions so far) — don't re-litigate it in mechanic-design tickets; only reference it.
- For `grilling`-type tickets, call the Skill tool for `grilling` and `domain-modeling` per the wayfinder default.
- Project has no git repo yet. Ticket 01/02 will decide whether/when to initialize one as part of engine scaffolding.

## Decisions so far

- Core premise: single-player puzzle-action, Spore Cell Stage-like — grow by absorbing smaller Amoebas, must be bigger than an Orb to Absorb it (the goal). Hand-authored levels, explorable map 4-8x the visible screen.
- Level philosophy: every level must be solvable multiple ways (e.g. eat-everything vs. outsmart-bigger-predators-to-reach-orb). Player picks a 2-Ability Loadout from a roster of 8 before entering a level; the level must remain solvable via most Loadout combinations, each in its own way.
- Ability/Ammo visual language: the player's Ammo/Ability inventory visually orbits the character; more Ammo widens the orbit. The player's size and art visually evolve as it grows.
- Destruction economy: when an Amoeba Shatters, it produces Fragments shaped like a smaller-scale echo of the original creature; Fragments serve as both Food and Ammo.
- Art direction: translucent, cell-under-a-microscope look, where creatures share/bleed a bit of the light value of their surroundings; light-toned player vs. darker-toned enemies for readability; abstract hybrid of "underwater" and "in space" mood, not literally either; creature movement/silhouette should be recognizable-but-abstracted (evokes a real animal without literally copying it — krill schooling and fleeing on whale-detection is the reference example).
- Audio/feel direction: player actions (Absorbing, using an Ability) should land with satisfying, musical feedback — the reference is the tactile pleasure of "caressing a piano," i.e. discrete, pitched, almost-melodic notes per action rather than generic impact SFX.
- Signature level 1 ("whale level"): named as fog, not yet ticketed in detail — awaits [Design the whale level in full](issues/09-whale-level-design.md).
- Signature level 2 ("gravity-planet level"): named as fog, not yet ticketed in detail — awaits [Design the gravity-planet level in full](issues/10-gravity-planet-level-design.md).
- [Research comparable games](issues/08-research-comparable-games.md): Osmos/agar.io/Spore/Feeding Frenzy point to color-coded size threat + inverse speed-to-size as core balance levers; krill/whale biology suggests a telegraphed cooldown-gated lunge predator for the whale level; orbital-mechanics precedents (Gravitar, Solar 2, Osmos) all require a trajectory-preview aid for the gravity-planet level. Full findings in [research/comparable-games.md](research/comparable-games.md).

## Not yet specified

- Broader level roster beyond the two signature levels, and any meta-progression / level-select structure between levels.
- Whether the vertical slice needs any narrative/framing wrapper at all, or is purely mechanical.
- Solo-dev art/audio production approach in detail (tools, whether any outsourcing) — touched by ticket 01 but may need its own pass once engine is chosen.
- Difficulty/failure-state philosophy across levels beyond the two specific "devour" risks already named (whale level, gravity level) — e.g. is there a lives/retry system, permadeath, checkpointing.
- Full audio direction beyond the "satisfying, piano-like notes on action" principle — music, ambient soundscape, whether pitch/notes are diegetic or purely feedback.

## Out of scope

(none yet)
