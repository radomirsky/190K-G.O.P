extends CharacterBody3D

@export var move_speed: float = 4.2
@export var accel: float = 18.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var player_path: NodePath = NodePath("../Player")
@export var break_cooldown_sec: float = 0.25
@export var break_radius: float = 1.35

var _break_cd: float = 0.0
var _player: Node3D = null

@onready var _break_area: Area3D = $BreakArea

func _ready() -> void:
	add_to_group("enemy")
	_player = get_node_or_null(player_path) as Node3D
	if _break_area and not _break_area.body_entered.is_connected(_on_break_area_body_entered):
		_break_area.body_entered.connect(_on_break_area_body_entered)


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null(player_path) as Node3D

	_break_cd = maxf(_break_cd - delta, 0.0)

	velocity.y -= gravity * delta

	if _player:
		var to_p := _player.global_position - global_position
		to_p.y = 0.0
		if to_p.length_squared() > 0.0001:
			var dir := to_p.normalized()
			var target_xz := dir * move_speed
			velocity.x = lerpf(velocity.x, target_xz.x, 1.0 - exp(-accel * delta))
			velocity.z = lerpf(velocity.z, target_xz.z, 1.0 - exp(-accel * delta))

	move_and_slide()


func _on_break_area_body_entered(body: Node) -> void:
	if _break_cd > 0.0:
		return
	if not body is RigidBody3D:
		return
	var rb := body as RigidBody3D
	if not rb.is_in_group("throwable"):
		return

	# Попали кубом в врага — враг разваливается.
	if rb.name == "Cube" or rb.name.begins_with("BrickShard") or rb.name == "Pyramid":
		_break_cd = break_cooldown_sec
		# Снаряд НЕ ломаем — только убиваем врага.
		# Можно чуть "отпружинить" куб от врага, чтобы было ощущение удара.
		if is_instance_valid(rb):
			var away := (rb.global_position - global_position)
			away.y = 0.0
			if away.length_squared() > 0.0001:
				away = away.normalized()
				rb.apply_central_impulse(away * 1.25)
		call_deferred("queue_free")
		return

	# Враг ломает твои кубы рядом.
	if _break_cd <= 0.0:
		_break_cd = break_cooldown_sec
		_break_nearby_bricks()


func _break_nearby_bricks() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var r2 := break_radius * break_radius
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var rb := node as RigidBody3D
		if rb.name != "Cube" and not rb.name.begins_with("BrickShard"):
			continue
		if global_position.distance_squared_to(rb.global_position) > r2:
			continue
		if rb.is_in_group("held_throwable"):
			continue
		if rb.has_method("_shatter_and_free"):
			rb.call_deferred("_shatter_and_free")
		else:
			rb.call_deferred("queue_free")
