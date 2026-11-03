extends Control

signal replay_requested
signal quit_requested

@onready var score_label: Label = $EndingPanel/VBoxContainer/ScoreLabel


func _ready() -> void:
	hide()


func set_score(apples_count: int) -> void:
	if score_label:
		score_label.text = "Congratulations! Your best apple run is %d apples collected !" % apples_count


func _on_btn_replay_pressed() -> void:
	replay_requested.emit()


func _on_btn_quit_pressed() -> void:
	quit_requested.emit()
	get_tree().quit()
