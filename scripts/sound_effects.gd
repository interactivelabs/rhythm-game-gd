extends Node
## Plays the game's sound effects in response to what happens in the level:
## coin when gold is collected, a chomp when food is eaten, hurt when an enemy hits the player, explosion
## when the player dies and power-up when the level is completed. Each sound is
## a child AudioStreamPlayer (on the SFX bus), so volumes can be tuned per sound
## in the scene. Nothing else needs to know this node exists.

@export var pickups: PickupPool
@export var enemies: EnemyPool

@onready var coin: AudioStreamPlayer = $Coin
@onready var eat: AudioStreamPlayer = $Eat
@onready var hurt: AudioStreamPlayer = $Hurt
@onready var explosion: AudioStreamPlayer = $Explosion
@onready var power_up: AudioStreamPlayer = $PowerUp


func _ready() -> void:
	if pickups:
		pickups.collected.connect(_on_pickup_collected)
	if enemies:
		enemies.hit_player.connect(_on_player_hit)
	GameManager.run_ended.connect(_on_run_ended)


func _on_pickup_collected(pickup: PickupData, _at: Vector2) -> void:
	# Gold is anything worth points; everything else is food.
	if pickup.score > 0:
		coin.play()
	else:
		eat.play()


func _on_player_hit(_enemy: EnemyData, _at: Vector2) -> void:
	# The killing blow plays the explosion instead (see _on_run_ended).
	if not GameManager.is_over:
		hurt.play()


func _on_run_ended(completed: bool) -> void:
	if completed:
		power_up.play()
	else:
		explosion.play()
