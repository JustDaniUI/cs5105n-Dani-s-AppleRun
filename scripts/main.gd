## main.gd — Updated for Week 5, 6, 7
## Changes from original:
##   Week 5: Audio buses (Music / SFX), return-to-menu action
##   Week 7: Save/load via SaveLoad singleton, screen-shake on death,
##            hit-stop (brief time-scale pause) on player death
extends Node2D

@onready var score_label : Label     = $HUD/ScorePannel/ScoreLabel
@onready var fade        : ColorRect = $HUD/Fade
@onready var music       : AudioStreamPlayer2D = $Music

const MENU_SCENE : String = "res://scenes/main_menu.tscn"

var level : int = 1
var score : int = 0
var health: int = 3
var current_level_root: Node = null

# ── Hit-stop: brief time-scale pause on impact ────────────────────────────────
var _hitstop_timer : float = 0.0
const HITSTOP_DURATION : float = 0.12   # seconds of slow-mo on death


# ── Audio Bus Setup (Week 5) ──────────────────────────────────────────────────
## The two buses (Music, SFX) must be created in Godot's Audio panel.
## This function reads their index from the bus layout so we can set volume.
func _setup_audio_buses() -> void:
	var music_bus_idx = AudioServer.get_bus_index("Music")
	var sfx_bus_idx   = AudioServer.get_bus_index("SFX")

	# If the buses exist, set default volumes (in dB).
	# Adjust these values to taste.
	if music_bus_idx >= 0:
		AudioServer.set_bus_volume_db(music_bus_idx, -6.0)
	if sfx_bus_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_bus_idx, 0.0)


# ── Called when the node enters the scene tree ────────────────────────────────
func _ready() -> void:
	_setup_audio_buses()

	fade.modulate.a = 1.0
	current_level_root = get_node("LevelRoot")

	# Week 7: Load saved progress on startup
	var saved = SaveLoad.load_game()
	level  = saved.get("level",  1)
	score  = saved.get("score",  0)
	health = saved.get("health", 3)

	score_label.text = "SCORE: %s" % score

	await _load_level(level, true, false)


# ── Process: handle hit-stop (Week 7) ────────────────────────────────────────
func _process(delta: float) -> void:
	if _hitstop_timer > 0.0:
		_hitstop_timer -= delta
		# Slow the game to 10 % speed during hit-stop
		Engine.time_scale = 0.1
	else:
		Engine.time_scale = 1.0

	# Return to main menu (Escape key — Week 5 accessibility)
	if Input.is_action_just_pressed("ui_cancel"):
		_return_to_menu()


# ── Level Management ──────────────────────────────────────────────────────────
func _load_level(level_number: int, first_load: bool, reset_score: bool) -> void:
	if not first_load:
		await _fade(1.0)

	if reset_score:
		score = 0
		score_label.text = "SCORE: 0"

	if current_level_root:
		current_level_root.queue_free()

	var level_path = "res://scenes/Levels/level%s.tscn" % level_number

	# Guard: if the level file doesn't exist, go back to menu
	if not ResourceLoader.exists(level_path):
		print("[Main] No more levels — game complete!")
		_save_and_return_to_menu()
		return

	current_level_root = load(level_path).instantiate()
	current_level_root.name = "LevelRoot"
	add_child(current_level_root)

	var player = current_level_root.get_node_or_null("Player")
	if player:
		player.health = health

	_setup_level(current_level_root)

	if player:
		player.update_heart_display()

	await _fade(0.0)


func _setup_level(level_root: Node) -> void:
	# Connect Exit
	var exit = level_root.get_node_or_null("Exit")
	if exit:
		exit.body_entered.connect(_on_exit_body_entered)

	# Connect Apples
	var apples = level_root.get_node_or_null("Apples")
	if apples:
		for apple in apples.get_children():
			apple.collected.connect(increase_score)

	# Connect Enemies (works with both old snail.gd and new snail_fsm.gd)
	var enemies = level_root.get_node_or_null("Enemies")
	if enemies:
		for enemy in enemies.get_children():
			enemy.player_died.connect(_on_player_died)


# ── Signal Handlers ───────────────────────────────────────────────────────────
func _on_player_died(body: Node2D) -> void:
	body.die()
	health = body.health

	# Week 7 — Trigger hit-stop and screen-shake
	_hitstop_timer = HITSTOP_DURATION
	_trigger_screen_shake()

	# Week 7 — Auto-save on death so health carries over
	SaveLoad.save_game(score, level, health)

	if health > 0:
		await _load_level(level, false, true)
	else:
		print("[Main] Game Over!")
		await get_tree().create_timer(1.5).timeout
		_save_and_return_to_menu()


func _on_exit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		level += 1
		body.can_move = false

		# Week 7 — Save progress when advancing a level
		SaveLoad.save_game(score, level, health)

		await _load_level(level, false, false)


# ── Score ─────────────────────────────────────────────────────────────────────
func increase_score() -> void:
	score += 1
	score_label.text = "SCORE: %s" % score


# ── Fade Transition ───────────────────────────────────────────────────────────
func _fade(to_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", to_alpha, 1.5)
	await tween.finished


# ── Screen Shake (Week 7) ─────────────────────────────────────────────────────
func _trigger_screen_shake() -> void:
	# Try to find a Camera2D with screen_shake.gd anywhere in the scene tree
	for cam in get_tree().get_nodes_in_group("screen_shake_cameras"):
		if cam.has_method("shake"):
			cam.shake(0.3, 10.0)
			return
	# Fallback: any Camera2D in the level
	if current_level_root:
		var cam = current_level_root.find_child("Camera2D", true, false)
		if cam and cam.has_method("shake"):
			cam.shake(0.3, 10.0)


# ── Menu Navigation (Week 5) ──────────────────────────────────────────────────
func _return_to_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(MENU_SCENE)


func _save_and_return_to_menu() -> void:
	SaveLoad.save_game(score, level, health)
	_return_to_menu()
