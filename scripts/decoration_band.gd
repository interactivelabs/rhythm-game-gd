class_name DecorationBand
extends Resource
## A horizontal strip of tilemap rows where decorations spawn, and what spawns there.
## Each band spawns independently, spaced by distance travelled (not time), so the
## density stays the same no matter how fast the world scrolls.
##
## The whole visible art of every prop is kept inside [min_row, max_row], so props
## never spill into the lanes. Entries too tall to fit are skipped (with a warning).

## Top tilemap row (inclusive) of the area props must stay inside.
@export var min_row: int = 0
## Bottom tilemap row (inclusive) of the area props must stay inside.
@export var max_row: int = 0
## Pixels the art may rise above the top of min_row (e.g. tall buildings poking
## up past the plateau edge). 0 = stay fully inside the rows.
@export var max_overhang: float = 0.0
## Empty space in pixels between neighbouring decorations (edge to edge of the
## visible art). Negative values let them overlap into clusters.
@export var min_gap: float = 64.0
@export var max_gap: float = 256.0
@export var entries: Array[DecorationEntry] = []
