extends CharacterBody3D
## Житель: E — квест, пока деревня не в ярости. Убийство жителя или ограбление на глазах у других — все живые жители преследуют игрока с катаной.

@export var npc_index: int = 0
@export var village_id: int = 0
@export var max_hp: int = 14
@export var mob_move_speed: float = 5.1
@export var mob_touch_damage: int = 6
@export var mob_touch_distance: float = 1.82
@export var mob_attack_cooldown_sec: float = 0.5
@export_range(0.08, 0.6, 0.01) var mob_attack_anim_sec: float = 0.26
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var _hp: int = 14
var _dead: bool = false
var _angry: bool = false
var _mob_atk_cd: float = 0.0
var _mob_atk_anim_t: float = 0.0


func _ready() -> void:
	_hp = max_hp
	floor_snap_length = 0.12
	add_to_group("quest_npc")
	add_to_group("talkable_npc")
	add_to_group("village_damageable_npc")
	var lbl := get_node_or_null("Label3D") as Label3D
	if lbl:
		lbl.text = "Житель %d — E" % npc_index


func activate_katana_mob() -> void:
	if _dead or _angry:
		return
	_angry = true
	remove_from_group("talkable_npc")
	add_to_group("village_katana_mob")
	var lbl := get_node_or_null("Label3D") as Label3D
	if lbl:
		lbl.text = "КАТАНА!"
		lbl.modulate = Color(1.0, 0.4, 0.35, 1.0)
	var body := get_node_or_null("BodyMesh") as MeshInstance3D
	if body:
		var m := body.get_surface_override_material(0) as StandardMaterial3D
		if m != null:
			var dup := m.duplicate() as StandardMaterial3D
			dup.emission_enabled = true
			dup.emission = Color(0.85, 0.12, 0.12)
			dup.emission_energy_multiplier = 0.9
			body.set_surface_override_material(0, dup)
	_ensure_mob_katana_mesh()


func _ensure_mob_katana_mesh() -> void:
	if get_node_or_null("MobKatana") != null:
		return
	var root := Node3D.new()
	root.name = "MobKatana"
	root.position = Vector3(0.38, 1.0, 0.12)
	add_child(root)
	var blade := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.06, 0.08, 0.88)
	blade.mesh = box
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.93, 0.93, 1.0, 1.0)
	bmat.metallic = 0.9
	bmat.roughness = 0.2
	blade.set_surface_override_material(0, bmat)
	root.add_child(blade)
	blade.position = Vector3(0.0, 0.0, -0.4)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_mob_atk_cd = maxf(_mob_atk_cd - delta, 0.0)
	var pl := _resolve_player()
	if not _angry:
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y -= gravity * delta
		move_and_slide()
		_update_mob_katana_swing(delta)
		return
	if pl == null:
		velocity.y -= gravity * delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		_update_mob_katana_swing(delta)
		return
	var to_p: Vector3 = pl.global_position - global_position
	to_p.y = 0.0
	var flat_len := to_p.length()
	if flat_len > 0.06:
		to_p /= flat_len
		velocity.x = to_p.x * mob_move_speed
		velocity.z = to_p.z * mob_move_speed
		look_at(global_position + Vector3(to_p.x, 0.0, to_p.z), Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	velocity.y -= gravity * delta
	move_and_slide()
	_try_mob_hit_player(pl)
	_update_mob_katana_swing(delta)


func _update_mob_katana_swing(delta: float) -> void:
	if not _angry:
		return
	var kat := get_node_or_null("MobKatana") as Node3D
	if kat == null:
		return
	if _mob_atk_anim_t <= 0.0:
		kat.rotation_degrees = Vector3.ZERO
		return
	_mob_atk_anim_t = maxf(_mob_atk_anim_t - delta, 0.0)
	var dur := maxf(mob_attack_anim_sec, 0.04)
	var u := 1.0 - (_mob_atk_anim_t / dur)
	var w := sin(u * PI)
	kat.rotation_degrees = Vector3(-58.0 * w, 0.0, -42.0 * w)


func _resolve_player() -> Node3D:
	var ps := get_tree().get_nodes_in_group("player")
	if ps.size() > 0 and ps[0] is Node3D:
		return ps[0] as Node3D
	return null


func _try_mob_hit_player(pl: Node3D) -> void:
	if pl == null or _mob_atk_cd > 0.0:
		return
	var d2 := global_position.distance_squared_to(pl.global_position)
	if d2 > mob_touch_distance * mob_touch_distance:
		return
	if pl.has_method("take_damage"):
		_mob_atk_cd = mob_attack_cooldown_sec
		_mob_atk_anim_t = mob_attack_anim_sec
		pl.call("take_damage", mob_touch_damage, "enemy")


func interact(player: Node) -> void:
	if _dead or _angry:
		return
	if npc_index >= 3:
		CityQuests.on_side_npc_interact(npc_index, player)
	else:
		CityQuests.on_npc_interact(npc_index, player)


func take_katana_hit(damage: int) -> void:
	if _dead:
		return
	var d := maxi(1, damage)
	_hp -= d
	if _hp <= 0:
		_die()


func _die() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("talkable_npc")
	remove_from_group("quest_npc")
	remove_from_group("village_damageable_npc")
	remove_from_group("village_katana_mob")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	set_physics_process(false)
	var body := get_node_or_null("BodyMesh") as MeshInstance3D
	if body:
		body.visible = false
	var lbl := get_node_or_null("Label3D") as Label3D
	if lbl:
		lbl.visible = false
	var kat := get_node_or_null("MobKatana") as Node3D
	if kat:
		kat.visible = false
	CityQuests.on_village_npc_killed(npc_index, village_id)
