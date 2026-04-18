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
## Жители 3–10: побочные поручения.
var _side_accepted: Dictionary = {}
var _side_kills0: Dictionary = {}
var _side_mama0: Dictionary = {}
var _side_done: Dictionary = {}


func _player_banner(player: Node, msg: String) -> void:
	if player != null and is_instance_valid(player) and player.has_method("notify_quest_banner"):
		player.call("notify_quest_banner", msg)


func on_npc_interact(idx: int, player: Node) -> void:
	if final_boss_spawned:
		_player_banner(player, "Главная угроза уже отбита. Отдыхай.")
		return
	if idx < 0 or idx > 2:
		return
	if idx == 0 and not _completed[0] and not GameProgress.has_puzzle_flag("village_entry_unlocked"):
		_player_banner(player, "Сначала наступи на плиту у ворот (смотри карту — клав. M).")
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
		GameProgress.upgrades_changed.emit()
		return

	if not _is_quest_progress_ok(idx):
		_player_banner(player, _progress_hint(idx))
		return

	GameProgress.add_mama(REWARD_MAMA[idx])
	_completed[idx] = true
	_player_banner(player, "Сделано! Награда: +%d МАМА." % REWARD_MAMA[idx])

	if _completed[0] and _completed[1] and _completed[2]:
		call_deferred("_spawn_final_boss_deferred")


const SIDE_KILLS_NEED: int = 2
const SIDE_MAMA_NEED: int = 2
const SIDE_KILL_REWARD_MAMA: int = 4
const SIDE_MAMA_REWARD_MAMA: int = 5


func on_side_npc_interact(idx: int, player: Node) -> void:
	if final_boss_spawned:
		_player_banner(player, "Главная угроза уже отбита. Отдыхай.")
		return
	if idx < 3:
		return
	if bool(_side_done.get(idx, false)):
		_player_banner(player, "Спасибо, ты нас выручил!")
		return
	if not bool(_side_accepted.get(idx, false)):
		_side_accepted[idx] = true
		if (idx % 2) == 1:
			_side_kills0[idx] = GameProgress.regular_kills
			_player_banner(
				player,
				"Поручение: убей ещё %d врагов (с этого момента). Потом снова E." % SIDE_KILLS_NEED
			)
		else:
			_side_mama0[idx] = GameProgress.mama_tokens
			_player_banner(
				player,
				"Поручение: собери ещё %d МАМА (с этого момента). Потом снова E." % SIDE_MAMA_NEED
			)
		GameProgress.upgrades_changed.emit()
		return
	if (idx % 2) == 1:
		var k0: int = int(_side_kills0.get(idx, 0))
		var got_k: int = GameProgress.regular_kills - k0
		if got_k < SIDE_KILLS_NEED:
			_player_banner(player, "Осталось убить врагов: %d" % (SIDE_KILLS_NEED - got_k))
			return
		GameProgress.add_mama(SIDE_KILL_REWARD_MAMA)
		_side_done[idx] = true
		_player_banner(player, "Сделано! Награда: +%d МАМА." % SIDE_KILL_REWARD_MAMA)
	else:
		var m0: int = int(_side_mama0.get(idx, 0))
		var got_m: int = GameProgress.mama_tokens - m0
		if got_m < SIDE_MAMA_NEED:
			_player_banner(player, "Осталось МАМА: %d" % (SIDE_MAMA_NEED - got_m))
			return
		GameProgress.add_mama(SIDE_MAMA_REWARD_MAMA)
		_side_done[idx] = true
		_player_banner(player, "Сделано! Награда: +%d МАМА." % SIDE_MAMA_REWARD_MAMA)
	GameProgress.upgrades_changed.emit()


## Если житель в этом радиусе от двери или от игрока — ограбление считается «на глазах», все жители с катанами.
const ROBBERY_WITNESS_RADIUS_FOR_MOB: float = 20.0


func robbery_triggers_villager_mob(door_node: Node3D, player: Node, door_village_id: int = 0) -> bool:
	var tree := door_node.get_tree()
	if tree == null:
		return false
	var pts: Array[Vector3] = [door_node.global_position]
	if player is Node3D:
		pts.append((player as Node3D).global_position)
	var lim2 := ROBBERY_WITNESS_RADIUS_FOR_MOB * ROBBERY_WITNESS_RADIUS_FOR_MOB
	for n in tree.get_nodes_in_group("talkable_npc"):
		if not n is Node3D:
			continue
		if int(n.get("village_id")) != door_village_id:
			continue
		var pg: Vector3 = (n as Node3D).global_position
		for pt in pts:
			if pg.distance_squared_to(pt) <= lim2:
				return true
	return false


func alert_all_villagers_katana_mob(only_village_id: int = -1) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("quest_npc"):
		if only_village_id >= 0 and int(n.get("village_id")) != only_village_id:
			continue
		if n.has_method("activate_katana_mob"):
			n.call("activate_katana_mob")


func on_village_npc_killed(idx: int, village_id: int = 0) -> void:
	GameProgress.register_village_murder()
	GameProgress.register_villager_kill_by_player()
	alert_all_villagers_katana_mob(village_id)
	if idx >= 3:
		_side_accepted.erase(idx)
		_side_kills0.erase(idx)
		_side_mama0.erase(idx)
		_side_done.erase(idx)
	GameProgress.upgrades_changed.emit()


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


