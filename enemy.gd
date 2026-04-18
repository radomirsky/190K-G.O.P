extends CharacterBody3D
class_name GameEnemy

@export var move_speed: float = 4.2
@export var accel: float = 18.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var player_path: NodePath = NodePath("../Player")
@export_range(0.2, 20.0, 0.05) var size_scale: float = 0.33
## Дополнительный множитель коллизий/дистанций (чтобы "хватать" было проще).
@export_range(0.5, 4.0, 0.05) var collision_scale_mul: float = 1.65
@export var break_cooldown_sec: float = 0.25
@export var break_radius: float = 1.35
@export var touch_damage: int = 8
@export var touch_distance: float = 2.1
@export var attack_cooldown_sec: float = 0.45
@export_range(0.05, 0.8, 0.01) var attack_anim_sec: float = 0.16
@export_range(0.0, 1.0, 0.01) var attack_anim_strength: float = 0.85
## "Видит игрока": дистанция и проверка лучом. Как только увидел один раз — всегда агрится.
@export var vision_range: float = 28.0
@export var vision_ray_height: float = 1.1
@export var vision_requires_line_of_sight: bool = true
@export var death_shard_impulse: float = 8.0
@export var death_shard_up: float = 3.5
@export_range(0, 12, 1) var death_big_shards_max: int = 10
@export_range(0, 12, 1) var death_small_shards_max: int = 0
@export_range(0.2, 4.0, 0.05) var death_big_shard_size_mul: float = 2.15
@export_range(0.2, 2.0, 0.05) var death_small_shard_size_mul: float = 0.55
@export var max_hp: int = 5
## Босс: 10 «полосок» HP (по 1 за попадание), сильный урон в ближнем бою.
@export var is_boss: bool = false
## Стрелок: бегает на расстоянии, уклоняется и стреляет по игроку.
@export var is_ranged: bool = false
@export var ranged_preferred_min_dist: float = 12.0
@export var ranged_preferred_max_dist: float = 20.0
@export var ranged_bullet_damage: int = 4
@export var ranged_fire_cooldown_sec: float = 1.4
@export var ranged_mag_size: int = 6
@export var ranged_reload_sec: float = 2.6
## Уклонение от летящих вражеских снарядов (кубы, пирамида, стазис, обрез и т.д.).
@export var projectile_avoid_radius: float = 7.5
@export_range(0.0, 60.0, 0.5) var projectile_avoid_min_speed: float = 5.0
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
## "Лучший AI": предсказание движения игрока и разбегание врагов, чтобы не толпились в одной точке.
@export_range(0.0, 2.0, 0.01) var chase_prediction_sec: float = 0.35
@export var separation_radius: float = 4.25
@export_range(0.0, 6.0, 0.05) var separation_strength: float = 1.65

var _break_cd: float = 0.0
var _attack_cd: float = 0.0
var _attack_anim: float = 0.0
var _initial_max_hp: int = 5
var _last_sawed_volley_id: int = -1
var _player: Node3D = null
var _dead: bool = false
var _hp: int = 5
var _invuln: float = 0.0
var _flash: float = 0.0
var _base_color: Color = Color(0.22, 0.95, 0.35, 1.0)
var _scale_applied: bool = false
var _thrown_stun: float = 0.0
var _aggro: bool = false
var _ranged_ammo: int = 0
var _ranged_fire_cd: float = 0.0
var _ranged_reload_t: float = 0.0

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
			dup.albedo_color = _base_color
			if not got_base:
				got_base = true
				_base_color = dup.albedo_color
		if is_ranged:
			_apply_ranged_gun_visual(hum)
	_apply_size_scale()
	_hp = max_hp
	_initial_max_hp = max_hp
	_ranged_ammo = ranged_mag_size
	if is_boss:
		add_to_group("boss")
		damage_invuln_sec = 0.0
		var hum_b := get_node_or_null("Humanoid") as Node3D
		if hum_b:
			_apply_boss_sphere_visual(hum_b)


