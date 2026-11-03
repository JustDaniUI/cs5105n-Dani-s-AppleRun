extends CharacterBody2D

@onready var animated_sprite_2d : AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound          : AudioStreamPlayer2D = $jumpSound
@onready var death_sound         : AudioStreamPlayer2D = $DeathSound

const SPEED          : float = 220.0
const JUMP_VELOCITY  : float = -680.0
const ACCEL          : float = 18.0   # Ground acceleration factor
const FRICTION       : float = 14.0   # Ground friction factor

# Coyote time & jump buffer for responsive feel
const COYOTE_TIME    : float = 0.12
const JUMP_BUFFER    : float = 0.10
var _coyote_timer    : float = 0.0
var _jump_buffer_timer : float = 0.0
var _was_on_floor    : bool = false

var alive     : bool = true
var can_move  : bool = true
var health    : int  = 3
var hearts_list : Array[TextureRect]


func _ready() -> void:
	var hearts_parents = $health_bar/HBoxContainer
	for child in hearts_parents.get_children():
		hearts_list.append(child)
	update_heart_display()
	animated_sprite_2d.play("idle")


func update_heart_display() -> void:
	for i in range(hearts_list.size()):
		hearts_list[i].visible = i < health


func _physics_process(delta: float) -> void:
	if not alive:
		return

	var on_floor := is_on_floor()

	# ── Coyote time ──────────────────────────────────────────────────────────
	if on_floor:
		_coyote_timer = COYOTE_TIME
		_was_on_floor = true
	elif _coyote_timer > 0.0:
		_coyote_timer -= delta

	# ── Jump buffer ──────────────────────────────────────────────────────────
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER
	elif _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta

	# ── Gravity ───────────────────────────────────────────────────────────────
	if not on_floor:
		velocity += get_gravity() * delta

	if can_move:
		# ── Jump (with coyote + buffer) ───────────────────────────────────────
		var can_jump = _coyote_timer > 0.0
		if _jump_buffer_timer > 0.0 and can_jump:
			velocity.y = JUMP_VELOCITY
			_coyote_timer = 0.0
			_jump_buffer_timer = 0.0
			jump_sound.play()

		# ── Horizontal movement ───────────────────────────────────────────────
		var direction := Input.get_axis("left", "right")
		if direction != 0.0:
			velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * SPEED * delta)
			animated_sprite_2d.flip_h = direction < 0.0
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * SPEED * delta)

		move_and_slide()

	# ── Animation state machine ───────────────────────────────────────────────
	_update_animation(on_floor)


func _update_animation(on_floor: bool) -> void:
	if not on_floor and velocity.y < 0.0:
		_play_anim("jumping")
	elif not on_floor and velocity.y > 50.0:
		# Use jump anim for falling too (no separate fall anim)
		_play_anim("jumping")
	elif abs(velocity.x) > 10.0:
		_play_anim("running")
	else:
		_play_anim("idle")


func _play_anim(anim: StringName) -> void:
	if animated_sprite_2d.animation != anim:
		animated_sprite_2d.play(anim)


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

	_play_anim("dying")
	alive = false
