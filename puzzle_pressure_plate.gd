extends Area3D
## Нажимная плита: при входе игрока выставляет флаг в GameProgress.

@export var flag_key: String = "suburbs_plate"
## Дополнительные флаги (например village_entry_unlocked для доступа к жителю 1).
@export var extra_flag_keys: PackedStringArray = PackedStringArray()
@export var one_shot: bool = true

var _done: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if one_shot and _done:
		return
	if body is CharacterBody3D and body.is_in_group("player"):
		_done = true
		GameProgress.set_puzzle_flag(flag_key, true)
		for fk in extra_flag_keys:
			if fk != "":
				GameProgress.set_puzzle_flag(fk, true)
		_flash_ok()


func _flash_ok() -> void:
	var mi := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mi == null:
		return
	var m := mi.get_surface_override_material(0) as StandardMaterial3D
	if m == null:
		m = StandardMaterial3D.new()
		mi.set_surface_override_material(0, m)
	m.albedo_color = Color(0.25, 0.85, 0.45, 1.0)
	m.emission_enabled = true
	m.emission = Color(0.2, 0.7, 0.35, 1.0)
	m.emission_energy_multiplier = 0.9
