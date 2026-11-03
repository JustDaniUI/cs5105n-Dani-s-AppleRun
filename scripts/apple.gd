extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collected_sound: AudioStreamPlayer2D = $CollectedSound
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var particles: CPUParticles2D = get_node_or_null("Particles")

signal collected


func _on_body_entered(_body: Node2D) -> void:
	animated_sprite_2d.animation = "collected"
	collected_sound.play()
	if particles:
		particles.emitting = true
	collected.emit()
	call_deferred("_disable_collision")


func _disable_collision() -> void:
	collision_shape_2d.disabled = true


func _on_animated_sprite_2d_animation_looped() -> void:
	if animated_sprite_2d.animation == "collected":
		animated_sprite_2d.visible = false
		if particles and particles.emitting:
			await get_tree().create_timer(0.35).timeout
		queue_free()
