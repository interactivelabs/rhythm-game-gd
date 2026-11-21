class_name FloatingText
extends HBoxContainer
## One feedback popup: an optional icon and a short text ("+15", "-30",
## "Invulnerable 3s") that pops in, rises and fades out. Pooled and reused by
## FeedbackPopups, so it hides itself (instead of being freed) when done.

## Emitted when the popup has faded out and can be reused.
signal finished

## Minimum gap between a popup and the screen's left/right edge.
const SCREEN_MARGIN := 8.0

@onready var icon_rect: TextureRect = $Icon
@onready var label: Label = $Label

var _tween: Tween


func _ready() -> void:
	# Own copy, so each popup can have its own colour.
	label.label_settings = label.label_settings.duplicate()
	hide()


## Shows `text` (tinted `color`, with `icon` if given) centred on `at`, then
## rises by `rise` pixels over `duration` seconds while fading out.
func play(text: String, color: Color, icon: Texture2D, at: Vector2, rise: float,
		duration: float) -> void:
	label.text = text
	label.label_settings.font_color = color
	icon_rect.texture = icon
	icon_rect.visible = icon != null
	reset_size()
	pivot_offset = size * 0.5
	position = at - size * 0.5
	# Keep wide popups on screen (the player is close to the left edge).
	var screen_width := get_viewport_rect().size.x
	position.x = clampf(position.x, SCREEN_MARGIN, maxf(SCREEN_MARGIN, screen_width - size.x - SCREEN_MARGIN))
	modulate.a = 1.0
	scale = Vector2(0.6, 0.6)
	show()

	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:y", position.y - rise, duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	_tween.chain().tween_callback(_on_done)


func _on_done() -> void:
	hide()
	finished.emit()