func _apply_size_scale() -> void:
	if _scale_applied:
		return
	_scale_applied = true
	var k := maxf(size_scale, 0.01)
	var ck := k * maxf(collision_scale_mul, 0.01)
	# Визуал.
	var hum := get_node_or_null("Humanoid") as Node3D
	if hum:
		hum.scale *= k
	# Основная коллизия тела: оставляем "как у игрока" (капсула), масштабируем только доп. множителем.
	var body_cs := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if body_cs and body_cs.shape:
		if body_cs.shape is CapsuleShape3D:
			var cs := (body_cs.shape as CapsuleShape3D).duplicate() as CapsuleShape3D
			cs.radius *= maxf(collision_scale_mul, 0.01)
			cs.height *= maxf(collision_scale_mul, 0.01)
			body_cs.shape = cs
	# Сфера попаданий/ломания (BreakArea).
	if _break_area:
		var bcs := _break_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if bcs and bcs.shape:
			if bcs.shape is SphereShape3D:
				var s2 := (bcs.shape as SphereShape3D).duplicate() as SphereShape3D
				s2.radius *= ck
				bcs.shape = s2
			elif bcs.shape is BoxShape3D:
				var b2 := (bcs.shape as BoxShape3D).duplicate() as BoxShape3D
				b2.size *= ck
				bcs.shape = b2
	# Логические дистанции тоже масштабируем, иначе огромный враг "не достаёт".
	break_radius *= ck
	touch_distance *= ck


## Игрок взял и кинул врага: сохраняем импульс и на время отключаем преследование.
func apply_thrown_velocity(v: Vector3, stun_sec: float = 0.6) -> void:
	if _dead:
		return
	_thrown_stun = maxf(_thrown_stun, stun_sec)
	velocity = v


func _apply_boss_sphere_visual(hum: Node3D) -> void:
	var sm := SphereMesh.new()
	sm.radius = 0.42
	sm.height = 0.84
	var got_base := false
	for c in hum.get_children():
		if not c is MeshInstance3D:
			continue
		var mi := c as MeshInstance3D
		mi.mesh = sm
		var m := mi.get_surface_override_material(0) as StandardMaterial3D
		if m == null:
			continue
		m.albedo_color = Color(0.2, 0.04, 0.12)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.5, 0.08)
		m.emission_energy_multiplier = 2.4
		if not got_base:
			_base_color = m.albedo_color
			got_base = true


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	if _dead:
		return
	# Всегда пытаемся резолвить игрока (включая fallback по группе).
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

	velocity.y -= gravity * delta

	_update_attack_anim_visual()

	if _player:
		# Как только "увидели" игрока — сразу агро и погоня/атака.
		if not _aggro and _can_see_player():
			_aggro = true
		if is_ranged:
			_try_ranged_fire()
		else:
			_try_damage_player()
		if _aggro:
			var dir := _compute_move_dir()
			if dir.length_squared() > 0.0001:
				# Всегда движемся относительно игрока (для стрелка — с прицелом на дистанцию и уклонение).
				# После броска лишь чуть "мягче" подруливаем, чтобы полёт/импульс сохранялся.
				var steer := 1.0 - exp(-accel * delta)
				if _thrown_stun > 0.0:
					steer *= 0.18
				var target_xz := dir * move_speed
				velocity.x = lerpf(velocity.x, target_xz.x, steer)
				velocity.z = lerpf(velocity.z, target_xz.z, steer)

	move_and_slide()
	if GameProgress.npc_village_bounds_valid:
		var pushed := GameProgress.push_pos_out_of_npc_village(global_position, 0.45)
		if pushed.distance_squared_to(global_position) > 0.0004:
			global_position = pushed
			velocity.x = 0.0
			velocity.z = 0.0


func _update_attack_anim_visual() -> void:
	var hum := get_node_or_null("Humanoid") as Node3D
	if hum == null:
		return
	if _attack_anim <= 0.0:
		hum.rotation.x = 0.0
		hum.position = Vector3.ZERO
		return
	var t := 1.0 - clampf(_attack_anim / maxf(attack_anim_sec, 0.001), 0.0, 1.0)
	# Делаем "удар": наклон вперёд + лёгкий рывок, с ease-кривой.
	var k := sin(t * PI)
	var str := attack_anim_strength * (1.35 if is_boss else 1.0)
	hum.rotation.x = -0.7 * k * str
	hum.position = Vector3(0.0, 0.0, -0.25 * k * str)


func _can_see_player() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var to_p := _player.global_position - global_position
	to_p.y = 0.0
	if to_p.length_squared() > vision_range * vision_range:
		return false
	if not vision_requires_line_of_sight:
		return true
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * vision_ray_height
	var to := _player.global_position + Vector3.UP * vision_ray_height
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	var col: Object = null
	if hit.has("collider"):
		col = hit["collider"] as Object
	if col == null:
		return true
	# Если по пути первым попался сам игрок/его часть — видим.
	if col is Node:
		var n := col as Node
		while n != null:
			if n == _player:
				return true
			n = n.get_parent()
	return false


