extends Node2D

@onready var score_label  : Label      = $HUD/ScorePannel/ScoreLabel
@onready var score_panel  : Panel      = $HUD/ScorePannel
@onready var fade         : ColorRect  = $HUD/Fade
@onready var pause_menu   : Control    = $HUD/PauseMenu
@onready var home_screen  : Control    = $HUD/HomeScreen

var level : int = 1
var score : int = 0
var health: int = 3
var current_level_root: Node = null
var is_game_active : bool = false

# Juice: Hit-stop timer
var _hitstop_timer: float = 0.0
const HITSTOP_DURATION: float = 0.12


func _ready() -> void:
	# Ensure PauseMenu connects back to main menu return
	if pause_menu:
		pause_menu.hide()

	# Connect HomeScreen signals
	if home_screen:
		home_screen.play_requested.connect(_on_home_play_requested)
		home_screen.load_requested.connect(_on_home_load_requested)

	# Check if launched directly from a save slot
	if Engine.has_singleton("SaveLoad") or get_tree().root.has_node("SaveLoad"):
		if SaveLoad.is_loading_saved_game and not SaveLoad.loaded_data.is_empty():
			level = SaveLoad.loaded_data.get("level", 1)
			score = SaveLoad.loaded_data.get("score", 0)
			health = SaveLoad.loaded_data.get("health", 3)
			SaveLoad.is_loading_saved_game = false
			_start_game(level, score, health)
			return

	# Default initial launch (including F6): Prompt to Home Screen first!
	_show_main_menu()


func _process(delta: float) -> void:
	if _hitstop_timer > 0.0:
		_hitstop_timer -= delta
		Engine.time_scale = 0.1
	else:
		Engine.time_scale = 1.0


# ── Menu & Game State Transitions ───────────────────────────────────────────

func _show_main_menu() -> void:
	is_game_active = false
	if score_panel:
		score_panel.hide()
	if pause_menu:
		pause_menu.hide()
	if current_level_root:
		current_level_root.queue_free()
		current_level_root = null
	if home_screen:
		home_screen.show()
	fade.modulate.a = 0.0


func _start_game(p_level: int, p_score: int, p_health: int) -> void:
	is_game_active = true
	level = p_level
	score = p_score
	health = p_health

	if home_screen:
		home_screen.hide()
	if score_panel:
		score_panel.show()
		score_label.text = "SCORE: %s" % score

	fade.modulate.a = 1.0
	current_level_root = get_node_or_null("LevelRoot")
	await _load_level(level, true, false)


func _on_home_play_requested() -> void:
	# Fresh game starts with score 0, level 1, 3 hearts
	_start_game(1, 0, 3)


func _on_home_load_requested(slot_data: Dictionary) -> void:
	var l = slot_data.get("level", 1)
	var s = slot_data.get("score", 0)
	var h = slot_data.get("health", 3)
	_start_game(l, s, h)


# ── Level Management ────────────────────────────────────────────────────────

func _load_level(level_number: int, first_load: bool, reset_score: bool) -> void:
	# Fade out
	if not first_load:
		await _fade(1.0)

	if reset_score:
		score = 0
		score_label.text = "SCORE: 0"

	if current_level_root:
		current_level_root.queue_free()

	# Change Level
	var level_path = "res://scenes/Levels/level%s.tscn" % level_number
	if not ResourceLoader.exists(level_path):
		print("No more levels or level not found: %s. Returning to menu." % level_path)
		_show_main_menu()
		return

	current_level_root = load(level_path).instantiate()
	current_level_root.name = "LevelRoot"
	add_child(current_level_root)

	# Setup player health BEFORE setting up the rest
	var player = current_level_root.get_node_or_null("Player")
	if player:
		player.health = health

	_setup_level(current_level_root)

	# Make sure the player's hearts display the saved health
	if player:
		player.update_heart_display()

	# Fade in
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

	# Connect enemies
	var enemies = level_root.get_node_or_null("Enemies")
	if enemies:
		for enemy in enemies.get_children():
			enemy.player_died.connect(_on_player_died)


# ── Signal Handlers ─────────────────────────────────────────────────────────

func _on_player_died(body):
	body.die()
	health = body.health

	# Juice: Screen shake + hit-stop on impact
	_hitstop_timer = HITSTOP_DURATION
	_screen_shake(0.3, 10.0)

	# Save progress into active slot so health carries over
	if Engine.has_singleton("SaveLoad") or get_tree().root.has_node("SaveLoad"):
		SaveLoad.save_current_game(score, level, health)

	if health > 0:
		await _load_level(level, false, true)
	else:
		print("Game Over !")
		# Reset slot on game over
		if Engine.has_singleton("SaveLoad") or get_tree().root.has_node("SaveLoad"):
			SaveLoad.delete_save()
		await get_tree().create_timer(1.2).timeout
		_show_main_menu()


func _on_exit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		level += 1
		body.can_move = false

		# Save progress to active slot on level advance
		if Engine.has_singleton("SaveLoad") or get_tree().root.has_node("SaveLoad"):
			SaveLoad.save_current_game(score, level, health)

		await _load_level(level, false, false)


# Fade
func _fade(to_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", to_alpha, 1.0)
	await tween.finished


# Score with Juice tween punch
func increase_score() -> void:
	score += 1
	score_label.text = "SCORE: %s" % score

	# Save incrementally
	if Engine.has_singleton("SaveLoad") or get_tree().root.has_node("SaveLoad"):
		SaveLoad.save_current_game(score, level, health)

	# Juice: punch scale on score panel
	if score_panel:
		score_panel.pivot_offset = score_panel.size / 2.0
		var tween = create_tween()
		tween.tween_property(score_panel, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(score_panel, "scale", Vector2(1.0, 1.0), 0.08)


# Juice: Screen shake
func _screen_shake(duration: float = 0.25, intensity: float = 8.0) -> void:
	var orig_pos = position
	var shake_tween = create_tween()
	for i in range(4):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		shake_tween.tween_property(self, "position", orig_pos + offset, duration / 8.0)
		shake_tween.tween_property(self, "position", orig_pos, duration / 8.0)
