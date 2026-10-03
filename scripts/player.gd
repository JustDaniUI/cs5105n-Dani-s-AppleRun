extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $jumpSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound


const SPEED = 300.0
const JUMP_VELOCITY = -850.0
var alive = true
var can_move = true
var hearts_list: Array[TextureRect]
var health = 3
var previous_health = 3

func _ready() -> void:
	var hearts_parents = $health_bar/HBoxContainer
	
	for child in hearts_parents.get_children():
		hearts_list.append(child)
	update_heart_display()

func update_heart_display() -> void:
	for i in range(hearts_list.size()):
		hearts_list[i].visible = i < health

func _physics_process(delta: float) -> void:
	
	if !alive:
		return
	
	# Add animation
	if velocity.x > 1 or velocity.x < -1:
		animated_sprite_2d.animation = "running"
	else:
		animated_sprite_2d.animation = "idle"
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		animated_sprite_2d.animation = "jumping"

	if can_move:
		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			jump_sound.play()

		# Get the input direction and handle the movement/deceleration.

		var direction := Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
		
		if direction == 1.0:
			animated_sprite_2d.flip_h = false
		elif direction == -1.0:
			animated_sprite_2d.flip_h = true
	
func die() -> void:
	if not alive:
		return

	if health > 0:
		var lost_heart_index = health - 1
		health -= 1

		update_heart_display()

		var heart = hearts_list[lost_heart_index]
		var sprite = heart.get_node("Heart") as AnimatedSprite2D

		heart.visible = true
		
		sprite.animation_finished.connect(
			func():
				heart.visible = false,
				CONNECT_ONE_SHOT
		)
		sprite.play("Death")

		death_sound.play()
		animated_sprite_2d.animation = "dying"
		alive = false
