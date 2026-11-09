extends Node2D

# Throwaway prototype. All rules here are PROVISIONAL, written to test feel,
# not to settle the design tickets (growth rules, class roster, abilities).

var world := Vector2(4800, 2700)
const SPEED := 1.6
const EAT := 1.1
const ORB_R := 46.0
const START_R := 12.0
const STAGE_RATIO := 1.2
const ZOOM_START := 1.2
const ZOOM_PER_STAGE := 0.9
const MIX := 22050.0
## The notes that play, in order, as you eat things (and on stage-ups). Type note names
## separated by spaces, like "C4 D4 E4 G4 A4". Sharps: "F#4", flats: "Bb3". Octave 4 = middle.
## Select the Main node in main.tscn to change it in the Inspector.
@export var eat_notes := "C4 D4 E4 G4 A4"
var scale_hz: Array[float] = []
const CONTROL_NAMES := ["Arrow keys", "Joystick", "Mouse", "Quit"]
var keys_needed := 3
var keys_total := 0          # keys placed in this level (0 = no key gate)
const LM := preload("res://level_marker.gd")
# Level 1 is built in code (frozen). Levels 2+ are scenes you edit in Godot: add a line here for each new one.
const LEVEL_SCENES := {2: "res://levels/level_2.tscn", 3: "res://levels/level_3.tscn", 4: "res://levels/level_4.tscn", 5: "res://levels/level_5.tscn", 6: "res://levels/level_6.tscn"}
const AB_NAMES := ["Rocket", "Harpoon", "Ink", "Leech mine", "Flash"]
const AB_COOLDOWN := [4.0, 1.6, 8.0, 1.0, 10.0]
const AB_COST := [2, 1, 2, 1, 3]  # ammo each ability uses (the dash on space always costs 1)
const LEECH_DPS := 9.0
const MEAT_MIN_R := 20.0  # creatures smaller than this don't leave meat chunks
# Health (levels with LevelDef.health on): max health per stage, share of the lost stage's
# cost that scatters as food, and how long scattered food can't be picked up.
const HP_BASE := 40.0
const HP_PER_STAGE := 20.0
const SCATTER_SHARE := 0.2
const SCATTER_DELAY := 0.9
const CURRENT_GRIP := 0.68  # sideways pull toward a current's centre, as a share of your swim speed
# Food economy: every pellet is 1 food. Cost of stage s -> s+1 is COST0 * COST_G^(s-1),
# so late stages need far more food than early ones.
const COST0 := 24.0
const COST_G := 1.13
const FOOD_PTS := {"food": 1.0, "krill": 2.0, "larva": 6.0, "mid": 12.0, "whale": 60.0, "meat": 3.0}

class Spark:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var size: float
	var col: Color
	var seek := false

class Thing:
	var kind: String
	var pos: Vector2
	var vel := Vector2.ZERO
	var r: float
	var school := -1
	var off := Vector2.ZERO
	var phase := 0.0
	var st := "roam"
	var tmr := 0.0
	var dir := Vector2.RIGHT
	var face := 0.0
	var dead := false
	var host := -1  # >= 0: sitting inside giant whale number `host` (off = belly position)
	var dmg := 30.0  # health per bite (health levels only)
	var bite_cd := 0.0
	var hp := 0.0       # enemy health (abilities only); max_hp 0 = never hurt yet
	var max_hp := 0.0
	var stun := 0.0     # seconds left stunned (flash bang, harpoon): can't move, bite or eat
	var hit_t := 0.0    # white flash after a hit
	var val := 0.0      # meat chunks: how much food it's worth
	var chunk_acc := 0.0  # damage taken since the last meat chunk tore off
	var pearl := 0      # anglers: 0 = decoy ball on the lure, 1 = the real golden pearl, -1 = lure is empty
	var pearl_r := 20.0
	var flip := 1.0     # 1 = facing right, -1 = facing left; passes through 0 while turning around

class Whale:
	# A giant whale that crosses the whole map (whale level). Local frame: +x = forward.
	var pos := Vector2.ZERO
	var dir := 1.0          # +1 swims right, -1 swims left
	var start_dir := 1.0
	var lane := 0.0
	var b := 520.0          # half body height (mouth is ~1.7x this tall)
	var a := 1350.0         # half body length
	var speed := 300.0
	var swarm_n := 45
	var swarm_x := 0.0      # the fleeing krill swarm's centre (x), runs ahead of the mouth
	var st := "idle"        # idle (off-map) / swim / hold (you are inside) / spasm
	var tmr := 0.0
	var tickle := 0.0       # how long you have been poking the belly lining
	var wake_t := 0.0
	var wake_side := 1.0
	var gulp := 0.0
	var phase := 0.0

class Rock:
	var pos: Vector2
	var r: float
	var gate := false
	var eat_stage := 0
	var label := false

class Vine:
	var a: Vector2
	var b: Vector2
	var triggered := false
	var timer := 0.0

var p_pos := Vector2(480, 1350)
var p_vel := Vector2.ZERO
var p_r := START_R
var food := 0.0
var inside: Array = []  # key items swallowed: [kind, r]
var pearl_t := 0.0
var dim := 0.0
var level := 1
var goal_radius := 18.0
var pending: Array[Thing] = []
var shrimp_touch := 0
var win_t := 0.0
var sparks: Array[Spark] = []
var ammo := 0
var ammo_max := 8
var dash_time := 0.0
var dash_dir := Vector2.RIGHT
var space_was := false
var things: Array[Thing] = []
var rocks: Array[Rock] = []
var vines: Array[Vine] = []
var school_base: Array[Vector2] = []
var school_pos: Array[Vector2] = []
var specks: Array = []
var orb_pos := Vector2(3900, 1350)
var state := "play"
var t := 0.0
var eaten := 0
var keys := 0
var gate_open := false
var stage := 1
var fx_t := 99.0
var intro_t := 99.0
var zoom_s := ZOOM_START
var banner_t := 0.0
var krill_timer := 0.0
var cam: Camera2D
var hud: Label
var banner: Label
var voices: Array[AudioStreamPlayer] = []
var voice_i := 0
var control := 0
var menu_sel := 0
var nav_prev := 0
var confirm_prev := true
# Health and stage loss (only when the level scene turns it on).
var health_on := false
var hp := HP_BASE + HP_PER_STAGE
var hurt_t := 0.0    # red flash after a hit
var hurt_cd := 0.0   # no second bite right away
var grace_t := 0.0   # no damage at all just after losing a stage
var drains: Array = []  # [pos, radius, health per second]
var hp_test := -1.0  # AMOEBA_HP: set health to this share of max on the first frame
var steer_test := Vector2.ZERO  # AMOEBA_STEER="x,y": hold this steering (testing only)
# Whale level + water currents.
var krill_respawn := true
var egg_hatch_time := 1.6     # seconds an egg wobbles and cracks after you touch it
var sea_monkey_speed := 0.9   # sea monkey chase speed, as a share of your stage-1 swim speed
var whales: Array[Whale] = []
var whale_interval := 30.0
var whale_t := 0.0
var whale_next := 0
var in_whale := -1           # index of the whale you are inside, or -1
var swallow_cd := 0.0
var jet := Vector2.ZERO      # strong push (blowhole jet), decays
var currents: Array = []     # [points, cumulative lengths, half-width, strength, bounding box]
var wakes: Array = []        # whale wake swirls: [pos, life, spin, radius]
var fps_label: Label
var flash_rect: ColorRect
# Gravity nuclei: [pos, core radius, reach, pull]. grav_vel is the momentum they give you.
var nuclei: Array = []
var grav_vel := Vector2.ZERO
# Abilities (levels with LevelDef.abilities on).
var abilities_on := false
var ab_enabled := 31        # which secondary abilities this level has (bit 0 = rocket ... bit 4 = flash)
var food_value := 1.0       # growth from one loose fragment (food pellet) on this level
var harpoon_up_stage := 4
var ab_sel := 0
var ab_cd: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var ab_q_prev := false
var ab_e_prev := false
var ab_f_prev := false
var ab_test := -1           # AMOEBA_ABIL=n: keep firing ability n (testing only)
var aim_dir := Vector2.RIGHT
var rocket_t := 0.0
var rocket_dir := Vector2.RIGHT
var hook := {}              # the harpoon while it is out
var inks: Array = []        # [pos, life, radius]
var leeches: Array = []     # {pos, life, host, off}
var flash_t := 0.0
var p_hidden := false       # inside your own ink: enemies lose track of you
var prof_on := false        # AMOEBA_PROF: print step / draw timings to the console
var prof := {"step": 0, "draw": 0, "frames": 0}
const ROCK_CELL := 256.0
var rock_grid := {}          # cell -> rocks near that cell (speeds up rock collisions)
var rock_grid_dirty := true
var rock_grid_count := -1
var scatter_list: Array[Thing] = []  # food you dropped, gathered once per frame
var current_grid := {}       # cell -> {current index: segment indices near that cell}
var current_food: Array[int] = []  # per current: how many pellets ride it
# Home base: bring the golden pearl back here to win.
var home_pos := Vector2(480, 1350)
var home_r := 220.0
var pearl_bonus := false     # the pearl's free stage is only given the first time you swallow it
var red_t := 0.0             # red screen-edge flash when you lose health
var red_vig: TextureRect
var whale_digest := 3.0      # health per second lost inside a whale's belly
var krill_left := -1         # krill that may still respawn (-1 = no limit)
var rocket_len := 1.6
var rocket_turn_deg := 45.0
var rocket_boost := 1400.0
var rocket_base := Vector2.RIGHT


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.0, 0.006, 0.016))
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(world.x)
	cam.limit_bottom = int(world.y)
	add_child(cam)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(hud)
	banner = Label.new()
	banner.position = Vector2(0, 220)
	banner.size = Vector2(1920, 120)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 64)
	banner.modulate = Color(1.0, 0.95, 0.75, 0.0)
	layer.add_child(banner)
	fps_label = Label.new()
	fps_label.position = Vector2(1920 - 150, 12)
	fps_label.size = Vector2(134, 30)
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps_label.add_theme_font_size_override("font_size", 22)
	layer.add_child(fps_label)
	flash_rect = ColorRect.new()
	flash_rect.size = Vector2(1920, 1080)
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash_rect)
	layer.move_child(flash_rect, 0)
	# Deep-sea darkness closing in from the screen edges.
	var vig := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 0.5)
	gt.width = 512
	gt.height = 288
	var gr := Gradient.new()
	gr.set_color(0, Color(0.0, 0.0, 0.02, 0.0))
	gr.set_color(1, Color(0.0, 0.0, 0.02, 0.82))
	gr.add_point(0.45, Color(0.0, 0.0, 0.02, 0.08))
	gt.gradient = gr
	vig.texture = gt
	vig.size = Vector2(1920, 1080)
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(vig)
	layer.move_child(vig, 0)
	# Subtle red flash around the screen edges whenever you lose health.
	red_vig = TextureRect.new()
	var rt := GradientTexture2D.new()
	rt.fill = GradientTexture2D.FILL_RADIAL
	rt.fill_from = Vector2(0.5, 0.5)
	rt.fill_to = Vector2(1.0, 0.5)
	rt.width = 512
	rt.height = 288
	var rg := Gradient.new()
	rg.set_color(0, Color(0.9, 0.05, 0.05, 0.0))
	rg.set_color(1, Color(0.9, 0.05, 0.05, 0.9))
	rg.add_point(0.6, Color(0.9, 0.05, 0.05, 0.0))
	rt.gradient = rg
	red_vig.texture = rt
	red_vig.size = Vector2(1920, 1080)
	red_vig.stretch_mode = TextureRect.STRETCH_SCALE
	red_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_vig.modulate.a = 0.0
	layer.add_child(red_vig)
	layer.move_child(red_vig, 1)
	scale_hz = parse_notes(eat_notes)
	if OS.get_environment("AMOEBA_ABIL") != "":
		ab_test = int(OS.get_environment("AMOEBA_ABIL"))
	prof_on = OS.get_environment("AMOEBA_PROF") != ""
	for i in 8:
		var pl := AudioStreamPlayer.new()
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = MIX
		gen.buffer_length = 0.6
		pl.stream = gen
		add_child(pl)
		voices.append(pl)
	reset()
	state = "menu"
	if OS.get_environment("AMOEBA_AUTOSTART") != "":
		if OS.get_environment("AMOEBA_LEVEL") != "":
			level = int(OS.get_environment("AMOEBA_LEVEL"))
			reset()
		if OS.get_environment("AMOEBA_POP") != "":
			var n_pop := 0
			for th in things:
				if th.kind == "egg" and n_pop < int(OS.get_environment("AMOEBA_POP")):
					pop_egg(th)
					n_pop += 1
		state = "play"
		if OS.get_environment("AMOEBA_SIZE") != "":
			p_r = float(OS.get_environment("AMOEBA_SIZE"))
			food = cum_food(1.0 + log(p_r / START_R) / log(STAGE_RATIO))
		intro_t = 99.0
		if OS.get_environment("AMOEBA_STEER") != "":
			var sv := OS.get_environment("AMOEBA_STEER").split(",")
			steer_test = Vector2(float(sv[0]), float(sv[1]))
		if OS.get_environment("AMOEBA_WHALE_T") != "":
			whale_t = float(OS.get_environment("AMOEBA_WHALE_T"))
		if OS.get_environment("AMOEBA_PEARL") != "":
			inside.append(["pearl", 22.0])  # start already carrying the pearl (testing only)
			pearl_bonus = true
		if OS.get_environment("AMOEBA_HP") != "":
			hp_test = float(OS.get_environment("AMOEBA_HP"))
		if OS.get_environment("AMOEBA_X") != "":
			p_pos = Vector2(float(OS.get_environment("AMOEBA_X")), float(OS.get_environment("AMOEBA_Y")))


func parse_notes(s: String) -> Array[float]:
	# "C4 D#4 Bb3" -> frequencies. Anything unreadable is skipped.
	var semis := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
	var out: Array[float] = []
	for tok in s.replace(",", " ").split(" ", false):
		var n := tok.strip_edges().to_upper()
		if n.length() < 2 or not semis.has(n[0]):
			continue
		var semi: int = semis[n[0]]
		var rest := n.substr(1)
		if rest.begins_with("#"):
			semi += 1
			rest = rest.substr(1)
		elif rest.begins_with("B"):
			semi -= 1
			rest = rest.substr(1)
		if not rest.is_valid_int():
			continue
		var midi := (int(rest) + 1) * 12 + semi
		out.append(440.0 * pow(2.0, (midi - 69) / 12.0))
	if out.is_empty():
		out = [261.63, 293.66, 329.63, 392.0, 440.0]
	return out


func note(i: int) -> float:
	return scale_hz[posmod(i, scale_hz.size())]


func add_ring(center: Vector2, ring_r: float, rock_r: float, gap_dir: float, gap_half: float, gate_arc: float = 0.0, eat_stage: int = 0) -> void:
	var first := rocks.size()
	var n := int(ceil(TAU * ring_r / (rock_r * 1.7)))
	for i in n:
		var ang := TAU * i / n
		var diff := absf(angle_difference(ang, gap_dir))
		if gap_half > 0.0 and diff * ring_r < gap_half:
			continue
		var rk := Rock.new()
		rk.pos = center + Vector2.from_angle(ang) * ring_r
		rk.r = rock_r
		rk.gate = gate_arc > 0.0 and diff < gate_arc
		rk.eat_stage = eat_stage
		rocks.append(rk)
	if eat_stage > 0 and rocks.size() > first:
		rocks[first].label = true


func free_spot(pos: Vector2, r: float) -> bool:
	for rk in rocks:
		if pos.distance_to(rk.pos) < r + rk.r + 10.0:
			return false
	return true


func random_free(xmin: float, xmax: float, ymin: float, ymax: float, r: float) -> Vector2:
	for i in 40:
		var p := Vector2(randf_range(xmin, xmax), randf_range(ymin, ymax))
		if free_spot(p, r):
			return p
	return Vector2(xmin, ymin)


