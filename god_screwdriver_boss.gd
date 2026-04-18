extends GameEnemy
## Финальный босс: 20 ударов по 1 HP, парит над игроком, сбрасывает бомбы.

const BOMB_SCENE := preload("res://boss_air_bomb.tscn")

@export var hover_height: float = 6.8
@export var hover_speed: float = 12.0
@export var bomb_drop_interval: float = 1.12

var _bomb_tick: float = 0.35


func _ready() -> void:
	is_boss = true
	max_hp = 20
	touch_damage = 10
	is_ranged = false
	move_speed = 0.0
	gravity = 0.0
	vision_requires_line_of_sight = false
	vision_range = 140.0
	size_scale = 0.38
	super._ready()
	call_deferred("_apply_screwdriver_visual")


func _apply_screwdriver_visual() -> void:
	var hum := get_node_or_null("Humanoid") as Node3D
	if hum == null:
		return
	for c in hum.get_children():
		c.queue_free()
	var handle := MeshInstance3D.new()
	var ch := CylinderMesh.new()
	ch.top_radius = 0.2
	ch.bottom_radius = 0.2
	ch.height = 0.75
	ch.radial_segments = 12
	handle.mesh = ch
	var mh := StandardMaterial3D.new()
	mh.albedo_color = Color(0.92, 0.78, 0.18)
	mh.metallic = 0.55
	mh.roughness = 0.32
	handle.set_surface_override_material(0, mh)
	handle.rotation_degrees = Vector3(90, 0, 0)
	handle.position = Vector3(0, 0.95, 0)
	hum.add_child(handle)
	var shaft := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.11
	sm.bottom_radius = 0.04
	sm.height = 2.15
	sm.radial_segments = 10
	shaft.mesh = sm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.52, 0.55, 0.6)
	ms.metallic = 0.92
	ms.roughness = 0.2
	shaft.set_surface_override_material(0, ms)
	shaft.rotation_degrees = Vector3(90, 0, 0)
	shaft.position = Vector3(0, 2.25, 0)
	hum.add_child(shaft)
	var lbl := Label3D.new()
	lbl.text = "БОЖЬЯ ОТВЁРТКА"
	lbl.font_size = 26
	lbl.outline_size = 8
	lbl.position = Vector3(0, 3.35, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hum.add_child(lbl)


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	if _dead:
		return
	_player = _resolve_player()

	_break_cd = maxf(_break_cd - delta, 0.0)
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_ranged_fire_cd = maxf(_ranged_fire_cd - delta, 0.0)
	_ranged_reload_t = maxf(_ranged_reload_t - delta, 0.0)
	_attack_anim = maxf(_attack_anim - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_thrown_stun = maxf(_thrown_stun - delta, 0.0)
	_flash = maxf(_flash - delta, 0.0)
	if _flash <= 0.0:
		_set_humanoid_color(_base_color)

	_update_attack_anim_visual()

	velocity = Vector3.ZERO
	if GameProgress.world_time_frozen:
		move_and_slide()
		return

	if _player != null and is_instance_valid(_player):
		if not _aggro:
			_aggro = true
		var target := _player.global_position + Vector3(0.0, hover_height, 0.0)
		var to_v := target - global_position
		var d := to_v.length()
		if d > 0.04:
			velocity = to_v * (hover_speed / maxf(d, 0.1))

	move_and_slide()

	_bomb_tick -= delta
	if _bomb_tick <= 0.0 and _player != null and is_instance_valid(_player):
		_bomb_tick = bomb_drop_interval
		_spawn_air_bomb()


func _spawn_air_bomb() -> void:
	var scene := get_tree().current_scene
	if scene == null or _player == null:
		return
	var b := BOMB_SCENE.instantiate() as CharacterBody3D
	if b == null:
		return
	var p0 := _player.global_position
	p0.x += randf_range(-5.5, 5.5)
	p0.z += randf_range(-5.5, 5.5)
	p0.y += 14.0 + randf_range(0.0, 5.0)
	scene.add_child(b)
	b.global_position = p0
