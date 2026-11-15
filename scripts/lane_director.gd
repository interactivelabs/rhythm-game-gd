class_name LaneDirector
extends Node
## Decides what appears in the player's lanes, and where. It is the only place
## that knows the whole layout, so it can keep it fair. The pools (PickupPool,
## EnemyPool) just display, scroll and hit-check what they're told to place.
##
## Content comes in "rows": every gap (distance-based, like everything else),
## each lane in a row gets an enemy, a pickup, or nothing. Rules:
## - At most lane_count - 1 enemies per row, so there is always a free lane.
## - Pickups only go in lanes without an enemy, so they never overlap.

@export var pickups: PickupPool
@export var enemies: EnemyPool
## Distance travelled after the run starts before the first row shows up.
@export var start_distance: float = 400.0
## Empty space in pixels between consecutive rows (edge to edge).
@export var min_gap: float = 220.0
@export var max_gap: float = 480.0
## Chance (0-1) that a row has enemies in it.
@export_range(0.0, 1.0, 0.01) var enemy_row_chance: float = 0.45
## Difficulty: most enemies in one row. 1 = easier (two lanes always free),
## 2 = harder (only one free lane). Always capped at lanes - 1 so one lane
## stays free.
@export_range(1, 2) var max_enemies_per_row: int = 1
## Chance (0-1) that each lane without an enemy gets a pickup.
@export_range(0.0, 1.0, 0.01) var pickup_chance: float = 0.3

var _next_left := 0.0
var _spawn_edge := 0.0


func _ready() -> void:
	# Run after the pools each frame: they move their items first, then rows are
	# placed straight into this frame's positions.
	process_priority = 10
	get_viewport().size_changed.connect(_update_spawn_edge)
	_update_spawn_edge()
	_next_left = _spawn_edge + start_distance


func _process(delta: float) -> void:
	_next_left -= GameManager.scroll_speed * delta
	if GameManager.lane_count() == 0:
		return
	while _next_left <= _spawn_edge:
		var width := _spawn_row(_next_left)
		_next_left += width + randf_range(min_gap, max_gap)


## Fills one row whose left edge is at `left`. Returns the row's width.
func _spawn_row(left: float) -> float:
	var lanes := GameManager.lane_count()
	var enemy_of := PackedInt32Array()
	var pickup_of := PackedInt32Array()
	enemy_of.resize(lanes)
	enemy_of.fill(-1)
	pickup_of.resize(lanes)
	pickup_of.fill(-1)

	if enemies and lanes > 1 and randf() < enemy_row_chance:
		var order := range(lanes)
		order.shuffle()
		var count := randi_range(1, mini(max_enemies_per_row, lanes - 1))
		for k in count:
			enemy_of[order[k]] = enemies.pick()

	if pickups:
		for lane in lanes:
			if enemy_of[lane] < 0 and randf() < pickup_chance:
				pickup_of[lane] = pickups.pick()

	var width := 0.0
	for lane in lanes:
		if enemy_of[lane] >= 0:
			width = maxf(width, enemies.item_radius(enemy_of[lane]) * 2.0)
		elif pickup_of[lane] >= 0:
			width = maxf(width, pickups.item_radius(pickup_of[lane]) * 2.0)

	var center_x := left + width * 0.5
	for lane in lanes:
		if enemy_of[lane] >= 0:
			enemies.place(enemy_of[lane], lane, center_x)
		elif pickup_of[lane] >= 0:
			pickups.place(pickup_of[lane], lane, center_x)
	return width


func _update_spawn_edge() -> void:
	_spawn_edge = get_viewport().get_visible_rect().size.x
