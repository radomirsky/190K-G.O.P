extends Node

## Жетоны «МАМА» с подбираемых дропов; тратятся в магазине.
signal mama_changed(new_total: int)
signal kills_changed(total: int)
signal boss_spawn_requested
signal upgrades_changed

const KILLS_FOR_BOSS := 10
const BOSS_MAMA_PICKUP_COUNT := 5
const COST_PYRAMID_MAG := 4
const COST_PYRAMID_RELOAD := 5
const COST_STASIS_DMG := 6
const COST_SAWED_PELLETS := 5
const MAX_UPGRADE_TIER := 4

var mama_tokens: int = 0
var regular_kills: int = 0
var boss_spawned: bool = false
## Остановка времени (Shift+Z): враги и снаряды замирают, скорости сохраняются до снятия.
var world_time_frozen: bool = false
var up_pyramid_mag: int = 0
var up_pyramid_reload: int = 0
var up_stasis_dmg: int = 0
var up_sawed_pellets: int = 0


func on_regular_enemy_died(world_pos: Vector3) -> void:
	regular_kills += 1
	kills_changed.emit(regular_kills)
	_spawn_mama_pickup(world_pos)
	if regular_kills >= KILLS_FOR_BOSS and not boss_spawned:
		boss_spawned = true
		boss_spawn_requested.emit()


func spend_mama(cost: int) -> bool:
	if mama_tokens < cost:
		return false
	mama_tokens -= cost
	mama_changed.emit(mama_tokens)
	return true


func add_mama(amount: int) -> void:
	if amount <= 0:
		return
	mama_tokens += amount
	mama_changed.emit(mama_tokens)


func try_buy_pyramid_mag() -> bool:
	if up_pyramid_mag >= MAX_UPGRADE_TIER:
		return false
	if not spend_mama(COST_PYRAMID_MAG):
		return false
	up_pyramid_mag += 1
	upgrades_changed.emit()
	return true


func try_buy_pyramid_reload() -> bool:
	if up_pyramid_reload >= MAX_UPGRADE_TIER:
		return false
	if not spend_mama(COST_PYRAMID_RELOAD):
		return false
	up_pyramid_reload += 1
	upgrades_changed.emit()
	return true


func try_buy_stasis_damage() -> bool:
	if up_stasis_dmg >= MAX_UPGRADE_TIER:
		return false
	if not spend_mama(COST_STASIS_DMG):
		return false
	up_stasis_dmg += 1
	upgrades_changed.emit()
	return true


func try_buy_sawed_pellets() -> bool:
	if up_sawed_pellets >= MAX_UPGRADE_TIER:
		return false
	if not spend_mama(COST_SAWED_PELLETS):
		return false
	up_sawed_pellets += 1
	upgrades_changed.emit()
	return true


func _spawn_mama_pickup(world_pos: Vector3) -> void:
	spawn_mama_pickup_at(world_pos + Vector3(0.0, 0.55, 0.0))


func spawn_mama_pickup_at(global_pos: Vector3) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var psc := load("res://mama_pickup.tscn") as PackedScene
	if psc == null:
		return
	var p := psc.instantiate() as Node3D
	scene.add_child(p)
	p.global_position = global_pos


func spawn_boss_mama_drops(world_pos: Vector3) -> void:
	for i in BOSS_MAMA_PICKUP_COUNT:
		var ang := TAU * float(i) / float(BOSS_MAMA_PICKUP_COUNT)
		var r := 1.1 + randf() * 0.55
		spawn_mama_pickup_at(world_pos + Vector3(cos(ang) * r, 0.55, sin(ang) * r))
