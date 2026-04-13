extends Node

const MAX_THROWABLES: int = 500

var _fifo: Array[RigidBody3D] = []


func _ready() -> void:
	call_deferred("_bootstrap_from_scene")


func _bootstrap_from_scene() -> void:
	for node in get_tree().get_nodes_in_group("throwable"):
		if node is RigidBody3D:
			var rb := node as RigidBody3D
			if not _fifo.has(rb):
				_fifo.append(rb)
				_connect_exit(rb)
	_trim_to_cap()


func _connect_exit(rb: RigidBody3D) -> void:
	if rb.get_meta("_tb_registered", false):
		return
	rb.set_meta("_tb_registered", true)
	rb.tree_exiting.connect(_on_rb_tree_exiting.bind(rb))


func _on_rb_tree_exiting(rb: RigidBody3D) -> void:
	var i := _fifo.find(rb)
	if i >= 0:
		_fifo.remove_at(i)


func track_throwable(rb: RigidBody3D) -> void:
	if rb == null or not is_instance_valid(rb):
		return
	if _fifo.has(rb):
		return
	_trim_before_add()
	_fifo.append(rb)
	_connect_exit(rb)


func _trim_before_add() -> void:
	var guard := 0
	while _fifo.size() >= MAX_THROWABLES and guard < MAX_THROWABLES * 3:
		guard += 1
		if _fifo.is_empty():
			break
		var victim := _fifo.pop_front()
		if not is_instance_valid(victim):
			continue
		if victim.is_in_group("held_throwable"):
			_fifo.append(victim)
			continue
		victim.queue_free()


func _trim_to_cap() -> void:
	var guard := 0
	while _fifo.size() > MAX_THROWABLES and guard < MAX_THROWABLES * 3:
		guard += 1
		if _fifo.is_empty():
			break
		var victim := _fifo.pop_front()
		if not is_instance_valid(victim):
			continue
		if victim.is_in_group("held_throwable"):
			_fifo.append(victim)
			continue
		victim.queue_free()
