extends GameEnemy
## Секретный финал: плоский «квадрат» с сегодняшней датой на табличке.

func _ready() -> void:
	is_boss = true
	max_hp = 26
	touch_damage = 24
	move_speed = 2.85
	vision_requires_line_of_sight = false
	vision_range = 160.0
	size_scale = 0.92
	collision_scale_mul = 2.05
	super._ready()
	add_to_group("secret_big_king")
	call_deferred("_apply_big_king_square_visual")


func _apply_big_king_square_visual() -> void:
	var hum := get_node_or_null("Humanoid") as Node3D
	if hum == null:
		return
	for i in range(hum.get_child_count() - 1, -1, -1):
		var ch := hum.get_child(i)
		hum.remove_child(ch)
		ch.free()
	var slab := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.45, 0.2, 2.45)
	slab.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.62, 0.14, 1)
	mat.metallic = 0.5
	mat.roughness = 0.38
	slab.set_surface_override_material(0, mat)
	hum.add_child(slab)
	var dt := Time.get_datetime_dict_from_system()
	var date_txt := "%02d.%02d.%04d" % [int(dt.day), int(dt.month), int(dt.year)]
	var title := Label3D.new()
	title.text = "БОЛЬШОЙ КОРОЛЬ\n%s" % date_txt
	title.font_size = 22
	title.outline_size = 9
	title.position = Vector3(0, 0.42, 1.28)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hum.add_child(title)
	_base_color = mat.albedo_color


func _die_scatter() -> void:
	if _dead:
		return
	_dead = true
	KingQuests.on_secret_big_king_defeated()
	queue_free()
