extends CharacterBody3D

const THROWABLE_CUBE_SCENE := preload("res://throwable_cube.tscn")
const THROWABLE_PYRAMID_SCENE := preload("res://throwable_pyramid.tscn")
const THROWABLE_COLOR_FREE := Color(0.45, 0.65, 0.95, 1.0)
const THROWABLE_COLOR_FIXED := Color(0.28, 0.72, 0.38, 1.0)
const THROWABLE_COLOR_ENLARGE_HINT := Color(1.0, 0.9, 0.18, 1.0)
const _HUMANOID_CUBE_LOCAL: Array[Vector3] = [
	Vector3(-0.35, 0.5, 0),
	Vector3(0.35, 0.5, 0),
	Vector3(-0.35, 1.5, 0),
	Vector3(0.35, 1.5, 0),
	Vector3(0.0, 2.5, 0),
	Vector3(0.0, 3.5, 0),
	Vector3(-1.1, 3.7, 0),
	Vector3(1.1, 3.7, 0),
	Vector3(0.0, 4.7, 0),
	Vector3(0.0, 5.7, 0),
]

@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.6
@export var mouse_sensitivity: float = 0.0025
@export var pickup_distance: float = 2.8
@export var throw_speed_min: float = 3.5
@export var throw_speed_max: float = 22.0
@export var throw_charge_full_time: float = 0.85
@export_range(0.0, 1.0, 0.05) var throw_tap_charge: float = 1.0
@export var body_push_multiplier: float = 1.15
@export var cube_spawn_distance: float = 3.0
@export var pyramid_spawn_height: float = 0.575
@export var glue_look_distance: float = 4.0
@export var glue_pair_max_distance: float = 1.45
@export var humanoid_spawn_forward: float = 3.5
@export var cube_enlarge_factor: float = 1.15
@export var cube_enlarge_max_scale: float = 5.0
@export_range(1, 64, 1) var max_cubes_at_full_enlarge: int = 5
## Дальность выбора куба для Shift+E; не меньше aim_ray_length, чтобы целить как по прицелу по всей карте.
@export var cube_enlarge_ray_distance: float = 48.0
@export var aim_ray_length: float = 48.0
@export var look_key_speed: float = 1.85
@export_range(0.0, 48.0, 0.25) var look_smoothing: float = 14.0
@export_range(40.0, 120.0, 0.5) var camera_fov: float = 65.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D
@onready var _hold_point: Node3D = $CameraPivot/Camera3D/HoldPoint

var _held: RigidBody3D = null
var _enlarge_hint_rb: RigidBody3D = null
var _prev_enlarge_hint_rb: RigidBody3D = null
var _jump_requested: bool = false
var _throw_press_usec: int = -1
var _cubes_world_locked: bool = false
var _want_mouse_captured: bool = true
var _crosshair_layer: CanvasLayer = null
var _hit_marker: MeshInstance3D = null
var _look_yaw_target: float = 0.0
var _look_pitch_target: float = 0.0


func _ready() -> void:
	if _camera:
		_camera.fov = camera_fov
	_want_mouse_captured = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_center_mouse_in_viewport()
	var win := get_window()
	if win:
		var cb := Callable(self, "_restore_mouse_capture_after_focus")
		if not win.focus_entered.is_connected(cb):
			win.focus_entered.connect(cb)
	call_deferred("_setup_aim_feedback")
	_look_yaw_target = rotation.y
	_look_pitch_target = _camera_pivot.rotation.x


func _exit_tree() -> void:
	if _held and is_instance_valid(_held):
		_held.remove_from_group("held_throwable")
		remove_collision_exception_with(_held)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		call_deferred("_restore_mouse_capture_after_focus")


func _restore_mouse_capture_after_focus() -> void:
	if not is_inside_tree():
		return
	if _want_mouse_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_center_mouse_in_viewport()


func _center_mouse_in_viewport() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var r := vp.get_visible_rect()
	vp.warp_mouse(r.position + r.size * 0.5)


func _process(_delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or not _want_mouse_captured:
		return
	var vp := get_viewport()
	if vp == null:
		return
	var r := vp.get_visible_rect()
	vp.warp_mouse(r.position + r.size * 0.5)


func _pitch_limit() -> float:
	return PI / 2.0 - 0.02


func _clamp_camera_pitch() -> void:
	var lim := _pitch_limit()
	_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -lim, lim)


func _clamp_pitch_target(p: float) -> float:
	var lim := _pitch_limit()
	return clampf(p, -lim, lim)


