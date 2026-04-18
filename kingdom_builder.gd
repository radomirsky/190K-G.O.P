extends Node3D
## Замок: король (корона), стража (броня + катана), три рычага-головоломки и бонусные рычаги на карте.

const LEVER_SCENE := preload("res://puzzle_lever.tscn")
const KING_SCRIPT := preload("res://castle_king.gd")
const GUARD_SCRIPT := preload("res://castle_guard.gd")

## Центр двора замка (мировые координаты).
@export var courtyard_origin: Vector3 = Vector3(108.0, 0.0, -28.0)


func _ready() -> void:
	_build_courtyard()
	_build_perimeter()
	_build_keep()
	_build_throne()
	_spawn_king()
	_spawn_guards()
	_spawn_king_puzzles()
	_spawn_world_bonus_puzzles()
	_add_labels()


func _stone_mat(light: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.52, 0.5, 0.48, 1) if light else Color(0.38, 0.36, 0.4, 1)
	m.roughness = 0.88
	return m


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, with_col: bool = true) -> void:
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.position = pos
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)
	body.add_child(mi)
	if with_col:
		var sh := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		sh.shape = box
		body.add_child(sh)


func _build_courtyard() -> void:
	var root := courtyard_origin
	_add_box(self, root + Vector3(0.0, 0.08, 0.0), Vector3(44.0, 0.2, 38.0), _stone_mat(true))


func _build_perimeter() -> void:
	var c := courtyard_origin
	var hx := 22.0
	var hz := 19.0
	var h := 5.5
	var t := 0.65
	var y := h * 0.5
	var m := _stone_mat(false)
	_add_box(self, c + Vector3(0.0, y, -hz - t * 0.5), Vector3(hx * 2.0 + 2.0 * t, h, t), m)
	_add_box(self, c + Vector3(0.0, y, hz + t * 0.5), Vector3(hx * 2.0 + 2.0 * t, h, t), m)
	# Западная стена — проход к королевству (со стороны арены, −X).
	var depth: float = hz * 2.0 + 2.0 * t
	var passage_w: float = 9.0
	var seg_z: float = (depth - passage_w) * 0.5
	var wx: float = c.x - hx - t * 0.5
	var z_n: float = c.z - (depth + passage_w) * 0.25
	var z_s: float = c.z + (depth + passage_w) * 0.25
	_add_box(self, Vector3(wx, y, z_n), Vector3(t, h, seg_z), m)
	_add_box(self, Vector3(wx, y, z_s), Vector3(t, h, seg_z), m)
	_add_box(self, c + Vector3(hx + t * 0.5, y, 0.0), Vector3(t, h, depth), m)
	# Подъезд к воротам (к проходу в западной стене).
	var road_m := _stone_mat(true)
	road_m.albedo_color = Color(0.34, 0.33, 0.36, 1)
	_add_box(self, c + Vector3(-hx - 18.0, 0.09, 0.0), Vector3(52.0, 0.2, 14.0), road_m)


func _keep_center() -> Vector3:
	return courtyard_origin + Vector3(0.0, 0.0, -4.0)


## Донжон с проходом: король внутри башни.
func _build_keep() -> void:
	var kc := _keep_center()
	var m := _stone_mat(false)
	var m2 := _stone_mat(true)
	var h := 4.85
	var t := 0.55
	var y := h * 0.5
	var w := 17.0
	var d := 13.0
	_add_box(self, kc + Vector3(0.0, 0.12, 0.0), Vector3(w, 0.24, d), m2)
	_add_box(self, kc + Vector3(0.0, y, -d * 0.5 - t * 0.5), Vector3(w + t, h, t), m)
	var gap := 5.5
	var side_w := (w - gap) * 0.5
	_add_box(
		self,
		kc + Vector3(-gap * 0.25 - side_w * 0.5, y, d * 0.5 + t * 0.5),
		Vector3(side_w, h, t),
		m
	)
	_add_box(
		self,
		kc + Vector3(gap * 0.25 + side_w * 0.5, y, d * 0.5 + t * 0.5),
		Vector3(side_w, h, t),
		m
	)
	_add_box(self, kc + Vector3(w * 0.5 + t * 0.5, y, 0.0), Vector3(t, h, d + 2.0 * t), m)
	_add_box(self, kc + Vector3(-w * 0.5 - t * 0.5, y, 0.0), Vector3(t, h, d + 2.0 * t), m)
	var th := 10.8
	var ty := th * 0.5 + 0.26
	var tz := -5.28
	var tw := 7.4
	var tdepth := 4.4
	var aisle := 4.0
	var pillar_w := (tw - aisle) * 0.5
	_add_box(
		self,
		kc + Vector3(-aisle * 0.25 - pillar_w * 0.5, ty, tz),
		Vector3(pillar_w, th, tdepth),
		m
	)
	_add_box(
		self,
		kc + Vector3(aisle * 0.25 + pillar_w * 0.5, ty, tz),
		Vector3(pillar_w, th, tdepth),
		m
	)
	_add_box(self, kc + Vector3(0.0, ty, tz - tdepth * 0.5 - 0.55), Vector3(tw, th, 1.15), m)


