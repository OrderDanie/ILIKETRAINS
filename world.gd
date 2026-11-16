class_name WorldRig
extends Node3D
## Environment, day/night, weather, the scrolling railway and the ten streamed locations.

var main
var env: Environment
var dome: Node3D
var dome_grad: Gradient
var sun_disc: MeshInstance3D
var sun_disc_mat: StandardMaterial3D
var sun: DirectionalLight3D
var fill: DirectionalLight3D
var ground: MeshInstance3D
var track: MultiMeshInstance3D
var forest_l: Array = []
var forest_r: Array = []
var locs: Dictionary = {}
var snow: Array = []
var snow_mat: StandardMaterial3D
var civils: Array = []
var spinners: Array = []
var flickers: Array = []
var sky_t := 0.0
var fog_d := 0.012
var daylight := 0.0
var t := 0.0
var post_n := 0
var sky_root: Node3D
var star_mat: StandardMaterial3D
var moon_mat: StandardMaterial3D
var aurora_mats: Array = []
var birds: Array = []
var rotors: Array = []
var crossings: Array = []
var bell_t := 0.0
var dbg_sky := true
var scn: Dictionary = {}
var herds: Array = []
var turners: Array = []
var salute_cd := 0.0
var deer_body: ArrayMesh
var deer_legs: ArrayMesh
var car_mats: Dictionary = {}
var gates: Dictionary = {}
var refl_img: Image
var refl_tex: ImageTexture
var refl_sky: Sky
var refl_on := false
var refl_key := -1
var mist_amp := 1.0
var dbg_drift := true
var tunnels: Array = []
var snow_quad: QuadMesh
var tree_mats: Array = []
var veg_grass: ArrayMesh
var veg_bush: ArrayMesh
var veg_bare: ArrayMesh
var ranges: Array = []
var drift: CPUParticles3D
var drift_mat: StandardMaterial3D
var env_freeze := false
var dbg_forest := true
var mid_body: StaticBody3D
var mid_k := 0
var mid_id := 40
var mid_lap := 0
var night := 0.0
var clear_f := 0.0
const MOON_DIR := Vector3(-0.47, 0.5, -0.73)

func build() -> void:
	env = Environment.new()
	# The engine's procedural sky re-filters its radiance map at a heavy per-frame cost on weak
	# and software GPUs, so the sky is an unshaded gradient dome that follows the camera instead.
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.09, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.fog_enabled = true
	env.fog_density = 0.012
	env.fog_sky_affect = 0.75
	env.fog_sun_scatter = 0.16
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.14
	env.tonemap_white = 5.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.95
	# reflections: a small sky panorama that changes only when the light does (a few times a day),
	# so metal and glass pick up zenith, horizon and ground instead of one flat colour
	refl_img = Image.create(64, 32, false, Image.FORMAT_RGB8)
	refl_img.fill(Color(0.1, 0.12, 0.16))
	refl_tex = ImageTexture.create_from_image(refl_img)
	var pano := PanoramaSkyMaterial.new()
	pano.panorama = refl_tex
	refl_sky = Sky.new()
	refl_sky.sky_material = pano
	refl_sky.radiance_size = Sky.RADIANCE_SIZE_32
	refl_sky.process_mode = Sky.PROCESS_MODE_QUALITY
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_max_distance = 70.0
	sun.shadow_bias = 0.06
	add_child(sun)
	fill = DirectionalLight3D.new()
	fill.shadow_enabled = false
	fill.rotation = Vector3(-0.5, 2.4, 0)
	fill.light_energy = 0.15
	fill.light_color = Color(0.6, 0.7, 0.9)
	add_child(fill)
	# ground
	var gm: StandardMaterial3D = Kit.mats["snow"].duplicate()
	gm.vertex_color_use_as_albedo = false
	gm.uv1_scale = Vector3(350, 350, 1)
	var pm := PlaneMesh.new()
	pm.size = Vector2(1400, 1400)
	ground = MeshInstance3D.new()
	ground.mesh = pm
	ground.material_override = gm
	ground.position.y = -0.25
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)
	var gb := StaticBody3D.new()
	add_child(gb)
	Kit.col(gb, Vector3(0, -0.75, 0), Vector3(1400, 1.0, 1400))
	Kit.col(gb, Vector3(-2.25, -0.115, 0), Vector3(8.6, 0.27, 1400))
	for sgn: float in [-1.0, 1.0]:
		Kit.col(gb, Vector3(-2.25 + sgn * 4.8, -0.2, 0), Vector3(1.3, 0.3, 1400), Basis(Vector3.BACK, -sgn * 0.26))
	_build_track()
	_build_forest()
	_build_snow()
	_build_sky()
	_update_env(1.0, true)

func _build_track() -> void:
	var mb := Kit.new()
	mb.box("ballast", Vector3(-2.25, -0.115, 20), Vector3(8.6, 0.27, 40))
	for sgn: float in [-1.0, 1.0]:
		mb.box("ballast", Vector3(-2.25 + sgn * 4.7, -0.17, 20), Vector3(1.2, 0.25, 40), Basis(Vector3.BACK, -sgn * 0.3))
	for tx: float in [0.0, -4.5]:
		for i in 61:
			mb.box("sleeper", Vector3(tx, 0.05, 0.33 + float(i) * 0.655), Vector3(2.5, 0.12, 0.24))
		for sgn: float in [-1.0, 1.0]:
			mb.box("rust", Vector3(tx + sgn * 0.75, 0.1175, 20), Vector3(0.14, 0.015, 40))
			mb.box("rust", Vector3(tx + sgn * 0.75, 0.15, 20), Vector3(0.022, 0.05, 40))
			mb.box("rail", Vector3(tx + sgn * 0.75, 0.186, 20), Vector3(0.066, 0.028, 40))
			for fp: float in [0.0, 20.0]:
				mb.box("rust", Vector3(tx + sgn * 0.75 + 0.02, 0.15, fp + 0.3), Vector3(0.02, 0.06, 0.5))
		mb.box("rubber", Vector3(tx, 5.75, 20), Vector3(0.025, 0.025, 40))
		mb.box("rubber", Vector3(tx, 6.3, 20), Vector3(0.02, 0.02, 40))
		for dz: float in [8.0, 20.0, 32.0]:
			mb.box("rubber", Vector3(tx, 6.02, dz), Vector3(0.012, 0.55, 0.012))
	mb.box("steel_dk", Vector3(-7.6, 3.3, 20), Vector3(0.24, 7.2, 0.24))
	mb.box("steel_dk", Vector3(-3.4, 6.55, 20), Vector3(8.6, 0.14, 0.14))
	mb.box("steel_dk", Vector3(-6.3, 5.6, 20), Vector3(3.0, 0.08, 0.08), Basis(Vector3.BACK, 0.65))
	mb.box("concrete", Vector3(-7.6, -0.05, 20), Vector3(0.7, 0.4, 0.7))
	for i in 10:
		mb.box("wood", Vector3(-12, 0.4, 2.0 + float(i) * 4.0), Vector3(0.12, 1.4, 0.12))
	mb.box("wood", Vector3(-12, 0.85, 20), Vector3(0.05, 0.1, 40))
	mb.box("wood", Vector3(-12, 0.35, 20), Vector3(0.05, 0.1, 40))
	mb.box("concrete", Vector3(-6.75, 0.04, 20), Vector3(0.4, 0.12, 40))
	mb.box("snow", Vector3(-2.25, 0.03, 20), Vector3(1.6, 0.03, 40))
	# balises between the rails, a location cabinet and a speed board beside the far track
	for tx3: float in [0.0, -4.5]:
		mb.box("amber_paint", Vector3(tx3, 0.125, 12.0), Vector3(0.44, 0.04, 0.52))
		mb.box("hull_blk", Vector3(tx3, 0.148, 12.0), Vector3(0.3, 0.006, 0.36))
	mb.box("concrete", Vector3(-7.05, -0.05, 27.0), Vector3(0.7, 0.2, 1.1))
	mb.box("panel_dk", Vector3(-7.05, 0.5, 27.0), Vector3(0.5, 1.2, 0.9))
	mb.box("snow", Vector3(-7.05, 1.13, 27.0), Vector3(0.56, 0.06, 0.96))
	mb.box("steel", Vector3(-6.79, 0.6, 27.2), Vector3(0.012, 0.16, 0.04))
	mb.cyl("steel_dk", Vector3(-7.1, 1.1, 35.0), 0.035, 2.6, 1, 5)
	mb.cyl("white_paint", Vector3(-7.1, 2.2, 35.03), 0.3, 0.03, 2, 12)
	mb.cyl("red", Vector3(-7.1, 2.2, 35.04), 0.3, 0.012, 2, 12)
	mb.cyl("white_paint", Vector3(-7.1, 2.2, 35.05), 0.24, 0.012, 2, 12)
	# lineside: telegraph pole and wires, marker post, drift mounds, cable trough
	mb.cyl("wood", Vector3(-10.4, 3.4, 5.0), 0.11, 7.4, 1, 6)
	mb.box("wood", Vector3(-10.4, 6.6, 5.0), Vector3(1.7, 0.1, 0.1))
	mb.box("wood", Vector3(-10.4, 6.0, 5.0), Vector3(1.2, 0.08, 0.08))
	for o: float in [-0.75, 0.0, 0.75]:
		mb.box("rubber", Vector3(-10.4 + o, 6.68, 20), Vector3(0.012, 0.012, 40))
		mb.cyl("white_paint", Vector3(-10.4 + o, 6.7, 5.0), 0.03, 0.1, 1, 5)
	mb.box("white_paint", Vector3(-7.15, 0.5, 31.0), Vector3(0.14, 0.9, 0.04))
	mb.box("hull_blk", Vector3(-7.15, 0.8, 31.0), Vector3(0.15, 0.16, 0.045))
	mb.box("concrete", Vector3(-6.2, 0.04, 20), Vector3(0.32, 0.1, 40))
	mb.cyl("snow", Vector3(-9.2, -0.02, 13.0), 1.7, 0.55, 1, 7, 0.4)
	mb.cyl("snow", Vector3(-11.4, 0.0, 30.5), 2.3, 0.8, 1, 7, 0.5)
	mb.cyl("snow", Vector3(-8.6, -0.05, 36.0), 1.2, 0.4, 1, 6, 0.3)
	for i in 4:
		mb.box("steel_dk", Vector3(0.75, 0.1, 5.0 + float(i) * 10.0), Vector3(0.16, 0.12, 0.5))
		mb.box("steel_dk", Vector3(-0.75, 0.1, 5.0 + float(i) * 10.0), Vector3(0.16, 0.12, 0.5))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mb.build_mesh()
	mm.instance_count = 26
	for i in 26:
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(0, 0, float(i) * 40.0 - 520.0)))
	track = MultiMeshInstance3D.new()
	track.multimesh = mm
	track.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(track)

func _build_forest() -> void:
	var mb := Kit.new()
	mb.cyl("wood", Vector3(0, 1.0, 0), 0.2, 2.6, 1, 6)
	var tiers: Array = [[2.3, 3.2, 3.2], [1.75, 2.8, 5.0], [1.15, 2.6, 6.7]]
	for tr: Array in tiers:
		var r: float = tr[0]
		var h: float = tr[1]
		var y: float = tr[2]
		mb.cyl("pine", Vector3(0, y, 0), r, h, 1, 7, 0.05)
		mb.cyl("snow", Vector3(0, y + h * 0.2, 0), r * 0.62, h * 0.62, 1, 7, 0.03)
	var tree: ArrayMesh = mb.build_mesh()
	# wind: a vertex shader bends the crowns, more strongly the higher up the tree
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nuniform vec3 tint : source_color = vec3(0.07, 0.12, 0.1);\nuniform float sway = 1.0;\nuniform float base = 2.0;\nuniform float amp = 1.0;\nuniform float top = 9.0;\nvarying float vh;\nvarying float vr;\nvoid vertex() {\n\tvec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;\n\tvh = clamp(VERTEX.y / top, 0.0, 1.0);\n\tvr = fract(sin(dot(MODEL_MATRIX[0].xz, vec2(12.9898, 78.233))) * 43758.5453);\n\tfloat h = max(VERTEX.y - base, 0.0);\n\tVERTEX.x += sin(TIME * 1.4 + wp.x * 0.21 + wp.z * 0.17) * h * 0.035 * sway * amp;\n\tVERTEX.z += cos(TIME * 1.1 + wp.x * 0.13) * h * 0.02 * sway * amp;\n}\nvoid fragment() {\n\tALBEDO = tint * mix(0.55, 1.08, vh) * mix(0.84, 1.12, vr);\n\tROUGHNESS = 0.95;\n}\n"
	for si in tree.get_surface_count():
		var sm0: Material = tree.surface_get_material(si)
		if sm0 == Kit.mats["pine"] or sm0 == Kit.mats["snow"]:
			var tm := ShaderMaterial.new()
			tm.shader = sh
			tm.set_shader_parameter("tint", Color(0.07, 0.12, 0.1) if sm0 == Kit.mats["pine"] else Color(0.84, 0.88, 0.96))
			tree.surface_set_material(si, tm)
			tree_mats.append(tm)
	# two more forms so the forest is not one tree repeated: a tall narrow spruce and a storm-broken snag
	var tb := Kit.new()
	tb.cyl("bark", Vector3(0, 1.6, 0), 0.17, 3.6, 1, 6)
	for i in 5:
		var ty: float = 2.8 + float(i) * 1.7
		var tr2: float = 1.6 - float(i) * 0.28
		tb.xf = Transform3D(Basis(Vector3.UP, float(i) * 0.7), Vector3.ZERO)
		tb.cyl("pine", Vector3(0, ty, 0), tr2, 2.6, 1, 6, 0.06)
		tb.cyl("snow", Vector3(0, ty + 0.6, 0), tr2 * 0.55, 1.4, 1, 6, 0.03)
	tb.xf = Transform3D.IDENTITY
	var tree_b: ArrayMesh = tb.build_mesh()
	var tc := Kit.new()
	tc.cyl("bark", Vector3(0, 3.2, 0), 0.24, 6.6, 1, 6, 0.12)
	tc.xf = Transform3D(Basis(Vector3.BACK, 0.5), Vector3(0, 6.3, 0))
	tc.cyl("bark", Vector3(0, 0.6, 0), 0.1, 1.3, 1, 5, 0.02)
	for i in 6:
		tc.xf = Transform3D(Basis(Vector3.UP, float(i) * 1.9) * Basis(Vector3.BACK, 1.15), Vector3(0, 1.6 + float(i) * 0.8, 0))
		tc.cyl("bark", Vector3(0, 0.45, 0), 0.035, 0.9 - float(i) * 0.08, 1, 4, 0.01)
	tc.xf = Transform3D(Basis(Vector3.UP, 0.4), Vector3.ZERO)
	tc.cyl("pine", Vector3(0, 2.6, 0), 1.3, 1.8, 1, 6, 0.3)
	tc.cyl("snow", Vector3(0, 3.0, 0), 0.8, 0.9, 1, 6, 0.1)
	tc.xf = Transform3D.IDENTITY
	tc.cyl("snow", Vector3(0, 0.1, 0), 0.7, 0.24, 1, 6, 0.2)
	var tree_c: ArrayMesh = tc.build_mesh()
	for tv: Array in [[tree_b, 11.5], [tree_c, 7.0]]:
		var tmesh: ArrayMesh = tv[0]
		var ttop: float = tv[1]
		_wind_mat(tmesh, sh, "pine", Color(0.055, 0.1, 0.085), 2.0, 1.0, ttop)
		_wind_mat(tmesh, sh, "snow", Color(0.84, 0.88, 0.96), 2.0, 1.0, ttop)
		_wind_mat(tmesh, sh, "bark", Color(0.2, 0.17, 0.15), 2.0, 1.0, ttop)
	# lineside vegetation: bare trees, scrub and dry grass standing out of the snow, all wind-driven
	var shg := Shader.new()
	shg.code = sh.code.replace("shader_type spatial;", "shader_type spatial;\nrender_mode cull_disabled;")
	var vb := Kit.new()
	vb.cyl("bark", Vector3(0, 2.6, 0), 0.17, 5.2, 1, 6, 0.07)
	for i in 7:
		vb.xf = Transform3D(Basis(Vector3.UP, float(i) * 2.2) * Basis(Vector3.BACK, 0.85 - 0.06 * float(i)), Vector3(0, 2.0 + float(i) * 0.5, 0))
		vb.cyl("bark", Vector3(0, 0.95, 0), 0.05, 1.9, 1, 4, 0.012)
		vb.xf = vb.xf * Transform3D(Basis(Vector3.BACK, -0.7), Vector3(0, 1.1, 0))
		vb.cyl("bark", Vector3(0, 0.45, 0), 0.022, 0.9, 1, 4, 0.006)
	vb.xf = Transform3D.IDENTITY
	vb.cyl("snow", Vector3(0, 0.08, 0), 0.6, 0.2, 1, 6, 0.2)
	veg_bare = vb.build_mesh()
	_wind_mat(veg_bare, sh, "bark", Color(0.2, 0.17, 0.15), 1.2, 1.0, 6.0)
	var vs := Kit.new()
	for i in 7:
		vs.xf = Transform3D(Basis(Vector3.UP, float(i) * 0.9) * Basis(Vector3.BACK, 0.35 + 0.09 * float(i % 4)), Vector3.ZERO)
		vs.cyl("bark", Vector3(0, 0.55, 0), 0.02, 1.1 + 0.1 * float(i % 3), 1, 4, 0.006)
	vs.xf = Transform3D.IDENTITY
	vs.cyl("snow", Vector3(0, 0.05, 0), 0.5, 0.16, 1, 6, 0.15)
	veg_bush = vs.build_mesh()
	_wind_mat(veg_bush, sh, "bark", Color(0.27, 0.2, 0.13), 0.15, 2.0, 1.2)
	var gst := SurfaceTool.new()
	gst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grng := RandomNumberGenerator.new()
	grng.seed = 5
	for i in 9:
		var ga: float = grng.randf() * TAU
		var gr: float = grng.randf() * 0.16
		var bp := Vector3(cos(ga) * gr, 0.0, sin(ga) * gr)
		var bw: Vector3 = Vector3(cos(ga + 1.3), 0, sin(ga + 1.3)) * 0.022
		var tip: Vector3 = bp + Vector3(cos(ga) * 0.16, grng.randf_range(0.35, 0.7), sin(ga) * 0.16)
		for p3: Vector3 in [bp - bw, bp + bw, tip]:
			gst.set_normal(Vector3.UP)
			gst.set_uv(Vector2.ZERO)
			gst.add_vertex(p3)
	veg_grass = gst.commit()
	var gm := ShaderMaterial.new()
	gm.shader = shg
	gm.set_shader_parameter("tint", Color(0.6, 0.53, 0.35))
	gm.set_shader_parameter("base", 0.0)
	gm.set_shader_parameter("amp", 4.0)
	gm.set_shader_parameter("top", 0.7)
	veg_grass.surface_set_material(0, gm)
	tree_mats.append(gm)
	var md := Kit.new()
	md.box("seat_dk", Vector3(0, 0.2, 0), Vector3(0.7, 0.4, 0.26), Basis(Vector3.UP, 0.4))
	md.box("red", Vector3(0.9, 0.14, 0.5), Vector3(0.5, 0.28, 0.34), Basis(Vector3.UP, -0.6))
	md.cyl("rubber", Vector3(-1.2, 0.12, 0.8), 0.34, 0.2, 1, 12)
	md.cyl("rust", Vector3(1.6, 0.42, -0.9), 0.3, 0.85, 1, 10)
	md.cyl("rust", Vector3(2.2, 0.28, -0.3), 0.3, 0.85, 0, 10)
	for i in 4:
		md.box("wood", Vector3(-1.0, 0.06 + float(i % 2) * 0.1, -1.4 + float(i) * 0.3), Vector3(1.2, 0.03, 0.12))
	md.box("wood", Vector3(-1.0, 0.11, -0.95), Vector3(0.1, 0.08, 1.1))
	md.box("sack", Vector3(0.2, 0.12, -1.6), Vector3(0.8, 0.24, 0.5), Basis(Vector3.UP, 1.1))
	md.box("corr", Vector3(-2.2, 0.03, 0.0), Vector3(1.0, 0.03, 2.0), Basis(Vector3(0.1, 1, 0).normalized(), 0.7))
	var debris: ArrayMesh = md.build_mesh()
	var mh := Kit.new()
	mh.cyl("hill", Vector3(0, 18, 0), 120.0, 36.0, 1, 9, 30.0)
	var hill: ArrayMesh = mh.build_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4071
	for side: float in [-1.0, 1.0]:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = tree
		mm.instance_count = 190
		for i in 190:
			var x: float = side * (42.0 + pow(rng.randf(), 1.6) * 170.0)
			var sc: float = rng.randf_range(0.7, 1.7)
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc, sc * rng.randf_range(0.9, 1.25), sc))
			mm.set_instance_transform(i, Transform3D(b, Vector3(x, -0.25, rng.randf() * 400.0)))
		var hm := MultiMesh.new()
		hm.transform_format = MultiMesh.TRANSFORM_3D
		hm.mesh = hill
		hm.instance_count = 3
		for i in 3:
			var hs: float = rng.randf_range(0.7, 1.5)
			hm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(hs, hs * rng.randf_range(0.6, 1.3), hs)), Vector3(side * rng.randf_range(300.0, 420.0), -0.3, float(i) * 133.0 + rng.randf() * 60.0)))
		var extra: Array = []
		for vd: Array in [[tree_b, 70, 18], [tree_c, 26, 8]]:
			var vm := MultiMesh.new()
			vm.transform_format = MultiMesh.TRANSFORM_3D
			vm.mesh = vd[0]
			var vcount: int = vd[1]
			vm.instance_count = vcount
			for i in vcount:
				var vx: float = side * (40.0 + pow(rng.randf(), 1.5) * 175.0)
				var vsc: float = rng.randf_range(0.75, 1.5)
				vm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(vsc, vsc * rng.randf_range(0.9, 1.3), vsc)), Vector3(vx, -0.25, rng.randf() * 400.0)))
			extra.append([vm, vd[2]])
		var ms := Kit.new()
		ms.cyl("snow", Vector3(0, 0.2, 0), 3.2, 0.9, 1, 8, 0.9)
		ms.cyl("rock", Vector3(2.1, 0.25, 0.8), 1.0, 1.0, 1, 5, 0.45)
		ms.cyl("wood", Vector3(-2.4, 0.7, -1.0), 0.07, 1.9, 1, 4, 0.02)
		ms.box("wood", Vector3(-2.2, 1.2, -1.0), Vector3(0.6, 0.04, 0.04), Basis(Vector3.BACK, 0.7))
		var sm2 := MultiMesh.new()
		sm2.transform_format = MultiMesh.TRANSFORM_3D
		sm2.mesh = ms.build_mesh()
		sm2.instance_count = 70
		for i in 70:
			var sx: float = side * ((15.0 if side < 0.0 else 44.0) + pow(rng.randf(), 1.4) * 150.0)
			var ssc: float = rng.randf_range(0.5, 2.0)
			sm2.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(ssc, ssc * rng.randf_range(0.5, 1.1), ssc)), Vector3(sx, -0.25, rng.randf() * 400.0)))
		var dmm := MultiMesh.new()
		dmm.transform_format = MultiMesh.TRANSFORM_3D
		dmm.mesh = debris
		dmm.instance_count = 16
		for i in 16:
			var dx: float = side * ((14.0 if side < 0.0 else 11.0) + rng.randf() * 22.0)
			dmm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(dx, -0.25, rng.randf() * 400.0)))
		for k in 3:
			var holder := Node3D.new()
			add_child(holder)
			var a := MultiMeshInstance3D.new()
			a.multimesh = mm
			a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(a)
			var b2 := MultiMeshInstance3D.new()
			b2.multimesh = hm
			b2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(b2)
			var c3 := MultiMeshInstance3D.new()
			c3.multimesh = sm2
			c3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(c3)
			var c4 := MultiMeshInstance3D.new()
			c4.multimesh = dmm
			c4.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(c4)
			for ex: Array in extra:
				var em := MultiMeshInstance3D.new()
				em.multimesh = ex[0]
				em.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				em.set_meta("low", int(ex[1]))
				holder.add_child(em)
			holder.set_meta("k", k)
			if side < 0.0:
				forest_l.append(holder)
			else:
				forest_r.append(holder)

func _wind_mat(mesh: ArrayMesh, shd: Shader, key: String, tint: Color, base: float, amp: float, top: float = 9.0) -> void:
	for si in mesh.get_surface_count():
		if mesh.surface_get_material(si) == Kit.mats[key]:
			var tm := ShaderMaterial.new()
			tm.shader = shd
			tm.set_shader_parameter("tint", tint)
			tm.set_shader_parameter("base", base)
			tm.set_shader_parameter("amp", amp)
			tm.set_shader_parameter("top", top)
			mesh.surface_set_material(si, tm)
			tree_mats.append(tm)

## Scrub, dry grass and bare trees along the line between stations, kept clear of platforms,
## sidings and the set-piece scenery so nothing grows through a wall.
func _veg_strip(n: Node3D, k: int, idx: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + k * 13
	var coast: bool = idx == 7 or idx == 8
	var zones: Array = [[-130.0, -30.0, 8.5], [-396.0, -298.0, 3.5], [-700.0, -562.0, 3.5]]
	var low: bool = int(GS.settings["preset"]) == 0
	var specs: Array = [[veg_grass, 160 if low else 440, 30.0, 0.7, 1.6, 3.5, 13.0], [veg_bush, 30 if low else 72, 42.0, 0.6, 1.5, 4.4, 13.5], [veg_bare, 14 if low else 34, 60.0, 0.7, 1.4, 7.5, 15.5]]
	for sp: Array in specs:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = sp[0]
		var cnt: int = sp[1]
		mm.instance_count = cnt
		for i in cnt:
			var zn: Array = zones[rng.randi() % zones.size()]
			var z: float = rng.randf_range(float(zn[0]), float(zn[1]))
			var x: float = maxf(float(zn[2]), float(sp[5])) + pow(rng.randf(), 1.7) * float(sp[2])
			if rng.randf() < 0.45 and not coast:
				x = -(float(sp[6]) + pow(rng.randf(), 1.5) * float(sp[2]))
			elif absf(z + 600.0) < 4.0 and x < 8.0:
				x += 5.0
			var sc: float = rng.randf_range(float(sp[3]), float(sp[4]))
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc, sc, sc)), Vector3(x, -0.25, z)))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)

func _mquad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for p: Vector3 in [a, b, c, a, c, d]:
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2.ZERO)
		st.add_vertex(p)

