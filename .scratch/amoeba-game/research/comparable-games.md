# Research: Comparable Games & Mechanics

Resolves: [08-research-comparable-games.md](../issues/08-research-comparable-games.md)

Framed against project terms from [CONTEXT.md](../../../CONTEXT.md): Orb, Absorb, Amoeba, Class, Ability, Ammo, Growth, Fragment, Shatter, Food.

Goal of this doc: surface **actionable patterns** — what worked, what to avoid — for tickets 03 (growth/size rules), 04 (class roster), 05 (ability roster), 09 (whale level), and 10 (gravity-planet level). This is research only; no design decisions are made here.

---

## 1. Spore's Cell Stage — growth/absorb loop, size-based predation

Sources: [Spore (2008 video game) — Wikipedia](https://en.wikipedia.org/wiki/Spore_(2008_video_game)), [Cell Stage — SporeWiki](https://spore.fandom.com/wiki/Cell_Stage), [Spore/Cell Stage — StrategyWiki](https://strategywiki.org/wiki/Spore/Cell_Stage)

**Mechanics observed:**
- Player commits to a diet at stage start — herbivore, carnivore, or omnivore — by choice of starting mouth part. This is a *lasting* commitment: it locks which mouth parts are available for the rest of the stage, and it carries forward to determine diet in the next stage (Creature Stage).
- Growth happens via **parts + DNA points**, not a single scalar. Eating food/prey grants DNA points (spend currency); finding "meteor bits" or defeating other cells grants new *parts* (spikes, extra mouths, fins, etc.) that must be socketed in a cell editor between "生成" (mate/reproduce) moments. So growth is discrete/editorial (visit an editor, choose a part) rather than continuous — size is one axis among several (speed, attack, defense parts).
- Predation/threat is read primarily through relative size in the environment (bigger creatures are dangerous, smaller are prey) plus diet-type friction: eating the wrong food type (e.g., meat as a herbivore) is possible but comes with a penalty/inefficiency rather than a hard block.
- Threat evasion is spatial/reactive (flee, use spines/toxin parts) rather than a distinct "ability."

**Actionable patterns:**
- **Diet-as-identity works as a soft constraint, not a hard wall.** A Class or early Loadout choice that colors *what* counts as efficient Food without fully blocking off other options gives players a build identity without punishing experimentation. Consider whether Amoeba Classes should have a "preferred Food" that yields bonus Growth/Ammo, rather than an eat/can't-eat binary — this keeps the level "solvable multiple ways" premise (map.md) intact.
- **Decouple Growth from a single "size" stat.** Spore's split between DNA points (currency) and parts (discrete unlocks) suggests Growth need not be purely "get bigger" — it can also mean unlocking new Ability-relevant traits. Worth cross-referencing with ticket 03's Growth/Size split and ticket 05's Ability roster.
- **What to avoid:** Spore's Cell Stage is widely regarded (including by its own team's later commentary and critics) as the shallowest, shortest stage in the game — mechanically it's closer to a warm-up/tutorial than a fully realized loop. Don't treat "Spore-like" as license to under-design the core loop; the Cell Stage is the *reference silhouette* for this project, but the actual depth needs to come from this project's own Ability/Class/Ammo systems, since Spore's Cell Stage alone doesn't have enough mechanical depth to imitate wholesale.

---

## 2. Osmos — size-based absorption, momentum-based movement

