# Amoeba Game

A single-player puzzle-action game (working title) in which the player controls a tiny amoeba that must grow by absorbing smaller creatures in order to reach and absorb a level's Golden Pearl(s). Abstract, translucent, cell-under-a-microscope visual register set in a mood that hybridizes underwater and outer-space.

## Language

**Golden Pearl**:
The goal object of a level. The player must be larger than a Golden Pearl to Absorb it; doing so is (one form of) the level's win condition. A level may contain one or more Golden Pearls.

**Absorb**:
The act of consuming a smaller Amoeba, Fragment, or Golden Pearl, converting it into Growth and/or Ammo for the player.
_Avoid_: eat, consume (informal synonyms used loosely in conversation; prefer Absorb in design docs)

**Amoeba**:
Any living creature in the world, including the player. Every Amoeba belongs to one of five Classes.

**Class**:
One of five size/behavior tiers an Amoeba belongs to, ranging from smaller-than-player to bigger-than-player. Determines relative size, movement personality, and threat/utility role. (Full roster: [Finalize the class roster](./.scratch/amoeba-game/issues/04-class-roster.md))

**Ability**:
One of eight distinct player actions (combat-oriented or evasion-oriented). The player equips exactly two as a Loadout before entering a level. (Full roster: [Finalize the ability roster](./.scratch/amoeba-game/issues/05-ability-roster.md))

**Loadout**:
The pair of Abilities a player selects before entering a level.

**Ammo**:
A consumable resource that some Abilities expend. Visually orbits the player character; a larger Ammo count widens the orbit radius.

**Growth**:
The increase in the player's Size resulting from an Absorb. Also visually evolves the player's art, not just its size.

**Fragment**:
The pieces left behind when an Amoeba is destroyed (Shatters) — shaped like a smaller-scale echo of the original creature. Fragments serve as both Food and Ammo.

**Shatter**:
The event of an Amoeba being destroyed, producing Fragments.

**Food**:
Loose, non-agentive matter that grants Growth (and sometimes Ammo) without requiring the player to out-fight or out-maneuver a live Amoeba. Distinct from Absorbing a live Amoeba directly. (Exact boundary between Food and Class-based prey still open: [Define core growth & size-comparison rules](./.scratch/amoeba-game/issues/03-growth-size-rules.md))