func get_world_map_bbcode() -> String:
	var t := ""
	t += "[font_size=22][b]КАРТА И ЗАДАНИЯ[/b][/font_size]\n"
	t += "[i]Пауза мира и защита от урона. M / Esc — закрыть. P — скрыть/показать этот список. [b]Колёсико мыши[/b] — приблизить/отдалить [b]вид сверху[/b]. Tab или лавка в деревне — магазин.[/i]\n\n"
	t += "[b]Кто есть кто (капсулы, E)[/b]\n"
	t += "• [color=#5a8fe8]Житель 0[/color] — северо-западнее лавки — [b]главный[/b] квест: враги (нужна плита у ворот).\n"
	t += "• [color=#5a8fe8]Житель 1[/color] — восток — главный: внешние ворота.\n"
	t += "• [color=#5a8fe8]Житель 2[/color] — север площади — главный: МАМА.\n"
	t += "• [color=#8fbc8f]Жители 3+[/color] — побочные поручения в каждой деревне (2 убийства или 2 МАМА с момента согласия).\n"
	t += "• [color=#ffd700]Король[/color] у [b]замка[/b] на востоке — поручения: враги, жители, головоломки у стен.\n"
	t += "• [color=#ff8888]Катана[/color] по королю — [b]стража[/b] нападает. Страж и король режутся катаной.\n"
	t += "• [color=#ff8888]Катана[/color] режет жителей; [b]убийство жителя[/b] — моб только в [b]его[/b] деревне. [b]Ограбление на глазах[/b] — то же.\n"
	t += "• [color=#daa520]Дома[/color] — E [b]ограбить[/b]; у каждой деревни свои [b]внешние[/b] и [b]внутренние[/b] рычаги ворот.\n"
	if GameProgress.village_outlaw_strikes > 0:
		t += "  [color=#ff6666]Розыск в деревне: %d (чем выше — тем злее спавн).[/color]\n" % GameProgress.village_outlaw_strikes
	t += "• Ты — игрок; фургон у [b]юга[/b] особняка.\n\n"
	t += "[b]Что за места[/b]\n"
	t += "• [color=#deb887]Особняк[/color] — деревянный пол у центра арены, въезд с юга; стены двора — тёмная трава вокруг.\n"
	t += "• [color=#8fbc8f]Три деревни[/color] — у каждой своя плита и рычаг у внешних ворот; второй рычаг [b]закрывает/открывает наружу[/b] после головоломки; третий — [b]внутренний[/b] проход.\n"
	t += "• [color=#dda0dd]Лавка[/color] — только у [b]деревни I[/b] (центр площади); Tab — везде.\n"
	t += "• [color=#e6c35c]Замок[/color] — восточнее арены; три рычага загадок для короля + бонусные рычаги у дозора, руин и капища.\n"
	t += "• [color=#aaa]Дороги[/color] — серые плиты на карте ведут к деревням и к замку.\n\n"
	t += "[b]Плита для первого жителя[/b]\n"
	if GameProgress.has_puzzle_flag("village_entry_unlocked"):
		t += "  [color=#90ee90]✓ Готово — можно говорить с жителем №1 (синий, задание «враги»).[/color]\n\n"
	else:
		t += (
			"  [color=#ffcc66]![/color] Подойди к [b]зелёной плите[/b] у подъезда к деревне (надпись «ПЛИТА») и [b]наступи[/b] на неё.\n\n"
		)
	t += "[b]Внешние ворота (головоломка)[/b]\n"
	t += "  1) Та же плита активирует механизм.\n"
	if GameProgress.has_puzzle_flag("suburbs_plate"):
		t += "     [color=#90ee90]✓ Плита нажата[/color]\n"
	else:
		t += "     Плита ещё не нажата.\n"
	t += "  2) [b]Рычаг[/b] — нажми E, глядя на рычаг у дороги.\n"
	if GameProgress.has_puzzle_flag("suburbs_lever"):
		t += "     [color=#90ee90]✓ Рычаг[/color]\n"
	else:
		t += "     Рычаг ещё не переключён.\n"
	t += "  Когда оба пункта готовы — [b]внешние ворота[/b] можно открыть; рычаг у проёма снова их [b]закрывает[/b].\n\n"
	t += "[b]Главные жители (E)[/b]\n"
	var qn := ["Житель 0 — враги", "Житель 1 — ворота", "Житель 2 — МАМА"]
	for i in range(3):
		if _completed[i]:
			t += "  [color=#888]%s — выполнено[/color]\n" % qn[i]
		elif _accepted[i]:
			t += "  [color=#ffcc66]%s — в процессе[/color]\n" % qn[i]
		else:
			t += "  %s\n" % qn[i]
	t += "[b]Побочные жители (деревни I–III)[/b]\n"
	for j in range(3, 27):
		if bool(_side_done.get(j, false)):
			t += "  [color=#888]Житель %d — сделано[/color]\n" % j
		elif bool(_side_accepted.get(j, false)):
			t += "  [color=#ffcc66]Житель %d — в процессе[/color]\n" % j
		else:
			t += "  Житель %d — поговори (E)\n" % j
	if final_boss_spawned:
		t += "\n[color=#ff8888]Финальный босс уже в мире.[/color]\n"
	return t
