extends Node3D
## Точка входа уровня: правила режима «Мирный» (убрать уже расставленных врагов).


func _ready() -> void:
	if GameSave.is_peaceful():
		call_deferred("_apply_peaceful_clear_enemies")
	call_deferred("_restore_secret_big_king_if_needed")


func _restore_secret_big_king_if_needed() -> void:
	KingQuests.restore_secret_big_king_if_save_pending()


func _apply_peaceful_clear_enemies() -> void:
	for n in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(n):
			n.queue_free()
