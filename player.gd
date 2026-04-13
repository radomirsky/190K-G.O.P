extends CharacterBody3D

const THROWABLE_CUBE_SCENE := preload("res://throwable_cube.tscn")

@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.6
@export var mouse_sensitivity: float = 0.0025
@export var pickup_distance: float = 2.8
@export var throw_speed_min: float = 3.5
@export var throw_speed_max: float = 22.0
@export var throw_charge_full_time: float = 0.85
@export var body_push_multiplier: float = 1.15
@export var cube_spawn_distance: float = 3.0
@export var glue_look_distance: float = 4.0
@export var glue_pair_max_distance: float = 1.45

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D
@onready var _hold_point: Node3D = $CameraPivot/Camera3D/HoldPoint

var _held: RigidBody3D = null
var _jump_requested: bool = false
var _throw_press_usec: int = -1
var _standing_on_throwable: bool = false
var _held_saved_collision_layer: int = 1
var _held_saved_collision_mask: int = 1
var _cubes_world_locked: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_jump_requested = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		_camera_pivot.rotation.x = clampf(
			_camera_pivot.rotation.x,
			-PI / 2.0 + 0.02,
			PI / 2.0 - 0.02
		)

	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	):
		if event.pressed:
			if _held:
				_throw_press_usec = Time.get_ticks_usec()
		else:
			if _held and _throw_press_usec >= 0:
				_throw_held_charged()

	if event is InputEventKey and event.pressed and not event.echo:
		if (
			event.keycode == KEY_Q
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		):
			_spawn_throwable_cube()
		if (
			event.keycode == KEY_Z
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		):
			_toggle_cubes_world_lock()
		if (
			event.keycode == KEY_X
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		):
			_unlock_cubes_world()
		if (
			event.keycode == KEY_C
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		):
			_try_glue_throwable_cubes()
		if event.keycode == KEY_E and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if _held:
				_release_held()
			else:
				_try_pickup()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

	if is_on_floor() and _jump_requested:
		if _standing_on_throwable:
			_jump_requested = false
		else:
			velocity.y = jump_velocity
			_jump_requested = false

	var dir2 := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		dir2.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		dir2.x += 1.0
	if Input.is_key_pressed(KEY_W):
		dir2.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		dir2.y += 1.0

	var direction := Vector3.ZERO
	if dir2.length_squared() > 0.0:
		dir2 = dir2.normalized()
		direction = (transform.basis * Vector3(dir2.x, 0.0, dir2.y)).normalized()
		direction.y = 0.0
		if direction.length_squared() > 0.0:
			direction = direction.normalized()

	var target_xz := direction * move_speed
	velocity.x = target_xz.x
	velocity.z = target_xz.z

	var move_vel := velocity
	move_and_slide()
	_apply_body_pushes(move_vel)

	if _held:
		_held.global_position = _hold_point.global_position
		_held.linear_velocity = Vector3.ZERO
		_held.angular_velocity = Vector3.ZERO

	_standing_on_throwable = _is_standing_on_throwable_floor()


func _is_standing_on_throwable_floor() -> bool:
	if not is_on_floor():
		return false
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().y < 0.52:
			continue
		var col := c.get_collider()
		if col is RigidBody3D and col.is_in_group("throwable"):
			return true
	return false


func _spawn_throwable_cube() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var cube := THROWABLE_CUBE_SCENE.instantiate() as RigidBody3D
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
	else:
		forward = Vector3(0.0, 0.0, -1.0)
	var spawn_pos := global_position + forward * cube_spawn_distance
	spawn_pos.y = global_position.y + 0.5
	scene.add_child(cube)
	cube.global_position = spawn_pos
	cube.linear_velocity = Vector3.ZERO
	cube.angular_velocity = Vector3.ZERO
	if _cubes_world_locked:
		cube.freeze = true


func _toggle_cubes_world_lock() -> void:
	_cubes_world_locked = not _cubes_world_locked
	_apply_throwables_world_lock()


func _unlock_cubes_world() -> void:
	_cubes_world_locked = false
	_apply_throwables_world_lock()


func _apply_throwables_world_lock() -> void:
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var rb := node as RigidBody3D
		if rb == _held:
			continue
		rb.freeze = _cubes_world_locked
		if _cubes_world_locked:
			rb.linear_velocity = Vector3.ZERO
			rb.angular_velocity = Vector3.ZERO


