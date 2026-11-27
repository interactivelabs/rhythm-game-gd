class_name Enemy
extends Node2D
## One enemy on screen. Instances are pooled and reused by EnemyPool, which calls
## setup() each time one is spawned. Enemies stand still and scroll with the
## world; the pool handles movement and hitting the player. Its origin is the
## point where the enemy's feet touch the ground.
##
## The sprite is mirrored in the scene so enemies face the player.
##
## As an enemy nears the player the pool calls attack(): it swings once (the
## "attack" animation, set to not loop in its SpriteFrames), timed so it is
## about 3/4 done on contact (EnemyData.attack_contact_progress), then returns
## to idle (animation_finished, connected in enemy.tscn). It swings whether or
## not the player is in its lane.

const IDLE := &"idle"
const ATTACK := &"attack"

var data: EnemyData
## Seconds before contact to start the attack (its length × attack_contact_progress).
var attack_lead_time := 0.0

var _attacked := false

@onready var animation: AnimatedSprite2D = $EnemyAnimation


func setup(new_data: EnemyData) -> void:
	data = new_data
	animation.sprite_frames = data.sprite_frames
	animation.offset = data.sprite_offset
	attack_lead_time = _duration(ATTACK) * data.attack_contact_progress
	_attacked = false
	animation.play(IDLE)
	# Start on a random frame so neighbouring enemies don't animate in sync.
	animation.frame = randi() % animation.sprite_frames.get_frame_count(IDLE)


## Plays the attack once. Does nothing if this enemy already attacked.
func attack() -> void:
	if _attacked or not animation.sprite_frames.has_animation(ATTACK):
		return
	_attacked = true
	animation.play(ATTACK)


func _on_animation_finished() -> void:
	if animation.animation == ATTACK:
		animation.play(IDLE)


## Length in seconds of `anim`, from the SpriteFrames' fps and per-frame
## durations (so re-timed art stays in sync).
func _duration(anim: StringName) -> float:
	var frames := animation.sprite_frames
	if not frames.has_animation(anim) or frames.get_animation_speed(anim) <= 0.0:
		return 0.0
	var units := 0.0
	for i in frames.get_frame_count(anim):
		units += frames.get_frame_duration(anim, i)
	return units / frames.get_animation_speed(anim)
