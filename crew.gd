class_name CrewAgent
extends Node3D
## A survivor living on the train. Walks the aisle between slots, picks activities from
## time of day, needs, assignment and emergencies. Lives in train space.

var main
var data: Dictionary = {}
var hum: Humanoid
var index := 0
var target := Vector3.ZERO
var target_yaw := 0.0
var target_pose := "sit"
var think_t := 0.0
var bubble: Label3D
var bubble_t := 0.0
var area: Area3D
var vel := 0.0
var greet_t := 0.0
var greet_cd := 0.0

const LINES := {
	"hungry": ["I can't remember my last proper meal.", "We need food. Soon."],
	"cold": ["It's freezing in here. Is the heating dead?", "I can see my breath."],
	"tired": ["I'm running on fumes.", "Wake me if something happens."],
	"sick": ["I don't feel right... fever, I think."],
	"low": ["How long can we keep this up?", "Everyone I knew was in Vostok."],
	"ok": ["She's a good train. She'll get us there.", "Quiet night. I don't trust it.", "Keep us moving, conductor.", "The Port. They say ships still leave from the Port."],
	"good": ["Warm, fed and rolling. Can't ask for more.", "For the first time in weeks I slept."],
}

func setup(m, d: Dictionary, i: int) -> void:
	main = m
	data = d
	index = i
	hum = Humanoid.new()
	add_child(hum)
	hum.setup(int(d["look"]), "survivor")
	bubble = Kit.text3d(self, Vector3(0, 2.05, 0), "", 30, Color(1.0, 0.9, 0.7), 0.0, 0.0022)
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.outline_size = 8
	bubble.outline_modulate = Color(0, 0, 0, 0.8)
	bubble.visible = false
	area = Kit.interact(self, Vector3(0, 1.0, 0), Vector3(0.7, 1.9, 0.7), "Talk to %s (%s)" % [d["name"], d["job"]], main.act.bind("talk", self))
	think()
	position = target
	rotation.y = target_yaw
	hum.pose = target_pose

func _aisle_x(z: float) -> float:
	return 0.95 if (z > -9.6 and z < -0.9) else 0.0

func seat() -> Array:
	var slots: Array = main.train.seat_slots
	return slots[(index * 3 + 1) % slots.size()]

func think() -> void:
	var hr: float = GS.hour()
	var assign: String = data["assign"]
	var st: Array = seat()
	var ws: Array = main.train.work_slot(assign, index)
	var meal: bool = (hr >= 7.0 and hr < 8.0) or (hr >= 12.5 and hr < 13.5) or (hr >= 18.5 and hr < 19.5)
	var act := "Sitting"
	var slot: Array = st
	var p := "sit"
	if GS.under_attack > 0.0:
		if assign == "Guard" and not ws.is_empty():
			slot = [Vector3(-0.7, TrainRig.FY, TrainRig.car_z(index % GS.cars.size()) + 1.25), -PI * 0.5]
			p = "aim"
			act = "On guard: defending the doors"
		else:
			act = "Taking cover"
	elif data["sick"]:
		p = "sleep"
		act = "Resting (ill)"
	elif (hr >= 22.5 or hr < 6.0) and assign != "Guard" and float(data["fatigue"]) > 12.0:
		p = "sleep"
		act = "Sleeping"
	elif float(data["fatigue"]) > 90.0:
		p = "sleep"
		act = "Sleeping (exhausted)"
	elif meal:
		act = "Eating"
		p = "eat"
	elif assign != "Idle" and not ws.is_empty():
		if assign == "Guard" and randf() < 0.6:
			var z: float = randf_range(TrainRig.car_z(0) + 1.0, main.train.tail_z() - 1.0)
			slot = [Vector3(0.0, TrainRig.FY, z), 0.0 if randf() < 0.5 else PI]
			p = "idle"
			act = "On patrol"
		else:
			slot = ws
			p = "work"
			act = "Working: " + assign
	else:
		var r: float = randf()
		if r < 0.25 and GS.crew.size() > 1:
			var other: Dictionary = GS.crew[randi() % GS.crew.size()]
			if other != data:
				var z2: float = randf_range(TrainRig.car_z(0) + 3.0, TrainRig.car_z(0) + 15.0)
				slot = [Vector3(0.0, TrainRig.FY, z2), 0.0 if randf() < 0.5 else PI]
				p = "talk"
				act = "Talking with " + str(other["name"]).split(" ")[0]
		elif r < 0.4:
			var z3: float = randf_range(TrainRig.car_z(0) + 1.0, main.train.tail_z() - 1.0)
			slot = [Vector3(0.0, TrainRig.FY, z3), PI * 0.5 if randf() < 0.5 else -PI * 0.5]
			p = "idle"
			act = "Stretching legs"
	data["act"] = act
	target = slot[0]
	target_yaw = slot[1]
	target_pose = p

