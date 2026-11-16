class_name Hostile
extends CharacterBody3D
## Infected and hostile-faction AI. Children of a location node (world space).

var main
var hum: Humanoid
var kind := "infected"
var hp := 2.0
var home := Vector3.ZERO
var wander_to := Vector3.ZERO
var wander_t := 0.0
var noise_t := 0.0
var noise_pos := Vector3.ZERO
var atk_t := 0.0
var growl_t := 3.0
var stagger := 0.0
var shoot_t := 2.0
var down := false
var down_t := 0.0
var speed_mul := 1.0
var chase_t := 0.0
var atk_anim := 0.0

func setup(m, k: String, seed_i: int, lap: int) -> void:
	main = m
	kind = k
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var sh := CapsuleShape3D.new()
	sh.radius = 0.3
	sh.height = 1.7
	cs.shape = sh
	cs.position.y = 0.85
	add_child(cs)
	hum = Humanoid.new()
	add_child(hum)
	hum.setup(seed_i, k)
	hum.pose = "shamble" if k == "infected" else "idle"
	hp = (2.0 if k == "infected" else 3.0) + float(mini(lap, 3))
	speed_mul = randf_range(0.85, 1.15) * (1.0 + 0.08 * float(mini(lap, 4)))
	growl_t = randf_range(2.0, 9.0)
	add_to_group("hostile")

func hear(pos: Vector3) -> void:
	if down or kind != "infected":
		return
	noise_pos = pos
	noise_t = 9.0

func hit(dmg: float) -> void:
	if down:
		return
	hp -= dmg
	stagger = 0.5
	if hp <= 0.0:
		down = true
		hum.pose = "down"
		collision_layer = 0
		collision_mask = 0
		GS.stats["neutralised"] = int(GS.stats["neutralised"]) + 1
		remove_from_group("hostile")

func _inside_train(p: Vector3) -> bool:
	return absf(p.x) < 1.45 and p.y > 1.0 and p.z > -15.0 and p.z < main.train.tail_z()

