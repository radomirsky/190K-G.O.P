extends CharacterBody3D
## Конь ковбоя: простой наземный «драйв», совместимый с enter_van/exit_van.

@export var accel: float = 62.0
@export var brake: float = 75.0
@export var max_speed: float = 16.5
@export var turn_speed: float = 3.2
@export var fuel_max: float = 100.0
@export var fuel_drain_idle: float = 0.0
@export var fuel_drain_moving: float = 0.0
@export var hull_max_hp: int = 20

var _fuel: float = 100.0
var _hull_hp: int = 20
var _destroyed: bool = false
var _driver: Node = null
var _body_mesh: MeshInstance3D = null


func _ready() -> void:
	_body_mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D
	_fuel = fuel_max
	_hull_hp = hull_max_hp
	if GameProgress.horse_destroyed:
		_destroyed = true
		_hull_hp = 0
		_apply_wreck_visual()


func set_driver(p: Node) -> void:
	_driver = p


func clear_driver() -> void:
	_driver = null


func has_driver() -> bool:
	return _driver != null and is_instance_valid(_driver)


func is_van_operable() -> bool:
	return not _destroyed and not GameProgress.horse_destroyed


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
		_break_horse()


func restore_van_after_purchase() -> void:
	_destroyed = false
	_hull_hp = hull_max_hp
	_fuel = fuel_max
	GameProgress.horse_destroyed = false
	_restore_visual()
	velocity = Vector3.ZERO


func _break_horse() -> void:
	if _destroyed:
		return
	GameProgress.horse_destroyed = true
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


func _restore_visual() -> void:
	if _body_mesh == null:
		return
	_body_mesh.set_surface_override_material(0, null)


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
		if GameSave.is_creative():
			_fuel = fuel_max
		else:
			var hspd := Vector3(velocity.x, 0.0, velocity.z).length()
			var drain := fuel_drain_idle
			if hspd > 0.35 or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_S):
				drain += fuel_drain_moving * clampf(hspd / max_speed, 0.25, 1.0)
			_fuel = maxf(_fuel - drain * delta, 0.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, brake * delta)
		velocity.z = move_toward(velocity.z, 0.0, brake * delta)
		move_and_slide()