func reset() -> void:
	seed(7)
	Engine.time_scale = 1.0
	p_pos = Vector2(480, 1350)
	p_vel = Vector2.ZERO
	p_r = START_R
	food = 0.0
	inside.clear()
	sparks.clear()
	pearl_t = 0.0
	win_t = 0.0
	ammo = 0
	eaten = 0
	keys = 0
	gate_open = false
	stage = 1
	fx_t = 99.0
	intro_t = 0.0
	zoom_s = ZOOM_START
	banner_t = 0.0
	dash_time = 0.0
	state = "play"
	things.clear()
	rocks.clear()
	rock_grid_dirty = true
	vines.clear()
	specks.clear()
	school_base.clear()
	school_pos.clear()
	pending.clear()
	shrimp_touch = 0
	health_on = true  # every level uses health now (bites hurt; health 0 drops a stage)
	drains.clear()
	hp = max_hp(1)
	hurt_t = 0.0
	hurt_cd = 0.0
	grace_t = 0.0
	krill_respawn = true
	nuclei.clear()
	grav_vel = Vector2.ZERO
	abilities_on = false
	ab_enabled = 31
	food_value = 1.0
	harpoon_up_stage = 4
	ab_cd.fill(0.0)
	rocket_t = 0.0
	hook = {}
	inks.clear()
	leeches.clear()
	flash_t = 0.0
	p_hidden = false
	egg_hatch_time = 1.6
	sea_monkey_speed = 0.9
	whales.clear()
	whale_next = 0
	in_whale = -1
	swallow_cd = 0.0
	jet = Vector2.ZERO
	currents.clear()
	current_grid.clear()
	wakes.clear()
	current_food.clear()
	pearl_bonus = false
	red_t = 0.0
	keys_needed = 3
	keys_total = 0
	home_r = 220.0
	whale_digest = 3.0
	krill_left = -1
	rocket_turn_deg = 45.0
	rocket_boost = 1400.0
	if level >= 2:
		build_level_scene(LEVEL_SCENES[level])
		home_pos = p_pos
		return
	# ---- LEVEL 1 (frozen: do not change this layout; new ideas go in other levels) ----
	world = Vector2(4800, 2700)
	apply_world()
	orb_pos = Vector2(3900, 1350)
	home_pos = p_pos
	keys_total = 3

	# Orb chamber: sealed ring, west side is a gate that opens with 3 keys (or a heavy dash).
	add_ring(orb_pos, 170.0, 34.0, PI, 0.0, 0.75, 16)
	# Pantries: sealed rings of purple (edible) wall with food inside.
	add_ring(Vector2(2300, 1100), 80.0, 26.0, 0.0, 0.0, 0.0, 6)
	add_ring(Vector2(800, 2400), 110.0, 30.0, 0.0, 0.0, 0.0, 9)
	for pc in [[Vector2(2300, 1100), 14, 45.0], [Vector2(800, 2400), 22, 70.0]]:
		for i in pc[1]:
			var pf := Thing.new()
			pf.kind = "food"
			pf.pos = pc[0] + Vector2.from_angle(randf() * TAU) * randf_range(5, pc[2])
			pf.r = randf_range(4.5, 6.5)
			pf.phase = randf() * TAU
			things.append(pf)
	# Key pockets: narrow openings, only small amoebas fit.
	var key_centers: Array[Vector2] = [Vector2(900, 500), Vector2(1900, 2050), Vector2(2900, 600)]
	var key_dirs: Array[float] = [PI / 2.0, -PI / 2.0, 0.0]
	for i in 3:
		add_ring(key_centers[i], 60.0, 20.0, key_dirs[i], 46.0)
		var kk := Thing.new()
		kk.kind = "key"
		kk.pos = key_centers[i]
		kk.r = 7.0
		kk.phase = randf() * TAU
		things.append(kk)
	# Harbor: medium opening, hunters of mid size can enter, whales cannot.
	add_ring(Vector2(1200, 2200), 150.0, 30.0, 0.0, 75.0)
	for i in 14:
		var hf := Thing.new()
		hf.kind = "food"
		hf.pos = Vector2(1200, 2200) + Vector2.from_angle(randf() * TAU) * randf_range(10, 95)
		hf.r = randf_range(4.5, 6.5)
		hf.phase = randf() * TAU
		things.append(hf)
	# The one Golden Pearl: the goal. Eating it grants a full stage and it floats inside you.
	var pe := Thing.new()
	pe.kind = "pearl"
	pe.pos = orb_pos
	pe.r = ORB_R
	pe.st = "goal"
	pe.phase = randf() * TAU
	things.append(pe)
	# Boulder fields for cover.
	var fields: Array[Vector2] = [Vector2(1500, 900), Vector2(2600, 1900), Vector2(3000, 1250), Vector2(700, 1900), Vector2(2200, 450), Vector2(3600, 2300)]
	for c in fields:
		for k in 7:
			var b := Rock.new()
			b.pos = c + Vector2.from_angle(randf() * TAU) * randf_range(0, 230)
			b.r = randf_range(28.0, 60.0)
			rocks.append(b)

	# Coral-larvae vines: look like solid growths, then dislodge and swarm.
	var vine_ends: Array = [[Vector2(1500, 1150), Vector2(1500, 1550)], [Vector2(2700, 2350), Vector2(3100, 2350)]]
	for vi in vine_ends.size():
		var v := Vine.new()
		v.a = vine_ends[vi][0]
		v.b = vine_ends[vi][1]
		vines.append(v)
		var axis: Vector2 = (v.b - v.a)
		var nrm := axis.normalized().orthogonal()
		for k in 24:
			var lv := Thing.new()
			lv.kind = "larva"
			lv.st = "attached"
			lv.school = vi
			lv.r = 22.0
			lv.pos = v.a + axis * (float(k) / 23.0) + nrm * (18.0 if k % 2 == 0 else -18.0)
			lv.face = nrm.angle() if k % 2 == 0 else (-nrm).angle()
			lv.tmr = randf_range(0.1, 1.0)
			lv.phase = randf() * TAU
			things.append(lv)

	for i in 700:
		specks.append([Vector2(randf() * world.x, randf() * world.y), randf_range(1.0, 3.0), randf()])
	for i in 300:
		var f := Thing.new()
		f.kind = "food"
		f.pos = random_free(0, world.x, 0, world.y, 8.0)
		f.r = randf_range(3.5, 6.0)
		f.phase = randf() * TAU
		things.append(f)
	var bases: Array[Vector2] = [Vector2(1350, 600), Vector2(1650, 2100), Vector2(2850, 1350), Vector2(3450, 450), Vector2(2250, 2475), Vector2(1050, 1425), Vector2(3750, 2175), Vector2(2475, 375)]
	for s in bases.size():
		school_base.append(bases[s])
		school_pos.append(bases[s])
		for k in 14:
			var kr := Thing.new()
			kr.kind = "krill"
			kr.r = randf_range(6.0, 8.0)
			kr.off = Vector2.from_angle(randf() * TAU) * randf_range(10, 60)
			kr.pos = bases[s] + kr.off
			kr.school = s
			kr.phase = randf() * TAU
			things.append(kr)
	for i in 14:
		var m := Thing.new()
		m.kind = "mid"
		m.r = randf_range(24.0, 32.0)
		m.pos = random_free(1050, 4050, 225, 2475, m.r)
		m.phase = randf() * TAU
		things.append(m)
	for wp in [Vector2(3450, 900), Vector2(3450, 1875), Vector2(2100, 750)]:
		var w := Thing.new()
		w.kind = "whale"
		w.r = 95.0
		w.pos = wp
		w.phase = randf() * TAU
		things.append(w)


func apply_world() -> void:
	cam.limit_right = int(world.x)
	cam.limit_bottom = int(world.y)


func build_level_scene(path: String) -> void:
	# Builds a level from a scene of LevelMarker nodes (placed in the Godot editor).
	var root: Node = load(path).instantiate()
	world = root.world_size
	health_on = root.health
	krill_respawn = root.krill_respawn
	abilities_on = root.abilities
	ab_enabled = root.ability_list
	food_value = root.fragment_value
	harpoon_up_stage = root.harpoon_upgrade_stage
	egg_hatch_time = root.egg_hatch_time
	sea_monkey_speed = root.sea_monkey_speed
	whale_interval = root.whale_interval
	whale_t = root.first_whale_delay
	keys_needed = root.keys_needed
	home_r = root.home_radius
	whale_digest = root.whale_digest
	krill_left = root.krill_respawn_limit if root.krill_respawn_limit > 0 else -1
	rocket_turn_deg = root.rocket_turn_limit_deg
	rocket_boost = root.rocket_boost_speed
	seed(root.seed_value)
	apply_world()
	p_pos = Vector2(500, world.y / 2.0)
	var scatter_food := 0
	for n in root.get_children():
		if n is Path2D:
			add_current(n)
			continue
		var k: int = n.kind
		var c: Vector2 = n.position
		match k:
			LM.Kind.START:
				p_pos = c
			LM.Kind.GOLDEN_PEARL:
				orb_pos = c
				goal_radius = n.size_min
				var pe := Thing.new()
				pe.kind = "pearl"
				pe.pos = c
				pe.r = n.size_min
				pe.st = "goal"
				pe.phase = randf() * TAU
				things.append(pe)
			LM.Kind.ROCK:
				var b := Rock.new()
				b.pos = c
				b.r = n.size_min
				rocks.append(b)
			LM.Kind.ROCK_FIELD:
				for i in n.count:
					var b2 := Rock.new()
					b2.pos = c + Vector2.from_angle(randf() * TAU) * randf_range(0.0, n.radius)
					b2.r = randf_range(n.size_min, n.size_max)
					rocks.append(b2)
			LM.Kind.ROCK_RING:
				add_ring(c, n.radius, n.size_min, deg_to_rad(n.gap_angle_deg), n.gap_width, deg_to_rad(n.gate_deg) * 0.5)
			LM.Kind.KEY:
				var kk := Thing.new()
				kk.kind = "key"
				kk.pos = c
				kk.r = 7.0
				kk.phase = randf() * TAU
				things.append(kk)
				keys_total += 1
			LM.Kind.EGG:
				add_egg(c)
			LM.Kind.EGG_FIELD:
				var placed: Array[Vector2] = []
				for i in 1200:
					if placed.size() >= n.count:
						break
					var p: Vector2 = c + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * n.radius
					if p.distance_to(c) < n.clear_radius:
						continue
					var ok := true
					for q in placed:
						if p.distance_to(q) < n.spacing:
							ok = false
							break
					if ok:
						placed.append(p)
				for p in placed:
					add_egg(p)
			LM.Kind.FOOD:
				add_pellet(c)
			LM.Kind.FOOD_FIELD:
				for i in n.count:
					add_pellet(c + Vector2.from_angle(randf() * TAU) * randf_range(0.0, n.radius))
			LM.Kind.FOOD_SCATTER:
				scatter_food += n.count
			LM.Kind.KRILL_SCHOOL:
				var s := school_base.size()
				school_base.append(c)
				school_pos.append(c)
				for i in n.count:
					var kr := Thing.new()
					kr.kind = "krill"
					kr.r = randf_range(6.0, 8.0)
					kr.off = Vector2.from_angle(randf() * TAU) * randf_range(10, 60)
					kr.pos = c + kr.off
					kr.school = s
					kr.phase = randf() * TAU
					things.append(kr)
			LM.Kind.MID:
				var m := Thing.new()
				m.kind = "mid"
				m.r = n.size_min
				m.pos = c
				m.phase = randf() * TAU
				m.dmg = n.damage
				things.append(m)
			LM.Kind.DRAIN:
				drains.append([c, n.radius, n.damage])
			LM.Kind.ANGLER:
				var an := Thing.new()
				an.kind = "angler"
				an.r = n.size_min
				an.pos = c
				an.dmg = n.damage
				an.phase = randf() * TAU
				an.face = randf() * TAU
				an.st = "lurk"
				an.flip = signf(cos(an.face)) if absf(cos(an.face)) > 0.01 else 1.0
				an.pearl = 1 if n.pearl_inside else 0
				an.pearl_r = n.pearl_size
				if n.pearl_inside:
					goal_radius = n.pearl_size
				things.append(an)
			LM.Kind.NUCLEUS:
				nuclei.append([c, float(n.size_min), float(n.radius), float(n.pull)])
			LM.Kind.WHALE:
				var w := Whale.new()
				w.b = n.radius
				w.a = n.radius * 2.6
				w.speed = n.speed
				w.swarm_n = n.count
				w.start_dir = 1.0  # whales always come in from the left and swim right
				w.dir = w.start_dir
				w.lane = c.y
				w.pos = Vector2(-99999.0, c.y)
				w.phase = randf() * TAU
				whales.append(w)
				if n.pearl_inside:
					var pe2 := Thing.new()
					pe2.kind = "pearl"
					pe2.st = "goal"
					pe2.r = n.size_min
					pe2.host = whales.size() - 1
					pe2.off = Vector2(-w.a * 0.25, w.b * 0.15)
					pe2.phase = randf() * TAU
					goal_radius = n.size_min
					things.append(pe2)
	for i in root.speck_count:
		specks.append([Vector2(randf() * world.x, randf() * world.y), randf_range(1.0, 3.0), randf()])
	for i in scatter_food:
		add_pellet(random_free(0, world.x, 0, world.y, 8.0))
	root.free()


func add_pellet(pos: Vector2) -> void:
	var f := Thing.new()
	f.kind = "food"
	f.pos = pos
	f.r = randf_range(3.5, 6.0)
	f.phase = randf() * TAU
	f.val = food_value
	things.append(f)

# ---------------- Water currents ----------------

func add_current(n: Node) -> void:
	var cv: Curve2D = n.curve
	if cv == null or cv.point_count < 2:
		return
	var pts := PackedVector2Array()
	for p in cv.tessellate_even_length(5, 60.0):
		pts.append(n.position + p)
	var cum := PackedFloat32Array([0.0])
	for i in range(1, pts.size()):
		cum.append(cum[i - 1] + pts[i].distance_to(pts[i - 1]))
	var box := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		box = box.expand(p)
	# File each stream segment under the cells it can reach, so a lookup only checks nearby segments.
	var ci := currents.size()
	for i in range(1, pts.size()):
		var sb := Rect2(pts[i - 1], Vector2.ZERO).expand(pts[i]).grow(float(n.width))
		var lo := (sb.position / ROCK_CELL).floor()
		var hi := (sb.end / ROCK_CELL).floor()
		for cx in range(int(lo.x), int(hi.x) + 1):
			for cy in range(int(lo.y), int(hi.y) + 1):
				var key := Vector2i(cx, cy)
				if not current_grid.has(key):
					current_grid[key] = {}
				var per: Dictionary = current_grid[key]
				if not per.has(ci):
					per[ci] = PackedInt32Array()
				var arr: PackedInt32Array = per[ci]
				arr.append(i)
				per[ci] = arr
	currents.append([pts, cum, float(n.width), float(n.strength), box.grow(n.width)])
	var fc: int = n.food_count if "food_count" in n else 0
	current_food.append(fc)
	for i in fc:
		add_current_food(ci, randf())


func add_current_food(ci: int, where: float) -> void:
	# A pellet riding current ci, at share `where` of the way along it.
	var c: Array = currents[ci]
	var cum: PackedFloat32Array = c[1]
	var cp := current_point(c, where * cum[cum.size() - 1])
	var d: Vector2 = cp[1]
	var f := Thing.new()
	f.kind = "food"
	f.pos = (cp[0] as Vector2) + d.orthogonal() * randf_range(-0.6, 0.6) * float(c[2])
	f.r = randf_range(3.5, 6.0)
	f.phase = randf() * TAU
	f.school = 1000 + ci
	things.append(f)


func refill_current_food() -> void:
	# New pellets keep entering at the start of each current, so the stream never runs dry.
	if current_food.is_empty():
		return
	var have: Array[int] = []
	have.resize(current_food.size())
	have.fill(0)
	for th in things:
		if th.kind == "food" and th.school >= 1000 and th.school - 1000 < have.size():
			have[th.school - 1000] += 1
	for ci in current_food.size():
		if have[ci] < current_food[ci]:
			add_current_food(ci, randf() * 0.1)


func current_flow(pos: Vector2, grip: float) -> Vector2:
	var out := Vector2.ZERO
	var per: Dictionary = current_grid.get(Vector2i((pos / ROCK_CELL).floor()), {})
	for ci in per:
		var c: Array = currents[ci]
		var pts: PackedVector2Array = c[0]
		var wdt: float = c[2]
		var best := wdt
		var bdir := Vector2.ZERO
		var bq := pos
		for i: int in per[ci]:
			var q := Geometry2D.get_closest_point_to_segment(pos, pts[i - 1], pts[i])
			var d := pos.distance_to(q)
			if d < best:
				best = d
				bq = q
				bdir = (pts[i] - pts[i - 1]).normalized()
		if bdir != Vector2.ZERO:
			# Flat, strong core (faster than you can swim) that only fades at the very edge...
			var k := 1.0 - pow(best / wdt, 4.0)
			out += bdir * float(c[3]) * k
			# ...plus a grip pulling you back toward the middle: escaping takes a sustained push.
			if best > 1.0:
				out += (bq - pos) / best * grip * sin(PI * clampf(best / wdt, 0.0, 1.0) * 0.9)
	return out


func wake_flow(pos: Vector2) -> Vector2:
	# Whale wakes: swirling eddies left behind (and alongside) a passing whale.
	var out := Vector2.ZERO
	for wk in wakes:
		var d: Vector2 = pos - wk[0]
		var l := d.length()
		var rad: float = wk[3]
		if l < rad and l > 1.0:
			var fade: float = clampf(wk[1] / 5.0, 0.0, 1.0)
			var k := sin(PI * l / rad)  # strongest midway out: you get spun around the eddy
			out += d.orthogonal() / l * wk[2] * 420.0 * k * fade - d / l * 60.0 * k * fade
	for w in whales:
		if w.st != "swim" and w.st != "hold":
			continue
		var lc := whale_local(w, pos)
		var f := body_f(w, lc)
		if w.st == "swim" and lc.x > w.a * 0.3 and absf(lc.y) < w.b * 1.1 and lc.x < w.a + 700.0:
			# In front of the open mouth the water is sucked in.
			var into := whale_world(w, Vector2(w.a * 0.5, 0.0)) - pos
			var kk := 1.0 - clampf((lc.x - w.a) / 700.0, 0.0, 1.0)
			out += into.normalized() * 260.0 * kk
		elif f > 1.0 and f < 1.9 and w.st == "swim":
			# Right beside a swimming whale the water streams back along its flank and curls.
			var k2 := 1.0 - (f - 1.0) / 0.9
			var rad2 := (pos - w.pos).normalized()
			var tang := rad2.orthogonal()
			if tang.x * w.dir > 0.0:
				tang = -tang
			out += tang * 330.0 * k2 + Vector2(w.dir * w.speed * 0.35 * k2, 0.0)
	return out


func flow_at(pos: Vector2, grip := 150.0) -> Vector2:
	return current_flow(pos, grip) + wake_flow(pos)


# ---------------- Giant whales ----------------

func whale_local(w: Whale, p: Vector2) -> Vector2:
	var d := p - w.pos
	return Vector2(d.x * w.dir, d.y)


func whale_world(w: Whale, l: Vector2) -> Vector2:
	return w.pos + Vector2(l.x * w.dir, l.y)


func body_f(w: Whale, l: Vector2) -> float:
	# < 1 inside the body. Blunt (superellipse) front where the mouth is, round back.
	var px := 4.0 if l.x > 0.0 else 2.0
	return pow(absf(l.x) / w.a, px) + pow(l.y / w.b, 2.0)


func in_mouth(w: Whale, l: Vector2) -> bool:
	return l.x > w.a * 0.42 and absf(l.y) < w.b * 0.85 and body_f(w, l) < 1.08


func belly_axes(w: Whale) -> Vector2:
	return Vector2(w.a * 0.66, w.b * 0.74)


func belly_center(w: Whale) -> Vector2:
	return Vector2(-w.a * 0.12, 0.0)


func belly_clamp(w: Whale, l: Vector2, margin: float) -> Array:
	# Keeps a local point inside the belly. Returns [point, touched_lining].
	var ax := belly_axes(w) - Vector2(margin, margin)
	ax = ax.max(Vector2(20, 20))
	var q := l - belly_center(w)
	var e := pow(q.x / ax.x, 2.0) + pow(q.y / ax.y, 2.0)
	if e <= 1.0:
		return [l, false]
	q /= sqrt(e)
	return [belly_center(w) + q, true]


func random_belly_spot(w: Whale) -> Vector2:
	var ax := belly_axes(w) * 0.8
	var a := randf() * TAU
	var r := sqrt(randf())
	return belly_center(w) + Vector2(cos(a) * ax.x, sin(a) * ax.y) * r


func start_whale_pass(i: int) -> void:
	var w := whales[i]
	w.dir = w.start_dir
	var gap := w.speed * 5.5     # krill first, the mouth ~5.5 s later
	var lane := clampf(lerpf(w.lane, p_pos.y, 0.6) + randf_range(-300.0, 300.0), w.b + 60.0, world.y - w.b - 60.0)
	var mouth_x := -gap - 400.0 if w.dir > 0.0 else world.x + gap + 400.0
	w.pos = Vector2(mouth_x - w.a * w.dir, lane)
	w.swarm_x = mouth_x + gap * w.dir
	w.st = "swim"
	w.tickle = 0.0
	for k in w.swarm_n:
		var kr := Thing.new()
		kr.kind = "krill"
		kr.st = "swarm"
		kr.school = i
		kr.r = randf_range(6.5, 8.5)
		kr.off = Vector2(randf_range(-320.0, 320.0), randf_range(-1.0, 1.0) * w.b * 0.75)
		kr.pos = Vector2(w.swarm_x, lane) + kr.off
		kr.phase = randf() * TAU
		things.append(kr)


