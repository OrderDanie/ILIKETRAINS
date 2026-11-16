extends Node3D
## LAST TRAIN - root: state machine, input routing, interactions, events, objectives, saving.

const MENU := 0
const PLAY := 1
const DEAD := 2

var state := MENU
var playing := false
var world: WorldRig
var train: TrainRig
var player: PlayerRig
var ui: GameUI
var sfx: Sfx
var crew_nodes: Array = []
var aboard := true
var at_stop := -1
var last_arrived := -999
var rolled_for := -999
var hailed_for := -999
var was_captured := false
var menu_cam: Camera3D
var menu_t := 0.0
var autosave_t := 90.0
var look_area: Area3D = null
var prompt := ""
var obj_t := 0.0
var alarm_t := 0.0
var horn_cd := 0.0
var fire_cd := 0.0
var talk_cd := 0.0
var booted := false
var boot_layer: CanvasLayer
var boot_lbl: Label
var auto_quality := false
var perf_t := 0.0
var perf_n := 0
var frame_n := 0
var last_dt := 0.0
var real_dt := 0.0
var tracers: Array = []
var impacts: Array = []
var tracer_i := 0
var impact_i := 0
var script_ms := 0.0
var real_avg := 0.1
var last_ms := 0
var auto_stage := 0
var test_mode := false
var had_settings := false
var look_block := 0.0
var test_steps := 1

func _stage(text: String) -> void:
	boot_lbl.text = text
	if test_mode:
		print("[boot] ", Time.get_ticks_msec(), " ms  ", text)
	await get_tree().process_frame
	await get_tree().process_frame

func _ready() -> void:
	randomize()
	had_settings = FileAccess.file_exists("user://last_train_settings.json")
	GS.load_settings()
	GS.apply_keys()
	Kit.init_materials()
	sfx = Sfx.new()
	add_child(sfx)
	_boot()

## Tears the running world down and builds it again in place (new game, load, quit to menu).
## Old nodes are freed first so two worlds never exist at once.
func restart(mode: String, slot: int = 0) -> void:
	if not booted:
		return
	booted = false
	playing = false
	state = MENU
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GS.boot = mode
	GS.boot_slot = slot
	for n: Node in [ui, player, world, train, menu_cam]:
		if is_instance_valid(n):
			n.queue_free()
	crew_nodes = []
	look_area = null
	await get_tree().process_frame
	await get_tree().process_frame
	_boot()

func _boot() -> void:
	boot_layer = CanvasLayer.new()
	boot_layer.layer = 50
	add_child(boot_layer)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.065, 0.075)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boot_layer.add_child(bg)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boot_layer.add_child(cc)
	var bv := VBoxContainer.new()
	cc.add_child(bv)
	var bt := Label.new()
	bt.text = "LAST TRAIN"
	bt.add_theme_font_override("font", Kit.get_font())
	bt.add_theme_font_size_override("font_size", 54)
	bt.add_theme_color_override("font_color", Color(0.93, 0.9, 0.84))
	bt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(bt)
	boot_lbl = Label.new()
	boot_lbl.add_theme_font_override("font", Kit.get_font())
	boot_lbl.add_theme_font_size_override("font_size", 15)
	boot_lbl.add_theme_color_override("font_color", Color(0.86, 0.65, 0.26))
	boot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(boot_lbl)
	await _stage("Loading surface materials")
	var boot: String = GS.boot
	GS.boot = ""
	var load_failed := false
	if boot == "load":
		if not GS.load_slot(GS.boot_slot):
			GS.reset_new()
			load_failed = true
			boot = ""
	else:
		GS.reset_new()
	await _stage("Assembling locomotive and carriages")
	train = TrainRig.new()
	train.main = self
	add_child(train)
	train.build()
	await _stage("Laying the Northern Line")
	world = WorldRig.new()
	world.main = self
	add_child(world)
	world.build()
	_build_fx()
	await _stage("Waking the crew")
	player = PlayerRig.new()
	player.main = self
	add_child(player)
	player.global_position = Vector3(-0.15, TrainRig.FY + 0.05, TrainRig.car_z(0) + 14.4)
	player.arsenal.main = self
	player.arsenal.equip_now(GS.cur_weapon)
	ui = GameUI.new()
	ui.main = self
	add_child(ui)
	ui.build()
	menu_cam = Camera3D.new()
	menu_cam.fov = 52.0
	menu_cam.far = 900.0
	add_child(menu_cam)
	sync_crew()
	apply_settings()
	await _stage("Building Nordhaven Station")
	world.update(0.016, player.global_position)
	auto_quality = not had_settings and not GS.calibrated
	if OS.has_feature("web"):
		var qs: Variant = JavaScriptBridge.eval("window.location.search", true)
		# the automation hook answers only on the developer's own loopback address;
		# on any deployed host it is inert, whatever the query string says
		var host: Variant = JavaScriptBridge.eval("window.location.hostname", true)
		var dev_host: bool = typeof(host) == TYPE_STRING and str(host) == "127.0.0.1"
		if typeof(qs) == TYPE_STRING:
			test_mode = dev_host and str(qs).contains("test=1")
			if test_mode:
				Engine.max_fps = 12
			if str(qs).contains("gfx=low"):
				auto_quality = false
				GS.settings["preset"] = 0
				GS.settings["scale"] = 0.5
	if auto_quality:
		GS.settings["preset"] = 0
		GS.settings["scale"] = 0.5
	apply_settings()
	booted = true
	if boot == "new" or boot == "load":
		begin_play(boot == "new")
	else:
		state = MENU
		GS.train["headlights"] = true
		menu_cam.current = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		ui.show_menu()
		if load_failed:
			ui.open("load", 0)
			ui.notice = "That save could not be read - it is missing or corrupted. Your other saves are untouched."
			ui.refresh()
	await _stage("")
	boot_layer.queue_free()

func sync_crew() -> void:
	for n: Node in crew_nodes:
		n.queue_free()
	crew_nodes = []
	for i in GS.crew.size():
		var a := CrewAgent.new()
		train.add_child(a)
		a.setup(self, GS.crew[i], i)
		crew_nodes.append(a)

func begin_play(fresh: bool) -> void:
	state = PLAY
	menu_cam.current = false
	player.cam.current = true
	ui.show_hud()
	if GS.ppos.size() == 4:
		player.global_position = Vector3(float(GS.ppos[0]), float(GS.ppos[1]) + 0.05, float(GS.ppos[2]))
		player.yaw = float(GS.ppos[3])
	else:
		player.global_position = Vector3(-0.15, TrainRig.FY + 0.05, TrainRig.car_z(0) + 14.4)
		player.yaw = 0.0
	var s: float = GS.train["s"]
	last_arrived = int(round(s / GS.SP)) if absf(s - round(s / GS.SP) * GS.SP) < 30.0 else -999
	rolled_for = int(floor(s / GS.SP))
	hailed_for = rolled_for
	capture()
	sfx.unlock()
	var k0: int = int(round(s / GS.SP))
	if fresh or absf(s - float(k0) * GS.SP) < 30.0:
		var L0: Dictionary = GS.loc_at(k0)
		ui.title_card(str(L0["name"]), "Day %d   -   %s" % [GS.day(), GS.clock()])
	ui.fade_pulse("")
	if fresh:
		GS.radio("...any station, any station. Nordhaven is lost. If you still have a locomotive, run it south. Do not stop for long.")
		GS.say("Nordhaven Station. The last train is yours.")
		var mkeys: Dictionary = GS.settings["keys"]
		GS.say("Press %s for the field manual: every system on the train, drawn and explained." % OS.get_keycode_string(int(mkeys["manual"])))

# ---------- menu actions ----------
func menu_default() -> void:
	if ui.is_open():
		return
	if GS.latest_slot() >= 0:
		continue_game()
	else:
		start_new()

