extends Node3D

@export var enemy_scene: PackedScene = preload("res://enemy.tscn")
@export var player_path: NodePath = NodePath("../Player")

@export var spawn_every_sec: float = 1.25
@export var max_alive: int = 12

@export var spawn_radius_min: float = 10.0
@export var spawn_radius_max: float = 18.0
@export var spawn_height: float = 0.6

var _t: float = 0.0
var _player: Node3D = null


func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	randomize()


func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null(player_path) as Node3D
		if _player == null:
			return

	_t += delta
	if _t < spawn_every_sec:
		return
	_t = 0.0

	# Ограничиваем количество живых врагов.
	if get_tree().get_nodes_in_group("enemy").size() >= max_alive:
		return

	_spawn_enemy()


func _spawn_enemy() -> void:
	if enemy_scene == null:
		return
	var e := enemy_scene.instantiate() as Node3D
	if e == null:
		return
	add_child(e)

	# Прописываем цель врагу (внутри его локальной сцены Enemy).
	if e.has_method("set"):
		e.set("player_path", get_path_to(_player))

	var r := randf_range(spawn_radius_min, spawn_radius_max)
	var a := randf_range(0.0, TAU)
	var off := Vector3(cos(a) * r, 0.0, sin(a) * r)
	e.global_position = _player.global_position + off + Vector3(0.0, spawn_height, 0.0)
