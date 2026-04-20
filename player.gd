extends CharacterBody3D

enum EquippedGun { NONE, PYRAMID, STASIS, SAWED_OFF, ANIMATRON, KATANA, CREATIVE_WAND, CYBER_CANNON }
enum GrappleState { INACTIVE, ROPE_READY, PULLING }
enum ViewMode { FIRST, SECOND, THIRD }
enum CharacterKind { HERO, COWBOY, CYBER }

const THROWABLE_CUBE_SCENE := preload("res://throwable_cube.tscn")
const THROWABLE_PYRAMID_SCENE := preload("res://throwable_pyramid.tscn")
const THROWABLE_STASIS_RING_SCENE := preload("res://throwable_stasis_ring.tscn")
const DYNAMITE_SCENE := preload("res://dynamite.tscn")
const ANIMATRON_BLACKHOLE_SCENE := preload("res://animatron_blackhole.tscn")
const DRIVABLE_HORSE_SCENE := preload("res://drivable_horse.tscn")
const DRIVABLE_FLYCAR_SCENE := preload("res://drivable_flycar.tscn")
const PAUSE_MENU_OVERLAY := preload("res://pause_menu_overlay.gd")
const THROWABLE_COLOR_FREE := Color(0.45, 0.65, 0.95, 1.0)
const THROWABLE_COLOR_FIXED := Color(0.28, 0.72, 0.38, 1.0)
const THROWABLE_COLOR_ENLARGE_HINT := Color(1.0, 0.9, 0.18, 1.0)
const _GUN_MODEL_LOCAL_POS := Vector3(0.25, -0.22, -0.55)
const _STASIS_GUN_LOCAL_POS := Vector3(-0.28, -0.2, -0.52)
const _SAWED_GUN_LOCAL_POS := Vector3(0.22, -0.21, -0.48)
const _ANIMATRON_MODEL_LOCAL_POS := Vector3(-0.02, -0.23, -0.62)
const _CREATIVE_WAND_LOCAL_POS := Vector3(0.34, -0.19, -0.58)
const _HUMANOID_CUBE_LOCAL: Array[Vector3] = [
	Vector3(-0.35, 0.5, 0),
	Vector3(0.35, 0.5, 0),
	Vector3(-0.35, 1.5, 0),
	Vector3(0.35, 1.5, 0),
	Vector3(0.0, 2.5, 0),
	Vector3(0.0, 3.5, 0),
	Vector3(-1.1, 3.7, 0),
	Vector3(1.1, 3.7, 0),
	Vector3(0.0, 4.7, 0),
	Vector3(0.0, 5.7, 0),
]

@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.6
@export var mouse_sensitivity: float = 0.0025
@export var pickup_distance: float = 2.8
@export var van_interact_distance: float = 3.2
@export var throw_speed_min: float = 3.5
@export var throw_speed_max: float = 22.0
@export var throw_charge_full_time: float = 0.85
@export_range(0.0, 1.0, 0.05) var throw_tap_charge: float = 1.0
@export var body_push_multiplier: float = 1.15
@export var cube_spawn_distance: float = 3.0
@export var pyramid_spawn_height: float = 0.575
@export var glue_look_distance: float = 4.0
@export var glue_pair_max_distance: float = 1.45
@export var humanoid_spawn_forward: float = 3.5
@export var gun_pyramid_speed: float = 26.0
@export var gun_fire_cooldown_sec: float = 0.12
@export var gun_mag_size: int = 10
## Длительность полной перезарядки пирамиды после клавиши R (апгрейд ускоряет).
@export_range(0.4, 20.0, 0.05) var gun_full_refill_delay_sec: float = 6.0
## Короткая анимация на модели пушки после пополнения магазина.
@export_range(0.0, 1.0, 0.05) var gun_refill_finish_anim_sec: float = 0.35
@export var stasis_ring_speed: float = 52.0
@export var stasis_fire_cooldown_sec: float = 0.18
@export var stasis_mag_size: int = 5
## Длительность перезарядки стазиса по R.
@export var stasis_refill_delay_sec: float = 5.0
## Анимация после перезарядки стазиса по R (отдельно от пирамиды).
@export_range(0.0, 2.5, 0.05) var stasis_refill_finish_anim_sec: float = 0.6
@export var stasis_reload_ring_spin_mul: float = 9.0
@export_range(0.15, 0.65, 0.02) var stasis_reload_tilt_max: float = 0.38
@export_range(10.0, 85.0, 0.5) var stasis_aim_fov: float = 22.0
@export var stasis_aim_fov_smooth: float = 16.0
## Подвод оружия к камере при ПКМ (в локале камеры).
@export var stasis_aim_model_offset: Vector3 = Vector3(0.2, -0.07, 0.16)
@export var stasis_aim_pos_smooth: float = 18.0
@export_range(3, 20, 1) var sawed_pellet_count: int = 8
@export var sawed_spread_jitter: float = 0.16
@export var sawed_cube_speed: float = 36.0
@export_range(0.2, 0.55, 0.01) var sawed_pellet_scale: float = 0.34
@export var sawed_fire_cooldown_sec: float = 0.9
@export var sawed_mag_size: int = 6
## Длительность перезарядки обреза по R.
@export var sawed_refill_delay_sec: float = 3.5
@export_range(0.0, 2.0, 0.05) var sawed_refill_finish_anim_sec: float = 0.4
## Аниматрон: чёрный шар-воронка, засасывающая всех врагов.
@export var animatron_reload_sec: float = 25.0
@export var animatron_blackhole_lifetime_sec: float = 5.0
@export var animatron_blackhole_fly_speed: float = 9.0
@export var animatron_suck_radius: float = 24.0
@export var animatron_suck_accel: float = 26.0
@export var animatron_suck_up: float = 0.55
@export var animatron_explosion_radius: float = 14.0
@export var animatron_explosion_damage: int = 4
@export var animatron_explosion_knockback: float = 22.0
@export var dash_speed: float = 14.5
@export var dash_duration_sec: float = 0.14
@export var dash_cooldown_sec: float = 0.7
@export var cube_enlarge_factor: float = 1.15
@export var cube_enlarge_max_scale: float = 5.0
@export_range(1, 64, 1) var max_cubes_at_full_enlarge: int = 5
## Дальность выбора куба для Shift+E; не меньше aim_ray_length, чтобы целить как по прицелу по всей карте.
@export var cube_enlarge_ray_distance: float = 48.0
@export var aim_ray_length: float = 48.0
@export var look_key_speed: float = 1.85
@export_range(0.0, 48.0, 0.25) var look_smoothing: float = 14.0
@export_range(40.0, 120.0, 0.5) var camera_fov: float = 65.0
@export var max_hp: int = 100
@export var enemy_touch_damage: int = 8
@export var damage_invuln_sec: float = 1.35
@export_range(0.0, 60.0, 0.5) var fall_damage_min_speed: float = 12.0
@export_range(0.0, 120.0, 0.5) var fall_damage_max_speed: float = 32.0
@export_range(0, 200, 1) var fall_damage_max: int = 55
## Верёвка: ПКМ — подготовка, ЛКМ — бросок по прицелу во что угодно; колесо натягивает тягу.
@export var grapple_max_range: float = 36.0
@export var grapple_break_range: float = 48.0
@export var grapple_pull_accel: float = 42.0
@export var grapple_arrive_range: float = 2.35
@export var grapple_melee_range: float = 3.1
@export var grapple_melee_damage: int = 3
@export var grapple_melee_cooldown_sec: float = 0.42
@export var grapple_attach_damage: int = 1
@export_range(0.5, 3.5, 0.05) var grapple_reel_min: float = 0.65
@export_range(1.2, 4.0, 0.05) var grapple_reel_max: float = 2.85
@export var grapple_reel_wheel_step: float = 0.38
@export var katana_range: float = 3.1
@export var katana_damage: int = 3
@export var katana_cooldown_sec: float = 0.32
@export_range(0.1, 3.0, 0.05) var katana_parry_sec: float = 1.0
@export_range(0.0, 60.0, 0.5) var katana_parry_cooldown_sec: float = 10.0
## Рывок катаны: средняя кнопка мыши — короткий рывок вперёд и урон лучом.
@export_range(1.0, 6.5, 0.05) var katana_lunge_hit_range: float = 3.5
@export_range(0.06, 0.35, 0.01) var katana_lunge_duration_sec: float = 0.13
@export_range(0.0, 60.0, 0.1) var katana_lunge_cooldown_sec: float = 10.0

## Киберпушка: удерживай ЛКМ, чтобы зарядить; отпусти — супер-взрыв.
@export_range(1.0, 120.0, 1.0) var cyber_charge_sec: float = 60.0
@export_range(2.0, 80.0, 0.5) var cyber_explosion_radius: float = 22.0
@export_range(1, 9999, 1) var cyber_explosion_damage: int = 999

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D
@onready var _hold_point: Node3D = $CameraPivot/Camera3D/HoldPoint

var _held: RigidBody3D = null
var _held_enemy: CharacterBody3D = null
var _last_player_spawned_cube: RigidBody3D = null
var _last_spawned_exit_cb: Callable = Callable()
var _enlarge_hint_rb: RigidBody3D = null
var _prev_enlarge_hint_rb: RigidBody3D = null
var _jump_requested: bool = false
var _throw_press_usec: int = -1
var _equipped: EquippedGun = EquippedGun.NONE
var _gun_cd: float = 0.0
var _gun_node: Node3D = null
var _gun_muzzle: Node3D = null
var _gun_ammo: int = 10
var _gun_reload: float = 0.0
var _gun_refill_wait: float = 0.0
var _stasis_ammo: int = 5
var _stasis_cd: float = 0.0
var _stasis_node: Node3D = null
var _stasis_muzzle: Node3D = null
var _stasis_reload: float = 0.0
var _stasis_refill_wait: float = 0.0
var _stasis_ring_visual: MeshInstance3D = null
var _stasis_ads_blend: float = 0.0
var _sawed_ammo: int = 6
var _sawed_cd: float = 0.0
var _sawed_node: Node3D = null
var _sawed_muzzle: Node3D = null
var _sawed_reload: float = 0.0
var _sawed_refill_wait: float = 0.0
var _sawed_volley_seq: int = 0
var _animatron_cd: float = 0.0
var _animatron_node: Node3D = null
var _katana_cd: float = 0.0
var _katana_node: Node3D = null
var _katana_swing_t: float = 0.0
var _katana_swing_len: float = 0.12
var _katana_idle_pos: Vector3 = Vector3(0.22, -0.24, -0.55)
var _katana_idle_rot: Vector3 = Vector3.ZERO
var _katana_parry_t: float = 0.0
var _katana_parry_cd: float = 0.0
var _katana_parry_flash_t: float = 0.0
var _katana_blade_mat: StandardMaterial3D = null
var _katana_lunge_cd: float = 0.0
var _creative_wand_node: Node3D = null
var _cyber_charge_t: float = 0.0
var _cyber_charging: bool = false
var _dash_t: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: Vector3 = Vector3.ZERO
var _cubes_world_locked: bool = false
## Снимок скоростей при остановке времени (Shift+Z): CharacterBody3D и RigidBody3D из сцен.
var _world_time_snap: Dictionary = {}
var _want_mouse_captured: bool = true
var _view_mode: ViewMode = ViewMode.FIRST
var _crosshair_layer: CanvasLayer = null
var _hit_marker: MeshInstance3D = null
var _look_yaw_target: float = 0.0
var _look_pitch_target: float = 0.0
var _hp: int = 100
var _hp_cd: float = 0.0
var _was_on_floor: bool = false
var _fall_min_vy: float = 0.0
var _dead_restart_in_progress: bool = false
var _death_layer: CanvasLayer = null
var _death_panel: PanelContainer = null
var _death_restart_btn: Button = null
var _death_exit_btn: Button = null
var _death_pause_btn: Button = null
var _death_hint_label: Label = null
var _death_visible: bool = false
## Первые секунды на экране смерти: нельзя нажимать кнопки и Esc (рестарт).
var _death_ui_input_locked: bool = false
var _secret_credits_layer: CanvasLayer = null
var _secret_ending_active: bool = false
const DEATH_UI_LOCK_SEC: float = 3.0
var _autosave_acc: float = 0.0
const AUTOSAVE_INTERVAL_SEC: float = 20.0
var _pause_layer: CanvasLayer = null
var _pause_overlay: Control = null
var _pause_main_panel: Control = null
var _pause_controls_root: Control = null
var _pause_hint_label: Label = null
var _pause_visible: bool = false
var _hp_layer: CanvasLayer = null
var _hp_label: Label = null
var _gun_label: Label = null
var _mama_hud: Label = null
var _van_fuel_label: Label = null
var _quest_banner: Label = null
var _quest_banner_timer: Timer = null
var _shop_open: bool = false
## Магазин открыт из зоны лавки на площади деревни (при выходе из зоны закроется).
var _shop_from_world_zone: bool = false
var _shop_layer: CanvasLayer = null
var _world_map_layer: CanvasLayer = null
var _world_map_rt: RichTextLabel = null
var _world_map_subviewport: SubViewport = null
var _world_map_view_cam: Camera3D = null
const WORLD_MAP_ORTHO_MIN := 22.0
const WORLD_MAP_ORTHO_MAX := 110.0
const WORLD_MAP_ORTHO_ZOOM_STEP := 4.5
var _world_map_hint_label: Label = null
var _world_map_hints_scroll: ScrollContainer = null
## На карте: P скрывает/показывает верхнюю подпись и текст заданий (вид сверху остаётся).
var _world_map_hints_collapsed: bool = false
var _world_map_visible: bool = false
var _world_map_map_wrap: Control = null
var _world_map_vpc: SubViewportContainer = null
var _world_map_strip_label: Label = null
var _world_map_player_marker: ColorRect = null
var _world_map_click_layer: Control = null
const WORLD_MAP_PLAYER_MARKER_SIZE := Vector2(32.0, 32.0)
var _grapple_state: GrappleState = GrappleState.INACTIVE
var _grapple_target: Node3D = null
var _grapple_enemy: Node3D = null
var _grapple_anchor_node: Node3D = null
var _grapple_anchor_local: Vector3 = Vector3.ZERO
var _grapple_anchor_world: Vector3 = Vector3.ZERO
var _grapple_line: MeshInstance3D = null
var _grapple_melee_cd: float = 0.0
var _grapple_reel: float = 1.0
## Управляемый фургон (см. drivable_van.gd).
var _driving_van: Node3D = null
var _van_saved_parent: Node = null
var _van_saved_index: int = 0
var _van_saved_layer: int = 1
var _van_saved_mask: int = 1

var _character_kind: CharacterKind = CharacterKind.HERO
var _character_visual_root: Node3D = null
var _character_hat: Node3D = null
var _personal_vehicle: Node3D = null
var _world_map_market_btn: Button = null


func _is_driving_van() -> bool:
	return _driving_van != null and is_instance_valid(_driving_van)


func _eff_gun_mag() -> int:
	return gun_mag_size + GameProgress.up_pyramid_mag * 2


func _eff_gun_refill_delay() -> float:
	return gun_full_refill_delay_sec * pow(0.88, float(GameProgress.up_pyramid_reload))


func _eff_sawed_pellets() -> int:
	return sawed_pellet_count + GameProgress.up_sawed_pellets


func _eff_grapple_max_range() -> float:
	return grapple_max_range + float(GameProgress.up_grapple_range) * 6.0


func _eff_grapple_pull_accel() -> float:
	return grapple_pull_accel * (1.0 + float(GameProgress.up_grapple_pull) * 0.18)


func _eff_grapple_attach_damage() -> int:
	return grapple_attach_damage + GameProgress.up_grapple_damage


func _eff_grapple_melee_damage() -> int:
	return grapple_melee_damage + GameProgress.up_grapple_damage


func _eff_animatron_reload_sec() -> float:
	var t := animatron_reload_sec - float(GameProgress.up_animatron_reload) * 3.5
	return maxf(t, 8.0)


func _eff_animatron_suck_radius() -> float:
	return animatron_suck_radius * (1.0 + float(GameProgress.up_animatron_vortex) * 0.12)


func _eff_animatron_suck_accel() -> float:
	return animatron_suck_accel * (1.0 + float(GameProgress.up_animatron_vortex) * 0.15)


func _eff_animatron_explosion_radius() -> float:
	return animatron_explosion_radius + float(GameProgress.up_animatron_blast) * 2.5


func _eff_animatron_explosion_damage() -> int:
	return animatron_explosion_damage + GameProgress.up_animatron_blast


func _clamp_gun_ammo_to_effective() -> void:
	_gun_ammo = mini(_gun_ammo, _eff_gun_mag())


func _ready() -> void:
	add_to_group("player")
	var tree0 := get_tree()
	if tree0:
		tree0.paused = false
	if _camera:
		_camera.fov = camera_fov
	_want_mouse_captured = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_center_mouse_in_viewport()
	_apply_view_mode()
	var win := get_window()
	if win:
		var cb := Callable(self, "_restore_mouse_capture_after_focus")
		if not win.focus_entered.is_connected(cb):
			win.focus_entered.connect(cb)
	call_deferred("_setup_aim_feedback")
	call_deferred("_setup_hp_ui")
	call_deferred("_setup_shop_ui")
	call_deferred("_ensure_pause_ui")
	call_deferred("_setup_world_map_ui")
	call_deferred("_setup_character_visuals")
	call_deferred("_apply_character_profile")
	if not GameProgress.mama_changed.is_connected(_on_mama_or_upgrades_changed):
		GameProgress.mama_changed.connect(_on_mama_or_upgrades_changed)
	if not GameProgress.upgrades_changed.is_connected(_on_mama_or_upgrades_changed):
		GameProgress.upgrades_changed.connect(_on_mama_or_upgrades_changed)
	if not GameProgress.kills_changed.is_connected(_on_mama_or_upgrades_changed):
		GameProgress.kills_changed.connect(_on_mama_or_upgrades_changed)
	_look_yaw_target = rotation.y
	_look_pitch_target = _camera_pivot.rotation.x
	_hp = max_hp
	_was_on_floor = is_on_floor()
	_fall_min_vy = 0.0
	_gun_ammo = _eff_gun_mag()
	_stasis_ammo = stasis_mag_size
	_sawed_ammo = sawed_mag_size
	call_deferred("_apply_game_save_spawn")


func is_dead_for_save() -> bool:
	return _dead_restart_in_progress


func _apply_game_save_spawn() -> void:
	GameSave.apply_pending_player_transform(self, _camera_pivot)
	_look_yaw_target = rotation.y
	if _camera_pivot:
		_look_pitch_target = _camera_pivot.rotation.x


func _exit_tree() -> void:
	if not _dead_restart_in_progress:
		GameSave.autosave_if_playing(self)
	if _held and is_instance_valid(_held):
		_held.remove_from_group("held_throwable")
		remove_collision_exception_with(_held)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		call_deferred("_restore_mouse_capture_after_focus")


func _restore_mouse_capture_after_focus() -> void:
	if not is_inside_tree():
		return
	if _shop_open:
		return
	if _world_map_visible:
		return
	if _pause_visible:
		return
	if _want_mouse_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_center_mouse_in_viewport()


func _center_mouse_in_viewport() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var r := vp.get_visible_rect()
	vp.warp_mouse(r.position + r.size * 0.5)