## Two layers of mountain ridge on each horizon. They ignore scene fog and are tinted toward the
## sky by hand, so they read as hazy silhouettes in clear weather and vanish in a storm.
func _build_ranges() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for layer in 2:
		for side: float in [-1.0, 1.0]:
			var P := 1300.0
			var segs := 52
			var base: float = 30.0 if layer == 0 else 78.0
			var amp: float = 48.0 if layer == 0 else 88.0
			var snowline: float = 54.0 if layer == 0 else 102.0
			var x: float = side * (360.0 if layer == 0 else 540.0)
			var ph: Array = [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
			var hs: Array = []
			for j in segs:
				var u: float = float(j) / float(segs) * TAU
				var h: float = base + amp * (0.5 + 0.34 * sin(u * 2.0 + float(ph[0])) + 0.3 * sin(u * 5.0 + float(ph[1])) + 0.2 * sin(u * 11.0 + float(ph[2])) + rng.randf_range(-0.12, 0.12))
				hs.append(maxf(8.0, h))
			var st_r := SurfaceTool.new()
			st_r.begin(Mesh.PRIMITIVE_TRIANGLES)
			var st_s := SurfaceTool.new()
			st_s.begin(Mesh.PRIMITIVE_TRIANGLES)
			var caps := 0
			var st_f := SurfaceTool.new()
			st_f.begin(Mesh.PRIMITIVE_TRIANGLES)
			for rep in 3:
				for j in segs:
					var z0: float = (float(rep) - 1.5) * P + float(j) * P / float(segs)
					var z1: float = z0 + P / float(segs)
					var j1: int = (j + 1) % segs
					var h0: float = hs[j]
					var h1: float = hs[j1]
					_mquad(st_r, Vector3(x, -3.0, z0), Vector3(x, -3.0, z1), Vector3(x, h1, z1), Vector3(x, h0, z0))
					var s0: float = minf(h0, snowline + 9.0 * sin(float(j) * 1.7))
					var s1: float = minf(h1, snowline + 9.0 * sin(float(j1) * 1.7))
					var f0: float = minf(h0 * 0.5, (18.0 if layer == 0 else 40.0) + 7.0 * sin(float(j) * 2.3))
					var f1: float = minf(h1 * 0.5, (18.0 if layer == 0 else 40.0) + 7.0 * sin(float(j1) * 2.3))
					var xf2: float = x - side * 3.0
					_mquad(st_f, Vector3(xf2, -3.0, z0), Vector3(xf2, -3.0, z1), Vector3(xf2, f1, z1), Vector3(xf2, f0, z0))
					if h0 > s0 + 0.5 or h1 > s1 + 0.5:
						var xs: float = x - side * 2.0
						_mquad(st_s, Vector3(xs, s0, z0), Vector3(xs, s1, z1), Vector3(xs, h1, z1), Vector3(xs, h0, z0))
						caps += 1
			var holder := Node3D.new()
			add_child(holder)
			var mats: Array = []
			for which in 3:
				if which == 1 and caps == 0:
					mats.append(null)
					continue
				var m := StandardMaterial3D.new()
				m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.disable_fog = true
				var mi := MeshInstance3D.new()
				mi.mesh = st_r.commit() if which == 0 else (st_s.commit() if which == 1 else st_f.commit())
				mi.material_override = m
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				holder.add_child(mi)
				mats.append(m)
			ranges.append({"node": holder, "P": P, "rock": mats[0], "snow": mats[1], "forest": mats[2], "haze": 0.28 if layer == 0 else 0.56})

func _build_snow() -> void:
	snow_mat = StandardMaterial3D.new()
	snow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	snow_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	snow_mat.albedo_color = Color(0.6, 0.65, 0.75)
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	q.material = snow_mat
	snow_quad = q
	for sgn: float in [-1.0, 1.0]:
		var p := CPUParticles3D.new()
		p.amount = 420
		p.lifetime = 3.0
		p.preprocess = 3.0
		p.local_coords = false
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(13.0, 5.0, 26.0)
		p.direction = Vector3(0, -1, 0)
		p.spread = 4.0
		p.gravity = Vector3.ZERO
		p.initial_velocity_min = 2.0
		p.initial_velocity_max = 3.4
		p.mesh = q
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		p.set_meta("sgn", sgn)
		add_child(p)
		snow.append(p)
	drift = Kit.particles(self, Vector3.ZERO, 22, 6.0, Color(0.85, 0.9, 1.0, 0.07), 3.6)
	drift.local_coords = false
	drift.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	drift.emission_box_extents = Vector3(24.0, 0.4, 34.0)
	drift.spread = 5.0
	drift.preprocess = 6.0
	drift_mat = drift.get_meta("mat")
	# the mist fades by growing and shrinking, not through per-particle colour
	drift_mat.vertex_color_use_as_albedo = false
	var dcv := Curve.new()
	dcv.add_point(Vector2(0.0, 0.0))
	dcv.add_point(Vector2(0.25, 1.0))
	dcv.add_point(Vector2(0.75, 1.0))
	dcv.add_point(Vector2(1.0, 0.0))
	drift.scale_amount_curve = dcv

func apply_preset(preset: int) -> void:
	sun.shadow_enabled = preset > 0
	sun.directional_shadow_max_distance = 110.0 if preset == 2 else 60.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if preset == 2 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	env.glow_enabled = preset > 0
	env.adjustment_enabled = preset > 0
	sun.shadow_blur = 1.4
	refl_on = preset > 0
	env.sky = refl_sky if refl_on else null
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY if refl_on else Environment.REFLECTION_SOURCE_BG
	refl_key = -1
	env.adjustment_contrast = 1.07
	env.adjustment_saturation = 0.9
	if drift != null:
		var dn: int = 10 if preset == 0 else 22
		if drift.amount != dn:
			drift.amount = dn
	var amt: int = [140, 420, 800][clampi(preset, 0, 2)]
	for p: CPUParticles3D in snow:
		if p.amount != amt:
			p.amount = amt
	for h: Node3D in forest_l + forest_r:
		var a: MultiMeshInstance3D = h.get_child(0)
		a.multimesh.visible_instance_count = 60 if preset == 0 else -1
		for ch: Node in h.get_children():
			if ch.has_meta("low"):
				var cm2: MultiMeshInstance3D = ch
				cm2.multimesh.visible_instance_count = int(ch.get_meta("low")) if preset == 0 else -1

# ---------------- per-frame ----------------
func update(dt: float, focus: Vector3) -> void:
	t += dt
	var s: float = GS.train["s"]
	var v: float = GS.train["speed"]
	track.position.z = fposmod(s, 40.0)
	for rg2: Dictionary in ranges:
		var rn: Node3D = rg2["node"]
		var rp: float = rg2["P"]
		rn.position.z = fposmod(s, rp) - rp * 0.5
	ground.position.z = fposmod(s, 4.0)
	var k0: int = int(round(s / GS.SP))
	var coastal := false
	var smod: float = fposmod(s, GS.SP * float(GS.NLOC))
	if smod > 7.0 * GS.SP - 520.0 and smod < 8.0 * GS.SP + 520.0:
		coastal = true
	for k: int in [k0 - 1, k0, k0 + 1]:
		var d: float = absf(float(k) * GS.SP - s)
		var idx: int = posmod(k, GS.NLOC)
		if d < 540.0 and k >= 0:
			if not locs.has(k):
				locs[k] = _build_loc(k)
			if (idx == 7 or idx == 8) and d < 520.0:
				coastal = true
		elif locs.has(k) and d > 700.0:
			var old: Node3D = locs[k]
			old.queue_free()
			locs.erase(k)
	for k: int in locs.keys():
		var n: Node3D = locs[k]
		n.position.z = s - float(k) * GS.SP
		if absf(float(k) * GS.SP - s) > 760.0:
			n.queue_free()
			locs.erase(k)
	var fz: float = fposmod(s, 400.0)
	for h: Node3D in forest_l:
		var hk: int = h.get_meta("k")
		h.position.z = fz + 400.0 * float(hk) - 600.0
		h.visible = not coastal and dbg_forest
	for h: Node3D in forest_r:
		var hk: int = h.get_meta("k")
		h.position.z = fz + 400.0 * float(hk) - 600.0
	_update_env(dt, false)
	# snow
	var wind: float = 0.0
	var fall: float = 2.6
	var on: bool = GS.weather != "clear"
	if GS.weather == "blizzard":
		wind = 9.0
		fall = 4.5
	var sleet: bool = GS.weather == "sleet"
	if sleet:
		wind = 2.5
		fall = 13.0
	snow_quad.size = Vector2(0.012, 0.32) if sleet else Vector2(0.05, 0.05)
	var keep_t: Array = []
	for tn: Variant in tunnels:
		if is_instance_valid(tn):
			keep_t.append(tn)
			var tnode: Node3D = tn
			if absf(tnode.global_position.z - focus.z) < 77.0 and focus.x > -9.2 and focus.x < 4.2:
				on = false
	tunnels = keep_t
	var sw: float = 0.6
	if GS.weather == "snow" or sleet:
		sw = 1.3
	elif GS.weather == "blizzard":
		sw = 2.8
	for tmv: ShaderMaterial in tree_mats:
		tmv.set_shader_parameter("sway", sw)
	var vel := Vector3(0, -fall, v + wind)
	var dv := Vector3(0.9 + wind * 0.35, 0.03, v * 0.92)
	drift.emitting = on or GS.weather == "clear"
	drift.visible = (on or GS.weather == "clear") and dbg_drift and not main.aboard and focus.y < 1.0
	drift.position = Vector3(focus.x - dv.x * 3.0, 0.1, focus.z - dv.z * 3.0)
	drift.direction = dv.normalized()
	drift.initial_velocity_min = dv.length() * 0.85
	drift.initial_velocity_max = dv.length() * 1.15
	var mistc: Color = Color(0.85, 0.9, 1.0) * (0.22 + 0.78 * daylight)
	drift_mat.albedo_color = Color(mistc.r, mistc.g, mistc.b, minf(0.9, (0.035 if GS.weather == "clear" else 0.07) * mist_amp))
	for p: CPUParticles3D in snow:
		var sg: float = p.get_meta("sgn")
		var cx: float = sg * 15.7
		if sg > 0.0:
			cx += maxf(0.0, focus.x - 13.0)
		else:
			cx += minf(0.0, focus.x + 13.0)
		p.emitting = on
		p.position = Vector3(cx, focus.y + 4.5, focus.z - vel.z * 1.5)
		p.direction = vel.normalized()
		p.initial_velocity_min = vel.length() * 0.8
		p.initial_velocity_max = vel.length() * 1.2
		p.emission_box_extents = Vector3(13.0, 5.0, 26.0 if GS.weather != "blizzard" else 16.0)
	snow_mat.albedo_color = Color(0.42, 0.47, 0.58).lerp(Color(0.92, 0.94, 0.98), daylight)
	if sleet:
		snow_mat.albedo_color = Color(0.36, 0.4, 0.48).lerp(Color(0.62, 0.66, 0.72), daylight)
	# living things in the world
	var keep: Array = []
	for c: Variant in civils:
		if is_instance_valid(c):
			var hmn: Humanoid = c
			var wt: float = float(hmn.get_meta("wave_t", 0.0))
			if wt > 0.0:
				hmn.set_meta("wave_t", wt - dt)
				hmn.pose = "wave"
			elif hmn.has_meta("camp") and v > 1.0 and absf(hmn.global_position.z - focus.z) < 60.0:
				hmn.pose = "wave"
			else:
				hmn.pose = str(hmn.get_meta("pose0", hmn.pose))
			hmn.animate(dt)
			keep.append(c)
	civils = keep
	var keep2: Array = []
	for sp: Variant in spinners:
		if is_instance_valid(sp):
			var spn: Node3D = sp
			spn.rotate_y(dt * 0.5)
			keep2.append(sp)
	spinners = keep2
	var keep3: Array = []
	for fl: Variant in flickers:
		if is_instance_valid(fl):
			var l: OmniLight3D = fl
			var be: float = l.get_meta("e")
			l.light_energy = be * (0.75 + 0.25 * sin(t * 11.0 + be * 7.0) * sin(t * 3.7))
			keep3.append(fl)
	flickers = keep3
	_stream_scenery(s, v)
	_animate_world(dt, focus, v)

func _update_env(dt: float, force: bool) -> void:
	if env_freeze:
		return
	sky_t -= dt
	var tod: float = fposmod(GS.time, 1440.0) / 1440.0
	var sv: float = sin((tod - 0.25) * TAU)
	var d: float = smoothstep(-0.12, 0.3, sv)
	daylight = d
	var wx: float = 0.0
	var fd: float = 0.0045
	if GS.weather == "snow":
		wx = 0.55
		fd = 0.011
	elif GS.weather == "blizzard":
		wx = 1.0
		fd = 0.04
	elif GS.weather == "sleet":
		wx = 0.78
		fd = 0.016
	fog_d = lerpf(fog_d, fd, clampf(dt * 0.4, 0.0, 1.0))
	env.fog_density = fog_d
	if sky_t > 0.0 and not force:
		return
	sky_t = 2.5
	var dusk: float = clampf(1.0 - absf(sv) / 0.28, 0.0, 1.0)
	var top: Color = Color(0.012, 0.018, 0.04).lerp(Color(0.26, 0.4, 0.6), d)
	var hor: Color = Color(0.075, 0.095, 0.14).lerp(Color(0.66, 0.72, 0.78), d)
	hor = hor.lerp(Color(0.78, 0.46, 0.3), dusk * 0.55 * (1.0 - wx * 0.7))
	top = top.lerp(hor, wx * 0.65)
	env.background_color = hor
	if dome_grad != null:
		dome_grad.set_color(0, top)
		dome_grad.set_color(1, top.lerp(hor, 0.45))
		dome_grad.set_color(2, hor)
		dome_grad.set_color(3, hor)
		dome_grad.set_color(4, hor * 0.6)
	env.fog_light_color = hor
	if refl_on:
		var rk: int = int(round(d * 5.0)) * 10 + int(round(wx * 2.0))
		if rk != refl_key:
			refl_key = rk
			var gnd: Color = hor * 0.55 + Color(0.02, 0.02, 0.025)
			for ry in 32:
				var rv: float = float(ry) / 31.0
				var rc: Color = top.lerp(hor, smoothstep(0.05, 0.5, rv)) if rv < 0.5 else hor.lerp(gnd, smoothstep(0.5, 0.6, rv))
				for rx in 64:
					refl_img.set_pixel(rx, ry, rc)
			refl_tex.update(refl_img)
	for rg: Dictionary in ranges:
		var hz: float = clampf(float(rg["haze"]) + wx * 0.5, 0.0, 1.0)
		var rockc: Color = Color(0.17, 0.2, 0.27) * (0.18 + 0.82 * d)
		var capc: Color = Color(0.7, 0.75, 0.84) * (0.17 + 0.83 * d)
		var fm: StandardMaterial3D = rg["forest"]
		fm.albedo_color = (Color(0.07, 0.1, 0.1) * (0.2 + 0.8 * d)).lerp(hor, hz * 0.85)
		var rm: StandardMaterial3D = rg["rock"]
		rm.albedo_color = rockc.lerp(hor, hz)
		if rg["snow"] != null:
			var cm: StandardMaterial3D = rg["snow"]
			cm.albedo_color = capc.lerp(hor, hz)
	env.ambient_light_color = Color(0.2, 0.25, 0.38).lerp(Color(0.62, 0.66, 0.72), d)
	env.ambient_light_energy = lerpf(0.75, 1.0, d)
	if sv > -0.05:
		var elev: float = 0.12 + asin(clampf(sv, 0.0, 1.0)) * 0.75
		sun.rotation = Vector3(-elev, (tod - 0.5) * PI + 0.6, 0)
		sun.light_energy = d * 1.2 * (1.0 - 0.55 * wx)
		sun.light_color = Color(1.0, 0.72, 0.5).lerp(Color(1.0, 0.96, 0.9), smoothstep(0.0, 0.5, sv))
	else:
		sun.basis = Basis.looking_at(-MOON_DIR.normalized(), Vector3.UP)
		sun.light_energy = 0.42 * smoothstep(-0.05, -0.2, sv) * (1.0 - 0.45 * wx)
		sun.light_color = Color(0.56, 0.66, 0.95)
	fill.light_energy = lerpf(0.12, 0.3, d)
	if sun_disc != null:
		sun_disc.visible = sv > -0.05 and wx < 0.95
		sun_disc.position = sun.basis.z.normalized() * 690.0
		var sc: Color = sun.light_color
		sun_disc_mat.albedo_color = Color(sc.r, sc.g, sc.b, clampf(d * 1.4, 0.0, 1.0) * (1.0 - 0.8 * wx))
	night = 1.0 - d
	clear_f = 1.0 - wx
	if star_mat != null:
		star_mat.albedo_color.a = night * clear_f * clear_f
		moon_mat.albedo_color.a = night * (1.0 - 0.75 * wx)
		for am: StandardMaterial3D in aurora_mats:
			am.albedo_color.a = night * pow(clear_f, 1.5) * 0.55
		sky_root.visible = night > 0.02 and dbg_sky

# ---------------- location kit ----------------
func _bld(mb: Kit, body: Node, c: Vector3, size: Vector3, wall: String, lit: float, rng: RandomNumberGenerator, gable: bool = false) -> void:
	var base: float = -0.25
	mb.sbox(body, wall, Vector3(c.x, base + size.y * 0.5, c.z), size)
	if gable:
		var run: float = size.x * 0.5 + 0.4
		var rise: float = run * 0.45
		var sl: float = sqrt(run * run + rise * rise)
		var ang: float = atan2(rise, run)
		for sgn: float in [-1.0, 1.0]:
			var rb := Basis(Vector3.BACK, -sgn * ang)
			mb.box("roof", Vector3(c.x + sgn * run * 0.5, base + size.y + rise * 0.5, c.z), Vector3(sl, 0.14, size.z + 0.8), rb)
			mb.box("snow", Vector3(c.x + sgn * run * 0.5, base + size.y + rise * 0.5 + 0.1, c.z), Vector3(sl * 0.92, 0.07, size.z + 0.6), rb)
		mb.box(wall, Vector3(c.x, base + size.y + rise * 0.35, c.z), Vector3(size.x * 0.55, rise * 0.7, size.z))
	else:
		mb.box("concrete", Vector3(c.x, base + size.y + 0.1, c.z), Vector3(size.x + 0.5, 0.2, size.z + 0.5))
		mb.box("snow", Vector3(c.x, base + size.y + 0.24, c.z), Vector3(size.x + 0.2, 0.1, size.z + 0.2))
	# variation: rooftop plant and aerials, a door, a downpipe, a lean-to
	if not gable:
		for i in rng.randi() % 3:
			mb.box("steel_dk", Vector3(c.x + rng.randf_range(-0.3, 0.3) * size.x, base + size.y + 0.65, c.z + rng.randf_range(-0.3, 0.3) * size.z), Vector3(1.5, 0.9, 1.1))
		if rng.randf() < 0.6:
			mb.cyl("steel_dk", Vector3(c.x + 0.3 * size.x, base + size.y + 2.4, c.z - 0.3 * size.z), 0.05, 4.4, 1, 5)
			mb.box("steel_dk", Vector3(c.x + 0.3 * size.x, base + size.y + 4.0, c.z - 0.3 * size.z), Vector3(0.9, 0.04, 0.04))
	var dz0: float = c.z + rng.randf_range(-0.3, 0.3) * size.z
	mb.box("wood", Vector3(c.x - size.x * 0.5 - 0.04, base + 1.05, dz0), Vector3(0.08, 2.1, 1.1))
	mb.box("steel_dk", Vector3(c.x - size.x * 0.5 - 0.3, base + 2.3, dz0), Vector3(0.6, 0.06, 1.5), Basis(Vector3.BACK, 0.2))
	mb.cyl("steel_dk", Vector3(c.x - size.x * 0.5 - 0.09, base + size.y * 0.5, c.z + size.z * 0.5 - 0.35), 0.06, size.y, 1, 6)
	if rng.randf() < 0.4:
		mb.box("corr", Vector3(c.x - size.x * 0.5 - 1.0, base + 1.1, c.z - size.z * 0.5 + 1.6), Vector3(2.0, 2.2, 3.0))
		mb.box("snow", Vector3(c.x - size.x * 0.5 - 1.0, base + 2.24, c.z - size.z * 0.5 + 1.6), Vector3(2.1, 0.08, 3.1))
	if rng.randf() < 0.5:
		mb.box("rust", Vector3(c.x - size.x * 0.5 - 0.02, base + size.y * 0.75, c.z + rng.randf_range(-0.3, 0.3) * size.z), Vector3(0.03, size.y * 0.4, 0.5))
	if wall == "facade":
		# tower blocks: piers, balconies with railings and washing, lift house, water tank, mast
		var ff: float = -1.0 if c.x >= 0.0 else 1.0
		var fx: float = c.x + ff * size.x * 0.5
		var bays: int = maxi(2, int(size.z / 4.5))
		var bwd: float = size.z / float(bays)
		for b in bays + 1:
			mb.box("concrete", Vector3(fx + ff * 0.14, base + size.y * 0.5, c.z - size.z * 0.5 + float(b) * bwd), Vector3(0.3, size.y, 0.36))
		var fl: int = int(size.y / 3.0)
		for r in range(1, fl, 2):
			for b in bays:
				if rng.randf() < 0.2:
					continue
				var bz: float = c.z - size.z * 0.5 + (float(b) + 0.5) * bwd
				mb.box("concrete", Vector3(fx + ff * 0.6, base + float(r) * 3.0, bz), Vector3(1.2, 0.14, bwd - 0.7))
				mb.box("steel_dk", Vector3(fx + ff * 1.18, base + float(r) * 3.0 + 0.55, bz), Vector3(0.04, 1.0, bwd - 0.7))
				if rng.randf() < 0.3:
					mb.box("mattress", Vector3(fx + ff * 1.2, base + float(r) * 3.0 + 0.3, bz + 0.4), Vector3(0.03, 0.9, 0.8))
		mb.box("concrete", Vector3(c.x, base + size.y + 1.4, c.z + size.z * 0.2), Vector3(3.6, 2.6, 4.0))
		mb.cyl("rust", Vector3(c.x - 2.5, base + size.y + 1.3, c.z - size.z * 0.25), 1.2, 2.2, 1, 10)
		mb.cyl("steel_dk", Vector3(c.x + 2.0, base + size.y + 3.5, c.z - size.z * 0.3), 0.06, 6.0, 1, 5)
		return
	var f: float = -1.0 if c.x >= 0.0 else 1.0
	var x: float = c.x + f * (size.x * 0.5 + 0.03)
	var rows: int = int((size.y - 1.2) / 3.0)
	var cols: int = maxi(1, int(size.z / 3.0))
	mb.box("concrete", Vector3(c.x + f * (size.x * 0.5 + 0.06), base + 0.35, c.z), Vector3(0.14, 0.7, size.z + 0.1))
	for r in rows:
		if r > 0:
			mb.box("concrete", Vector3(c.x + f * (size.x * 0.5 + 0.04), base + 0.55 + float(r) * 3.0, c.z), Vector3(0.1, 0.12, size.z + 0.06))
		for q in cols:
			var wz: float = c.z - size.z * 0.5 + (float(q) + 0.5) * size.z / float(cols)
			var wy: float = base + 2.0 + float(r) * 3.0
			var litw: bool = rng.randf() < lit
			var fate: float = rng.randf()
			mb.box("win_lit" if litw else "glass_dark", Vector3(x, wy, wz), Vector3(0.06, 1.3, 1.3))
			mb.box("concrete", Vector3(x + f * 0.02, wy - 0.7, wz), Vector3(0.12, 0.08, 1.5))
			mb.box("concrete", Vector3(x + f * 0.01, wy + 0.72, wz), Vector3(0.1, 0.1, 1.46))
			mb.box("hull_blk", Vector3(x + f * 0.035, wy, wz), Vector3(0.03, 1.3, 0.05))
			mb.box("hull_blk", Vector3(x + f * 0.035, wy + 0.15, wz), Vector3(0.03, 0.05, 1.3))
			if not litw and fate < 0.22:
				mb.box("wood", Vector3(x + f * 0.06, wy + 0.2, wz), Vector3(0.03, 0.24, 1.5), Basis(Vector3.RIGHT, 0.12))
				mb.box("wood", Vector3(x + f * 0.06, wy - 0.25, wz), Vector3(0.03, 0.24, 1.5), Basis(Vector3.RIGHT, -0.08))
			elif not litw and fate < 0.34:
				mb.box("mattress", Vector3(x + f * 0.05, wy - 0.2, wz + 0.2), Vector3(0.02, 0.8, 0.7), Basis(Vector3.RIGHT, 0.06))
	mb.box("concrete", Vector3(c.x + f * (size.x * 0.5 + 0.08), base + size.y - 0.15, c.z), Vector3(0.18, 0.3, size.z + 0.2))

func _room(mb: Kit, body: Node, n: Node3D, c: Vector3, size: Vector3, wall: String, lit: float) -> void:
	var base: float = -0.25
	var w: float = size.x
	var h: float = size.y
	var d: float = size.z
	var th: float = 0.25
	mb.box("concrete", Vector3(c.x, base + 0.005, c.z), Vector3(w, 0.03, d))
	mb.sbox(body, wall, Vector3(c.x + w * 0.5 - th * 0.5, base + h * 0.5, c.z), Vector3(th, h, d))
	mb.sbox(body, wall, Vector3(c.x, base + h * 0.5, c.z - d * 0.5 + th * 0.5), Vector3(w, h, th))
	mb.sbox(body, wall, Vector3(c.x, base + h * 0.5, c.z + d * 0.5 - th * 0.5), Vector3(w, h, th))
	var seg: float = (d - 1.4) * 0.5
	var fx: float = c.x - w * 0.5 + th * 0.5
	mb.sbox(body, wall, Vector3(fx, base + h * 0.5, c.z - 0.7 - seg * 0.5), Vector3(th, h, seg))
	mb.sbox(body, wall, Vector3(fx, base + h * 0.5, c.z + 0.7 + seg * 0.5), Vector3(th, h, seg))
	mb.sbox(body, wall, Vector3(fx, base + 2.3 + (h - 2.3) * 0.5, c.z), Vector3(th, h - 2.3, 1.4))
	for sgn: float in [-1.0, 1.0]:
		mb.box("win_lit" if lit > 0.3 else "glass_dark", Vector3(fx - 0.13, base + 1.8, c.z + sgn * (0.7 + seg * 0.5)), Vector3(0.04, 1.1, minf(1.6, seg * 0.6)))
	mb.sbox(body, "concrete", Vector3(c.x, base + h + 0.1, c.z), Vector3(w + 0.6, 0.2, d + 0.6))
	mb.box("snow", Vector3(c.x, base + h + 0.25, c.z), Vector3(w + 0.3, 0.1, d + 0.3))
	if lit > 0.0:
		var l: OmniLight3D = Kit.omni(n, Vector3(c.x, base + h - 0.5, c.z), Color(1.0, 0.8, 0.55), 1.3 * lit, maxf(w, d) * 0.9)
		l.set_meta("e", 1.3 * lit)
		if lit < 0.9:
			flickers.append(l)
		mb.box("lamp_warm", Vector3(c.x, base + h - 0.12, c.z), Vector3(0.2, 0.08, 0.2))

func _loot(mb: Kit, body: Node, n: Node3D, k: int, id: int, pos: Vector3, style: int = 0) -> void:
	var top: float = 0.6
	var nm := "supply crate"
	match style:
		0:
			var cr: Node3D = Kit.prop("crate", Vector3(0.98, 0.62, 0.72))
			if cr != null:
				cr.position = pos
				cr.rotation.y = fmod(absf(pos.x * 7.3 + pos.z * 3.1), 0.5) - 0.25
				n.add_child(cr)
				Kit.col(body, pos + Vector3(0, 0.19, 0), Vector3(0.95, 0.38, 0.7))
				top = 0.38
			else:
				mb.sbox(body, "wood", pos + Vector3(0, 0.3, 0), Vector3(0.9, 0.6, 0.6))
				mb.box("steel_dk", pos + Vector3(-0.28, 0.3, 0), Vector3(0.05, 0.62, 0.62))
				mb.box("steel_dk", pos + Vector3(0.28, 0.3, 0), Vector3(0.05, 0.62, 0.62))
		1:
			mb.sbox(body, "panel_dk", pos + Vector3(0, 0.9, 0), Vector3(0.5, 1.8, 0.8))
			mb.box("steel", pos + Vector3(-0.26, 1.0, 0.2), Vector3(0.02, 0.16, 0.03))
			top = 1.8
			nm = "locker"
		2:
			var br: Node3D = Kit.prop("barrel", Vector3(0.62, 0.92, 0.62))
			if br != null:
				br.position = pos
				br.rotation.y = fmod(absf(pos.x * 5.1 + pos.z * 2.3), TAU)
				n.add_child(br)
			else:
				mb.cyl("hull", pos + Vector3(0, 0.45, 0), 0.3, 0.9, 1, 12)
				mb.cyl("steel_dk", pos + Vector3(0, 0.9, 0), 0.31, 0.03, 1, 12)
			Kit.col(body, pos + Vector3(0, 0.45, 0), Vector3(0.6, 0.9, 0.6))
			top = 0.92
			nm = "drum"
		3:
			mb.box("sack", pos + Vector3(0, 0.18, 0), Vector3(0.85, 0.36, 0.42))
			mb.box("seat_dk", pos + Vector3(0, 0.37, 0), Vector3(0.5, 0.03, 0.06))
			top = 0.36
			nm = "abandoned bag"
	var key := "%d:%d" % [k, id]
	if GS.looted.has(key):
		return
	var tag := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.1, 0.1, 0.1)
	tag.mesh = bm
	tag.material_override = Kit.mats["tag"]
	tag.position = pos + Vector3(0, top + 0.1, 0)
	tag.rotation = Vector3(0.6, 0.6, 0)
	n.add_child(tag)
	var a: Area3D = Kit.interact(n, pos + Vector3(0, top * 0.5 + 0.2, 0), Vector3(1.1, top + 0.6, 1.1), "Search " + nm, Callable())
	a.set_meta("cb", main.act.bind("loot", {"key": key, "area": a, "tag": tag, "idx": posmod(k, GS.NLOC)}))

const WCASES := [["morrow", Vector3(20.6, -0.25, 28.4)], ["stryk", Vector3(29.4, -0.25, 36.2)], ["kestrel", Vector3(18.6, -0.25, 16.4)], ["tundra", Vector3(15.3, -0.25, 84.4)], ["harrow", Vector3(19.4, -0.25, 38.6)], ["sable", Vector3(9.4, -0.25, 37.0)], ["bastion", Vector3(20.4, -0.25, 31.0)], ["northwind", Vector3(16.8, -0.25, 72.4)], ["arclight", Vector3(16.0, -0.25, 134.4)], []]

## A hard weapon case on a steel trestle. Opening it grants the weapon and two magazines.
func _weapon_case(mb: Kit, body: Node, n: Node3D, k: int, id: int, pos: Vector3, wid: String) -> void:
	var W: Dictionary = Arsenal.DEFS[wid]
	mb.sbox(body, "steel_dk", pos + Vector3(0, 0.3, 0), Vector3(0.5, 0.6, 1.2))
	mb.box("gun_olive", pos + Vector3(0, 0.66, 0), Vector3(0.44, 0.12, 1.12))
	mb.box("gun_grip", pos + Vector3(0, 0.722, 0), Vector3(0.4, 0.004, 1.06))
	for z: float in [-0.5, 0.5]:
		mb.box("gun_poly", pos + Vector3(0, 0.66, z), Vector3(0.46, 0.13, 0.03))
	var key := "%d:%d" % [k, id]
	var lid := Node3D.new()
	lid.position = pos + Vector3(0.22, 0.724, 0)
	n.add_child(lid)
	var lk := Kit.new()
	lk.box("gun_olive", Vector3(-0.22, 0.03, 0), Vector3(0.44, 0.06, 1.12))
	for i in 5:
		lk.box("gun_poly", Vector3(-0.22, 0.062, -0.4 + float(i) * 0.2), Vector3(0.4, 0.006, 0.03))
	for z2: float in [-0.36, 0.36]:
		lk.box("steel", Vector3(-0.445, 0.0, z2), Vector3(0.012, 0.05, 0.06))
	lk.box("gun_poly", Vector3(-0.46, 0.0, 0), Vector3(0.03, 0.03, 0.18))
	lk.commit(lid, false)
	var lb: Label3D = Kit.text3d(lid, Vector3(-0.22, 0.067, 0.3), str(W["name"]), 44, Color(0.92, 0.86, 0.6), PI * 0.5, 0.004)
	lb.rotation.x = -PI * 0.5
	if GS.looted.has(key):
		lid.rotation.z = -1.9
		return
	var tag := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.1, 0.1, 0.1)
	tag.mesh = bm
	tag.material_override = Kit.mats["tag"]
	tag.position = Vector3(-0.22, 0.2, -0.4)
	tag.rotation = Vector3(0.6, 0.6, 0)
	lid.add_child(tag)
	var a: Area3D = Kit.interact(n, pos + Vector3(0, 0.7, 0), Vector3(0.8, 0.9, 1.3), "Open weapon case: %s  (%s)" % [W["name"], W["cat"]], Callable())
	a.set_meta("cb", main.act.bind("weapon", {"key": key, "area": a, "wid": wid, "lid": lid}))

func _lamp_post(mb: Kit, n: Node3D, pos: Vector3, on: bool, flick: bool = false) -> void:
	mb.cyl("steel_dk", pos + Vector3(0, 2.2, 0), 0.06, 4.4, 1, 6)
	mb.box("steel_dk", pos + Vector3(-0.5, 4.35, 0), Vector3(1.1, 0.06, 0.08))
	mb.box("lamp_warm" if on else "glass_dark", pos + Vector3(-0.95, 4.28, 0), Vector3(0.4, 0.08, 0.2))
	post_n += 1
	if on and (int(GS.settings["preset"]) > 0 or post_n % 2 == 0):
		var l: OmniLight3D = Kit.omni(n, pos + Vector3(-1.0, 3.9, 0), Color(1.0, 0.76, 0.48), 2.4, 11.0)
		l.set_meta("e", 2.2)
		if flick:
			flickers.append(l)

func _car(n: Node3D, body: Node, mb: Kit, file: String, pos: Vector3, yaw: float) -> void:
	var ps: PackedScene = load("res://assets/models/%s.glb" % file)
	if ps == null:
		return
	var c: Node3D = ps.instantiate()
	c.position = pos
	c.rotation.y = yaw
	c.scale = Vector3(1.75, 1.75, 1.75)
	n.add_child(c)
	# two winters outdoors: paint faded and dulled, nothing left that shines
	for mn: Node in c.find_children("*", "MeshInstance3D", true, false):
		var cmi: MeshInstance3D = mn
		for si in cmi.get_surface_override_material_count():
			var src: Material = cmi.get_active_material(si)
			if src is BaseMaterial3D:
				if not car_mats.has(src):
					var wm: BaseMaterial3D = src.duplicate()
					var ac: Color = wm.albedo_color
					var lum: float = ac.r * 0.3 + ac.g * 0.59 + ac.b * 0.11
					wm.albedo_color = ac.lerp(Color(lum, lum, lum), 0.5) * 0.6 + Color(0.03, 0.025, 0.02)
					wm.roughness = 0.92
					wm.metallic = 0.0
					car_mats[src] = wm
				cmi.set_surface_override_material(si, car_mats[src])
	var b := Basis(Vector3.UP, yaw)
	if body != null:
		Kit.col(body, pos + Vector3(0, 0.8, 0), Vector3(2.0, 1.6, 4.4), b)
	mb.box("snow", pos + Vector3(0, 1.62 if file != "firetruck" else 2.4, 0), Vector3(1.5, 0.08, 2.0), b)

func _person(n: Node3D, pos: Vector3, yaw: float, seed_i: int, pose: String) -> Humanoid:
	var h := Humanoid.new()
	n.add_child(h)
	h.setup(seed_i, "survivor")
	h.position = pos
	h.rotation.y = yaw
	h.pose = pose
	h.set_meta("pose0", pose)
	civils.append(h)
	return h

func _recruit(n: Node3D, pos: Vector3, yaw: float, rname: String, job: String, key: String) -> void:
	if GS.recruited.has(key):
		return
	var h: Humanoid = _person(n, pos, yaw, rname.hash() % 1000, "talk")
	var a: Area3D = Kit.interact(h, Vector3(0, 1.0, 0), Vector3(0.8, 1.9, 0.8), "Speak to %s (%s) - offer a place aboard" % [rname, job], Callable())
	a.set_meta("cb", main.act.bind("recruit", {"name": rname, "job": job, "node": h, "key": key}))

func _hostile(n: Node3D, kind: String, pos: Vector3, seed_i: int, lap: int) -> void:
	var h := Hostile.new()
	n.add_child(h)
	h.position = pos
	h.home = pos
	h.rotation.y = randf() * TAU
	h.setup(main, kind, seed_i, lap)

