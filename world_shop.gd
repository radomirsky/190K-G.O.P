extends Node3D

## Киоск на краю карты: при входе игрока в зону открывается тот же UI магазина (валюта — МАМА).


func _ready() -> void:
	var tr := get_node_or_null("Trigger") as Area3D
	if tr == null:
		return
	if not tr.body_entered.is_connected(_on_body_entered):
		tr.body_entered.connect(_on_body_entered)
	if not tr.body_exited.is_connected(_on_body_exited):
		tr.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("notify_world_shop_zone"):
		body.notify_world_shop_zone(true)


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("notify_world_shop_zone"):
		body.notify_world_shop_zone(false)
