extends StaticBody3D
## Внешние ворота деревни: закрыты, пока не выполнена головоломка (need_flags). После — открыты,
## пока не включён рычаг (closed_toggle_flag). Рычаг должен быть с toggle_flag_on_interact.

@export var need_flags: Array = ["suburbs_plate", "suburbs_lever"]
@export var closed_toggle_flag: String = "village_outer_closed"


func _ready() -> void:
	if not GameProgress.upgrades_changed.is_connected(_sync):
		GameProgress.upgrades_changed.connect(_sync)
	_sync()


func _sync() -> void:
	var puzzle_ok := true
	for f in need_flags:
		var fk := str(f)
		if fk == "":
			continue
		if not GameProgress.has_puzzle_flag(fk):
			puzzle_ok = false
			break
	var shut := false
	if puzzle_ok and closed_toggle_flag != "":
		shut = GameProgress.has_puzzle_flag(closed_toggle_flag)
	var block := (not puzzle_ok) or shut
	collision_layer = 1 if block else 0
	collision_mask = 1 if block else 0
	for c in get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).visible = block
		elif c is Label3D:
			(c as Label3D).visible = block
		elif c is CollisionShape3D:
			(c as CollisionShape3D).disabled = not block