func say(text: String) -> void:
	bubble.text = text
	bubble.visible = true
	bubble_t = 4.5

func mood_line() -> String:
	var key := "ok"
	if data["sick"]:
		key = "sick"
	elif float(data["hunger"]) > 55.0:
		key = "hungry"
	elif float(GS.train["temp"]) < 9.0:
		key = "cold"
	elif float(data["fatigue"]) > 75.0:
		key = "tired"
	elif float(data["morale"]) < 40.0:
		key = "low"
	elif float(data["morale"]) > 68.0:
		key = "good"
	var arr: Array = LINES[key]
	return arr[randi() % arr.size()]

func update(dt: float) -> void:
	think_t -= dt
	if think_t <= 0.0:
		think_t = randf_range(5.0, 9.0)
		think()
		if target_pose == "talk" and randf() < 0.6:
			say(mood_line())
	if bubble_t > 0.0:
		bubble_t -= dt
		if bubble_t <= 0.0:
			bubble.visible = false
	var pos: Vector3 = position
	var dz: float = target.z - pos.z
	var moving := false
	var spd: float = 1.25 if GS.under_attack <= 0.0 else 2.4
	var dirv := Vector3.ZERO
	var remain: float = absf(dz) + absf(target.x - pos.x)
	if absf(dz) > 0.12:
		var ax: float = _aisle_x(pos.z + signf(dz) * 0.4)
		if absf(pos.x - ax) > 0.08:
			dirv = Vector3(signf(ax - pos.x), 0, 0)
		else:
			dirv = Vector3(0, 0, signf(dz))
		moving = true
	elif absf(target.x - pos.x) > 0.06:
		dirv = Vector3(signf(target.x - pos.x), 0, 0)
		moving = true
	if moving:
		# build up to walking pace, ease off over the last steps, and do not stride until turned
		var facing: float = absf(wrapf(atan2(-dirv.x, -dirv.z) - rotation.y, -PI, PI))
		var want: float = minf(spd, 0.35 + remain * 1.6) * clampf(1.4 - facing, 0.15, 1.0)
		vel = move_toward(vel, want, dt * (2.6 if want > vel else 4.0))
		position += dirv * vel * dt
		position.y = TrainRig.FY
		rotation.y = lerp_angle(rotation.y, atan2(-dirv.x, -dirv.z), clampf(dt * 6.0, 0.0, 1.0))
		hum.pose = "walk"
		hum.move_speed = vel / 2.0
	else:
		vel = move_toward(vel, 0.0, dt * 4.0)
		position = position.lerp(Vector3(target.x, target.y, target.z), clampf(dt * 5.0, 0.0, 1.0))
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(dt * 4.5, 0.0, 1.0))
		hum.pose = target_pose
		hum.move_speed = vel / 2.0
	# notice the conductor: turn the head, and greet now and then
	var to: Vector3 = main.player.global_position - global_position
	var dist: float = to.length()
	var want := 0.0
	greet_cd = maxf(0.0, greet_cd - dt)
	if dist < 3.4 and hum.pose != "sleep" and hum.pose != "walk":
		want = clampf(wrapf(atan2(-to.x, -to.z) - rotation.y, -PI, PI), -1.15, 1.15)
		if dist < 2.3 and greet_cd <= 0.0 and GS.under_attack <= 0.0 and main.state == 1:
			greet_cd = 45.0
			greet_t = 1.5
			var greets: Array = ["Conductor.", "Evening, conductor.", "Still in one piece?", "Good to see you.", "Keep her rolling."]
			say(str(greets[randi() % greets.size()]))
	hum.look_yaw = want
	if greet_t > 0.0:
		greet_t -= dt
		if hum.pose == "idle" or hum.pose == "talk" or hum.pose == "work":
			hum.pose = "wave"
	hum.animate(dt)
