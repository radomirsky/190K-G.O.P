extends Node3D
## Квартал с домиками и тремя жителями (квесты — CityQuests).

const QUEST_NPC_SCENE := preload("res://quest_npc.tscn")

@export var grid_origin: Vector3 = Vector3(-40.0, 0.0, -34.0)
@export var cell_size: float = 9.5
@export var grid_w: int = 5
@export var grid_h: int = 5


func _ready() -> void:
	_build_plaza_and_houses()
	_spawn_quest_npcs()


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
		Vector3(-2.2, 0.05, -1.0),
		Vector3(1.8, 0.05, 0.6),
		Vector3(0.2, 0.05, 2.4),
	]
	for i in range(mini(3, offsets.size())):
		var npc := QUEST_NPC_SCENE.instantiate() as StaticBody3D
		if npc == null:
			continue
		npc.npc_index = i
		add_child(npc)
		npc.global_position = mid + offsets[i]