Sources: [Osmos — Wikipedia](https://en.wikipedia.org/wiki/Osmos), [GDC Vault: Minimalist Game Design: Growing Osmos (Hemisphere Games, IGS 2010)](https://www.gdcvault.com/play/1012298/Minimalist-Game-Design-Growing), [GDC Vault: Minimalism and OSMOS: a Post-Mortem](https://www.gdcvault.com/play/1014042/Minimalism-and-OSMOS-a-Post), [Hemisphere Games GDC talk post](https://www.hemispheregames.com/2010/04/01/gdc-talk-minimalist-game-design-growing-osmos/)

**Mechanics observed:**
- **Propulsion = self-cannibalizing thrust.** The player mote moves by ejecting a small piece of its own mass in the opposite direction (conservation of momentum). This means *every unit of movement costs Growth/size* — mobility and size are the same resource, directly opposed. There is no separate "fuel" stat.
- **Binary size-comparison rule, color-coded.** Motes smaller than the player render blue (safe to absorb on contact); motes larger render red (contact = player is absorbed = game over). No partial states, no combat — the entire interaction model is "touch it, and the size comparison decides who wins," fully legible via color alone.
- **Level typology:** "sentient" levels (motes that actively react/compete with the player), "ambient" levels (drifting motes, mostly a physics puzzle), and "force" levels (dominated by large gravitational bodies where the player must plot orbits/trajectories — includes an in-game trajectory-prediction tool to help players reason about orbital paths before committing).
- Postmortem candor (per Hemisphere's own talks): the minimalist "one input dimension" design was a deliberate constraint chosen specifically to keep the interface legible across very different platforms (PC/Mac/Linux → later iPad), and much of their iteration was about interface/feedback clarity and pacing rather than adding mechanical breadth.

**Actionable patterns:**
- **Movement-costs-size is a strong, legible tension mechanic** directly relevant to the "puzzle-action" premise in map.md. Worth considering (in ticket 03) whether some subset of player movement/Abilities should cost Growth/size rather than a separate Ammo pool — or conversely, deliberately *not* doing this and instead using it only for specific Abilities, to differentiate from Osmos rather than clone it.
- **Binary red/blue threat coloring is the single most copy-worthy pattern here.** It's a proven, at-a-glance way to communicate "can I Absorb this" vs. "will this Absorb me," which maps directly onto Class-based size tiers (ticket 04). Recommend the Class roster settle on a consistent color/value language for "smaller than player" vs. "bigger than player" at a glance, independent of species/silhouette design.
- **"Force levels" with a trajectory-prediction aid is a direct precedent for the gravity-planet level (ticket 10).** Osmos shipped an explicit UI tool to preview orbital paths precisely because unaided gravity-well navigation was found to be too opaque/frustrating for players to reason about turn-to-turn. Strong signal: don't ship gravity-slingshot mechanics without some form of trajectory feedback (ghost path, predicted arc, etc.).
- **What to avoid:** because propulsion directly consumes the player's own size, Osmos levels can create a lose-lose spiral (too small to move safely, but movement is the only way to reach food) — their postmortem process was substantially about pacing/tuning to avoid stranding the player. If Growth-costs-movement is adopted even partially, budget playtesting time specifically for "stranded/too-small-to-recover" failure states.

---

## 3. Feeding-frenzy-style games (agar.io, Feeding Frenzy) — growth curves, multi-class balance

Sources: [Agar.io — Wikipedia](https://en.wikipedia.org/wiki/Agar.io), [Feeding Frenzy (video game) — Wikipedia](https://en.wikipedia.org/wiki/Feeding_Frenzy_(video_game)), [Feeding Frenzy 2 — Wikipedia](https://en.wikipedia.org/wiki/Feeding_Frenzy_2)

**Mechanics observed (agar.io):**
- Continuous **mass decay over time** (cells lose a small % of mass/second) — this is a soft timer that forces constant re-engagement with the Food loop; it prevents a player from growing once and coasting.
- **Speed is an inverse function of mass** (roughly speed ∝ mass^-0.44 in community-documented formulas) — bigger is slower, by design, so raw size is never a dominant strategy on its own; agility is the counter-play available to smaller/weaker Classes.
- **Eat threshold is a ratio, not a fixed size band**: a cell can only absorb another cell that is some margin smaller (commonly cited as needing to be smaller than ~90% of the eating cell's size) — this avoids "I am technically 1 unit bigger, I win" edge cases and makes the size gap feel meaningfully decisive when it happens.
- **Viruses as a symmetry-breaker for smaller players**: an environmental hazard that only punishes large cells (fragmenting them into many small pieces when they cross a size threshold while touching one), giving small players a way to threaten big ones indirectly. This is the core "how do small Classes stay relevant against big ones" answer.
- **Splitting/ejecting mass** are player-initiated ways to trade size for tactical options (covering more ground, feeding an ally, baiting a virus onto an enemy).

**Mechanics observed (Feeding Frenzy):**
- Explicit discrete **size tiers tied to a food chain** (player controls a sequence of species across the campaign, each with a hard "what you can eat" ceiling), rather than agar.io's continuous mass value.
- **"Frenzy" streak mechanic**: rapid consecutive eats within a short window trigger a scoring multiplier state that decays quickly without continued action — a soft combo-meter layered on top of the base grow/eat loop, purely to reward tempo and aggression rather than caution.

**Actionable patterns:**
- **Decay/upkeep pressure is what turns "grow by eating" into a game rather than a monotonic curve.** Recommend ticket 03 consider whether Growth should have any passive decay or upkeep cost (even level-specific, e.g. only in the whale level, tied to time-pressure) to avoid a snowball-and-coast dynamic once the player is sufficiently big.
- **Speed/mobility inversely tied to size is the single most load-bearing balance lever in the entire "growth game" genre** — both agar.io and (implicitly, via bigger/slower predators) Feeding Frenzy use it. This directly informs the Class roster (ticket 04): if Classes range smaller-than-player to bigger-than-player, tying bigger Classes to slower movement/telegraphed attacks is a proven way to keep smaller Classes/Loadouts viable, supporting the "solvable multiple ways" design premise already locked in map.md.
- **An eat-threshold expressed as a ratio (not an absolute size delta) reads better than a fixed cutoff** — worth a direct recommendation to ticket 03: define "can Absorb X" as a relative-size rule (e.g., "smaller than N% of player's current size") rather than fixed size-class brackets alone, or use both (Class bracket AND relative-size ratio) so that a same-Class matchup still resolves sensibly.
- **A frenzy/combo meter is a cheap way to add moment-to-moment texture to a fundamentally simple Absorb loop** without inventing new systems — worth flagging to ticket 05 (Ability roster) or a future juice/feel pass, not necessarily this ticket's business to decide.
- **What to avoid:** agar.io's design leans on multiplayer social dynamics (teaming up on a leader, communicating via feeding) that don't transfer to a solo single-player game — its virus/split/eject toolkit exists largely to create *player-vs-player* social plays. For this single-player project, the transferable core is decay pressure + speed/size inversion + ratio-based eat threshold; the split/virus/social layer is not directly applicable and shouldn't be copied wholesale.

---

## 4. Real krill/whale filter-feeding behavior — for the whale level

Sources: [Constraints on lunge feeding: krill can clog the baleen of filter-feeding whales — J. Exp. Biol. 2026 (Stanford Hopkins Marine Station)](https://doi.org/10.1242/jeb.251852) (via [phys.org summary](https://phys.org/news/2026-07-krill-buildup-fin-whale-filter.html), [EurekAlert summary](https://www.eurekalert.org/news-releases/1134617)), [The characteristics of krill swarms in relation to aggregating Antarctic blue whales — Scientific Reports 2019](https://www.nature.com/articles/s41598-019-52792-4), [Bait ball — Wikipedia](https://en.wikipedia.org/wiki/Bait_ball)

**Behavior observed:**
- **Lunge feeding is a single, high-cost, high-reward "engulf" action, not continuous grazing.** A ~20m fin whale engulfs ~60 m³ of water and ~144 kg of krill in one lunge, then spends ~31 seconds expelling the water through baleen before it can lunge again — meaning whales get roughly 6 lunges per ~8-minute dive. This is a hard cooldown/action-economy pattern, not a toggleable "eat mode."
- **Baleen can clog.** New (2026) biomechanical modeling shows that if krill accumulate on the baleen faster than water drains, the whale's next lunge is delayed dramatically (modeled worst case ~16 minutes to clear, vs. the normal 31 seconds) — i.e., overeating in a single lunge has a steep diminishing-returns/penalty curve, not a free scaling reward. Whales apparently need to keep ~15% of the baleen "window" clear to stay efficient.
- **Krill swarming is fundamentally a predator-avoidance behavior that backfires against bulk predators.** Dense swarming defends against small predators that eat krill one at a time (e.g., penguins), but that same density is exactly what makes a swarm attractive to a lunge-feeding whale — the defense mechanism against small threats is a dinner bell for big ones.
- **Krill availability is patchy and time-gated by vertical migration.** During daylight, krill sit in deep, dense patches; whales largely don't feed then. As krill migrate toward the surface (dawn/dusk), patches become shallower and somewhat less dense, and *that's* when whale feeding activity spikes — feeding rate (lunges/hour) is highest when prey is shallow, and drops off with depth. Blue whales specifically prefer shallow, high-density swarms over diffuse deep layers to maximize energy return per lunge.

**Actionable patterns — directly for the "whale level" (ticket 09):**
- **Model the whale's threat as a rare, telegraphed, high-commitment lunge rather than a constantly-chasing predator.** A whale that surfaces/dives on a readable cycle and executes a single big "engulf" action with real windup and real recovery/cooldown is both biologically accurate and a much better puzzle-action pattern (readable danger windows) than a whale that continuously hunts the player 1:1.
- **Give the whale a soft "clogging" penalty for over-lunging**, mirroring the 2026 baleen-clog finding: if the whale successfully engulfs a very dense/large krill patch, make its *next* lunge meaningfully delayed. This creates a natural rhythm the player can learn and exploit (harvest right after a big whale lunge, while it's "digesting"/recovering) — directly serviceable as a core skill test for the level.
- **Tie krill availability to a depth/time cycle the player can read and act on**, mirroring real vertical migration: krill schools are deep/dense/safer-from-the-whale at some points and shallow/exposed/whale-vulnerable at others. This gives the player a legible "when is it safe to harvest vs. when is the whale about to strike" rhythm, rather than a flat always-on threat, and it's literally the mechanism biologists document as driving real whale feeding timing.
- **Swarm density as a double-edged sword**: since real krill swarm tightly specifically because it's safer against small predators but riskier against bulk predators, consider making player-Amoeba's own predation behavior (picking off krill one at a time, off the edge of a school) explicitly *safer* than being near/inside a dense swarm right as the whale lunges — this mirrors the biology (whale wants density, player should generally avoid it) and gives a clean risk/reward read.
- **What to avoid:** don't make the whale a conventional chase predator that's simply "big and fast" — that collapses the level into generic predator-avoidance and throws away the more interesting, biologically-grounded rhythm-and-timing puzzle (readable lunge cycles + clogging cooldown + migration timing) that real filter-feeding behavior offers "for free" as design material.

---

## 5. Gravity-slingshot / orbital-mechanics mechanics in other games — for the gravity-planet level

Sources: [Gravitar — Wikipedia](https://en.wikipedia.org/wiki/Gravitar), [Getting Good: Gravitar — PrimeTime Amusements](https://primetimeamusements.com/getting-good-gravitar/), [Solar 2 Review — Hey Poor Player](https://www.heypoorplayer.com/2017/05/28/solar-2-review-late-to-the-game/), [Solar 2 Review — PC Gamer](https://www.pcgamer.com/solar-2-review/), [Osmos — Wikipedia (force levels)](https://en.wikipedia.org/wiki/Osmos), [Slingshot: Orbital Mechanics Space Game](https://slingshot.indiega.me/), [Gravity assist — Wikipedia](https://en.wikipedia.org/wiki/Gravity_assist)

**Mechanics observed:**
- **Gravitar (1982):** Ship is continuously pulled toward gravity sources (planets, and a deadly central sun in the overworld); some universes even use *inverted* ("negative") gravity to force players to re-learn intuitions. Fuel is a hard, ever-draining resource consumed by thrusting and by using the tractor beam (which doubles as shield); running out of fuel ends the game independent of lives. A tractor beam lets the player pick up fuel-refill pickups from the surface without landing.
- **Solar 2:** Growth loop is literally "get things to orbit you, then consume them" — the player nudges asteroids into a stable orbit around their own gravity well, then triggers an explicit "absorb" input once an object is safely orbiting, rather than growing on mere contact. Reviewers flag that gravity-based controls are the game's main friction/difficulty spike ("fiddly... difficult even after a patch"), i.e., pure unaided orbital-physics control reads as frustrating to a general audience without assistance.
- **Osmos "force levels":** large static gravity wells the player must navigate around/through; the game ships a dedicated trajectory-preview tool specifically for these levels (see Section 2) — direct evidence that orbital mechanics need assistive UI to stay fun rather than just accurate.
- **Gravity assist (real physics, for reference):** a spacecraft's path is altered by borrowing momentum from a massive body during a close flyby, changing speed/direction without expending fuel — the "free" energy trade that makes slingshotting appealing is that you gain net velocity by interacting with a gravity well correctly, rather than only ever losing energy to it.

**Actionable patterns:**
- **"Orbit, then act" is a more controllable interaction pattern than "collide to absorb" for gravity-based levels.** Solar 2's model (nudge into stable orbit → explicit trigger to consume) gives the player a clear intermediate feedback state ("it's captured, now I can choose to eat it") instead of demanding pixel-perfect real-time collision under drifting gravity — worth strong consideration for how "Absorb" should work specifically in the gravity-planet level (ticket 10), even if regular levels use direct contact-based Absorb (per Osmos/Spore norms above).
- **Fuel/thrust should be a distinct, visibly-draining resource in a gravity level**, per Gravitar — this maps naturally onto this project's existing Ammo concept (visually orbiting the player, per CONTEXT.md) if Ammo or a similar meter is spent on active thrust/course-correction against gravity, separate from the main Growth/size stat. Flag for ticket 03/05 crossover: does moving *against* a gravity well cost Ammo, Growth, or a level-specific fuel resource?
- **Ship a trajectory-preview aid.** Both Osmos and general gravity-assist mission planning (patched-conic method: reason about each leg of a flyby locally) point the same direction: don't ask players to mentally integrate an n-body simulation in real time. A ghost-path/predicted-arc indicator is close to a hard requirement, not a nice-to-have, if ticket 10 wants gravity-slingshotting to feel skillful rather than trial-and-error.
- **Use inverted/unusual gravity sparingly as a difficulty lever**, per Gravitar's "negative gravity" universes — a good escalation tool for later gravity-planet content once the base mechanic is taught, rather than introducing it on day one.
- **What to avoid:** Solar 2's reviewers specifically call out unassisted gravity controls as the game's main frustration point even after a balance patch — strong signal that "realistic," unaided orbital mechanics are a genre-wide difficulty trap. Recommend ticket 10 treat trajectory assistance (preview arcs, snap-to-orbit assists, or generous capture tolerances) as part of the *core* mechanic spec, not a stretch-goal polish item.

---

## Cross-cutting takeaways (for tickets 03–05, 09–10 generally)

1. **Size-comparison-as-color** (Osmos) is the cheapest, most proven way to make "can I Absorb this" legible across a whole Class roster — recommend locking this early regardless of what else changes.
2. **Speed/mobility inversely tied to size** (agar.io, implicitly Feeding Frenzy/Osmos) is the primary lever every one of these games uses to keep smaller Classes/Loadouts relevant against bigger ones — directly supports the already-locked "every level solvable multiple ways" premise.
3. **Ratio-based (not fixed-band) eat thresholds** (agar.io) resolve edge cases better than hard Class brackets alone; consider combining both.
4. **Movement-costs-resource** (Osmos's mass-ejection propulsion) is an available but optional tension mechanic — strong thematic fit, but budget for the "stranded, too small to move" failure mode it can create.
5. **The whale level should be built around a telegraphed, cooldown-gated lunge plus a readable krill depth/timing cycle**, not a continuous chase — this is a direct, biologically-sourced answer to "how do I make harvesting-vs-being-eaten feel like a puzzle and not a QTE."
6. **The gravity-planet level needs an explicit trajectory-assist affordance and probably an "orbit, then confirm-absorb" interaction** rather than raw contact-to-absorb under drifting gravity — every genre precedent examined treats unaided orbital control as a frustration risk, not a feature.
