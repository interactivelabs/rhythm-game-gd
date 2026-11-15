extends CharacterBody2D

enum State { IDLE, MOVING, ATTACK }

const STATE_ANIMATIONS := {
	State.IDLE: "idle",
	State.MOVING: "walking",
	State.ATTACK: "attack",
}

@onready var animation: AnimatedSprite2D = $PlayerAnimation

var state: State = State.IDLE


func _ready() -> void:
	_enter_state(state)


func _physics_process(_delta: float) -> void:
	var next_state := _get_next_state()
	if next_state != state:
		change_state(next_state)

	move_and_slide()


# Decides which state the player should be in from current input.
# Attack takes priority over moving; idle is the fallback.
func _get_next_state() -> State:
	if Input.is_action_pressed("attack"):
		return State.ATTACK
	if Input.is_action_pressed("move_right"):
		return State.MOVING
	return State.IDLE


func change_state(new_state: State) -> void:
	state = new_state
	_enter_state(new_state)


func _enter_state(new_state: State) -> void:
	animation.play(STATE_ANIMATIONS[new_state])