func start_new() -> void:
	if state == MENU:
		GS.reset_new()
		sync_crew()
		begin_play(true)
	else:
		restart("new")

func continue_game() -> void:
	var n: int = GS.latest_slot()
	if n < 0:
		start_new()
	else:
		load_slot(n)

func load_slot(n: int) -> void:
	var info: Dictionary = GS.slot_info(n)
	if not info["ok"]:
		ui.notice = "That save cannot be loaded."
		ui.refresh()
		return
	restart("load", n)

func save_game(n: int) -> bool:
	var p: Vector3 = player.global_position
	GS.ppos = [p.x, p.y, p.z, player.yaw]
	GS.slot = n
	return GS.save_slot(n)

func quit_to_menu() -> void:
	if state == PLAY:
		save_game(0)
	restart("")

func capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	look_block = 0.35

func on_ui_open() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	was_captured = false

func on_ui_close() -> void:
	if state == PLAY:
		capture()

func ui_blocking() -> bool:
	return ui.is_open()

func apply_settings() -> void:
	var st: Dictionary = GS.settings
	get_viewport().scaling_3d_scale = clampf(float(st["scale"]), 0.25 if test_mode else 0.5, 1.0)
	sfx.set_master(float(st["volume"]))
	world.apply_preset(int(st["preset"]))
	train.apply_preset(int(st["preset"]))
	# Low preset drops normal mapping: the biggest per-pixel saving on weak GPUs
	for mk: String in Kit.mats.keys():
		var km: StandardMaterial3D = Kit.mats[mk]
		if km.normal_texture != null:
			km.normal_enabled = int(st["preset"]) > 0
	for pk: String in Kit.plains.keys():
		var pm: StandardMaterial3D = Kit.plains[pk]
		if pm.normal_texture != null:
			pm.normal_enabled = int(st["preset"]) > 0
	player.torch.shadow_enabled = int(st["preset"]) == 2
	var fs: bool = st["fullscreen"]
	var cur: int = DisplayServer.window_get_mode()
	if fs and cur != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fs and cur == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# ---------- input ----------
