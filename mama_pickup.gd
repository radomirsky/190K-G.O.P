extends Area3D

@export var mama_value: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	GameProgress.add_mama(mama_value)
	queue_free()
