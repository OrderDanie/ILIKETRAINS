class_name PlayerRig
extends CharacterBody3D
## First-person controller. Lives in train space (the world scrolls, not the train).

const WALK := 3.7
const SPRINT := 6.3
const CROUCH := 1.9

var main
var head: Node3D
var cam: Camera3D
var torch: SpotLight3D
var arsenal: Arsenal
var view_kick := 0.0
var insp_cam := Vector3.ZERO
var shape: CapsuleShape3D
var cshape: CollisionShape3D
var yaw := 0.0
var pitch := 0.0
var seated := false
var lounge := false
var crouched := false
var sprinting := false
var step_acc := 0.0
var bob_t := 0.0
var eye := 1.62
var rum_t := 0.0
var board_t := 0.0
var board_z := 0.0
var board_wait := 0.0
var board_side := 1.0
var jump_req := false
var hint_cd := 0.0
const GRAV := 17.0

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 0.35
	shape = CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.75
	cshape = CollisionShape3D.new()
	cshape.shape = shape
	cshape.position.y = 0.875
	add_child(cshape)
	head = Node3D.new()
	head.position.y = eye
	add_child(head)
	cam = Camera3D.new()
	cam.fov = 75.0
	cam.near = 0.03
	cam.far = 900.0
	cam.current = false
	head.add_child(cam)
	torch = SpotLight3D.new()
	torch.spot_range = 26.0
	torch.spot_angle = 27.0
	torch.light_energy = 3.2
	torch.light_color = Color(1.0, 0.95, 0.85)
	torch.shadow_enabled = false
	torch.visible = false
	torch.position = Vector3(0.15, -0.12, 0.0)
	cam.add_child(torch)
	arsenal = Arsenal.new()
	cam.add_child(arsenal)

func look(rel: Vector2) -> void:
	var sens: float = float(GS.settings["sens"]) * 0.0023
	sens *= cam.fov / maxf(1.0, float(GS.settings["fov"]))
	arsenal.add_look(rel)
	yaw -= rel.x * sens
	pitch = clampf(pitch - rel.y * sens, -1.45, 1.45)

func set_crouch(c: bool) -> void:
	if c == crouched:
		return
	crouched = c
	shape.height = 1.1 if c else 1.75
	cshape.position.y = shape.height * 0.5

