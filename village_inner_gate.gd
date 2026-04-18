extends StaticBody3D
## Внутренняя дверь прохода в деревню: закрыта, пока выставлен флаг village_inner_gate_closed.

const FLAG_KEY := "village_inner_gate_closed"


func _ready() -> void:
	if not GameProgress.upgrades_changed.is_connected(_sync_from_progress):
		GameProgress.upgrades_changed.connect(_sync_from_progress)
	_sync_from_progress()


func _sync_from_progress() -> void:
	var closed := GameProgress.has_puzzle_flag(FLAG_KEY)
	collision_layer = 1 if closed else 0
	collision_mask = 1 if closed else 0
	for c in get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).visible = closed
		elif c is Label3D:
			(c as Label3D).visible = closed
		elif c is CollisionShape3D:
			(c as CollisionShape3D).disabled = not closed
