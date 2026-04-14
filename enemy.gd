extends CharacterBody3D

@export var move_speed: float = 4.2
@export var accel: float = 18.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var player_path: NodePath = NodePath("../Player")
@export var break_cooldown_sec: float = 0.25
@export var break_radius: float = 1.35
@export var touch_damage: int = 8
@export var touch_distance: float = 2.1
@export var death_shard_impulse: float = 8.0
@export var death_shard_up: float = 3.5

var _break_cd: float = 0.0
var _player: Node3D = null
var _dead: bool = false

@onready var _break_area: Area3D = $BreakArea

func _ready() -> void:
	add_to_group("enemy")
	_player = get_node_or_null(player_path) as Node3D
	if _break_area and not _break_area.body_entered.is_connected(_on_break_area_body_entered):
		_break_area.body_entered.connect(_on_break_area_body_entered)


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	if _dead:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null(player_path) as Node3D

	_break_cd = maxf(_break_cd - delta, 0.0)

	velocity.y -= gravity * delta

	if _player:
		_try_damage_player()
		var to_p := _player.global_position - global_position
		to_p.y = 0.0
		if to_p.length_squared() > 0.0001:
			var dir := to_p.normalized()
			var target_xz := dir * move_speed
			velocity.x = lerpf(velocity.x, target_xz.x, 1.0 - exp(-accel * delta))
			velocity.z = lerpf(velocity.z, target_xz.z, 1.0 - exp(-accel * delta))

	move_and_slide()

func _try_damage_player() -> void:
	if _break_cd > 0.0 or _player == null:
		return
	if global_position.distance_squared_to(_player.global_position) > touch_distance * touch_distance:
		return
	if _player.has_method("take_damage"):
		_break_cd = break_cooldown_sec
		_player.call("take_damage", touch_damage)


func _die_scatter() -> void:
	if _dead:
		return
	_dead = true
	var scene := get_tree().current_scene
	if scene == null:
		queue_free()
		return
	var hum := get_node_or_null("Humanoid") as Node3D
	if hum == null:
		queue_free()
		return
	var mat_col := Color(0.95, 0.32, 0.32, 1.0)
	for child in hum.get_children():
		if not child is MeshInstance3D:
			continue
		var mi := child as MeshInstance3D
		if mi.get_surface_override_material(0) is StandardMaterial3D:
			mat_col = (mi.get_surface_override_material(0) as StandardMaterial3D).albedo_color
			break
	var scr: Script = load("res://throwable_break.gd") as Script
	for child in hum.get_children():
		if not child is MeshInstance3D:
			continue
		var mi := child as MeshInstance3D
		var rb := RigidBody3D.new()
		rb.set_script(scr)
		rb.name = "BrickShard_enemy_%d" % get_instance_id()
		rb.mass = 0.12
		rb.continuous_cd = true
		var mesh_i := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var sz := 0.85
		if mi.mesh is BoxMesh:
			sz = (mi.mesh as BoxMesh).size.x
		bm.size = Vector3(sz, sz, sz)
		mesh_i.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = mat_col
		mesh_i.set_surface_override_material(0, mat)
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(sz, sz, sz)
		col.shape = bs
		rb.add_child(mesh_i)
		rb.add_child(col)
		rb.add_to_group("throwable")
		scene.add_child(rb)
		ThrowablesBudget.track_throwable(rb)
		rb.global_position = mi.global_position
		var away := (mi.global_position - global_position)
		if away.length_squared() < 1e-6:
			away = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
		away = away.normalized()
		rb.linear_velocity = away * death_shard_impulse + Vector3.UP * death_shard_up
		rb.angular_velocity = Vector3(
			randf_range(-8.0, 8.0), randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)
		)
	queue_free()


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
		call_deferred("_die_scatter")
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