func _aim_ray_from_dir() -> Array:
	var from: Vector3
	var dir: Vector3
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		from = _camera.global_position
		dir = -_camera.global_transform.basis.z
	else:
		var mp := get_viewport().get_mouse_position()
		from = _camera.project_ray_origin(mp)
		dir = _camera.project_ray_normal(mp)
	return [from, dir]


func _throw_aim_dir() -> Vector3:
	var ad := _aim_ray_from_dir()
	return (ad[1] as Vector3).normalized()


func _is_use_key(event: InputEventKey) -> bool:
	if not event.pressed or event.echo:
		return false
	# keycode — по раскладке; physical_keycode — физическая клавиша как на QWERTY (удобно при RU)
	return event.keycode == KEY_E or event.physical_keycode == KEY_E


func _world_actions_input_ok() -> bool:
	var m := Input.mouse_mode
	return m == Input.MOUSE_MODE_CAPTURED or m == Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_jump_requested = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_want_mouse_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_center_mouse_in_viewport()
		_look_yaw_target = rotation.y
		_look_pitch_target = _camera_pivot.rotation.x
		get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion:
		if (
			Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			or Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
		):
			_look_yaw_target -= event.relative.x * mouse_sensitivity
			_look_pitch_target = _clamp_pitch_target(
				_look_pitch_target - event.relative.y * mouse_sensitivity
			)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if (
			Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			or Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
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
			and (event.ctrl_pressed or Input.is_key_pressed(KEY_CTRL))
			and not (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
		):
			ThrowablesBudget.brick_shattering_enabled = (
				not ThrowablesBudget.brick_shattering_enabled
			)
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_Q
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_spawn_throwable_cube()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_R
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_spawn_throwable_pyramid()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_Z
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_toggle_cubes_world_lock()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_X
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_unlock_cubes_world()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_B
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_arrange_cubes_humanoid()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_G
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_try_glue_throwable_cubes()
			get_viewport().set_input_as_handled()
		elif (
			_is_use_key(event)
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			if _try_enlarge_cube():
				get_viewport().set_input_as_handled()
			elif _held:
				_release_held()
				get_viewport().set_input_as_handled()
		elif _is_use_key(event):
			if _held:
				_throw_held_tap()
			else:
				_try_pickup()
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

	if _jump_requested:
		velocity.y = jump_velocity
		_jump_requested = false

	var dir2 := Vector2.ZERO
	# Физические позиции WASD — движение не ломается на русской и др. раскладке.
	if Input.is_physical_key_pressed(KEY_A):
		dir2.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		dir2.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		dir2.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
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

	var lk := look_key_speed * delta
	if Input.is_key_pressed(KEY_LEFT):
		_look_yaw_target += lk
	if Input.is_key_pressed(KEY_RIGHT):
		_look_yaw_target -= lk
	if Input.is_key_pressed(KEY_UP):
		_look_pitch_target = _clamp_pitch_target(_look_pitch_target + lk)
	if Input.is_key_pressed(KEY_DOWN):
		_look_pitch_target = _clamp_pitch_target(_look_pitch_target - lk)

	var smooth_k := 1.0
	if look_smoothing > 0.0:
		smooth_k = 1.0 - exp(-look_smoothing * delta)
	rotation.y = lerp_angle(rotation.y, _look_yaw_target, smooth_k)
	_camera_pivot.rotation.x = lerpf(
		_camera_pivot.rotation.x,
		_look_pitch_target,
		smooth_k
	)
	_clamp_camera_pitch()

	if _held:
		_held.global_position = _hold_point.global_position
		_held.linear_velocity = Vector3.ZERO
		_held.angular_velocity = Vector3.ZERO

	_update_enlarge_hint_target()
	_update_aim_feedback()
	if _enlarge_hint_rb != _prev_enlarge_hint_rb:
		_prev_enlarge_hint_rb = _enlarge_hint_rb
		_refresh_all_throwable_visuals()


func _setup_aim_feedback() -> void:
	if _crosshair_layer == null:
		_crosshair_layer = CanvasLayer.new()
		_crosshair_layer.layer = 100
		add_child(_crosshair_layer)
		var root := Control.new()
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_crosshair_layer.add_child(root)
		var cc := CenterContainer.new()
		cc.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(cc)
		var cross := Control.new()
		cross.custom_minimum_size = Vector2(22, 22)
		var vbar := ColorRect.new()
		vbar.position = Vector2(10, 3)
		vbar.size = Vector2(2, 16)
		vbar.color = Color(1, 1, 1, 0.92)
		var hbar := ColorRect.new()
		hbar.position = Vector2(3, 10)
		hbar.size = Vector2(16, 2)
		hbar.color = Color(1, 1, 1, 0.92)
		cross.add_child(vbar)
		cross.add_child(hbar)
		cc.add_child(cross)

	if _hit_marker == null:
		var scene := get_tree().current_scene
		if scene == null:
			return
		_hit_marker = MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.065
		sm.height = 0.13
		_hit_marker.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.9, 0.2, 0.95)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_hit_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_hit_marker.material_override = mat
		_hit_marker.visible = false
		scene.add_child(_hit_marker)


func _update_aim_feedback() -> void:
	if _hit_marker == null or _camera == null or not is_inside_tree():
		return
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if _crosshair_layer:
			_crosshair_layer.visible = true
	else:
		if _crosshair_layer:
			_crosshair_layer.visible = false
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var dir: Vector3 = ad[1]

	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + dir.normalized() * aim_ray_length)
	q.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		_hit_marker.visible = false
		return
	var n := Vector3.UP
	if hit.has("normal"):
		n = hit["normal"] as Vector3
	_hit_marker.global_position = hit.position as Vector3 + n * 0.04
	_hit_marker.visible = true