func _process(_delta: float) -> void:
	# Захват курсора — только в этом режиме фиксируем мышь в центре (FPS).
	# Таймеры и UI крутятся всегда, иначе при видимом курсоре оружие/перезарядка замирают.
	if (
		not _shop_open
		and not _world_map_visible
		and not _pause_visible
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		and _want_mouse_captured
	):
		var vp_warp := get_viewport()
		if vp_warp:
			var rw := vp_warp.get_visible_rect()
			vp_warp.warp_mouse(rw.position + rw.size * 0.5)
	if _world_map_visible:
		_update_world_map_player_marker()
	if _cyber_charging:
		if (
			GameProgress.world_time_frozen
			or _pause_visible
			or _shop_open
			or _death_visible
			or _world_map_visible
		):
			_cyber_charging = false
			_cyber_charge_t = 0.0
		else:
			_cyber_charge_t = clampf(_cyber_charge_t + _delta, 0.0, cyber_charge_sec)
	_gun_cd = maxf(_gun_cd - _delta, 0.0)
	_gun_reload = maxf(_gun_reload - _delta, 0.0)
	if _equipped == EquippedGun.PYRAMID and _gun_refill_wait > 0.0:
		_gun_refill_wait = maxf(_gun_refill_wait - _delta, 0.0)
		if _gun_refill_wait <= 0.0:
			_gun_ammo = _eff_gun_mag()
			_gun_refill_wait = 0.0
			if gun_refill_finish_anim_sec > 0.0:
				_gun_reload = gun_refill_finish_anim_sec
	_stasis_cd = maxf(_stasis_cd - _delta, 0.0)
	_stasis_reload = maxf(_stasis_reload - _delta, 0.0)
	if _equipped == EquippedGun.STASIS and _stasis_refill_wait > 0.0:
		_stasis_refill_wait = maxf(_stasis_refill_wait - _delta, 0.0)
		if _stasis_refill_wait <= 0.0:
			_stasis_ammo = stasis_mag_size
			_stasis_refill_wait = 0.0
			if stasis_refill_finish_anim_sec > 0.0:
				_stasis_reload = stasis_refill_finish_anim_sec
	_sawed_cd = maxf(_sawed_cd - _delta, 0.0)
	_sawed_reload = maxf(_sawed_reload - _delta, 0.0)
	if _equipped == EquippedGun.SAWED_OFF and _sawed_refill_wait > 0.0:
		_sawed_refill_wait = maxf(_sawed_refill_wait - _delta, 0.0)
		if _sawed_refill_wait <= 0.0:
			_sawed_ammo = sawed_mag_size
			_sawed_refill_wait = 0.0
			if sawed_refill_finish_anim_sec > 0.0:
				_sawed_reload = sawed_refill_finish_anim_sec
	_animatron_cd = maxf(_animatron_cd - _delta, 0.0)
	_katana_cd = maxf(_katana_cd - _delta, 0.0)
	_katana_parry_t = maxf(_katana_parry_t - _delta, 0.0)
	_katana_parry_cd = maxf(_katana_parry_cd - _delta, 0.0)
	_katana_parry_flash_t = maxf(_katana_parry_flash_t - _delta, 0.0)
	_katana_lunge_cd = maxf(_katana_lunge_cd - _delta, 0.0)
	_dash_cd = maxf(_dash_cd - _delta, 0.0)
	_hp_cd = maxf(_hp_cd - _delta, 0.0)

	_update_hp_ui()

	if _is_driving_van():
		if _camera:
			var fk_v := 1.0 - exp(-stasis_aim_fov_smooth * _delta)
			_camera.fov = lerpf(_camera.fov, camera_fov, fk_v)
		return

	var want_stasis_aim := false
	if _camera and _equipped == EquippedGun.STASIS:
		want_stasis_aim = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var stasis_reload_busy := _stasis_refill_wait > 0.0 or _stasis_reload > 0.0
	var ads_target := 1.0 if (want_stasis_aim and not stasis_reload_busy) else 0.0
	_stasis_ads_blend = lerpf(
		_stasis_ads_blend,
		ads_target,
		1.0 - exp(-stasis_aim_pos_smooth * _delta)
	)
	if _equipped != EquippedGun.STASIS:
		_stasis_ads_blend = lerpf(_stasis_ads_blend, 0.0, 1.0 - exp(-12.0 * _delta))

	if _camera:
		var target_fov := stasis_aim_fov if want_stasis_aim else camera_fov
		var fk := 1.0 - exp(-stasis_aim_fov_smooth * _delta)
		_camera.fov = lerpf(_camera.fov, target_fov, fk)

	# Анимация перезарядки: лёгкое покачивание/наклон пушки.
	if _equipped == EquippedGun.PYRAMID:
		_ensure_gun_nodes()
		if _gun_node:
			var t := float(Time.get_ticks_msec()) / 1000.0
			var k_wait := 0.0
			if _gun_refill_wait > 0.0:
				k_wait = clampf(_gun_refill_wait / maxf(_eff_gun_refill_delay(), 0.01), 0.0, 1.0)
			var k_fin := 0.0
			if _gun_reload > 0.0:
				k_fin = clampf(_gun_reload / maxf(gun_refill_finish_anim_sec, 0.01), 0.0, 1.0)
			var k := maxf(k_wait, k_fin)
			if k > 0.0:
				_gun_node.rotation = Vector3(0.0, 0.0, sin(t * 10.0) * 0.35 * k)
				_gun_node.position = _GUN_MODEL_LOCAL_POS + Vector3(0.0, sin(t * 14.0) * 0.02 * k, 0.0)
			else:
				_gun_node.rotation = Vector3.ZERO
				_gun_node.position = _GUN_MODEL_LOCAL_POS
	elif _equipped == EquippedGun.STASIS:
		_ensure_stasis_nodes()
		if _stasis_node and _stasis_ring_visual:
			var t2 := float(Time.get_ticks_msec()) / 1000.0
			var ads_ofs := stasis_aim_model_offset * _stasis_ads_blend
			if _stasis_refill_wait > 0.0:
				var prog := 1.0 - clampf(_stasis_refill_wait / maxf(stasis_refill_delay_sec, 0.01), 0.0, 1.0)
				var wob := sin(t2 * 11.0) * 0.07
				var tilt := lerpf(stasis_reload_tilt_max, stasis_reload_tilt_max * 0.35, prog)
				tilt += sin(t2 * 15.5) * 0.045
				_stasis_node.rotation = Vector3(tilt, wob, sin(t2 * 9.0) * 0.11)
				var pull_z := lerpf(0.16, 0.05, prog)
				_stasis_node.position = (
					_STASIS_GUN_LOCAL_POS
					+ ads_ofs
					+ Vector3(wob * 0.35, -0.07 * prog, pull_z)
				)
				var sp := t2 * stasis_reload_ring_spin_mul
				_stasis_ring_visual.rotation = Vector3(sp * 1.1, sin(t2 * 19.0) * 0.18, sp * 0.75)
				_stasis_ring_visual.scale = Vector3.ONE
			elif _stasis_reload > 0.0:
				var fin := 1.0 - clampf(
					_stasis_reload / maxf(stasis_refill_finish_anim_sec, 0.01),
					0.0,
					1.0
				)
				var snap := sin(fin * PI)
				_stasis_node.rotation = Vector3(-0.26 * (1.0 - snap), 0.0, 0.08 * snap)
				_stasis_node.position = _STASIS_GUN_LOCAL_POS + ads_ofs + Vector3(0.0, 0.025 * snap, -0.09 * snap)
				_stasis_ring_visual.rotation = Vector3.ZERO
				var rs := 1.0 + 0.32 * snap
				_stasis_ring_visual.scale = Vector3(rs, rs, rs)
			else:
				_stasis_node.rotation = Vector3.ZERO
				_stasis_node.position = _STASIS_GUN_LOCAL_POS + ads_ofs
				_stasis_ring_visual.rotation = Vector3.ZERO
				_stasis_ring_visual.scale = Vector3.ONE
	elif _equipped == EquippedGun.SAWED_OFF:
		_ensure_sawed_nodes()
		if _sawed_node:
			var ts := float(Time.get_ticks_msec()) / 1000.0
			var kw := 0.0
			if _sawed_refill_wait > 0.0:
				kw = clampf(_sawed_refill_wait / maxf(sawed_refill_delay_sec, 0.01), 0.0, 1.0)
			var kf := 0.0
			if _sawed_reload > 0.0:
				kf = clampf(_sawed_reload / maxf(sawed_refill_finish_anim_sec, 0.01), 0.0, 1.0)
			var ks := maxf(kw, kf)
			if ks > 0.0:
				_sawed_node.rotation = Vector3(sin(ts * 11.0) * 0.12 * ks, 0.0, sin(ts * 9.0) * 0.22 * ks)
				_sawed_node.position = _SAWED_GUN_LOCAL_POS + Vector3(0.0, sin(ts * 13.0) * 0.018 * ks, 0.0)
			else:
				_sawed_node.rotation = Vector3.ZERO
				_sawed_node.position = _SAWED_GUN_LOCAL_POS
	elif _equipped == EquippedGun.ANIMATRON:
		_ensure_animatron_nodes()
		if _animatron_node:
			var ta := float(Time.get_ticks_msec()) / 1000.0
			var k := 0.0
			if _animatron_cd > 0.0:
				k = clampf(_animatron_cd / maxf(_eff_animatron_reload_sec(), 0.01), 0.0, 1.0)
			_animatron_node.rotation = Vector3(0.0, 0.0, sin(ta * 8.0) * 0.28 * k)
			_animatron_node.position = _ANIMATRON_MODEL_LOCAL_POS + Vector3(0.0, sin(ta * 13.0) * 0.02 * k, 0.0)
			var ring := _animatron_node.get_node_or_null("Ring") as MeshInstance3D
			if ring:
				ring.rotation = Vector3(PI / 2.0, ta * 3.2, sin(ta * 6.0) * 0.2 * k)
	elif _equipped == EquippedGun.KATANA:
		_ensure_katana_nodes()
		if _katana_node:
			# Быстрый взмах: вперёд → назад, с небольшим подъёмом/поворотом.
			_katana_swing_t = maxf(_katana_swing_t - _delta, 0.0)
			var k := 0.0
			if _katana_swing_t > 0.0:
				k = 1.0 - clampf(_katana_swing_t / maxf(_katana_swing_len, 0.001), 0.0, 1.0)
				# Ease in/out, чтобы не было “робота”.
				k = sin(k * PI)
			# Парирование: стойка с поднятым клинком.
			var p := 0.0
			if _katana_parry_t > 0.0:
				p = clampf(_katana_parry_t / maxf(katana_parry_sec, 0.001), 0.0, 1.0)
			_katana_node.position = (
				_katana_idle_pos
				+ Vector3(0.06 * k, 0.03 * k, -0.10 * k)
				+ Vector3(-0.10 * p, 0.09 * p, 0.06 * p)
			)
			_katana_node.rotation = (
				_katana_idle_rot
				+ Vector3(-0.35 * k, 0.65 * k, -0.15 * k)
				+ Vector3(-0.25 * p, -0.55 * p, 0.35 * p)
			)
			# Флэш на клинке в момент парирования.
			if _katana_blade_mat:
				var fk := 0.0
				if _katana_parry_flash_t > 0.0:
					fk = clampf(_katana_parry_flash_t / 0.14, 0.0, 1.0)
				_katana_blade_mat.emission_energy_multiplier = 0.35 + 0.9 * fk
	elif _equipped == EquippedGun.CREATIVE_WAND:
		_ensure_creative_wand_nodes()
		if _creative_wand_node:
			var tw := float(Time.get_ticks_msec()) / 1000.0
			_creative_wand_node.rotation = Vector3(
				sin(tw * 7.0) * 0.07,
				sin(tw * 5.0) * 0.1,
				sin(tw * 9.0) * 0.05
			)
			_creative_wand_node.position = (
				_CREATIVE_WAND_LOCAL_POS + Vector3(0.0, sin(tw * 11.0) * 0.018, 0.0)
			)
	else:
		# Если катана или палочка были активны и режим сменился — возвращаем в idle.
		if _katana_node and is_instance_valid(_katana_node):
			_katana_node.position = _katana_idle_pos
			_katana_node.rotation = _katana_idle_rot
		if _creative_wand_node and is_instance_valid(_creative_wand_node):
			_creative_wand_node.position = _CREATIVE_WAND_LOCAL_POS
			_creative_wand_node.rotation = Vector3.ZERO


func _setup_hp_ui() -> void:
	if _hp_layer != null:
		return
	_hp_layer = CanvasLayer.new()
	_hp_layer.layer = 101
	add_child(_hp_layer)
	_hp_label = Label.new()
	_hp_label.text = ""
	_hp_label.position = Vector2(16, 14)
	_hp_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_hp_layer.add_child(_hp_label)
	_gun_label = Label.new()
	_gun_label.text = ""
	_gun_label.position = Vector2(16, 38)
	_gun_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_hp_layer.add_child(_gun_label)
	_mama_hud = Label.new()
	_mama_hud.text = ""
	_mama_hud.position = Vector2(16, 60)
	_mama_hud.add_theme_color_override("font_color", Color(0.95, 0.85, 0.95, 0.95))
	_hp_layer.add_child(_mama_hud)
	_van_fuel_label = Label.new()
	_van_fuel_label.text = ""
	_van_fuel_label.visible = false
	_van_fuel_label.position = Vector2(16, 84)
	_hp_layer.add_child(_van_fuel_label)
	_quest_banner = Label.new()
	_quest_banner.visible = false
	_quest_banner.position = Vector2(16, 420)
	_quest_banner.size = Vector2(1180, 140)
	_quest_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_banner.add_theme_color_override("font_color", Color(0.96, 0.94, 1.0, 1.0))
	_hp_layer.add_child(_quest_banner)
	_quest_banner_timer = Timer.new()
	_quest_banner_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_quest_banner_timer.one_shot = true
	_quest_banner_timer.timeout.connect(_on_quest_banner_timer)
	add_child(_quest_banner_timer)
	_update_hp_ui()


func _on_quest_banner_timer() -> void:
	if _quest_banner != null:
		_quest_banner.visible = false


func notify_quest_banner(text: String) -> void:
	if not is_inside_tree():
		return
	if _hp_layer == null:
		_setup_hp_ui()
	if _quest_banner == null:
		return
	_quest_banner.text = text
	_quest_banner.visible = true
	if _quest_banner_timer != null:
		_quest_banner_timer.stop()
		_quest_banner_timer.start(5.5)


func _update_hp_ui() -> void:
	if _hp_label:
		if GameSave.is_creative():
			_hp_label.text = "Креатив — без урона"
		else:
			_hp_label.text = "HP: %d/%d" % [_hp, max_hp]
	if _gun_label:
		if _is_driving_van():
			if GameProgress.van_turrets_installed and not GameProgress.van_destroyed:
				_gun_label.text = "ФУРГОН: без оружия — ЛКМ скорострел, ПКМ бомба"
			else:
				_gun_label.text = "ФУРГОН: без оружия (купите турели в лавке)"
		elif _equipped == EquippedGun.PYRAMID:
			var gm := _eff_gun_mag()
			if _gun_refill_wait > 0.0:
				_gun_label.text = "GUN: %d/%d  перезарядка %.1fs  [R]" % [_gun_ammo, gm, _gun_refill_wait]
			elif _gun_reload > 0.0:
				_gun_label.text = "GUN: %d/%d  дозарядка…" % [_gun_ammo, gm]
			elif _gun_ammo < gm:
				_gun_label.text = "GUN: %d/%d  [R — зарядить]" % [_gun_ammo, gm]
			else:
				_gun_label.text = "GUN: %d/%d" % [_gun_ammo, gm]
		elif _equipped == EquippedGun.STASIS:
			if _stasis_refill_wait > 0.0:
				_gun_label.text = (
					"СТАЗИС: %d/%d  перезарядка %.1fs  [R] [ПКМ прицел]"
					% [_stasis_ammo, stasis_mag_size, _stasis_refill_wait]
				)
			elif _stasis_reload > 0.0:
				_gun_label.text = "СТАЗИС: %d/%d  дозарядка… [ПКМ прицел]" % [_stasis_ammo, stasis_mag_size]
			elif _stasis_ammo < stasis_mag_size:
				_gun_label.text = (
					"СТАЗИС: %d/%d  [R — зарядить] [ПКМ прицел]" % [_stasis_ammo, stasis_mag_size]
				)
			else:
				_gun_label.text = "СТАЗИС: %d/%d  [ПКМ прицел]" % [_stasis_ammo, stasis_mag_size]
		elif _equipped == EquippedGun.SAWED_OFF:
			if _sawed_refill_wait > 0.0:
				_gun_label.text = "ОБРЕЗ: %d/%d  перезарядка %.1fs  [R]  (залп %d кубов)" % [
					_sawed_ammo,
					sawed_mag_size,
					_sawed_refill_wait,
					_eff_sawed_pellets(),
				]
			elif _sawed_reload > 0.0:
				_gun_label.text = "ОБРЕЗ: %d/%d  дозарядка…" % [_sawed_ammo, sawed_mag_size]
			elif _sawed_ammo < sawed_mag_size:
				_gun_label.text = "ОБРЕЗ: %d/%d  [R — зарядить]  (залп %d кубов)" % [
					_sawed_ammo,
					sawed_mag_size,
					_eff_sawed_pellets(),
				]
			else:
				_gun_label.text = "ОБРЕЗ: %d/%d  (залп %d кубов)" % [_sawed_ammo, sawed_mag_size, _eff_sawed_pellets()]
		elif _equipped == EquippedGun.ANIMATRON:
			if _animatron_cd > 0.0:
				_gun_label.text = "АНИМАТРОН: перезарядка %.1fs" % [_animatron_cd]
			else:
				_gun_label.text = "АНИМАТРОН: готов (ЛКМ — чёрная воронка)"
		elif _equipped == EquippedGun.CYBER_CANNON:
			var pct := 0
			if cyber_charge_sec > 0.01:
				pct = int(round((_cyber_charge_t / cyber_charge_sec) * 100.0))
			pct = clampi(pct, 0, 100)
			if _cyber_charging:
				_gun_label.text = "КИБЕРПУШКА: заряд %d%% (держи ЛКМ, отпусти — взрыв)" % pct
			else:
				_gun_label.text = "КИБЕРПУШКА: заряд %d%% (ЛКМ — заряд/взрыв)" % pct
		elif _equipped == EquippedGun.CREATIVE_WAND:
			_gun_label.text = (
				"КРЕАТИВНАЯ ПАЛОЧКА: ЛКМ — все враги + %d МАМА  |  6 — убрать"
				% GameProgress.CREATIVE_WAND_MAMA_GRANT
			)
		else:
			_gun_label.text = ""
	if _mama_hud:
		var r := GameProgress.regular_kills % GameProgress.KILLS_FOR_BOSS
		var until_boss := GameProgress.KILLS_FOR_BOSS - r if r != 0 else GameProgress.KILLS_FOR_BOSS
		_mama_hud.text = "МАМА: %d   Динамит: %d   Убийств: %d (босс каждые %d; до след.: %d)" % [
			GameProgress.mama_tokens,
			GameProgress.dynamite_stock,
			GameProgress.regular_kills,
			GameProgress.KILLS_FOR_BOSS,
			until_boss,
		]
	if _van_fuel_label:
		if _driving_van != null and is_instance_valid(_driving_van) and _driving_van.has_method("get_fuel_ratio"):
			_van_fuel_label.visible = true
			var fr := float(_driving_van.call("get_fuel_ratio"))
			var pct := int(round(fr * 100.0))
			var hp_pct := 100
			if _driving_van.has_method("get_hull_ratio"):
				hp_pct = int(round(float(_driving_van.call("get_hull_ratio")) * 100.0))
			var tur_hint := ""
			if GameProgress.van_turrets_installed and not GameProgress.van_destroyed:
				tur_hint = "   | ЛКМ турель / ПКМ турель"
			_van_fuel_label.text = (
				"ФУРГОН: корпус %d%%   бензин %d%%   | заправка %d МАМА, сломан — %d МАМА"
				% [hp_pct, pct, GameProgress.COST_VAN_REFUEL, GameProgress.COST_VAN_RESTORE]
				+ tur_hint
			)
			if hp_pct <= 15 or fr <= 0.001:
				_van_fuel_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.28, 1.0))
			elif hp_pct < 35 or fr < 0.2:
				_van_fuel_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35, 1.0))
			else:
				_van_fuel_label.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0, 0.98))
		else:
			_van_fuel_label.visible = false


func _on_mama_or_upgrades_changed(_arg = null) -> void:
	_update_hp_ui()
	_refresh_shop_buttons()
	if _world_map_visible:
		_refresh_world_map_content()


