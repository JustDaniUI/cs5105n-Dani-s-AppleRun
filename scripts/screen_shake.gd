## screen_shake.gd
## Week 7 — Juice, Save/Load & Optimization
##
## Attach this script to a Camera2D node in main.tscn (or any level scene).
## Call ScreenShake.shake() from any script to trigger a screen-shake effect.
##
## Works as a standalone script OR as an Autoload singleton
## (add in Project → Autoload as "ScreenShake" and remove the camera
##  reference to instead call via $Camera2D.start_shake()).

extends Camera2D

# ── Exported tuning parameters ────────────────────────────────────────────────
@export var default_duration  : float = 0.3   # seconds the shake lasts
@export var default_intensity : float = 8.0   # pixels of max offset

# ── Internal state ────────────────────────────────────────────────────────────
var _shake_time      : float = 0.0
var _shake_intensity : float = 0.0
var _shake_duration  : float = 0.0
var _origin_offset   : Vector2 = Vector2.ZERO


func _ready() -> void:
	_origin_offset = offset


func _process(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		# Decay the intensity linearly toward zero as time runs out
		var t      = _shake_time / _shake_duration
		var amount = _shake_intensity * t
		offset = _origin_offset + Vector2(
			randf_range(-amount, amount),
			randf_range(-amount, amount)
		)
	else:
		# Reset to original offset once shake is done
		offset = _origin_offset


# ── Public API ────────────────────────────────────────────────────────────────

## Start a screen shake. Call this from any script that holds a reference to
## the Camera2D, e.g.:  get_viewport().get_camera_2d().shake()
func shake(duration: float = -1.0, intensity: float = -1.0) -> void:
	_shake_duration  = duration  if duration  > 0.0 else default_duration
	_shake_intensity = intensity if intensity > 0.0 else default_intensity
	_shake_time      = _shake_duration
