extends Node
## Квесты жителей: разные типы (убийства, головоломка, МАМА), затем финальный босс.
## Финальный босс сейчас — «Божья отвёртка». Босс-вертолёт: отдельная сцена, подключить позже (заменить god_screwdriver_boss.tscn в _spawn_final_boss_deferred).

const QUEST_TYPE_KILL: int = 0
const QUEST_TYPE_PUZZLE: int = 1
const QUEST_TYPE_MAMA: int = 2

const QUEST_TYPES: Array[int] = [QUEST_TYPE_KILL, QUEST_TYPE_PUZZLE, QUEST_TYPE_MAMA]
const KILLS_NEED: Array[int] = [4, 0, 0]
const MAMA_NEED: Array[int] = [0, 0, 8]
const REWARD_MAMA: Array[int] = [5, 7, 10]

var _accepted: Array[bool] = [false, false, false]
var _completed: Array[bool] = [false, false, false]
var _kills_at_accept: Array[int] = [-1, -1, -1]
var _mama_at_accept: Array[int] = [-1, -1, -1]
var final_boss_spawned: bool = false


func _player_banner(player: Node, msg: String) -> void:
	if player != null and is_instance_valid(player) and player.has_method("notify_quest_banner"):
		player.call("notify_quest_banner", msg)


func on_npc_interact(idx: int, player: Node) -> void:
	if final_boss_spawned:
		_player_banner(player, "Главная угроза уже отбита. Отдыхай.")
		return
	if idx < 0 or idx > 2:
		return
	if _completed[idx]:
		_player_banner(player, "Спасибо, ты нас выручил!")
		return

	if not _accepted[idx]:
		_accepted[idx] = true
		match QUEST_TYPES[idx]:
			QUEST_TYPE_KILL:
				_kills_at_accept[idx] = GameProgress.regular_kills
				_player_banner(
					player,
					"Задание: убей ещё %d врагов (с этого момента). Потом снова E." % KILLS_NEED[idx]
				)
			QUEST_TYPE_PUZZLE:
				_player_banner(
					player,
					"Задание: открой ворота в район. Наступи на зелёную плиту у ворот, затем нажми E на рычаге. Вернись сюда."
				)
			QUEST_TYPE_MAMA:
				_mama_at_accept[idx] = GameProgress.mama_tokens
				_player_banner(
					player,
					"Задание: собери ещё %d жетонов МАМА (с дропа врагов). Потом снова E." % MAMA_NEED[idx]
				)
		return

	if not _is_quest_progress_ok(idx):
		_player_banner(player, _progress_hint(idx))
		return

	GameProgress.add_mama(REWARD_MAMA[idx])
	_completed[idx] = true
	_player_banner(player, "Сделано! Награда: +%d МАМА." % REWARD_MAMA[idx])

	if _completed[0] and _completed[1] and _completed[2]:
		call_deferred("_spawn_final_boss_deferred")


func _is_quest_progress_ok(idx: int) -> bool:
	match QUEST_TYPES[idx]:
		QUEST_TYPE_KILL:
			return GameProgress.regular_kills - _kills_at_accept[idx] >= KILLS_NEED[idx]
		QUEST_TYPE_PUZZLE:
			return GameProgress.has_puzzle_flag("suburbs_plate") and GameProgress.has_puzzle_flag(
				"suburbs_lever"
			)
		QUEST_TYPE_MAMA:
			return GameProgress.mama_tokens - _mama_at_accept[idx] >= MAMA_NEED[idx]
	return false


func _progress_hint(idx: int) -> String:
	match QUEST_TYPES[idx]:
		QUEST_TYPE_KILL:
			var need := KILLS_NEED[idx]
			var got := GameProgress.regular_kills - _kills_at_accept[idx]
			return "Осталось убить врагов: %d" % maxi(0, need - got)
		QUEST_TYPE_PUZZLE:
			if not GameProgress.has_puzzle_flag("suburbs_plate"):
				return "Сначала наступи на плиту у деревянных ворот."
			if not GameProgress.has_puzzle_flag("suburbs_lever"):
				return "Теперь нажми E на рычаге у дороги."
			return "Всё готово — поговори ещё раз."
		QUEST_TYPE_MAMA:
			var need2 := MAMA_NEED[idx]
			var got2 := GameProgress.mama_tokens - _mama_at_accept[idx]
			return "Осталось МАМА: %d" % maxi(0, need2 - got2)
	return ""


func _spawn_final_boss_deferred() -> void:
	if final_boss_spawned:
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
	# TODO: заменить на сцену вертолёта-ботса, когда будет готова (аналогично: парение + сброс бомб).
	var boss_ps := load("res://god_screwdriver_boss.tscn") as PackedScene
	if boss_ps == null:
		return
	var boss := boss_ps.instantiate() as CharacterBody3D
	if boss == null:
		return
	scene.add_child(boss)
	var spawn := pl.global_position + Vector3(5.0, 10.0, -6.0)
	spawn.y = maxf(spawn.y, 7.0)
	boss.global_position = spawn
	if boss.has_method("set"):
		boss.set("player_path", boss.get_path_to(pl))
	final_boss_spawned = true
	_player_banner(pl, "ФИНАЛ: Божья отвёртка! 20 ударов, бомбы с неба. (Вертолёт — в разработке.)")
