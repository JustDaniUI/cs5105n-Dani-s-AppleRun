extends ParallaxBackground

@export var scroll_speed: float = 15.0


func _process(delta: float) -> void:
	scroll_offset.x += scroll_speed * delta