func _setup_shop_ui() -> void:
	if _shop_layer != null:
		return
	_shop_layer = CanvasLayer.new()
	_shop_layer.layer = 105
	_shop_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_shop_layer.visible = false
	add_child(_shop_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -250.0
	panel.offset_top = 72.0
	panel.offset_right = 250.0
	panel.offset_bottom = 620.0
	_shop_layer.add_child(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	margin.add_child(outer)
	var title := Label.new()
	title.name = "ShopTitle"
	title.text = "МАГАЗИН — валюта: жетоны МАМА (Tab / лавка в деревне, Esc — закрыть)"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(title)
	var info := Label.new()
	info.name = "ShopInfo"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(info)
	var scroll := ScrollContainer.new()
	scroll.name = "ShopScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	outer.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)
	for key in [
		"pyramid_mag",
		"pyramid_reload",
		"stasis_dmg",
		"sawed_pellets",
		"dynamite",
		"grapple_range",
		"grapple_pull",
		"grapple_damage",
		"katana_dmg",
		"katana_speed",
		"animatron_reload",
		"animatron_vortex",
		"animatron_blast",
		"van_turrets",
		"van_refuel",
		"van_restore",
		"horse_buy",
		"horse_restore",
	]:
		var btn := Button.new()
		btn.name = "Btn_" + key
		btn.custom_minimum_size = Vector2(420, 32)
		btn.pressed.connect(_on_shop_buy_pressed.bind(key))
		vbox.add_child(btn)
	_refresh_shop_buttons()


func _refresh_shop_buttons() -> void:
	if _shop_layer == null:
		return
	var info := _shop_layer.find_child("ShopInfo", true, false) as Label
	if info:
		var r2 := GameProgress.regular_kills % GameProgress.KILLS_FOR_BOSS
		var kills_until_next := GameProgress.KILLS_FOR_BOSS - r2 if r2 != 0 else GameProgress.KILLS_FOR_BOSS
		info.text = (
			"Жетоны «МАМА» — валюта: подбери дроп или с босса (×%d). Сейчас: %d. Босс на каждом %d-м убийстве; до следующего: %d. Лавка на площади в деревне открывает магазин при подходе."
			% [
				GameProgress.BOSS_MAMA_PICKUP_COUNT,
				GameProgress.mama_tokens,
				GameProgress.KILLS_FOR_BOSS,
				kills_until_next,
			]
		)
	_set_shop_btn(
		"Btn_pyramid_mag",
		"Пирамида: +2 патрона в магазин",
		GameProgress.up_pyramid_mag,
		GameProgress.COST_PYRAMID_MAG
	)
	_set_shop_btn(
		"Btn_pyramid_reload",
		"Пирамида: быстрее перезарядка по R (~12%% за уровень)",
		GameProgress.up_pyramid_reload,
		GameProgress.COST_PYRAMID_RELOAD
	)
	_set_shop_btn(
		"Btn_stasis_dmg", "Стазис: +1 урон", GameProgress.up_stasis_dmg, GameProgress.COST_STASIS_DMG
	)
	_set_shop_btn(
		"Btn_sawed_pellets",
		"Обрез: +1 куб в залпе",
		GameProgress.up_sawed_pellets,
		GameProgress.COST_SAWED_PELLETS
	)
	_set_shop_btn(
		"Btn_grapple_range",
		"Трос: +6м к дальности",
		GameProgress.up_grapple_range,
		GameProgress.COST_GRAPPLE_RANGE
	)
	_set_shop_btn(
		"Btn_grapple_pull",
		"Трос: сильнее притягивание (+18%/ур.)",
		GameProgress.up_grapple_pull,
		GameProgress.COST_GRAPPLE_PULL
	)
	_set_shop_btn(
		"Btn_grapple_damage",
		"Трос: +1 урон (крюк и удар)",
		GameProgress.up_grapple_damage,
		GameProgress.COST_GRAPPLE_DAMAGE
	)
	_set_shop_btn(
		"Btn_katana_dmg",
		"Катана: +1 урон",
		GameProgress.up_katana_dmg,
		GameProgress.COST_KATANA_DMG
	)
	_set_shop_btn(
		"Btn_katana_speed",
		"Катана: быстрее взмах (−10% кулдаун/ур.)",
		GameProgress.up_katana_speed,
		GameProgress.COST_KATANA_SPEED
	)
	_set_shop_btn(
		"Btn_animatron_reload",
		"Аниматрон: быстрее перезарядка (−3.5 с за ур., мин. 8 с)",
		GameProgress.up_animatron_reload,
		GameProgress.COST_ANIMATRON_RELOAD
	)
	_set_shop_btn(
		"Btn_animatron_vortex",
		"Аниматрон: сильнее воронка (+12% радиус, +15% тяга за ур.)",
		GameProgress.up_animatron_vortex,
		GameProgress.COST_ANIMATRON_VORTEX
	)
	_set_shop_btn(
		"Btn_animatron_blast",
		"Аниматрон: мощнее взрыв (+2.5 м радиус, +1 урон за ур.)",
		GameProgress.up_animatron_blast,
		GameProgress.COST_ANIMATRON_BLAST
	)
	_set_shop_btn_van_turrets()
	_set_shop_btn_van_refuel()
	_set_shop_btn_van_restore()
	_set_shop_btn_horse_buy()
	_set_shop_btn_horse_restore()
	_set_shop_btn_dynamite()


func _set_shop_btn_horse_buy() -> void:
	var b := _shop_layer.find_child("Btn_horse_buy", true, false) as Button
	if b == null:
		return
	var speed_txt := "скорость %.1f" % 16.5
	if _character_kind != CharacterKind.COWBOY:
		b.text = "Конь (ковбой): купить — %s   |   цена %d МАМА" % [speed_txt, GameProgress.COST_HORSE_BUY]
		b.disabled = true
		return
	if GameProgress.horse_owned:
		b.text = "Конь (ковбой): уже куплен — %s" % speed_txt
		b.disabled = true
		return
	b.text = "Конь (ковбой): купить — %s, HP 20   |   цена %d МАМА" % [speed_txt, GameProgress.COST_HORSE_BUY]
	b.disabled = GameProgress.mama_tokens < GameProgress.COST_HORSE_BUY


func _set_shop_btn_horse_restore() -> void:
	var b := _shop_layer.find_child("Btn_horse_restore", true, false) as Button
	if b == null:
		return
	if _character_kind != CharacterKind.COWBOY:
		b.text = "Конь (ковбой): восстановление (только для ковбоя)"
		b.disabled = true
		return
	if not GameProgress.horse_owned:
		b.text = "Конь (ковбой): нет коня — сначала покупка"
		b.disabled = true
		return
	if not GameProgress.horse_destroyed:
		b.text = "Конь (ковбой): на ходу (восстановление не нужно)"
		b.disabled = true
		return
	b.text = "Конь (ковбой): восстановить после поломки   |   цена %d МАМА" % GameProgress.COST_HORSE_RESTORE
	b.disabled = GameProgress.mama_tokens < GameProgress.COST_HORSE_RESTORE


func _set_shop_btn_dynamite() -> void:
	var b := _shop_layer.find_child("Btn_dynamite", true, false) as Button
	if b == null:
		return
	b.text = "Динамит: +1 шт. (бросок клав. 6, слабый взрыв)   |   цена %d МАМА" % GameProgress.COST_DYNAMITE
	b.disabled = GameProgress.mama_tokens < GameProgress.COST_DYNAMITE


func _set_shop_btn_van_restore() -> void:
	var b := _shop_layer.find_child("Btn_van_restore", true, false) as Button
	if b == null:
		return
	if not GameProgress.van_destroyed:
		b.text = "Фургон: на ходу (восстановление не нужно)"
		b.disabled = true
	else:
		b.text = "Фургон: восстановить после поломки   |   цена %d МАМА" % GameProgress.COST_VAN_RESTORE
		b.disabled = GameProgress.mama_tokens < GameProgress.COST_VAN_RESTORE


func _set_shop_btn_van_refuel() -> void:
	var b := _shop_layer.find_child("Btn_van_refuel", true, false) as Button
	if b == null:
		return
	if GameProgress.van_destroyed:
		b.text = "Фургон: сломан — сначала восстановление (%d МАМА)" % GameProgress.COST_VAN_RESTORE
		b.disabled = true
		return
	var fr := GameProgress.get_van_fuel_ratio_for_shop()
	if fr >= 0.999:
		b.text = "Фургон: бак полон (заправка не нужна)"
		b.disabled = true
	else:
		b.text = "Фургон: заправить бак   |   цена %d МАМА" % GameProgress.COST_VAN_REFUEL
		b.disabled = GameProgress.mama_tokens < GameProgress.COST_VAN_REFUEL


func _set_shop_btn_van_turrets() -> void:
	var b := _shop_layer.find_child("Btn_van_turrets", true, false) as Button
	if b == null:
		return
	if GameProgress.van_turrets_installed:
		b.text = "Фургон: турели установлены (бомбомёт + скорострел)"
		b.disabled = true
	else:
		b.text = "Фургон: турели на крышу — бомбы и скорострел   |   цена %d МАМА" % GameProgress.COST_VAN_TURRETS
		b.disabled = GameProgress.mama_tokens < GameProgress.COST_VAN_TURRETS


func _set_shop_btn(node_name: String, title: String, tier: int, cost: int) -> void:
	var b := _shop_layer.find_child(node_name, true, false) as Button
	if b == null:
		return
	b.text = "%s   |   ур.%d/%d   |   цена %d МАМА" % [
		title,
		tier,
		GameProgress.MAX_UPGRADE_TIER,
		cost,
	]
	b.disabled = tier >= GameProgress.MAX_UPGRADE_TIER or GameProgress.mama_tokens < cost


func _on_shop_buy_pressed(which: String) -> void:
	var ok := false
	match which:
		"pyramid_mag":
			ok = GameProgress.try_buy_pyramid_mag()
		"pyramid_reload":
			ok = GameProgress.try_buy_pyramid_reload()
		"stasis_dmg":
			ok = GameProgress.try_buy_stasis_damage()
		"sawed_pellets":
			ok = GameProgress.try_buy_sawed_pellets()
		"grapple_range":
			ok = GameProgress.try_buy_grapple_range()
		"grapple_pull":
			ok = GameProgress.try_buy_grapple_pull()
		"grapple_damage":
			ok = GameProgress.try_buy_grapple_damage()
		"katana_dmg":
			ok = GameProgress.try_buy_katana_damage()
		"katana_speed":
			ok = GameProgress.try_buy_katana_speed()
		"animatron_reload":
			ok = GameProgress.try_buy_animatron_reload()
		"animatron_vortex":
			ok = GameProgress.try_buy_animatron_vortex()
		"animatron_blast":
			ok = GameProgress.try_buy_animatron_blast()
		"van_turrets":
			ok = GameProgress.try_buy_van_turrets()
		"van_refuel":
			ok = GameProgress.try_buy_van_refuel()
		"van_restore":
			ok = GameProgress.try_buy_van_restore()
		"horse_buy":
			ok = GameProgress.try_buy_horse()
			if ok and _character_kind == CharacterKind.COWBOY:
				_apply_character_profile()
		"horse_restore":
			ok = GameProgress.try_buy_horse_restore()
			if ok and _character_kind == CharacterKind.COWBOY:
				_apply_character_profile()
		"dynamite":
			ok = GameProgress.try_buy_dynamite()
	if ok:
		_clamp_gun_ammo_to_effective()
	_refresh_shop_buttons()
	_update_hp_ui()


func notify_world_shop_zone(inside: bool) -> void:
	if inside:
		if not _shop_open:
			_shop_from_world_zone = true
			_toggle_shop()
	else:
		if _shop_open and _shop_from_world_zone:
			_shop_from_world_zone = false
			_toggle_shop()
		else:
			_shop_from_world_zone = false


func _toggle_shop() -> void:
	if not _shop_open and _world_map_visible:
		_world_map_visible = false
		if _world_map_layer != null:
			_world_map_layer.visible = false
		_world_map_stop_3d_preview()
		_update_game_pause_from_ui()
	_shop_open = not _shop_open
	if _shop_layer:
		_shop_layer.visible = _shop_open
	_refresh_shop_buttons()
	if _shop_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_want_mouse_captured = false
	else:
		_want_mouse_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_center_mouse_in_viewport()


func _setup_world_map_ui() -> void:
	if _world_map_layer != null:
		return
	_world_map_layer = CanvasLayer.new()
	_world_map_layer.layer = 103
	_world_map_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_world_map_layer.visible = false
	add_child(_world_map_layer)
	var root := WorldMapOverlayRoot.new()
	root.player_node = self
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.color = Color(0.06, 0.07, 0.09, 0.94)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_world_map_layer.add_child(root)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	root.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var strip := Label.new()
	_world_map_strip_label = strip
	_update_world_map_strip_text()
	strip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	strip.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95, 0.98))
	vbox.add_child(strip)
	var bar := HBoxContainer.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_constant_override("separation", 10)
	vbox.add_child(bar)
	var btn_market := Button.new()
	_world_map_market_btn = btn_market
	btn_market.text = "Рынок"
	btn_market.custom_minimum_size = Vector2(140, 34)
	btn_market.pressed.connect(_teleport_to_market)
	bar.add_child(btn_market)
	var hint_market := Label.new()
	hint_market.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_market.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_market.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 0.9))
	hint_market.text = "Кнопка телепортирует на площадь деревни с лавкой."
	bar.add_child(hint_market)
	var map_hint := Label.new()
	map_hint.text = "Вид сверху: жёлтые подписи в мире — что где; колёсико меняет масштаб. Большой жёлтый квадрат — ты."
	map_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_hint.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0, 0.95))
	vbox.add_child(map_hint)
	_world_map_hint_label = map_hint
	var map_wrap := Control.new()
	_world_map_map_wrap = map_wrap
	map_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_wrap.custom_minimum_size = Vector2(400, 220)
	vbox.add_child(map_wrap)
	var vpc := SubViewportContainer.new()
	_world_map_vpc = vpc
	vpc.layout_mode = 1
	vpc.set_anchors_preset(Control.PRESET_FULL_RECT)
	vpc.offset_right = 0.0
	vpc.offset_bottom = 0.0
	vpc.stretch = true
	map_wrap.add_child(vpc)
	var sv := SubViewport.new()
	sv.size = Vector2i(880, 380)
	sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
	sv.handle_input_locally = false
	sv.transparent_bg = false
	vpc.add_child(sv)
	_world_map_subviewport = sv
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 64.0
	cam.near = 0.5
	cam.far = 420.0
	cam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	cam.position = Vector3(38.0, 118.0, -26.0)
	cam.current = true
	sv.add_child(cam)
	_world_map_view_cam = cam
	_world_map_player_marker = ColorRect.new()
	_world_map_player_marker.color = Color(1.0, 0.88, 0.1, 0.96)
	_world_map_player_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_map_player_marker.size = WORLD_MAP_PLAYER_MARKER_SIZE
	_world_map_player_marker.visible = false
	map_wrap.add_child(_world_map_player_marker)
	_world_map_click_layer = Control.new()
	_world_map_click_layer.layout_mode = 1
	_world_map_click_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_world_map_click_layer.offset_right = 0.0
	_world_map_click_layer.offset_bottom = 0.0
	_world_map_click_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_map_click_layer.gui_input.connect(_on_world_map_area_gui_input)
	map_wrap.add_child(_world_map_click_layer)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(100, 140)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(sc)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.custom_minimum_size = Vector2(820, 80)
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(rt)
	_world_map_rt = rt
	_world_map_hints_scroll = sc
	_world_map_hints_collapsed = false
	_apply_world_map_hints_visibility()


func _apply_world_map_hints_visibility() -> void:
	if _world_map_hint_label != null:
		_world_map_hint_label.visible = not _world_map_hints_collapsed
	if _world_map_hints_scroll != null:
		_world_map_hints_scroll.visible = not _world_map_hints_collapsed


func _toggle_world_map_hints() -> void:
	if not _world_map_visible:
		return
	_world_map_hints_collapsed = not _world_map_hints_collapsed
	_apply_world_map_hints_visibility()


func _world_map_wheel_zoom(dir: int) -> void:
	if not _world_map_visible or _world_map_view_cam == null:
		return
	# dir < 0 — колёсико вверх (уменьшаем ortho size = приближение)
	_world_map_view_cam.size = clampf(
		_world_map_view_cam.size + float(dir) * WORLD_MAP_ORTHO_ZOOM_STEP,
		WORLD_MAP_ORTHO_MIN,
		WORLD_MAP_ORTHO_MAX
	)


func _update_world_map_strip_text() -> void:
	if _world_map_strip_label == null:
		return
	var t := (
		"M / Esc — закрыть карту. P — скрыть/показать текст подсказок. "
		+ "Колёсико мыши — приблизить или отдалить вид сверху."
	)
	if GameSave.is_creative():
		t += " Креатив: ЛКМ по виду сверху — телепорт."
	_world_map_strip_label.text = t


func _refresh_world_map_click_layer() -> void:
	if _world_map_click_layer != null:
		_world_map_click_layer.mouse_filter = (
			Control.MOUSE_FILTER_STOP
			if GameSave.is_creative()
			else Control.MOUSE_FILTER_IGNORE
		)


func _on_world_map_area_gui_input(event: InputEvent) -> void:
	if not _world_map_visible or not GameSave.is_creative():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_world_map_creative_teleport_to_screen_global(mb.global_position)
			if _world_map_click_layer != null:
				_world_map_click_layer.accept_event()


func _world_map_creative_teleport_to_screen_global(screen_global: Vector2) -> void:
	if not GameSave.is_creative():
		return
	if _world_map_vpc == null or _world_map_subviewport == null or _world_map_view_cam == null:
		return
	var r := _world_map_vpc.get_global_rect()
	if not r.has_point(screen_global):
		return
	var rel := screen_global - r.position
	var nx := rel.x / maxf(r.size.x, 1.0)
	var ny := rel.y / maxf(r.size.y, 1.0)
	nx = clampf(nx, 0.0, 1.0)
	ny = clampf(ny, 0.0, 1.0)
	var sp := Vector2(nx * float(_world_map_subviewport.size.x), ny * float(_world_map_subviewport.size.y))
	var cam := _world_map_view_cam
	var origin := cam.project_ray_origin(sp)
	var dir := cam.project_ray_normal(sp)
	var plane_y := global_position.y
	if absf(dir.y) < 0.0001:
		return
	var tr := (plane_y - origin.y) / dir.y
	if tr < 0.0:
		return
	var target := origin + dir * tr
	target.y = plane_y
	if _is_driving_van():
		exit_van()
	global_position = target
	velocity = Vector3.ZERO
	notify_quest_banner("Креатив: телепорт по карте.")


func _update_world_map_player_marker() -> void:
	if not _world_map_visible:
		return
	if (
		_world_map_player_marker == null
		or _world_map_map_wrap == null
		or _world_map_vpc == null
		or _world_map_subviewport == null
		or _world_map_view_cam == null
	):
		return
	var cam := _world_map_view_cam
	var wp := global_position + Vector3(0.0, 0.55, 0.0)
	if cam.is_position_behind(wp):
		_world_map_player_marker.visible = false
		return
	var sub_sz := _world_map_subviewport.size
	if sub_sz.x < 1 or sub_sz.y < 1:
		return
	var uv := cam.unproject_position(wp)
	var wrap_sz := _world_map_map_wrap.size
	if wrap_sz.x < 2.0 or wrap_sz.y < 2.0:
		return
	var px := (uv.x / float(sub_sz.x)) * wrap_sz.x
	var py := (uv.y / float(sub_sz.y)) * wrap_sz.y
	_world_map_player_marker.visible = true
	_world_map_player_marker.position = Vector2(px, py) - _world_map_player_marker.size * 0.5


func _refresh_world_map_content() -> void:
	if _world_map_rt == null:
		return
	_world_map_rt.text = CityQuests.get_world_map_bbcode()


func _world_map_start_3d_preview() -> void:
	if _world_map_subviewport == null or not is_inside_tree():
		return
	_world_map_subviewport.world_3d = get_world_3d()
	_world_map_subviewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE


func _world_map_stop_3d_preview() -> void:
	if _world_map_subviewport == null:
		return
	_world_map_subviewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _update_game_pause_from_ui() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = _pause_visible or _world_map_visible


func _toggle_world_map() -> void:
	if _shop_open:
		_toggle_shop()
	if _world_map_layer == null:
		_setup_world_map_ui()
	_world_map_visible = not _world_map_visible
	if _world_map_layer != null:
		_world_map_layer.visible = _world_map_visible
	if _world_map_visible:
		_world_map_hints_collapsed = false
		_apply_world_map_hints_visibility()
		_update_world_map_strip_text()
		_refresh_world_map_click_layer()
		_refresh_world_map_content()
		_world_map_start_3d_preview()
		_update_world_map_player_marker()
		_refresh_world_map_market_button()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_want_mouse_captured = false
	else:
		_world_map_stop_3d_preview()
		if not _shop_open and not _pause_visible and not _death_visible:
			_want_mouse_captured = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_center_mouse_in_viewport()
	_update_game_pause_from_ui()


func _refresh_world_map_market_button() -> void:
	if _world_map_market_btn == null:
		return
	_world_map_market_btn.disabled = not GameProgress.market_pos_valid
	if not GameProgress.market_pos_valid:
		_world_map_market_btn.text = "Рынок (не найден)"
	else:
		_world_map_market_btn.text = "Рынок"


func _teleport_to_market() -> void:
	if not GameProgress.market_pos_valid:
		notify_quest_banner("Рынок не найден в мире.")
		return
	if _is_driving_van():
		exit_van()
	var p := GameProgress.get_market_pos()
	# Чуть сдвигаем, чтобы не застрять в киоске.
	global_position = p + Vector3(2.0, 0.55, 2.0)
	velocity = Vector3.ZERO
	notify_quest_banner("Телепорт на рынок.")


func take_damage(amount: int, source: String = "") -> void:
	if amount <= 0:
		return
	if GameSave.is_creative():
		return
	if _world_map_visible:
		return
	if _hp_cd > 0.0:
		return
	if _dead_restart_in_progress:
		return
	# Парирование катаной блокирует урон именно от врагов.
	if _katana_parry_t > 0.0 and source == "enemy":
		return
	_hp_cd = damage_invuln_sec
	_hp = clampi(_hp - amount, 0, max_hp)
	_update_hp_ui()
	if _hp <= 0:
		_on_player_died()


func heal(amount: int) -> void:
	if amount <= 0:
		return
	_hp = clampi(_hp + amount, 0, max_hp)
	_update_hp_ui()


func _on_player_died() -> void:
	if not is_inside_tree():
		return
	if _dead_restart_in_progress:
		return
	if GameSave.current_mode == GameSave.Mode.SURVIVAL:
		_survival_respawn_after_death()
		return
	_dead_restart_in_progress = true
	exit_van()
	_hide_pause_menu()
	# Останавливаем управление и врагов.
	set_process(false)
	set_physics_process(false)
	# Пауза/Esc на экране смерти обрабатываются здесь, не в _process.
	set_process_unhandled_input(true)
	GameProgress.world_time_frozen = true
	for grp in ["enemy", "village_katana_mob", "castle_guard"]:
		for node in get_tree().get_nodes_in_group(grp):
			if node is CharacterBody3D:
				(node as CharacterBody3D).set_physics_process(false)
	_show_death_screen()


func _survival_respawn_after_death() -> void:
	exit_van()
	var death_pos := global_position
	var lost := GameProgress.mama_tokens
	if lost > 0:
		GameProgress.scatter_mama_pickups_at(death_pos, lost)
	GameProgress.mama_tokens = 0
	GameProgress.mama_changed.emit(GameProgress.mama_tokens)
	global_position = GameSave.get_mansion_spawn()
	velocity = Vector3.ZERO
	_hp = max_hp
	_hp_cd = 0.0
	_update_hp_ui()
	rotation.y = 0.0
	_look_yaw_target = 0.0
	_look_pitch_target = 0.0
	if _camera_pivot:
		_camera_pivot.rotation.x = 0.0
	notify_quest_banner("Выживание: МАМА остались на месте гибели. Ты в особняке.")
	GameSave.autosave_if_playing(self)


func _restart_scene_after_death() -> void:
	if _death_visible and _death_ui_input_locked:
		return
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	if GameSave.current_mode == GameSave.Mode.HARDCORE:
		GameSave.reset_world_for_hardcore_respawn()
	tree.reload_current_scene()


