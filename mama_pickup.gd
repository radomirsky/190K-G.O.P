extends RigidBody3D

@export var mama_value: int = 1

@onready var _pickup_zone: Area3D = $PickupZone


func _ready() -> void:
	gravity_scale = 1.0
	if _pickup_zone and not _pickup_zone.body_entered.is_connected(_on_pickup_body_entered):
		_pickup_zone.body_entered.connect(_on_pickup_body_entered)


func _on_pickup_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	GameProgress.add_mama(mama_value)
	queue_free()
