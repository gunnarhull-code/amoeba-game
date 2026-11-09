@tool
class_name LevelDef
extends Node2D
## Root of a level scene. Put LevelMarker nodes under it and place them in the editor.
## The dashed rectangle in the editor is the playable world.

@export var world_size := Vector2(6400, 3600):
	set(v):
		world_size = v
		queue_redraw()
@export var seed_value := 11
@export var speck_count := 1250  # background drifting dust
## Health and stage loss: bigger creatures bite (instead of killing), DRAIN clouds hurt,
## health 0 drops you one stage (stage 1: death). On for every level.
@export var health := true
## Krill schools refill off-screen. Turn off for levels where food should run out.
@export var krill_respawn := true
## Seconds between whale passes (only matters if the level has WHALE markers).
@export var whale_interval := 30.0
@export var first_whale_delay := 7.0
## Seconds an egg wobbles and cracks after you touch it, before the sea monkey comes out.
@export var egg_hatch_time := 1.6
## How fast sea monkeys chase you, as a share of your own speed at stage 1 (1.0 = same speed).
@export var sea_monkey_speed := 0.9
## Secondary abilities: Q / E (LB / RB) pick one, F / X / right-click uses it. Each costs ammo.
@export var abilities := false
## Below this stage the harpoon is a hook that drags things in; from this stage on it's a damaging spike.
@export var harpoon_upgrade_stage := 4
## Which secondary abilities this level has (tick the boxes). The dash on space is always there.
@export_flags("Rocket", "Harpoon", "Ink", "Leech mine", "Flash") var ability_list := 31
## Growth from one loose fragment (food pellet). Ammo is always +1. Lower it to scatter lots of
## fragments around without letting the player grow too big.
@export var fragment_value := 1.0
## How big the home circle around START is. Bring the golden pearl inside it to win.
@export var home_radius := 220.0
## How many KEY markers you must collect to open the gates (ROCK_RING with gate_deg).
@export var keys_needed := 3
## Health per second you lose while inside a whale's belly (it slowly digests you).
@export var whale_digest := 3.0
## With krill_respawn on: how many krill may respawn in total (0 = no limit).
@export var krill_respawn_limit := 0
## Rocket: how far (degrees) you can steer it away from the way you launched.
@export var rocket_turn_limit_deg := 45.0
## Rocket: top speed once the afterburner kicks in (you swim about 370 at the start).
@export var rocket_boost_speed := 1400.0


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, world_size), Color(0.4, 0.8, 1.0, 0.8), false, 6.0)