func _input(ev: InputEvent) -> void:
	if not booted:
		return
	if state == MENU:
		if (ev is InputEventKey or ev is InputEventMouseButton) and ev.pressed:
			sfx.unlock()
		if ev is InputEventKey and ev.pressed and not ev.echo:
			if ui.is_open():
				if ev.keycode == KEY_ESCAPE:
					ui.close()
			elif ev.keycode == KEY_ENTER or ev.keycode == KEY_SPACE or ev.keycode == KEY_KP_ENTER:
				menu_default()
		return
	if state == DEAD:
		return
	if ev is InputEventMouseMotion:
		var free_look: bool = test_mode or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		var rel: Vector2 = ev.relative
		if (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or free_look) and not ui.is_open() and look_block <= 0.0 and rel.length() < 260.0:
			player.look(rel)
		return
	if ev is InputEventMouseButton:
		if ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and not ui.is_open():
			sfx.unlock()
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not test_mode:
				capture()
			else:
				player.arsenal.fire_pressed = true
		elif ev.pressed and not ui.is_open() and (ev.button_index == MOUSE_BUTTON_WHEEL_UP or ev.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			player.arsenal.cycle_weapon(1 if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1)
		return
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	if ev.is_action_pressed("pause"):
		if ui.is_open():
			ui.close()
		else:
			ui.open("pause", 0)
		return
	for scr: String in ["inventory", "map", "objectives", "manage", "manual"]:
		if ev.is_action_pressed(scr):
			if ui.is_open():
				if ui.screen == scr:
					ui.close()
			else:
				ui.open(scr, 0)
			get_viewport().set_input_as_handled()
			return
	if ui.is_open():
		return
	if ev.is_action_pressed("flashlight"):
		player.torch.visible = not player.torch.visible
		sfx.play("ui_switch", -10.0)
	elif ev.is_action_pressed("doors"):
		var pp0: Vector3 = player.global_position
		if aboard or (absf(pp0.x) < 14.0 and pp0.z > -28.0 and pp0.z < train.tail_z() + 12.0):
			act("doors", null)
		else:
			GS.say("Too far from the train to work the doors.", "warn")
	elif ev.is_action_pressed("reload"):
		player.arsenal.start_reload()
	elif ev.is_action_pressed("inspect"):
		player.arsenal.start_inspect()
	elif ev.is_action_pressed("swap"):
		player.arsenal.cycle_weapon(1)
	elif ev.keycode >= KEY_0 and ev.keycode <= KEY_9:
		player.arsenal.select_slot(9 if ev.keycode == KEY_0 else int(ev.keycode) - KEY_1)
	elif ev.is_action_pressed("interact"):
		var has_target: bool = look_area != null and is_instance_valid(look_area)
		if player.lounge:
			player.lounge = false
			player.global_position = Vector3(0.0, TrainRig.FY + 0.05, player.global_position.z + 0.45)
		elif player.seated and (not has_target or str(look_area.get_meta("label")) == "@seat"):
			player.seated = false
			player.global_position = Vector3(0.78, TrainRig.FY + 0.05, -12.25)
		elif has_target:
			var cb: Callable = look_area.get_meta("cb")
			if cb.is_valid():
				player.arsenal.reach()
				cb.call()
	elif player.seated:
		if ev.is_action_pressed("horn"):
			act("horn", null)
		elif ev.is_action_pressed("headlights"):
			act("lights", null)
		elif ev.is_action_pressed("autopilot"):
			act("auto", null)

func _drive_input(dt: float) -> void:
	var t: Dictionary = GS.train
	var thr: float = t["throttle"]
	var brk: float = t["brake"]
	var touched := false
	if Input.is_action_pressed("move_up"):
		touched = true
		if brk > 0.0:
			brk = maxf(0.0, brk - dt * 0.9)
		else:
			thr = minf(1.0, thr + dt * 0.45)
	if Input.is_action_pressed("move_down"):
		touched = true
		if thr > 0.0:
			thr = maxf(0.0, thr - dt * 0.7)
		else:
			brk = minf(1.0, brk + dt * 0.8)
	if Input.is_action_pressed("jump"):
		touched = true
		thr = 0.0
		brk = 1.0
	if touched:
		if t["autopilot"]:
			t["autopilot"] = false
			GS.say("Manual takeover. Autopilot disengaged.", "warn")
		if thr > 0.0 and not t["engine_on"] and obj_t <= 0.0:
			GS.say("The engine is off. Press the ENG switch on the desk.", "warn")
		if thr > 0.0 and t["doors_open"]:
			t["doors_open"] = false
			sfx.play("door", -4.0)
			GS.say("Doors closing.")
		t["throttle"] = thr
		t["brake"] = brk

# ---------- automated test hook (only active with ?test=1) ----------
func _poll_test() -> void:
	var c: Variant = JavaScriptBridge.eval("(function(){var c=window.__lt_cmd||'';window.__lt_cmd='';return c;})()", true)
	if typeof(c) != TYPE_STRING or str(c) == "":
		return
	for line: String in str(c).split(";"):
		var a: PackedStringArray = line.strip_edges().split(" ", false)
		if a.size() > 0:
			_test_cmd(a)

func _test_cmd(a: PackedStringArray) -> void:
	match a[0]:
		"tp":
			player.seated = false
			player.global_position = Vector3(float(a[1]), float(a[2]), float(a[3]))
			player.board_t = 0.0
			player.board_wait = 0.0
			player.lounge = false
			player.velocity = Vector3.ZERO
			if a.size() > 4:
				player.yaw = float(a[4])
			if a.size() > 5:
				player.pitch = float(a[5])
		"look":
			player.yaw = float(a[1])
			player.pitch = float(a[2])
		"hour":
			GS.time = floor(GS.time / 1440.0) * 1440.0 + float(a[1]) * 60.0
			world.sky_t = 0.0
		"weather":
			GS.weather = a[1]
			GS.weather_t = 900.0
		"warp":
			GS.train["s"] = float(a[1]) * GS.SP + float(a[2])
			GS.train["speed"] = 0.0
		"act":
			act(a[1], int(a[2]) if a.size() > 2 else null)
		"ui":
			ui.open(a[1], int(a[2]) if a.size() > 2 else 0)
		"close":
			ui.close()
		"gfx":
			GS.settings["preset"] = int(a[1])
			GS.settings["scale"] = float(a[2])
			apply_settings()
		"set":
			GS.train[a[1]] = float(a[2])
		"give":
			GS.add(GS.store, a[1], int(a[2]))
		"use":
			if look_area != null and is_instance_valid(look_area):
				var cb: Callable = look_area.get_meta("cb")
				cb.call()
		"new":
			start_new()
		"steps":
			test_steps = int(a[1])
		"jump":
			player.jump_req = true
		"walk":
			var wk := InputEventAction.new()
			wk.action = a[1]
			wk.pressed = int(a[2]) != 0
			Input.parse_input_event(wk)
		"fire":
			fire_cd = 0.0
			fire()
		"pull":
			var ph: Hostile = _nearest_hostile()
			if ph != null:
				ph.global_position = Vector3(float(a[1]), float(a[2]), float(a[3]))
				ph.velocity = Vector3.ZERO
				ph.noise_t = 0.0
		"trade":
			var tr: Dictionary = GameUI.TRADES[int(a[1])]
			ui._do_trade(tr["give"], tr["get"])
		"craft":
			ui._craft(GS.RECIPES[int(a[1])])
		"upgrade":
			ui._upgrade(GS.UPGRADES[int(a[1])])
		"assign":
			ui._cycle(int(a[1]), int(a[2]))
		"xfer":
			ui._xfer(a[1], int(a[2]), int(a[3]) != 0)
		"useitem":
			ui._use(a[1])
		"giveinv":
			GS.add(GS.inv, a[1], int(a[2]))
		"tick":
			for i in int(a[1]):
				GS.tick(5.0, aboard)
		"crewdump":
			var rows: Array = []
			for c: Dictionary in GS.crew:
				rows.append("%s/%s/%s h%d f%d t%d fa%d m%d p%d%s" % [str(c["name"]).split(" ")[0], c["job"], c["assign"], int(c["health"]), int(c["hunger"]), int(c["thirst"]), int(c["fatigue"]), int(c["morale"]), int(GS.prod(c) * 100.0), (" SICK" if c["sick"] else "") + " trust%d" % int(c.get("trust", 0.0))])
			print("[crew] ", JSON.stringify({"crew": rows, "air": int(GS.train["air"]), "san": int(GS.train["sanitation"]), "temp": snappedf(float(GS.train["temp"]), 0.1), "tout": snappedf(GS.t_out, 0.1), "power_ok": GS.power_ok, "warnings": GS.warnings, "upg": GS.upgrades, "engine": int(GS.loco["engine"]), "stats": GS.stats}))
		"addcar":
			GS.cars.append({"type": a[1], "hull": 70.0, "sys": 70.0})
			train.add_carriage(GS.cars.size() - 1)
		"event":
			GS.events[a[1]] = a[2]
		"hurt":
			hurt_player(float(a[1]), true)
		"aim":
			var best: Hostile = _nearest_hostile()
			if best != null:
				var tgt: Vector3 = best.global_position + Vector3(0, 1.1, 0)
				var d: Vector3 = tgt - player.cam.global_position
				player.yaw = atan2(-d.x, -d.z)
				player.pitch = atan2(d.y, Vector2(d.x, d.z).length())
		"near":
			var nh: Hostile = _nearest_hostile()
			if nh != null:
				var np: Vector3 = nh.global_position
				print("[near] ", JSON.stringify({"kind": nh.kind, "hp": nh.hp, "dist": snappedf(np.distance_to(player.global_position), 0.1), "pos": [snappedf(np.x, 0.1), snappedf(np.y, 0.1), snappedf(np.z, 0.1)], "hull": snappedf(GS.hull_avg(), 0.1), "attack": snappedf(GS.under_attack, 0.1), "hp_player": int(GS.player["health"]), "neutralised": int(GS.stats["neutralised"]), "ammo": GS.count(GS.inv, "ammo")}))
			else:
				print("[near] ", JSON.stringify({"kind": "none", "neutralised": int(GS.stats["neutralised"]), "hull": snappedf(GS.hull_avg(), 0.1)}))
		"freeze":
			RenderingServer.render_loop_enabled = int(a[1]) == 0
		"dbg":
			var on: bool = int(a[2]) != 0
			match a[1]:
				"hud": ui.hud.visible = on
				"crew":
					for cn: Node3D in crew_nodes:
						cn.visible = on
				"train": train.visible = on
				"world": world.visible = on
				"lamps":
					for l: OmniLight3D in train.lamps:
						l.visible = on
				"glass":
					var gm: StandardMaterial3D = Kit.mats["glass"]
					gm.albedo_color.a = 1.0 if on else 0.0
				"sky":
					world.dbg_sky = on
					world.sky_root.visible = on
				"track": world.track.visible = on
				"forest":
					world.dbg_forest = on
					for h: Node3D in world.forest_l + world.forest_r:
						h.visible = on
				"locs":
					for ln: Node3D in world.locs.values():
						ln.visible = on
				"hd": ui.hd.visible = on
				"pvc":
					for pm3: StandardMaterial3D in Kit.pmats:
						pm3.vertex_color_use_as_albedo = on
				"pamp":
					world.mist_amp = 12.0 if on else 1.0
					for pm4: StandardMaterial3D in Kit.pmats:
						pm4.albedo_color.a = 0.85 if on else float(pm4.get_meta("a0", 0.3))
				"fade": ui.fade.visible = on
				"rig": player.arsenal.visible = on
				"drift": world.dbg_drift = on
				"shadow":
					for shn: Node in train.find_children("*", "MeshInstance3D", true, false):
						var smi: MeshInstance3D = shn
						if smi.material_override == train.shadow_mat:
							smi.visible = on
				"ovl":
					ui.hd.vignette.visible = on
					ui.hd.frost.visible = on
					ui.hd.blood.visible = on
				"straps": train.strap_mmi.visible = on
				"snow":
					for sp: CPUParticles3D in world.snow:
						sp.visible = on
				"labels":
					for l3: Node in find_children("*", "Label3D", true, false):
						var lb: Label3D = l3
						lb.visible = on
				"parts":
					for pn: Node in find_children("*", "CPUParticles3D", true, false):
						var pp2: CPUParticles3D = pn
						if not world.snow.has(pp2):
							pp2.visible = on
		"kill":
			match a[1]:
				"disp": train.disp_freeze = true
				"parts":
					for pn: Node in find_children("*", "CPUParticles3D", true, false):
						var pk: CPUParticles3D = pn
						pk.emitting = false
						pk.visible = false
				"agon": get_node("/root/AgonDebug").set_process(false)
				"sky":
					world.env.background_mode = Environment.BG_COLOR
					world.env.background_color = Color(0.05, 0.06, 0.09)
				"skyon": world.env.background_mode = Environment.BG_SKY
				"envfreeze": world.env_freeze = true
				"lights":
					for ln2: Node in find_children("*", "Light3D", true, false):
						var lk: Light3D = ln2
						lk.visible = false
				"phys": PhysicsServer3D.set_active(false)
				"crew":
					for cn2: Node3D in crew_nodes:
						cn2.queue_free()
					crew_nodes = []
					GS.crew = []
		"crewpose":
			if crew_nodes.size() > int(a[1]):
				var ca: CrewAgent = crew_nodes[int(a[1])]
				ca.position = Vector3(float(a[2]), float(a[3]), float(a[4]))
				ca.target = ca.position
				ca.rotation.y = float(a[5])
				ca.target_yaw = float(a[5])
				ca.target_pose = a[6]
				ca.hum.pose = a[6]
				ca.think_t = 9999.0
		"crewwalk":
			if crew_nodes.size() > int(a[1]):
				var cw: CrewAgent = crew_nodes[int(a[1])]
				cw.target = Vector3(float(a[2]), float(a[3]), float(a[4]))
				cw.target_pose = "idle"
				cw.think_t = 9999.0
		"case":
			var found: Area3D = null
			for an: Node in find_children("*", "Area3D", true, false):
				if an.has_meta("cb"):
					var cbx: Callable = an.get_meta("cb")
					if cbx.is_valid():
						var bargs: Array = cbx.get_bound_arguments()
						if bargs.size() == 2 and str(bargs[0]) == "weapon" and typeof(bargs[1]) == TYPE_DICTIONARY:
							var bd: Dictionary = bargs[1]
							if str(bd.get("wid", "")) == a[1]:
								found = an as Area3D
			if found == null:
				print("[case] ", a[1], " NONE")
			else:
				var cpos: Vector3 = found.global_position
				var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
				var placed := false
				for off: Vector3 in [Vector3(1.1, 0, 0), Vector3(-1.1, 0, 0), Vector3(0, 0, 1.1), Vector3(0, 0, -1.1)]:
					var foot: Vector3 = cpos + off + Vector3(0, -0.6, 0)
					var eyep: Vector3 = foot + Vector3(0, 1.62, 0)
					var cq := PhysicsRayQueryParameters3D.create(eyep, cpos, 3)
					cq.collide_with_areas = true
					cq.exclude = [player.get_rid()]
					var cres: Dictionary = space.intersect_ray(cq)
					if not cres.is_empty() and cres["collider"] == found:
						player.seated = false
						player.board_t = 0.0
						player.global_position = foot
						player.velocity = Vector3.ZERO
						var cd: Vector3 = cpos - eyep
						player.yaw = atan2(-cd.x, -cd.z)
						player.pitch = atan2(cd.y, Vector2(cd.x, cd.z).length())
						placed = true
						break
				print("[case] ", a[1], " PLACED" if placed else " BLOCKED", " at ", cpos)
		"story":
			print("[story] ", JSON.stringify({"ch": Story.ch(), "step": Story.step(), "tk": int(GS.story["tk"]), "mk": int(GS.story["mk"]), "flags": GS.story["flags"], "found": GS.story["found"], "log": (GS.story["log"] as Array).size(), "done": GS.story["done"], "dlg": str(Story.cur.get("id", "")) if ui.screen == "story" else "", "screen": ui.screen, "opts": (Story.cur.get("options", []) as Array).size() if ui.screen == "story" else 0, "obj": Story.objective(), "marker": Story.marker().size(), "queue": Story.queue.size(), "events": GS.events}))
		"sact":
			Story.interact(self, a[1])
		"schoose":
			if ui.screen == "story":
				Story.choose(self, int(a[1]))
		"man":
			ManualView.chapter = int(a[1])
			ManualView.page = int(a[2]) if a.size() > 2 else 0
			ui.open("manual", 0)
		"wpn":
			var ar: Arsenal = player.arsenal
			match a[1]:
				"all":
					for wid2: String in Arsenal.ORDER:
						if not GS.weapons.has(wid2):
							GS.weapons[wid2] = int(Arsenal.DEFS[wid2]["mag"])
					for ak2: String in ["ammo", "ammo_rifle", "ammo_shell", "ammo_mag"]:
						GS.add(GS.inv, ak2, 120)
					GS.add(GS.inv, "batteries", 4)
					GS.add(GS.inv, "scrap", 10)
				"equip":
					ar.raised_t = 30.0
					ar.switch_to(a[2])
				"inspect": ar.start_inspect()
				"reload": ar.start_reload()
				"ads": ar.force_ads = int(a[2]) != 0
				"raise": ar.raised_t = float(a[2])
				"next": ar.cycle_weapon(1)
				"speed": ar.anim_speed = float(a[2])
				"fast": ar.fast = int(a[2]) != 0
				"scrub":
					ar.anim_t = float(a[2])
					ar.anim_speed = 0.0
				"auto":
					ar.fire_held = true
					ar.fire_pressed = true
					ar._try_fire()
					ar.fire_held = false
				"reach": ar.reach()
				"dump":
					print("[wpn] ", JSON.stringify({"cur": ar.cur, "mag": ar.mag(), "res": ar.reserve(), "anim": ar.anim_name, "t": snappedf(ar.anim_t, 0.01), "len": snappedf(ar.anim_len, 0.01), "w": snappedf(ar.anim_w, 0.01), "ads": snappedf(ar.ads, 0.01), "low": snappedf(ar.low, 0.01), "spr": snappedf(ar.spr, 0.01), "owned": ar.owned().size(), "weapons": GS.weapons, "fov": snappedf(player.cam.fov, 0.1), "scope": snappedf(ar.scope_a, 0.01), "vis": ar.rig.visible}))
		"talk":
			if crew_nodes.size() > int(a[1]):
				ui.open_talk(crew_nodes[int(a[1])])
		"say":
			ui._talk(a[1])
		"save":
			print("[save] ", save_game(int(a[1])))
		"load":
			load_slot(int(a[1]))
		"menu":
			quit_to_menu()
		"corrupt":
			var f := FileAccess.open(GS.slot_path(int(a[1])), FileAccess.WRITE)
			f.store_string("{ this is not json")
			f.close()
		"dump":
			var acts: Array = []
			for c: Dictionary in GS.crew:
				acts.append("%s:%s" % [str(c["name"]).split(" ")[0], c["act"]])
			var p: Vector3 = player.global_position
			print("[dump] ", JSON.stringify({"pos": [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)], "yaw": snappedf(player.yaw, 0.01), "aboard": aboard, "seated": player.seated, "state": state, "screen": ui.screen, "prompt": prompt, "at_stop": at_stop, "obj": GS.objective, "s": snappedf(float(GS.train["s"]), 0.1), "v": snappedf(float(GS.train["speed"]), 0.01), "thr": snappedf(float(GS.train["throttle"]), 0.01), "brk": snappedf(float(GS.train["brake"]), 0.01), "eng": GS.train["engine_on"], "ap": GS.train["autopilot"], "doors": GS.train["doors_open"], "diesel": int(GS.train["diesel"]), "bat": snappedf(float(GS.train["battery"]), 0.1), "kw": [snappedf(GS.kw_gen, 0.1), snappedf(GS.kw_load, 0.1)], "temp": snappedf(float(GS.train["temp"]), 0.1), "cars": GS.cars.size(), "crew": acts, "store": GS.store, "inv": GS.inv, "hp": int(GS.player["health"]), "hostiles": get_tree().get_nodes_in_group("hostile").size(), "looted": GS.looted.size(), "clock": GS.clock(), "weather": GS.weather, "warn": GS.warnings.size(), "dt": snappedf(last_dt, 0.001), "rdt": snappedf(real_dt, 0.01), "lounge": player.lounge, "slots": world.slot_types(), "sights": (GS.story["sights"] as Array).size(), "man": [ManualView.chapter, ManualView.page], "perf": [snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.1), snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.1), int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), snappedf(script_ms, 0.1)], "avg": snappedf(real_avg, 0.01), "steps_out": train.steps_out(), "preset": GS.settings["preset"], "scale": GS.settings["scale"]}))

