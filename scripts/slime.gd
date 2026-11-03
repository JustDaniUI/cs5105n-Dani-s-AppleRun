## slime.gd — Slime enemy, medium speed.
## Slime sprite faces LEFT by default in sheet.
extends Area2D

signal player_died(body)

@export var patrol_speed          : float = 42.0
@export var chase_speed           : float = 65.0
@export var patrol_distance       : float = 70.0
@export var detect_horiz          : float = 105.0
@export var detect_vert           : float = 22.0
@export var faces_left_by_default : bool  = true

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


func _do_patrol(delta: float) -> void:
	_ensure_walk_anim()
	if _can_see_player():
		current_state = State.CHASE
		if timer: timer.stop()
		return
	var next_x = position.x + patrol_direction * patrol_speed * delta
	if abs(next_x - spawn_position.x) >= patrol_distance or _is_wall_ahead():
		patrol_direction *= -1.0
		_update_sprite_flip()
		_update_detectors()
		next_x = position.x
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
	var max_reach = patrol_distance + 24.0
	if abs(position.x - spawn_position.x) >= max_reach or _is_wall_ahead():
		_start_return()
		return
	position.x = clamp(
		position.x + chase_dir * chase_speed * delta,
		spawn_position.x - max_reach,
		spawn_position.x + max_reach
	)


func _do_return(delta: float) -> void:
	if _can_see_player():
		current_state = State.CHASE
		return
	if abs(position.x - spawn_position.x) <= 3.0:
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


func _is_wall_ahead() -> bool:
	if not is_instance_valid(wall_detector): return false
	wall_detector.force_raycast_update()
	if not wall_detector.is_colliding(): return false
	return not (is_instance_valid(player_ref) and wall_detector.get_collider() == player_ref)


func _update_sprite_flip() -> void:
	if animated_sprite_2d:
		# Slime faces LEFT: flip when going right
		animated_sprite_2d.flip_h = patrol_direction > 0.0


func _play_walk_anim() -> void:
	if not animated_sprite_2d or not animated_sprite_2d.sprite_frames: return
	if animated_sprite_2d.sprite_frames.has_animation("walk"):
		animated_sprite_2d.play("walk")
	elif animated_sprite_2d.sprite_frames.has_animation("running"):
		animated_sprite_2d.play("running")


func _ensure_walk_anim() -> void:
	if animated_sprite_2d and not animated_sprite_2d.is_playing():
		_play_walk_anim()


func _update_detectors() -> void:
	if is_instance_valid(wall_detector):
		wall_detector.target_position = Vector2(18.0 * patrol_direction, 0.0)
		wall_detector.position = Vector2(0.0, 2.0)
	if is_instance_valid(floor_detector):
		floor_detector.position = Vector2(14.0 * patrol_direction, 6.0)
		floor_detector.target_position = Vector2(0.0, 16.0)


func _can_see_player() -> bool:
	if not is_instance_valid(player_ref) or not player_ref.alive: return false
	return (abs(player_ref.global_position.y - global_position.y) <= detect_vert and
			abs(player_ref.global_position.x - global_position.x) <= detect_horiz)


func _find_player() -> void:
	if not is_instance_valid(player_ref):
		player_ref = get_tree().root.find_child("Player", true, false)


func _on_timer_timeout() -> void:
	if current_state == State.PATROL:
		patrol_direction *= -1.0
		_update_sprite_flip()
		_update_detectors()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.alive:
		player_died.emit(body)
