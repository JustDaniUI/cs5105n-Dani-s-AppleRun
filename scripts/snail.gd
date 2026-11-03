## snail.gd
## Universal Fair Enemy FSM — PATROL → CHASE → RETURN
## Enemies are Area2D (not CharacterBody2D), so they do NOT auto-collide
## with TileMap walls. Wall stopping is enforced via WallDetector RayCast2D
## + strict patrol_distance leash so enemies NEVER clip through walls.
##
## Animation priority: "running" > "walk" (so both Snail/Rat and Skeleton work)

extends Area2D

signal player_died(body)

@export var patrol_speed          : float = 45.0
@export var chase_speed           : float = 70.0
@export var patrol_distance       : float = 75.0   # Half-width patrol corridor from spawn
@export var detect_horiz          : float = 140.0  # Horizontal sight radius
@export var detect_vert           : float = 28.0   # Vertical tier tolerance (pixels)
@export var faces_left_by_default : bool  = true   # true=Snail/Rat/Slime; false=Skeleton

enum State { PATROL, CHASE, RETURN }
var current_state : State = State.PATROL

var patrol_direction : float = -1.0
var spawn_position   : Vector2
var player_ref       : Node2D = null

@onready var animated_sprite_2d : AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_detector      : RayCast2D = $WallDetector
@onready var floor_detector     : RayCast2D = $FloorDetector

var timer : Timer = null


func _ready() -> void:
	spawn_position = position

	# Direction-flip timer
	timer = get_node_or_null("Timer") as Timer
	if not timer:
		timer = Timer.new()
		timer.name = "Timer"
		timer.wait_time = 2.0
		timer.autostart = true
		add_child(timer)
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	_play_walk_anim()
	_update_sprite_flip()
	_update_detectors()


func _physics_process(delta: float) -> void:
	_find_player()

	match current_state:
		State.PATROL:  _do_patrol(delta)
		State.CHASE:   _do_chase(delta)
		State.RETURN:  _do_return(delta)


# ── State Handlers ────────────────────────────────────────────────────────────

func _do_patrol(delta: float) -> void:
	_ensure_walk_anim()

	if _can_see_player():
		current_state = State.CHASE
		if timer: timer.stop()
		return

	var step = patrol_direction * patrol_speed * delta
	var next_x = position.x + step

	# Hard leash + wall stop
	if abs(next_x - spawn_position.x) >= patrol_distance or _is_wall_ahead():
		patrol_direction *= -1.0
		_update_sprite_flip()
		_update_detectors()
		next_x = clamp(
			position.x,
			spawn_position.x - patrol_distance,
			spawn_position.x + patrol_distance
		)

	position.x = clamp(next_x, spawn_position.x - patrol_distance, spawn_position.x + patrol_distance)


func _do_chase(delta: float) -> void:
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
		_update_detectors()

	# Never chase beyond leash + buffer, never through walls
	var max_reach = patrol_distance + 24.0
	if abs(position.x - spawn_position.x) >= max_reach or _is_wall_ahead():
		_start_return()
		return

	var next_x = position.x + chase_dir * chase_speed * delta
	position.x = clamp(next_x,
		spawn_position.x - max_reach,
		spawn_position.x + max_reach)


func _do_return(delta: float) -> void:
	if _can_see_player():
		current_state = State.CHASE
		return

	var dist = abs(position.x - spawn_position.x)
	if dist <= 3.0:
		position.x = spawn_position.x
		current_state = State.PATROL
		if timer: timer.start()
		return

	var return_dir = sign(spawn_position.x - position.x)
	if return_dir != patrol_direction:
		patrol_direction = return_dir
		_update_sprite_flip()
		_update_detectors()

	position.x += return_dir * patrol_speed * delta


func _start_return() -> void:
	current_state = State.RETURN
	if timer: timer.stop()


# ── Wall / Ledge Detection ────────────────────────────────────────────────────

func _is_wall_ahead() -> bool:
	if not is_instance_valid(wall_detector):
		return false
	wall_detector.force_raycast_update()
	if not wall_detector.is_colliding():
		return false
	var col = wall_detector.get_collider()
	# Don't treat the player as a wall
	return not (is_instance_valid(player_ref) and col == player_ref)


# ── Sprite ────────────────────────────────────────────────────────────────────

func _update_sprite_flip() -> void:
	if not animated_sprite_2d:
		return
	if faces_left_by_default:
		# Snail/Rat/Slime face LEFT in sheet → flip when going RIGHT
		animated_sprite_2d.flip_h = patrol_direction > 0.0
	else:
		# Skeleton faces RIGHT in sheet → flip when going LEFT
		animated_sprite_2d.flip_h = patrol_direction < 0.0


func _play_walk_anim() -> void:
	if not animated_sprite_2d or not animated_sprite_2d.sprite_frames:
		return
	if animated_sprite_2d.sprite_frames.has_animation("running"):
		animated_sprite_2d.play("running")
	elif animated_sprite_2d.sprite_frames.has_animation("walk"):
		animated_sprite_2d.play("walk")


func _ensure_walk_anim() -> void:
	if animated_sprite_2d and not animated_sprite_2d.is_playing():
		_play_walk_anim()


# ── Raycasts ──────────────────────────────────────────────────────────────────

func _update_detectors() -> void:
	if is_instance_valid(wall_detector):
		wall_detector.target_position = Vector2(18.0 * patrol_direction, 0.0)
		wall_detector.position = Vector2(0.0, 2.0)
		wall_detector.enabled = true

	if is_instance_valid(floor_detector):
		floor_detector.position = Vector2(14.0 * patrol_direction, 6.0)
		floor_detector.target_position = Vector2(0.0, 16.0)
		floor_detector.enabled = true


# ── Player Detection ──────────────────────────────────────────────────────────

func _can_see_player() -> bool:
	if not is_instance_valid(player_ref) or not player_ref.alive:
		return false
	var dx = abs(player_ref.global_position.x - global_position.x)
	var dy = abs(player_ref.global_position.y - global_position.y)
	return dy <= detect_vert and dx <= detect_horiz


func _find_player() -> void:
	if not is_instance_valid(player_ref):
		player_ref = get_tree().root.find_child("Player", true, false)


# ── Signals ───────────────────────────────────────────────────────────────────

func _on_timer_timeout() -> void:
	if current_state == State.PATROL:
		patrol_direction *= -1.0
		_update_sprite_flip()
		_update_detectors()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.alive:
		player_died.emit(body)
