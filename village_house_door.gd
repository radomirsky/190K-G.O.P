extends StaticBody3D
## Дверной проём дома в деревне: E — ограбить один раз, деревня злится (больше врагов).

@export var house_id: String = "0_0"

var _robbed: bool = false


func _ready() -> void:
	add_to_group("village_house_loot")


func interact(player: Node) -> void:
	if _robbed:
		if player != null and is_instance_valid(player) and player.has_method("notify_quest_banner"):
			player.call("notify_quest_banner", "Здесь уже пусто.")
		return
	_robbed = true
	var loot := 2 + randi() % 3
	GameProgress.add_mama(loot)
	GameProgress.register_village_robbery()
	if player != null and is_instance_valid(player) and player.has_method("notify_quest_banner"):
		player.call(
			"notify_quest_banner",
			"Нашёл %d МАМА. Ограбление! В деревне появятся враги — осторожнее." % loot
		)
