## snail.gd
## Fair, Platform-Constrained Finite State Machine (FSM)
## Features robust Ledge (Floor) and Wall RayCast detection so the Snail
## will NEVER walk off platforms, float in mid-air, or jam into walls.

extends Area2D

signal player_died(body)

# ── Tuning Constants (Balanced for Fair Platforming) ─────────────────────────
const PATROL_SPEED   : float = 38.0   # Relaxed pacing speed
const CHASE_SPEED    : float = 52.0   # Alert pursuit speed
const DETECT_HORIZ   : float = 90.0   # Max horizontal sight
const DETECT_VERT    : float = 20.0   # Must be on the exact same platform height!

enum State { PATROL, CHASE, RETURN }
var current_state : State = State.PATROL

var patrol_direction : float = -1.0
var spawn_position   : Vector2
var player_ref       : Node2D = null
var flip_cooldown    : float = 0.0

@onready var animated_sprite_2d : AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_detector     : RayCast2D        = $FloorDetector
@onready var wall_detector      : RayCast2D        = $WallDetector


func _ready() -> void:
	spawn_position = position
	if animated_sprite_2d:
		animated_sprite_2d.play("running")
	_update_raycasts()


func _physics_process(delta: float) -> void:
	if flip_cooldown > 0.0:
		flip_cooldown -= delta

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
		return

	# Ledge & wall check BEFORE moving
	if _is_at_ledge_or_wall() and flip_cooldown <= 0.0:
		_flip_direction()

	position.x += patrol_direction * PATROL_SPEED * delta


func _process_chase(delta: float) -> void:
	if not _can_see_player():
		current_state = State.RETURN
		return

	var dx = player_ref.global_position.x - global_position.x
	if abs(dx) < 6.0:
		return

	var chase_dir = sign(dx)
	if chase_dir != patrol_direction:
		patrol_direction = chase_dir
		_update_raycasts()

	# Stop if pursuit would send snail over a ledge or into a wall
	if _is_at_ledge_or_wall():
		# Can't cross ledge; stop and return
		current_state = State.RETURN
		return

	position.x += chase_dir * CHASE_SPEED * delta


func _process_return(delta: float) -> void:
	if _can_see_player():
		current_state = State.CHASE
		return

	var dist_to_spawn = abs(position.x - spawn_position.x)
	if dist_to_spawn < 3.0:
		current_state = State.PATROL
		return

	var ret_dir = sign(spawn_position.x - position.x)
	if ret_dir != patrol_direction:
		patrol_direction = ret_dir
		_update_raycasts()

	if _is_at_ledge_or_wall():
		# Spawn point might be on the other side of an obstruction, resume patrol safely
		current_state = State.PATROL
		_flip_direction()
		return

	position.x += ret_dir * PATROL_SPEED * delta


func _is_at_ledge_or_wall() -> bool:
	if not floor_detector or not wall_detector:
		return false

	floor_detector.force_raycast_update()
	wall_detector.force_raycast_update()

	# If no floor ahead -> at a ledge!
	if not floor_detector.is_colliding():
		return true

	# If wall ahead (that isn't the player) -> blocked!
	if wall_detector.is_colliding():
		var col = wall_detector.get_collider()
		if col != player_ref:
			return true

	return false


func _flip_direction() -> void:
	patrol_direction *= -1.0
	flip_cooldown = 0.25
	_update_raycasts()


func _update_raycasts() -> void:
	if animated_sprite_2d:
		# Sprite faces left by default in Walk (38x24).png
		animated_sprite_2d.flip_h = (patrol_direction > 0.0)

	if floor_detector:
		# Place floor detector slightly in front of snail foot
		floor_detector.position = Vector2(14.0 * patrol_direction, 6.0)
		floor_detector.target_position = Vector2(0.0, 16.0)

	if wall_detector:
		# Point wall detector horizontally forward
		wall_detector.position = Vector2(0.0, 4.0)
		wall_detector.target_position = Vector2(16.0 * patrol_direction, 0.0)


func _can_see_player() -> bool:
	if not is_instance_valid(player_ref):
		return false
	if not player_ref.alive:
		return false

	var dx = player_ref.global_position.x - global_position.x
	var dy = player_ref.global_position.y - global_position.y

	# Strict vertical tolerance: must be on same platform
	if abs(dy) > DETECT_VERT:
		return false

	# Must be within horizontal detection radius
	if abs(dx) > DETECT_HORIZ:
		return false

	return true


func _find_player() -> void:
	if not is_instance_valid(player_ref):
		player_ref = get_tree().root.find_child("Player", true, false)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_died.emit(body)
