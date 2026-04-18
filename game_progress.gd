extends Node

## Жетоны «МАМА» с подбираемых дропов; тратятся в магазине.
signal mama_changed(new_total: int)
signal kills_changed(total: int)
signal boss_spawn_requested
signal upgrades_changed
## Рост «охоты» после убийства жителя или ограбления дома в деревне.
signal village_outlaw_changed(strikes: int)

const KILLS_FOR_BOSS := 10
const BOSS_MAMA_PICKUP_COUNT := 5
## Выдача за удар «креативной палочкой» (режим креатива).
const CREATIVE_WAND_MAMA_GRANT := 9999
const COST_PYRAMID_MAG := 4
const COST_PYRAMID_RELOAD := 5
const COST_STASIS_DMG := 6
const COST_SAWED_PELLETS := 5
const COST_GRAPPLE_RANGE := 5
const COST_GRAPPLE_PULL := 6
const COST_GRAPPLE_DAMAGE := 6
const COST_ANIMATRON_RELOAD := 7
const COST_ANIMATRON_VORTEX := 6
const COST_ANIMATRON_BLAST := 7
const COST_KATANA_DMG := 5
const COST_KATANA_SPEED := 5
const COST_VAN_TURRETS := 10
const COST_VAN_REFUEL := 5
const COST_VAN_RESTORE := 20
const COST_DYNAMITE := 5
const MAX_UPGRADE_TIER := 4

var mama_tokens: int = 0
var regular_kills: int = 0
## Жители деревень, убитые игроком (для поручений короля).
var villager_kills: int = 0
## Последний порог убийств, на котором уже был запрошен босс (10, 20, 30…).
var last_boss_kills_milestone: int = 0
## Остановка времени (Shift+Z): враги и снаряды замирают, скорости сохраняются до снятия.
var world_time_frozen: bool = false
var up_pyramid_mag: int = 0
var up_pyramid_reload: int = 0
var up_stasis_dmg: int = 0
var up_sawed_pellets: int = 0
var up_grapple_range: int = 0
var up_grapple_pull: int = 0
var up_grapple_damage: int = 0
var up_animatron_reload: int = 0
var up_animatron_vortex: int = 0
var up_animatron_blast: int = 0
var up_katana_dmg: int = 0
var up_katana_speed: int = 0
## Одноразовая покупка: бомбомёт + скорострел на управляемом фургоне.
var van_turrets_installed: bool = false
## Фургон уничтожен (0 HP) — снова завести только за МАМА в лавке.
var van_destroyed: bool = false
## Купленный в лавке динамит (бросок клав. 6).
var dynamite_stock: int = 0
## Флаги головоломок (плиты, рычаги, ворота) — ключ → true.
var puzzle_flags: Dictionary = {}
## Накопленные проступки в деревне: убийство жителя +2, ограбление дома +1. Враги чаще и могут зайти в деревню.
var village_outlaw_strikes: int = 0


func register_village_murder() -> void:
	village_outlaw_strikes += 2
	village_outlaw_changed.emit(village_outlaw_strikes)


func register_village_robbery() -> void:
	village_outlaw_strikes += 1
	village_outlaw_changed.emit(village_outlaw_strikes)


func set_puzzle_flag(key: String, value: bool = true) -> void:
	puzzle_flags[key] = value
	upgrades_changed.emit()


func has_puzzle_flag(key: String) -> bool:
	return bool(puzzle_flags.get(key, false))


## Прямоугольник деревни NPC на плоскости XZ (враги не спавнятся и не заходят).
var npc_village_bounds_valid: bool = false
var npc_village_x_min: float = 0.0
var npc_village_x_max: float = -1.0
var npc_village_z_min: float = 0.0
var npc_village_z_max: float = -1.0


func register_npc_village_xz(x0: float, x1: float, z0: float, z1: float) -> void:
	npc_village_x_min = minf(x0, x1)
	npc_village_x_max = maxf(x0, x1)
	npc_village_z_min = minf(z0, z1)
	npc_village_z_max = maxf(z0, z1)
	npc_village_bounds_valid = true


