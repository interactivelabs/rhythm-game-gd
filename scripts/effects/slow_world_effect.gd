class_name SlowWorldEffect
extends PickupEffect
## Slows the world down, undoing some of the speed-up from collected gold. The
## song follows, as it tracks the world speed. Never goes below the starting
## speed (GameManager.BASE_SCROLL_SPEED).

## Multiplies the current world speed (0.8 = 20% slower).
@export_range(0.1, 1.0, 0.01) var speed_factor: float = 0.8


func apply(_player: Player) -> void:
	GameManager.scale_speed(speed_factor)


func describe() -> String:
	return "Slower -%d%%" % roundi((1.0 - speed_factor) * 100.0)
