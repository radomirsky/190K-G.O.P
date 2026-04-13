extends RigidBody3D

@export var destroy_min_relative_speed: float = 1.15

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 12
	if not body_shape_entered.is_connected(_on_body_shape_entered):
		body_shape_entered.connect(_on_body_shape_entered)


func _on_body_shape_entered(
	_body_rid: RID,
	body: Node,
	_body_shape_index: int,
	_local_shape_index: int
) -> void:
	if is_in_group("held_throwable"):
		return
	if not body is RigidBody3D:
		return
	if not body.is_in_group("throwable"):
		return
	if body == self:
		return
	var other := body as RigidBody3D
	if other.is_in_group("held_throwable"):
		var keep := linear_velocity
		call_deferred("_restore_velocity", keep)
		return
	var rel := linear_velocity.distance_to(other.linear_velocity)
	if rel < destroy_min_relative_speed:
		return
	var v2 := linear_velocity.length_squared()
	var o2 := other.linear_velocity.length_squared()
	const EPS := 1e-3
	if v2 < o2 - EPS:
		return
	if absf(v2 - o2) <= EPS:
		if get_instance_id() < other.get_instance_id():
			return
	var keep_v := linear_velocity
	if is_instance_valid(other):
		other.call_deferred("queue_free")
	call_deferred("_restore_velocity", keep_v)


func _restore_velocity(v: Vector3) -> void:
	if is_instance_valid(self):
		linear_velocity = v
