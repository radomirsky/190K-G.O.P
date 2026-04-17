extends Node3D
## Строит пол, внешние стены и внутренние перегородки особняка (часть ломается от грузовика).

@export var floor_half_x: float = 20.0
@export var floor_half_z: float = 15.0
@export var wall_height: float = 4.2
@export var wall_thick: float = 0.45
@export var inner_wall_mass: float = 95.0


func _ready() -> void:
	_build_floor()
	_build_outer_shell()
	_build_inner_rigid_walls()
	_build_ceiling()
	_add_interior_lights()


func _wood_floor_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.42, 0.28, 0.16, 1.0)
	m.roughness = 0.72
	m.metallic = 0.02
	return m


func _wall_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.88, 0.84, 0.78, 1.0)
	m.roughness = 0.88
	return m


func _build_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "MansionFloor"
	add_child(body)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(floor_half_x * 2.0, 0.22, floor_half_z * 2.0)
	mi.mesh = mesh
	mi.set_surface_override_material(0, _wood_floor_mat())
	body.add_child(mi)
	var sh := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = mesh.size
	sh.shape = box
	sh.position = Vector3.ZERO
	body.add_child(sh)
	body.position = Vector3(0.0, -0.11, 0.0)


func _add_static_wall(name: String, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = name
	add_child(body)
	body.position = pos
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.set_surface_override_material(0, _wall_mat())
	body.add_child(mi)
	var sh := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	sh.shape = box
	body.add_child(sh)


func _build_outer_shell() -> void:
	var hx := floor_half_x
	var hz := floor_half_z
	var h := wall_height
	var t := wall_thick
	var y := h * 0.5
	# Север / юг (с проёмом на юге для заезда грузовика)
	_add_static_wall("WallNorth", Vector3(0.0, y, -hz - t * 0.5), Vector3(hx * 2.0 + t * 2.0, h, t))
	var gap := 7.0
	var south_w := (hx * 2.0 - gap) * 0.5
	_add_static_wall(
		"WallSouthLeft",
		Vector3(-hx + south_w * 0.5 - gap * 0.25, y, hz + t * 0.5),
		Vector3(south_w, h, t)
	)
	_add_static_wall(
		"WallSouthRight",
		Vector3(hx - south_w * 0.5 + gap * 0.25, y, hz + t * 0.5),
		Vector3(south_w, h, t)
	)
	# Восток / запад
	_add_static_wall("WallEast", Vector3(hx + t * 0.5, y, 0.0), Vector3(t, h, hz * 2.0 + t * 2.0))
	_add_static_wall("WallWest", Vector3(-hx - t * 0.5, y, 0.0), Vector3(t, h, hz * 2.0 + t * 2.0))


func _add_rigid_partition(name: String, pos: Vector3, size: Vector3) -> void:
	var rb := RigidBody3D.new()
	rb.name = name
	rb.mass = inner_wall_mass
	rb.continuous_cd = true
	rb.linear_damp = 3.5
	rb.angular_damp = 2.8
	rb.gravity_scale = 1.0
	rb.add_to_group("mansion_wall")
	add_child(rb)
	rb.position = pos + Vector3(0.0, size.y * 0.5, 0.0)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var wm := _wall_mat()
	wm.albedo_color = Color(0.72, 0.68, 0.62, 1.0)
	mi.set_surface_override_material(0, wm)
	rb.add_child(mi)
	var sh := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	sh.shape = box
	rb.add_child(sh)


func _build_inner_rigid_walls() -> void:
	var h := 3.2
	var t := 0.28
	# Коридор вдоль X
	_add_rigid_partition("InnerA", Vector3(-6.0, 0.0, 0.0), Vector3(t, h, 12.0))
	_add_rigid_partition("InnerB", Vector3(6.0, 0.0, 0.0), Vector3(t, h, 12.0))
	_add_rigid_partition("InnerC", Vector3(0.0, 0.0, -5.0), Vector3(22.0, h, t))
	_add_rigid_partition("InnerD", Vector3(0.0, 0.0, 6.5), Vector3(16.0, h, t))
	# Колонны / шкафы
	_add_rigid_partition("InnerE", Vector3(-12.0, 0.0, -8.0), Vector3(2.2, h * 0.85, 2.2))
	_add_rigid_partition("InnerF", Vector3(11.0, 0.0, 7.0), Vector3(2.2, h * 0.85, 2.2))


func _build_ceiling() -> void:
	var body := StaticBody3D.new()
	body.name = "Ceiling"
	add_child(body)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(floor_half_x * 2.0 + wall_thick * 2.0, 0.2, floor_half_z * 2.0 + wall_thick * 2.0)
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.52, 0.48, 1.0)
	m.roughness = 0.9
	mi.set_surface_override_material(0, m)
	body.add_child(mi)
	var sh := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = mesh.size
	sh.shape = box
	body.add_child(sh)
	body.position = Vector3(0.0, wall_height + 0.15, 0.0)


func _add_interior_lights() -> void:
	for p in [Vector3(-8, 3.2, -6), Vector3(8, 3.2, 6), Vector3(0, 3.2, 0), Vector3(-10, 3.2, 8)]:
		var omni := OmniLight3D.new()
		omni.light_energy = 0.55
		omni.omni_range = 18.0
		omni.light_color = Color(1.0, 0.92, 0.82, 1.0)
		omni.position = p
		add_child(omni)