func _ensure_death_ui() -> void:
	if _death_layer != null:
		return
	_death_layer = CanvasLayer.new()
	_death_layer.layer = 200
	_death_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_death_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_layer.add_child(root)

	var red := ColorRect.new()
	red.set_anchors_preset(Control.PRESET_FULL_RECT)
	red.color = Color(0.85, 0.05, 0.08, 0.82)
	root.add_child(red)

	_death_panel = PanelContainer.new()
	_death_panel.set_anchors_preset(Control.PRESET_CENTER)
	_death_panel.offset_left = -220
	_death_panel.offset_top = -110
	_death_panel.offset_right = 220
	_death_panel.offset_bottom = 130
	root.add_child(_death_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_death_panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)

	var title := Label.new()
	title.text = "ТЫ УМЕР"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var btn_pause := Button.new()
	_death_pause_btn = btn_pause
	btn_pause.text = "Пауза"
	btn_pause.custom_minimum_size = Vector2(220, 36)
	btn_pause.pressed.connect(_open_pause_menu_internal)
	v.add_child(btn_pause)

	var hint := Label.new()
	_death_hint_label = hint
	hint.text = "Esc — заново\nИли выбери кнопку ниже"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)

	var restart := Button.new()
	_death_restart_btn = restart
	restart.text = "Заново"
	restart.custom_minimum_size = Vector2(180, 34)
	restart.pressed.connect(_restart_scene_after_death)
	h.add_child(restart)

	var exitb := Button.new()
	_death_exit_btn = exitb
	exitb.text = "Выйти"
	exitb.custom_minimum_size = Vector2(180, 34)
	exitb.pressed.connect(_exit_game)
	h.add_child(exitb)

	_death_layer.visible = false


func _show_death_screen() -> void:
	if _world_map_visible:
		_world_map_visible = false
		if _world_map_layer != null:
			_world_map_layer.visible = false
		_world_map_stop_3d_preview()
		_update_game_pause_from_ui()
	_ensure_death_ui()
	_death_visible = true
	_death_ui_input_locked = true
	_apply_death_ui_lock_state()
	if _death_layer:
		_death_layer.visible = true
	if _death_restart_btn:
		if GameSave.current_mode == GameSave.Mode.HARDCORE:
			_death_restart_btn.text = "Сначала (весь прогресс сбросится)"
		else:
			_death_restart_btn.text = "Заново"
	var t := get_tree().create_timer(DEATH_UI_LOCK_SEC, true)
	t.timeout.connect(_on_death_ui_lock_expired, CONNECT_ONE_SHOT)
	# Отпускаем мышь для кнопок.
	_want_mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func start_secret_ending_credits() -> void:
	if _secret_credits_layer != null and is_instance_valid(_secret_credits_layer):
		return
	exit_van()
	_release_held()
	if _held_enemy != null and is_instance_valid(_held_enemy):
		_release_held_enemy()
	_secret_ending_active = true
	GameProgress.world_time_frozen = true
	for node in get_tree().get_nodes_in_group("enemy"):
		if node is CharacterBody3D:
			(node as CharacterBody3D).set_physics_process(false)
	for node in get_tree().get_nodes_in_group("castle_guard"):
		if node is CharacterBody3D:
			(node as CharacterBody3D).set_physics_process(false)
	_want_mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_secret_credits_layer = CanvasLayer.new()
	_secret_credits_layer.layer = 195
	_secret_credits_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_secret_credits_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_secret_credits_layer.add_child(root)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.12, 0.96)
	root.add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 88)
	root.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "Ты победил Большого Короля!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title)
	var body := Label.new()
	body.text = (
		"Ты обрадовался.\n\n"
		+ "Спасибо, что прошли игру.\n"
		+ "Надеюсь, вам понравилось.\n\n"
		+ "Продолжение следует…"
	)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 22)
	vbox.add_child(body)
	var btn := Button.new()
	btn.text = "В главное меню"
	btn.custom_minimum_size = Vector2(280, 42)
	btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	btn.offset_bottom = -20.0
	btn.pressed.connect(_finish_secret_credits_to_menu)
	root.add_child(btn)
	var hint := Label.new()
	hint.text = "Esc — то же самое"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_bottom = -68.0
	root.add_child(hint)
	notify_quest_banner("Титры: секретный финал пройден.")
	GameSave.autosave_if_playing(self)


func _finish_secret_credits_to_menu() -> void:
	_secret_ending_active = false
	GameProgress.world_time_frozen = false
	if _secret_credits_layer != null and is_instance_valid(_secret_credits_layer):
		_secret_credits_layer.queue_free()
	_secret_credits_layer = null
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file("res://title_menu.tscn")


func _apply_death_ui_lock_state() -> void:
	if _death_restart_btn:
		_death_restart_btn.disabled = _death_ui_input_locked
	if _death_exit_btn:
		_death_exit_btn.disabled = _death_ui_input_locked
	if _death_hint_label:
		if _death_ui_input_locked:
			_death_hint_label.text = (
				"Подождите %d сек…\nEsc или «Пауза» — полная пауза (в туалет и т.п.)"
				% int(ceil(DEATH_UI_LOCK_SEC))
			)
		else:
			_death_hint_label.text = "Esc — заново\nИли выбери кнопку ниже"


func _on_death_ui_lock_expired() -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return
	if not _death_visible:
		return
	_death_ui_input_locked = false
	_apply_death_ui_lock_state()


func _ensure_pause_ui() -> void:
	if _pause_layer != null:
		return
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 150
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)
	var po := Control.new()
	po.set_script(PAUSE_MENU_OVERLAY)
	_pause_overlay = po
	_pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.focus_mode = Control.FOCUS_ALL
	_pause_layer.add_child(_pause_overlay)
	_pause_overlay.back_or_cancel_requested.connect(_on_pause_overlay_back_or_cancel)

	var blue := ColorRect.new()
	blue.set_anchors_preset(Control.PRESET_FULL_RECT)
	blue.color = Color(0.12, 0.35, 0.92, 0.72)
	blue.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.add_child(blue)

	var panel := PanelContainer.new()
	_pause_main_panel = panel
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -210
	panel.offset_top = -148
	panel.offset_right = 210
	panel.offset_bottom = 148
	_pause_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)

	var title := Label.new()
	title.text = "Пауза"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var cont := Button.new()
	cont.text = "Продолжить"
	cont.custom_minimum_size = Vector2(240, 34)
	cont.pressed.connect(_hide_pause_menu)
	v.add_child(cont)

	var btn_help := Button.new()
	btn_help.text = "Управление"
	btn_help.custom_minimum_size = Vector2(240, 34)
	btn_help.pressed.connect(_pause_show_controls)
	v.add_child(btn_help)

	var btn_exit := Button.new()
	btn_exit.text = "Выйти из игры"
	btn_exit.custom_minimum_size = Vector2(240, 34)
	btn_exit.pressed.connect(_exit_game)
	v.add_child(btn_exit)

	var hint := Label.new()
	_pause_hint_label = hint
	hint.text = "Esc — продолжить"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)

	_pause_controls_root = Control.new()
	_pause_controls_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_controls_root.visible = false
	_pause_controls_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.add_child(_pause_controls_root)

	var help_dim := ColorRect.new()
	help_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_dim.color = Color(0.04, 0.12, 0.35, 0.94)
	help_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_controls_root.add_child(help_dim)

	var back_btn := Button.new()
	back_btn.text = "Назад"
	back_btn.custom_minimum_size = Vector2(120, 32)
	back_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_btn.offset_left = 16
	back_btn.offset_top = 12
	back_btn.offset_right = 136
	back_btn.offset_bottom = 44
	back_btn.pressed.connect(_pause_hide_controls)
	_pause_controls_root.add_child(back_btn)

	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.offset_left = 16
	sc.offset_top = 52
	sc.offset_right = -16
	sc.offset_bottom = -16
	_pause_controls_root.add_child(sc)

	var help_lbl := Label.new()
	help_lbl.text = _pause_controls_help_text()
	help_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(help_lbl)
	call_deferred("_pause_apply_help_label_width", help_lbl)

	_pause_layer.visible = false


func _show_pause_menu() -> void:
	if _shop_open:
		return
	_open_pause_menu_internal()


func _open_pause_menu_internal() -> void:
	if _pause_visible:
		return
	_ensure_pause_ui()
	_pause_hide_controls()
	if _pause_layer:
		# Экран смерти (слой 200) — поднимаем паузу, иначе синий экран не виден.
		_pause_layer.layer = 220 if _death_visible else 150
	_pause_visible = true
	_update_game_pause_from_ui()
	if _pause_layer:
		_pause_layer.visible = true
	if _pause_overlay:
		_pause_overlay.grab_focus()
	_want_mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _hide_pause_menu() -> void:
	if not _pause_visible:
		return
	_pause_hide_controls()
	_pause_visible = false
	if _pause_layer:
		_pause_layer.visible = false
		_pause_layer.layer = 150
	_update_game_pause_from_ui()
	if not _shop_open and not _death_visible:
		_want_mouse_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_center_mouse_in_viewport()


func _exit_game() -> void:
	# С экрана смерти нельзя выйти только в первые секунды; из меню паузы — можно.
	if _death_visible and _death_ui_input_locked and not _pause_visible:
		return
	var tree := get_tree()
	if tree:
		tree.quit()


func _on_pause_overlay_back_or_cancel() -> void:
	if _pause_controls_root != null and _pause_controls_root.visible:
		_pause_hide_controls()
	else:
		_hide_pause_menu()


func _pause_show_controls() -> void:
	if _pause_main_panel:
		_pause_main_panel.visible = false
	if _pause_controls_root:
		_pause_controls_root.visible = true
	if _pause_hint_label:
		_pause_hint_label.text = "Esc — назад к меню"


func _pause_hide_controls() -> void:
	if _pause_controls_root:
		_pause_controls_root.visible = false
	if _pause_main_panel:
		_pause_main_panel.visible = true
	if _pause_hint_label:
		_pause_hint_label.text = "Esc — продолжить"


func _pause_controls_help_text() -> String:
	return (
		"Движение — WASD\n"
		+ "Прыжок — Пробел\n"
		+ "Рывок — левый Shift\n"
		+ "Обзор — мышь\n"
		+ "Смена оружия — колёсико вверх/вниз (кроме режима верёвки)\n"
		+ "Слоты — 1 аниматрон, 2 обрез, 3 пирамида, 4 стазис, 5 катана\n"
		+ "ЛКМ — выстрел / удар катаной / верёвка / метание\n"
		+ "ПКМ — парирование (катана) или крюк-верёвка\n"
		+ "СКМ — рывок катаны: урон по прицелу, перезарядка 10 сек\n"
		+ "В фургоне: оружие недоступно; турели — ЛКМ (скорострел) и ПКМ (бомба), если куплены в лавке\n"
		+ "E — сесть в фургон / выйти; подобрать / метнуть; Shift+E — увеличить куб / отпустить\n"
		+ "R — перезарядка; Shift+R — кинуть пирамидку\n"
		+ "Q / Ctrl+Q — очистка мира; Shift+Q — куб\n"
		+ "F — стазис; G — пистолет; Shift+G — клей кубов\n"
		+ "H — обрез; M — карта (колёсико — масштаб, жёлтый квадрат — ты; в креативе ЛКМ по виду — телепорт); Tab — магазин\n"
		+ "6 — бросить динамит (лавка); в режиме «Креатив» — креативная палочка (ещё раз 6 — убрать)\n"
		+ "B — вид камеры; Shift+B — «человек» из кубов\n"
		+ "Shift+Z — стоп времени; Shift+X/Y — кубы; стрелки — поворот камеры\n"
		+ "Esc — пауза\n"
	)


func _pause_apply_help_label_width(lbl: Label) -> void:
	if lbl == null or not is_instance_valid(lbl):
		return
	var vp := get_viewport()
	if vp == null:
		return
	lbl.custom_minimum_size.x = maxf(320.0, vp.get_visible_rect().size.x - 80.0)


func _pitch_limit() -> float:
	return PI / 2.0 - 0.02


func _clamp_camera_pitch() -> void:
	var lim := _pitch_limit()
	_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -lim, lim)


func _clamp_pitch_target(p: float) -> float:
	var lim := _pitch_limit()
	return clampf(p, -lim, lim)


func _cycle_view_mode() -> void:
	match _view_mode:
		ViewMode.FIRST:
			_view_mode = ViewMode.SECOND
		ViewMode.SECOND:
			_view_mode = ViewMode.THIRD
		_:
			_view_mode = ViewMode.FIRST
	_apply_view_mode()


func _apply_view_mode() -> void:
	if _camera == null or _camera_pivot == null:
		return
	# FIRST: камера в точке pivot (как сейчас).
	# SECOND: немного назад/вверх (ощущение "за плечом").
	# THIRD: дальше назад/выше.
	match _view_mode:
		ViewMode.FIRST:
			_camera.position = Vector3.ZERO
		ViewMode.SECOND:
			_camera.position = Vector3(0.35, 0.12, 2.2)
		ViewMode.THIRD:
			_camera.position = Vector3(0.6, 0.25, 4.6)


func _aim_ray_from_dir() -> Array:
	var from: Vector3
	var dir: Vector3
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		from = _camera.global_position
		dir = -_camera.global_transform.basis.z
	else:
		var mp := get_viewport().get_mouse_position()
		from = _camera.project_ray_origin(mp)
		dir = _camera.project_ray_normal(mp)
	return [from, dir]


func _throw_aim_dir() -> Vector3:
	var ad := _aim_ray_from_dir()
	return (ad[1] as Vector3).normalized()


func _is_use_key(event: InputEventKey) -> bool:
	if not event.pressed or event.echo:
		return false
	# keycode — по раскладке; physical_keycode — физическая клавиша как на QWERTY (удобно при RU)
	return event.keycode == KEY_E or event.physical_keycode == KEY_E


func _world_actions_input_ok() -> bool:
	if _secret_ending_active:
		return false
	var m := Input.mouse_mode
	return (
		m == Input.MOUSE_MODE_CAPTURED
		or m == Input.MOUSE_MODE_VISIBLE
		or m == Input.MOUSE_MODE_CONFINED
	)


func _ensure_grapple_rope_node() -> void:
	if _grapple_line != null:
		return
	_grapple_line = MeshInstance3D.new()
	_grapple_line.name = "GrappleRope"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.038
	cyl.bottom_radius = 0.038
	cyl.height = 1.0
	cyl.radial_segments = 8
	_grapple_line.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.84, 0.71, 0.4)
	mat.roughness = 0.5
	_grapple_line.material_override = mat
	_grapple_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_grapple_line)
	_grapple_line.visible = false


func _clear_grapple() -> void:
	_grapple_state = GrappleState.INACTIVE
	_grapple_target = null
	_grapple_enemy = null
	_grapple_anchor_node = null
	_grapple_anchor_local = Vector3.ZERO
	_grapple_anchor_world = Vector3.ZERO
	_grapple_reel = 1.0
	if _grapple_line != null:
		_grapple_line.visible = false


func _grapple_hook_world() -> Vector3:
	if _grapple_anchor_node != null and is_instance_valid(_grapple_anchor_node):
		return _grapple_anchor_node.to_global(_grapple_anchor_local)
	if _grapple_target != null and is_instance_valid(_grapple_target):
		return _grapple_target.global_position
	if _grapple_anchor_world != Vector3.ZERO:
		return _grapple_anchor_world
	var ad := _aim_ray_from_dir()
	return (ad[0] as Vector3) + (ad[1] as Vector3).normalized() * 4.0


func _try_grapple_attach() -> void:
	if _camera == null:
		return
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var dir: Vector3 = (ad[1] as Vector3).normalized()
	var w := get_world_3d()
	if w == null:
		return
	var space := w.direct_space_state
	if space == null:
		return
	var to := from + dir * _eff_grapple_max_range()
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = true
	var excl: Array[RID] = [get_rid()]
	if _held != null and is_instance_valid(_held):
		excl.append(_held.get_rid())
	query.exclude = excl
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty() or not hit.has("collider"):
		return
	var hp := Vector3.ZERO
	if hit.has("position"):
		hp = hit["position"] as Vector3
	var col: Object = hit["collider"]

	_grapple_target = null
	_grapple_enemy = null
	_grapple_anchor_node = null
	_grapple_anchor_world = hp

	if col is Node:
		var n: Node = col as Node
		if n is Node3D:
			_grapple_target = n as Node3D
			_grapple_anchor_node = _grapple_target
			_grapple_anchor_local = _grapple_target.to_local(hp)
		# Если попали во врага или его часть — ищем родителя из группы enemy.
		while n != null:
			if n.is_in_group("enemy"):
				_grapple_enemy = n as Node3D
				break
			n = n.get_parent()

	_grapple_state = GrappleState.PULLING
	_grapple_reel = 1.0
	_ensure_grapple_rope_node()
	var attach_dmg := _eff_grapple_attach_damage()
	if _grapple_enemy != null and is_instance_valid(_grapple_enemy) and attach_dmg > 0:
		if _grapple_enemy.has_method("take_grapple_hit"):
			_grapple_enemy.call("take_grapple_hit", attach_dmg)
		elif _grapple_enemy.has_method("take_grapple_punch"):
			_grapple_enemy.call("take_grapple_punch", attach_dmg)


func _apply_grapple_pull(delta: float) -> void:
	if _grapple_target == null or not is_instance_valid(_grapple_target):
		_clear_grapple()
		return
	if _dash_t > 0.0:
		return
	var anchor := _grapple_hook_world()
	var to := anchor - global_position
	var dist := to.length()
	if dist > grapple_break_range:
		_clear_grapple()
		return
	if dist > grapple_arrive_range:
		var dir := to.normalized()
		var pull := _eff_grapple_pull_accel() * _grapple_reel * delta
		velocity.x += dir.x * pull
		velocity.z += dir.z * pull
		velocity.y += dir.y * pull * 0.82
	var h := Vector3(velocity.x, 0.0, velocity.z)
	var max_h := 38.0
	if h.length() > max_h:
		h = h.normalized() * max_h
		velocity.x = h.x
		velocity.z = h.z
	velocity.y = clampf(velocity.y, -36.0, 36.0)


func _update_grapple_rope_visual() -> void:
	if _grapple_line == null:
		return
	if _grapple_state == GrappleState.INACTIVE:
		_grapple_line.visible = false
		return
	_ensure_grapple_rope_node()
	_grapple_line.visible = true
	var hook := _grapple_hook_world()
	var p1 := global_position + global_transform.basis * Vector3(0.12, 1.05, 0.1)
	var to_v := hook - p1
	var len := maxf(0.08, to_v.length())
	var dir := to_v / len
	var mid := p1 + dir * (len * 0.5)
	var bx := dir.cross(Vector3.UP)
	if bx.length_squared() < 1e-8:
		bx = Vector3(1, 0, 0)
	else:
		bx = bx.normalized()
	var bz := bx.cross(dir).normalized()
	bx = dir.cross(bz).normalized()
	_grapple_line.global_transform = Transform3D(Basis(bx * 0.07, dir * len, bz * 0.07), mid)


func _grapple_in_melee_range() -> bool:
	if _grapple_enemy == null or not is_instance_valid(_grapple_enemy):
		return false
	return global_position.distance_to(_grapple_enemy.global_position) <= grapple_melee_range


func _grapple_try_melee() -> void:
	if _grapple_melee_cd > 0.0:
		return
	if not _grapple_in_melee_range():
		return
	if _grapple_enemy != null and is_instance_valid(_grapple_enemy) and _grapple_enemy.has_method("take_grapple_punch"):
		_grapple_enemy.call("take_grapple_punch", _eff_grapple_melee_damage())
		_grapple_melee_cd = grapple_melee_cooldown_sec


func _cycle_weapon(step: int) -> void:
	var guns: Array[EquippedGun] = [
		EquippedGun.PYRAMID,
		EquippedGun.STASIS,
		EquippedGun.SAWED_OFF,
		EquippedGun.ANIMATRON,
		EquippedGun.KATANA,
	]
	var idx := guns.find(_equipped)
	if idx < 0:
		idx = 0
	idx = (idx + step) % guns.size()
	if idx < 0:
		idx += guns.size()
	_equipped = guns[idx]
	_update_weapon_visibility()
	_update_hp_ui()


