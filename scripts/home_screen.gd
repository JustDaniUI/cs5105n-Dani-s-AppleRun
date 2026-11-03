extends Control

signal play_requested
signal load_requested(slot_data: Dictionary)

# Minecraft-style rotating splash texts
const SPLASH_TEXTS: Array[String] = [
	"Run for Apples... or is that it?",
	"An apple a day keeps the doctor away!",
	"Look out for mobs!",
	"This game is all about apples btw",
	"100% apple-approved!",
	"Snails... why did it have to be snails?",
	"Collect all the apples!",
	"Jump higher! No, higher!",
	"Warning: Contains apples.",
	"Is that a skeleton?!",
	"More apples = more fun. Probably.",
	"Apples are just fancy fruit, fight me.",
	"Professional apple runner",
]

# Audio bus indices
var bus_master : int = 0
var bus_music  : int = 1
var bus_sfx    : int = 2

@onready var main_panel     : Control   = $MainPanel
@onready var settings_panel : Control   = $SettingsPanel
@onready var subtitle_label : Label     = $MainPanel/VBoxContainer/TitleBox/SubtitleLabel

# Settings sliders & value labels
@onready var master_slider  : HSlider   = $SettingsPanel/VBoxContainer/MasterRow/MasterSlider
@onready var master_val     : Label     = $SettingsPanel/VBoxContainer/MasterRow/MasterVal
@onready var music_slider   : HSlider   = $SettingsPanel/VBoxContainer/MusicRow/MusicSlider
@onready var music_val      : Label     = $SettingsPanel/VBoxContainer/MusicRow/MusicVal
@onready var sfx_slider     : HSlider   = $SettingsPanel/VBoxContainer/SFXRow/SFXSlider
@onready var sfx_val        : Label     = $SettingsPanel/VBoxContainer/SFXRow/SFXVal
@onready var test_sound     : AudioStreamPlayer = $TestSFX


func _ready() -> void:
	# Resolve audio bus indices
	bus_master = AudioServer.get_bus_index("Master")
	bus_music  = AudioServer.get_bus_index("Music")
	bus_sfx    = AudioServer.get_bus_index("SFX")

	if bus_master < 0: bus_master = 0
	if bus_music < 0:  bus_music = 0
	if bus_sfx < 0:    bus_sfx = 0

	# Pick a random splash text
	if subtitle_label:
		subtitle_label.text = SPLASH_TEXTS[randi() % SPLASH_TEXTS.size()]

	# Initial panel visibility
	_show_main_panel()

	# Initialize slider values from current AudioServer volumes
	_init_audio_sliders()


# ── Navigation ────────────────────────────────────────────────────────────────

func _show_main_panel() -> void:
	main_panel.visible = true
	settings_panel.visible = false
	if subtitle_label:
		subtitle_label.text = SPLASH_TEXTS[randi() % SPLASH_TEXTS.size()]


func _show_settings_panel() -> void:
	main_panel.visible = false
	settings_panel.visible = true


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
