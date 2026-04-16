extends Control
## Висит поверх игры с PROCESS_MODE_ALWAYS, пока дерево сцены на паузе.

signal continue_requested


func _unhandled_input(event: InputEvent) -> void:
	var esc := event is InputEventKey and event.pressed and not event.echo and (
		event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE
	)
	if event.is_action_pressed("ui_cancel") or esc:
		continue_requested.emit()
		get_viewport().set_input_as_handled()
