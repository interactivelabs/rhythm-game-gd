class_name EnemyPool
extends LanePool
## Pool of enemies placed in the lanes by the LaneDirector. Enemies stand still
## and scroll with the world. Touching one hurts the player (unless the player
## is briefly invulnerable from a previous hit) and removes the enemy.

## Emitted when an enemy actually damaged the player (for sounds/effects).
signal hit_player(enemy: EnemyData, at: Vector2)

## Enemy types that can spawn. See resources/enemies/.
@export var enemies: Array[EnemyData] = []


func _weights() -> PackedFloat32Array:
	var w := PackedFloat32Array()
	for e in enemies:
		w.append(e.weight)
	return w


func _radius(index: int) -> float:
	return enemies[index].collision_radius


func _setup_item(item: Node2D, index: int) -> void:
	(item as Enemy).setup(enemies[index])


func _on_touched(index: int, at: Vector2) -> bool:
	# While invulnerable the player passes through and the enemy stays.
	if not (player as Player).take_hit(enemies[index].damage):
		return false
	hit_player.emit(enemies[index], at)
	return true
