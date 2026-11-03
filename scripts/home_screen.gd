extends Control

signal play_requested
signal load_requested(slot_data: Dictionary)

# Audio bus indices
var bus_master : int = 0
var bus_music  : int = 1
var bus_sfx    : int = 2

@onready var main_panel     : Control   = $MainPanel
@onready var settings_panel : Control   = $SettingsPanel
@onready var load_panel     : Control   = $LoadPanel

# Settings sliders & value labels
@onready var master_slider  : HSlider   = $SettingsPanel/VBoxContainer/MasterRow/MasterSlider
@onready var master_val     : Label     = $SettingsPanel/VBoxContainer/MasterRow/MasterVal
@onready var music_slider   : HSlider   = $SettingsPanel/VBoxContainer/MusicRow/MusicSlider
@onready var music_val      : Label     = $SettingsPanel/VBoxContainer/MusicRow/MusicVal
@onready var sfx_slider     : HSlider   = $SettingsPanel/VBoxContainer/SFXRow/SFXSlider
@onready var sfx_val        : Label     = $SettingsPanel/VBoxContainer/SFXRow/SFXVal
@onready var test_sound     : AudioStreamPlayer = $TestSFX

# Slot labels & buttons
@onready var slot1_info     : Label     = $LoadPanel/VBoxContainer/Slot1/InfoLabel
@onready var slot1_btn      : Button    = $LoadPanel/VBoxContainer/Slot1/BtnLoadSlot
@onready var slot1_del      : Button    = $LoadPanel/VBoxContainer/Slot1/BtnDeleteSlot

@onready var slot2_info     : Label     = $LoadPanel/VBoxContainer/Slot2/InfoLabel
@onready var slot2_btn      : Button    = $LoadPanel/VBoxContainer/Slot2/BtnLoadSlot
@onready var slot2_del      : Button    = $LoadPanel/VBoxContainer/Slot2/BtnDeleteSlot

@onready var slot3_info     : Label     = $LoadPanel/VBoxContainer/Slot3/InfoLabel
@onready var slot3_btn      : Button    = $LoadPanel/VBoxContainer/Slot3/BtnLoadSlot
@onready var slot3_del      : Button    = $LoadPanel/VBoxContainer/Slot3/BtnDeleteSlot


func _ready() -> void:
	# Resolve audio bus indices
	bus_master = AudioServer.get_bus_index("Master")
	bus_music  = AudioServer.get_bus_index("Music")
	bus_sfx    = AudioServer.get_bus_index("SFX")

	if bus_master < 0: bus_master = 0
	if bus_music < 0:  bus_music = 0
	if bus_sfx < 0:    bus_sfx = 0

	# Initial panel visibility
	_show_main_panel()

	# Initialize slider values from current AudioServer volumes
	_init_audio_sliders()


# ── Navigation ───────────────────────────────────────────────────────────────

func _show_main_panel() -> void:
	main_panel.visible = true
	settings_panel.visible = false
	load_panel.visible = false


func _show_settings_panel() -> void:
	main_panel.visible = false
	settings_panel.visible = true
	load_panel.visible = false


func _show_load_panel() -> void:
	main_panel.visible = false
	settings_panel.visible = false
	load_panel.visible = true
	_refresh_slots()


# ── Main Menu Buttons ─────────────────────────────────────────────────────────

func _on_btn_play_pressed() -> void:
	# Start a fresh game: score is always 0
	SaveLoad.is_loading_saved_game = false
	SaveLoad.active_slot = 1
	SaveLoad.loaded_data = {
		"score": 0,
		"level": 1,
		"health": 3
	}
	play_requested.emit()
	if get_parent() == get_tree().root:
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_btn_settings_pressed() -> void:
	_show_settings_panel()


func _on_btn_load_pressed() -> void:
	_show_load_panel()


func _on_btn_quit_pressed() -> void:
	get_tree().quit()


# ── Settings & Audio Buses ────────────────────────────────────────────────────

func _init_audio_sliders() -> void:
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
	master_val.text = "%d%%" % int(value)
	AudioServer.set_bus_volume_db(bus_master, _slider_to_db(value))
	AudioServer.set_bus_mute(bus_master, value <= 0.0)


func _on_music_slider_value_changed(value: float) -> void:
	music_val.text = "%d%%" % int(value)
	AudioServer.set_bus_volume_db(bus_music, _slider_to_db(value))
	AudioServer.set_bus_mute(bus_music, value <= 0.0)


func _on_sfx_slider_value_changed(value: float) -> void:
	sfx_val.text = "%d%%" % int(value)
	AudioServer.set_bus_volume_db(bus_sfx, _slider_to_db(value))
	AudioServer.set_bus_mute(bus_sfx, value <= 0.0)
	if test_sound and not test_sound.playing:
		test_sound.play()


func _on_settings_back_pressed() -> void:
	_show_main_panel()


# ── Load Panel & 3 Slots ─────────────────────────────────────────────────────

func _refresh_slots() -> void:
	_setup_slot_row(1, slot1_info, slot1_btn, slot1_del)
	_setup_slot_row(2, slot2_info, slot2_btn, slot2_del)
	_setup_slot_row(3, slot3_info, slot3_btn, slot3_del)


func _setup_slot_row(slot_idx: int, info_lbl: Label, load_btn: Button, del_btn: Button) -> void:
	var meta = SaveLoad.get_slot_metadata(slot_idx)
	if meta.is_empty():
		info_lbl.text = "Slot %d: Empty" % slot_idx
		load_btn.text = "Start New"
		del_btn.visible = false
	else:
		info_lbl.text = "Slot %d: Level %s | Score: %s | Hearts: %s" % [
			slot_idx,
			meta.get("level", 1),
			meta.get("score", 0),
			meta.get("health", 3)
		]
		load_btn.text = "Load Slot %d" % slot_idx
		del_btn.visible = true


func _load_slot(slot_idx: int) -> void:
	var data = SaveLoad.load_slot(slot_idx)
	if data.is_empty():
		SaveLoad.is_loading_saved_game = false
		SaveLoad.active_slot = slot_idx
		SaveLoad.loaded_data = {
			"score": 0,
			"level": 1,
			"health": 3
		}
	else:
		SaveLoad.is_loading_saved_game = true
		SaveLoad.active_slot = slot_idx
		SaveLoad.loaded_data = data

	load_requested.emit(SaveLoad.loaded_data)
	if get_parent() == get_tree().root:
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _delete_slot(slot_idx: int) -> void:
	SaveLoad.delete_slot(slot_idx)
	_refresh_slots()


func _on_slot1_load_pressed() -> void:
	_load_slot(1)

func _on_slot1_delete_pressed() -> void:
	_delete_slot(1)

func _on_slot2_load_pressed() -> void:
	_load_slot(2)

func _on_slot2_delete_pressed() -> void:
	_delete_slot(2)

func _on_slot3_load_pressed() -> void:
	_load_slot(3)

func _on_slot3_delete_pressed() -> void:
	_delete_slot(3)

func _on_load_back_pressed() -> void:
	_show_main_panel()
