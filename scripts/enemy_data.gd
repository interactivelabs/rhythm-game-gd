class_name EnemyData
extends Resource
## Per-type enemy configuration. Create one .tres per enemy type and assign
## it to an enemy instance's `data` property.

@export var display_name: String = ""
@export var damage: int = 1
@export var sprite_frames: SpriteFrames
## Radius of the enemy's CircleShape2D (bear sprites are larger: 256px vs 192px).
@export var collision_radius: float = 39.0
