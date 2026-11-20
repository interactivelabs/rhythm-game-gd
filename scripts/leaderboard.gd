extends Node
## High scores of completed runs (autoloaded as `Leaderboard`).
##
## Kept in memory only for now, so it resets when the game closes. Each entry is
## a Dictionary { "name": String, "score": int, "time": float } so it can be
## saved as-is later (e.g. JSON or ConfigFile) without changing callers.
##
## Ranking: more gold first; on equal gold the faster run wins, and on a full tie
## whoever got there first stays ahead.

signal changed

## Entries kept; anything ranked lower is dropped.
const MAX_ENTRIES := 10
## Longest name accepted (longer names are cut).
const MAX_NAME_LENGTH := 12
## Used when the player leaves the name empty.
const DEFAULT_NAME := "Player"

## Best first. Read-only from outside; use add_entry() to change it.
var entries: Array[Dictionary] = []


## Adds a run and returns its rank (0 = first), or -1 if it didn't make the list.
func add_entry(player_name: String, score: int, time: float) -> int:
	player_name = player_name.strip_edges().left(MAX_NAME_LENGTH)
	if player_name.is_empty():
		player_name = DEFAULT_NAME
	var entry := {"name": player_name, "score": score, "time": time}
	var rank := entries.size()
	for i in entries.size():
		if _ranks_above(entry, entries[i]):
			rank = i
			break
	if rank >= MAX_ENTRIES:
		return -1
	entries.insert(rank, entry)
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	changed.emit()
	return rank


## The best `count` entries.
func top(count: int) -> Array[Dictionary]:
	return entries.slice(0, count)


## True if a ranks strictly above b (ties keep the older entry ahead).
static func _ranks_above(a: Dictionary, b: Dictionary) -> bool:
	if a.score != b.score:
		return a.score > b.score
	return a.time < b.time
