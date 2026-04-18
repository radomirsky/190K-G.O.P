extends StaticBody3D
## Рычаг: E по прицелу — выставляет флаг (один раз) или переключает его (toggle_flag_on_interact).

@export var flag_key: String = "suburbs_lever"
@export var one_shot: bool = true
## Если true и one_shot == false: каждое E снимает/ставит флаг (например внутренние ворота).
@export var toggle_flag_on_interact: bool = false
## Субтитры внизу экрана (тот же Label, что у жителей — notify_quest_banner), после переключения.
@export var banner_text_when_flag_on: String = ""
@export var banner_text_when_flag_off: String = ""
## Если > 0 — один раз при первом срабатывании (one_shot) выдать МАМА.
@export var mama_reward_on_first_pull: int = 0

var _pulled: bool = false
var _mama_left: int = 0


func _ready() -> void:
	_mama_left = mama_reward_on_first_pull
	add_to_group("puzzle_lever")
	call_deferred("_apply_handle_from_flag")


func interact(_player: Node) -> void:
	if one_shot and _pulled:
		return
	if one_shot:
		_pulled = true
		GameProgress.set_puzzle_flag(flag_key, true)
		if _mama_left > 0:
			GameProgress.add_mama(_mama_left)
			_mama_left = 0
		_emit_subtitle_banner(_player, banner_text_when_flag_on)
	elif toggle_flag_on_interact:
		var on := not GameProgress.has_puzzle_flag(flag_key)
		GameProgress.set_puzzle_flag(flag_key, on)
		_emit_subtitle_banner(_player, banner_text_when_flag_on if on else banner_text_when_flag_off)
	else:
		GameProgress.set_puzzle_flag(flag_key, true)
		_emit_subtitle_banner(_player, banner_text_when_flag_on)
	_apply_handle_from_flag()


func _emit_subtitle_banner(player: Node, text: String) -> void:
	if text == "":
		return
	if player != null and is_instance_valid(player) and player.has_method("notify_quest_banner"):
		player.call("notify_quest_banner", text)


func _apply_handle_from_flag() -> void:
	var h := get_node_or_null("Handle") as MeshInstance3D
	if h == null:
		return
	var pulled := GameProgress.has_puzzle_flag(flag_key)
	h.rotation_degrees.z = -38.0 if pulled else 0.0
