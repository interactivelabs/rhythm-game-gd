extends ScrollPool
## Scrolls decorative props right-to-left to fake forward motion through the canyon.
## Use one spawner per draw layer (e.g. one behind the player, one in front) and
## give each only the bands that belong on that layer.
##
## Spawning is distance-based: faster scrolling means props cross the screen
## sooner, but the number on screen (and so the per-frame cost) stays the same.
## If a frame scrolls a long way, each prop is placed where it should be by then
## (overshoot is carried forward), so props never bunch up at high speed.
## Placement uses each sprite's visible (non-transparent) area, so padding in the
## art never pushes props into the lanes. Moving/pooling lives in ScrollPool.

## Bands of rows to decorate. See resources/decorations/.
@export var bands: Array[DecorationBand] = []
## Tile layer used to turn band rows into y positions.
@export var tile_layer: TileMapLayer

## Keeps feet this many pixels above the bottom edge of a band's last row.
const FLOOR_MARGIN := 4.0

# Per band: entries that fit in the band, their cumulative weights, and for each
# entry the y range where its feet can go.
var _choices: Array = [] # Array[Array[DecorationEntry]]
var _cumulative: Array[PackedFloat32Array] = []
var _feet_min: Array[PackedFloat32Array] = []
var _feet_max: Array[PackedFloat32Array] = []
# Per band: x of the next prop's left edge, and which choice it will be.
var _next_left := PackedFloat32Array()
var _pending := PackedInt32Array()


func _ready() -> void:
	assert(tile_layer != null, "%s needs a tile_layer" % name)
	super()
	for b in bands.size():
		_prepare_band(b)
	_after_scroll(0.0)


## Works out which entries fit in the band and where their feet can go.
func _prepare_band(b: int) -> void:
	var band := bands[b]
	var half_tile := tile_layer.tile_set.tile_size.y * 0.5
	var ceiling := _row_center_y(band.min_row) - half_tile - band.max_overhang
	var floor_y := _row_center_y(band.max_row) + half_tile - FLOOR_MARGIN

	var choices: Array[DecorationEntry] = []
	var cumulative := PackedFloat32Array()
	var feet_min := PackedFloat32Array()
	var feet_max := PackedFloat32Array()
	var total := 0.0
	for entry in band.entries:
		var lowest_feet := ceiling + entry.visible_rect().size.y
		if lowest_feet > floor_y:
			push_warning("%s: %s is too tall for rows %d-%d (needs %d px, has %d px); skipped." % [
					name, entry.texture.resource_path.get_file(), band.min_row, band.max_row,
					entry.visible_rect().size.y, floor_y - ceiling])
			continue
		choices.append(entry)
		total += entry.weight
		cumulative.append(total)
		feet_min.append(lowest_feet)
		feet_max.append(floor_y)

	_choices.append(choices)
	_cumulative.append(cumulative)
	_feet_min.append(feet_min)
	_feet_max.append(feet_max)
	_pending.append(_pick(b) if not choices.is_empty() else -1)
	# Start a little off the left edge so the screen begins already decorated.
	_next_left.append(-randf_range(0.0, band.max_gap))


## Moves every band's spawn cursor by dx and spawns whatever reached the right edge.
func _after_scroll(dx: float) -> void:
	for b in bands.size():
		if _pending[b] < 0:
			continue
		var left := _next_left[b] - dx
		while left <= _spawn_edge:
			var c := _pending[b]
			var entry: DecorationEntry = _choices[b][c]
			var vis := entry.visible_rect()
			spawn(entry.texture, entry.hframes, vis, left + vis.size.x * 0.5,
					randf_range(_feet_min[b][c], _feet_max[b][c]),
					entry.allow_flip and randf() < 0.5, entry.foot_offset)
			left += vis.size.x + randf_range(bands[b].min_gap, bands[b].max_gap)
			_pending[b] = _pick(b)
		_next_left[b] = left


## Weighted random pick; returns an index into _choices[b].
func _pick(b: int) -> int:
	var cumulative := _cumulative[b]
	var roll := randf() * cumulative[-1]
	for c in cumulative.size():
		if roll <= cumulative[c]:
			return c
	return cumulative.size() - 1


func _row_center_y(row: int) -> float:
	return to_local(tile_layer.to_global(tile_layer.map_to_local(Vector2i(0, row)))).y
