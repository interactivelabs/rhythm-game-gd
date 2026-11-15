extends CanvasLayer
## In-game HUD (top right): health bar, gold score and run time. Purely reacts to
## GameManager's signals, so nothing else needs to know the HUD exists.

@onready var health_bar: HealthBar = %HealthBar
@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel


func _ready() -> void:
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.run_seconds_changed.connect(_on_run_seconds_changed)
	# Show the starting values without animating.
	health_bar.fill.max_value = GameManager.MAX_HEALTH
	health_bar.fill.value = GameManager.health
	_on_score_changed(GameManager.score)
	_on_run_seconds_changed(int(GameManager.run_time))


func _on_health_changed(health: int, max_health: int) -> void:
	health_bar.set_value(health, max_health)


func _on_score_changed(score: int) -> void:
	score_label.text = str(score)


## Shows run time as mm:ss.
func _on_run_seconds_changed(seconds: int) -> void:
	time_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]
