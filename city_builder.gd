extends Node3D
## Три деревни на карте: у каждой свои плита/рычаг, внешние ворота (перекрываются рычагом после головоломки) и внутренние ворота.

const QUEST_NPC_SCENE := preload("res://quest_npc.tscn")
const WORLD_SHOP_SCENE := preload("res://world_shop.tscn")
const VILLAGE_BURGLARY_SCRIPT := preload("res://village_house_burglary.gd")
const VILLAGE_LOOT_TRIGGER_SCRIPT := preload("res://village_house_loot_trigger.gd")
const PLATE_SCENE := preload("res://puzzle_pressure_plate.tscn")
const LEVER_SCENE := preload("res://puzzle_lever.tscn")
const OUTER_GATE_SCENE := preload("res://village_outer_gate.tscn")
const INNER_GATE_SCENE := preload("res://village_inner_gate.tscn")

const CELL: float = 9.5

var _village_specs: Array[Dictionary] = []


func _ready() -> void:
	_init_specs()
	for spec in _village_specs:
		_build_village(spec)
	_register_all_village_bounds()


func _init_specs() -> void:
	var side_off: Array[Vector3] = [
		Vector3(-4.2, 0.05, 3.1),
		Vector3(4.5, 0.05, 2.6),
		Vector3(-3.8, 0.05, -2.9),
		Vector3(3.9, 0.05, -3.4),
		Vector3(0.2, 0.05, 5.5),
		Vector3(-6.0, 0.05, 0.4),
		Vector3(6.1, 0.05, -0.8),
		Vector3(1.2, 0.05, -5.2),
	]
	_village_specs = [
		{
			"village_id": 0,
			"grid_origin": Vector3(44.0, 0.0, -80.0),
			"grid_w": 5,
			"grid_h": 6,
			"plaza_cell": Vector2i(2, 2),
			"gap_cx_bias": 2.0,
			"plate_key": "suburbs_plate",
			"lever_key": "suburbs_lever",
			"plate_extra": PackedStringArray(["village_entry_unlocked"]),
			"gate_need": ["suburbs_plate", "suburbs_lever"],
			"outer_closed_key": "village_outer_closed",
			"inner_key": "village_inner_gate_closed",
			"label": "ДЕРЕВНЯ I\nплощадь · лавка",
			"has_shop": true,
			"npc_mains": [
				Vector3(-6.2, 0.05, -5.0),
				Vector3(6.0, 0.05, -4.5),
				Vector3(-0.5, 0.05, 6.2),
			],
			"npc_main_idx": [0, 1, 2],
			"npc_side0": 3,
			"side_off": side_off,
			"roads":
			[
				{"pos": Vector3(14.0, 0.08, -18.0), "size": Vector3(32.0, 0.18, 16.0)},
				{"pos": Vector3(46.0, 0.08, -36.0), "size": Vector3(48.0, 0.18, 28.0)},
			],
		},
		{
			"village_id": 1,
			"grid_origin": Vector3(-82.0, 0.0, -58.0),
			"grid_w": 4,
			"grid_h": 5,
			"plaza_cell": Vector2i(1, 2),
			"gap_cx_bias": 0.0,
			"plate_key": "village_west_plate",
			"lever_key": "village_west_lever",
			"plate_extra": PackedStringArray(),
			"gate_need": ["village_west_plate", "village_west_lever"],
			"outer_closed_key": "village_west_outer_closed",
			"inner_key": "village_west_inner_closed",
			"label": "ДЕРЕВНЯ II\nзапад",
			"has_shop": false,
			"npc_mains": [],
			"npc_main_idx": [],
			"npc_side0": 11,
			"side_off": side_off,
			"roads":
			[
				{"pos": Vector3(-48.0, 0.08, -24.0), "size": Vector3(52.0, 0.18, 18.0)},
				{"pos": Vector3(-68.0, 0.08, -38.0), "size": Vector3(22.0, 0.18, 32.0)},
			],
		},
		{
			"village_id": 2,
			"grid_origin": Vector3(62.0, 0.0, -132.0),
			"grid_w": 5,
			"grid_h": 5,
			"plaza_cell": Vector2i(2, 2),
			"gap_cx_bias": 1.0,
			"plate_key": "village_far_plate",
			"lever_key": "village_far_lever",
			"plate_extra": PackedStringArray(),
			"gate_need": ["village_far_plate", "village_far_lever"],
			"outer_closed_key": "village_far_outer_closed",
			"inner_key": "village_far_inner_closed",
			"label": "ДЕРЕВНЯ III\nсевер",
			"has_shop": false,
			"npc_mains": [],
			"npc_main_idx": [],
			"npc_side0": 19,
			"side_off": side_off,
			"roads":
			[
				{"pos": Vector3(56.0, 0.08, -88.0), "size": Vector3(36.0, 0.18, 22.0)},
				{"pos": Vector3(72.0, 0.08, -112.0), "size": Vector3(28.0, 0.18, 36.0)},
			],
		},
	]


