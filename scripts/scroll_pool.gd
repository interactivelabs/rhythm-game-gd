class_name ScrollPool
extends Node2D
## Base for anything that spawns items which scroll right-to-left with the world
## (decorations, pickups, ...). Subclasses decide *what* and *where* to spawn by
## overriding _after_scroll(); this class handles the moving and recycling.
##
## Items are any Node2D: plain Sprite2Ds by default (decorations), or instances
## of a scene when a subclass overrides _create_item() (pickups).
##
## Performance notes (built so GameManager.scroll_speed can keep increasing):
## - Items carry no movement logic. One loop here moves all of them, so the
##   cost is one _process call no matter how many are on screen.
## - Items come from a pool created up front and are recycled when they leave
##   the screen: nothing is instantiated or freed during play. Pooled items are
##   hidden and have processing disabled, so they cost nothing while waiting.
## - Sprite2D items with several frames (spawn(..., hframes > 1)) share one
##   animation clock. Their frame only updates when that clock ticks.

## Items created up front. The pool grows on demand if it runs out.
@export var initial_pool_size: int = 32
## Frames per second for Sprite2D items animated through hframes.
@export var animation_fps: float = 8.0

# Active items and their per-item data, kept in parallel arrays.
# Removal is swap-with-last, so order doesn't matter (y-sort handles draw order).
var _active: Array[Node2D] = []
var _half_width := PackedFloat32Array()
var _hframes := PackedInt32Array()
var _phase := PackedInt32Array()
## Free per-item int for subclasses (e.g. which pickup type or lane an item is).
var _tag := PackedInt32Array()

## X just past the right edge of the visible area, where new items appear.
var _spawn_edge := 0.0
var _anim_tick := 0

var _pool: Array[Node2D] = []
## Separate pools for items made from scenes (see spawn_scene()), per scene.
var _scene_pools: Dictionary[PackedScene, Array] = {}
var _anim_time := 0.0


## Bounding box of the non-transparent pixels across all frames of a horizontal
## strip, relative to a frame's top-left. Slow-ish: call once and cache the result.
static func measure_visible(texture: Texture2D, hframes: int) -> Rect2:
	var size := Vector2i(texture.get_width() / hframes, texture.get_height())
	var img := texture.get_image()
	var bounds := Rect2i()
	for f in hframes:
		var used := img.get_region(Rect2i(f * size.x, 0, size.x, size.y)).get_used_rect()
		if used.has_area():
			bounds = used if not bounds.has_area() else bounds.merge(used)
	return Rect2(bounds) if bounds.has_area() else Rect2(Vector2.ZERO, Vector2(size))


func _ready() -> void:
	y_sort_enabled = true
	for i in initial_pool_size:
		_pool.append(_new_pooled_item())
	get_viewport().size_changed.connect(_update_spawn_edge)
	_update_spawn_edge()


func _process(delta: float) -> void:
	var dx := GameManager.scroll_speed * delta

	_anim_time += delta
	var tick := int(_anim_time * animation_fps)
	var animate := tick != _anim_tick
	_anim_tick = tick

	var i := _active.size() - 1
	while i >= 0:
		var item := _active[i]
		# Recycle items that were already off-screen after last frame's move. Doing
		# it a frame late (invisible) guarantees _after_scroll saw every item at
		# least once after its final move, e.g. so a pickup that crossed the
		# player and left the screen in one frame still gets collected.
		if item.position.x + _half_width[i] < 0.0:
			despawn(i)
		else:
			item.position.x -= dx
			if animate and _hframes[i] > 1:
				(item as Sprite2D).frame = (tick + _phase[i]) % _hframes[i]
		i -= 1

	_after_scroll(dx)


## Called once per frame after every item moved left by dx. Spawn things here.
func _after_scroll(_dx: float) -> void:
	pass


## Creates one new pooled item. Override to pool scene instances instead.
func _create_item() -> Node2D:
	return Sprite2D.new()


