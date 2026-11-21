class_name Campfire
extends NightOnly
## A campfire: animated flame plus a flickering light glow
## (shaders/fire_glow.gdshader). Only shows at night (see NightOnly), fading in
## with the night. Instance scenes/campfire.tscn wherever a fire is needed (e.g.
## the building scenes) and move/scale the instance; the glow scales with it.

@onready var flame: AnimatedSprite2D = $Flame


func _ready() -> void:
	# Start on a random frame so neighbouring fires don't burn in sync.
	flame.frame = randi() % flame.sprite_frames.get_frame_count(flame.animation)