func _nearest_hostile() -> Hostile:
	var best: Hostile = null
	var bd := 1e9
	for h: Node in get_tree().get_nodes_in_group("hostile"):
		var hn: Hostile = h
		var dd: float = hn.global_position.distance_to(player.global_position)
		if dd < bd:
			bd = dd
			best = hn
	return best

# ---------- frame ----------
func _process(dt: float) -> void:
	if not booted:
		return
	frame_n += 1
	if test_mode:
		if frame_n <= 3 or frame_n % 50 == 0:
			print("[frame] ", frame_n, "  dt ", snappedf(dt, 0.001), "  state ", state)
		_poll_test()
	if auto_quality:
		perf_n += 1
		if perf_n > 3:
			perf_t += dt
		if auto_stage == 0 and perf_n >= 24:
			var avg0: float = perf_t / 21.0
			if avg0 < 0.024:
				GS.settings["preset"] = 1
				GS.settings["scale"] = 1.0
				auto_stage = 1
				perf_n = 0
				perf_t = 0.0
			else:
				auto_quality = false
				GS.calibrated = true
				GS.settings["scale"] = 0.75 if avg0 < 0.05 else 0.5
			apply_settings()
		elif auto_stage == 1 and perf_n >= 44:
			auto_quality = false
			GS.calibrated = true
			if perf_t / 41.0 > 0.045:
				GS.settings["preset"] = 0
				GS.settings["scale"] = 0.75
				apply_settings()
	var t_us: int = Time.get_ticks_usec()
	_frame(dt)
	script_ms = float(Time.get_ticks_usec() - t_us) / 1000.0