func _container(mb: Kit, body: Node, pos: Vector3, mat: String, yaw: float = 0.0) -> void:
	var b := Basis(Vector3.UP, yaw)
	mb.sbox(body, mat, pos + Vector3(0, 1.3, 0), Vector3(2.44, 2.6, 6.06), b)
	mb.box("snow", pos + Vector3(0, 2.63, 0), Vector3(2.3, 0.06, 5.9), b)

func _tent(mb: Kit, body: Node, pos: Vector3) -> void:
	for sgn: float in [-1.0, 1.0]:
		mb.box("canvas", pos + Vector3(sgn * 0.75, 0.95, 0), Vector3(2.5, 0.05, 3.4), Basis(Vector3.BACK, -sgn * 0.95))
	mb.box("snow", pos + Vector3(0, 1.98, 0), Vector3(0.5, 0.06, 3.3))
	Kit.col(body, pos + Vector3(0, 0.8, 0), Vector3(2.4, 1.6, 3.2))

func _fire(mb: Kit, body: Node, n: Node3D, pos: Vector3) -> void:
	mb.cyl("rust", pos + Vector3(0, 0.45, 0), 0.3, 0.9, 1, 10)
	mb.cyl("fire", pos + Vector3(0, 0.95, 0), 0.24, 0.12, 1, 8, 0.05)
	Kit.col(body, pos + Vector3(0, 0.45, 0), Vector3(0.6, 0.9, 0.6))
	var l: OmniLight3D = Kit.omni(n, pos + Vector3(0, 1.5, 0), Color(1.0, 0.55, 0.2), 2.4, 9.0)
	l.set_meta("e", 2.4)
	flickers.append(l)
	var fl: CPUParticles3D = Kit.particles(n, pos + Vector3(0, 1.0, 0), 12, 0.7, Color(1.0, 0.5, 0.12, 0.9), 0.55, true)
	fl.spread = 14.0
	fl.initial_velocity_min = 1.2
	fl.initial_velocity_max = 2.2
	var sp: CPUParticles3D = Kit.particles(n, pos + Vector3(0, 1.1, 0), 7, 1.7, Color(1.0, 0.7, 0.3, 1.0), 0.07, true)
	sp.spread = 28.0
	sp.initial_velocity_min = 1.6
	sp.initial_velocity_max = 3.2
	_smoke(n, pos + Vector3(0, 1.6, 0), 1.3, 8)

func _smoke(n: Node3D, pos: Vector3, psize: float, amount: int = 12) -> void:
	var sm3: CPUParticles3D = Kit.particles(n, pos, amount, 6.0, Color(0.32, 0.33, 0.36, 0.3), psize)
	sm3.spread = 12.0
	sm3.direction = Vector3(0.25, 1.0, 0.3).normalized()
	sm3.initial_velocity_min = psize * 0.5
	sm3.initial_velocity_max = psize * 0.9
	sm3.gravity = Vector3(0.25, 0.05, 0.4)

func _signal(mb: Kit, pos: Vector3) -> void:
	mb.cyl("steel_dk", pos + Vector3(0, 2.6, 0), 0.07, 5.4, 1, 6)
	mb.box("concrete", pos + Vector3(0, 0.0, 0), Vector3(0.5, 0.5, 0.5))
	mb.box("hull_blk", pos + Vector3(0, 5.0, 0.06), Vector3(0.42, 1.1, 0.2))
	mb.box("hull_blk", pos + Vector3(0, 5.62, 0.2), Vector3(0.46, 0.05, 0.3))
	mb.cyl("sig_r", pos + Vector3(0, 5.25, 0.17), 0.11, 0.04, 2, 10)
	mb.cyl("sig_g", pos + Vector3(0, 4.78, 0.17), 0.11, 0.04, 2, 10)
	for i in 8:
		mb.box("steel_dk", pos + Vector3(0.14, 0.6 + float(i) * 0.5, -0.12), Vector3(0.3, 0.03, 0.03))
	mb.box("steel_dk", pos + Vector3(0.28, 2.5, -0.12), Vector3(0.03, 4.4, 0.03))

func _platform_extras(mb: Kit, body: Node, n: Node3D, lit: int) -> void:
	# rear railing, open at the three ramps
	var z: float = -20.0
	while z < 200.0:
		var mid: float = z + 2.0
		var open := false
		for g: float in [10.0, 62.0, 120.0]:
			if absf(mid - g) < 2.2:
				open = true
		if not open:
			mb.box("steel_dk", Vector3(7.52, 1.8, z), Vector3(0.06, 1.1, 0.06))
			mb.box("steel_dk", Vector3(7.52, 2.32, mid), Vector3(0.05, 0.05, 4.0))
			mb.box("steel_dk", Vector3(7.52, 1.82, mid), Vector3(0.03, 0.03, 4.0))
			Kit.col(body, Vector3(7.52, 1.8, mid), Vector3(0.12, 1.1, 4.0))
		z += 4.0
	var poster: Array = ["red", "hull", "amber_paint", "white_paint", "corr_blue"]
	for i in 5:
		var fz: float = 4.0 + float(i) * 40.0
		mb.cyl("steel_dk", Vector3(7.05, 1.7, fz), 0.24, 0.9, 1, 10)
		mb.cyl("snow", Vector3(7.05, 2.18, fz), 0.25, 0.08, 1, 10, 0.1)
		Kit.col(body, Vector3(7.05, 1.7, fz), Vector3(0.48, 0.9, 0.48))
		mb.box("hull_blk", Vector3(7.44, 2.6, fz + 6.0), Vector3(0.06, 1.5, 1.14))
		mb.box(poster[i], Vector3(7.4, 2.7, fz + 6.0), Vector3(0.02, 1.0, 0.94))
		mb.box("white_paint", Vector3(7.395, 2.15, fz + 6.0), Vector3(0.02, 0.22, 0.94))
		mb.cyl("snow", Vector3(6.4, 1.38, fz + 15.0), 1.0, 0.42, 1, 7, 0.25)
		mb.cyl("snow", Vector3(3.2, 1.33, fz + 27.0), 0.7, 0.26, 1, 6, 0.2)
		mb.box("sack" if i % 2 == 0 else "seat_dk", Vector3(6.3, 1.43, fz + 9.0), Vector3(0.6, 0.36, 0.3), Basis(Vector3.UP, float(i) * 1.3))
	for i in 8:
		var pr: float = 0.34 + 0.12 * float((i * 5) % 4)
		mb.cyl("wetice", Vector3(2.9 + float((i * 7) % 9) * 0.42, 1.2535, -12.0 + float(i) * 26.0 + float(i % 3) * 3.0), pr, 0.004, 1, 16)
		mb.cyl("wetice", Vector3(3.4 + float((i * 3) % 7) * 0.4, 1.2535, -11.0 + float(i) * 26.0 + float(i % 3) * 3.0), pr * 0.6, 0.004, 1, 12)
	# vending and ticket machines
	mb.sbox(body, "hull", Vector3(7.02, 2.2, 19.5), Vector3(0.7, 1.9, 0.9))
	mb.box("screen" if lit > 1 else "glass_dark", Vector3(6.66, 2.5, 19.5), Vector3(0.02, 0.9, 0.7))
	mb.box("hull_blk", Vector3(6.66, 1.75, 19.5), Vector3(0.02, 0.3, 0.6))
	mb.sbox(body, "amber_paint", Vector3(7.12, 1.95, 21.0), Vector3(0.45, 1.4, 0.5))
	mb.box("screen" if lit > 1 else "glass_dark", Vector3(6.89, 2.25, 21.0), Vector3(0.02, 0.3, 0.34))
	# hanging departure board and clock
	mb.cyl("steel_dk", Vector3(7.0, 2.9, 30.0), 0.05, 3.3, 1, 6)
	mb.box("steel_dk", Vector3(5.75, 4.5, 30.0), Vector3(2.6, 0.06, 0.06))
	mb.box("hull_blk", Vector3(4.9, 4.05, 30.0), Vector3(1.9, 0.8, 0.14))
	for sgn: float in [-1.0, 1.0]:
		var yaw: float = PI if sgn < 0.0 else 0.0
		Kit.text3d(n, Vector3(4.9, 4.22, 30.0 + sgn * 0.08), "KALDWICK PORT", 30, Color(1.0, 0.7, 0.25), yaw, 0.0045)
		Kit.text3d(n, Vector3(4.9, 3.92, 30.0 + sgn * 0.08), "NO SERVICE", 26, Color(0.9, 0.3, 0.22), yaw, 0.0045)
	mb.cyl("steel_dk", Vector3(6.45, 4.08, 30.0), 0.33, 0.14, 2, 14)
	mb.cyl("win_lit" if lit > 0 else "white_paint", Vector3(6.45, 4.08, 30.0), 0.28, 0.16, 2, 14)
	for sgn: float in [-1.0, 1.0]:
		mb.box("hull_blk", Vector3(6.45, 4.17, 30.0 + sgn * 0.085), Vector3(0.025, 0.2, 0.006))
		mb.box("hull_blk", Vector3(6.37, 4.1, 30.0 + sgn * 0.085), Vector3(0.14, 0.025, 0.006))
	# signals at both ends of the platform, between the tracks
	_signal(mb, Vector3(-2.25, 0.0, -30.0))
	_signal(mb, Vector3(-2.25, 0.0, 206.0))
	# junction: a turnout off the running line into a short spur with a buffer stop and a loaded wagon
	var ang: float = atan2(4.5, 30.0)
	var dl: float = sqrt(4.5 * 4.5 + 900.0)
	var rb := Basis(Vector3.UP, ang)
	mb.box("ballast", Vector3(2.25, -0.116, -97.0), Vector3(3.3, 0.27, dl), rb)
	Kit.col(body, Vector3(2.25, -0.116, -97.0), Vector3(3.3, 0.27, dl), rb)
	mb.box("ballast", Vector3(4.5, -0.116, -62.5), Vector3(3.5, 0.27, 39.0))
	Kit.col(body, Vector3(4.5, -0.116, -62.5), Vector3(3.5, 0.27, 39.0))
	for i in 36:
		mb.box("sleeper", Vector3(2.25, 0.05, -97.0) + rb * Vector3(0, 0, -14.6 + float(i) * 0.83), Vector3(2.5, 0.12, 0.24), rb)
	for i in 46:
		mb.box("sleeper", Vector3(4.5, 0.05, -81.6 + float(i) * 0.83), Vector3(2.5, 0.12, 0.24))
	for sgn: float in [-1.0, 1.0]:
		mb.box("rust", Vector3(2.25, 0.15, -97.0) + rb * Vector3(sgn * 0.75, 0, 0), Vector3(0.022, 0.07, dl), rb)
		mb.box("rail", Vector3(2.25, 0.186, -97.0) + rb * Vector3(sgn * 0.75, 0, 0), Vector3(0.066, 0.028, dl), rb)
		mb.box("rust", Vector3(4.5 + sgn * 0.75, 0.15, -62.5), Vector3(0.022, 0.07, 39.0))
		mb.box("rust", Vector3(4.5 + sgn * 0.75, 0.186, -62.5), Vector3(0.066, 0.028, 39.0))
		mb.box("rail", Vector3(sgn * 0.75 + 0.1, 0.19, -109.5), Vector3(0.05, 0.03, 5.0), Basis(Vector3.UP, 0.03))
		mb.box("red", Vector3(4.5 + sgn * 0.8, 0.75, -43.6), Vector3(0.16, 1.3, 0.16))
		mb.box("rust", Vector3(4.5 + sgn * 0.8, 0.5, -44.4), Vector3(0.1, 1.2, 0.1), Basis(Vector3.RIGHT, -0.7))
	mb.sbox(body, "white_paint", Vector3(4.5, 1.15, -43.6), Vector3(2.3, 0.3, 0.2))
	for i in 4:
		mb.box("red", Vector3(3.65 + float(i) * 0.57, 1.15, -43.705), Vector3(0.28, 0.3, 0.02))
	mb.box("lamp_red", Vector3(4.5, 1.45, -43.6), Vector3(0.14, 0.14, 0.14))
	mb.box("steel_dk", Vector3(2.3, 0.1, -113.2), Vector3(0.5, 0.1, 0.34))
	mb.cyl("steel_dk", Vector3(2.3, 0.5, -113.2), 0.03, 0.9, 1, 6)
	mb.box("white_paint", Vector3(2.3, 0.86, -113.2), Vector3(0.05, 0.36, 0.2), Basis(Vector3.RIGHT, 0.5))
	mb.box("blink_a", Vector3(2.3, 1.02, -113.2), Vector3(0.12, 0.12, 0.12))
	mb.cyl("steel", Vector3(1.6, 0.14, -113.2), 0.02, 1.5, 0, 5)
	mb.sbox(body, "panel_dk", Vector3(3.5, 0.3, -116.0), Vector3(0.7, 1.1, 0.45))
	mb.box("snow", Vector3(3.5, 0.87, -116.0), Vector3(0.74, 0.05, 0.5))
	mb.box("amber_paint", Vector3(3.14, 0.5, -116.0), Vector3(0.01, 0.2, 0.2))
	# the wagon on the spur: bolster wagon with a stack of rail and sleepers under snow
	mb.sbox(body, "under", Vector3(4.5, 0.98, -57.5), Vector3(2.6, 0.32, 12.8))
	mb.box("wood", Vector3(4.5, 1.17, -57.5), Vector3(2.7, 0.06, 12.8))
	for i in 5:
		for sgn2: float in [-1.0, 1.0]:
			mb.box("rust", Vector3(4.5 + sgn2 * 1.3, 1.75, -63.0 + float(i) * 2.75), Vector3(0.09, 1.1, 0.09))
	for i in 6:
		mb.box("rust", Vector3(3.75 + float(i % 3) * 0.3, 1.26 + float(i / 3) * 0.14, -57.5), Vector3(0.14, 0.13, 11.6))
	for i in 9:
		mb.box("sleeper", Vector3(5.1, 1.27 + float(i / 3) * 0.14, -61.0 + float(i % 3) * 2.7), Vector3(0.9, 0.13, 2.5))
	mb.box("snow", Vector3(4.5, 1.62, -57.5), Vector3(2.3, 0.08, 11.0))
	Kit.col(body, Vector3(4.5, 1.6, -57.5), Vector3(2.7, 1.0, 12.6))
	for bz: float in [-62.2, -52.8]:
		for wz: float in [-0.9, 0.9]:
			mb.cyl("wheel", Vector3(3.75, 0.66, bz + wz), 0.46, 0.13, 0, 14)
			mb.cyl("wheel", Vector3(5.25, 0.66, bz + wz), 0.46, 0.13, 0, 14)
			mb.cyl("steel_dk", Vector3(4.5, 0.66, bz + wz), 0.07, 1.6, 0, 6)
		mb.box("under", Vector3(4.5, 0.64, bz), Vector3(2.2, 0.24, 2.6))
	Kit.text3d(n, Vector3(3.19, 0.98, -57.5), "PW 2291   KARSK P-WAY", 60, Color(0.8, 0.78, 0.7), -PI * 0.5, 0.004)
	# roadside clutter: signs, refuse and rubble
	var signs: Array = [[11.8, 64.6, "STATION"], [11.8, 122.6, "NO ENTRY"]]
	for sg: Array in signs:
		var sx: float = sg[0]
		var sz: float = sg[1]
		mb.cyl("steel_dk", Vector3(sx, 0.95, sz), 0.04, 2.5, 1, 6)
		mb.box("white_paint", Vector3(sx, 1.95, sz), Vector3(0.05, 0.5, 0.9), Basis(Vector3.UP, 0.12))
		mb.box("red", Vector3(sx - 0.03, 2.17, sz), Vector3(0.012, 0.06, 0.9), Basis(Vector3.UP, 0.12))
		Kit.text3d(n, Vector3(sx - 0.04, 1.93, sz), str(sg[2]), 40, Color(0.1, 0.1, 0.12), -PI * 0.5 + 0.12, 0.0042)
	for i in 6:
		mb.cyl("bag", Vector3(6.6 + float(i % 3) * 0.34, 1.45 + float(i / 3) * 0.3, 150.0 + float(i % 2) * 0.4), 0.26, 0.42, 1, 7, 0.1)
	mb.box("wood", Vector3(6.2, 1.4, 151.2), Vector3(0.5, 0.3, 0.4), Basis(Vector3.UP, 0.5))
	mb.box("white_paint", Vector3(5.6, 1.257, 150.4), Vector3(0.3, 0.004, 0.42), Basis(Vector3.UP, 0.8))
	for i in 9:
		var rs: float = 0.35 + 0.22 * float((i * 5) % 4)
		mb.box("concrete" if i % 3 != 0 else "brick", Vector3(9.0 + float(i % 3) * 0.7, -0.1 + rs * 0.2, 150.0 + float(i / 3) * 0.8), Vector3(rs * 1.3, rs * 0.6, rs), Basis(Vector3(0.3, 1.0, 0.2).normalized(), float(i) * 0.9))
	for i in 4:
		mb.cyl("rust", Vector3(9.4 + float(i) * 0.3, 0.3, 150.6), 0.012, 1.3, 1, 4, 0.012)

func _platform(mb: Kit, body: Node, n: Node3D, lname: String, lit: int) -> void:
	mb.sbox(body, "concrete", Vector3(4.61, 0.46, 89.0), Vector3(5.98, 1.42, 222.0))
	mb.box("paving", Vector3(4.61, 1.21, 89.0), Vector3(6.0, 0.08, 222.0))
	Kit.col(body, Vector3(4.61, 1.2, 89.0), Vector3(5.98, 0.1, 222.0))
	mb.box("amber_paint", Vector3(2.1, 1.252, 89.0), Vector3(0.22, 0.006, 222.0))
	mb.box("white_paint", Vector3(1.72, 1.252, 89.0), Vector3(0.18, 0.006, 222.0))
	mb.sbox(body, "concrete", Vector3(4.61, 0.4, -25.05), Vector3(5.98, 0.2, 6.3), Basis(Vector3.RIGHT, -0.245))
	mb.sbox(body, "concrete", Vector3(4.61, 0.4, 203.05), Vector3(5.98, 0.2, 6.3), Basis(Vector3.RIGHT, 0.245))
	for rz: float in [10.0, 62.0, 120.0]:
		mb.sbox(body, "concrete", Vector3(9.26, 0.41, rz), Vector3(3.8, 0.2, 2.6), Basis(Vector3.BACK, -0.4154))
	for i in 11:
		var z: float = -16.0 + float(i) * 20.0
		_lamp_post(mb, n, Vector3(7.25, 1.25, z), i < 5 + lit and lit > 0 and i >= 1 and i <= lit, lit == 1)
	mb.box("hull_blk", Vector3(7.35, 3.3, 14.0), Vector3(0.08, 0.7, 5.2))
	mb.cyl("steel_dk", Vector3(7.4, 2.1, 12.0), 0.05, 1.8, 1, 6)
	mb.cyl("steel_dk", Vector3(7.4, 2.1, 16.0), 0.05, 1.8, 1, 6)
	Kit.text3d(n, Vector3(7.3, 3.3, 14.0), lname.to_upper(), 64, Color(0.95, 0.92, 0.85), -PI * 0.5, 0.0055)
	for bz: float in [24.0, 52.0]:
		mb.box("wood", Vector3(6.8, 1.7, bz), Vector3(0.45, 0.06, 1.8))
		mb.box("wood", Vector3(7.02, 2.0, bz), Vector3(0.05, 0.4, 1.8))
		mb.box("steel_dk", Vector3(6.8, 1.47, bz - 0.7), Vector3(0.4, 0.44, 0.06))
		mb.box("steel_dk", Vector3(6.8, 1.47, bz + 0.7), Vector3(0.4, 0.44, 0.06))
		Kit.col(body, Vector3(6.85, 1.6, bz), Vector3(0.5, 0.7, 1.8))
	_platform_extras(mb, body, n, lit)

