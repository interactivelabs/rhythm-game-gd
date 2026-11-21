class_name DecorationEntry
extends Resource
## One decoration that a DecorationBand can spawn: either a plain sprite
## (texture) or a whole scene (scene), e.g. a building with a campfire.

## The art. Not needed when `scene` is set (its Sprite is used instead).
@export var texture: Texture2D
## Optional scene to spawn instead of a plain sprite, for decorations with extra
## parts (see scenes/buildings/). Its origin must be where the art stands
## (bottom centre of the visible art), and it needs a Sprite2D child named
## "Sprite", whose texture is used to measure it. hframes/allow_flip/foot_offset
## don't apply to scenes; set those up in the scene itself.
@export var scene: PackedScene
## Horizontal frames in the texture (e.g. 8 for the animated bush strips, 1 for static art).
@export_range(1, 64) var hframes: int = 1
## Relative chance of this entry being picked within its band.
@export_range(0.0, 100.0, 0.1) var weight: float = 1.0
## Randomly mirror the sprite for extra variety (keep off for art with directional lighting).
@export var allow_flip: bool = true
## Extra vertical nudge in pixels (positive = down). The visible art's bottom is
## already detected automatically; only use this to fine-tune where it "stands".
@export var foot_offset: float = 0.0

var _visible_rect := Rect2()
var _measured := false


func frame_size() -> Vector2:
	return Vector2(texture.get_width() / float(hframes), texture.get_height())


## Name shown in warnings.
func display_name() -> String:
	var path := scene.resource_path if scene else texture.resource_path
	return path.get_file()


## Bounding box of the non-transparent pixels across all frames, relative to a
## frame's top-left. Measured once (on first call) and cached, so it costs nothing
## during play.
func visible_rect() -> Rect2:
	if not _measured:
		_measured = true
		if scene:
			var instance := scene.instantiate()
			var sprite := instance.get_node("Sprite") as Sprite2D
			_visible_rect = ScrollPool.measure_visible(sprite.texture, sprite.hframes)
			instance.free()
		else:
			_visible_rect = ScrollPool.measure_visible(texture, hframes)
	return _visible_rect