func _input(event: InputEvent) -> void:
	if _pause_visible:
		return
	if _is_driving_van():
		if event is InputEventMouseMotion:
			if not _shop_open and not _pause_visible:
				var mm0 := Input.mouse_mode
				if (
					mm0 == Input.MOUSE_MODE_CAPTURED
					or mm0 == Input.MOUSE_MODE_VISIBLE
					or mm0 == Input.MOUSE_MODE_CONFINED
				):
					_look_yaw_target -= event.relative.x * mouse_sensitivity
					_look_pitch_target = _clamp_pitch_target(
						_look_pitch_target - event.relative.y * mouse_sensitivity
					)
		elif event is InputEventMouseButton:
			if not _shop_open and not _pause_visible:
				get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		if _grapple_state != GrappleState.INACTIVE:
			_clear_grapple()
			get_viewport().set_input_as_handled()
		_jump_requested = true
	# Поворот камеры из движения мыши — в _input, чтобы срабатывало без ПКМ и до GUI.
	if event is InputEventMouseButton:
		if (
			not _shop_open
			and not GameProgress.world_time_frozen
			and _world_actions_input_ok()
			and _grapple_state == GrappleState.PULLING
		):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				_grapple_reel = minf(_grapple_reel + grapple_reel_wheel_step, grapple_reel_max)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				_grapple_reel = maxf(_grapple_reel - grapple_reel_wheel_step, grapple_reel_min)
				get_viewport().set_input_as_handled()
		elif (
			not _shop_open
			and _world_actions_input_ok()
			and _grapple_state != GrappleState.PULLING
			and event.pressed
		):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_cycle_weapon(1)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_cycle_weapon(-1)
				get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		if not _shop_open and not _pause_visible and _world_actions_input_ok():
			if _equipped == EquippedGun.KATANA and _try_katana_lunge():
				get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if _shop_open or GameProgress.world_time_frozen:
			pass
		elif _world_actions_input_ok() and _equipped == EquippedGun.KATANA:
			if event.pressed:
				if _katana_parry_cd > 0.0:
					return
				_katana_parry_t = katana_parry_sec
				_katana_parry_flash_t = 0.14
				_katana_parry_cd = katana_parry_cooldown_sec
				get_viewport().set_input_as_handled()
		elif _world_actions_input_ok() and _equipped != EquippedGun.STASIS:
			if event.pressed:
				if _grapple_state == GrappleState.PULLING:
					_clear_grapple()
					get_viewport().set_input_as_handled()
				elif _grapple_state == GrappleState.ROPE_READY:
					_clear_grapple()
					get_viewport().set_input_as_handled()
				elif _grapple_state == GrappleState.INACTIVE:
					_grapple_state = GrappleState.ROPE_READY
					_ensure_grapple_rope_node()
					get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion:
		if _shop_open or _pause_visible:
			return
		var mm := Input.mouse_mode
		if (
			mm == Input.MOUSE_MODE_CAPTURED
			or mm == Input.MOUSE_MODE_VISIBLE
			or mm == Input.MOUSE_MODE_CONFINED
		):
			_look_yaw_target -= event.relative.x * mouse_sensitivity
			_look_pitch_target = _clamp_pitch_target(
				_look_pitch_target - event.relative.y * mouse_sensitivity
			)
	# ЛКМ: стрельба из пушки (G) или стазиса (F), иначе — метание удерживаемого (как раньше).
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _shop_open or _pause_visible:
			return
		if not _world_actions_input_ok():
			return
		if event.pressed:
			if not _shop_open and not GameProgress.world_time_frozen:
				if _grapple_state == GrappleState.ROPE_READY:
					_try_grapple_attach()
					get_viewport().set_input_as_handled()
					return
				if _grapple_state == GrappleState.PULLING:
					_grapple_try_melee()
					get_viewport().set_input_as_handled()
					return
			if _held_enemy != null and is_instance_valid(_held_enemy):
				if event.pressed:
					_throw_press_usec = Time.get_ticks_usec()
				elif _throw_press_usec >= 0:
					_throw_held_charged()
				get_viewport().set_input_as_handled()
				return
			if _equipped == EquippedGun.CYBER_CANNON:
				_cyber_charging = true
				get_viewport().set_input_as_handled()
				return
			if _equipped == EquippedGun.PYRAMID and _gun_cd <= 0.0 and _gun_ammo > 0:
				_cancel_gun_finish_reload_anim()
				_fire_gun_pyramid()
				_gun_cd = gun_fire_cooldown_sec
				_gun_ammo -= 1
				_update_hp_ui()
				get_viewport().set_input_as_handled()
				return
			if _equipped == EquippedGun.STASIS and _stasis_cd <= 0.0 and _stasis_ammo > 0:
				_cancel_stasis_reload_anim()
				_fire_stasis_ring()
				_stasis_cd = stasis_fire_cooldown_sec
				_stasis_ammo -= 1
				_update_hp_ui()
				get_viewport().set_input_as_handled()
				return
			if _equipped == EquippedGun.SAWED_OFF and _sawed_cd <= 0.0 and _sawed_ammo > 0:
				_cancel_sawed_reload_anim()
				_fire_sawed_off()
				_sawed_cd = sawed_fire_cooldown_sec
				_sawed_ammo -= 1
				_update_hp_ui()
				get_viewport().set_input_as_handled()
				return
			if _equipped == EquippedGun.ANIMATRON and _animatron_cd <= 0.0:
				_fire_animatron_blackhole()
				_animatron_cd = _eff_animatron_reload_sec()
				_update_hp_ui()
				get_viewport().set_input_as_handled()
				return
			if _equipped == EquippedGun.KATANA and _katana_cd <= 0.0:
				_fire_katana_swing()
				_katana_swing_t = _katana_swing_len
				var kspd := pow(0.9, float(GameProgress.up_katana_speed))
				_katana_cd = maxf(0.08, katana_cooldown_sec * kspd)
				get_viewport().set_input_as_handled()
				return
			if _equipped == EquippedGun.CREATIVE_WAND and GameSave.is_creative():
				_fire_creative_wand()
				get_viewport().set_input_as_handled()
				return
			if _held:
				_throw_press_usec = Time.get_ticks_usec()
		else:
			if _equipped == EquippedGun.CYBER_CANNON and _cyber_charging:
				_cyber_charging = false
				if _cyber_charge_t >= maxf(0.1, cyber_charge_sec):
					_cyber_charge_t = 0.0
					_fire_cyber_cannon()
				else:
					var pct := 0
					if cyber_charge_sec > 0.01:
						pct = int(round((_cyber_charge_t / cyber_charge_sec) * 100.0))
					notify_quest_banner("Киберпушка: заряд %d%% (нужно 100%%)." % clampi(pct, 0, 100))
				get_viewport().set_input_as_handled()
				return
			if _held and _throw_press_usec >= 0:
				_throw_held_charged()
			elif (
				_held_enemy != null
				and is_instance_valid(_held_enemy)
				and _throw_press_usec >= 0
			):
				_throw_held_charged()


func _unhandled_input(event: InputEvent) -> void:
	var esc := false
	if event is InputEventKey:
		var k := event as InputEventKey
		esc = k.pressed and not k.echo and (k.keycode == KEY_ESCAPE or k.physical_keycode == KEY_ESCAPE)
	if event.is_action_pressed("ui_cancel") or esc:
		if _secret_credits_layer != null and is_instance_valid(_secret_credits_layer) and _secret_credits_layer.visible:
			_finish_secret_credits_to_menu()
			get_viewport().set_input_as_handled()
			return
		if _world_map_visible:
			_toggle_world_map()
			get_viewport().set_input_as_handled()
			return
		if _death_visible:
			if _death_ui_input_locked:
				if not _pause_visible:
					_show_pause_menu()
				get_viewport().set_input_as_handled()
				return
			_restart_scene_after_death()
			get_viewport().set_input_as_handled()
			return
		if _shop_open:
			_toggle_shop()
			get_viewport().set_input_as_handled()
			return
		if _pause_visible:
			_hide_pause_menu()
			get_viewport().set_input_as_handled()
			return
		_show_pause_menu()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		# Переключение персонажа: стрелки влево/вправо.
		if (
			(event.keycode == KEY_LEFT or event.physical_keycode == KEY_LEFT)
			and _world_actions_input_ok()
			and not _shop_open
			and not _pause_visible
			and not _world_map_visible
			and not _death_visible
		):
			_switch_character(-1)
			get_viewport().set_input_as_handled()
			return
		if (
			(event.keycode == KEY_RIGHT or event.physical_keycode == KEY_RIGHT)
			and _world_actions_input_ok()
			and not _shop_open
			and not _pause_visible
			and not _world_map_visible
			and not _death_visible
		):
			_switch_character(1)
			get_viewport().set_input_as_handled()
			return
		if _is_driving_van():
			if event.keycode == KEY_M and _world_actions_input_ok():
				_toggle_world_map()
				get_viewport().set_input_as_handled()
				return
			if event.keycode == KEY_TAB and _world_actions_input_ok():
				_toggle_shop()
				get_viewport().set_input_as_handled()
				return
			if (
				_is_use_key(event)
				and not (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
				and _world_actions_input_ok()
			):
				exit_van()
				get_viewport().set_input_as_handled()
				return
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_SHIFT and event.location == KEY_LOCATION_LEFT:
			_try_dash()
			get_viewport().set_input_as_handled()
		elif (
			(event.keycode == KEY_1 or event.physical_keycode == KEY_1)
			and _world_actions_input_ok()
		):
			if _equipped == EquippedGun.ANIMATRON:
				_equipped = EquippedGun.NONE
			else:
				_equipped = EquippedGun.ANIMATRON
			_update_weapon_visibility()
			_update_hp_ui()
			get_viewport().set_input_as_handled()
		elif (
			(event.keycode == KEY_2 or event.physical_keycode == KEY_2)
			and _world_actions_input_ok()
		):
			if _equipped == EquippedGun.SAWED_OFF:
				_equipped = EquippedGun.NONE
			else:
				_equipped = EquippedGun.SAWED_OFF
			_update_weapon_visibility()
			_update_hp_ui()
			get_viewport().set_input_as_handled()
		elif (
			(event.keycode == KEY_3 or event.physical_keycode == KEY_3)
			and _world_actions_input_ok()
		):
			if _equipped == EquippedGun.PYRAMID:
				_equipped = EquippedGun.NONE
			else:
				_equipped = EquippedGun.PYRAMID
			_update_weapon_visibility()
			_update_hp_ui()
			get_viewport().set_input_as_handled()
		elif (
			(event.keycode == KEY_4 or event.physical_keycode == KEY_4)
			and _world_actions_input_ok()
		):
			if _equipped == EquippedGun.STASIS:
				_equipped = EquippedGun.NONE
			else:
				_equipped = EquippedGun.STASIS
			_update_weapon_visibility()
			_update_hp_ui()
			get_viewport().set_input_as_handled()
		elif (
			(event.keycode == KEY_5 or event.physical_keycode == KEY_5)
			and _world_actions_input_ok()
		):
			if _equipped == EquippedGun.KATANA:
				_equipped = EquippedGun.NONE
			else:
				_equipped = EquippedGun.KATANA
			_update_weapon_visibility()
			_update_hp_ui()
			get_viewport().set_input_as_handled()
		elif (
			(event.keycode == KEY_6 or event.physical_keycode == KEY_6)
			and _world_actions_input_ok()
			and not _is_driving_van()
		):
			if GameSave.is_creative():
				if _equipped == EquippedGun.CREATIVE_WAND:
					_equipped = EquippedGun.NONE
				else:
					_equipped = EquippedGun.CREATIVE_WAND
				_update_weapon_visibility()
				_update_hp_ui()
			else:
				_throw_dynamite()
			get_viewport().set_input_as_handled()
		if (
			(event.keycode == KEY_C or event.physical_keycode == KEY_C)
			and _world_actions_input_ok()
		):
			_clear_world_objects()
			get_viewport().set_input_as_handled()
		if (
			event.keycode == KEY_Q
			and (event.ctrl_pressed or Input.is_key_pressed(KEY_CTRL))
			and not (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
		):
			ThrowablesBudget.brick_shattering_enabled = (
				not ThrowablesBudget.brick_shattering_enabled
			)
			get_viewport().set_input_as_handled()
		elif (
			(event.keycode == KEY_Q or event.physical_keycode == KEY_Q)
			and not (event.ctrl_pressed or Input.is_key_pressed(KEY_CTRL))
			and not (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_clear_world_objects()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_Q
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_spawn_throwable_cube()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_R
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_spawn_throwable_pyramid()
			get_viewport().set_input_as_handled()
		elif (
			(event.keycode == KEY_R or event.physical_keycode == KEY_R)
			and not (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and not (event.ctrl_pressed or Input.is_key_pressed(KEY_CTRL))
			and _world_actions_input_ok()
		):
			_try_start_weapon_reload()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_Z
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_toggle_world_time_freeze()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_X
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			if GameProgress.world_time_frozen:
				_resume_world_time()
			else:
				_unlock_cubes_world()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_Y
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_toggle_cubes_world_lock()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_B
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_arrange_cubes_humanoid()
			get_viewport().set_input_as_handled()
		elif (
			(event.keycode == KEY_B or event.physical_keycode == KEY_B)
			and not (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_cycle_view_mode()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_G
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_try_glue_throwable_cubes()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F and _world_actions_input_ok():
			_toggle_stasis()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M and _world_actions_input_ok():
			_toggle_world_map()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_TAB and _world_actions_input_ok():
			_toggle_shop()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_H and _world_actions_input_ok():
			_toggle_sawed_off()
			get_viewport().set_input_as_handled()
		elif (
			event.keycode == KEY_G
			and not (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			_toggle_gun()
			get_viewport().set_input_as_handled()
		elif (
			_is_use_key(event)
			and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT))
			and _world_actions_input_ok()
		):
			if _try_enlarge_cube():
				get_viewport().set_input_as_handled()
			elif _held:
				_release_held()
				get_viewport().set_input_as_handled()
		elif _is_use_key(event):
			if _driving_van != null and is_instance_valid(_driving_van):
				exit_van()
			elif _try_interact_puzzle_lever():
				pass
			elif _try_interact_village_house_loot():
				pass
			elif _try_interact_quest_npc():
				pass
			elif _held:
				_throw_held_tap()
			elif _held_enemy != null and is_instance_valid(_held_enemy):
				_throw_held_tap()
			else:
				_try_pickup()
			get_viewport().set_input_as_handled()

func _try_dash() -> void:
	if _dash_cd > 0.0 or _dash_t > 0.0:
		return
	if not is_on_floor():
		return
	var dir2 := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A):
		dir2.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		dir2.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		dir2.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		dir2.y += 1.0
	var dir := Vector3.ZERO
	if dir2.length_squared() > 0.0:
		dir2 = dir2.normalized()
		dir = (transform.basis * Vector3(dir2.x, 0.0, dir2.y)).normalized()
	else:
		dir = -global_transform.basis.z
		dir.y = 0.0
		if dir.length_squared() > 0.0001:
			dir = dir.normalized()
	_dash_dir = dir
	_dash_t = dash_duration_sec
	_dash_cd = dash_cooldown_sec


func _clear_world_objects() -> void:
	# Удаляем динамику на сцене: снаряды, врагов, дроп МАМА, клей между кубами.
	if GameProgress.world_time_frozen:
		GameProgress.world_time_frozen = false
		_world_time_snap.clear()
	if _held != null and is_instance_valid(_held):
		_release_held()
	for node in get_tree().get_nodes_in_group("throwable"):
		if node is Node:
			var n := node as Node
			if n.is_in_group("held_throwable"):
				continue
			n.call_deferred("queue_free")
	for node in get_tree().get_nodes_in_group("enemy"):
		if node is Node:
			(node as Node).call_deferred("queue_free")
	for node in get_tree().get_nodes_in_group("mama_pickup"):
		if node is Node:
			(node as Node).call_deferred("queue_free")
	for node in get_tree().get_nodes_in_group("cube_glue"):
		if node is Node:
			(node as Node).call_deferred("queue_free")

func _reset_gun_model_idle() -> void:
	_ensure_gun_nodes()
	if _gun_node:
		_gun_node.rotation = Vector3.ZERO
		_gun_node.position = _GUN_MODEL_LOCAL_POS


func _reset_stasis_model_idle() -> void:
	_ensure_stasis_nodes()
	if _stasis_node:
		_stasis_node.rotation = Vector3.ZERO
		_stasis_node.position = _STASIS_GUN_LOCAL_POS
	if _stasis_ring_visual:
		_stasis_ring_visual.rotation = Vector3.ZERO
		_stasis_ring_visual.scale = Vector3.ONE


func _cancel_gun_finish_reload_anim() -> void:
	_gun_refill_wait = 0.0
	_gun_reload = 0.0
	_reset_gun_model_idle()


func _cancel_stasis_reload_anim() -> void:
	_stasis_refill_wait = 0.0
	_stasis_reload = 0.0
	_reset_stasis_model_idle()


func _update_weapon_visibility() -> void:
	if not GameSave.is_creative() and _equipped == EquippedGun.CREATIVE_WAND:
		_equipped = EquippedGun.NONE
	_ensure_gun_nodes()
	_ensure_stasis_nodes()
	_ensure_sawed_nodes()
	_ensure_animatron_nodes()
	_ensure_katana_nodes()
	_ensure_creative_wand_nodes()
	if _is_driving_van():
		if _gun_node:
			_gun_node.visible = false
		if _stasis_node:
			_stasis_node.visible = false
		if _sawed_node:
			_sawed_node.visible = false
		if _animatron_node:
			_animatron_node.visible = false
		if _katana_node:
			_katana_node.visible = false
		if _creative_wand_node:
			_creative_wand_node.visible = false
		return
	if _gun_node:
		_gun_node.visible = (_equipped == EquippedGun.PYRAMID)
	if _stasis_node:
		_stasis_node.visible = (_equipped == EquippedGun.STASIS)
	if _sawed_node:
		_sawed_node.visible = (_equipped == EquippedGun.SAWED_OFF)
	if _animatron_node:
		_animatron_node.visible = (_equipped == EquippedGun.ANIMATRON)
	if _katana_node:
		_katana_node.visible = (_equipped == EquippedGun.KATANA)
	if _creative_wand_node:
		_creative_wand_node.visible = (
			GameSave.is_creative() and _equipped == EquippedGun.CREATIVE_WAND
		)


func _fire_creative_wand() -> void:
	if not GameSave.is_creative():
		return
	var tree := get_tree()
	if tree == null:
		return
	var list: Array[Node] = []
	for n in tree.get_nodes_in_group("enemy"):
		if n is Node:
			list.append(n as Node)
	for n in list:
		if not is_instance_valid(n):
			continue
		if n is GameEnemy:
			(n as GameEnemy).creative_wand_kill()
		elif n.has_method("creative_wand_kill"):
			n.call("creative_wand_kill")
	for kn in tree.get_nodes_in_group("king_npc"):
		if not is_instance_valid(kn):
			continue
		if kn.has_method("creative_wand_kill"):
			kn.call("creative_wand_kill")
	var mobs: Array[Node] = []
	for n2 in tree.get_nodes_in_group("village_katana_mob"):
		if n2 is Node:
			mobs.append(n2 as Node)
	for n in mobs:
		if not is_instance_valid(n):
			continue
		if n.has_method("creative_wand_kill"):
			n.call("creative_wand_kill")
	GameProgress.add_mama(GameProgress.CREATIVE_WAND_MAMA_GRANT)
	notify_quest_banner(
		"Креативная палочка: враги и разъярённые жители сняты. +%d МАМА."
		% GameProgress.CREATIVE_WAND_MAMA_GRANT
	)
	_update_hp_ui()


func _ensure_creative_wand_nodes() -> void:
	if _creative_wand_node != null and is_instance_valid(_creative_wand_node):
		return
	if _camera == null:
		return
	_creative_wand_node = Node3D.new()
	_creative_wand_node.name = "CreativeWand"
	_camera.add_child(_creative_wand_node)
	_creative_wand_node.position = _CREATIVE_WAND_LOCAL_POS
	var rod := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.028
	cyl.bottom_radius = 0.04
	cyl.height = 0.52
	cyl.radial_segments = 10
	rod.mesh = cyl
	var mrod := StandardMaterial3D.new()
	mrod.albedo_color = Color(0.55, 0.22, 0.92, 1.0)
	mrod.emission_enabled = true
	mrod.emission = Color(0.72, 0.35, 1.0, 1.0)
	mrod.emission_energy_multiplier = 0.85
	mrod.metallic = 0.35
	mrod.roughness = 0.4
	rod.set_surface_override_material(0, mrod)
	rod.rotation_degrees = Vector3(90, 0, 0)
	rod.position = Vector3(0, 0, -0.18)
	_creative_wand_node.add_child(rod)
	var star := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.07
	sph.height = 0.14
	sph.radial_segments = 12
	star.mesh = sph
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(1.0, 0.85, 0.35, 1.0)
	ms.emission_enabled = true
	ms.emission = Color(1.0, 0.92, 0.5, 1.0)
	ms.emission_energy_multiplier = 1.1
	ms.metallic = 0.5
	ms.roughness = 0.25
	star.set_surface_override_material(0, ms)
	star.position = Vector3(0, 0, -0.52)
	_creative_wand_node.add_child(star)
	_creative_wand_node.visible = false


func _toggle_gun() -> void:
	if _equipped == EquippedGun.PYRAMID:
		_equipped = EquippedGun.NONE
	else:
		_equipped = EquippedGun.PYRAMID
	_update_weapon_visibility()


func _toggle_stasis() -> void:
	if _equipped == EquippedGun.STASIS:
		_equipped = EquippedGun.NONE
	else:
		_equipped = EquippedGun.STASIS
	_update_weapon_visibility()


func _toggle_sawed_off() -> void:
	if _equipped == EquippedGun.SAWED_OFF:
		_equipped = EquippedGun.NONE
	else:
		_equipped = EquippedGun.SAWED_OFF
	_update_weapon_visibility()


func _reset_sawed_model_idle() -> void:
	_ensure_sawed_nodes()
	if _sawed_node:
		_sawed_node.rotation = Vector3.ZERO
		_sawed_node.position = _SAWED_GUN_LOCAL_POS


func _cancel_sawed_reload_anim() -> void:
	_sawed_refill_wait = 0.0
	_sawed_reload = 0.0
	_reset_sawed_model_idle()


func _try_start_weapon_reload() -> void:
	match _equipped:
		EquippedGun.PYRAMID:
			if _gun_ammo >= _eff_gun_mag():
				return
			if _gun_refill_wait > 0.0 or _gun_reload > 0.0:
				return
			_gun_refill_wait = _eff_gun_refill_delay()
		EquippedGun.STASIS:
			if _stasis_ammo >= stasis_mag_size:
				return
			if _stasis_refill_wait > 0.0 or _stasis_reload > 0.0:
				return
			_stasis_refill_wait = stasis_refill_delay_sec
		EquippedGun.SAWED_OFF:
			if _sawed_ammo >= sawed_mag_size:
				return
			if _sawed_refill_wait > 0.0 or _sawed_reload > 0.0:
				return
			_sawed_refill_wait = sawed_refill_delay_sec
		_:
			return
	_update_hp_ui()


func _ensure_gun_nodes() -> void:
	if _gun_node != null and is_instance_valid(_gun_node):
		return
	if _camera == null:
		return
	_gun_node = Node3D.new()
	_gun_node.name = "PyramidGun"
	_camera.add_child(_gun_node)
	_gun_node.transform.origin = _GUN_MODEL_LOCAL_POS

	var mesh_i := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.18, 0.12, 0.42)
	mesh_i.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.2, 1.0)
	mesh_i.set_surface_override_material(0, mat)
	_gun_node.add_child(mesh_i)

	_gun_muzzle = Node3D.new()
	_gun_muzzle.name = "Muzzle"
	_gun_muzzle.transform.origin = Vector3(0.0, -0.02, -0.32)
	_gun_node.add_child(_gun_muzzle)

	_gun_node.visible = false


func _ensure_stasis_nodes() -> void:
	if _stasis_node != null and is_instance_valid(_stasis_node):
		if _stasis_ring_visual == null or not is_instance_valid(_stasis_ring_visual):
			_stasis_ring_visual = _stasis_node.get_node_or_null("StasisRingVisual") as MeshInstance3D
			if _stasis_ring_visual == null and _stasis_node.get_child_count() > 0:
				var c0 := _stasis_node.get_child(0)
				if c0 is MeshInstance3D:
					_stasis_ring_visual = c0 as MeshInstance3D
		return
	if _camera == null:
		return
	_stasis_node = Node3D.new()
	_stasis_node.name = "StasisGun"
	_camera.add_child(_stasis_node)
	_stasis_node.transform.origin = _STASIS_GUN_LOCAL_POS

	var ring_mesh := MeshInstance3D.new()
	var tm := TorusMesh.new()
	# TorusMesh: inner/outer radius + сегменты.
	tm.inner_radius = 0.08
	tm.outer_radius = 0.14
	tm.rings = 10
	tm.ring_segments = 20
	ring_mesh.mesh = tm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.35, 0.55, 0.98, 1.0)
	smat.emission_enabled = true
	smat.emission = Color(0.15, 0.35, 0.9, 1.0)
	smat.emission_energy_multiplier = 0.4
	ring_mesh.set_surface_override_material(0, smat)
	ring_mesh.name = "StasisRingVisual"
	_stasis_ring_visual = ring_mesh
	_stasis_node.add_child(ring_mesh)

	var grip := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.1, 0.1, 0.28)
	grip.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.2, 0.22, 0.28, 1.0)
	grip.set_surface_override_material(0, gmat)
	grip.position = Vector3(0.0, 0.0, 0.12)
	_stasis_node.add_child(grip)

	_stasis_muzzle = Node3D.new()
	_stasis_muzzle.name = "StasisMuzzle"
	_stasis_muzzle.transform.origin = Vector3(0.0, 0.0, -0.26)
	_stasis_node.add_child(_stasis_muzzle)

	_stasis_node.visible = false


func _ensure_sawed_nodes() -> void:
	if _sawed_node != null and is_instance_valid(_sawed_node):
		return
	if _camera == null:
		return
	_sawed_node = Node3D.new()
	_sawed_node.name = "SawedOffGun"
	_camera.add_child(_sawed_node)
	_sawed_node.transform.origin = _SAWED_GUN_LOCAL_POS

	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.42, 0.28, 0.16, 1.0)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.35, 0.35, 0.38, 1.0)

	var stock := MeshInstance3D.new()
	var stock_m := BoxMesh.new()
	stock_m.size = Vector3(0.1, 0.12, 0.22)
	stock.mesh = stock_m
	stock.set_surface_override_material(0, wood)
	stock.position = Vector3(0.0, 0.0, 0.14)
	_sawed_node.add_child(stock)

	for side in [-1.0, 1.0]:
		var barrel := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.038
		bm.bottom_radius = 0.042
		bm.height = 0.36
		bm.radial_segments = 10
		barrel.mesh = bm
		barrel.set_surface_override_material(0, metal)
		barrel.rotation = Vector3(PI / 2.0, 0.0, 0.0)
		barrel.position = Vector3(side * 0.055, 0.0, -0.14)
		_sawed_node.add_child(barrel)

	_sawed_muzzle = Node3D.new()
	_sawed_muzzle.name = "SawedMuzzle"
	_sawed_muzzle.transform.origin = Vector3(0.0, 0.0, -0.32)
	_sawed_node.add_child(_sawed_muzzle)

	_sawed_node.visible = false


