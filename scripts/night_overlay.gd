class_name NightOverlay
extends ColorRect
## Turns the world to night once the player has night_score gold: calls
## GameManager.start_night(), then follows GameManager.night_amount() to slowly
## fade in a moonlight colour grade (shaders/night.gdshader). The light part of the grade follows the player.
##
## Sits in the world at z_index 10, so it recolours everything drawn below it
## (terrain, decorations, enemies, pickups, player) but not the feedback popups
## (z 20), night-only lights like building campfires (z 15), or the HUD / end
## screen (CanvasLayers, always drawn on top).
## Stays night until the scene reloads (Play Again), which brings back the day.
## Hidden during the day, so it costs nothing until night falls.

## Gold needed for night to fall.
@export var night_score: int = 3000
## Seconds the change from day to night takes.
@export var transition_time: float = 15.0
## The light (the brightest part of the night) is centred on this node.
@export var player: Node2D
## Where the light sits relative to the player's origin (a bit above = their chest).
@export var light_offset := Vector2(0, -20)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_fit_viewport)
	_fit_viewport()
	_set_amount(0.0)
	hide()
	set_process(false)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.night_started.connect(_on_night_started)


func _process(_delta: float) -> void:
	_set_amount(GameManager.night_amount())
	if player:
		var light := (player.global_position + light_offset) / get_viewport_rect().size
		(material as ShaderMaterial).set_shader_parameter(&"light_center", light)


func _on_score_changed(score: int) -> void:
	if score >= night_score:
		GameManager.start_night(transition_time)


func _on_night_started(_fade_time: float) -> void:
	show()
	set_process(true)
	_process(0.0)


func _set_amount(value: float) -> void:
	(material as ShaderMaterial).set_shader_parameter(&"amount", value)


## Covers the whole visible area (there's no camera, so world = screen).
func _fit_viewport() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
