extends StaticBody3D
## Рычаг: E по прицелу — выставляет флаг (один раз) или переключает его (toggle_flag_on_interact).

@export var flag_key: String = "suburbs_lever"
@export var one_shot: bool = true
## Если true и one_shot == false: каждое E снимает/ставит флаг (например внутренние ворота).
@export var toggle_flag_on_interact: bool = false

var _pulled: bool = false


func _ready() -> void:
	add_to_group("puzzle_lever")
	call_deferred("_apply_handle_from_flag")


func interact(_player: Node) -> void:
	if one_shot and _pulled:
		return
	if one_shot:
		_pulled = true
		GameProgress.set_puzzle_flag(flag_key, true)
	elif toggle_flag_on_interact:
		var on := not GameProgress.has_puzzle_flag(flag_key)
		GameProgress.set_puzzle_flag(flag_key, on)
	else:
		GameProgress.set_puzzle_flag(flag_key, true)
	_apply_handle_from_flag()


func _apply_handle_from_flag() -> void:
	var h := get_node_or_null("Handle") as MeshInstance3D
	if h == null:
		return
	var pulled := GameProgress.has_puzzle_flag(flag_key)
	h.rotation_degrees.z = -38.0 if pulled else 0.0
