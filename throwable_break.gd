extends RigidBody3D

const CUBE_CHIP_SIZE_RATIO := 1.35
const CUBE_CHIP_COOLDOWN_USEC := 120_000

@export var destroy_min_relative_speed: float = 0.0
@export_range(2, 12, 1) var shatter_piece_count: int = 5
@export var shatter_shard_size: float = 0.38
@export var shatter_outward_impulse: float = 5.5
@export var min_shard_size: float = 0.11
@export_range(1, 2, 1) var final_crumb_count: int = 2
## Если >= 2, осколки при следующем ударе тоже делятся на столько кусков (один раз), затем снова обычная формула.
@export_range(0, 12, 1) var next_level_piece_count: int = 0

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 12
	if not body_shape_entered.is_connected(_on_body_shape_entered):
		body_shape_entered.connect(_on_body_shape_entered)


func _is_shatter_brick(rb: RigidBody3D) -> bool:
	return rb.has_method("_shatter_and_free") and (
		rb.name == "Cube" or rb.name.begins_with("BrickShard")
	)


func _cube_scale_mul(rb: RigidBody3D) -> float:
	if rb.name != "Cube":
		return 1.0
	return float(rb.get_meta("_cube_scale_mul", 1.0))


func _box_mesh_size(rb: RigidBody3D) -> Vector3:
	var mesh_i := rb.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_i and mesh_i.mesh is BoxMesh:
		return (mesh_i.mesh as BoxMesh).size
	return Vector3.ONE


func _v3_max_axis(v: Vector3) -> float:
	return maxf(v.x, maxf(v.y, v.z))


func _chip_cube_on_impact(big: RigidBody3D, small: RigidBody3D) -> void:
	if (
		not is_instance_valid(big)
		or not is_instance_valid(small)
		or big.name != "Cube"
		or small.name != "Cube"
	):
		return
	var now := Time.get_ticks_usec()
	var last: int = int(big.get_meta("_last_chip_usec", 0))
	if now - last < CUBE_CHIP_COOLDOWN_USEC:
		return
	big.set_meta("_last_chip_usec", now)

	var parent_node := big.get_parent()
	if parent_node == null:
		return

	var mesh_big := big.get_node_or_null("MeshInstance3D") as MeshInstance3D
	var col_big := big.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if mesh_big == null or col_big == null or not mesh_big.mesh is BoxMesh or not col_big.shape is BoxShape3D:
		return
	var big_s := (mesh_big.mesh as BoxMesh).size
	var vol_big := big_s.x * big_s.y * big_s.z
	if vol_big < 1e-4:
		return

	var small_s := _box_mesh_size(small)
	var chip_edge := clampf(
		_v3_max_axis(small_s) * 0.65,
		_v3_max_axis(big_s) * 0.07,
		_v3_max_axis(big_s) * 0.3
	)
	var vol_chip := chip_edge * chip_edge * chip_edge
	vol_chip = minf(vol_chip, vol_big * 0.22)
	chip_edge = pow(vol_chip, 1.0 / 3.0)
	var new_vol := vol_big - vol_chip
	var new_edge := pow(
		maxf(new_vol, pow(maxf(_v3_max_axis(big_s) * 0.32, 0.18), 3.0)),
		1.0 / 3.0
	)
	vol_chip = vol_big - pow(new_edge, 3.0)
	chip_edge = pow(maxf(vol_chip, 1e-5), 1.0 / 3.0)

	var away := small.global_position - big.global_position
	if away.length_squared() < 1e-6:
		away = big.global_transform.basis * Vector3.FORWARD
	away = away.normalized()
	var half := _v3_max_axis(big_s) * 0.5

	var bm_new := (mesh_big.mesh as BoxMesh).duplicate() as BoxMesh
	bm_new.size = Vector3(new_edge, new_edge, new_edge)
	mesh_big.mesh = bm_new
	var bs_new := (col_big.shape as BoxShape3D).duplicate() as BoxShape3D
	bs_new.size = Vector3(new_edge, new_edge, new_edge)
	col_big.shape = bs_new

	var mass_before := big.mass
	var ratio_m := pow(new_edge, 3.0) / vol_big
	big.mass *= ratio_m
	var rdim := new_edge / big_s.x
	if big.has_method("_shatter_and_free"):
		big.shatter_shard_size *= rdim
		big.min_shard_size *= rdim
	var mul_meta := _cube_scale_mul(big) * rdim
	big.set_meta("_cube_scale_mul", mul_meta)

	var label := big.get_node_or_null("BrickLabel") as Node3D
	if label:
		label.position *= rdim

	var mat_col := Color(0.42, 0.62, 0.92, 1.0)
	if mesh_big.get_surface_override_material(0) is StandardMaterial3D:
		mat_col = (mesh_big.get_surface_override_material(0) as StandardMaterial3D).albedo_color
	elif mesh_big.mesh:
		var smat: Material = mesh_big.mesh.surface_get_material(0)
		if smat is StandardMaterial3D:
			mat_col = (smat as StandardMaterial3D).albedo_color

	var scr: Script = load("res://throwable_break.gd") as Script
	var chip := RigidBody3D.new()
	chip.set_script(scr)
	chip.name = "BrickShard_%d_chip" % small.get_instance_id()
	chip.shatter_shard_size = maxf(chip_edge * 0.55, 0.07)
	chip.shatter_piece_count = 3
	chip.next_level_piece_count = 0
	chip.min_shard_size = maxf(chip.shatter_shard_size * 0.35, 0.06)
	chip.final_crumb_count = big.final_crumb_count
	chip.destroy_min_relative_speed = big.destroy_min_relative_speed
	chip.shatter_outward_impulse = big.shatter_outward_impulse * 0.85
	chip.mass = clampf(mass_before * (vol_chip / vol_big), 0.03, 2.5)
	chip.continuous_cd = true
	var mesh_c := MeshInstance3D.new()
	var bmc := BoxMesh.new()
	bmc.size = Vector3(chip_edge, chip_edge, chip_edge)
	mesh_c.mesh = bmc
	var mchip := StandardMaterial3D.new()
	mchip.albedo_color = mat_col
	mesh_c.set_surface_override_material(0, mchip)
	var col_c := CollisionShape3D.new()
	var bsc := BoxShape3D.new()
	bsc.size = Vector3(chip_edge, chip_edge, chip_edge)
	col_c.shape = bsc
	chip.add_child(mesh_c)
	chip.add_child(col_c)
	chip.add_to_group("throwable")
	parent_node.add_child(chip)
	ThrowablesBudget.track_throwable(chip)
	chip.global_position = big.global_position + away * (half + chip_edge * 0.52)
	var rel_v := small.linear_velocity - big.linear_velocity
	chip.linear_velocity = away * 5.5 + rel_v * 0.55 + big.linear_velocity * 0.25
	chip.angular_velocity = Vector3(
		randf_range(-5.0, 5.0), randf_range(-4.0, 5.0), randf_range(-5.0, 5.0)
	)

	small.queue_free()