func update_whales(delta: float) -> void:
	if whales.is_empty():
		return
	whale_t -= delta
	if whale_t <= 0.0:
		whale_t = whale_interval
		for tries in whales.size():
			var i := (whale_next + tries) % whales.size()
			if whales[i].st == "idle":
				start_whale_pass(i)
				whale_next = (i + 1) % whales.size()
				break
	for i in whales.size():
		var w := whales[i]
		w.gulp = maxf(w.gulp - delta, 0.0)
		match w.st:
			"idle":
				continue
			"swim":
				w.swarm_x += w.dir * w.speed * 1.02 * delta
				# It steers toward you, but slowly: you can dodge out of the mouth's path.
				var ahead := (p_pos.x - w.pos.x) * w.dir
				if ahead > 0.0 and ahead < w.a + 2600.0 and in_whale < 0:
					w.pos.y += clampf((p_pos.y - w.pos.y) * 0.4, -75.0, 75.0) * delta
				w.pos.y = clampf(w.pos.y, w.b + 40.0, world.y - w.b - 40.0)
				w.pos.x += w.dir * w.speed * delta
				w.wake_t -= delta
				if w.wake_t <= 0.0:
					w.wake_t = 0.45
					w.wake_side = -w.wake_side
					wakes.append([whale_world(w, Vector2(-w.a * 1.05, w.b * 0.55 * w.wake_side)), 5.0, w.wake_side * w.dir, w.b * 0.7])
				whale_eat(w, i)
				if (w.dir > 0.0 and w.pos.x - w.a > world.x + 300.0) or (w.dir < 0.0 and w.pos.x + w.a < -300.0):
					w.st = "idle"
			"hold":
				w.tmr += delta
				# Settle fully inside the map so the camera can follow you around the belly.
				var tx := clampf(w.pos.x, w.a + 80.0, world.x - w.a - 80.0)
				var nx := move_toward(w.pos.x, tx, w.speed * delta)
				if in_whale == i:
					p_pos.x += nx - w.pos.x  # you are carried along inside it
				w.pos.x = nx
			"spasm":
				# The lining convulses and water rushes up through the hole on top.
				w.tmr -= delta
				var hole := whale_world(w, whale_hole(w))
				var src := whale_world(w, belly_center(w))
				for k in 3:
					var p0 := src.lerp(hole, randf_range(0.2, 1.0)) + Vector2(randf_range(-60.0, 60.0), 0.0)
					add_spark(p0, (hole - p0).normalized() * 700.0 + Vector2(0.0, -500.0), randf_range(0.5, 1.0), randf_range(1.5, 3.0), Color(0.75, 0.95, 1.0, 0.8))
				if w.tmr <= 0.0:
					w.tickle = 0.0
					w.st = "hold" if in_whale == i else "swim"
	for wk in wakes:
		wk[1] -= delta
	wakes = wakes.filter(func(x: Array) -> bool: return x[1] > 0.0)


func whale_eat(w: Whale, i: int) -> void:
	# Everything that drifts into the open mouth is swallowed, you included.
	var belly_n := 0
	for th in things:
		if th.host == i:
			belly_n += 1
	for th in things:
		if th.dead or th.host >= 0 or th.kind == "pearl":
			continue
		var l := whale_local(w, th.pos)
		if not in_mouth(w, l):
			continue
		w.gulp = 0.4
		if th.kind == "egg":
			th.dead = true
			continue
		if belly_n > 60:
			continue  # belly full: it stops swallowing, nothing is killed
		var n := 3 if th.kind == "mid" else 1
		if th.kind == "mid":
			th.dead = true  # mids are crushed into food chunks
			for k in n:
				var f := Thing.new()
				f.kind = "food"
				f.r = randf_range(5.0, 7.0)
				f.host = i
				f.off = random_belly_spot(w)
				f.phase = randf() * TAU
				pending.append(f)
		else:
			th.host = i
			th.st = "belly"
			th.vel = Vector2.ZERO
			th.off = random_belly_spot(w)
		belly_n += n
	if in_whale < 0 and swallow_cd <= 0.0 and state == "play" and in_mouth(w, whale_local(w, p_pos)):
		in_whale = i
		w.st = "hold"
		w.tmr = 0.0
		w.gulp = 0.6
		jet = Vector2.ZERO
		p_vel = Vector2.ZERO
		banner.text = "SWALLOWED"
		banner_t = 2.0
		for hz in [146.83, 110.0, 73.42]:
			play_note(hz)


func whale_hole(w: Whale) -> Vector2:
	return Vector2(-w.a * 0.12, -w.b * 0.95)


func hole_half_width(w: Whale) -> float:
	return maxf(w.b * 0.15, p_r * 1.25)


func update_belly_player(delta: float) -> void:
	var w := whales[in_whale]
	var l := whale_local(w, p_pos)
	if w.st == "spasm":
		# A strong current runs from the belly up through the hole on top. It is just water:
		# it pushes you, and if you ride it you shoot out of the whale.
		var hole := whale_hole(w)
		var target := Vector2(hole.x, minf(l.y, hole.y) - 300.0)
		var push := (target - l).normalized() * 1150.0
		l += push * delta
		var in_channel := absf(l.x - hole.x) < hole_half_width(w) and l.y < belly_center(w).y
		if not in_channel:
			l = belly_clamp(w, l, p_r)[0]
		p_pos = whale_world(w, l)
		if l.y < -w.b - p_r * 0.5:
			# Out of the hole: you keep the jet's momentum and coast away.
			in_whale = -1
			swallow_cd = 3.0
			jet = Vector2(push.x * w.dir, push.y)
			p_vel = Vector2.ZERO
			for hz in [261.63, 392.0, 523.25]:
				play_note(hz)
		return
	var res := belly_clamp(w, l, p_r)
	p_pos = whale_world(w, res[0])
	if res[1] and w.st == "hold":
		w.tickle += delta
		if randf() < delta * 25.0:
			add_spark(p_pos + (p_pos - whale_world(w, belly_center(w))).normalized() * p_r, Vector2.from_angle(randf() * TAU) * 60.0, 0.5, 2.0, Color(1.0, 0.75, 0.8))
		if w.tickle > 1.0:
			w.st = "spasm"
			w.tmr = 3.0
			play_note(87.31)
			play_note(82.41)
	elif w.st == "hold":
		w.tickle = maxf(w.tickle - delta * 0.5, 0.0)


func push_out_of_whales(pos: Vector2, r: float) -> Vector2:
	for i in whales.size():
		var w := whales[i]
		if w.st == "idle" or i == in_whale:
			continue
		var l := whale_local(w, pos)
		if absf(l.x) > w.a + r or absf(l.y) > w.b + r:
			continue
		if body_f(w, l) >= 1.0 or (w.st == "swim" and in_mouth(w, l)):
			continue
		if l.length() < 1.0:
			l = Vector2(0.0, -1.0)
		# Bisect for the body edge along the ray from the centre, then step out by r.
		var lo := 1.0
		var hi := 3.0
		for k in 10:
			var m := (lo + hi) * 0.5
			if body_f(w, l * m) < 1.0:
				lo = m
			else:
				hi = m
		var edge := l * hi
		pos = whale_world(w, edge + edge.normalized() * r * 0.6)
	return pos


func add_egg(pos: Vector2) -> void:
	var e := Thing.new()
	e.kind = "egg"
	e.pos = pos
	e.r = 16.0
	e.phase = randf() * TAU
	things.append(e)


func wake_egg(th: Thing) -> void:
	# Touching an egg wakes it: it wobbles and cracks for a moment, then the sea monkey bursts out.
	if th.st == "hatch":
		return
	th.st = "hatch"
	th.tmr = egg_hatch_time
	play_note(174.61)


func pop_egg(th: Thing) -> void:
	th.dead = true
	for i in 44:
		var a := randf() * TAU
		var c := Color(0.85, 0.95, 1.0).lerp(Color.WHITE, randf())
		add_spark(th.pos, Vector2.from_angle(a) * randf_range(60.0, 320.0), randf_range(0.5, 1.2), randf_range(1.5, 3.5), c)
	var sh := Thing.new()
	sh.kind = "shrimp"
	sh.r = randf_range(15.0, 17.5)  # about two stages bigger than a newborn cell
	sh.dmg = 12.0
	sh.pos = th.pos
	sh.vel = Vector2.from_angle(randf() * TAU) * 220.0
	sh.phase = randf() * TAU
	pending.append(sh)
	play_note(233.08)
	play_note(349.23)


func update_shrimp(th: Thing, delta: float) -> void:
	# Same rules as every other creature: it hunts you while it's bigger than you and
	# runs from you once you're bigger than it.
	var d := p_pos - th.pos
	var l := d.length()
	var want := Vector2.ZERO
	if th.r > p_r * EAT and not p_hidden and (l < 1800.0 or th.st == "hunt"):
		th.st = "hunt"
		var dn := d / maxf(l, 1.0)
		want = dn * 230.0 * SPEED * sea_monkey_speed + dn.orthogonal() * sin(t * 9.0 + th.phase) * 70.0
	else:
		th.st = "roam"
		if p_r > th.r * EAT and l < 420.0:
			want = -d / maxf(l, 1.0) * 300.0 * SPEED
		else:
			want = Vector2.from_angle(t * 0.4 + th.phase) * 70.0
	for o in things:
		if o != th and o.kind == "shrimp":
			var dd := th.pos - o.pos
			var ll := dd.length()
			if ll < 24.0 and ll > 0.01:
				want += dd / ll * 120.0
	th.vel = th.vel.lerp(want, 1.0 - exp(-7.0 * delta))


func stage_of(r: float) -> int:
	return maxi(1, 1 + int(floor(log(r / START_R) / log(STAGE_RATIO))))


func stage_needed(r: float) -> int:
	return maxi(1, 1 + int(ceil(log(r * EAT / START_R) / log(STAGE_RATIO))))


func stage_cost(s: int) -> float:
	return COST0 * pow(COST_G, s - 1)


func max_hp(s: int) -> float:
	return HP_BASE + HP_PER_STAGE * s


func bite_damage(th: Thing) -> float:
	# Bigger biters hit much harder: damage grows with the square of how much bigger they are.
	# Something about 3x your size takes a whole stage-1 health bar in one bite.
	var ratio := th.r / maxf(p_r, 1.0)
	return th.dmg * maxf(1.0, ratio * ratio / 1.5)


func hurt(amount: float, from: Vector2) -> void:
	# Health levels only. Health 0 drops you a stage; at stage 1 it kills you.
	if not health_on or state != "play" or grace_t > 0.0 or amount <= 0.0:
		return
	hp -= amount
	red_t = maxf(red_t, 0.55 if amount >= 5.0 else 0.22)
	if amount >= 5.0:
		hurt_t = 0.35
		var away := (p_pos - from).normalized() if p_pos.distance_to(from) > 0.1 else Vector2.RIGHT
		for i in 18:
			var a := away.angle() + PI + randf_range(-1.0, 1.0)
			add_spark(p_pos + Vector2.from_angle(a) * p_r, Vector2.from_angle(a) * randf_range(80.0, 260.0), randf_range(0.3, 0.7), randf_range(1.5, 3.0), Color(1.0, randf_range(0.4, 0.7), 0.45))
	if hp > 0.0:
		return
	if stage <= 1:
		hp = 0.0
		state = "dead"
		Engine.time_scale = 1.0
		play_note(98.0)
		play_note(92.5)
		return
	lose_stage()


func lose_stage() -> void:
	stage -= 1
	# You restart the lower stage at zero food; 20% of what it costs to climb back scatters.
	var cost := stage_cost(stage)
	food = cum_food(float(stage)) + 0.001
	hp = max_hp(stage)
	grace_t = 1.6
	hurt_cd = 1.6
	fx_t = 99.0
	Engine.time_scale = 1.0
	var n := maxi(3, int(round(cost * SCATTER_SHARE)))
	for i in n:
		var a := TAU * (i + randf() * 0.6) / n
		var f := Thing.new()
		f.kind = "food"
		f.st = "scatter"
		f.r = randf_range(5.0, 6.5)
		f.pos = p_pos + Vector2.from_angle(a) * p_r * 0.5
		f.vel = Vector2.from_angle(a) * randf_range(260.0, 520.0)
		f.tmr = SCATTER_DELAY
		f.phase = randf() * TAU
		pending.append(f)
	for i in 70:
		var a2 := randf() * TAU
		add_spark(p_pos + Vector2.from_angle(a2) * p_r, Vector2.from_angle(a2) * randf_range(120.0, 480.0), randf_range(0.5, 1.2), randf_range(1.5, 3.5), Color(0.8, 0.95, 1.0).lerp(Color(1.0, 0.5, 0.45), randf()))
	banner.text = "SHRUNK"
	banner_t = 2.2
	for hz in [392.0, 311.13, 233.08, 155.56]:
		play_note(hz)


# Total food needed to reach stage level L (L = 1 at the start).
func cum_food(level: float) -> float:
	return COST0 * (pow(COST_G, level - 1.0) - 1.0) / (COST_G - 1.0)


func level_of_food(f: float) -> float:
	return 1.0 + log(1.0 + f * (COST_G - 1.0) / COST0) / log(COST_G)


func radius_of_food(f: float) -> float:
	return START_R * pow(STAGE_RATIO, level_of_food(f) - 1.0)


func add_spark(pos: Vector2, vel: Vector2, life: float, size: float, col: Color, seek: bool = false) -> void:
	if sparks.size() > 700:
		return
	var sp := Spark.new()
	sp.pos = pos
	sp.vel = vel
	sp.life = life
	sp.max_life = life
	sp.size = size
	sp.col = col
	sp.seek = seek
	sparks.append(sp)


func key_color() -> Color:
	return Color.from_hsv(randf_range(0.32, 0.52), randf_range(0.45, 0.85), 1.0)


func swallow_burst(pos: Vector2, pr: float, gold: bool) -> void:
	var n := 80 if gold else 34
	for i in n:
		var a := randf() * TAU
		var sp := randf_range(120.0, 520.0) * clampf(pr / 30.0, 0.7, 1.8)
		var c := Color(1.0, randf_range(0.8, 0.97), randf_range(0.35, 0.8)) if gold else key_color()
		add_spark(pos, Vector2.from_angle(a) * sp, randf_range(0.6, 1.5), randf_range(1.5, 4.0), c)
	for i in (36 if gold else 16):
		var a2 := randf() * TAU
		var from := pos + Vector2.from_angle(a2) * p_r * randf_range(2.2, 3.4)
		var tang := Vector2.from_angle(a2 + PI / 2.0) * randf_range(150.0, 320.0)
		add_spark(from, tang, randf_range(1.2, 2.0), randf_range(2.0, 4.0), Color(1.0, 0.92, 0.55) if gold else key_color(), true)


func eat_pearl(th: Thing) -> void:
	# The pearl rides inside you. Bring it back to the home circle to win.
	inside.append(["pearl", th.r])
	if not pearl_bonus:
		pearl_bonus = true
		food += stage_cost(stage_of(p_r))
		pearl_t = 2.5
	swallow_burst(th.pos, th.r, true)
	for hz in [523.25, 659.25, 783.99, 1046.5]:
		play_note(hz)
	banner.text = "BRING THE PEARL HOME"
	banner_t = 2.4


func has_pearl() -> bool:
	for it in inside:
		if it[0] == "pearl":
			return true
	return false


func drop_pearl(away: Vector2) -> void:
	# Dashing shakes the pearl loose: it pops out behind you.
	for i in inside.size():
		if inside[i][0] != "pearl":
			continue
		var pr: float = inside[i][1]
		inside.remove_at(i)
		var pe := Thing.new()
		pe.kind = "pearl"
		pe.st = "goal"
		pe.r = pr
		pe.pos = p_pos - away * (p_r + pr + 6.0)
		pe.vel = -away * 220.0
		pe.tmr = 1.2  # can't be swallowed again straight away
		pe.phase = randf() * TAU
		if in_whale >= 0:
			pe.host = in_whale
			pe.off = whale_local(whales[in_whale], pe.pos)
		pending.append(pe)
		swallow_burst(pe.pos, pr * 0.5, true)
		play_note(392.0)
		play_note(311.13)
		banner.text = "PEARL DROPPED"
		banner_t = 1.4
		return


func update_fx(delta: float) -> void:
	# Smooth growth toward the size the current food total entitles you to.
	var rate := 5.0 if pearl_t <= 0.0 else 1.1
	pearl_t = maxf(pearl_t - delta, 0.0)
	p_r = lerpf(p_r, radius_of_food(food), 1.0 - exp(-rate * delta))
	for sp in sparks:
		sp.life -= delta
		if sp.seek:
			sp.vel = sp.vel.lerp((p_pos - sp.pos).normalized() * 700.0, 1.0 - exp(-3.5 * delta))
			if sp.pos.distance_to(p_pos) < p_r * 0.35:
				sp.life = 0.0
		else:
			sp.vel *= exp(-1.8 * delta)
		sp.pos += sp.vel * delta
	sparks = sparks.filter(func(x: Spark) -> bool: return x.life > 0.0)
	if state == "play":
		for th in things:
			if th.host >= 0 and th.host != in_whale:
				continue  # nothing shows through a whale's body
			if th.kind == "pearl" and th.pos.distance_to(p_pos) < 1500.0 / cam.zoom.x:
				if randf() < delta * 16.0:
					var c := Color(1.0, randf_range(0.85, 1.0), randf_range(0.5, 0.9))
					add_spark(th.pos + Vector2.from_angle(randf() * TAU) * th.r * randf_range(0.3, 1.25), Vector2(randf_range(-10, 10), randf_range(-26, -8)), randf_range(0.9, 1.9), randf_range(1.5, 3.2), c)
			elif th.kind == "key" and th.pos.distance_to(p_pos) < 1500.0 / cam.zoom.x:
				if randf() < delta * 9.0:
					# Keys shed little vibrant motes that spiral outward and fade.
					var ang := randf() * TAU
					add_spark(th.pos + Vector2.from_angle(ang) * th.r * 1.5, Vector2.from_angle(ang + 1.2) * randf_range(20, 45), randf_range(0.8, 1.6), randf_range(1.2, 2.4), key_color())


func base_zoom(s: int) -> float:
	return ZOOM_START * pow(ZOOM_PER_STAGE, s - 1)


