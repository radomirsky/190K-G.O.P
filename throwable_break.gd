extends RigidBody3D

@export var destroy_min_relative_speed: float = 0.0
@export_range(2, 12, 1) var shatter_piece_count: int = 5
@export var shatter_shard_size: float = 0.38
@export var shatter_outward_impulse: float = 5.5
@export var min_shard_size: float = 0.11

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 12
	if not body_shape_entered.is_connected(_on_body_shape_entered):
		body_shape_entered.connect(_on_body_shape_entered)


func _on_body_shape_entered(
	_body_rid: RID,
	body: Node,
	_body_shape_index: int,
	_local_shape_index: int
) -> void:
	if is_in_group("held_throwable"):
		return
	if not body is RigidBody3D:
		return
	if not body.is_in_group("throwable"):
		return
	if body == self:
		return
	var other := body as RigidBody3D
	if other.is_in_group("held_throwable"):
		var keep := linear_velocity
		call_deferred("_restore_velocity", keep)
		return
	var rel := linear_velocity.distance_to(other.linear_velocity)
	var sp := linear_velocity.length()
	var op := other.linear_velocity.length()
	const IDLE_SPD := 0.03
	const IDLE_REL := 0.05
	if sp < IDLE_SPD and op < IDLE_SPD and rel < IDLE_REL:
		return
	if destroy_min_relative_speed > 0.0 and rel < destroy_min_relative_speed:
		return
	const V_EPS := 0.008
	if sp < op - V_EPS:
		return
	if absf(sp - op) <= V_EPS:
		if get_instance_id() < other.get_instance_id():
			return
	var keep_v := linear_velocity
	if is_instance_valid(other):
		if other.has_method("_shatter_and_free") and (
			other.name == "Cube" or other.name.begins_with("BrickShard")
		):
			other.call_deferred("_shatter_and_free")
		else:
			other.call_deferred("queue_free")
	call_deferred("_restore_velocity", keep_v)


func _restore_velocity(v: Vector3) -> void:
	if is_instance_valid(self):
		linear_velocity = v


func _shatter_random_unit() -> Vector3:
	return Vector3(randf_range(-1.0, 1.0), randf_range(-0.35, 1.0), randf_range(-1.0, 1.0)).normalized()


func _spawn_final_crumbs() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		queue_free()
		return
	var p := global_position
	var inherit_v := linear_velocity
	var basis := global_transform.basis
	var sz := maxf(shatter_shard_size * 0.55, 0.055)
	var mat_col := Color(0.42, 0.62, 0.92, 1.0)
	for i in 2:
		var crumb := RigidBody3D.new()
		crumb.name = "BrickCrumb_%d_%d" % [get_instance_id(), i]
		crumb.mass = 0.04
		crumb.continuous_cd = true
		var mesh_i := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(sz, sz, sz)
		mesh_i.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = mat_col
		mesh_i.set_surface_override_material(0, mat)
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(sz, sz, sz)
		col.shape = bs
		crumb.add_child(mesh_i)
		crumb.add_child(col)
		crumb.add_to_group("throwable")
		parent_node.add_child(crumb)
		crumb.global_position = p + basis * Vector3(randf_range(-0.12, 0.12), randf_range(-0.08, 0.12), randf_range(-0.12, 0.12))
		crumb.linear_velocity = inherit_v * 0.35 + basis * _shatter_random_unit() * 2.8
		crumb.angular_velocity = Vector3(
			randf_range(-5.0, 5.0), randf_range(-5.0, 5.0), randf_range(-5.0, 5.0)
		)


func _shatter_and_free() -> void:
	if not is_instance_valid(self):
		return
	if shatter_shard_size < min_shard_size or shatter_shard_size * 0.74 < min_shard_size:
		_spawn_final_crumbs()
		queue_free()
		return
	var parent_node := get_parent()
	if parent_node == null:
		queue_free()
		return
	var scr: Script = load("res://throwable_break.gd") as Script
	var p := global_position
	var inherit_v := linear_velocity
	var ang := angular_velocity
	var basis := global_transform.basis
	var sz := shatter_shard_size
	var n: int = clampi(shatter_piece_count, 2, 12)
	var next_sz: float = maxf(sz * 0.74, min_shard_size * 0.95)
	var child_n: int = clampi(maxi(2, n - 1), 2, 8)
	if sz < 0.22:
		child_n = clampi(maxi(2, n - 2), 2, 6)
	var mass_scale := pow(next_sz / 0.38, 3.0)
	for i in n:
		var shard := RigidBody3D.new()
		shard.set_script(scr)
		shard.name = "BrickShard_%d_%d" % [get_instance_id(), i]
		shard.shatter_shard_size = next_sz
		shard.shatter_piece_count = child_n
		shard.min_shard_size = min_shard_size
		shard.destroy_min_relative_speed = destroy_min_relative_speed
		shard.shatter_outward_impulse = shatter_outward_impulse * 0.9
		shard.mass = clampf(0.11 * mass_scale, 0.03, 0.85)
		shard.continuous_cd = true
		var mesh_i := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(next_sz, next_sz, next_sz)
		mesh_i.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.42, 0.62, 0.92, 1.0)
		mesh_i.set_surface_override_material(0, mat)
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(next_sz, next_sz, next_sz)
		col.shape = bs
		shard.add_child(mesh_i)
		shard.add_child(col)
		shard.add_to_group("throwable")
		parent_node.add_child(shard)
		shard.global_position = (
			p
			+ basis * Vector3(randf_range(-0.22, 0.22), randf_range(-0.22, 0.22), randf_range(-0.22, 0.22))
		)
		var burst := basis * _shatter_random_unit() * shatter_outward_impulse
		shard.linear_velocity = inherit_v * randf_range(0.15, 0.45) + burst + ang.cross(
			basis * Vector3.UP
		) * randf_range(0.0, 0.35)
		shard.angular_velocity = Vector3(
			randf_range(-6.0, 6.0), randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)
		)
	queue_free()
