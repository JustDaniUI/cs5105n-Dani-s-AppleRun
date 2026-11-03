extends Control

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
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_btn_settings_pressed() -> void:
	_show_settings_panel()


func _on_btn_load_pressed() -> void:
	_show_load_panel()


func _on_btn_quit_pressed() -> void:
	get_tree().quit()


# ── Settings & Audio Buses ────────────────────────────────────────────────────

func _init_audio_sliders() -> void:
	var master_vol = _db_to_percent(AudioServer.get_bus_volume_db(bus_master))
	var music_vol  = _db_to_percent(AudioServer.get_bus_volume_db(bus_music))
	var sfx_vol    = _db_to_percent(AudioServer.get_bus_volume_db(bus_sfx))

	master_slider.value = master_vol
	master_val.text = "%d%%" % master_vol

	music_slider.value = music_vol
	music_val.text = "%d%%" % music_vol

	sfx_slider.value = sfx_vol
	sfx_val.text = "%d%%" % sfx_vol


func _db_to_percent(db: float) -> float:
	if db <= -30.0:
		return 0.0
	return clamp(db_to_linear(db) * 100.0, 0.0, 100.0)


func _on_master_slider_value_changed(value: float) -> void:
	master_val.text = "%d%%" % value
	if value <= 1.0:
		AudioServer.set_bus_mute(bus_master, true)
	else:
		AudioServer.set_bus_mute(bus_master, false)
		AudioServer.set_bus_volume_db(bus_master, linear_to_db(value / 100.0))


func _on_music_slider_value_changed(value: float) -> void:
	music_val.text = "%d%%" % value
	if value <= 1.0:
		AudioServer.set_bus_mute(bus_music, true)
	else:
		AudioServer.set_bus_mute(bus_music, false)
		AudioServer.set_bus_volume_db(bus_music, linear_to_db(value / 100.0))


func _on_sfx_slider_value_changed(value: float) -> void:
	sfx_val.text = "%d%%" % value
	if value <= 1.0:
		AudioServer.set_bus_mute(bus_sfx, true)
	else:
		AudioServer.set_bus_mute(bus_sfx, false)
		AudioServer.set_bus_volume_db(bus_sfx, linear_to_db(value / 100.0))


func _on_btn_test_sfx_pressed() -> void:
	if test_sound:
		test_sound.play()


func _on_btn_settings_back_pressed() -> void:
	_show_main_panel()


# ── 3-Slot Save / Load System ────────────────────────────────────────────────

func _refresh_slots() -> void:
	_setup_slot_ui(1, slot1_info, slot1_btn, slot1_del)
	_setup_slot_ui(2, slot2_info, slot2_btn, slot2_del)
	_setup_slot_ui(3, slot3_info, slot3_btn, slot3_del)


func _setup_slot_ui(slot: int, info_lbl: Label, load_btn: Button, del_btn: Button) -> void:
	var info = SaveLoad.get_slot_info(slot)
	if info.get("exists", false):
		info_lbl.text = "LEVEL %d  •  SCORE: %d  •  HEARTS: %d  (%s)" % [
			info.get("level", 1),
			info.get("score", 0),
			info.get("health", 3),
			info.get("timestamp", "Saved")
		]
		load_btn.text = "LOAD"
		del_btn.visible = true
	else:
		info_lbl.text = "[ EMPTY SLOT - NO DATA ]"
		load_btn.text = "NEW RUN"
		del_btn.visible = false


func _load_slot(slot: int) -> void:
	var info = SaveLoad.get_slot_info(slot)
	SaveLoad.active_slot = slot

	if info.get("exists", false):
		# Load from saved progress
		SaveLoad.is_loading_saved_game = true
		SaveLoad.loaded_data = info
	else:
		# Start fresh in this slot
		SaveLoad.is_loading_saved_game = false
		SaveLoad.loaded_data = {
			"score": 0,
			"level": 1,
			"health": 3
		}

	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_slot_1_load_pressed() -> void: _load_slot(1)
func _on_slot_2_load_pressed() -> void: _load_slot(2)
func _on_slot_3_load_pressed() -> void: _load_slot(3)


func _on_slot_1_delete_pressed() -> void:
	SaveLoad.delete_slot(1)
	_refresh_slots()


func _on_slot_2_delete_pressed() -> void:
	SaveLoad.delete_slot(2)
	_refresh_slots()


func _on_slot_3_delete_pressed() -> void:
	SaveLoad.delete_slot(3)
	_refresh_slots()


func _on_btn_load_back_pressed() -> void:
	_show_main_panel()
