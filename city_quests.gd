extends Node
## Квесты жителей города: три задания на убийства, награда МАМА, затем босс «Божья отвёртка».

const KILLS_NEED: Array[int] = [3, 3, 4]
const REWARD_MAMA: Array[int] = [5, 7, 9]

var _accepted: Array[bool] = [false, false, false]
var _completed: Array[bool] = [false, false, false]
var _kills_at_accept: Array[int] = [-1, -1, -1]
var _active_idx: int = -1
var screwdriver_spawned: bool = false


func _player_banner(player: Node, msg: String) -> void:
	if player != null and is_instance_valid(player) and player.has_method("notify_quest_banner"):
		player.call("notify_quest_banner", msg)


func on_npc_interact(idx: int, player: Node) -> void:
	if screwdriver_spawned:
		_player_banner(player, "Божья отвёртка уже была. Отдыхай.")
		return
	if idx < 0 or idx > 2:
		return
	if idx > 0 and not _completed[idx - 1]:
		_player_banner(player, "Сначала помоги соседу слева (дом %d)." % idx)
		return
	if _completed[idx]:
		_player_banner(player, "Спасибо, ты нас выручил!")
		return
	if not _accepted[idx]:
		_accepted[idx] = true
		_active_idx = idx
		_kills_at_accept[idx] = GameProgress.regular_kills
		_player_banner(
			player,
			"Задание: убей ещё %d врагов (с этого момента). Потом снова E." % KILLS_NEED[idx]
		)
		return

	if _active_idx != idx:
		_active_idx = idx

	var need := KILLS_NEED[idx]
	var got := GameProgress.regular_kills - _kills_at_accept[idx]
	if got < need:
		_player_banner(player, "Осталось убить врагов: %d" % (need - got))
		return

	GameProgress.add_mama(REWARD_MAMA[idx])
	_completed[idx] = true
	_active_idx = -1
	_player_banner(player, "Сделано! Награда: +%d МАМА." % REWARD_MAMA[idx])

	if _completed[0] and _completed[1] and _completed[2]:
		call_deferred("_spawn_screwdriver_deferred")


func _spawn_screwdriver_deferred() -> void:
	if screwdriver_spawned:
		return
	var tree := get_tree()
	if tree == null:
		return
	var scene := tree.current_scene
	if scene == null:
		return
	var pl := tree.get_first_node_in_group("player") as Node3D
	if pl == null:
		return
	var boss_ps := load("res://god_screwdriver_boss.tscn") as PackedScene
	if boss_ps == null:
		return
	var boss := boss_ps.instantiate() as CharacterBody3D
	if boss == null:
		return
	scene.add_child(boss)
	var spawn := pl.global_position + Vector3(6.0, 9.5, -4.0)
	spawn.y = maxf(spawn.y, 7.0)
	boss.global_position = spawn
	if boss.has_method("set"):
		boss.set("player_path", boss.get_path_to(pl))
	screwdriver_spawned = true
	_player_banner(pl, "БОЖЬЯ ОТВЁРТКА! 20 ударов — и бомбы с неба!")
