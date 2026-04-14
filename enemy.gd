extends CharacterBody3D

@export var move_speed: float = 4.2
@export var accel: float = 18.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var player_path: NodePath = NodePath("../Player")
@export var break_cooldown_sec: float = 0.25
@export var break_radius: float = 1.35
@export var touch_damage: int = 8
@export var touch_distance: float = 2.1
@export var death_shard_impulse: float = 8.0
@export var death_shard_up: float = 3.5
@export var max_hp: int = 5
@export var damage_invuln_sec: float = 0.08
@export var hit_flash_sec: float = 1.4
@export var hit_flash_color: Color = Color(0.18, 0.95, 0.22, 1.0)
## До игрока ближе этого расстояния — множитель урона максимальный.
@export var proximity_damage_near_m: float = 3.5
## От игрока дальше этого — множитель минимальный (линейно между near и far).
@export var proximity_damage_far_m: float = 44.0
@export var proximity_damage_base: int = 1
@export var proximity_damage_close_mult: float = 2.6
@export var proximity_damage_far_mult: float = 0.85
## Урон от кольца стазиса (не зависит от дистанции до игрока — только попадание).
@export var stasis_hit_damage: int = 2
## Сколько залпов обреза нужно, чтобы убить врага с начальным max_hp (урон за залп делится поровну).
@export_range(1, 12, 1) var sawed_volleys_to_kill: int = 3

var _break_cd: float = 0.0
var _initial_max_hp: int = 5
var _last_sawed_volley_id: int = -1
var _player: Node3D = null
var _dead: bool = false
var _hp: int = 5
var _invuln: float = 0.0
var _flash: float = 0.0
var _base_color: Color = Color(0.95, 0.32, 0.32, 1.0)

@onready var _break_area: Area3D = $BreakArea

func _ready() -> void:
	add_to_group("enemy")
	_player = get_node_or_null(player_path) as Node3D
	if _break_area and not _break_area.body_entered.is_connected(_on_break_area_body_entered):
		_break_area.body_entered.connect(_on_break_area_body_entered)
	var hum := get_node_or_null("Humanoid") as Node3D
	if hum:
		var got_base := false
		for c in hum.get_children():
			if not c is MeshInstance3D:
				continue
			var mi := c as MeshInstance3D
			var mat := mi.get_surface_override_material(0) as StandardMaterial3D
			if mat == null:
				continue
			# Материал в сцене общий — делаем уникальным для КАЖДОГО кубика у этого врага,
			# чтобы враги не красили друг друга и чтобы "полностью зелёный" работало.
			var dup := mat.duplicate() as StandardMaterial3D
			mi.set_surface_override_material(0, dup)
			if not got_base:
				got_base = true
				_base_color = dup.albedo_color
	_hp = max_hp
	_initial_max_hp = max_hp


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	if _dead:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null(player_path) as Node3D

	_break_cd = maxf(_break_cd - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_flash = maxf(_flash - delta, 0.0)
	if _flash <= 0.0:
		_set_humanoid_color(_base_color)

	velocity.y -= gravity * delta

	if _player:
		_try_damage_player()
		var to_p := _player.global_position - global_position
		to_p.y = 0.0
		if to_p.length_squared() > 0.0001:
			var dir := to_p.normalized()
			var target_xz := dir * move_speed
			velocity.x = lerpf(velocity.x, target_xz.x, 1.0 - exp(-accel * delta))
			velocity.z = lerpf(velocity.z, target_xz.z, 1.0 - exp(-accel * delta))

	move_and_slide()

func _try_damage_player() -> void:
	if _break_cd > 0.0 or _player == null:
		return
	if global_position.distance_squared_to(_player.global_position) > touch_distance * touch_distance:
		return
	if _player.has_method("take_damage"):
		_break_cd = break_cooldown_sec
		_player.call("take_damage", touch_damage)


func _set_humanoid_color(c: Color) -> void:
	var hum := get_node_or_null("Humanoid") as Node3D
	if hum == null:
		return
	for child in hum.get_children():
		if not child is MeshInstance3D:
			continue
		var mi := child as MeshInstance3D
		var mat := mi.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.albedo_color = c


func _resolve_player() -> Node3D:
	if _player != null and is_instance_valid(_player):
		return _player
	_player = get_node_or_null(player_path) as Node3D
	return _player


func _compute_hit_damage_from_player() -> int:
	var p := _resolve_player()
	if p == null:
		return maxi(1, proximity_damage_base)
	var d := global_position.distance_to(p.global_position)
	var near_m := proximity_damage_near_m
	var far_m := proximity_damage_far_m
	if far_m <= near_m:
		far_m = near_m + 0.001
	var t := clampf((far_m - d) / (far_m - near_m), 0.0, 1.0)
	var mult := lerpf(proximity_damage_far_mult, proximity_damage_close_mult, t)
	var raw := float(proximity_damage_base) * mult
	return maxi(1, roundi(raw))


func _take_hit(amount: int = 1) -> void:
	if _dead:
		return
	if _invuln > 0.0:
		return
	if amount < 1:
		amount = 1
	_invuln = damage_invuln_sec
	_flash = hit_flash_sec
	_set_humanoid_color(hit_flash_color)
	_hp -= amount
	if _hp <= 0:
		_die_scatter()


func _sawed_volley_damage_amount() -> int:
	return maxi(1, (_initial_max_hp + sawed_volleys_to_kill - 1) / sawed_volleys_to_kill)


## Залп обреза: фиксированный урон за выстрел (первое попадание куба из залпа), без i-frames.
func _take_sawed_volley_hit(amount: int) -> void:
	if _dead:
		return
	if amount < 1:
		amount = 1
	_flash = hit_flash_sec
	_set_humanoid_color(hit_flash_color)
	_hp -= amount
	if _hp <= 0:
		_die_scatter()


## Стазис: урон без окна неуязвимости и без отсечения по _break_cd (см. _on_break_area_body_entered).
func _take_stasis_hit(amount: int) -> void:
	if _dead:
		return
	if amount < 1:
		amount = 1
	_flash = hit_flash_sec
	_set_humanoid_color(hit_flash_color)
	_hp -= amount
	if _hp <= 0:
		_die_scatter()


func _die_scatter() -> void:
	if _dead:
		return
	_dead = true
	var scene := get_tree().current_scene
	if scene == null:
		queue_free()
		return
	var hum := get_node_or_null("Humanoid") as Node3D
	if hum == null:
		queue_free()
		return
	var mat_col := Color(0.95, 0.32, 0.32, 1.0)
	for child in hum.get_children():
		if not child is MeshInstance3D:
			continue
		var mi := child as MeshInstance3D
		if mi.get_surface_override_material(0) is StandardMaterial3D:
			mat_col = (mi.get_surface_override_material(0) as StandardMaterial3D).albedo_color
			break
	var scr: Script = load("res://throwable_break.gd") as Script
	for child in hum.get_children():
		if not child is MeshInstance3D:
			continue
		var mi := child as MeshInstance3D
		var rb := RigidBody3D.new()
		rb.set_script(scr)
		rb.name = "BrickShard_enemy_%d" % get_instance_id()
		rb.mass = 0.12
		rb.continuous_cd = true
		var mesh_i := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var sz := 0.85
		if mi.mesh is BoxMesh:
			sz = (mi.mesh as BoxMesh).size.x
		bm.size = Vector3(sz, sz, sz)
		mesh_i.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = mat_col
		mesh_i.set_surface_override_material(0, mat)
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(sz, sz, sz)
		col.shape = bs
		rb.add_child(mesh_i)
		rb.add_child(col)
		rb.add_to_group("throwable")
		scene.add_child(rb)
		ThrowablesBudget.track_throwable(rb)
		rb.global_position = mi.global_position
		var away := (mi.global_position - global_position)
		if away.length_squared() < 1e-6:
			away = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
		away = away.normalized()
		rb.linear_velocity = away * death_shard_impulse + Vector3.UP * death_shard_up
		rb.angular_velocity = Vector3(
			randf_range(-8.0, 8.0), randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)
		)
	queue_free()


