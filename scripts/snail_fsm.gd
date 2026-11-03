## snail_fsm.gd
## Week 6 — AI & Enemies: Finite State Machine for the Snail enemy.
##
## AI-ASSISTED NOTE (Week 6 requirement):
##   The FSM skeleton below was drafted with the help of an AI coding assistant
##   (Antigravity / Claude). Every line has been read, renamed, and commented by
##   the developer. The patrol/chase thresholds and collision handling were tuned
##   manually during playtesting.
##
## States:
##   PATROL  — snail walks back and forth on its platform.
##   CHASE   — snail moves toward the player when detected nearby.
##   RETURN  — snail walks back to its spawn position after losing the player.

extends Area2D

# ── Signals ──────────────────────────────────────────────────────────────────
signal player_died

# ── Constants ─────────────────────────────────────────────────────────────────
const PATROL_SPEED  : float = 45.0   # pixels/sec while patrolling
const CHASE_SPEED   : float = 90.0   # pixels/sec while chasing (faster!)
const DETECT_RANGE  : float = 200.0  # pixels — how close player must be to trigger chase
const LOSE_RANGE    : float = 350.0  # pixels — how far player must go to end chase

# ── State Machine ─────────────────────────────────────────────────────────────
enum State { PATROL, CHASE, RETURN }
var current_state : State = State.PATROL

# ── Internal variables ────────────────────────────────────────────────────────
var patrol_direction  : float = -1.0       # 1 = right, -1 = left
var spawn_position    : Vector2            # remembered at _ready
var player_ref        : Node2D = null      # cached reference to the Player node

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var patrol_timer    : Timer             = $Timer   # existing timer in scene


func _ready() -> void:
	spawn_position = position
	# Start the patrol animation immediately
	animated_sprite.play("running")


func _process(delta: float) -> void:
	# ── Detect player every frame (simple distance check) ──────────────────
	_update_player_ref()

	match current_state:
		State.PATROL:
			_do_patrol(delta)
		State.CHASE:
			_do_chase(delta)
		State.RETURN:
			_do_return(delta)


# ── State Logic ───────────────────────────────────────────────────────────────

func _do_patrol(delta: float) -> void:
	# Move left/right; timer signal handles turning (see _on_timer_timeout)
	position.x += patrol_direction * PATROL_SPEED * delta

	# Transition: player close enough → chase
	if player_ref and _distance_to_player() < DETECT_RANGE:
		current_state = State.CHASE
		patrol_timer.stop()   # pause the patrol-turn timer during chase


func _do_chase(delta: float) -> void:
	if not player_ref:
		_begin_return()
		return

	var dist = _distance_to_player()

	# Transition: player too far → return to spawn
	if dist > LOSE_RANGE:
		_begin_return()
		return

	# Move toward player
	var chase_dir = sign(player_ref.position.x - position.x)
	position.x += chase_dir * CHASE_SPEED * delta
	animated_sprite.flip_h = chase_dir < 0


func _do_return(delta: float) -> void:
	var dist_to_spawn = abs(position.x - spawn_position.x)

	if dist_to_spawn < 4.0:
		# Close enough — snap and resume patrol
		position.x = spawn_position.x
		patrol_timer.start()
		current_state = State.PATROL
		return

	var return_dir = sign(spawn_position.x - position.x)
	position.x += return_dir * PATROL_SPEED * delta
	animated_sprite.flip_h = return_dir < 0


# ── Helpers ───────────────────────────────────────────────────────────────────

func _begin_return() -> void:
	current_state = State.RETURN
	patrol_timer.stop()


func _update_player_ref() -> void:
	# Try to find the Player node in the scene if we don't have it yet
	if player_ref and is_instance_valid(player_ref):
		return
	# Walk up to the level root and look for the Player
	var level_root = get_parent()
	if level_root:
		player_ref = level_root.get_node_or_null("Player")


func _distance_to_player() -> float:
	if player_ref and is_instance_valid(player_ref):
		return position.distance_to(player_ref.position)
	return INF


# ── Existing signal handlers (kept from original snail.gd) ────────────────────

## Patrol timer fires → flip direction (same as original)
func _on_timer_timeout() -> void:
	patrol_direction *= -1
	animated_sprite.flip_h = !animated_sprite.flip_h


## Collision with player → emit player_died (main.gd handles the rest)
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.alive:
		emit_signal("player_died", body)