func _frame(dt: float) -> void:
	last_dt = dt
	look_block = maxf(0.0, look_block - dt)
	var now_ms: int = Time.get_ticks_msec()
	real_dt = float(now_ms - last_ms) / 1000.0
	real_avg = lerpf(real_avg, real_dt, 0.2)
	last_ms = now_ms
	dt = minf(dt, 0.1)
	if state == MENU:
		menu_t += dt
		menu_cam.position = Vector3(-6.2 + sin(menu_t * 0.11) * 0.8, 2.1 + sin(menu_t * 0.07) * 0.25, -27.0 + cos(menu_t * 0.09) * 1.2)
		menu_cam.look_at(Vector3(1.6, 2.4, -12.0))
		world.update(dt, menu_cam.position)
		train.render(dt)
		for a: CrewAgent in crew_nodes:
			a.hum.animate(dt)
		sfx.update(dt, false, 0.4, false)
		playing = false
		return
	playing = state == PLAY and not ui.is_open()
	var cap: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if playing and was_captured and not cap and not test_mode:
		ui.open("pause", 0)
		playing = false
	if playing:
		was_captured = cap
	if not playing:
		sfx.update(dt, true, 0.0, true)
		return
	var pp: Vector3 = player.global_position
	aboard = absf(pp.x) < 1.5 and pp.y > 1.0 and pp.z > -15.3 and pp.z < train.tail_z() + 0.3
	if player.seated:
		_drive_input(dt)
	for i in test_steps:
		train.simulate(dt, aboard)
		GS.tick(dt * 0.6, aboard)
		_events(dt)
	if player.lounge:
		GS.player["fatigue"] = maxf(0.0, float(GS.player["fatigue"]) - dt * 0.22)
		GS.player["cold"] = maxf(0.0, float(GS.player["cold"]) - dt * 2.0)
	world.update(dt, pp)
	train.render(dt)
	if crew_nodes.size() != GS.crew.size():
		sync_crew()
	for a: CrewAgent in crew_nodes:
		a.update(dt)
	var ar: Arsenal = player.arsenal
	var cap2: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	ar.fire_held = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and (cap2 or test_mode)
	ar.aim_held = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and cap2
	ar.update(dt)
	_fx(dt)
	_scan()
	ui.update_hud(dt, prompt)
	sfx.update(dt, aboard, clampf(1.0 - (pp.z + 8.0) / 45.0, 0.15, 1.0), false)
	horn_cd = maxf(0.0, horn_cd - dt)
	fire_cd = maxf(0.0, fire_cd - dt)
	talk_cd = maxf(0.0, talk_cd - dt)
	autosave_t -= dt
	if autosave_t <= 0.0:
		autosave_t = 90.0
		save_game(0)

func _scan() -> void:
	look_area = null
	prompt = ""
	var keys: Dictionary = GS.settings["keys"]
	var kn: String = OS.get_keycode_string(int(keys["interact"]))
	if player.lounge:
		prompt = "[%s] Stand up" % kn
		return
	if player.seated:
		prompt = "[%s] Leave the driver's seat" % kn
	elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not test_mode:
		prompt = "Click to take control of the view  (or hold the right mouse button to look)"
	if prompt == "" and not aboard and not player.seated and train.board_target(player.global_position).size() >= 2:
		prompt = "[%s] Climb aboard" % OS.get_keycode_string(int(keys["jump"]))
	var from: Vector3 = player.cam.global_position
	var to: Vector3 = from - player.cam.global_transform.basis.z * 2.7
	var q := PhysicsRayQueryParameters3D.create(from, to, 3)
	q.collide_with_areas = true
	q.exclude = [player.get_rid()]
	var res: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	if res.is_empty():
		return
	var col: Object = res["collider"]
	if col is Area3D and col.has_meta("cb"):
		if player.seated and str(col.get_meta("label")) == "@seat":
			return
		look_area = col
		prompt = "[%s] %s" % [kn, label_for(str(col.get_meta("label")))]

func label_for(l: String) -> String:
	if not l.begins_with("@"):
		return l
	var key: String = l.substr(1)
	var t: Dictionary = GS.train
	if key.begins_with("couple:"):
		return "Couple the %s carriage (Tool Kit + 2 Repair Materials)" % str(TrainRig.TYPE_LABEL[key.substr(7)]).capitalize()
	match key:
		"doors":
			if t["doors_open"]:
				return "Close the carriage doors"
			if float(t["speed"]) > 0.3:
				return "Doors locked while the train is moving"
			return "Open the carriage doors" if at_stop >= 0 else "Open the carriage doors (no platform: steps deploy)"
		"repair":
			return "Carriage service panel: repair (2 Repair Materials)"
		"engine":
			return "Stop the engine" if t["engine_on"] else "Start the engine"
		"lights":
			return "Headlights: switch off" if t["headlights"] else "Headlights: switch on"
		"wipers":
			return "Wipers: stop" if t["wipers"] else "Wipers: start"
		"auto":
			return "Disengage autopilot" if t["autopilot"] else "Engage autopilot to the next stop"
		"horn":
			return "Sound the horn"
		"seat":
			return "Take the controls"
		"gen":
			return "Generator: stop" if t["gen_on"] else "Generator: start"
		"harvest":
			return "Planters: check the crop"
		"fixengine":
			return "Engine: service (2 Repair Materials) - condition %d %%" % int(GS.loco["engine"])
	return key