func _physics_process(dt: float) -> void:
	if main == null or not main.playing:
		return
	rotation.y = yaw
	head.rotation.x = pitch
	var target_eye: float = 1.3 if seated else (1.2 if lounge else (1.0 if crouched else 1.62))
	eye = lerpf(eye, target_eye, clampf(dt * 10.0, 0.0, 1.0))
	view_kick = lerpf(view_kick, 0.0, clampf(dt * 9.0, 0.0, 1.0))
	cam.rotation.x = view_kick + insp_cam.x
	cam.rotation.y = insp_cam.y
	if seated or lounge:
		velocity = Vector3.ZERO
		head.position.y = eye
		_rumble(dt)
		return
	var p: Dictionary = GS.player
	var stam: float = p["stamina"]
	var dir2 := Vector2.ZERO
	if not main.ui_blocking():
		dir2 = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
		set_crouch(Input.is_action_pressed("crouch"))
	var wish: Vector3 = (transform.basis * Vector3(dir2.x, 0, dir2.y))
	wish.y = 0.0
	if wish.length() > 1.0:
		wish = wish.normalized()
	sprinting = Input.is_action_pressed("sprint") and not crouched and dir2.y < 0.0 and stam > 3.0 and not main.ui_blocking()
	var spd: float = SPRINT if sprinting else (CROUCH if crouched else WALK)
	if float(p["fatigue"]) > 85.0:
		spd *= 0.8
	if float(p["cold"]) > 60.0:
		spd *= 0.85
	if sprinting and wish.length() > 0.1:
		stam -= 14.0 * dt
	else:
		stam += (9.0 if float(p["fatigue"]) < 80.0 else 4.5) * dt
	var on_floor: bool = is_on_floor()
	board_t = maxf(0.0, board_t - dt)
	var acc: float = 14.0 if on_floor else (10.0 if board_t > 0.0 else 3.0)
	velocity.x = lerpf(velocity.x, wish.x * spd, clampf(dt * acc, 0.0, 1.0))
	velocity.z = lerpf(velocity.z, wish.z * spd, clampf(dt * acc, 0.0, 1.0))
	if on_floor:
		if (Input.is_action_just_pressed("jump") or jump_req) and stam > 6.0 and not main.ui_blocking():
			do_jump()
			stam -= 6.0
	else:
		velocity.y -= GRAV * dt
	jump_req = false
	if board_wait > 0.0:
		# a jump at closed doors, or beside a train still rolling to a stand, is remembered:
		# the doors release the moment the train is stopped and the player is carried aboard
		board_wait -= dt
		if on_floor and main.train.door_beside(global_position) and float(GS.train["speed"]) < 0.3 and not GS.train["doors_open"]:
			main.act("doors", null)
		if on_floor and main.train.board_target(global_position).size() >= 2:
			board_wait = 0.0
			do_jump()
	if board_t > 0.0:
		# boarding jump: line up with the doorway on the way up, then carry in over the sill
		var dzb: float = board_z - global_position.z
		if absf(dzb) > 0.12:
			velocity.z = clampf(dzb * 9.0, -6.0, 6.0)
		else:
			velocity.z = 0.0
		var ox: float = global_position.x * board_side
		if global_position.y > TrainRig.FY - 0.05 and ox > 1.05 and absf(dzb) < 0.3:
			velocity.x = -board_side * clampf((ox - 0.9) * 13.0, 2.6, 6.5)
		elif ox > 1.9:
			velocity.x = -board_side * maxf(-velocity.x * board_side, 1.2)
		if ox < 1.0 or (on_floor and board_t < 1.0):
			board_t = 0.0
	p["stamina"] = clampf(stam, 0.0, 100.0)
	move_and_slide()
	# step up low ledges (door sills, the top of the boarding steps, kerbs) instead of stopping dead
	if on_floor and is_on_wall() and wish.length() > 0.3:
		var up := Vector3(0, 0.36, 0)
		var fwd: Vector3 = wish.normalized() * 0.22
		if not test_move(global_transform, up) and not test_move(global_transform.translated(up), fwd):
			global_position += up + fwd
			move_and_collide(Vector3(0, -0.4, 0))
	var hv: float = Vector2(velocity.x, velocity.z).length()
	if on_floor and hv > 0.5:
		bob_t += dt * hv * 1.6
		step_acc += hv * dt
		if step_acc > (2.3 if sprinting else 1.75):
			step_acc = 0.0
			main.sfx.play("step_snow" if global_position.y < 0.6 else "step_hard", -9.0 if not crouched else -18.0, randf_range(0.9, 1.1))
			if sprinting and not main.aboard:
				main.noise(global_position, 14.0)
	head.position.y = eye + sin(bob_t * 2.0) * 0.022 * clampf(hv / 4.0, 0.0, 1.0)
	_rumble(dt)
	if global_position.y < -6.0:
		global_position = Vector3(0, TrainRig.FY + 0.1, TrainRig.car_z(0) + 1.25)
		velocity = Vector3.ZERO

## Carriage motion felt through the camera: fine vibration, slow sway and a kick on each rail joint.
func _rumble(dt: float) -> void:
	var v: float = GS.train["speed"]
	var k: float = clampf(v / 25.0, 0.0, 1.0)
	if main.aboard and v > 0.3:
		rum_t += dt
		head.position.y += sin(rum_t * 31.0) * 0.0022 * k - main.train.joint_kick * 0.009 * k
		cam.rotation.z = lerpf(cam.rotation.z, sin(rum_t * 1.1) * 0.007 * k + sin(rum_t * 2.7) * 0.003 * k, clampf(dt * 8.0, 0.0, 1.0))
	else:
		cam.rotation.z = lerpf(cam.rotation.z, 0.0, clampf(dt * 5.0, 0.0, 1.0))

## A normal jump clears 0.85 m. Beside an open carriage door the jump is sized to land exactly
## on the vestibule floor, however far below it the player is standing.
func do_jump() -> void:
	var tgt: Array = main.train.board_target(global_position)
	if tgt.size() >= 3:
		var rise: float = float(tgt[0]) + 0.5 - global_position.y
		velocity.y = sqrt(2.0 * GRAV * maxf(rise, 0.3))
		board_z = float(tgt[1])
		board_side = float(tgt[2])
		board_t = 1.3
		main.sfx.play("w_cloth", -8.0, 0.8)
		return
	velocity.y = 5.4
	if main.train.door_beside(global_position):
		if float(GS.train["speed"]) >= 0.3:
			board_wait = 14.0
			GS.say("The train is still rolling. Hold on - you will be pulled aboard the moment it stops.", "warn")
		elif not GS.train["doors_open"]:
			main.act("doors", null)
			board_wait = 2.4
			GS.say("Doors opening. Climbing aboard.")
		else:
			board_wait = 1.8
