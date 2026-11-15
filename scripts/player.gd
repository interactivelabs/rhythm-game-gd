extends CharacterBody2D


var animation: AnimatedSprite2D

func _ready():
	animation = get_node("PlayerAnimation")
	animation.play("idle")

func _physics_process(delta: float) -> void:
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		animation.play("idle")

	move_and_slide()