# ---------- interactions ----------
func act(what: String, arg: Variant) -> void:
	var t: Dictionary = GS.train
	var p: Dictionary = GS.player
	match what:
		"seat":
			player.seated = true
			player.set_crouch(false)
			player.global_position = Vector3(0, TrainRig.FY, -12.6)
			player.velocity = Vector3.ZERO
		"engine":
			sfx.play("clunk", 0.0)
			if t["engine_on"]:
				t["engine_on"] = false
				t["autopilot"] = false
				GS.say("Engine stopped. The train now runs on its battery.")
			elif float(t["diesel"]) <= 0.0:
				GS.say("The tank is dry. Find diesel.", "bad")
			else:
				t["engine_on"] = true
				GS.say("The diesel catches and settles into a low idle.", "good")
				noise(Vector3(0, 1, -8), 45.0)
		"lights":
			t["headlights"] = not t["headlights"]
			sfx.play("ui_switch", -6.0)
		"wipers":
			t["wipers"] = not t["wipers"]
			sfx.play("ui_switch", -6.0)
		"doors":
			if t["doors_open"]:
				t["doors_open"] = false
				sfx.play("door", -3.0)
			elif float(t["speed"]) > 0.3:
				GS.say("Doors are interlocked while the train is moving.", "warn")
			else:
				t["doors_open"] = true
				t["autopilot"] = false
				t["throttle"] = 0.0
				t["brake"] = 1.0
				sfx.play("door", -3.0)
				noise(player.global_position, 20.0)
				if at_stop < 0:
					GS.say("Doors open on the open line. Boarding steps deployed.", "warn")
		"auto":
			sfx.play("ui_switch", -6.0)
			if t["autopilot"]:
				t["autopilot"] = false
				GS.say("Autopilot disengaged. You have the train.")
			elif not t["engine_on"]:
				GS.say("Autopilot needs the engine running.", "warn")
			else:
				if t["doors_open"]:
					t["doors_open"] = false
					sfx.play("door", -3.0)
				train.engage_autopilot()
				t["brake"] = 0.0
				var k: int = int(round(float(t["ap_target"]) / GS.SP))
				var L: Dictionary = GS.loc_at(k)
				GS.say("Autopilot engaged. Next stop: %s. You may leave the cab." % L["name"], "good")
		"horn":
			if horn_cd <= 0.0:
				horn_cd = 1.8
				sfx.play("horn", 2.0)
				noise(Vector3(0, 2, -15), 90.0)
				world.salute(player.global_position)
		"window":
			var wa: Array = arg
			player.lounge = true
			player.seated = false
			player.set_crouch(false)
			player.global_position = Vector3(float(wa[2]) * 1.0, TrainRig.FY, TrainRig.car_z(int(wa[0])) + float(wa[1]))
			player.velocity = Vector3.ZERO
			player.yaw = -PI * 0.5 * float(wa[2])
			player.pitch = -0.04
			GS.say("You take the window seat. Sitting here rests you and keeps you warm.")
		"repair":
			var c: Dictionary = GS.cars[int(arg)]
			var key: String = "hull" if float(c["hull"]) < float(c["sys"]) else "sys"
			if float(c[key]) >= 99.0:
				GS.say("This carriage is in good order.")
			elif do_repair(c, key):
				GS.say("Carriage %s repaired to %d %%." % ["hull" if key == "hull" else "systems", int(c[key])], "good")
		"fixengine":
			var wk := "engine"
			for k2: String in ["brakes", "electrical", "hull"]:
				if float(GS.loco[k2]) < float(GS.loco[wk]):
					wk = k2
			if float(GS.loco[wk]) >= 99.0:
				GS.say("The locomotive is in good order.")
			elif do_repair(GS.loco, wk):
				GS.say("Locomotive %s repaired to %d %%." % [wk, int(GS.loco[wk])], "good")
		"sleep":
			if GS.under_attack > 0.0:
				GS.say("Not now. The train is under attack.", "bad")
			elif float(t["speed"]) > 0.5:
				GS.say("Stop the train before you sleep.", "warn")
			else:
				var hours: float = clampf(float(p["fatigue"]) / 12.0, 1.0, 8.0)
				for i in int(hours * 12.0):
					GS.tick(5.0, true)
				p["fatigue"] = maxf(0.0, float(p["fatigue"]) - 15.0 * hours)
				p["stamina"] = 100.0
				ui.fade_pulse("You sleep for %d hours." % int(hours))
				save_game(0)
		"rest":
			if GS.under_attack > 0.0:
				GS.say("Not now.", "bad")
			else:
				for i in 12:
					GS.tick(5.0, true)
				p["fatigue"] = maxf(0.0, float(p["fatigue"]) - 9.0)
				p["stamina"] = 100.0
				ui.fade_pulse("An hour passes.")
		"store":
			ui.open("inventory", 0)
		"manage":
			ui.open("manage", 0)
		"craft":
			ui.open("manage", 5)
		"trade":
			ui.open("trade", 0)
		"med":
			if not p["bleeding"] and not p["sick"] and float(p["health"]) > 95.0:
				GS.say("You are not hurt.")
			elif GS.pay({"medicine": 1}):
				p["bleeding"] = false
				p["sick"] = false
				p["health"] = minf(100.0, float(p["health"]) + 45.0)
				GS.say("Wounds cleaned and dressed.", "good")
			else:
				GS.say("The cabinet is empty. No medical supplies.", "warn")
		"meal":
			if GS.take(GS.store, "food", 1):
				p["hunger"] = maxf(0.0, float(p["hunger"]) - 70.0)
				p["cold"] = maxf(0.0, float(p["cold"]) - 30.0)
				GS.say("A hot meal. It helps more than it should.", "good")
			else:
				GS.say("The galley is bare.", "warn")
		"tap":
			if GS.take(GS.store, "water", 1):
				p["thirst"] = maxf(0.0, float(p["thirst"]) - 60.0)
				GS.say("Cold, clean water.", "good")
			else:
				GS.say("The tanks are dry.", "warn")
		"gen":
			t["gen_on"] = not t["gen_on"]
			sfx.play("clunk", 0.0)
			GS.say("Generator running." if t["gen_on"] else "Generator stopped.")
		"armoury":
			var drew: Array = []
			for ak: String in ["ammo", "ammo_rifle", "ammo_shell", "ammo_mag"]:
				var n: int = mini(20 if ak == "ammo" else 12, GS.count(GS.store, ak))
				if n > 0:
					GS.take(GS.store, ak, n)
					GS.add(GS.inv, ak, n)
					var ait: Dictionary = GS.ITEMS[ak]
					drew.append("%d %s" % [n, ait["name"]])
			if drew.is_empty():
				GS.say("The armoury is empty.", "warn")
			else:
				GS.say("Drew " + ", ".join(drew) + ".")
		"harvest":
			if GS.staffed("Farming") > 0.0 and GS.power_ok:
				GS.say("The planters are tended and growing. Produce goes straight to the stores.", "good")
			elif not GS.power_ok:
				GS.say("The grow lights are dark. Nothing grows without power.", "warn")
			else:
				GS.say("The planters need a farmer. Assign someone to Farming.", "warn")
		"talk":
			var ag: CrewAgent = arg
			ui.open_talk(ag)
		"story":
			Story.interact(self, str(arg))
		"loot":
			_loot(arg)
		"weapon":
			var wd: Dictionary = arg
			var wid: String = wd["wid"]
			var W: Dictionary = Arsenal.DEFS[wid]
			var per: int = int(W.get("per", 1))
			var give: int = maxi(1, int(W["mag"]) * 2 / per)
			GS.add(GS.inv, str(W["ammo"]), give)
			var ait2: Dictionary = GS.ITEMS[W["ammo"]]
			if GS.weapons.has(wid):
				GS.say("%s already carried. Took %d %s." % [W["name"], give, ait2["name"]], "good")
			else:
				GS.weapons[wid] = int(W["mag"])
				GS.say("Weapon acquired: %s  (%s)  +%d %s." % [W["name"], W["cat"], give, ait2["name"]], "good")
				ui.title_card(str(W["name"]), str(W["cat"]))
				player.arsenal.switch_to(wid)
			GS.looted[wd["key"]] = true
			var wa: Node = wd["area"]
			wa.queue_free()
			var lid: Node3D = wd["lid"]
			create_tween().tween_property(lid, "rotation:z", -1.9, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			sfx.play("clunk", -2.0, 0.8)
		"couple":
			_couple(arg)
		"recruit":
			_recruit(arg)
		"clear":
			var d: Dictionary = arg
			if GS.count(GS.store, "tools") + GS.count(GS.inv, "tools") <= 0:
				GS.say("You need a Tool Kit to clear this.", "warn")
			else:
				for i in 12:
					GS.tick(5.0, false)
				p["fatigue"] = minf(100.0, float(p["fatigue"]) + 12.0)
				GS.events.erase(str(int(d["k"])))
				var node: Node = d["node"]
				node.queue_free()
				ui.fade_pulse("An hour of hard work. The line is clear.")
				GS.say("Track cleared.", "good")

func do_repair(d: Dictionary, key: String) -> bool:
	if GS.count(GS.store, "tools") + GS.count(GS.inv, "tools") <= 0:
		GS.say("Repairs need a Tool Kit.", "warn")
		return false
	if not GS.pay({"parts": 2}):
		GS.say("Not enough Repair Materials (2 needed).", "warn")
		return false
	var amount: float = 22.0 + 12.0 * minf(1.5, GS.staffed("Repairs")) + (8.0 if GS.has_car("workshop") else 0.0)
	d[key] = minf(100.0, float(d[key]) + amount)
	GS.stats["repairs"] = int(GS.stats["repairs"]) + 1
	sfx.play("clunk", 0.0)
	return true

func _loot(d: Dictionary) -> void:
	if GS.weight(GS.inv) >= GS.inv_cap():
		GS.say("You cannot carry any more. Store supplies aboard the train first.", "warn")
		return
	var L: Dictionary = GS.LOCS[int(d["idx"])]
	var table: Array = L["loot"]
	var got: Dictionary = {}
	for i in 2 + randi() % 2:
		var item: String = table[randi() % table.size()]
		var q := 1
		match item:
			"food", "water": q = randi_range(2, 5)
			"medicine", "batteries": q = randi_range(1, 2)
			"diesel": q = randi_range(1, 3)
			"electronics", "parts": q = randi_range(1, 3)
			"scrap": q = randi_range(2, 4)
			"ammo": q = randi_range(10, 22)
			"ammo_rifle": q = randi_range(12, 26)
			"ammo_shell": q = randi_range(4, 9)
			"ammo_mag": q = randi_range(4, 8)
		got[item] = int(got.get(item, 0)) + q
	var parts: Array = []
	for k: String in got.keys():
		GS.add(GS.inv, k, int(got[k]))
		var it: Dictionary = GS.ITEMS[k]
		parts.append("%d %s" % [int(got[k]), it["name"]])
	GS.looted[d["key"]] = true
	GS.stats["looted"] = int(GS.stats["looted"]) + 1
	var a: Node = d["area"]
	a.queue_free()
	var tag: Node = d["tag"]
	var ttw := create_tween()
	ttw.tween_property(tag, "scale", Vector3(0.01, 0.01, 0.01), 0.22)
	ttw.tween_callback(tag.queue_free)
	sfx.play("bell", -6.0)
	GS.say("Found: " + ", ".join(parts), "good")
	noise(player.global_position, 8.0)

func _couple(d: Dictionary) -> void:
	if GS.count(GS.store, "tools") + GS.count(GS.inv, "tools") <= 0:
		GS.say("Coupling needs a Tool Kit.", "warn")
		return
	if float(GS.train["speed"]) > 0.2:
		return
	if not GS.pay({"parts": 2}):
		GS.say("The coupler is seized. You need 2 Repair Materials to free it.", "warn")
		return
	var type: String = d["type"]
	GS.cars.append({"type": type, "hull": 58.0, "sys": 52.0})
	train.add_carriage(GS.cars.size() - 1)
	GS.coupled[str(int(d["idx"]))] = true
	GS.stats["coupled"] = int(GS.stats["coupled"]) + 1
	var node: Node = d["node"]
	node.queue_free()
	var area: Node = d["area"]
	area.queue_free()
	for c: Dictionary in GS.crew:
		c["morale"] = minf(100.0, float(c["morale"]) + 5.0)
	ui.fade_pulse("Shunting...  The %s carriage is coupled to the train." % str(TrainRig.TYPE_LABEL[type]).capitalize())
	sfx.play("thud", 2.0, 0.7)
	GS.say("The train is now %d carriages long. Energy demand has risen." % GS.cars.size(), "good")
	save_game(0)

func _recruit(d: Dictionary) -> void:
	if str(d["key"]) == "fixed7" and Story.f("niko_stays"):
		GS.say("Niko Aalto is staying with the light. He raises a hand and goes back to the crank.")
		return
	if GS.crew.size() >= GS.crew_cap():
		GS.say("No berth free. Couple another Passenger carriage first.", "warn")
		return
	var rname: String = d["name"]
	var c: Dictionary = GS.mk_crew(rname, d["job"], 2 + absi(rname.hash()) % 3, absi(rname.hash()) % 997)
	GS.crew.append(c)
	GS.recruited[d["key"]] = true
	GS.stats["recruited"] = int(GS.stats["recruited"]) + 1
	var node: Node = d["node"]
	node.queue_free()
	for o: Dictionary in GS.crew:
		o["morale"] = minf(100.0, float(o["morale"]) + 3.0)
	GS.say("%s (%s) joins the train. Assigned: %s." % [rname, d["job"], c["assign"]], "good")
	sfx.play("bell", -6.0)

func fire() -> void:
	if not playing or player.arsenal.mag() <= 0:
		return
	player.arsenal.raised_t = 6.0
	player.arsenal.fire_now()

## One hitscan projectile. Coil slugs pass through whatever they hit.
func shot(from: Vector3, dir: Vector3, dmg: float, muzzle: Vector3, tracer: bool, pierce: bool) -> void:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var exclude: Array = [player.get_rid()]
	var endp: Vector3 = from + dir * 120.0
	for pass_i in (4 if pierce else 1):
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 120.0, 5)
		q.exclude = exclude
		var res: Dictionary = space.intersect_ray(q)
		if res.is_empty():
			break
		endp = res["position"]
		var col: Object = res["collider"]
		if col.has_method("hit"):
			col.call("hit", dmg)
			ui.hit_marker()
			sfx.play("thud", -8.0, 1.3)
			_impact(endp, Color(0.5, 0.1, 0.08, 0.7))
			if not pierce:
				break
			exclude.append(res["rid"])
		else:
			_impact(endp, Color(0.8, 0.8, 0.82, 0.6))
			break
	if tracer:
		var tr: MeshInstance3D = tracers[tracer_i]
		tracer_i = (tracer_i + 1) % tracers.size()
		var mid: Vector3 = (muzzle + endp) * 0.5
		var ln: float = muzzle.distance_to(endp)
		var tdir: Vector3 = (endp - muzzle).normalized()
		if ln > 1.5:
			var tup: Vector3 = Vector3.UP if absf(tdir.y) < 0.95 else Vector3.RIGHT
			var txb: Vector3 = tup.cross(-tdir).normalized()
			tr.global_transform = Transform3D(Basis(txb, (-tdir).cross(txb), -tdir).scaled(Vector3(1.6 if pierce else 1.0, 1.6 if pierce else 1.0, ln)), mid)
			tr.visible = true
			tr.set_meta("t", 0.09 if pierce else 0.05)