func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 0.01)
	t += delta
	if state == "menu":
		menu_input()
	else:
		if Input.is_key_pressed(KEY_R) or Input.is_joy_button_pressed(0, JOY_BUTTON_START):
			reset()
		if Input.is_key_pressed(KEY_ESCAPE) or Input.is_joy_button_pressed(0, JOY_BUTTON_BACK):
			reset()
			state = "menu"
			confirm_prev = true
	if state == "won" and (Input.is_key_pressed(KEY_N) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)):
		level = level % (LEVEL_SCENES.size() + 1) + 1
		reset()
	if state == "play":
		var t0 := Time.get_ticks_usec()
		step(delta)
		prof["step"] += Time.get_ticks_usec() - t0
		intro_t += real_delta
	if state != "menu":
		update_fx(delta)

	# Stage-up cutscene: slow motion + extra zoom pull-back that settles at the new zoom.
	if fx_t < 99.0:
		fx_t += real_delta
		if fx_t < 1.6:
			Engine.time_scale = lerpf(0.3, 1.0, smoothstep(0.7, 1.6, fx_t))
		else:
			Engine.time_scale = 1.0
		if fx_t > 4.0:
			fx_t = 99.0
	banner_t = maxf(banner_t - real_delta, 0.0)
	flash_t = maxf(flash_t - real_delta, 0.0)
	flash_rect.color.a = clampf(flash_t / 0.7, 0.0, 1.0) * 0.85
	hurt_t = maxf(hurt_t - real_delta, 0.0)
	red_t = maxf(red_t - real_delta, 0.0)
	red_vig.modulate.a = clampf(red_t / 0.55, 0.0, 1.0) * 0.45
	banner.modulate.a = clampf(banner_t / 0.6, 0.0, 1.0) if banner_t < 0.6 else 1.0

	zoom_s = lerpf(zoom_s, base_zoom(stage), 1.0 - exp(-2.5 * real_delta))
	var intro := 1.0 + 1.1 * pow(1.0 - clampf(intro_t / 3.2, 0.0, 1.0), 2.0)
	# Never zoom out so far that the map fits the screen: always keep a little scrolling.
	var zmin := maxf(1920.0 / (world.x * 0.98), 1080.0 / (world.y * 0.98))
	cam.zoom = Vector2.ONE * maxf(zoom_s * intro, zmin)
	cam.position = p_pos

	var msg := "Level %d   Food %d" % [level, int(food)]
	if health_on:
		msg += "   Health %d/%d (0 = you shrink)" % [int(ceil(hp)), int(max_hp(stage))]
	if keys_total > 0:
		msg += "   Gate OPEN" if gate_open else "   Keys %d/%d" % [keys, keys_needed]
	msg += "   Ammo %d" % ammo
	msg += "\nCarrying the golden pearl: get it home to the glowing circle (dashing drops it)" if has_pearl() else "\nFind the golden pearl and bring it back to the glowing circle where you started"
	if in_whale >= 0 and state == "play":
		msg += "\nInside a whale!  Poke the wriggly belly lining to get blasted out the top."
	if state == "dead" and health_on:
		msg = "Your membrane burst at stage 1.  Press R to restart."
	elif state == "dead":
		msg = "Devoured.  Press R to restart."
	elif state == "won":
		msg = "You brought the golden pearl home!  N / A: next level   R: replay"
	var help := ["arrows: steer   space: dash", "left stick / d-pad: steer   A: dash", "mouse: steer   space: dash"]
	hud.text = msg + "\n" + help[control] + " (costs 1 ammo)   R / Start: restart   Esc / Back: menu"
	if abilities_on and state == "play":
		var row := ""
		for i in AB_NAMES.size():
			if (ab_enabled & (1 << i)) == 0:
				continue
			var nm: String = AB_NAMES[i]
			if i == 1:
				nm = "Spike" if stage >= harpoon_up_stage else "Hook"
			nm += " (%d)" % AB_COST[i]
			if ab_cd[i] > 0.0:
				nm += " %.0f" % ceil(ab_cd[i])
			row += ("[ %s ]" % nm if i == ab_sel else "  %s  " % nm) + "  "
		hud.text += "\nAbility (ammo cost):  " + row + "\nQ / E or LB / RB: switch    F, X or right-click: use"
	if state == "menu":
		var lines := "AMOEBA GAME\n\nLevel %d   (press 1-%d, or shoulder buttons, to change)\n\nChoose your controls  (up/down, then Enter / Space / A)\n\n" % [level, LEVEL_SCENES.size() + 1]
		for i in CONTROL_NAMES.size():
			lines += ("  > " if i == menu_sel else "    ") + CONTROL_NAMES[i] + "\n"
		if menu_sel == 1 and Input.get_connected_joypads().is_empty():
			lines += "\nNo joystick detected yet. Plug one in and press a button."
		hud.text = lines
	var fps := Engine.get_frames_per_second()
	fps_label.text = "%d FPS" % fps
	fps_label.modulate = Color(0.5, 1.0, 0.6) if fps >= 55 else (Color(1.0, 0.85, 0.4) if fps >= 30 else Color(1.0, 0.45, 0.4))
	prof["frames"] += 1
	if prof_on and prof["frames"] >= 60:
		print("things %d rocks %d | step %.2f ms  draw %.2f ms  fps %d" % [things.size(), rocks.size(), prof["step"] / 60000.0, prof["draw"] / 60000.0, fps])
		prof = {"step": 0, "draw": 0, "frames": 0}
	queue_redraw()


func switch_level(n: int) -> void:
	if n == level:
		return
	level = n
	reset()
	state = "menu"
	confirm_prev = true


func menu_input() -> void:
	if Input.is_key_pressed(KEY_1) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER):
		switch_level(1)
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER):
		switch_level(mini(level + 1, LEVEL_SCENES.size() + 1))
	else:
		for lv in LEVEL_SCENES:
			if Input.is_key_pressed(KEY_0 + lv):
				switch_level(lv)
	var nav := 0
	if Input.is_key_pressed(KEY_UP) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP) or Input.get_joy_axis(0, JOY_AXIS_LEFT_Y) < -0.6:
		nav = -1
	elif Input.is_key_pressed(KEY_DOWN) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN) or Input.get_joy_axis(0, JOY_AXIS_LEFT_Y) > 0.6:
		nav = 1
	if nav != 0 and nav != nav_prev:
		menu_sel = posmod(menu_sel + nav, CONTROL_NAMES.size())
	nav_prev = nav
	var confirm := Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER) or Input.is_key_pressed(KEY_SPACE) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	if confirm and not confirm_prev:
		if menu_sel == 3:
			get_tree().quit()
			return
		control = menu_sel
		state = "play"
		intro_t = 0.0
		space_was = true
	confirm_prev = confirm


func move_vector() -> Vector2:
	if steer_test != Vector2.ZERO:
		return steer_test
	if control == 0:
		var v := Vector2(float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT)), float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP)))
		return v.limit_length(1.0)
	if control == 1:
		var s := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
		if s.length() < 0.2:
			s = Vector2.ZERO
		var pad := Vector2(float(Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT)), float(Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN)) - float(Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP)))
		return (s + pad).limit_length(1.0)
	var to := get_global_mouse_position() - p_pos
	if to.length() <= 8.0:
		return Vector2.ZERO
	return (to / 120.0).limit_length(1.0)


func rebuild_rock_grid() -> void:
	# Each rock is filed under every cell within half a cell of it, so a small object only
	# has to check the one cell it sits in.
	rock_grid.clear()
	var pad := ROCK_CELL * 0.5
	for rk in rocks:
		var lo := ((rk.pos - Vector2.ONE * (rk.r + pad)) / ROCK_CELL).floor()
		var hi := ((rk.pos + Vector2.ONE * (rk.r + pad)) / ROCK_CELL).floor()
		for cx in range(int(lo.x), int(hi.x) + 1):
			for cy in range(int(lo.y), int(hi.y) + 1):
				var key := Vector2i(cx, cy)
				if not rock_grid.has(key):
					rock_grid[key] = []
				rock_grid[key].append(rk)
	rock_grid_dirty = false
	rock_grid_count = rocks.size()


func resolve_rocks(pos: Vector2, r: float) -> Vector2:
	if rock_grid_dirty or rock_grid_count != rocks.size():
		rebuild_rock_grid()
	var list: Array = rocks
	if r <= ROCK_CELL * 0.5:
		list = rock_grid.get(Vector2i((pos / ROCK_CELL).floor()), [])
	for rk: Rock in list:
		var d := pos - rk.pos
		var m := r + rk.r
		if absf(d.x) > m or absf(d.y) > m:
			continue
		var l2 := d.length_squared()
		if l2 < m * m:
			var l := sqrt(l2)
			pos += (d / l if l > 0.001 else Vector2.RIGHT) * (m - l)
	return pos


func open_gate() -> void:
	if gate_open:
		return
	gate_open = true
	rocks = rocks.filter(func(x: Rock) -> bool: return not x.gate)
	for hz in [196.0, 293.66, 392.0, 493.88]:
		play_note(hz)
	banner.text = "THE GATE OPENS"
	banner_t = 2.5


func step(delta: float) -> void:
	var mv := move_vector()
	var dir := mv.normalized() if mv.length() > 0.01 else Vector2.ZERO
	var spd := 230.0 * SPEED * pow(START_R / p_r, 0.25)
	var want := mv * spd
	p_vel = p_vel.lerp(want, 1.0 - exp(-6.0 * delta))
	var sp := Input.is_key_pressed(KEY_SPACE) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	if sp and not space_was and ammo > 0 and dash_time <= 0.0:
		ammo -= 1
		dash_time = 0.22
		dash_dir = dir if dir != Vector2.ZERO else (p_vel.normalized() if p_vel.length() > 1.0 else Vector2.RIGHT)
		play_note(130.81)
		drop_pearl(dash_dir)
	space_was = sp
	if dash_time > 0.0:
		dash_time -= delta
		p_vel = dash_dir * 650.0 * SPEED
	if dir != Vector2.ZERO:
		aim_dir = dir
	if abilities_on:
		ability_input(delta)
	if rocket_t > 0.0:
		# Afterburner: a slow start, then a quarter of the way through it kicks in hard.
		# You can steer it a little (up to rocket_turn_deg off your starting heading), never turn around.
		rocket_t -= delta
		var prog := 1.0 - rocket_t / rocket_len
		if dir != Vector2.ZERO:
			var want_a := clampf(angle_difference(rocket_base.angle(), dir.angle()), -deg_to_rad(rocket_turn_deg), deg_to_rad(rocket_turn_deg))
			var cur_a := angle_difference(rocket_base.angle(), rocket_dir.angle())
			cur_a = move_toward(cur_a, want_a, deg_to_rad(110.0) * delta)
			rocket_dir = rocket_base.rotated(cur_a)
		var fast := maxf(rocket_boost, spd * 3.5)
		var rs := lerpf(spd * 0.9, spd * 1.3, prog / 0.25) if prog < 0.25 else lerpf(spd * 1.3, fast, smoothstep(0.25, 0.33, prog))
		if prog > 0.85:
			rs = lerpf(rs, spd, smoothstep(0.85, 1.0, prog))
		p_vel = rocket_dir * rs
		var burn := prog >= 0.25
		if randf() < delta * (70.0 if burn else 20.0):
			var back := -rocket_dir.rotated(randf_range(-0.35, 0.35))
			var col := Color(1.0, 0.6, 0.25).lerp(Color(1.0, 0.95, 0.6), randf()) if burn else Color(0.6, 0.85, 1.0, 0.7)
			add_spark(p_pos + back * p_r, back * randf_range(150.0, 420.0) * (1.0 if burn else 0.4), randf_range(0.25, 0.5), randf_range(2.0, 3.5) * (1.0 if burn else 0.6), col)
	if not nuclei.is_empty() and in_whale < 0:
		var acc := nucleus_gravity(p_pos)
		grav_vel += acc * delta
		# Momentum lingers inside a nucleus' pull (so you can slingshot) and fades once you're clear.
		grav_vel *= exp(-(0.15 if acc != Vector2.ZERO else 0.8) * delta)
		grav_vel = grav_vel.limit_length(2200.0)
	var flow := Vector2.ZERO
	if in_whale < 0 and (not currents.is_empty() or not whales.is_empty()):
		flow = flow_at(p_pos, CURRENT_GRIP * spd)
		# Currents barely move a truly massive cell: full push up to stage 10, ~5% by stage 18.
		var big := smoothstep(START_R * pow(STAGE_RATIO, 9.0), START_R * pow(STAGE_RATIO, 17.0), p_r)
		flow *= 1.0 - 0.95 * big
	jet *= exp(-1.3 * delta)
	swallow_cd = maxf(swallow_cd - delta, 0.0)
	p_pos += (p_vel + flow + jet + grav_vel) * delta
	for nu in nuclei:
		# The nucleus itself is solid: you slide around its surface.
		var nd: Vector2 = p_pos - nu[0]
		var nm: float = nu[1] + p_r
		if nd.length() < nm:
			var nn := nd.normalized() if nd.length() > 0.01 else Vector2.UP
			p_pos = nu[0] + nn * nm
			var vn := grav_vel.dot(nn)
			if vn < 0.0:
				grav_vel -= nn * vn
	if abilities_on:
		update_abilities(delta)
	var chomped := false
	for rk in rocks:
		if rk.eat_stage > 0 and stage >= rk.eat_stage and p_pos.distance_to(rk.pos) < p_r + rk.r + 2.0:
			rk.eat_stage = -1
			chomped = true
	if chomped:
		rocks = rocks.filter(func(x: Rock) -> bool: return x.eat_stage >= 0)
		play_note(note(eaten) * 0.5)
	p_pos = resolve_rocks(p_pos, p_r)

	krill_timer -= delta
	if krill_timer <= 0.0 and krill_respawn and krill_left != 0:
		krill_timer = 0.5
		respawn_krill()
	if krill_timer <= 0.0:
		krill_timer = 0.5
	if fmod(t, 0.5) < delta:
		refill_current_food()
	update_whales(delta)
	if in_whale >= 0:
		update_belly_player(delta)
	else:
		p_pos = push_out_of_whales(p_pos, p_r)
		p_pos = p_pos.clamp(Vector2(p_r, p_r), world - Vector2(p_r, p_r))

	for i in school_pos.size():
		school_pos[i] = school_base[i] + Vector2(sin(t * 0.2 + i), cos(t * 0.17 + i * 2.0)) * 220.0

	if health_on:
		hurt_cd = maxf(hurt_cd - delta, 0.0)
		grace_t = maxf(grace_t - delta, 0.0)
		for d in drains:
			if p_pos.distance_to(d[0]) < d[1] + p_r * 0.5:
				hurt(d[2] * delta, d[0])
				if randf() < delta * 30.0:
					var a := randf() * TAU
					add_spark(p_pos + Vector2.from_angle(a) * p_r, Vector2.from_angle(a) * randf_range(20.0, 70.0), randf_range(0.4, 0.8), randf_range(1.2, 2.2), Color(0.7, 1.0, 0.4))

	for v in vines:
		if v.triggered:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(p_pos, v.a, v.b)
		if p_pos.distance_to(closest) < 360.0:
			v.timer += delta
		else:
			v.timer = maxf(v.timer - delta * 0.5, 0.0)
		if v.timer > 2.2:
			v.triggered = true
			play_note(87.31)

	var threats: Array = [[p_pos, p_r]]
	for th in things:
		if th.kind == "mid" or th.kind == "whale":
			threats.append([th.pos, th.r])

	var near_flow := not currents.is_empty() or not wakes.is_empty() or not whales.is_empty()
	scatter_list.clear()
	if health_on:
		for th in things:
			if th.kind == "food" and th.st == "scatter" and not th.dead:
				scatter_list.append(th)
	var awake := 2600.0 / cam.zoom.x  # plain food farther than this from you sits still (no visible difference)
	for th in things:
		if th.kind == "food" and th.host < 0 and th.st != "scatter" and (absf(th.pos.x - p_pos.x) > awake or absf(th.pos.y - p_pos.y) > awake * 0.6):
			continue
		if th.host >= 0:
			# Inside a whale's belly: drift slowly, carried along with the whale.
			var hw := whales[th.host]
			th.off += Vector2(sin(t * 0.5 + th.phase), cos(t * 0.4 + th.phase * 1.3)) * 14.0 * delta
			th.off = belly_clamp(hw, th.off, th.r + 10.0)[0]
			th.pos = whale_world(hw, th.off)
			continue
		if th.kind == "krill" and th.st == "swarm":
			update_swarm_krill(th, delta)
			th.pos += th.vel * delta
			th.face = th.vel.angle()
			continue
		th.hit_t = maxf(th.hit_t - delta, 0.0)
		th.bite_cd = maxf(th.bite_cd - delta, 0.0)
		if th.stun > 0.0:
			th.stun -= delta
			th.vel *= exp(-5.0 * delta)
			th.pos += th.vel * delta
			th.pos = th.pos.clamp(Vector2(th.r, th.r), world - Vector2(th.r, th.r))
			continue
		match th.kind:
			"meat":
				th.vel = th.vel.lerp(Vector2.from_angle(th.phase + t * 0.3) * 10.0, 1.0 - exp(-1.5 * delta))
			"pearl":
				th.vel *= exp(-2.5 * delta)
				th.tmr = maxf(th.tmr - delta, 0.0)
			"egg":
				if th.st == "hatch":
					th.tmr -= delta
					if th.tmr <= 0.0:
						pop_egg(th)
			"food":
				th.vel = th.vel.lerp(Vector2.from_angle(th.phase + t * 0.3) * 12.0, 1.0 - exp(-2.0 * delta))
				th.tmr = maxf(th.tmr - delta, 0.0)  # scattered food: pickup delay
			"krill":
				update_krill(th, threats, delta)
			"mid":
				update_mid(th, delta)
			"whale":
				update_whale(th, delta)
			"larva":
				update_larva(th, delta)
			"shrimp":
				update_shrimp(th, delta)
			"angler":
				update_angler(th, delta)
		if not inks.is_empty() and is_enemy(th):
			var fl := ink_flee(th.pos)
			if fl != Vector2.ZERO:
				th.vel = th.vel.lerp(fl, 1.0 - exp(-6.0 * delta))
		th.pos += th.vel * delta
		for nu in nuclei:
			var tn: Vector2 = th.pos - nu[0]
			if tn.length() < nu[1] + th.r:
				th.pos = nu[0] + (tn.normalized() if tn.length() > 0.01 else Vector2.UP) * (nu[1] + th.r)
		if near_flow and th.kind != "egg" and th.pos.distance_squared_to(p_pos) < 2.25e6:
			th.pos += flow_at(th.pos) * delta * (0.6 if th.kind == "mid" else 1.0)
		if not whales.is_empty():
			th.pos = push_out_of_whales(th.pos, th.r)
		if th.kind != "food" and th.kind != "key" and not (th.kind == "pearl" and th.vel == Vector2.ZERO) and not (th.kind == "larva" and th.st == "attached"):
			th.pos = resolve_rocks(th.pos, th.r)
		th.pos = th.pos.clamp(Vector2(th.r, th.r), world - Vector2(th.r, th.r))
		if th.vel.length() > 6.0 and th.kind != "angler":
			th.face = th.vel.angle()
		var fc := cos(th.face)
		if absf(fc) > 0.25:
			th.flip = move_toward(th.flip, signf(fc), delta * 5.0)

	var prey: Array[Thing] = []
	for k in things:
		if (k.kind == "krill" and k.host < 0) or (health_on and k.kind == "food" and k.st == "scatter"):
			prey.append(k)
	for pr in things:
		if (pr.kind == "mid" or pr.kind == "whale") and pr.host < 0:
			for k in prey:
				if k.kind == "krill" and not k.dead and k.host < 0 and pr.pos.distance_to(k.pos) < pr.r * 0.6:
					k.dead = true
				elif health_on and k.kind == "food" and k.st == "scatter" and k.tmr <= 0.0 and not k.dead and pr.pos.distance_to(k.pos) < pr.r * 0.8:
					k.dead = true  # enemies steal the food you dropped

	for th in things:
		if th.dead or th.host != in_whale:
			continue  # you can only reach things on the same side of a whale's wall
		var l := p_pos.distance_to(th.pos)
		if th.kind == "key":
			if l < p_r + th.r:
				th.dead = true
				keys += 1
				inside.append(["key", th.r])
				swallow_burst(th.pos, 20.0, false)
				ammo = mini(ammo + 1, ammo_max)
				play_note(note(keys) * 2.0)
				if keys >= keys_needed:
					open_gate()
				else:
					banner.text = "KEY %d / %d" % [keys, keys_needed]
					banner_t = 1.6
			continue
		if th.kind == "egg":
			if l < p_r + th.r:
				wake_egg(th)
			continue
		if (th.kind == "food" or th.kind == "pearl") and th.tmr > 0.0:
			continue
		if th.kind == "meat":
			# Meat chunks can always be eaten, whatever your size.
			if l < p_r + th.r * 0.5:
				th.dead = true
				food += th.val
				ammo = mini(ammo + 1, ammo_max)
				play_note(note(eaten))
				eaten += 1
			continue
		if th.kind == "angler" and th.pearl >= 0 and (th.stun > 0.0 or p_hidden):
			# Stunned (or you're hidden in ink): you can pluck the ball off its lure.
			var lp := lure_pos(th)
			if p_pos.distance_to(lp) < p_r and p_r > th.pearl_r * EAT:
				take_lure(th)
		if health_on and th.kind != "pearl" and th.r > p_r * EAT and not (th.kind == "larva" and th.st == "attached"):
			# Health levels: bigger creatures bite on touch (with a cooldown) instead of swallowing you.
			if l < th.r + p_r * 0.6 and th.bite_cd <= 0.0 and hurt_cd <= 0.0 and grace_t <= 0.0 and th.stun <= 0.0:
				var away := (p_pos - th.pos) / maxf(l, 1.0)
				th.bite_cd = 1.4
				hurt_cd = 0.5
				th.vel = -away * 260.0
				p_vel += away * 520.0
				play_note(110.0)
				play_note(116.54)
				hurt(bite_damage(th), th.pos)
				if state != "play":
					break
			continue
		if p_r > th.r * EAT and l < p_r - th.r * 0.3:
			th.dead = true
			if th.kind == "pearl":
				eat_pearl(th)
				continue
			food += th.val if th.kind == "food" and th.val > 0.0 else FOOD_PTS.get(th.kind, 1.0)
			ammo = mini(ammo + 1, ammo_max)
			var hz: float = note(eaten)
			eaten += 1
			play_note(hz)
		elif th.kind != "pearl" and th.r > p_r * EAT and l < th.r * 0.8 and th.stun <= 0.0 and not (th.kind == "larva" and th.st == "attached"):
			state = "dead"
			Engine.time_scale = 1.0
			play_note(98.0)
			break
	things = things.filter(func(x: Thing) -> bool: return not x.dead)
	things.append_array(pending)
	pending.clear()
	# Inside a whale you are slowly digested.
	if in_whale >= 0 and health_on and state == "play":
		hurt(whale_digest * delta, p_pos)
	# Home with the pearl: you win.
	if state == "play" and win_t <= 0.0 and in_whale < 0 and has_pearl() and p_pos.distance_to(home_pos) < home_r:
		win_t = 1.6
		banner.text = "HOME WITH THE PEARL"
		banner_t = 2.6
		for i in 60:
			var a := randf() * TAU
			add_spark(home_pos + Vector2.from_angle(a) * home_r, Vector2.from_angle(a) * randf_range(60.0, 260.0), randf_range(0.8, 1.6), randf_range(2.0, 4.0), Color(1.0, 0.9, 0.55))

	var s := stage_of(p_r)
	# (The size check skips the stage-up while you are still shrinking after a stage loss.)
	if s > stage and state == "play" and p_r <= radius_of_food(food) + 0.01:
		hp = max_hp(s)  # growing heals you fully
		stage = s
		fx_t = 0.0
		banner.text = "BIGGER"
		banner_t = 2.6
		var root: float = note(stage)
		for hz in [root, root * 1.5, root * 2.0]:
			play_note(hz)

	if hp_test >= 0.0:
		hp = max_hp(stage) * hp_test
		hp_test = -1.0

	if win_t > 0.0:
		win_t -= delta
		if win_t <= 0.0:
			state = "won"
			Engine.time_scale = 1.0
			for hz in [392.0, 523.25, 659.25, 783.99]:
				play_note(hz)


