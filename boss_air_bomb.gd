extends CharacterBody3D
## Падающая бомба босса: взрыв при касании земли/игрока, урон по радиусу.

const FALL_SPEED := 28.0
const SPLASH_R2 := 7.5 * 7.5
const DAMAGE := 11

var _exploded: bool = false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	if GameProgress.world_time_frozen:
		return
	velocity = Vector3(0.0, -FALL_SPEED, 0.0)
	move_and_slide()
	if is_on_floor():
		_explode()
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col == null:
			continue
		var n := col.get_collider()
		if n != null and n is Node and (n as Node).is_in_group("player"):
			_explode()
			return


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	var p := global_position
	for pl in get_tree().get_nodes_in_group("player"):
		if pl.has_method("take_damage"):
			var xz := Vector3(pl.global_position.x - p.x, 0.0, pl.global_position.z - p.z)
			if xz.length_squared() <= SPLASH_R2:
				pl.call("take_damage", DAMAGE, "god_screwdriver_bomb")
	queue_free()
