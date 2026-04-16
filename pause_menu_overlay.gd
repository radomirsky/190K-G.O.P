extends Control
## Висит поверх игры с PROCESS_MODE_ALWAYS, пока дерево сцены на паузе.

## Esc / ui_cancel: закрыть паузу или вернуться с экрана «Управление».
signal back_or_cancel_requested


func _unhandled_input(event: InputEvent) -> void:
	var esc := false
	if event is InputEventKey:
		var k := event as InputEventKey
		esc = k.pressed and not k.echo and (k.keycode == KEY_ESCAPE or k.physical_keycode == KEY_ESCAPE)
	if event.is_action_pressed("ui_cancel") or esc:
		back_or_cancel_requested.emit()
		get_viewport().set_input_as_handled()
