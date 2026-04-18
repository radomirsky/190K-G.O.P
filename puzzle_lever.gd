extends StaticBody3D
## Рычаг: E по прицелу — включает флаг (один раз).

@export var flag_key: String = "suburbs_lever"
@export var one_shot: bool = true

var _pulled: bool = false


func _ready() -> void:
	add_to_group("puzzle_lever")


func interact(_player: Node) -> void:
	if one_shot and _pulled:
		return
	_pulled = true
	GameProgress.set_puzzle_flag(flag_key, true)
	var h := get_node_or_null("Handle") as MeshInstance3D
	if h:
		h.rotation_degrees.z = -38.0
