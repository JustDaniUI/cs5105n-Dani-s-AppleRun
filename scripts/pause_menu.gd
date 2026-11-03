extends Control

func _ready() -> void:
	hide()

func resume() -> void:
	get_tree().paused = false
	hide()

func pause() -> void:
	get_tree().paused = true
	show()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P):
		if get_tree().paused:
			resume()
		else:
			pause()

func _on_resume_button_pressed() -> void:
	resume()

func _on_restart_button_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://scenes/home_screen.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