## Расширить зону деревень (несколько посёлков на одной карте).
func expand_npc_village_xz(x0: float, x1: float, z0: float, z1: float) -> void:
	var nx0 := minf(x0, x1)
	var nx1 := maxf(x0, x1)
	var nz0 := minf(z0, z1)
	var nz1 := maxf(z0, z1)
	if not npc_village_bounds_valid:
		register_npc_village_xz(nx0, nx1, nz0, nz1)
		return
	npc_village_x_min = minf(npc_village_x_min, nx0)
	npc_village_x_max = maxf(npc_village_x_max, nx1)
	npc_village_z_min = minf(npc_village_z_min, nz0)
	npc_village_z_max = maxf(npc_village_z_max, nz1)


func is_pos_in_npc_village_xz(pos: Vector3) -> bool:
	if not npc_village_bounds_valid:
		return false
	return (
		pos.x >= npc_village_x_min
		and pos.x <= npc_village_x_max
		and pos.z >= npc_village_z_min
		and pos.z <= npc_village_z_max
	)


func push_pos_out_of_npc_village(pos: Vector3, margin: float = 0.45) -> Vector3:
	if not npc_village_bounds_valid or not is_pos_in_npc_village_xz(pos):
		return pos
	var dl := pos.x - npc_village_x_min
	var dr := npc_village_x_max - pos.x
	var db := pos.z - npc_village_z_min
	var df := npc_village_z_max - pos.z
	var m := minf(minf(dl, dr), minf(db, df))
	var out := pos
	if m == dl:
		out.x = npc_village_x_min - margin
	elif m == dr:
		out.x = npc_village_x_max + margin
	elif m == db:
		out.z = npc_village_z_min - margin
	else:
		out.z = npc_village_z_max + margin
	return out


func register_villager_kill_by_player() -> void:
	villager_kills += 1
	upgrades_changed.emit()


func on_regular_enemy_died(world_pos: Vector3) -> void:
	regular_kills += 1
	kills_changed.emit(regular_kills)
	_spawn_mama_pickup(world_pos)
	if regular_kills > 0 and regular_kills % KILLS_FOR_BOSS == 0:
		if regular_kills > last_boss_kills_milestone:
			last_boss_kills_milestone = regular_kills
			boss_spawn_requested.emit()


## Убийство креативной палочкой: счётчик и волны босса, без жетона на земле (МАМА выдаётся отдельно).
func register_enemy_kill_no_mama_pickup() -> void:
	regular_kills += 1
	kills_changed.emit(regular_kills)
	if regular_kills > 0 and regular_kills % KILLS_FOR_BOSS == 0:
		if regular_kills > last_boss_kills_milestone:
			last_boss_kills_milestone = regular_kills
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


func try_buy_grapple_range() -> bool:
	if up_grapple_range >= MAX_UPGRADE_TIER:
		return false
	if not spend_mama(COST_GRAPPLE_RANGE):
		return false
	up_grapple_range += 1
	upgrades_changed.emit()
	return true


func try_buy_grapple_pull() -> bool:
	if up_grapple_pull >= MAX_UPGRADE_TIER:
		return false
	if not spend_mama(COST_GRAPPLE_PULL):
		return false
	up_grapple_pull += 1
	upgrades_changed.emit()
	return true


func try_buy_grapple_damage() -> bool:
	if up_grapple_damage >= MAX_UPGRADE_TIER:
		return false
	if not spend_mama(COST_GRAPPLE_DAMAGE):
		return false
	up_grapple_damage += 1
	upgrades_changed.emit()
	return true


func try_buy_animatron_reload() -> bool:
	if up_animatron_reload >= MAX_UPGRADE_TIER:
		return false
	if not spend_mama(COST_ANIMATRON_RELOAD):
		return false
	up_animatron_reload += 1
	upgrades_changed.emit()
	return true


func try_buy_animatron_vortex() -> bool:
	if up_animatron_vortex >= MAX_UPGRADE_TIER:
		return false
	if not spend_mama(COST_ANIMATRON_VORTEX):
		return false
	up_animatron_vortex += 1
	upgrades_changed.emit()
	return true