func _layout(spec: Dictionary) -> Dictionary:
	var gw: int = spec["grid_w"]
	var gh: int = spec["grid_h"]
	var go: Vector3 = spec["grid_origin"]
	var total_x := float(gw) * CELL
	var total_z := float(gh) * CELL
	var x0 := go.x - 1.0
	var x1 := go.x + total_x + 1.0
	var z0 := go.z - 1.0
	var z1 := go.z + total_z + 1.0
	var h := 4.0
	var t := 0.55
	var bias: float = float(spec.get("gap_cx_bias", 0.0))
	var gap_cx := (x0 + x1) * 0.5 + bias
	var gap_w := 6.2
	var xmin := gap_cx - gap_w * 0.5
	var xmax := gap_cx + gap_w * 0.5
	return {
		"x0": x0,
		"x1": x1,
		"z0": z0,
		"z1": z1,
		"h": h,
		"t": t,
		"gap_cx": gap_cx,
		"gap_w": gap_w,
		"xmin": xmin,
		"xmax": xmax,
	}


func _plaza_center(spec: Dictionary) -> Vector3:
	var pc: Vector2i = spec["plaza_cell"]
	var go: Vector3 = spec["grid_origin"]
	return go + Vector3((float(pc.x) + 0.5) * CELL, 0.12, (float(pc.y) + 0.5) * CELL)


func _wall_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.4, 0.38, 0.36, 1)
	m.roughness = 0.9
	return m


func _plaza_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.31, 0.34, 1)
	m.roughness = 0.92
	return m


func _house_mat(rng: RandomNumberGenerator) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.65 + rng.randf() * 0.12, 0.52, 0.42, 1)
	m.roughness = 0.88
	return m


func _roof_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.36, 0.2, 0.16, 1)
	m.roughness = 0.85
	return m


func _add_box_static(name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.name = name
	add_child(body)
	body.position = pos
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)
	body.add_child(mi)
	var sh := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	sh.shape = box
	body.add_child(sh)


func _map_label_3d(text: String, world_pos: Vector3) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 19
	l.outline_size = 7
	l.outline_modulate = Color(0.02, 0.02, 0.05, 0.9)
	l.modulate = Color(1.0, 0.94, 0.78, 1.0)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(l)
	l.global_position = world_pos


func _register_all_village_bounds() -> void:
	var pad := 5.0
	for spec in _village_specs:
		var go: Vector3 = spec["grid_origin"]
		var gw: int = spec["grid_w"]
		var gh: int = spec["grid_h"]
		var min_x := go.x - pad
		var max_x := go.x + float(gw) * CELL + pad
		var min_z := go.z - pad
		var max_z := go.z + float(gh) * CELL + pad
		GameProgress.expand_npc_village_xz(min_x, max_x, min_z, max_z)
	# Дороги и старый коридор к I деревне.
	GameProgress.expand_npc_village_xz(-95.0, 92.0, -145.0, -4.0)


