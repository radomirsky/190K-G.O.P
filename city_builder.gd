extends Node3D
## Город севернее особняка (не на паркете): дома, площадь, проход с головоломкой (плита + рычаг + ворота).

const QUEST_NPC_SCENE := preload("res://quest_npc.tscn")
const VILLAGER_EXTRA_SCENE := preload("res://villager_extra.tscn")
const WORLD_SHOP_SCENE := preload("res://world_shop.tscn")
const PLATE_SCENE := preload("res://puzzle_pressure_plate.tscn")
const LEVER_SCENE := preload("res://puzzle_lever.tscn")
const GATE_SCENE := preload("res://puzzle_gate_door.tscn")
const INNER_GATE_SCENE := preload("res://village_inner_gate.tscn")

## Левый нижний угол сетки домов (мир): вся сетка севернее особняка (z < ~-22).
@export var grid_origin: Vector3 = Vector3(44.0, 0.0, -80.0)
@export var cell_size: float = 9.5
@export var grid_w: int = 5
@export var grid_h: int = 6


func _ready() -> void:
	_build_north_passage_and_puzzle()
	_build_plaza_and_houses()
	_build_village_walls_and_gateway()
	_build_village_inner_gate_and_lever()
	_spawn_quest_npcs()
	_spawn_village_shop()
	_spawn_extra_villagers()
	_register_npc_village_exclusion_zone()


func _register_npc_village_exclusion_zone() -> void:
	var pad := 4.0
	var min_x := grid_origin.x - pad
	var max_x := grid_origin.x + float(grid_w) * cell_size + pad
	var min_z := grid_origin.z - pad
	var max_z := grid_origin.z + float(grid_h) * cell_size + pad
	# Дороги и головоломка у ворот (южный и северный отрезки).
	min_x = minf(min_x, -2.0)
	max_x = maxf(max_x, 76.0)
	min_z = minf(min_z, -54.0)
	max_z = maxf(max_z, -5.0)
	GameProgress.register_npc_village_xz(min_x, max_x, min_z, max_z)


func _plaza_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.31, 0.34, 1)
	m.roughness = 0.92
	return m


func _house_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.65 + randf() * 0.12, 0.52, 0.42, 1)
	m.roughness = 0.88
	return m


func _roof_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.36, 0.2, 0.16, 1)
	m.roughness = 0.85
	return m


func _wall_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.4, 0.38, 0.36, 1)
	m.roughness = 0.9
	return m


## Общая геометрия ограды и проёма ворот (юг), чтобы стена, плита и puzzle_gate совпадали.
func _village_wall_layout() -> Dictionary:
	var total_x := float(grid_w) * cell_size
	var total_z := float(grid_h) * cell_size
	var x0 := grid_origin.x - 1.0
	var x1 := grid_origin.x + total_x + 1.0
	var z0 := grid_origin.z - 1.0
	var z1 := grid_origin.z + total_z + 1.0
	var h := 4.0
	var t := 0.55
	var gap_cx := (x0 + x1) * 0.5 + 2.0
	var gap_w := 6.2
	var xmin := gap_cx - gap_w * 0.5
	var xmax := gap_cx + gap_w * 0.5
	return {
		"x0": x0,
		"x1": x1,
		"z0": z0,
		"z1": z1,
		"h": h,
		"t": t,
		"gap_cx": gap_cx,
		"gap_w": gap_w,
		"xmin": xmin,
		"xmax": xmax,
	}


