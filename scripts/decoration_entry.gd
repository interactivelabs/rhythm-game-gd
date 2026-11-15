class_name DecorationEntry
extends Resource
## One decoration sprite that a DecorationBand can spawn.

@export var texture: Texture2D
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


## Bounding box of the non-transparent pixels across all frames, relative to a
## frame's top-left. Measured once (on first call) and cached, so it costs nothing
## during play.
func visible_rect() -> Rect2:
	if not _measured:
		_measured = true
		_visible_rect = ScrollPool.measure_visible(texture, hframes)
	return _visible_rect