func _get_throwable_mesh(rb: RigidBody3D) -> MeshInstance3D:
	return rb.get_node_or_null("MeshInstance3D") as MeshInstance3D


func _is_enlargeable_brick_box(rb: RigidBody3D) -> bool:
	if rb == null:
		return false
	if rb.name == "Cube":
		return true
	if rb.name.begins_with("BrickShard"):
		var m := _get_throwable_mesh(rb)
		return m != null and m.mesh is BoxMesh
	return false


func _raycast_aimed_enlarge_box(max_dist: float) -> RigidBody3D:
	var rb := _raycast_aimed_throwable(max_dist)
	if rb != null and _is_enlargeable_brick_box(rb):
		return rb
	return _nearest_enlargeable_box_on_aim(max_dist)


func _nearest_enlargeable_box_on_aim(max_dist: float) -> RigidBody3D:
	var ad := _aim_ray_from_dir()
	var o: Vector3 = ad[0]
	var dir: Vector3 = (ad[1] as Vector3).normalized()
	var best: RigidBody3D = null
	var best_t := INF
	const MAX_SEP := 1.45
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var cand := node as RigidBody3D
		if cand == _held or not _is_enlargeable_brick_box(cand):
			continue
		var rel := cand.global_position - o
		var t := rel.dot(dir)
		if t < 0.15 or t > max_dist:
			continue
		var perp2 := rel.length_squared() - t * t
		if perp2 > MAX_SEP * MAX_SEP:
			continue
		if best == null or t < best_t:
			best_t = t
			best = cand
	return best


func _enlarge_pick_ray_distance() -> float:
	return maxf(cube_enlarge_ray_distance, aim_ray_length)


func _count_cubes_at_full_enlarge() -> int:
	var n := 0
	var lim := cube_enlarge_max_scale
	const EPS := 0.03
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var rb := node as RigidBody3D
		if not _is_enlargeable_brick_box(rb):
			continue
		var m := float(rb.get_meta("_cube_scale_mul", 1.0))
		if m >= lim - EPS:
			n += 1
	return n


func _try_enlarge_cube() -> bool:
	var rb: RigidBody3D = null
	if _held and _is_enlargeable_brick_box(_held):
		rb = _held
	else:
		rb = _raycast_aimed_enlarge_box(_enlarge_pick_ray_distance())
	if rb == null:
		return false
	_enlarge_cube(rb)
	return true


func _update_enlarge_hint_target() -> void:
	var t: RigidBody3D = null
	if _held and _is_enlargeable_brick_box(_held):
		t = _held
	else:
		t = _raycast_aimed_enlarge_box(_enlarge_pick_ray_distance())
	if t != null and _enlarge_would_apply(t):
		_enlarge_hint_rb = t
	else:
		_enlarge_hint_rb = null


func _enlarge_would_apply(rb: RigidBody3D) -> bool:
	if rb == null or not is_instance_valid(rb) or not _is_enlargeable_brick_box(rb):
		return false
	var mul: float = float(rb.get_meta("_cube_scale_mul", 1.0))
	var new_mul := minf(mul * cube_enlarge_factor, cube_enlarge_max_scale)
	var ratio := new_mul / mul
	if ratio <= 1.0001:
		return false
	const EPS := 0.03
	var was_below_full := mul < cube_enlarge_max_scale - EPS
	var hits_full := new_mul >= cube_enlarge_max_scale - EPS
	if (
		was_below_full
		and hits_full
		and _count_cubes_at_full_enlarge() >= max_cubes_at_full_enlarge
	):
		return false
	return true


