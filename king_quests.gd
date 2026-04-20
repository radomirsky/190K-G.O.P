extends Node
## Поручения короля: враги, жители, головоломки у замка. Продолжение сюжета — позже.

const KING_CORPSE_SCENE := preload("res://king_corpse.tscn")
const BIG_KING_SCENE := preload("res://big_king_boss.tscn")

const KILL_ENEMIES_NEED: int = 6
const KILL_ENEMIES_REWARD: int = 10
const KILL_VILLAGERS_NEED: int = 3
const KILL_VILLAGERS_REWARD: int = 14
const PUZZLE_REWARD: int = 12

var _stage: int = 0
var _k0: int = 0
var _v0: int = 0
## Король убит катаной — на троне пусто, труп можно нести и выкинуть за карту.
var king_slain: bool = false
## Труп улетел за пределы мира — призван Большой Король.
var secret_big_king_spawned: bool = false
## Секретный финал пройден — титры показаны.
var secret_big_king_defeated: bool = false


func _player_banner(player: Node, msg: String) -> void:
	if player != null and is_instance_valid(player) and player.has_method("notify_quest_banner"):
		player.call("notify_quest_banner", msg)


func on_king_interact(player: Node) -> void:
	if king_slain:
		return
	match _stage:
		0:
			_player_banner(
				player,
				"Я король этого края. Докажи силу: убей ещё %d врагов с этого момента. Потом снова E."
				% KILL_ENEMIES_NEED
			)
			_stage = 1
			_k0 = GameProgress.regular_kills
		1:
			if GameProgress.regular_kills - _k0 < KILL_ENEMIES_NEED:
				var left := KILL_ENEMIES_NEED - (GameProgress.regular_kills - _k0)
				_player_banner(player, "Осталось врагов: %d" % maxi(0, left))
				return
			GameProgress.add_mama(KILL_ENEMIES_REWARD)
			_player_banner(
				player,
				"Достойно. Награда +%d МАМА. Теперь истреби %d жителей деревень — любых. Потом E."
				% [KILL_ENEMIES_REWARD, KILL_VILLAGERS_NEED]
			)
			_stage = 2
			_v0 = GameProgress.villager_kills
		2:
			if GameProgress.villager_kills - _v0 < KILL_VILLAGERS_NEED:
				var lv := KILL_VILLAGERS_NEED - (GameProgress.villager_kills - _v0)
				_player_banner(player, "Осталось жителей: %d" % maxi(0, lv))
				return
			GameProgress.add_mama(KILL_VILLAGERS_REWARD)
			_player_banner(
				player,
				"Жестоко, но приказ выполнен. +%d МАМА. Реши три загадки у замка — рычаги алтаря, бастиона и сада. Потом E."
				% KILL_VILLAGERS_REWARD
			)
			_stage = 3
		3:
			if not (
				GameProgress.has_puzzle_flag("king_puzzle_altar")
				and GameProgress.has_puzzle_flag("king_puzzle_bastion")
				and GameProgress.has_puzzle_flag("king_puzzle_garden")
			):
				_player_banner(player, "Рычаги ещё не все. Обойди двор замка.")
				return
			GameProgress.add_mama(PUZZLE_REWARD)
			_player_banner(
				player,
				"Королевство довольно тобой. +%d МАМА. Продолжение следует…" % PUZZLE_REWARD
			)
			_stage = 4
		_:
			_player_banner(player, "Свободен. Продолжение следует…")


func get_map_bbcode() -> String:
	var t := ""
	t += "  [b]Путь:[/b] [i]западный проход[/i] в стене двора → [i]донжон[/i] с юга зала → проход между башнями → [i]трон[/i] (E — задания).\n"
	if king_slain and not secret_big_king_defeated:
		if not secret_big_king_spawned:
			t += "  [color=#ee8866]Секрет:[/color] труп короля подбери (E) и выбрось за край карты — призовётся Большой Король.\n"
		else:
			t += "  [color=#ffcc66]Секрет:[/color] Большой Король уже в мире — победи его, чтобы увидеть титры.\n"
		return t
	if secret_big_king_defeated:
		t += "  [color=#90ee90]Секретный финал[/color] пройден.\n"
		return t
	match _stage:
		0:
			t += "  [color=#ffcc66]Король:[/color] поговори на троне (E), чтобы начать цепочку поручений.\n"
		1:
			var le := KILL_ENEMIES_NEED - (GameProgress.regular_kills - _k0)
			t += "  [color=#ffcc66]Король:[/color] убей врагов с момента принятия, осталось: %d\n" % maxi(0, le)
		2:
			var lv := KILL_VILLAGERS_NEED - (GameProgress.villager_kills - _v0)
			t += "  [color=#ffcc66]Король:[/color] убей жителей деревень, осталось: %d\n" % maxi(0, lv)
		3:
			var ok := (
				GameProgress.has_puzzle_flag("king_puzzle_altar")
				and GameProgress.has_puzzle_flag("king_puzzle_bastion")
				and GameProgress.has_puzzle_flag("king_puzzle_garden")
			)
			if ok:
				t += "  [color=#90ee90]Король:[/color] все рычаги нажаты — снова E у короля за наградой.\n"
			else:
				t += "  [color=#ffcc66]Король:[/color] три рычага во дворе: алтарь, бастион, сад.\n"
		_:
			t += "  [color=#888]Король:[/color] поручения выполнены.\n"
	return t


