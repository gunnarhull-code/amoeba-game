# Next steps: building the parked ideas

An ordered plan for the ideas still parked in [ideas.md](ideas.md). Health and stage loss is done (Level 3, see [the prototype ticket](issues/11-core-loop-prototype.md)), and everything below builds on it. Each idea debuts in its own new level so it can be felt on its own; Level 1 stays frozen. All numbers are starting guesses to tune by play.

Order and why: hairworm vines need nothing new except the health system, so they come first and are cheap. Meat chunks need a way to kill things, which the game does not have yet, so enemy health comes before them. The poison mine needs all of that plus a second ability button, so it comes last.

## 1. Hairworm wall vines (Level 7)

**Build:** a new `HAIRWORM` LevelMarker Kind (appended to the enum): a cluster of hair-thin worms anchored on a rock or the world edge, with `radius` = reach, `count` = number of strands, `damage` = health drained per second. When you come within reach a strand latches on: it draws as a line from anchor to you, pulls you slowly toward the wall, slows your steering, and drains health through the existing `hurt()` path, so health 0 drops a stage as usual. Visual: thin pale strands that sway at rest (easy to mistake for hair or debris), going taut and reddish when latched.

**Level 7 idea:** a narrow wall-lined channel where the food is, with hairworm clusters on both walls; a wide open route around exists but has biters in it. Teaches "slow drain you can escape" versus Level 3's "bite".

**Depends on:** Level 3 health (`health_on`, `hurt()`, stage loss). Nothing else.

**Open questions:**
- How do you escape? Options: dash breaks free (costs ammo), struggling (steer away hard for N seconds), or growing past a stage threshold snaps the strands. Recommendation: dash breaks free, and a few seconds of steering away also works, slowly.
- Are bigger stages immune, or does each cluster have a stage above which it can't hold you? (Fits the "same creature, different role" principle.)
- Can hairworms grab other creatures too (useful as a trap you lure biters into)?
- How it reads differently from the coral-larvae vine: larvae look solid and then swarm; hairworms never leave the wall and only grab.

## 2. Enemy health and a way to hurt things (Level 8, part 1) — PARTLY DONE in Level 6 (enemy health bars, spike, leech mine)

