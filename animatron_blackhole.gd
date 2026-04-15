extends Node3D

## После посадки (попадание во врага или таймаут полёта): рост и через lifetime_sec — взрыв.
@export var lifetime_sec: float = 5.0
@export var max_flight_sec: float = 24.0
@export var suck_radius: float = 24.0
@export var suck_accel: float = 26.0
@export var suck_up: float = 0.55
@export var fly_speed: float = 24.0
@export var grow_scale_end: float = 3.2
@export var explosion_radius: float = 14.0
@export var explosion_knockback: float = 22.0

var _vel: Vector3 = Vector3.ZERO
var _flying: bool = true
var _planted: bool = false
var _plant_t: float = 0.0
var _flight_t: float = 0.0

@onready var _area: Area3D = $Area3D
@onready var _col: CollisionShape3D = $Area3D/CollisionShape3D
@onready var _mesh: MeshInstance3D = $MeshInstance3D

var _mesh_scale0: Vector3 = Vector3.ONE


func _ready() -> void:
	if _mesh:
		_mesh_scale0 = _mesh.scale
	if _col and _col.shape is SphereShape3D:
		(_col.shape as SphereShape3D).radius = suck_radius


func set_initial_velocity(v: Vector3) -> void:
	_vel = v


func _process(delta: float) -> void:
	if not _planted:
		return
	_plant_t += delta
	var k := clampf(_plant_t / maxf(lifetime_sec, 0.05), 0.0, 1.0)
	if _mesh:
		var s := lerpf(1.0, grow_scale_end, k)
		_mesh.scale = _mesh_scale0 * s
	if _plant_t >= lifetime_sec:
		_explode()


func _physics_process(delta: float) -> void:
	if _area == null:
		return
	if _flying:
		_flight_t += delta
		if _flight_t >= max_flight_sec:
			_plant()
			return
		var step := _vel * delta
		if step.length_squared() > 1e-10:
			var old_pos := global_position
			var new_pos := old_pos + step
			if _ray_hits_enemy(old_pos, new_pos):
				return
			global_position = new_pos
		_apply_suck(delta)


func _ray_hits_enemy(from: Vector3, to: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.collision_mask = 0xFFFFFFFF
	var res := space.intersect_ray(q)
	if res.is_empty():
		return false
	var col: Object = res.get("collider")
	if col is Node and (col as Node).is_in_group("enemy"):
		var hit_pos: Vector3 = res.get("position", to)
		global_position = hit_pos
		_plant()
		return true
	return false


func _plant() -> void:
	if not _flying:
		return
	_flying = false
	_planted = true
	_vel = Vector3.ZERO
	_plant_t = 0.0


func _apply_suck(delta: float) -> void:
	var center := global_position
	for body in _area.get_overlapping_bodies():
		if body == null:
			continue
		if not (body is Node) or not (body as Node).is_in_group("enemy"):
			continue
		var e := body as CharacterBody3D
		if e == null:
			continue
		var to := center - e.global_position
		var dist := maxf(0.35, to.length())
		var dir := to / dist
		var k := clampf(1.0 - (dist / maxf(suck_radius, 0.1)), 0.0, 1.0)
		var pull := suck_accel * (0.25 + 0.75 * k) * delta
		e.velocity.x += dir.x * pull
		e.velocity.z += dir.z * pull
		e.velocity.y += (dir.y + suck_up) * pull * 0.85


func _explode() -> void:
	var tree := get_tree()
	if tree == null:
		queue_free()
		return
	var center := global_position
	for node in tree.get_nodes_in_group("enemy"):
		if not node is CharacterBody3D:
			continue
		var e := node as CharacterBody3D
		var to := e.global_position - center
		var dist := to.length()
		if dist > explosion_radius or dist < 0.01:
			continue
		var dir := to / dist
		e.velocity += dir * explosion_knockback + Vector3.UP * (explosion_knockback * 0.4)
	queue_free()
