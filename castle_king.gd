extends StaticBody3D
## Король: E — поручения. Катана бьёт по нему — стража в ярости.

@export var max_hp: int = 36

var _hp: int = 36


func _ready() -> void:
	_hp = max_hp
	add_to_group("talkable_npc")
	add_to_group("king_npc")


func interact(player: Node) -> void:
	KingQuests.on_king_interact(player)


func take_katana_hit(damage: int) -> void:
	KingQuests.on_king_attacked()
	var d := maxi(1, damage)
	_hp -= d
	if _hp <= 0:
		_hp = 0
		if is_inside_tree():
			var tree := get_tree()
			if tree != null:
				for n in tree.get_nodes_in_group("castle_guard"):
					if n.has_method("activate_aggro"):
						n.call("activate_aggro")
