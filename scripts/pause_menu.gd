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
	# Only allow pausing if the game is active (not on the home screen)
	var main_node = get_tree().root.find_child("Main", true, false)
	if main_node and "is_game_active" in main_node and not main_node.is_game_active:
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P):
		if get_tree().paused:
			resume()
		else:
			pause()

func _on_resume_button_pressed() -> void:
	resume()

func _on_restart_button_pressed() -> void:
	resume()
	var main_node = get_tree().root.find_child("Main", true, false)
	if main_node and main_node.has_method("_load_level"):
		main_node._load_level(main_node.level, false, true)
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
