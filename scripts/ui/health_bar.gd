class_name HealthBar
extends Control
## Wooden bar with a red fill (assets/UIElements/Bars). The frame is three pieces
## (left cap, tiling middle, right cap) so the bar can be any width; set the width
## with custom_minimum_size. The fill is a TextureProgressBar inside the frame.

## Seconds the fill takes to slide to a new value.
@export var animate_time: float = 0.2

var _tween: Tween

@onready var fill: TextureProgressBar = $Fill


## Sets the bar to value/max_value, sliding the fill there.
func set_value(value: float, max_value: float) -> void:
	fill.max_value = max_value
	if _tween:
		_tween.kill()
	if not is_inside_tree() or animate_time <= 0.0:
		fill.value = value
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(fill, "value", value, animate_time)
