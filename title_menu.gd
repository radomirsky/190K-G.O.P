extends Control

@onready var _main_vbox: VBoxContainer = $Center/MainVBox
@onready var _worlds_host: VBoxContainer = $Center/MainVBox/WorldsHost
@onready var _btn_new: Button = $Center/MainVBox/BtnNew
@onready var _btn_quit: Button = $Center/MainVBox/BtnQuit
@onready var _mode_panel: PanelContainer = $ModePanel
@onready var _btn_hardcore: Button = $ModePanel/CenterMode/ModeVBox/BtnHardcore
@onready var _btn_survival: Button = $ModePanel/CenterMode/ModeVBox/BtnSurvival
@onready var _btn_creative: Button = $ModePanel/CenterMode/ModeVBox/BtnCreative
@onready var _btn_peaceful: Button = $ModePanel/CenterMode/ModeVBox/BtnPeaceful
@onready var _btn_mode_back: Button = $ModePanel/CenterMode/ModeVBox/BtnBack
@onready var _replace_panel: PanelContainer = $ReplacePanel
@onready var _replace_slots_host: VBoxContainer = $ReplacePanel/CenterReplace/ReplaceVBox/ReplaceSlotsHost
@onready var _btn_replace_back: Button = $ReplacePanel/CenterReplace/ReplaceVBox/BtnReplaceBack

var _slot_rows: Array[Dictionary] = []
var _pending_mode: GameSave.Mode = GameSave.Mode.NONE


func _ready() -> void:
	_build_slot_rows()
	_btn_new.pressed.connect(_on_new_pressed)
	_btn_quit.pressed.connect(_on_quit)
	_btn_hardcore.pressed.connect(_on_hardcore)
	_btn_survival.pressed.connect(_on_survival)
	_btn_creative.pressed.connect(_on_creative)
	_btn_peaceful.pressed.connect(_on_peaceful)
	_btn_mode_back.pressed.connect(_on_mode_back)
	_btn_replace_back.pressed.connect(_on_replace_back)
	_refresh_world_slots()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _build_slot_rows() -> void:
	for i in range(1, GameSave.MAX_WORLDS + 1):
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		_worlds_host.add_child(hb)
		var info := Label.new()
		info.custom_minimum_size = Vector2(420, 0)
		hb.add_child(info)
		var play := Button.new()
		play.text = "Играть"
		play.custom_minimum_size = Vector2(92, 34)
		var slot_i := i
		play.pressed.connect(func() -> void: _on_play_slot(slot_i))
		hb.add_child(play)
		var delb := Button.new()
		delb.text = "Удалить"
		delb.custom_minimum_size = Vector2(92, 34)
		delb.pressed.connect(func() -> void: _on_delete_slot(slot_i))
		hb.add_child(delb)
		_slot_rows.append({"info": info, "play": play, "del": delb})


func _refresh_world_slots() -> void:
	for idx in range(_slot_rows.size()):
		var row: Dictionary = _slot_rows[idx]
		var info: Label = row["info"]
		var play: Button = row["play"]
		var delb: Button = row["del"]
		var pr := GameSave.get_slot_preview(idx + 1)
		if not bool(pr.get("occupied", false)):
			info.text = "Мир %d — пусто" % (idx + 1)
			play.disabled = true
			delb.disabled = true
		else:
			info.text = "Мир %d — %s, МАМА: %d" % [idx + 1, pr["mode_name"], pr["mama"]]
			play.disabled = false
			delb.disabled = false


func _rebuild_replace_buttons() -> void:
	for c in _replace_slots_host.get_children():
		c.queue_free()
	for i in range(1, GameSave.MAX_WORLDS + 1):
		var pr := GameSave.get_slot_preview(i)
		var b := Button.new()
		b.custom_minimum_size = Vector2(440, 40)
		if bool(pr.get("occupied", false)):
			b.text = "Заменить слот %d (%s, МАМА %d) — сохранение будет стёрто" % [i, pr["mode_name"], pr["mama"]]
		else:
			b.text = "Слот %d пуст (не должно появляться)" % i
			b.disabled = true
		var slot_i := i
		b.pressed.connect(func() -> void: _on_confirm_replace_slot(slot_i))
		_replace_slots_host.add_child(b)


func _on_play_slot(slot: int) -> void:
	GameSave.continue_game(slot)
	_refresh_world_slots()


func _on_delete_slot(slot: int) -> void:
	GameSave.delete_slot(slot)
	_refresh_world_slots()


func _on_new_pressed() -> void:
	_main_vbox.visible = false
	_mode_panel.visible = true


func _complete_new_game(mode: GameSave.Mode) -> void:
	var free_slot := GameSave.get_first_free_slot()
	if free_slot > 0:
		GameSave.start_new_game(mode, free_slot)
		return
	_pending_mode = mode
	_mode_panel.visible = false
	_replace_panel.visible = true
	_rebuild_replace_buttons()


func _on_confirm_replace_slot(slot: int) -> void:
	var mode := _pending_mode
	_replace_panel.visible = false
	GameSave.start_new_game(mode, slot)


func _on_replace_back() -> void:
	_replace_panel.visible = false
	_mode_panel.visible = true
	_rebuild_replace_buttons()


func _on_hardcore() -> void:
	_complete_new_game(GameSave.Mode.HARDCORE)


func _on_survival() -> void:
	_complete_new_game(GameSave.Mode.SURVIVAL)


func _on_creative() -> void:
	_complete_new_game(GameSave.Mode.CREATIVE)


func _on_peaceful() -> void:
	_complete_new_game(GameSave.Mode.PEACEFUL)


func _on_mode_back() -> void:
	_mode_panel.visible = false
	_main_vbox.visible = true
	_refresh_world_slots()


func _on_quit() -> void:
	get_tree().quit()