func _raycast_aimed_throwable(max_dist: float) -> RigidBody3D:
	var space := get_world_3d().direct_space_state
	var from := _camera.global_position
	var to := from - _camera.global_transform.basis.z * max_dist
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty() or not hit.has("collider"):
		return null
	var col: Object = hit["collider"]
	if col is RigidBody3D and col.is_in_group("throwable"):
		return col as RigidBody3D
	return null


func _find_nearest_throwable(from_rb: RigidBody3D, max_dist: float) -> RigidBody3D:
	var best: RigidBody3D = null
	var best_d2 := max_dist * max_dist
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var rb := node as RigidBody3D
		if rb == from_rb or rb == _held:
			continue
		var d2 := from_rb.global_position.distance_squared_to(rb.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = rb
	return best


func _glue_joint_pair_exists(scene: Node, a: RigidBody3D, b: RigidBody3D) -> bool:
	var pa := scene.get_path_to(a)
	var pb := scene.get_path_to(b)
	for child in scene.get_children():
		if not child is PinJoint3D:
			continue
		var j := child as PinJoint3D
		var ja := j.node_a
		var jb := j.node_b
		if (ja == pa and jb == pb) or (ja == pb and jb == pa):
			return true
	return false


func _try_glue_throwable_cubes() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var a := _raycast_aimed_throwable(glue_look_distance)
	if a == null or a == _held:
		return
	var b := _find_nearest_throwable(a, glue_pair_max_distance)
	if b == null:
		return
	if _glue_joint_pair_exists(scene, a, b):
		return
	_unlock_cubes_world()
	a.freeze = false
	b.freeze = false
	a.linear_velocity = Vector3.ZERO
	b.linear_velocity = Vector3.ZERO
	a.angular_velocity = Vector3.ZERO
	b.angular_velocity = Vector3.ZERO
	var joint := PinJoint3D.new()
	joint.name = "CubeGlue_%s" % str(Time.get_ticks_msec())
	scene.add_child(joint)
	joint.global_position = (a.global_position + b.global_position) * 0.5
	joint.node_a = scene.get_path_to(a)
	joint.node_b = scene.get_path_to(b)
	joint.angular_limit_enabled = true
	joint.angular_limit_lower = deg_to_rad(-2.0)
	joint.angular_limit_upper = deg_to_rad(2.0)


func _apply_body_pushes(move_velocity: Vector3) -> void:
	var v_h := Vector3(move_velocity.x, 0.0, move_velocity.z)
	if v_h.length_squared() < 0.0001:
		return
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var col := c.get_collider()
		if not col is RigidBody3D:
			continue
		var rb := col as RigidBody3D
		if rb.freeze or rb == _held:
			continue
		var n := c.get_normal()
		var n_h := Vector3(n.x, 0.0, n.z)
		if n_h.length_squared() < 0.0001:
			continue
		n_h = n_h.normalized()
		var speed_into := v_h.dot(-n_h)
		if speed_into <= 0.0:
			continue
		rb.apply_central_impulse(-n_h * speed_into * rb.mass * body_push_multiplier)


func _try_pickup() -> void:
	var collider := _raycast_aimed_throwable(pickup_distance)
	if collider == null:
		return
	_held = collider
	_held_saved_collision_layer = _held.collision_layer
	_held_saved_collision_mask = _held.collision_mask
	_held.collision_layer = 0
	_held.collision_mask = 0
	_held.freeze = true
	_throw_press_usec = -1


func _release_held() -> void:
	if not _held:
		return
	_held.collision_layer = _held_saved_collision_layer
	_held.collision_mask = _held_saved_collision_mask
	_held.freeze = _cubes_world_locked
	_held = null
	_throw_press_usec = -1


func _throw_held_charged() -> void:
	if not _held:
		_throw_press_usec = -1
		return
	var elapsed_sec := (Time.get_ticks_usec() - _throw_press_usec) / 1_000_000.0
	_throw_press_usec = -1
	elapsed_sec = maxf(elapsed_sec, 0.0)
	var charge := clampf(elapsed_sec / maxf(throw_charge_full_time, 0.05), 0.0, 1.0)
	var speed := lerpf(throw_speed_min, throw_speed_max, charge)
	var impulse_dir := -_camera.global_transform.basis.z.normalized()
	_held.collision_layer = _held_saved_collision_layer
	_held.collision_mask = _held_saved_collision_mask
	_held.freeze = false
	_held.linear_velocity = impulse_dir * speed
	_held = null