func _build_village_walls_and_gateway() -> void:
	var lay := _village_wall_layout()
	var x0: float = lay["x0"]
	var x1: float = lay["x1"]
	var z0: float = lay["z0"]
	var z1: float = lay["z1"]
	var h: float = lay["h"]
	var t: float = lay["t"]
	var wm := _wall_mat()
	var gap_cx: float = lay["gap_cx"]
	var xmin: float = lay["xmin"]
	var xmax: float = lay["xmax"]
	_add_box_static("VillageWallN", Vector3((x0 + x1) * 0.5, h * 0.5, z0 - t * 0.5), Vector3(x1 - x0 + 2.0 * t, h, t), wm)
	_add_box_static("VillageWallW", Vector3(x0 - t * 0.5, h * 0.5, (z0 + z1) * 0.5), Vector3(t, h, z1 - z0 + 2.0 * t), wm)
	_add_box_static("VillageWallE", Vector3(x1 + t * 0.5, h * 0.5, (z0 + z1) * 0.5), Vector3(t, h, z1 - z0 + 2.0 * t), wm)
	var w_left := xmin - x0
	if w_left > 0.8:
		_add_box_static("VillageWallS_L", Vector3(x0 + w_left * 0.5, h * 0.5, z1 + t * 0.5), Vector3(w_left, h, t), wm)
	var w_right := x1 - xmax
	if w_right > 0.8:
		_add_box_static("VillageWallS_R", Vector3(xmax + w_right * 0.5, h * 0.5, z1 + t * 0.5), Vector3(w_right, h, t), wm)
	_add_box_static("VillageGatePostL", Vector3(xmin - 0.48, h * 0.55, z1 + t * 0.5), Vector3(0.82, h * 1.12, 0.82), wm)
	_add_box_static("VillageGatePostR", Vector3(xmax + 0.48, h * 0.55, z1 + t * 0.5), Vector3(0.82, h * 1.12, 0.82), wm)
	var beam_w := xmax - xmin + 1.2
	_add_box_static("VillageGateLintel", Vector3((xmin + xmax) * 0.5, h * 1.12 + 0.35, z1 + t * 0.5), Vector3(beam_w, 0.55, 0.75), wm)


## Внутри деревни: рычаг переключает вторую дверь в проходе (можно жать E сколько угодно).
func _build_village_inner_gate_and_lever() -> void:
	var lay := _village_wall_layout()
	var gap_cx: float = lay["gap_cx"]
	var z1: float = lay["z1"]
	var t: float = lay["t"]
	# Чуть севернее внешних ворот — в коридоре между стеной и площадью.
	var z_inner := z1 - 4.2
	var inner := INNER_GATE_SCENE.instantiate() as StaticBody3D
	if inner:
		add_child(inner)
		inner.global_position = Vector3(gap_cx, 0.0, z_inner)
	var lever_in := LEVER_SCENE.instantiate() as StaticBody3D
	if lever_in:
		lever_in.flag_key = "village_inner_gate_closed"
		lever_in.one_shot = false
		lever_in.toggle_flag_on_interact = true
		lever_in.banner_text_when_flag_on = "Внутренние ворота закрыты.\nСубтитры — DimaTorzok"
		lever_in.banner_text_when_flag_off = "Внутренние ворота открыты.\nСубтитры — DimaTorzok"
		add_child(lever_in)
		lever_in.global_position = Vector3(gap_cx + 3.2, 0.05, z_inner - 1.1)
		var lbl := lever_in.get_node_or_null("Label3D") as Label3D
		if lbl:
			lbl.text = "Рычаг ворот — E\n(снова E — открыть)"


func _add_box_static(name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.name = name
	add_child(body)
	body.position = pos
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)
	body.add_child(mi)
	var sh := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	sh.shape = box
	body.add_child(sh)


func _build_north_passage_and_puzzle() -> void:
	var mat := _plaza_mat()
	var lay := _village_wall_layout()
	var gap_cx: float = lay["gap_cx"]
	var z1: float = lay["z1"]
	var t: float = lay["t"]
	# Дорога от двора особняка к воротам.
	_add_box_static("CityRoadSouth", Vector3(14.0, 0.08, -18.0), Vector3(32.0, 0.18, 16.0), mat)
	_add_box_static("CityRoadNorth", Vector3(46.0, 0.08, -36.0), Vector3(48.0, 0.18, 28.0), mat)

	var plate := PLATE_SCENE.instantiate() as Area3D
	if plate:
		plate.flag_key = "suburbs_plate"
		plate.extra_flag_keys = PackedStringArray(["village_entry_unlocked"])
		add_child(plate)
		# Южнее проёма в стене — на подходе к деревне.
		plate.global_position = Vector3(gap_cx, 0.12, z1 + t + 2.75)
		var plbl := Label3D.new()
		plbl.text = "ПЛИТА\n(шагни сюда)"
		plbl.font_size = 22
		plbl.outline_size = 8
		plbl.modulate = Color(0.95, 0.95, 1.0)
		plbl.position = Vector3(0.0, 0.72, 0.0)
		plbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		plate.add_child(plbl)

	var gate := GATE_SCENE.instantiate() as StaticBody3D
	if gate:
		add_child(gate)
		gate.global_position = Vector3(gap_cx, 0.0, z1 + t * 0.5)

	var lever := LEVER_SCENE.instantiate() as StaticBody3D
	if lever:
		lever.flag_key = "suburbs_lever"
		add_child(lever)
		lever.global_position = Vector3(gap_cx + 5.5, 0.05, z1 + t + 1.15)


