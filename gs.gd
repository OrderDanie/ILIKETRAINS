class_name GS
extends RefCounted
## Centralised game state + pure simulation. Nothing in here touches the scene tree.

const SP := 2700.0
const NLOC := 10
const LOCS := [
	{"name": "Nordhaven Station", "kind": "Abandoned station", "car": "", "infected": 2, "loot": ["food", "food", "water", "water", "medicine", "scrap"]},
	{"name": "Karsk Maintenance Depot", "kind": "Railway depot", "car": "workshop", "infected": 3, "loot": ["tools", "parts", "parts", "scrap", "scrap", "diesel", "ammo"]},
	{"name": "Vostok Central", "kind": "Abandoned city", "car": "medical", "infected": 7, "loot": ["medicine", "medicine", "electronics", "food", "batteries", "water", "ammo", "ammo_shell"]},
	{"name": "Ironworks District", "kind": "Industrial district", "car": "generator", "infected": 5, "loot": ["diesel", "diesel", "batteries", "electronics", "scrap", "parts", "ammo_rifle"]},
	{"name": "Depot 9 Warehouses", "kind": "Warehouses", "car": "kitchen", "infected": 4, "loot": ["food", "food", "food", "water", "water", "tools", "ammo_shell", "ammo_rifle"]},
	{"name": "Haven Junction", "kind": "Survivor settlement", "car": "passenger", "infected": 0, "loot": ["food", "water"]},
	{"name": "Fort Varda", "kind": "Military installation", "car": "security", "infected": 0, "loot": ["ammo", "ammo_rifle", "ammo_rifle", "ammo_mag", "medicine", "parts", "diesel", "tools"]},
	{"name": "Cape Halt", "kind": "Coastal railway", "car": "greenhouse", "infected": 3, "loot": ["water", "food", "scrap", "batteries"]},
	{"name": "Port of Kaldwick", "kind": "Port", "car": "water", "infected": 6, "loot": ["diesel", "diesel", "electronics", "parts", "food", "scrap"]},
	{"name": "Greywater Halt", "kind": "Abandoned station", "car": "storage", "infected": 3, "loot": ["food", "water", "medicine", "scrap", "parts", "batteries", "ammo_mag", "ammo_rifle"]},
]
const ITEMS := {
	"food": {"name": "Canned Food", "desc": "Sealed rations. One tin feeds one person once. Spoils faster without power.", "w": 1.0},
	"water": {"name": "Clean Water", "desc": "Drinking water, one litre bottles.", "w": 1.0},
	"medicine": {"name": "Medical Supplies", "desc": "Bandages and antibiotics. Stops bleeding, cures illness.", "w": 0.5},
	"diesel": {"name": "Diesel Can", "desc": "10 litre jerrycan. Stored cans are poured into the locomotive tank.", "w": 3.0},
	"batteries": {"name": "Battery Cells", "desc": "Each stored cell adds 15 kWh to the train battery bank.", "w": 1.5},
	"tools": {"name": "Tool Kit", "desc": "Required for repairs, coupling and clearing the line.", "w": 2.0},
	"electronics": {"name": "Electronics", "desc": "Circuit boards and wiring for crafting and upgrades.", "w": 0.5},
	"parts": {"name": "Repair Materials", "desc": "Steel plate, seals and fittings. Used for all train repairs.", "w": 2.0},
	"scrap": {"name": "Scrap Metal", "desc": "Raw material for the workbench. Traded at settlements.", "w": 1.0},
	"ammo": {"name": "9 mm Rounds", "desc": "Pistols and submachine guns. Also used by guards defending the train.", "w": 0.02},
	"ammo_rifle": {"name": "Rifle Rounds", "desc": "5.56 and 7.62 mm. Carbines, assault rifles, marksman rifles and machine guns.", "w": 0.03},
	"ammo_shell": {"name": "12 Gauge Shells", "desc": "Buckshot for the pump shotgun.", "w": 0.05},
	"ammo_mag": {"name": "Magnum Rounds", "desc": ".44 and .338. Revolvers and precision rifles.", "w": 0.05},
}
const ASSIGN := {
	"Idle": {"jobs": [], "car": "", "desc": "Rests and keeps others company."},
	"Repairs": {"jobs": ["Mechanic", "Engineer"], "car": "", "desc": "Slowly repairs the most damaged system. Uses repair materials."},
	"Cooking": {"jobs": ["Cook"], "car": "kitchen", "desc": "Hot meals: -25% food use, better morale. Needs Kitchen car."},
	"Medical": {"jobs": ["Doctor", "Nurse"], "car": "", "desc": "Treats the sick and injured. Uses medical supplies."},
	"Farming": {"jobs": ["Farmer"], "car": "greenhouse", "desc": "Grows food. Needs Greenhouse car and power."},
	"Water": {"jobs": ["Engineer"], "car": "water", "desc": "Purifies snow melt. Needs Water Treatment car and power."},
	"Power": {"jobs": ["Electrician", "Engineer"], "car": "", "desc": "Tunes generation: -10% load, more generator output."},
	"Guard": {"jobs": ["Security"], "car": "", "desc": "Defends a stopped train. Uses ammunition."},
	"Sanitation": {"jobs": [], "car": "", "desc": "Cleans carriages and handles waste."},
}
const RECIPES := [
	{"id": "parts", "name": "Repair Materials x2", "cost": {"scrap": 3}, "give": {"parts": 2}, "car": ""},
	{"id": "ammo", "name": "Pistol Rounds x8", "cost": {"scrap": 2, "electronics": 1}, "give": {"ammo": 8}, "car": "workshop"},
	{"id": "med", "name": "Medical Supplies x1", "cost": {"water": 2, "electronics": 1}, "give": {"medicine": 1}, "car": "medical"},
	{"id": "cell", "name": "Battery Cell x1", "cost": {"electronics": 2, "scrap": 2}, "give": {"batteries": 1}, "car": "workshop"},
	{"id": "tools", "name": "Tool Kit x1", "cost": {"scrap": 4, "parts": 1}, "give": {"tools": 1}, "car": ""},
]
const UPGRADES := [
	{"id": "insulation", "name": "Insulated Panels", "desc": "Heat loss and heating load -30%.", "cost": {"parts": 5, "scrap": 4}},
	{"id": "armour", "name": "Hull Armour Plating", "desc": "Hull damage from attacks -50%.", "cost": {"parts": 8, "scrap": 6}},
	{"id": "battery", "name": "Battery Bank Expansion", "desc": "+60 kWh battery capacity.", "cost": {"batteries": 3, "electronics": 3}},
	{"id": "lamps", "name": "High-Output Headlights", "desc": "Headlights reach much further.", "cost": {"electronics": 3, "parts": 2}},
	{"id": "injectors", "name": "Engine Overhaul", "desc": "Diesel consumption -25%.", "cost": {"parts": 6, "tools": 1, "electronics": 2}},
]
const POOL_NAMES := ["Anja Falk", "Marek Dvorak", "Sofia Lund", "Emil Krause", "Ilse Varga", "Oskar Nyman", "Tilda Brandt", "Viktor Hale", "Maren Olsen", "Darius Kohl", "Edda Stein", "Rurik Havel"]
const POOL_JOBS := ["Mechanic", "Doctor", "Nurse", "Engineer", "Cook", "Farmer", "Electrician", "Security"]
const TRAITS := ["Stoic", "Anxious", "Cheerful", "Gruff", "Resourceful", "Quiet", "Protective", "Stubborn"]
const FIXED_RECRUITS := {"2": ["Lena Voss", "Nurse"], "3": ["Pavel Orlov", "Electrician"], "4": ["Greta Holm", "Farmer"], "5": ["Sami Qureshi", "Engineer"], "7": ["Niko Aalto", "Farmer"], "9": ["Jonas Berg", "Mechanic"]}
const KEY_DEFAULTS := {"move_up": KEY_W, "move_down": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "jump": KEY_SPACE, "sprint": KEY_SHIFT, "crouch": KEY_C, "interact": KEY_E, "flashlight": KEY_F, "inventory": KEY_TAB, "map": KEY_M, "objectives": KEY_J, "manage": KEY_T, "horn": KEY_H, "headlights": KEY_L, "autopilot": KEY_P, "doors": KEY_G, "reload": KEY_R, "inspect": KEY_V, "swap": KEY_Q, "manual": KEY_N}
const KEY_LABELS := {"move_up": "Move forward / Throttle up", "move_down": "Move back / Throttle down", "move_left": "Strafe left", "move_right": "Strafe right", "jump": "Jump / Train brake", "sprint": "Sprint", "crouch": "Crouch", "interact": "Interact", "flashlight": "Flashlight", "inventory": "Inventory", "map": "Railway map", "objectives": "Objectives", "manage": "Train management", "horn": "Horn", "headlights": "Headlights", "autopilot": "Autopilot", "doors": "Carriage doors (aboard)", "reload": "Reload weapon", "inspect": "Inspect weapon", "swap": "Next weapon", "manual": "Field manual"}

