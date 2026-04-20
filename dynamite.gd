extends RigidBody3D
## Бросок из лавки: по таймеру или удару — слабый урон по площади.

@export var fuse_sec: float = 3.6
@export var explosion_radius: float = 3.9
@export var explosion_damage: int = 2
@export var impact_speed_to_detonate: float = 2.4
@export var arm_delay_sec: float = 0.12

var _fuse: float = 0.0
var _arm: float = 0.0
var _exploded: bool = false


func _ready() -> void:
	_fuse = fuse_sec
	_arm = arm_delay_sec
	contact_monitor = true
	max_contacts_reported = 8
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	if GameProgress.world_time_frozen:
		return
	_arm = maxf(_arm - delta, 0.0)
	_fuse -= delta
	if _fuse <= 0.0:
		_explode()


func _on_body_entered(body: Node) -> void:
	if _exploded or _arm > 0.0:
		return
	if body == self:
		return
	if linear_velocity.length() >= impact_speed_to_detonate:
		_explode()


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	var p := global_position
	var r2 := explosion_radius * explosion_radius
	for n in get_tree().get_nodes_in_group("enemy"):
		if not n is Node3D:
			continue
		var e := n as Node3D
		if e.global_position.distance_squared_to(p) > r2:
			continue
		if e.has_method("take_dynamite_explosion"):
			e.call("take_dynamite_explosion", explosion_damage)
	queue_free()
