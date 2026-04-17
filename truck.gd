extends RigidBody3D
## Тяжёлый грузовик: давит врагов, сносит внутренние стены особняка.

@export var engine_force: float = 9200.0
@export var steer_speed: float = 0.55
@export var enemy_damage_from_speed_mul: float = 4.5
@export var enemy_damage_min: int = 6
@export var enemy_damage_max: int = 80
@export var wall_impulse_mul: float = 0.22
@export var hit_cooldown_sec: float = 0.35

var _hit_cd: Dictionary = {}  # instance_id -> seconds left


func _ready() -> void:
	body_shape_entered.connect(_on_body_shape_entered)
	gravity_scale = 1.0
	linear_damp = 0.15
	angular_damp = 0.8


func _physics_process(delta: float) -> void:
	_hit_cd_cleanup(delta)
	# Едет вперёд и плавно «рулит», чтобы не застревать в коридорах.
	apply_central_force(-global_transform.basis.z * engine_force)
	rotate_y(steer_speed * delta * sin(Time.get_ticks_msec() * 0.0007))


func _hit_cd_cleanup(delta: float) -> void:
	var rm: Array = []
	for k in _hit_cd.keys():
		_hit_cd[k] = float(_hit_cd[k]) - delta
		if float(_hit_cd[k]) <= 0.0:
			rm.append(k)
	for id in rm:
		_hit_cd.erase(id)


func _on_body_shape_entered(_body_rid: RID, body: Node, _body_shape: int, _local_shape: int) -> void:
	if body == null or not is_instance_valid(body):
		return
	var spd := linear_velocity.length()
	if body is CharacterBody3D and body.is_in_group("enemy"):
		if spd < 1.2:
			return
		var id := body.get_instance_id()
		if _hit_cd.get(id, 0.0) > 0.0:
			return
		_hit_cd[id] = hit_cooldown_sec
		var dmg := clampi(int(spd * enemy_damage_from_speed_mul), enemy_damage_min, enemy_damage_max)
		if body.has_method("take_truck_hit"):
			body.call("take_truck_hit", dmg)
		return
	if body is RigidBody3D and body.is_in_group("mansion_wall"):
		if spd < 2.0:
			return
		var id2 := body.get_instance_id()
		if _hit_cd.get(id2, 0.0) > 0.0:
			return
		_hit_cd[id2] = hit_cooldown_sec * 0.65
		var push := linear_velocity.normalized() * spd * mass * wall_impulse_mul
		body.apply_central_impulse(push)
		body.apply_torque_impulse(Vector3(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5), randf_range(-1.0, 1.0)) * spd * 0.08)
