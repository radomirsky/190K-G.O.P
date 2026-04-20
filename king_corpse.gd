extends RigidBody3D
## Труп короля: бросок как снаряд. За пределами мира — секретный босс.

const WORLD_XZ_LIMIT: float = 195.0
const WORLD_Y_FALL: float = -34.0

var _off_map_checked: bool = false


func _ready() -> void:
	add_to_group("throwable")
	contact_monitor = true
	max_contacts_reported = 4
	linear_damp = 0.35
	angular_damp = 0.9


func _physics_process(_delta: float) -> void:
	if _off_map_checked:
		return
	var p := global_position
	if (
		p.y < WORLD_Y_FALL
		or absf(p.x) > WORLD_XZ_LIMIT
		or absf(p.z) > WORLD_XZ_LIMIT
	):
		_off_map_checked = true
		KingQuests.request_secret_boss_from_corpse_fall()
		queue_free()
