extends StaticBody3D
## Точка E внутри зоны дома — делегирует родителю.


func _ready() -> void:
	add_to_group("village_house_loot")


func interact(player: Node) -> void:
	var p := get_parent()
	if p != null and p.has_method("try_loot"):
		p.call("try_loot", player)