func _impact(pos: Vector3, col: Color) -> void:
	var ip: CPUParticles3D = impacts[impact_i]
	impact_i = (impact_i + 1) % impacts.size()
	ip.global_position = pos
	var m: StandardMaterial3D = ip.get_meta("mat")
	m.albedo_color = col
	ip.restart()
	ip.emitting = true

func _fx(dt: float) -> void:
	for tr: MeshInstance3D in tracers:
		if tr.visible:
			var tt: float = float(tr.get_meta("t")) - dt
			tr.set_meta("t", tt)
			if tt <= 0.0:
				tr.visible = false

func _build_fx() -> void:
	tracers = []
	impacts = []
	var tm := StandardMaterial3D.new()
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	tm.albedo_color = Color(1.0, 0.85, 0.55, 0.55)
	for i in 4:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.018, 0.018, 1.0)
		mi.mesh = bm
		mi.material_override = tm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		world.add_child(mi)
		tracers.append(mi)
	for i in 4:
		var ip: CPUParticles3D = Kit.particles(world, Vector3.ZERO, 10, 0.45, Color(0.8, 0.8, 0.82, 0.6), 0.22)
		ip.one_shot = true
		ip.explosiveness = 0.95
		ip.emitting = false
		ip.spread = 70.0
		ip.initial_velocity_min = 0.8
		ip.initial_velocity_max = 2.6
		ip.gravity = Vector3(0, -3.0, 0)
		impacts.append(ip)

