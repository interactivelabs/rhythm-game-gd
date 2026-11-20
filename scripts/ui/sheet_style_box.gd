@tool
class_name SheetStyleBox
extends StyleBox
## StyleBox that draws one of the sliced sheets in assets/UIElements (papers,
## banners, buttons, ribbons). Those sheets store the pieces of a panel
## (corners, edges, centre) spaced apart with transparent gaps, so a plain
## StyleBoxTexture can't use them. This puts the pieces back together at any
## size: corners keep their size, edges and the centre tile to fill the rest.
##
## Sheet layout along each axis, starting at `origin`:
##     [corner] [gap] [middle] [gap] [corner]
## With single_row, only one row of pieces is used (left end, middle, right
## end) and it is scaled to fill the full height - that's how ribbons work.
## Use `origin` to pick a row in a sheet that has several (e.g. ribbon colours).

## The sliced sheet.
@export var texture: Texture2D:
	set(value):
		texture = value
		emit_changed()
## Top-left of the first corner piece in the sheet.
@export var origin := Vector2i.ZERO:
	set(value):
		origin = value
		emit_changed()
## Size of a corner piece in the sheet (pixels).
@export var corner_size := Vector2i(64, 64):
	set(value):
		corner_size = value
		emit_changed()
## Size of the middle (edge/centre) pieces in the sheet (pixels).
@export var middle_size := Vector2i(64, 64):
	set(value):
		middle_size = value
		emit_changed()
## Empty space between pieces in the sheet (pixels).
@export var gap := Vector2i(64, 64):
	set(value):
		gap = value
		emit_changed()
## Use a single row of pieces (3-slice), scaled to the box's height.
@export var single_row := false:
	set(value):
		single_row = value
		emit_changed()
## Screen pixels per sheet pixel (ignored with single_row, which fits the height).
@export_range(0.1, 4.0, 0.05, "or_greater") var pixel_scale := 1.0:
	set(value):
		pixel_scale = value
		emit_changed()
## Tint, e.g. slightly above 1 for a hover highlight.
@export var modulate := Color.WHITE:
	set(value):
		modulate = value
		emit_changed()


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if texture == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var scale := rect.size.y / corner_size.y if single_row else pixel_scale
	var src_x := _source_spans(origin.x, corner_size.x, middle_size.x, gap.x)
	var dst_x := _dest_spans(rect.position.x, rect.size.x, corner_size.x * scale)
	var src_y: Array[Vector2]
	var dst_y: Array[Vector2]
	if single_row:
		src_y = [Vector2(origin.y, corner_size.y)]
		dst_y = [Vector2(rect.position.y, rect.size.y)]
	else:
		src_y = _source_spans(origin.y, corner_size.y, middle_size.y, gap.y)
		dst_y = _dest_spans(rect.position.y, rect.size.y, corner_size.y * scale)

	var rid := texture.get_rid()
	for row in src_y.size():
		var tile_y := row == 1
		for col in 3:
			var tile_x := col == 1
			var dst := Rect2(dst_x[col].x, dst_y[row].x, dst_x[col].y, dst_y[row].y)
			var src := Rect2(src_x[col].x, src_y[row].x, src_x[col].y, src_y[row].y)
			_draw_piece(to_canvas_item, rid, dst, src, scale, tile_x, tile_y)


## (start, length) of the three pieces along one axis of the sheet.
static func _source_spans(start: int, corner: int, middle: int, spacing: int) -> Array[Vector2]:
	return [
		Vector2(start, corner),
		Vector2(start + corner + spacing, middle),
		Vector2(start + corner + spacing * 2 + middle, corner),
	]


## (start, length) of the three pieces along one axis on screen. Corners shrink
## if the box is too small to fit both.
static func _dest_spans(start: float, length: float, corner: float) -> Array[Vector2]:
	var c := floorf(minf(corner, length * 0.5))
	return [
		Vector2(start, c),
		Vector2(start + c, length - c * 2.0),
		Vector2(start + length - c, c),
	]


## Draws src into dst. Along a tiled axis the piece repeats at its scaled size
## (the last copy is cropped); otherwise it is stretched to fit.
func _draw_piece(item: RID, rid: RID, dst: Rect2, src: Rect2, scale: float,
		tile_x: bool, tile_y: bool) -> void:
	if dst.size.x <= 0.0 or dst.size.y <= 0.0:
		return
	var step := Vector2(
		maxf(src.size.x * scale, 1.0) if tile_x else dst.size.x,
		maxf(src.size.y * scale, 1.0) if tile_y else dst.size.y)
	var y := 0.0
	while y < dst.size.y:
		var h := minf(step.y, dst.size.y - y)
		var x := 0.0
		while x < dst.size.x:
			var w := minf(step.x, dst.size.x - x)
			RenderingServer.canvas_item_add_texture_rect_region(item,
					Rect2(dst.position + Vector2(x, y), Vector2(w, h)), rid,
					Rect2(src.position, src.size * Vector2(w / step.x, h / step.y)),
					modulate)
			x += step.x
		y += step.y
