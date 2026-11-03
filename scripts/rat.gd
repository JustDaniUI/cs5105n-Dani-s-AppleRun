## rat.gd
## Animated Rat Enemy
## Fast scampering rodent enemy that patrols platforms.
## Features ledge & wall detection so it never walks off edges into empty space.

extends Area2D

signal player_died(body)

const PATROL_SPEED : float = 55.0
const CHASE_SPEED  : float = 85.0
const DETECT_HORIZ : float = 120.0
const DETECT_VERT  : float = 20.0

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

	var speed = PATROL_SPEED
	var is_chasing = _can_see_player()

	if is_chasing:
		var dx = player_ref.global_position.x - global_position.x
		if abs(dx) > 6.0:
			var chase_dir = sign(dx)
			if chase_dir != patrol_direction:
				patrol_direction = chase_dir
				_update_raycasts()
			speed = CHASE_SPEED

	# Ledge & wall check
	if _is_at_ledge_or_wall():
		if is_chasing:
			return
		elif flip_cooldown <= 0.0:
			_flip_direction()

	position.x += patrol_direction * speed * delta


func _is_at_ledge_or_wall() -> bool:
	if not floor_detector or not wall_detector:
		return false

	floor_detector.force_raycast_update()
	wall_detector.force_raycast_update()

	if not floor_detector.is_colliding():
		return true

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
		# Sprite faces left by default in sheet
		animated_sprite_2d.flip_h = (patrol_direction > 0.0)

	if floor_detector:
		floor_detector.position = Vector2(14.0 * patrol_direction, 6.0)
		floor_detector.target_position = Vector2(0.0, 16.0)

	if wall_detector:
		wall_detector.position = Vector2(0.0, 4.0)
		wall_detector.target_position = Vector2(16.0 * patrol_direction, 0.0)


func _can_see_player() -> bool:
	if not is_instance_valid(player_ref) or not player_ref.alive:
		return false

	var dx = player_ref.global_position.x - global_position.x
	var dy = player_ref.global_position.y - global_position.y

	return abs(dy) <= DETECT_VERT and abs(dx) <= DETECT_HORIZ


func _find_player() -> void:
	if not is_instance_valid(player_ref):
		player_ref = get_tree().root.find_child("Player", true, false)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_died.emit(body)
