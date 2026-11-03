## main_menu.gd
## Week 5 — UI/UX & Audio
##
## Controls the Main Menu scene (main_menu.tscn).
## Buttons:   [New Game]  [Continue]  [Quit]
## "Continue" is enabled only when a save file already exists.

extends Control

# ── Scene path constants ───────────────────────────────────────────────────────
const GAME_SCENE : String = "res://scenes/main.tscn"

# ── Node references ────────────────────────────────────────────────────────────
@onready var btn_new_game : Button = $VBoxContainer/BtnNewGame
@onready var btn_continue : Button = $VBoxContainer/BtnContinue
@onready var btn_quit     : Button = $VBoxContainer/BtnQuit
@onready var title_label  : Label  = $TitleLabel


func _ready() -> void:
	# Disable Continue if there is no save to load
	if SaveLoad.load_game().get("level", 1) == 1 and SaveLoad.load_game().get("score", 0) == 0:
		btn_continue.disabled = true
	else:
		btn_continue.disabled = false

	btn_new_game.grab_focus()


# ── Button Handlers ───────────────────────────────────────────────────────────

## Start a brand-new game (wipes any existing save)
func _on_btn_new_game_pressed() -> void:
	SaveLoad.delete_save()
	get_tree().change_scene_to_file(GAME_SCENE)


## Load the saved game and continue from where the player left off
func _on_btn_continue_pressed() -> void:
	# The main.gd _ready() will call SaveLoad.load_game() automatically
	get_tree().change_scene_to_file(GAME_SCENE)


## Quit the application
func _on_btn_quit_pressed() -> void:
	get_tree().quit()
