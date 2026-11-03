extends Control

signal retry_requested
signal menu_requested

const DEATH_MESSAGES: Array[String] = [
	"You died! You probably ate a bad apple.",
	"An apple a day didn't keep death away!",
	"That was definitely a poisoned apple...",
	"Snail speed, meet snail reflexes.",
	"The mobs warned you, but did you listen?",
	"Did you trip over a blade of grass?",
	"Watch out for the mobs next time!",
	"Gravity: 1, Apple Runner: 0.",
	"Apples don't bite, but the enemies sure do!",
	"Rotten luck... or was it a rotten apple?",
	"The doctor won this round.",
	"Skill issue? Or bad apple?",
	"Game over! You ran out of hearts!",
]

@onready var message_label: Label = $DeathPanel/VBoxContainer/MessageLabel
@onready var parallax_bg: ParallaxBackground = $ParallaxBackground


func _ready() -> void:
	hide()


func setup_death_screen() -> void:
	if message_label:
		message_label.text = DEATH_MESSAGES[randi() % DEATH_MESSAGES.size()]
	if parallax_bg:
		parallax_bg.scroll_offset = Vector2.ZERO
	show()


func _on_btn_retry_pressed() -> void:
	hide()
	retry_requested.emit()


func _on_btn_menu_pressed() -> void:
	hide()
	menu_requested.emit()