func _physics_process(dt: float) -> void:
	if main == null or not main.playing:
		return
	if down:
		hum.animate(dt)
		down_t += dt
		if down_t > 25.0:
			queue_free()
		return
	var gp: Vector3 = global_position
	var pp: Vector3 = main.player.global_position
	var to_p: Vector3 = pp - gp
	var dist: float = to_p.length()
	if dist > 110.0 or float(GS.train["speed"]) > 1.5:
		return
	stagger = maxf(0.0, stagger - dt)
	if kind == "raider":
		_raider(dt, gp, pp, dist)
		return
	var target: Vector3 = gp
	var spd := 0.0
	var sense: float = 13.0
	if main.player.sprinting:
		sense += 9.0
	if main.player.crouched:
		sense -= 6.0
	if main.player.torch.visible:
		sense += 9.0
	var p_in: bool = main.aboard
	var doors: bool = GS.train["doors_open"]
	var me_in: bool = _inside_train(gp)
	var chasing := false
	if dist < sense and (not p_in or me_in or (doors and dist < 9.0)):
		chase_t = 15.0
	chase_t = maxf(0.0, chase_t - dt)
	if chase_t > 0.0 and dist < 36.0 and (not p_in or me_in or doors):
		target = pp
		spd = 3.3
		chasing = true
	elif noise_t > 0.0:
		noise_t -= dt
		target = noise_pos
		spd = 2.2
		if gp.distance_to(noise_pos) < 2.0:
			noise_t = 0.0
	else:
		var lit: bool = GS.train["headlights"] or (GS.train["lights"] and GS.power_ok)
		var tz: float = clampf(gp.z, -14.0, main.train.tail_z())
		var d_train: float = Vector2(gp.x, gp.z - tz).length()
		var reach: float = 70.0 if GS.train["headlights"] else (40.0 if lit else 16.0)
		if d_train < reach:
			if gp.y > 0.8 and gp.x > 1.5:
				target = Vector3(2.3, gp.y, tz)
				if doors:
					var ci: int = clampi(int(round((gp.z - 2.25) / 17.0)), 0, GS.cars.size() - 1)
					var dz: float = TrainRig.car_z(ci) + 1.25
					target = Vector3(2.3, gp.y, dz) if absf(gp.z - dz) > 0.5 else Vector3(0.3, gp.y, dz)
			else:
				target = Vector3(-2.4 if gp.x < 0.0 else 9.0, gp.y, tz)
			spd = 1.5
			if Vector2(gp.x - target.x, gp.z - target.z).length() < 0.9:
				spd = 0.0
				if gp.x < 3.5:
					GS.under_attack = 3.0
					atk_t -= dt
					if atk_t <= 0.0:
						atk_t = 1.6
						var guard: float = GS.staffed("Guard") * (1.5 if GS.has_car("security") else 1.0)
						if guard > 0.0 and GS.count(GS.store, "ammo") > 0 and randf() < 0.25 * guard:
							GS.take(GS.store, "ammo", 1)
							main.sfx.play_at("shot", gp, -6.0)
							hit(1.5)
						else:
							GS.damage_hull(1.2 * (0.4 if guard > 0.0 else 1.0))
							atk_anim = 0.6
							main.sfx.play_at("thud", gp, -2.0, randf_range(0.8, 1.1))
		else:
			wander_t -= dt
			if wander_t <= 0.0:
				wander_t = randf_range(3.0, 8.0)
				var hw: Vector3 = get_parent().global_position + home
				wander_to = hw + Vector3(randf_range(-4.0, 4.0), 0, randf_range(-5.0, 5.0))
			target = wander_to
			spd = 0.8
	if me_in:
		GS.under_attack = 3.0
		if not chasing and randf() < dt * 0.4 and GS.crew.size() > 0:
			var c: Dictionary = GS.crew[randi() % GS.crew.size()]
			c["health"] = maxf(0.0, float(c["health"]) - 6.0)
			c["morale"] = maxf(0.0, float(c["morale"]) - 5.0)
	# the platform is 1.5 m above the ground: climb it by the nearest ramp instead of pushing at the wall
	if target.y - gp.y > 0.7 and gp.y < 0.8 and gp.x > 6.0 and spd > 0.0:
		var oz: float = get_parent().global_position.z
		var lz: float = gp.z - oz
		var rz: float = 10.0
		for cand: float in [62.0, 120.0]:
			if absf(lz - cand) < absf(lz - rz):
				rz = cand
		if absf(lz - rz) > 0.8:
			target = Vector3(maxf(gp.x, 11.4), gp.y, rz + oz)
		else:
			target = Vector3(6.6, gp.y, rz + oz)
	var dir: Vector3 = target - gp
	dir.y = 0.0
	var dl: float = dir.length()
	if stagger > 0.0:
		spd = 0.0
	if dl > 0.4 and spd > 0.0:
		dir /= dl
		var acc: float = clampf(dt * 3.5, 0.0, 1.0)
		velocity.x = lerpf(velocity.x, dir.x * spd * speed_mul, acc)
		velocity.z = lerpf(velocity.z, dir.z * spd * speed_mul, acc)
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(dt * 5.0, 0.0, 1.0))
	else:
		velocity.x = lerpf(velocity.x, 0.0, clampf(dt * 6.0, 0.0, 1.0))
		velocity.z = lerpf(velocity.z, 0.0, clampf(dt * 6.0, 0.0, 1.0))
	if not is_on_floor():
		velocity.y -= 17.0 * dt
	else:
		velocity.y = 0.0
	move_and_slide()
	hum.move_speed = Vector2(velocity.x, velocity.z).length() / 2.0
	atk_anim = maxf(0.0, atk_anim - dt)
	if stagger > 0.0:
		hum.pose = "stagger"
	elif atk_anim > 0.0:
		hum.pose = "attack"
	else:
		hum.pose = "shamble"
	hum.look_yaw = clampf(wrapf(atan2(-to_p.x, -to_p.z) - rotation.y, -PI, PI), -1.0, 1.0) if dist < 14.0 else 0.0
	hum.animate(dt)
	atk_t = maxf(-1.0, atk_t - dt) if chasing else atk_t
	if chasing and dist < 1.5 and absf(to_p.y) < 1.6 and atk_t <= 0.0:
		atk_t = 1.1
		atk_anim = 0.6
		main.hurt_player(9.0, true)
	growl_t -= dt
	if growl_t <= 0.0 and dist < 40.0:
		growl_t = randf_range(4.0, 11.0) if not chasing else randf_range(1.5, 3.5)
		main.sfx.play_at("growl", gp + Vector3(0, 1.5, 0), -4.0, randf_range(0.8, 1.2))

func _raider(dt: float, gp: Vector3, pp: Vector3, dist: float) -> void:
	if Story.f("varda_peace"):
		# the garrison has stood down: they watch the train, they do not fire on it
		var look: Vector3 = pp - gp
		rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), clampf(dt * 1.5, 0.0, 1.0))
		hum.pose = "idle"
		hum.animate(dt)
		return
	var alert: bool = not main.aboard and dist < 36.0
	var d_train: float = absf(gp.x)
	var dir: Vector3 = pp - gp
	if alert or d_train < 60.0:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(dt * 4.0, 0.0, 1.0))
		hum.pose = "aim"
		shoot_t -= dt
		if shoot_t <= 0.0 and stagger <= 0.0:
			shoot_t = randf_range(1.6, 3.0)
			main.sfx.play_at("shot", gp + Vector3(0, 1.4, 0), -3.0, 0.8)
			if alert:
				var q := PhysicsRayQueryParameters3D.create(gp + Vector3(0, 1.5, 0), pp + Vector3(0, 1.0, 0), 1)
				var res: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
				var clear: bool = res.is_empty() or res.get("collider") == main.player
				if clear and randf() < (0.2 if main.player.crouched else 0.42):
					main.hurt_player(11.0, false)
			elif float(GS.train["speed"]) < 0.5:
				GS.under_attack = 3.0
				if randf() < 0.5:
					GS.damage_hull(1.5)
	else:
		hum.pose = "idle"
	if not is_on_floor():
		velocity.y -= 17.0 * dt
		move_and_slide()
	hum.animate(dt)
