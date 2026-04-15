extends Node3D

@export var lifetime_sec: float = 4.8
@export var suck_radius: float = 24.0
@export var suck_accel: float = 26.0
@export var suck_up: float = 0.55

var _t: float = 0.0

@onready var _area: Area3D = $Area3D
@onready var _col: CollisionShape3D = $Area3D/CollisionShape3D


func _ready() -> void:
	if _col and _col.shape is SphereShape3D:
		(_col.shape as SphereShape3D).radius = suck_radius


func _process(delta: float) -> void:
	_t += delta
	if _t >= lifetime_sec:
		queue_free()


func _physics_process(delta: float) -> void:
	if _area == null:
		return
	var center := global_position
	for body in _area.get_overlapping_bodies():
		if body == null:
			continue
		if not (body is Node) or not (body as Node).is_in_group("enemy"):
			continue
		var e := body as CharacterBody3D
		if e == null:
			continue
		var to := center - e.global_position
		var dist := maxf(0.35, to.length())
		var dir := to / dist
		# Чем ближе — тем сильнее (мягко).
		var k := clampf(1.0 - (dist / maxf(suck_radius, 0.1)), 0.0, 1.0)
		var pull := suck_accel * (0.25 + 0.75 * k) * delta
		e.velocity.x += dir.x * pull
		e.velocity.z += dir.z * pull
		e.velocity.y += (dir.y + suck_up) * pull * 0.85
