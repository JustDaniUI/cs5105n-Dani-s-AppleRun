## snail.gd
## Universal Fair Enemy Finite State Machine (FSM)
## Used across all animated enemies (Snail, Slime, Rat, Skeleton).
##
## States:
##   PATROL — Paces back and forth along its designated platform.
##   CHASE  — If player is on the same vertical level and in range, pursues alertly.
##   RETURN — If player escapes or leaves the platform tier, returns to spawn point.

extends Area2D

signal player_died(body)

@export var patrol_speed           : float = 45.0
@export var chase_speed            : float = 70.0
@export var patrol_distance        : float = 75.0   # Platform boundary limit from spawn
@export var detect_horiz           : float = 140.0  # Horizontal sight range
@export var detect_vert            : float = 24.0   # Strict vertical tier tolerance
@export var faces_left_by_default  : bool  = true   # True for Snail/Rat/Slime; False for Skeleton

enum State { PATROL, CHASE, RETURN }
var current_state : State = State.PATROL

var patrol_direction : float = -1.0
var spawn_position   : Vector2
var player_ref       : Node2D = null

@onready var animated_sprite_2d : AnimatedSprite2D = $AnimatedSprite2D
var timer : Timer = null


func _ready() -> void:
	spawn_position = position

	# Dynamically resolve or create Timer for patrol direction flips
	timer = get_node_or_null("Timer") as Timer
	if not timer:
		timer = Timer.new()
		timer.name = "Timer"
		timer.wait_time = 2.0
		timer.autostart = true
		add_child(timer)

	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

	# Ensure body_entered is connected
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# Always start running/walking animation
	if animated_sprite_2d:
		if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("running"):
			animated_sprite_2d.play("running")
		elif animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("walk"):
			animated_sprite_2d.play("walk")

	_update_sprite_flip()


func _physics_process(delta: float) -> void:
	_find_player()

	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.RETURN:
			_process_return(delta)


func _process_patrol(delta: float) -> void:
	# Ensure animation is playing
	if animated_sprite_2d and not animated_sprite_2d.is_playing():
		if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("running"):
			animated_sprite_2d.play("running")

	# Check for player on the same tier
	if _can_see_player():
		current_state = State.CHASE
		if timer:
			timer.stop()
		return

	# Move in patrol direction
	var next_x = position.x + patrol_direction * patrol_speed * delta

	# Clamp to platform patrol bounds
	if abs(next_x - spawn_position.x) >= patrol_distance:
		patrol_direction *= -1.0
		_update_sprite_flip()
		position.x = clamp(next_x, spawn_position.x - patrol_distance, spawn_position.x + patrol_distance)
	else:
		position.x = next_x


func _process_chase(delta: float) -> void:
	if not _can_see_player():
		_start_return()
		return

	var dx = player_ref.global_position.x - global_position.x
	if abs(dx) < 4.0:
		return

	var chase_dir = sign(dx)
	if chase_dir != patrol_direction:
		patrol_direction = chase_dir
		_update_sprite_flip()

	var next_x = position.x + chase_dir * chase_speed * delta

	# Stop chasing at platform edge to prevent flying off or going through walls
	if abs(next_x - spawn_position.x) >= patrol_distance + 20.0:
		position.x = clamp(next_x, spawn_position.x - (patrol_distance + 20.0), spawn_position.x + (patrol_distance + 20.0))
		_start_return()
		return

	position.x = next_x


func _process_return(delta: float) -> void:
	if _can_see_player():
		current_state = State.CHASE
		return

	var dist_to_spawn = abs(position.x - spawn_position.x)
	if dist_to_spawn <= 3.0:
		position.x = spawn_position.x
		current_state = State.PATROL
		if timer:
			timer.start()
		return

	var return_dir = sign(spawn_position.x - position.x)
	if return_dir != patrol_direction:
		patrol_direction = return_dir
		_update_sprite_flip()

	position.x += return_dir * patrol_speed * delta


func _start_return() -> void:
	current_state = State.RETURN
	if timer:
		timer.stop()


func _update_sprite_flip() -> void:
	if not animated_sprite_2d:
		return

	if faces_left_by_default:
		# Snail, Rat, Slime face left in sheet: moving right requires flip_h = true
		animated_sprite_2d.flip_h = (patrol_direction > 0.0)
	else:
		# Skeleton faces right in sheet: moving left requires flip_h = true
		animated_sprite_2d.flip_h = (patrol_direction < 0.0)


func _can_see_player() -> bool:
	if not is_instance_valid(player_ref):
		return false
	if not player_ref.alive:
		return false

	var dx = abs(player_ref.global_position.x - global_position.x)
	var dy = abs(player_ref.global_position.y - global_position.y)

	return dy <= detect_vert and dx <= detect_horiz


func _find_player() -> void:
	if is_instance_valid(player_ref):
		return
	player_ref = get_tree().root.find_child("Player", true, false)


func _on_timer_timeout() -> void:
	if current_state == State.PATROL:
		patrol_direction *= -1.0
		_update_sprite_flip()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.alive:
		player_died.emit(body)
