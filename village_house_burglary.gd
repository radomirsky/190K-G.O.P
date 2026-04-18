extends Node3D
## Грабёж: нужно зайти в зону у входа (порог), затем E на ящик. Свидетели — только жители (quest_npc).

@export var house_id: String = "0_0"
@export var village_id: int = 0

var _players_in_zone: int = 0
var _robbed: bool = false


func _ready() -> void:
	var area := get_node_or_null("InteriorArea") as Area3D
	if area != null:
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)
		if not area.body_exited.is_connected(_on_body_exited):
			area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_in_group("player"):
		_players_in_zone += 1


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_in_group("player"):
		_players_in_zone = maxi(0, _players_in_zone - 1)


func try_loot(player: Node) -> void:
	if _robbed:
		if player != null and is_instance_valid(player) and player.has_method("notify_quest_banner"):
			player.call("notify_quest_banner", "Здесь уже пусто.")
		return
	if _players_in_zone <= 0:
		if player != null and is_instance_valid(player) and player.has_method("notify_quest_banner"):
			player.call("notify_quest_banner", "Сначала зайди в дом — подойди к порогу со стороны улицы.")
		return
	_robbed = true
	var loot := 2 + randi() % 3
	GameProgress.add_mama(loot)
	GameProgress.register_village_robbery()
	var mob := false
	if player != null and is_instance_valid(player):
		mob = CityQuests.robbery_triggers_villager_mob(self, player, village_id)
		if mob:
			CityQuests.alert_all_villagers_katana_mob(village_id)
	if player != null and is_instance_valid(player) and player.has_method("notify_quest_banner"):
		if mob:
			player.call(
				"notify_quest_banner",
				"Нашёл %d МАМА! Тебя видели — жители с катанами!" % loot
			)
		else:
			player.call(
				"notify_quest_banner",
				"Нашёл %d МАМА. Ограбление! В деревне появятся враги — осторожнее." % loot
			)
