extends CharacterBody3D
## Летающая машина: простой «ховер», совместимый с enter_van/exit_van (интерфейс как у фургона).

@export var accel: float = 44.0
@export var brake: float = 58.0
@export var max_speed: float = 18.0
@export var turn_speed: float = 2.6
@export var lift_speed: float = 9.0
@export var fuel_max: float = 100.0
@export var fuel_drain_idle: float = 0.65
@export var fuel_drain_moving: float = 2.2
@export var hull_max_hp: int = 70

var _fuel: float = 100.0
var _hull_hp: int = 100
var _destroyed: bool = false
var _driver: Node = null
var _body_mesh: MeshInstance3D = null


func _ready() -> void:
	_fuel = fuel_max
	_hull_hp = hull_max_hp
	_body_mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D


func set_driver(p: Node) -> void:
	_driver = p


func clear_driver() -> void:
	_driver = null


func has_driver() -> bool:
	return _driver != null and is_instance_valid(_driver)


func is_van_operable() -> bool:
	return not _destroyed


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
		_break()


func _break() -> void:
	if _destroyed:
		return
	_destroyed = true
	velocity = Vector3.ZERO
	if has_driver() and is_instance_valid(_driver) and _driver.has_method("exit_van"):
		_driver.call("exit_van")
	else:
		clear_driver()
	if _body_mesh:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.12, 0.18, 0.22, 1.0)
		m.roughness = 0.98
		_body_mesh.set_surface_override_material(0, m)


func _physics_process(delta: float) -> void:
	if not is_van_operable():
		velocity = velocity.move_toward(Vector3.ZERO, brake * delta)
		move_and_slide()
		return

	if has_driver():
		var motor_ok := _fuel > 0.001 or GameSave.is_creative()
		var fwd := -global_transform.basis.z
		fwd.y = 0.0
		if fwd.length_squared() > 0.0001:
			fwd = fwd.normalized()
		var spd := Vector3(velocity.x, 0.0, velocity.z).dot(fwd)
		if motor_ok and Input.is_physical_key_pressed(KEY_W):
			spd = move_toward(spd, max_speed, accel * delta)
		elif motor_ok and Input.is_physical_key_pressed(KEY_S):
			spd = move_toward(spd, -max_speed * 0.35, accel * 0.65 * delta)
		else:
			spd = move_toward(spd, 0.0, brake * delta)
		velocity.x = fwd.x * spd
		velocity.z = fwd.z * spd

		var upv := 0.0
		if motor_ok and Input.is_key_pressed(KEY_SPACE):
			upv += 1.0
		if motor_ok and (Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_CONTROL)):
			upv -= 1.0
		velocity.y = move_toward(velocity.y, upv * lift_speed, lift_speed * 2.2 * delta)

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
			if hspd > 0.35 or absf(velocity.y) > 0.25:
				drain += fuel_drain_moving * clampf(hspd / max_speed, 0.25, 1.0)
			_fuel = maxf(_fuel - drain * delta, 0.0)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, brake * delta)
		move_and_slide()