func _ensure_animatron_nodes() -> void:
	if _animatron_node != null and is_instance_valid(_animatron_node):
		return
	if _camera == null:
		return
	_animatron_node = Node3D.new()
	_animatron_node.name = "AnimatronGun"
	_camera.add_child(_animatron_node)
	_animatron_node.transform.origin = _ANIMATRON_MODEL_LOCAL_POS
	var core := MeshInstance3D.new()
	core.name = "Core"
	var sm := SphereMesh.new()
	sm.radius = 0.09
	sm.height = 0.18
	core.mesh = sm
	var mat := StandardMaterial3D.new()
	# Стиль "рельсотрона": тёмный металл + холодное голубое свечение.
	mat.albedo_color = Color(0.18, 0.18, 0.2, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.35, 0.9, 1.0)
	mat.emission_energy_multiplier = 0.95
	mat.roughness = 0.35
	core.set_surface_override_material(0, mat)
	_animatron_node.add_child(core)
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var tm := TorusMesh.new()
	tm.inner_radius = 0.10
	tm.outer_radius = 0.14
	tm.rings = 10
	tm.ring_segments = 14
	ring.mesh = tm

	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.22, 0.26, 0.34, 1.0)
	rmat.emission_enabled = true
	rmat.emission = Color(0.15, 0.45, 1.0, 1.0)
	rmat.emission_energy_multiplier = 0.7
	rmat.roughness = 0.55
	ring.set_surface_override_material(0, rmat)
	ring.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	_animatron_node.add_child(ring)
	_animatron_node.visible = false


func _ensure_katana_nodes() -> void:
	if _katana_node != null and is_instance_valid(_katana_node):
		return
	if _camera == null:
		return
	_katana_node = Node3D.new()
	_katana_node.name = "Katana"
	_camera.add_child(_katana_node)
	_katana_node.transform.origin = _katana_idle_pos
	_katana_node.rotation = _katana_idle_rot

	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.035
	handle_mesh.bottom_radius = 0.035
	handle_mesh.height = 0.26
	handle_mesh.radial_segments = 10
	handle.mesh = handle_mesh
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.16, 0.11, 0.07, 1.0)
	hmat.roughness = 0.65
	hmat.metallic = 0.05
	# Простая процедурная "текстурка" обмотки рукояти.
	var hnoise := FastNoiseLite.new()
	hnoise.noise_type = FastNoiseLite.TYPE_CELLULAR
	hnoise.frequency = 9.0
	var htex := NoiseTexture2D.new()
	htex.width = 256
	htex.height = 256
	htex.noise = hnoise
	htex.seamless = true
	hmat.albedo_texture = htex
	handle.set_surface_override_material(0, hmat)
	handle.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	handle.position = Vector3(0.0, -0.04, 0.02)
	_katana_node.add_child(handle)

	var tsuba := MeshInstance3D.new()
	var tsuba_mesh := CylinderMesh.new()
	tsuba_mesh.top_radius = 0.06
	tsuba_mesh.bottom_radius = 0.06
	tsuba_mesh.height = 0.02
	tsuba_mesh.radial_segments = 12
	tsuba.mesh = tsuba_mesh
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.35, 0.3, 0.18, 1.0)
	tmat.metallic = 0.55
	tmat.roughness = 0.32
	tsuba.set_surface_override_material(0, tmat)
	tsuba.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	tsuba.position = Vector3(0.0, 0.0, -0.06)
	_katana_node.add_child(tsuba)

	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.028, 0.04, 1.02)
	blade.mesh = blade_mesh
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.88, 0.92, 0.98, 1.0)
	bmat.metallic = 0.9
	bmat.roughness = 0.12
	# Процедурная "текстурка" металла (лёгкая зернистость).
	var bnoise := FastNoiseLite.new()
	bnoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	bnoise.frequency = 32.0
	bnoise.fractal_type = FastNoiseLite.FRACTAL_FBM
	bnoise.fractal_octaves = 4
	var btex := NoiseTexture2D.new()
	btex.width = 256
	btex.height = 256
	btex.noise = bnoise
	btex.seamless = true
	bmat.roughness_texture = btex
	bmat.roughness_texture_channel = StandardMaterial3D.TEXTURE_CHANNEL_RED
	bmat.emission_enabled = true
	bmat.emission = Color(0.12, 0.32, 0.75, 1.0)
	bmat.emission_energy_multiplier = 0.35
	_katana_blade_mat = bmat
	blade.set_surface_override_material(0, bmat)
	blade.position = Vector3(0.0, 0.02, -0.62)
	_katana_node.add_child(blade)

	_katana_node.visible = false


func _katana_ray_damage(from: Vector3, direction: Vector3, reach: float) -> void:
	var dir := direction.normalized()
	if dir.length_squared() < 1e-8:
		return
	var w := get_world_3d()
	if w == null:
		return
	var space := w.direct_space_state
	if space == null:
		return
	var to := from + dir * reach
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = true
	query.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty() or not hit.has("collider"):
		return
	var col: Object = hit["collider"]
	if not col is Node:
		return
	var n := col as Node
	while n != null:
		if n.is_in_group("enemy"):
			if n.has_method("take_katana_hit"):
				n.call("take_katana_hit", katana_damage + GameProgress.up_katana_dmg)
			return
		if n.is_in_group("castle_guard"):
			if n.has_method("take_katana_hit"):
				n.call("take_katana_hit", katana_damage + GameProgress.up_katana_dmg)
			return
		if n.is_in_group("king_npc"):
			if n.has_method("take_katana_hit"):
				n.call("take_katana_hit", katana_damage + GameProgress.up_katana_dmg)
			return
		if n.is_in_group("village_damageable_npc"):
			if n.has_method("take_katana_hit"):
				n.call("take_katana_hit", katana_damage + GameProgress.up_katana_dmg)
			return
		n = n.get_parent()


func _try_katana_lunge() -> bool:
	if _equipped != EquippedGun.KATANA:
		return false
	if _katana_lunge_cd > 0.0 or _dash_t > 0.0:
		return false
	if not is_on_floor():
		return false
	var dir := -global_transform.basis.z
	dir.y = 0.0
	if dir.length_squared() < 1e-6:
		return false
	dir = dir.normalized()
	_dash_dir = dir
	_dash_t = katana_lunge_duration_sec
	_katana_lunge_cd = katana_lunge_cooldown_sec
	# Урон — луч из камеры по прицелу (как взмах), движение рывка остаётся по горизонтали.
	if _camera != null:
		var ad := _aim_ray_from_dir()
		var from_cam: Vector3 = ad[0]
		var aim_dir: Vector3 = (ad[1] as Vector3).normalized()
		_katana_ray_damage(from_cam, aim_dir, katana_lunge_hit_range)
	else:
		var from_body := global_position + Vector3(0.0, 1.0, 0.0)
		_katana_ray_damage(from_body, dir, katana_lunge_hit_range)
	_katana_swing_t = _katana_swing_len
	return true


func _fire_katana_swing() -> void:
	if _camera == null:
		return
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var dir: Vector3 = (ad[1] as Vector3).normalized()
	_katana_ray_damage(from, dir, katana_range)


func _fire_sawed_off() -> void:
	var scene := get_tree().current_scene
	if scene == null or _camera == null:
		return
	_ensure_sawed_nodes()
	if _sawed_muzzle == null:
		return
	var base_dir := _throw_aim_dir()
	var right := _camera.global_transform.basis.x
	var up := _camera.global_transform.basis.y
	var base_pos := _sawed_muzzle.global_position
	_sawed_volley_seq += 1
	var volley_id := _sawed_volley_seq
	for _i in range(_eff_sawed_pellets()):
		var cube := THROWABLE_CUBE_SCENE.instantiate() as RigidBody3D
		cube.set_meta("_player_spawned", true)
		cube.set_meta("_cube_scale_mul", sawed_pellet_scale)
		cube.set_meta("_sawed_volley_id", volley_id)
		scene.add_child(cube)
		cube.scale = Vector3.ONE * sawed_pellet_scale
		cube.mass = maxf(0.12, 0.85 * pow(sawed_pellet_scale, 3.0))
		cube.global_position = base_pos + right * randf_range(-0.05, 0.05) + up * randf_range(-0.04, 0.04)
		var jitter := right * randf_range(-sawed_spread_jitter, sawed_spread_jitter)
		jitter += up * randf_range(-sawed_spread_jitter, sawed_spread_jitter)
		var dir := (base_dir + jitter).normalized()
		cube.global_rotation = _camera.global_rotation
		cube.linear_velocity = dir * sawed_cube_speed
		cube.angular_velocity = Vector3(
			randf_range(-6.0, 6.0), randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)
		)
		var lbl := cube.get_node_or_null("BrickLabel")
		if lbl:
			lbl.queue_free()
		if _cubes_world_locked:
			cube.freeze = true
			cube.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		_update_throwable_visual(cube)
		ThrowablesBudget.track_throwable(cube)
		_snap_throwable_if_world_time_frozen(cube)


func _fire_stasis_ring() -> void:
	var scene := get_tree().current_scene
	if scene == null or _camera == null:
		return
	_ensure_stasis_nodes()
	if _stasis_muzzle == null:
		return
	var ring := THROWABLE_STASIS_RING_SCENE.instantiate() as RigidBody3D
	ring.add_to_group("stasis_projectile")
	scene.add_child(ring)
	ring.global_position = _stasis_muzzle.global_position
	ring.global_rotation = _camera.global_rotation
	var dir := _throw_aim_dir()
	ring.linear_velocity = dir * stasis_ring_speed
	var spin := dir.cross(Vector3.UP)
	if spin.length_squared() < 1e-5:
		spin = dir.cross(Vector3.RIGHT)
	ring.angular_velocity = spin.normalized() * 20.0
	if _cubes_world_locked:
		ring.freeze = true
		ring.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	ThrowablesBudget.track_throwable(ring)
	_snap_throwable_if_world_time_frozen(ring)


func _fire_gun_pyramid() -> void:
	var scene := get_tree().current_scene
	if scene == null or _camera == null:
		return
	_ensure_gun_nodes()
	if _gun_muzzle == null:
		return
	var pyr := THROWABLE_PYRAMID_SCENE.instantiate() as RigidBody3D
	scene.add_child(pyr)
	pyr.global_position = _gun_muzzle.global_position
	pyr.global_rotation = _camera.global_rotation
	pyr.linear_velocity = _throw_aim_dir() * gun_pyramid_speed
	pyr.angular_velocity = Vector3.ZERO
	if _cubes_world_locked:
		pyr.freeze = true
		pyr.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	_update_throwable_visual(pyr)
	ThrowablesBudget.track_throwable(pyr)
	_snap_throwable_if_world_time_frozen(pyr)


func _fire_animatron_blackhole() -> void:
	if _camera == null:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var bh := ANIMATRON_BLACKHOLE_SCENE.instantiate() as Node3D
	if bh == null:
		return
	scene.add_child(bh)
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var dir: Vector3 = _animatron_aim_dir()
	# Стартуем рядом с камерой и летим по лучу.
	bh.global_position = from + dir * 1.25
	if bh.has_method("set"):
		bh.set("lifetime_sec", animatron_blackhole_lifetime_sec)
		bh.set("suck_radius", _eff_animatron_suck_radius())
		bh.set("suck_accel", _eff_animatron_suck_accel())
		bh.set("suck_up", animatron_suck_up)
		bh.set("fly_speed", animatron_blackhole_fly_speed)
		bh.set("explosion_radius", _eff_animatron_explosion_radius())
		bh.set("explosion_damage", _eff_animatron_explosion_damage())
		bh.set("explosion_knockback", animatron_explosion_knockback)
	if bh.has_method("set_initial_velocity"):
		bh.call("set_initial_velocity", dir * animatron_blackhole_fly_speed)


func _fire_cyber_cannon() -> void:
	if _camera == null:
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var scene := tree.current_scene
	if not is_instance_valid(scene):
		return
	var w := scene.get_world_3d()
	if w == null:
		return
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var dir: Vector3 = (ad[1] as Vector3).normalized()
	var to := from + dir * 160.0
	var space := w.direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = true
	q.collide_with_bodies = true
	q.hit_from_inside = true
	q.exclude = [self]
	var hit := space.intersect_ray(q)
	var p := to
	if not hit.is_empty() and hit.has("position"):
		p = hit["position"] as Vector3

	_spawn_cyber_explosion(p)


func _spawn_cyber_explosion(p: Vector3) -> void:
	notify_quest_banner("Кибер-взрыв!")
	var tree := get_tree()
	if tree == null:
		return
	var r := cyber_explosion_radius
	var r2 := r * r

	for n in tree.get_nodes_in_group("enemy"):
		if not n is Node3D:
			continue
		var e := n as Node3D
		if e.global_position.distance_squared_to(p) > r2:
			continue
		if e.has_method("take_dynamite_explosion"):
			e.call("take_dynamite_explosion", cyber_explosion_damage)
		elif e.has_method("take_damage"):
			e.call("take_damage", cyber_explosion_damage)

	# Разнести то, что игрок может таскать/бросать.
	for n in tree.get_nodes_in_group("throwable"):
		if not n is RigidBody3D:
			continue
		var rb := n as RigidBody3D
		var d2 := rb.global_position.distance_squared_to(p)
		if d2 > r2 or d2 < 0.0001:
			continue
		var k := 1.0 - clampf(sqrt(d2) / maxf(r, 0.01), 0.0, 1.0)
		var dir := (rb.global_position - p).normalized()
		rb.freeze = false
		rb.apply_central_impulse(dir * (65.0 * k) * rb.mass)

	# «Дома и что захочешь»: ломаем маркеры/двери/триггеры лута домов.
	for n in tree.get_nodes_in_group("village_house_loot"):
		if not n is Node:
			continue
		var nd := n as Node
		if nd is Node3D:
			if (nd as Node3D).global_position.distance_squared_to(p) > r2:
				continue
		nd.queue_free()


func _animatron_aim_dir() -> Vector3:
	# Автонаведение: если враг близко к прицелу, летим в него; иначе — по прямому лучу.
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var fwd: Vector3 = (ad[1] as Vector3).normalized()
	var best: Node3D = null
	var best_score := -INF
	var max_d2 := _eff_grapple_max_range() * _eff_grapple_max_range()
	for node in get_tree().get_nodes_in_group("enemy"):
		if not node is Node3D:
			continue
		var e := node as Node3D
		var to := (e.global_position + Vector3(0.0, 2.0, 0.0)) - from
		var d2 := to.length_squared()
		if d2 <= 0.0001 or d2 > max_d2:
			continue
		var dir := to.normalized()
		var dot := fwd.dot(dir)
		# Чем ближе к центру прицела и чем ближе по дистанции — тем лучше.
		var score := dot * 2.0 - sqrt(d2) * 0.01
		if dot > 0.93 and score > best_score:
			best_score = score
			best = e
	if best != null:
		return ((best.global_position + Vector3(0.0, 2.0, 0.0)) - from).normalized()
	return fwd


func _setup_character_visuals() -> void:
	if _character_visual_root != null and is_instance_valid(_character_visual_root):
		return
	_character_visual_root = get_node_or_null("Humanoid") as Node3D
	if _character_visual_root == null:
		_character_visual_root = self


func _switch_character(dir: int) -> void:
	if dir == 0:
		return
	if _is_driving_van():
		exit_van()
	var idx := int(_character_kind) + (1 if dir > 0 else -1)
	if idx < 0:
		idx = int(CharacterKind.CYBER)
	if idx > int(CharacterKind.CYBER):
		idx = 0
	_character_kind = idx as CharacterKind
	_apply_character_profile()


func _apply_character_profile() -> void:
	_setup_character_visuals()
	# Сбрасываем кибер-заряд, чтобы не переносился между персонажами.
	_cyber_charging = false
	_cyber_charge_t = 0.0

	match _character_kind:
		CharacterKind.HERO:
			max_hp = 100
			_equipped = EquippedGun.NONE
			_apply_hat(false, Color.WHITE)
			_ensure_personal_vehicle(null)
			notify_quest_banner("Персонаж: Герой")
		CharacterKind.COWBOY:
			# Шляпа даёт больше HP.
			max_hp = 120
			_apply_hat(true, Color(0.45, 0.28, 0.12, 1.0))
			# Ковбой дружит с катаной/верёвкой как «лассо».
			if _equipped == EquippedGun.CYBER_CANNON:
				_equipped = EquippedGun.KATANA
			if GameProgress.horse_owned and not GameProgress.horse_destroyed:
				_ensure_personal_vehicle(DRIVABLE_HORSE_SCENE)
				notify_quest_banner("Персонаж: Ковбой (HP 120, конь куплен; лассо = верёвка ПКМ/ЛКМ)")
			else:
				_ensure_personal_vehicle(null)
				notify_quest_banner("Персонаж: Ковбой (HP 120). Коня купи на рынке.")
		CharacterKind.CYBER:
			max_hp = 70
			_apply_hat(false, Color.WHITE)
			_equipped = EquippedGun.CYBER_CANNON
			_ensure_personal_vehicle(DRIVABLE_FLYCAR_SCENE)
			notify_quest_banner("Персонаж: Киберчеловек (ЛКМ — заряд киберпушки ~1 мин)")

	_hp = clampi(_hp, 0, max_hp)
	_update_weapon_visibility()
	_update_hp_ui()


