class_name NightOnly
extends CanvasItem
## Hidden during the day; fades in as night falls, in step with the night grade
## (follows GameManager.night_amount()). For night-only things like building
## campfires. Pooled buildings that scroll in later match the current night.


func _process(_delta: float) -> void:
	var amount := GameManager.night_amount()
	visible = amount > 0.0
	modulate.a = amount