func hurt_player(dmg: float, melee: bool) -> void:
	var p: Dictionary = GS.player
	p["health"] = maxf(0.0, float(p["health"]) - dmg)
	ui.hurt()
	sfx.play("thud", -2.0, 0.9)
	if float(p["health"]) <= 0.0:
		_die()
		return
	if melee and randf() < 0.22 and not p["bleeding"]:
		p["bleeding"] = true
		GS.say("You are bleeding.", "bad")

func _die() -> void:
	if state != PLAY:
		return
	GS.player["health"] = 0.0
	state = DEAD
	playing = false
	player.seated = false
	GS.train["autopilot"] = false
	GS.train["throttle"] = 0.0
	GS.train["brake"] = 1.0
	if ui.is_open():
		ui.screen = ""
	ui.open("dead", 0)

func noise(pos: Vector3, radius: float) -> void:
	for h: Node in get_tree().get_nodes_in_group("hostile"):
		var hn: Hostile = h
		if hn.global_position.distance_to(pos) < radius:
			hn.hear(pos)

# ---------- world events, objectives ----------
func _events(dt: float) -> void:
	var t: Dictionary = GS.train
	var s: float = t["s"]
	var v: float = t["speed"]
	if train.collided > 0.0:
		var dmg: float = train.collided * 2.2
		train.collided = 0.0
		GS.loco["hull"] = maxf(0.0, float(GS.loco["hull"]) - dmg)
		GS.loco["engine"] = maxf(5.0, float(GS.loco["engine"]) - dmg * 0.5)
		GS.say("IMPACT. The train ploughs into debris on the line.", "bad")
		hurt_player(dmg * 0.4, false)
		for c: Dictionary in GS.crew:
			c["morale"] = maxf(0.0, float(c["morale"]) - 8.0)
	var k: int = int(round(s / GS.SP))
	at_stop = k if (absf(s - float(k) * GS.SP) < 30.0 and v < 0.3) else -1
	if at_stop >= 0 and at_stop != last_arrived:
		last_arrived = at_stop
		var idx: int = posmod(k, GS.NLOC)
		var L: Dictionary = GS.loc_at(k)
		var meridian: bool = Story.is_meridian(k)
		if not meridian:
			GS.discovered[str(idx)] = true
		GS.stats["stops"] = int(GS.stats["stops"]) + 1
		if idx == 0 and not meridian:
			GS.stats["laps"] = int(GS.stats["laps"]) + 1
			GS.radio("Nordhaven again. Lap %d of the Northern Line. The dead have had time to gather." % (int(GS.stats["laps"]) + 1))
		GS.speed_limit = 33.0
		for c: Dictionary in GS.crew:
			c["morale"] = minf(100.0, float(c["morale"]) + 3.0)
		GS.say("Arrived: %s  (%s)" % [L["name"], L["kind"]], "good")
		ui.title_card(str(L["name"]), str(L["kind"]))
		for key: String in GS.events.keys():
			if int(key) < k - 1:
				GS.events.erase(key)
		save_game(0)
	var kn: int = int(floor(s / GS.SP)) + 1
	if s > float(kn - 1) * GS.SP + 60.0 and rolled_for < kn:
		rolled_for = kn
		_roll_event(kn)
	if float(kn) * GS.SP - s < 420.0 and hailed_for < kn:
		hailed_for = kn
		var hi: int = posmod(kn, GS.NLOC)
		if hi == 5:
			GS.radio("Haven Junction to approaching train: we see your lights. Platform is clear, traders are waiting. Weapons holstered.")
		elif hi == 6:
			GS.radio("This is Fort Varda. You are entering a restricted zone. Stop and you will be fired upon.")
		elif hi == 2:
			GS.radio("...automated loop: Vostok Central evacuation has ended. Do not enter the city. Do not use lights. Do not make noise...")
	if GS.under_attack > 0.0:
		alarm_t -= dt
		if alarm_t <= 0.0:
			alarm_t = 2.6
			sfx.play("alarm", -10.0)
	obj_t -= dt
	if obj_t <= 0.0:
		obj_t = 0.5
		_check_obj()
	if float(GS.player["health"]) <= 0.0:
		_die()

func _roll_event(kn: int) -> void:
	if GS.events.has(str(kn)) or Story.is_meridian(kn):
		return
	var idx: int = posmod(kn, GS.NLOC)
	var L: Dictionary = GS.LOCS[idx]
	var r: float = randf()
	var ev := ""
	if kn == 1 or idx == 5:
		ev = ""
	elif r < 0.17:
		ev = "blocked"
	elif r < 0.31 and int(L["infected"]) > 0:
		ev = "horde"
	elif r < 0.46 and GS.crew.size() < GS.crew_cap():
		ev = "survivor"
	elif r < 0.58:
		ev = "wreck"
	elif r < 0.68:
		ev = "signal"
	elif r < 0.76:
		ev = "storm"
	match ev:
		"blocked":
			GS.radio("Track report: the line is obstructed just beyond %s. Stop at the platform and clear it by hand." % L["name"])
		"horde":
			GS.radio("Warning: a large group of infected is migrating through %s. Keep the doors shut and the lights low." % L["name"])
		"survivor":
			GS.radio("Distress signal: \"...I'm on the platform at %s. Red flare. Please. If anyone has a train...\"" % L["name"])
		"wreck":
			GS.radio("An abandoned freight train is reported on the second track at %s. Its cargo may be intact." % L["name"])
		"signal":
			GS.speed_limit = 14.0
			GS.radio("Damaged infrastructure ahead: signalling and track bed are failing. Speed restricted to 50 km/h until the next stop.")
		"storm":
			GS.weather = "blizzard"
			GS.weather_t = 260.0
			GS.radio("Weather emergency: a snowstorm is closing over the line. Temperature falling fast. Heating load will rise.")
	if ev in ["blocked", "horde", "survivor", "wreck"]:
		GS.events[str(kn)] = ev

func _check_obj() -> void:
	var o: int = GS.objective
	if o >= 5:
		# the prologue is over: the campaign drives the objectives from here
		Story.tick(self)
		return
	var done := false
	match o:
		0: done = aboard and player.global_position.z < -11.4
		1: done = GS.train["engine_on"]
		2: done = int(GS.stats["looted"]) >= 3 or last_arrived >= 1 or float(GS.train["s"]) > 40.0
		3: done = int(GS.stats["transfers"]) > 0 or last_arrived >= 1 or float(GS.train["s"]) > 40.0
		4: done = float(GS.train["speed"]) > 4.0
		5: done = last_arrived >= 1
		6: done = int(GS.stats["coupled"]) > 0
		7: done = int(GS.stats["recruited"]) > 0
		8: done = GS.discovered.has("5")
		9: done = GS.discovered.has("8")
	if done:
		GS.say("Objective complete: %s" % GameUI.OBJECTIVES[o][0], "good")
		GS.objective = o + 1
		sfx.play("bell", -4.0)