func try_buy_animatron_blast() -> bool:
	if up_animatron_blast >= MAX_UPGRADE_TIER:
		return false
	if not spend_mama(COST_ANIMATRON_BLAST):
		return false
	up_animatron_blast += 1
	upgrades_changed.emit()
	return true


func try_buy_katana_damage() -> bool:
	if up_katana_dmg >= MAX_UPGRADE_TIER:
		return false
	if not spend_mama(COST_KATANA_DMG):
		return false
	up_katana_dmg += 1
	upgrades_changed.emit()
	return true


func try_buy_katana_speed() -> bool:
	if up_katana_speed >= MAX_UPGRADE_TIER:
		return false
	if not spend_mama(COST_KATANA_SPEED):
		return false
	up_katana_speed += 1
	upgrades_changed.emit()
	return true


func try_buy_van_turrets() -> bool:
	if van_turrets_installed:
		return false
	if not spend_mama(COST_VAN_TURRETS):
		return false
	van_turrets_installed = true
	upgrades_changed.emit()
	return true


func get_van_fuel_ratio_for_shop() -> float:
	if van_destroyed:
		return 1.0
	var tree := get_tree()
	if tree == null:
		return 1.0
	for n in tree.get_nodes_in_group("drivable_van"):
		if n.has_method("get_fuel_ratio"):
			return float(n.call("get_fuel_ratio"))
	return 1.0


func try_buy_van_refuel() -> bool:
	if van_destroyed:
		return false
	var tree := get_tree()
	if tree == null:
		return false
	var vans := tree.get_nodes_in_group("drivable_van")
	if vans.is_empty():
		return false
	var needs := false
	for n in vans:
		if n.has_method("get_fuel_ratio") and float(n.call("get_fuel_ratio")) < 0.999:
			needs = true
			break
	if not needs:
		return false
	if not spend_mama(COST_VAN_REFUEL):
		return false
	for n in vans:
		if n.has_method("refuel_full"):
			n.call("refuel_full")
	upgrades_changed.emit()
	return true


func try_buy_van_restore() -> bool:
	if not van_destroyed:
		return false
	if not spend_mama(COST_VAN_RESTORE):
		return false
	van_destroyed = false
	var tree := get_tree()
	if tree != null:
		for n in tree.get_nodes_in_group("drivable_van"):
			if n.has_method("restore_van_after_purchase"):
				n.call("restore_van_after_purchase")
	upgrades_changed.emit()
	return true


func try_buy_dynamite() -> bool:
	if not spend_mama(COST_DYNAMITE):
		return false
	dynamite_stock += 1
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


func reset_for_new_game() -> void:
	mama_tokens = 0
	regular_kills = 0
	villager_kills = 0
	last_boss_kills_milestone = 0
	world_time_frozen = false
	up_pyramid_mag = 0
	up_pyramid_reload = 0
	up_stasis_dmg = 0
	up_sawed_pellets = 0
	up_grapple_range = 0
	up_grapple_pull = 0
	up_grapple_damage = 0
	up_animatron_reload = 0
	up_animatron_vortex = 0
	up_animatron_blast = 0
	up_katana_dmg = 0
	up_katana_speed = 0
	van_turrets_installed = false
	van_destroyed = false
	dynamite_stock = 0
	puzzle_flags.clear()
	village_outlaw_strikes = 0
	npc_village_bounds_valid = false
	npc_village_x_min = 0.0
	npc_village_x_max = -1.0
	npc_village_z_min = 0.0
	npc_village_z_max = -1.0
	mama_changed.emit(mama_tokens)
	kills_changed.emit(regular_kills)
	upgrades_changed.emit()


