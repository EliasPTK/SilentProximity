extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_down() -> void:
	webID.web_id = int($TextEdit.text)
	webID.cam_id = $TextEdit2.text
	$Label.text = "Current Websocket: " + $TextEdit.text
	$TextEdit.text = ""
	$TextEdit2.text = ""
