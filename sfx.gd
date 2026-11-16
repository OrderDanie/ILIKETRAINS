class_name Sfx
extends Node
## Reactive audio: looped beds (engine, rails, wind, brake) + one-shot pool + 3D pool.

var streams: Dictionary = {}
var loops: Dictionary = {}
var pool: Array = []
var pool3: Array = []
var pi := 0
var p3i := 0
var started := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n: String in ["engine", "rail", "wind", "brake", "horn", "alarm", "door", "radio", "growl", "shot", "thud", "clunk", "ui_click", "ui_switch", "rain", "shot_rev", "shot_smg", "shot_ar", "shot_sg", "shot_dmr", "shot_snp", "shot_lmg", "shot_coil", "shot_rivet", "w_magout", "w_magin", "w_rack", "w_pump", "w_shell", "w_click", "w_bolt", "w_ratchet", "w_cover", "w_cloth", "w_charge"]:
		streams[n] = load("res://assets/sfx/%s.wav" % n)
	for n: String in ["step_snow", "step_hard", "bell"]:
		streams[n] = load("res://assets/sfx/%s.ogg" % n)
	for n: String in ["engine", "rail", "wind", "brake", "rain"]:
		var w: AudioStreamWAV = streams[n]
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * float(w.mix_rate)) - 1
		var p := AudioStreamPlayer.new()
		p.stream = w
		p.volume_db = -60.0
		add_child(p)
		loops[n] = p
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	for i in 4:
		var p3 := AudioStreamPlayer3D.new()
		p3.unit_size = 6.0
		p3.max_distance = 60.0
		add_child(p3)
		pool3.append(p3)

func unlock() -> void:
	if started:
		return
	started = true
	for n: String in loops.keys():
		var p: AudioStreamPlayer = loops[n]
		p.play()

func set_master(v: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, v)))

func play(n: String, db: float = 0.0, pitch: float = 1.0) -> void:
	if not streams.has(n):
		return
	var p: AudioStreamPlayer = pool[pi]
	pi = (pi + 1) % pool.size()
	p.stream = streams[n]
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()

func play_at(n: String, pos: Vector3, db: float = 0.0, pitch: float = 1.0) -> void:
	if not streams.has(n):
		return
	var p: AudioStreamPlayer3D = pool3[p3i]
	p3i = (p3i + 1) % pool3.size()
	p.stream = streams[n]
	p.volume_db = db
	p.pitch_scale = pitch
	p.global_position = pos
	p.play()

func _vol(n: String, lin: float, dt: float) -> void:
	var p: AudioStreamPlayer = loops[n]
	var target: float = linear_to_db(maxf(0.0005, lin))
	p.volume_db = lerpf(p.volume_db, target, clampf(dt * 5.0, 0.0, 1.0))

func update(dt: float, inside: bool, near_engine: float, silent: bool) -> void:
	if not started:
		return
	var t: Dictionary = GS.train
	var v: float = t["speed"]
	var thr: float = t["throttle"]
	var on: bool = t["engine_on"]
	if silent:
		for n: String in loops.keys():
			_vol(n, 0.0, dt)
		return
	var e: float = (0.16 + 0.34 * thr) * (0.35 + 0.65 * near_engine) if on else 0.0
	_vol("engine", e, dt)
	var ep: AudioStreamPlayer = loops["engine"]
	ep.pitch_scale = lerpf(ep.pitch_scale, 0.8 + 0.5 * thr + v / 90.0, dt * 2.0)
	_vol("rail", clampf(v / 30.0, 0.0, 1.0) * (0.55 if inside else 0.8), dt)
	var rp: AudioStreamPlayer = loops["rail"]
	rp.pitch_scale = clampf(0.6 + v / 28.0, 0.6, 1.7)
	var w: float = 0.12
	if GS.weather == "snow":
		w = 0.22
	elif GS.weather == "blizzard":
		w = 0.6
	w += v / 120.0
	if inside:
		w *= 0.6 if t["doors_open"] else 0.28
	_vol("wind", w, dt)
	_vol("rain", (0.5 if not inside else 0.22) if GS.weather == "sleet" else 0.0, dt)
	var br: float = t["brake"]
	_vol("brake", 0.22 * br * clampf(v / 6.0, 0.0, 1.0) if v > 0.4 else 0.0, dt)
