class_name Enemy
extends Node2D
## One enemy on screen. Instances are pooled and reused by EnemyPool, which calls
## setup() each time one is spawned. Enemies stand still and scroll with the
## world; the pool handles movement and hitting the player. Its origin is the
## point where the enemy's feet touch the ground.
##
## The sprite is mirrored in the scene so enemies face the player.

var data: EnemyData

@onready var animation: AnimatedSprite2D = $EnemyAnimation


func setup(new_data: EnemyData) -> void:
	data = new_data
	animation.sprite_frames = data.sprite_frames
	animation.offset = data.sprite_offset
	animation.play(&"idle")
	# Start on a random frame so neighbouring enemies don't animate in sync.
	animation.frame = randi() % animation.sprite_frames.get_frame_count(&"idle")
