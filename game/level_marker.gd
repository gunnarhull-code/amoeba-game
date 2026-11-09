@tool
class_name LevelMarker
extends Node2D
## One placeable thing in a level scene. Drag it in the Godot editor, pick its Kind,
## and tweak the numbers in the Inspector. Positions are world coordinates.
##
## Which settings each Kind uses:
##   START          player start position.
##   GOLDEN_PEARL   the goal. Size = size_min (you must be a bit bigger than it to swallow it).
##                  Swallow it, then carry it back to the START circle to win. Dashing drops it.
##   ROCK           one boulder of radius size_min.
##   ROCK_FIELD     `count` boulders scattered within `radius`, radii between size_min and size_max.
##   ROCK_RING      a ring of boulders: ring `radius`, boulder radius size_min,
##                  opening faces gap_angle_deg (180 = west), opening half-width gap_width (0 = sealed).
##                  gate_deg > 0: the boulders across that many degrees (centred on gap_angle_deg)
##                  are a gate that disappears once you have collected the level's keys
##                  (LevelDef.keys_needed). Use it to lock a nest until the keys are found.
##   EGG            one landmine egg.
##   EGG_FIELD      packed eggs within `radius` (none closer than clear_radius to the centre),
##                  never closer than `spacing` to each other. `count` is the maximum.
##   FOOD           one pellet.
##   FOOD_FIELD     `count` pellets within `radius`.
##   FOOD_SCATTER   `count` pellets spread over the whole level.
##   KRILL_SCHOOL   a school of `count` krill that flees from big things.
##   MID            one mid hunter, radius size_min. On levels with health on (LevelDef.health),
##                  a mid bigger than you bites instead of killing: `damage` health per bite.
##   DRAIN          a toxic cloud of `radius` that drains `damage` health per second while you
##                  are in it (only does anything on levels with health on).
##   WHALE          one giant whale in the level's whale cycle (LevelDef.whale_interval).
##                  Whales take turns, in scene order, crossing the whole map chasing a swarm of
##                  `count` krill. Whales always enter from the left and swim right; the marker's
##                  height sets its usual lane. `radius` = half the body height (mouth is ~1.7x this
##                  tall), `speed` = swim speed in px/s (you swim 368 at stage 1, so 295 is 0.8x you).
##                  pearl_inside: the golden pearl (size size_min) is in its belly, hidden until you're inside.
##
##   NUCLEUS        a gravity nucleus you can slingshot around. size_min = the solid core's radius,
##                  radius = how far its pull reaches, pull = how strong (at the surface).
##   ANGLER         an angler fish lurking in the dark with a glowing ball on its lure. It lunges
##                  when you swim up to the ball. size_min = body radius, damage = bite strength
##                  (bigger anglers hit much harder than this). pearl_size = size of the lure ball.
##                  pearl_inside OFF: the ball is a decoy that looks almost like the golden pearl.
##                  pearl_inside ON: the ball IS the golden pearl (use only one per level, and no
##                  GOLDEN_PEARL marker). You can only pluck it while the angler is stunned (flash)
##                  or while you hide in your ink.
##   KEY            one key. Collect keys_needed of them (LevelDef) to open every gate (ROCK_RING gate_deg).
##
## Water currents are not markers: add a CurrentPath node (current_path.gd) and draw its curve.
##
## New Kinds go at the END of the enum so existing scenes keep their numbers.

enum Kind { START, GOLDEN_PEARL, ROCK, ROCK_FIELD, ROCK_RING, EGG, EGG_FIELD, FOOD, FOOD_FIELD, FOOD_SCATTER, KRILL_SCHOOL, MID, DRAIN, WHALE, NUCLEUS, ANGLER, KEY }

@export var kind: Kind = Kind.ROCK:
	set(v):
		kind = v
		queue_redraw()
@export var radius := 200.0:
	set(v):
		radius = v
		queue_redraw()
@export var count := 6
@export var size_min := 30.0:
	set(v):
		size_min = v
		queue_redraw()
@export var size_max := 60.0
@export var spacing := 72.0
@export var clear_radius := 0.0
@export_range(0.0, 360.0) var gap_angle_deg := 180.0
@export var gap_width := 170.0
@export var damage := 30.0
@export var speed := 295.0
@export var pearl_inside := false
@export var pull := 1600.0
@export var pearl_size := 20.0
@export var gate_deg := 0.0:
	set(v):
		gate_deg = v
		queue_redraw()

const COLORS := {
	Kind.START: Color(0.4, 1.0, 0.6),
	Kind.GOLDEN_PEARL: Color(1.0, 0.8, 0.2),
	Kind.ROCK: Color(0.6, 0.6, 0.7),
	Kind.ROCK_FIELD: Color(0.6, 0.6, 0.7),
	Kind.ROCK_RING: Color(0.6, 0.6, 0.7),
	Kind.EGG: Color(1.0, 1.0, 1.0),
	Kind.EGG_FIELD: Color(1.0, 1.0, 1.0),
	Kind.FOOD: Color(0.5, 1.0, 0.7),
	Kind.FOOD_FIELD: Color(0.5, 1.0, 0.7),
	Kind.FOOD_SCATTER: Color(0.5, 1.0, 0.7),
	Kind.KRILL_SCHOOL: Color(1.0, 0.6, 0.4),
	Kind.MID: Color(0.9, 0.4, 0.5),
	Kind.DRAIN: Color(0.6, 0.9, 0.3),
	Kind.WHALE: Color(0.7, 0.85, 1.0),
	Kind.NUCLEUS: Color(0.75, 0.55, 1.0),
	Kind.ANGLER: Color(1.0, 0.75, 0.3),
	Kind.KEY: Color(0.35, 1.0, 0.65),
}


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var c: Color = COLORS.get(kind, Color.WHITE)
	var area := 0.0
	match kind:
		Kind.ROCK_FIELD, Kind.EGG_FIELD, Kind.FOOD_FIELD, Kind.ROCK_RING, Kind.DRAIN, Kind.WHALE, Kind.NUCLEUS:
			area = radius
	if area > 0.0:
		draw_arc(Vector2.ZERO, area, 0.0, TAU, 64, Color(c, 0.6), 3.0)
		draw_circle(Vector2.ZERO, area, Color(c, 0.06))
	if kind == Kind.ROCK_RING and gate_deg > 0.0:
		var ga := deg_to_rad(gap_angle_deg)
		draw_arc(Vector2.ZERO, radius, ga - deg_to_rad(gate_deg) * 0.5, ga + deg_to_rad(gate_deg) * 0.5, 24, Color(0.35, 1.0, 0.65), 10.0)
	if kind == Kind.ANGLER:
		draw_circle(Vector2(size_min * 1.9, 0.0), pearl_size, Color(1.0, 0.85, 0.3, 0.9 if pearl_inside else 0.4))
	if kind == Kind.START:
		draw_arc(Vector2.ZERO, 220.0, 0.0, TAU, 64, Color(c, 0.6), 3.0)
	var dot := 16.0
	match kind:
		Kind.ROCK, Kind.MID, Kind.GOLDEN_PEARL, Kind.NUCLEUS, Kind.ANGLER:
			dot = size_min
		Kind.EGG:
			dot = 16.0
		Kind.KEY:
			dot = 10.0
	draw_circle(Vector2.ZERO, dot, Color(c, 0.55))
	draw_arc(Vector2.ZERO, dot, 0.0, TAU, 32, c, 2.0)
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-60, -maxf(dot, 20.0) - 10.0), str(Kind.keys()[kind]).capitalize(), HORIZONTAL_ALIGNMENT_CENTER, 120, 22, c)
