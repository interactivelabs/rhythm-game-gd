extends Node
## Global game state (autoloaded as `GameManager`).

signal scroll_speed_changed(speed: float)
signal score_changed(score: int)
signal health_changed(health: int, max_health: int)

## Tilemap rows of the canyon the player can move between (top to bottom).
const LANE_ROWS: Array[int] = [3, 4, 5]
## Lane the player starts in (index into LANE_ROWS) - the middle row.
const START_LANE := 1
## Vertical nudge applied to every lane (negative = up), so the player's feet
## don't sit too close to the plateau edge on the bottom lane.
const LANE_Y_OFFSET := -15.0
## Starting speed (pixels/second) at which the world scrolls right-to-left.
const BASE_SCROLL_SPEED := 300.0
const START_HEALTH := 50
const MAX_HEALTH := 100

## Current world scroll speed in pixels/second. Everything that fakes forward
## motion (terrain, decorations, pickups) follows it, so raising it speeds up
## the whole level at once. Stays at 0 until start_run() is called.
var scroll_speed: float = 0.0:
	set(value):
		if value == scroll_speed:
			return
		scroll_speed = value
		scroll_speed_changed.emit(scroll_speed)
## True once the player has started the run (pressed right).
var is_running := false
## Points from collected gold.
var score := 0
var health := START_HEALTH
## Global y position of each lane's centre, filled by register_lanes().
var lane_y: Array[float] = []


## Starts the run: the world begins scrolling. Does nothing if already running.
func start_run() -> void:
	if is_running:
		return
	is_running = true
	scroll_speed = BASE_SCROLL_SPEED


func add_score(amount: int) -> void:
	if amount == 0:
		return
	score += amount
	score_changed.emit(score)


## Changes health by amount (negative to damage), clamped to 0..MAX_HEALTH.
func change_health(amount: int) -> void:
	var new_health := clampi(health + amount, 0, MAX_HEALTH)
	if new_health == health:
		return
	health = new_health
	health_changed.emit(health, MAX_HEALTH)


## Applies a collected pickup's effects.
func collect(pickup: PickupData) -> void:
	add_score(pickup.score)
	change_health(pickup.heal)


## Computes lane positions from the given tilemap layer.
func register_lanes(layer: TileMapLayer) -> void:
	lane_y.clear()
	for row in LANE_ROWS:
		lane_y.append(layer.to_global(layer.map_to_local(Vector2i(0, row))).y + LANE_Y_OFFSET)


func lane_count() -> int:
	return lane_y.size()


func get_lane_y(lane: int) -> float:
	return lane_y[clampi(lane, 0, lane_y.size() - 1)]