func _compute_move_dir() -> Vector3:
	if _player == null or not is_instance_valid(_player):
		return Vector3.ZERO
	var target := _player.global_position
	if chase_prediction_sec > 0.0 and _player is CharacterBody3D:
		target += ( _player as CharacterBody3D ).velocity * chase_prediction_sec
	var to_p := target - global_position
	to_p.y = 0.0
	if to_p.length_squared() < 0.0001:
		return Vector3.ZERO
	var dir := to_p.normalized()

	# Для стрелка приоритет — держать дистанцию и уклоняться от игрока.
	if is_ranged:
		var dist := sqrt(to_p.length_squared())
		# Слишком близко — отступаем назад от игрока.
		if dist < ranged_preferred_min_dist * 0.7:
			dir = -dir
		# Слишком далеко — чуть подбегаем.
		elif dist > ranged_preferred_max_dist * 1.1:
			# dir уже "к игроку".
			pass
		else:
			# В комфортной зоне — двигаемся вбок, как уклонение.
			var side := Vector3(to_p.z, 0.0, -to_p.x).normalized()
			# Чуть рандома, чтобы стрелки не шли все одинаково.
			if randi() & 1:
				side = -side
			dir = side

	# Разбегание от других врагов, чтобы "толпа" лучше обходила игрока и не стопорилась.
	if separation_strength > 0.0 and separation_radius > 0.0:
		var rad := separation_radius * maxf(size_scale, 1.0)
		var rad2 := rad * rad
		var push := Vector3.ZERO
		for node in get_tree().get_nodes_in_group("enemy"):
			if node == self or not (node is Node3D):
				continue
			var e := node as Node3D
			var off := global_position - e.global_position
			off.y = 0.0
			var d2 := off.length_squared()
			if d2 <= 0.0001 or d2 > rad2:
				continue
			var d := sqrt(d2)
			var k := 1.0 - clampf(d / rad, 0.0, 1.0)
			push += (off / d) * k
		if push.length_squared() > 0.0001:
			dir = (dir + push.normalized() * separation_strength).normalized()
	# Уклонение от летящих в нас снарядов игрока.
	dir = _apply_projectile_avoidance(dir)
	return dir


func _apply_projectile_avoidance(base_dir: Vector3) -> Vector3:
	if projectile_avoid_radius <= 0.0:
		return base_dir
	var space_dir := base_dir
	var r2 := projectile_avoid_radius * projectile_avoid_radius
	var avoid := Vector3.ZERO
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var rb := node as RigidBody3D
		if rb.is_in_group("held_throwable"):
			continue
		var to_me := global_position - rb.global_position
		to_me.y = 0.0
		var d2 := to_me.length_squared()
		if d2 <= 0.0004 or d2 > r2:
			continue
		var vel := rb.linear_velocity
		vel.y = 0.0
		var spd := vel.length()
		if spd < projectile_avoid_min_speed:
			continue
		# Снаряд летит примерно в нашу сторону?
		var vdir := vel / spd
		var tdir := to_me / sqrt(d2)
		if vdir.dot(tdir) < 0.6:
			continue
		# Уклоняемся вбок относительно направления снаряда.
		var side := vdir.cross(Vector3.UP)
		if side.length_squared() < 0.0001:
			side = Vector3(tdir.z, 0.0, -tdir.x)
		side = side.normalized()
		# Чем ближе снаряд, тем сильнее от него отходим.
		var k := 1.0 - clampf(sqrt(d2) / projectile_avoid_radius, 0.0, 1.0)
		avoid += side * k
	if avoid.length_squared() <= 0.0001:
		return base_dir
	var dir := (space_dir + avoid.normalized() * 2.0).normalized()
	if dir.length_squared() < 0.0001:
		return base_dir
	return dir


func _apply_ranged_gun_visual(hum: Node3D) -> void:
	var gun := MeshInstance3D.new()
	gun.name = "Gun"
	var m := BoxMesh.new()
	m.size = Vector3(0.22, 0.14, 0.5)
	gun.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.1, 1.0)
	mat.metallic = 0.7
	mat.roughness = 0.22
	mat.emission_enabled = true
	mat.emission = Color(0.16, 0.32, 0.9, 1.0)
	mat.emission_energy_multiplier = 0.8
	gun.set_surface_override_material(0, mat)
	# Простейшее позиционирование «в руке» справа от корпуса.
	gun.position = Vector3(0.65, 1.2, 0.25)
	gun.rotation = Vector3(0.0, PI / 2.0, 0.0)
	hum.add_child(gun)