func _build_throne() -> void:
	var kc := _keep_center()
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.72, 0.58, 0.22, 1)
	gold.metallic = 0.55
	gold.roughness = 0.42
	var base := kc + Vector3(0.0, 0.0, -4.35)
	_add_box(self, base + Vector3(0.0, 0.38, 0.0), Vector3(1.85, 0.45, 1.45), gold, false)
	_add_box(self, base + Vector3(0.0, 1.12, -0.68), Vector3(1.95, 1.5, 0.42), gold, false)
	var arm := StandardMaterial3D.new()
	arm.albedo_color = Color(0.55, 0.42, 0.18, 1)
	arm.metallic = 0.5
	_add_box(self, base + Vector3(-0.95, 0.62, 0.05), Vector3(0.35, 0.35, 1.15), arm, false)
	_add_box(self, base + Vector3(0.95, 0.62, 0.05), Vector3(0.35, 0.35, 1.15), arm, false)


func _spawn_king() -> void:
	var k := StaticBody3D.new()
	k.name = "King"
	k.set_script(KING_SCRIPT)
	k.collision_layer = 1
	k.collision_mask = 1
	var shp := CapsuleShape3D.new()
	shp.radius = 0.36
	shp.height = 1.05
	var cs := CollisionShape3D.new()
	cs.shape = shp
	cs.position = Vector3(0.0, 0.58, 0.12)
	k.add_child(cs)
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.33
	cm.height = 1.05
	body.mesh = cm
	var robe := StandardMaterial3D.new()
	robe.albedo_color = Color(0.75, 0.2, 0.25, 1)
	robe.roughness = 0.65
	body.set_surface_override_material(0, robe)
	body.position = Vector3(0.0, 0.58, 0.1)
	body.rotation_degrees = Vector3(-22.0, 0.0, 0.0)
	k.add_child(body)
	var crown := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.14
	tor.outer_radius = 0.22
	crown.mesh = tor
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.95, 0.82, 0.25, 1)
	gold.metallic = 0.92
	gold.roughness = 0.22
	crown.set_surface_override_material(0, gold)
	crown.position = Vector3(0.0, 1.12, 0.02)
	crown.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	k.add_child(crown)
	var lbl := Label3D.new()
	lbl.text = "Король — E\n(задания)"
	lbl.font_size = 22
	lbl.outline_size = 7
	lbl.position = Vector3(0.0, 1.65, 0.0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	k.add_child(lbl)
	add_child(k)
	var kc := _keep_center()
	k.global_position = kc + Vector3(0.0, 0.52, -4.32)
	k.rotation_degrees.y = 180.0


func _spawn_guards() -> void:
	var kc := _keep_center()
	var spots: Array[Vector3] = [
		kc + Vector3(-3.9, 0.05, 7.45),
		kc + Vector3(3.9, 0.05, 7.45),
		courtyard_origin + Vector3(-11.5, 0.05, 10.5),
		courtyard_origin + Vector3(11.5, 0.05, 10.5),
	]
	var yaws := [185.0, 175.0, 25.0, -25.0]
	for i in range(spots.size()):
		_spawn_guard_at(spots[i], yaws[i])


func _spawn_guard_at(pos: Vector3, yaw_deg: float) -> void:
	var g := CharacterBody3D.new()
	g.set_script(GUARD_SCRIPT)
	g.collision_layer = 1
	g.collision_mask = 1
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34
	cap.height = 1.42
	var cs := CollisionShape3D.new()
	cs.shape = cap
	cs.position = Vector3(0.0, 0.72, 0.0)
	g.add_child(cs)
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.31
	cm.height = 1.38
	body.mesh = cm
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.55, 0.48, 0.44, 1)
	body.set_surface_override_material(0, skin)
	body.position = Vector3(0.0, 0.72, 0.0)
	g.add_child(body)
	var chest := MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = Vector3(0.52, 0.42, 0.26)
	chest.mesh = bx
	var arm := StandardMaterial3D.new()
	arm.albedo_color = Color(0.22, 0.26, 0.34, 1)
	arm.metallic = 0.75
	arm.roughness = 0.32
	chest.set_surface_override_material(0, arm)
	chest.position = Vector3(0.0, 1.02, 0.02)
	g.add_child(chest)
	var helm := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.22
	hm.height = 0.44
	helm.mesh = hm
	var hm_mat := StandardMaterial3D.new()
	hm_mat.albedo_color = Color(0.3, 0.32, 0.38, 1)
	hm_mat.metallic = 0.8
	helm.set_surface_override_material(0, hm_mat)
	helm.position = Vector3(0.0, 1.38, 0.0)
	g.add_child(helm)
	var kat := Node3D.new()
	kat.position = Vector3(0.36, 0.92, 0.08)
	g.add_child(kat)
	var blade := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(0.05, 0.07, 0.78)
	blade.mesh = bmesh
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.92, 0.92, 1.0, 1)
	bmat.metallic = 0.88
	blade.set_surface_override_material(0, bmat)
	blade.position = Vector3(0.0, 0.0, -0.34)
	kat.add_child(blade)
	add_child(g)
	g.global_position = pos
	g.rotation_degrees.y = yaw_deg


