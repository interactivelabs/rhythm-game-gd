extends Node
## Global game state (autoloaded as `GameManager`).

signal scroll_speed_changed(speed: float)
signal score_changed(score: int)
signal health_changed(health: int, max_health: int)
## Emitted once per whole second of run time (not every frame).
signal run_seconds_changed(seconds: int)
## Emitted when the run starts (the player pressed right).
signal run_started
## Emitted when the run is over and the world stops. completed = true when the
## level was finished (the song ended), false when health reached 0.
signal run_ended(completed: bool)

## Tilemap rows of the canyon the player can move between (top to bottom).
const LANE_ROWS: Array[int] = [3, 4, 5]
## Lane the player starts in (index into LANE_ROWS) - the middle row.
const START_LANE := 1
## Vertical nudge applied to every lane (negative = up), so the player's feet
## don't sit too close to the plateau edge on the bottom lane.
const LANE_Y_OFFSET := -15.0
## Starting speed (pixels/second) at which the world scrolls right-to-left.
const BASE_SCROLL_SPEED := 300.0
const START_HEALTH := 100
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
## Difficulty knob: multiplies every speed increase (e.g. the speed_gain of
## collected pickups). 1 = normal, 2 = speed ramps up twice as fast, 0 = the
## world never speeds up. Exported so it shows in the Remote inspector while
## testing.
@export_range(0.0, 10.0, 0.05, "or_greater") var speed_scaling: float = 1.0
## True once the player has started the run (pressed right), until it ends.
var is_running := false
## True once the run has ended (finished or died). A new run needs a restart.
var is_over := false
## True if the run ended by finishing the level (the song played to the end).
var level_completed := false
## Points from collected gold.
var score := 0
var health := START_HEALTH
## Seconds since the run started.
var run_time := 0.0
## Global y position of each lane's centre, filled by register_lanes().
var lane_y: Array[float] = []


func _process(delta: float) -> void:
	if not is_running:
		return
	var before := int(run_time)
	run_time += delta
	var now := int(run_time)
	if now != before:
		run_seconds_changed.emit(now)


## Starts the run: the world begins scrolling. Does nothing if already running.
func start_run() -> void:
	if is_running or is_over:
		return
	is_running = true
	scroll_speed = BASE_SCROLL_SPEED
	run_started.emit()


## The level was finished (the song ended).
func complete_level() -> void:
	end_run(true)


## Ends the run: the world stops scrolling and the run timer freezes.
## completed = true if the level was finished, false if the player died.
func end_run(completed := false) -> void:
	if not is_running:
		return
	is_running = false
	is_over = true
	level_completed = completed
	scroll_speed = 0.0
	run_ended.emit(completed)


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
	if health == 0:
		end_run()


## Applies a collected pickup's effects.
func collect(pickup: PickupData) -> void:
	add_score(pickup.score)
	change_health(pickup.heal)
	add_speed(pickup.speed_gain)


## Speeds the world up by amount px/s, scaled by speed_scaling. Only while running.
func add_speed(amount: float) -> void:
	if not is_running or amount == 0.0:
		return
	scroll_speed += amount * speed_scaling


## Computes lane positions from the given tilemap layer.
func register_lanes(layer: TileMapLayer) -> void:
	lane_y.clear()
	for row in LANE_ROWS:
		lane_y.append(layer.to_global(layer.map_to_local(Vector2i(0, row))).y + LANE_Y_OFFSET)


func lane_count() -> int:
	return lane_y.size()


func get_lane_y(lane: int) -> float:
	return lane_y[clampi(lane, 0, lane_y.size() - 1)]
