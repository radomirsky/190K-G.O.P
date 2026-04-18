extends StaticBody3D
## Житель города: E по прицелу — квест через CityQuests.

@export var npc_index: int = 0


func _ready() -> void:
	add_to_group("quest_npc")
	var lbl := get_node_or_null("Label3D") as Label3D
	if lbl:
		lbl.text = "Житель [%d] — E" % npc_index


func interact(player: Node) -> void:
	CityQuests.on_npc_interact(npc_index, player)
