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

var state: State = State.IDLE
var lane := 0
var _lane_tween: Tween

@onready var animation: AnimatedSprite2D = $PlayerAnimation


func _ready() -> void:
	_enter_state(state)


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("move_up"):
		_move_lane(-1)
	elif Input.is_action_just_pressed("move_down"):
		_move_lane(1)

	if Input.is_action_just_pressed("move_right"):
		GameManager.start_run()

	var next_state := _get_next_state()
	if next_state != state:
		change_state(next_state)

	move_and_slide()


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
