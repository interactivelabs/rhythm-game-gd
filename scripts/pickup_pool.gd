class_name PickupPool
extends LanePool
## Pool of pickups (gold, food, ...) placed in the lanes by the LaneDirector.
## Touching one applies it to GameManager (score, health, speed),
## runs its effects on the player, and removes it.

## Emitted after a pickup has been applied to GameManager (for sounds/effects).
signal collected(pickup: PickupData, at: Vector2)

## Pickup types that can spawn. See resources/pickups/.
@export var pickups: Array[PickupData] = []


func _weights() -> PackedFloat32Array:
	var w := PackedFloat32Array()
	for p in pickups:
		w.append(p.weight)
	return w


func _radius(index: int) -> float:
	return pickups[index].collision_radius


func _setup_item(item: Node2D, index: int) -> void:
	(item as Pickup).setup(pickups[index])


func _on_touched(index: int, at: Vector2) -> bool:
	if GameManager.is_over:
		return true
	var pickup := pickups[index]
	GameManager.collect(pickup)
	for effect in pickup.effects:
		effect.apply(player as Player)
	collected.emit(pickup, at)
	return true
