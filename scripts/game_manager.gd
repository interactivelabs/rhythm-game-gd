extends Node
## Global game state (autoloaded as `GameManager`).

## Tilemap rows of the canyon the player can move between (top to bottom).
const LANE_ROWS: Array[int] = [3, 4, 5]
## Lane the player starts in (index into LANE_ROWS) - the middle row.
const START_LANE := 1
## Vertical nudge applied to every lane (negative = up), so the player's feet
## don't sit too close to the plateau edge on the bottom lane.
const LANE_Y_OFFSET := -15.0
## Starting speed (pixels/second) at which the world scrolls right-to-left.
const BASE_SCROLL_SPEED := 300.0

## Current world scroll speed in pixels/second. Everything that fakes forward
## motion (decorations, later obstacles/coins) reads this, so raising it speeds
## up the whole level at once.
## Stays at 0 until start_run() is called.
var scroll_speed: float = 0.0
## True once the player has started the run (pressed right).
var is_running := false


## Starts the run: the world begins scrolling. Does nothing if already running.
func start_run() -> void:
	if is_running:
		return
	is_running = true
	scroll_speed = BASE_SCROLL_SPEED

## Global y position of each lane's centre, filled by register_lanes().
var lane_y: Array[float] = []


## Computes lane positions from the given tilemap layer.
func register_lanes(layer: TileMapLayer) -> void:
	lane_y.clear()
	for row in LANE_ROWS:
		lane_y.append(layer.to_global(layer.map_to_local(Vector2i(0, row))).y + LANE_Y_OFFSET)


func lane_count() -> int:
	return lane_y.size()


func get_lane_y(lane: int) -> float:
	return lane_y[clampi(lane, 0, lane_y.size() - 1)]
