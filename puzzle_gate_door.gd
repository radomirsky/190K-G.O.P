extends StaticBody3D
## Ворота: исчезают, когда все перечисленные флаги выставлены.

@export var need_flags: Array[String] = ["suburbs_plate", "suburbs_lever"]

var _opened: bool = false


func _ready() -> void:
	if not GameProgress.upgrades_changed.is_connected(_try_open):
		GameProgress.upgrades_changed.connect(_try_open)
	_try_open()


func _try_open() -> void:
	if _opened:
		return
	for f in need_flags:
		if not GameProgress.has_puzzle_flag(f):
			return
	_opened = true
	if GameProgress.upgrades_changed.is_connected(_try_open):
		GameProgress.upgrades_changed.disconnect(_try_open)
	collision_layer = 0
	collision_mask = 0
	for c in get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).visible = false
	queue_free()
