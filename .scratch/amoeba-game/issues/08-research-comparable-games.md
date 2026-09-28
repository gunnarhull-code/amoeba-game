Status: resolved
Type: research

## Question

Research comparable games and mechanics to surface proven patterns before locking tickets 03-07:

- Spore's Cell Stage: growth/absorb loop, size-based predation rules.
- Osmos: size-based absorption, momentum-based movement.
- Feeding-frenzy-style games (agar.io, Feeding Frenzy): growth curves and multi-class predator/prey balance.
- Real krill/whale filter-feeding behavior, as inspiration for the whale level's krill-gathering-vs-whale-predation tension.
- Gravity-slingshot mechanics in other games (e.g. orbital-mechanics games), as inspiration for the gravity-planet level.

Summarize actionable patterns (what worked, what to avoid), not just descriptions of each game.

## Answer

Full findings, with sources, in [research/comparable-games.md](../research/comparable-games.md).

Key actionable patterns surfaced:

- **Size-comparison-as-color** (Osmos): a strict binary "smaller = blue/safe, bigger = red/deadly" visual language is the cheapest, most legible way to communicate Absorb-ability across a whole Class roster — recommend locking a similar convention early.
- **Speed inversely tied to size** (agar.io; implicit in Feeding Frenzy): every growth-game precedent examined uses "bigger = slower" as its primary lever for keeping smaller Classes/Loadouts viable against bigger ones — directly supports the already-locked "every level solvable multiple ways" premise.
- **Ratio-based eat thresholds beat fixed size brackets** (agar.io: must be smaller than ~90% of the eating cell) — worth combining with Class brackets rather than relying on brackets alone.
- **Movement-costs-size** (Osmos's mass-ejection propulsion) is a strong optional tension mechanic, but its own postmortem process spent real effort avoiding a "too small to move safely" stranded-player failure state — budget for that risk if adopted.
- **Diet-as-identity works best as a soft bonus, not a hard wall** (Spore Cell Stage): a Class/Loadout "preferred Food" that yields bonus Growth/Ammo (rather than blocking off other food) preserves solvability-multiple-ways.
- **Whale level**: real filter-feeding biology gives a ready-made puzzle structure — model the whale as a telegraphed, cooldown-gated lunge predator (not a continuous chaser), give it a "clogging" penalty that delays its next lunge after a big hit (2026 baleen-clog research), and tie krill exposure to a readable depth/timing migration cycle the player can learn to exploit. Avoid making the whale a generic fast/big chase predator — that throws away the biologically-grounded rhythm puzzle.
- **Gravity-planet level**: every precedent (Gravitar, Solar 2, Osmos's "force levels") treats unaided orbital control as a frustration trap. Ship a trajectory-preview/ghost-path aid as a core mechanic, not polish, and consider Solar 2's "nudge into stable orbit, then confirm-absorb" pattern instead of raw drift-and-collide for this level specifically. Fuel/thrust-as-a-draining-resource (Gravitar) maps naturally onto the existing Ammo concept.

No design decisions were made here — these are inputs for tickets 03 (growth/size rules), 04 (class roster), 05 (ability roster), 09 (whale level), and 10 (gravity-planet level).