func _build_village(spec: Dictionary) -> void:
	var lay := _layout(spec)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(spec["village_id"]) + 202504
	var wm := _wall_mat()
	var x0: float = lay["x0"]
	var x1: float = lay["x1"]
	var z0: float = lay["z0"]
	var z1: float = lay["z1"]
	var h: float = lay["h"]
	var t: float = lay["t"]
	var gap_cx: float = lay["gap_cx"]
	var xmin: float = lay["xmin"]
	var xmax: float = lay["xmax"]
	var z_inner: float = z1 - 4.2
	_add_box_static(
		"VwN_%d" % spec["village_id"],
		Vector3((x0 + x1) * 0.5, h * 0.5, z0 - t * 0.5),
		Vector3(x1 - x0 + 2.0 * t, h, t),
		wm
	)
	_add_box_static(
		"VwW_%d" % spec["village_id"],
		Vector3(x0 - t * 0.5, h * 0.5, (z0 + z1) * 0.5),
		Vector3(t, h, z1 - z0 + 2.0 * t),
		wm
	)
	_add_box_static(
		"VwE_%d" % spec["village_id"],
		Vector3(x1 + t * 0.5, h * 0.5, (z0 + z1) * 0.5),
		Vector3(t, h, z1 - z0 + 2.0 * t),
		wm
	)
	var w_left := xmin - x0
	if w_left > 0.8:
		_add_box_static(
			"VwSL_%d" % spec["village_id"],
			Vector3(x0 + w_left * 0.5, h * 0.5, z1 + t * 0.5),
			Vector3(w_left, h, t),
			wm
		)
	var w_right := x1 - xmax
	if w_right > 0.8:
		_add_box_static(
			"VwSR_%d" % spec["village_id"],
			Vector3(xmax + w_right * 0.5, h * 0.5, z1 + t * 0.5),
			Vector3(w_right, h, t),
			wm
		)
	_add_box_static(
		"VPostL_%d" % spec["village_id"],
		Vector3(xmin - 0.48, h * 0.55, z1 + t * 0.5),
		Vector3(0.82, h * 1.12, 0.82),
		wm
	)
	_add_box_static(
		"VPostR_%d" % spec["village_id"],
		Vector3(xmax + 0.48, h * 0.55, z1 + t * 0.5),
		Vector3(0.82, h * 1.12, 0.82),
		wm
	)
	var beam_w := xmax - xmin + 1.2
	_add_box_static(
		"VLint_%d" % spec["village_id"],
		Vector3((xmin + xmax) * 0.5, h * 1.12 + 0.35, z1 + t * 0.5),
		Vector3(beam_w, 0.55, 0.75),
		wm
	)

	var plate_key: String = spec["plate_key"]
	var lever_key: String = spec["lever_key"]
	var plate_extra: PackedStringArray = spec["plate_extra"]
	var gate_need: Array = spec["gate_need"]
	var outer_key: String = spec["outer_closed_key"]
	var inner_key: String = spec["inner_key"]

	var plate := PLATE_SCENE.instantiate() as Area3D
	if plate:
		plate.flag_key = plate_key
		plate.extra_flag_keys = plate_extra
		add_child(plate)
		plate.global_position = Vector3(gap_cx, 0.12, z1 + t + 2.75)
		var plbl := Label3D.new()
		plbl.text = "ПЛИТА\n(шагни)"
		plbl.font_size = 20
		plbl.outline_size = 7
		plbl.position = Vector3(0.0, 0.72, 0.0)
		plbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		plate.add_child(plbl)

	var outer := OUTER_GATE_SCENE.instantiate() as StaticBody3D
	if outer:
		var need_arr: Array = []
		for f in gate_need:
			need_arr.append(str(f))
		outer.need_flags = need_arr
		outer.closed_toggle_flag = outer_key
		add_child(outer)
		outer.global_position = Vector3(gap_cx, 0.0, z1 + t * 0.5)

	var lever_out := LEVER_SCENE.instantiate() as StaticBody3D
	if lever_out:
		lever_out.flag_key = lever_key
		lever_out.one_shot = true
		add_child(lever_out)
		lever_out.global_position = Vector3(gap_cx + 5.5, 0.05, z1 + t + 1.15)

	var lever_outer_toggle := LEVER_SCENE.instantiate() as StaticBody3D
	if lever_outer_toggle:
		lever_outer_toggle.flag_key = outer_key
		lever_outer_toggle.one_shot = false
		lever_outer_toggle.toggle_flag_on_interact = true
		lever_outer_toggle.banner_text_when_flag_on = "Внешние ворота закрыты."
		lever_outer_toggle.banner_text_when_flag_off = "Внешние ворота открыты."
		add_child(lever_outer_toggle)
		# Внутри деревни, севернее внутренних ворот (к площади).
		lever_outer_toggle.global_position = Vector3(gap_cx + 3.0, 0.05, z_inner - 2.6)
		var olbl := lever_outer_toggle.get_node_or_null("Label3D") as Label3D
		if olbl:
			olbl.text = "Внешние ворота — E\n(в деревне)"

	var inner := INNER_GATE_SCENE.instantiate() as StaticBody3D
	if inner:
		inner.flag_key = inner_key
		add_child(inner)
		inner.global_position = Vector3(gap_cx, 0.0, z_inner)

	var lever_in := LEVER_SCENE.instantiate() as StaticBody3D
	if lever_in:
		lever_in.flag_key = inner_key
		lever_in.one_shot = false
		lever_in.toggle_flag_on_interact = true
		lever_in.banner_text_when_flag_on = "Внутренние ворота закрыты."
		lever_in.banner_text_when_flag_off = "Внутренние ворота открыты."
		add_child(lever_in)
		lever_in.global_position = Vector3(gap_cx + 3.2, 0.05, z_inner - 1.1)
		var lbl := lever_in.get_node_or_null("Label3D") as Label3D
		if lbl:
			lbl.text = "Рычаг внутренних ворот — E"

	var rid := 0
	for rd in spec.get("roads", []):
		_add_box_static("Road_%d_%d" % [spec["village_id"], rid], rd["pos"], rd["size"], _plaza_mat())
		rid += 1

	var gw: int = spec["grid_w"]
	var gh: int = spec["grid_h"]
	var go: Vector3 = spec["grid_origin"]
	var total_x := float(gw) * CELL
	var total_z := float(gh) * CELL
	var mid := go + Vector3(total_x * 0.5, 0.0, total_z * 0.5)
	_add_box_static("Plaza_%d" % spec["village_id"], mid + Vector3(0.0, 0.1, 0.0), Vector3(total_x + 3.0, 0.22, total_z + 3.0), _plaza_mat())

	var plaza_cell: Vector2i = spec["plaza_cell"]
	for gx in range(gw):
		for gz in range(gh):
			if gx == plaza_cell.x and gz == plaza_cell.y:
				continue
			var cell_c := go + Vector3((float(gx) + 0.5) * CELL, 0.0, (float(gz) + 0.5) * CELL)
			var hw := CELL * (0.34 + rng.randf() * 0.06)
			var hd := CELL * (0.34 + rng.randf() * 0.06)
			var hh := 2.2 + rng.randf() * 1.6
			_add_box_static(
				"H_%d_%d_%d" % [spec["village_id"], gx, gz],
				cell_c + Vector3(0.0, hh * 0.5 + 0.12, 0.0),
				Vector3(hw, hh, hd),
				_house_mat(rng)
			)
			var rh := 0.32
			_add_box_static(
				"R_%d_%d_%d" % [spec["village_id"], gx, gz],
				cell_c + Vector3(0.0, hh + rh * 0.5 + 0.18, 0.0),
				Vector3(hw * 1.06, rh, hd * 1.06),
				_roof_mat()
			)
			_add_house_loot_door(cell_c, hw, hd, hh, gx, gz, spec["village_id"])

	var plaza := _plaza_center(spec)
	_map_label_3d(spec["label"], plaza + Vector3(0.0, 16.5, 0.0))
	_map_label_3d("ВНЕШН. ВОРОТА", Vector3(gap_cx, 11.0, z1 + t * 0.5))
	_map_label_3d("ПЛИТА", Vector3(gap_cx, 9.5, z1 + t + 2.75))
	_map_label_3d("РЫЧАГ\nвход", Vector3(gap_cx + 5.5, 9.5, z1 + t + 1.15))
	_map_label_3d("ВНУТР. ВОРОТА", Vector3(gap_cx, 10.5, z_inner))
	_map_label_3d("РЫЧАГ\nвнешн. вор.", Vector3(gap_cx + 3.0, 9.5, z_inner - 2.6))
	_map_label_3d("РЫЧАГ\nвнутри", Vector3(gap_cx + 3.2, 9.5, z_inner - 1.1))

	if bool(spec.get("has_shop", false)):
		var shop := WORLD_SHOP_SCENE.instantiate() as Node3D
		if shop:
			add_child(shop)
			shop.global_position = plaza
			shop.rotation_degrees = Vector3(0.0, 20.0, 0.0)
			GameProgress.register_market_pos(plaza)

	var vid: int = spec["village_id"]
	var mains: Array = spec["npc_mains"]
	var main_idx: Array = spec["npc_main_idx"]
	for i in range(mains.size()):
		var npc := QUEST_NPC_SCENE.instantiate() as CharacterBody3D
		if npc == null:
			continue
		npc.npc_index = int(main_idx[i])
		npc.village_id = vid
		add_child(npc)
		npc.global_position = plaza + mains[i]

	var s0: int = int(spec["npc_side0"])
	var offs: Array = spec["side_off"]
	for j in range(offs.size()):
		var sn := QUEST_NPC_SCENE.instantiate() as CharacterBody3D
		if sn == null:
			continue
		sn.npc_index = s0 + j
		sn.village_id = vid
		add_child(sn)
		sn.global_position = plaza + offs[j]


