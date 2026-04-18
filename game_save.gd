extends Node

## До 4 независимых миров (файлы user://world_1.save … world_4.save).
## Старый user://profile.save при первом запуске переносится в слот 1.

const SAVE_VERSION := 1
const MAIN_SCENE := "res://main.tscn"
const MAX_WORLDS := 4
const LEGACY_SAVE_PATH := "user://profile.save"

enum Mode { NONE, HARDCORE, SURVIVAL, CREATIVE, PEACEFUL }

## Активный слот 1..MAX_WORLDS во время игры и автосохранения.
var current_slot: int = 1
var current_mode: Mode = Mode.NONE
var _pending_player: Dictionary = {}


func is_creative() -> bool:
	return current_mode == Mode.CREATIVE


func is_peaceful() -> bool:
	return current_mode == Mode.PEACEFUL


func _ready() -> void:
	_migrate_legacy_profile_if_needed()


func slot_path(slot: int) -> String:
	return "user://world_%d.save" % clampi(slot, 1, MAX_WORLDS)


func _migrate_legacy_profile_if_needed() -> void:
	var ddir := DirAccess.open("user://")
	# Слот 1 уже занят — дубликат profile.save удаляем.
	if FileAccess.file_exists(LEGACY_SAVE_PATH) and FileAccess.file_exists(slot_path(1)):
		if ddir and ddir.file_exists("profile.save"):
			ddir.remove("profile.save")
		return
	if not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return
	if FileAccess.file_exists(slot_path(1)):
		return
	var f_old := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
	if f_old == null:
		return
	var txt := f_old.get_as_text()
	f_old.close()
	var f_new := FileAccess.open(slot_path(1), FileAccess.WRITE)
	if f_new == null:
		return
	f_new.store_string(txt)
	f_new.close()
	if ddir and ddir.file_exists("profile.save"):
		ddir.remove("profile.save")


func has_any_saved_world() -> bool:
	for i in range(1, MAX_WORLDS + 1):
		if FileAccess.file_exists(slot_path(i)):
			return true
	return false


func is_slot_occupied(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(clampi(slot, 1, MAX_WORLDS)))


func get_first_free_slot() -> int:
	for i in range(1, MAX_WORLDS + 1):
		if not FileAccess.file_exists(slot_path(i)):
			return i
	return 0


func delete_slot(slot: int) -> void:
	var fname := "world_%d.save" % clampi(slot, 1, MAX_WORLDS)
	var da := DirAccess.open("user://")
	if da and da.file_exists(fname):
		da.remove(fname)


## Краткое описание слота для меню (без загрузки в автозагрузки квестов).
func get_slot_preview(slot: int) -> Dictionary:
	var s := clampi(slot, 1, MAX_WORLDS)
	var out: Dictionary = {
		"slot": s,
		"occupied": false,
		"mode": Mode.NONE,
		"mode_name": "—",
		"mama": 0,
	}
	if not FileAccess.file_exists(slot_path(s)):
		return out
	var f := FileAccess.open(slot_path(s), FileAccess.READ)
	if f == null:
		return out
	var txt := f.get_as_text()
	f.close()
	var jp := JSON.new()
	if jp.parse(txt) != OK:
		out["occupied"] = true
		out["mode_name"] = "ошибка файла"
		return out
	var root = jp.data
	if typeof(root) != TYPE_DICTIONARY:
		return out
	var d: Dictionary = root
	if int(d.get("version", 0)) != SAVE_VERSION:
		out["occupied"] = true
		out["mode_name"] = "старая версия"
		return out
	out["occupied"] = true
	var mode_raw := int(d.get("mode", Mode.SURVIVAL))
	var mode_clamped := clampi(mode_raw, Mode.NONE, Mode.PEACEFUL)
	out["mode"] = mode_clamped
	out["mode_name"] = mode_display_name(mode_clamped as Mode)
	var g = d.get("game", {})
	if typeof(g) == TYPE_DICTIONARY:
		out["mama"] = int(g.get("mama_tokens", 0))
	return out


func mode_display_name(m: Mode) -> String:
	match m:
		Mode.HARDCORE:
			return "Хардкор"
		Mode.SURVIVAL:
			return "Выживание"
		Mode.CREATIVE:
			return "Креатив"
		Mode.PEACEFUL:
			return "Мирный"
		_:
			return "—"


func has_save_file() -> bool:
	return has_any_saved_world()