func _on_body_shape_entered(
	_body_rid: RID,
	body: Node,
	_body_shape_index: int,
	_local_shape_index: int
) -> void:
	if is_in_group("held_throwable"):
		return
	if not ThrowablesBudget.brick_shattering_enabled:
		return
	# Пирамидки и кольца стазиса: при касании пола/платформ исчезают.
	if (
		(name == "Pyramid" or name == "StasisRing" or is_in_group("stasis_projectile"))
		and body is StaticBody3D
	):
		call_deferred("queue_free")
		return
	if not body is RigidBody3D:
		return
	if not body.is_in_group("throwable"):
		return
	if body == self:
		return
	var other := body as RigidBody3D
	if self.name == "Cube" and other.name == "Cube":
		var sm := _cube_scale_mul(self)
		var om := _cube_scale_mul(other)
		var lo := minf(sm, om)
		var hi := maxf(sm, om)
		if hi >= lo * CUBE_CHIP_SIZE_RATIO:
			if get_instance_id() < other.get_instance_id():
				return
			var big: RigidBody3D = self if sm > om else other
			var small: RigidBody3D = other if sm > om else self
			call_deferred("_chip_cube_on_impact", big, small)
			return
	if other.is_in_group("held_throwable"):
		var keep := linear_velocity
		call_deferred("_restore_velocity", keep)
		return
	var self_brick := _is_shatter_brick(self)
	var other_brick := _is_shatter_brick(other)
	var both_bricks := self_brick and other_brick
	var rel := linear_velocity.distance_to(other.linear_velocity)
	var sp := linear_velocity.length()
	var op := other.linear_velocity.length()
	const IDLE_SPD := 0.02
	const IDLE_REL := 0.035

	if not both_bricks:
		if sp < IDLE_SPD and op < IDLE_SPD and rel < IDLE_REL:
			return
		if destroy_min_relative_speed > 0.0 and rel < destroy_min_relative_speed:
			return
	if get_instance_id() < other.get_instance_id():
		return
	if is_instance_valid(other):
		if other_brick:
			other.call_deferred("_shatter_and_free")
		elif other.is_in_group("throwable"):
			other.call_deferred("queue_free")
	if self_brick:
		# Кирпичи не ломаем "сами от себя" при столкновении — ломается только один объект (other),
		# выбранный по instance_id выше.
		pass
	elif is_in_group("throwable"):
		call_deferred("queue_free")


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
	for i in final_crumb_count:
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
		ThrowablesBudget.track_throwable(crumb)
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
	var next_sz: float = maxf(sz * 0.64, min_shard_size * 0.95)
	var child_n: int
	if next_level_piece_count >= 2:
		child_n = clampi(next_level_piece_count, 2, 12)
	else:
		child_n = clampi(maxi(2, n - 1), 2, 8)
		if sz < 0.22:
			child_n = clampi(maxi(2, n - 2), 2, 6)
	var mass_scale := pow(next_sz / 0.38, 3.0)
	for i in n:
		var shard := RigidBody3D.new()
		shard.set_script(scr)
		shard.name = "BrickShard_%d_%d" % [get_instance_id(), i]
		shard.shatter_shard_size = next_sz
		shard.shatter_piece_count = child_n
		shard.next_level_piece_count = 0
		shard.min_shard_size = min_shard_size
		shard.final_crumb_count = final_crumb_count
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
		ThrowablesBudget.track_throwable(shard)
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
