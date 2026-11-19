extends AudioStreamPlayer
## The level's song. It starts with the run, plays faster as the world speeds
## up, and when it ends the level is complete (GameManager.complete_level()).
##
## Tempo curve: the song follows the world's speed-up in a straight line at
## first (tempo_influence of the level's increase), then eases off more and
## more as it approaches max_tempo, which it never passes. The world itself
## keeps speeding up without limit; only the song levels off.
##
## Speeding audio up also raises its pitch. With keep_original_pitch, the
## PitchShift effect on this player's bus (default_bus_layout.tres) shifts it
## back down by the same amount, so the song gets faster but stays in key.
## Turn it off for the classic arcade "chipmunk" speed-up.

## Keep the song in key as it speeds up (uses the bus's PitchShift effect).
## Can be toggled while the game runs (Remote inspector) to compare.
@export var keep_original_pitch: bool = true:
	set(value):
		keep_original_pitch = value
		_apply_pitch_mode()
## How strongly the song follows the world's speed-up at first.
## 0.3 = the level speeding up by 10% speeds the song up by 3%.
@export_range(0.0, 1.0, 0.05) var tempo_influence: float = 0.3
## Fastest the song will ever play (1.6 = 60% faster than normal). It gets
## close to this gradually and never goes past it.
@export_range(1.0, 4.0, 0.05) var max_tempo: float = 1.6

var _pitch_shift: AudioEffectPitchShift
var _bus_index := -1
var _effect_index := -1


func _ready() -> void:
	_find_pitch_shift()
	_apply_pitch_mode()
	finished.connect(_on_finished)
	GameManager.run_started.connect(_on_run_started)
	GameManager.run_ended.connect(_on_run_ended)
	GameManager.scroll_speed_changed.connect(_on_scroll_speed_changed)


## Playback rate for a given world speed (1 = normal tempo).
## Straight line with slope tempo_influence near the start, then bends smoothly
## towards max_tempo (tanh: linear at first, flattening into a ceiling).
func rate_for_speed(speed: float) -> float:
	var level_increase := speed / GameManager.BASE_SCROLL_SPEED - 1.0
	var headroom := max_tempo - 1.0
	if headroom <= 0.0 or level_increase <= 0.0:
		return 1.0
	return 1.0 + headroom * tanh(level_increase * tempo_influence / headroom)


## How far into the song we are, 0-1 (handy for a progress bar later).
func progress() -> float:
	if stream == null or stream.get_length() <= 0.0:
		return 0.0
	return get_playback_position() / stream.get_length()


func _on_run_started() -> void:
	_on_scroll_speed_changed(GameManager.scroll_speed)
	play()


func _on_scroll_speed_changed(speed: float) -> void:
	if speed <= 0.0:
		return # world stopped (before start / after the end): leave tempo alone
	var rate := rate_for_speed(speed)
	pitch_scale = rate
	if _pitch_shift:
		_pitch_shift.pitch_scale = 1.0 / rate


func _on_finished() -> void:
	GameManager.complete_level()


func _on_run_ended(completed: bool) -> void:
	if not completed:
		stop()


## Finds the PitchShift effect on this player's bus (see default_bus_layout.tres).
func _find_pitch_shift() -> void:
	_bus_index = AudioServer.get_bus_index(bus)
	if _bus_index < 0:
		return
	for i in AudioServer.get_bus_effect_count(_bus_index):
		var effect := AudioServer.get_bus_effect(_bus_index, i)
		if effect is AudioEffectPitchShift:
			_pitch_shift = effect
			_effect_index = i
			return
	if keep_original_pitch:
		push_warning("%s: bus '%s' has no PitchShift effect; pitch will rise with tempo." % [name, bus])


## Enables or disables the PitchShift effect to match keep_original_pitch.
func _apply_pitch_mode() -> void:
	if _effect_index >= 0:
		AudioServer.set_bus_effect_enabled(_bus_index, _effect_index, keep_original_pitch)