func _enlarge_cube(rb: RigidBody3D) -> void:
	if not _enlarge_would_apply(rb):
		return
	var mul: float = float(rb.get_meta("_cube_scale_mul", 1.0))
	var new_mul := minf(mul * cube_enlarge_factor, cube_enlarge_max_scale)
	var ratio := new_mul / mul

	# Замороженные заспавненные кубы (мир/человекоид): без кадра без freeze коллизия может не обновиться.
	var restore_frozen_static := (
		rb != _held
		and rb.freeze
		and rb.freeze_mode == RigidBody3D.FREEZE_MODE_STATIC
	)
	if restore_frozen_static:
		rb.freeze = false

	rb.set_meta("_cube_scale_mul", new_mul)

	var mesh_i := _get_throwable_mesh(rb)
	var col_n := rb.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if mesh_i and mesh_i.mesh is BoxMesh:
		var bm := (mesh_i.mesh as BoxMesh).duplicate() as BoxMesh
		bm.size *= ratio
		mesh_i.mesh = bm
	if col_n and col_n.shape is BoxShape3D:
		var bs := (col_n.shape as BoxShape3D).duplicate() as BoxShape3D
		bs.size *= ratio
		col_n.shape = bs

	rb.mass *= pow(ratio, 3.0)
	if rb.has_method("_shatter_and_free"):
		rb.shatter_shard_size *= ratio
		rb.min_shard_size *= ratio

	var label := rb.get_node_or_null("BrickLabel") as Node3D
	if label:
		label.position *= ratio

	if restore_frozen_static:
		rb.freeze = true
		rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC

	_update_enlarge_hint_target()
	_prev_enlarge_hint_rb = _enlarge_hint_rb
	_refresh_all_throwable_visuals()


func _ensure_throwable_material(mesh: MeshInstance3D) -> StandardMaterial3D:
	var body := mesh.get_parent() as RigidBody3D
	var ovr := mesh.get_surface_override_material(0) as StandardMaterial3D
	if ovr:
		if body and not body.has_meta("_free_albedo"):
			body.set_meta("_free_albedo", ovr.albedo_color)
		return ovr
	var src: Material = null
	if mesh.mesh:
		src = mesh.mesh.surface_get_material(0)
	if src is StandardMaterial3D:
		ovr = (src as StandardMaterial3D).duplicate() as StandardMaterial3D
	else:
		ovr = StandardMaterial3D.new()
		ovr.albedo_color = THROWABLE_COLOR_FREE
	mesh.set_surface_override_material(0, ovr)
	if body and not body.has_meta("_free_albedo"):
		body.set_meta("_free_albedo", ovr.albedo_color)
	return ovr


func _update_throwable_visual(rb: RigidBody3D) -> void:
	if rb == null or not is_instance_valid(rb):
		return
	var mesh := _get_throwable_mesh(rb)
	if mesh == null:
		return
	var mat := _ensure_throwable_material(mesh)
	var free_col := THROWABLE_COLOR_FREE
	if rb.has_meta("_free_albedo"):
		free_col = rb.get_meta("_free_albedo") as Color
	if rb == _enlarge_hint_rb and _enlarge_would_apply(rb):
		mat.albedo_color = THROWABLE_COLOR_ENLARGE_HINT
	elif rb == _held:
		mat.albedo_color = free_col
	elif rb.freeze:
		mat.albedo_color = THROWABLE_COLOR_FIXED
	else:
		mat.albedo_color = free_col


func _refresh_all_throwable_visuals() -> void:
	for node in get_tree().get_nodes_in_group("throwable"):
		if node is RigidBody3D:
			_update_throwable_visual(node as RigidBody3D)


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
	cube.set_meta("_player_spawned", true)
	scene.add_child(cube)
	cube.global_position = spawn_pos
	cube.linear_velocity = Vector3.ZERO
	cube.angular_velocity = Vector3.ZERO
	if _cubes_world_locked:
		cube.freeze = true
		cube.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	_update_throwable_visual(cube)
	ThrowablesBudget.track_throwable(cube)


