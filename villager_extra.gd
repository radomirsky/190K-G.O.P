extends StaticBody3D
## Обычный житель без квеста: E — короткая реплика (тот же баннер, что у квестовых).

@export_multiline var greet_line: String = "Тихий день."


func _ready() -> void:
	add_to_group("talkable_npc")
	var body := get_node_or_null("BodyMesh") as MeshInstance3D
	if body != null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(
			0.42 + randf() * 0.38, 0.35 + randf() * 0.4, 0.32 + randf() * 0.38, 1.0
		)
		m.roughness = 0.62
		body.set_surface_override_material(0, m)
	var lbl := get_node_or_null("Label3D") as Label3D
	if lbl != null:
		lbl.text = "Житель — E"


func interact(player: Node) -> void:
	if player != null and is_instance_valid(player) and player.has_method("notify_quest_banner"):
		player.call("notify_quest_banner", greet_line)