func _apply_hat(enabled: bool, color: Color) -> void:
	if not enabled:
		if _character_hat != null and is_instance_valid(_character_hat):
			_character_hat.queue_free()
		_character_hat = null
		return
	if _character_visual_root == null:
		return
	if _character_hat != null and is_instance_valid(_character_hat):
		return
	var hat := Node3D.new()
	hat.name = "CowboyHat"
	_character_visual_root.add_child(hat)
	hat.position = Vector3(0.0, 5.95, 0.0)
	var brim := MeshInstance3D.new()
	var brim_mesh := CylinderMesh.new()
	brim_mesh.top_radius = 1.0
	brim_mesh.bottom_radius = 1.0
	brim_mesh.height = 0.1
	brim_mesh.radial_segments = 18
	brim.mesh = brim_mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	brim.set_surface_override_material(0, m)
	hat.add_child(brim)
	var top := MeshInstance3D.new()
	var top_mesh := CylinderMesh.new()
	top_mesh.top_radius = 0.45
	top_mesh.bottom_radius = 0.55
	top_mesh.height = 0.55
	top_mesh.radial_segments = 18
	top.mesh = top_mesh
	top.position = Vector3(0.0, 0.32, 0.0)
	top.set_surface_override_material(0, m)
	hat.add_child(top)
	_character_hat = hat


func _ensure_personal_vehicle(scene: PackedScene) -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var world := tree.current_scene
	if scene == null:
		if _personal_vehicle != null and is_instance_valid(_personal_vehicle):
			_personal_vehicle.queue_free()
		_personal_vehicle = null
		return
	if _personal_vehicle == null or not is_instance_valid(_personal_vehicle):
		var v := scene.instantiate() as Node3D
		if v == null:
			return
		world.add_child(v)
		v.add_to_group("drivable_van")
		v.add_to_group("personal_vehicle")
		_personal_vehicle = v
	# Подгоняем транспорт рядом с игроком, если он далеко.
	if _personal_vehicle != null and is_instance_valid(_personal_vehicle):
		var want := global_position + Vector3(4.0, 0.0, 3.0)
		if _personal_vehicle.global_position.distance_squared_to(want) > 16.0 * 16.0:
			_personal_vehicle.global_position = want


func _apply_camera_look_smoothing(delta: float) -> void:
	var lk := look_key_speed * delta
	if Input.is_key_pressed(KEY_UP):
		_look_pitch_target = _clamp_pitch_target(_look_pitch_target + lk)
	if Input.is_key_pressed(KEY_DOWN):
		_look_pitch_target = _clamp_pitch_target(_look_pitch_target - lk)

	var smooth_k := 1.0
	if look_smoothing > 0.0:
		smooth_k = 1.0 - exp(-look_smoothing * delta)
	rotation.y = lerp_angle(rotation.y, _look_yaw_target, smooth_k)
	_camera_pivot.rotation.x = lerpf(
		_camera_pivot.rotation.x,
		_look_pitch_target,
		smooth_k
	)
	_clamp_camera_pitch()


func _physics_process(delta: float) -> void:
	if _driving_van != null and is_instance_valid(_driving_van):
		_apply_camera_look_smoothing(delta)
		return
	if _secret_ending_active:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			if velocity.y < 0.0:
				velocity.y = 0.0
		move_and_slide()
		_apply_camera_look_smoothing(delta)
		return
	_autosave_acc += delta
	if _autosave_acc >= AUTOSAVE_INTERVAL_SEC:
		_autosave_acc = 0.0
		GameSave.autosave_if_playing(self)
	var on_floor_before := is_on_floor()
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

	if _jump_requested:
		if is_on_floor():
			velocity.y = jump_velocity
		# Не даём "копить" прыжок в воздухе.
		_jump_requested = false

	var dir2 := Vector2.ZERO
	# Физические позиции WASD — движение не ломается на русской и др. раскладке.
	if Input.is_physical_key_pressed(KEY_A):
		dir2.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		dir2.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		dir2.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		dir2.y += 1.0

	var direction := Vector3.ZERO
	if dir2.length_squared() > 0.0:
		dir2 = dir2.normalized()
		direction = (transform.basis * Vector3(dir2.x, 0.0, dir2.y)).normalized()
		direction.y = 0.0
		if direction.length_squared() > 0.0:
			direction = direction.normalized()

	var target_xz := direction * move_speed
	if _dash_t > 0.0:
		_dash_t = maxf(_dash_t - delta, 0.0)
		velocity.x = _dash_dir.x * dash_speed
		velocity.z = _dash_dir.z * dash_speed
	else:
		velocity.x = target_xz.x
		velocity.z = target_xz.z

	if _grapple_state == GrappleState.PULLING:
		_apply_grapple_pull(delta)
		_grapple_reel = lerpf(_grapple_reel, 1.0, 2.2 * delta)
	_grapple_melee_cd = maxf(_grapple_melee_cd - delta, 0.0)

	var move_vel := velocity
	move_and_slide()
	var on_floor_after := is_on_floor()

	# Урон от падения: считаем минимальную вертикальную скорость в полёте и применяем при приземлении.
	if not on_floor_before:
		_fall_min_vy = minf(_fall_min_vy, velocity.y)
	if (not _was_on_floor) and on_floor_after:
		var impact_speed := -_fall_min_vy
		_fall_min_vy = 0.0
		if impact_speed > fall_damage_min_speed:
			var t := clampf(
				(impact_speed - fall_damage_min_speed) / maxf(fall_damage_max_speed - fall_damage_min_speed, 0.001),
				0.0,
				1.0
			)
			var dmg := maxi(1, roundi(float(fall_damage_max) * t))
			take_damage(dmg, "fall")
	_was_on_floor = on_floor_after
	if is_on_floor() and _grapple_state == GrappleState.ROPE_READY:
		_clear_grapple()
	_apply_body_pushes(move_vel)

	_apply_camera_look_smoothing(delta)

	if _held:
		_held.global_position = _hold_point.global_position
		_held.linear_velocity = Vector3.ZERO
		_held.angular_velocity = Vector3.ZERO
	if _held_enemy:
		_held_enemy.global_position = _hold_point.global_position

	_update_enlarge_hint_target()
	_update_aim_feedback()
	_update_grapple_rope_visual()
	if _enlarge_hint_rb != _prev_enlarge_hint_rb:
		_prev_enlarge_hint_rb = _enlarge_hint_rb
		_refresh_all_throwable_visuals()


func _setup_aim_feedback() -> void:
	if _crosshair_layer == null:
		_crosshair_layer = CanvasLayer.new()
		_crosshair_layer.layer = 100
		add_child(_crosshair_layer)
		var root := Control.new()
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_crosshair_layer.add_child(root)
		var cc := CenterContainer.new()
		cc.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(cc)
		var cross := Control.new()
		cross.custom_minimum_size = Vector2(22, 22)
		var vbar := ColorRect.new()
		vbar.position = Vector2(10, 3)
		vbar.size = Vector2(2, 16)
		vbar.color = Color(1, 1, 1, 0.92)
		var hbar := ColorRect.new()
		hbar.position = Vector2(3, 10)
		hbar.size = Vector2(16, 2)
		hbar.color = Color(1, 1, 1, 0.92)
		cross.add_child(vbar)
		cross.add_child(hbar)
		cc.add_child(cross)

	if _hit_marker == null:
		var scene := get_tree().current_scene
		if scene == null:
			return
		_hit_marker = MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.065
		sm.height = 0.13
		_hit_marker.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.9, 0.2, 0.95)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_hit_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_hit_marker.material_override = mat
		_hit_marker.visible = false
		scene.add_child(_hit_marker)


func _update_aim_feedback() -> void:
	if _hit_marker == null or _camera == null or not is_inside_tree():
		return
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if _crosshair_layer:
			_crosshair_layer.visible = true
	else:
		if _crosshair_layer:
			_crosshair_layer.visible = false
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var dir: Vector3 = ad[1]

	var w := get_world_3d()
	if w == null:
		return
	var space := w.direct_space_state
	if space == null:
		return
	var q := PhysicsRayQueryParameters3D.create(from, from + dir.normalized() * aim_ray_length)
	q.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		_hit_marker.visible = false
		return
	var n := Vector3.UP
	if hit.has("normal"):
		n = hit["normal"] as Vector3
	_hit_marker.global_position = hit.position as Vector3 + n * 0.04
	_hit_marker.visible = true


func _get_throwable_mesh(rb: RigidBody3D) -> MeshInstance3D:
	return rb.get_node_or_null("MeshInstance3D") as MeshInstance3D


func _is_enlargeable_brick_box(rb: RigidBody3D) -> bool:
	if rb == null:
		return false
	if rb.name == "Cube":
		return true
	if rb.name.begins_with("BrickShard"):
		var m := _get_throwable_mesh(rb)
		return m != null and m.mesh is BoxMesh
	return false


func _raycast_aimed_enlarge_box(max_dist: float) -> RigidBody3D:
	var rb := _raycast_aimed_throwable_passthrough(max_dist)
	if rb != null and _is_enlargeable_brick_box(rb):
		return rb
	rb = _nearest_enlargeable_box_on_aim(max_dist)
	return rb


func _raycast_aimed_throwable_passthrough(max_dist: float) -> RigidBody3D:
	var ad := _aim_ray_from_dir()
	var pos: Vector3 = ad[0]
	var dir: Vector3 = (ad[1] as Vector3).normalized()
	var w := get_world_3d()
	if w == null:
		return null
	var space := w.direct_space_state
	if space == null:
		return null
	var excl: Array[RID] = [get_rid()]
	if _held != null and is_instance_valid(_held):
		excl.append(_held.get_rid())
	var total := 0.0
	const BUMP := 0.1
	const MAX_STEPS := 48
	for _step in MAX_STEPS:
		if total >= max_dist - 0.001:
			break
		var seg_end := pos + dir * (max_dist - total)
		var q := PhysicsRayQueryParameters3D.create(pos, seg_end)
		q.collide_with_areas = false
		q.collide_with_bodies = true
		q.hit_from_inside = true
		q.exclude = excl
		var hit: Dictionary = space.intersect_ray(q)
		if hit.is_empty():
			return null
		var col: Object = hit["collider"]
		if col is RigidBody3D and col.is_in_group("throwable"):
			return col as RigidBody3D
		if not col is CollisionObject3D:
			return null
		var rid: RID = (col as CollisionObject3D).get_rid()
		var already := false
		for e in excl:
			if e == rid:
				already = true
				break
		if not already:
			excl.append(rid)
		var hp: Vector3 = hit["position"] as Vector3
		var traveled: float = pos.distance_to(hp) + BUMP
		total += traveled
		pos = hp + dir * BUMP
	return null


func _nearest_enlargeable_box_on_aim(max_dist: float) -> RigidBody3D:
	var ad := _aim_ray_from_dir()
	var o: Vector3 = ad[0]
	var dir: Vector3 = (ad[1] as Vector3).normalized()
	var best: RigidBody3D = null
	var best_t := INF
	var sep_lim := maxf(3.5, max_dist * 0.07)
	var sep2 := sep_lim * sep_lim
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var cand := node as RigidBody3D
		if cand == _held or not _is_enlargeable_brick_box(cand):
			continue
		var rel := cand.global_position - o
		var t := rel.dot(dir)
		if t < 0.15 or t > max_dist:
			continue
		var perp2 := rel.length_squared() - t * t
		if perp2 > sep2:
			continue
		if best == null or t < best_t:
			best_t = t
			best = cand
	return best


func _enlarge_pick_ray_distance() -> float:
	return maxf(cube_enlarge_ray_distance, aim_ray_length)

func _find_oldest_full_map_cube(except_rb: RigidBody3D) -> RigidBody3D:
	var lim := cube_enlarge_max_scale
	const EPS := 0.03
	var best: RigidBody3D = null
	var best_tick := INF
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var rb := node as RigidBody3D
		if rb == except_rb or rb == _held:
			continue
		if not _is_enlargeable_brick_box(rb):
			continue
		if rb.get_meta("_player_spawned", false):
			continue
		var m := float(rb.get_meta("_cube_scale_mul", 1.0))
		if m < lim - EPS:
			continue
		var tick := float(rb.get_meta("_full_reached_tick", 0.0))
		if tick <= 0.0:
			# Если это "старый" куб без меты — считаем его самым старым.
			tick = -1.0
		if best == null or tick < best_tick:
			best = rb
			best_tick = tick
	return best

func _can_replace_full_map_cube(except_rb: RigidBody3D) -> bool:
	if _count_map_cubes_at_full_enlarge() < max_cubes_at_full_enlarge:
		return true
	return _find_oldest_full_map_cube(except_rb) != null


## Кубы с карты (без _player_spawned): не больше max_cubes_at_full_enlarge на пределе. Кубы Shift+Q / человекоид не участвуют в этом лимите и могут вырасти до cube_enlarge_max_scale, как кирпич на сцене.
func _count_map_cubes_at_full_enlarge() -> int:
	var n := 0
	var lim := cube_enlarge_max_scale
	const EPS := 0.03
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var rb := node as RigidBody3D
		if not _is_enlargeable_brick_box(rb):
			continue
		if rb.get_meta("_player_spawned", false):
			continue
		var m := float(rb.get_meta("_cube_scale_mul", 1.0))
		if m >= lim - EPS:
			n += 1
	return n


func _try_enlarge_cube() -> bool:
	var aimed := _raycast_aimed_enlarge_box(_enlarge_pick_ray_distance())
	if aimed != null and _enlarge_would_apply(aimed):
		_enlarge_cube(aimed)
		return true
	if _held != null and _is_enlargeable_brick_box(_held) and _enlarge_would_apply(_held):
		_enlarge_cube(_held)
		return true
	return false


func _update_enlarge_hint_target() -> void:
	var aimed := _raycast_aimed_enlarge_box(_enlarge_pick_ray_distance())
	if aimed != null and _enlarge_would_apply(aimed):
		_enlarge_hint_rb = aimed
		return
	if _held != null and _is_enlargeable_brick_box(_held) and _enlarge_would_apply(_held):
		_enlarge_hint_rb = _held
		return
	_enlarge_hint_rb = null


func _enlarge_would_apply(rb: RigidBody3D) -> bool:
	if rb == null or not is_instance_valid(rb) or not _is_enlargeable_brick_box(rb):
		return false
	var mul: float = float(rb.get_meta("_cube_scale_mul", 1.0))
	var new_mul := minf(mul * cube_enlarge_factor, cube_enlarge_max_scale)
	var ratio := new_mul / mul
	if ratio <= 1.0001:
		return false
	const EPS := 0.03
	var was_below_full := mul < cube_enlarge_max_scale - EPS
	var hits_full := new_mul >= cube_enlarge_max_scale - EPS
	if was_below_full and hits_full:
		if not rb.get_meta("_player_spawned", false):
			if not _can_replace_full_map_cube(rb):
				return false
	return true


func _enlarge_cube(rb: RigidBody3D) -> void:
	if not _enlarge_would_apply(rb):
		return
	var mul: float = float(rb.get_meta("_cube_scale_mul", 1.0))
	var new_mul := minf(mul * cube_enlarge_factor, cube_enlarge_max_scale)
	var ratio := new_mul / mul
	const EPS := 0.03
	var was_below_full := mul < cube_enlarge_max_scale - EPS
	var hits_full := new_mul >= cube_enlarge_max_scale - EPS
	if was_below_full and hits_full and not rb.get_meta("_player_spawned", false):
		if _count_map_cubes_at_full_enlarge() >= max_cubes_at_full_enlarge:
			var victim := _find_oldest_full_map_cube(rb)
			if is_instance_valid(victim):
				victim.queue_free()

	# Замороженные заспавненные кубы (мир/человекоид): без кадра без freeze коллизия может не обновиться.
	var restore_frozen_static := (
		rb != _held
		and rb.freeze
		and rb.freeze_mode == RigidBody3D.FREEZE_MODE_STATIC
	)
	if restore_frozen_static:
		rb.freeze = false

	rb.set_meta("_cube_scale_mul", new_mul)
	if hits_full and not rb.get_meta("_player_spawned", false) and not rb.has_meta("_full_reached_tick"):
		rb.set_meta("_full_reached_tick", float(Time.get_ticks_usec()))

	var mesh_i := _get_throwable_mesh(rb)
	var col_n := rb.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if mesh_i and mesh_i.mesh is BoxMesh:
		var bm := (mesh_i.mesh as BoxMesh).duplicate() as BoxMesh
		bm.size *= ratio
		mesh_i.mesh = bm
	if col_n and col_n.shape is BoxShape3D:
		var bs := (col_n.shape as BoxShape3D).duplicate() as BoxShape3D
		bs.size *= ratio
		col_n.shape = bs

	rb.mass *= pow(ratio, 3.0)
	if rb.has_method("_shatter_and_free"):
		rb.shatter_shard_size *= ratio
		rb.min_shard_size *= ratio

	var label := rb.get_node_or_null("BrickLabel") as Node3D
	if label:
		label.position *= ratio

	if restore_frozen_static:
		rb.freeze = true
		rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC

	_update_enlarge_hint_target()
	_prev_enlarge_hint_rb = _enlarge_hint_rb
	_refresh_all_throwable_visuals()


func _ensure_throwable_material(mesh: MeshInstance3D) -> StandardMaterial3D:
	var body := mesh.get_parent() as RigidBody3D
	var ovr := mesh.get_surface_override_material(0) as StandardMaterial3D
	if ovr:
		if body and not body.has_meta("_free_albedo"):
			body.set_meta("_free_albedo", ovr.albedo_color)
		return ovr
	var src: Material = null
	if mesh.mesh:
		src = mesh.mesh.surface_get_material(0)
	if src is StandardMaterial3D:
		ovr = (src as StandardMaterial3D).duplicate() as StandardMaterial3D
	else:
		ovr = StandardMaterial3D.new()
		ovr.albedo_color = THROWABLE_COLOR_FREE
	mesh.set_surface_override_material(0, ovr)
	if body and not body.has_meta("_free_albedo"):
		body.set_meta("_free_albedo", ovr.albedo_color)
	return ovr


func _update_throwable_visual(rb: RigidBody3D) -> void:
	if rb == null or not is_instance_valid(rb):
		return
	if rb.name == "StasisRing" or rb.is_in_group("stasis_projectile"):
		return
	var mesh := _get_throwable_mesh(rb)
	if mesh == null:
		return
	var mat := _ensure_throwable_material(mesh)
	var free_col := THROWABLE_COLOR_FREE
	if rb.has_meta("_free_albedo"):
		free_col = rb.get_meta("_free_albedo") as Color
	if rb == _enlarge_hint_rb and _enlarge_would_apply(rb):
		mat.albedo_color = THROWABLE_COLOR_ENLARGE_HINT
	elif rb == _held:
		mat.albedo_color = free_col
	elif rb.freeze:
		mat.albedo_color = THROWABLE_COLOR_FIXED
	else:
		mat.albedo_color = free_col


func _refresh_all_throwable_visuals() -> void:
	for node in get_tree().get_nodes_in_group("throwable"):
		if node is RigidBody3D:
			_update_throwable_visual(node as RigidBody3D)


func _spawn_throwable_cube() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var cube := THROWABLE_CUBE_SCENE.instantiate() as RigidBody3D
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
	else:
		forward = Vector3(0.0, 0.0, -1.0)
	var spawn_pos := global_position + forward * cube_spawn_distance
	spawn_pos.y = global_position.y + 0.5
	cube.set_meta("_player_spawned", true)
	cube.set_meta("_cube_scale_mul", 1.0)
	scene.add_child(cube)
	cube.global_position = spawn_pos
	cube.linear_velocity = Vector3.ZERO
	cube.angular_velocity = Vector3.ZERO
	if _cubes_world_locked:
		cube.freeze = true
		cube.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	if _last_spawned_exit_cb.is_valid():
		var prev := _last_player_spawned_cube
		if is_instance_valid(prev) and prev.tree_exiting.is_connected(_last_spawned_exit_cb):
			prev.tree_exiting.disconnect(_last_spawned_exit_cb)
	_last_player_spawned_cube = cube
	_last_spawned_exit_cb = _on_last_spawned_cube_exiting.bind(cube)
	cube.tree_exiting.connect(_last_spawned_exit_cb)
	_update_throwable_visual(cube)
	ThrowablesBudget.track_throwable(cube)
	_snap_throwable_if_world_time_frozen(cube)
	heal(5)


func _on_last_spawned_cube_exiting(cube: RigidBody3D) -> void:
	if _last_player_spawned_cube == cube:
		_last_player_spawned_cube = null


func _throw_dynamite() -> void:
	if _is_driving_van():
		return
	if GameProgress.dynamite_stock <= 0:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var dyn := DYNAMITE_SCENE.instantiate() as RigidBody3D
	if dyn == null:
		return
	var dir := _throw_aim_dir()
	var spawn_pos := global_position + Vector3(0.0, 1.15, 0.0) + dir * 0.65
	scene.add_child(dyn)
	dyn.global_position = spawn_pos
	dyn.linear_velocity = dir * 15.0
	dyn.angular_velocity = Vector3(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	_spawn_dynamite_throw_fire_fx(spawn_pos)
	GameProgress.dynamite_stock -= 1
	GameProgress.upgrades_changed.emit()
	_update_hp_ui()


func _spawn_dynamite_throw_fire_fx(at: Vector3) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var root := Node3D.new()
	root.name = "DynamiteThrowFireFx"
	scene.add_child(root)
	root.global_position = at
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.42, 0.12)
	light.light_energy = 2.2
	light.omni_range = 4.2
	light.shadow_enabled = false
	root.add_child(light)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.28
	sm.height = sm.radius * 2.0
	sm.radial_segments = 10
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.38, 0.08, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.48, 0.1)
	mat.emission_energy_multiplier = 2.8
	mi.set_surface_override_material(0, mat)
	root.add_child(mi)
	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	root.add_child(timer)
	timer.timeout.connect(root.queue_free)
	timer.start()