static var train: Dictionary = {}
static var loco: Dictionary = {}
static var cars: Array = []
static var crew: Array = []
static var inv: Dictionary = {}
static var store: Dictionary = {}
static var player: Dictionary = {}
static var time := 0.0
static var weather := "snow"
static var weather_t := 300.0
static var discovered: Dictionary = {}
static var looted: Dictionary = {}
static var coupled: Dictionary = {}
static var recruited: Dictionary = {}
static var events: Dictionary = {}
static var objective := 0
static var stats: Dictionary = {}
static var upgrades: Dictionary = {}
static var radio_log: Array = []
static var ppos: Array = []
static var settings: Dictionary = {}
static var weapons: Dictionary = {}
static var story: Dictionary = {}
static var cur_weapon := "p9"
static var boot := ""
static var calibrated := false
static var boot_slot := 0
static var slot := 1
# transient (not saved)
static var warnings: Array = []
static var msgs: Array = []
static var power_ok := true
static var kw_gen := 0.0
static var kw_load := 0.0
static var t_out := -15.0
static var under_attack := 0.0
static var food_acc := 0.0
static var water_acc := 0.0
static var hour_acc := 0.0
static var speed_limit := 33.0

static func mk_crew(cname: String, job: String, skill: int, look: int) -> Dictionary:
	var assign := "Idle"
	for a: String in ASSIGN.keys():
		var jobs: Array = ASSIGN[a]["jobs"]
		var need: String = ASSIGN[a]["car"]
		if jobs.has(job) and (need == "" or has_car(need)) and assign == "Idle":
			assign = a
	return {"name": cname, "job": job, "skill": skill, "trait": TRAITS[look % TRAITS.size()], "health": 90.0, "hunger": 15.0, "thirst": 15.0, "fatigue": 30.0, "morale": 62.0, "sick": false, "assign": assign, "act": "Sitting", "rel": {}, "look": look, "trust": 0.0}

