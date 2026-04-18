extends Node
## Поручения короля: враги, жители, головоломки у замка. Продолжение сюжета — позже.

const KILL_ENEMIES_NEED: int = 6
const KILL_ENEMIES_REWARD: int = 10
const KILL_VILLAGERS_NEED: int = 3
const KILL_VILLAGERS_REWARD: int = 14
const PUZZLE_REWARD: int = 12

var _stage: int = 0
var _k0: int = 0
var _v0: int = 0


func _player_banner(player: Node, msg: String) -> void:
	if player != null and is_instance_valid(player) and player.has_method("notify_quest_banner"):
		player.call("notify_quest_banner", msg)


func on_king_interact(player: Node) -> void:
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