func _try_damage_player() -> void:
	if _attack_cd > 0.0 or _player == null:
		return
	if global_position.distance_squared_to(_player.global_position) > touch_distance * touch_distance:
		return
	if _player.has_method("take_damage"):
		_attack_cd = attack_cooldown_sec
		_attack_anim = maxf(_attack_anim, attack_anim_sec)
		_player.call("take_damage", touch_damage, "enemy")


func _try_ranged_fire() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _ranged_reload_t > 0.0:
		return
	if _ranged_fire_cd > 0.0:
		return
	if _ranged_ammo <= 0:
		_ranged_reload_t = ranged_reload_sec
		_ranged_ammo = ranged_mag_size
		return
	# Стреляем только когда игрок в поле зрения, на примерно средней дистанции.
	if not _can_see_player():
		return
	var to_p := _player.global_position - global_position
	to_p.y = 0.0
	var d2 := to_p.length_squared()
	if d2 <= 0.01:
		return
	var d := sqrt(d2)
	if d < ranged_preferred_min_dist * 0.65 or d > ranged_preferred_max_dist * 1.35:
		return
	# Имитируем выстрел лучом из центра врага по игроку.
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3(0.0, 1.2, 0.0)
	var to := _player.global_position + Vector3(0.0, 1.0, 0.0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return
	if hit.has("collider"):
		var col := hit["collider"] as Object
		if col is Node:
			var n := col as Node
			while n != null:
				if n == _player and _player.has_method("take_damage"):
					_ranged_fire_cd = ranged_fire_cooldown_sec
					_ranged_ammo -= 1
					_player.call("take_damage", ranged_bullet_damage, "enemy")
					return
				n = n.get_parent()


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
	if _player == null or not is_instance_valid(_player):
		# Fallback: в сцене игрок всегда в группе "player".
		var ps := get_tree().get_nodes_in_group("player")
		if ps.size() > 0 and ps[0] is Node3D:
			_player = ps[0] as Node3D
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


## Попадание катаной: отдельный канал урона ближнего боя от игрока.
func take_katana_hit(damage: int) -> void:
	if _dead:
		return
	if damage < 1:
		damage = 1
	_take_hit(damage)


## Удар с верёвки (игрок притянулся ПКМ+ЛКМ в прыжке).
func take_grapple_punch(damage: int) -> void:
	if _dead:
		return
	if damage < 1:
		damage = 1
	_take_hit(damage)


## Попадание крюком (маленький урон в точку попадания).
func take_grapple_hit(damage: int) -> void:
	if _dead:
		return
	if damage < 1:
		damage = 1
	_take_hit(damage)


## Взрыв чёрной дыры аниматрона: урон по тем же правилам, что и обычное попадание.
func take_blackhole_explosion(damage: int) -> void:
	if _dead:
		return
	if damage < 1:
		damage = 1
	_take_hit(damage)


func take_truck_hit(damage: int) -> void:
	if _dead:
		return
	if damage < 1:
		damage = 1
	if is_boss:
		_take_hit(damage)
		return
	# Обычный враг — наезд грузовика сразу убивает (без окна неуязвимости).
	_take_stasis_hit(_hp)


## Скорострел с фургона: без окна неуязвимости, как стазис.
func take_van_minigun_hit(damage: int) -> void:
	if _dead:
		return
	if damage < 1:
		damage = 1
	_take_stasis_hit(damage)


func take_dynamite_explosion(damage: int) -> void:
	if _dead:
		return
	if damage < 1:
		damage = 1
	_take_stasis_hit(damage)


func _take_hit(amount: int = 1) -> void:
	if _dead:
		return
	if _invuln > 0.0:
		return
	if amount < 1:
		amount = 1
	if is_boss:
		amount = 1
	_invuln = damage_invuln_sec
	_flash = hit_flash_sec
	_set_humanoid_color(hit_flash_color)
	_hp -= amount
	if _hp <= 0:
		_die_scatter()


func _sawed_volley_damage_amount() -> int:
	if is_boss:
		return 1
	return maxi(1, (_initial_max_hp + sawed_volleys_to_kill - 1) / sawed_volleys_to_kill)


## Залп обреза: фиксированный урон за выстрел (первое попадание куба из залпа), без i-frames.
func _take_sawed_volley_hit(amount: int) -> void:
	if _dead:
		return
	if amount < 1:
		amount = 1
	if is_boss:
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
	if is_boss:
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
	if is_boss:
		GameProgress.spawn_boss_mama_drops(global_position)
	else:
		GameProgress.on_regular_enemy_died(global_position)
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
			var st_dmg := maxi(1, stasis_hit_damage + GameProgress.up_stasis_dmg)
			_take_stasis_hit(st_dmg)
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
