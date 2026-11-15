extends ScrollPool
## Spawns pickups (gold, meat, ...) in the player's lanes, as pooled instances of
## pickup_scene, and collects them when the player touches one.
##
## Collision is a swept lane check, not physics bodies:
## - A pickup only counts as touched if the player is in its lane: the player's
##   y is within half a lane of the pickup's lane, so it works mid lane-switch.
## - It checks the whole stretch the pickup moved this frame, not just where it
##   ended up. At high speed a pickup can jump past the player in a single frame;
##   a physics Area2D would miss that ("tunnelling"), but this check can't.
## - It costs a few comparisons per on-screen pickup, with no physics server
##   involvement, so it scales with scroll_speed as cheaply as the decorations.

## Emitted after a pickup has been applied to GameManager (for sounds/effects).
signal collected(pickup: PickupData, at: Vector2)

## Scene instanced (and pooled) for every pickup. Its root must be a Pickup.
@export var pickup_scene: PackedScene = preload("res://scenes/pickup.tscn")
## Pickup types that can spawn. See resources/pickups/.
@export var pickups: Array[PickupData] = []
## The player, whose CollisionShape2D (a circle) is used as its hit size.
@export var player: Node2D
## Empty space in pixels between consecutive pickups (edge to edge, across all lanes).
@export var min_gap: float = 160.0
@export var max_gap: float = 520.0
## Distance travelled after the run starts before the first pickup shows up.
@export var start_distance: float = 300.0
## Where a pickup's base sits relative to the lane's y (the player's centre).
## About 41 lines it up with the warrior's feet.
@export var feet_offset: float = 41.0

## Bits of the per-item tag used for the lane; the rest is the pickup index.
const LANE_BITS := 4

var _cumulative := PackedFloat32Array()
var _next_left := 0.0
var _player_radius := 40.0


func _ready() -> void:
	assert(player != null, "%s needs a player" % name)
	assert(not pickups.is_empty(), "%s has no pickups" % name)
	super()
	var total := 0.0
	for p in pickups:
		total += p.weight
		_cumulative.append(total)
	var shape := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape and shape.shape is CircleShape2D:
		_player_radius = (shape.shape as CircleShape2D).radius
	_next_left = _spawn_edge + start_distance


func _create_item() -> Node2D:
	return pickup_scene.instantiate()


func _after_scroll(dx: float) -> void:
	_collect_touched(dx)
	_spawn_due(dx)


func _collect_touched(dx: float) -> void:
	if _active.is_empty() or GameManager.lane_count() == 0:
		return
	var i := _active.size() - 1
	while i >= 0:
		var tag := _tag[i]
		var data := pickups[tag >> LANE_BITS]
		var x_now := _active[i].position.x
		# Touched anywhere between where it was last frame and where it is now.
		if _touches_player(data, tag & ((1 << LANE_BITS) - 1), x_now, x_now + dx):
			var at := _active[i].position
			despawn(i)
			_apply(data, at)
		i -= 1


func _spawn_due(dx: float) -> void:
	_next_left -= dx
	if GameManager.lane_count() == 0:
		return
	while _next_left <= _spawn_edge:
		var index := _pick()
		var data := pickups[index]
		var radius := data.collision_radius
		var lane := randi() % GameManager.lane_count()
		var center_x := _next_left + radius
		var feet_y := _lane_y(lane) + feet_offset
		_next_left += radius * 2.0 + randf_range(min_gap, max_gap)
		# At high speed the overshoot can place a new pickup well left of the spawn
		# edge, maybe already past the player. Check the path it skipped.
		if _touches_player(data, lane, center_x, _spawn_edge + radius):
			_apply(data, Vector2(center_x, feet_y))
			continue
		var pickup := acquire() as Pickup
		pickup.setup(data)
		activate(pickup, center_x, feet_y, radius, (index << LANE_BITS) | lane)


## True if the player is in `lane` and a pickup whose centre swept from x_from
## down to x_to (x_to <= x_from) touched the player's hit circle on the way.
func _touches_player(data: PickupData, lane: int, x_to: float, x_from: float) -> bool:
	var player_pos := to_local(player.global_position)
	if absf(player_pos.y - _lane_y(lane)) >= _half_lane_height():
		return false
	var reach := _player_radius + data.collision_radius
	return x_to - reach <= player_pos.x and player_pos.x <= x_from + reach


func _apply(data: PickupData, at: Vector2) -> void:
	GameManager.collect(data)
	collected.emit(data, at)


## Weighted random pick; returns an index into pickups.
func _pick() -> int:
	var roll := randf() * _cumulative[-1]
	for i in _cumulative.size():
		if roll <= _cumulative[i]:
			return i
	return _cumulative.size() - 1


func _lane_y(lane: int) -> float:
	return to_local(Vector2(0.0, GameManager.get_lane_y(lane))).y


func _half_lane_height() -> float:
	if GameManager.lane_count() < 2:
		return INF
	return absf(GameManager.get_lane_y(1) - GameManager.get_lane_y(0)) * 0.5