**Build:** give every creature a health value (scaling with its size, same shape as the player's `40 + 20 * stage`), and reuse the cracked-membrane ring drawing for them, so a hurt enemy looks hurt. First way to deal damage: a **dash ram**: dashing into a creature bigger than you deals damage based on your size instead of you bouncing off, and the bitten-back rule still applies. A creature at 0 health dies (Shatters). Smaller creatures are still absorbed whole as now; health only matters for things you can't eat yet.

**Depends on:** Level 3 health (the ring drawing and `hurt()` could be generalised to take a target). The `Thing` class gets `hp` and `hp_max` fields.

**Open questions:**
- Is the dash ram the right first damage source, or should killing only ever come from abilities (poison mine, later ones)? Dash ram is cheap and testable now.
- Should creatures regenerate health? (The player doesn't yet, see step 5.)
- Can enemies hurt each other (a biter bumping a krill school, a guard biting a biter)? That would make the scatter-food stealing more lively.

## 3. Meat chunks on kill (Level 8, part 2) — DONE in Level 6 (placeholder look)

**Build:** when a creature dies from damage it bursts into **meat chunks**: round amber-ringed organelle blobs like the concept art, flung outward like the stage-loss scatter (reuse that code: pickup delay, enemies can eat them). Total food in the chunks = the creature's food value (`FOOD_PTS`) or more, so killing something too big to eat is a way to grow. Chunk size scales with the creature, so a guard's chunks are big but each chunk is still edible at a lower stage than the guard itself.

**Level 8 idea:** a few big guards between you and the pearl; you can sneak past at low stage, or bait them into a toxic cloud and dash-ram them to death for a pile of chunks.

**Depends on:** step 2 (something has to die). Reuses the Level 3 scatter pellet code.

**Open questions:**
- Are meat chunks the same thing as **Fragments** in [CONTEXT.md](../../CONTEXT.md) (Food and Ammo, shaped like a smaller echo of the creature)? If yes, update the glossary instead of adding a new term; if no, define how they differ.
- Do chunks scale with the enemy's size, and are they edible at any stage or only when you are bigger than each chunk? (Recommendation: each chunk is small enough to eat 2-3 stages below the creature.)
- Do chunks give ammo as well as food?
- Do chunks rot/fade after a while, so they can't be farmed?

## 4. Ability buttons (plumbing, no level of its own)

**Build:** the game only has one ability today (dash on Space / A). The poison mine needs a second button and per-ability ammo costs. Add a second action (e.g. Shift / B / right mouse) and a small "loadout" of two abilities chosen per level (start with: the level scene picks them, a pre-level picker comes later per [the ability roster ticket](issues/05-ability-roster.md)). HUD shows both.

**Depends on:** nothing new; touches input and the HUD in `main.gd`.

**Open questions:**
- Is the loadout picked by the player before a level (the design in CONTEXT.md) or fixed per level for now? Recommendation: fixed per level in the prototype.
- Do all abilities share one ammo pool (the orbiting dots), or each have their own?

## 5. Poison mine ability (Level 9)

**Build:** the second ability. Press it to drop a mine under you (a dull, slightly food-like blob). You can't eat it. A creature that eats it is hurt by size: small creatures die (and burst into meat chunks); bigger creatures lose chunks of meat off their body, which drops their **health, not their size**: they still count as the same stage to eat. Mines last a limited time.

**Level 9 idea:** a pearl guarded by something you can never out-grow in this level; the intended route is to lay mines on its patrol path, then pick up the chunks it drops.

**Depends on:** step 2 (creature health), step 3 (meat chunks, also for chunks torn off a living creature), step 4 (a second button).

**Open questions (from ideas.md):**
- Ammo cost, how many mines can exist at once, how long a mine lasts.
- Are enemies attracted to it (does it look like food to them)? Recommendation: yes, mids go for it like dropped food, which reuses the food-seeking code from Level 3.
- Can it hurt the player (e.g. if another creature carries it)? Recommendation: no, keep it simple at first.
- How much health does a "chunk off the body" take from a bigger creature, and how many chunks drop?

## 6. Health follow-ups (any time, decide before tuning)

Things Level 3 left simple on purpose that need a decision once the above is in:
- **Health regeneration:** none at the moment, so damage piles up until you lose a stage. Options: slow regen when not hurt for a few seconds, or regen only from eating.
- **Stage-up refill:** stage-up currently adds the extra capacity only (a hurt amoeba stays hurt). Alternative: full refill on stage-up, which is more forgiving.
- **Shrimp and whales under health:** shrimp still use "three at once = devoured" and whales aren't in any health level yet. Decide whether they bite/drain instead.
- **Retrofit Level 2?** Level 2 has health off. Turning it on is one line in its scene (`health = true`) if the user wants it.
- **Damage numbers:** bite and drain values in the Level 3 scene are first guesses.

## Level 6: ability playground (built 2026-11-08)

- **Gravity nuclei** (LevelMarker kind NUCLEUS): solid core, pull that fades out at its reach; your momentum lingers inside the pull so you can slingshot.
- **Abilities** (LevelDef `abilities` on): Q / E or LB / RB to choose, F / X / right-click to use.
  - Rocket: a long, very fast, slightly steerable burst.
  - Harpoon: hook below `harpoon_upgrade_stage` (drags things in; anything 1.6x your size hauls *you* in; hooks onto rock and pulls you there). From that stage on it becomes a spike that damages.
  - Ink: black cloud; enemies flee it, and lose you while you're inside.
  - Leech mine: dropped behind you, latches onto the first enemy to touch it, 9 damage/s for 5 s.
  - Flash: stuns every creature near you for about 3 s (they can't move, bite or eat).
- **Enemy health + meat chunks**: health bars appear once something is hurt; killed creatures burst into edible meat chunks.
- **Angler fish** (kind ANGLER, also in Levels 5 and 6): nearly invisible in the dark, dangles a fake golden pearl; swim up to it and it lunges.

Also on 2026-11-08: health is on for **every** level (bites scale with the square of how much bigger the biter is, so huge things effectively swallow you in one bite), and a first deep-sea visual pass (darker water, marine snow, glowing motes, vignette, your own faint glow).

## Rule changes + Level 6 rebuild (2026-11-08, later)

- **No stage numbers anywhere** (HUD, banners, labels over creatures, pearls, edible walls). Test whether size alone reads. Still left as hints: rim colours (blue = edible, orange = dangerous) and the purple edible walls brightening as you near their size.
- **Bring the pearl home** on every level, Level 1 included: swallowing the golden pearl no longer wins. Carry it back to the glowing home circle around START (LevelDef `home_radius`). Dashing (space) or rocketing drops it; it pops out behind you and can't be re-swallowed for 1.2 s. Only you can eat it. The free stage is given only the first time.
- **Rocket** is an afterburner: slow first quarter, then a big kick; steer at most `rocket_turn_limit_deg` (45) off the launch heading.
- **Creatures flip instead of rotating**: always right side up, only a small up/down tilt.
- **Sea monkeys** follow regular enemy rules: hatch at about 2 stages bigger than a newborn cell, bite (12), chase while bigger than you, flee/edible once you're bigger. The 3-at-once rule is gone.
- **Meat chunks** tear off medium and big creatures (radius 20+) as they lose health, one per share of health lost; small ones leave none. Globby, never fade, always edible, sized by food value.
- **Whales:** 2 minutes between passes; slow digestion inside (LevelDef `whale_digest`, 3 hp/s); full belly just stops swallowing (krill aren't killed); krill respawn on the whale level, capped at 150 (`krill_respawn_limit`); the pearl no longer glints through the body.
- **Red screen-edge flash** whenever you lose health. **Full heal** on growing a stage.
- **Food rides currents by default** (CurrentPath `food_count`, 25; refills at the current's start).
- **Eating notes** are an Inspector setting on the Main node (`eat_notes`, e.g. "C4 D4 E4 G4 A4").
- **Level 6 rebuilt as the angler deep** (26000 x 14000): 20 anglers, sized from the level's total food so you can never get big enough to eat one. 19 carry decoy balls; the one in the locked vault (far east) carries the real golden pearl. 3 keys in 3 nests open the vault gate: one behind an egg minefield, one behind a toxic cloud next to a gravity nucleus, one behind a current pouring out of its door (rocket in). 9 more decoy nests with food. To take the real pearl, stun the angler (flash) or hide in ink, then pluck it. Plucking a decoy wakes the angler and it lunges.
- Open: is the harpoon order right (hook first, spike from stage 4)? Can you reach half a whale's size before the whales eat the map (playtest)?
- **Dash (space) is the one ability every level always has** (1 ammo). Rocket, harpoon, ink, leech mine and flash are secondary, picked per level with the LevelDef `ability_list` checkboxes, and each costs ammo (rocket 2, harpoon 1, ink 2, leech 1, flash 3). Not enough ammo = a thud and "NEED n AMMO".
- **Fragments everywhere:** Level 6 now has 1,600 loose fragments plus 30-40 in each nest. Each gives +1 ammo but only a quarter of normal growth (LevelDef `fragment_value`), so the anglers stay uneatable (now 410+ radius). Levels 1-5 already had 220-1,500.