# ---------------- location builder ----------------
func _build_loc(k: int) -> Node3D:
	var kbl: Array = Kit.bevel_push(0.03, 0.05, 7.0)
	var idx: int = posmod(k, GS.NLOC)
	var lap: int = k / GS.NLOC
	var L: Dictionary = GS.loc_at(k)
	var meridian: bool = Story.is_meridian(k)
	var midx: int = 99 if meridian else idx
	var n := Node3D.new()
	add_child(n)
	n.position.z = float(GS.train["s"]) - float(k) * GS.SP
	var body := StaticBody3D.new()
	n.add_child(body)
	var mb := Kit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + k * 31
	var ev: String = GS.events.get(str(k), "")
	var lit: int = 9 if meridian else [4, 2, 1, 2, 2, 9, 3, 2, 3, 1][idx]
	_platform(mb, body, n, L["name"], lit)
	match midx:
		99:
			_build_meridian(mb, body, n)
		0:
			_room(mb, body, n, Vector3(18.5, 0, 26.0), Vector3(9.0, 4.4, 15.0), "brick", 1.0)
			mb.sbox(body, "wood", Vector3(21.5, 0.3, 22.0), Vector3(0.8, 1.1, 5.0))
			mb.box("wood", Vector3(16.0, 0.2, 30.5), Vector3(0.5, 0.06, 2.4))
			mb.box("wood", Vector3(16.0, 0.2, 21.5), Vector3(0.5, 0.06, 2.4))
			_loot(mb, body, n, k, 1, Vector3(22.2, -0.25, 31.5), 1)
			_loot(mb, body, n, k, 2, Vector3(19.0, -0.25, 19.6), 0)
			mb.sbox(body, "brick", Vector3(18.5, 6.0, 15.5), Vector3(4.2, 12.5, 4.2))
			mb.cyl("roof", Vector3(18.5, 13.6, 15.5), 3.4, 2.8, 1, 4, 0.1)
			mb.cyl("win_lit", Vector3(16.36, 10.2, 15.5), 1.1, 0.06, 0, 16)
			Kit.text3d(n, Vector3(16.3, 10.2, 15.5), "21:40", 96, Color(0.1, 0.08, 0.05), -PI * 0.5, 0.006)
			for i in 6:
				mb.cyl("steel_dk", Vector3(6.9, 3.0, 4.0 + float(i) * 8.0), 0.08, 3.5, 1, 6)
				mb.box("steel_dk", Vector3(4.6, 4.7, 4.0 + float(i) * 8.0), Vector3(5.2, 0.12, 0.12))
			mb.box("corr", Vector3(4.6, 4.85, 24.0), Vector3(5.8, 0.08, 42.0))
			mb.box("snow", Vector3(4.6, 4.93, 24.0), Vector3(5.6, 0.08, 41.6))
			for i in 5:
				mb.box("lamp_warm", Vector3(4.6, 4.6, 8.0 + float(i) * 8.0), Vector3(0.9, 0.05, 0.14))
			var cl: OmniLight3D = Kit.omni(n, Vector3(4.6, 4.3, 24.0), Color(1.0, 0.8, 0.55), 1.6, 16.0)
			cl.set_meta("e", 1.6)
			for i in 7:
				mb.box("sack" if i % 2 == 0 else "seat_dk", Vector3(3.2 + rng.randf() * 3.4, 1.43 + rng.randf() * 0.05, 18.0 + rng.randf() * 16.0), Vector3(0.6, 0.36, 0.25), Basis(Vector3.UP, rng.randf() * 3.0))
			_loot(mb, body, n, k, 3, Vector3(6.2, 1.25, 30.0), 3)
			_loot(mb, body, n, k, 4, Vector3(5.8, 1.25, 46.0), 0)
			_loot(mb, body, n, k, 5, Vector3(12.0, -0.25, 6.0), 2)
			mb.box("hull_blk", Vector3(7.3, 2.6, 36.0), Vector3(0.06, 1.3, 2.2))
			Kit.text3d(n, Vector3(7.25, 2.85, 36.0), "ALL SERVICES SUSPENDED", 40, Color(1.0, 0.7, 0.25), -PI * 0.5, 0.004)
			Kit.text3d(n, Vector3(7.25, 2.4, 36.0), "EVACUATION POINT - LAST TRAIN 21:40", 30, Color(0.9, 0.88, 0.8), -PI * 0.5, 0.004)
			for sx: float in [-9.5, 9.6]:
				mb.sbox(body, "steel_dk", Vector3(sx, 3.6, 78.0), Vector3(0.5, 7.7, 2.6))
			mb.box("steel_dk", Vector3(0, 7.6, 78.0), Vector3(19.6, 0.25, 2.6))
			for sz: float in [76.75, 79.25]:
				mb.box("hull", Vector3(0, 8.3, sz), Vector3(19.6, 1.2, 0.08))
			mb.box("snow", Vector3(0, 7.76, 78.0), Vector3(19.4, 0.06, 2.3))
			_car(n, body, mb, "car-sports", Vector3(14.5, -0.25, 44.0), 0.5)
			_bld(mb, body, Vector3(24.0, 0, 62.0), Vector3(9.0, 6.5, 14.0), "brick", 0.25, rng, true)
			_bld(mb, body, Vector3(-22.0, 0, 30.0), Vector3(8.0, 5.0, 12.0), "wood", 0.0, rng, true)
		1:
			for wz: float in [16.0, 50.0]:
				mb.sbox(body, "corr", Vector3(14.0, 3.75, wz), Vector3(0.3, 8.0, 30.0))
			mb.sbox(body, "corr", Vector3(14.0, 5.75, 33.0), Vector3(0.3, 4.0, 4.0))
			mb.sbox(body, "corr", Vector3(32.0, 3.75, 33.0), Vector3(0.3, 8.0, 64.0))
			mb.sbox(body, "corr", Vector3(23.0, 3.75, 65.0), Vector3(18.0, 8.0, 0.3))
			for sgn: float in [-1.0, 1.0]:
				mb.box("roof", Vector3(23.0 + sgn * 4.6, 9.0, 33.0), Vector3(9.8, 0.16, 65.0), Basis(Vector3.BACK, -sgn * 0.26))
				mb.box("snow", Vector3(23.0 + sgn * 4.6, 9.12, 33.0), Vector3(9.2, 0.08, 64.0), Basis(Vector3.BACK, -sgn * 0.26))
			for i in 5:
				mb.box("steel_dk", Vector3(23.0, 7.6, 6.0 + float(i) * 13.0), Vector3(17.8, 0.3, 0.2))
			mb.box("concrete", Vector3(23.0, -0.24, 33.0), Vector3(18.0, 0.03, 64.0))
			for sgn: float in [-1.0, 1.0]:
				mb.box("rail", Vector3(23.0 + sgn * 0.75, -0.15, 33.0), Vector3(0.07, 0.15, 62.0))
			for i in 3:
				mb.cyl("wheel", Vector3(22.25, 0.22, 20.0 + float(i) * 1.6), 0.46, 0.13, 0, 14)
				mb.cyl("wheel", Vector3(23.75, 0.22, 20.0 + float(i) * 1.6), 0.46, 0.13, 0, 14)
				mb.cyl("steel_dk", Vector3(23.0, 0.22, 20.0 + float(i) * 1.6), 0.08, 1.9, 0, 6)
			Kit.col(body, Vector3(23.0, 0.2, 21.6), Vector3(2.0, 0.9, 4.4))
			mb.sbox(body, "wood", Vector3(30.8, 0.2, 30.0), Vector3(1.0, 0.9, 6.0))
			_loot(mb, body, n, k, 1, Vector3(30.9, -0.25, 40.0), 1)
			_loot(mb, body, n, k, 2, Vector3(16.0, -0.25, 44.0), 0)
			_loot(mb, body, n, k, 3, Vector3(28.0, -0.25, 12.0), 2)
			var dl: OmniLight3D = Kit.omni(n, Vector3(23.0, 6.5, 33.0), Color(1.0, 0.8, 0.55), 2.0, 24.0)
			dl.set_meta("e", 2.0)
			flickers.append(dl)
			mb.box("lamp_warm", Vector3(23.0, 7.4, 33.0), Vector3(0.5, 0.1, 1.5))
			for gx: float in [10.5, 30.0]:
				for gz: float in [84.0, 90.0]:
					mb.sbox(body, "amber_paint", Vector3(gx, 4.2, gz), Vector3(0.5, 9.0, 0.5))
			for gz: float in [84.0, 90.0]:
				mb.box("amber_paint", Vector3(20.25, 8.9, gz), Vector3(20.5, 0.7, 0.5))
			mb.box("steel_dk", Vector3(18.0, 8.8, 87.0), Vector3(1.6, 0.8, 6.4))
			mb.cyl("rubber", Vector3(18.0, 6.4, 87.0), 0.03, 4.2, 1, 5)
			mb.box("red", Vector3(18.0, 4.2, 87.0), Vector3(0.5, 0.5, 0.3))
			for i in 7:
				mb.box("rust", Vector3(10.0 + float(i % 4) * 0.22, -0.15 + float(i / 4) * 0.17, 100.0), Vector3(0.14, 0.16, 14.0))
			mb.cyl("hull_lt", Vector3(11.0, 1.4, -9.0), 1.5, 6.0, 2, 16)
			mb.sbox(body, "concrete", Vector3(11.0, 0.0, -9.0), Vector3(2.4, 0.9, 5.0))
			_loot(mb, body, n, k, 4, Vector3(9.3, -0.25, -4.5), 2)
			_loot(mb, body, n, k, 5, Vector3(5.5, 1.25, 38.0), 0)
		2:
			for i in 10:
				var hh: float = rng.randf_range(18.0, 46.0)
				var wz: float = rng.randf_range(12.0, 18.0)
				var bx: float = 28.0 + rng.randf() * 4.0
				if i == 0:
					bx = 33.0
				_bld(mb, body, Vector3(bx, 0, -24.0 + float(i) * 22.0), Vector3(12.0, hh, wz), "facade", 0.0, rng)
				var hh2: float = rng.randf_range(14.0, 38.0)
				_bld(mb, body, Vector3(-27.0 - rng.randf() * 5.0, 0, -30.0 + float(i) * 23.0), Vector3(12.0, hh2, rng.randf_range(12.0, 18.0)), "facade", 0.0, rng)
			mb.box("plastic", Vector3(17.0, -0.24, 89.0), Vector3(9.0, 0.03, 222.0))
			_room(mb, body, n, Vector3(17.5, 0, 14.0), Vector3(7.0, 3.6, 9.0), "concrete", 0.0)
			mb.box("led_green", Vector3(13.9, 3.0, 14.0), Vector3(0.06, 0.9, 0.3))
			mb.box("led_green", Vector3(13.9, 3.0, 14.0), Vector3(0.06, 0.3, 0.9))
			Kit.text3d(n, Vector3(13.85, 3.75, 14.0), "APTEKA  PHARMACY", 40, Color(0.6, 1.0, 0.7), -PI * 0.5, 0.005)
			mb.sbox(body, "panel", Vector3(20.3, 0.3, 14.0), Vector3(0.6, 1.1, 6.0))
			_loot(mb, body, n, k, 1, Vector3(20.2, -0.25, 17.7), 1)
			_loot(mb, body, n, k, 2, Vector3(17.5, -0.25, 10.4), 0)
			_loot(mb, body, n, k, 3, Vector3(16.0, -0.25, 17.4), 3)
			_recruit(n, Vector3(18.6, -0.25, 12.5), PI * 0.5, "Lena Voss", "Nurse", "fixed2")
			_car(n, body, mb, "car-police", Vector3(11.4, -0.25, 30.0), 0.5)
			_car(n, body, mb, "car-sports", Vector3(16.0, -0.25, 40.0), -0.2)
			_car(n, body, mb, "car-sports", Vector3(18.5, -0.25, 96.0), 2.7)
			_car(n, body, mb, "firetruck", Vector3(15.5, -0.25, 76.0), 0.15)
			for i in 4:
				mb.sbox(body, "concrete", Vector3(8.8 + float(i) * 1.4, 0.1, 52.0 + float(i % 2) * 0.5), Vector3(1.2, 0.8, 0.6))
			for sx: float in [10.0, 13.0]:
				mb.cyl("steel_dk", Vector3(sx, 3.0, 118.0), 0.1, 6.5, 1, 6)
			mb.box("white_paint", Vector3(11.5, 5.2, 118.0), Vector3(5.0, 2.4, 0.15))
			Kit.text3d(n, Vector3(11.5, 5.5, 117.9), "STAY INDOORS", 64, Color(0.6, 0.12, 0.1), PI, 0.007)
			Kit.text3d(n, Vector3(11.5, 4.7, 117.9), "HELP IS COMING", 48, Color(0.15, 0.15, 0.15), PI, 0.007)
			_loot(mb, body, n, k, 4, Vector3(5.6, 1.25, 66.0), 3)
			_loot(mb, body, n, k, 5, Vector3(12.4, -0.25, 84.0), 0)
		3:
			_bld(mb, body, Vector3(28.0, 0, 36.0), Vector3(16.0, 12.0, 52.0), "brick", 0.12, rng)
			for ch: Array in [[33.0, -6.0], [36.0, 76.0], [31.0, 98.0]]:
				var cx: float = ch[0]
				var cz: float = ch[1]
				mb.cyl("brick", Vector3(cx, 17.0, cz), 1.9, 34.5, 1, 12, 1.2)
				mb.cyl("lamp_red", Vector3(cx, 34.4, cz), 1.25, 0.3, 1, 10)
				Kit.col(body, Vector3(cx, 5.0, cz), Vector3(3.4, 10.5, 3.4))
			for tz: float in [104.0, 116.0]:
				mb.cyl("rust", Vector3(18.0, 3.75, tz), 4.0, 8.0, 1, 18)
				mb.cyl("snow", Vector3(18.0, 7.8, tz), 3.9, 0.1, 1, 18)
				Kit.col(body, Vector3(18.0, 3.75, tz), Vector3(6.6, 8.0, 6.6))
			for i in 9:
				mb.box("steel_dk", Vector3(12.6, 1.9, -12.0 + float(i) * 8.0), Vector3(0.2, 4.3, 0.2))
				mb.box("steel_dk", Vector3(12.6, 4.0, -12.0 + float(i) * 8.0), Vector3(1.6, 0.14, 0.14))
			mb.cyl("rust", Vector3(12.2, 4.3, 20.0), 0.22, 66.0, 2, 8)
			mb.cyl("amber_paint", Vector3(12.8, 4.25, 20.0), 0.14, 66.0, 2, 8)
			mb.cyl("rust", Vector3(13.2, 4.2, 20.0), 0.09, 66.0, 2, 6)
			_room(mb, body, n, Vector3(16.5, 0, 82.0), Vector3(6.0, 3.4, 8.0), "corr", 0.6)
			_loot(mb, body, n, k, 1, Vector3(18.7, -0.25, 84.8), 1)
			_loot(mb, body, n, k, 2, Vector3(17.0, -0.25, 79.0), 2)
			_recruit(n, Vector3(16.6, -0.25, 83.5), PI * 0.5, "Pavel Orlov", "Electrician", "fixed3")
			mb.box("steel_dk", Vector3(16.0, 3.4, 60.0), Vector3(1.2, 0.3, 16.0), Basis(Vector3.RIGHT, 0.35))
			mb.sbox(body, "rust", Vector3(16.0, 0.9, 67.0), Vector3(3.0, 2.3, 3.0))
			_loot(mb, body, n, k, 3, Vector3(10.4, -0.25, 44.0), 2)
			_loot(mb, body, n, k, 4, Vector3(5.4, 1.25, 72.0), 0)
			_loot(mb, body, n, k, 5, Vector3(11.6, -0.25, 96.0), 2)
			_bld(mb, body, Vector3(-26.0, 0, 40.0), Vector3(14.0, 9.0, 40.0), "corr", 0.0, rng, true)
		4:
			for i in 4:
				if i != 1:
					_bld(mb, body, Vector3(26.0, 0, float(i) * 34.0), Vector3(14.0, 7.0, 26.0), "corr", 0.0, rng, true)
			_room(mb, body, n, Vector3(21.0, 0, 34.0), Vector3(12.0, 5.0, 18.0), "corr", 0.5)
			for i in 3:
				mb.sbox(body, "steel_dk", Vector3(24.0, 1.0, 28.0 + float(i) * 6.0), Vector3(4.0, 2.5, 0.8))
				mb.box("wood", Vector3(24.0, 1.3, 28.0 + float(i) * 6.0), Vector3(3.6, 0.5, 1.0))
			_loot(mb, body, n, k, 1, Vector3(25.6, -0.25, 41.0), 0)
			_loot(mb, body, n, k, 2, Vector3(18.0, -0.25, 27.0), 0)
			_loot(mb, body, n, k, 3, Vector3(26.0, -0.25, 31.0), 1)
			_container(mb, body, Vector3(11.4, -0.25, -10.0), "corr_red")
			_container(mb, body, Vector3(11.4, -0.25, 74.0), "corr_blue")
			_container(mb, body, Vector3(11.4, 2.35, 74.0), "corr_amber", 0.06)
			_container(mb, body, Vector3(11.4, -0.25, 81.0), "corr_red")
			_container(mb, body, Vector3(16.0, -0.25, 108.0), "corr_blue", 1.2)
			for i in 5:
				mb.sbox(body, "wood", Vector3(9.5 + rng.randf() * 3.0, -0.1 + 0.15, 48.0 + float(i) * 2.2), Vector3(1.2, 0.3 + 0.3 * float(i % 3), 1.0))
			mb.sbox(body, "amber_paint", Vector3(13.0, 0.5, 20.0), Vector3(1.2, 1.5, 2.2))
			mb.box("steel_dk", Vector3(13.0, 1.4, 18.7), Vector3(1.0, 3.2, 0.12))
			mb.box("steel_dk", Vector3(13.0, 0.0, 18.2), Vector3(0.9, 0.06, 1.0))
			_recruit(n, Vector3(10.0, -0.25, 68.0), PI * 0.5, "Greta Holm", "Farmer", "fixed4")
			_loot(mb, body, n, k, 4, Vector3(5.6, 1.25, 84.0), 0)
			_loot(mb, body, n, k, 5, Vector3(9.6, -0.25, 77.0), 3)
		5:
			mb.sbox(body, "corr", Vector3(31.0, 1.25, 40.0), Vector3(0.25, 3.2, 102.0))
			for fz: float in [-11.0, 91.0]:
				mb.sbox(body, "corr", Vector3(20.0, 1.25, fz), Vector3(22.0, 3.2, 0.25))
			for i in 5:
				_tent(mb, body, Vector3(16.0 + float(i % 2) * 8.0, -0.25, 2.0 + float(i) * 17.0))
			_fire(mb, body, n, Vector3(13.0, -0.25, 22.0))
			_fire(mb, body, n, Vector3(20.0, -0.25, 46.0))
			_fire(mb, body, n, Vector3(13.5, -0.25, 70.0))
			for tx: float in [25.5, 28.5]:
				for tz: float in [78.5, 81.5]:
					mb.box("wood", Vector3(tx, 3.0, tz), Vector3(0.22, 6.6, 0.22))
			mb.sbox(body, "wood", Vector3(27.0, 6.2, 80.0), Vector3(4.0, 0.2, 4.0))
			mb.box("corr", Vector3(27.0, 8.6, 80.0), Vector3(4.6, 0.1, 4.6))
			mb.box("lamp_warm", Vector3(27.0, 8.4, 80.0), Vector3(0.3, 0.1, 0.3))
			Kit.col(body, Vector3(27.0, 3.0, 80.0), Vector3(3.2, 6.4, 3.2))
			mb.sbox(body, "wood", Vector3(11.5, 0.2, 32.0), Vector3(1.0, 0.9, 3.4))
			for sz: float in [30.4, 33.6]:
				mb.cyl("wood", Vector3(12.2, 1.1, sz), 0.05, 2.7, 1, 5)
				mb.cyl("wood", Vector3(10.7, 1.1, sz), 0.05, 2.7, 1, 5)
			mb.box("corr_amber", Vector3(11.5, 2.5, 32.0), Vector3(2.2, 0.06, 4.0), Basis(Vector3.BACK, 0.12))
			for i in 5:
				mb.box("wood" if i % 2 == 0 else "sack", Vector3(11.4, 0.8, 30.8 + float(i) * 0.6), Vector3(0.5, 0.3, 0.4))
			var tr: Humanoid = _person(n, Vector3(12.6, -0.25, 32.0), PI * 0.5, 55, "talk")
			Kit.interact(tr, Vector3(0, 1.0, 0), Vector3(0.9, 1.9, 0.9), "Trade with Odile (Quartermaster)", main.act.bind("trade", null))
			Kit.interact(n, Vector3(11.3, 0.9, 32.0), Vector3(1.2, 1.2, 3.4), "Trade with Odile (Quartermaster)", main.act.bind("trade", null))
			_person(n, Vector3(13.9, -0.25, 22.6), 2.2, 61, "idle")
			_person(n, Vector3(12.2, -0.25, 22.9), -2.2, 62, "talk")
			_person(n, Vector3(20.8, -0.25, 46.6), 2.6, 63, "idle")
			_person(n, Vector3(26.6, 6.3, 80.0), PI * 0.5, 64, "aim")
			_recruit(n, Vector3(9.4, -0.25, 14.0), PI * 0.5, "Sami Qureshi", "Engineer", "fixed5")
			for i in 24:
				mb.box("lamp_warm", Vector3(8.4, 3.6 - 0.25 * sin(float(i % 8) / 7.0 * PI), -8.0 + float(i) * 4.0), Vector3(0.08, 0.1, 0.08))
			for i in 4:
				mb.cyl("wood", Vector3(8.4, 1.7, -8.0 + float(i) * 32.0), 0.07, 4.0, 1, 5)
			Kit.text3d(n, Vector3(8.5, 4.3, 44.0), "HAVEN JUNCTION  -  TRADERS WELCOME", 56, Color(1.0, 0.8, 0.45), -PI * 0.5, 0.006)
			for i in 3:
				mb.sbox(body, "wood", Vector3(24.0, 0.05, 30.0 + float(i) * 4.0), Vector3(6.0, 0.6, 1.2))
				mb.box("soil", Vector3(24.0, 0.36, 30.0 + float(i) * 4.0), Vector3(5.8, 0.03, 1.0))
			_loot(mb, body, n, k, 1, Vector3(9.6, -0.25, 40.0), 0)
			_loot(mb, body, n, k, 2, Vector3(5.6, 1.25, 20.0), 0)
		6:
			for i in 41:
				var fz: float = -20.0 + float(i) * 4.0
				if fz > 27.0 and fz < 35.0:
					continue
				mb.box("steel_dk", Vector3(13.0, 1.1, fz), Vector3(0.1, 2.8, 0.1))
			for seg: Array in [[-20.0, 27.0], [35.0, 140.0]]:
				var za: float = seg[0]
				var zb: float = seg[1]
				for hy: float in [0.3, 1.2, 2.1, 2.5]:
					mb.box("steel_dk", Vector3(13.0, hy, (za + zb) * 0.5), Vector3(0.04, 0.04, zb - za))
				Kit.col(body, Vector3(13.0, 1.1, (za + zb) * 0.5), Vector3(0.2, 2.8, zb - za))
			for bz: float in [4.0, 52.0, 100.0]:
				mb.sbox(body, "concrete", Vector3(24.0, 1.25, bz), Vector3(9.0, 3.0, 12.0))
				mb.box("glass_dark", Vector3(19.47, 1.9, bz), Vector3(0.06, 0.3, 6.0))
				mb.box("snow", Vector3(24.0, 2.8, bz), Vector3(8.8, 0.1, 11.8))
			for tz: float in [-8.0, 84.0]:
				for lx: float in [15.0, 18.0]:
					for lz: float in [-1.5, 1.5]:
						mb.box("steel_dk", Vector3(lx, 3.4, tz + lz), Vector3(0.18, 7.4, 0.18))
				mb.box("steel_dk", Vector3(16.5, 7.1, tz), Vector3(3.6, 0.2, 3.6))
				mb.box("corr", Vector3(16.5, 8.1, tz + 1.7), Vector3(3.6, 1.8, 0.1))
				mb.box("corr", Vector3(18.2, 8.1, tz), Vector3(0.1, 1.8, 3.6))
				mb.box("roof", Vector3(16.5, 9.6, tz), Vector3(4.2, 0.12, 4.2))
				Kit.col(body, Vector3(16.5, 3.5, tz), Vector3(3.4, 7.4, 3.4))
				var sp := SpotLight3D.new()
				sp.position = Vector3(16.5, 8.6, tz)
				sp.rotation = Vector3(-0.42, PI * 0.5 + tz * 0.1, 0)
				sp.spot_range = 60.0
				sp.spot_angle = 14.0
				sp.light_energy = 9.0
				sp.light_color = Color(0.9, 0.95, 1.0)
				n.add_child(sp)
				spinners.append(sp)
				mb.box("lamp_white", Vector3(16.0, 8.6, tz), Vector3(0.3, 0.3, 0.3))
			_room(mb, body, n, Vector3(22.0, 0, 28.0), Vector3(8.0, 3.4, 12.0), "concrete", 0.5)
			_loot(mb, body, n, k, 1, Vector3(25.0, -0.25, 23.5), 1)
			_loot(mb, body, n, k, 2, Vector3(25.0, -0.25, 32.5), 1)
			_loot(mb, body, n, k, 3, Vector3(21.0, -0.25, 24.0), 0)
			mb.cyl("steel_dk", Vector3(30.0, 5.0, 70.0), 0.3, 10.5, 1, 8)
			mb.cyl("hull_lt", Vector3(30.0, 10.6, 70.0), 2.4, 0.3, 0, 14)
			mb.cyl("lamp_red", Vector3(30.0, 11.0, 70.0), 0.15, 0.3, 1, 6)
			for i in 2:
				var tz2: float = 66.0 + float(i) * 12.0
				mb.sbox(body, "canvas", Vector3(17.0, 1.3, tz2), Vector3(2.5, 2.3, 5.0))
				mb.sbox(body, "hull_blk", Vector3(17.0, 1.0, tz2 - 3.4), Vector3(2.4, 2.0, 1.8))
				for wz2: float in [-3.4, 1.5]:
					mb.cyl("rubber", Vector3(17.0, 0.25, tz2 + wz2), 0.5, 2.6, 0, 10)
			for i in 8:
				mb.sbox(body, "sack", Vector3(14.6, 0.1 + 0.0, 24.0 + float(i) * 0.0 + (0.0 if i < 4 else 14.0) + float(i % 4) * 0.0), Vector3(1.4, 0.9, 1.0 + float(i % 4) * 0.4))
			Kit.text3d(n, Vector3(12.9, 2.2, 22.0), "RESTRICTED AREA", 56, Color(0.75, 0.2, 0.15), -PI * 0.5, 0.006)
			Kit.text3d(n, Vector3(12.9, 1.7, 22.0), "LETHAL FORCE AUTHORISED", 36, Color(0.9, 0.88, 0.8), -PI * 0.5, 0.006)
			var rpos: Array = [Vector3(15.0, -0.25, 31.0), Vector3(19.0, -0.25, 14.0), Vector3(18.5, -0.25, 44.0), Vector3(16.0, -0.25, 96.0), Vector3(20.0, -0.25, 62.0), Vector3(27.0, -0.25, 40.0)]
			for i in mini(4 + lap, rpos.size()):
				_hostile(n, "raider", rpos[i], k * 13 + i, lap)
			_loot(mb, body, n, k, 4, Vector3(20.0, -0.25, 90.0), 0)
			_loot(mb, body, n, k, 5, Vector3(5.6, 1.25, 58.0), 0)
		7, 8:
			var sea := MeshInstance3D.new()
			var spm := PlaneMesh.new()
			spm.size = Vector2(900, 1200)
			sea.mesh = spm
			sea.material_override = Kit.plain("water")
			sea.position = Vector3(-464.0, -0.16, 50.0)
			sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(sea)
			mb.sbox(body, "concrete", Vector3(-13.6, 0.2, 50.0), Vector3(0.8, 1.3, 1100.0))
			for i in 40:
				var rs: float = rng.randf_range(1.0, 2.6)
				mb.box("concrete", Vector3(-15.0 - rng.randf() * 2.5, -0.1, -200.0 + float(i) * 13.0 + rng.randf() * 6.0), Vector3(rs, rs * 0.7, rs), Basis(Vector3(0.3, 1, 0.2).normalized(), rng.randf() * 3.0))
			if idx == 7:
				mb.sbox(body, "concrete", Vector3(-22.0, 0.6, 20.0), Vector3(16.0, 2.2, 12.0))
				mb.cyl("white_paint", Vector3(-22.0, 11.7, 20.0), 2.5, 20.0, 1, 14, 1.6)
				mb.cyl("red", Vector3(-22.0, 8.0, 20.0), 2.25, 2.4, 1, 14, 2.06)
				mb.cyl("red", Vector3(-22.0, 15.0, 20.0), 1.95, 2.4, 1, 14, 1.76)
				mb.cyl("steel_dk", Vector3(-22.0, 21.8, 20.0), 2.1, 0.2, 1, 14)
				mb.cyl("lamp_warm", Vector3(-22.0, 22.8, 20.0), 0.9, 1.8, 1, 10)
				mb.cyl("red", Vector3(-22.0, 24.3, 20.0), 1.7, 1.2, 1, 10, 0.1)
				var lh := Node3D.new()
				lh.position = Vector3(-22.0, 22.8, 20.0)
				n.add_child(lh)
				for sg: float in [0.0, PI]:
					var sp2 := SpotLight3D.new()
					sp2.rotation = Vector3(-0.3, sg, 0)
					sp2.spot_range = 90.0
					sp2.spot_angle = 12.0
					sp2.light_energy = 12.0
					sp2.light_color = Color(1.0, 0.9, 0.7)
					lh.add_child(sp2)
				spinners.append(lh)
				for sgn: float in [-1.0, 1.0]:
					mb.sbox(body, "wood", Vector3(6.6, 2.35, 23.0 + sgn * 3.0), Vector3(1.9, 2.2, 0.12))
				mb.sbox(body, "wood", Vector3(7.5, 2.35, 23.0), Vector3(0.12, 2.2, 6.0))
				mb.box("roof", Vector3(6.5, 3.5, 23.0), Vector3(2.6, 0.1, 6.6))
				mb.box("snow", Vector3(6.5, 3.58, 23.0), Vector3(2.4, 0.07, 6.4))
				_loot(mb, body, n, k, 1, Vector3(6.7, 1.25, 21.0), 3)
				for i in 3:
					var bb := Basis(Vector3.UP, 0.4 + float(i) * 0.9) * Basis(Vector3.BACK, 0.25)
					mb.sbox(body, "wood" if i != 1 else "corr_blue", Vector3(11.0 + float(i) * 2.0, 0.3, 36.0 + float(i) * 9.0), Vector3(1.9, 0.9, 5.6), bb)
				_room(mb, body, n, Vector3(18.0, 0, 70.0), Vector3(7.0, 3.3, 8.0), "brick", 0.8)
				_loot(mb, body, n, k, 2, Vector3(20.6, -0.25, 72.8), 1)
				_loot(mb, body, n, k, 3, Vector3(17.6, -0.25, 67.0), 0)
				_recruit(n, Vector3(18.4, -0.25, 71.0), PI * 0.5, "Niko Aalto", "Farmer", "fixed7")
				for i in 4:
					mb.box("wood", Vector3(10.0, 0.8, 90.0 + float(i) * 2.0), Vector3(0.08, 2.1, 0.08))
				mb.box("wood", Vector3(10.0, 1.8, 93.0), Vector3(0.06, 0.06, 6.4))
				_loot(mb, body, n, k, 4, Vector3(10.8, -0.25, 96.5), 2)
				_bld(mb, body, Vector3(27.0, 0, 30.0), Vector3(8.0, 4.5, 10.0), "wood", 0.3, rng, true)
			else:
				mb.box("hull_blk", Vector3(-34.0, 5.5, 60.0), Vector3(16.0, 12.0, 110.0))
				mb.box("red", Vector3(-34.0, 0.6, 60.0), Vector3(16.1, 1.6, 110.1))
				mb.box("white_paint", Vector3(-34.0, 16.0, 100.0), Vector3(13.0, 9.0, 16.0))
				for r in 3:
					for q in 5:
						mb.box("win_lit" if (r + q) % 3 == 0 else "glass_dark", Vector3(-27.45, 13.5 + float(r) * 2.4, 94.0 + float(q) * 3.0), Vector3(0.06, 1.0, 1.6))
				mb.cyl("red", Vector3(-34.0, 23.5, 104.0), 2.0, 6.0, 1, 12)
				for i in 6:
					mb.box(["corr_red", "corr_blue", "corr_amber"][i % 3], Vector3(-34.0, 12.8, 14.0 + float(i) * 12.5), Vector3(14.0, 2.6, 12.0))
				for cz: float in [0.0, 52.0, 104.0]:
					for cx: float in [14.5, 30.0]:
						for dz2: float in [-5.0, 5.0]:
							mb.sbox(body, "corr_amber", Vector3(cx, 15.0, cz + dz2), Vector3(1.0, 30.5, 1.0))
					mb.box("corr_amber", Vector3(22.25, 30.0, cz), Vector3(17.0, 1.6, 11.0))
					mb.box("corr_amber", Vector3(8.0, 31.5, cz), Vector3(58.0, 1.4, 2.4))
					mb.box("hull_lt", Vector3(10.0, 29.2, cz), Vector3(3.0, 2.6, 3.0))
					mb.box("win_lit", Vector3(10.0, 29.4, cz - 1.52), Vector3(2.2, 1.0, 0.05))
					mb.cyl("rubber", Vector3(-12.0, 22.0, cz), 0.05, 18.0, 1, 5)
					mb.box("lamp_red", Vector3(-20.5, 32.4, cz), Vector3(0.4, 0.4, 0.4))
					mb.box("lamp_red", Vector3(30.0, 30.6, cz), Vector3(0.4, 0.4, 0.4))
				var cm: Array = ["corr_red", "corr_blue", "corr_amber", "corr"]
				for i in 16:
					var cx2: float = 17.0 + float(i % 4) * 3.2
					var cz2: float = 16.0 + float(i / 4) * 21.0 + (8.0 if i >= 8 else 0.0)
					for lv in 1 + rng.randi() % 3:
						_container(mb, body, Vector3(cx2, -0.25 + float(lv) * 2.62, cz2), cm[rng.randi() % 4])
				_room(mb, body, n, Vector3(17.5, 0, 132.0), Vector3(7.0, 3.4, 9.0), "concrete", 0.7)
				_loot(mb, body, n, k, 1, Vector3(20.2, -0.25, 135.4), 1)
				_loot(mb, body, n, k, 2, Vector3(17.6, -0.25, 128.6), 0)
				mb.cyl("hull_lt", Vector3(11.0, 1.3, -10.0), 1.5, 7.0, 2, 16)
				mb.sbox(body, "concrete", Vector3(11.0, 0.0, -10.0), Vector3(2.4, 0.9, 6.0))
				_loot(mb, body, n, k, 3, Vector3(9.2, -0.25, -5.0), 2)
				_loot(mb, body, n, k, 4, Vector3(9.4, -0.25, -13.0), 2)
				_loot(mb, body, n, k, 5, Vector3(12.6, -0.25, 44.0), 0)
				_loot(mb, body, n, k, 6, Vector3(5.6, 1.25, 96.0), 0)
				for i in 10:
					mb.cyl("steel_dk", Vector3(7.1, 1.5, -10.0 + float(i) * 14.0), 0.16, 0.5, 1, 8)
		9:
			_room(mb, body, n, Vector3(17.0, 0, 22.0), Vector3(6.0, 3.6, 9.0), "brick", 0.0)
			_loot(mb, body, n, k, 1, Vector3(19.2, -0.25, 25.0), 1)
			_loot(mb, body, n, k, 2, Vector3(16.8, -0.25, 18.6), 3)
			mb.box("corr", Vector3(4.8, 2.6, 34.0), Vector3(5.6, 0.1, 16.0), Basis(Vector3.BACK, 0.5))
			mb.box("corr", Vector3(5.2, 1.5, 54.0), Vector3(4.6, 0.1, 9.0), Basis(Vector3(0.2, 0, 1).normalized(), -0.2))
			for i in 3:
				mb.cyl("steel_dk", Vector3(6.9, 2.6, 28.0 + float(i) * 6.0), 0.08, 2.8, 1, 6)
			for lx: float in [18.5, 21.5]:
				for lz: float in [48.5, 51.5]:
					mb.box("steel_dk", Vector3(lx, 3.4, lz), Vector3(0.22, 7.4, 0.22))
			mb.cyl("rust", Vector3(20.0, 9.2, 50.0), 2.6, 4.4, 1, 14)
			mb.cyl("snow", Vector3(20.0, 11.45, 50.0), 2.5, 0.1, 1, 14)
			mb.cyl("rust", Vector3(20.0, 3.4, 50.0), 0.15, 7.4, 1, 6)
			Kit.col(body, Vector3(20.0, 3.5, 50.0), Vector3(3.4, 7.4, 3.4))
			var wb := Basis(Vector3.BACK, 0.38) * Basis(Vector3.UP, 0.12)
			mb.sbox(body, "rust", Vector3(-5.6, 1.5, 34.0), Vector3(2.9, 2.6, 13.0), wb)
			mb.box("under", Vector3(-5.0, 0.4, 30.0), Vector3(2.4, 0.5, 3.0), wb)
			mb.box("under", Vector3(-5.0, 0.4, 38.0), Vector3(2.4, 0.5, 3.0), wb)
			_loot(mb, body, n, k, 3, Vector3(-8.6, -0.25, 31.0), 0)
			_fire(mb, body, n, Vector3(12.0, -0.25, 70.0))
			_tent(mb, body, Vector3(15.0, -0.25, 74.0))
			mb.sbox(body, "corr", Vector3(18.0, 0.9, 80.0), Vector3(10.0, 2.4, 0.2))
			Kit.text3d(n, Vector3(13.2, 1.6, 79.85), "GREYWATER OUTPOST", 48, Color(1.0, 0.8, 0.45), PI, 0.006)
			_recruit(n, Vector3(12.8, -0.25, 71.2), 2.4, "Jonas Berg", "Mechanic", "fixed9")
			_loot(mb, body, n, k, 4, Vector3(14.0, -0.25, 68.0), 0)
			_loot(mb, body, n, k, 5, Vector3(5.6, 1.25, 76.0), 2)
			_bld(mb, body, Vector3(27.0, 0, 30.0), Vector3(8.0, 5.0, 12.0), "brick", 0.0, rng, true)
	var wc: Array = [] if meridian else WCASES[idx]
	if wc.size() > 0:
		var wpos: Vector3 = wc[1]
		_weapon_case(mb, body, n, k, 90, wpos, str(wc[0]))
	if idx == 1:
		_weapon_case(mb, body, n, k, 91, Vector3(16.2, -0.25, 52.0), "riveter")
	# coupling carriage
	var ctype: String = L["car"]
	if ctype != "" and not GS.coupled.has(str(idx)):
		var cz3: float = main.train.tail_z() + 9.0
		var dc: Node3D = main.train.make_carriage(ctype, false, 0)
		dc.position = Vector3(0, 0, cz3)
		n.add_child(dc)
		var a: Area3D = Kit.interact(n, Vector3(1.9, 2.3, cz3 + 1.3), Vector3(1.0, 2.0, 3.0), "@couple:" + ctype, Callable())
		a.set_meta("cb", main.act.bind("couple", {"idx": idx, "node": dc, "area": a, "type": ctype}))
		mb.box("amber_paint", Vector3(2.6, 1.9, cz3 + 0.4), Vector3(0.08, 1.3, 0.08))
		mb.box("tag", Vector3(2.6, 2.62, cz3 + 0.4), Vector3(0.14, 0.14, 0.14))
	# events
	if ev == "blocked":
		var deb := Node3D.new()
		n.add_child(deb)
		var db := StaticBody3D.new()
		deb.add_child(db)
		var dm := Kit.new()
		for i in 9:
			var ds: float = rng.randf_range(0.8, 2.0)
			dm.sbox(db, ["concrete", "rust", "wood"][i % 3], Vector3(rng.randf_range(-2.0, 2.0), ds * 0.3, -37.0 - rng.randf() * 4.0), Vector3(ds, ds * 0.7, ds * 1.3), Basis(Vector3(0.3, 1, 0.4).normalized(), rng.randf() * 3.0))
		dm.box("steel_dk", Vector3(-1.0, 1.2, -39.0), Vector3(0.26, 9.0, 0.26), Basis(Vector3.BACK, 1.2))
		dm.box("snow", Vector3(0, 0.3, -39.0), Vector3(5.0, 0.6, 4.0))
		dm.box("lamp_red", Vector3(0, 1.4, -35.6), Vector3(0.2, 0.2, 0.2))
		dm.commit(deb)
		var ca: Area3D = Kit.interact(deb, Vector3(0, 1.0, -37.0), Vector3(6.0, 2.5, 5.0), "Clear the line (needs a Tool Kit, takes an hour)", Callable())
		ca.set_meta("cb", main.act.bind("clear", {"k": k, "node": deb}))
		gates[k] = deb
	elif ev == "gate":
		# a bolted barrier and a signal at danger: the road ahead is closed by the story, not by rubble
		var gt := Node3D.new()
		n.add_child(gt)
		var gb := StaticBody3D.new()
		gt.add_child(gb)
		var gm := Kit.new()
		for sx: float in [-1.7, 1.7]:
			gm.box("steel_dk", Vector3(sx, 0.85, -37.0), Vector3(0.16, 1.5, 0.16))
			gm.box("concrete", Vector3(sx, 0.1, -37.0), Vector3(0.5, 0.3, 0.5))
			gm.box("red", Vector3(sx * 0.44, 0.33, -36.2), Vector3(0.22, 0.26, 0.5), Basis(Vector3.RIGHT, 0.5))
		gm.sbox(gb, "white_paint", Vector3(0, 1.3, -37.0), Vector3(3.6, 0.32, 0.12))
		for i in 5:
			gm.box("red", Vector3(-1.44 + float(i) * 0.72, 1.3, -36.935), Vector3(0.36, 0.32, 0.02))
		gm.box("steel_dk", Vector3(0, 0.8, -37.0), Vector3(0.1, 0.1, 3.4), Basis(Vector3.UP, PI * 0.5))
		gm.cyl("steel_dk", Vector3(2.6, 2.4, -37.0), 0.07, 5.0, 1, 6)
		gm.box("hull_blk", Vector3(2.6, 4.7, -36.9), Vector3(0.42, 0.9, 0.2))
		gm.cyl("lamp_red", Vector3(2.6, 4.9, -36.79), 0.12, 0.04, 2, 10)
		gm.cyl("glass_dark", Vector3(2.6, 4.5, -36.79), 0.12, 0.04, 2, 10)
		gm.box("lamp_red", Vector3(0, 1.62, -37.0), Vector3(0.16, 0.16, 0.16))
		gm.commit(gt)
		Kit.omni(gt, Vector3(0, 2.2, -36.0), Color(1.0, 0.15, 0.1), 1.6, 9.0)
		gates[k] = gt
	elif ev == "survivor":
		var pn: String = GS.POOL_NAMES[posmod(k * 7, GS.POOL_NAMES.size())]
		var pj: String = GS.POOL_JOBS[posmod(k * 5, GS.POOL_JOBS.size())]
		_recruit(n, Vector3(5.2, 1.25, 26.0), PI * 0.5, pn, pj, "ev%d" % k)
		mb.box("lamp_red", Vector3(6.0, 1.3, 27.0), Vector3(0.08, 0.08, 0.3))
		var fl: OmniLight3D = Kit.omni(n, Vector3(6.0, 1.7, 27.0), Color(1.0, 0.2, 0.1), 2.0, 10.0)
		fl.set_meta("e", 2.0)
		flickers.append(fl)
	elif ev == "wreck":
		for i in 2:
			mb.sbox(body, "rust", Vector3(-4.5, 2.2, 30.0 + float(i) * 15.0), Vector3(2.9, 2.9, 13.5))
			mb.box("under", Vector3(-4.5, 0.5, 30.0 + float(i) * 15.0), Vector3(2.4, 0.6, 11.0))
			mb.box("snow", Vector3(-4.5, 3.7, 30.0 + float(i) * 15.0), Vector3(2.7, 0.1, 13.2))
		for i in 3:
			_loot(mb, body, n, k, 20 + i, Vector3(-7.6, -0.25, 26.0 + float(i) * 8.0), i % 2 * 2)
	_story_objs(mb, body, n, k, idx, meridian)
	mb.commit(n)
	# infected
	var cnt: int = int(L["infected"])
	if cnt > 0:
		cnt += mini(lap, 4)
		if ev == "horde":
			cnt = cnt * 2 + 2
		for i in cnt:
			var p := Vector3.ZERO
			var m: int = i % 3
			if m == 2 and (idx == 7 or idx == 8):
				m = 0
			if m == 0:
				p = Vector3(rng.randf_range(3.0, 6.5), 1.3, rng.randf_range(95.0 if k == 0 else 66.0, 150.0))
			elif m == 1:
				p = Vector3(rng.randf_range(8.6, 9.6), -0.2, rng.randf_range(70.0 if k == 0 else 20.0, 130.0))
			else:
				p = Vector3(rng.randf_range(-26.0, -14.0), -0.2, rng.randf_range(40.0 if k == 0 else -10.0, 110.0))
			_hostile(n, "infected", p, k * 17 + i, lap)
	_build_mid(n, k, idx)
	_veg_strip(n, k, idx)
	if idx == 3:
		for ch: Array in [[33.0, -6.0], [36.0, 76.0], [31.0, 98.0]]:
			_smoke(n, Vector3(float(ch[0]), 35.5, float(ch[1])), 5.0, 10)
	Kit.bevel_pop(kbl)
	return n

