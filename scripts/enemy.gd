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

## Which enemy type this is (sprites, damage, ...). See resources/enemies/.
@export var data: EnemyData

var state: State = State.IDLE

var damage: int:
	get:
		return data.damage if data else 0

@onready var animation: AnimatedSprite2D = $EnemyAnimation
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	assert(data != null, "%s has no EnemyData assigned" % name)
	_apply_data()
	_enter_state(state)


func _physics_process(_delta: float) -> void:
	var next_state := _get_next_state()
	if next_state != state:
		change_state(next_state)

	move_and_slide()


func _apply_data() -> void:
	animation.sprite_frames = data.sprite_frames
	# Duplicate so instances don't share (and overwrite) the same shape.
	var shape := collision.shape.duplicate() as CircleShape2D
	shape.radius = data.collision_radius
	collision.shape = shape


# Enemies just idle for now; AI will decide the state here later.
func _get_next_state() -> State:
	return State.IDLE


func change_state(new_state: State) -> void:
	state = new_state
	_enter_state(new_state)


func _enter_state(new_state: State) -> void:
	animation.play(STATE_ANIMATIONS[new_state])
