class_name EnemyData
extends Resource
## Per-type enemy configuration. One .tres per enemy type, listed on the
## EnemyPool. See resources/enemies/. Shown in game by scenes/enemy.tscn.

@export var display_name: String = ""
## Health the player loses when hit (health is 0-100).
@export var damage: int = 10
@export var sprite_frames: SpriteFrames
## Sprite offset that puts the art's feet on the enemy's origin, so it stands on
## the same line as the player. Measured for the mirrored (left-facing) sprite.
@export var sprite_offset: Vector2 = Vector2.ZERO
## Half-width of the hit area in pixels. A bit smaller than the visible art
## feels fair. Also used for spacing.
@export var collision_radius: float = 39.0
## Relative chance of this type being picked when a row gets an enemy.
@export_range(0.0, 100.0, 0.1) var weight: float = 1.0
