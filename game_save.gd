extends Node

## Слот сохранения: режим игры, прогресс и позиция игрока (для «Продолжить»).

const SAVE_PATH := "user://profile.save"
const SAVE_VERSION := 1
const MAIN_SCENE := "res://main.tscn"
enum Mode { NONE, HARDCORE, SURVIVAL, CREATIVE, PEACEFUL }

var current_mode: Mode = Mode.NONE


func is_creative() -> bool:
	return current_mode == Mode.CREATIVE


func is_peaceful() -> bool:
	return current_mode == Mode.PEACEFUL
var _pending_player: Dictionary = {}


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func start_new_game(mode: Mode) -> void:
	current_mode = mode
	reset_world_state()
	save_to_disk(null)
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(MAIN_SCENE)


func continue_game() -> void:
	if not load_from_disk():
		push_warning("GameSave: не удалось загрузить сохранение.")
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
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("GameSave: запись %s не удалась." % SAVE_PATH)
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


func load_from_disk() -> bool:
	if not has_save_file():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
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
