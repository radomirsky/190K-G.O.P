extends CharacterBody3D
## Страж замка: броня и катана. Атака по королю — преследуют игрока.

@export var max_hp: int = 18
@export var move_speed: float = 4.9
@export var touch_damage: int = 7
@export var touch_distance: float = 1.85
@export var attack_cooldown_sec: float = 0.48
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var _hp: int = 18
var _dead: bool = false
var _aggro: bool = false
var _atk_cd: float = 0.0


func _ready() -> void:
	_hp = max_hp
	floor_snap_length = 0.12
	add_to_group("castle_guard")


func activate_aggro() -> void:
	if _dead:
		return
	_aggro = true


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_atk_cd = maxf(_atk_cd - delta, 0.0)
	if not _aggro:
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y -= gravity * delta
		move_and_slide()
		return
	var pl := _resolve_player()
	if pl == null:
		velocity.y -= gravity * delta
		move_and_slide()
		return
	var to_p: Vector3 = pl.global_position - global_position
	to_p.y = 0.0
	var fl := to_p.length()
	if fl > 0.07:
		to_p /= fl
		velocity.x = to_p.x * move_speed
		velocity.z = to_p.z * move_speed
		look_at(global_position + Vector3(to_p.x, 0.0, to_p.z), Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	velocity.y -= gravity * delta
	move_and_slide()
	_try_hit(pl)


func _resolve_player() -> Node3D:
	var ps := get_tree().get_nodes_in_group("player")
	if ps.size() > 0 and ps[0] is Node3D:
		return ps[0] as Node3D
	return null


func _try_hit(pl: Node3D) -> void:
	if _atk_cd > 0.0:
		return
	if global_position.distance_squared_to(pl.global_position) > touch_distance * touch_distance:
		return
	if pl.has_method("take_damage"):
		_atk_cd = attack_cooldown_sec
		pl.call("take_damage", touch_damage, "enemy")


func take_katana_hit(damage: int) -> void:
	if _dead:
		return
	var d := maxi(1, damage)
	_hp -= d
	if _hp <= 0:
		_die()
	else:
		_aggro = true


func _die() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("castle_guard")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	set_physics_process(false)
	for c in get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).visible = false
		elif c is Label3D:
			(c as Label3D).visible = false