static func reset_new() -> void:
	train = {"s": 0.0, "speed": 0.0, "throttle": 0.0, "brake": 1.0, "engine_on": false, "headlights": false, "wipers": false, "doors_open": false, "autopilot": false, "ap_target": 0.0, "diesel": 420.0, "battery": 80.0, "heating": true, "vent": true, "lights": true, "temp": 15.0, "air": 88.0, "sanitation": 78.0, "ration": 1.0, "gen_on": true}
	loco = {"engine": 82.0, "brakes": 86.0, "electrical": 74.0, "hull": 88.0}
	cars = [{"type": "passenger", "hull": 84.0, "sys": 80.0}, {"type": "storage", "hull": 71.0, "sys": 76.0}]
	crew = []
	crew.append(mk_crew("Mara Lindqvist", "Mechanic", 4, 3))
	crew.append(mk_crew("Tomas Reyes", "Doctor", 4, 8))
	crew.append(mk_crew("Ivo Brandt", "Security", 3, 14))
	crew.append(mk_crew("Hanne Sorel", "Cook", 3, 21))
	inv = {"food": 1, "water": 1, "ammo": 28, "medicine": 1}
	weapons = {"p9": 14}
	story = Story.fresh()
	cur_weapon = "p9"
	store = {"food": 20, "water": 24, "medicine": 3, "parts": 4, "tools": 1, "scrap": 3, "electronics": 1, "batteries": 1, "ammo": 16}
	player = {"health": 100.0, "stamina": 100.0, "hunger": 22.0, "thirst": 22.0, "fatigue": 28.0, "cold": 0.0, "bleeding": false, "sick": false}
	time = 21.0 * 60.0 + 12.0
	weather = "snow"
	weather_t = 420.0
	discovered = {"0": true}
	looted = {}
	coupled = {}
	recruited = {}
	events = {}
	objective = 0
	upgrades = {}
	radio_log = []
	ppos = []
	stats = {"minutes": 0.0, "distance": 0.0, "stops": 0, "laps": 0, "recruited": 0, "lost": 0, "neutralised": 0, "looted": 0, "coupled": 0, "crafted": 0, "repairs": 0, "transfers": 0}
	warnings = []
	msgs = []
	under_attack = 0.0
	speed_limit = 33.0

# ---------- helpers ----------
## The stop at position k on the line. One k can be Meridian Central once Corridor Seven is open.
static func loc_at(k: int) -> Dictionary:
	if Story.is_meridian(k):
		return Story.MERIDIAN
	return LOCS[posmod(k, NLOC)]

static func hour() -> float:
	return fposmod(time, 1440.0) / 60.0

static func day() -> int:
	return int(floor((time - 21.0 * 60.0) / 1440.0)) + 1

static func clock() -> String:
	var m: int = int(fposmod(time, 1440.0))
	return "%02d:%02d" % [m / 60, m % 60]

static func people() -> int:
	return crew.size() + 1

static func has_car(t: String) -> bool:
	for c: Dictionary in cars:
		if c["type"] == t:
			return true
	return false

static func car_count(t: String) -> int:
	var n := 0
	for c: Dictionary in cars:
		if c["type"] == t:
			n += 1
	return n

static func count(d: Dictionary, item: String) -> int:
	return int(d.get(item, 0))

static func add(d: Dictionary, item: String, n: int) -> void:
	d[item] = count(d, item) + n

static func take(d: Dictionary, item: String, n: int) -> bool:
	if count(d, item) < n:
		return false
	d[item] = count(d, item) - n
	return true

static func weight(d: Dictionary) -> float:
	var w := 0.0
	for k: String in d.keys():
		if ITEMS.has(k):
			var it: Dictionary = ITEMS[k]
			var iw: float = it["w"]
			w += iw * float(count(d, k))
	return w

static func inv_cap() -> float:
	return 32.0

static func store_cap() -> float:
	return 110.0 + 160.0 * float(car_count("storage"))

static func bat_cap() -> float:
	return 120.0 + 60.0 * float(int(upgrades.get("battery", 0))) + 15.0 * float(count(store, "batteries"))

static func crew_cap() -> int:
	return 2 + 8 * car_count("passenger")

static func can_afford(cost: Dictionary) -> bool:
	for k: String in cost.keys():
		if count(store, k) + count(inv, k) < int(cost[k]):
			return false
	return true

