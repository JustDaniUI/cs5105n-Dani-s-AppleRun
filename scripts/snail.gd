## snail.gd
## Week 6 — AI & Enemies: Fair, Platform-Constrained Finite State Machine (FSM)
##
## States:
##   PATROL — Paces back and forth along its designated platform within platform bounds.
##   CHASE  — If player is on the SAME platform and in sight, speeds up slightly to pursue.
##   RETURN — If player escapes or leaves the platform level, returns to spawn point.

extends Area2D

signal player_died

# ── Tuning Constants (Balanced for Fair Platforming) ─────────────────────────
const PATROL_SPEED   : float = 40.0   # Normal walking speed
const CHASE_SPEED    : float = 55.0   # Alert speed (fair and avoidable)
const DETECT_HORIZ   : float = 110.0  # Max horizontal detection distance
const DETECT_VERT    : float = 22.0   # Must be on the same vertical platform level!
const MAX_LEASH      : float = 65.0   # Cannot walk off platform (max distance from spawn)

enum State { PATROL, CHASE, RETURN }
var current_state : State = State.PATROL

var patrol_direction : float = -1.0
var spawn_position   : Vector2
var player_ref       : Node2D = null

@onready var animated_sprite_2d : AnimatedSprite2D = $AnimatedSprite2D
@onready var timer : Timer = $Timer


func _ready() -> void:
	spawn_position = position
	if animated_sprite_2d:
		animated_sprite_2d.play("running")


func _process(delta: float) -> void:
	_find_player()

	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.RETURN:
			_process_return(delta)


func _process_patrol(delta: float) -> void:
	# Check if player is on the same platform and within detection window
	if _can_see_player():
		current_state = State.CHASE
		timer.stop()
		return

	# Move in patrol direction
	var next_x = position.x + patrol_direction * PATROL_SPEED * delta

	# Keep within platform bounds
	if abs(next_x - spawn_position.x) >= MAX_LEASH:
		patrol_direction *= -1.0
		animated_sprite_2d.flip_h = (patrol_direction > 0)
		position.x = clamp(next_x, spawn_position.x - MAX_LEASH, spawn_position.x + MAX_LEASH)
	else:
		position.x = next_x


func _process_chase(delta: float) -> void:
	# If player jumped away, climbed to another platform, or died, return to patrol
	if not _can_see_player():
		_start_return()
		return

	var dx = player_ref.global_position.x - global_position.x

	# Deadzone to prevent flipping jitter when player is directly above/jumping over
	if abs(dx) < 6.0:
		return

	var chase_dir = sign(dx)
	var next_x = position.x + chase_dir * CHASE_SPEED * delta

	# Snail will NOT walk off the platform or through walls; stops at edge
	if abs(next_x - spawn_position.x) >= MAX_LEASH:
		# Hit platform edge while chasing; cannot pursue further
		position.x = clamp(next_x, spawn_position.x - MAX_LEASH, spawn_position.x + MAX_LEASH)
		_start_return()
		return

	position.x = next_x
	animated_sprite_2d.flip_h = (chase_dir > 0)


func _process_return(delta: float) -> void:
	# If player stepped back into view on same platform, re-engage chase
	if _can_see_player():
		current_state = State.CHASE
		return

	var dist_to_spawn = abs(position.x - spawn_position.x)
	if dist_to_spawn <= 3.0:
		position.x = spawn_position.x
		current_state = State.PATROL
		timer.start()
		return

	var return_dir = sign(spawn_position.x - position.x)
	position.x += return_dir * PATROL_SPEED * delta
	animated_sprite_2d.flip_h = (return_dir > 0)


func _start_return() -> void:
	current_state = State.RETURN
	timer.stop()


## True ONLY when player is alive, on the same platform height, and within line of sight
func _can_see_player() -> bool:
	if not player_ref or not is_instance_valid(player_ref):
		return false
	if not player_ref.get("alive"):
		return false

	var dy = abs(player_ref.global_position.y - global_position.y)
	if dy > DETECT_VERT:
		return false # Player is on a different tier/platform!

	var dx = abs(player_ref.global_position.x - global_position.x)
	if dx > DETECT_HORIZ:
		return false # Too far horizontally

	return true


func _find_player() -> void:
	if player_ref and is_instance_valid(player_ref):
		return
	var root = get_tree().current_scene
	if root:
		player_ref = root.find_child("Player", true, false)


func _on_timer_timeout() -> void:
	if current_state == State.PATROL:
		patrol_direction *= -1.0
		animated_sprite_2d.flip_h = (patrol_direction > 0)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.alive:
		emit_signal("player_died", body)
