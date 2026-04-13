extends CharacterBody3D

@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.6
@export var mouse_sensitivity: float = 0.0025
@export var pickup_distance: float = 2.8
@export var throw_speed_min: float = 3.5
@export var throw_speed_max: float = 22.0
@export var throw_charge_full_time: float = 0.85

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D
@onready var _hold_point: Node3D = $CameraPivot/Camera3D/HoldPoint

var _held: RigidBody3D = null
var _jump_requested: bool = false
var _throw_press_usec: int = -1


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

	move_and_slide()

	if _held:
		_held.global_position = _hold_point.global_position
		_held.linear_velocity = Vector3.ZERO
		_held.angular_velocity = Vector3.ZERO


func _try_pickup() -> void:
	var space := get_world_3d().direct_space_state
	var from := _camera.global_position
	var to := from - _camera.global_transform.basis.z * pickup_distance
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider is RigidBody3D and collider.is_in_group("throwable"):
		_held = collider as RigidBody3D
		_held.freeze = true
		_throw_press_usec = -1


func _release_held() -> void:
	if not _held:
		return
	_held.freeze = false
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
	_held.freeze = false
	_held.linear_velocity = impulse_dir * speed
	_held = null
