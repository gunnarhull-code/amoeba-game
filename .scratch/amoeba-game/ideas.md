# Ideas parking lot

Ideas not yet built, unless marked IMPLEMENTED. Pull one into a new level or ticket when ready. Level 1 stays frozen. The build order for the rest is in [next-steps.md](next-steps.md).

## Health and stage loss (IMPLEMENTED in Level 3)

Built as Level 3 (`game/levels/level_3.tscn`, health turned on per level by `LevelDef.health`; levels 1 and 2 play as before). What was built is described in the Level 3 section of [the prototype ticket](issues/11-core-loop-prototype.md). Original notes:

- The player has **health** separate from size/stage.
- If anything reduces health to 0, the player **drops down one stage** instead of dying outright (health refills; exact refill amount undecided).
- Some enemies take health in large amounts (big bites); others drain it slowly.
- Decided: at stage 1, 0 health = death, which means restart the level.
- Decided: losing a stage (e.g. 6 to 5) drops you back to that lower stage and **scatters food worth 20% of what it takes to get back up** (the cost of 5 to 6) around where you were hit. Decided: you restart the lower stage at zero food; you can collect the scatter again; enemies can eat it too.
- Decided: health scales with stage. Display: health is the membrane ring around the body (it thins, cracks and dims as you are hurt) so no separate health bar is needed. Built in Level 3.

## Killing things leaves meat chunks (idea)

- A killed enemy disappears into **meat chunks** that look like the organelle-rich cells in the concept art (round amber-ringed blobs, see map.md concept art).
- Chunks are Food (ties into the existing Fragment/Food economy in CONTEXT.md).
- Open: do chunks scale with the enemy's size, and are they edible at any stage or only by smaller/equal players?

## Poison mine (Ability idea)

- Drop it under you. The player **cannot eat it**.
- Anything that eats it is hurt depending on its size:
  - small creature: dies.
  - bigger creature: loses **chunks of meat** off its body. This lowers its **health, not its size** (it still counts as the same stage to eat).
- Open: ammo cost, how many mines at once, how long a mine lasts, whether enemies are attracted to it (look like food?), whether it can hurt the player if another creature carries it.

## Hairworm vines (environmental hazard idea)

- Hair-worm-like vines **fixed to a wall**.
- They **grab you and slowly eat you**, counting down your health, and ultimately your stage (via the health-zero rule above).
- Open: how to escape (dash? cut free? get bigger?), reach/length, whether larger players are immune, and how it differs from the coral-larvae ambush vine.

## Where this touches the design tickets

- Health and meat chunks affect [growth and size rules](issues/03-growth-size-rules.md) and [win/lose conditions](issues/06-win-conditions.md).
- Poison mine is a candidate for the ability roster ([05](issues/05-ability-roster.md) if it exists).
