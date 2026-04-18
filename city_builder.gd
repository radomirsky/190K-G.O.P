extends Node3D
## Город севернее особняка (не на паркете): дома, площадь, проход с головоломкой (плита + рычаг + ворота).

const QUEST_NPC_SCENE := preload("res://quest_npc.tscn")
const PLATE_SCENE := preload("res://puzzle_pressure_plate.tscn")
const LEVER_SCENE := preload("res://puzzle_lever.tscn")
const GATE_SCENE := preload("res://puzzle_gate_door.tscn")

## Левый нижний угол сетки домов (мир): вся сетка севернее особняка (z < ~-22).
@export var grid_origin: Vector3 = Vector3(44.0, 0.0, -80.0)
@export var cell_size: float = 9.5
@export var grid_w: int = 5
@export var grid_h: int = 6


func _ready() -> void:
	_build_north_passage_and_puzzle()
	_build_plaza_and_houses()
	_spawn_quest_npcs()
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
	# Дорога от двора особняка к воротам.
	_add_box_static("CityRoadSouth", Vector3(14.0, 0.08, -18.0), Vector3(32.0, 0.18, 16.0), mat)
	_add_box_static("CityRoadNorth", Vector3(46.0, 0.08, -36.0), Vector3(48.0, 0.18, 28.0), mat)

	var plate := PLATE_SCENE.instantiate() as Area3D
	if plate:
		plate.flag_key = "suburbs_plate"
		add_child(plate)
		plate.global_position = Vector3(22.0, 0.12, -19.0)

	var gate := GATE_SCENE.instantiate() as StaticBody3D
	if gate:
		add_child(gate)
		gate.global_position = Vector3(36.5, 0.0, -30.0)

	var lever := LEVER_SCENE.instantiate() as StaticBody3D
	if lever:
		lever.flag_key = "suburbs_lever"
		add_child(lever)
		lever.global_position = Vector3(52.0, 0.05, -28.0)


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


func _spawn_quest_npcs() -> void:
	var total_x := float(grid_w) * cell_size
	var total_z := float(grid_h) * cell_size
	var mid := grid_origin + Vector3(total_x * 0.5, 0.0, total_z * 0.5)
	var offsets: Array[Vector3] = [
		Vector3(-2.4, 0.05, -1.2),
		Vector3(1.9, 0.05, 0.5),
		Vector3(0.3, 0.05, 2.5),
	]
	for i in range(mini(3, offsets.size())):
		var npc := QUEST_NPC_SCENE.instantiate() as StaticBody3D
		if npc == null:
			continue
		npc.npc_index = i
		add_child(npc)
		npc.global_position = mid + offsets[i]
