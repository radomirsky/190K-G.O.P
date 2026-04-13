extends RigidBody3D

@export var destroy_min_relative_speed: float = 1.15
@export_range(1, 12, 1) var shatter_piece_count: int = 5
@export var shatter_shard_size: float = 0.38
@export var shatter_outward_impulse: float = 5.5
@export var debris_lifetime_sec: float = 7.0

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
	if rel < destroy_min_relative_speed:
		return
	var v2 := linear_velocity.length_squared()
	var o2 := other.linear_velocity.length_squared()
	const EPS := 1e-3
	if v2 < o2 - EPS:
		return
	if absf(v2 - o2) <= EPS:
		if get_instance_id() < other.get_instance_id():
			return
	var keep_v := linear_velocity
	if is_instance_valid(other):
		if other.name == "Cube":
			other.call_deferred("_shatter_and_free")
		else:
			other.call_deferred("queue_free")
	call_deferred("_restore_velocity", keep_v)


func _restore_velocity(v: Vector3) -> void:
	if is_instance_valid(self):
		linear_velocity = v


func _shatter_random_unit() -> Vector3:
	return Vector3(randf_range(-1.0, 1.0), randf_range(-0.35, 1.0), randf_range(-1.0, 1.0)).normalized()


func _shatter_and_free() -> void:
	if not is_instance_valid(self):
		return
	var parent_node := get_parent()
	if parent_node == null:
		queue_free()
		return
	var p := global_position
	var inherit_v := linear_velocity
	var ang := angular_velocity
	var basis := global_transform.basis
	var sz := shatter_shard_size
	var n: int = clampi(shatter_piece_count, 1, 12)
	for i in n:
		var shard := RigidBody3D.new()
		shard.name = "BrickShard_%d_%d" % [get_instance_id(), i]
		shard.mass = 0.11
		shard.continuous_cd = true
		var mesh_i := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(sz, sz, sz)
		mesh_i.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.42, 0.62, 0.92, 1.0)
		mesh_i.set_surface_override_material(0, mat)
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(sz, sz, sz)
		col.shape = bs
		shard.add_child(mesh_i)
		shard.add_child(col)
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
		if debris_lifetime_sec > 0.05:
			var t := get_tree().create_timer(debris_lifetime_sec)
			t.timeout.connect(
				func() -> void:
					if is_instance_valid(shard):
						shard.queue_free()
			)
	queue_free()
