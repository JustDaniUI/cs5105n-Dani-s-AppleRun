## save_load.gd
## Week 7 — Juice, Save/Load & Optimization
##
## Autoload singleton — add this in Project → Project Settings → Autoload
## as the name "SaveLoad".
##
## Saves and loads game progress (score, level, health) to/from a JSON file
## stored in the user's data directory.
##
## AI-ASSISTED NOTE: The ConfigFile/JSON pattern below was drafted with the help
## of an AI coding assistant (Antigravity / Claude) and then adapted to match
## the existing score/level/health variables in main.gd.

extends Node

# ── Constants ─────────────────────────────────────────────────────────────────
const SAVE_PATH : String = "user://apple_run_save.json"

# ── Default save data ─────────────────────────────────────────────────────────
## Returns a dictionary with default values for a fresh save.
func _default_data() -> Dictionary:
	return {
		"score":  0,
		"level":  1,
		"health": 3,
	}


# ── Save ───────────────────────────────────────────────────────────────────────
## Write the player's current progress to disk.
## Call this whenever the player advances a level or collects apples.
func save_game(score: int, level: int, health: int) -> void:
	var data : Dictionary = {
		"score":  score,
		"level":  level,
		"health": health,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("[SaveLoad] Game saved — score:%s level:%s health:%s" % [score, level, health])
	else:
		push_warning("[SaveLoad] Could not open save file for writing: %s" % SAVE_PATH)


# ── Load ───────────────────────────────────────────────────────────────────────
## Read saved progress from disk.
## Returns the save dictionary, or default values if no save file exists.
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveLoad] No save file found — using defaults.")
		return _default_data()

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_warning("[SaveLoad] Could not open save file for reading.")
		return _default_data()

	var content : String = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed is Dictionary:
		# Merge with defaults so any missing keys get a safe value
		var defaults = _default_data()
		for key in defaults:
			if not parsed.has(key):
				parsed[key] = defaults[key]
		print("[SaveLoad] Game loaded — score:%s level:%s health:%s" % [parsed.score, parsed.level, parsed.health])
		return parsed
	else:
		push_warning("[SaveLoad] Save file is corrupt — using defaults.")
		return _default_data()


# ── Delete ────────────────────────────────────────────────────────────────────
## Wipe saved progress (e.g. when starting a new game from the main menu).
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		print("[SaveLoad] Save file deleted.")
