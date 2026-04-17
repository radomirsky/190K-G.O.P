extends Node3D
## Турель на крыше фургона: бомбомёт или скорострел (мини-пули без i-frame у врага).

const BOMB_SCENE := preload("res://van_bomb_projectile.tscn")

@export var bomb_turret: bool = true
@export var target_range: float = 40.0
@export var bomb_cooldown_sec: float = 1.05
@export var minigun_cooldown_sec: float = 0.072
@export var minigun_damage: int = 1
@export var barrel_forward: float = 0.55

var _cd: float = 0.0


func _ready() -> void:
	_update_visual()


func _process(_delta: float) -> void:
	_update_visual()


func _physics_process(delta: float) -> void:
	_update_visual()
	if GameProgress.van_destroyed:
		return
	if not GameProgress.van_turrets_installed:
		return
	var van := get_parent() as Node3D
	if van == null or not van.has_method("has_driver"):
		return
	if not bool(van.call("has_driver")):
		return
	if GameProgress.world_time_frozen:
		return
	_cd -= delta
	var target := _nearest_enemy(van)
	if target == null:
		return
	var aim := target.global_position + Vector3(0.0, 0.85, 0.0)
	_aim_flat(aim)
	if _cd > 0.0:
		return
	if bomb_turret:
		_fire_bomb(van, aim)
		_cd = bomb_cooldown_sec
	else:
		_fire_minigun(van, aim)
		_cd = minigun_cooldown_sec


func _update_visual() -> void:
	visible = GameProgress.van_turrets_installed and not GameProgress.van_destroyed


func _nearest_enemy(from_node: Node3D) -> Node3D:
	var best: Node3D = null
	var best_d2 := target_range * target_range
	var o := from_node.global_position
	for n in get_tree().get_nodes_in_group("enemy"):
		if not n is Node3D:
			continue
		var e := n as Node3D
		var d2 := o.distance_squared_to(e.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = e
	return best


func _aim_flat(world_pt: Vector3) -> void:
	var p := global_position
	var t := Vector3(world_pt.x, p.y, world_pt.z)
	if p.distance_squared_to(t) > 0.0004:
		look_at(t, Vector3.UP)


func _muzzle_global() -> Vector3:
	return global_position - global_transform.basis.z * barrel_forward + Vector3(0.0, 0.08, 0.0)


func _fire_bomb(van: Node3D, aim: Vector3) -> void:
	var muzzle := _muzzle_global()
	var dir := aim - muzzle
	dir.y = 0.0
	if dir.length_squared() < 0.001:
		dir = -van.global_transform.basis.z
		dir.y = 0.0
	dir = dir.normalized()
	var bomb := BOMB_SCENE.instantiate() as CharacterBody3D
	var scene := get_tree().current_scene
	if scene == null:
		bomb.queue_free()
		return
	scene.add_child(bomb)
	bomb.call("fire", muzzle + dir * 0.85, dir)


func _fire_minigun(van: Node3D, aim: Vector3) -> void:
	var muzzle := _muzzle_global()
	var to := aim - muzzle
	if to.length_squared() < 0.001:
		return
	to = to.normalized()
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(muzzle + to * 0.12, muzzle + to * target_range)
	q.collide_with_areas = true
	q.collide_with_bodies = true
	q.exclude = [van.get_rid()]
	if van.has_method("get_driver_node_or_null"):
		var drv := van.call("get_driver_node_or_null") as Node
		if drv != null and drv is CollisionObject3D:
			q.exclude.append((drv as CollisionObject3D).get_rid())
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return
	var col = hit.get("collider")
	if col == null or not col is Node:
		return
	var node := col as Node
	if node.is_in_group("enemy") and node.has_method("take_van_minigun_hit"):
		node.call("take_van_minigun_hit", minigun_damage)