static func pay(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for k: String in cost.keys():
		var need: int = int(cost[k])
		var from_inv: int = mini(need, count(inv, k))
		inv[k] = count(inv, k) - from_inv
		store[k] = count(store, k) - (need - from_inv)
	return true

static func cost_text(cost: Dictionary) -> String:
	var parts: Array = []
	for k: String in cost.keys():
		var it: Dictionary = ITEMS[k]
		parts.append("%d %s" % [int(cost[k]), it["name"]])
	return ", ".join(parts)

static func prod(c: Dictionary) -> float:
	if c["sick"]:
		return 0.0
	var m: float = c["morale"]
	var f: float = c["fatigue"]
	var sk: float = float(c["skill"])
	var a: String = c["assign"]
	var jobs: Array = ASSIGN[a]["jobs"]
	var bonus: float = 1.5 if jobs.has(c["job"]) else 0.7
	var trust: float = 1.0 + clampf(float(c.get("trust", 0.0)), 0.0, 100.0) / 650.0
	return clampf((0.35 + 0.65 * m / 100.0) * (1.0 - f / 160.0) * (sk / 4.0) * bonus * trust, 0.0, 2.0)

static func staffed(assign: String) -> float:
	var need: String = ASSIGN[assign]["car"]
	if need != "" and not has_car(need):
		return 0.0
	var p := 0.0
	for c: Dictionary in crew:
		if c["assign"] == assign:
			p += prod(c)
	return p

static func avg_morale() -> float:
	if crew.is_empty():
		return 50.0
	var m := 0.0
	for c: Dictionary in crew:
		var cm: float = c["morale"]
		m += cm
	return m / float(crew.size())

static func say(text: String, kind: String = "info") -> void:
	msgs.append([text, kind])

static func radio(text: String) -> void:
	radio_log.append("[%s] %s" % [clock(), text])
	if radio_log.size() > 12:
		radio_log.pop_front()
	msgs.append([text, "radio"])

static func worst_system() -> Array:
	var best: Array = [loco, "engine", "Locomotive engine"]
	var lo := 101.0
	for k: String in ["engine", "brakes", "electrical", "hull"]:
		var v: float = loco[k]
		if v < lo:
			lo = v
			best = [loco, k, "Locomotive " + k]
	for i in cars.size():
		var c: Dictionary = cars[i]
		for k: String in ["hull", "sys"]:
			var v: float = c[k]
			if v < lo:
				lo = v
				best = [c, k, "Car %d %s" % [i + 1, "hull" if k == "hull" else "systems"]]
	best.append(lo)
	return best

static func hull_avg() -> float:
	var h: float = loco["hull"]
	for c: Dictionary in cars:
		var ch: float = c["hull"]
		h += ch
	return h / float(cars.size() + 1)

static func damage_hull(amount: float) -> void:
	if int(upgrades.get("armour", 0)) > 0:
		amount *= 0.5
	var i: int = randi() % (cars.size() + 1)
	if i == 0:
		loco["hull"] = maxf(0.0, float(loco["hull"]) - amount)
	else:
		var c: Dictionary = cars[i - 1]
		c["hull"] = maxf(0.0, float(c["hull"]) - amount)

# ---------- simulation ----------
static func tick(dt: float, aboard: bool) -> void:
	time += dt
	stats["minutes"] = float(stats["minutes"]) + dt
	var h: float = dt / 60.0
	var nveh: float = float(cars.size() + 1)
	var tod: float = fposmod(time, 1440.0) / 1440.0
	t_out = -14.0 + 7.0 * cos((tod - 0.58) * TAU)
	if weather == "blizzard":
		t_out -= 8.0
	elif weather == "clear":
		t_out -= 2.0
	weather_t -= dt
	if weather_t <= 0.0:
		var r: float = randf()
		var old := weather
		weather = "clear" if r < 0.28 else ("snow" if r < 0.66 else ("sleet" if r < 0.84 else "blizzard"))
		weather_t = randf_range(240.0, 600.0)
		if weather == "blizzard" and old != "blizzard":
			radio("Weather service loop: severe snowstorm front crossing the line. Visibility near zero.")
	# --- diesel + electricity
	var eng: bool = train["engine_on"]
	var diesel: float = train["diesel"]
	var thr: float = train["throttle"]
	var eff: float = 0.75 if int(upgrades.get("injectors", 0)) > 0 else 1.0
	var cans: int = count(store, "diesel")
	if cans > 0 and diesel < 1190.0:
		store["diesel"] = 0
		diesel = minf(1200.0, diesel + 10.0 * float(cans))
		say("%d diesel cans poured into the tank." % cans)
	var gen := 0.0
	if eng:
		diesel -= (4.0 + 24.0 * thr) * eff * h
		gen += 42.0 * float(loco["engine"]) / 100.0
	if has_car("generator") and train["gen_on"] and diesel > 0.0:
		diesel -= 3.0 * h
		gen += 30.0 * (1.0 + 0.3 * minf(1.0, staffed("Power")))
	if diesel <= 0.0:
		diesel = 0.0
		if eng:
			train["engine_on"] = false
			say("The engine dies. The tank is dry.", "bad")
	train["diesel"] = diesel
	var ins: float = 0.7 if int(upgrades.get("insulation", 0)) > 0 else 1.0
	var ld := 0.0
	if train["lights"]:
		ld += 1.5 * nveh
	if train["heating"]:
		ld += 3.2 * nveh * clampf((18.0 - t_out) / 35.0, 0.3, 1.3) * ins
	if train["vent"]:
		ld += 1.0 * nveh
	if train["headlights"]:
		ld += 1.2
	for c: Dictionary in cars:
		match c["type"]:
			"medical": ld += 3.0
			"kitchen": ld += 4.0
			"greenhouse": ld += 6.0
			"water": ld += 5.0
			"workshop": ld += 3.0
			"security": ld += 2.0
			"storage": ld += 1.0
	ld *= 1.0 + (100.0 - float(loco["electrical"])) / 180.0
	if staffed("Power") > 0.0:
		ld *= 0.9
	kw_gen = gen
	kw_load = ld
	var bat: float = float(train["battery"]) + (gen - ld) * h
	var cap: float = bat_cap()
	power_ok = bat > 0.0 or gen >= ld
	train["battery"] = clampf(bat, 0.0, cap)
	# --- climate
	var temp: float = train["temp"]
	var heat_on: bool = train["heating"] and power_ok
	var target: float = 20.0 if heat_on else t_out + 5.0
	var k: float = 2.2 if heat_on else 0.35 * ins * (1.0 + (100.0 - hull_avg()) / 60.0)
	if train["doors_open"]:
		target = lerpf(target, t_out, 0.45)
		k += 0.8
	temp += (target - temp) * (1.0 - exp(-k * h))
	train["temp"] = temp
	var air: float = train["air"]
	if train["vent"] and power_ok:
		air += 45.0 * h
	else:
		air -= float(people()) * 2.2 * h
	if train["doors_open"]:
		air += 25.0 * h
	train["air"] = clampf(air, 0.0, 100.0)
	var san: float = float(train["sanitation"]) - float(people()) * 0.9 * h + staffed("Sanitation") * 9.0 * h
	if has_car("water") and power_ok:
		san += 3.0 * h
	train["sanitation"] = clampf(san, 0.0, 100.0)
	# --- food / water
	var ration: float = train["ration"]
	var cooking: float = staffed("Cooking")
	food_acc += float(crew.size()) * 0.11 * ration * (0.75 if cooking > 0.0 else 1.0) * h
	water_acc += float(crew.size()) * 0.14 * ration * h
	var starving := false
	var parched := false
	if food_acc >= 1.0:
		food_acc -= 1.0
		if not take(store, "food", 1):
			starving = true
	if water_acc >= 1.0:
		water_acc -= 1.0
		if not take(store, "water", 1):
			parched = true
	if count(store, "food") <= 0:
		starving = true
	if count(store, "water") <= 0:
		parched = true
	if power_ok:
		if staffed("Farming") > 0.0 and randf() < 0.55 * minf(1.5, staffed("Farming")) * h:
			add(store, "food", 1)
		if staffed("Water") > 0.0 and randf() < 1.0 * minf(1.5, staffed("Water")) * h:
			add(store, "water", 1)
	var spoil: float = (0.012 if power_ok else 0.06) * h * float(count(store, "food"))
	if randf() < spoil:
		take(store, "food", 1)
		if not power_ok:
			say("Food spoiled: refrigeration is without power.", "warn")
	# --- wear + repairs
	var v: float = train["speed"]
	if v > 1.0:
		loco["engine"] = maxf(5.0, float(loco["engine"]) - 0.25 * h * (0.5 + thr))
		if float(train["brake"]) > 0.2:
			loco["brakes"] = maxf(5.0, float(loco["brakes"]) - 1.2 * h)
	if weather == "blizzard":
		damage_hull(0.6 * h)
	if randf() < 0.02 * h:
		loco["electrical"] = maxf(5.0, float(loco["electrical"]) - randf_range(2.0, 6.0))
		say("A relay burns out somewhere in the locomotive.", "warn")
	var rep: float = staffed("Repairs")
	if rep > 0.0 and count(store, "tools") > 0:
		var w: Array = worst_system()
		var lo: float = w[3]
		if lo < 96.0 and count(store, "parts") > 0:
			var d: Dictionary = w[0]
			var key: String = w[1]
			var mult: float = 1.5 if has_car("workshop") else 1.0
			d[key] = minf(100.0, float(d[key]) + 5.0 * rep * mult * h)
			if randf() < 0.3 * h:
				take(store, "parts", 1)
	# --- attack decay
	under_attack = maxf(0.0, under_attack - dt)
	# --- crew
	var hr: float = hour()
	var medic: float = staffed("Medical") * (2.0 if has_car("medical") else 1.0)
	var lights_ok: bool = train["lights"] and power_ok
	var dead: Array = []
	for c: Dictionary in crew:
		var hu: float = c["hunger"]
		var th: float = c["thirst"]
		var fa: float = c["fatigue"]
		var mo: float = c["morale"]
		var he: float = c["health"]
		var base_h: float = 40.0 * (1.0 - ration)
		hu = hu + 8.0 * h if starving else maxf(base_h, hu - 25.0 * h)
		th = th + 11.0 * h if parched else maxf(base_h, th - 30.0 * h)
		var act: String = c["act"]
		if act.begins_with("Sleep") or act.begins_with("Rest"):
			fa -= 11.0 * h
		elif act.begins_with("Work") or act.begins_with("On "):
			fa += 4.5 * h
		else:
			fa += 2.5 * h
		var mt := 60.0
		if hu > 60.0: mt -= 18.0
		if th > 60.0: mt -= 18.0
		if temp < 8.0: mt -= 16.0
		if air < 40.0: mt -= 10.0
		if not lights_ok: mt -= 8.0
		if san < 30.0: mt -= 8.0
		if cooking > 0.0: mt += 10.0
		if under_attack > 0.0: mt -= 15.0
		if ration < 1.0: mt -= 8.0
		var rel: Dictionary = c["rel"]
		for rk: String in rel.keys():
			if float(rel[rk]) > 25.0:
				mt += 4.0
				break
		mo += (mt - mo) * (1.0 - exp(-0.5 * h))
		if hu > 85.0 or th > 85.0:
			he -= 5.0 * h
		if temp < 2.0:
			he -= 3.0 * h
		var sick: bool = c["sick"]
		if sick:
			he -= 1.6 * h
			if medic > 0.0 and randf() < 0.5 * medic * h and count(store, "medicine") > 0:
				take(store, "medicine", 1)
				sick = false
				say("%s has recovered under treatment." % c["name"], "good")
		else:
			var p: float = 0.004
			if air < 40.0: p += 0.03
			if san < 30.0: p += 0.04
			if temp < 6.0: p += 0.03
			if randf() < p * h:
				sick = true
				say("%s has fallen ill." % c["name"], "warn")
			if hu < 60.0 and th < 60.0 and temp > 8.0:
				he += (1.0 + 4.0 * medic) * h
		c["sick"] = sick
		c["hunger"] = clampf(hu, 0.0, 100.0)
		c["thirst"] = clampf(th, 0.0, 100.0)
		c["fatigue"] = clampf(fa, 0.0, 100.0)
		c["morale"] = clampf(mo, 0.0, 100.0)
		c["health"] = clampf(he, 0.0, 100.0)
		if he <= 0.0:
			dead.append(c)
	for c: Dictionary in dead:
		crew.erase(c)
		stats["lost"] = int(stats["lost"]) + 1
		say("%s did not make it." % c["name"], "bad")
		for o: Dictionary in crew:
			o["morale"] = maxf(0.0, float(o["morale"]) - 15.0)
	hour_acc += h
	if hour_acc >= 1.0 and crew.size() >= 2:
		hour_acc = 0.0
		var a: Dictionary = crew[randi() % crew.size()]
		var b: Dictionary = crew[randi() % crew.size()]
		if a != b:
			var delta: float = 3.0 if float(a["morale"]) + float(b["morale"]) > 80.0 else -2.0
			var ra: Dictionary = a["rel"]
			var rb: Dictionary = b["rel"]
			ra[b["name"]] = clampf(float(ra.get(b["name"], 0.0)) + delta, -50.0, 100.0)
			rb[a["name"]] = clampf(float(rb.get(a["name"], 0.0)) + delta, -50.0, 100.0)
	# --- player
	var ph: float = float(player["hunger"]) + 4.0 * h
	var pt: float = float(player["thirst"]) + 6.0 * h
	var pf: float = float(player["fatigue"]) + 3.0 * h
	var pc: float = player["cold"]
	var hp: float = player["health"]
	var amb: float = temp if aboard else t_out
	if amb < 6.0:
		pc += (6.0 - amb) * 0.055 * dt
	else:
		pc -= 1.6 * dt
	pc = clampf(pc, 0.0, 100.0)
	if aboard:
		if ph > 55.0 and take(store, "food", 1):
			ph -= 45.0
			say("You eat a ration from the train stores.")
		if pt > 55.0 and take(store, "water", 1):
			pt -= 45.0
			say("You drink from the train stores.")
	if ph > 90.0 or pt > 90.0:
		hp -= 6.0 * h
	if pc > 70.0:
		hp -= 14.0 * h
	if player["bleeding"]:
		hp -= 22.0 * h
	if player["sick"]:
		hp -= 4.0 * h
	if hp > 0.0 and ph < 60.0 and pt < 60.0 and pc < 30.0 and not player["bleeding"]:
		hp += (2.5 + 5.0 * medic) * h
	player["hunger"] = clampf(ph, 0.0, 100.0)
	player["thirst"] = clampf(pt, 0.0, 100.0)
	player["fatigue"] = clampf(pf, 0.0, 100.0)
	player["cold"] = pc
	player["health"] = clampf(hp, 0.0, 100.0)
	_warnings(starving, parched, temp, air, san)

static func _warnings(starving: bool, parched: bool, temp: float, air: float, san: float) -> void:
	warnings = []
	if under_attack > 0.0:
		warnings.append(["TRAIN UNDER ATTACK", 2])
	if not power_ok:
		warnings.append(["NO POWER - systems offline", 2])
	elif float(train["battery"]) < 15.0 and kw_gen < kw_load:
		warnings.append(["Battery low", 1])
	if float(train["diesel"]) < 80.0:
		warnings.append(["Diesel low: %d L" % int(train["diesel"]), 2 if float(train["diesel"]) < 25.0 else 1])
	if starving:
		warnings.append(["No food in stores", 2])
	elif count(store, "food") < 6:
		warnings.append(["Food running low", 1])
	if parched:
		warnings.append(["No water in stores", 2])
	elif count(store, "water") < 6:
		warnings.append(["Water running low", 1])
	if temp < 8.0:
		warnings.append(["Carriages freezing: %d C" % int(temp), 2 if temp < 2.0 else 1])
	if air < 40.0:
		warnings.append(["Poor air quality", 1])
	if san < 30.0:
		warnings.append(["Sanitation critical", 1])
	if float(loco["engine"]) < 35.0:
		warnings.append(["Engine badly damaged", 1])
	if float(loco["brakes"]) < 35.0:
		warnings.append(["Brakes worn", 1])
	if hull_avg() < 40.0:
		warnings.append(["Hull integrity low", 1])
	if player["bleeding"]:
		warnings.append(["You are bleeding - use medical supplies", 2])
	if float(player["cold"]) > 55.0:
		warnings.append(["Hypothermia risk - get inside", 2])
	if float(player["fatigue"]) > 85.0:
		warnings.append(["Exhausted - sleep in the crew bunk", 1])

# ---------- persistence ----------
static func to_dict() -> Dictionary:
	return {"v": 2, "ts": Time.get_unix_time_from_system(), "train": train, "loco": loco, "cars": cars, "crew": crew, "inv": inv, "store": store, "player": player, "time": time, "weather": weather, "weather_t": weather_t, "discovered": discovered, "looted": looted, "coupled": coupled, "recruited": recruited, "events": events, "objective": objective, "stats": stats, "upgrades": upgrades, "radio_log": radio_log, "ppos": ppos, "weapons": weapons, "cur_weapon": cur_weapon, "story": story}

static func _merge(dst: Dictionary, src: Variant) -> void:
	if typeof(src) != TYPE_DICTIONARY:
		return
	var sd: Dictionary = src
	for k: Variant in sd.keys():
		dst[k] = sd[k]

static func from_dict(d: Variant) -> bool:
	if typeof(d) != TYPE_DICTIONARY:
		return false
	var dd: Dictionary = d
	if not dd.has("train") or not dd.has("cars") or not dd.has("crew") or typeof(dd["cars"]) != TYPE_ARRAY or typeof(dd["train"]) != TYPE_DICTIONARY:
		return false
	var lc: Array = dd["cars"]
	for c: Variant in lc:
		if typeof(c) != TYPE_DICTIONARY:
			return false
		var cd: Dictionary = c
		if not cd.has("type") or not cd.has("hull"):
			return false
	reset_new()
	_merge(train, dd["train"])
	_merge(loco, dd.get("loco", {}))
	cars = lc
	crew = []
	var lcrew: Variant = dd["crew"]
	if typeof(lcrew) == TYPE_ARRAY:
		var arr: Array = lcrew
		for c: Variant in arr:
			if typeof(c) == TYPE_DICTIONARY:
				var base: Dictionary = mk_crew("Survivor", "Mechanic", 2, 1)
				_merge(base, c)
				base["skill"] = int(base["skill"])
				base["look"] = int(base["look"])
				if not ASSIGN.has(base["assign"]):
					base["assign"] = "Idle"
				if typeof(base["rel"]) != TYPE_DICTIONARY:
					base["rel"] = {}
				crew.append(base)
	inv = {}
	_merge(inv, dd.get("inv", {}))
	store = {}
	_merge(store, dd.get("store", {}))
	_merge(player, dd.get("player", {}))
	time = float(dd.get("time", time))
	weather = str(dd.get("weather", "snow"))
	weather_t = float(dd.get("weather_t", 300.0))
	discovered = {}
	_merge(discovered, dd.get("discovered", {}))
	looted = {}
	_merge(looted, dd.get("looted", {}))
	coupled = {}
	_merge(coupled, dd.get("coupled", {}))
	recruited = {}
	_merge(recruited, dd.get("recruited", {}))
	events = {}
	_merge(events, dd.get("events", {}))
	objective = int(dd.get("objective", 0))
	_merge(stats, dd.get("stats", {}))
	upgrades = {}
	_merge(upgrades, dd.get("upgrades", {}))
	var rl: Variant = dd.get("radio_log", [])
	if typeof(rl) == TYPE_ARRAY:
		radio_log = rl
	var pp: Variant = dd.get("ppos", [])
	if typeof(pp) == TYPE_ARRAY:
		ppos = pp
	weapons = {}
	_merge(weapons, dd.get("weapons", {}))
	if weapons.is_empty():
		weapons = {"p9": 0}
	cur_weapon = str(dd.get("cur_weapon", "p9"))
	story = Story.fresh()
	var sv: Variant = dd.get("story", null)
	if typeof(sv) == TYPE_DICTIONARY:
		var sd: Dictionary = sv
		for sk: String in story.keys():
			if sd.has(sk):
				if typeof(sd[sk]) == typeof(story[sk]) or (typeof(sd[sk]) == TYPE_FLOAT and typeof(story[sk]) == TYPE_INT):
					story[sk] = sd[sk]
	if not weapons.has(cur_weapon):
		cur_weapon = str(weapons.keys()[0])
	if int(dd.get("v", 1)) < 2:
		# saves from before the line was lengthened: keep the same place on the route
		train["s"] = float(train["s"]) * 3.0
	train["speed"] = 0.0
	train["throttle"] = 0.0
	train["brake"] = 1.0
	train["autopilot"] = false
	return true

static func slot_path(n: int) -> String:
	return "user://last_train_slot_%d.json" % n

static func save_slot(n: int) -> bool:
	var f := FileAccess.open(slot_path(n), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict()))
	f.close()
	return true

