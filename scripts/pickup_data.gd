class_name PickupData
extends Resource
## Per-type pickup configuration (gold stones, food, ...). One .tres per type,
## listed on the PickupSpawner. See resources/pickups/. Shown in game by
## scenes/pickup.tscn, which plays sprite_frames' "default" animation.

@export var display_name: String = ""
## Animation shown for this pickup (uses the "default" animation).
@export var sprite_frames: SpriteFrames
## Sprite offset that puts the art's bottom-centre (where it touches the ground)
## on the pickup's origin, so it lines up with the player's feet.
@export var sprite_offset: Vector2 = Vector2.ZERO
## Points added to GameManager.score when collected.
@export var score: int = 0
## Health restored when collected.
@export var heal: int = 0
## World scroll speed (px/s) added when collected, multiplied by
## GameManager.speed_scaling.
@export var speed_gain: float = 0.0
## Extra effects applied when collected (invulnerability, slow-down, ...).
## They combine: list as many as you like. See scripts/effects/.
@export var effects: Array[PickupEffect] = []
## Relative chance of this type being spawned.
@export_range(0.0, 100.0, 0.1) var weight: float = 1.0
## Half-width of the hit area in pixels (roughly half the art's visible width).
## Also used for spacing between pickups.
@export var collision_radius: float = 24.0