# ---------------- sky, birds, animated lights ----------------
func _sky_mat(additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.disable_fog = true
	m.albedo_color = Color(1, 1, 1, 0)
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _build_sky() -> void:
	_build_ranges()
	dome = Node3D.new()
	add_child(dome)
	dome_grad = Gradient.new()
	dome_grad.offsets = PackedFloat32Array([0.0, 0.3, 0.485, 0.53, 1.0])
	dome_grad.colors = PackedColorArray([Color(0.01, 0.02, 0.04), Color(0.03, 0.05, 0.08), Color(0.07, 0.09, 0.14), Color(0.07, 0.09, 0.14), Color(0.04, 0.05, 0.08)])
	var dgt := GradientTexture2D.new()
	dgt.gradient = dome_grad
	dgt.fill_from = Vector2(0, 0)
	dgt.fill_to = Vector2(0, 1)
	dgt.width = 4
	dgt.height = 128
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.cull_mode = BaseMaterial3D.CULL_DISABLED
	dm.disable_fog = true
	dm.albedo_texture = dgt
	var sph := SphereMesh.new()
	sph.radius = 820.0
	sph.height = 1640.0
	sph.radial_segments = 20
	sph.rings = 14
	var dmi := MeshInstance3D.new()
	dmi.mesh = sph
	dmi.material_override = dm
	dmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dome.add_child(dmi)
	var sg := Gradient.new()
	sg.offsets = PackedFloat32Array([0.0, 0.1, 0.14, 1.0])
	sg.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	var sgt := GradientTexture2D.new()
	sgt.gradient = sg
	sgt.fill = GradientTexture2D.FILL_RADIAL
	sgt.fill_from = Vector2(0.5, 0.5)
	sgt.fill_to = Vector2(0.5, 0.0)
	sgt.width = 128
	sgt.height = 128
	sun_disc_mat = _sky_mat(true)
	sun_disc_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sun_disc_mat.albedo_texture = sgt
	var sq := QuadMesh.new()
	sq.size = Vector2(260, 260)
	sq.material = sun_disc_mat
	sun_disc = MeshInstance3D.new()
	sun_disc.mesh = sq
	sun_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sun_disc.visible = false
	dome.add_child(sun_disc)
	sky_root = Node3D.new()
	add_child(sky_root)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	star_mat = _sky_mat(false)
	star_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	star_mat.billboard_keep_scale = true
	star_mat.albedo_texture = Kit.soft_tex()
	var q := QuadMesh.new()
	q.size = Vector2(3.4, 3.4)
	q.material = star_mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = q
	mm.instance_count = 240
	for i in 240:
		var d := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(0.07, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		var sc: float = rng.randf_range(0.5, 1.4)
		if rng.randf() < 0.08:
			sc *= 2.2
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(sc, sc, sc)), d * 720.0))
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = mm
	smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sky_root.add_child(smi)
	# moon: bright disc with a soft halo
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.25, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0.95, 0.97, 1, 1), Color(0.7, 0.8, 1, 0.22), Color(0.6, 0.7, 1, 0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	gt.width = 128
	gt.height = 128
	moon_mat = _sky_mat(false)
	moon_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	moon_mat.albedo_texture = gt
	var mq := QuadMesh.new()
	mq.size = Vector2(150, 150)
	mq.material = moon_mat
	var moon := MeshInstance3D.new()
	moon.mesh = mq
	moon.position = MOON_DIR.normalized() * 700.0
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sky_root.add_child(moon)
	# aurora: two drifting curtains
	var img := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	var ph: Array = [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
	for x in 64:
		var u: float = float(x) / 64.0 * TAU
		var st: float = clampf(0.45 + 0.3 * sin(u * 3.0 + float(ph[0])) + 0.2 * sin(u * 7.0 + float(ph[1])) + 0.12 * sin(u * 13.0 + float(ph[2])), 0.0, 1.0)
		st = st * st
		for y in 32:
			var vv: float = 1.0 - float(y) / 31.0
			var env: float = pow(sin(clampf(vv, 0.0, 1.0) * PI), 0.7) * (1.0 - vv * 0.65)
			var c: Color = Color(0.25, 1.0, 0.55).lerp(Color(0.55, 0.35, 0.95), vv)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, st * env))
	var atx := ImageTexture.create_from_image(img)
	for layer in 2:
		var stl := SurfaceTool.new()
		stl.begin(Mesh.PRIMITIVE_TRIANGLES)
		var rad: float = 560.0 + float(layer) * 70.0
		var y0: float = 110.0 + float(layer) * 50.0
		var y1: float = y0 + 210.0
		for i in 24:
			var a0: float = deg_to_rad(-80.0 + float(i) * 160.0 / 24.0) + float(layer) * 0.35
			var a1: float = deg_to_rad(-80.0 + float(i + 1) * 160.0 / 24.0) + float(layer) * 0.35
			var w0: float = sin(float(i) * 0.9 + float(layer)) * 40.0
			var w1: float = sin(float(i + 1) * 0.9 + float(layer)) * 40.0
			var p0 := Vector3(sin(a0) * (rad + w0), y0, -cos(a0) * (rad + w0))
			var p1 := Vector3(sin(a1) * (rad + w1), y0, -cos(a1) * (rad + w1))
			var u0: float = float(i) / 8.0
			var u1: float = float(i + 1) / 8.0
			var vs: Array = [[p0, Vector2(u0, 1)], [p1, Vector2(u1, 1)], [p1 + Vector3(0, y1 - y0, 0), Vector2(u1, 0)], [p0, Vector2(u0, 1)], [p1 + Vector3(0, y1 - y0, 0), Vector2(u1, 0)], [p0 + Vector3(0, y1 - y0, 0), Vector2(u0, 0)]]
			for e: Array in vs:
				var pv: Vector3 = e[0]
				var uv: Vector2 = e[1]
				stl.set_uv(uv)
				stl.set_normal(Vector3.UP)
				stl.add_vertex(pv)
		var am: StandardMaterial3D = _sky_mat(true)
		am.albedo_texture = atx
		am.texture_repeat = true
		var ami := MeshInstance3D.new()
		ami.mesh = stl.commit()
		ami.material_override = am
		ami.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sky_root.add_child(ami)
		aurora_mats.append(am)
	# birds
	for i in 6:
		var b := Node3D.new()
		add_child(b)
		var body := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.12, 0.08, 0.4)
		body.mesh = bm
		body.material_override = Kit.plain("bird")
		b.add_child(body)
		var wings: Array = []
		for sgn: float in [-1.0, 1.0]:
			var piv := Node3D.new()
			b.add_child(piv)
			var w := MeshInstance3D.new()
			var wm := BoxMesh.new()
			wm.size = Vector3(0.55, 0.02, 0.22)
			w.mesh = wm
			w.material_override = Kit.plain("bird")
			w.position.x = sgn * 0.3
			piv.add_child(w)
			wings.append(piv)
		birds.append({"node": b, "wings": wings, "phase": rng.randf() * TAU, "radius": rng.randf_range(16.0, 38.0), "height": rng.randf_range(13.0, 26.0), "speed": rng.randf_range(0.25, 0.45)})

func _animate_world(dt: float, focus: Vector3, v: float) -> void:
	salute_cd = maxf(0.0, salute_cd - dt)
	var keep_h: Array = []
	for hv: Variant in herds:
		var hd: Dictionary = hv
		var hn: Variant = hd["node"]
		if hn == null or not is_instance_valid(hn):
			continue
		keep_h.append(hd)
		var flee: float = maxf(0.0, float(hd["flee"]) - dt)
		hd["flee"] = flee
		var run: float = 15.0 if flee > 0.0 else 10.5
		var deer: Array = hd["deer"]
		for de: Array in deer:
			var dn: Node3D = de[0]
			var fp: Node3D = de[1]
			var bp: Node3D = de[2]
			dn.position.z -= run * dt
			if dn.position.z < -190.0:
				dn.position.z += 380.0
			dn.position.x = lerpf(dn.position.x, float(de[4]) + (24.0 if flee > 0.0 else 0.0), clampf(dt * 0.7, 0.0, 1.0))
			var ph: float = t * (11.0 if flee > 0.0 else 8.5) + float(de[3])
			fp.rotation.x = sin(ph) * 0.75
			bp.rotation.x = -sin(ph) * 0.75
			dn.position.y = -0.25 + absf(sin(ph)) * 0.14
			dn.rotation.x = cos(ph) * 0.06
	herds = keep_h
	var keep_t: Array = []
	for tv: Variant in turners:
		if is_instance_valid(tv):
			var tn: Node3D = tv
			tn.rotate_y(dt * 0.09)
			keep_t.append(tv)
	turners = keep_t
	sky_root.position = focus
	dome.position = focus
	for i in aurora_mats.size():
		var am: StandardMaterial3D = aurora_mats[i]
		am.uv1_offset.x += dt * (0.012 + 0.008 * float(i))
	# crossing lamps alternate, signals follow the train's readiness to depart
	var on: bool = fmod(t, 1.0) < 0.5
	var ba: StandardMaterial3D = Kit.mats["blink_a"]
	var bb: StandardMaterial3D = Kit.mats["blink_b"]
	ba.emission_energy_multiplier = 4.5 if on else 0.05
	bb.emission_energy_multiplier = 0.05 if on else 4.5
	var go: bool = GS.train["engine_on"] and not GS.train["doors_open"]
	var sr: StandardMaterial3D = Kit.mats["sig_r"]
	var sg: StandardMaterial3D = Kit.mats["sig_g"]
	sr.emission_energy_multiplier = 0.05 if go else 4.5
	sg.emission_energy_multiplier = 4.0 if go else 0.05
	# birds circle over a stopped train in daylight
	var show: bool = daylight > 0.3 and GS.weather != "blizzard" and v < 3.0
	for b: Dictionary in birds:
		var node: Node3D = b["node"]
		node.visible = show
		if not show:
			continue
		var ph: float = b["phase"]
		var an: float = t * float(b["speed"]) + ph
		var rad: float = b["radius"]
		node.position = focus + Vector3(14.0 + cos(an) * rad, float(b["height"]) + sin(t * 0.3 + ph) * 2.0, 20.0 + sin(an) * rad)
		node.rotation.y = -an
		var wings: Array = b["wings"]
		var flap: float = sin(t * 7.0 + ph) * 0.6
		var wl: Node3D = wings[0]
		var wr: Node3D = wings[1]
		wl.rotation.z = -flap
		wr.rotation.z = flap
	# wind turbines
	var spd: float = 0.5
	if GS.weather == "snow":
		spd = 0.9
	elif GS.weather == "blizzard":
		spd = 1.8
	var keep: Array = []
	for r: Variant in rotors:
		if is_instance_valid(r):
			var rn: Node3D = r
			rn.rotate_object_local(Vector3.BACK, dt * spd)
			keep.append(r)
	rotors = keep
	# level-crossing bell as the train passes
	bell_t -= dt
	var keep2: Array = []
	for c: Variant in crossings:
		if is_instance_valid(c):
			keep2.append(c)
			var cn: Node3D = c
			if absf(cn.global_position.z) < 70.0 and v > 1.0 and bell_t <= 0.0:
				bell_t = 0.55
				main.sfx.play_at("bell", cn.global_position + Vector3(4.0, 3.0, 0.0), -2.0, 0.85)
	crossings = keep2

# ---------------- scenery between stations ----------------
const MIDS := [["crossing", "village"], ["bridge", "tunnel"], ["overbridge", "wagons"], ["tunnel", "crossing"], ["village", "bridge"], ["pylons", "crossing"], ["overbridge", "mast"], ["overbridge", "turbines"], ["wagons", "crossing"], ["cutting", "turbines"]]

func _build_mid(n: Node3D, k: int, idx: int) -> void:
	var kbm: Array = Kit.bevel_push(0.03, 0.05, 7.0)
	_build_mid2(n, k, idx)
	Kit.bevel_pop(kbm)

func _build_mid2(n: Node3D, k: int, idx: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 500 + k * 17
	var coast: bool = idx == 7 or idx == 8
	var pair: Array = MIDS[idx]
	var zs: Array = [-215.0, -480.0]
	for i in 2:
		var mb := Kit.new()
		var sub := Node3D.new()
		sub.position.z = zs[i]
		n.add_child(sub)
		mid_body = StaticBody3D.new()
		sub.add_child(mid_body)
		mid_k = k
		mid_id = 40 + i * 10
		mid_lap = k / GS.NLOC
		match str(pair[i]):
			"crossing": _mid_crossing(mb, sub, coast)
			"village": _mid_village(mb, sub, rng, coast)
			"bridge": _mid_bridge(mb, sub, rng, coast)
			"pylons": _mid_pylons(mb, sub)
			"overbridge": _mid_overbridge(mb, sub, coast)
			"wagons": _mid_wagons(mb, sub, rng)
			"turbines": _mid_turbines(mb, sub)
			"mast": _mid_mast(mb, sub)
			"tunnel": _mid_tunnel(mb, sub)
			"cutting": _mid_cutting(mb, sub)
		if idx == 2 and str(pair[i]) == "wagons":
			_story_obj(mb, mid_body, sub, "s_van", Vector3(6.2, -0.25, 24.8), "case", 0.4)
		elif idx == 6 and str(pair[i]) == "mast":
			_story_obj(mb, mid_body, sub, "s_mast", Vector3(49.4, -0.25, -4.0), "radio", PI)
		mb.commit(sub)
	# approach gantry, seen as the train runs in
	var mg := Kit.new()
	var ga := Node3D.new()
	ga.position.z = 300.0
	n.add_child(ga)
	for x: float in [3.1, -8.0]:
		mg.box("steel_dk", Vector3(x, 3.8, 0), Vector3(0.3, 8.1, 0.3))
		mg.box("concrete", Vector3(x, 0.0, 0), Vector3(0.8, 0.5, 0.8))
	mg.box("steel_dk", Vector3(-2.45, 7.7, 0), Vector3(11.4, 0.35, 0.35))
	mg.box("steel_dk", Vector3(-2.45, 8.3, 0), Vector3(11.4, 0.08, 0.08))
	for tx: float in [0.0, -4.5]:
		mg.box("hull_blk", Vector3(tx, 8.5, 0.1), Vector3(0.5, 1.2, 0.22))
		mg.cyl("sig_g", Vector3(tx, 8.78, 0.22), 0.13, 0.04, 2, 10)
		mg.cyl("sig_r", Vector3(tx, 8.26, 0.22), 0.13, 0.04, 2, 10)
	mg.box("white_paint", Vector3(5.6, 2.6, 0), Vector3(3.6, 1.1, 0.1))
	mg.cyl("steel_dk", Vector3(4.4, 1.0, -0.05), 0.06, 2.6, 1, 6)
	mg.cyl("steel_dk", Vector3(6.8, 1.0, -0.05), 0.06, 2.6, 1, 6)
	var L: Dictionary = GS.loc_at(k)
	Kit.text3d(ga, Vector3(5.6, 2.75, 0.06), str(L["name"]).to_upper(), 40, Color(0.08, 0.08, 0.1), 0.0, 0.006)
	Kit.text3d(ga, Vector3(5.6, 2.3, 0.06), "300 M", 30, Color(0.55, 0.12, 0.1), 0.0, 0.006)
	mg.commit(ga)

func _mid_crossing(mb: Kit, sub: Node3D, coast: bool) -> void:
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(7.5, -0.25, -6.2), 0)
	_loot(mb, mid_body, sub, mid_k, mid_id + 1, Vector3(15.6, -0.25, -3.6), 3)
	var x0: float = -13.0 if coast else -70.0
	mb.box("asphalt", Vector3((x0 + 80.0) * 0.5, -0.22, 0), Vector3(80.0 - x0, 0.06, 7.0))
	mb.box("asphalt", Vector3(-2.25, 0.17, 0), Vector3(9.6, 0.06, 7.0))
	for i in 15:
		mb.box("white_paint", Vector3(9.0 + float(i) * 4.6, -0.185, 0), Vector3(2.2, 0.01, 0.14))
	for sgn: float in [-1.0, 1.0]:
		var bx: float = 4.6 if sgn > 0.0 else -9.2
		var pz: float = -4.3 * sgn
		mb.cyl("steel_dk", Vector3(bx, 1.9, pz), 0.07, 4.3, 1, 6)
		mb.box("white_paint", Vector3(bx, 3.7, pz), Vector3(0.04, 0.16, 1.5), Basis(Vector3.RIGHT, 0.7))
		mb.box("white_paint", Vector3(bx, 3.7, pz), Vector3(0.04, 0.16, 1.5), Basis(Vector3.RIGHT, -0.7))
		mb.box("hull_blk", Vector3(bx, 2.8, pz), Vector3(0.1, 0.4, 1.0))
		for face: float in [-1.0, 1.0]:
			mb.cyl("blink_a", Vector3(bx + face * 0.07, 2.8, pz - 0.28), 0.13, 0.04, 0, 10)
			mb.cyl("blink_b", Vector3(bx + face * 0.07, 2.8, pz + 0.28), 0.13, 0.04, 0, 10)
		mb.box("amber_paint", Vector3(bx + 0.3, 0.6, pz), Vector3(0.3, 1.2, 0.3))
		for j in 6:
			mb.box("red" if j % 2 == 0 else "white_paint", Vector3(bx + 0.3, 1.05, pz + sgn * (0.45 + float(j) * 0.6)), Vector3(0.08, 0.1, 0.6))
	mb.box("brick", Vector3(10.0, 1.15, -8.0), Vector3(3.4, 2.8, 3.4))
	mb.box("roof", Vector3(10.0, 2.65, -8.0), Vector3(4.0, 0.16, 4.0))
	mb.box("snow", Vector3(10.0, 2.78, -8.0), Vector3(3.8, 0.1, 3.8))
	mb.box("win_lit", Vector3(8.28, 1.5, -8.0), Vector3(0.05, 0.8, 1.0))
	_lamp_post(mb, sub, Vector3(7.2, -0.25, 5.2), true)
	_car(sub, mid_body, mb, "car-sports", Vector3(13.0, -0.25, -1.7), PI * 0.5)
	_car(sub, mid_body, mb, "car-police", Vector3(21.0, -0.25, -1.5), PI * 0.5 + 0.12)
	_car(sub, mid_body, mb, "firetruck", Vector3(33.0, -0.25, 1.6), -PI * 0.5)
	_car(sub, mid_body, mb, "car-sports", Vector3(46.0, -0.25, -2.2), PI * 0.5 - 0.5)
	if not coast:
		_car(sub, mid_body, mb, "car-sports", Vector3(-16.0, -0.25, 1.6), -PI * 0.5 + 0.2)
	crossings.append(sub)

func _mid_village(mb: Kit, sub: Node3D, rng: RandomNumberGenerator, coast: bool) -> void:
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(9.0, -0.25, -20.0), 0)
	_loot(mb, mid_body, sub, mid_k, mid_id + 1, Vector3(15.4, -0.25, 14.0), 3)
	_loot(mb, mid_body, sub, mid_k, mid_id + 2, Vector3(9.2, -0.25, 44.0), 2)
	_hostile(sub, "infected", Vector3(16.0, -0.2, -40.0), mid_k * 23 + 1, mid_lap)
	_hostile(sub, "infected", Vector3(15.0, -0.2, 30.0), mid_k * 23 + 2, mid_lap)
	var walls: Array = ["wood", "brick", "wood", "corr"]
	var smoke_n := 0
	for xi in 3:
		for zi in 5:
			if rng.randf() < 0.28:
				continue
			var hx: float = 19.0 + float(xi) * 17.0 + rng.randf_range(-2.0, 2.0)
			var hz: float = -62.0 + float(zi) * 31.0 + rng.randf_range(-3.0, 3.0)
			var sz := Vector3(rng.randf_range(6.0, 8.5), rng.randf_range(3.2, 4.6), rng.randf_range(7.0, 10.0))
			_bld(mb, mid_body, Vector3(hx, 0, hz), sz, walls[rng.randi() % walls.size()], 0.22, rng, true)
			mb.box("brick", Vector3(hx + 1.2, sz.y + 1.6, hz + 1.5), Vector3(0.6, 2.0, 0.6))
			mb.box("wood", Vector3(hx - sz.x * 0.5 - 0.04, 0.75, hz + 2.0), Vector3(0.08, 2.0, 1.0))
			if smoke_n < 3 and rng.randf() < 0.5:
				smoke_n += 1
				_smoke(sub, Vector3(hx + 1.2, sz.y + 2.8, hz + 1.5), 1.7)
			for f in 5:
				mb.box("wood", Vector3(hx - sz.x * 0.5 - 3.0, 0.3, hz - 4.0 + float(f) * 2.0), Vector3(0.1, 1.1, 0.1))
			mb.box("wood", Vector3(hx - sz.x * 0.5 - 3.0, 0.6, hz), Vector3(0.05, 0.08, 8.2))
	# church
	mb.box("brick", Vector3(62.0, 6.5, -20.0), Vector3(4.4, 13.5, 4.4))
	mb.cyl("roof", Vector3(62.0, 16.5, -20.0), 3.3, 6.5, 1, 4, 0.05)
	mb.box("steel", Vector3(62.0, 20.4, -20.0), Vector3(0.1, 1.4, 0.1))
	mb.box("steel", Vector3(62.0, 20.6, -20.0), Vector3(0.7, 0.1, 0.1))
	_bld(mb, mid_body, Vector3(62.0, 0, -9.0), Vector3(7.0, 6.0, 15.0), "brick", 0.1, rng, true)
	mb.box("asphalt", Vector3(12.0, -0.22, 0), Vector3(5.0, 0.06, 150.0))
	_lamp_post(mb, sub, Vector3(15.0, -0.25, -30.0), true, true)
	_lamp_post(mb, sub, Vector3(15.0, -0.25, 36.0), true)
	_car(sub, mid_body, mb, "car-sports", Vector3(11.4, -0.25, 10.0), 0.1)
	_car(sub, mid_body, mb, "car-police", Vector3(12.6, -0.25, -48.0), 2.9)
	mb.box("white_paint", Vector3(8.6, 2.4, -70.0), Vector3(0.12, 1.6, 4.0))
	mb.cyl("steel_dk", Vector3(8.6, 0.8, -71.5), 0.06, 2.2, 1, 5)
	mb.cyl("steel_dk", Vector3(8.6, 0.8, -68.5), 0.06, 2.2, 1, 5)
	Kit.text3d(sub, Vector3(8.5, 2.6, -70.0), "QUARANTINE", 60, Color(0.6, 0.12, 0.1), PI * 0.5, 0.006)
	Kit.text3d(sub, Vector3(8.5, 2.0, -70.0), "DO NOT STOP", 44, Color(0.1, 0.1, 0.12), PI * 0.5, 0.006)
	if not coast:
		_bld(mb, mid_body, Vector3(-26.0, 0, 20.0), Vector3(10.0, 5.0, 15.0), "wood", 0.0, rng, true)
		mb.cyl("corr", Vector3(-22.0, 4.5, 34.0), 2.2, 9.5, 1, 12)
		mb.cyl("roof", Vector3(-22.0, 9.9, 34.0), 2.3, 1.4, 1, 12, 0.2)

func _mid_bridge(mb: Kit, sub: Node3D, rng: RandomNumberGenerator, coast: bool) -> void:
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(32.0, -0.25, 6.0), 0)
	mb.box("icelake", Vector3(150.0, -0.2, 0), Vector3(284.0, 0.06, 46.0))
	if not coast:
		mb.box("icelake", Vector3(-154.0, -0.2, 0), Vector3(284.0, 0.06, 46.0))
	for i in 26:
		var rx: float = rng.randf_range(9.0, 90.0) * (1.0 if (i % 2 == 0 or coast) else -1.0)
		var rs: float = rng.randf_range(0.8, 2.4)
		mb.box("rock", Vector3(rx, -0.05, (23.0 if i % 4 < 2 else -23.0) + rng.randf_range(-1.5, 1.5)), Vector3(rs * 1.4, rs * 0.7, rs), Basis(Vector3(0.2, 1, 0.3).normalized(), rng.randf() * 3.0))
	for z: float in [-31.0, 31.0]:
		mb.box("concrete", Vector3(-2.25, 0.3, z), Vector3(12.6, 1.4, 2.4))
	var ang: float = atan2(6.0, 7.4)
	var dl: float = sqrt(36.0 + 7.4 * 7.4)
	for sx: float in [3.1, -7.6]:
		mb.box("steel_dk", Vector3(sx, 0.35, 0), Vector3(0.4, 0.5, 60.0))
		mb.box("steel_dk", Vector3(sx, 7.75, 0), Vector3(0.4, 0.4, 60.0))
		for i in 11:
			mb.box("steel_dk", Vector3(sx, 4.05, -30.0 + float(i) * 6.0), Vector3(0.26, 7.4, 0.26))
		for i in 10:
			var dz: float = -27.0 + float(i) * 6.0
			mb.box("steel_dk", Vector3(sx, 4.05, dz), Vector3(0.2, dl, 0.2), Basis(Vector3.RIGHT, ang if i % 2 == 0 else -ang))
	for i in 11:
		mb.box("steel_dk", Vector3(-2.25, 7.75, -30.0 + float(i) * 6.0), Vector3(10.7, 0.22, 0.22))
	for i in 5:
		mb.box("steel_dk", Vector3(-2.25, 7.75, -24.0 + float(i) * 12.0), Vector3(0.16, 0.16, 16.0), Basis(Vector3.UP, 0.73 if i % 2 == 0 else -0.73))
	for i in 2:
		var hx: float = 34.0 + float(i) * 17.0
		mb.box("wood", Vector3(hx, 0.7, 6.0 - float(i) * 13.0), Vector3(2.2, 1.9, 2.6))
		mb.box("roof", Vector3(hx, 1.75, 6.0 - float(i) * 13.0), Vector3(2.6, 0.12, 3.0))
		mb.box("lamp_warm", Vector3(hx - 1.12, 0.9, 6.0 - float(i) * 13.0), Vector3(0.04, 0.4, 0.4))

func _mid_pylons(mb: Kit, sub: Node3D) -> void:
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(36.4, -0.25, 3.0), 2)
	_loot(mb, mid_body, sub, mid_k, mid_id + 1, Vector3(36.8, -0.25, -3.4), 0)
	for pi in 3:
		var pz: float = -85.0 + float(pi) * 85.0
		var px := 26.0
		for a: float in [-1.0, 1.0]:
			for b: float in [-1.0, 1.0]:
				mb.box("steel_dk", Vector3(px + a * 1.5, 12.0, pz + b * 1.5), Vector3(0.24, 24.6, 0.24), Basis(Vector3.BACK, a * 0.085) * Basis(Vector3.RIGHT, -b * 0.085))
		for h: float in [4.0, 10.0, 16.0, 21.0]:
			var w: float = 5.2 - h * 0.17
			mb.box("steel_dk", Vector3(px, h, pz - w * 0.5), Vector3(w, 0.12, 0.12))
			mb.box("steel_dk", Vector3(px, h, pz + w * 0.5), Vector3(w, 0.12, 0.12))
			mb.box("steel_dk", Vector3(px - w * 0.5, h, pz), Vector3(0.12, 0.12, w))
			mb.box("steel_dk", Vector3(px + w * 0.5, h, pz), Vector3(0.12, 0.12, w))
		for h: float in [18.5, 23.0]:
			mb.box("steel_dk", Vector3(px, h, pz), Vector3(15.0 if h < 20.0 else 10.0, 0.3, 0.3))
			for o: float in [-1.0, 1.0]:
				mb.cyl("white_paint", Vector3(px + o * (7.0 if h < 20.0 else 4.6), h - 0.7, pz), 0.1, 1.2, 1, 6)
		mb.box("blink_b" if pi % 2 == 0 else "blink_a", Vector3(px, 24.6, pz), Vector3(0.4, 0.4, 0.4))
	for o: float in [-7.0, 7.0, -4.6, 4.6]:
		mb.box("rubber", Vector3(26.0 + o, 17.2 if absf(o) > 5.0 else 21.7, 0), Vector3(0.04, 0.04, 230.0))
	for f in 12:
		mb.box("steel_dk", Vector3(38.0 + float(f % 6) * 3.2, 0.8, -12.0 if f < 6 else 12.0), Vector3(0.08, 2.2, 0.08))
	for i in 3:
		mb.box("hull", Vector3(42.0 + float(i) * 5.0, 1.2, 0), Vector3(2.4, 2.9, 3.4))
		for q in 3:
			mb.cyl("white_paint", Vector3(42.0 + float(i) * 5.0, 3.2, -1.0 + float(q)), 0.13, 1.2, 1, 6)
	mb.box("amber_paint", Vector3(38.0, 1.4, 0), Vector3(0.06, 0.7, 1.0))

func _mid_overbridge(mb: Kit, sub: Node3D, coast: bool) -> void:
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(6.4, -0.25, 2.0), 3)
	var xl: float = -13.0 if coast else -58.0
	var xr := 68.0
	var cx: float = (xl + xr) * 0.5
	mb.box("concrete", Vector3(cx, 8.4, 0), Vector3(xr - xl, 1.0, 9.0))
	mb.box("asphalt", Vector3(cx, 8.92, 0), Vector3(xr - xl, 0.05, 7.4))
	for sz: float in [-4.3, 4.3]:
		mb.box("concrete", Vector3(cx, 9.4, sz), Vector3(xr - xl, 0.9, 0.3))
	for px: float in [4.2, -9.6, 30.0, 52.0, -34.0]:
		if px < xl + 2.0:
			continue
		mb.box("concrete", Vector3(px, 3.85, 0), Vector3(1.0, 8.2, 7.0))
	mb.box("snow", Vector3(xr + 17.0, 4.0, 0), Vector3(37.0, 0.8, 12.0), Basis(Vector3.BACK, -0.235))
	if not coast:
		mb.box("snow", Vector3(xl - 17.0, 4.0, 0), Vector3(37.0, 0.8, 12.0), Basis(Vector3.BACK, 0.235))
	_car(sub, mid_body, mb, "firetruck", Vector3(15.0, 8.95, 0.9), PI * 0.5 + 0.3)
	_car(sub, mid_body, mb, "car-sports", Vector3(26.0, 8.95, -1.6), PI * 0.5)
	_car(sub, mid_body, mb, "car-sports", Vector3(-3.0, 8.95, 1.5), -PI * 0.5 + 0.4)
	for i in 4:
		mb.cyl("steel_dk", Vector3(-6.0 + float(i) * 18.0, 11.4, 4.3), 0.06, 4.2, 1, 5)
	Kit.text3d(sub, Vector3(4.2, 4.6, 3.56), "NO HELP\nSOUTH", 110, Color(0.62, 0.12, 0.1), 0.0, 0.012)
	Kit.text3d(sub, Vector3(-9.6, 3.6, 3.56), "KEEP MOVING", 64, Color(0.85, 0.85, 0.8), 0.0, 0.012)

