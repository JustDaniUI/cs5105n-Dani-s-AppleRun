## snail.gd
## Week 6 — AI & Enemies: Finite State Machine (FSM)
##
## AI-ASSISTED NOTE:
##   The FSM structure was drafted with the assistance of an AI coding tool,
##   then read, structured, refactored, and tuned by the developer.
##
## States:
##   PATROL — Snail moves back and forth on its patrol route (timer-based turn).
##   CHASE  — When the player is detected nearby, the snail chases the player.
##   RETURN — When the player escapes, the snail returns to its starting point.

extends Area2D

signal player_died

const PATROL_SPEED : float = 45.0
const CHASE_SPEED  : float = 85.0
const DETECT_RANGE : float = 200.0
const LOSE_RANGE   : float = 340.0

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
	position.x += patrol_direction * PATROL_SPEED * delta

	# Transition: player detected in range -> chase
	if player_ref and _player_distance() < DETECT_RANGE:
		current_state = State.CHASE
		timer.stop()


func _process_chase(delta: float) -> void:
	if not player_ref:
		_start_return()
		return

	var dist = _player_distance()
	if dist > LOSE_RANGE:
		_start_return()
		return

	# Move toward player
	var chase_dir = sign(player_ref.global_position.x - global_position.x)
	if chase_dir != 0:
		position.x += chase_dir * CHASE_SPEED * delta
		animated_sprite_2d.flip_h = (chase_dir > 0)


func _process_return(delta: float) -> void:
	var dist_to_spawn = abs(position.x - spawn_position.x)
	if dist_to_spawn < 4.0:
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


func _find_player() -> void:
	if player_ref and is_instance_valid(player_ref):
		return
	var root = get_tree().current_scene
	if root:
		player_ref = root.find_child("Player", true, false)


func _player_distance() -> float:
	if player_ref and is_instance_valid(player_ref):
		return global_position.distance_to(player_ref.global_position)
	return INF


func _on_timer_timeout() -> void:
	if current_state == State.PATROL:
		patrol_direction *= -1.0
		animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.alive:
		emit_signal("player_died", body)
