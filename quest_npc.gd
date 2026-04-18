extends StaticBody3D
## Житель: E — квест (главный 0–2 или побочный 3–10). Катана наносит урон; смерть — «охота» в деревне.

@export var npc_index: int = 0
@export var max_hp: int = 14

var _hp: int = 14
var _dead: bool = false


func _ready() -> void:
	_hp = max_hp
	add_to_group("quest_npc")
	add_to_group("talkable_npc")
	add_to_group("village_damageable_npc")
	var lbl := get_node_or_null("Label3D") as Label3D
	if lbl:
		lbl.text = "Житель %d — E" % npc_index


func interact(player: Node) -> void:
	if _dead:
		return
	if npc_index >= 3 and npc_index <= 10:
		CityQuests.on_side_npc_interact(npc_index, player)
	else:
		CityQuests.on_npc_interact(npc_index, player)


func take_katana_hit(damage: int) -> void:
	if _dead:
		return
	var d := maxi(1, damage)
	_hp -= d
	if _hp <= 0:
		_die()


func _die() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("talkable_npc")
	remove_from_group("quest_npc")
	remove_from_group("village_damageable_npc")
	collision_layer = 0
	collision_mask = 0
	var body := get_node_or_null("BodyMesh") as MeshInstance3D
	if body:
		body.visible = false
	var lbl := get_node_or_null("Label3D") as Label3D
	if lbl:
		lbl.visible = false
	CityQuests.on_village_npc_killed(npc_index)