func start_new_game(mode: Mode, into_slot: int) -> void:
	var slot := clampi(into_slot, 1, MAX_WORLDS)
	current_slot = slot
	current_mode = mode
	reset_world_state()
	save_to_disk(null)
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(MAIN_SCENE)


func continue_game(from_slot: int) -> void:
	var slot := clampi(from_slot, 1, MAX_WORLDS)
	if not load_from_slot(slot):
		push_warning("GameSave: не удалось загрузить мир %d." % slot)
		return
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(MAIN_SCENE)


func reset_world_state() -> void:
	GameProgress.reset_for_new_game()
	CityQuests.reset_for_new_game()
	KingQuests.reset_for_new_game()
	_pending_player.clear()


func reset_world_for_hardcore_respawn() -> void:
	reset_world_state()
	save_to_disk(null)


func get_mansion_spawn() -> Vector3:
	return Vector3(0.0, 0.55, -2.0)


func save_to_disk(player: Node3D) -> void:
	var payload := _build_payload(player)
	var json := JSON.stringify(payload)
	var path := slot_path(current_slot)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("GameSave: запись %s не удалась." % path)
		return
	f.store_string(json)
	f.close()


func autosave_if_playing(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	if current_mode == Mode.NONE:
		return
	var sc := get_tree().current_scene
	if sc == null:
		return
	if String(sc.scene_file_path) != MAIN_SCENE:
		return
	if player.has_method("is_dead_for_save") and bool(player.call("is_dead_for_save")):
		return
	save_to_disk(player)


func load_from_slot(slot: int) -> bool:
	var s := clampi(slot, 1, MAX_WORLDS)
	if not FileAccess.file_exists(slot_path(s)):
		return false
	current_slot = s
	var f := FileAccess.open(slot_path(s), FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	f.close()
	var p := JSON.new()
	if p.parse(txt) != OK:
		return false
	var root = p.data
	if typeof(root) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = root
	if int(d.get("version", 0)) != SAVE_VERSION:
		return false
	var mode_raw := int(d.get("mode", Mode.SURVIVAL))
	current_mode = clampi(mode_raw, Mode.NONE, Mode.PEACEFUL) as Mode
	var g = d.get("game", {})
	if typeof(g) == TYPE_DICTIONARY:
		GameProgress.apply_persistent_state(g)
	var c = d.get("city", {})
	if typeof(c) == TYPE_DICTIONARY:
		CityQuests.apply_persistent_state(c)
	var k = d.get("king", {})
	if typeof(k) == TYPE_DICTIONARY:
		KingQuests.apply_persistent_state(k)
	var pl = d.get("player", {})
	_pending_player = pl if typeof(pl) == TYPE_DICTIONARY else {}
	return true


func apply_pending_player_transform(player: Node3D, camera_pivot: Node3D) -> void:
	if _pending_player.is_empty():
		return
	var px := float(_pending_player.get("x", player.global_position.x))
	var py := float(_pending_player.get("y", player.global_position.y))
	var pz := float(_pending_player.get("z", player.global_position.z))
	player.global_position = Vector3(px, py, pz)
	var yaw := float(_pending_player.get("yaw", player.global_rotation.y))
	player.global_rotation = Vector3(0.0, yaw, 0.0)
	if camera_pivot != null:
		var pitch := float(_pending_player.get("pitch", camera_pivot.rotation.x))
		camera_pivot.rotation.x = pitch
	_pending_player.clear()


func _build_payload(player: Node3D) -> Dictionary:
	var payload: Dictionary = {
		"version": SAVE_VERSION,
		"mode": int(current_mode),
		"game": GameProgress.get_persistent_state(),
		"city": CityQuests.get_persistent_state(),
		"king": KingQuests.get_persistent_state(),
	}
	if player != null and is_instance_valid(player):
		payload["player"] = {
			"x": player.global_position.x,
			"y": player.global_position.y,
			"z": player.global_position.z,
			"yaw": player.global_rotation.y,
			"pitch": _read_player_pitch(player),
		}
	return payload


func _read_player_pitch(player: Node3D) -> float:
	var pivot := player.get_node_or_null("CameraPivot") as Node3D
	if pivot == null:
		return 0.0
	return pivot.rotation.x


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		var pl := get_tree().get_first_node_in_group("player")
		if pl is Node3D:
			autosave_if_playing(pl as Node3D)
