extends Control
## Висит поверх игры с PROCESS_MODE_ALWAYS, пока дерево сцены на паузе.

signal continue_requested


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		continue_requested.emit()
		get_viewport().set_input_as_handled()
