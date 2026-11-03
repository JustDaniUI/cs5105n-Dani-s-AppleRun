extends Control

@onready var menu_panel    : Panel    = $MenuPanel
@onready var options_panel : Panel    = $OptionsPanel
@onready var master_slider : HSlider  = $OptionsPanel/VBoxContainer/MasterRow/MasterSlider
@onready var master_val    : Label    = $OptionsPanel/VBoxContainer/MasterRow/MasterVal
@onready var music_slider  : HSlider  = $OptionsPanel/VBoxContainer/MusicRow/MusicSlider
@onready var music_val     : Label    = $OptionsPanel/VBoxContainer/MusicRow/MusicVal
@onready var sfx_slider    : HSlider  = $OptionsPanel/VBoxContainer/SFXRow/SFXSlider
@onready var sfx_val       : Label    = $OptionsPanel/VBoxContainer/SFXRow/SFXVal

var bus_master : int = 0
var bus_music  : int = 1
var bus_sfx    : int = 2


func _ready() -> void:
	bus_master = AudioServer.get_bus_index("Master")
	bus_music  = AudioServer.get_bus_index("Music")
	bus_sfx    = AudioServer.get_bus_index("SFX")
	if bus_master < 0: bus_master = 0
	if bus_music < 0:  bus_music = 0
	if bus_sfx < 0:    bus_sfx = 0
	hide()


func resume() -> void:
	get_tree().paused = false
	hide()


func pause() -> void:
	get_tree().paused = true
	_show_menu_panel()
	_sync_audio_sliders()
	show()


func _show_menu_panel() -> void:
	if menu_panel: menu_panel.show()
	if options_panel: options_panel.hide()


func _show_options_panel() -> void:
	_sync_audio_sliders()
	if menu_panel: menu_panel.hide()
	if options_panel: options_panel.show()


func _sync_audio_sliders() -> void:
	if not master_slider: return
	var master_db = AudioServer.get_bus_volume_db(bus_master)
	var music_db  = AudioServer.get_bus_volume_db(bus_music)
	var sfx_db    = AudioServer.get_bus_volume_db(bus_sfx)

	master_slider.value = _db_to_slider(master_db)
	music_slider.value  = _db_to_slider(music_db)
	sfx_slider.value    = _db_to_slider(sfx_db)

	master_val.text = "%d%%" % int(master_slider.value)
	music_val.text  = "%d%%" % int(music_slider.value)
	sfx_val.text    = "%d%%" % int(sfx_slider.value)


func _slider_to_db(pct: float) -> float:
	if pct <= 0.0:
		return -80.0
	return linear_to_db(pct / 100.0)


func _db_to_slider(db: float) -> float:
	if db <= -70.0:
		return 0.0
	return clamp(db_to_linear(db) * 100.0, 0.0, 100.0)


func _on_master_slider_value_changed(value: float) -> void:
	if master_val: master_val.text = "%d%%" % int(value)
	AudioServer.set_bus_volume_db(bus_master, _slider_to_db(value))
	AudioServer.set_bus_mute(bus_master, value <= 0.0)


func _on_music_slider_value_changed(value: float) -> void:
	if music_val: music_val.text = "%d%%" % int(value)
	AudioServer.set_bus_volume_db(bus_music, _slider_to_db(value))
	AudioServer.set_bus_mute(bus_music, value <= 0.0)


func _on_sfx_slider_value_changed(value: float) -> void:
	if sfx_val: sfx_val.text = "%d%%" % int(value)
	AudioServer.set_bus_volume_db(bus_sfx, _slider_to_db(value))
	AudioServer.set_bus_mute(bus_sfx, value <= 0.0)


func _on_options_button_pressed() -> void:
	_show_options_panel()


func _on_back_button_pressed() -> void:
	_show_menu_panel()


func _unhandled_input(event: InputEvent) -> void:
	var main_node = get_tree().root.find_child("Main", true, false)
	if main_node and "is_game_active" in main_node and not main_node.is_game_active:
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P):
		if get_tree().paused:
			if options_panel and options_panel.visible:
				_show_menu_panel()
			else:
				resume()
		else:
			pause()


func _on_resume_button_pressed() -> void:
	resume()


func _on_restart_button_pressed() -> void:
	resume()
	var main_node = get_tree().root.find_child("Main", true, false)
	if main_node and main_node.has_method("_start_game"):
		main_node._start_game(main_node.level, 0, 3)
	else:
		get_tree().reload_current_scene()


func _on_main_menu_button_pressed() -> void:
	resume()
	var main_node = get_tree().root.find_child("Main", true, false)
	if main_node and main_node.has_method("_show_main_menu"):
		main_node._show_main_menu()
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
