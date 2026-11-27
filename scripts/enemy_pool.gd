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


## Starts each enemy's attack so it is attack_contact_progress through it on contact.
## Timed by seconds-to-contact rather than a fixed distance, so the swing stays
## in sync as scroll_speed rises. Lane-agnostic: enemies swing at a dodging
## player too. Enemy.attack() only fires once per spawn.
func _on_approach(item: Node2D, _index: int, distance: float) -> void:
	var enemy := item as Enemy
	if distance <= GameManager.scroll_speed * enemy.attack_lead_time:
		enemy.attack()


func _on_touched(index: int, at: Vector2) -> bool:
	# While invulnerable the player passes through and the enemy stays.
	if not (player as Player).take_hit(enemies[index].damage):
		return false
	hit_player.emit(enemies[index], at)
	return true
