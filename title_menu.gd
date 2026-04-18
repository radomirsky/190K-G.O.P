extends Control

@onready var _main_vbox: VBoxContainer = $Center/MainVBox
@onready var _btn_continue: Button = $Center/MainVBox/BtnContinue
@onready var _btn_new: Button = $Center/MainVBox/BtnNew
@onready var _btn_quit: Button = $Center/MainVBox/BtnQuit
@onready var _mode_panel: PanelContainer = $ModePanel
@onready var _btn_hardcore: Button = $ModePanel/CenterMode/ModeVBox/BtnHardcore
@onready var _btn_survival: Button = $ModePanel/CenterMode/ModeVBox/BtnSurvival
@onready var _btn_creative: Button = $ModePanel/CenterMode/ModeVBox/BtnCreative
@onready var _btn_peaceful: Button = $ModePanel/CenterMode/ModeVBox/BtnPeaceful
@onready var _btn_mode_back: Button = $ModePanel/CenterMode/ModeVBox/BtnBack


func _ready() -> void:
	_refresh_continue_state()
	_btn_continue.pressed.connect(_on_continue)
	_btn_new.pressed.connect(_on_new_pressed)
	_btn_quit.pressed.connect(_on_quit)
	_btn_hardcore.pressed.connect(_on_hardcore)
	_btn_survival.pressed.connect(_on_survival)
	_btn_mode_back.pressed.connect(_on_mode_back)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _refresh_continue_state() -> void:
	_btn_continue.disabled = not GameSave.has_save_file()


func _on_continue() -> void:
	GameSave.continue_game()


func _on_new_pressed() -> void:
	_main_vbox.visible = false
	_mode_panel.visible = true


func _on_hardcore() -> void:
	GameSave.start_new_game(GameSave.Mode.HARDCORE)


func _on_survival() -> void:
	GameSave.start_new_game(GameSave.Mode.SURVIVAL)


func _on_creative() -> void:
	GameSave.start_new_game(GameSave.Mode.CREATIVE)


func _on_peaceful() -> void:
	GameSave.start_new_game(GameSave.Mode.PEACEFUL)


func _on_mode_back() -> void:
	_mode_panel.visible = false
	_main_vbox.visible = true


func _on_quit() -> void:
	get_tree().quit()
