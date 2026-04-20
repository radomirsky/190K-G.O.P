extends CharacterBody3D
## Снаряд бомбомёта фургона: летит по прямой, при столкновении — взрыв по врагам в радиусе.

@export var fly_speed: float = 34.0
@export var max_lifetime_sec: float = 4.0
@export var splash_radius: float = 5.2
@export var splash_damage: int = 11

var _vel: Vector3 = Vector3.ZERO
var _life: float = 0.0
var _armed: bool = false


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING


func fire(from: Vector3, dir: Vector3) -> void:
	global_position = from
	_vel = dir.normalized() * fly_speed
	_life = max_lifetime_sec
	_armed = true


func _physics_process(delta: float) -> void:
	if not _armed:
		return
	if GameProgress.world_time_frozen:
		return
	_life -= delta
	if _life <= 0.0:
		_explode()
		return
	var col := move_and_collide(_vel * delta)
	if col:
		_explode()


func _explode() -> void:
	if not _armed:
		return
	_armed = false
	var p := global_position
	for n in get_tree().get_nodes_in_group("enemy"):
		if not n is Node3D:
			continue
		var e := n as Node3D
		if e.global_position.distance_squared_to(p) > splash_radius * splash_radius:
			continue
		if e.has_method("take_truck_hit"):
			e.call("take_truck_hit", splash_damage)
	queue_free()
