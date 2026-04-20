extends StaticBody3D
## Король: E — поручения. Катана бьёт по нему — стража в ярости; при 0 HP — труп.

@export var max_hp: int = 36

var _hp: int = 36
var _dead: bool = false


func _ready() -> void:
	_hp = max_hp
	add_to_group("talkable_npc")
	add_to_group("king_npc")


func interact(player: Node) -> void:
	if _dead:
		return
	KingQuests.on_king_interact(player)


func take_katana_hit(damage: int) -> void:
	if _dead:
		return
	KingQuests.on_king_attacked()
	var d := maxi(1, damage)
	_hp -= d
	if _hp <= 0:
		_die()


func creative_wand_kill() -> void:
	if _dead:
		return
	_die()


func _die() -> void:
	if _dead:
		return
	_dead = true
	KingQuests.on_king_attacked()
	var parent_n := get_parent()
	var wp := global_position
	KingQuests.on_king_slain_spawn_corpse(wp, parent_n)
	queue_free()