func on_king_attacked() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("castle_guard"):
		if n.has_method("activate_aggro"):
			n.call("activate_aggro")


func on_king_slain_spawn_corpse(world_pos: Vector3, parent_node: Node) -> void:
	if king_slain:
		return
	king_slain = true
	if parent_node == null or not is_instance_valid(parent_node):
		return
	var c := KING_CORPSE_SCENE.instantiate() as RigidBody3D
	if c == null:
		return
	parent_node.add_child(c)
	c.global_position = world_pos + Vector3(0.0, 0.35, 0.0)


func request_secret_boss_from_corpse_fall() -> void:
	if not king_slain or secret_big_king_spawned or secret_big_king_defeated:
		return
	if GameSave.is_peaceful():
		var pl0 := get_tree().get_first_node_in_group("player")
		_player_banner(pl0, "Мирный режим: Большой Король не приходит.")
		return
	secret_big_king_spawned = true
	call_deferred("_spawn_secret_big_king_near_player")


func restore_secret_big_king_if_save_pending() -> void:
	if GameSave.is_peaceful():
		return
	if not king_slain or not secret_big_king_spawned or secret_big_king_defeated:
		return
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("secret_big_king"):
		if is_instance_valid(n):
			return
	_spawn_secret_big_king_near_player()


func _spawn_secret_big_king_near_player() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var scene := tree.current_scene
	var pl := tree.get_first_node_in_group("player") as Node3D
	if scene == null or pl == null:
		return
	var boss := BIG_KING_SCENE.instantiate() as CharacterBody3D
	if boss == null:
		return
	scene.add_child(boss)
	if boss.has_method("set"):
		boss.set("player_path", boss.get_path_to(pl))
	var want := pl.global_position + Vector3(11.0, 0.0, 7.0)
	var base := _snap_character_to_floor(want)
	boss.global_position = base + Vector3(0.0, 1.05, 0.0)
	_player_banner(
		pl,
		"СЕКРЕТ: Большой Король! Плоский квадрат с сегодняшней датой. 26 ударов катаной."
	)


func _snap_character_to_floor(want_pos: Vector3) -> Vector3:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return want_pos
	var w := tree.current_scene.get_world_3d()
	if w == null:
		return want_pos
	var space := w.direct_space_state
	var from := want_pos + Vector3.UP * 12.0
	var to := want_pos + Vector3.DOWN * 55.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.hit_from_inside = true
	var hit := space.intersect_ray(q)
	if hit.is_empty() or not hit.has("position"):
		return want_pos
	var p := hit["position"] as Vector3
	return p + Vector3.UP * 0.06


func on_secret_big_king_defeated() -> void:
	if secret_big_king_defeated:
		return
	secret_big_king_defeated = true
	var pl := get_tree().get_first_node_in_group("player")
	if pl != null and is_instance_valid(pl) and pl.has_method("start_secret_ending_credits"):
		pl.call_deferred("start_secret_ending_credits")
	if pl is Node3D:
		GameSave.autosave_if_playing(pl as Node3D)


func reset_for_new_game() -> void:
	_stage = 0
	_k0 = 0
	_v0 = 0
	king_slain = false
	secret_big_king_spawned = false
	secret_big_king_defeated = false


func get_persistent_state() -> Dictionary:
	return {
		"stage": _stage,
		"k0": _k0,
		"v0": _v0,
		"king_slain": king_slain,
		"secret_big_king_spawned": secret_big_king_spawned,
		"secret_big_king_defeated": secret_big_king_defeated,
	}


func apply_persistent_state(d: Dictionary) -> void:
	if d.is_empty():
		return
	_stage = int(d.get("stage", 0))
	_k0 = int(d.get("k0", 0))
	_v0 = int(d.get("v0", 0))
	king_slain = bool(d.get("king_slain", false))
	secret_big_king_spawned = bool(d.get("secret_big_king_spawned", false))
	secret_big_king_defeated = bool(d.get("secret_big_king_defeated", false))