func _mid_wagons(mb: Kit, sub: Node3D, rng: RandomNumberGenerator) -> void:
	_weapon_case(mb, mid_body, sub, mid_k, mid_id + 5, Vector3(8.0, -0.25, 15.6), "grendel")
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(5.8, -0.25, 20.6), 0)
	_loot(mb, mid_body, sub, mid_k, mid_id + 1, Vector3(6.0, -0.25, 16.8), 2)
	_hostile(sub, "infected", Vector3(9.0, -0.2, 2.0), mid_k * 29 + 1, mid_lap)
	_hostile(sub, "infected", Vector3(11.0, -0.2, 34.0), mid_k * 29 + 2, mid_lap)
	var mats: Array = ["rust", "corr_red", "corr_blue", "rust", "hull_blk"]
	for i in 6:
		var wz: float = -40.0 + float(i) * 14.2
		var tilt := Basis.IDENTITY
		var off := Vector3(-4.5, 0, wz)
		if i == 4:
			tilt = Basis(Vector3.BACK, 0.34) * Basis(Vector3.UP, 0.1)
			off = Vector3(-6.4, -0.2, wz)
		if i == 2:
			mb.cyl("hull_blk", off + Vector3(0, 2.5, 0), 1.4, 11.5, 2, 14)
			mb.box("steel_dk", off + Vector3(0, 4.0, 0), Vector3(0.8, 0.3, 1.2))
		else:
			mb.box(mats[i % mats.size()], off + Vector3(0, 2.45, 0), Vector3(2.8, 2.7, 12.4), tilt)
			mb.box("hull_blk", off + tilt * Vector3(1.41, 2.3, 0.5), Vector3(0.04, 2.0, 2.4), tilt)
		mb.box("under", off + Vector3(0, 0.95, 0), Vector3(2.5, 0.35, 12.6), tilt)
		mb.box("snow", off + tilt * Vector3(0, 3.86, 0), Vector3(2.6, 0.12, 12.0), tilt)
		for bz: float in [-4.2, 4.2]:
			for wsx: float in [-0.75, 0.75]:
				mb.cyl("wheel", off + tilt * Vector3(wsx, 0.5, bz - 0.9), 0.46, 0.13, 0, 12)
				mb.cyl("wheel", off + tilt * Vector3(wsx, 0.5, bz + 0.9), 0.46, 0.13, 0, 12)
	for i in 9:
		mb.cyl("hull" if i % 3 == 0 else "rust", Vector3(-9.5 - rng.randf() * 3.0, 0.2, -30.0 + rng.randf() * 70.0), 0.3, 0.9, 1 if i % 2 == 0 else 2, 10)
	mb.box("corr", Vector3(8.0, 1.2, 20.0), Vector3(3.0, 2.9, 4.0))
	mb.box("snow", Vector3(8.0, 2.72, 20.0), Vector3(3.2, 0.12, 4.2))
	Kit.text3d(sub, Vector3(-3.06, 2.6, -11.6), "THEY ARE IN THE WAGONS", 54, Color(0.85, 0.85, 0.8), PI * 0.5, 0.008)

func _mid_turbines(mb: Kit, sub: Node3D) -> void:
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(8.0, -0.25, 6.0), 3)
	var places: Array = [Vector3(64.0, 0, -55.0), Vector3(92.0, 0, 8.0), Vector3(122.0, 0, 70.0)]
	for i in places.size():
		var p: Vector3 = places[i]
		mb.cyl("white_paint", p + Vector3(0, 22.75, 0), 1.7, 46.0, 1, 10, 0.9)
		mb.box("white_paint", p + Vector3(-0.8, 46.6, 0), Vector3(5.2, 2.0, 2.0))
		mb.box("blink_a" if i % 2 == 0 else "blink_b", p + Vector3(0.6, 47.8, 0), Vector3(0.4, 0.4, 0.4))
		var rot := Node3D.new()
		rot.position = p + Vector3(-3.6, 46.6, 0)
		rot.rotation.y = PI * 0.5
		sub.add_child(rot)
		var bmk := Kit.new()
		bmk.cyl("white_paint", Vector3.ZERO, 0.8, 1.2, 2, 10, 0.3)
		for b in 3:
			var bb := Basis(Vector3.BACK, float(b) * TAU / 3.0)
			bmk.box("white_paint", bb * Vector3(0, 9.6, 0), Vector3(1.1, 18.0, 0.16), bb)
		bmk.commit(rot, false)
		rot.rotation.z = float(i) * 0.7
		rotors.append(rot)

func _mid_mast(mb: Kit, sub: Node3D) -> void:
	_weapon_case(mb, mid_body, sub, mid_k, mid_id + 5, Vector3(52.0, -0.25, 3.8), "halberd")
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(50.2, -0.25, 1.6), 0)
	_loot(mb, mid_body, sub, mid_k, mid_id + 1, Vector3(50.2, -0.25, -1.4), 1)
	var px := 46.0
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			mb.box("steel_dk", Vector3(px + a * 1.6, 29.0, b * 1.6), Vector3(0.24, 58.2, 0.24), Basis(Vector3.BACK, a * 0.045) * Basis(Vector3.RIGHT, -b * 0.045))
	for i in 14:
		var h: float = 3.0 + float(i) * 4.0
		var w: float = 5.6 - h * 0.085
		mb.box("steel_dk", Vector3(px, h, -w * 0.5), Vector3(w, 0.1, 0.1))
		mb.box("steel_dk", Vector3(px, h, w * 0.5), Vector3(w, 0.1, 0.1))
		mb.box("steel_dk", Vector3(px - w * 0.5, h, 0), Vector3(0.1, 0.1, w))
		mb.box("steel_dk", Vector3(px + w * 0.5, h, 0), Vector3(0.1, 0.1, w))
	for h: float in [20.0, 40.0, 58.0]:
		mb.box("blink_a" if h < 30.0 or h > 50.0 else "blink_b", Vector3(px, h, 0), Vector3(0.5, 0.5, 0.5))
	for d: float in [-1.0, 1.0]:
		mb.cyl("hull_lt", Vector3(px + 1.2, 44.0, d * 1.2), 1.1, 0.4, 0, 12)
		mb.box("rubber", Vector3(px + d * 20.0, 22.0, 0), Vector3(0.05, 59.0, 0.05), Basis(Vector3.BACK, d * 0.74))
	mb.box("concrete", Vector3(px + 7.0, 1.2, 0), Vector3(4.0, 2.9, 5.0))
	mb.box("win_lit", Vector3(px + 4.97, 1.6, 0), Vector3(0.05, 0.8, 1.2))
	mb.box("snow", Vector3(px + 7.0, 2.72, 0), Vector3(4.2, 0.12, 5.2))

func _mid_tunnel(mb: Kit, sub: Node3D) -> void:
	_weapon_case(mb, mid_body, sub, mid_k, mid_id + 5, Vector3(3.6, -0.25, 40.0), "vesper")
	var L := 150.0
	for sx: float in [4.5, -9.5]:
		mb.sbox(mid_body, "concrete", Vector3(sx, 3.7, 0), Vector3(0.8, 8.0, L))
	mb.box("concrete", Vector3(-2.5, 8.1, 0), Vector3(14.8, 0.8, L))
	mb.box("rock", Vector3(-2.5, 11.4, 0), Vector3(40.0, 6.0, L - 2.0))
	mb.box("snow", Vector3(-2.5, 14.5, 0), Vector3(38.0, 0.3, L - 4.0))
	mb.box("snow", Vector3(27.0, 6.6, 0), Vector3(28.0, 1.2, L - 2.0), Basis(Vector3.BACK, -0.5))
	mb.box("snow", Vector3(-32.0, 6.6, 0), Vector3(28.0, 1.2, L - 2.0), Basis(Vector3.BACK, 0.5))
	for sz: float in [-1.0, 1.0]:
		var pz: float = sz * (L * 0.5 + 0.3)
		mb.box("concrete", Vector3(6.6, 4.6, pz), Vector3(4.4, 10.2, 1.4))
		mb.box("concrete", Vector3(-11.6, 4.6, pz), Vector3(4.4, 10.2, 1.4))
		mb.box("concrete", Vector3(-2.5, 9.6, pz), Vector3(22.6, 2.4, 1.4))
		mb.box("amber_paint", Vector3(-2.5, 8.25, pz + sz * 0.72), Vector3(13.2, 0.3, 0.04))
		for st in 3:
			var hh: float = 10.0 - float(st) * 3.2
			mb.box("concrete", Vector3(12.8 + float(st) * 8.0, hh * 0.5 - 0.3, pz), Vector3(8.0, hh, 1.0))
			mb.box("concrete", Vector3(-17.8 - float(st) * 8.0, hh * 0.5 - 0.3, pz), Vector3(8.0, hh, 1.0))
			mb.box("snow", Vector3(12.8 + float(st) * 8.0, hh - 0.2, pz), Vector3(8.2, 0.2, 1.2))
		Kit.text3d(sub, Vector3(-2.5, 9.7, pz + sz * 0.72), "KARSK TUNNEL   1962", 90, Color(0.14, 0.14, 0.16), 0.0 if sz > 0.0 else PI, 0.012)
		for i in 8:
			mb.cyl("ice", Vector3(-8.0 + float(i) * 1.6, 7.7 - 0.25 - 0.1 * float(i % 3), pz + sz * 0.5), 0.01, 0.5 + 0.2 * float(i % 3), 1, 4, 0.05)
	for i in 6:
		var lz: float = -62.5 + float(i) * 25.0
		mb.box("lamp_warm", Vector3(4.02, 5.2, lz), Vector3(0.1, 0.14, 0.7))
		mb.box("steel_dk", Vector3(4.06, 5.34, lz), Vector3(0.06, 0.06, 0.9))
		mb.box("concrete", Vector3(4.3, 1.0, lz + 12.0), Vector3(0.5, 2.3, 1.6))
		mb.box("white_paint", Vector3(4.02, 1.6, lz + 12.0), Vector3(0.02, 0.4, 0.4))
	for cy: float in [4.2, 4.4, 4.6]:
		mb.cyl("rubber", Vector3(4.0, cy, 0), 0.04, L, 2, 5)
	mb.cyl("rust", Vector3(-8.95, 3.0, 0), 0.12, L, 2, 8)
	for i in 3:
		var tl: OmniLight3D = Kit.omni(sub, Vector3(1.5, 5.0, -50.0 + float(i) * 50.0), Color(1.0, 0.78, 0.5), 1.8, 26.0)
		tl.set_meta("e", 1.8)
		if i == 1:
			flickers.append(tl)
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(3.4, -0.25, 12.0), 0)
	_loot(mb, mid_body, sub, mid_k, mid_id + 1, Vector3(3.4, -0.25, -40.0), 3)
	tunnels.append(sub)

## A smooth-shaded terrain strip: rows along z, columns at the given x positions, heights from hfn.
## Steep faces are tinted as bare rock through the vertex colour; the rest stays snow.
func _heightfield(parent: Node3D, xs: Array, z0: float, z1: float, nz: int, hfn: Callable) -> void:
	var nx: int = xs.size()
	var hs: Array = []
	for i in nx:
		var col: Array = []
		for j in nz + 1:
			var hv: float = hfn.call(float(xs[i]), lerpf(z0, z1, float(j) / float(nz)))
			col.append(hv)
		hs.append(col)
	var cols: Array = []
	for i in nx:
		var ccol: Array = []
		var ia: int = maxi(i - 1, 0)
		var ib: int = mini(i + 1, nx - 1)
		for j in nz + 1:
			var ha: Array = hs[ia]
			var hb: Array = hs[ib]
			var slope: float = absf(float(hb[j]) - float(ha[j])) / maxf(0.3, absf(float(xs[ib]) - float(xs[ia])))
			var k: float = smoothstep(0.35, 0.8, slope)
			ccol.append(Color(1, 1, 1).lerp(Color(0.25, 0.25, 0.29), k))
		cols.append(ccol)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in nx - 1:
		for j in nz:
			var corners: Array = [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]
			var pts: Array = []
			var pcs: Array = []
			for cn: Array in corners:
				var ci: int = cn[0]
				var cj: int = cn[1]
				var hcol: Array = hs[ci]
				var ccol2: Array = cols[ci]
				pts.append(Vector3(float(xs[ci]), float(hcol[cj]) - 0.25, lerpf(z0, z1, float(cj) / float(nz))))
				pcs.append(ccol2[cj])
			var p0: Vector3 = pts[0]
			var p1: Vector3 = pts[1]
			var p3: Vector3 = pts[3]
			var order: Array = [0, 1, 2, 0, 2, 3]
			if (p1 - p0).cross(p3 - p0).y > 0.0:
				order = [0, 2, 1, 0, 3, 2]
			for o: int in order:
				var pv: Vector3 = pts[o]
				var pc: Color = pcs[o]
				st.set_color(pc)
				st.set_uv(Vector2(pv.x, pv.z))
				st.add_vertex(pv)
	st.generate_normals()
	st.generate_tangents()
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, Kit.mats["snow"])
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)

## The line runs through a blasted rock cutting: crags on both sides, a retaining wall, and a
## rockfall that has buried the far track.
func _mid_cutting(mb: Kit, sub: Node3D) -> void:
	for side: float in [1.0, -1.0]:
		var toe: float = 5.2 if side > 0.0 else 13.0
		var far: float = toe + 36.0
		var xs: Array = []
		for o: float in [0.0, 0.8, 1.8, 3.2, 5.0, 8.0, 14.0, 22.0, 30.0, 36.0]:
			xs.append(side * (toe + o))
		var hf := func(x: float, z: float) -> float:
			var ax: float = absf(x)
			var rise: float = smoothstep(toe, toe + 5.5, ax) * (1.0 - smoothstep(far - 16.0, far, ax))
			var env2: float = 1.0 - smoothstep(48.0, 74.0, absf(z))
			var nn: float = 0.56 + 0.2 * sin(z * 0.31 + ax * 0.45) + 0.14 * sin(z * 0.83 + 1.3) + 0.1 * sin(z * 1.7 + ax)
			return maxf(0.0, 12.0 * rise * env2 * nn)
		_heightfield(sub, xs, -75.0, 75.0, 30, hf)
		Kit.col(mid_body, Vector3(side * (toe + 4.6), 3.0, 0), Vector3(7.0, 7.0, 124.0))
	# retaining wall with buttresses, coping and weep stains along the near side
	mb.box("concrete", Vector3(4.95, 0.55, 0), Vector3(0.4, 1.6, 112.0))
	mb.box("concrete", Vector3(4.92, 1.4, 0), Vector3(0.56, 0.12, 112.2))
	mb.box("snow", Vector3(4.95, 1.49, 0), Vector3(0.5, 0.07, 112.0))
	for i in 13:
		var bz: float = -54.0 + float(i) * 9.0
		mb.box("concrete", Vector3(4.66, 0.4, bz), Vector3(0.3, 1.3, 0.6), Basis(Vector3.BACK, -0.16))
		mb.box("grime", Vector3(4.745, 0.5, bz + 3.2), Vector3(0.006, 0.9, 0.16))
		mb.cyl("rust", Vector3(4.7, 0.9, bz + 3.2), 0.05, 0.14, 0, 6)
		mb.cyl("ice", Vector3(4.66, 0.62, bz + 3.2), 0.008, 0.5, 1, 4, 0.04)
	# the rockfall across the far track, and loose scree at the foot of the near wall
	var falls: Array = [[-4.6, 0.7, 8.0, 1.5], [-5.6, 0.5, 10.4, 1.1], [-3.5, 0.45, 11.0, 0.9], [-6.8, 0.4, 7.2, 0.8], [-4.2, 0.3, 13.2, 0.6], [-8.6, 0.6, 9.6, 1.3], [-10.4, 0.9, 11.6, 1.9]]
	for fr: Array in falls:
		var rr: float = fr[3]
		mb.xf = Transform3D(Basis(Vector3(0.3, 1.0, 0.2).normalized(), rr * 2.1) * Basis(Vector3.RIGHT, rr * 0.7), Vector3(float(fr[0]), float(fr[1]), float(fr[2])))
		mb.cyl("rock", Vector3.ZERO, rr, rr * 1.2, 1, 6, rr * 0.55)
		mb.xf = Transform3D.IDENTITY
	Kit.col(mid_body, Vector3(-5.2, 0.6, 9.8), Vector3(5.6, 1.6, 6.4))
	for i in 9:
		var sr: float = 0.18 + 0.1 * float((i * 5) % 4)
		mb.box("rock", Vector3(3.4 + 0.3 * float(i % 4), -0.1 + sr * 0.3, -40.0 + float(i) * 9.5), Vector3(sr * 1.4, sr * 0.8, sr), Basis(Vector3(0.2, 1.0, 0.3).normalized(), float(i) * 1.3))
	mb.box("rust", Vector3(-3.75, 0.24, 9.4), Vector3(0.07, 0.07, 5.0), Basis(Vector3.RIGHT, 0.12) * Basis(Vector3.UP, 0.07))
	# warning board for approaching trains, a platelayers' hut and what they left behind
	mb.cyl("steel_dk", Vector3(3.5, 1.0, 68.0), 0.04, 2.6, 1, 5)
	mb.box("amber_paint", Vector3(3.5, 2.0, 68.0), Vector3(1.1, 0.7, 0.05))
	Kit.text3d(sub, Vector3(3.5, 2.0, 68.03), "FALLING ROCK", 44, Color(0.06, 0.06, 0.07), 0.0, 0.0042)
	mb.sbox(mid_body, "wood", Vector3(3.5, 0.75, -62.0), Vector3(1.8, 2.0, 2.4))
	mb.box("corr", Vector3(3.5, 1.82, -62.0), Vector3(2.1, 0.08, 2.8), Basis(Vector3.BACK, 0.12))
	mb.box("snow", Vector3(3.5, 1.9, -62.0), Vector3(2.0, 0.07, 2.7), Basis(Vector3.BACK, 0.12))
	mb.box("hull_blk", Vector3(2.59, 0.6, -62.0), Vector3(0.02, 1.6, 0.8))
	mb.cyl("rust", Vector3(2.7, 0.2, -59.8), 0.3, 0.9, 1, 10)
	mb.box("steel_dk", Vector3(2.9, 0.1, -58.6), Vector3(0.06, 0.06, 1.5), Basis(Vector3.RIGHT, 0.5))
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(3.3, -0.25, -57.6), 0)
	_loot(mb, mid_body, sub, mid_k, mid_id + 1, Vector3(3.4, -0.25, 30.0), 3)

# ---------------- the campaign in the world ----------------
## Opens a story barrier or cleared blockage: the barrier lifts away instead of vanishing.
func open_gate(k: int) -> void:
	if gates.has(k):
		var g: Variant = gates[k]
		gates.erase(k)
		if g != null and is_instance_valid(g):
			var gn: Node3D = g
			for cs: Node in gn.find_children("*", "CollisionShape3D", true, false):
				var csh: CollisionShape3D = cs
				csh.set_deferred("disabled", true)
			var tw := create_tween()
			tw.tween_property(gn, "position:y", -4.0, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tw.tween_callback(gn.queue_free)

## A thing in the world the story can be read from or decided at, with a pale marker until used.
func _story_obj(mb: Kit, body: Node, n: Node3D, id: String, pos: Vector3, kind: String, yaw: float = 0.0) -> void:
	var keep: Transform3D = mb.xf
	mb.xf = keep * Transform3D(Basis(Vector3.UP, yaw), pos)
	var w := Vector3(0.9, 0.9, 0.6)
	match kind:
		"desk":
			mb.box("wood", Vector3(0, 0.74, 0), Vector3(1.3, 0.05, 0.65))
			for sx: float in [-0.6, 0.6]:
				mb.box("steel_dk", Vector3(sx, 0.36, 0), Vector3(0.05, 0.72, 0.6))
			mb.box("steel_dk", Vector3(0.32, 0.5, 0), Vector3(0.5, 0.42, 0.58))
			mb.box("steel", Vector3(0.32, 0.56, 0.295), Vector3(0.16, 0.03, 0.02))
			mb.box("white_paint", Vector3(-0.22, 0.772, 0.02), Vector3(0.42, 0.012, 0.3), Basis(Vector3.UP, 0.2))
			mb.box("red", Vector3(0.26, 0.79, -0.1), Vector3(0.3, 0.04, 0.22), Basis(Vector3.UP, -0.3))
			mb.box("plastic", Vector3(-0.47, 0.82, -0.18), Vector3(0.14, 0.1, 0.2))
			mb.cyl("steel_dk", Vector3(0.5, 0.92, -0.22), 0.03, 0.3, 1, 6)
			mb.cyl("lamp_warm", Vector3(0.5, 1.08, -0.16), 0.07, 0.05, 1, 8)
			w = Vector3(1.3, 0.8, 0.65)
		"cabinet":
			mb.box("panel_dk", Vector3(0, 0.9, 0), Vector3(0.8, 1.8, 0.45))
			mb.box("screen", Vector3(0, 1.38, 0.23), Vector3(0.5, 0.26, 0.012))
			mb.box("hull_blk", Vector3(0, 0.95, 0.23), Vector3(0.6, 0.4, 0.012))
			for i in 8:
				mb.box("led_green" if i % 3 != 0 else "led_amber", Vector3(-0.24 + float(i % 4) * 0.16, 1.02 - float(i / 4) * 0.14, 0.24), Vector3(0.03, 0.03, 0.01))
			mb.box("steel", Vector3(0.3, 0.5, 0.235), Vector3(0.03, 0.2, 0.03))
			mb.cyl("rubber", Vector3(-0.3, 1.95, 0), 0.02, 0.4, 1, 5)
			w = Vector3(0.8, 1.8, 0.45)
		"lever":
			mb.box("steel_dk", Vector3(0, 0.1, 0), Vector3(1.1, 0.2, 0.5))
			mb.box("red", Vector3(-0.25, 0.72, -0.12), Vector3(0.06, 1.2, 0.06), Basis(Vector3.RIGHT, 0.28))
			mb.box("white_paint", Vector3(0.25, 0.72, 0.12), Vector3(0.06, 1.2, 0.06), Basis(Vector3.RIGHT, -0.28))
			for sx2: float in [-0.25, 0.25]:
				mb.box("steel", Vector3(sx2, 0.24, 0), Vector3(0.12, 0.1, 0.4))
			for px: float in [-0.6, 0.6]:
				mb.box("steel_dk", Vector3(px, 0.85, -0.3), Vector3(0.06, 1.7, 0.06))
			mb.box("corr", Vector3(0, 1.72, -0.05), Vector3(1.5, 0.05, 0.9), Basis(Vector3.RIGHT, 0.15))
			mb.box("snow", Vector3(0, 1.77, -0.05), Vector3(1.4, 0.05, 0.8), Basis(Vector3.RIGHT, 0.15))
			w = Vector3(1.1, 1.3, 0.5)
		"crate":
			mb.box("white_paint", Vector3(0, 0.25, 0), Vector3(0.8, 0.5, 0.6))
			mb.box("white_paint", Vector3(0.06, 0.72, 0.02), Vector3(0.7, 0.44, 0.54), Basis(Vector3.UP, 0.2))
			mb.box("red", Vector3(0, 0.27, 0.302), Vector3(0.28, 0.09, 0.006))
			mb.box("red", Vector3(0, 0.27, 0.302), Vector3(0.09, 0.28, 0.006))
			mb.box("steel_dk", Vector3(0, 0.5, 0), Vector3(0.82, 0.02, 0.62))
			w = Vector3(0.82, 0.94, 0.62)
		"case":
			mb.box("seat_dk", Vector3(0, 0.19, 0), Vector3(0.56, 0.38, 0.19))
			mb.box("steel", Vector3(0, 0.39, 0), Vector3(0.14, 0.03, 0.03))
			mb.box("white_paint", Vector3(0.12, 0.26, 0.098), Vector3(0.1, 0.07, 0.004))
			mb.box("stitch", Vector3(0, 0.19, 0.097), Vector3(0.5, 0.01, 0.004))
			w = Vector3(0.56, 0.4, 0.2)
		"board":
			mb.box("wood", Vector3(0, 1.5, 0), Vector3(0.9, 0.7, 0.05))
			mb.box("white_paint", Vector3(0, 1.52, 0.03), Vector3(0.56, 0.48, 0.008))
			mb.box("glass", Vector3(0, 1.52, 0.036), Vector3(0.6, 0.52, 0.004))
			mb.box("red", Vector3(0, 1.7, 0.034), Vector3(0.4, 0.05, 0.004))
			w = Vector3(0.9, 1.9, 0.12)
		_:
			mb.box("steel_dk", Vector3(0, 0.4, 0), Vector3(1.1, 0.8, 0.55))
			mb.box("wood", Vector3(0, 0.82, 0), Vector3(1.16, 0.04, 0.6))
			mb.box("plastic", Vector3(-0.1, 1.06, -0.06), Vector3(0.66, 0.44, 0.36))
			mb.box("screen", Vector3(-0.2, 1.1, 0.125), Vector3(0.3, 0.2, 0.01))
			for i in 3:
				mb.cyl("steel", Vector3(0.1 + float(i) * 0.07, 1.02, 0.125), 0.022, 0.03, 2, 8)
			mb.cyl("hull_blk", Vector3(0.38, 0.9, 0.1), 0.09, 0.03, 2, 12)
			mb.cyl("hull_blk", Vector3(0.38, 1.12, 0.1), 0.09, 0.03, 2, 12)
			mb.cyl("steel", Vector3(0.42, 0.9, 0.0), 0.012, 0.9, 1, 4)
			w = Vector3(1.16, 1.3, 0.6)
	mb.xf = keep
	var rb := Basis(Vector3.UP, yaw)
	if body != null:
		Kit.col(body, pos + Vector3(0, w.y * 0.5, 0), w, rb)
	var top: float = w.y
	var a: Area3D = Kit.interact(n, pos + Vector3(0, top * 0.5 + 0.25, 0), Vector3(1.5, top + 0.9, 1.5), Story.label(id), main.act.bind("story", id))
	Story.nodes[id] = a
	if not Story.f("u_" + id):
		var tag := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.11, 0.11, 0.11)
		tag.mesh = bm
		tag.material_override = Kit.mats["tag_story"]
		tag.position = pos + Vector3(0, top + 0.28, 0)
		tag.rotation = Vector3(0.62, 0.62, 0)
		n.add_child(tag)
		a.set_meta("tag", tag)

func _story_npc(n: Node3D, id: String, pos: Vector3, yaw: float, seed_i: int, pose: String) -> void:
	var h: Humanoid = _person(n, pos, yaw, seed_i, pose)
	var a: Area3D = Kit.interact(h, Vector3(0, 1.0, 0), Vector3(0.9, 1.9, 0.9), Story.label(id), main.act.bind("story", id))
	Story.nodes[id] = a

func _story_objs(mb: Kit, body: Node, n: Node3D, k: int, idx: int, meridian: bool) -> void:
	if meridian:
		return
	match idx:
		0:
			_story_obj(mb, body, n, "s_suitcase", Vector3(6.3, 1.25, 40.5), "case", 1.1)
		1:
			_story_obj(mb, body, n, "c1_desk", Vector3(15.0, -0.25, 22.0), "desk", PI * 0.5)
			_story_obj(mb, body, n, "c1_relay", Vector3(31.45, -0.25, 46.0), "cabinet", -PI * 0.5)
			Kit.text3d(n, Vector3(14.2, 2.3, 22.0), "DISPATCH", 44, Color(0.9, 0.86, 0.75), PI * 0.5, 0.005)
		2:
			_story_obj(mb, body, n, "c1_stock", Vector3(15.3, -0.25, 11.2), "crate", 0.3)
		3:
			_story_obj(mb, body, n, "c2_book", Vector3(18.75, -0.25, 81.6), "desk", -PI * 0.5)
		4:
			_story_obj(mb, body, n, "c2_relays", Vector3(16.4, -0.25, 30.4), "crate", -0.2)
			Kit.text3d(n, Vector3(16.4, 0.5, 30.72), "HAVEN JCN\nDO NOT REFIT", 22, Color(0.1, 0.1, 0.12), 0.0, 0.004)
		5:
			_story_obj(mb, body, n, "c2_frame", Vector3(9.8, -0.25, 60.0), "lever", PI * 0.5)
		6:
			_story_obj(mb, body, n, "c3_orders", Vector3(25.7, -0.25, 28.0), "board", -PI * 0.5)
		7:
			_story_obj(mb, body, n, "c3_light", Vector3(21.05, -0.25, 69.3), "cabinet", -PI * 0.5)
		8:
			_story_obj(mb, body, n, "c4_log", Vector3(20.2, -0.25, 130.6), "desk", -PI * 0.5)
			_story_obj(mb, body, n, "c4_rec", Vector3(7.0, 1.25, 112.0), "cabinet", -PI * 0.5)
			_story_npc(n, "c4_people", Vector3(11.6, -0.25, 70.0), PI * 0.5, 733, "idle")
			_person(n, Vector3(12.5, -0.25, 71.3), 1.9, 741, "idle")
			_fire(mb, body, n, Vector3(12.6, -0.25, 68.4))
		9:
			_story_obj(mb, body, n, "c5_points", Vector3(4.2, 1.25, -12.5), "lever", PI * 0.5)

