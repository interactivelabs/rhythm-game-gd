class_name FeedbackPopups
extends Node2D
## Floating numbers above the player's head saying what just happened:
## "-30" (sword) when hit, "+15" (coin) for gold, "+20" (meat) for food, and
## each food effect's own text and icon (see PickupEffect.describe()).
##
## Popups appear at the player and don't scroll with the world, so they stay
## readable at any speed. Several at once (e.g. heal + effect) stack upwards.
## Like the HUD, this only listens to signals; nothing calls it directly.

@export var popup_scene: PackedScene
@export var player: Node2D
@export var pickups: PickupPool
@export var enemies: EnemyPool

@export_group("Layout")
## Where the first popup appears, relative to the player's origin.
@export var head_offset := Vector2(0, -72)
## Vertical gap between stacked popups.
@export var line_height: float = 30.0
## Popups shown within this many seconds of the last one stack above it.
@export var stack_window: float = 0.35
## Most popups stacked at once before starting again at the bottom.
@export var max_stack: int = 4
## Pixels a popup rises while fading out, and how long that takes.
@export var rise: float = 48.0
@export var duration: float = 0.9

@export_group("Look")
@export var damage_icon: Texture2D
@export var heal_icon: Texture2D
@export var gold_icon: Texture2D
@export var damage_color := Color(1.0, 0.38, 0.32)
@export var heal_color := Color(0.55, 1.0, 0.45)
@export var gold_color := Color(1.0, 0.86, 0.35)
@export var effect_color := Color(0.6, 0.86, 1.0)

var _free: Array[FloatingText] = []
var _stack := 0
var _last_time := -INF


func _ready() -> void:
	assert(popup_scene != null and player != null, "%s needs popup_scene and player" % name)
	if pickups:
		pickups.collected.connect(_on_pickup_collected)
	if enemies:
		enemies.hit_player.connect(_on_player_hit)


func _on_pickup_collected(pickup: PickupData, _at: Vector2) -> void:
	if pickup.score > 0:
		_show("+%d" % pickup.score, gold_color, gold_icon)
	if pickup.heal > 0:
		_show("+%d" % pickup.heal, heal_color, heal_icon)
	for effect in pickup.effects:
		_show(effect.describe(), effect_color, effect.icon)


func _on_player_hit(enemy: EnemyData, _at: Vector2) -> void:
	_show("-%d" % enemy.damage, damage_color, damage_icon)


func _show(text: String, color: Color, icon: Texture2D) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_time > stack_window:
		_stack = 0
	_last_time = now
	var at := to_local(player.global_position + head_offset) + Vector2(0, -_stack * line_height)
	_stack = (_stack + 1) % max_stack
	_acquire().play(text, color, icon, at, rise, duration)


func _acquire() -> FloatingText:
	if not _free.is_empty():
		return _free.pop_back()
	var popup := popup_scene.instantiate() as FloatingText
	add_child(popup)
	popup.finished.connect(func(): _free.append(popup))
	return popup
