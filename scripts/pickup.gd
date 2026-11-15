class_name Pickup
extends Node2D
## One pickup on screen. Instances are pooled and reused by PickupSpawner, which
## calls setup() each time one is spawned. Its origin is the point where the
## pickup touches the ground (lined up with the player's feet).
##
## This scene is the place for per-pickup extras (shadow, glow, collect effect).

var data: PickupData

@onready var sprite: AnimatedSprite2D = $Sprite


func setup(new_data: PickupData) -> void:
	data = new_data
	sprite.sprite_frames = data.sprite_frames
	sprite.offset = data.sprite_offset
	sprite.play(&"default")
	# Start on a random frame so neighbouring gold doesn't shine in sync.
	sprite.frame = randi() % sprite.sprite_frames.get_frame_count(&"default")