func _spawn_throwable_pyramid() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var pyr := THROWABLE_PYRAMID_SCENE.instantiate() as RigidBody3D
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
	else:
		forward = Vector3(0.0, 0.0, -1.0)
	var spawn_pos := global_position + forward * cube_spawn_distance
	spawn_pos.y = global_position.y + pyramid_spawn_height
	scene.add_child(pyr)
	pyr.global_position = spawn_pos
	pyr.linear_velocity = Vector3.ZERO
	pyr.angular_velocity = Vector3.ZERO
	if _cubes_world_locked:
		pyr.freeze = true
		pyr.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	_update_throwable_visual(pyr)
	ThrowablesBudget.track_throwable(pyr)


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
			rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
			rb.linear_velocity = Vector3.ZERO
			rb.angular_velocity = Vector3.ZERO
	_refresh_all_throwable_visuals()


func _raycast_aimed_throwable(max_dist: float) -> RigidBody3D:
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var dir: Vector3 = (ad[1] as Vector3).normalized()
	var space := get_world_3d().direct_space_state
	var to := from + dir * max_dist
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = true
	var excl: Array[RID] = [get_rid()]
	if _held != null and is_instance_valid(_held):
		excl.append(_held.get_rid())
	query.exclude = excl
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


func _humanoid_floor_anchor() -> Vector3:
	var flat_fwd := -global_transform.basis.z
	flat_fwd.y = 0.0
	if flat_fwd.length_squared() < 1e-5:
		flat_fwd = Vector3(0.0, 0.0, -1.0)
	else:
		flat_fwd = flat_fwd.normalized()
	var origin := global_position + flat_fwd * humanoid_spawn_forward + Vector3(0, 4.0, 0)
	var space := get_world_3d().direct_space_state
	var excl: Array[RID] = [get_rid()]
	if _held:
		excl.append(_held.get_rid())
	var q := PhysicsRayQueryParameters3D.create(origin, origin + Vector3(0, -40.0, 0))
	q.exclude = excl
	var hit: Dictionary = space.intersect_ray(q)
	if not hit.is_empty() and hit.has("position"):
		return hit.position as Vector3
	return global_position + flat_fwd * humanoid_spawn_forward + Vector3(0, 0.5, 0.0)


func _arrange_cubes_humanoid() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var anchor := _humanoid_floor_anchor()
	var yaw_basis := Basis.from_euler(Vector3(0.0, rotation.y, 0.0))
	for off in _HUMANOID_CUBE_LOCAL:
		var world_pos := anchor + yaw_basis * off
		var cube := THROWABLE_CUBE_SCENE.instantiate() as RigidBody3D
		cube.set_meta("_player_spawned", true)
		scene.add_child(cube)
		cube.global_position = world_pos
		cube.global_rotation = Vector3.ZERO
		cube.linear_velocity = Vector3.ZERO
		cube.angular_velocity = Vector3.ZERO
		cube.freeze = true
		cube.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		_update_throwable_visual(cube)
		ThrowablesBudget.track_throwable(cube)


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
	joint.set_param(PinJoint3D.PARAM_BIAS, 0.65)
	joint.set_param(PinJoint3D.PARAM_DAMPING, 1.15)
	_update_throwable_visual(a)
	_update_throwable_visual(b)


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
	_held.add_to_group("held_throwable")
	add_collision_exception_with(_held)
	_held.freeze = true
	_held.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	_throw_press_usec = -1
	_update_throwable_visual(_held)


func _release_held() -> void:
	if not _held:
		return
	var body := _held
	body.remove_from_group("held_throwable")
	remove_collision_exception_with(body)
	body.freeze = _cubes_world_locked
	if _cubes_world_locked:
		body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	_held = null
	_throw_press_usec = -1
	_update_throwable_visual(body)


func _apply_throw_body(body: RigidBody3D, dir: Vector3, speed: float) -> void:
	body.remove_from_group("held_throwable")
	remove_collision_exception_with(body)
	body.freeze = false
	body.linear_velocity = dir * speed
	_held = null
	_throw_press_usec = -1
	_update_throwable_visual(body)


func _throw_held_tap() -> void:
	if not _held:
		return
	var body := _held
	var charge := clampf(throw_tap_charge, 0.0, 1.0)
	var speed := lerpf(throw_speed_min, throw_speed_max, charge)
	_apply_throw_body(body, _throw_aim_dir(), speed)


func _throw_held_charged() -> void:
	if not _held:
		_throw_press_usec = -1
		return
	var body := _held
	var elapsed_sec := (Time.get_ticks_usec() - _throw_press_usec) / 1_000_000.0
	_throw_press_usec = -1
	elapsed_sec = maxf(elapsed_sec, 0.0)
	var charge := clampf(elapsed_sec / maxf(throw_charge_full_time, 0.05), 0.0, 1.0)
	var speed := lerpf(throw_speed_min, throw_speed_max, charge)
	_apply_throw_body(body, _throw_aim_dir(), speed)
