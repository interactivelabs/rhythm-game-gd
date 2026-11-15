extends Node2D

@onready var ground: TileMapLayer = $TerrainGround/Ground
@onready var player = $Player


# Runs after the children's _ready, so the player is already set up here.
func _ready() -> void:
	GameManager.register_lanes(ground)
	player.snap_to_lane(GameManager.START_LANE)