func _is_stasis_projectile(rb: RigidBody3D) -> bool:
	return rb.is_in_group("stasis_projectile") or rb.name == "StasisRing"


func _on_break_area_body_entered(body: Node) -> void:
	if not body is RigidBody3D:
		return
	var rb := body as RigidBody3D
	if not rb.is_in_group("throwable"):
		return
	var is_stasis_proj := _is_stasis_projectile(rb)
	var is_sawed_cube := rb.name == "Cube" and rb.has_meta("_sawed_volley_id")
	if not is_stasis_proj and not is_sawed_cube and _break_cd > 0.0:
		return

	# Попали кубом в врага — враг разваливается.
	if (
		rb.name == "Cube"
		or rb.name.begins_with("BrickShard")
		or rb.name == "Pyramid"
		or is_stasis_proj
	):
		if not is_stasis_proj and not is_sawed_cube:
			_break_cd = break_cooldown_sec
		# Снаряд НЕ ломаем — только убиваем врага.
		# Можно чуть "отпружинить" куб от врага, чтобы было ощущение удара.
		if is_instance_valid(rb):
			if rb.name == "Pyramid" or is_stasis_proj or is_sawed_cube:
				rb.call_deferred("queue_free")
			var away := (rb.global_position - global_position)
			away.y = 0.0
			if away.length_squared() > 0.0001:
				away = away.normalized()
				rb.apply_central_impulse(away * 1.25)
		if is_stasis_proj:
			_take_stasis_hit(maxi(1, stasis_hit_damage))
		elif is_sawed_cube:
			var svid := int(rb.get_meta("_sawed_volley_id"))
			if svid != _last_sawed_volley_id:
				_last_sawed_volley_id = svid
				_take_sawed_volley_hit(_sawed_volley_damage_amount())
		else:
			var dmg: int = _compute_hit_damage_from_player()
			call_deferred("_take_hit", dmg)
		return

	# Враг ломает твои кубы рядом.
	if _break_cd <= 0.0:
		_break_cd = break_cooldown_sec
		_break_nearby_bricks()


func _break_nearby_bricks() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var r2 := break_radius * break_radius
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var rb := node as RigidBody3D
		if rb.name != "Cube" and not rb.name.begins_with("BrickShard"):
			continue
		if global_position.distance_squared_to(rb.global_position) > r2:
			continue
		if rb.is_in_group("held_throwable"):
			continue
		if rb.has_method("_shatter_and_free"):
			rb.call_deferred("_shatter_and_free")
		else:
			rb.call_deferred("queue_free")