func _spawn_king_puzzles() -> void:
	var c := courtyard_origin
	var specs: Array[Dictionary] = [
		{"key": "king_puzzle_altar", "pos": c + Vector3(-14.0, 0.05, -12.0), "txt": "Алтарь — E"},
		{"key": "king_puzzle_bastion", "pos": c + Vector3(14.0, 0.05, -12.0), "txt": "Бастион — E"},
		{"key": "king_puzzle_garden", "pos": c + Vector3(0.0, 0.05, -15.0), "txt": "Сад — E"},
	]
	for s in specs:
		var lv := LEVER_SCENE.instantiate() as StaticBody3D
		if lv == null:
			continue
		lv.flag_key = str(s["key"])
		lv.one_shot = true
		lv.banner_text_when_flag_on = "Загадка решена."
		add_child(lv)
		lv.global_position = s["pos"]
		var lb := lv.get_node_or_null("Label3D") as Label3D
		if lb:
			lb.text = str(s["txt"])


func _spawn_world_bonus_puzzles() -> void:
	var bonus: Array[Dictionary] = [
		{
			"key": "world_bonus_watchtower",
			"pos": Vector3(28.0, 0.05, 12.0),
			"mama": 5,
			"hint": "Дозор — E"
		},
		{
			"key": "world_bonus_ruins",
			"pos": Vector3(-52.0, 0.05, 8.0),
			"mama": 5,
			"hint": "Руины — E"
		},
		{
			"key": "world_bonus_shrine",
			"pos": Vector3(18.0, 0.05, -52.0),
			"mama": 4,
			"hint": "Капище — E"
		},
	]
	for b in bonus:
		var lv2 := LEVER_SCENE.instantiate() as StaticBody3D
		if lv2 == null:
			continue
		lv2.flag_key = str(b["key"])
		lv2.one_shot = true
		lv2.mama_reward_on_first_pull = int(b["mama"])
		lv2.banner_text_when_flag_on = "Тайна открыта — МАМА в казне."
		add_child(lv2)
		lv2.global_position = b["pos"]
		var lb2 := lv2.get_node_or_null("Label3D") as Label3D
		if lb2:
			lb2.text = str(b["hint"])


func _add_labels() -> void:
	var l := Label3D.new()
	l.text = "КОРОЛЕВСТВО\nзамок · трон"
	l.font_size = 26
	l.outline_size = 8
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.global_position = courtyard_origin + Vector3(0.0, 14.0, 0.0)
	add_child(l)
	var gate_l := Label3D.new()
	gate_l.text = "ПРОХОД\nв королевство"
	gate_l.font_size = 20
	gate_l.outline_size = 7
	gate_l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	gate_l.global_position = courtyard_origin + Vector3(-22.0 - 12.0, 8.5, 0.0)
	add_child(gate_l)
	GameProgress.expand_npc_village_xz(
		courtyard_origin.x - 52.0,
		courtyard_origin.x + 28.0,
		courtyard_origin.z - 24.0,
		courtyard_origin.z + 24.0
	)
