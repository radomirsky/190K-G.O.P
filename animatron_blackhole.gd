extends Node3D

## После посадки (враг / пол / таймаут): рост и через lifetime_sec — взрыв.
@export var lifetime_sec: float = 5.0
@export var max_flight_sec: float = 24.0
@export var suck_radius: float = 24.0
@export var suck_accel: float = 26.0
@export var suck_up: float = 0.55
@export var fly_speed: float = 24.0
@export var grow_scale_end: float = 3.2
@export var explosion_radius: float = 14.0
@export var explosion_knockback: float = 22.0
@export var explosion_damage: int = 4

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
		elif _vel.length_squared() > 1e-10:
			var old_pos := global_position
			var new_pos := old_pos + _vel * delta
			if not _try_move_and_plant_on_hit(old_pos, new_pos):
				global_position = new_pos
	if _flying or _planted:
		_apply_suck(delta)


func _ray_collision_skip(col: Object) -> bool:
	if col is Node:
		var n := col as Node
		if n.is_in_group("player"):
			return true
		if n.is_in_group("throwable"):
			return true
	return false


func _ray_collision_plant(col: Object) -> bool:
	if col is Node and (col as Node).is_in_group("enemy"):
		return true
	if col is StaticBody3D or col is AnimatableBody3D:
		return true
	if col is RigidBody3D:
		return (col as RigidBody3D).freeze
	return false


func _try_move_and_plant_on_hit(from: Vector3, to: Vector3) -> bool:
	var w := get_world_3d()
	if w == null:
		return false
	var space := w.direct_space_state
	if space == null:
		return false
	var seg := to - from
	var seg_len := seg.length()
	if seg_len < 1e-8:
		return false
	var dir := seg / seg_len
	var start := from
	for __ in range(20):
		var q := PhysicsRayQueryParameters3D.create(start, to)
		q.collide_with_areas = false
		q.collide_with_bodies = true
		q.collision_mask = 0xFFFFFFFF
		var res := space.intersect_ray(q)
		if res.is_empty():
			return false
		var col: Object = res.get("collider")
		var hitp: Vector3 = res.get("position", to)
		if _ray_collision_skip(col):
			start = hitp + dir * 0.12
			if (to - start).dot(dir) < 0.02:
				return false
			continue
		if _ray_collision_plant(col):
			global_position = hitp
			_plant()
			return true
		start = hitp + dir * 0.12
		if (to - start).dot(dir) < 0.02:
			return false
	return false


func _plant() -> void:
	if not _flying:
		return
	_flying = false
	_planted = true
	_vel = Vector3.ZERO
	_plant_t = 0.0


func _apply_suck_to_body(body: CharacterBody3D, center: Vector3, delta: float) -> void:
	var to := center - body.global_position
	var dist := maxf(0.35, to.length())
	var dir := to / dist
	var k := clampf(1.0 - (dist / maxf(suck_radius, 0.1)), 0.0, 1.0)
	var pull := suck_accel * (0.25 + 0.75 * k) * delta
	body.velocity.x += dir.x * pull
	body.velocity.z += dir.z * pull
	body.velocity.y += (dir.y + suck_up) * pull * 0.85


func _apply_suck(delta: float) -> void:
	var center := global_position
	for body in _area.get_overlapping_bodies():
		if body == null or not body is CharacterBody3D:
			continue
		var n := body as Node
		if not n.is_in_group("enemy") and not n.is_in_group("player"):
			continue
		_apply_suck_to_body(body as CharacterBody3D, center, delta)


func _spawn_explosion_visual(parent: Node, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "BlackholeExplosionFx"
	parent.add_child(root)
	root.global_position = at

	var flash := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.56
	flash.mesh = sm
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.albedo_color = Color(0.7, 0.92, 1.0, 0.55)
	fmat.emission_enabled = true
	fmat.emission = Color(0.45, 0.82, 1.0)
	fmat.emission_energy_multiplier = 6.5
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.set_surface_override_material(0, fmat)
	flash.scale = Vector3(0.12, 0.12, 0.12)
	root.add_child(flash)

	var lit := OmniLight3D.new()
	lit.light_color = Color(0.55, 0.88, 1.0)
	lit.light_energy = 9.0
	lit.omni_range = explosion_radius * 1.35
	root.add_child(lit)

	# ParticleProcessMaterial только у GPUParticles3D (у CPUParticles3D в Godot 4 нет process_material).
	var gpu := GPUParticles3D.new()
	gpu.one_shot = true
	gpu.explosiveness = 0.94
	gpu.amount = 56
	gpu.lifetime = 0.52
	gpu.emitting = false
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 0.65
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 5.0
	pmat.initial_velocity_max = 19.0
	pmat.gravity = Vector3(0, -5, 0)
	pmat.scale_min = 0.1
	pmat.scale_max = 0.42
	pmat.color = Color(0.4, 0.78, 1.0)
	gpu.process_material = pmat
	var qm := QuadMesh.new()
	qm.size = Vector2(0.38, 0.38)
	gpu.draw_pass_1 = qm
	var pvis := StandardMaterial3D.new()
	pvis.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pvis.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pvis.emission_enabled = true
	pvis.emission = Color(0.55, 0.9, 1.0)
	pvis.emission_energy_multiplier = 2.2
	pvis.albedo_color = Color(1, 1, 1, 0.9)
	pvis.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gpu.material_override = pvis
	root.add_child(gpu)
	gpu.emitting = true

	var tw := root.create_tween()
	tw.set_parallel(true)
	var end_s := explosion_radius * 0.32
	tw.tween_property(flash, "scale", Vector3.ONE * end_s, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(fmat, "emission_energy_multiplier", 0.0, 0.45)
	tw.tween_property(fmat, "albedo_color:a", 0.0, 0.42)
	tw.tween_property(lit, "light_energy", 0.0, 0.32)
	tw.chain().tween_interval(0.55)
	tw.tween_callback(root.queue_free)


func _explode() -> void:
	var tree := get_tree()
	if tree == null:
		queue_free()
		return
	var scene: Node = tree.current_scene
	var center := global_position
	if scene:
		_spawn_explosion_visual(scene, center)

	for node in tree.get_nodes_in_group("enemy"):
		if not node is CharacterBody3D:
			continue
		var e := node as CharacterBody3D
		var to := e.global_position - center
		var dist := to.length()
		if dist > explosion_radius or dist < 0.01:
			continue
		if e.has_method("take_blackhole_explosion"):
			e.call("take_blackhole_explosion", explosion_damage)
		var dir := to / dist
		e.velocity += dir * explosion_knockback + Vector3.UP * (explosion_knockback * 0.4)

	for node in tree.get_nodes_in_group("player"):
		if not node is CharacterBody3D:
			continue
		var p := node as CharacterBody3D
		var to := p.global_position - center
		var dist := to.length()
		if dist > explosion_radius or dist < 0.01:
			continue
		if p.has_method("take_damage"):
			p.call("take_damage", explosion_damage)
		var dir := to / dist
		p.velocity += dir * explosion_knockback + Vector3.UP * (explosion_knockback * 0.4)

	queue_free()