func get_persistent_state() -> Dictionary:
	return {
		"mama_tokens": mama_tokens,
		"regular_kills": regular_kills,
		"villager_kills": villager_kills,
		"last_boss_kills_milestone": last_boss_kills_milestone,
		"world_time_frozen": world_time_frozen,
		"up_pyramid_mag": up_pyramid_mag,
		"up_pyramid_reload": up_pyramid_reload,
		"up_stasis_dmg": up_stasis_dmg,
		"up_sawed_pellets": up_sawed_pellets,
		"up_grapple_range": up_grapple_range,
		"up_grapple_pull": up_grapple_pull,
		"up_grapple_damage": up_grapple_damage,
		"up_animatron_reload": up_animatron_reload,
		"up_animatron_vortex": up_animatron_vortex,
		"up_animatron_blast": up_animatron_blast,
		"up_katana_dmg": up_katana_dmg,
		"up_katana_speed": up_katana_speed,
		"van_turrets_installed": van_turrets_installed,
		"van_destroyed": van_destroyed,
		"dynamite_stock": dynamite_stock,
		"puzzle_flags": puzzle_flags.duplicate(true),
		"village_outlaw_strikes": village_outlaw_strikes,
	}


func apply_persistent_state(d: Dictionary) -> void:
	if d.is_empty():
		return
	mama_tokens = int(d.get("mama_tokens", 0))
	regular_kills = int(d.get("regular_kills", 0))
	villager_kills = int(d.get("villager_kills", 0))
	last_boss_kills_milestone = int(d.get("last_boss_kills_milestone", 0))
	world_time_frozen = bool(d.get("world_time_frozen", false))
	up_pyramid_mag = int(d.get("up_pyramid_mag", 0))
	up_pyramid_reload = int(d.get("up_pyramid_reload", 0))
	up_stasis_dmg = int(d.get("up_stasis_dmg", 0))
	up_sawed_pellets = int(d.get("up_sawed_pellets", 0))
	up_grapple_range = int(d.get("up_grapple_range", 0))
	up_grapple_pull = int(d.get("up_grapple_pull", 0))
	up_grapple_damage = int(d.get("up_grapple_damage", 0))
	up_animatron_reload = int(d.get("up_animatron_reload", 0))
	up_animatron_vortex = int(d.get("up_animatron_vortex", 0))
	up_animatron_blast = int(d.get("up_animatron_blast", 0))
	up_katana_dmg = int(d.get("up_katana_dmg", 0))
	up_katana_speed = int(d.get("up_katana_speed", 0))
	van_turrets_installed = bool(d.get("van_turrets_installed", false))
	van_destroyed = bool(d.get("van_destroyed", false))
	dynamite_stock = int(d.get("dynamite_stock", 0))
	var pf = d.get("puzzle_flags", {})
	puzzle_flags.clear()
	if typeof(pf) == TYPE_DICTIONARY:
		for k in pf:
			puzzle_flags[str(k)] = bool(pf[k])
	village_outlaw_strikes = int(d.get("village_outlaw_strikes", 0))
	mama_changed.emit(mama_tokens)
	kills_changed.emit(regular_kills)
	upgrades_changed.emit()


## При смерти в режиме выживания: выложить жетоны МАМА у тела (как «монеты»).
func scatter_mama_pickups_at(world_pos: Vector3, total: int) -> void:
	if total <= 0:
		return
	var maxp := 50
	var n: int = mini(total, maxp)
	n = maxi(n, 1)
	var base: int = total / n
	var rem: int = total % n
	for i in range(n):
		var v: int = base + (1 if i < rem else 0)
		if v < 1:
			continue
		var ang: float = TAU * float(i) / float(n) + randf() * 0.25
		var r: float = 0.35 + randf() * 1.1
		var ppos: Vector3 = world_pos + Vector3(cos(ang) * r, 0.55, sin(ang) * r)
		spawn_mama_pickup_at_value(ppos, v)


func spawn_mama_pickup_at_value(global_pos: Vector3, value: int) -> void:
	if value < 1:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var psc := load("res://mama_pickup.tscn") as PackedScene
	if psc == null:
		return
	var p := psc.instantiate() as Node3D
	if p == null:
		return
	p.set("mama_value", value)
	scene.add_child(p)
	p.global_position = global_pos