## Meridian Central: not a city. A marshalling yard, a control tower, four glasshouses, thirty-one people.
func _build_meridian(mb: Kit, body: Node, n: Node3D) -> void:
	_room(mb, body, n, Vector3(18.0, 0, 22.0), Vector3(8.0, 4.0, 10.0), "brick", 1.0)
	mb.box("brick", Vector3(18.0, 5.75, 22.0), Vector3(6.0, 3.4, 8.0))
	mb.box("win_lit", Vector3(14.97, 5.9, 22.0), Vector3(0.06, 1.5, 6.4))
	mb.box("win_lit", Vector3(18.0, 5.9, 17.97), Vector3(4.4, 1.5, 0.06))
	mb.box("win_lit", Vector3(18.0, 5.9, 26.03), Vector3(4.4, 1.5, 0.06))
	for wz: float in [19.4, 22.0, 24.6]:
		mb.box("hull_blk", Vector3(14.93, 5.9, wz + 1.3), Vector3(0.06, 1.5, 0.08))
	mb.box("roof", Vector3(18.0, 7.55, 22.0), Vector3(7.2, 0.2, 9.2))
	mb.box("snow", Vector3(18.0, 7.7, 22.0), Vector3(7.0, 0.1, 9.0))
	mb.cyl("steel_dk", Vector3(20.5, 10.6, 24.5), 0.07, 6.0, 1, 5)
	mb.box("steel_dk", Vector3(20.5, 12.6, 24.5), Vector3(1.6, 0.05, 0.05))
	mb.box("blink_a", Vector3(20.5, 13.7, 24.5), Vector3(0.22, 0.22, 0.22))
	Kit.text3d(n, Vector3(13.8, 3.3, 22.0), "MERIDIAN CENTRAL", 64, Color(1.0, 0.82, 0.48), -PI * 0.5, 0.006)
	Kit.text3d(n, Vector3(13.8, 2.82, 22.0), "NORTHLINE TRAFFIC CONTROL", 30, Color(0.92, 0.9, 0.84), -PI * 0.5, 0.006)
	_story_obj(mb, body, n, "c5_tx", Vector3(20.9, -0.25, 22.0), "radio", -PI * 0.5)
	# the glasshouses
	for i in 4:
		var gz: float = 42.0 + float(i) * 12.0
		mb.sbox(body, "concrete", Vector3(19.0, 0.0, gz), Vector3(10.0, 0.5, 5.0))
		for sgn: float in [-1.0, 1.0]:
			mb.box("glass", Vector3(19.0, 1.45, gz + sgn * 2.45), Vector3(10.0, 2.4, 0.04))
			mb.box("glass", Vector3(19.0, 3.15, gz + sgn * 1.3), Vector3(10.0, 0.04, 2.9), Basis(Vector3.RIGHT, sgn * 0.42))
			mb.box("white_paint", Vector3(19.0, 2.65, gz + sgn * 2.45), Vector3(10.1, 0.07, 0.07))
		mb.box("white_paint", Vector3(19.0, 3.72, gz), Vector3(10.1, 0.08, 0.08))
		for q in 6:
			var qx: float = 14.0 + float(q) * 2.0
			mb.box("white_paint", Vector3(qx, 1.45, gz - 2.45), Vector3(0.06, 2.4, 0.06))
			mb.box("white_paint", Vector3(qx, 1.45, gz + 2.45), Vector3(0.06, 2.4, 0.06))
		mb.box("soil", Vector3(19.0, 0.3, gz), Vector3(9.4, 0.12, 3.8))
		for p in 16:
			mb.cyl("leaf" if p % 3 != 0 else "leaf_lt", Vector3(14.6 + float(p % 8) * 1.25, 0.62, gz - 0.9 + float(p / 8) * 1.8), 0.24, 0.6, 1, 6, 0.04)
		mb.box("grow", Vector3(19.0, 2.5, gz), Vector3(9.0, 0.05, 0.2))
		var gl: OmniLight3D = Kit.omni(n, Vector3(19.0, 2.2, gz), Color(1.0, 0.6, 0.85), 1.5, 9.0)
		gl.set_meta("e", 1.5)
	# the camp: tents, fires, a washing line between two dead signals
	_tent(mb, body, Vector3(11.5, -0.25, 34.0))
	_tent(mb, body, Vector3(11.5, -0.25, 64.0))
	_tent(mb, body, Vector3(11.0, -0.25, 96.0))
	_fire(mb, body, n, Vector3(10.6, -0.25, 28.0))
	_fire(mb, body, n, Vector3(10.4, -0.25, 58.0))
	for sz: float in [70.0, 78.0]:
		_signal(mb, Vector3(10.4, -0.25, sz))
	mb.box("rubber", Vector3(10.4, 3.2, 74.0), Vector3(0.012, 0.012, 8.0))
	var wash: Array = ["white_paint", "red", "seat", "canvas", "white_paint", "amber_paint"]
	for i in 6:
		mb.box(str(wash[i]), Vector3(10.4, 2.85, 71.0 + float(i) * 1.2), Vector3(0.02, 0.6, 0.7))
	for i in 20:
		mb.box("lamp_warm", Vector3(8.4, 3.6 - 0.25 * sin(float(i % 8) / 7.0 * PI), -8.0 + float(i) * 4.0), Vector3(0.08, 0.1, 0.08))
	for i in 4:
		mb.cyl("wood", Vector3(8.4, 1.7, -8.0 + float(i) * 28.0), 0.07, 4.0, 1, 5)
	# the gates Ivo closed, standing open
	for sgn2: float in [-1.0, 1.0]:
		mb.sbox(body, "concrete", Vector3(12.6, 1.4, 110.0 + sgn2 * 3.2), Vector3(0.7, 3.3, 0.7))
		mb.box("steel_dk", Vector3(14.6, 1.3, 110.0 + sgn2 * 3.4), Vector3(4.0, 2.6, 0.08), Basis(Vector3.UP, sgn2 * 0.15))
		for q2 in 5:
			mb.box("rust", Vector3(13.0 + float(q2) * 0.8, 1.3, 110.0 + sgn2 * (3.47 + float(q2) * 0.12)), Vector3(0.06, 2.4, 0.06))
	# the people
	_story_npc(n, "c5_edda", Vector3(5.4, 1.25, 12.0), PI * 0.5, 303, "idle")
	var ppl: Array = [[11.4, -0.25, 28.8, 2.4, "idle"], [9.8, -0.25, 28.4, -2.2, "talk"], [11.2, -0.25, 58.6, 2.6, "talk"], [9.6, -0.25, 57.6, -2.4, "idle"], [14.2, -0.25, 40.4, 0.0, "work"], [13.9, -0.25, 52.3, 0.2, "work"], [5.8, 1.25, 30.0, PI * 0.5, "idle"], [6.2, 1.25, 46.0, PI * 0.5, "wave"], [9.9, -0.25, 73.0, PI * 0.5, "work"]]
	for i in ppl.size():
		var pe: Array = ppl[i]
		_person(n, Vector3(float(pe[0]), float(pe[1]), float(pe[2])), float(pe[3]), 520 + i * 7, str(pe[4]))

# ---------------- scenery along the open line ----------------
## Six more set pieces on every leg, streamed in ahead of the train and freed behind it.
const SLOT_OFF := [760.0, 1040.0, 1320.0, 1600.0, 1880.0, 2160.0]
const SCENES := [
	["herd", "farm", "gallery", "lake", "sawmill", "hilltop"],
	["steamer", "camp", "pylons", "herd", "village", "dishes"],
	["airliner", "crossing", "cooling", "camp", "lake", "turbines"],
	["cooling", "sawmill", "overbridge", "herd", "farm", "gallery"],
	["farm", "lake", "camp", "hilltop", "bridge", "herd"],
	["dishes", "herd", "steamer", "gallery", "airliner", "camp"],
	["hilltop", "gallery", "lake", "sawmill", "turbines", "herd"],
	["stacks", "shipwreck", "rig", "pier", "icefield", "stacks"],
	["airliner", "herd", "farm", "dishes", "lake", "camp"],
	["gallery", "hilltop", "herd", "sawmill", "steamer", "camp"]]

func slot_types() -> Array:
	var o: Array = []
	for key: int in scn.keys():
		var nd: Node3D = scn[key]
		o.append(str(nd.get_meta("type")))
	return o

func _stream_scenery(s: float, v: float) -> void:
	var leg0: int = int(floor(s / GS.SP))
	var built := false
	for kk: int in [leg0, leg0 + 1, leg0 - 1]:
		if kk < 0:
			continue
		for i in SLOT_OFF.size():
			var sz: float = float(kk) * GS.SP + float(SLOT_OFF[i])
			var key: int = kk * 8 + i
			var rel: float = sz - s
			if rel < 620.0 and rel > -430.0 and not scn.has(key) and not built:
				scn[key] = _build_slot(kk, i, sz)
				built = true
	for key2: int in scn.keys():
		var nd: Node3D = scn[key2]
		var rel2: float = float(nd.get_meta("sz")) - s
		if rel2 > 700.0 or rel2 < -480.0:
			nd.queue_free()
			scn.erase(key2)
			continue
		nd.position.z = -rel2
		if absf(rel2) < 130.0 and v > 1.0:
			Story.sight(main, str(nd.get_meta("type")))
	if v > 1.0:
		for k: int in locs.keys():
			var pair: Array = MIDS[posmod(k, GS.NLOC)]
			for i2 in 2:
				if absf(float(k) * GS.SP + (215.0 if i2 == 0 else 480.0) - s) < 110.0:
					Story.sight(main, str(pair[i2]))

func _build_slot(kk: int, i: int, sz: float) -> Node3D:
	var kb: Array = Kit.bevel_push(0.03, 0.05, 7.0)
	var idx: int = posmod(kk, GS.NLOC)
	var row: Array = SCENES[idx]
	var type: String = row[i]
	var n := Node3D.new()
	add_child(n)
	n.position.z = float(GS.train["s"]) - sz
	n.set_meta("type", type)
	n.set_meta("sz", sz)
	mid_body = StaticBody3D.new()
	n.add_child(mid_body)
	mid_k = kk
	mid_id = 60 + i * 8
	mid_lap = kk / GS.NLOC
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + kk * 53 + i * 11
	var mb := Kit.new()
	if idx == 7:
		_slot_sea(mb, n, rng, i)
	match type:
		"herd": _sc_herd(n, rng)
		"farm": _sc_farm(mb, n, rng)
		"gallery": _sc_gallery(mb, n)
		"lake": _sc_lake(mb, n, rng)
		"sawmill": _sc_sawmill(mb, n)
		"hilltop": _sc_hilltop(mb, n)
		"steamer": _sc_steamer(mb, n)
		"camp": _sc_camp(mb, n, rng)
		"dishes": _sc_dishes(mb, n)
		"airliner": _sc_airliner(mb, n, rng)
		"cooling": _sc_cooling(mb, n)
		"stacks": _sc_stacks(mb, n, rng)
		"shipwreck": _sc_shipwreck(mb, n)
		"rig": _sc_rig(mb, n)
		"pier": _sc_pier(mb, n)
		"icefield": _sc_icefield(mb, n, rng)
		"pylons": _mid_pylons(mb, n)
		"village": _mid_village(mb, n, rng, false)
		"crossing": _mid_crossing(mb, n, false)
		"turbines": _mid_turbines(mb, n)
		"overbridge": _mid_overbridge(mb, n, false)
		"bridge": _mid_bridge(mb, n, rng, false)
	mb.commit(n)
	Kit.bevel_pop(kb)
	return n

## The horn carries: people wave back, herds bolt.
func salute(pos: Vector3) -> void:
	var camp := false
	for c: Variant in civils:
		if is_instance_valid(c):
			var hmn: Humanoid = c
			var d: Vector3 = hmn.global_position - pos
			if Vector2(d.x, d.z).length() < 170.0:
				hmn.set_meta("wave_t", 4.5)
				if hmn.has_meta("camp"):
					camp = true
	for hv: Variant in herds:
		var hd: Dictionary = hv
		var hn: Variant = hd["node"]
		if hn != null and is_instance_valid(hn):
			var hn3: Node3D = hn
			if absf(hn3.global_position.z - pos.z) < 280.0:
				hd["flee"] = 4.5
	if camp and salute_cd <= 0.0:
		salute_cd = 45.0
		GS.say("They wave back. Somebody lifts a child up to see the train.", "good")
		Story.morale(1.5)

func _waver(n: Node3D, pos: Vector3, yaw: float, seed_i: int, pose: String) -> void:
	var h: Humanoid = _person(n, pos, yaw, seed_i, pose)
	h.set_meta("camp", true)

func _deer_meshes() -> void:
	if deer_body != null:
		return
	var fur: String = Kit.cmat(Color(0.36, 0.3, 0.25), 0.95)
	var pale: String = Kit.cmat(Color(0.72, 0.68, 0.62), 0.95)
	var horn: String = Kit.cmat(Color(0.78, 0.73, 0.62), 0.8)
	var mb := Kit.new()
	mb.ball(fur, Vector3(0, 1.02, 0), Vector3(0.26, 0.3, 0.62), 8, 5)
	mb.ball(pale, Vector3(0, 0.96, -0.46), Vector3(0.21, 0.27, 0.26), 8, 5)
	mb.ball(pale, Vector3(0, 1.08, 0.6), Vector3(0.08, 0.1, 0.08), 6, 4)
	mb.xf = Transform3D(Basis(Vector3.RIGHT, -0.7), Vector3(0, 1.15, -0.6))
	mb.cyl(fur, Vector3(0, 0.25, 0), 0.12, 0.55, 1, 6, 0.085)
	mb.xf = Transform3D.IDENTITY
	mb.ball(fur, Vector3(0, 1.62, -1.0), Vector3(0.09, 0.1, 0.2), 6, 4)
	for sgn: float in [-1.0, 1.0]:
		mb.box(horn, Vector3(sgn * 0.14, 1.95, -0.9), Vector3(0.03, 0.55, 0.03), Basis(Vector3.BACK, -sgn * 0.5) * Basis(Vector3.RIGHT, 0.3))
		mb.box(horn, Vector3(sgn * 0.24, 2.1, -1.0), Vector3(0.025, 0.26, 0.025), Basis(Vector3.RIGHT, -0.8))
		mb.box(horn, Vector3(sgn * 0.2, 2.0, -0.8), Vector3(0.025, 0.2, 0.025), Basis(Vector3.RIGHT, 0.9))
		mb.box(fur, Vector3(sgn * 0.09, 1.72, -0.9), Vector3(0.03, 0.09, 0.05))
	deer_body = mb.build_mesh()
	var ml := Kit.new()
	for sgn2: float in [-1.0, 1.0]:
		ml.cyl(fur, Vector3(sgn2 * 0.13, -0.24, 0), 0.045, 0.5, 1, 5, 0.07)
		ml.cyl(fur, Vector3(sgn2 * 0.13, -0.68, 0.02), 0.03, 0.44, 1, 5, 0.04)
		ml.box(Kit.cmat(Color(0.08, 0.07, 0.06), 0.7), Vector3(sgn2 * 0.13, -0.9, -0.02), Vector3(0.07, 0.06, 0.1))
	deer_legs = ml.build_mesh()

func _sc_herd(sub: Node3D, rng: RandomNumberGenerator) -> void:
	_deer_meshes()
	var deer: Array = []
	for i in 9:
		var dn := Node3D.new()
		var x0: float = 13.0 + rng.randf() * 20.0
		dn.position = Vector3(x0, -0.25, -160.0 + float(i) * 38.0 + rng.randf() * 20.0)
		var sc: float = rng.randf_range(0.82, 1.12)
		dn.scale = Vector3(sc, sc, sc)
		sub.add_child(dn)
		var bm := MeshInstance3D.new()
		bm.mesh = deer_body
		bm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dn.add_child(bm)
		var pivs: Array = []
		for pz: float in [-0.4, 0.42]:
			var pv := Node3D.new()
			pv.position = Vector3(0, 0.94, pz)
			dn.add_child(pv)
			var lm := MeshInstance3D.new()
			lm.mesh = deer_legs
			lm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			pv.add_child(lm)
			pivs.append(pv)
		deer.append([dn, pivs[0], pivs[1], rng.randf() * TAU, x0])
	herds.append({"node": sub, "deer": deer, "flee": 0.0})

func _sc_farm(mb: Kit, sub: Node3D, rng: RandomNumberGenerator) -> void:
	_bld(mb, mid_body, Vector3(26.0, 0, -22.0), Vector3(8.0, 5.0, 11.0), "wood", 0.75, rng, true)
	mb.box("brick", Vector3(27.5, 7.6, -19.0), Vector3(0.7, 2.6, 0.7))
	_smoke(sub, Vector3(27.5, 9.2, -19.0), 1.6, 8)
	_bld(mb, mid_body, Vector3(42.0, 0, 14.0), Vector3(12.0, 7.0, 18.0), "corr_red", 0.0, rng, true)
	mb.box("wood", Vector3(35.9, 2.0, 14.0), Vector3(0.14, 4.4, 4.6))
	mb.box("white_paint", Vector3(35.82, 2.0, 14.0), Vector3(0.04, 4.4, 0.16))
	mb.cyl("corr", Vector3(31.0, 5.25, 31.0), 2.4, 11.0, 1, 14)
	mb.cyl("roof", Vector3(31.0, 11.5, 31.0), 2.6, 1.6, 1, 14, 0.2)
	mb.box("steel_dk", Vector3(28.55, 5.0, 31.0), Vector3(0.06, 10.0, 0.4))
	for i in 34:
		mb.box("wood", Vector3(14.0, 0.3, -50.0 + float(i) * 3.0), Vector3(0.12, 1.2, 0.12))
	for hy: float in [0.35, 0.75]:
		mb.box("wood", Vector3(14.0, hy, -0.5), Vector3(0.05, 0.1, 99.0))
	for i in 7:
		var bx: float = 17.0 + float(i % 3) * 2.6
		var bz: float = 30.0 + float(i / 3) * 2.2 + rng.randf()
		mb.cyl("sack", Vector3(bx, 0.45, bz), 0.7, 1.3, 0, 12)
		mb.cyl("snow", Vector3(bx, 1.05, bz), 0.5, 0.2, 0, 8)
	# tractor
	mb.box("red", Vector3(19.0, 0.85, 3.0), Vector3(1.2, 1.0, 2.6))
	mb.box("hull_blk", Vector3(19.0, 1.95, 3.9), Vector3(1.25, 1.3, 1.3))
	mb.box("glass_dark", Vector3(19.0, 2.1, 3.22), Vector3(1.0, 0.8, 0.05))
	mb.cyl("steel_dk", Vector3(19.4, 2.0, 2.2), 0.05, 1.4, 1, 6)
	for sgn: float in [-1.0, 1.0]:
		mb.cyl("rubber", Vector3(19.0 + sgn * 0.75, 0.55, 4.0), 0.8, 0.4, 0, 14)
		mb.cyl("amber_paint", Vector3(19.0 + sgn * 0.96, 0.55, 4.0), 0.4, 0.04, 0, 10)
		mb.cyl("rubber", Vector3(19.0 + sgn * 0.62, 0.2, 2.0), 0.45, 0.26, 0, 12)
	mb.box("snow", Vector3(19.0, 2.64, 3.9), Vector3(1.2, 0.08, 1.2))
	# wind pump
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			mb.box("steel_dk", Vector3(52.0 + a * 0.7, 4.5, -30.0 + b * 0.7), Vector3(0.1, 9.4, 0.1), Basis(Vector3.BACK, a * 0.07) * Basis(Vector3.RIGHT, -b * 0.07))
	var rot := Node3D.new()
	rot.position = Vector3(51.4, 9.4, -30.0)
	rot.rotation.y = PI * 0.5
	sub.add_child(rot)
	var rk := Kit.new()
	for bl in 8:
		var bb := Basis(Vector3.BACK, float(bl) * TAU / 8.0)
		rk.box("steel", bb * Vector3(0, 1.0, 0), Vector3(0.36, 1.5, 0.03), bb * Basis(Vector3.UP, 0.4))
	rk.cyl("steel_dk", Vector3.ZERO, 0.16, 0.3, 2, 8)
	rk.commit(rot, false)
	rotors.append(rot)
	_lamp_post(mb, sub, Vector3(16.5, -0.25, -12.0), true)
	_waver(sub, Vector3(15.2, -0.25, -6.0), PI * 0.5, 811 + mid_k, "idle")
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(16.6, -0.25, 9.0), 0)

func _sc_gallery(mb: Kit, sub: Node3D) -> void:
	var L := 132.0
	mb.box("concrete", Vector3(-2.4, 7.95, 0), Vector3(14.6, 0.6, L))
	mb.box("snow", Vector3(-2.4, 8.4, 0), Vector3(14.2, 0.3, L - 1.0))
	mb.sbox(mid_body, "concrete", Vector3(-9.5, 3.8, 0), Vector3(0.8, 8.0, L))
	mb.box("concrete", Vector3(4.5, 7.4, 0), Vector3(0.7, 0.6, L))
	mb.box("concrete", Vector3(4.5, 0.25, 0), Vector3(0.4, 1.0, L))
	for i in 23:
		var cz: float = -66.0 + float(i) * 6.0
		mb.sbox(mid_body, "concrete", Vector3(4.5, 3.55, cz), Vector3(0.6, 7.2, 0.6))
		mb.box("grime", Vector3(4.19, 2.0, cz), Vector3(0.01, 2.6, 0.3))
		if i % 4 == 1:
			mb.box("lamp_warm", Vector3(-2.3, 7.6, cz), Vector3(0.9, 0.06, 0.16))
	for ez: float in [-66.0, 66.0]:
		mb.box("concrete", Vector3(-2.4, 8.7, ez), Vector3(15.4, 1.4, 1.2))
		mb.box("amber_paint", Vector3(-2.4, 7.56, ez), Vector3(13.6, 0.26, 1.24))
	for i in 3:
		var gl: OmniLight3D = Kit.omni(sub, Vector3(-2.3, 6.4, -44.0 + float(i) * 44.0), Color(1.0, 0.78, 0.5), 1.5, 22.0)
		gl.set_meta("e", 1.5)
	var xs: Array = [-9.9, -14.0, -20.0, -28.0, -36.0, -44.0, -54.0, -66.0, -80.0]
	var hf := func(x: float, z: float) -> float:
		var ax: float = -x
		var env2: float = 1.0 - smoothstep(64.0, 96.0, absf(z))
		return (8.6 + 17.0 * smoothstep(10.0, 42.0, ax)) * (1.0 - smoothstep(50.0, 80.0, ax)) * env2 * (0.9 + 0.1 * sin(z * 0.21 + ax * 0.3))
	_heightfield(sub, xs, -98.0, 98.0, 22, hf)
	tunnels.append(sub)

func _sc_lake(mb: Kit, sub: Node3D, rng: RandomNumberGenerator) -> void:
	mb.box("icelake", Vector3(112.0, -0.2, 0), Vector3(184.0, 0.06, 250.0))
	for i in 22:
		var rs: float = rng.randf_range(0.6, 1.8)
		mb.box("rock", Vector3(19.0 + rng.randf() * 2.5, -0.05, -120.0 + float(i) * 11.0 + rng.randf() * 4.0), Vector3(rs * 1.4, rs * 0.7, rs), Basis(Vector3(0.2, 1.0, 0.3).normalized(), rng.randf() * 3.0))
	mb.box("wood", Vector3(20.0, 0.05, -6.0), Vector3(9.0, 0.14, 1.6))
	for i in 4:
		mb.cyl("wood", Vector3(16.5 + float(i) * 2.4, -0.1, -6.8), 0.09, 0.7, 1, 5)
		mb.cyl("wood", Vector3(16.5 + float(i) * 2.4, -0.1, -5.2), 0.09, 0.7, 1, 5)
	var huts: Array = [Vector3(34.0, 0, -18.0), Vector3(48.0, 0, 6.0), Vector3(40.0, 0, 30.0), Vector3(62.0, 0, -34.0)]
	for i in huts.size():
		var hp: Vector3 = huts[i]
		var hb := Basis(Vector3.UP, 0.3 * float(i) - 0.4)
		mb.box("wood" if i % 2 == 0 else "corr_blue", hp + Vector3(0, 0.95, 0), Vector3(2.0, 2.0, 2.4), hb)
		mb.box("roof", hp + Vector3(0, 2.04, 0), Vector3(2.4, 0.1, 2.8), hb)
		mb.box("snow", hp + Vector3(0, 2.14, 0), Vector3(2.2, 0.1, 2.6), hb)
		mb.cyl("steel_dk", hp + Vector3(0.5, 2.5, 0.4), 0.06, 0.9, 1, 6)
		mb.cyl("hull_blk", hp + Vector3(-1.9, -0.16, 0.6), 0.4, 0.012, 1, 10)
		if i == 1:
			mb.box("win_lit", hp + hb * Vector3(-1.02, 1.1, 0), Vector3(0.05, 0.6, 0.7), hb)
			var hl: OmniLight3D = Kit.omni(sub, hp + Vector3(-1.8, 1.2, 0), Color(1.0, 0.75, 0.45), 1.6, 9.0)
			hl.set_meta("e", 1.6)
			flickers.append(hl)
			_smoke(sub, hp + Vector3(0.5, 3.1, 0.4), 0.8, 6)
	# sledge and a man at his hole
	mb.box("wood", Vector3(44.0, 0.0, 9.0), Vector3(0.7, 0.12, 1.8))
	mb.box("sack", Vector3(44.0, 0.22, 9.2), Vector3(0.6, 0.3, 0.9))
	mb.cyl("wood", Vector3(46.4, 0.5, 7.4), 0.015, 1.6, 1, 4)
	_waver(sub, Vector3(46.0, -0.2, 6.8), PI * 0.5, 623 + mid_k, "work")
	_waver(sub, Vector3(21.5, 0.1, -6.0), PI * 0.5, 629 + mid_k, "idle")
	mb.box("wood", Vector3(24.5, 0.22, -11.0), Vector3(1.5, 0.5, 4.4), Basis(Vector3.BACK, PI) * Basis(Vector3.UP, 0.4))
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(17.0, -0.25, -2.6), 3)

func _sc_sawmill(mb: Kit, sub: Node3D) -> void:
	for p in 3:
		var pz: float = -34.0 + float(p) * 9.0
		for r in 3:
			for q in 3 - r:
				mb.cyl("wood", Vector3(15.0 + float(q) * 0.74 + float(r) * 0.37, 0.1 + float(r) * 0.62, pz), 0.36, 6.0, 2, 9)
		mb.box("snow", Vector3(15.74, 1.86, pz), Vector3(1.2, 0.1, 5.6))
	for i in 6:
		mb.box("wood", Vector3(22.0 + float(i % 3) * 7.0, 2.5, -4.0 + float(i / 3) * 9.0), Vector3(0.3, 5.5, 0.3))
	for sgn: float in [-1.0, 1.0]:
		mb.box("corr", Vector3(29.0, 5.9, 0.5 + sgn * 2.7), Vector3(17.0, 0.1, 6.0), Basis(Vector3.RIGHT, sgn * 0.28))
		mb.box("snow", Vector3(29.0, 6.02, 0.5 + sgn * 2.7), Vector3(16.6, 0.1, 5.6), Basis(Vector3.RIGHT, sgn * 0.28))
	mb.box("steel_dk", Vector3(29.0, 0.6, 0.5), Vector3(6.0, 0.9, 1.2))
	mb.cyl("steel", Vector3(29.0, 1.2, 0.5), 0.8, 0.03, 2, 18)
	mb.cyl("wood", Vector3(26.0, 1.3, 0.5), 0.34, 5.0, 0, 9)
	for i in 4:
		mb.box("wood", Vector3(20.0, 0.3 + 0.0, 14.0 + float(i) * 2.0), Vector3(1.3, 1.0, 5.0), Basis(Vector3.UP, PI * 0.5))
		mb.box("snow", Vector3(20.0, 0.86, 14.0 + float(i) * 2.0), Vector3(5.0, 0.1, 1.2))
	# the burner
	mb.cyl("rust", Vector3(42.0, 4.5, 22.0), 3.4, 9.5, 1, 14, 1.5)
	mb.cyl("fire", Vector3(42.0, 9.3, 22.0), 1.4, 0.2, 1, 12)
	mb.box("steel_dk", Vector3(36.0, 4.6, 12.0), Vector3(0.7, 0.3, 17.0), Basis(Vector3.UP, 0.54) * Basis(Vector3.RIGHT, 0.5))
	var bl: OmniLight3D = Kit.omni(sub, Vector3(42.0, 11.0, 22.0), Color(1.0, 0.5, 0.18), 3.0, 34.0)
	bl.set_meta("e", 3.0)
	flickers.append(bl)
	var sp: CPUParticles3D = Kit.particles(sub, Vector3(42.0, 9.6, 22.0), 10, 2.2, Color(1.0, 0.6, 0.2, 1.0), 0.16, true)
	sp.spread = 20.0
	sp.initial_velocity_min = 2.0
	sp.initial_velocity_max = 4.5
	_smoke(sub, Vector3(42.0, 10.4, 22.0), 3.2, 10)
	mb.cyl("sack", Vector3(34.0, 0.8, 26.0), 3.0, 2.2, 1, 9, 0.3)
	_lamp_post(mb, sub, Vector3(13.0, -0.25, 6.0), true, true)
	_waver(sub, Vector3(24.5, -0.25, 1.8), PI * 0.5, 717 + mid_k, "work")
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(13.4, -0.25, -8.0), 0)

func _sc_hilltop(mb: Kit, sub: Node3D) -> void:
	var xs: Array = [46.0, 54.0, 64.0, 76.0, 88.0, 98.0, 110.0, 124.0, 140.0, 160.0]
	var hf := func(x: float, z: float) -> float:
		return 40.0 * exp(-(x - 95.0) * (x - 95.0) / 2025.0 - z * z / 4900.0) * (0.94 + 0.06 * sin(z * 0.13 + x * 0.2))
	_heightfield(sub, xs, -150.0, 150.0, 24, hf)
	var top := Vector3(95.0, 39.2, 0.0)
	mb.cyl("white_paint", top + Vector3(0, 3.0, 0), 5.0, 6.4, 1, 18)
	mb.ball("white_paint", top + Vector3(0, 6.2, 0), Vector3(5.2, 5.0, 5.2), 16, 8)
	mb.box("glass_dark", top + Vector3(-3.4, 8.4, 0), Vector3(2.6, 3.8, 1.2), Basis(Vector3.BACK, 0.62))
	mb.box("win_lit", top + Vector3(-5.02, 2.6, 1.6), Vector3(0.06, 1.2, 1.0))
	mb.box("win_lit", top + Vector3(-5.02, 2.6, -1.8), Vector3(0.06, 1.2, 1.0))
	mb.cyl("white_paint", top + Vector3(4.0, 1.4, 11.0), 2.4, 3.6, 1, 14)
	mb.ball("white_paint", top + Vector3(4.0, 3.2, 11.0), Vector3(2.5, 2.4, 2.5), 12, 6)
	mb.cyl("steel_dk", top + Vector3(-2.0, 7.0, -10.0), 0.1, 15.0, 1, 5)
	mb.box("blink_a", top + Vector3(-2.0, 14.7, -10.0), Vector3(0.4, 0.4, 0.4))
	# the cable lift up from the line
	mb.box("rubber", Vector3(53.0, 24.5, 6.0), Vector3(87.2, 0.06, 0.06), Basis(Vector3.BACK, 0.4636))
	var pyl: Array = [[30.0, 0.0, 13.0], [55.0, 18.0, 25.5], [78.0, 34.5, 37.0]]
	for pe: Array in pyl:
		var h0: float = pe[1]
		var h1: float = pe[2]
		mb.box("steel_dk", Vector3(float(pe[0]), (h0 + h1) * 0.5, 6.0), Vector3(0.4, h1 - h0 + 0.6, 0.4))
		mb.box("steel_dk", Vector3(float(pe[0]), h1 + 0.2, 6.0), Vector3(0.3, 0.3, 2.4))
	mb.box("steel_dk", Vector3(42.0, 18.5, 6.0), Vector3(0.06, 1.0, 0.06))
	mb.box("red", Vector3(42.0, 17.2, 6.0), Vector3(1.8, 1.7, 1.3))
	mb.box("glass_dark", Vector3(42.0, 17.5, 5.34), Vector3(1.4, 0.7, 0.03))
	mb.sbox(mid_body, "wood", Vector3(14.0, 1.4, 6.0), Vector3(4.0, 3.2, 5.0))
	mb.box("roof", Vector3(14.0, 3.2, 6.0), Vector3(4.6, 0.16, 5.6))
	mb.box("snow", Vector3(14.0, 3.34, 6.0), Vector3(4.4, 0.12, 5.4))
	Kit.text3d(sub, Vector3(11.94, 2.2, 6.0), "OBSERVATORY LIFT", 40, Color(0.9, 0.86, 0.75), -PI * 0.5, 0.005)
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(11.0, -0.25, 9.6), 1)