func respawn_krill() -> void:
	var counts: Array[int] = []
	counts.resize(school_pos.size())
	counts.fill(0)
	for th in things:
		if th.kind == "krill" and th.school >= 0 and th.host < 0 and th.st != "swarm":
			counts[th.school] += 1
	var view := Rect2(p_pos - Vector2(1920, 1080) * 0.5 / cam.zoom.x, Vector2(1920, 1080) / cam.zoom.x).grow(160.0)
	for s in school_pos.size():
		if counts[s] >= 14:
			continue
		for attempt in 6:
			var off := Vector2.from_angle(randf() * TAU) * randf_range(20.0, 320.0)
			var pos := school_pos[s] + off
			if view.has_point(pos) or not Rect2(Vector2.ZERO, world).has_point(pos) or not free_spot(pos, 8.0):
				continue
			var kr := Thing.new()
			kr.kind = "krill"
			kr.r = randf_range(6.0, 8.0)
			kr.off = off.limit_length(60.0)
			kr.pos = pos
			kr.school = s
			kr.phase = randf() * TAU
			things.append(kr)
			if krill_left > 0:
				krill_left -= 1
			break


func update_krill(th: Thing, threats: Array, delta: float) -> void:
	var flee := Vector2.ZERO
	for tr in threats:
		var d: Vector2 = th.pos - tr[0]
		var l := d.length()
		var reach: float = 90.0 + float(tr[1]) * 1.5
		if l < reach:
			flee += d / maxf(l, 1.0) * (1.0 - l / reach)
	var want: Vector2
	if flee.length() > 0.01:
		want = flee.normalized() * 270.0 * SPEED
	else:
		want = ((school_pos[th.school] + th.off) - th.pos) * 1.5
		want = want.limit_length(150.0 * SPEED) + Vector2.from_angle(t * 1.7 + th.phase) * 30.0
	th.vel = th.vel.lerp(want, 1.0 - exp(-8.0 * delta))


func update_swarm_krill(th: Thing, delta: float) -> void:
	# The big fleeing krill swarm running ahead of a whale.
	var w := whales[th.school]
	var home := Vector2(w.swarm_x, w.pos.y) + th.off + Vector2(sin(t * 1.3 + th.phase), cos(t * 1.1 + th.phase)) * 30.0
	var want := (home - th.pos) * 1.6
	want = want.limit_length(w.speed * 2.2)
	var d := th.pos - p_pos
	var reach := 90.0 + p_r * 1.5
	if d.length() < reach:
		want += d.normalized() * 300.0 * SPEED * (1.0 - d.length() / reach)
	th.vel = th.vel.lerp(want, 1.0 - exp(-6.0 * delta))
	if (w.dir > 0.0 and th.pos.x > world.x + 700.0) or (w.dir < 0.0 and th.pos.x < -700.0):
		th.dead = true  # swam off the far side of the map


func update_mid(th: Thing, delta: float) -> void:
	var d := p_pos - th.pos
	var l := d.length()
	var want: Vector2
	if p_r * EAT < th.r and l < 380.0 and not p_hidden:
		want = d.normalized() * 155.0 * SPEED
	elif p_r > th.r * EAT and l < 260.0:
		want = -d.normalized() * 170.0 * SPEED
	else:
		want = Vector2.from_angle(th.phase + t * 0.3 + sin(t * 0.11 + th.phase)) * 50.0
	if health_on:
		# After a bite the hunter backs off, and it goes for any food you dropped nearby.
		var best: Thing = null
		var bd := 520.0
		for f in scatter_list:
			if not f.dead:
				var fd := th.pos.distance_to(f.pos)
				if fd < bd:
					bd = fd
					best = f
		if best != null and (th.bite_cd > 0.0 or p_r * EAT >= th.r or l > 380.0):
			want = (best.pos - th.pos).normalized() * 165.0 * SPEED
		elif th.bite_cd > 0.6:
			want = -d.normalized() * 120.0 * SPEED
	th.vel = th.vel.lerp(want, 1.0 - exp(-4.0 * delta))


func update_larva(th: Thing, delta: float) -> void:
	if th.st == "attached":
		th.vel = Vector2.ZERO
		if vines[th.school].triggered:
			th.tmr -= delta
			if th.tmr <= 0.0:
				th.st = "swarm"
		return
	var d := p_pos - th.pos
	var l := d.length()
	var want: Vector2
	if p_r < th.r * EAT and l < 900.0:
		want = d.normalized() * 260.0 * SPEED + Vector2.from_angle(t * 6.0 + th.phase) * 60.0
	elif p_r > th.r * EAT and l < 300.0:
		want = -d.normalized() * 200.0 * SPEED
	else:
		want = Vector2.from_angle(th.phase + t * 0.4) * 40.0
	th.vel = th.vel.lerp(want, 1.0 - exp(-5.0 * delta))


func update_whale(th: Thing, delta: float) -> void:
	var d := p_pos - th.pos
	var l := d.length()
	match th.st:
		"roam":
			var want := Vector2.from_angle(th.phase + t * 0.15) * 55.0
			th.vel = th.vel.lerp(want, 1.0 - exp(-2.0 * delta))
			if p_r * EAT < th.r and l < 520.0:
				th.st = "wind"
				th.tmr = 0.9
		"wind":
			th.vel = th.vel.lerp(Vector2.ZERO, 1.0 - exp(-6.0 * delta))
			th.face = d.angle()
			th.tmr -= delta
			if th.tmr <= 0.0:
				th.st = "lunge"
				th.tmr = 0.55
				th.dir = d.normalized()
		"lunge":
			th.vel = th.dir * 430.0 * SPEED
			th.tmr -= delta
			if th.tmr <= 0.0:
				th.st = "rest"
				th.tmr = 2.8
		"rest":
			th.vel = th.vel.lerp(Vector2.ZERO, 1.0 - exp(-3.0 * delta))
			th.tmr -= delta
			if th.tmr <= 0.0:
				th.st = "roam"


func play_note(freq: float) -> void:
	var pl := voices[voice_i]
	voice_i = (voice_i + 1) % voices.size()
	pl.play()
	var pb := pl.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var n := int(MIX * 0.5)
	for i in n:
		var tt := float(i) / MIX
		var s := sin(TAU * freq * tt) * exp(-tt * 6.0) * 0.3 + sin(TAU * freq * 2.0 * tt) * exp(-tt * 9.0) * 0.08
		pb.push_frame(Vector2(s, s))


func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	_draw_world()
	prof["draw"] += Time.get_ticks_usec() - t0


