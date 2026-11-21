class_name AfterimageTrail
extends Node2D
## Fading copies ("ghosts") of a sprite drawn where it was a moment ago, so
## things stay readable when the world scrolls very fast. Without it, at high
## speed an item jumps tens of pixels per frame and seems to blink from spot to
## spot. The trail appears past start_speed and is fully visible at full_speed.
##
## Everything that uses it scrolls at exactly GameManager.scroll_speed, so where
## it was t seconds ago is simply x + speed * t (to the right, since the world
## moves left). The ghosts are created once and only repositioned each frame:
## nothing is spawned or freed during play, which fits the pooled items.
##
## Put this node *before* the source sprite in the scene so ghosts draw behind it.

## The sprite to copy (current animation frame, offset and flip).
@export var source: AnimatedSprite2D
@export_range(1, 12) var ghost_count: int = 4
## Seconds of past motion the trail covers. The trail's length on screen is
## scroll_speed * trail_time, so it stretches as the world speeds up.
@export_range(0.0, 0.5, 0.005) var trail_time: float = 0.05
## Below this scroll speed (px/s) there is no trail.
@export var start_speed: float = 700.0
## At and above this scroll speed (px/s) the trail is fully visible.
@export var full_speed: float = 1600.0
## Opacity of the ghost closest to the sprite at full strength.
@export_range(0.0, 1.0, 0.05) var max_alpha: float = 0.5
## Colour of the ghosts (e.g. pale blue for a cool smear).
@export var tint: Color = Color.WHITE
## Add the ghosts' light onto the scene instead of painting over it (a glow).
@export var additive: bool = false

var _ghosts: Array[Sprite2D] = []


func _ready() -> void:
	assert(source != null, "%s needs a source sprite" % get_path())
	var material_add: CanvasItemMaterial
	if additive:
		material_add = CanvasItemMaterial.new()
		material_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i in ghost_count:
		var ghost := Sprite2D.new()
		ghost.material = material_add
		add_child(ghost)
		_ghosts.append(ghost)
	visible = false


func _process(_delta: float) -> void:
	var speed := GameManager.scroll_speed
	var strength := clampf(inverse_lerp(start_speed, full_speed, speed), 0.0, 1.0)
	visible = strength > 0.0 and source.sprite_frames != null
	if not visible:
		return
	var texture := source.sprite_frames.get_frame_texture(source.animation, source.frame)
	for i in _ghosts.size():
		var ghost := _ghosts[i]
		var t := trail_time * float(i + 1) / _ghosts.size()
		ghost.texture = texture
		ghost.centered = source.centered
		ghost.offset = source.offset
		ghost.flip_h = source.flip_h
		ghost.flip_v = source.flip_v
		ghost.scale = source.scale
		ghost.position = source.position + Vector2(speed * t, 0.0)
		var color := tint
		color.a *= max_alpha * strength * (1.0 - float(i) / _ghosts.size())
		ghost.modulate = color
