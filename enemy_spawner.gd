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
	if not GameProgress.boss_spawn_requested.is_connected(_on_boss_spawn_requested):
		GameProgress.boss_spawn_requested.connect(_on_boss_spawn_requested)
	randomize()


func _on_boss_spawn_requested() -> void:
	if enemy_scene == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null(player_path) as Node3D
		if _player == null:
			return
	if get_tree().get_nodes_in_group("boss").size() > 0:
		return
	var b := enemy_scene.instantiate() as CharacterBody3D
	if b == null:
		return
	b.is_boss = true
	b.max_hp = 10
	b.touch_damage = 34
	b.move_speed = 3.1
	add_child(b)
	b.set("player_path", get_path_to(_player))
	var flat := _player.global_position - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.001:
		flat = Vector3(0.0, 0.0, -1.0)
	flat = flat.normalized() * 16.0
	b.global_position = _player.global_position + flat + Vector3(0.0, spawn_height, 0.0)


func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameProgress.world_time_frozen:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null(player_path) as Node3D
		if _player == null:
			return

	_t += delta
	if _t < spawn_every_sec:
		return
	_t = 0.0

	# Ограничиваем количество живых обычных врагов (босс не считается).
	var n_alive := 0
	for node in get_tree().get_nodes_in_group("enemy"):
		if node is Node and (node as Node).is_in_group("boss"):
			continue
		n_alive += 1
	if n_alive >= max_alive:
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