func _add_house_loot_door(
	cell_c: Vector3, hw: float, hd: float, hh: float, gx: int, gz: int, village_id: int
) -> void:
	var root := Node3D.new()
	root.name = "HouseLoot_%d_%d_%d" % [village_id, gx, gz]
	root.set_script(VILLAGE_BURGLARY_SCRIPT)
	root.house_id = "%d_%d_%d" % [village_id, gx, gz]
	root.village_id = village_id
	add_child(root)
	root.global_position = cell_c

	var area := Area3D.new()
	area.name = "InteriorArea"
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitorable = false
	var a_sh := CollisionShape3D.new()
	var a_box := BoxShape3D.new()
	var ah := clampf(hh * 0.88, 1.85, 3.0)
	a_box.size = Vector3(maxf(hw * 0.92, 1.2), ah, maxf(hd * 0.5, 1.05))
	a_sh.shape = a_box
	a_sh.position = Vector3(0.0, a_box.size.y * 0.5 + 0.04, hd * 0.16)
	area.add_child(a_sh)
	root.add_child(area)

	var loot := StaticBody3D.new()
	loot.name = "LootChest"
	loot.set_script(VILLAGE_LOOT_TRIGGER_SCRIPT)
	loot.collision_layer = 1
	loot.collision_mask = 1
	var l_sh := CollisionShape3D.new()
	var l_box := BoxShape3D.new()
	l_box.size = Vector3(0.88, 0.52, 0.52)
	l_sh.shape = l_box
	l_sh.position = Vector3(0.0, 0.32, 0.0)
	loot.add_child(l_sh)
	var chest := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.82, 0.48, 0.48)
	chest.mesh = cm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.4, 0.24, 0.14, 1)
	chest.set_surface_override_material(0, cmat)
	chest.position = Vector3(0.0, 0.3, 0.0)
	loot.add_child(chest)
	root.add_child(loot)
	loot.position = Vector3(0.0, 0.04, hd * 0.36)

	var tag := Label3D.new()
	tag.text = "Ящик — E"
	tag.font_size = 15
	tag.outline_size = 6
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = loot.position + Vector3(0.0, 1.12, 0.0)
	root.add_child(tag)
