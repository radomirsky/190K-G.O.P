extends Node3D
## Турель на крыше фургона: прицел по камере водителя; ПКМ — бомба, ЛКМ — скорострел.

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
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		return
	var want_fire := false
	if bomb_turret:
		want_fire = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	else:
		want_fire = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if not want_fire:
		return
	var aim := _aim_world_point_from_driver_camera(van)
	_aim_at_world(aim)
	_cd -= delta
	if _cd > 0.0:
		return
	if bomb_turret:
		_fire_bomb(van, aim)
		_cd = bomb_cooldown_sec
	else:
		_fire_minigun(van, aim)
		_cd = minigun_cooldown_sec


func _aim_world_point_from_driver_camera(van: Node3D) -> Vector3:
	var drv := van.get_driver_node_or_null() as Node3D
	if drv == null:
		return van.global_position - van.global_transform.basis.z * 18.0
	var cam := drv.find_child("Camera3D", true, false) as Camera3D
	if cam == null:
		return van.global_position - van.global_transform.basis.z * 18.0
	var from := cam.global_position
	var dir := -cam.global_transform.basis.z.normalized()
	var to := from + dir * target_range
	var w := get_world_3d()
	if w == null:
		return to
	var space := w.direct_space_state
	if space == null:
		return to
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = true
	q.collide_with_bodies = true
	var ex: Array[RID] = [van.get_rid()]
	if drv is CollisionObject3D:
		ex.append((drv as CollisionObject3D).get_rid())
	q.exclude = ex
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return to
	return hit.position as Vector3


func _update_visual() -> void:
	visible = GameProgress.van_turrets_installed and not GameProgress.van_destroyed


func _aim_at_world(world_pt: Vector3) -> void:
	var p := global_position
	if p.distance_squared_to(world_pt) > 0.0004:
		look_at(world_pt, Vector3.UP)


func _muzzle_global() -> Vector3:
	return global_position - global_transform.basis.z * barrel_forward + Vector3(0.0, 0.08, 0.0)


func _fire_bomb(van: Node3D, aim: Vector3) -> void:
	var muzzle := _muzzle_global()
	var dir := aim - muzzle
	if dir.length_squared() < 0.001:
		dir = -van.global_transform.basis.z
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
	var w := get_world_3d()
	if w == null:
		return
	var space := w.direct_space_state
	if space == null:
		return
	var q := PhysicsRayQueryParameters3D.create(muzzle + to * 0.12, muzzle + to * target_range)
	q.collide_with_areas = true
	q.collide_with_bodies = true
	var ex: Array[RID] = [van.get_rid()]
	if van.has_method("get_driver_node_or_null"):
		var drv := van.call("get_driver_node_or_null") as Node
		if drv != null and drv is CollisionObject3D:
			ex.append((drv as CollisionObject3D).get_rid())
	q.exclude = ex
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return
	var col = hit.get("collider")
	if col == null or not col is Node:
		return
	var node := col as Node
	if node.is_in_group("enemy") and node.has_method("take_van_minigun_hit"):
		node.call("take_van_minigun_hit", minigun_damage)
