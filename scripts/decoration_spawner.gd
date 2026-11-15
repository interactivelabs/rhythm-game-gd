extends Node2D
## Scrolls decorative props right-to-left to fake forward motion through the canyon.
##
## Performance notes (built so GameManager.scroll_speed can keep increasing):
## - Decorations are plain Sprite2D children: no scripts, physics or signals per prop.
##   This node moves all of them in one loop, so the cost is one _process call.
## - Sprites come from a pre-allocated pool and are recycled when they leave the
##   screen: nothing is instantiated or freed during play.
## - Spawning is distance-based. Faster scrolling means sprites cross the screen
##   sooner, but the number on screen (and so the per-frame cost) stays the same.
## - If a frame scrolls a long way, each prop is placed where it should be by then
##   (overshoot is carried forward), so props never bunch up at high speed.
## - Animated props (bushes) share one clock. Their frame is only updated when
##   that clock ticks, not on every rendered frame.

## Bands of rows to decorate. See resources/decorations/.
@export var bands: Array[DecorationBand] = []
## Tile layer used to turn band rows into y positions.
@export var tile_layer: TileMapLayer
## Sprites created up front. The pool grows on demand if it runs out, but that
## shouldn't happen with sane band gaps.
@export var initial_pool_size: int = 32
## Frames per second for animated decorations.
@export var animation_fps: float = 8.0

var _pool: Array[Sprite2D] = []

# Active sprites and their per-sprite data, kept in parallel arrays.
# Removal is swap-with-last, so order doesn't matter (y-sort handles draw order).
var _active: Array[Sprite2D] = []
var _half_width := PackedFloat32Array()
var _hframes := PackedInt32Array()
var _phase := PackedInt32Array()

# Per band: x of the next prop's left edge, and which entry that prop will be.
var _next_left := PackedFloat32Array()
var _pending: Array[DecorationEntry] = []
# Per band: y range where the props' feet can be placed.
var _base_y_min := PackedFloat32Array()
var _base_y_max := PackedFloat32Array()

var _spawn_edge := 0.0
var _anim_time := 0.0
var _anim_tick := 0


func _ready() -> void:
	assert(tile_layer != null, "DecorationSpawner needs a tile_layer")
	y_sort_enabled = true
	for i in initial_pool_size:
		_pool.append(_create_sprite())

	get_viewport().size_changed.connect(_update_spawn_edge)
	_update_spawn_edge()

	var tile_h := float(tile_layer.tile_set.tile_size.y)
	for band in bands:
		assert(not band.entries.is_empty(), "DecorationBand has no entries")
		_base_y_min.append(_row_center_y(band.min_row))
		_base_y_max.append(_row_center_y(band.max_row) + tile_h * 0.45)
		_pending.append(band.pick_entry())
		# Start a little off the left edge so the screen begins already decorated.
		_next_left.append(-randf_range(0.0, band.max_gap))

	_spawn_due(0.0)


func _process(delta: float) -> void:
	var dx := GameManager.scroll_speed * delta

	_anim_time += delta
	var tick := int(_anim_time * animation_fps)
	var animate := tick != _anim_tick
	_anim_tick = tick

	var i := _active.size() - 1
	while i >= 0:
		var sprite := _active[i]
		var x := sprite.position.x - dx
		if x + _half_width[i] < 0.0:
			_despawn(i)
		else:
			sprite.position.x = x
			if animate and _hframes[i] > 1:
				sprite.frame = (tick + _phase[i]) % _hframes[i]
		i -= 1

	_spawn_due(dx)


## Moves every band's spawn cursor by dx and spawns whatever reached the right edge.
func _spawn_due(dx: float) -> void:
	for b in bands.size():
		var left := _next_left[b] - dx
		while left <= _spawn_edge:
			var entry := _pending[b]
			var width := entry.frame_size().x
			_spawn(entry, left + width * 0.5, randf_range(_base_y_min[b], _base_y_max[b]))
			var band := bands[b]
			var next := band.pick_entry()
			left += width + randf_range(band.min_gap, band.max_gap)
			_pending[b] = next
		_next_left[b] = left


func _spawn(entry: DecorationEntry, center_x: float, base_y: float) -> void:
	var sprite: Sprite2D = _pool.pop_back() if not _pool.is_empty() else _create_sprite()
	var size := entry.frame_size()
	sprite.texture = entry.texture
	sprite.hframes = entry.hframes
	var phase := randi() % entry.hframes
	sprite.frame = (_anim_tick + phase) % entry.hframes
	sprite.flip_h = entry.allow_flip and randf() < 0.5
	# Anchor at bottom-centre so position.y is the prop's feet (correct y-sort depth).
	sprite.offset = Vector2(0.0, -size.y * 0.5 + entry.foot_offset)
	sprite.position = Vector2(center_x, base_y)
	sprite.visible = true

	_active.append(sprite)
	_half_width.append(size.x * 0.5)
	_hframes.append(entry.hframes)
	_phase.append(phase)


func _despawn(i: int) -> void:
	var sprite := _active[i]
	sprite.visible = false
	_pool.append(sprite)

	var last := _active.size() - 1
	_active[i] = _active[last]
	_half_width[i] = _half_width[last]
	_hframes[i] = _hframes[last]
	_phase[i] = _phase[last]
	_active.resize(last)
	_half_width.resize(last)
	_hframes.resize(last)
	_phase.resize(last)


func _create_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.visible = false
	add_child(sprite)
	return sprite


func _update_spawn_edge() -> void:
	# Spawn just past the right edge of the visible area.
	_spawn_edge = get_viewport_rect().size.x


func _row_center_y(row: int) -> float:
	return to_local(tile_layer.to_global(tile_layer.map_to_local(Vector2i(0, row)))).y