func _sc_steamer(mb: Kit, sub: Node3D) -> void:
	var x := 9.4
	for sgn: float in [-1.0, 1.0]:
		mb.box("rust", Vector3(x + sgn * 0.75, -0.14, 0.0), Vector3(0.07, 0.15, 34.0))
	for i in 26:
		mb.box("sleeper", Vector3(x, -0.2, -16.5 + float(i) * 1.32), Vector3(2.5, 0.12, 0.24))
	mb.box("under", Vector3(x, 1.0, -2.6), Vector3(2.0, 0.5, 9.6))
	mb.cyl("rust", Vector3(x, 2.45, -3.6), 1.15, 6.4, 2, 16)
	mb.cyl("hull_blk", Vector3(x, 2.45, -7.2), 1.2, 0.9, 2, 16)
	mb.cyl("steel_dk", Vector3(x, 2.45, -7.68), 0.95, 0.06, 2, 14)
	mb.cyl("gun_brass", Vector3(x, 2.45, -7.72), 0.14, 0.06, 2, 8)
	mb.box("hull_blk", Vector3(x, 3.85, -7.5), Vector3(0.4, 0.4, 0.36))
	mb.cyl("lamp_white", Vector3(x, 3.85, -7.7), 0.15, 0.03, 2, 10)
	mb.cyl("hull_blk", Vector3(x, 4.15, -7.0), 0.32, 1.3, 1, 12, 0.44)
	mb.ball("gun_brass", Vector3(x, 3.7, -4.6), Vector3(0.46, 0.52, 0.46), 10, 6)
	mb.ball("rust", Vector3(x, 3.62, -2.6), Vector3(0.5, 0.4, 0.5), 10, 6)
	mb.cyl("gun_brass", Vector3(x, 3.75, -1.2), 0.05, 0.5, 1, 6)
	for bz: float in [-6.0, -4.6, -3.2, -1.8]:
		mb.cyl("steel_dk", Vector3(x, 2.45, bz), 1.17, 0.07, 2, 16)
	mb.box("red", Vector3(x, 2.9, 0.7), Vector3(2.5, 2.4, 2.3))
	mb.box("hull_blk", Vector3(x, 4.16, 0.9), Vector3(2.8, 0.12, 3.0))
	mb.box("snow", Vector3(x, 4.28, 0.9), Vector3(2.6, 0.12, 2.8))
	for sgn2: float in [-1.0, 1.0]:
		mb.box("glass_dark", Vector3(x + sgn2 * 1.26, 3.3, 0.6), Vector3(0.03, 0.8, 1.1))
		mb.box("gun_brass", Vector3(x + sgn2 * 1.262, 2.5, 0.7), Vector3(0.02, 0.2, 1.4))
		mb.cyl("hull_blk", Vector3(x + sgn2 * 1.0, 1.1, -7.0), 0.4, 1.2, 2, 10)
		mb.box("steel", Vector3(x + sgn2 * 1.04, 0.78, -3.6), Vector3(0.08, 0.12, 4.4))
		mb.box("steel", Vector3(x + sgn2 * 1.04, 0.95, -5.9), Vector3(0.07, 0.1, 1.6), Basis(Vector3.RIGHT, 0.12))
		for wz: float in [-5.6, -3.6, -1.6]:
			mb.cyl("red", Vector3(x + sgn2 * 0.9, 0.86, wz), 0.95, 0.14, 0, 18)
			mb.cyl("rail", Vector3(x + sgn2 * 0.9, 0.86, wz), 1.0, 0.06, 0, 18)
			mb.cyl("steel_dk", Vector3(x + sgn2 * 0.98, 0.86, wz), 0.2, 0.06, 0, 8)
			mb.box("steel_dk", Vector3(x + sgn2 * 0.98, 0.5, wz), Vector3(0.05, 0.4, 0.5))
		mb.cyl("wheel", Vector3(x + sgn2 * 0.9, 0.36, -7.6), 0.46, 0.12, 0, 12)
		for tz: float in [3.6, 5.2, 6.8]:
			mb.cyl("wheel", Vector3(x + sgn2 * 0.9, 0.4, tz), 0.5, 0.12, 0, 12)
	mb.box("hull_blk", Vector3(x, 2.0, 5.2), Vector3(2.4, 2.0, 5.4))
	mb.box("plastic", Vector3(x, 3.06, 5.6), Vector3(2.0, 0.2, 4.2))
	mb.box("snow", Vector3(x, 3.2, 5.4), Vector3(2.0, 0.12, 4.6))
	mb.box("red", Vector3(x, 0.9, -8.4), Vector3(2.5, 0.4, 0.2))
	mb.box("steel_dk", Vector3(x, 0.4, -8.9), Vector3(2.2, 0.7, 0.1), Basis(Vector3.RIGHT, -0.6))
	mb.box("snow", Vector3(x, 3.62, -3.6), Vector3(0.9, 0.1, 6.0))
	mb.cyl("snow", Vector3(x + 2.0, 0.1, -3.0), 2.2, 0.7, 1, 7, 0.5)
	mb.cyl("snow", Vector3(x - 1.6, 0.0, 6.0), 1.8, 0.5, 1, 7, 0.4)
	Kit.col(mid_body, Vector3(x, 2.0, -0.6), Vector3(2.8, 4.2, 16.4))
	Kit.text3d(sub, Vector3(x - 1.27, 2.52, 0.7), "NORDHAVEN BELLE", 26, Color(0.1, 0.08, 0.05), -PI * 0.5, 0.0045)
	Kit.text3d(sub, Vector3(x - 1.21, 2.2, 5.2), "N L  1 9 3 7", 44, Color(0.78, 0.6, 0.26), -PI * 0.5, 0.005)
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(7.2, -0.25, 3.4), 1)

func _sc_camp(mb: Kit, sub: Node3D, rng: RandomNumberGenerator) -> void:
	_tent(mb, mid_body, Vector3(13.6, -0.25, -11.0))
	_tent(mb, mid_body, Vector3(15.6, -0.25, 0.5))
	_tent(mb, mid_body, Vector3(13.2, -0.25, 11.5))
	_fire(mb, mid_body, sub, Vector3(10.2, -0.25, 0.0))
	for i in 2:
		var cr: Node3D = Kit.prop("crate", Vector3(0.98, 0.62, 0.72))
		if cr != null:
			cr.position = Vector3(11.6 + float(i) * 0.5, -0.25 + float(i) * 0.38, 5.4)
			cr.rotation.y = 0.3 * float(i) + 0.2
			sub.add_child(cr)
	var br: Node3D = Kit.prop("barrel", Vector3(0.62, 0.92, 0.62))
	if br != null:
		br.position = Vector3(11.0, -0.25, -5.6)
		sub.add_child(br)
	mb.cyl("wood", Vector3(8.6, 2.4, -14.0), 0.06, 5.4, 1, 6)
	mb.box("amber_paint", Vector3(8.6, 4.6, -13.3), Vector3(0.03, 0.8, 1.4))
	for sz: float in [-17.6, -14.4]:
		mb.cyl("wood", Vector3(8.2, 1.0, sz), 0.06, 2.6, 1, 5)
	mb.box("white_paint", Vector3(8.2, 1.9, -16.0), Vector3(0.1, 1.0, 3.4))
	Kit.text3d(sub, Vector3(8.13, 1.92, -16.0), "WE ARE STILL HERE", 44, Color(0.1, 0.1, 0.12), -PI * 0.5, 0.005)
	mb.box("rubber", Vector3(13.0, 2.0, 6.0), Vector3(0.012, 0.012, 9.0))
	var wash: Array = ["white_paint", "red", "seat", "canvas"]
	for i in 4:
		mb.box(str(wash[i]), Vector3(13.0, 1.68, 3.0 + float(i) * 1.6), Vector3(0.02, 0.6, 0.7))
	for sz2: float in [1.5, 10.5]:
		mb.cyl("wood", Vector3(13.0, 0.9, sz2), 0.05, 2.4, 1, 5)
	var ppl: Array = [[9.2, -1.4, "idle"], [9.0, 1.2, "idle"], [11.2, 0.9, "talk"], [8.8, 4.0, "idle"], [10.9, -1.2, "work"]]
	for i in ppl.size():
		var pe: Array = ppl[i]
		_waver(sub, Vector3(float(pe[0]), -0.25, float(pe[1])), PI * 0.5, 900 + mid_k * 7 + i * 13 + rng.randi() % 5, str(pe[2]))
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(12.0, -0.25, -6.8), 3)

func _sc_dishes(mb: Kit, sub: Node3D) -> void:
	var spots: Array = [Vector3(26.0, 0, -30.0), Vector3(44.0, 0, 2.0), Vector3(62.0, 0, 36.0)]
	for i in spots.size():
		var dp: Vector3 = spots[i]
		mb.cyl("concrete", dp + Vector3(0, 2.4, 0), 1.4, 5.4, 1, 12, 1.0)
		mb.box("steel_dk", dp + Vector3(0.9, 1.0, 0), Vector3(0.1, 2.4, 0.9))
		var rot := Node3D.new()
		rot.position = dp + Vector3(0, 5.1, 0)
		rot.rotation.y = float(i) * 1.3
		sub.add_child(rot)
		var dk := Kit.new()
		dk.box("steel_dk", Vector3(0, 0.5, 0), Vector3(1.2, 1.0, 1.2))
		dk.xf = Transform3D(Basis(Vector3.RIGHT, 0.95), Vector3(0, 1.2, 0))
		dk.cyl("white_paint", Vector3(0, 0.7, 0), 0.5, 1.4, 1, 18, 4.4)
		dk.cyl("grime", Vector3(0, 1.405, 0), 4.2, 0.01, 1, 18)
		dk.cyl("white_paint", Vector3(0, 1.41, 0), 4.05, 0.01, 1, 18)
		dk.cyl("steel_dk", Vector3(0, 2.5, 0), 0.05, 2.2, 1, 5)
		dk.box("steel_dk", Vector3(0, 3.6, 0), Vector3(0.4, 0.3, 0.4))
		for q in 3:
			var qb := Basis(Vector3.UP, float(q) * TAU / 3.0)
			dk.box("steel_dk", qb * Vector3(1.5, 2.5, 0), Vector3(0.04, 3.2, 0.04), qb * Basis(Vector3.BACK, 0.95))
		dk.xf = Transform3D.IDENTITY
		dk.commit(rot, false)
		turners.append(rot)
	mb.sbox(mid_body, "concrete", Vector3(16.0, 1.2, 12.0), Vector3(5.0, 2.9, 6.0))
	mb.box("snow", Vector3(16.0, 2.72, 12.0), Vector3(5.2, 0.12, 6.2))
	mb.box("win_lit", Vector3(13.47, 1.6, 12.0), Vector3(0.05, 0.8, 1.6))
	mb.cyl("steel_dk", Vector3(17.5, 6.0, 14.0), 0.07, 7.0, 1, 5)
	mb.box("blink_b", Vector3(17.5, 9.6, 14.0), Vector3(0.3, 0.3, 0.3))
	for f in 16:
		mb.box("steel_dk", Vector3(12.0, 0.8, -40.0 + float(f) * 5.5), Vector3(0.08, 2.2, 0.08))
	mb.box("steel_dk", Vector3(12.0, 1.8, 1.0), Vector3(0.04, 0.04, 83.0))
	mb.box("steel_dk", Vector3(12.0, 0.9, 1.0), Vector3(0.04, 0.04, 83.0))
	Kit.text3d(sub, Vector3(13.4, 2.4, 12.0), "NORTHLINE RADIO OBSERVATORY", 30, Color(0.9, 0.86, 0.75), -PI * 0.5, 0.005)
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(12.9, -0.25, 16.4), 1)

func _sc_airliner(mb: Kit, sub: Node3D, rng: RandomNumberGenerator) -> void:
	mb.box("soil", Vector3(46.0, -0.2, 34.0), Vector3(5.0, 0.06, 60.0), Basis(Vector3.UP, 0.5))
	var keep: Transform3D = mb.xf
	mb.xf = keep * Transform3D(Basis(Vector3.UP, 0.5) * Basis(Vector3.BACK, 0.1), Vector3(30.0, -0.3, -4.0))
	mb.cyl("hull_lt", Vector3(0, 1.8, -7.0), 1.9, 12.0, 2, 16)
	mb.cyl("hull_lt", Vector3(0, 1.8, -14.7), 0.5, 3.4, 2, 16, 1.9)
	mb.box("glass_dark", Vector3(0, 2.5, -14.9), Vector3(1.5, 0.5, 1.2), Basis(Vector3.RIGHT, -0.5))
	mb.cyl("hull_blk", Vector3(0, 1.8, -0.98), 1.8, 0.05, 2, 16)
	mb.box("snow", Vector3(0, 3.66, -7.0), Vector3(2.2, 0.12, 11.0))
	for sgn: float in [-1.0, 1.0]:
		mb.box("corr_blue", Vector3(sgn * 1.9, 1.5, -7.0), Vector3(0.03, 0.3, 12.0))
		for w in 14:
			mb.box("glass_dark", Vector3(sgn * 1.87, 2.2, -12.4 + float(w) * 0.8), Vector3(0.04, 0.3, 0.24))
	mb.box("hull_blk", Vector3(-1.88, 1.6, -3.0), Vector3(0.05, 1.8, 0.9))
	mb.box("amber_paint", Vector3(-3.4, 0.6, -3.0), Vector3(3.4, 0.3, 1.2), Basis(Vector3.BACK, 0.42))
	mb.box("hull_lt", Vector3(9.0, 1.2, -5.0), Vector3(15.0, 0.34, 4.0), Basis(Vector3.UP, -0.32) * Basis(Vector3.BACK, 0.08))
	mb.box("hull_lt", Vector3(-4.0, 2.2, -5.0), Vector3(5.0, 0.34, 3.6), Basis(Vector3.UP, 0.3) * Basis(Vector3.BACK, -0.5))
	mb.cyl("steel_dk", Vector3(6.5, 0.4, -6.4), 1.0, 3.2, 2, 14)
	mb.cyl("hull_blk", Vector3(6.5, 0.4, -8.02), 0.8, 0.04, 2, 12)
	mb.cyl("hull_lt", Vector3(1.2, 1.7, 10.0), 1.9, 9.0, 2, 16)
	mb.cyl("hull_lt", Vector3(1.2, 2.0, 17.0), 1.9, 5.0, 2, 16, 0.6)
	mb.cyl("hull_blk", Vector3(1.2, 1.7, 5.48), 1.8, 0.05, 2, 16)
	mb.box("hull_lt", Vector3(1.2, 5.4, 17.0), Vector3(0.26, 5.6, 3.4), Basis(Vector3.RIGHT, 0.5))
	mb.box("corr_blue", Vector3(1.2, 6.6, 17.8), Vector3(0.28, 2.0, 2.6), Basis(Vector3.RIGHT, 0.5))
	mb.box("hull_lt", Vector3(1.2, 2.6, 18.2), Vector3(7.0, 0.2, 2.0))
	mb.box("snow", Vector3(1.2, 3.56, 10.0), Vector3(2.2, 0.12, 8.4))
	mb.xf = keep
	var bags: Array = ["seat_dk", "red", "sack", "hull", "canvas", "seat"]
	for i in 16:
		mb.box(str(bags[i % bags.size()]), Vector3(20.0 + rng.randf() * 22.0, -0.06, -14.0 + rng.randf() * 30.0), Vector3(0.7, 0.36, 0.3), Basis(Vector3.UP, rng.randf() * 3.0))
	for i in 5:
		mb.box("seat", Vector3(22.0 + rng.randf() * 14.0, 0.2, -6.0 + rng.randf() * 18.0), Vector3(0.5, 0.9, 0.5), Basis(Vector3(0.4, 1.0, 0.2).normalized(), rng.randf() * 3.0))
	Kit.col(mid_body, Vector3(30.0, 1.6, -4.0), Vector3(5.0, 3.8, 30.0), Basis(Vector3.UP, 0.5))
	_loot(mb, mid_body, sub, mid_k, mid_id, Vector3(24.4, -0.25, 3.0), 3)
	_loot(mb, mid_body, sub, mid_k, mid_id + 1, Vector3(22.0, -0.25, -9.0), 0)

func _sc_cooling(mb: Kit, sub: Node3D) -> void:
	var prof: Array = [[1.0, 0.0], [0.84, 0.28], [0.7, 0.56], [0.64, 0.76], [0.7, 1.0]]
	var spots: Array = [Vector3(86.0, 0, -44.0), Vector3(126.0, 0, 10.0)]
	for ti in spots.size():
		var tp: Vector3 = spots[ti]
		for i in 4:
			var a: Array = prof[i]
			var b: Array = prof[i + 1]
			mb.cyl("concrete", tp + Vector3(0, (float(a[1]) + float(b[1])) * 27.0, 0), float(a[0]) * 19.0, (float(b[1]) - float(a[1])) * 54.0, 1, 22, float(b[0]) * 19.0)
		mb.cyl("hull_blk", tp + Vector3(0, 54.05, 0), 12.6, 0.1, 1, 22)
		for q in 12:
			var qa: float = float(q) * TAU / 12.0
			mb.box("concrete", tp + Vector3(cos(qa) * 19.4, 2.0, sin(qa) * 19.4), Vector3(0.8, 4.6, 0.8), Basis(Vector3.UP, -qa) * Basis(Vector3.BACK, 0.3))
		mb.box("grime", tp + Vector3(-13.2, 30.0, 0), Vector3(0.2, 30.0, 3.0))
		if ti == 0:
			var st: CPUParticles3D = Kit.particles(sub, tp + Vector3(0, 56.0, 0), 12, 9.0, Color(0.9, 0.92, 0.95, 0.26), 24.0)
			st.spread = 14.0
			st.direction = Vector3(0.3, 1.0, 0.2).normalized()
			st.initial_velocity_min = 3.0
			st.initial_velocity_max = 5.5
			st.gravity = Vector3(0.6, 0.1, 0.5)
			mb.box("blink_a", tp + Vector3(-12.8, 54.6, 0), Vector3(0.5, 0.5, 0.5))
		else:
			mb.box("blink_b", tp + Vector3(-12.8, 54.6, 0), Vector3(0.5, 0.5, 0.5))
	mb.box("corr", Vector3(64.0, 9.0, 38.0), Vector3(26.0, 18.5, 60.0))
	mb.box("snow", Vector3(64.0, 18.4, 38.0), Vector3(25.6, 0.3, 59.6))
	for w in 8:
		mb.box("win_lit" if w % 3 == 1 else "glass_dark", Vector3(50.95, 11.0, 14.0 + float(w) * 7.0), Vector3(0.08, 6.0, 3.0))
	mb.cyl("concrete", Vector3(70.0, 35.0, 78.0), 2.6, 70.5, 1, 14, 1.8)
	for b2 in 3:
		mb.cyl("red", Vector3(70.0, 50.0 + float(b2) * 8.0, 78.0), 2.24 - float(b2) * 0.1, 3.0, 1, 14)
	mb.box("blink_a", Vector3(70.0, 70.6, 78.0), Vector3(0.5, 0.5, 0.5))
	for p in 3:
		var px: float = 22.0 + float(p) * 9.0
		mb.box("steel_dk", Vector3(px, 4.0, 0.0), Vector3(0.3, 8.5, 0.3))
		mb.box("steel_dk", Vector3(px, 7.6, 0.0), Vector3(0.2, 0.2, 5.0))
		for o: float in [-2.2, 0.0, 2.2]:
			mb.cyl("white_paint", Vector3(px, 7.1, o), 0.1, 0.8, 1, 6)
	for o2: float in [-2.2, 0.0, 2.2]:
		mb.box("rubber", Vector3(31.0, 6.7, o2), Vector3(19.0, 0.04, 0.04))
	mb.box("steel_dk", Vector3(16.0, 1.0, 0.0), Vector3(0.08, 2.4, 60.0))
	mb.box("amber_paint", Vector3(15.9, 1.6, 6.0), Vector3(0.05, 0.7, 1.0))

func _slot_sea(mb: Kit, sub: Node3D, rng: RandomNumberGenerator, i: int) -> void:
	# each slot covers its own 280 m of shore; the first and last meet the station's sea
	var za: float = 140.0
	var zb: float = -140.0
	if i == 0:
		za = 210.0
	elif i == SLOT_OFF.size() - 1:
		zb = 110.0
	var zc: float = (za + zb) * 0.5
	var zl: float = za - zb
	var sea := MeshInstance3D.new()
	var spm := PlaneMesh.new()
	spm.size = Vector2(900, zl)
	sea.mesh = spm
	sea.material_override = Kit.plain("water")
	sea.position = Vector3(-464.0, -0.17, zc)
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sub.add_child(sea)
	mb.sbox(mid_body, "concrete", Vector3(-13.6, 0.2, zc), Vector3(0.8, 1.3, zl))
	for r in 12:
		var rs: float = rng.randf_range(1.0, 2.6)
		mb.box("concrete", Vector3(-15.0 - rng.randf() * 2.5, -0.1, zb + (float(r) + rng.randf()) * zl / 12.0), Vector3(rs, rs * 0.7, rs), Basis(Vector3(0.3, 1, 0.2).normalized(), rng.randf() * 3.0))
	# the land side rises into a headland
	var xs: Array = [7.6, 9.0, 12.0, 16.0, 22.0, 30.0, 40.0, 52.0, 66.0]
	var hgt: float = rng.randf_range(12.0, 26.0)
	var ph: float = rng.randf() * 6.0
	var hf := func(x: float, z: float) -> float:
		var env2: float = 1.0 - smoothstep(96.0, 138.0, absf(z))
		return hgt * smoothstep(8.0, 30.0, x) * env2 * (0.78 + 0.22 * sin(z * 0.05 + ph) + 0.08 * sin(z * 0.31 + x * 0.2))
	_heightfield(sub, xs, -140.0, 140.0, 20, hf)

func _sc_stacks(mb: Kit, sub: Node3D, rng: RandomNumberGenerator) -> void:
	var spots: Array = [Vector3(-70.0, 0, -44.0), Vector3(-112.0, 0, 16.0), Vector3(-150.0, 0, 74.0)]
	for i in spots.size():
		var sp: Vector3 = spots[i]
		var h: float = 30.0 + rng.randf() * 14.0
		var r: float = 8.0 + rng.randf() * 4.0
		mb.cyl("rock", sp + Vector3(0, h * 0.28, 0), r, h * 0.56, 1, 9, r * 0.74)
		mb.cyl("rock", sp + Vector3(1.0, h * 0.78, 0.6), r * 0.74, h * 0.44, 1, 8, r * 0.46)
		mb.cyl("snow", sp + Vector3(1.0, h + 0.2, 0.6), r * 0.48, 0.5, 1, 8, r * 0.3)
		mb.cyl("ice", sp + Vector3(0, 0.3, 0), r + 2.2, 0.5, 1, 10)
		for q in 4:
			var rr: float = 1.5 + rng.randf() * 2.5
			mb.cyl("rock", sp + Vector3(cos(float(q) * 1.7) * (r + 5.0), rr * 0.4, sin(float(q) * 1.7) * (r + 5.0)), rr, rr * 1.2, 1, 6, rr * 0.5)
	mb.cyl("rock", Vector3(-40.0, 3.0, 110.0), 5.0, 8.0, 1, 7, 2.6)
	mb.cyl("snow", Vector3(-40.0, 7.1, 110.0), 2.7, 0.3, 1, 7)

func _sc_shipwreck(mb: Kit, sub: Node3D) -> void:
	var keep: Transform3D = mb.xf
	mb.xf = keep * Transform3D(Basis(Vector3.UP, 0.28) * Basis(Vector3.BACK, 0.2), Vector3(-58.0, -1.0, 0.0))
	mb.box("hull_blk", Vector3(0, 4.6, 0), Vector3(13.0, 9.0, 74.0))
	mb.box("red", Vector3(0, 0.8, 0), Vector3(13.1, 1.8, 74.1))
	mb.box("hull_blk", Vector3(0, 6.0, -40.0), Vector3(8.0, 8.0, 8.0), Basis(Vector3.UP, 0.78))
	mb.box("white_paint", Vector3(0, 14.0, 24.0), Vector3(11.0, 10.0, 12.0))
	for r in 3:
		for q in 4:
			mb.box("glass_dark", Vector3(5.52, 11.5 + float(r) * 2.6, 20.0 + float(q) * 2.8), Vector3(0.06, 1.0, 1.6))
	mb.cyl("red", Vector3(0, 22.0, 27.0), 1.8, 6.0, 1, 12)
	mb.cyl("hull_blk", Vector3(0, 25.2, 27.0), 1.86, 0.8, 1, 12)
	mb.cyl("steel_dk", Vector3(0, 15.0, -14.0), 0.3, 12.0, 1, 6)
	mb.box("steel_dk", Vector3(0, 17.0, -8.0), Vector3(0.3, 0.3, 13.0), Basis(Vector3.RIGHT, 0.4))
	for i in 5:
		mb.box(["corr_red", "corr_blue", "corr_amber"][i % 3], Vector3(-1.5 + float(i % 2) * 3.0, 10.4, -28.0 + float(i) * 7.0), Vector3(2.44, 2.6, 6.06))
	for i in 6:
		mb.box("rust", Vector3(6.52, 5.0 - float(i % 2), -30.0 + float(i) * 11.0), Vector3(0.05, 5.0, 1.4))
	mb.box("snow", Vector3(0, 9.16, -6.0), Vector3(12.4, 0.2, 40.0))
	mb.xf = keep
	for i in 5:
		mb.cyl("ice", Vector3(-36.0 - float(i) * 3.0, -0.05, -30.0 + float(i) * 16.0), 3.0 + float(i % 3), 0.3, 1, 7)

func _sc_rig(mb: Kit, sub: Node3D) -> void:
	var c := Vector3(-170.0, 0, 10.0)
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			mb.cyl("steel_dk", c + Vector3(a * 12.0, 13.0, b * 12.0), 1.7, 28.0, 1, 10)
			mb.box("steel_dk", c + Vector3(a * 12.0, 10.0, 0), Vector3(0.6, 0.6, 24.0), Basis(Vector3.RIGHT, b * 0.0))
		mb.box("steel_dk", c + Vector3(0, 12.0, a * 12.0), Vector3(24.0, 0.6, 0.6), Basis(Vector3.BACK, 0.5))
	mb.box("hull_lt", c + Vector3(0, 28.0, 0), Vector3(32.0, 3.4, 32.0))
	mb.box("amber_paint", c + Vector3(0, 30.0, 0), Vector3(32.4, 0.4, 32.4))
	mb.box("white_paint", c + Vector3(8.0, 34.0, -8.0), Vector3(10.0, 8.0, 12.0))
	for q in 4:
		mb.box("win_lit" if q % 2 == 0 else "glass_dark", c + Vector3(13.05, 34.0 + float(q / 2) * 2.6, -11.0 + float(q % 2) * 5.0), Vector3(0.08, 1.2, 2.4))
	for a2: float in [-1.0, 1.0]:
		for b2: float in [-1.0, 1.0]:
			mb.box("steel_dk", c + Vector3(-6.0 + a2 * 2.0, 46.0, 4.0 + b2 * 2.0), Vector3(0.4, 33.0, 0.4), Basis(Vector3.BACK, a2 * 0.11) * Basis(Vector3.RIGHT, -b2 * 0.11))
	for lv in 4:
		var w: float = 7.4 - float(lv) * 1.7
		mb.box("steel_dk", c + Vector3(-6.0, 34.0 + float(lv) * 8.0, 4.0), Vector3(w, 0.3, w))
	mb.box("blink_a", c + Vector3(-6.0, 62.8, 4.0), Vector3(0.6, 0.6, 0.6))
	mb.cyl("hull_lt", c + Vector3(16.0, 31.2, 14.0), 7.0, 0.5, 1, 14)
	mb.box("steel_dk", c + Vector3(-22.0, 36.0, -14.0), Vector3(24.0, 0.6, 0.6), Basis(Vector3.BACK, 0.5))
	var tip: Vector3 = c + Vector3(-32.6, 41.8, -14.0)
	mb.box("fire", tip, Vector3(1.2, 1.6, 1.2))
	var fl: CPUParticles3D = Kit.particles(sub, tip + Vector3(0, 1.0, 0), 10, 0.9, Color(1.0, 0.55, 0.15, 0.9), 5.0, true)
	fl.initial_velocity_min = 4.0
	fl.initial_velocity_max = 8.0
	var ol: OmniLight3D = Kit.omni(sub, tip + Vector3(0, 2.0, 0), Color(1.0, 0.55, 0.2), 4.0, 90.0)
	ol.set_meta("e", 4.0)
	flickers.append(ol)
	mb.box("amber_paint", c + Vector3(12.0, 36.0, 12.0), Vector3(1.0, 9.0, 1.0))
	mb.box("amber_paint", c + Vector3(19.0, 42.0, 12.0), Vector3(16.0, 0.7, 0.7), Basis(Vector3.BACK, 0.3))

func _sc_pier(mb: Kit, sub: Node3D) -> void:
	mb.box("wood", Vector3(-38.0, 1.2, 0.0), Vector3(48.0, 0.2, 3.2))
	for i in 9:
		for sgn: float in [-1.0, 1.0]:
			mb.cyl("wood", Vector3(-16.0 - float(i) * 5.6, 0.3, sgn * 1.4), 0.16, 2.2, 1, 6)
			mb.box("wood", Vector3(-16.0 - float(i) * 5.6, 1.8, sgn * 1.55), Vector3(0.08, 1.0, 0.08))
	for sgn2: float in [-1.0, 1.0]:
		mb.box("wood", Vector3(-38.0, 2.25, sgn2 * 1.55), Vector3(46.0, 0.07, 0.07))
	mb.box("wood", Vector3(-62.0, 1.2, 0.0), Vector3(7.0, 0.2, 7.0))
	mb.box("corr_blue", Vector3(-62.6, 2.75, 0.0), Vector3(4.0, 2.9, 4.2))
	mb.box("roof", Vector3(-62.6, 4.3, 0.0), Vector3(4.6, 0.14, 4.8))
	mb.box("snow", Vector3(-62.6, 4.42, 0.0), Vector3(4.4, 0.1, 4.6))
	mb.box("win_lit", Vector3(-60.57, 2.9, 0.6), Vector3(0.06, 0.9, 1.2))
	mb.cyl("steel_dk", Vector3(-59.0, 3.2, -2.6), 0.06, 4.0, 1, 5)
	mb.box("lamp_warm", Vector3(-59.0, 5.1, -2.6), Vector3(0.3, 0.2, 0.3))
	var pl: OmniLight3D = Kit.omni(sub, Vector3(-59.0, 4.6, -2.6), Color(1.0, 0.78, 0.48), 2.6, 18.0)
	pl.set_meta("e", 2.6)
	mb.box("corr_blue", Vector3(-40.0, 0.25, 4.6), Vector3(2.0, 1.0, 5.6), Basis(Vector3.BACK, 0.12))
	mb.box("white_paint", Vector3(-40.0, 1.1, 5.4), Vector3(1.5, 0.9, 1.8), Basis(Vector3.BACK, 0.12))
	mb.cyl("steel_dk", Vector3(-40.0, 2.0, 3.6), 0.04, 2.4, 1, 5)
	for i in 4:
		mb.cyl("wood", Vector3(-24.0 - float(i) * 3.0, 2.2, -1.5), 0.05, 2.0, 1, 5)
	mb.box("canvas", Vector3(-28.5, 2.5, -1.5), Vector3(9.0, 1.2, 0.03))
	mb.box("wood", Vector3(-14.4, 0.9, 0.0), Vector3(2.4, 0.2, 3.2), Basis(Vector3.BACK, -0.25))
	_waver(sub, Vector3(-54.0, 1.3, 0.4), -PI * 0.5, 1301 + mid_k, "idle")

func _sc_icefield(mb: Kit, sub: Node3D, rng: RandomNumberGenerator) -> void:
	for i in 46:
		var r: float = rng.randf_range(2.0, 7.5)
		var p := Vector3(-19.0 - pow(rng.randf(), 1.3) * 210.0, -0.08, rng.randf_range(-205.0, 205.0))
		mb.xf = Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p)
		mb.cyl("ice", Vector3.ZERO, r, 0.34, 1, 6 + i % 3)
		if i % 2 == 0:
			mb.cyl("snow", Vector3(r * 0.1, 0.2, 0), r * 0.7, 0.1, 1, 6)
	mb.xf = Transform3D.IDENTITY
	for i in 12:
		var s2: float = rng.randf_range(2.0, 6.0)
		mb.box("ice", Vector3(-24.0 - rng.randf() * 120.0, 0.4, rng.randf_range(-190.0, 190.0)), Vector3(s2, 0.4, s2 * 1.4), Basis(Vector3(rng.randf() - 0.5, 0.3, rng.randf() - 0.5).normalized(), rng.randf_range(0.3, 0.8)))
