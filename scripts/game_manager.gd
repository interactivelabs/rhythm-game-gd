extends Node
## Global game state (autoloaded as `GameManager`).

## Tilemap rows of the canyon the player can move between (top to bottom).
const LANE_ROWS: Array[int] = [3, 4, 5]
## Lane the player starts in (index into LANE_ROWS) - the middle row.
const START_LANE := 1
## Vertical nudge applied to every lane (negative = up), so the player's feet
## don't sit too close to the plateau edge on the bottom lane.
const LANE_Y_OFFSET := -15.0

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
