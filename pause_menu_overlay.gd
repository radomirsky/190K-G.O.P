extends Control
## Висит поверх игры с PROCESS_MODE_ALWAYS, пока дерево сцены на паузе.

signal continue_requested


func _unhandled_input(event: InputEvent) -> void:
	var esc := false
	if event is InputEventKey:
		var k := event as InputEventKey
		esc = k.pressed and not k.echo and (k.keycode == KEY_ESCAPE or k.physical_keycode == KEY_ESCAPE)
	if event.is_action_pressed("ui_cancel") or esc:
		continue_requested.emit()
		get_viewport().set_input_as_handled()
