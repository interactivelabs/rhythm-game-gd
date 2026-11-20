extends CanvasLayer
## Shown when the run ends: "Victory!" when the song played to the end, "Game
## Over" when health ran out. Shows the final gold and time, with buttons to
## play again or quit. Like the HUD, it only reacts to GameManager's signals.
##
## On a win the player types a name, which adds the run to the Leaderboard;
## the screen then shows the top scores with the new one highlighted.

## Seconds to wait after the run ends before the screen appears, so the
## player sees what happened (e.g. the death) first.
@export var show_delay_lost: float = 1.0
@export var show_delay_won: float = 0.4
## Seconds the screen takes to fade in.
@export var fade_time: float = 0.35
@export var win_title: String = "Victory!"
@export var lose_title: String = "Game Over"
## Leaderboard rows shown (the player's own row is added below if lower).
@export var leaderboard_rows: int = 5

## Brightness of the keyboard-focused button, so it's clear which one Enter hits.
const FOCUS_TINT := Color(1.2, 1.2, 1.2)

@onready var root: Control = $Root
@onready var ribbon: PanelContainer = %Ribbon
@onready var title_label: Label = %TitleLabel
@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel
@onready var name_entry: Control = %NameEntry
@onready var name_edit: LineEdit = %NameEdit
@onready var save_button: Button = %SaveButton
@onready var scores: GridContainer = %Scores
@onready var play_again_button: Button = %PlayAgainButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	hide()
	GameManager.run_ended.connect(_on_run_ended)
	play_again_button.pressed.connect(_on_play_again_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	save_button.pressed.connect(_submit_name)
	name_edit.text_submitted.connect(_submit_name.unbind(1))
	name_edit.max_length = Leaderboard.MAX_NAME_LENGTH
	for button: Button in [play_again_button, quit_button, save_button]:
		button.focus_entered.connect(func(): button.modulate = FOCUS_TINT)
		button.focus_exited.connect(func(): button.modulate = Color.WHITE)
	# Quitting makes no sense in a browser tab.
	quit_button.visible = not OS.has_feature("web")


func _on_run_ended(completed: bool) -> void:
	title_label.text = win_title if completed else lose_title
	ribbon.theme_type_variation = &"WinRibbon" if completed else &"LoseRibbon"
	score_label.text = str(GameManager.score)
	time_label.text = _format_time(GameManager.run_time)
	name_entry.visible = completed
	scores.visible = false

	await get_tree().create_timer(show_delay_won if completed else show_delay_lost).timeout
	root.modulate.a = 0.0
	show()
	create_tween().tween_property(root, "modulate:a", 1.0, fade_time)
	if completed:
		name_edit.grab_focus()
	else:
		play_again_button.grab_focus()


## Saves the run under the typed name and swaps the name entry for the scores.
func _submit_name() -> void:
	if not name_entry.visible:
		return
	var rank := Leaderboard.add_entry(name_edit.text, GameManager.score, GameManager.run_time)
	name_entry.hide()
	_show_scores(rank)
	play_again_button.grab_focus()


## Fills the scores grid (rank, name, gold, time), highlighting `highlight`.
func _show_scores(highlight: int) -> void:
	for child in scores.get_children():
		scores.remove_child(child)
		child.queue_free()
	var shown := mini(leaderboard_rows, Leaderboard.entries.size())
	for rank in shown:
		_add_score_row(rank, rank == highlight)
	if highlight >= shown:
		_add_score_row(highlight, true)
	scores.show()


func _add_score_row(rank: int, highlighted: bool) -> void:
	var entry: Dictionary = Leaderboard.entries[rank]
	var cells := ["%d." % (rank + 1), entry.name, str(entry.score), _format_time(entry.time)]
	for i in cells.size():
		var label := Label.new()
		label.text = cells[i]
		label.theme_type_variation = &"ScoreRowHighlight" if highlighted else &"ScoreRowLabel"
		# Numbers line up on the right, the name on the left.
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 1 else HORIZONTAL_ALIGNMENT_RIGHT
		scores.add_child(label)


## Run time as mm:ss.
static func _format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d" % [s / 60, s % 60]


func _on_play_again_pressed() -> void:
	GameManager.reset()
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
