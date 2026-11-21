@abstract
class_name PickupEffect
extends Resource
## Something extra a pickup does when collected, on top of its score, heal and
## speed_gain (see PickupData). A pickup lists any number of these in its
## `effects` array, so effects combine freely: a taco could be invulnerability
## plus a slow-down, without either effect knowing about the other.
##
## To add a new effect: make a script that extends PickupEffect, export its
## settings, and override apply() and describe(). It then shows up in the inspector's "New ..."
## list for any pickup's effects.
##
## Effect resources can be shared by several pickups (and every spawned copy of
## a pickup uses the same one), so keep them stateless: anything that lasts over
## time (timers, tweens) belongs to the thing being affected, e.g. the Player.


## Icon shown next to describe()'s text when the effect is collected (optional).
@export var icon: Texture2D


## Applies the effect. Called once, when the player collects the pickup.
@abstract func apply(player: Player) -> void


## Short text shown to the player when collected, e.g. "Invulnerable 3s".
@abstract func describe() -> String


## Seconds as compact text: 3 -> "3s", 2.5 -> "2.5s".
static func format_seconds(seconds: float) -> String:
	return ("%ds" % int(seconds)) if is_equal_approx(seconds, roundf(seconds)) else ("%.1fs" % seconds)