## Takes an item from the pool (growing it if empty). Call activate() after
## configuring it.
func acquire() -> Node2D:
	return _pool.pop_back() if not _pool.is_empty() else _new_pooled_item()


## Shows an acquired item with its origin at (center_x, y) and starts scrolling
## it. half_width is used to tell when it has left the screen. Returns its index.
func activate(item: Node2D, center_x: float, y: float, half_width: float, tag := 0,
		hframes := 1, phase := 0) -> int:
	item.position = Vector2(center_x, y)
	item.process_mode = Node.PROCESS_MODE_INHERIT
	item.visible = true
	_active.append(item)
	_half_width.append(half_width)
	_hframes.append(hframes)
	_phase.append(phase)
	_tag.append(tag)
	return _active.size() - 1


## Sprite2D helper: shows a pooled sprite so the bottom-centre of its visible art
## (vis, as returned by measure_visible) sits at (center_x, feet_y).
## Requires the default _create_item(). Returns the item's index.
func spawn(texture: Texture2D, hframes: int, vis: Rect2, center_x: float, feet_y: float,
		flip := false, foot_offset := 0.0, tag := 0) -> int:
	var sprite := acquire() as Sprite2D
	var frame_size := Vector2(texture.get_width() / float(hframes), texture.get_height())
	# Visible centre relative to the frame centre (mirrored when flipped).
	var vis_center_x := vis.get_center().x - frame_size.x * 0.5
	if flip:
		vis_center_x = -vis_center_x

	sprite.texture = texture
	sprite.hframes = hframes
	var phase := randi() % hframes
	sprite.frame = (_anim_tick + phase) % hframes
	sprite.flip_h = flip
	sprite.offset = Vector2(-vis_center_x, frame_size.y * 0.5 - vis.end.y + foot_offset)
	return activate(sprite, center_x, feet_y, vis.size.x * 0.5, tag, hframes, phase)


## Shows a pooled instance of `scene` with its origin at (x, y) and starts
## scrolling it. The scene's origin should be where its art stands (bottom
## centre). half_width is used to tell when it has left the screen.
## Instances are pooled per scene, so this is cheap after the first few.
func spawn_scene(scene: PackedScene, x: float, y: float, half_width: float, tag := 0) -> int:
	var pool: Array = _scene_pools.get_or_add(scene, [])
	var item: Node2D = pool.pop_back() if not pool.is_empty() else _new_scene_item(scene)
	return activate(item, x, y, half_width, tag)


## Creates `count` instances of `scene` up front, so spawning them later
## doesn't have to instantiate during play.
func prewarm_scene(scene: PackedScene, count: int) -> void:
	var pool: Array = _scene_pools.get_or_add(scene, [])
	for i in count:
		pool.append(_new_scene_item(scene))


## Hides item i and returns it to the pool. Swaps the last item into slot i, so
## when iterating while despawning, go from the end backwards.
func despawn(i: int) -> void:
	var item := _active[i]
	_deactivate(item)
	if item.has_meta(&"pool_scene"):
		_scene_pools[item.get_meta(&"pool_scene")].append(item)
	else:
		_pool.append(item)

	var last := _active.size() - 1
	_active[i] = _active[last]
	_half_width[i] = _half_width[last]
	_hframes[i] = _hframes[last]
	_phase[i] = _phase[last]
	_tag[i] = _tag[last]
	_active.resize(last)
	_half_width.resize(last)
	_hframes.resize(last)
	_phase.resize(last)
	_tag.resize(last)


func _new_scene_item(scene: PackedScene) -> Node2D:
	var item := scene.instantiate() as Node2D
	item.set_meta(&"pool_scene", scene)
	add_child(item)
	_deactivate(item)
	return item


func _new_pooled_item() -> Node2D:
	var item := _create_item()
	add_child(item)
	_deactivate(item)
	return item


func _deactivate(item: Node2D) -> void:
	item.visible = false
	item.process_mode = Node.PROCESS_MODE_DISABLED


func _update_spawn_edge() -> void:
	_spawn_edge = get_viewport_rect().size.x
