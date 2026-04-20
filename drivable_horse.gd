extends "res://drivable_van.gd"
## Конь: тот же интерфейс, что у фургона, но быстрее и без «бензинового смысла».


func _ready() -> void:
	# Чуть быстрее и «живее».
	accel = 62.0
	brake = 75.0
	max_speed = 16.5
	turn_speed = 3.2
	fuel_max = 100.0
	fuel_drain_idle = 0.0
	fuel_drain_moving = 0.0
	hull_max_hp = 120
	super._ready()

