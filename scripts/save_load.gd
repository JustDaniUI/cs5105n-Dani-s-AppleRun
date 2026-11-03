## save_load.gd
## Week 7 — Juice, Save/Load & 3-Slot State Persistence
##
## Autoload singleton managing 3 independent save slots.
## Saves and loads score, level, health, and timestamp to user://slot_X.json

extends Node

var active_slot : int = 1
var is_loading_saved_game : bool = false
var loaded_data : Dictionary = {}


func get_slot_path(slot: int) -> String:
	return "user://slot_%d.json" % slot


func default_data(slot: int = 1) -> Dictionary:
	return {
		"slot": slot,
		"score": 0,
		"level": 1,
		"health": 3,
		"exists": false,
		"timestamp": ""
	}


func get_slot_info(slot: int) -> Dictionary:
	var path = get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return default_data(slot)

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return default_data(slot)

	var content = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed is Dictionary:
		parsed["exists"] = true
		return parsed
	return default_data(slot)


func save_slot(slot: int, score: int, level: int, health: int) -> void:
	active_slot = slot
	var time_dict = Time.get_datetime_dict_from_system()
	var time_str = "%02d/%02d %02d:%02d" % [time_dict.month, time_dict.day, time_dict.hour, time_dict.minute]

	var data : Dictionary = {
		"slot": slot,
		"score": score,
		"level": level,
		"health": health,
		"exists": true,
		"timestamp": time_str
	}

	var path = get_slot_path(slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("[SaveLoad] Slot %d saved -> Score:%d Level:%d Health:%d" % [slot, score, level, health])


func delete_slot(slot: int) -> void:
	var path = get_slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		print("[SaveLoad] Slot %d deleted" % slot)


func save_current_game(score: int, level: int, health: int) -> void:
	save_slot(active_slot, score, level, health)


# Backward compatibility methods
func save_game(score: int, level: int, health: int) -> void:
	save_current_game(score, level, health)


func load_game() -> Dictionary:
	return get_slot_info(active_slot)


func delete_save() -> void:
	delete_slot(active_slot)