static func read_slot(n: int) -> Variant:
	if not FileAccess.file_exists(slot_path(n)):
		return null
	var f := FileAccess.open(slot_path(n), FileAccess.READ)
	if f == null:
		return null
	var txt: String = f.get_as_text()
	f.close()
	var js := JSON.new()
	if js.parse(txt) != OK:
		return "corrupt"
	var data: Variant = js.data
	if typeof(data) != TYPE_DICTIONARY:
		return "corrupt"
	return data

static func slot_info(n: int) -> Dictionary:
	var d: Variant = read_slot(n)
	if d == null:
		return {"exists": false, "ok": false, "label": "Empty", "ts": 0.0}
	if typeof(d) != TYPE_DICTIONARY:
		return {"exists": true, "ok": false, "label": "Corrupted save - cannot be loaded", "ts": 0.0}
	var dd: Dictionary = d
	if typeof(dd.get("train", null)) != TYPE_DICTIONARY or typeof(dd.get("cars", null)) != TYPE_ARRAY:
		return {"exists": true, "ok": false, "label": "Corrupted save - cannot be loaded", "ts": 0.0}
	var tr: Dictionary = dd["train"]
	var k: int = int(round(float(tr.get("s", 0.0)) * (3.0 if int(dd.get("v", 1)) < 2 else 1.0) / SP))
	var loc: Dictionary = LOCS[posmod(k, NLOC)]
	var t: float = float(dd.get("time", 0.0))
	var lcars: Array = dd["cars"]
	var lcrew: Array = dd.get("crew", [])
	var label := "Day %d - near %s - %d carriages, %d survivors" % [int(floor((t - 1260.0) / 1440.0)) + 1, loc["name"], lcars.size(), lcrew.size()]
	return {"exists": true, "ok": true, "label": label, "ts": float(dd.get("ts", 0.0))}

