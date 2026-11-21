class_name Player
extends CharacterBody2D

enum State {
	IDLE,
	MOVING,
	ATTACK,
}

const STATE_ANIMATIONS := {
	State.IDLE: "idle",
	State.MOVING: "walking",
	State.ATTACK: "attack",
}

## Seconds it takes to glide from one lane to the next.
const LANE_SWITCH_TIME := 0.15
## Seconds per blink (half visible, half faded) while invulnerable.
const BLINK_TIME := 0.08
## Seconds the death effect (flash red, sink and fade out) takes.
const DEATH_TIME := 0.8

## Seconds of invulnerability after being hit, so one mistake can't chain hits.
@export var invulnerable_time: float = 1.0

var state: State = State.IDLE
var lane := 0
var _lane_tween: Tween
var _blink_tween: Tween

@onready var animation: AnimatedSprite2D = $PlayerAnimation
@onready var invulnerability_timer: Timer = $InvulnerabilityTimer


func _ready() -> void:
	invulnerability_timer.timeout.connect(_on_invulnerability_timeout)
	GameManager.run_ended.connect(_on_run_ended)
	_enter_state(state)


func _physics_process(_delta: float) -> void:
	# No lane changes once the run is over.
	if not GameManager.is_over:
		if Input.is_action_just_pressed("move_up"):
			_move_lane(-1)
		elif Input.is_action_just_pressed("move_down"):
			_move_lane(1)

	if Input.is_action_just_pressed("move_right"):
		GameManager.start_run()

	if GameManager.is_over:
		return # run over: ignore input (e.g. Space while typing a name)

	var next_state := _get_next_state()
	if next_state != state:
		change_state(next_state)

	move_and_slide()


## Called when an enemy runs into the player. Returns false (and does nothing)
## while still invulnerable from a previous hit.
func take_hit(damage: int) -> bool:
	if is_invulnerable():
		return false
	GameManager.change_health(-damage)
	make_invulnerable(invulnerable_time)
	return true


## Enemies can't hurt the player for `duration` seconds (the player blinks).
## If already invulnerable for longer, that is kept.
func make_invulnerable(duration: float) -> void:
	if GameManager.is_over:
		return
	if invulnerability_timer.time_left >= duration:
		return
	invulnerability_timer.start(duration)
	if _blink_tween:
		_blink_tween.kill()
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(animation, "modulate:a", 0.25, BLINK_TIME)
	_blink_tween.tween_property(animation, "modulate:a", 1.0, BLINK_TIME)


func is_invulnerable() -> bool:
	return not invulnerability_timer.is_stopped()


func _on_invulnerability_timeout() -> void:
	if _blink_tween:
		_blink_tween.kill()
	animation.modulate.a = 1.0


func _on_run_ended(completed: bool) -> void:
	if completed:
		change_state(State.IDLE)
	else:
		_die()


## Death effect: stop blinking, flash red, then sink down and fade out.
func _die() -> void:
	invulnerability_timer.stop()
	if _blink_tween:
		_blink_tween.kill()
	animation.pause()
	animation.modulate = Color(1.0, 0.35, 0.35, 1.0)
	var tween := create_tween().set_parallel()
	tween.tween_property(animation, "modulate:a", 0.0, DEATH_TIME).set_delay(0.2)
	tween.tween_property(animation, "position:y", animation.position.y + 12.0, DEATH_TIME) \
			.set_delay(0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Places the player on a lane instantly (no tween). Used at startup.
func snap_to_lane(new_lane: int) -> void:
	lane = clampi(new_lane, 0, GameManager.lane_count() - 1)
	global_position.y = GameManager.get_lane_y(lane)


func _move_lane(direction: int) -> void:
	var new_lane := clampi(lane + direction, 0, GameManager.lane_count() - 1)
	if new_lane == lane:
		return
	lane = new_lane
	if _lane_tween:
		_lane_tween.kill()
	_lane_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_lane_tween.tween_property(self, "global_position:y", GameManager.get_lane_y(lane),
			LANE_SWITCH_TIME)


func _is_switching_lane() -> bool:
	return _lane_tween != null and _lane_tween.is_running()


# Decides which state the player should be in from current input.
# Attack takes priority over moving; once the run has started the player
# keeps running for good; idle is only used before the start.
func _get_next_state() -> State:
	if Input.is_action_pressed("attack"):
		return State.ATTACK
	if GameManager.is_running or _is_switching_lane():
		return State.MOVING
	return State.IDLE


func change_state(new_state: State) -> void:
	state = new_state
	_enter_state(new_state)


func _enter_state(new_state: State) -> void:
	animation.play(STATE_ANIMATIONS[new_state])
