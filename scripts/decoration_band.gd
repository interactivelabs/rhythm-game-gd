class_name DecorationBand
extends Resource
## A horizontal strip of tilemap rows where decorations spawn, and what spawns there.
## Each band spawns independently, spaced by distance travelled (not time), so the
## density stays the same no matter how fast the world scrolls.

## First tilemap row (inclusive) where an entry's base (feet) can land.
@export var min_row: int = 0
## Last tilemap row (inclusive) where an entry's base (feet) can land.
@export var max_row: int = 0
## Empty space in pixels between neighbouring decorations (edge to edge).
## Negative values let them overlap into clusters.
@export var min_gap: float = 64.0
@export var max_gap: float = 256.0
@export var entries: Array[DecorationEntry] = []

var _total_weight := -1.0


## Weighted random pick.
func pick_entry() -> DecorationEntry:
	if _total_weight < 0.0:
		_total_weight = 0.0
		for e in entries:
			_total_weight += e.weight
	var roll := randf() * _total_weight
	for e in entries:
		roll -= e.weight
		if roll <= 0.0:
			return e
	return entries[-1]
