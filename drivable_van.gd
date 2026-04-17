extends CharacterBody3D
## Управляемый фургон: W/S газ/тормоз, A/D поворот; сбивает врагов.

@export var accel: float = 38.0
@export var brake: float = 52.0
@export var max_speed: float = 13.0
@export var turn_speed: float = 2.35
@export var enemy_damage_min: int = 8
@export var enemy_damage_max: int = 72
@export var enemy_hit_cooldown_sec: float = 0.28
@export var fuel_max: float = 100.0
@export var fuel_drain_idle: float = 0.38
@export var fuel_drain_moving: float = 1.85

var _fuel: float = 100.0
var _driver: Node = null
var _hit_cd: Dictionary = {}


func _ready() -> void:
	_fuel = fuel_max
	_add_wheel_meshes()


func _add_wheel_meshes() -> void:
	var offsets: Array[Vector3] = [
		Vector3(-0.98, 0.14, 1.38),
		Vector3(0.98, 0.14, 1.38),
		Vector3(-0.98, 0.14, -1.38),
		Vector3(0.98, 0.14, -1.38),
	]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.11, 1.0)
	mat.roughness = 0.93
	for p in offsets:
		var w := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.34
		mesh.bottom_radius = 0.34
		mesh.height = 0.22
		mesh.radial_segments = 14
		w.mesh = mesh
		w.set_surface_override_material(0, mat)
		w.position = p
		w.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		add_child(w)


func set_driver(p: Node) -> void:
	_driver = p


func clear_driver() -> void:
	_driver = null


func has_driver() -> bool:
	return _driver != null and is_instance_valid(_driver)


func get_driver_node_or_null() -> Node:
	if not has_driver():
		return null
	return _driver


func get_fuel_ratio() -> float:
	if fuel_max <= 0.0:
		return 0.0
	return clampf(_fuel / fuel_max, 0.0, 1.0)


func refuel_full() -> void:
	_fuel = fuel_max


func _physics_process(delta: float) -> void:
	if not has_driver():
		return
	_hit_cd_decay(delta)
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	if fwd.length_squared() > 0.0001:
		fwd = fwd.normalized()
	var spd := velocity.dot(fwd)
	var motor_ok := _fuel > 0.001
	if motor_ok and Input.is_physical_key_pressed(KEY_W):
		spd = move_toward(spd, max_speed, accel * delta)
	elif motor_ok and Input.is_physical_key_pressed(KEY_S):
		spd = move_toward(spd, -max_speed * 0.45, accel * 0.65 * delta)
	else:
		spd = move_toward(spd, 0.0, brake * delta)
	velocity.x = fwd.x * spd
	velocity.z = fwd.z * spd
	var turn := 0.0
	if Input.is_physical_key_pressed(KEY_A):
		turn += 1.0
	if Input.is_physical_key_pressed(KEY_D):
		turn -= 1.0
	rotate_y(turn * turn_speed * delta)
	move_and_slide()
	_resolve_enemy_hits()
	var hspd := Vector3(velocity.x, 0.0, velocity.z).length()
	var drain := fuel_drain_idle
	if hspd > 0.35 or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_S):
		drain += fuel_drain_moving * clampf(hspd / max_speed, 0.25, 1.0)
	_fuel = maxf(_fuel - drain * delta, 0.0)


func _hit_cd_decay(delta: float) -> void:
	var rm: Array = []
	for k in _hit_cd.keys():
		_hit_cd[k] = float(_hit_cd[k]) - delta
		if float(_hit_cd[k]) <= 0.0:
			rm.append(k)
	for id in rm:
		_hit_cd.erase(id)


func _resolve_enemy_hits() -> void:
	var hspd := Vector3(velocity.x, 0.0, velocity.z).length()
	if hspd < 1.8:
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col == null:
			continue
		var n := col.get_collider()
		if n == null or not n is Node:
			continue
		var node := n as Node
		if not node.is_in_group("enemy"):
			continue
		var id := node.get_instance_id()
		if float(_hit_cd.get(id, 0.0)) > 0.0:
			continue
		_hit_cd[id] = enemy_hit_cooldown_sec
		var dmg := clampi(int(hspd * 4.2), enemy_damage_min, enemy_damage_max)
		if node.has_method("take_truck_hit"):
			node.call("take_truck_hit", dmg)