func _draw_world() -> void:
	# Deep water: a little blue light near the top of the map, nearly black at the bottom.
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(world.x, 0.0), world, Vector2(0.0, world.y)]),
		PackedColorArray([Color(0.012, 0.04, 0.07), Color(0.012, 0.04, 0.07), Color(0.0, 0.008, 0.02), Color(0.0, 0.008, 0.02)]))
	draw_rect(Rect2(Vector2.ZERO, world), Color(0.1, 0.2, 0.3, 0.3), false, 6.0)
	# Only draw what the camera can see (plus a margin): off-screen drawing was the main slowdown.
	var vsize := Vector2(1920, 1080) / cam.zoom.x
	var vr := Rect2(cam.get_screen_center_position() - vsize * 0.5, vsize).grow(40.0)
	var speck_view := vr.grow(20.0)
	# Zoomed far out, specks pile up on screen: draw a share of them so the density looks the same.
	var stride := maxi(1, int(round(0.6 / cam.zoom.x)))
	for si in range(0, specks.size(), stride):
		var s: Array = specks[si]
		# Marine snow: drifts slowly down, sways a little, wraps back to the top.
		var base: Vector2 = s[0]
		var sp := Vector2(base.x + sin(t * 0.2 + s[2] * 9.0) * 10.0, fposmod(base.y + t * (5.0 + 14.0 * s[2]), world.y))
		if not speck_view.has_point(sp):
			continue
		var sr: float = s[1]
		if s[2] > 0.96:
			# A few bioluminescent motes pulse blue-green.
			var gl := 0.5 + 0.5 * sin(t * (1.2 + s[2]) + s[2] * 40.0)
			draw_circle(sp, sr * 3.5, Color(0.2, 0.9, 0.8, 0.05 * gl))
			draw_circle(sp, sr * 0.9, Color(0.5, 1.0, 0.9, 0.25 + 0.4 * gl))
		elif sr * cam.zoom.x < 2.5:
			draw_rect(Rect2(sp - Vector2(sr, sr) * 0.8, Vector2(sr, sr) * 1.6), Color(0.7, 0.75, 0.8, 0.09))
		else:
			draw_circle(sp, sr, Color(0.7, 0.75, 0.8, 0.09))

	for rk in rocks:
		if not vr.grow(rk.r + 6.0).has_point(rk.pos):
			continue
		if rk.eat_stage > 0:
			# Purple = edible wall. Dark when far from its stage, lighter as you approach it.
			var req := START_R * pow(STAGE_RATIO, rk.eat_stage - 1)
			var pg := clampf(p_r / req, 0.0, 1.0)
			var fill := Color(0.14, 0.06, 0.24).lerp(Color(0.55, 0.32, 0.82), pg)
			var edge := Color(0.4, 0.2, 0.6).lerp(Color(0.95, 0.82, 1.0), pg)
			var wid := 2.0
			if stage >= rk.eat_stage:
				wid = 3.5 + 1.5 * sin(t * 5.0)
				edge = Color(1.0, 0.9, 1.0)
			draw_circle(rk.pos, rk.r, fill)
			draw_arc(rk.pos, rk.r, 0.0, TAU, 24, edge, wid, true)
		else:
			draw_circle(rk.pos, rk.r, Color(0.07, 0.1, 0.15, 0.95))
			draw_arc(rk.pos, rk.r, 0.0, TAU, 24, Color(0.3, 0.42, 0.52, 0.55), 2.0, true)

	for v in vines:
		var shake := v.timer / 2.2
		draw_line(v.a, v.b, Color(0.55, 0.35, 0.22, 0.85), 30.0 + shake * 4.0, true)
		draw_line(v.a, v.b, Color(0.95, 0.7, 0.45, 0.5), 8.0, true)

	for d in drains:
		draw_drain(d[0], d[1])

	var view := Rect2(p_pos - Vector2(1920, 1080) * 0.5 / cam.zoom.x, Vector2(1920, 1080) / cam.zoom.x).grow(300.0)
	for c in currents:
		if view.intersects(c[4]):
			draw_current(c, view)
	for wk in wakes:
		if view.grow(wk[3]).has_point(wk[0]):
			draw_wake(wk)
	if vr.grow(home_r).has_point(home_pos):
		draw_home()
	for nu in nuclei:
		if vr.grow(nu[2]).has_point(nu[0]):
			draw_nucleus(nu)
	for w in whales:
		if w.st != "idle" and vr.grow(w.a * 1.2).has_point(w.pos):
			draw_whale_body(w)

	for th in things:
		if not vr.grow(th.r * 4.5 + 40.0).has_point(th.pos):
			continue
		if th.host >= 0 and th.host != in_whale:
			continue  # a whale's insides stay hidden until you are swallowed into it
		if th.host >= 0:
			dim = 0.45
			draw_thing(th)
			dim = 0.0
		else:
			draw_thing(th)
		if th.hit_t > 0.0:
			draw_circle(th.pos, th.r, Color(1, 1, 1, th.hit_t * 2.0))
		if th.max_hp > 0.0 and th.hp < th.max_hp:
			var bw := maxf(th.r * 1.6, 26.0 / cam.zoom.x)
			var bp := th.pos + Vector2(-bw * 0.5, -th.r * 1.25 - 10.0 / cam.zoom.x)
			var bh := 5.0 / cam.zoom.x
			draw_rect(Rect2(bp, Vector2(bw, bh)), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(bp, Vector2(bw * clampf(th.hp / th.max_hp, 0.0, 1.0), bh)), Color(1.0, 0.35, 0.3, 0.9))
		if th.stun > 0.0:
			for k in 3:
				var sa := t * 5.0 + TAU * k / 3.0
				draw_circle(th.pos + Vector2(cos(sa) * th.r * 0.8, -th.r * 1.1 + sin(sa) * th.r * 0.25), maxf(2.0, th.r * 0.12), Color(1.0, 0.95, 0.5, 0.9))
	if abilities_on:
		draw_abilities(vr)
	for i in whales.size():
		if whales[i].st != "idle" and vr.grow(whales[i].a * 1.2).has_point(whales[i].pos):
			draw_whale_overlay(whales[i])

	var pr := p_r
	# You glow faintly, lighting the dark water around you.
	draw_circle(p_pos, pr * 4.0, Color(0.35, 0.75, 1.0, 0.025))
	draw_circle(p_pos, pr * 2.2, Color(0.4, 0.85, 1.0, 0.035))
	draw_circle(p_pos, pr * 1.35, Color(0.7, 0.95, 1.0, 0.07))
	if dash_time > 0.0:
		draw_circle(p_pos - dash_dir * pr * 1.2, pr * 0.8, Color(0.8, 1.0, 1.0, 0.15))
	draw_circle(p_pos, pr, Color(0.75, 0.95, 1.0, 0.3))
	if health_on:
		draw_membrane(pr)
	else:
		draw_arc(p_pos, pr, 0.0, TAU, 48, Color(0.92, 1.0, 1.0, 0.95), maxf(3.0, pr * 0.06), true)
	# Subtle asymmetric organelles drifting inside, so you read as a living cell.
	for k in 5:
		var sd := float(k) * 1.7
		var c := p_pos + Vector2(sin(t * (0.23 + 0.05 * k) + sd * 3.0) * 0.5 + sin(t * 0.41 + sd) * 0.15, cos(t * (0.19 + 0.04 * k) + sd * 2.0) * 0.5 + cos(t * 0.37 + sd) * 0.15) * pr * 0.55
		var base := pr * (0.1 + 0.035 * (k % 3))
		var poly := PackedVector2Array()
		for j in 10:
			var aj := TAU * j / 10.0 + t * 0.15 * (1.0 if k % 2 == 0 else -1.0)
			var rj := base * (1.0 + 0.4 * sin(j * 2.1 + sd + t * 0.7) + 0.2 * sin(j * 3.7 + sd * 2.0))
			poly.append(Vector2(cos(aj) * 1.25, sin(aj)) * rj)
		var oc := Color(0.75, 0.95, 1.0, 0.055) if k % 2 == 0 else Color(1.0, 0.85, 0.6, 0.045)
		# Drawn relative to the organelle (big world coordinates made tiny shapes fail to triangulate).
		draw_set_transform(c, 0.0, Vector2.ONE)
		draw_colored_polygon(poly, oc)
		poly.append(poly[0])
		draw_polyline(poly, Color(oc, 0.07), 1.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Key items (keys, the golden pearl) float inside you, shrunk. Other cells never do.
	var n_in := inside.size()
	if n_in > 0:
		draw_circle(p_pos, pr * 0.85, Color(1.0, 0.9, 0.55, minf(0.03 + 0.025 * n_in, 0.14)))
	for i in n_in:
		var orbit := 0.0 if n_in == 1 else pr * 0.36
		var ang := t * 0.5 + TAU * i / maxf(n_in, 1.0)
		var off := Vector2.from_angle(ang) * orbit + Vector2(sin(t * 1.3 + i), cos(t * 1.1 + i)) * pr * 0.05
		dim = 0.75
		if inside[i][0] == "pearl":
			draw_pearl(p_pos + off, minf(inside[i][1] * 0.4, pr * 0.28), true, float(i))
		else:
			draw_key(p_pos + off, minf(inside[i][1], pr * 0.17), float(i))
		dim = 0.0
	# Murky belly tint over the swallowed items so they read as sitting inside you.
	if n_in > 0:
		draw_circle(p_pos, pr * 0.97, Color(0.45, 0.65, 0.65, 0.12))
	for k in ammo:
		var a2 := t * 1.8 + TAU * k / maxf(ammo, 1.0)
		var rad := pr + 12.0 + ammo * 1.2
		draw_circle(p_pos + Vector2.from_angle(a2) * rad, 3.5, Color(1.0, 0.75, 0.35, 0.9))

	if has_pearl() and state == "play" and p_pos.distance_to(home_pos) > home_r:
		var hd := (home_pos - p_pos).normalized()
		var tip := p_pos + hd * (p_r + 34.0 / cam.zoom.x)
		var w2 := 9.0 / cam.zoom.x
		var ga := 0.35 + 0.2 * sin(t * 3.0)
		draw_colored_polygon(PackedVector2Array([tip + hd * w2 * 1.6, tip + hd.orthogonal() * w2, tip - hd.orthogonal() * w2]), Color(1.0, 0.88, 0.5, ga))
	if fx_t < 2.0:
		var ring_r := p_r * 2.0 + fx_t * 700.0
		var alpha := 0.7 * (1.0 - fx_t / 2.0)
		draw_arc(p_pos, ring_r, 0.0, TAU, 96, Color(1.0, 0.95, 0.7, alpha), 5.0 / cam.zoom.x, true)

	for sp in sparks:
		var a3 := clampf(sp.life / sp.max_life, 0.0, 1.0)
		var ss := sp.size / cam.zoom.x
		draw_circle(sp.pos, ss * 2.4, Color(sp.col, a3 * 0.18))
		draw_circle(sp.pos, ss, Color(sp.col, a3))
		if sp.size > 2.6:
			draw_line(sp.pos - Vector2(ss * 2.2, 0), sp.pos + Vector2(ss * 2.2, 0), Color(1, 1, 0.9, a3 * 0.7), 1.0 / cam.zoom.x)
			draw_line(sp.pos - Vector2(0, ss * 2.2), sp.pos + Vector2(0, ss * 2.2), Color(1, 1, 0.9, a3 * 0.7), 1.0 / cam.zoom.x)

	var font := ThemeDB.fallback_font
	var fs := int(15.0 / cam.zoom.x)
	for v in vines:
		var mid := (v.a + v.b) * 0.5
		if mid.distance_to(p_pos) < 1400.0 / cam.zoom.x * 0.7:
			draw_string(font, mid + Vector2(40.0, 0.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.45))


func draw_home() -> void:
	# Your home base: a soft ring of light where you started. Brighter while you carry the pearl.
	var lit := 1.0 if has_pearl() else 0.45
	var pulse := 0.5 + 0.5 * sin(t * 1.6)
	draw_circle(home_pos, home_r, Color(0.45, 0.85, 1.0, 0.035 * lit))
	draw_circle(home_pos, home_r * 0.6, Color(0.6, 0.95, 1.0, 0.03 * lit))
	draw_arc(home_pos, home_r, 0.0, TAU, 96, Color(0.6, 0.95, 1.0, (0.25 + 0.2 * pulse) * lit), maxf(3.0, 3.0 / cam.zoom.x), true)
	for k in 12:
		var a := TAU * k / 12.0 + t * 0.15
		draw_circle(home_pos + Vector2.from_angle(a) * home_r, maxf(3.0, 4.0 / cam.zoom.x), Color(0.8, 1.0, 1.0, (0.3 + 0.4 * pulse) * lit))
	if has_pearl():
		draw_arc(home_pos, home_r * (1.05 + 0.08 * pulse), 0.0, TAU, 96, Color(1.0, 0.9, 0.55, 0.35 * (1.0 - pulse)), 2.0 / cam.zoom.x, true)


func draw_membrane(pr: float) -> void:
	# Health shown on the membrane ring: at full health it matches the normal ring; as you are
	# hurt it thins, dims, goes pink and cracks open in more and more places.
	var w := maxf(3.0, pr * 0.06)
	var f := clampf(hp / max_hp(stage), 0.0, 1.0)
	var flash := clampf(hurt_t / 0.35, 0.0, 1.0)
	var low := 1.0 - smoothstep(0.0, 0.4, f)
	var col := Color(0.92, 1.0, 1.0).lerp(Color(1.0, 0.45, 0.4), clampf(low * 0.85 + flash * 0.6, 0.0, 1.0))
	var alpha := clampf(lerpf(0.35, 0.95, f) + flash * 0.4 + low * 0.25 * sin(t * 9.0), 0.1, 1.0)
	var width := w * lerpf(0.35, 1.0, f) * (1.0 + flash * 0.5)
	var broken := (1.0 - f) * 0.75
	var n := 18
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var hv := fposmod(sin(i * 12.9898 + 4.1) * 43758.5453, 1.0)
		if hv < broken:
			# A crack: the segment breaks open with a jagged line running into the body.
			var am := (a0 + a1) * 0.5
			var seg := a1 - a0
			draw_arc(p_pos, pr, a0, a0 + seg * 0.3, 4, Color(col, alpha), width, true)
			draw_arc(p_pos, pr, a1 - seg * 0.3, a1, 4, Color(col, alpha), width, true)
			var depth := pr * (0.18 + 0.2 * hv / maxf(broken, 0.01))
			var pts := PackedVector2Array([
				p_pos + Vector2.from_angle(am - seg * 0.2) * pr,
				p_pos + Vector2.from_angle(am + seg * 0.15) * (pr - depth * 0.35),
				p_pos + Vector2.from_angle(am - seg * 0.1) * (pr - depth * 0.7),
				p_pos + Vector2.from_angle(am + seg * 0.08) * (pr - depth),
			])
			draw_polyline(pts, Color(col, alpha * 0.8), maxf(1.5, w * 0.5), true)
		else:
			draw_arc(p_pos, pr, a0, a1 + 0.004, 6, Color(col, alpha), width, true)


func current_point(c: Array, s: float) -> Array:
	# Position and direction at arc length s along a current.
	var pts: PackedVector2Array = c[0]
	var cum: PackedFloat32Array = c[1]
	var lo := 0
	var hi := cum.size() - 1
	while hi - lo > 1:
		var m := (lo + hi) / 2
		if cum[m] <= s:
			lo = m
		else:
			hi = m
	var seg := maxf(cum[hi] - cum[lo], 0.001)
	var d := (pts[hi] - pts[lo]) / seg
	return [pts[lo] + d * (s - cum[lo]), d]


func draw_current(c: Array, view: Rect2) -> void:
	var pts: PackedVector2Array = c[0]
	var cum: PackedFloat32Array = c[1]
	var wdt: float = c[2]
	var total: float = cum[cum.size() - 1]
	draw_polyline(pts, Color(0.35, 0.75, 0.95, 0.045), wdt * 2.0, true)
	draw_polyline(pts, Color(0.4, 0.85, 1.0, 0.05), wdt * 1.1, true)
	# Streaks racing along the stream in three lanes.
	var spacing := 110.0
	var n := int(total / spacing)
	var speed: float = c[3] * 0.55
	for k in n:
		for lane in 3:
			var s := fposmod(k * spacing + lane * 37.0 + t * speed * (0.85 + 0.15 * lane), total)
			var cp := current_point(c, s)
			var p: Vector2 = cp[0]
			if not view.has_point(p):
				continue
			var d: Vector2 = cp[1]
			var side := (float(lane) - 1.0) * wdt * 0.55 + sin(k * 1.7 + lane) * wdt * 0.12
			p += d.orthogonal() * side
			var a := 0.22 * (1.0 - absf(float(lane) - 1.0) * 0.4)
			draw_line(p - d * 26.0, p + d * 26.0, Color(0.75, 0.95, 1.0, a), 2.0, true)


func draw_wake(wk: Array) -> void:
	var fade: float = clampf(wk[1] / 5.0, 0.0, 1.0)
	var rad: float = wk[3]
	var spin: float = wk[2]
	var c: Vector2 = wk[0]
	draw_circle(c, rad * 0.9, Color(0.5, 0.8, 1.0, 0.025 * fade))
	for k in 5:
		var r0 := rad * (0.25 + 0.15 * k)
		var a0 := -t * spin * (2.2 - k * 0.3) + k * 1.3
		draw_arc(c, r0, a0, a0 + 1.6, 16, Color(0.7, 0.92, 1.0, 0.16 * fade), 2.5, true)


func whale_outline(w: Whale, scale: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 72
	for i in n:
		var th := TAU * i / n
		var c := cos(th)
		var s := sin(th)
		var px := 4.0 if c > 0.0 else 2.0
		pts.append(Vector2(w.a * signf(c) * pow(absf(c), 2.0 / px), w.b * s) * scale)
	return pts


func whale_shake(w: Whale) -> Vector2:
	if w.st == "spasm":
		return Vector2(sin(t * 60.0), cos(t * 53.0)) * 18.0
	if w.st == "hold" and w.tickle > 0.0:
		return Vector2(sin(t * 40.0), cos(t * 37.0)) * 10.0 * w.tickle
	return Vector2.ZERO


func mouth_poly(w: Whale) -> PackedVector2Array:
	var open := 1.0 if w.st == "swim" else 0.15
	open *= 1.0 + 0.05 * sin(t * 2.0 + w.phase) - w.gulp * 0.4
	var lip := w.b * 0.85 * open
	var lx := w.a * pow(maxf(1.0 - pow(lip / w.b, 2.0), 0.0), 0.25)
	return PackedVector2Array([
		Vector2(lx, -lip), Vector2(w.a * 1.01, -lip * 0.45), Vector2(w.a * 1.01, lip * 0.45),
		Vector2(lx, lip), Vector2(w.a * 0.38, lip * 0.18), Vector2(w.a * 0.38, -lip * 0.18)])


func draw_whale_body(w: Whale) -> void:
	# Bursaria-style bag: pale translucent body with a huge funnel mouth at the front.
	draw_set_transform(w.pos + whale_shake(w), 0.0, Vector2(w.dir, 1.0))
	draw_colored_polygon(whale_outline(w, 1.1), Color(0.6, 0.85, 1.0, 0.035))
	draw_colored_polygon(whale_outline(w, 1.0), Color(0.22, 0.32, 0.4, 0.42))
	var inside_me := in_whale >= 0 and whales[in_whale] == w
	if inside_me:
		# Belly cavity, slightly darker (only seen from inside).
		var bc := belly_center(w)
		var ax := belly_axes(w)
		var bel := PackedVector2Array()
		for i in 48:
			var an := TAU * i / 48.0
			bel.append(bc + Vector2(cos(an) * ax.x, sin(an) * ax.y))
		draw_colored_polygon(bel, Color(0.07, 0.12, 0.17, 0.55))
	else:
		# From outside the body is murky: you can't see in.
		draw_colored_polygon(whale_outline(w, 0.97), Color(0.16, 0.24, 0.3, 0.5))
	# Funnel mouth: dark throat fading out toward the lips.
	var mp := mouth_poly(w)
	draw_colored_polygon(mp, Color(0.01, 0.02, 0.04, 0.45))
	var inner := PackedVector2Array()
	for p in mp:
		inner.append(Vector2(lerpf(p.x, w.a * 0.38, 0.45), p.y * 0.5))
	draw_colored_polygon(inner, Color(0.0, 0.01, 0.02, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_whale_overlay(w: Whale) -> void:
	draw_set_transform(w.pos + whale_shake(w), 0.0, Vector2(w.dir, 1.0))
	var bc := belly_center(w)
	var ax := belly_axes(w)
	var inside_me := in_whale >= 0 and whales[in_whale] == w
	var excite := 1.0 + (w.tickle * 4.0 if w.st == "hold" else 0.0) + (6.0 if w.st == "spasm" else 0.0)
	# Murky tint over the swallowed things so they read as inside.
	var bel := PackedVector2Array()
	for k in 48:
		var an := TAU * k / 48.0
		bel.append(bc + Vector2(cos(an) * ax.x, sin(an) * ax.y))
	if inside_me:
		draw_colored_polygon(bel, Color(0.3, 0.45, 0.5, 0.1))
	# Wriggly tentacle lining around the belly wall (poke it to get blasted out). Only seen from inside.
	for k in (64 if inside_me else 0):
		var an := TAU * k / 64.0
		var base := bc + Vector2(cos(an) * ax.x, sin(an) * ax.y)
		var inward := (bc - base).normalized()
		var ln := w.b * (0.09 + 0.04 * sin(k * 2.3))
		var pl := PackedVector2Array()
		for j in 5:
			var f := j / 4.0
			var wig := sin(t * 3.0 * excite + k * 0.9 + f * 3.0) * ln * 0.35 * f
			pl.append(base + inward * ln * f + inward.orthogonal() * wig)
		draw_polyline(pl, Color(1.0, 0.7, 0.75, 0.32 + 0.1 * minf(excite, 3.0)), maxf(3.0, w.b * 0.012), true)
	# Curved ciliary band running from the mouth along the body.
	var band := PackedVector2Array()
	for k in 30:
		var f := k / 29.0
		band.append(Vector2(lerpf(w.a * 0.55, -w.a * 0.85, f), w.b * (0.82 - 0.25 * sin(f * PI))))
	draw_polyline(band, Color(0.75, 0.92, 1.0, 0.18), w.b * 0.05, true)
	# Membrane + cilia fringe.
	var outl := whale_outline(w, 1.0)
	var mp := mouth_poly(w)
	var lip := absf(mp[0].y)
	# The membrane is open where the mouth is (front, between the lips).
	var open := PackedVector2Array()
	for p in outl:
		if not (p.x > 0.0 and absf(p.y) < lip):
			open.append(p)
	# Points run front-bottom -> back -> front-top; stitch so the line doesn't cross the mouth.
	var start := 0
	for k in range(1, open.size()):
		if open[k].distance_to(open[k - 1]) > w.b * 0.3:
			start = k
	var mem := PackedVector2Array()
	for k in open.size():
		mem.append(open[(start + k) % open.size()])
	draw_polyline(mem, Color(0.82, 0.96, 1.0, 0.85), maxf(5.0, w.b * 0.016), true)
	for k in mem.size():
		var p := mem[k]
		var nrm := Vector2(p.x / (w.a * w.a), p.y / (w.b * w.b)).normalized()
		var sway := sin(t * 5.0 + k * 0.6) * 0.5
		draw_line(p, p + nrm.rotated(sway) * w.b * 0.07, Color(0.8, 0.95, 1.0, 0.35), 2.0, true)
	# Mouth lips.
	draw_polyline(PackedVector2Array([mp[0], mp[5], mp[4], mp[3]]), Color(0.9, 0.95, 1.0, 0.7), maxf(4.0, w.b * 0.012), true)
	# Hole on top. While the lining convulses it gapes open and a channel of water rushes up to it.
	var hole := whale_hole(w)
	var hr := w.b * 0.09
	if w.st == "spasm":
		hr = hole_half_width(w)
		var ch := PackedVector2Array([
			Vector2(hole.x - hr, hole.y), Vector2(hole.x + hr, hole.y),
			Vector2(hole.x + hr * 1.6, bc.y - ax.y * 0.6), Vector2(hole.x - hr * 1.6, bc.y - ax.y * 0.6)])
		draw_colored_polygon(ch, Color(0.6, 0.9, 1.0, 0.08))
	draw_circle(hole, hr, Color(0.01, 0.02, 0.04, 0.9))
	draw_arc(hole, hr, 0.0, TAU, 24, Color(0.85, 0.97, 1.0, 0.8), 4.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_drain(pos: Vector2, r: float) -> void:
	# Toxic murk: a sickly green-violet haze with slow churning blobs and a faint rim.
	if pos.distance_to(p_pos) > r + 2200.0 / cam.zoom.x:
		return
	draw_circle(pos, r, Color(0.35, 0.55, 0.15, 0.10))
	draw_circle(pos, r * 0.75, Color(0.45, 0.25, 0.5, 0.07))
	for k in 9:
		var sd := float(k) * 2.3
		var c := pos + Vector2(sin(t * 0.21 + sd), cos(t * 0.17 + sd * 1.3)) * r * 0.55
		draw_circle(c, r * (0.22 + 0.06 * sin(t * 0.9 + sd)), Color(0.55, 0.8, 0.25, 0.06))
	for k in 14:
		var ph := float(k) * 1.37
		var life := fposmod(t * 0.25 + ph * 0.31, 1.0)
		var bp := pos + Vector2.from_angle(ph * 2.9) * r * 0.85 * fposmod(ph * 0.53, 1.0) + Vector2(0.0, -life * 40.0)
		draw_arc(bp, 3.0 + 5.0 * life, 0.0, TAU, 10, Color(0.8, 1.0, 0.5, 0.35 * (1.0 - life)), 1.5, true)
	var n := 40
	for i in n:
		if i % 2 == 0:
			var a0 := TAU * i / n + t * 0.05
			draw_arc(pos, r, a0, a0 + TAU / n, 4, Color(0.7, 0.95, 0.35, 0.35), 3.0, true)


func arc_segs(r: float) -> int:
	# Fewer points for circles that are small on screen; they look the same.
	return clampi(int(r * cam.zoom.x * 0.6), 12, 48)


func rim_for(th: Thing) -> Color:
	if p_r > th.r * EAT:
		return Color(0.45, 0.8, 0.9, 0.85)
	if th.r > p_r * EAT:
		return Color(1.0, 0.5, 0.25, 0.95)
	return Color(0.85, 0.78, 0.5, 0.85)


func dc(c: Color) -> Color:
	# Dulls colors for things swallowed inside the belly: murky, desaturated, translucent.
	if dim <= 0.0:
		return c
	var m := c.lerp(Color(0.32, 0.42, 0.4), dim * 0.65)
	return Color(m.r, m.g, m.b, c.a * (1.0 - dim * 0.6))


func draw_pearl(pos: Vector2, r: float, ok: bool, ph: float) -> void:
	var rr := r * (1.0 + 0.04 * sin(t * 2.0 + ph))
	var gl := 1.0 if ok else 0.5
	for i in 6:
		draw_circle(pos, rr * (2.2 - i * 0.22), dc(Color(1.0, 0.8, 0.3, (0.02 + 0.012 * i) * gl)))
	# Body: stacked offset circles fake a lit sphere, dark amber edge to pale gold core.
	for i in 10:
		var f := i / 9.0
		var col := dc(Color(0.55, 0.32, 0.06)).lerp(dc(Color(1.0, 0.94, 0.62)), pow(f, 0.8))
		draw_circle(pos + Vector2(-0.28, -0.32) * rr * f, rr * (1.0 - f * 0.82), col)
	# Pearly iridescent rim.
	for k in 14:
		var ang := TAU * k / 14.0 + t * 0.3
		var c := Color.from_hsv(fposmod(0.08 + 0.45 * (0.5 + 0.5 * sin(ang * 2.0 + t * 1.4)), 1.0), 0.3, 1.0, 0.55)
		draw_arc(pos, rr, ang, ang + TAU / 14.0 + 0.03, 6, dc(c), maxf(1.5, rr * 0.07), true)
	draw_circle(pos + Vector2(-0.36, -0.4) * rr, rr * 0.17, dc(Color(1.0, 1.0, 0.95, 0.9)))
	draw_circle(pos + Vector2(-0.2, -0.5) * rr, rr * 0.07, dc(Color(1.0, 1.0, 1.0, 0.9)))
	var g := pow(maxf(0.0, sin(t * 1.3 + ph * 2.0)), 12.0)
	if g > 0.02 and dim == 0.0:
		var gp := pos + Vector2(0.45, -0.45) * rr
		var ln := rr * 0.7 * g
		draw_line(gp - Vector2(ln, 0), gp + Vector2(ln, 0), dc(Color(1, 1, 0.9, g)), 2.0 / cam.zoom.x, true)
		draw_line(gp - Vector2(0, ln), gp + Vector2(0, ln), dc(Color(1, 1, 0.9, g)), 2.0 / cam.zoom.x, true)
	if ok and dim == 0.0:
		draw_arc(pos, rr * (1.25 + 0.06 * sin(t * 4.0)), 0.0, TAU, 40, dc(Color(1.0, 0.95, 0.6, 0.5)), 2.0 / cam.zoom.x, true)


func draw_key(pos: Vector2, r: float, ph: float) -> void:
	# Vibrant but not "special-shiny": emerald core, cyan halo, orbiting motes.
	var kp := 1.0 + 0.15 * sin(t * 4.0 + ph)
	for i in 4:
		draw_circle(pos, r * (4.2 - i * 0.8) * kp, dc(Color(0.2, 1.0, 0.7, 0.025 + 0.02 * i)))
	draw_circle(pos, r * kp, dc(Color(0.35, 0.95, 0.65)))
	draw_circle(pos + Vector2(-0.2, -0.25) * r, r * 0.55 * kp, dc(Color(0.75, 1.0, 0.85)))
	draw_arc(pos, r * 1.5 * kp, t * 2.0 + ph, t * 2.0 + ph + PI * 1.2, 16, dc(Color(0.5, 1.0, 0.95, 0.7)), maxf(1.0, r * 0.18), true)
	draw_arc(pos, r * 2.0 * kp, -t * 1.5 + ph, -t * 1.5 + ph + PI * 0.8, 16, dc(Color(0.6, 1.0, 0.7, 0.45)), maxf(1.0, r * 0.14), true)
	for k in 3:
		var ao := t * 2.6 + ph + TAU * k / 3.0
		draw_circle(pos + Vector2.from_angle(ao) * r * 2.5, maxf(1.0, r * 0.2), dc(Color(0.8, 1.0, 0.9, 0.8)))


func ellipse_pts(a: float, b: float, n: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var an := TAU * i / n
		pts.append(Vector2(cos(an) * a, sin(an) * b))
	return pts


func draw_egg(th: Thing) -> void:
	var r := th.r * (1.0 + 0.04 * sin(t * 3.0 + th.phase))
	var hatch := 0.0
	if th.st == "hatch":
		# Waking up: shakes harder and harder, swells a little, cracks spread over the shell.
		hatch = 1.0 - clampf(th.tmr / maxf(egg_hatch_time, 0.01), 0.0, 1.0)
		r *= 1.0 + 0.12 * hatch
		var shake := Vector2(sin(t * 38.0 + th.phase), cos(t * 33.0 + th.phase)) * r * (0.05 + 0.18 * hatch)
		draw_set_transform(shake, 0.0, Vector2.ONE)
		draw_egg_body(th, r, hatch)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	draw_egg_body(th, r, 0.0)


func draw_egg_body(th: Thing, r: float, hatch: float) -> void:
	if r * cam.zoom.x < 10.0:
		# Small on screen: a cheaper egg with the same look from a distance.
		draw_circle(th.pos, r * 1.8, Color(0.85, 0.95, 1.0, 0.07))
		draw_circle(th.pos, r, Color(0.8, 0.87, 0.95))
		draw_circle(th.pos + Vector2(-0.25, -0.28) * r * 0.6, r * 0.55, Color(0.95, 0.97, 1.0))
		return
	for i in 3:
		draw_circle(th.pos, r * (2.6 - i * 0.5), Color(0.85, 0.95, 1.0, 0.03 + 0.02 * i))
	for i in 7:
		var f := i / 6.0
		draw_circle(th.pos + Vector2(-0.25, -0.28) * r * f, r * (1.0 - f * 0.7), Color(0.72, 0.8, 0.9).lerp(Color(1, 1, 1), f))
	draw_arc(th.pos, r, 0.0, TAU, mini(arc_segs(r), 28), Color(0.92, 0.98, 1.0, 0.9), maxf(1.5, r * 0.08), true)
	# Something small curled up inside, shifting (squirming once it wakes).
	var wsp := 1.0 + 9.0 * hatch
	var wob := Vector2(sin(t * 0.8 * wsp + th.phase), cos(t * 0.6 * wsp + th.phase)) * r * 0.22
	draw_circle(th.pos + wob, r * (0.24 + 0.12 * hatch), Color(0.45, 0.5, 0.62, 0.45 + 0.35 * hatch))
	draw_circle(th.pos + Vector2(-0.35, -0.4) * r, r * 0.14, Color(1, 1, 1, 0.85))
	if hatch > 0.0:
		# Cracks grow in from a few spots on the shell.
		for k in 4:
			var a := th.phase + k * 1.7
			var grow := clampf(hatch * 1.6 - k * 0.2, 0.0, 1.0)
			if grow <= 0.0:
				continue
			var p0 := th.pos + Vector2.from_angle(a) * r
			var p1 := th.pos + Vector2.from_angle(a + 0.25) * r * (1.0 - 0.35 * grow)
			var p2 := th.pos + Vector2.from_angle(a - 0.15) * r * (1.0 - 0.7 * grow)
			draw_polyline(PackedVector2Array([p0, p1, p2]), Color(0.3, 0.38, 0.5, 0.9), maxf(1.2, r * 0.07), true)


func pose_rot(th: Thing) -> float:
	# Creatures stay right side up: they flip left/right and only tilt a little up or down.
	var tilt := clampf(atan2(sin(th.face), absf(cos(th.face))), -0.35, 0.35)
	return tilt if th.flip >= 0.0 else -tilt


func pose_xf(th: Thing, l: Vector2) -> Vector2:
	# A point in the creature's own frame (+x = its nose) to the world.
	return th.pos + Vector2(l.x * th.flip, l.y).rotated(pose_rot(th))


func draw_shrimp(th: Thing) -> void:
	# Red while it's bigger than you (it hunts you), blue once you're big enough to eat it.
	var danger := th.r > p_r * EAT
	var hunting := th.st == "hunt" and danger
	var rim := Color(1.0, 0.5, 0.35, 0.95) if danger else rim_for(th)
	var fill := Color(0.9, 0.55, 0.5, 0.85) if danger else Color(0.6, 0.78, 0.8, 0.8)
	var r := th.r
	var sp := 18.0 if hunting else 8.0
	draw_set_transform(th.pos, pose_rot(th), Vector2(th.flip, 1.0))
	var a := r * 1.6
	var b := r * 0.62
	for k in 4:
		var lx := -a * 0.6 + k * a * 0.42
		var wig := sin(t * sp + th.phase + k * 1.3) * r * 0.35
		for sgn in [-1.0, 1.0]:
			draw_line(Vector2(lx, b * 0.6 * sgn), Vector2(lx + wig, (b + r * 0.75) * sgn), Color(rim, 0.8), maxf(1.2, r * 0.1), true)
	draw_colored_polygon(PackedVector2Array([Vector2(-a * 0.8, 0), Vector2(-a - r * 0.7, -r * 0.6), Vector2(-a - r * 0.5, 0), Vector2(-a - r * 0.7, r * 0.6)]), Color(fill, 0.8))
	var body := ellipse_pts(a, b)
	draw_colored_polygon(body, fill)
	body.append(body[0])
	draw_polyline(body, rim, maxf(1.5, r * 0.1), true)
	for k in 3:
		var sx := -a * 0.4 + k * a * 0.4
		draw_line(Vector2(sx, -b * 0.8), Vector2(sx, b * 0.8), Color(rim, 0.35), 1.0)
	draw_circle(Vector2(a * 0.7, -b * 0.35), r * 0.16, Color(0.05, 0.05, 0.1))
	for sgn in [-1.0, 1.0]:
		var aw := sin(t * 6.0 + th.phase) * r * 0.3
		draw_line(Vector2(a * 0.95, b * 0.3 * sgn), Vector2(a + r * 1.2, (b * 0.9 + aw) * sgn), Color(rim, 0.7), 1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_thing(th: Thing) -> void:
	# Tiny on screen (zoomed far out): one dot looks the same and is far cheaper to draw.
	if th.r * cam.zoom.x < 3.5 and th.kind != "pearl" and th.kind != "key":
		var dotc := Color(0.9, 0.97, 1.0, 0.8) if th.kind == "egg" else Color(rim_for(th), 0.7)
		var dr := th.r * (1.3 if th.kind == "krill" else 1.0)
		if dr * cam.zoom.x < 2.0:
			draw_rect(Rect2(th.pos - Vector2(dr, dr) * 0.85, Vector2(dr, dr) * 1.7), dc(dotc))
		else:
			draw_circle(th.pos, dr, dc(dotc))
		return
	if th.kind == "egg":
		draw_egg(th)
		return
	if th.kind == "meat":
		draw_meat(th)
		return
	if th.kind == "angler":
		draw_angler(th)
		return
	if th.kind == "shrimp":
		draw_shrimp(th)
		return
	if th.kind == "key":
		draw_key(th.pos, th.r, th.phase)
		return
	if th.kind == "pearl":
		draw_pearl(th.pos, th.r, true, th.phase)
		return
	var rim := rim_for(th)
	var fill := Color(0.04, 0.08, 0.14, 0.75)
	if th.kind == "food" and th.st == "scatter":
		# Bits of your own membrane: pale and glowing, dimmer until they can be picked up.
		var ga := 0.5 if th.tmr > 0.0 else 0.9
		draw_circle(th.pos, th.r * 2.2, Color(0.75, 0.95, 1.0, 0.08 * ga))
		draw_circle(th.pos, th.r, Color(0.8, 0.97, 1.0, 0.6 * ga))
		draw_arc(th.pos, th.r, 0.0, TAU, 12, Color(0.95, 1.0, 1.0, ga), 1.5, true)
		return
	if th.kind == "food":
		draw_circle(th.pos, th.r, Color(rim, 0.55))
		return
	if th.kind == "key":
		var kp := 1.0 + 0.2 * sin(t * 4.0 + th.phase)
		draw_circle(th.pos, th.r * 3.5 * kp, Color(0.3, 1.0, 0.55, 0.12))
		draw_circle(th.pos, th.r * kp, Color(0.55, 1.0, 0.7, 0.95))
		return
	var scl := Vector2(1.0, 1.0)
	var r := th.r
	var pos := th.pos
	if th.kind == "krill":
		scl = Vector2(1.7, 1.0)
	elif th.kind == "whale":
		scl = Vector2(1.3, 1.0)
		if th.st == "wind":
			r *= 1.0 + 0.06 * sin(t * 30.0)
			rim = Color(1.0, 0.3, 0.2, 1.0)
	elif th.kind == "larva" and th.st == "attached":
		var shake := vines[th.school].timer / 2.2
		pos += Vector2(sin(t * 45.0 + th.phase), cos(t * 41.0 + th.phase)) * shake * 3.0
		fill = Color(0.85, 0.58, 0.38, 0.95)
		rim = Color(1.0, 0.85, 0.65, 0.95)
	var small := r * cam.zoom.x < 10.0
	if not small:
		draw_circle(pos, r * 1.25, Color(rim, 0.06))
	if th.kind == "larva" and th.st == "attached":
		draw_set_transform(pos, th.face, scl)
	else:
		draw_set_transform(pos, pose_rot(th), Vector2(scl.x * th.flip, scl.y))
	draw_circle(Vector2.ZERO, r, fill)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, arc_segs(r), rim, maxf(2.5, r * 0.05), not small)
	if th.kind == "whale":
		draw_circle(Vector2(r * 0.7, 0.0), r * 0.42, Color(0.01, 0.02, 0.04, 0.9))
		draw_arc(Vector2(r * 0.7, 0.0), r * 0.42, -1.9, 1.9, 24, Color(rim, 0.9), 3.0, true)
		draw_circle(Vector2(-r * 0.3, r * 0.2), r * 0.18, Color(1.0, 0.65, 0.3, 0.6))
		draw_circle(Vector2(-r * 0.1, -r * 0.35), r * 0.12, Color(1.0, 0.65, 0.3, 0.5))
	elif th.kind == "mid":
		draw_circle(Vector2(r * 0.1, 0.0), r * 0.3, Color(1.0, 0.65, 0.3, 0.55))
	elif th.kind == "larva" and th.st == "swarm":
		draw_circle(Vector2(r * 0.1, 0.0), r * 0.35, Color(1.0, 0.65, 0.3, 0.65))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------- Gravity nuclei ----------------

func nucleus_gravity(pos: Vector2) -> Vector2:
	# Strongest at the surface, falling off with distance, gone at the edge of its reach.
	var acc := Vector2.ZERO
	for nu in nuclei:
		var d: Vector2 = nu[0] - pos
		var l := d.length()
		var reach: float = nu[2]
		if l > reach or l < 1.0:
			continue
		var core: float = nu[1]
		var g: float = nu[3] * pow(core / maxf(l, core), 1.3)
		g *= 1.0 - smoothstep(reach * 0.7, reach, l)
		acc += d / l * g
	return acc


func draw_nucleus(nu: Array) -> void:
	var pos: Vector2 = nu[0]
	var core: float = nu[1]
	var reach: float = nu[2]
	# The pull: faint rings sliding inward.
	draw_circle(pos, reach, Color(0.55, 0.42, 0.95, 0.025))
	for k in 5:
		var f := fposmod(k / 5.0 - t * 0.1, 1.0)
		draw_arc(pos, core + (reach - core) * f, 0.0, TAU, 72, Color(0.75, 0.6, 1.0, 0.45 * f * (1.0 - f)), 2.0, true)
	draw_circle(pos, core * 1.3, Color(0.7, 0.55, 1.0, 0.08))
	draw_circle(pos, core, Color(0.26, 0.17, 0.4, 0.95))
	# Chromatin swirling inside.
	for k in 7:
		var ang := t * (0.15 + 0.03 * k) + k * 0.9
		draw_arc(pos, core * (0.25 + 0.09 * k), ang, ang + 1.9, 18, Color(0.75, 0.55, 0.95, 0.3), maxf(2.0, core * 0.035), true)
	draw_circle(pos + Vector2(core * 0.22, -core * 0.15), core * 0.27, Color(0.55, 0.35, 0.78, 0.9))
	draw_circle(pos + Vector2(core * 0.15, -core * 0.22), core * 0.09, Color(0.85, 0.7, 1.0, 0.7))
	draw_arc(pos, core, 0.0, TAU, 72, Color(0.85, 0.75, 1.0, 0.8), maxf(3.0, core * 0.035), true)
	for k in 6:
		var oa := t * (0.6 - 0.05 * k) + k * 1.1
		draw_circle(pos + Vector2.from_angle(oa) * core * (1.25 + 0.12 * k), maxf(2.0, core * 0.03), Color(0.85, 0.75, 1.0, 0.5))


# ---------------- Abilities ----------------

func is_enemy(th: Thing) -> bool:
	return th.host < 0 and (th.kind == "mid" or th.kind == "shrimp" or th.kind == "larva" or th.kind == "whale" or th.kind == "angler")


func is_creature(th: Thing) -> bool:
	return is_enemy(th) or (th.kind == "krill" and th.host < 0)


func damage_thing(th: Thing, amount: float) -> void:
	if th.dead:
		return
	if th.max_hp <= 0.0:
		th.max_hp = 10.0 + th.r * 2.2
		th.hp = th.max_hp
	th.hp -= amount
	th.hit_t = maxf(th.hit_t, 0.15)
	# Medium and big creatures tear off meat chunks as they lose health; small ones don't.
	if th.r >= MEAT_MIN_R:
		th.chunk_acc += minf(amount, th.hp + amount)
		var n_total := chunk_count(th)
		var per := th.max_hp / n_total
		while th.chunk_acc >= per:
			th.chunk_acc -= per
			spawn_chunk(th, meat_value(th) / n_total)
	if th.hp <= 0.0:
		kill_thing(th)


func chunk_count(th: Thing) -> int:
	return clampi(int(th.r / 7.0), 3, 14)


func meat_value(th: Thing) -> float:
	# All the chunks of one creature together are worth about as much as eating a hunter.
	return clampf(th.r * 0.3, 4.0, 15.0)


func spawn_chunk(th: Thing, v: float) -> void:
	var m := Thing.new()
	m.kind = "meat"
	m.val = v * randf_range(0.6, 1.4)
	m.r = clampf(6.5 + m.val * 1.6, 6.5, 18.0)  # a bit bigger than your own fragments, more for more food
	var a := randf() * TAU
	m.pos = th.pos + Vector2.from_angle(a) * th.r * randf_range(0.3, 0.8)
	m.vel = Vector2.from_angle(a) * randf_range(60.0, 200.0)
	m.phase = randf() * TAU
	pending.append(m)
	for i in 6:
		add_spark(m.pos, Vector2.from_angle(a + randf_range(-0.6, 0.6)) * randf_range(60.0, 200.0), randf_range(0.3, 0.6), randf_range(1.5, 2.5), Color(1.0, 0.5, 0.4))


func kill_thing(th: Thing) -> void:
	# Chunks already tore off as it was hurt; the rest is a burst.
	th.dead = true
	for i in 30:
		var a2 := randf() * TAU
		add_spark(th.pos, Vector2.from_angle(a2) * randf_range(80.0, 320.0), randf_range(0.4, 0.9), randf_range(1.5, 3.0), Color(1.0, 0.55, 0.35).lerp(Color(1.0, 0.85, 0.5), randf()))
	play_note(146.83)
	play_note(220.0)


func ability_input(delta: float) -> void:
	for i in ab_cd.size():
		ab_cd[i] = maxf(ab_cd[i] - delta, 0.0)
	var q := Input.is_key_pressed(KEY_Q) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER)
	var e := Input.is_key_pressed(KEY_E) or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER)
	var f := Input.is_key_pressed(KEY_F) or Input.is_joy_button_pressed(0, JOY_BUTTON_X) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if (ab_enabled & 31) == 0:
		return
	if q and not ab_q_prev:
		ab_sel = next_ability(-1)
	if e and not ab_e_prev:
		ab_sel = next_ability(1)
	if (ab_enabled & (1 << ab_sel)) == 0:
		ab_sel = next_ability(1)
	if ab_test >= 0:
		ab_sel = ab_test
		f = ab_cd[ab_sel] <= 0.0 and not ab_f_prev
	if f and not ab_f_prev and ab_cd[ab_sel] <= 0.0 and in_whale < 0:
		if ammo >= AB_COST[ab_sel]:
			ammo -= AB_COST[ab_sel]
			fire_ability(ab_sel)
		else:
			play_note(110.0)  # not enough ammo: a dull thud
			banner.text = "NEED %d AMMO  (eat to get more)" % AB_COST[ab_sel]
			banner_t = 1.2
	ab_q_prev = q
	ab_e_prev = e
	ab_f_prev = f


func next_ability(step: int) -> int:
	var i := ab_sel
	for k in AB_NAMES.size():
		i = posmod(i + step, AB_NAMES.size())
		if (ab_enabled & (1 << i)) != 0:
			return i
	return ab_sel


func fire_ability(i: int) -> void:
	match i:
		0:  # Rocket: an afterburner. Starts slow, kicks in hard a quarter of the way through.
			rocket_t = rocket_len
			rocket_dir = aim_dir
			rocket_base = aim_dir
			drop_pearl(aim_dir)
			play_note(98.0)
			play_note(146.83)
		1:  # Harpoon: hook (drags things in) until harpoon_up_stage, then a damaging spike.
			if not hook.is_empty():
				return
			hook = {"pos": p_pos + aim_dir * p_r, "vel": aim_dir * 1600.0, "dist": 0.0, "st": "fly",
				"spike": stage >= harpoon_up_stage, "target": null, "t": 0.0, "range": 950.0 + p_r * 3.0}
			play_note(329.63)
		2:  # Ink: a black cloud. Enemies flee it and lose you while you're inside.
			inks.append([p_pos, 6.0, 260.0 + p_r * 2.5])
			for k in 24:
				var a := randf() * TAU
				add_spark(p_pos, Vector2.from_angle(a) * randf_range(40.0, 200.0), randf_range(0.5, 1.0), randf_range(2.5, 4.5), Color(0.1, 0.1, 0.18))
			play_note(73.42)
		3:  # Leech mine: left behind you; latches onto the first enemy that touches it.
			leeches.append({"pos": p_pos - aim_dir * (p_r + 12.0), "life": 15.0, "host": null, "off": Vector2.ZERO})
			if leeches.size() > 6:
				leeches.pop_front()
			play_note(196.0)
		4:  # Flash: stuns every creature around you.
			flash_t = 0.7
			var rad := 750.0 + p_r * 3.0
			for th in things:
				if is_creature(th) and not th.dead and th.pos.distance_to(p_pos) < rad:
					th.stun = maxf(th.stun, 2.8)
			for k in 40:
				var a := randf() * TAU
				add_spark(p_pos, Vector2.from_angle(a) * randf_range(300.0, 900.0), randf_range(0.3, 0.6), randf_range(2.0, 3.5), Color(1.0, 1.0, 0.85))
			play_note(783.99)
			play_note(1046.5)
	ab_cd[i] = AB_COOLDOWN[i]


func spike_damage() -> float:
	return 25.0 + 5.0 * stage


func ink_flee(pos: Vector2) -> Vector2:
	for ik in inks:
		var d: Vector2 = pos - ik[0]
		var reach: float = ik[2] * 1.5
		if d.length() < reach:
			return (d.normalized() if d.length() > 0.01 else Vector2.RIGHT) * 280.0 * SPEED
	return Vector2.ZERO


func update_abilities(delta: float) -> void:
	# Ink clouds.
	p_hidden = false
	for ik in inks:
		ik[1] -= delta
		if p_pos.distance_to(ik[0]) < ik[2] * 0.85:
			p_hidden = true
	inks = inks.filter(func(x: Array) -> bool: return x[1] > 0.0)
	# Leech mines.
	for lc in leeches:
		lc["life"] -= delta
		var host = lc["host"]
		if host == null:
			for th in things:
				if not th.dead and is_enemy(th) and th.pos.distance_to(lc["pos"]) < th.r + 10.0:
					lc["host"] = th
					lc["off"] = (lc["pos"] - th.pos).limit_length(th.r * 0.85)
					lc["life"] = 5.0
					play_note(164.81)
					break
		elif host.dead:
			lc["life"] = 0.0
		else:
			lc["pos"] = host.pos + lc["off"]
			damage_thing(host, LEECH_DPS * delta)
	leeches = leeches.filter(func(x: Dictionary) -> bool: return x["life"] > 0.0)
	update_hook(delta)


func update_hook(delta: float) -> void:
	if hook.is_empty():
		return
	var hp: Vector2 = hook["pos"]
	match hook["st"]:
		"fly":
			var stp: Vector2 = hook["vel"] * delta
			hook["pos"] = hp + stp
			hook["dist"] += stp.length()
			for th in things:
				if th.dead or th.host >= 0 or th.kind == "pearl" or th.kind == "key":
					continue
				if hook["spike"] and not is_creature(th):
					continue
				if th.pos.distance_to(hook["pos"]) < th.r + 8.0:
					if hook["spike"]:
						damage_thing(th, spike_damage())
						th.vel += (hook["vel"] as Vector2).normalized() * 320.0
						th.stun = maxf(th.stun, 0.4)
						hook["st"] = "back"
						play_note(207.65)
					else:
						hook["st"] = "reel"
						hook["target"] = th
						hook["t"] = 0.0
						play_note(261.63)
					return
			var solid := false
			for rk in rocks:
				if (hook["pos"] as Vector2).distance_to(rk.pos) < rk.r:
					solid = true
			for nu in nuclei:
				if (hook["pos"] as Vector2).distance_to(nu[0]) < nu[1]:
					solid = true
			if solid:
				# The hook bites into rock: it hauls you over to it. The spike just bounces off.
				hook["st"] = "back" if hook["spike"] else "anchor"
				hook["t"] = 0.0
			elif hook["dist"] > hook["range"]:
				hook["st"] = "back"
		"reel":
			var th: Thing = hook["target"]
			hook["t"] += delta
			if th.dead or hook["t"] > 3.0:
				hook["st"] = "back"
				return
			var d := p_pos - th.pos
			var l := maxf(d.length(), 0.01)
			if th.r > p_r * 1.6:
				jet = -d / l * 900.0  # too heavy to drag: it hauls you in instead
			else:
				th.pos += d / l * minf(900.0 * delta, maxf(l - p_r - th.r, 0.0))
				if is_creature(th):
					th.stun = maxf(th.stun, 0.8)
			hook["pos"] = th.pos
			if l < p_r + th.r + 6.0:
				hook = {}
		"anchor":
			var d2: Vector2 = hook["pos"] - p_pos
			hook["t"] += delta
			jet = d2.normalized() * 950.0
			if d2.length() < p_r + 40.0 or hook["t"] > 2.5:
				hook = {}
		"back":
			var d3 := p_pos - hp
			if d3.length() < p_r + 10.0:
				hook = {}
			else:
				hook["pos"] = hp + d3.normalized() * minf(2600.0 * delta, d3.length())


func draw_abilities(vr: Rect2) -> void:
	for ik in inks:
		var fade := clampf(ik[1] / 1.5, 0.0, 1.0)
		var grow := 1.0 - 0.3 * clampf(ik[1] - 5.0, 0.0, 1.0)
		var r: float = ik[2] * grow
		var c: Vector2 = ik[0]
		if not vr.grow(r).has_point(c):
			continue
		for k in 9:
			var sd := float(k) * 2.1
			var bc := c + Vector2(sin(t * 0.4 + sd), cos(t * 0.33 + sd * 1.3)) * r * 0.45
			draw_circle(bc, r * (0.42 + 0.08 * sin(t + sd)), Color(0.03, 0.03, 0.07, 0.32 * fade))
		draw_circle(c, r * 0.6, Color(0.02, 0.02, 0.05, 0.5 * fade))
	for lc in leeches:
		var lp: Vector2 = lc["pos"]
		var on: bool = lc["host"] != null
		var lr := 7.0 + (1.5 * sin(t * 8.0) if on else 0.0)
		draw_circle(lp, lr * 1.8, Color(0.8, 0.2, 0.35, 0.12))
		draw_circle(lp, lr, Color(0.55, 0.12, 0.25, 0.95))
		for k in 5:
			var a := TAU * k / 5.0 + t * (3.0 if on else 0.8)
			draw_line(lp, lp + Vector2.from_angle(a) * lr * 1.7, Color(0.9, 0.35, 0.45, 0.8), 1.5, true)
		draw_circle(lp, lr * 0.35, Color(1.0, 0.6, 0.6, 0.9))
	if not hook.is_empty():
		var hp: Vector2 = hook["pos"]
		var spike: bool = hook["spike"]
		var rope := Color(0.9, 0.95, 1.0, 0.7) if not spike else Color(1.0, 0.8, 0.6, 0.5)
		draw_line(p_pos, hp, rope, maxf(2.0, 2.0 / cam.zoom.x), true)
		var hd := (hp - p_pos).normalized()
		if hd == Vector2.ZERO:
			hd = aim_dir
		var sz := 14.0 + p_r * 0.15
		if spike:
			draw_colored_polygon(PackedVector2Array([hp + hd * sz * 1.4, hp + hd.orthogonal() * sz * 0.35, hp - hd.orthogonal() * sz * 0.35]), Color(1.0, 0.85, 0.65))
		else:
			draw_line(hp, hp + hd * sz, Color(0.95, 1.0, 1.0), 3.0, true)
			for sgn in [-1.0, 1.0]:
				draw_line(hp + hd * sz, hp + hd * sz * 0.3 + hd.orthogonal() * sz * 0.6 * sgn, Color(0.95, 1.0, 1.0), 3.0, true)


func draw_meat(th: Thing) -> void:
	# A globby chunk of a killed creature: a lumpy, wobbling blob with darker clots inside.
	var r := th.r
	draw_set_transform(th.pos, th.phase, Vector2.ONE)
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		var rr := r * (1.0 + 0.22 * sin(a * 3.0 + th.phase * 5.0) + 0.12 * sin(a * 5.0 + t * 2.2 + th.phase) + 0.05 * sin(t * 3.0 + i))
		pts.append(Vector2.from_angle(a) * rr)
	draw_circle(Vector2.ZERO, r * 1.7, Color(1.0, 0.45, 0.35, 0.05))
	draw_colored_polygon(pts, Color(0.62, 0.2, 0.22, 0.9))
	for k in 3:
		var c := Vector2.from_angle(th.phase * 3.0 + k * 2.1) * r * 0.4
		draw_circle(c, r * (0.32 - 0.06 * k), Color(0.4, 0.1, 0.14, 0.8))
	draw_circle(Vector2(-0.25, -0.3) * r, r * 0.3, Color(1.0, 0.6, 0.55, 0.45))
	draw_circle(Vector2(-0.35, -0.4) * r, r * 0.1, Color(1.0, 0.9, 0.85, 0.7))
	pts.append(pts[0])
	draw_polyline(pts, Color(1.0, 0.55, 0.5, 0.75), maxf(1.2, r * 0.1), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------- Angler fish ----------------
# Lurks in the dark, nearly invisible, dangling a fake golden pearl in front of its jaws.
# Swim up to the "pearl" and it lunges.

func lure_pos(th: Thing) -> Vector2:
	return pose_xf(th, Vector2(th.r * 1.9, sin(t * 1.3 + th.phase) * th.r * 0.12))


func take_lure(th: Thing) -> void:
	# You pluck the ball off the lure. Only one angler carries the real golden pearl.
	var lp := lure_pos(th)
	if th.pearl == 1:
		th.pearl = -1
		var pe := Thing.new()
		pe.kind = "pearl"
		pe.st = "goal"
		pe.r = th.pearl_r
		pe.pos = lp
		eat_pearl(pe)
		return
	# A decoy: it bursts into dull mush, and the angler snaps awake.
	th.pearl = -1
	food += 1.0
	for i in 26:
		var a := randf() * TAU
		add_spark(lp, Vector2.from_angle(a) * randf_range(60.0, 240.0), randf_range(0.4, 0.9), randf_range(1.5, 3.0), Color(0.75, 0.6, 0.35).lerp(Color(0.4, 0.35, 0.3), randf()))
	play_note(155.56)
	play_note(146.83)
	banner.text = "A FAKE"
	banner_t = 1.4
	th.stun = 0.0
	angler_lunge(th, p_pos - th.pos)


func angler_lunge(th: Thing, to: Vector2) -> void:
	th.st = "lunge"
	th.tmr = 0.45
	th.dir = to.normalized() if to.length() > 0.01 else Vector2.from_angle(th.face)
	play_note(65.41)
	play_note(69.3)


func update_angler(th: Thing, delta: float) -> void:
	var to := p_pos - th.pos
	match th.st:
		"lurk":
			th.vel = th.vel.lerp(Vector2.from_angle(t * 0.1 + th.phase) * 4.0, 1.0 - exp(-1.0 * delta))
			if to.length() < th.r * 7.0 and not p_hidden:
				th.face = lerp_angle(th.face, to.angle(), 1.0 - exp(-0.7 * delta))
			if not p_hidden and p_pos.distance_to(lure_pos(th)) < p_r + maxf(th.r * 1.1, 80.0):
				angler_lunge(th, to)
		"lunge":
			# Big anglers lunge farther: the strike covers about 1.6 body widths.
			th.vel = th.dir * maxf(1150.0, th.r * 7.0)
			th.face = th.dir.angle()
			th.tmr -= delta
			if th.tmr <= 0.0:
				th.st = "rest"
				th.tmr = 2.5
		"rest":
			th.vel = th.vel.lerp(Vector2.ZERO, 1.0 - exp(-3.0 * delta))
			th.tmr -= delta
			if th.tmr <= 0.0:
				th.st = "lurk"


func draw_angler(th: Thing) -> void:
	var r := th.r
	var reveal := 1.0 - smoothstep(r * 1.6, r * 5.5, th.pos.distance_to(p_pos))
	if th.st == "lunge":
		reveal = 1.0
	var open := 0.25 + (0.75 if th.st == "lunge" else 0.15 * sin(t * 0.8 + th.phase) + 0.1)
	draw_set_transform(th.pos, pose_rot(th), Vector2(th.flip, 1.0))
	var body_a := 0.12 + 0.75 * reveal
	# Tail fin.
	draw_colored_polygon(PackedVector2Array([Vector2(-r * 1.0, 0.0), Vector2(-r * 1.75, -r * 0.6 + sin(t * 2.0) * r * 0.1), Vector2(-r * 1.55, 0.0), Vector2(-r * 1.75, r * 0.6 + sin(t * 2.0) * r * 0.1)]), Color(0.05, 0.06, 0.09, body_a))
	# Body.
	var body := ellipse_pts(r * 1.25, r * 0.95, 28)
	draw_colored_polygon(body, Color(0.05, 0.06, 0.09, body_a))
	body.append(body[0])
	draw_polyline(body, Color(0.25, 0.3, 0.38, 0.1 + 0.5 * reveal), maxf(2.0, r * 0.03), true)
	# Gaping jaws lined with needle teeth.
	var jaw := r * 0.75 * open
	draw_colored_polygon(PackedVector2Array([Vector2(r * 1.3, -jaw), Vector2(r * 0.3, -jaw * 0.25), Vector2(r * 0.3, jaw * 0.25), Vector2(r * 1.3, jaw)]), Color(0.0, 0.0, 0.01, 0.2 + 0.75 * reveal))
	for k in 6:
		var x := lerpf(r * 0.45, r * 1.25, k / 5.0)
		var yt := lerpf(jaw * 0.3, jaw, k / 5.0)
		var tl := r * (0.16 + 0.06 * (k % 2))
		var tc := Color(0.9, 0.92, 0.85, 0.05 + 0.85 * reveal)
		draw_colored_polygon(PackedVector2Array([Vector2(x - r * 0.05, -yt), Vector2(x + r * 0.05, -yt), Vector2(x, -yt + tl)]), tc)
		draw_colored_polygon(PackedVector2Array([Vector2(x - r * 0.05, yt), Vector2(x + r * 0.05, yt), Vector2(x, yt - tl)]), tc)
	# Small pale eye.
	draw_circle(Vector2(r * 0.55, -r * 0.45), r * 0.09, Color(0.75, 0.8, 0.7, 0.1 + 0.6 * reveal))
	# The stalk (illicium) arching over the head to the lure.
	var lure_l := Vector2(r * 1.9, sin(t * 1.3 + th.phase) * r * 0.12)
	var stalk := PackedVector2Array()
	for k in 9:
		var f := k / 8.0
		var p0 := Vector2(r * 0.4, -r * 0.85)
		stalk.append(p0.lerp(lure_l, f) + Vector2(0.0, -sin(f * PI) * r * 0.55))
	draw_polyline(stalk, Color(0.35, 0.38, 0.42, 0.18 + 0.6 * reveal), maxf(1.5, r * 0.035), true)
	if th.pearl < 0:
		draw_circle(lure_l, maxf(3.0, r * 0.03), Color(0.4, 0.42, 0.45, 0.2 + 0.5 * reveal))  # empty lure tip
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var lp := lure_pos(th)
	if th.pearl == 1:
		draw_pearl(lp, th.pearl_r, true, th.phase)
	elif th.pearl == 0:
		draw_decoy(lp, th.pearl_r, th.phase)


func draw_decoy(pos: Vector2, r: float, ph: float) -> void:
	# Almost the golden pearl, but not quite: a touch more orange, a flat steady sheen
	# where the real one shimmers, and it pulses in time with the angler's breathing.
	var rr := r * (1.0 + 0.07 * sin(t * 0.8 + ph))
	for i in 6:
		draw_circle(pos, rr * (2.2 - i * 0.22), Color(1.0, 0.72, 0.28, 0.02 + 0.012 * i))
	for i in 10:
		var f := i / 9.0
		var col := Color(0.55, 0.28, 0.05).lerp(Color(1.0, 0.9, 0.58), pow(f, 0.8))
		draw_circle(pos + Vector2(-0.28, -0.32) * rr * f, rr * (1.0 - f * 0.82), col)
	draw_arc(pos, rr, 0.0, TAU, 40, Color(1.0, 0.85, 0.55, 0.45), maxf(1.5, rr * 0.07), true)
	draw_circle(pos + Vector2(-0.36, -0.4) * rr, rr * 0.17, Color(1.0, 1.0, 0.92, 0.85))
	draw_circle(pos + Vector2(-0.2, -0.5) * rr, rr * 0.07, Color(1.0, 1.0, 1.0, 0.85))
	draw_arc(pos, rr * 1.25, 0.0, TAU, 40, Color(1.0, 0.92, 0.6, 0.4), 2.0 / cam.zoom.x, true)
