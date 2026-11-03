extends Area2D

signal player_died(body)

@export var speed: float = 55.0
@export var direction: float = -1.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer


func _ready() -> void:
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("running"):
		animated_sprite_2d.play("running")
	_update_flip()


func _process(delta: float) -> void:
	position.x += direction * speed * delta


func _on_timer_timeout() -> void:
	direction *= -1.0
	_update_flip()


func _update_flip() -> void:
	# Rat "running" frames (row y=64) face RIGHT in the sheet — flip when going LEFT
	animated_sprite_2d.flip_h = (direction < 0.0)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.alive:
		player_died.emit(body)
