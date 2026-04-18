extends CharacterBody3D
## Управляемый фургон: W/S газ/тормоз, A/D поворот; сбивает врагов; корпус с HP.

@export var accel: float = 38.0
@export var brake: float = 52.0
@export var max_speed: float = 13.0
@export var turn_speed: float = 2.35
@export var enemy_damage_min: int = 8
@export var enemy_damage_max: int = 72
## Гориз. скорость выше этого — наезд наносит урон (ниже порога «толчки» не бьют).
@export var enemy_ram_min_speed: float = 0.45
@export var enemy_hit_cooldown_sec: float = 0.28
@export var fuel_max: float = 100.0
@export var fuel_drain_idle: float = 0.38
@export var fuel_drain_moving: float = 1.85
@export var hull_max_hp: int = 100
@export var hull_hurt_cooldown_sec: float = 0.48
## Урон касанием врага по корпусу: доля от того же «touch_damage», что получает игрок (у игрока — 100%).
@export_range(0.05, 1.0, 0.01) var enemy_contact_damage_vs_player_fraction: float = 0.38

var _fuel: float = 100.0
var _hull_hp: int = 100
var _destroyed: bool = false
var _driver: Node = null
var _hit_cd: Dictionary = {}
var _hull_hurt_cd: Dictionary = {}
var _body_mesh: MeshInstance3D = null
var _body_mat_default: StandardMaterial3D = null


func _ready() -> void:
	_cache_body_visual()
	_fuel = fuel_max
	_hull_hp = hull_max_hp
	_add_wheel_meshes()
	if GameProgress.van_destroyed:
		_destroyed = true
		_hull_hp = 0
		_apply_wreck_visual()


func _cache_body_visual() -> void:
	_body_mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if _body_mesh == null:
		return
	var m0 := _body_mesh.get_surface_override_material(0) as StandardMaterial3D
	if m0 != null:
		_body_mat_default = m0.duplicate() as StandardMaterial3D


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


func is_van_operable() -> bool:
	return not _destroyed and not GameProgress.van_destroyed


func get_fuel_ratio() -> float:
	if fuel_max <= 0.0:
		return 0.0
	return clampf(_fuel / fuel_max, 0.0, 1.0)


func get_hull_ratio() -> float:
	if hull_max_hp <= 0:
		return 0.0
	return clampf(float(_hull_hp) / float(hull_max_hp), 0.0, 1.0)


func refuel_full() -> void:
	if not is_van_operable():
		return
	_fuel = fuel_max


func take_hull_damage(amount: int) -> void:
	if not is_van_operable() or amount < 1:
		return
	_hull_hp -= amount
	if _hull_hp <= 0:
		_hull_hp = 0
		_break_van()


func restore_van_after_purchase() -> void:
	_destroyed = false
	_hull_hp = hull_max_hp
	_fuel = fuel_max
	_restore_body_visual()
	velocity = Vector3.ZERO


func _break_van() -> void:
	if _destroyed:
		return
	GameProgress.van_destroyed = true
	_destroyed = true
	_hull_hp = 0
	velocity = Vector3.ZERO
	if has_driver() and is_instance_valid(_driver) and _driver.has_method("exit_van"):
		_driver.call("exit_van")
	else:
		clear_driver()
	_apply_wreck_visual()


func _apply_wreck_visual() -> void:
	if _body_mesh == null:
		return
	var wreck := StandardMaterial3D.new()
	wreck.albedo_color = Color(0.22, 0.14, 0.12, 1.0)
	wreck.roughness = 0.95
	_body_mesh.set_surface_override_material(0, wreck)


func _restore_body_visual() -> void:
	if _body_mesh == null or _body_mat_default == null:
		_cache_body_visual()
	if _body_mesh != null and _body_mat_default != null:
		_body_mesh.set_surface_override_material(0, _body_mat_default.duplicate())


func _physics_process(delta: float) -> void:
	if not is_van_operable():
		var grav0 := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
		if not is_on_floor():
			velocity.y -= grav0 * delta
		else:
			if velocity.y < 0.0:
				velocity.y = 0.0
		velocity.x = move_toward(velocity.x, 0.0, brake * delta)
		velocity.z = move_toward(velocity.z, 0.0, brake * delta)
		move_and_slide()
		return

	_hit_cd_decay(delta)
	_hull_hurt_cd_decay(delta)

	var grav := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	if not is_on_floor():
		velocity.y -= grav * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

	if has_driver():
		var fwd := -global_transform.basis.z
		fwd.y = 0.0
		if fwd.length_squared() > 0.0001:
			fwd = fwd.normalized()
		var spd := velocity.dot(fwd)
		var motor_ok := _fuel > 0.001 or GameSave.is_creative()
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
		var hspd := Vector3(velocity.x, 0.0, velocity.z).length()
		if GameSave.is_creative():
			_fuel = fuel_max
		else:
			var drain := fuel_drain_idle
			if hspd > 0.35 or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_S):
				drain += fuel_drain_moving * clampf(hspd / max_speed, 0.25, 1.0)
			_fuel = maxf(_fuel - drain * delta, 0.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, brake * delta)
		velocity.z = move_toward(velocity.z, 0.0, brake * delta)
		move_and_slide()

	_resolve_enemy_hits()
	_resolve_van_damage_from_enemy_contacts()


func _hit_cd_decay(delta: float) -> void:
	var rm: Array = []
	for k in _hit_cd.keys():
		_hit_cd[k] = float(_hit_cd[k]) - delta
		if float(_hit_cd[k]) <= 0.0:
			rm.append(k)
	for id in rm:
		_hit_cd.erase(id)


func _hull_hurt_cd_decay(delta: float) -> void:
	var rm: Array = []
	for k in _hull_hurt_cd.keys():
		_hull_hurt_cd[k] = float(_hull_hurt_cd[k]) - delta
		if float(_hull_hurt_cd[k]) <= 0.0:
			rm.append(k)
	for id in rm:
		_hull_hurt_cd.erase(id)


func _resolve_enemy_hits() -> void:
	var hspd := Vector3(velocity.x, 0.0, velocity.z).length()
	if hspd < enemy_ram_min_speed:
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


func _resolve_van_damage_from_enemy_contacts() -> void:
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
		if float(_hull_hurt_cd.get(id, 0.0)) > 0.0:
			continue
		_hull_hurt_cd[id] = hull_hurt_cooldown_sec
		var base_touch := 7
		var td: Variant = node.get("touch_damage")
		if td != null:
			base_touch = maxi(1, int(td))
		var dmg := maxi(
			1,
			int(round(float(base_touch) * enemy_contact_damage_vs_player_fraction))
		)
		take_hull_damage(dmg)
