class_name LanePool
extends ScrollPool
## Base for things that live in the player's lanes (pickups, enemies) and react
## when the player touches them. A pool does not decide what to spawn or when:
## the LaneDirector calls place(). The pool displays, scrolls and hit-checks.
##
## Collision is a swept lane check, not physics bodies:
## - An item only counts as touched if the player is in its lane: the player's
##   y is within half a lane of the item's lane, so it works mid lane-switch.
## - It checks the whole stretch the item moved this frame, not just where it
##   ended up. At high speed an item can jump past the player in a single frame;
##   a physics Area2D would miss that ("tunnelling"), but this check can't.
## - It costs a few comparisons per on-screen item, with no physics server
##   involvement, so it scales with scroll_speed as cheaply as the decorations.
##
## Subclasses override _weights(), _radius(), _setup_item() and _on_touched().

## Scene instanced (and pooled) for every item.
@export var item_scene: PackedScene
## The player, whose CollisionShape2D (a circle) is used as its hit size.
@export var player: Node2D
## Where an item's base sits relative to the lane's y (the player's centre).
## About 41 lines it up with the warrior's feet.
@export var feet_offset: float = 41.0

## Bits of the per-item tag used for the lane; the rest is the data index.
const LANE_BITS := 4
## Extra distance past the left edge before an item is recycled, so wide art
## isn't cut off while still partly visible.
const OFFSCREEN_MARGIN := 128.0

var _cumulative := PackedFloat32Array()
var _player_radius := 40.0


func _ready() -> void:
	assert(player != null, "%s needs a player" % name)
	assert(item_scene != null, "%s needs an item_scene" % name)
	super()
	var total := 0.0
	for w in _weights():
		total += w
		_cumulative.append(total)
	var shape := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape and shape.shape is CircleShape2D:
		_player_radius = (shape.shape as CircleShape2D).radius


## Pools instances of item_scene instead of plain sprites.
func _create_item() -> Node2D:
	return item_scene.instantiate()


# --- Overridden by subclasses --------------------------------------------------

## Spawn weight of each data entry (index = data index).
func _weights() -> PackedFloat32Array:
	return PackedFloat32Array()


## Hit radius of data entry `index`.
func _radius(_index: int) -> float:
	return 0.0


## Configures a pooled scene instance to show data entry `index`.
func _setup_item(_item: Node2D, _index: int) -> void:
	pass


## The player touched an item of data entry `index`. Return true to remove it.
func _on_touched(_index: int, _at: Vector2) -> bool:
	return true


# --- Used by the LaneDirector ----------------------------------------------------

## Weighted random data index (by _weights()), or -1 if there is no data.
func pick() -> int:
	if _cumulative.is_empty():
		return -1
	var roll := randf() * _cumulative[-1]
	for i in _cumulative.size():
		if roll <= _cumulative[i]:
			return i
	return _cumulative.size() - 1


## Hit radius of data entry `index` (also used for spacing).
func item_radius(index: int) -> float:
	return _radius(index)


## Spawns data entry `index` in `lane` with its centre at center_x.
func place(index: int, lane: int, center_x: float) -> void:
	var radius := _radius(index)
	var at := Vector2(center_x, _lane_y(lane) + feet_offset)
	# At high speed the overshoot can place a new item well left of the spawn
	# edge, maybe already past the player. Check the path it skipped.
	if _touches_player(radius, lane, center_x, _spawn_edge + radius) and _on_touched(index, at):
		return
	var item := acquire()
	_setup_item(item, index)
	activate(item, at.x, at.y, radius + OFFSCREEN_MARGIN, (index << LANE_BITS) | lane)


# --- Internals -------------------------------------------------------------------

func _after_scroll(dx: float) -> void:
	if _active.is_empty() or GameManager.lane_count() == 0:
		return
	var i := _active.size() - 1
	while i >= 0:
		var tag := _tag[i]
		var index := tag >> LANE_BITS
		var x_now := _active[i].position.x
		# Touched anywhere between where it was last frame and where it is now.
		if _touches_player(_radius(index), tag & ((1 << LANE_BITS) - 1), x_now, x_now + dx) \
				and _on_touched(index, _active[i].position):
			despawn(i)
		i -= 1


## True if the player is in `lane` and an item whose centre swept from x_from
## down to x_to (x_to <= x_from) touched the player's hit circle on the way.
func _touches_player(radius: float, lane: int, x_to: float, x_from: float) -> bool:
	var player_pos := to_local(player.global_position)
	if absf(player_pos.y - _lane_y(lane)) >= _half_lane_height():
		return false
	var reach := _player_radius + radius
	return x_to - reach <= player_pos.x and player_pos.x <= x_from + reach


func _lane_y(lane: int) -> float:
	return to_local(Vector2(0.0, GameManager.get_lane_y(lane))).y


func _half_lane_height() -> float:
	if GameManager.lane_count() < 2:
		return INF
	return absf(GameManager.get_lane_y(1) - GameManager.get_lane_y(0)) * 0.5
