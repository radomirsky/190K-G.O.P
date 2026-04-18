extends Node3D
## Точка входа уровня: правила режима «Мирный» (убрать уже расставленных врагов).


func _ready() -> void:
	if GameSave.is_peaceful():
		call_deferred("_apply_peaceful_clear_enemies")


func _apply_peaceful_clear_enemies() -> void:
	for n in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(n):
			n.queue_free()