func _spawn_throwable_pyramid() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var pyr := THROWABLE_PYRAMID_SCENE.instantiate() as RigidBody3D
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
	else:
		forward = Vector3(0.0, 0.0, -1.0)
	var spawn_pos := global_position + forward * cube_spawn_distance
	spawn_pos.y = global_position.y + pyramid_spawn_height
	scene.add_child(pyr)
	pyr.global_position = spawn_pos
	pyr.linear_velocity = Vector3.ZERO
	pyr.angular_velocity = Vector3.ZERO
	if _cubes_world_locked:
		pyr.freeze = true
		pyr.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	_update_throwable_visual(pyr)
	ThrowablesBudget.track_throwable(pyr)
	_snap_throwable_if_world_time_frozen(pyr)


func _toggle_cubes_world_lock() -> void:
	_cubes_world_locked = not _cubes_world_locked
	_apply_throwables_world_lock()


func _unlock_cubes_world() -> void:
	_cubes_world_locked = false
	_apply_throwables_world_lock()


func _apply_throwables_world_lock() -> void:
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var rb := node as RigidBody3D
		if rb == _held:
			continue
		rb.freeze = _cubes_world_locked
		if _cubes_world_locked:
			rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
			rb.linear_velocity = Vector3.ZERO
			rb.angular_velocity = Vector3.ZERO
	_refresh_all_throwable_visuals()


func _toggle_world_time_freeze() -> void:
	if GameProgress.world_time_frozen:
		_resume_world_time()
	else:
		_freeze_world_time()


func _freeze_world_time() -> void:
	if GameProgress.world_time_frozen:
		return
	GameProgress.world_time_frozen = true
	_world_time_snap.clear()
	for grp in ["enemy", "village_katana_mob", "castle_guard"]:
		for node in get_tree().get_nodes_in_group(grp):
			if not node is CharacterBody3D:
				continue
			var e := node as CharacterBody3D
			if not e.is_inside_tree():
				continue
			_world_time_snap[e] = {"vel": e.velocity}
			e.velocity = Vector3.ZERO
			e.set_physics_process(false)
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var rb := node as RigidBody3D
		if rb == _held or rb.is_in_group("held_throwable"):
			continue
		if not rb.is_inside_tree():
			continue
		_world_time_snap[rb] = {
			"lv": rb.linear_velocity,
			"av": rb.angular_velocity,
		}
		rb.freeze = true
		rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	_refresh_all_throwable_visuals()


func _resume_world_time() -> void:
	if not GameProgress.world_time_frozen:
		return
	GameProgress.world_time_frozen = false
	for node in _world_time_snap.keys():
		if not is_instance_valid(node):
			continue
		if node is CharacterBody3D:
			var e := node as CharacterBody3D
			var en := e as Node
			if (
				en.is_in_group("enemy")
				or en.is_in_group("village_katana_mob")
				or en.is_in_group("castle_guard")
			):
				e.set_physics_process(true)
				var st_e: Dictionary = _world_time_snap[node]
				e.velocity = st_e.get("vel", Vector3.ZERO) as Vector3
		elif node is RigidBody3D:
			var rb := node as RigidBody3D
			var st: Dictionary = _world_time_snap[node]
			rb.freeze = false
			rb.linear_velocity = st.get("lv", Vector3.ZERO) as Vector3
			rb.angular_velocity = st.get("av", Vector3.ZERO) as Vector3
	_world_time_snap.clear()
	_apply_throwables_world_lock()
	_refresh_all_throwable_visuals()


func _snap_throwable_if_world_time_frozen(rb: RigidBody3D) -> void:
	if rb == null or not is_instance_valid(rb):
		return
	if not GameProgress.world_time_frozen:
		return
	if rb == _held or rb.is_in_group("held_throwable"):
		return
	_world_time_snap[rb] = {"lv": rb.linear_velocity, "av": rb.angular_velocity}
	rb.freeze = true
	rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC


func _raycast_aimed_throwable(max_dist: float) -> RigidBody3D:
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var dir: Vector3 = (ad[1] as Vector3).normalized()
	var w := get_world_3d()
	if w == null:
		return null
	var space := w.direct_space_state
	if space == null:
		return null
	var to := from + dir * max_dist
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = true
	var excl: Array[RID] = [get_rid()]
	if _held != null and is_instance_valid(_held):
		excl.append(_held.get_rid())
	query.exclude = excl
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty() or not hit.has("collider"):
		return null
	var col: Object = hit["collider"]
	if col is RigidBody3D and col.is_in_group("throwable"):
		return col as RigidBody3D
	return null


func _raycast_aimed_enemy(max_dist: float) -> CharacterBody3D:
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var dir: Vector3 = (ad[1] as Vector3).normalized()
	var w := get_world_3d()
	if w == null:
		return null
	var space := w.direct_space_state
	if space == null:
		return null
	var to := from + dir * max_dist
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = true
	var excl: Array[RID] = [get_rid()]
	if _held != null and is_instance_valid(_held):
		excl.append(_held.get_rid())
	query.exclude = excl
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty() or not hit.has("collider"):
		return null
	var col: Object = hit["collider"]
	if not col is Node:
		return null
	var n := col as Node
	while n != null:
		if n.is_in_group("enemy") and n is CharacterBody3D:
			var cb := n as CharacterBody3D
			if bool(cb.get("is_boss")):
				return null
			return cb
		n = n.get_parent()
	return null


func _raycast_aimed_quest_npc(max_dist: float) -> Node:
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var dir: Vector3 = (ad[1] as Vector3).normalized()
	var w := get_world_3d()
	if w == null:
		return null
	var space := w.direct_space_state
	if space == null:
		return null
	var to := from + dir * max_dist
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = true
	var excl: Array[RID] = [get_rid()]
	if _held != null and is_instance_valid(_held):
		excl.append(_held.get_rid())
	query.exclude = excl
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty() or not hit.has("collider"):
		return null
	var col: Object = hit["collider"]
	if not col is Node:
		return null
	var n := col as Node
	while n != null:
		if n.is_in_group("talkable_npc"):
			return n
		n = n.get_parent()
	return null


func _raycast_aimed_village_house_loot(max_dist: float) -> Node:
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var dir: Vector3 = (ad[1] as Vector3).normalized()
	var w := get_world_3d()
	if w == null:
		return null
	var space := w.direct_space_state
	if space == null:
		return null
	var to := from + dir * max_dist
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = true
	var excl: Array[RID] = [get_rid()]
	if _held != null and is_instance_valid(_held):
		excl.append(_held.get_rid())
	query.exclude = excl
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty() or not hit.has("collider"):
		return null
	var col: Object = hit["collider"]
	if not col is Node:
		return null
	var n := col as Node
	while n != null:
		if n.is_in_group("village_house_loot"):
			return n
		n = n.get_parent()
	return null


func _try_interact_village_house_loot() -> bool:
	if not _world_actions_input_ok():
		return false
	if _shop_open or _pause_visible:
		return false
	if _is_driving_van():
		return false
	var h := _raycast_aimed_village_house_loot(4.0)
	if h == null:
		return false
	if h.has_method("interact"):
		h.call("interact", self)
		return true
	return false


func _try_interact_quest_npc() -> bool:
	if not _world_actions_input_ok():
		return false
	if _shop_open or _pause_visible:
		return false
	if _is_driving_van():
		return false
	var npc := _raycast_aimed_quest_npc(4.2)
	if npc == null:
		return false
	if npc.has_method("interact"):
		npc.call("interact", self)
		return true
	return false


func _raycast_aimed_puzzle_lever(max_dist: float) -> Node:
	var ad := _aim_ray_from_dir()
	var from: Vector3 = ad[0]
	var dir: Vector3 = (ad[1] as Vector3).normalized()
	var w := get_world_3d()
	if w == null:
		return null
	var space := w.direct_space_state
	if space == null:
		return null
	var to := from + dir * max_dist
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.hit_from_inside = true
	var excl: Array[RID] = [get_rid()]
	if _held != null and is_instance_valid(_held):
		excl.append(_held.get_rid())
	query.exclude = excl
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty() or not hit.has("collider"):
		return null
	var col: Object = hit["collider"]
	if not col is Node:
		return null
	var n := col as Node
	while n != null:
		if n.is_in_group("puzzle_lever"):
			return n
		n = n.get_parent()
	return null


func _try_interact_puzzle_lever() -> bool:
	if not _world_actions_input_ok():
		return false
	if _shop_open or _pause_visible:
		return false
	if _is_driving_van():
		return false
	var lev := _raycast_aimed_puzzle_lever(3.8)
	if lev == null:
		return false
	if lev.has_method("interact"):
		lev.call("interact", self)
		return true
	return false


func _find_nearest_throwable(from_rb: RigidBody3D, max_dist: float) -> RigidBody3D:
	var best: RigidBody3D = null
	var best_d2 := max_dist * max_dist
	for node in get_tree().get_nodes_in_group("throwable"):
		if not node is RigidBody3D:
			continue
		var rb := node as RigidBody3D
		if rb == from_rb or rb == _held:
			continue
		var d2 := from_rb.global_position.distance_squared_to(rb.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = rb
	return best


func _humanoid_floor_anchor() -> Vector3:
	var flat_fwd := -global_transform.basis.z
	flat_fwd.y = 0.0
	if flat_fwd.length_squared() < 1e-5:
		flat_fwd = Vector3(0.0, 0.0, -1.0)
	else:
		flat_fwd = flat_fwd.normalized()
	var origin := global_position + flat_fwd * humanoid_spawn_forward + Vector3(0, 4.0, 0)
	var w := get_world_3d()
	if w == null:
		return global_position + flat_fwd * humanoid_spawn_forward + Vector3(0, 0.5, 0.0)
	var space := w.direct_space_state
	if space == null:
		return global_position + flat_fwd * humanoid_spawn_forward + Vector3(0, 0.5, 0.0)
	var excl: Array[RID] = [get_rid()]
	if _held:
		excl.append(_held.get_rid())
	var q := PhysicsRayQueryParameters3D.create(origin, origin + Vector3(0, -40.0, 0))
	q.exclude = excl
	var hit: Dictionary = space.intersect_ray(q)
	if not hit.is_empty() and hit.has("position"):
		return hit.position as Vector3
	return global_position + flat_fwd * humanoid_spawn_forward + Vector3(0, 0.5, 0.0)


func _arrange_cubes_humanoid() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var anchor := _humanoid_floor_anchor()
	var yaw_basis := Basis.from_euler(Vector3(0.0, rotation.y, 0.0))
	for off in _HUMANOID_CUBE_LOCAL:
		var world_pos := anchor + yaw_basis * off
		var cube := THROWABLE_CUBE_SCENE.instantiate() as RigidBody3D
		cube.set_meta("_player_spawned", true)
		scene.add_child(cube)
		cube.global_position = world_pos
		cube.global_rotation = Vector3.ZERO
		cube.linear_velocity = Vector3.ZERO
		cube.angular_velocity = Vector3.ZERO
		cube.freeze = true
		cube.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		_update_throwable_visual(cube)
		ThrowablesBudget.track_throwable(cube)
		_snap_throwable_if_world_time_frozen(cube)
		heal(5)


func _glue_joint_pair_exists(scene: Node, a: RigidBody3D, b: RigidBody3D) -> bool:
	var pa := scene.get_path_to(a)
	var pb := scene.get_path_to(b)
	for child in scene.get_children():
		if not child is PinJoint3D:
			continue
		var j := child as PinJoint3D
		var ja := j.node_a
		var jb := j.node_b
		if (ja == pa and jb == pb) or (ja == pb and jb == pa):
			return true
	return false


func _try_glue_throwable_cubes() -> void:
	if GameProgress.world_time_frozen:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var a := _raycast_aimed_throwable(glue_look_distance)
	if a == null or a == _held:
		return
	var b := _find_nearest_throwable(a, glue_pair_max_distance)
	if b == null:
		return
	if _glue_joint_pair_exists(scene, a, b):
		return
	_unlock_cubes_world()
	a.freeze = false
	b.freeze = false
	a.linear_velocity = Vector3.ZERO
	b.linear_velocity = Vector3.ZERO
	a.angular_velocity = Vector3.ZERO
	b.angular_velocity = Vector3.ZERO
	var joint := PinJoint3D.new()
	joint.name = "CubeGlue_%s" % str(Time.get_ticks_msec())
	joint.add_to_group("cube_glue")
	scene.add_child(joint)
	joint.global_position = (a.global_position + b.global_position) * 0.5
	joint.node_a = scene.get_path_to(a)
	joint.node_b = scene.get_path_to(b)
	joint.set_param(PinJoint3D.PARAM_BIAS, 0.65)
	joint.set_param(PinJoint3D.PARAM_DAMPING, 1.15)
	_update_throwable_visual(a)
	_update_throwable_visual(b)


func _apply_body_pushes(move_velocity: Vector3) -> void:
	var v_h := Vector3(move_velocity.x, 0.0, move_velocity.z)
	if v_h.length_squared() < 0.0001:
		return
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var col := c.get_collider()
		if not col is RigidBody3D:
			continue
		var rb := col as RigidBody3D
		if rb.freeze or rb == _held:
			continue
		var n := c.get_normal()
		var n_h := Vector3(n.x, 0.0, n.z)
		if n_h.length_squared() < 0.0001:
			continue
		n_h = n_h.normalized()
		var speed_into := v_h.dot(-n_h)
		if speed_into <= 0.0:
			continue
		rb.apply_central_impulse(-n_h * speed_into * rb.mass * body_push_multiplier)


func enter_van(van: Node3D) -> void:
	if van == null or not is_instance_valid(van) or not van.has_method("set_driver"):
		return
	if van.has_method("is_van_operable") and not bool(van.call("is_van_operable")):
		return
	if _driving_van != null:
		return
	if van.has_method("has_driver") and bool(van.call("has_driver")):
		return
	_driving_van = van
	_van_saved_parent = get_parent()
	_van_saved_index = get_index()
	_van_saved_layer = collision_layer
	_van_saved_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	_van_saved_parent.remove_child(self)
	van.add_child(self)
	position = Vector3(0.0, 0.72, 0.35)
	rotation = Vector3.ZERO
	van.call("set_driver", self)
	_update_weapon_visibility()
	_update_hp_ui()


func exit_van() -> void:
	if _driving_van == null:
		return
	var van_ref: Node3D = _driving_van
	_driving_van = null

	var exit_g: Vector3
	if is_instance_valid(van_ref):
		if van_ref.has_method("clear_driver"):
			van_ref.call("clear_driver")
		var xform := van_ref.global_transform
		exit_g = van_ref.global_position + xform.basis.x * 2.85 + Vector3(0.0, 0.55, 0.0)
	else:
		exit_g = global_position + Vector3(2.5, 0.0, 0.0)

	var par := get_parent()
	if par != null and is_instance_valid(par):
		par.remove_child(self)

	var p := _van_saved_parent
	if p == null or not is_instance_valid(p):
		var tree := get_tree()
		if tree != null:
			p = tree.current_scene

	if p != null and is_instance_valid(p):
		p.add_child(self)
		var nch := p.get_child_count()
		p.move_child(self, clampi(_van_saved_index, 0, maxi(0, nch - 1)))

	global_position = exit_g
	rotation = Vector3.ZERO
	collision_layer = _van_saved_layer
	collision_mask = _van_saved_mask
	_update_weapon_visibility()
	_update_hp_ui()


func _try_enter_van() -> bool:
	if _driving_van != null and is_instance_valid(_driving_van):
		return false
	if _held or (_held_enemy != null and is_instance_valid(_held_enemy)):
		return false
	var r2 := van_interact_distance * van_interact_distance
	var best: Node3D = null
	var best_d2 := INF
	for n in get_tree().get_nodes_in_group("drivable_van"):
		if not n is Node3D:
			continue
		var v := n as Node3D
		if v.has_method("is_van_operable") and not bool(v.call("is_van_operable")):
			continue
		if v.has_method("has_driver") and bool(v.call("has_driver")):
			continue
		var d2 := global_position.distance_squared_to(v.global_position)
		if d2 > r2:
			continue
		if d2 < best_d2:
			best_d2 = d2
			best = v
	if best == null:
		return false
	enter_van(best)
	return true


func _try_pickup() -> void:
	if _try_enter_van():
		return
	if _held_enemy != null and is_instance_valid(_held_enemy):
		return
	var collider := _raycast_aimed_throwable(pickup_distance)
	if collider != null:
		_held = collider
		_held.add_to_group("held_throwable")
		add_collision_exception_with(_held)
		_held.freeze = true
		_held.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		_throw_press_usec = -1
		_update_throwable_visual(_held)
		return

	# Если не нашли "throwable" — пробуем схватить врага.
	var e := _raycast_aimed_enemy(pickup_distance)
	if e == null:
		return
	_held_enemy = e
	add_collision_exception_with(_held_enemy)
	_held_enemy.velocity = Vector3.ZERO
	_held_enemy.set_physics_process(false)
	_throw_press_usec = -1


func _release_held() -> void:
	if not _held:
		return
	var body := _held
	body.remove_from_group("held_throwable")
	remove_collision_exception_with(body)
	body.freeze = _cubes_world_locked
	if _cubes_world_locked:
		body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	_held = null
	_throw_press_usec = -1
	_update_throwable_visual(body)


func _release_held_enemy() -> void:
	if _held_enemy == null or not is_instance_valid(_held_enemy):
		_held_enemy = null
		return
	var e := _held_enemy
	remove_collision_exception_with(e)
	e.set_physics_process(true)
	_held_enemy = null
	_throw_press_usec = -1


func _apply_throw_body(body: RigidBody3D, dir: Vector3, speed: float) -> void:
	body.remove_from_group("held_throwable")
	remove_collision_exception_with(body)
	body.freeze = false
	body.linear_velocity = dir * speed
	_held = null
	_throw_press_usec = -1
	_update_throwable_visual(body)
	_snap_throwable_if_world_time_frozen(body)


func _throw_held_tap() -> void:
	if _held:
		var body := _held
		var charge := clampf(throw_tap_charge, 0.0, 1.0)
		var speed := lerpf(throw_speed_min, throw_speed_max, charge)
		_apply_throw_body(body, _throw_aim_dir(), speed)
		return
	if _held_enemy != null and is_instance_valid(_held_enemy):
		var dir := _throw_aim_dir()
		var charge2 := clampf(throw_tap_charge, 0.0, 1.0)
		var speed2 := lerpf(throw_speed_min, throw_speed_max, charge2)
		var e := _held_enemy
		remove_collision_exception_with(e)
		e.set_physics_process(true)
		if e.has_method("apply_thrown_velocity"):
			e.call("apply_thrown_velocity", dir * speed2, 0.7)
		else:
			e.velocity = dir * speed2
		_held_enemy = null
		_throw_press_usec = -1


func _throw_held_charged() -> void:
	if _held:
		var body := _held
		var elapsed_sec := (Time.get_ticks_usec() - _throw_press_usec) / 1_000_000.0
		_throw_press_usec = -1
		elapsed_sec = maxf(elapsed_sec, 0.0)
		var charge := clampf(elapsed_sec / maxf(throw_charge_full_time, 0.05), 0.0, 1.0)
		var speed := lerpf(throw_speed_min, throw_speed_max, charge)
		_apply_throw_body(body, _throw_aim_dir(), speed)
		return
	if _held_enemy == null or not is_instance_valid(_held_enemy):
		_throw_press_usec = -1
		_held_enemy = null
		return
	var elapsed_sec2 := (Time.get_ticks_usec() - _throw_press_usec) / 1_000_000.0
	_throw_press_usec = -1
	elapsed_sec2 = maxf(elapsed_sec2, 0.0)
	var charge2 := clampf(elapsed_sec2 / maxf(throw_charge_full_time, 0.05), 0.0, 1.0)
	var speed2 := lerpf(throw_speed_min, throw_speed_max, charge2)
	var dir2 := _throw_aim_dir()
	var e2 := _held_enemy
	remove_collision_exception_with(e2)
	e2.set_physics_process(true)
	if e2.has_method("apply_thrown_velocity"):
		e2.call("apply_thrown_velocity", dir2 * speed2, 0.9)
	else:
		e2.velocity = dir2 * speed2
	_held_enemy = null


## Корень оверлея карты: при паузе сцены ввод к игроку не доходит — ловим M/Esc здесь (PROCESS_MODE_ALWAYS).
class WorldMapOverlayRoot extends ColorRect:
	var player_node: Node = null

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		set_process_unhandled_input(true)

	func _unhandled_input(event: InputEvent) -> void:
		if not visible:
			return
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and player_node != null and is_instance_valid(player_node):
				if mb.button_index == MOUSE_BUTTON_WHEEL_UP and player_node.has_method("_world_map_wheel_zoom"):
					player_node.call("_world_map_wheel_zoom", -1)
					get_viewport().set_input_as_handled()
					return
				if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and player_node.has_method("_world_map_wheel_zoom"):
					player_node.call("_world_map_wheel_zoom", 1)
					get_viewport().set_input_as_handled()
					return
		if event is InputEventKey and event.pressed and not event.echo:
			var k := event as InputEventKey
			if k.keycode == KEY_P or k.physical_keycode == KEY_P:
				if player_node != null and is_instance_valid(player_node) and player_node.has_method("_toggle_world_map_hints"):
					player_node.call("_toggle_world_map_hints")
					get_viewport().set_input_as_handled()
				return
			if (
				k.keycode == KEY_M
				or k.physical_keycode == KEY_M
				or k.keycode == KEY_ESCAPE
				or k.physical_keycode == KEY_ESCAPE
			):
				if player_node != null and is_instance_valid(player_node) and player_node.has_method("_toggle_world_map"):
					player_node.call("_toggle_world_map")
					get_viewport().set_input_as_handled()