func _build_plaza_and_houses() -> void:
	var total_x := float(grid_w) * cell_size
	var total_z := float(grid_h) * cell_size
	var mid := grid_origin + Vector3(total_x * 0.5, 0.0, total_z * 0.5)
	_add_box_static("CityPlaza", mid + Vector3(0.0, 0.1, 0.0), Vector3(total_x + 3.0, 0.22, total_z + 3.0), _plaza_mat())

	var plaza_cell := Vector2i(2, 2)
	for gx in range(grid_w):
		for gz in range(grid_h):
			if gx == plaza_cell.x and gz == plaza_cell.y:
				continue
			var cell_c := grid_origin + Vector3((float(gx) + 0.5) * cell_size, 0.0, (float(gz) + 0.5) * cell_size)
			var hw := cell_size * (0.34 + randf() * 0.06)
			var hd := cell_size * (0.34 + randf() * 0.06)
			var hh := 2.2 + randf() * 1.6
			_add_box_static(
				"House_%d_%d" % [gx, gz],
				cell_c + Vector3(0.0, hh * 0.5 + 0.12, 0.0),
				Vector3(hw, hh, hd),
				_house_mat()
			)
			var rh := 0.32
			_add_box_static(
				"Roof_%d_%d" % [gx, gz],
				cell_c + Vector3(0.0, hh + rh * 0.5 + 0.18, 0.0),
				Vector3(hw * 1.06, rh, hd * 1.06),
				_roof_mat()
			)


func _plaza_cell_center() -> Vector3:
	var gx := 2
	var gz := 2
	return grid_origin + Vector3((float(gx) + 0.5) * cell_size, 0.12, (float(gz) + 0.5) * cell_size)


func _spawn_village_shop() -> void:
	var shop := WORLD_SHOP_SCENE.instantiate() as Node3D
	if shop == null:
		return
	add_child(shop)
	shop.global_position = _plaza_cell_center()
	# Лицом к югу (к выходу из деревни).
	shop.rotation_degrees = Vector3(0.0, 20.0, 0.0)


func _spawn_extra_villagers() -> void:
	var base := _plaza_cell_center()
	var lines: PackedStringArray = PackedStringArray([
		"Давно не видели гостей.",
		"У ворот шумно, когда шлагбаум падает.",
		"Жетоны МАМА? Покупай у лавки на площади.",
		"Осторожнее на дороге — фургон не ждёт.",
		"Синий житель выдаёт поручения, если плиту наступил.",
		"Третий по счёту любит поговорить про жетоны.",
		"Крыши держатся — пока что.",
		"Если заблудился — жми M, карта поможет.",
	])
	var spots: Array[Vector3] = [
		Vector3(-4.2, 0.05, 3.1),
		Vector3(4.5, 0.05, 2.6),
		Vector3(-3.8, 0.05, -2.9),
		Vector3(3.9, 0.05, -3.4),
		Vector3(0.2, 0.05, 5.5),
		Vector3(-6.0, 0.05, 0.4),
		Vector3(6.1, 0.05, -0.8),
		Vector3(1.2, 0.05, -5.2),
	]
	for i in range(mini(spots.size(), lines.size())):
		var v := VILLAGER_EXTRA_SCENE.instantiate() as StaticBody3D
		if v == null:
			continue
		v.set("greet_line", lines[i])
		add_child(v)
		v.global_position = base + spots[i]


func _spawn_quest_npcs() -> void:
	var mid := _plaza_cell_center()
	var offsets: Array[Vector3] = [
		Vector3(-6.2, 0.05, -5.0),
		Vector3(6.0, 0.05, -4.5),
		Vector3(-0.5, 0.05, 6.2),
	]
	for i in range(mini(3, offsets.size())):
		var npc := QUEST_NPC_SCENE.instantiate() as StaticBody3D
		if npc == null:
			continue
		npc.npc_index = i
		add_child(npc)
		npc.global_position = mid + offsets[i]