static func load_slot(n: int) -> bool:
	var d: Variant = read_slot(n)
	if d == null or typeof(d) != TYPE_DICTIONARY:
		return false
	return from_dict(d)

static func latest_slot() -> int:
	var best := -1
	var bt := -1.0
	for n in 4:
		var info: Dictionary = slot_info(n)
		if info["ok"] and float(info["ts"]) > bt:
			bt = float(info["ts"])
			best = n
	return best

static func default_settings() -> Dictionary:
	var keys: Dictionary = {}
	for k: String in KEY_DEFAULTS.keys():
		keys[k] = int(KEY_DEFAULTS[k])
	return {"preset": 1, "scale": 1.0, "fullscreen": false, "volume": 0.8, "sens": 1.0, "fov": 75.0, "keys": keys}

static func load_settings() -> void:
	settings = default_settings()
	if not FileAccess.file_exists("user://last_train_settings.json"):
		return
	var f := FileAccess.open("user://last_train_settings.json", FileAccess.READ)
	if f == null:
		return
	var js := JSON.new()
	if js.parse(f.get_as_text()) != OK or typeof(js.data) != TYPE_DICTIONARY:
		return
	var d: Dictionary = js.data
	for k: String in ["preset", "scale", "fullscreen", "volume", "sens", "fov"]:
		if d.has(k):
			settings[k] = d[k]
	settings["preset"] = int(settings["preset"])
	if typeof(d.get("keys", null)) == TYPE_DICTIONARY:
		var lk: Dictionary = d["keys"]
		var keys: Dictionary = settings["keys"]
		for k: String in keys.keys():
			if lk.has(k):
				keys[k] = int(lk[k])

static func save_settings() -> void:
	var f := FileAccess.open("user://last_train_settings.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(settings))
		f.close()

static func apply_keys() -> void:
	var keys: Dictionary = settings["keys"]
	for a: String in keys.keys():
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		InputMap.action_erase_events(a)
		var ev := InputEventKey.new()
		ev.physical_keycode = int(keys[a]) as Key
		InputMap.action_add_event(a, ev)
	var arrows: Dictionary = {"move_up": KEY_UP, "move_down": KEY_DOWN, "move_left": KEY_LEFT, "move_right": KEY_RIGHT}
	for a: String in arrows.keys():
		var ev := InputEventKey.new()
		ev.physical_keycode = int(arrows[a]) as Key
		InputMap.action_add_event(a, ev)
	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
	InputMap.action_erase_events("pause")
	var pe := InputEventKey.new()
	pe.physical_keycode = KEY_ESCAPE
	InputMap.action_add_event("pause", pe)
