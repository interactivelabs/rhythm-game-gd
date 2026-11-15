extends Parallax2D
## A Parallax2D that scrolls its children with the world, at GameManager.scroll_speed.
##
## The looping itself is Parallax2D's job, set up in the inspector:
## - repeat_size.x = width of one repeating chunk of the child tile layer
## - repeat_times  = how many copies are drawn, so the screen is always covered
## The engine advances and wraps the scroll in C++ with no per-frame script.
## This script only updates autoscroll when the speed actually changes.


func _ready() -> void:
	GameManager.scroll_speed_changed.connect(_on_scroll_speed_changed)
	_on_scroll_speed_changed(GameManager.scroll_speed)


func _on_scroll_speed_changed(speed: float) -> void:
	autoscroll.x = -speed
